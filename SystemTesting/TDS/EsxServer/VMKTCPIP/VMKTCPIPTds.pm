#!/usr/bin/perl
#########################################################################
#Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VMKTCPIP::VMKTCPIPTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ( "DHCP","DHCPDisableEnable","DHCPReboot","EEsxReboot",
              "ESXRebootTorture", "VMRebootTorture", "StressVmknic",
              "StressSetReset", "TCPIPStackEnableDisable","TCPIPStackTSO",
              "TCPIPStackTSOJF","Multicast", "NetStress",
              "MultipleUDPStreamTx","JFCapability","JFCapabilityPersistent",
              "JFMaxMTU","NegativeJF","JFSameSwitch","JFDiffSwitch",
              "TSOCapability","TsoCapabilityPersistent","TsoSoftware",
              "TSOSameSwitch","TSODiffSwitch","JFTSO","JFNetStress",
              "LROStatsEnable","LROMaxLength","TrafficShapingIngress",
              "TrafficShapingEgress","DHCPNoDHCPServer",
              "MultipleStacks","VmknicVDS","VmknicVlan","RFRoute",
              "VMKNictest");

   %VMKTCPIP = (
        'EEsxReboot' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'EEsxReboot',
          'Summary' => 'Verify that the VMKNIC retains STATIC IP after Reboot',
          'ExpectedResult' => 'PASS',
          'Tags' => 'hostreboot',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'VmknicStaticSUT'
              ],
              [
                'VmknicStaticHelper'
              ],
              [
                'RebootHost'
              ],
              [
                'PingTraffic'
              ]
            ],
            'Iterations' => '1',
            'VmknicStaticSUT' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.10',
              'iterations' => '1'
            },
            'VmknicStaticHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '192.168.0.11',
              'iterations' => '1'
            },
            'RebootHost' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'reboot' => 'yes'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'EsxRebootTorture' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'EsxRebootTorture',
          'Summary' => 'Verify ESX doesn\'t crash after host reboot torture.'.
                     'RCCA for bug 1195340',
          'ExpectedResult' => 'PASS',
          'Tags' => 'hostreboot, stress, rcca',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]',
                    'ipv4' => '192.168.0.10',
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]',
                    'ipv4' => '192.168.0.11',
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'RebootHost'
              ],
            ],
            'RebootHost' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'reboot' => 'yes',
              'runworkload' => 'PingTraffic',
              'Iterations' => '100',
              'maxtimeout' => '14400',
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '5',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]',
            }
          }
        },


        'VMRebootTorture' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'VMRebootTorture',
          'Summary' => 'Verify ESX doesn\'t crash after VMs reboot'.
                      'torture. RCCA for bug 1195340',
          'ExpectedResult' => 'PASS',
          'Tags' => 'vmreboot, stress, rcca',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vm' => {
              '[1-3]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[x]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1]'
              },
            },
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-3]' => {
                    'vss' => 'host.[1].vss.[x]'
                  }
                },
                'vmnic' => {
                  '[1-3]' => {
                    'driver' => 'any'
                  }
                },
                'vss' => {
                  '[1-3]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'RebootVM1',
                'RebootVM2'
              ]
            ],
            'RebootVM1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'maxtimeout' => '14400',
              'iterations' => '2',
              'vmstate' => 'reboot',
              'waitforvdnet' => 'true',
              'runworkload' => 'TRAFFIC1',
              'Iterations' => '100',
            },
            'RebootVM2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2]',
              'maxtimeout' => '14400',
              'iterations' => '2',
              'vmstate' => 'reboot',
              'waitforvdnet' => 'true',
              'runworkload' => 'TRAFFIC2',
              'Iterations' => '100',
            },
            'TRAFFIC1' => {
              'Type' => 'Traffic',
              'testduration' => '5',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'TRAFFIC2' => {
              'Type' => 'Traffic',
              'testduration' => '5',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            }
          }
        },


        'TsoSoftware' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TsoSoftware',
          'Summary' => 'Verify the network traffic after enabling software TSO',
          'ExpectedResult' => 'Pass',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'TSOEnable'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ],
              [
                'TSODisable'
              ]
            ],
            'Iterations' => '1',
            'TSOEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'true',
                 },
              'iterations' => '1'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1024,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'TSODisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'false',
                 },
              'iterations' => '1'
            }
          }
        },


        'NegativeJF' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'NegativeJF',
          'Summary' => 'Verify that the VMKernel is intact after JF Misconfiguration ',
          'ExpectedResult' => undef,
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'SwitchJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'NetperfTx'
              ],
              [
                'NetperfRx'
              ],
              [
                'NetperfTxRx'
              ],
              [
                'SwitchJF_2000'
              ],
              [
                'SwitchJFhelper_2000'
              ],
              [
                'NetAdapterJF_2000'
              ],
              [
                'NetAdapterJFHelper_2000'
              ],
              [
                'NetperfTxRx'
              ],
              [
                'SwitchJF_4000'
              ],
              [
                'SwitchJFhelper_4000'
              ],
              [
                'NetAdapterJF_4000'
              ],
              [
                'NetAdapterJFHelper_4000'
              ],
              [
                'NetperfTxRx'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'SwitchJFhelperDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'NetperfTx' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '30',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'minexpresult'   => "IGNORE"
            },
            'NetperfRx' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localsendsocketsize' => '8000',
              'dataintegritycheck' => 'Enable',
              'testduration' => '30',
              'portnumber' => '13000',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '8000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'minexpresult'   => "IGNORE"
            },
            'NetperfTxRx' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localsendsocketsize' => '8000',
              'dataintegritycheck' => 'Enable',
              'testduration' => '30',
              'portnumber' => '13000',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '8000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'minexpresult'   => "IGNORE"
            },
            'SwitchJF_2000' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '2000'
            },
            'SwitchJFhelper_2000' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '2000'
            },
            'NetAdapterJF_2000' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '2000'
            },
            'NetAdapterJFHelper_2000' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '2000'
            },
            'SwitchJF_4000' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '4000'
            },
            'SwitchJFhelper_4000' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '4000'
            },
            'NetAdapterJF_4000' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '4000'
            },
            'NetAdapterJFHelper_4000' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '4000'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'SwitchJFhelperDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'MultipleUDPStreamTx' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'MultipleUDPStreamTx',
          'Summary' => 'Create vmknic and run  multiple Netperf streams in parallel',
          'ExpectedResult' => undef,
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'Netperf_1',
                'Netperf_2',
                'Netperf_3',
                'Netperf_4',
                'Netperf_5'
              ]
            ],
            'Iterations' => '1',
            'Netperf_1' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '500,1024,1472,1500,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf_2' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '14000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '500,1024,1472,1500,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf_3' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '15000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '64,1024,1472,1500,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf_4' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '16000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '500,1024,1472,1500,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf_5' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '17000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1024,1472,1500,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'TsoCapabilityPersistent' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TsoCapabilityPersistent',
          'Summary' => 'Verify that TSO is retained after Reboot',
          'ExpectedResult' => 'PASS',
          'Tags' => 'hostreboot',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'TSOCheck'
              ],
              [
                'PingTraffic'
              ],
              [
                'RebootHost'
              ],
              [
                'PingTraffic'
              ]
            ],
            'Iterations' => '1',
            'TSOCheck' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'check_tso_support' => 'true',
              'iterations' => '1'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'noofinbound' => '1',
              'pingpktsize' => '1000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'RebootHost' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'reboot' => 'yes'
            }
          }
        },


        'JFMaxMTU' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFMaxMTU',
          'Summary' => 'Verify that JF >16k cannot be Set on VMkernel',
          'ExpectedResult' => 'FAIL',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'SwitchJF'
              ],
              [
                'NetAdapterJF'
              ]
            ],
            'Iterations' => '1',
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '2048'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'expectedresult' => 'Fail',
              'mtu' => '20000'
            }
          }
        },


        'StressSetReset' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'StressSetReset',
          'Summary' => 'Verify TSO with the Network Stress Options Enabled',
          'ExpectedResult' => 'FAIL',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnableNetFailPktAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPktSlabHeapAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktSlabHeapAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPktClone'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktClone'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPktFrameCopy'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktFrameCopy'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPktCopyBytesIn'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktCopyBytesIn'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPktCopyBytesOut'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktCopyBytesOut'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPrivHdr'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPrivHdr'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailCopyFromSGMA'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailCopyFromSGMA'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailKseg'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailKseg'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailPartialCopy'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPartialCopy'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetHwRetainBuffer'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetHwRetainBuffer'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetCorruptPortInput'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetCorruptPortInput'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetCorruptPortOutput'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetCorruptPortOutput'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfCorruptEthHdr'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptEthHdr'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfCorruptRxData'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptRxData'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfCorruptRxTcpUdp'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptRxTcpUdp'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfCorruptTx'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptTx'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfFailRx'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfFailRx'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetFailNDiscHeapAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailNDiscHeapAlloc'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetCopyToLowSG'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetCopyToLowSG'
              ],
              [
                'Netperf'
              ],
              [
                'EnableNetIfFailHardTx'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfFailHardTx'
              ],
              [
                'Netperf'
              ]
            ],
            'Iterations' => '1',
            'EnableNetFailPktAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktAlloc}}',
              }
            },
            'Netperf' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '4000,32000',
              'localreceivesocketsize' => '32000',
              'localsendsocketsize' => '32000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32000',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000,32000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'DisableNetFailPktAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktAlloc}}',
              }
            },
            'EnableNetFailPktSlabHeapAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktSlabHeapAlloc}}',
              }
            },
            'DisableNetFailPktSlabHeapAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktSlabHeapAlloc}}',
              }
            },
            'EnableNetFailPktClone' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktClone}}',
              }
            },
            'DisableNetFailPktClone' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktClone}}',
              }
            },
            'EnableNetFailPktFrameCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktFrameCopy}}',
              }
            },
            'DisableNetFailPktFrameCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktFrameCopy}}',
              }
            },
            'EnableNetFailPktCopyBytesIn' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesIn}}',
              }
            },
            'DisableNetFailPktCopyBytesIn' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesIn}}',
              }
            },
            'EnableNetFailPktCopyBytesOut' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesOut}}',
              }
            },
            'DisableNetFailPktCopyBytesOut' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesOut}}',
              }
            },
            'EnableNetFailPrivHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPrivHdr}}',
              }
            },
            'DisableNetFailPrivHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPrivHdr}}',
              }
            },
            'EnableNetFailCopyFromSGMA' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailCopyFromSGMA}}',
              }
            },
            'DisableNetFailCopyFromSGMA' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailCopyFromSGMA}}',
              }
            },
            'EnableNetFailKseg' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailKseg}}',
              }
            },
            'DisableNetFailKseg' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailKseg}}',
              }
            },
            'EnableNetFailPartialCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPartialCopy}}',
              }
            },
            'DisableNetFailPartialCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPartialCopy}}',
              }
            },
            'EnableNetHwRetainBuffer' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetHwRetainBuffer}}',
              }
            },
            'DisableNetHwRetainBuffer' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetHwRetainBuffer}}',
              }
            },
            'EnableNetCorruptPortInput' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCorruptPortInput}}',
              }
            },
            'DisableNetCorruptPortInput' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCorruptPortInput}}',
              }
            },
            'EnableNetCorruptPortOutput' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCorruptPortOutput}}',
              }
            },
            'DisableNetCorruptPortOutput' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCorruptPortOutput}}',
              }
            },
            'EnableNetIfCorruptEthHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptEthHdr}}',
              }
            },
            'DisableNetIfCorruptEthHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptEthHdr}}',
              }
            },
            'EnableNetIfCorruptRxData' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxData}}',
              }
            },
            'DisableNetIfCorruptRxData' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxData}}',
              }
            },
            'EnableNetIfCorruptRxTcpUdp' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxTcpUdp}}',
              }
            },
            'DisableNetIfCorruptRxTcpUdp' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxTcpUdp}}',
              }
            },
            'EnableNetIfCorruptTx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptTx}}',
              }
            },
            'DisableNetIfCorruptTx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptTx}}',
              }
            },
            'EnableNetIfFailRx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfFailRx}}',
              }
            },
            'DisableNetIfFailRx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfFailRx}}',
              }
            },
            'EnableNetFailNDiscHeapAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailNDiscHeapAlloc}}',
              }
            },
            'DisableNetFailNDiscHeapAlloc' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailNDiscHeapAlloc}}',
              }
            },
            'EnableNetCopyToLowSG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCopyToLowSG}}',
              }
            },
            'DisableNetCopyToLowSG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetCopyToLowSG}}',
              }
            },
            'EnableNetIfFailHardTx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfFailHardTx}}',
              }
            },
            'DisableNetIfFailHardTx' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfFailHardTx}}',
              }
            }
          }
        },

        'MultipleStacks' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'MultipleStacks',
          'Summary' => 'Create 32 vmknic and run traffic ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[1]'
                  }
                }
              },
              '[1]' => {
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
            [
              'Create32PortGroups'
            ],
            [
              'Create32VMKNICs'
            ],
            [
              'SetIPv4'
            ],
            [
              'SetIPv4_helper'
            ],
            [
              'NetperfTCP'
            ]
          ],
          'Iterations' => '1',
          'Create32PortGroups' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'portgroup' => {
              '[1-32]' => {
                'vss' => 'host.[1].vss.[1]'
              }
            },
          },
          'Create32VMKNICs' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'vmknic' => {
              '[26]' => {
                'portgroup' => 'host.[1].portgroup.[26]'
              },
              '[19]' => {
                'portgroup' => 'host.[1].portgroup.[19]'
              },
              '[4]' => {
                'portgroup' => 'host.[1].portgroup.[4]'
              },
              '[28]' => {
                'portgroup' => 'host.[1].portgroup.[28]'
              },
              '[25]' => {
                'portgroup' => 'host.[1].portgroup.[25]'
              },
              '[14]' => {
                'portgroup' => 'host.[1].portgroup.[14]'
              },
              '[20]' => {
                'portgroup' => 'host.[1].portgroup.[20]'
              },
              '[31]' => {
                'portgroup' => 'host.[1].portgroup.[31]'
              },
              '[27]' => {
                'portgroup' => 'host.[1].portgroup.[27]'
              },
              '[16]' => {
                'portgroup' => 'host.[1].portgroup.[16]'
              },
              '[12]' => {
                'portgroup' => 'host.[1].portgroup.[12]'
              },
              '[32]' => {
                'portgroup' => 'host.[1].portgroup.[32]'
              },
              '[11]' => {
                'portgroup' => 'host.[1].portgroup.[11]'
              },
              '[6]' => {
                'portgroup' => 'host.[1].portgroup.[6]'
              },
              '[24]' => {
                'portgroup' => 'host.[1].portgroup.[24]'
              },
              '[2]' => {
                'portgroup' => 'host.[1].portgroup.[2]'
              },
              '[18]' => {
                'portgroup' => 'host.[1].portgroup.[18]'
              },
              '[10]' => {
                'portgroup' => 'host.[1].portgroup.[10]'
              },
              '[29]' => {
                'portgroup' => 'host.[1].portgroup.[29]'
              },
              '[23]' => {
                'portgroup' => 'host.[1].portgroup.[23]'
              },
              '[21]' => {
                'portgroup' => 'host.[1].portgroup.[21]'
              },
              '[22]' => {
                'portgroup' => 'host.[1].portgroup.[22]'
              },
              '[8]' => {
                'portgroup' => 'host.[1].portgroup.[8]'
              },
              '[30]' => {
                'portgroup' => 'host.[1].portgroup.[30]'
              },
              '[7]' => {
                'portgroup' => 'host.[1].portgroup.[7]'
              },
              '[3]' => {
                'portgroup' => 'host.[1].portgroup.[3]'
              },
              '[13]' => {
                'portgroup' => 'host.[1].portgroup.[13]'
              },
              '[17]' => {
                'portgroup' => 'host.[1].portgroup.[17]'
              },
              '[1]' => {
                'portgroup' => 'host.[1].portgroup.[1]'
              },
              '[5]' => {
                'portgroup' => 'host.[1].portgroup.[5]'
              },
              '[9]' => {
                'portgroup' => 'host.[1].portgroup.[9]'
              },
              '[15]' => {
                'portgroup' => 'host.[1].portgroup.[15]'
              }
            }
          },
            'SetIPv4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1-32]',
              'maxtimeout' => '49200',
              'ipv4' => 'AUTO'
            },
            'SetIPv4_helper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'maxtimeout' => '9200',
              'ipv4' => 'AUTO'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '8000',
              'localreceivesocketsize' => '32000',
              'localsendsocketsize' => '32000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'bursttype' => 'stream',
              'testadapter' => 'host.[2].vmknic.[1]',
              'parallelsession' => 'yes',
              'noofoutbound' => '1',
              'maxtimeout' => '28800',
              'remotesendsocketsize' => '32000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '8000',
              'supportadapter' => 'host.[1].vmknic.[1-32]'
            }
          }
        },


        'TSOSameSwitch' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TSOSameSwitch',
          'Summary' => 'Verify Network traffic between the VM and vmknic after enabling TSO',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1024',
              'supportadapter' => 'vm.[1].vnic.[1]'
            }
          }
        },


        'JFNetStress' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFNetStress',
          'Summary' => 'Verify JF with Stress options enabled ',
          'ExpectedResult' => 'Fail',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'PingTraffic'
              ],
              [
                'SwitchJF'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'EnableStress'
              ],
              [
                'NetperfTCP'
              ],
              [
                'DisableStress'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'EnableStress' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%VDNetLib::TestData::StressTestData::VMKTCPIPJFNetstress'
              }
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'host.[2].vmknic.[1]',
              #PR 1161969
              #minexpresult should be a numeric value and cannot be just 'IGNORE'.
              #TODO: Will fix this and remove 'IGNORE' in future
              'minexpresult' => 'IGNORE',
              'verification' => 'Verification'
            },
            'Verification' => {
              'PktCapVerificaton' => {
                'verificationtype' => 'pktcap',
                'target' => 'host.[2].vmknic.[1]',
                'pktcount' => '10+',
                'pktcapfilter' => 'count 20'
              }
            },
            'DisableStress' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%VDNetLib::TestData::StressTestData::VMKTCPIPJFNetstress'
              }
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'TsoCapability' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TsoCapability',
          'Summary' => 'Verify that Tso is supported byVmnic',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'TSOCheck'
              ]
            ],
            'Iterations' => '1',
            'TSOCheck' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'check_tso_support' => 'true',
              'iterations' => '1'
            }
          }
        },


        'TCPIPStackTSOJF' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TCPIPStackTSOJF',
          'Summary' => 'Verify TSO and JF in Tcpipstack ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'SwitchJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'NetperfTCP'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'SwitchJFhelperDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '8000',
              'localsendsocketsize' => '32000',
              'testduration' => '5',
              'portnumber' => '13000',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '32000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '32000,',
              'verification' => 'Stats',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '8000'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'SwitchJFhelperDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'VMNicTest' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'Esx Server',
          'TestName' => 'VMNicTest',
          'Summary' => 'Simple test on vmnic/vmknic',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[3]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[4]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[2]' => {
                    'portgroup' => 'host.[1].portgroup.[3]'
                  },
                  '[3]' => {
                    'portgroup' => 'host.[1].portgroup.[4]'
                  },
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapter_1'
              ],
              [
                'NetAdapter_2'
              ],
              [
                'NetAdapter_3'
              ],
              [
                'NetAdapter_4'
              ],
              [
                'NetAdapter_5'
              ],
              [
                'NetAdapter_6'
              ],
              [
                'NetAdapter_7'
              ],
              [
                'NetAdapter_8'
              ],
              [
                'NetAdapter_9'
              ],
              [
                'NetAdapter_10'
              ]
            ],
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1],host.[1].vmknic.[2]',
              'devicestatus' => 'DOWN,UP'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlro' => 'DISABLE,ENABLE'
            },
            'NetAdapter_3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlromxlgth' => '32765'
            },
            'NetAdapter_4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'NetAdapter_5' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1600'
            },
            'NetAdapter_6' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'settcpipstress' => 'rxReorderProb',
              'configurevmotion' => 'ENABLE,DISABLE',
              'tcpipstressvalue' => '13'
            },
            'NetAdapter_7' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE,DISABLE'
            },
            'NetAdapter_8' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'ableipv6' => 'ENABLE,DISABLE'
            },
            'NetAdapter_9' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv6' => 'ADD',
              'ipv6addr' => 'DHCPV6,ROUTER,PEERDNS,STATIC'
            },
            'NetAdapter_10' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv6' => 'DELETE'
            }
          }
        },


        'LROStatsEnable' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'LROStatsEnable',
          'Summary' => 'Verify TCPIPStack with LRO stats enabled',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'LROEnable'
              ],
              [
                'NetperfTCP'
              ],
              [
                'LRODisable'
              ]
            ],
            'Iterations' => '1',
            'LROEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlro' => 'ENABLE'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'LRODisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlro' => 'DISABLE'
            }
          }
        },


        'TCPIPStackTSO' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TCPIPStackTSO',
          'Summary' => 'Verify TSO in Tcpipstack ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'NetperfTCP'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '8000,32000',
              'localsendsocketsize' => '32000',
              'testduration' => '5',
              'portnumber' => '13000',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '32000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '32000,',
              'verification' => 'Stats',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '8000,32000'
            }
          }
        },


        'DHCPReboot' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'DHCPReboot',
          'Summary' => 'Verify that the VMKNIC retains the DHCP IP  after reboot',
          'ExpectedResult' => 'PASS',
          'Tags' => 'hostreboot',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'RebootHost'
              ],
              [
                'PingTraffic'
              ]
            ],
            'Iterations' => '1',
            'RebootHost' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'reboot' => 'yes'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'Multicast' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'Multicast',
          'Summary' => 'Create a vmknic with DHCP IP ',
          'ExpectedResult' => 'PASS',
          'Tags' => 'BAT,batnovc',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PingTraffic'
              ],
              [
                'IperfTraffic'
              ]
            ],
            'Iterations' => '1',
            'PingTraffic' => {
              'Type' => 'Traffic',
              'testduration' => '10',
              'toolname' => 'ping',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'IperfTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'Iperf',
              'testduration' => '10',
              'routingscheme' => 'multicast',
              'testadapter' => 'host.[1].vmknic.[1]',
              'minexpresult' => '1',
              'noofinbound' => '1',
              'multicasttimetolive' => '32',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'JFCapabilityPersistent' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFCapabilityPersistent',
          'Summary' => 'Verif If VMKNIC retainsJF setting across reboots',
          'ExpectedResult' => 'PASS',
          'Tags' => 'hostreboot',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'Iterations' => '1',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'SwitchJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'RebootHost'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'SwitchJFhelperDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ]
            ],
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'RebootHost' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'reboot' => 'yes'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'SwitchJFhelperDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'DHCPDisableEnable' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'DHCPDisableEnable',
          'Summary' => 'Verify that VMKNIC retains DHCP IPafter Disable/enable ' .
                       'and make sure it has dhcp ip',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'VmknicDisableEnable'
              ]
            ],
            'Iterations' => '1',
            'VmknicDisableEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'devicestatus' => 'DOWN,UP',
              'iterations' => '1'
            }
          }
        },


        'JFDiffSwitch' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFDiffSwitch',
          'Summary' => 'Verify that Traffic between VM(Vmxnet3) and VMKnic ' .
                       'works fine',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vss' => {
                  '[1]' => {}
                },
                'portgroup' => {
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'AddUplinkonHelper1'
              ],
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ],
              [
                'SwitchJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFVnic'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFVnicDisable'
              ],
              [
                'SwitchJFHelperDisable'
              ]
            ],
            'Iterations' => '1',
            'AddUplinkonHelper1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
            },
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '8000',
              'localreceivesocketsize' => '32000',
              'localsendsocketsize' => '32000',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '8000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1000,2000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFVnic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '1000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFVnicDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'mtu' => '1500'
            },
            'SwitchJFHelperDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            }
          }
        },


        'Stressvmknic' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'Stressvmknic',
          'Summary' => 'Create a vmknic and Stress it by disabling and enabling',
          'ExpectedResult' => 'FAIL',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'BasicTraffic'
              ],
              [
                'EnableDisableLoop',
                'Netperf',
                'IperfTraffic',
                'Netperf_rr'
              ]
            ],
            'ExitSequence' => [
              [
                'EnableDevice'
              ]
            ],
            'Iterations' => '1',
            'BasicTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'EnableDisableLoop' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1],host.[2].vmknic.[1]',
              'devicestatus' => 'DOWN,UP',
              'iterations' => '50'
            },
            'Netperf' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '1024,8192,32738,57344,64000,25600',
              'receivemessagesize' => '1024,4096,8192,57344,64000,25600',
              'localreceivesocketsize' => '1024,8192,32738,57344,64000,25600',
              'localsendsocketsize' => '1024,4096,8192,57344,64000,25600',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'expectedresult' => 'IGNORE',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '1024,8192,32738,57344,64000,25600',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '1024,4096,8192,57344,64000,25600',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'IperfTraffic' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '1024,4096,8192,57344,64000,25600',
              'localsendsocketsize' => '1024,4096,8192,57344,64000,25600',
              'toolname' => 'Iperf',
              'testduration' => '5',
              'portnumber' => '17000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'expectedresult' => 'IGNORE',
              'l4protocol' => 'TCP',
              'noofinbound' => '1',
              'tcpwindowsize' => '1024,4096,8192,57344,64000,25600',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf_rr' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15000',
              'responsesize' => '1,64,100,1024,1500,4096,8192',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'expectedresult' => 'IGNORE',
              'l4protocol' => 'TCP',
              'requestsize' => '1,64,100,1024,1500,4096,8192',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'EnableDevice' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1],host.[2].vmknic.[1]',
              'devicestatus' => 'UP',
              'iterations' => '1'
            }
          }
        },


        'DHCPNoDHCPServer' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'DHCPNoDHCPServer',
          'Summary' => 'Create a vmknic with No DHCPIP ',
          'ExpectedResult' => 'Pass',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'VmnicDisable'
              ],
              [
                'VmnicEnable'
              ]
            ],
            'Iterations' => '1',
            'VmnicDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'devicestatus' => 'DOWN',
              'iterations' => '1'
            },
            'VmnicEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'devicestatus' => 'UP',
              'iterations' => '1'
            }
          }
        },


        'UDPWithIPv4AndIPv6' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'Esx Server',
          'TestName' => 'UDPWithIPv4AndIPv6',
          'Summary' => 'This test verifies UDP Traffic stressing both inbound ' .
                       'and outbound paths.',
          'ExpectedResult' => 'PASS',
          'Tags' => 'BAT,batnovc',
          'Version' => '2',
          'ParentTDSID' => '7.1',
          'AutomationStatus' => 'automated',
          'Priority' => 'P1',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'UDPTraffic'
              ]
            ],
            'UDPTraffic' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '131072',
              'toolname' => 'netperf',
              'testduration' => '20',
              'testadapter' => 'vm.[1].vnic.[1],host.[2].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '131072',
              'minexpresult' => 'IGNORE',
              'maxtimeout' => '5000',
              'verification' => 'PktCap',
              'l4protocol' => 'udp',
              'l3protocol' => 'ipv4,ipv6',
              'sendmessagesize' => '63488-8192,15872',
              'noofinbound' => '1',
              'supportadapter' => 'host.[1].vmknic.[1]'
            }
          }
        },


        'JFTSO' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFTSO',
          'Summary' => 'Verify JF   ',
          'ExpectedResult' => 'Fail',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'SwitchJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'TSOEnable'
              ],
              [
                'NetperfTCP'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'SwitchJFhelperDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ],
              [
                'TSODisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'TSOEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'true',
                 },
              'iterations' => '1'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'minexpresult' => 'ignore',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelperDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'TSODisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'false',
                 },
              'iterations' => '1'
            }
          }
        },


        'RFRoute' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'RFRoute',
          'Summary' => 'Verify that enabling routing sockets to send kernel ' .
                       'updates for interfaces/ip addresses and routes ' .
                       'doesn\'t cause a regression.',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'AddvSwitch'
              ],
              [
                'AddPGs'
              ],
              [
                'AddVmknic1'
              ],
              [
                'AddVmknic2'
              ],
              [
                'AddVmknic3'
              ],
              [
                'AddVmknic4'
              ],
              [
                'AddVmknic5'
              ],
              [
                'AddVmkRoute1'
              ],
              [
                'AddVmkRoute2'
              ],
              [
                'AddVmkRoute3'
              ],
              [
                'AddVmkRoute4'
              ],
              [
                'AddVmkRoute5'
              ],
              [
                'DeleteVmknic1'
              ],
              [
                'DeleteVmknic2'
              ],
              [
                'DeleteVmknic3'
              ],
              [
                'DeleteVmknic4'
              ],
              [
                'DeleteVmknic5'
              ],
              [
                'DeletePG1'
              ],
              [
                'DeletePG2'
              ],
              [
                'DeletePG3'
              ],
              [
                'DeletePG4'
              ],
              [
                'DeletePG5'
              ],
              [
                'DeletevSwitch'
              ],
              [
                'Sleep'
              ]
            ],
            'Iterations' => '20',
            'AddvSwitch' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => 'vSwitchRF'
                }
              }
            },
            'AddPGs' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'portgroup' => {
                '[5]' => {
                  'name' => 'vmkpg-4',
                  'vss' => 'host.[1].vss.[1]'
                },
                '[2]' => {
                  'name' => 'vmkpg-1',
                  'vss' => 'host.[1].vss.[1]'
                },
                '[3]' => {
                  'name' => 'vmkpg-2',
                  'vss' => 'host.[1].vss.[1]'
                },
                '[6]' => {
                  'name' => 'vmkpg-5',
                  'vss' => 'host.[1].vss.[1]'
                },
                '[4]' => {
                  'name' => 'vmkpg-3',
                  'vss' => 'host.[1].vss.[1]'
                }
              }
            },
            'AddVmknic1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'host.[1].portgroup.[2]',
                  'ipv4' => '192.168.10.1',
                  'netmask' => '255.255.255.0'
                }
              }
            },
            'AddVmknic2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[2]' => {
                  'portgroup' => 'host.[1].portgroup.[3]',
                  'ipv4' => '192.168.20.1',
                  'netmask' => '255.255.255.0'
                }
              }
            },
            'AddVmknic3' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[3]' => {
                  'portgroup' => 'host.[1].portgroup.[4]',
                  'ipv4' => '192.168.30.1',
                  'netmask' => '255.255.255.0'
                }
              }
            },
            'AddVmknic4' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[4]' => {
                  'portgroup' => 'host.[1].portgroup.[5]',
                  'ipv4' => '192.168.40.1',
                  'netmask' => '255.255.255.0'
                }
              }
            },
            'AddVmknic5' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[5]' => {
                  'portgroup' => 'host.[1].portgroup.[6]',
                  'ipv4' => '192.168.50.1',
                  'netmask' => '255.255.255.0'
                }
              }
            },
            'AddVmkRoute1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'network' => '192.168.110.0',
              'gateway' => '192.168.10.1',
              'netmask' => '255.255.255.0',
              'route' => 'Add'
            },
            'AddVmkRoute2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[2]',
              'network' => '192.168.120.0',
              'gateway' => '192.168.20.1',
              'netmask' => '255.255.255.0',
              'route' => 'Add'
            },
            'AddVmkRoute3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[3]',
              'network' => '192.168.130.0',
              'gateway' => '192.168.30.1',
              'netmask' => '255.255.255.0',
              'route' => 'Add'
            },
            'AddVmkRoute4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[4]',
              'network' => '192.168.140.0',
              'gateway' => '192.168.40.1',
              'netmask' => '255.255.255.0',
              'route' => 'Add'
            },
            'AddVmkRoute5' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[5]',
              'network' => '192.168.150.0',
              'gateway' => '192.168.50.1',
              'netmask' => '255.255.255.0',
              'route' => 'Add'
            },
            'DeleteVmknic1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[1]'
            },
            'DeleteVmknic2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[2]'
            },
            'DeleteVmknic3' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[3]'
            },
            'DeleteVmknic4' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[4]'
            },
            'DeleteVmknic5' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[5]'
            },
            'DeletePG1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deleteportgroup' => 'host.[1].portgroup.[2]'
            },
            'DeletePG2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deleteportgroup' => 'host.[1].portgroup.[3]'
            },
            'DeletePG3' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deleteportgroup' => 'host.[1].portgroup.[4]'
            },
            'DeletePG4' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deleteportgroup' => 'host.[1].portgroup.[5]'
            },
            'DeletePG5' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deleteportgroup' => 'host.[1].portgroup.[6]'
            },
            'DeletevSwitch' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevss' => 'host.[1].vss.[1]'
            },
            'Sleep' => {
              'Type' => 'Command',
              'command' => 'sleep 30',
              'testhost' => 'host.[1].x.[x]'
            }
          }
        },


        'TCPWithIPv4AndIPv6' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'Esx Server',
          'TestName' => 'TCPWithIPv4AndIPv6',
          'Summary' => 'This test verifies TCP Traffic stressing both ' .
                       'inbound and outbound paths.',
          'ExpectedResult' => 'PASS',
          'Tags' => 'BAT,batnovc',
          'Version' => '2',
          'ParentTDSID' => '7.1',
          'AutomationStatus' => 'automated',
          'Priority' => 'P0',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'TCPTraffic'
              ]
            ],
            'TCPTraffic' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '131072',
              'toolname' => 'netperf',
              'testduration' => '20',
              'testadapter' => 'vm.[1].vnic.[1],host.[2].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '131072',
              'maxtimeout' => '5000',
              'verification' => 'PktCap',
              'l4protocol' => 'tcp',
              'l3protocol' => 'ipv4,ipv6',
              'sendmessagesize' => '131072,131072-16384,16384',
              'noofinbound' => '1',
              'supportadapter' => 'host.[1].vmknic.[1]'
            }
          }
        },


        'TCPIPStackEnableDisable' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TCPIPStackEnableDisable',
          'Summary' => 'Create a vmknic and Stress it by disabling and enabling',
          'ExpectedResult' => undef,
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticSUT'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'InboundTraffic',
                'OutboundTraffic',
                'VmknicDelete',
                'VmknicAddDelete'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticSUT' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.222'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'InboundTraffic' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '32000',
              'localsendsocketsize' => '32000',
              'localreceivesocketsize' => '32000',
              'toolname' => 'netperf',
              'testduration' => '1000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '32000',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'noofinbound' => '1',
              'sendmessagesize' => '32000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'OutboundTraffic' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '32000',
              'localsendsocketsize' => '32000',
              'localreceivesocketsize' => '32000',
              'toolname' => 'netperf',
              'testduration' => '1000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32000',
              'minexpresult' => 'IGNORE',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '32000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'VmknicDelete' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[1]',
              'sleepbetweenworkloads' => '60'
            },
            'VmknicAddDelete' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'sleepbetweenworkloads' => '90',
              'iterations' => '20',
              'deletevmknic' => 'host.[1].vmknic.[2]',
              'vmknic' => {
                '[2]' => {
                  'portgroup' => 'host.[1].portgroup.[2]',
                  'ipv4' => '192.168.0.222',
                  'netmask' => '255.255.0.0'
                }
              }
            },
          }
        },


        'DHCP' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'DHCP',
          'Summary' => 'Create a vmknic with DHCP IP ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PingTraffic'
              ]
            ],
            'Iterations' => '1',
            'PingTraffic' => {
              'Type' => 'Traffic',
              'testduration' => '10',
              'toolname' => 'ping',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'TSODiffSwitch' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TSODiffSwitch',
          'Summary' => 'Verify Network traffic between the VM and vmknic after' .
                       ' enabling TSO',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vss' => {
                  '[1]' => {}
                },
                'portgroup' => {
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'AddUplinkonHelper1'
              ],
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ]
            ],
            'Iterations' => '1',
            'AddUplinkonHelper1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
            },
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1024',
              'supportadapter' => 'vm.[1].vnic.[1]'
            }
          }
        },


        'JFSameSwitch' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFSameSwitch',
          'Summary' => 'Verify that Traffic between VM(Vmxnet3) and VMKnic ' .
                       'works fine',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ],
              [
                'SwitchJF'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'NetAdapterJFVnic'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'NetperfTCP'
              ],
              [
                'NetperfUDP'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFVnicDisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '192.168.0.200'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'ipv4' => '192.168.0.201'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '8000',
              'localreceivesocketsize' => '32000',
              'localsendsocketsize' => '32000',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '8000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '10',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1000,2000',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFVnic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFVnicDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'VmknicVlan' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'VmknicVlan',
          'Summary' => 'Verify that network traffic between Vmknics using ' .
                       'vswitch vlan tagging',
          'ExpectedResult' => 'PASS',
          'Tags' => 'BAT,batnovc,CAT_P0',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'SwitchVlan'
              ],
              [
                'SwitchVlanhelper'
              ],
              [
                'PingTraffic'
              ],
              [
                'Netperf'
              ],
              [
                'NetperfUDP'
              ],
              [
                'SwitchVlanDisable'
              ],
              [
                'SwitchVlanhelperDisable'
              ]
            ],
            'Iterations' => '1',
            'SwitchVlan' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[1].portgroup.[2]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
            },
            'SwitchVlanhelper' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[2].portgroup.[2]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'Netperf' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32000',
              'receivemessagesize' => '1500,32000',
              'localreceivesocketsize' => '32000,',
              'localsendsocketsize' => '32000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32000',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '1500,32000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'NetperfUDP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '32768',
              'receivemessagesize' => '1000,2000',
              'localreceivesocketsize' => '32768',
              'localsendsocketsize' => '32768',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'portnumber' => '15000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '32768',
              'l4protocol' => 'UDP',
              'sendmessagesize' => '1024,2000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'SwitchVlanDisable' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[1].portgroup.[2]',
              'vlantype' => 'access',
              'vlan' => '0'
            },
            'SwitchVlanhelperDisable' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[2].portgroup.[2]',
              'vlantype' => 'access',
              'vlan' => '0'
            }
          }
        },


        'NetStress' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'NetStress',
          'Summary' => 'Verify TSO with the Network Stress Options Enabled',
          'ExpectedResult' => 'Pass',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnableNetIfForceRxSWCsum'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfForceRxSWCsum'
              ],
              [
                'EnableNetFailPktCopyBytesOut'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktCopyBytesOut'
              ],
              [
                'EnableNetFailPrivHdr'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPrivHdr'
              ],
              [
                'EnableNetFailCopyFromSGMA'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailCopyFromSGMA'
              ],
              [
                'EnableNetFailKseg'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailKseg'
              ],
              [
                'EnableNetIfCorruptEthHdr'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptEthHdr'
              ],
              [
                'EnableNetIfCorruptRxData'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetIfCorruptRxData'
              ],
              [
                'EnableNetFailPktFrameCopy'
              ],
              [
                'Netperf'
              ],
              [
                'DisableNetFailPktFrameCopy'
              ]
            ],
            'Iterations' => '1',
            'EnableNetIfForceRxSWCsum' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfForceRxSWCsum}}',
              }
            },
            'Netperf' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localreceivesocketsize' => '8000',
              'localsendsocketsize' => '8000',
              'toolname' => 'Netperf',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '8000',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'DisableNetIfForceRxSWCsum' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktAlloc}}',
              }
            },
            'EnableNetFailPktCopyBytesOut' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesOut}}',
              }
            },
            'DisableNetFailPktCopyBytesOut' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktCopyBytesOut}}',
              }
            },
            'EnableNetFailPrivHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPrivHdr}}',
              }
            },
            'DisableNetFailPrivHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPrivHdr}}',
              }
            },
            'EnableNetFailCopyFromSGMA' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailCopyFromSGMA}}',
              }
            },
            'DisableNetFailCopyFromSGMA' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailCopyFromSGMA}}',
              }
            },
            'EnableNetFailKseg' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailKseg}}',
              }
            },
            'DisableNetFailKseg' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailKseg}}',
              }
            },
            'EnableNetIfCorruptEthHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptEthHdr}}',
              }
            },
            'DisableNetIfCorruptEthHdr' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptEthHdr}}',
              }
            },
            'EnableNetIfCorruptRxData' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxData}}',
              }
            },
            'DisableNetIfCorruptRxData' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetIfCorruptRxData}}',
              }
            },
            'EnableNetFailPktFrameCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'enable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktFrameCopy}}',
              }
            },
            'DisableNetFailPktFrameCopy' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'configure_stress' => {
                  'operation' => 'disable',
                  'stress_options' => '%{$VDNetLib::TestData::StressTestData::VMKTCPIPStress{NetFailPktFrameCopy}}',
              }
            }
          }
        },


        'TrafficeShappingIngress' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'TrafficeShappingIngress',
          'Summary' => 'Verify TrafficShapingIngress using vmknic ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnableShaping1'
              ],
              [
                'EnableShaping2'
              ],
              [
                'EnableShaping3'
              ],
              [
                'EnableShaping4'
              ]
            ],
            'ExitSequence' => [
              [
                'DisableShaping'
              ]
            ],
            'Iterations' => '1',
            'EnableShaping1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'runworkload' => 'Traffic1',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'avg_bandwidth' => '500000',
                'burst_size' => '50000',
                'peak_bandwidth' => '1000000'
              }
            },
            'EnableShaping2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'runworkload' => 'Traffic2',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'avg_bandwidth' => '125000',
                'burst_size' => '50000',
                'peak_bandwidth' => '500000'
              }
            },
            'EnableShaping3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'runworkload' => 'Traffic3',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'avg_bandwidth' => '125',
                'burst_size' => '25',
                'peak_bandwidth' => '1000'
              }
            },
            'EnableShaping4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'expectedresult' =>'FAIL',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'avg_bandwidth' => '0',
                'burst_size' => '0',
                'peak_bandwidth' => '0'
              }
            },
            'DisableShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable'
              }
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'host.[2].vmknic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'maxtimeout' => '500',
              'l4protocol' => 'udp',
              'maxthroughput' => '600',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'host.[2].vmknic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'maxtimeout' => '500',
              'l4protocol' => 'udp',
              'maxthroughput' => '150',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'host.[2].vmknic.[1]',
              'remotesendsocketsize' => '32768,65535',
              'minexpresult' => '0',
              'maxtimeout' => '500',
              'l4protocol' => 'udp',
              'maxthroughput' => '1',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'host.[1].vmknic.[1]'
            }
          }
        },


        'VmknicVDS' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'VmknicVDS',
          'Summary' => 'Verify the network traffic between Vmknics using VDS',
          'ExpectedResult' => 'PASS',
          'Tags' => 'BAT,batwithvc',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2].x.[x]'
                  }
                },
                'dvportgroup' => {
                  '[2]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  },
                  '[3]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  },
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
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
                    'portgroup' => 'vc.[1].dvportgroup.[3]'
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
                    'portgroup' => 'vc.[1].dvportgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'Iperf'
              ]
            ],
            'Iterations' => '1',
            'Iperf' => {
              'Type' => 'Traffic',
              'localreceivesocketsize' => '32000',
              'localsendsocketsize' => '32000',
              'toolname' => 'Iperf',
              'testduration' => '5',
              'portnumber' => '17000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'l4protocol' => 'TCP',
              'noofinbound' => '1',
              'tcpwindowsize' => '8000',
              'supportadapter' => 'host.[2].vmknic.[1]'
            }
          }
        },


        'JFCapability' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'JFCapability',
          'Summary' => 'Verify JF capability of VMKnic',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'NetAdapterStaticVmknic'
              ],
              [
                'NetAdapterStaticHelper1'
              ],
              [
                'PingTraffic'
              ],
              [
                'SwitchJF'
              ],
              [
                'NetAdapterJF'
              ],
              [
                'SwitchJFhelper'
              ],
              [
                'NetAdapterJFHelper'
              ],
              [
                'PingTrafficJF'
              ],
              [
                'SwitchJFDisable'
              ],
              [
                'NetAdapterJFDisable'
              ],
              [
                'NetAdapterJFHelperDisable'
              ]
            ],
            'Iterations' => '1',
            'NetAdapterStaticVmknic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'NetAdapterStaticHelper1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'noofinbound' => '1',
              'pingpktsize' => '100',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'SwitchJF' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJF' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '9000'
            },
            'SwitchJFhelper' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'mtu' => '9000'
            },
            'NetAdapterJFHelper' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '9000'
            },
            'PingTrafficJF' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'pingpktsize' => '2000',
              'testadapter' => 'host.[1].vmknic.[1]',
              'pktfragmentation' => 'no',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'SwitchJFDisable' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'mtu' => '1500'
            },
            'NetAdapterJFHelperDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'mtu' => '1500'
            }
          }
        },


        'LROMaxLength' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'LROMaxLength',
          'Summary' => 'Verify TCPIPStack with different LRO Packet sizes',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]'
                  }
                }
              },
              '[1]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'LROEnable'
              ],
              [
                'LROLengthEnable'
              ],
              [
                'NetperfTCP'
              ],
              [
                'LROLengthEnable_1'
              ],
              [
                'NetperfTCP_1'
              ],
              [
                'LRODisable'
              ],
              [
                'LROLengthDisable'
              ]
            ],
            'Iterations' => '1',
            'LROEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlro' => 'Enable'
            },
            'LROLengthEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlromxlgth' => '28000'
            },
            'NetperfTCP' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '64000',
              'receivemessagesize' => '32000',
              'localsendsocketsize' => '64000',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '64000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '64000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '32000'
            },
            'LROLengthEnable_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlromxlgth' => '8000'
            },
            'NetperfTCP_1' => {
              'Type' => 'Traffic',
              'remotereceivesocketsize' => '8000',
              'receivemessagesize' => '4000',
              'localsendsocketsize' => '8000',
              'dataintegritycheck' => 'Enable',
              'testduration' => '5',
              'portnumber' => '13000',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'supportadapter' => 'host.[2].vmknic.[1]',
              'localreceivesocketsize' => '8000',
              'toolname' => 'Netperf',
              'bursttype' => 'stream',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '8000,',
              'l4protocol' => 'TCP',
              'sendmessagesize' => '4000'
            },
            'LRODisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlro' => 'Disable'
            },
            'LROLengthDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'setlromxlgth' => '16000'
            }
          }
        },

        'ChangeVmknic' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'ChangeVmknic',
          'Summary' => 'Verify if PSOD happends while editing Vmknic, this is a' .
                       ' issue which can be triggered a bunch of commands. ' .
                       'see PR1089476',
          'ExpectedResult' => 'PASS',
          'Tags' => 'RCCA',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'vss' => {
                  '[1]' => {
                    'name' => 'Test_vSwitch',
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['AddPortGroup1'],
              ['AddVmkic1'],
              ['EditVmkic1'],
              ['AddPortGroup2'],
              ['AddVmkic2'],
              ['EditVmkic2_DHCP'],
              ['EditVmkic2_FIXED'],
              ['RemoveVmkic2'],
              ['CheckPSOD'],
              ['RemoveVmkic1'],
            ],
            'ExitSequence' => [
              ['RemovePortGroup1'],
              ['RemovePortGroup2'],
              ['CheckPSOD']
            ],

            'Iterations' => '1',
            'AddPortGroup1' => {
              'Type' => 'Command',
              'command' => 'esxcfg-vswitch',
              'args' => '-A testPG1 Test_vSwitch',
              'testhost' => 'host.[1]'
            },
            'AddVmkic1' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface add',
              'args' => '-p testPG1',
              'testhost' => 'host.[1]'
            },
            'EditVmkic1' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface ipv4 set',
              'args' => '-i vmk1 -I 192.168.1.1 -N 255.255.255.0 -t static',
              'testhost' => 'host.[1]'
            },
            'AddPortGroup2' => {
              'Type' => 'Command',
              'command' => 'esxcfg-vswitch',
              'args' => '-A testPG2 Test_vSwitch',
              'testhost' => 'host.[1]'
            },
            'AddVmkic2' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface add',
              'args' => '-p testPG2',
              'testhost' => 'host.[1]'
            },
            'EditVmkic2_DHCP' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface ipv4 set',
              'args' => '-i vmk2 -t dhcp',
              'testhost' => 'host.[1]'
            },
            'EditVmkic2_FIXED' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface ipv4 set',
              'args' => '-i vmk2 -I 192.168.1.1 -N 255.255.255.0 -t static',
              'testhost' => 'host.[1]',
              'ExpectedResult' => 'FAIL'
            },
            'RemoveVmkic2' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface remove',
              'args' => '-i vmk2',
              'testhost' => 'host.[1]'
            },
            'CheckPSOD' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'checkPSOD' => 'yes'
            },
            'RemoveVmkic1' => {
              'Type' => 'Command',
              'command' => 'esxcli network ip interface remove',
              'args' => '-i vmk1',
              'testhost' => 'host.[1]'
            },
            'RemovePortGroup1' => {
              'Type' => 'Command',
              'command' => 'esxcfg-vswitch',
              'args' => '-D testPG1 Test_vSwitch',
              'testhost' => 'host.[1]'
            },
            'RemovePortGroup2' => {
              'Type' => 'Command',
              'command' => 'esxcfg-vswitch',
              'args' => '-D testPG2 Test_vSwitch',
              'testhost' => 'host.[1]'
            },
          }
        },

        'IsolateSlaveInCluster' => {
         'Component' => 'VMKTCPIP',
         'Category' => 'ESX Server',
         'TestName'         => 'IsolateSlaveInCluster',
         'Summary'          => 'Based on PR1140226, PSOD happened if we isolate' .
                               ' slave host from cluster.',
         'ExpectedResult' => 'PASS',
         'Tags' => 'hostreboot, RCCA',
         'Version' => '2',
         'AutomationStatus' => 'Automated',

         TestbedSpec => {
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
               '[1]' => {
                  'vmnic' => {
                     '[1]' => {
                        'driver' => 'any'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                        'portgroup' => 'vc.[1].dvportgroup.[1]'
                     }
                  }
               },
               '[2]' => {
                  'vmnic' => {
                     '[1]' => {
                        'driver' => 'any'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                        'portgroup' => 'vc.[1].dvportgroup.[1]'
                     }
                  }
               }
            }
         },

         WORKLOADS => {
            Sequence => [['CreateCluster'],['MoveHostToCluster'],
                         ['RebootHost'],
                         ['MoveHostFromCluster'],['DeleteCluster'],
                         ['CheckPSOD']
                        ],

            "CreateCluster" => {
               Type => "Datacenter",
               TestDatacenter => "vc.[1].datacenter.[1]",
               Cluster => {
                  '[1]' => {
                     clustername => "cluster1",
                     ha => 1,
                     drs => 0,
                  },
               },
            },
            "MoveHostToCluster" => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
               MoveHostsToCluster => "host.[1-2]",
               sleepbetweenworkloads => 120
            },
            "RebootHost" => {
               Type     => "Host",
               TestHost => "host.[1-2]",
               Reboot   => "yes",
            },
            "MoveHostFromCluster" => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
               MoveHostsFromCluster => "host.[1-2]",
            },
            "DeleteCluster" => {
               Type => "Datacenter",
               TestDatacenter => "vc.[1].datacenter.[1]",
               deletecluster => "vc.[1].datacenter.[1].cluster.[1]",
            },
            'CheckPSOD' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'checkPSOD' => 'yes'
            },
         },
        },

        'DifferentRoute' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'DifferentRoute',
          'Summary' => 'RCCA for bug 1233887',
          'ExpectedResult' => 'PASS',
          'Tags' => '',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                  'vmnic' => {
                    '[1]' => {
                       'driver' => 'any'
                    }
                },
                'portgroup' => {
                  '[0]' => {
                    'vss' => 'host.[1].vss.[0]',
                  },
                  '[1]' => {
                    'vss' => 'host.[1].vss.[1]'
                  }
                },
                'vss' => {
                  '[0]' => {
                      'name' => 'vSwitch0'
                  },
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[1].vmnic.[1]'
                  }
                },
                'vmknic' => {
                  '[0]' => {
                    'portgroup' => 'host.[1].portgroup.[0]',
                    'interface' => 'vmk0'
                  },
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]'
                  }
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'SetVmknicIP'
              ],
              [
                'PingTraffic'
              ]
            ],
            'SetVmknicIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'dhcp',
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'ping',
              'testduration' => '10',
              'testadapter' => 'host.[1].vmknic.[0]',
              'supportadapter' => 'host.[1].vmknic.[1]',
              'verification' => "VerificationPing",
              'expectedresult' => 'FAIL'
            },
            'VerificationPing' => {
                'PktCapVerificaton' => {
                    'target' => 'host.[1].vmknic.[0]',
                    'pktcapfilter' => 'dst host host.[1].vmknic.[1]',
                    'verificationtype' => 'pktcap',
                    'pktcount' => '3+',
                }
            }
          }
        },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VMKTCPIP.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VMKTCPIP class.
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
   my $self = $class->SUPER::new(\%VMKTCPIP);
   return (bless($self, $class));
}
