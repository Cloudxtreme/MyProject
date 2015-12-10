#!/usr/bin/perl
#########################################################################
#Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NETSEC::NETSECTds;

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%NETSEC = (
        'AddrulesPort_ICMP' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_ICMP',
          'Summary' => 'Adding rules to the Port and verifying ICMP package'.
                       ' is accepted/dropped/Logged',
          'ExpectedResult' => 'PASS',
          'Tags' => 'CAT_P0',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile4'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile2'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_ICMPLog'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile3'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_ICMPDrop'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_ICMPAccept'
              ]
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'AddRulesFile4' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => '  ',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile2' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'IP_PROTO=0x01  ACTION=LOG',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_ICMPAccept' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '5',
              'pingpktsize' => '1000',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'AddRulesFile3' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'IP_PROTO=0x01  ACTION=DROP;IP_PROTO=0x02  ACTION=DROP',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_ICMPDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '5',
              'pingpktsize' => '1000',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'FAIL',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'IP_PROTO=0x01  ACTION=ACCEPT',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_ICMPLog' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '5',
              'pingpktsize' => '1000',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Verification_1' => {
              'log' => {
              'target' => 'srchost',
              'StringPresent' => [
              'Got packet matching a rule hash'
               ],
              'verificationtype' => 'VMKernelLog'
               }
           },
          }
        },

        'AddrulesPort_Dst' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_Dst',
          'Summary' => 'Adding rules to the Port and verifying destion' .
                       ' port rules work for accept/drop/log.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_dstLog'
              ],
              [
                'Traffic_dstAccept'
              ],
              [
                'Traffic_dstDrop'
              ]
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'DPORT=15110 ACTION=PUNT;DPORT=15120 ACTION=DROP;'.
                            'DPORT=15130 ACTION=ACCEPT; DPORT=15140 ACTION=LOG;'.
                            'DPORT=15111 ACTION=PUNT;DPORT=15121 ACTION=DROP;'.
                            'DPORT=15131 ACTION=ACCEPT; DPORT=15141 ACTION=LOG',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_dstLog' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15140',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_dstAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '15130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'minexpresult' => '50',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_dstDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15120',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'log' => {
                'target' => 'dsthost',
                'StringPresent' => [
                    'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK'
                                                                      => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx'
                                                                      => '10-',
                'verificationtype' => 'vsish'
              }
            }
          }
        },

        'AddrulesPort_Src' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_Src',
          'Summary' => 'Adding rules to the Port and verifying source port'.
                       ' rules work for accept/drop/log.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_srcAccept'
              ],
              [
                'Traffic_srcLog'
              ],
              [
                'Traffic_srcDrop'
              ]
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'SPORT=14110 ACTION=PUNT; SPORT=14120 ACTION=DROP; '.
                            'SPORT=14130 ACTION=ACCEPT; SPORT=14140 ACTION=LOG; '.
                            'SPORT=14111 ACTION=PUNT; SPORT=14121 ACTION=DROP; '.
                            'SPORT=14131 ACTION=ACCEPT; SPORT=14141 ACTION=LOG',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_srcAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '14130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'minexpresult' => '50',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_srcLog' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '14140',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_srcDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '14120',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'log' => {
                'target' => 'srchost',
                'StringPresent' => [
                  'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK'
                         => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx'
                                   => '10-',
                'verificationtype' => 'vsish'
              }
            }
          }
        },

        'AddrulesPort_JF' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_JF',
          'Summary' => 'Adding rules to the Port and verifying'.
                       ' JF package is accepted/dropped/Logged',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'SetVDSMTU'
              ],
              [
                'SetVSSMTU'
              ],
              [
                'SetVnicMTU'
              ],
              [
                'Traffic_JFDrop'
              ],
              [
                'Traffic_JFLog'
              ],
              [
                'Traffic_JFAccept'
              ],
            ],
            'ExitSequence' => [
              [
                'ReSetVDSMTU'
              ],
              [
                'ReSetVSSMTU'
              ],
              [
                'ReSetVnicMTU'
              ],
              [
                'RemovePortRules'
              ],
              [
                'PoweroffVM'
              ],
            ],
             'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'DPORT=18120 ACTION=DROP; DPORT=18110 ACTION=PUNT;'.
                            'DPORT=18130 ACTION=ACCEPT; DPORT=18140 ACTION=LOG;'.
                            'DPORT=18121 ACTION=DROP; DPORT=18111 ACTION=PUNT;'.
                            'DPORT=18131 ACTION=ACCEPT; DPORT=18141 ACTION=LOG',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetVDSMTU' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'SetVSSMTU' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'SetVnicMTU' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '9000'
            },
            'Traffic_JFDrop' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '4000',
              'receivemessagesize' => '2048',
              'localsendsocketsize' => '4000',
              'testduration' => '5',
              'portnumber' => '18120',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]',
              'localreceivesocketsize' => '4000,',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'remotesendsocketsize' => '4000',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'sendmessagesize' => '2048'
            },
            'Traffic_JFLog' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '4000',
              'receivemessagesize' => '2048',
              'localsendsocketsize' => '4000',
              'testduration' => '5',
              'portnumber' => '18140',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]',
              'localreceivesocketsize' => '4000,',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '4000',
              'verification' => 'Verification_1',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'sendmessagesize' => '2048'
            },
            'Traffic_JFAccept' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '4000',
              'receivemessagesize' => '2048',
              'localsendsocketsize' => '4000',
              'testduration' => '5',
              'portnumber' => '18130',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]',
              'localreceivesocketsize' => '4000,',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '4000',
              'verification' => 'Stats',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'sendmessagesize' => '2048'
            },
            'ReSetVDSMTU' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'ReSetVSSMTU' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'ReSetVnicMTU' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '1500'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'log' => {
                'target' => 'srchost',
                'StringPresent' => [
                  'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
              }
            },
            'VerificationJF' => {
              'PktCapVerificaton' => {
                'srcpktcapfilter' => 'size>1500',
                'target' => 'src',
                'pktcount' => '1',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK'
                         => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx'
                                   => '10-',
                'verificationtype' => 'vsish'
              }
            }
          }
        },

        'AddrulesPort_Multicast' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_Multicast',
          'Summary' => 'Adding rules to the Port and verifying'.
                       ' IGMP package is accepted/dropped/Logged',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile2'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_IGMPLog'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile3'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_IGMPDrop'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_IGMPAccept'
              ]
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile2' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'IP_PROTO=0x02  ACTION=LOG',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_IGMPAccept' => {
              'Type' => 'Traffic',
              'toolname' => 'Iperf',
              'testduration' => '10',
              'routingscheme' => 'multicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'noofinbound' => '1',
              'multicasttimetolive' => '32',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'AddRulesFile3' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'IP_PROTO=0x01  ACTION=DROP;'.
                            'IP_PROTO=0x02  ACTION=DROP',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_IGMPDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Iperf',
              'testduration' => '10',
              'routingscheme' => 'multicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'noofinbound' => '1',
              'multicasttimetolive' => '32',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
               'addrules' => 'IP_PROTO=0x01  ACTION=ACCEPT;'.
                             'IP_PROTO=0x02  ACTION=ACCEPT',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15',
                'verificationtype' => 'pktcap'
              }
            },
            'Traffic_IGMPLog' => {
              'Type' => 'Traffic',
              'toolname' => 'Iperf',
              'testduration' => '10',
              'routingscheme' => 'multicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'noofinbound' => '1',
              'multicasttimetolive' => '32',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'verification' => 'Verification_1',
            },
            'Verification_1' => {
              'log' => {
                'target' => 'srchost',
                'StringPresent' => [
                  'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
                }
             }
             }
        },

        'AddrulesPort_VMOps' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_VMOps',
          'Summary' => 'Adding rules to the Port and verify these'.
                       ' rules still work after restart/off/on the protected VM.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'RebootVM'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic_srcAccept'
              ],
              [
                'Traffic_dstDrop'
              ],
              [
                'PoweroffVM'
              ],
              [
                'PoweronVM'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic_srcAccept'
              ],
              [
                'Traffic_dstDrop'
              ]
            ],
            'ExitSequence' => [
               ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'SPORT=14130 ACTION=ACCEPT; DPORT=15120 ACTION=DROP;'.
                            'SPORT=14131 ACTION=ACCEPT; DPORT=15121 ACTION=DROP',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RebootVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'iterations' => '1',
              'operation' => 'reset'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic_srcAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '14130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'minexpresult' => '50',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_dstDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15120',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'PoweronVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweron'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '10-',
                'verificationtype' => 'vsish'
              }
            }
          }
        },

        'AddrulesPort_TCP' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_TCP',
          'Summary' => 'Adding rules to the Port and verifying'.
                       ' TCP rules work for accept/drop/log.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile_Accept'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_TCPAccept'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile_Log'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_TCPLog'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile_Drop'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_TCPDrop'
              ],
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile_Log' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x06 ACTION=LOG;'.
                            'ETH_TYPE=0x86dd IP_PROTO=0x06 ACTION=LOG;',
            },
            'AddRulesFile_Accept' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x06 ACTION=ACCEPT;'.
                            'ETH_TYPE=0x86dd IP_PROTO=0x06 ACTION=ACCEPT;',
            },
            'AddRulesFile_Drop' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x06 ACTION=DROP;'.
                            'ETH_TYPE=0x86dd IP_PROTO=0x06 ACTION=DROP;',
            },
            'Traffic_TCPAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '16130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'minexpresult' => '50',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_TCPLog' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '16140',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_TCPDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '16120',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap',
              }
            },
            'Verification_1' => {
              'log' => {
                'target' => 'dsthost',
                'StringPresent' => [
                  'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK'
                         => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx'
                                   => '10-',
                'verificationtype' => 'vsish'
              }
            }
          }
        },

        'AddrulesPort_UDP' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_UDP',
          'Summary' => 'Adding rules to the Port and verifying'.
                       ' UDP rules work for accept/drop/log.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile_Accept'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_UDPAccept'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile_Log'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_UDPLog'
              ],
              [
                'RemovePortRules'
              ],
              [
                'AddRulesFile_Drop'
              ],
              [
                'PushPortRules'
              ],
              [
                'Traffic_UDPDrop'
              ]
            ],
            'ExitSequence' => [
              ['RemovePortRules'], ['PoweroffVM']
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile_Log' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x11 ACTION=LOG;',
            },
            'AddRulesFile_Accept' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x11 ACTION=ACCEPT;',
            },
            'AddRulesFile_Drop' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'addrules' => 'ETH_TYPE=0x0800 IP_PROTO=0x11 ACTION=DROP;',
            },
            'Traffic_UDPAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '17130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'UDP',
              'l3protocol' => 'IPv4',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Traffic_UDPLog' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '17140',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'UDP',
              'l3protocol' => 'IPv4',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic_UDPDrop' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '1024',
              'localsendsocketsize' => '1024',
              'toolname' => 'Iperf',
              'testduration' => '5',
              'portnumber' => '17120',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'UDP',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'log' => {
                'target' => 'dsthost',
                'StringPresent' => [
                  'Got packet matching a rule hash'
                ],
                'verificationtype' => 'VMKernelLog'
              }
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK'
                         => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx'
                                   => '10-',
                'verificationtype' => 'vsish'
              }
              }
            }
        },


        'AddrulesPort_Vmotion' => {
          'Product'   => 'ESX',
          'Component' => 'IO Filters',
          'Category'  => 'Networking',
          'TestName' => 'AddrulesPort_Dst',
          'Summary' => 'Adding rules to the Port and verifying destion' .
                       ' port rules work for accept/drop/log.',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]'
                  }
                },
                'dvportgroup' => {
                  '[1-2]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[2]',
                   }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[2]',
                   }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'datastoreType' => 'shared',
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'DVFilterHostSetup'
              ],
              [
                'AddCustomAgent'
              ],
              [
                'AddRulesFile'
              ],
              [
                'PushPortRules'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic_srcAccept'
              ],
              [
                'Traffic_dstDrop'
              ],
              [
                'EnableVMotion'
              ],
              [
                'vmotion'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic_srcAccept'
              ],
              [
                'Traffic_dstDrop'
              ],
            ],
            'ExitSequence' => [
              [
                'RemovePortRules'
              ],
              [
                'PoweroffVM'
              ],
            ],
            'Iterations' => '1',
            'PoweroffVM' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'hostsetup' => 'dvfilter-generic-hp',
              'role' => 'host'
            },
            'AddCustomAgent' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'dvfilterparams' => 'qw(10:foobar)',
              'slotdetails' => 'qw(0:1)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'onfailure' => 'qw(failOpen)',
              'adapter' => 'vm.[1].vnic.[1]',
              'configureprotectedvm' => 'true',
            },
            'RemovePortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(remove)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'PushPortRules' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'dvfilteroperation' => 'qw(add)',
              'filters' => 'qw(dvfilter-generic-hp)',
              'configureportrules' => 'true',
              'adapter' => 'vm.[1].vnic.[1]'
            },
            'AddRulesFile' => {
              'Type' => 'DVFilter',
              'TestDVFilter' => 'vm.[1]',
              'adapter' => 'vm.[1].vnic.[1]',
              'role' => 'vm',
              'addrules' => 'SPORT=14130 ACTION=ACCEPT; DPORT=15120 ACTION=DROP;'.
                            'SPORT=14131 ACTION=ACCEPT; DPORT=15121 ACTION=DROP',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'EnableVMotion' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[-1].vmknic.[1]',
               'configurevmotion' => 'ENABLE',
               'ipv4' => 'dhcp'
            },
            'vmotion' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'priority' => 'high',
               'vmotion' => 'roundtrip',
               'sleepbetweenworkloads' => '30',
               'dsthost' => 'host.[2].x.[x]',
               'iterations' => '4',
               'staytime' => '60'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic_srcAccept' => {
              'Type' => 'Traffic',
              'dataintegritycheck' => 'Enable',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '14130',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'PASS',
              'minexpresult' => '50',
              'verification' => 'Verification_Accept',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Verification_Accept' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '1400+',
                'pktcapfilter' => 'count 1500,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              },
              'Vsish' => {
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '500+',
                'target' => 'dst',
                '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '10-',
                'verificationtype' => 'vsish'
              }
            },
            'Traffic_dstDrop' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15120',
              'bursttype' => 'stream',
              'testadapter' => 'vm.[2].vnic.[1]',
              'expectedresult' => 'FAIL',
              'verification' => 'VerificationDrop',
              'l4protocol' => 'TCP',
              'l3protocol' => 'IPv4,IPv6',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'VerificationDrop' => {
              'PktCapVerificaton' => {
                'target' => 'dstvm',
                'pktcount' => '0',
                'pktcapfilter' => 'count 15,tcp-ack != 0',
                'verificationtype' => 'pktcap'
              }
            },
          }
        },


   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for NETSEC.
#
# Input:
#       None.
#
# Results:
#       An instance/object of NETSEC class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%NETSEC);
   return (bless($self, $class));
}
