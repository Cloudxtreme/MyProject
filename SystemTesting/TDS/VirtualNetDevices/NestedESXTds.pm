#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::VirtualNetDevices::NestedESXTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
use TDS::VirtualNetDevices::CommonWorkloads ':AllConstants';
{
%NestedESX = (
                'TSO' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'TSO',
                  'Summary' => 'Verify TSO works fine with minimum and max TCP/IP and ethernet header sizes',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'Functional',
                  'Version' => '2',
                  'ParentTDSID' => '167',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::NestedESX::TSO',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'ConfigureIP1'
                      ],
                      [
                        'EnableTSO'
                      ],
                      [
                        'SetMTU_VNIC'
                      ],
                      [
                        'SetMTU_VSS'
                      ],
#                      [
#                        'SetMTU_VMNIC'
#                      ],
                      [
                        'PING_TRAFFIC'
                      ],
                      [
                        'TRAFFIC_1'
                      ],
                      [
                        'TRAFFIC_2'
                      ],
                      [
                        'DisableTSO'
                      ],
                      [
                        'TCPTRAFFIC'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                   PING_TRAFFIC => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '2',
                      'testduration' => '20',
                      'toolname' => 'ping',
                      'noofinbound' => '2',
                      'L3Protocol'     => 'ipv4',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'supportadapter' => 'vm.[3].vnic.[1]',
                    },
                    'SetMTU_VNIC' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
                      'mtu' => '1500',
                    },
                    'SetMTU_VSS' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
                      'mtu' => '1500',
                    },
                    'EnableTSO' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tsoipv4',
                        'enable'       => 'true',
                      },
                    },
                    'DisableTSO' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tsoipv4',
                        'enable'       => 'false',
                      },
                    },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'ipv4' => '192.168.100.98'
                    },
                    'ConfigureIP1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'ipv4' => '192.168.100.99'
                    },
                    'TCPTRAFFIC' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '131072',
                      'toolname' => 'netperf',
                      'testduration' => '30',
                      'bursttype' => 'stream',
                      'maxtimeout' => '14400',
                      'remotesendsocketsize' => '131072',
                      'verification' => 'Stats',
                      'l4protocol' => 'tcp',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'sendmessagesize' => '16384,32444,48504,64564,80624,96684,112744,128804'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '131072',
                      'verification' => 'MaxMTU',
                      'testduration' => '60',
                      'remotesendsocketsize' => '131072',
                      'sendmessagesize' => '96684',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf',
                      'sleepbetweenworkloads' => '10',
                    },
                    'TRAFFIC_2' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '131072',
                      'verification' => 'MaxMTU1',
                      'testduration' => '60',
                      'remotesendsocketsize' => '131072',
                      'sendmessagesize' => '96684',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf',
                      'sleepbetweenworkloads' => '10',
                    },
                    'MaxMTU' => {
                      'Pktcap' => {
                        'pktcapfilter' => 'size > 1514',
                        'Target' => 'src',
                        'pktcount' => '2000+',
                        'verificationtype' => 'pktcap',
                        'maxpktsize' => '9000+'
                      },
                      'Vsish' => {
                        'Target' => 'src',
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '100+',
                        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '100+',
                        'verificationtype' => 'vsish'
                      }
                    },
                    'MaxMTU1' => {
                      'Pktcap' => {
                        'pktcapfilter' => 'size < 1800',
                        'Target' => 'dst',
                        'pktcount' => '2000+',
                        'verificationtype' => 'pktcap',
                      },
                      'Vsish' => {
                        'Target' => 'dst',
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '100+',
                        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '100+',
                        'verificationtype' => 'vsish'
                      }
                    },
                    'NetAdapter_1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
                      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                      'mtu' => '9000'
                    },
                    'PacketCap' => {
                      'PktCap' => {
                        'pktcapfilter' => "vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                        'Target' => 'src',
                        'badpkt' => '0',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },

                'CSO' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'CSOwithUDPTCPwithIPv4and6',
                  'Summary' => 'Verify CSO works fine with UDP/TCP IPv4 and IPv6 traffic.',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'LongDuration,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,' .
                            'CAT_LIN_VMXNET2,CAT_WIN_E1000E',
                  'Version' => '2',
                  'ParentTDSID' => '3.3',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::CSOwithUDPTCPwithIPv4and6',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        },
                      },
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
                          }
                        },
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'ConfigureIP1'
                      ],
                      [
                        'CSOEnableSUT_tx',
                        'CSOEnableSUT_rx'
                      ],
                      [
                        'CSODisableHelper_tx',
                        'CSODisableHelper_rx'
                      ],
                      [
                        'Traffic_Ping'
                      ],
                      [
                        'TRAFFICIPV4andIPV6'
                      ],
                      [
                        'CSOEnableHelper_tx',
                        'CSOEnableHelper_rx',
                      ],
                      [
                        'TRAFFICIPV4andIPV6ChecksumON'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'CSOEnableHelper_tx',
                        'CSOEnableHelper_rx',
                      ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'ipv4' => '192.168.100.98'
                    },
                    'ConfigureIP1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'ipv4' => '192.168.100.99'
                    },
                    'ConfigureIP_v6' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'ipv6' => '2001:DB8:2de::e10'
                    },
                    'ConfigureIP1_v6' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'ipv6' => '2001:DB8:2de::e11'
                    },
                   'Traffic_Ping' => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '2',
                      'testduration' => '20',
                      'toolname' => 'ping',
                      'noofinbound' => '2',
                      'L3Protocol'     => 'ipv4,ipv6',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'supportadapter' => 'vm.[3].vnic.[1]',
                    },
                    'CSOEnableSUT_tx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcptxchecksumipv4',
                        'enable'       => 'true',
                      },
                      'iterations' => '1'
                    },
                    'CSOEnableSUT_rx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcptxchecksumipv4',
                        'enable'       => 'true',
                      },
                      'sleepbetweenworkloads' => '60',
                      'iterations' => '1'
                    },
                    'CSODisableHelper_tx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcptxchecksumipv4',
                        'enable'       => 'false',
                      },
                      'iterations' => '1'
                    },
                    'CSODisableHelper_rx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcprxchecksumipv4',
                        'enable'       => 'false',
                      },
                      'sleepbetweenworkloads' => '60',
                      'iterations' => '1'
                    },
                    'TRAFFICIPV4andIPV6' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '64512',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream',
                      'noofoutbound' => '3',
                      'maxtimeout' => '32400',
                      'verification' => 'PktCap',
                      'l4protocol' => 'tcp,udp',
                      'l3protocol' => 'ipv4,ipv6',
                      'sendmessagesize' => '8192,16384,32768',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'noofinbound' => '3'
                    },
                    'CSOEnableHelper_tx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcprxchecksumipv4',
                        'enable'       => 'true',
                      },
                      'iterations' => '1'
                    },
                    'CSOEnableHelper_rx' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcprxchecksumipv4',
                        'enable'       => 'true',
                      },
                      'sleepbetweenworkloads' => '60',
                      'iterations' => '1'
                    },
                    'EnableSGHelper' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                         'offload_type' => 'sg',
                         'enable'       => 'true',
                      },
                    },
                    'EnableTSOHelper' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tsoipv4',
                        'enable'       => 'true',
                      },
                    },
                    'TRAFFICIPV4andIPV6ChecksumON' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '64512',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream',
                      'noofoutbound' => '3',
                      'maxtimeout' => '32400',
                      'verification' => 'PktCap',
                      'l4protocol' => 'tcp,udp',
                      'l3protocol' => 'ipv4,ipv6',
                      'sendmessagesize' => '8192,16384,32768',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'noofinbound' => '3'
                    }
                  }
                  }
                },

                'VLAN' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'TrafficTestOverVLANInterface',
                  'Summary' => 'Verify IO with VLAN insetting/getting VLAN ID on ' .
                               'DUT works fine',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'LongDuration,LIN_VMXNET3_BOTH',
                  'Version' => '2',
                  'ParentTDSID' => '97',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::TrafficTestOverVLANInterface',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
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
                            'portgroup' => 'host.[1].portgroup.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                #      [
                #        'DisableTSO'
                #      ],
                #      [
                #        'DisableCSO'
                #      ],
                      [
                        'Switch_Default_A'
                      ],
                      [
                        'Switch_Default_B'
                      ],
                      [
                        'EnablePromiscuous'
                      ],
                      [
                        'EnablePromiscuous2'
                      ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'ConfigureIP1'
                      ],
                 #     [ 'Traffic_vmk' ],
                      [
                        'Switch_SUT'
                      ],
                      [
                        'Switch_SUT1'
                      ],
                      [
                        'VLAN1500MTU'
                      ],
                      [
                        'EnableIPv6'
                      ],
                      [
                        'EnableIPv4'
                      ],
                      [
                        'TRAFFIC',
                      ],
#                      [
#                        'TRAFFIC'
#                      ]
                    ],
                    'ExitSequence' => [
                     [
                        'RemoveVLAN_SUT'
                     ],
                     [
                        'RemoveVLAN_HELPER'
                     ],
                      [
                        'Switch_Default_A'
                      ],
                      [
                        'Switch_Default_B'
                      ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],

                    ],

                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[2].vmknic.[1]',
                      'ipv4' => '192.168.100.100'
                    },
                    'ConfigureIP1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[1].vmknic.[1]',
                      'ipv4' => '192.168.100.101'
                    },
                    'DisableTSO' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tsoipv4',
                        'enable'       => 'false',
                      },
                    },
                    'DisableCSO' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
                      'configure_offload' =>{
                        'offload_type' => 'tcprxchecksumipv4',
                        'enable'       => 'false',
                      },
                      'sleepbetweenworkloads' => '20',
                      'iterations' => '1'
                    },

                    'Switch_SUT' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[1].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '4095'
                    },
                    'Switch_SUT1' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[2].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '4095'
                    },
                    'EnablePromiscuous' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                    },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                    'VLAN1500MTU' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
                      'vlaninterface' => {
                        '[1]' => {
                          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
                        },
                      },
                      'mtu' => '1500'
                    },
                    'EnableIPv6' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1].vlaninterface.[1],vm.[3].vnic.[1].vlaninterface.[1]',
                      'ipv6' => 'ADD',
                      'ipv6addr' => 'DEFAULT',
                      'iterations' => '1'
                    },
                    'EnableIPv4' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1].vlaninterface.[1],vm.[3].vnic.[1].vlaninterface.[1]',
                      'ipv4' => 'AUTO',
                      'iterations' => '1'
                    },
                    'TRAFFIC' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '64512',
                      'testduration' => '60',
                      'noofoutbound' => '3',
                      'noofinbound' => '3',
                      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]',
                      'toolname' => 'netperf',
                      'bursttype' => 'stream',
                      'testadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]',
                      'maxtimeout' => '75600',
                      'remotesendsocketsize' => '131072',
                      'verification' => 'PacketCap',
                      'l4protocol' => 'tcp,udp',
                      'l3protocol' => 'ipv4,ipv6',
#                      'sendmessagesize' => '1024,2048,4096,8192,16384,32768'
#                      'sendmessagesize' => '2048'
                    },
                   'Traffic_vmk' => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '2',
                      'testduration' => '30',
                      'toolname' => 'netperf',
                      'noofinbound' => '2',
                      'verification' => 'PacketCap',
                      'L3Protocol'     => 'ipv4',
                      'TestAdapter' => 'host.[2].vmknic.[1]',
                      'supportadapter' => 'host.[1].vmknic.[1]',
                    },

                    'RemoveVLAN_SUT' => {
                     'Type' => 'NetAdapter',
                     'TestAdapter' => 'vm.[3].vnic.[1]',
                     'deletevlaninterface' => 'vm.[3].vnic.[1].vlaninterface.[1]'
                    },
                    'RemoveVLAN_HELPER' => {
                     'Type' => 'NetAdapter',
                     'TestAdapter' => 'vm.[2].vnic.[1]',
                     'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
                    },
                    'Switch_Default_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[1].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '21'
                    },
                    'Switch_Default_B' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[2].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '21'                                                                                                                                                                                                         
                    },
                    'PacketCap' => {
                      'PktCap' => {
#                        'pktcapfilter' => "vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
                        'Target' => 'src',
                        'badpkt' => '0',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },

                'UDPRRSweep' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'UDPRRSweep',
                  'Summary' => 'Verify UDP RR traffic with message sizes 1byte to 4096 ' .
                               'bytes with default vNIC settings works fine.',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
                  'Version' => '2',
                  'ParentTDSID' => '87',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::UDPRRSweep',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'
                      ],
                      [
                        'ConfigureIP0'
                      ],
#                      [
#                        'ConfigureIP1'
#                      ],
                      [
                        'UDPTraffic'
                      ]

                    ],
                    'ExitSequence' => [
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                    'ConfigureIP0' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                    },

                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'ipv4' => '192.168.100.98'
                    },
                    'ConfigureIP1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'ipv4' => '192.168.100.99'
                    },
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },

                    'UDPTraffic' => {
                      'Type' => 'Traffic',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'responsesize' => '4096,1024',
                      'bursttype' => 'rr',
                      'noofoutbound' => '3',
                      'maxtimeout' => '201000',
                      'verification' => 'Traffic_UDP',
                      'l4protocol' => 'udp',
                      'noofinbound' => '3',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'requestsize' => '4096-1,128'
                    },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'Traffic_UDP' => {
                      'PktCap' => {
                        'Target' => 'src',
                        'badpkt' => '0',
                        'pktcount' => '1000+',
                        'retransmission' => '9-',
                        'verificationtype' => 'pktcap'
                      },
                      'Vsish' => {
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '10000+',
                        'Target' => 'src',
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '9-',
                        'verificationtype' => 'vsish'
                      }
                    }
                  }
                },

                'TCPRRSweep' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'TCPRRSweep',
                  'Summary' => 'Verify TCP RR traffic with message sizes 1byte to 4096' .
                               ' bytes with default vNIC settings works fine.',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
                  'Version' => '2',
                  'ParentTDSID' => '88',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::TCPRRSweep',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'
                      ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'TCPTraffic'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                    },
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'TCPTraffic' => {
                      'Type' => 'Traffic',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'responsesize' => '4096,1024',
                      'bursttype' => 'rr',
                      'noofoutbound' => '3',
                      'maxtimeout' => '81000',
                      'verification' => 'Traffic_TCP',
                      'l4protocol' => 'tcp',
                      'noofinbound' => '3',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'requestsize' => '4096-1,128'
                    },
                    'Traffic_TCP' => {
                      'PktCap' => {
                        'Target' => 'src',
                        'badpkt' => '0',
                        'pktcount' => '1000+',
                        'retransmission' => '5-',
                        'verificationtype' => 'pktcap'
                      },
                      'Vsish' => {
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '10000+',
                        'Target' => 'src',
                        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
                        'verificationtype' => 'vsish'
                      }
                    }
                  }
                },

                'IOWithSmallMsgSizes' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'IOWithSmallMsgSizes',
                  'Summary' => 'Verify IO with highly fragmented pkts does not result ' .
                               'in vNIC hang.',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
                  'Version' => '2',
                  'ParentTDSID' => '96',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOWithSmallMsgSizes',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'Traffic'
                      ],
                      [
                        'DisableEnablevNic'
                      ],
                      [
                        'TRAFFIC_1'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                    },
                    'Traffic' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '1024',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream',
                      'noofoutbound' => '1',
                      'expectedresult' => 'IGNORE',
                      'maxtimeout' => '108000',
                      'l4protocol' => 'tcp',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'sendmessagesize' => '500-1,20',
                      'noofinbound' => '1'
                    },
                    'DisableEnablevNic' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'devicestatus' => 'DOWN,UP'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'verification' => 'PacketCapture',
                      'testduration' => '60',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf'
                    },
                    'PacketCapture' => {
                      'Pktcap' => {
                        'Target' => 'src,dst',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },

                'JumboFrameOperations' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'JumboFrameOperations',
                  'Summary' => 'Tests JumboFrame ping acrossSuspend/Resume,sVLAN and gVLAN.',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'Functional',
                  'Version' => '2',
                  'Environment' => {
                    'NOOFMACHINES' => '2',
                    'Build' => 'NA',
                    'Platform' => 'ESX/ESXi',
                    'DriverVersion' => 'NA',
                    'GOS' => 'NA',
                    'Version' => 'NA',
                    'ToolsVersion' => 'NA',
                    'Driver' => 'Vmxnet3,Vmxnet2,e1000',
                    'Setup' => 'INTER/INTRA'
                  },
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::JumboFrameOperations',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'MTU9000'
                      ],
                      [
                        'Switch_1_B'
                      ],
                      [
                        'Switch_2_B'
                      ],
                      [
                        'Ping'
                      ],
                      [
                        'SuspendResume'
                      ],
                      [
                        'Ping'
                      ],
                      [
                        'Switch_1_A'
                      ],
                      [
                        'Switch_1_B'
                      ],
                      [
                        'Switch_2_A'
                      ],
                      [
                        'Switch_2_B'
                      ],
                      #[
                      #  'TRAFFIC_1'
                      #],
                      [
                        'Switch_3_A'
                      ],
                      [
                        'Switch_3_B'
                      ],
                      [
                        'Switch_4_A'
                      ],
                      [
                        'Switch_4_B'
                      ],
                      [
                        'NetAdapter_1'
                      ],
                      [
                        'TRAFFIC_2'
                      ]
                    ],
                    'ExitSequence' => [
#                      [
#                        'NetAdapter_2'
#                      ],
                      [
                        'Switch_5_A'
                      ],
                      [
                        'Switch_5_B'
                      ],
                      [
                        'Switch_6_A'
                      ],
                      [
                        'Switch_6_B'
                      ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'MTU9000' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'mtu' => '9000',
                      'ipv4' => 'AUTO'
                    },
                    'Ping' => {
                      'Type' => 'Traffic',
                      'pktfragmentation' => 'no',
                      'testduration' => '60',
                      'toolname' => 'ping',
                      'pingpktsize' => '8000',
                      'L3Protocol'     => 'ipv6,ipv4',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]'
                    },
                    'SuspendResume' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'vmstate' => 'suspend,resume'
                    },
                    'Switch_1_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[1].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                    },
                    'Switch_1_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'mtu' => '9000'
                    },
                    'Switch_2_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[2].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                    },
                    'Switch_2_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'mtu' => '9000'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'localsendsocketsize' => '131072',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream,rr',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'noofoutbound' => '3',
                      'remotesendsocketsize' => '131072',
                      'maxtimeout' => '14400',
                      'l4protocol' => 'tcp',
                      'sendmessagesize' => '63488-8192,15872',
                      'noofinbound' => '3',
                      'supportadapter' => 'vm.[2].vnic.[1]'
                    },
                    'Switch_3_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[1].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '4095'
                    },
                    'Switch_3_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'mtu' => '9000'
                    },
                    'Switch_4_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[2].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '4095'
                    },
                    'Switch_4_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'mtu' => '9000'
                    },
                    'NetAdapter_1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                      'mtu' => '9000'
                    },
                    'TRAFFIC_2' => {
                      'Type' => 'Traffic',
                      'receivemessagesize' => '9000',
                      'localsendsocketsize' => '131072',
                      'testduration' => '60',
                      'noofoutbound' => '2',
                      'noofinbound' => '2',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf',
                      'bursttype' => 'stream',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'maxtimeout' => '21600',
                      'remotesendsocketsize' => '131072',
                      'verification' => 'PacketCap',
                      'l4protocol' => 'tcp',
                      'sendmessagesize' => '1024,2048,4096,8000'
                    },
                    'NetAdapter_2' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'vlan' => '0',
                      'mtu' => '1500'
                    },
                    'Switch_5_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[1].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '0'
                    },
                    'Switch_5_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'mtu' => '1500'
                    },
                    'Switch_6_A' => {
                      'Type' => 'PortGroup',
                      'TestPortGroup' => 'host.[2].portgroup.[1]',
                      'vlantype' => 'access',
                      'vlan' => '0'
                    },
                    'Switch_6_B' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'mtu' => '1500'
                    },
                    'PacketCap' => {
                      'PktCap' => {
                      #  'pktcapfilter' => "vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                        'Target' => 'src',
                        'badpkt' => '0',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },

                'LinkStateCheckwithPGChange' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'LinkStateCheckwithPGChange',
                  'Summary' => 'Verify link state is persistent across port group changes.',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,' .
                            'CAT_LIN_VMXNET2,CAT_LIN_E1000,LIN_VMXNET3_BOTH',
                  'Version' => '2',
                  'Environment' => {
                    'NOOFMACHINES' => '2',
                    'Build' => 'NA',
                    'Platform' => 'ESX/ESXi',
                    'DriverVersion' => 'NA',
                    'GOS' => 'NA',
                    'Version' => 'NA',
                    'ToolsVersion' => 'NA',
                    'Driver' => 'Vmxnet3,Vmxnet2,e1000',
                    'Setup' => 'INTER/INTRA'
                  },
                  'ParentTDSID' => '3.4',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::LinkStateCheckwithPGChange',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'TRAFFIC'
                      ],
                      [
                        'AddVssPortgroup1'
                      ],
                      [
                        'AddVssPortgroup2'
                      ],
                      [
                        'ChangePortgroup1'
                      ],
                      [
                        'ChangePortgroup1_2'
                      ],
                      [
                        'TRAFFIC'
                      ],
                      [
                        'DisconnectvNIC'
                      ],
                      [
                        'ChangePortgroup2'
                      ],
                      [
                        'ChangePortgroup2_2'
                      ],
                      [
                        'TRAFFIC_1'
                      ],
                      [
                        'ConnectvNIC'
                      ],
                      [
                        'TRAFFIC'
                      ],
                    ],
                    'ExitSequence' => [
                      [
                        'ConnectvNIC',
                      ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                      
                    ],
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                    },
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'TRAFFIC' => {
                      'Type' => 'Traffic',
                      'verification' => 'PacketCapture',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'testduration' => '60',
                      'toolname' => 'netperf'
                    },
                    'AddVssPortgroup2' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[2]',
                      'portgroup' => {
                        '[2]' => {
                          'vss' => 'host.[2].vss.[1]',
                        }
                      }
                    },
                    'AddVssPortgroup1' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'portgroup' => {
                        '[2]' => {
                          'vss' => 'host.[1].vss.[1]',                                                                                                                                                                                       
                        }
                      }
                    },
                    'ChangePortgroup1' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'portgroup' => 'host.[2].portgroup.[2]',
                      'reconfigure' => 'true'
                    },
                    'ChangePortgroup1_2' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[2].vnic.[1]',
                      'portgroup' => 'host.[1].portgroup.[2]',
                      'reconfigure' => 'true'
                    },
                    'DisconnectvNIC' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'connected' => '0',
                      'reconfigure' => 'true'
                    },
                    'ChangePortgroup2' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'portgroup' => 'host.[2].portgroup.[1]',
                      'reconfigure' => 'true'
                    },
                    'ChangePortgroup2_2' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[2].vnic.[1]',
                      'portgroup' => 'host.[1].portgroup.[1]',
                      'reconfigure' => 'true'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'expectedresult' => 'FAIL',
                      'toolname' => 'ping',
                      'noofinbound' => '1',
                      'testadapter' => 'vm.[2].vnic.[1]',
                      'supportadapter' => 'vm.[3].vnic.[1]'
                    },
                    'ConnectvNIC' => {
                      'Type' => 'NetAdapter',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'connected' => '1',
                      'reconfigure' => 'true'
                    },
                    'PacketCapture' => {
                      'Pktcap' => {
                   #     'pktcapfilter' => 'count 1500',
                        'Target' => 'src',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },


                'HWUPDOWNMultipletimes' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'HWUPDOWNMultipletimes',
                  'Summary' => 'Verify disabling/enabling the device multiple times ' .
                               'doesn\'t crash/wedge',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'Stress,CAT_LIN_VMXNET2,CAT_WIN_E1000E,CAT_LIN_E1000,' .
                            'CAT_WIN_E1000,CAT_WIN_VMXNET2,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
                  'Version' => '2',
                  'ParentTDSID' => '3.3',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::HWUPDOWNMultipletimes',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      [
                        'DisableEnablevNic'
                      ],
                      [
                        'ConfigureIP'
                      ],
                      [
                        'TRAFFIC_1'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'EnablevNIC'
                      ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                    ],
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'DisableEnablevNic' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[2].vmnic.[1]',
                      'maxtimeout' => '16200',
                      'devicestatus' => 'down,up',
                      'sleepbetweencombos' => '10',
                      'iterations' => '25'
                    },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'verification' => 'PacketCapture',
                      'testduration' => '60',
                      'sleepbetweencombos' => '60',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf'
                    },
                    'EnablevNIC' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[2].vmnic.[1]',
                      'devicestatus' => 'up'
                    },
                    'PacketCapture' => {
                      'Pktcap' => {
                  #      'pktcapfilter' => 'count 1500',
                        'Target' => 'src',
                        'pktcount' => '1000+',
                        'verificationtype' => 'pktcap'
                      }
                    }
                  }
                },

                'KillVMXWhileIO' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'KillVMXWhileIO',
                  'Summary' => 'Verify host doesn\'t PSOD when vmx is killed from host' .
                               ' while IO over guest vNIC',
                  'ExpectedResult' => 'PASS',
                  'AutomationStatus'  => 'Automated',
                  'Tags' => 'Functional,CAT_LIN_E1000,CAT_LIN_VMXNET2,CAT_WIN_E1000,' .
                            'CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BOTH',
                  'Version' => '2',
                  'ParentTDSID' => '157',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::KillVMXWhileIO',
                  'TestbedSpec' => {
                    'vm' => {
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[3]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                   #         'driver' => 'e1000'
                          }
                        },
                        'host' => 'host.[2]'
                      },
                    },
                    'host' => {
                      '[1]' => {
                        'portgroup' => {
                          '[1]' => {
                            'vss' => 'host.[1].vss.[1]'
                          }
                        },
                        'vmnic' => {
                          '[1]' => {
                          }
                        },
                        'vss' => {
                          '[1]' => {
                            'configureuplinks' => 'add',
                            'vmnicadapter' => 'host.[1].vmnic.[1]'
                          }
                        }
                      },
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
                          }
                        },
                        'vmknic' => {
                          '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]'
                          }
                        }
                       }
                      }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'EnablePromiscuous1'
                      ],
                      [
                        'EnablePromiscuous2'                                                                                                                                                                                                                       ],
                      ['ConfigureIP'],
                      [
                        'TRAFFIC',
                        'KillVM',
                      ],
                      [
                        'PowerOnAfterKill'
                      ],
                      [
                        'TRAFFIC_1'
                      ]
                    ],
                    'ExitSequence' => [
                    #  [
                    #    'PowerOn'
                    #  ],
                      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                   ],
                   'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1],vm.[2].vnic.[1]',
                      'ipv4' => 'AUTO'
                   },
                   'EnablePromiscuous1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'setpromiscuous' => 'Enable'
                   },
                   'EnablePromiscuous2' => {                                                                                                                                                                                                                       'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',                                                                                                                                                                                                          'setpromiscuous' => 'Enable',
                      'sleepbetweenworkloads' => '40',
                   },
                   'RemoveUplink' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[2].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[2].vmnic.[1]'
                   },
                   'RemoveUplink1' => {
                      'Type' => 'Switch',
                      'TestSwitch' => 'host.[1].vss.[1]',
                      'configureuplinks' => 'remove',
                      'vmnicadapter' => 'host.[1].vmnic.[1]'
                   },
                    'TRAFFIC' => {
                      'Type' => 'Traffic',
                      'toolname' => 'netperf',
                      'testduration' => '900',
                      'bursttype' => 'stream',
                      'testadapter' => 'vm.[2].vnic.[1]',
                      'noofoutbound' => '3',
                      'expectedresult' => 'IGNORE',
                      'l4protocol' => 'udp',
                      'noofinbound' => '3',
                      'supportadapter' => 'vm.[3].vnic.[1]'
                    },
                    'KillVM' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'sleepbetweenworkloads' => '360',
                      'iterations' => '1',
                      'operation' => 'killvm'
                    },
                    'PowerOnAfterKill' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'iterations' => '1',
                      'vmstate' => 'poweron'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'verification' => 'PktCap',
                      'testduration' => '60',
                      'testadapter' => 'vm.[3].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'toolname' => 'netperf'
                    },
                    'PowerOn' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'iterations' => '1',
                      'vmstate' => 'poweron'
                    }
                  }
                },


   );
} # End of ISA.



#######################################################################
#
# new --
#       This is the constructor for VDCommon.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDCommon class.
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
   my $self = $class->SUPER::new(\%NestedESX);
   if ($self eq FAILURE) {
      print "error ". VDGetLastError() ."\n";
      VDSetLastError(VDGetLastError());
   }
   return (bless($self, $class));
}

1;


