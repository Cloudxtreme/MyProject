#!/usr/bin/perl
#########################################################################
#Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FPT::FPTTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %FPT = (
      'MemoryOverCommit' => {
         'Component' => 'network NPA/UPT/SRIOV',
         'Category' => 'ESX Server',
         'TestName' => 'MemoryOverCommit',
         'Summary' => 'Verify adding maximum memoryWould not poweron the FPT vm',
         'ExpectedResult' => 'PASS',
         'Tags' => 'rpmt,bqmt,physicalonly',
         'Version' => '2',
         'TestbedSpec' => {
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1]' => {
                    'speed' => '10G',
                    'driver' => 'any'
                  }
                },
                'vss' => {
                  '[1]' => {
                     'vmnicadapter'     => "host.[2].vmnic.[1]",
                     'configureuplinks' => "add",
                  }
                },
                'portgroup' => {
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'speed' => '10G',
                    'driver' => 'ixgbe',
                    'passthrough' => {
                       'type' => "fpt"
                    },
                  }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'pcipassthru' => {
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]',
                    'driver' => "fpt"
                  }
                },
                'reservememory' => 'max',
                'vmstate' => 'poweroff',
                'host' => 'host.[1]'
              }
            }
         },
         'WORKLOADS' => {
           'Sequence' => [
             [
               'PoweroffVM'
             ],
             [
               'Snapshot'
             ],
             [
               'MemoryOverCommitVM'
             ],
             [
               'PoweronVM'
             ],
             [
               'RevertSnapshot'
             ],
             [
               'PoweronVMafterRevertSnapshot'
             ],
             [
               'TCPTraffic'
             ]
           ],
           'ExitSequence' => [
             [
               'HotRemoveVnic'
             ]
           ],
           'PoweroffVM' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'iterations' => '1',
             'vmstate' => 'poweroff'
           },
           'Snapshot' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'snapshotname' => 'fptNeg1',
             'iterations' => '1',
             'operation' => 'createsnap'
           },
           'MemoryOverCommitVM' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'iterations' => '1',
             'operation' => 'memoryovercommit'
           },
           'PoweronVM' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'expectedresult' => 'FAIL',
             'iterations' => '1',
             'vmstate' => 'poweron'
           },
           'RevertSnapshot' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'snapshotname' => 'fptNeg1',
             'iterations' => '1',
             'operation' => 'revertsnap',
             'waitforvdnet' => '0'
           },
           'PoweronVMafterRevertSnapshot' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[1]',
             'iterations' => '1',
             'vmstate' => 'poweron'
           },
           'TCPTraffic' => {
             'Type' => 'Traffic',
             'toolname' => 'netperf',
             'testduration' => '60',
             'testadapter' => 'vm.[1].pcipassthru.[1]',
             'noofoutbound' => '1',
             'verification' => 'Verification_1',
             'l4protocol' => 'tcp',
             'l3protocol' => 'ipv4,ipv6',
             'noofinbound' => '1',
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'HotRemoveVnic' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[2]',
             'deletevnic' => 'vm.[2].vnic.[1]'
           },
           'Verification_1' => {
             'PktCapVerificaton' => {
               'target' => 'dstvm',
               'badpkt' => '0',
               'pktcount' => '1400+',
               'pktcapfilter' => 'count 1500',
               'verificationtype' => 'pktcap'
             }
           }
         }
      },


      'JumboFrames' => {
        'Component' => 'network NPA/UPT/SRIOV',
        'Category' => 'ESX Server',
        'TestName' => 'JumboFrames',
        'Summary' => 'Verify network performance with JF enabled inside FPT VM',
        'ExpectedResult' => 'PASS',
        'Tags' => 'rpmt,bqmt,physicalonly',
        'Version' => '2',
        'TestbedSpec' => {
          'host' => {
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'any'
                }
              },
              'vss' => {
                '[1]' => {
                   'vmnicadapter'     => "host.[2].vmnic.[1]",
                   'configureuplinks' => "add",
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'ixgbe',
                  'passthrough' => {
                     'type' => "fpt"
                  },
                }
              }
            }
          },
          'vm' => {
            '[2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2]'
            },
            '[1]' => {
              'pcipassthru' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]',
                  'driver' => "fpt",
                }
              },
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            }
          }
        },
         'WORKLOADS' => {
           'Sequence' => [
             [
               'PoweronVM'
             ],
             [
               'BasicTraffic'
             ],
             [
               'SwitchJF'
             ],
             [
               'EnableNetAdapterJF'
             ],
             [
               'TCPTraffic'
             ],
             [
               'DisableSwitchJF'
             ],
             [
               'DisableNetAdapterJF'
             ]
           ],
           'Iterations' => '1',
           'PoweronVM' => {
              'Type'    => "VM",
              'TestVM'  => "vm.[1]",
              'vmstate' => "poweron",
           },
           'BasicTraffic' => {
             'Type' => 'Traffic',
             'noofoutbound' => '1',
             'l4protocol' => 'tcp',
             'l3protocol' => 'ipv4,ipv6',
             'toolname' => 'netperf',
             'noofinbound' => '1',
             'testadapter' => 'vm.[1].pcipassthru.[1]',
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'SwitchJF' => {
             'Type' => 'Switch',
             'TestSwitch' => 'host.[2].vss.[1]',
             'testadapter' => 'vm.[2].vnic.[1]',
             'mtu' => '9000'
           },
           'EnableNetAdapterJF' => {
             'Type' => 'NetAdapter',
             'TestAdapter' => 'vm.[1].pcipassthru.[1],vm.[2].vnic.[1]',
             'mtu' => '9000'
           },
           'TCPTraffic' => {
             'Type' => 'Traffic',
             'localsendsocketsize' => '131072',
             'toolname' => 'netperf',
             'testduration' => '60',
             'testadapter' => 'vm.[1].pcipassthru.[1]',
             'noofoutbound' => '1',
             'remotesendsocketsize' => '131072',
             'maxtimeout' => '5000',
             'verification' => 'Verification_1',
             'l4protocol' => 'tcp,udp',
             'l3protocol' => 'ipv4,ipv6',
             'sendmessagesize' => '2048,32768,64512',
             'noofinbound' => '1',
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'DisableSwitchJF' => {
             'Type' => 'Switch',
             'TestSwitch' => 'host.[2].vss.[1]',
             'testadapter' => 'vm.[2].vnic.[1]',
             'mtu' => '1500'
           },
           'DisableNetAdapterJF' => {
             'Type' => 'NetAdapter',
             'TestAdapter' => 'vm.[1].pcipassthru.[1],vm.[2].vnic.[1]',
             'mtu' => '1500'
           },
           'Verification_1' => {
             'PktCapVerificaton' => {
               'target' => 'srcvm',
               'badpkt' => '0',
               'pktcount' => '1400+',
               'pktcapfilter' => 'count 1500,size > 1500',
               'verificationtype' => 'pktcap'
             }
           }
         }
      },


      'VMOPs' => {
        'Component' => 'network NPA/UPT/SRIOV',
        'Category' => 'ESX Server',
        'TestName' => 'VMOPs',
        'Summary' => 'This test case verifies operations on a VM that has FPT ' .
                     'pci passthru device ',
        'ExpectedResult' => 'PASS',
        'Tags' => 'physicalonly',
        'Version' => '2',
        'TestbedSpec' => {
          'host' => {
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'any'
                }
              },
              'vss' => {
                '[1]' => {
                   'vmnicadapter'     => "host.[2].vmnic.[1]",
                   'configureuplinks' => "add",
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                   'driver' => "ixgbe",
                   'passthrough' => {
                      'type' => "fpt"
                   },
                }
              },
            }
          },
          'vm' => {
            '[2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2]'
            },
            '[1]' => {
              'pcipassthru' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]',
                  'driver' => "fpt",
                }
              },
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            [
              'PoweronVM'
            ],
            [
              'Suspend'
            ],
            [
              'Snapshot'
            ],
            [
              'TCPTraffic'
            ],
            [
              'ResetVM'
            ],
            [
              'WaitForVDNet'
            ],
            [
              'TCPTraffic'
            ],
            [
              'RebootVM'
            ],
            [
              'TCPTraffic'
            ],
            [
              'ResetPCI'
            ],
            [
              'TCPTraffic'
            ],
            [
              'DriverReload'
            ],
            [
              'TCPTraffic'
            ]
          ],
          'PoweronVM' => {
             'Type'    => "VM",
             'TestVM'  => "vm.[1]",
             'vmstate' => "poweron",
          },
          'Suspend' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'expectedresult' => 'FAIL',
            'iterations' => '1',
            'vmstate' => 'suspend'
          },
          'Snapshot' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'expectedresult' => 'FAIL',
            'snapshotname' => 'fptNeg',
            'iterations' => '1',
            'operation' => 'createsnap'
          },
          'TCPTraffic' => {
            'Type' => 'Traffic',
            'toolname' => 'netperf',
            'testduration' => '60',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'noofoutbound' => '1',
            'verification' => 'Verification_1',
            'l4protocol' => 'tcp',
            'l3protocol' => 'ipv4,ipv6',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'ResetVM' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'iterations' => '10',
            'operation' => 'reset',
            'waitforvdnet' => 0
          },
          'WaitForVDNet' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'operation' => 'waitforvdnet'
          },
          'RebootVM' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'iterations' => '1',
            'operation' => 'reboot',
            'waitforvdnet' => 1
          },
          'ResetPCI' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].pcipassthru.[1]',
            'devicestatus' => 'DOWN,UP',
            'iterations' => '20'
          },
          'DriverReload' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].pcipassthru.[1]',
            'reload_driver' => 'true',
            'iterations' => '5'
          },
          'Verification_1' => {
            'PktCapVerificaton' => {
              'target' => 'dstvm',
              'badpkt' => '0',
              'pktcount' => '1400+',
              'pktcapfilter' => 'count 1500',
              'verificationtype' => 'pktcap'
            }
          }
        }
      },


      'AddPCI' => {
        'Component' => 'network NPA/UPT/SRIOV',
        'Category' => 'ESX Server',
        'TestName' => 'AddPCI',
        'Summary' => 'Put device in passthrough mode on host and add the ' .
                     'passthru device to FPT VM',
        'ExpectedResult' => 'PASS',
        'Tags' => 'physicalonly,CAT_P0',
        'Version' => '2',
        'TestbedSpec' => {
          'host' => {
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'any'
                }
              },
              'vss' => {
                '[1]' => {
                   'vmnicadapter'     => "host.[2].vmnic.[1]",
                   'configureuplinks' => "add",
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'ixgbe',
                  'passthrough' => {
                     'type' => "fpt"
                  },
                }
              },
            }
          },
          'vm' => {
            '[2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2]'
            },
            '[1]' => {
              'pcipassthru' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]',
                  'driver' => 'fpt'
                }
              },
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            [
              'PoweronVM'
            ],
            [
              'ConfigureIP'
            ],
            [
              'BroadcastTraffic'
            ],
            [
              'MulticastTraffic'
            ],
            [
              'PingFlood'
            ],
            [
              'TCPTraffic'
            ],
            [
              'UDPTraffic'
            ]
          ],
          'PoweronVM' => {
             'Type'    => "VM",
             'TestVM'  => "vm.[1]",
             'vmstate' => "poweron",
          },
          'ConfigureIP' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].pcipassthru.[1],vm.[2].vnic.[1]',
            'ipv4' => 'AUTO'
          },
          'BroadcastTraffic' => {
            'Type' => 'Traffic',
            'testduration' => '60',
            'toolname' => 'ping',
            'noofinbound' => '1',
            'routingscheme' => 'broadcast',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'MulticastTraffic' => {
            'Type' => 'Traffic',
            'toolname' => 'Iperf',
            'testduration' => '60',
            'routingscheme' => 'multicast',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'noofoutbound' => '1',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'PingFlood' => {
            'Type' => 'Traffic',
            'connectivitytest' => '0',
            'toolname' => 'ping',
            'testduration' => '60',
            'routingscheme' => 'flood',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'l3protocol' => 'ipv4',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'TCPTraffic' => {
            'Type' => 'Traffic',
            'localsendsocketsize' => '131072',
            'toolname' => 'netperf',
            'testduration' => '60',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'noofoutbound' => '1',
            'remotesendsocketsize' => '131072',
            'maxtimeout' => '5000',
            'verification' => 'Verification_1',
            'l4protocol' => 'tcp',
            'l3protocol' => 'ipv4,ipv6',
            'sendmessagesize' => '1,2048,32768,64512',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'UDPTraffic' => {
            'Type' => 'Traffic',
            'localsendsocketsize' => '131072',
            'toolname' => 'netperf',
            'testduration' => '20',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'noofoutbound' => '1',
            'remotesendsocketsize' => '131072',
            'maxtimeout' => '5000',
            'minexpresult' => 'IGNORE',
            'verification' => 'Verification_1',
            'l4protocol' => 'UDP',
            'l3protocol' => 'ipv4,ipv6',
            'sendmessagesize' => '17,2048,32768,64512',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'Verification_1' => {
            'PktCapVerificaton' => {
              'target' => 'dstvm',
              'badpkt' => '0',
              'pktcount' => '1400+',
              'pktcapfilter' => 'count 1500',
              'verificationtype' => 'pktcap'
            }
          }
        }
      },


      'SamePCIID' => {
        'Component' => 'network NPA/UPT/SRIOV',
        'Category' => 'ESX Server',
        'TestName' => 'SamePCIID',
        'Summary' => 'Verify addig same PCIID fails in FPT VM',
        'ExpectedResult' => undef,
        'Tags' => 'bqmt,physicalonly',
        'Version' => '2',
        'TestbedSpec' => {
          'host' => {
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'any'
                }
              },
              'vss' => {
                '[1]' => {
                   'vmnicadapter'     => "host.[2].vmnic.[1]",
                   'configureuplinks' => "add",
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'ixgbe',
                  'passthrough' => {
                     'type' => "fpt"
                  },
                },
              },
            }
          },
          'vm' => {
            '[2]' => {
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            },
            '[3]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2]'
            },
            '[1]' => {
              'pcipassthru' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]',
                  'driver' => 'fpt'
                }
              },
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            [
              'PoweronVM'
            ],
            [
              'SameHostTraffic'
            ],
            [
              'PoweroffHelper1'
            ],
            [
              'AddPassthrutoVM'
            ],
            [
              'PoweronHelper1Neg'
            ],
            [
              'PoweroffSUT'
            ],
            [
              'PoweronHelper1Pos'
            ],
            [
              'DifferentHostTraffic'
            ]
          ],
          'PoweronVM' => {
             'Type'    => "VM",
             'TestVM'  => "vm.[1]",
             'vmstate' => "poweron",
          },
          'SameHostTraffic' => {
            'Type' => 'Traffic',
            'verification' => 'Verification_1',
            'testduration' => '60',
            'l3protocol' => 'ipv4,ipv6',
            'toolname' => 'netperf',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'supportadapter' => 'vm.[3].vnic.[1]'
          },
          'PoweroffHelper1' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[2]',
            'vmstate' => 'poweroff'
          },
          'AddPassthrutoVM' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[2]',
            'pcipassthru' => {
              '[1]' => {
                'vmnic' => 'host.[1].vmnic.[1]',
                'driver' => 'fpt'
              }
            }
          },
          'PoweronHelper1Neg' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[2]',
            'expectedresult' => 'FAIL',
            'vmstate' => 'poweron'
          },
          'PoweroffSUT' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'vmstate' => 'poweroff'
          },
          'PoweronHelper1Pos' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[2]',
            'vmstate' => 'poweron'
          },
          'DifferentHostTraffic' => {
            'Type' => 'Traffic',
            'verification' => 'Verification_1',
            'testduration' => '60',
            'l3protocol' => 'ipv4,ipv6',
            'toolname' => 'netperf',
            'testadapter' => 'vm.[2].pcipassthru.[1]',
            'supportadapter' => 'vm.[3].vnic.[1]'
          },
          'Verification_1' => {
            'PktCapVerificaton' => {
              'target' => 'dstvm',
              'badpkt' => '0',
              'pktcount' => '1400+',
              'pktcapfilter' => 'count 1500',
              'verificationtype' => 'pktcap'
            }
          }
        }
      },


      'GuestVLAN' => {
        'Component' => 'network NPA/UPT/SRIOV',
        'Category' => 'ESX Server',
        'TestName' => 'GuestVLAN',
        'Summary' => 'Verify Guest vlantagging in FPT VM',
        'ExpectedResult' => 'PASS',
        'Tags' => 'rpmt,bqmt,physicalonly',
        'Version' => '2',
        'TestbedSpec' => {
          'host' => {
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'any'
                }
              },
              'vss' => {
                '[1]' => {
                   'vmnicadapter'     => "host.[2].vmnic.[1]",
                   'configureuplinks' => "add",
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                  'speed' => '10G',
                  'driver' => 'ixgbe',
                  'passthrough' => {
                     'type' => "fpt"
                  },
                }
              }
            }
          },
          'vm' => {
            '[2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2]'
            },
            '[1]' => {
              'pcipassthru' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]',
                  'driver' => 'fpt'
                }
              },
              'vmstate' => 'poweroff',
              'host' => 'host.[1]'
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            [
              'PoweronVM'
            ],
            [
              'SwitchVlan'
            ],
            [
              'SUTPCIVLAN'
            ],
            [
              'HelperVnicVLAN'
            ],
            [
              'Traffic'
            ],
            [
              'SwitchVlanDisable'
            ],
            [
              'VnicVLANDisable'
            ],
            [
              'PCIVLANDisable'
            ]
          ],
          'PoweronVM' => {
             'Type'    => "VM",
             'TestVM'  => "vm.[1]",
             'vmstate' => "poweron",
          },
          'SwitchVlan' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'host.[2].portgroup.[1]',
            'vlantype' => 'access',
            'vlan' => '4095'
          },
          'SUTPCIVLAN' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].pcipassthru.[1]',
            'vlan' => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B
          },
          'HelperVnicVLAN' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[2].vnic.[1]',
            'vlan' => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B
          },
          'Traffic' => {
            'Type' => 'Traffic',
            'toolname' => 'netperf',
            'testduration' => '60',
            'testadapter' => 'vm.[1].pcipassthru.[1]',
            'noofoutbound' => '1',
            'verification' => 'Verification_1',
            'l4protocol' => 'tcp,udp',
            'l3protocol' => 'ipv4,ipv6',
            'noofinbound' => '1',
            'supportadapter' => 'vm.[2].vnic.[1]'
          },
          'SwitchVlanDisable' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'host.[2].portgroup.[1]',
            'vlantype' => 'access',
            'vlan' => '0'
          },
          'VnicVLANDisable' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[2].vnic.[1]',
            'vlan' => '0'
          },
          'PCIVLANDisable' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].pcipassthru.[1]',
            'vlan' => '0'
          },
          'Verification_1' => {
            'PktCapVerificaton' => {
              'target' => 'dstvm',
              'badpkt' => '0',
              'pktcount' => '1400+',
              'pktcapfilter' => 'count 1500',
              'verificationtype' => 'pktcap'
            }
          }
        }
      },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for FPT.
#
# Input:
#       None.
#
# Results:
#       An instance/object of FPT class.
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
   my $self = $class->SUPER::new(\%FPT);
   return (bless($self, $class));
}
