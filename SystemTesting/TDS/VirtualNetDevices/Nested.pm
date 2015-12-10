#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::VirtualNetDevices::VDCommonTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
use TDS::VirtualNetDevices::CommonWorkloads ':AllConstants';
{
%VDCommon = (
                'TCPUDPTraffic' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'TCPUDPTraffic',
                  'Summary' => 'This test verifies TCP/UDP Traffic stressing both inbound and outbound paths.',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'LongDuration,BAT,batnovc,LIN_VMXNET3_BOTH',
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
                  'ParentTDSID' => '7.1',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::TCPUDPTraffic',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      }
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
                            'driver' => 'any'
                          }
                        },
                        'vss' => {
                          '[1]' => {}
                        }
                      }
                    }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'TCPTraffic'
                      ],
                      [
                        'UDPTraffic'
                      ]
                    ],
                    'TCPTraffic' => {
                      'Type' => 'Traffic',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'localsendsocketsize' => '131072',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream',
                      'noofoutbound' => '2',
                      'maxtimeout' => '8100',
                      'remotesendsocketsize' => '131072',
                      'verification' => 'PktCap',
                      'sendmessagesize' => '131072-16384,16384',
                      'noofinbound' => '3'
                    },
                    'UDPTraffic' => {
                      'Type' => 'Traffic',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
                      'localsendsocketsize' => '131072',
                      'toolname' => 'netperf',
                      'testduration' => '60',
                      'bursttype' => 'stream',
                      'noofoutbound' => '2',
                      'expectedresult' => 'IGNORE',
                      'remotesendsocketsize' => '131072',
                      'maxtimeout' => '8100',
                      'verification' => 'PktCap',
                      'l4protocol' => 'udp',
                      'sendmessagesize' => '63488-8192,15872',
                      'noofinbound' => '3'
                    }
                  }
                },


                'HotAddvNIC' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'HotAddvNIC',
                  'Summary' => 'Tests connectivity after Power On/Off',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'Functional,BAT,batnovc,LIN_VMXNET3_BOTH',
                  'Version' => '2',
                  'Environment' => {
                    'NOOFMACHINES' => '2',
                    'Build' => 'NA',
                    'Platform' => 'ESX/ESXi',
                    'DriverVersion' => 'NA',
                    'GOS' => 'NA',
                    'Version' => 'NA',
                    'ToolsVersion' => 'NA',
                    'Driver' => 'vmxnet3',
                    'Setup' => 'INTER/INTRA'
                  },
                  'ParentTDSID' => '5.18',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::HotAddvNIC',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
			},
                        'host' => 'host.[1]'
                      },
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      }
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
                            'driver' => 'any'
                          }
                        },
                        'vss' => {
                          '[1]' => {}
                        }
                      }
                    }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'TRAFFIC_1'
                      ],
                      [
                        'HotAdd_vmxnet3'
                      ],
                      [
                        'TRAFFIC_2'
                      ],
                      [
                        'HotRemove'
                      ],
                      [
                        'HotAdd_e1000'
                      ],
                      [
                        'TRAFFIC_2'
                      ],
                      [
                        'HotRemove'
                      ],
                      [
                        'HotAdd_e1000e'
                      ],
                      [
                        'TRAFFIC_2'
                      ],
                    ],
                    'ExitSequence' => [
                      [
                        'HotRemove'
                      ]
                    ],
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '1',
                      'testduration' => '20',
                      'toolname' => 'netperf',
                      'noofinbound' => '1',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]'
                    },
                    'HotAdd_vmxnet3' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vnic' => {
                        '[2]' => {
                          'portgroup' => 'host.[1].portgroup.[1]',
                          'driver' => 'vmxnet3'
                        }
                      }
                    },
                    'HotAdd_e1000' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vnic' => {
                        '[2]' => {
                          'portgroup' => 'host.[1].portgroup.[1]',
                          'driver' => 'e1000'
                        }
                      }
                    },
                    'HotAdd_e1000e' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vnic' => {
                        '[2]' => {
                          'portgroup' => 'host.[1].portgroup.[1]',
                          'driver' => 'e1000e'
                        }
                      }
                    },
                    'TRAFFIC_2' => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '1',
                      'testduration' => '20',
                      'toolname' => 'netperf',
                      'noofinbound' => '1',
                      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
                      'supportadapter' => 'vm.[2].vnic.[1]'
                    },
                    'HotRemove' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'deletevnic' => 'vm.[1].vnic.[2]'
                    }
                  }
                },


                'SuspendResume' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'SuspendResume',
                  'Summary' => 'Test connectivity after Suspend/Resume',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'Functional,BAT,batnovc,LIN_VMXNET3_BOTH',
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
                  'ParentTDSID' => '5.5',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::SuspendResume',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      }
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
                            'driver' => 'any'
                          }
                        },
                        'vss' => {
                          '[1]' => {}
                        }
                      }
                    }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'SuspendResume'
                      ],
                      [
                        'TRAFFIC_1'
                      ]
                    ],
                    'SuspendResume' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'iterations' => '1',
                      'vmstate' => 'suspend,resume'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'testduration' => '60',
                      'toolname' => 'netperf',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]'
                    }
                  }
                },


                'ChangevNICStateDuringBoot' => {
                  'Component' => 'Vmxnet3',
                  'Category' => 'Virtual Net Devices',
                  'TestName' => 'ChangevNICStateDuringBoot',
                  'Summary' => 'Tests vNIC link state changesduring VM power off/on.',
                  'ExpectedResult' => 'PASS',
                  'Tags' => 'Functional,BAT,batnovc,LIN_VMXNET3_BOTH',
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
                  'ParentTDSID' => '5.23',
                  'AutomationStatus' => 'automated',
                  'testID' => 'TDS::VirtualNetDevices::VDCommon::ChangevNICStateDuringBoot',
                  'Priority' => 'P0',
                  'TestbedSpec' => {
                    'vm' => {
                      '[2]' => {
                        'vnic' => {
                          '[1]' => {
			    'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      },
                      '[1]' => {
                        'vnic' => {
                          '[1]' => {
                            'portgroup' => 'host.[1].portgroup.[1]',
                            'driver' => 'vmxnet3'
                          }
                        },
                        'host' => 'host.[1]'
                      }
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
                            'driver' => 'any'
                          }
                        },
                        'vss' => {
                          '[1]' => {}
                        }
                      }
                    }
                  },
                  'WORKLOADS' => {
                    'Sequence' => [
                      [
                        'PowerOff'
                      ],
                      [
                        'DisconnectvNic'
                      ],
                      [
                        'PowerOn'
                      ],
                      [
                        'TRAFFIC_1'
                      ],
                      [
                        'ConnectvNic'
                      ],
                      [
                        'Traffic_Ping'
                      ]
                    ],
                    'ExitSequence' => [
                      [
                        'ConnectvNic'
                      ]
                    ],
                    'Traffic_Ping' => PING_TRAFFIC ,
                    'PowerOff' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vmstate' => 'poweroff'
                    },
                    'DisconnectvNic' => {
                      'Type' => 'NetAdapter',
                      'reconfigure' => 'true',
                      'connected' => 0,
                      'testadapter' => 'vm.[1].vnic.[1]'
                    },
                    'PowerOn' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vmstate' => 'poweron'
                    },
                    'TRAFFIC_1' => {
                      'Type' => 'Traffic',
                      'expectedresult' => 'FAIL',
                      'testduration' => '20',
                      'toolname' => 'ping',
                      'noofinbound' => '1',
                      'testadapter' => 'vm.[2].vnic.[1]',
                      'supportadapter' => 'vm.[1].vnic.[1]'
                    },
                    'ConnectvNic' => {
                      'Type' => 'NetAdapter',
                      'reconfigure' => 'true',
                      'connected' => 1,
                      'testadapter' => 'vm.[1].vnic.[1]'
                    },
                  }
                },


		'RxFloodwithWoL' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'RxFloodwithWoL',
		  'Summary' => 'Verify ISR doesn\'t miss interrupts during waking up VM' .
		               ' while Rx traffic and SR operations.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress',
		  'Version' => '2',
		  'ParentTDSID' => '166',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::RxFloodwithWoL',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'Ping',
		        'WOL'
		      ],
		      [
		        'Ping',
		        'Standby',
		        'Wake'
		      ],
		      [
		        'Ping',
		        'SuspendResume'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Reset'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'Ping' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'routingscheme' => 'flood',
		      'noofinbound' => '8',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    },
		    'WOL' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'sleepbetweenworkloads' => '300',
		      'wol' => 'MAGIC',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Standby' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '600',
		      'iterations' => '1',
		      'operation' => 'standby'
		    },
		    'Wake' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'sleepbetweenworkloads' => '900',
		      'wakeupguest' => 'MAGIC',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '600',
		      'iterations' => '1',
		      'vmstate' => 'suspend,resume'
		    },
		    'Reset' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'operation' => 'reset'
		    }
		  }
		},


		'TxWithNetVmxnet3FailFixCsum' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3FailFixCsum',
		  'Summary' => 'Verify IO with NetVmxnet3FailFixCsum stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '124',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3FailFixCsum',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailFixCsum",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'minexpresult' => '1',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailFixCsum",
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
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
		      [
		        'PowerOn'
		      ]
		    ],
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
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'KillVM' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '360',
		      'iterations' => '1',
		      'operation' => 'killvm'
		    },
		    'PowerOnAfterKill' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'poweron'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PktCap',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'poweron'
		    }
		  }
		},


		'CSOwithUDPTCPwithIPv4and6' => {
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
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
		        'EnableSGHelper'
		      ],
		      [
		        'EnableTSOHelper'
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
		        'EnableSGHelper'
		      ],
		      [
		        'EnableTSOHelper'
		      ]
		    ],
		    'CSODisableTx' => CSO_DISABLE_TX,
		    'CSODisableRx' => CSO_DISABLE_RX,
		    'ConfigureIP'  => CONFIGURE_IP,
		    'Traffic_Ping' => PING_TRAFFIC,
		    'CSOEnableSUT_tx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'iterations' => '1'
		    },
		    'CSOEnableSUT_rx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
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
		      'testadapter' => 'vm.[1].vnic.[1]',
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
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    }
		  }
		},


		'TxWithNetFailPortsetConnectPort' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortsetConnectPort',
		  'Summary' => 'Verify IO with NetFailPortsetConnectPort stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '71',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortsetConnectPort',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNICFAIL'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetConnectPort",
		       }
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'iterations' => '1',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNICFAIL' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'expectedresult' => 'FAIL',
		      'iterations' => '1',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Ping' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetConnectPort",
		       }
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'iterations' => '1',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		    }
		  }
		},


		'MTUE1000' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices,CAT_LIN_E1000',
		  'TestName' => 'MTUE1000',
		  'Summary' => 'Verify MTU of vNIC can be set to minMTU, maxMTU, ' .
		               'and (minMTU+maxMTU)/2 for E1000.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional',
		  'Version' => '2',
		  'ParentTDSID' => '167',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MTUE1000',
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
		            'driver' => 'any'
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
                   #     'vmnic' => {
                   #       '[1]' => {
                           # 'portgroup' => 'host.[1].portgroup.[1]',
                           # 'driver' => 'vmxnet3'
                   #       }
                   #     },
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
                 #           'driver' => 'any'
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
		        'ConfigureIP',
		      ],
                      [
                        'ConfigureIP1',
                      ],
                      [
                        'ConfigureIP2',
                      ],
                      [
                        'PING_TRAFFIC'
                      ],
                      [
                        'TRAFFIC'
                      ],
                      [ 'TRAFFIC1' ],
		      [
		        'DefaultE1000'
		      ],
		 #     [
		 #       'MinMTUE1000'
		 #     ],
		   #   [
		   #     'Ping'
		   #   ],
		   #   [
		   #     'MTU1600'
		   #   ],
		   #   [
		   #     'Ping'
		   #   ],
		      [
		        'MaxMTUE1000'
		      ],
                      [
                        'DefaultE1000'
                      ]
		   #   [
		   #     'Ping'
		   #   ],
		   #   [
		   #     'MaxMinMTUE1000'
		   #   ],
		   #   [
		   #     'Ping'
		   #   ],
		   #   [
		   #     'InvalidMaxE1000'
		   #   ],
		   #   [
		   #     'InvalidMinE1000'
		  #    ]
		    ],
		    'ExitSequence' => [
		      [
                        'RemoveUplink'
                      ],
                      [
                        'RemoveUplink1'
                      ],
                 #     [                                                                                                                                                                                                                                              'Shutdown'                                                                                                                                                                                                                                 ],
                  #    [
                  #      'Shutdown1'
                  #    ],
                   #   [
                   #     'DeleteVSS'
                   #   ],
                   #   [
                   #     'PowerOn'
                   #   ],
                   #   [
                   #     'PowerOn1'
                   #   ],
		    ],
		   # 'ConfigureIP'=> CONFIGURE_IP ,
		   # 'Ping' => PING_TRAFFIC,
		   # 'DefaultE1000' => {
		   #   'Type' => 'NetAdapter',
		   #   'TestAdapter' => 'vm.[1].vnic.[1]',
		   #   'mtu' => '1500',
		   # },
                    'TRAFFIC' => {                      'Type' => 'Traffic',                      'testduration' => '60',                      'toolname' => 'netperf',                      'testadapter' => 'vm.[2].vnic.[1]',                      'supportadapter' => 'vm.[3].vnic.[1]',                    },
'TRAFFIC1' => {                      'Type' => 'Traffic',                      'testduration' => '60',                      'toolname' => 'netperf',                      'testadapter' => 'vm.[2].vnic.[1]',                      'supportadapter' => 'host.[2].vmknic.[1]',                    },
                    'ConfigureIP' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'ipv4' => '192.168.100.99',
                    },
                    'ConfigureIP1' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[3].vnic.[1]',
                      'ipv4' => '192.168.100.100'
                    },
                    'ConfigureIP2' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[2].vmknic.[1]',
                      'ipv4' => '192.168.100.101'
                    },
                   'DeleteVSS' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'deletevss' => 'host.[1].vss.[1]'
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
                   'DeleteVnic' => {
                      'Type' => 'VM',
                      'deletevnic' => 'vm.[1].vnic.[1]',
                      'TestVM' => 'vm.[1]',
                      'sleepbetweenworkloads' => '40',
                   },
                   PING_TRAFFIC => {
                      'Type' => 'Traffic',
                      'noofoutbound' => '2',
                      'testduration' => '60',
                      'toolname' => 'ping',
                      'noofinbound' => '2',
                      'L3Protocol'     => 'ipv4',
                      'TestAdapter' => 'vm.[2].vnic.[1]',
              #        'supportadapter' => 'host.[2].vmknic.[1]',
                      'supportadapter' => 'vm.[3].vnic.[1]',
                    },
                    'Shutdown' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'maxtimeout' => '14400',
                      'vmstate' => 'poweroff',
                      'sleepbetweenworkloads' => '30',
                    },
                    'Shutdown1' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'maxtimeout' => '14400',
                      'vmstate' => 'poweroff',
                      'sleepbetweenworkloads' => '30',
                    },
                    'PowerOn' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'vmstate' => 'poweron',
                      'sleepbetweenworkloads' => '230'
                    },
                    'PowerOn1' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[3]',
                      'vmstate' => 'poweron',
                      'sleepbetweenworkloads' => '230'
                    },
                    'Reboot' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'maxtimeout' => '14400',
                      'iterations' => '1',
                      'operation' => 'reboot',
                      'waitforvdnet' => '1'
                    },
                    'SuspendResume' => {
                      'Type' => 'VM',
                      'TestVM' => 'vm.[1]',
                      'maxtimeout' => '108000',
                      'iterations' => '2',
                      'vmstate' => 'suspend,resume'
                    },
                    'DefaultE1000' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'host.[2].vmknic.[1],vm.[2].vnic.[1]',
                      'mtu' => '1500',
                    },
		    'MinMTUE1000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '46,68'
		    },
		    'MaxMTUE1000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1611'
		    },
		    'MaxMinMTUE1000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '7500'
		    },
		    'MTU1600' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1600'
		    },
		    'InvalidMaxE1000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'mtu' => '16111'
		    },
		    'InvalidMinE1000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'mtu' => '45'
		    }
		  }
		},


		'TxWithNetE1000ForceSmallChangelog' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetE1000ForceSmallChangelog',
		  'Summary' => 'Verify IO with NetE1000ForceSmallChangelog stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetE1000ForceSmallChangelog',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP',
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceSmallChangelog",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceSmallChangelog",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    }
		  }
		},


		'BDTrafficwhenLnkDown' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'BDTrafficwhenLnkDown',
		  'Summary' => 'Verify IO over disconnected link will not cause' .
		               ' tx/rx wedge.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,' .
		            'CAT_LIN_VMXNET2,CAT_WIN_E1000,CAT_WIN_VMXNET2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::BDTrafficwhenLnkDown',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DisablevNIC',
		        'TRAFFIC'
		      ],
		      [
		        'EnablevNIC'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'DisablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'sleepbetweenworkloads' => '360',
		      'devicestatus' => 'DOWN'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '600',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '3',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'noofinbound' => '3',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'Target' => 'src,dst',
		        'pktcount' => '2000+',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'TRAFFIC'
		      ],
		      [
		        'Addswitch'
		      ],
		      [
		        'AddVssPortgroup'
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
		      [
		        'Deleteswitch'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    },
		    'Addswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'vss' => {
		        '[2]' => {}
		      }
		    },
		    'AddVssPortgroup' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[2]' => {
		          'vss' => 'host.[1].vss.[2]',
		        }
		      }
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[2]',
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
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'connected' => '0',
		      'reconfigure' => 'true'
		    },
		    'ChangePortgroup2' => {
		      'Type' => 'NetAdapter',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[1]',
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
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'connected' => '1',
		      'reconfigure' => 'true'
		    },
		    'Deleteswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'deletevss' => 'host.[1].vss.[2]'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TSOwithSGCSOOff' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TSOwithSGCSOOff',
		  'Summary' => 'Verify TSO fails as expected when CSO is turned off ' .
		               'and SG is off.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,CAT_LIN_VMNET2,' .
		            'CAT_LIN_E1000,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TSOwithSGCSOOff',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'CSOEnableTx',
		        'CSOEnableRx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'CSODisableTx',
		        'CSODisableRx',
		      ],
		      [
		        'DisableSG'
		      ],
		      [
		        'EnableTSOFAIL'
		      ],
		      [
		        'CSOEnableTx',
		        'CSOEnableRx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'CSOEnableTx',
		        'CSOEnableRx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'CSODisableTx' => CSO_DISABLE_TX,
		    'CSODisableRx' => CSO_DISABLE_RX,
		    'CSOEnableTx' => CSO_ENABLE_TX,
		    'CSOEnableRx' => CSO_ENABLE_RX,
		    'EnableSG' => ENABLE_SG,
		    'EnableTSO'=> ENABLE_TSO,
		    'DisableSG' => DISABLE_SG,
		    'DisableTSO'=> DISABLE_TSO,
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PktCap_Checksum',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'sendmessagesize' => '32768,65536,130172'
		    },
		    'EnableTSOFAIL' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'PktCap_Checksum' => {
		      'PktCap' => {
		        'pktcapfilter' => 'size > 1514',
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap',
		        'pktcksumerror' => '2000+',
		        'maxpktsize' => '9000+'
		      }
		    }
		  }
		},


		'MultiqueueTraffic' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiqueueTraffic',
		  'Summary' => 'Load the driver with multiple queuesand send ' .
		               'different types of traffic',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,SMP,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiqueueTraffic',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetTxQueues'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'SetRxQueues'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'IperfTraffic'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetDefaultTxQueues',
		      ],
		      [
		        'SetDefaultRxQueues'
		      ],
		    ],
		    'Iterations' => '1',
		    'SetTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '8',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => '100',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '8'
		    },
		    'SetRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'IperfTraffic' => {
		      'Type' => 'Traffic',
		      'testduration' => '10',
		      'toolname' => 'Iperf',
		      'routingscheme' => 'multicast',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'verification' => 'PktCap',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'multicasttimetolive' => '32'
		    },
		    'PingTraffic' => PING_TRAFFIC ,
		    'SetDefaultTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		    },
		    'SetDefaultRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		    },
		  }
		},


		'TxWithNetFailPortsetConnectPortINTER' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortsetConnectPortINTER',
		  'Summary' => 'Verify IO with NetFailPortsetConnectPort stress' .
		               ' option in INTER setup.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortsetConnectPortINTER',
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
		        }
		      },
		      '[1]' => {
		        'portgroup' => {
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
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'UnlinkpNIC'
		      ],
		      [
		        'UplinkpNIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'UplinkpNICPass'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'UplinkpNICPass'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetConnectPort",
		       }
		    },
		    'UnlinkpNIC' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'UplinkpNIC' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'expectedresult' => 'FAIL',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetConnectPort",
		       }
		    },
		    'UplinkpNICPass' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    }
		  }
		},


		'TxWithNetE1000OutOfBoundPA' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetE1000OutOfBoundPA',
		  'Summary' => 'Verify IO with NetE1000OutOfBoundPA stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_E1000',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetE1000OutOfBoundPA',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000OutOfBoundPA",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '1000',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'maxtimeout' => '27000',
		      'minexpresult' => '1',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '500,1000',
		      'noofinbound' => '3',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000OutOfBoundPA",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '1000,65536',
		      'noofinbound' => '3',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    }
		  }
		},


		'RepeatedStartshuts' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'RepeatedStartshuts',
		  'Summary' => 'Verify multiple startup/shutdown with DUT installed.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,CAT_WIN_E1000E,CAT_LIN_VMXNET2,CAT_WIN_VMXNET2,' .
		            'CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::RepeatedStartshuts',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Reboot'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'Shutdown'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'PowerOn'
		      ]
		    ],
		    'Reboot' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'maxtimeout' => '14400',
		      'iterations' => '10',
		      'operation' => 'reboot',
		      'waitforvdnet' => '1'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
		      'sleepbetweencombos' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'Shutdown' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'maxtimeout' => '14400',
		      'iterations' => '20',
		      'vmstate' => 'poweron'
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'poweron'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'RuntFramesTSOandNon-TSO' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'RuntFramesTSOandNon-TSO',
		  'Summary' => 'Verify the device does not drop runt frames with TSO ' .
		               'and without TSO.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '101',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::RuntFramesTSOandNon-TSO',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'MTU'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'Traffic_Ping'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'Traffic_Ping'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnableTSO'
		      ],
		      [
		        'DefaultMTU'
		      ]
		    ],
		    'DisableTSO' => DISABLE_TSO,
		    'EnableTSO' => ENABLE_TSO,
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'Traffic_Ping' => PING_TRAFFIC,
		    'MTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '576',
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '4096',
		      'toolname' => 'netperf',
		      'testduration' => '600',
		      'noofoutbound' => '5',
		      'remotesendsocketsize' => '4096',
		      'noofinbound' => '5',
		      'sendmessagesize' => '2092',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    },
		    'DefaultMTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    }
		  }
		},


		'IOWithNetVmxnet3HdrTooBig' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOWithNetVmxnet3HdrTooBig',
		  'Summary' => 'Verify IO with stress option IO.Stress.IOwithNetVmxnet3HdrTooBig' .
		               ' doesn\'t hang/wedge the vNIC.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '160',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOWithNetVmxnet3HdrTooBig',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::IOwithNetVmxnet3HdrTooBig",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofoutbound' => '3',
		      'expectedresult' => 'FAIL',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4094,8192,32768,131072',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::IOwithNetVmxnet3HdrTooBig",
		       }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'verification' => 'Stats',
		      'testduration' => '120',
		      'toolname' => 'netperf',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    }
		  }
		},


		'SRTorture' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'SRTorture',
		  'Summary' => 'Verify VMX doesn\'t crash across SR torture tests',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '81',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::SRTorture',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SuspendResume'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'maxtimeout' => '108000',
		      'iterations' => '50',
		      'vmstate' => 'suspend,resume'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    }
		  }
		},


		'HotAddRemovevNIC' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'HotAddRemovevNIC',
		  'Summary' => 'Verify hot-add/hot-remove works across various valid' .
		               ' combinations',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'Functional,CAT_LIN_VMXNET2,CAT_LIN_E1000,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '6',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::HotAddRemovevNIC',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HotAdd'
		      ],
		      [
		        'HotRemove'
		      ],
		    ],
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[2-9]' => {
		          'portgroup' => 'host.[1].portgroup.[1]',
		          'driver' => 'e1000'
		        }
		      },
		      'runworkload'=> 'Traffic',
		    },
		    'Traffic' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[2-9]'
		    },
		  },
		},


		'VLANWithTagPriority' => {
		  'Component' => 'VirtualNetDevices',
		  'Category' => 'Vmxnet3',
		  'TestName' => 'VLANWithTagPriority',
		  'Summary' => 'Verify VLAN with PriorityVLAN disabled.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional',
		  'Version' => '2',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::VLANWithTagPriority',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Switch_1'
		      ],
		      [
		        'DisablePriorityVLAN'
		      ],
		      [
		        'VerifyPriorityDisable'
		      ],
		      [
		        'VerifyVLANDisable'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'VerifyPingFail'
		      ],
		      [
		        'gVLAN_Disable_SUT'
		      ],
		      [
		        'gVLAN_Disable_Helper'
		      ],
		      [
		        'EnablePriorityVLAN'
		      ],
		      [
		        'VerifyPriorityEnable'
		      ],
		      [
		        'VerifyVLANEnable'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'gVLAN_Disable_SUT'
		      ],
		      [
		        'gVLAN_Disable_Helper'
		      ],
		      [
		        'PriorityEnable'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'VerifyPingFail'
		      ],
		      [
		        'gVLAN_Disable_SUT'
		      ],
		      [
		        'gVLAN_Disable_Helper'
		      ],
		      [
		        'VLANEnable'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'gVLAN_Disable_SUT'
		      ],
		      [
		        'gVLAN_Disable_Helper'
		      ],
		      [
		        'Switch_2'
		      ]
		    ],
		    'Switch_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'DisablePriorityVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'priorityvlan' => 'Priority,VLAN',
		      'priorityvlanaction' => 'Disable'
		    },
		    'VerifyPriorityDisable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'Priority',
		         'value'       => 'disable',
		      },
		    },
		    'VerifyVLANDisable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'VLAN',
		         'value'       => 'disable',
		      },
		    },
		    'gVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        },
		      },
		    },
		    'VerifyPingFail' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000'
		    },
		    'gVLAN_Disable_SUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'gVLAN_Disable_Helper' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'EnablePriorityVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'priorityvlan' => 'Priority,VLAN',
		      'priorityvlanaction' => 'Enable'
		    },
		    'VerifyPriorityEnable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'Priority',
		         'value'       => 'enable',
		      },
		    },
		    'VerifyVLANEnable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'VLAN',
		         'value'       => 'enable',
		      },
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_gVLAN',
		      'l4protocol' => 'tcp,udp',
		      'l3protocol' => 'ipv4',
		      'sendmessagesize' => '1024,32768',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'PriorityEnable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'priorityvlan' => 'Priority',
		      'priorityvlanaction' => 'Enable'
		    },
		    'VLANEnable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'priorityvlan' => 'VLAN',
		      'priorityvlanaction' => 'Enable'
		    },
		    'Switch_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Verification_gVLAN' => {
		      'Pktcap' => {
		        'Pktcapfilter' => 'vlan',
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '100+',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '100+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'TxWithNetVmxnet3FailTsoSplitMove' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3FailTsoSplitMove',
		  'Summary' => 'Verify IO with NetVmxnet3FailTsoSplitMove stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '147',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3FailTsoSplitMove',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailTsoSplitMove",
		       }
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailTsoSplitMove",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '65536,131072'
		    }
		  }
		},


		'TxWithNetVmxnet3SkipRxDesc' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3SkipRxDesc',
		  'Summary' => 'Verify IO with NetVmxnet3SkipRxDesc stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '124',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3SkipRxDesc',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3SkipRxDesc",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3SkipRxDesc",
		       }
		    }
		  }
		},


		'TxWithNetFailGPHeapAlign' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailGPHeapAlign',
		  'Summary' => 'Verify IO with NetFailGPHeapAlign stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailGPHeapAlign',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {
		        'portgroup' => {
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
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'TxQueue',
		        'RxQueue',
		      ],
		      [
		        'DisableEnablevNIC'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailGPHeapAlign",
		       }
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'TxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'IGNORE',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,8',
		      },
		      'iterations' => '1'
		    },
		    'RxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'IGNORE',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,8',
		      },
		      'iterations' => '1'
		    },
		    'DisableEnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'IGNORE',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '10'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailGPHeapAlign",
		       }
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'Interop_SRD_vlance' => {
		  'Component' => 'Vmxnet',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'Interop_SRD_vlance',
		  'Summary' => 'Ensure driver works fine after snapshot revert delete ' .
		               'for vlance vNIC.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Interop',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::Interop_SRD_vlance',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'MTU'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
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
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ]
		    ],
		    'ExitSequence' => [
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
		        'SnapshotDelete'
		      ]
		    ],
		    'Ping' => PING_TRAFFIC,
		    'SnapshotRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'verification' => 'Ping',
		      'snapshot' => 'create,revert',
		      'waitforvdnet' => 'true'
		    },
		    'SnapshotDelete' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'iterations' => '1',
		      'snapshot' => 'delete',
		      'waitforvdnet' => 'true'
		    },
		    'MTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '1500'
		    },
		    'Switch_1_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_1_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_2_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => '113',
		      'mtu' => '1500'
		    },
		    'Switch_3_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_3_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_4_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_4_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    }
		  }
		},


		'HotAddRemoveTorture' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'HotAddRemoveTorture',
		  'Summary' => 'Verify driver or host doesn\'t crash and device ' .
		               'doesn\'t hang after hot-add/remove torture.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,CAT_LIN_E1000,CAT_LIN_VMXNET2,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '6',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::HotAddRemoveTorture',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		     'Sequence' => [
		       [
		         'HotAddRemove'
		       ],
		       [
		         'HotAdd'
		       ],
		       [
		         'HotRemove'
		       ],
		     ],
		     'Iterations' => 1,
		     'HotAddRemove' => {
		       'Type' => 'VM',
		       'TestVM' => 'vm.[1]',
		       'vnic' => {
		         '[2-9]' => {
		           'portgroup' => 'host.[1].portgroup.[1]',
		           'driver' => 'vmxnet3',
		         },
		       },
		       'deletevnic' => 'vm.[1].vnic.[2-9]',
		       'maxtimeout' => '6000',
		       'Iterations' => '5',
		     },
		     'HotAdd' => {
		       'Type' => 'VM',
		       'TestVM' => 'vm.[1]',
		       'vnic' => {
		         '[2-9]' => {
		           'portgroup' => 'host.[1].portgroup.[1]',
		           'driver' => 'vmxnet3'
		         },
		       },
		       'runworkload'=> 'Traffic',
		     },
		     'Traffic' => {
		       'Type' => 'Traffic',
		       'testduration' => '60',
		       'toolname' => 'netperf',
		       'testadapter' => 'vm.[1].vnic.[1]',
		       'supportadapter' => 'vm.[2].vnic.[1]'
		     },
		     'HotRemove' => {
		       'Type' => 'VM',
		       'TestVM' => 'vm.[1]',
		       'deletevnic' => 'vm.[1].vnic.[2-9]',
		     },
		   },
		 },


		'TxWithNetFailPortInputResume' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortInputResume',
		  'Summary' => 'Verify IO with NetFailPortInputResume stress option',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,' .
		            'CAT_WIN_E1000,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortInputResume',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortInputResume",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '1800',
		      'noofoutbound' => '3',
		      'maxtimeout' => '32400',
		      'minexpresult' => '1',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '2048,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortInputResume",
		       }
		    }
		  }
		},


		'IOwithmismatchingMTUs' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOwithmismatchingMTUs',
		  'Summary' => 'Verify IO over a connection with mis-matching MTUs ' .
		               'doesn\'t crash the host.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,LIN_VMXNET3_RELEASE',
		  'Version' => '2',
		  'ParentTDSID' => '108',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOwithmismatchingMTUs',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTUSUT'
		      ],
		      [
		        'MTUHelper'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DefaultMTU'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DefaultMTU'
		      ]
		    ],
		    'MTUSUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO',
		      'iterations' => '1',
		      'mtu' => '9000'
		    },
		    'MTUHelper' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO',
		      'iterations' => '1',
		      'mtu' => '1500'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '3',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '32400',
		      'verification' => 'Traffic_MTU',
		      'sendmessagesize' => '10240,16384,32768,65536,131072',
		      'noofinbound' => '3',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DefaultMTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '1500'
		    },
		    'Traffic_MTU' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'retransmission' => '5-',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '10000+',
		        'Target' => 'src,dst',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'TxWithNetCorruptPortOutput' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetCorruptPortOutput',
		  'Summary' => 'Verify IO with NetCorruptPortOutput stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_WIN_E1000,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetCorruptPortOutput',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetCorruptPortOutput",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '1800',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3',
		      'sendmessagesize' => '131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetCorruptPortOutput",
		       }
		    }
		  }
		},


		'InterruptModes' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'InterruptModes',
		  'Summary' => 'This test verifies variousinterrupt modes.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'Functional,CAT_WIN_VMXNET2,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'Vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '5.15',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::InterruptModes',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'IntrModes_1'
		      ],
		      [
		        'Traffic'
		      ],
		      [
		        'IntrModes_2'
		      ],
		      [
		        'Traffic'
		      ],
		      [
		        'IntrModes_3'
		      ],
		      [
		        'Traffic'
		      ],
		      [
		        'IntrModes_4'
		      ],
		      [
		        'Traffic'
		      ],
		      [
		        'IntrModes_5'
		      ],
		      [
		        'Traffic'
		      ],
		      [
		        'IntrModes_6'
		      ],
		      [
		        'Traffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetDefault'
		      ]
		    ],
		    'IntrModes_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-INTX'
		    },
		    'Traffic' => {
		      'Type' => 'Traffic',
		      'testduration' => '10',
		      'toolname' => 'netperf'
		    },
		    'IntrModes_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSI'
		    },
		    'IntrModes_3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    },
		    'IntrModes_4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'ACTIVE-INTX'
		    },
		    'IntrModes_5' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'ACTIVE-MSI'
		    },
		    'IntrModes_6' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'ACTIVE-MSIX'
		    },
		    'SetDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    }
		  }
		},


		'MTUVmxnet3' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MTUVmxnet3',
		  'Summary' => 'Verify MTU of vNIC can be set to minMTU, maxMTU, ' .
		               'and (minMTU+maxMTU)/2 for Vmxnet3.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '167',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MTUVmxnet3',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'DefaultVmxnet3'
		      ],
		      [
		        'MinMTUVmxnet3'
		      ],
		      [
		        'Traffic_Ping'
		      ],
		      [
		        'MaxMTUVmxnet3'
		      ],
		      [
		        'Traffic_Ping',
		        'TRAFFICMAX'
		      ],
		      [
		        'MTU1600Vmxnet3'
		      ],
		      [
		        'Traffic_Ping'
		      ],
		      [
		        'MaxMinMTUVmxnet3'
		      ],
		      [
		        'Traffic_Ping'
		      ],
		      [
		        'InvalidMaxVmxnet3'
		      ],
		      [
		        'InvalidMinVmxnet3'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DefaultVmxnet3'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'Traffic_Ping' => PING_TRAFFIC,
		    'DefaultVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'MinMTUVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '68'
		    },
		    'MTU1600Vmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1600'
		    },
		    'MaxMTUVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'TRAFFICMAX' => {
		      'Type' => 'Traffic',
		      'verification' => 'MaxMTU',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf',
		      'sleepbetweenworkloads' => '60',
		    },
		    'MaxMinMTUVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '4534'
		    },
		    'InvalidMaxVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'mtu' => '9001'
		    },
		    'InvalidMinVmxnet3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'mtu' => '67'
		    },
		    'MaxMTU' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'size > 1514',
		        'Target' => 'src,dst',
		        'pktcount' => '4000+',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '9000+'
		      }
		    }
		  }
		},


		'TrafficTestOverVLANInterface' => {
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Switch_SUT'
		      ],
		      [
		        'EnablePromiscuous'
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
		        'TRAFFIC'
		      ],
		      [
		        'Switch_9000'
		      ],
		      [
		        'Adapter_9000'
		      ],
              [
                'Adapter_Vlan_9000'
              ],
		      [
		        'JFPing'
		      ],
		      [
		        'TRAFFIC'
		      ]
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
		      ]
		    ],
		    'Switch_SUT' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'EnablePromiscuous' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setpromiscuous' => 'Enable'
		    },
		    'VLAN1500MTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		        },
		      },
		      'mtu' => '1500'
		    },
		    'EnableIPv6' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1].vlaninterface.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT',
		      'iterations' => '1'
		    },
		    'EnableIPv4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1].vlaninterface.[1]',
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
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'maxtimeout' => '75600',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'PacketCap',
		      'l4protocol' => 'tcp,udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '1024,2048,4096,8192,16384,32768'
		    },
		    'RemoveVLAN_SUT' => {
		     'Type' => 'NetAdapter',
		     'TestAdapter' => 'vm.[1].vnic.[1]',
		     'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveVLAN_HELPER' => {
		     'Type' => 'NetAdapter',
		     'TestAdapter' => 'vm.[2].vnic.[1]',
		     'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'Switch_9000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'Adapter_9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'Adapter_Vlan_9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1].vlaninterface.[1]',
		      'mtu' => '9000'
		     },
		    'JFPing' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'testduration' => '200',
		      'pingpktsize' => '8000',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'noofoutbound' => '2',
		      'pktfragmentation' => 'no',
		      'noofinbound' => '3',
		      'L3Protocol'     => 'ipv4,ipv6',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'Switch_Default_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_Default_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'PacketCap' => {
		      'PktCap' => {
		        'pktcapfilter' => "vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TxWithNetFailPortsetEnablePortINTER' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortsetEnablePortINTER',
		  'Summary' => 'Verify IO with NetFailPortsetEnablePort stress ' .
		               'option in INTER setup.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortsetEnablePortINTER',
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
		        }
		      },
		      '[1]' => {
		        'portgroup' => {
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
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'UnlinkpNIC'
		      ],
		      [
		        'UplinkpNICFAIL'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'UplinkpNICPass'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'UplinkpNICPass'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetEnablePort",
		       }
		    },
		    'UnlinkpNIC' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'UplinkpNICFAIL' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'expectedresult' => 'FAIL',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetEnablePort",
		       }
		    },
		    'UplinkpNICPass' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    }
		  }
		},


		'MultiTxQueue_MSIX_UDP' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiTxQueue_MSIX_UDP',
		  'Summary' => 'Enables/disables Multi Tx Queue and tests UDPTraffic' .
		               ' aross multiple queueswith MSIx Interrupt.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration,SMP',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiTxQueue_MSIX_UDP',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'MSIX'
		      ],
		      [
		        'MultiQueueTxUDP',
		        'MultiQueueRxUDP',
		      ],
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'MultiQueueTxUDP',
		        'MultiQueueRxUDP',
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'DisableRSS'
		      ],
		      [
		        'DefaultIntrMode'
		      ]
		    ],
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'MSIX' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    },
		    'MultiQueueTxUDP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'verification' => 'UDPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'MultiQueueRxUDP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableMultiTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		    },
		    'DisableMultiRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    },
		    'DefaultIntrMode' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    }
		  }
		},


		'TxWithNetFailPktCanAppend' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPktCanAppend',
		  'Summary' => 'Verify IO with NetFailPktCanAppend stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,' .
		            'CAT_WIN_E1000E,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPktCanAppend',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPktCanAppend",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPktCanAppend",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    }
		  }
		},


		'TSOOperationsOverIPV4andIPv6' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TSOOperationsOverIPV4andIPv6',
		  'Summary' => 'This test verifies TSO functionality with message size ' .
		               'that span SG listboundaries and verify TSO ' .
		               'functionalitybefore and after Suspend/Resume,' .
		               'Snapshot/Revert Operations,gVLAN and sVLAN,' .
		               'Functionality over IPv4 and IPv6',
		  'ExpectedResult' => 'PASS',
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
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TSOOperationsOverIPV4andIPv6',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'TCPTRAFFIC'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'TCPTRAFFIC'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'TCPTRAFFIC'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'TCPTRAFFIC'
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
		      [
		        'TRAFFIC_1'
		      ],
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
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SnapshotDelete'
		      ],
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
		      ]
		    ],
		    'EnableTSO' => ENABLE_TSO,
		    'ConfigureIP' => CONFIGURE_IP,
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
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '16384,32444,48504,64564,80624,96684,112744,128804'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'suspend,resume'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'testduration' => '60',
		      'noofoutbound' => '3',
		      'noofinbound' => '3',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf',
		      'bursttype' => 'stream,rr',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '43200',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'PacketCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '63488-8192,15872'
		    },
		    'SnapshotRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'tso_srd',
		      'iterations' => '1',
		      'snapshot' => 'create,revert',
		      'waitforvdnet' => 'true'
		    },
		    'SnapshotDelete' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'tso_srd',
		      'iterations' => '1',
		      'snapshot' => 'delete',
		      'waitforvdnet' => 'true'
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		    },
		    'Switch_2_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_4_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		      'mtu' => '9000'
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_6_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
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


		'TxWithNetTxWorldlet' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetTxWorldlet',
		  'Summary' => 'Verify Tx with NetTxWorldlet stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET2,CAT_LIN_E1000',
		  'Version' => '2',
		  'ParentTDSID' => '118',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetTxWorldlet',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'DisableEnablevNic'
		      ],
		      [
		        'ConfigureIP'
		      ],

		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'DisableEnablevNic'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetNoLPD",
		       }
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '20'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetNoLPD",
		       }
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'VMotion' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'VMotion',
		  'Summary' => 'This test tests VMotion with the specific adapter type.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Pots',
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
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::VMotion',
		  'Priority' => 'P0',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    },
		    'vc' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableVMotionSUT'
		      ],
		      [
		        'EnableVMotionHelper'
		      ],
		      [
		        'Connect'
		      ],
		      [
		        'CreateDC'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'VMotion'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'RemoveDC'
		      ]
		    ],
		    'EnableVMotionSUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.1'
		    },
		    'EnableVMotionHelper' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.2'
		    },
		    'Connect' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'opt' => 'connect'
		    },
		    'CreateDC' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'datacenter' => {
		        '[1]' => {
		          'name' => 'vmotiontest',
		          'host' => 'host.[1];;host.[1]'
		        }
		      }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'VMotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'dsthost' => 'host.[1]',
		      'staytime' => '60'
		    },
		    'RemoveDC' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'deletedatacenter' => 'vc.[1].datacenter.[1]'
		    }
		  }
		},


		'UnloadSRLnkDown' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'UnloadSRLnkDown',
		  'Summary' => 'Ensure driver can be uninstalled across suspend ' .
		               'resume operations with link state change.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'Functional,WindowsNotSupported,CAT_LIN_VMXNET2,' .
		            'CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
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
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::UnloadSRLnkDown',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Suspend'
		      ],
		      [
		        'Addswitch'
		      ],
		      [
		        'AddVssPortgroup'
		      ],
		      [
		        'ChangePortgroup'
		      ],
		      [
		        'Deleteswitch'
		      ],
		      [
		        'Resume'
		      ],
		      [
		        'LoadUnload'
		      ],
		      [
		        'ConnectvNic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Resume'
		      ],
		      [
		        'ConnectvNic'
		      ]
		    ],
		    'Suspend' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'suspend'
		    },
		    'Addswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'vss' => {
		        '[2]' => {}
		      }
		    },
		    'AddVssPortgroup' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[2]' => {
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup' => {
		      'Type' => 'NetAdapter',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[2]',
		      'reconfigure' => 'true'
		    },
		    'Deleteswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'deletevss' => 'host.[1].vss.[2]'
		    },
		    'Resume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'resume'
		    },
		    'LoadUnload' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		    },
		    'ConnectvNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[1]',
		      'connected' => '1',
		      'reconfigure' => 'true'
		    }
		  }
		},


		'vMotionWithVDS' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'vMotionWithVDS',
		  'Summary' => 'Test the vmotion functionality with different vnics',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'vmotion,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '101',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::vMotionWithVDS',
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
		          },
		          '[2]' => {
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
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vmknic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[2]'
		          }
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vmknic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[2]'
		          }
		        },
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'NetperfTraffic',
		        'vmotion'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'EnableVMotion1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.1'
		    },
		    'EnableVMotion2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.2'
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp, udp',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'vmotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'sleepbetweenworkloads' => '30',
		      'dsthost' => 'host.[2]',
		      'iterations' => '6',
		      'staytime' => '30'
		    }
		  }
		},


		'TxWithNetVmxnetNoLPD' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnetNoLPD',
		  'Summary' => 'Verify Tx with NetVmxnetNoLPD stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '118',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnetNoLPD',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetNoLPD",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetNoLPD",
		       }
		    }
		  }
		},


		'VLANwithStressOption' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'VLANwithStressOption',
		  'Summary' => 'Verify VLAN functionality by pinging a interface ' .
		               'that doesn\'t match vlan id and with stress option enabled.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_E1000,CAT_LIN_VMNET2,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::VLANwithStressOption',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Switch_1'
		      ],
		      [
		        'gVLAN_SUT_SetVlanD'
		      ],
		      [
		        'gVLAN_Helper_SetVlanE'
		      ],
		      [
		        'VerifyPingFail_InterfaceVlan'
		      ],
		      [
		        'gVLAN_Helper_SetVlanD'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'VerifyPingPass_InterfaceVlan'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'gVLAN_SUT_Disable'
		      ],
		      [
		        'gVLAN_Helper_Disable'
		      ],
		      [
		        'Switch_2'
		      ]
		    ],
		    'Switch_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'gVLAN_SUT_SetVlanD' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        }
		     }
		    },
		    'gVLAN_Helper_SetVlanE' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		         }
		      }
		     },
		    'VerifyPingFail_InterfaceVlan' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000',
		      'TestAdapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'gVLAN_Helper_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' =>'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'gVLAN_SUT_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' =>'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'gVLAN_Helper_SetVlanD' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        }
		      },
		      'reconfigure' => 'true'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::VLANwithStressOption",
		       }
		    },
		    'VerifyPingPass_InterfaceVlan' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000',
		      'L3Protocol'     => 'ipv4,ipv6',
		      'TestAdapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::VLANwithStressOption",
		       }
		    }
		  }
		},
		'TxWithNetVmxnetTxIncompletePkt' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnetTxIncompletePkt',
		  'Summary' => 'Verify Tx with TxWithNetVmxnetTxIncompletePkt ' .
		               'stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '117',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnetTxIncompletePkt',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableTSO'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ],
  		      [
 		        'EnableTSO'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		      'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'tsoipv4' => 'Enable',
		      'ipv4' => 'AUTO'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetTxIncompletePkt",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'tsoipv4' => 'Disable'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetTxIncompletePkt",
		       }
		    }
		  }
		},


		'Interop_SRD' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'Interop_SRD',
		  'Summary' => 'Ensure driver works fine after snapshot revert delete.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Interop,CAT_WIN_VMXNET2,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::Interop_SRD',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'MTU'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
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
		        'NetAdapter_1'
		      ],
		      [
		        'Ping_InterfaceVlan'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping_InterfaceVlan'
		      ],
		      [
		        'RemoveVLAN_SUT'
		      ],
		      [
		        'RemoveVLAN_HELPER'
		      ],
		      [
		        'MTU_1500'
		      ],
		      [
		        'Switch_3_A'
		      ],
		      [
		        'Switch_3_B'
		      ],
		      [
		        'ConfigureTxRingSize128',
		        'ConfigureRx1RingSize128',
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'ConfigureTxRingSize1024',
		        'ConfigureRx1RingSize2048',
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'ConfigureTxRingSize4096',
		        'ConfigureRx1RingSize256',
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Exit_RemoveVLAN_SUT'
		      ],
		      [
		        'Exit_RemoveVLAN_HELPER'
		      ],
		      [
		        'Switch_3_A'
		      ],
		      [
		        'Switch_3_B'
		      ],
		      [
		        'DefaultTxRingSize',
		        'DefaultRx1RingSize',
		      ],
		      [
		        'SnapshotDelete'
		      ],
              [
                'MTU_1500'
              ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'Ping' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'L3Protocol'     => 'ipv4,ipv6',
		    },
		    'Ping_InterfaceVlan' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000',
		      'L3Protocol'     => 'ipv4,ipv6',
		      'TestAdapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'SnapshotRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'snapshot' => 'create,revert',
		      'waitforvdnet' => 'true'
		    },
		    'SnapshotDelete' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'iterations' => '1',
		      'snapshot' => 'delete',
		      'waitforvdnet' => 'true'
		    },
		    'MTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '9000'
		    },
		    'Switch_1_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_1_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'Switch_2_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        },
		      },
		      'mtu' => '9000'
		    },
		    'RemoveVLAN_SUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'skipPostProcess' => 1,
		    },
		    'RemoveVLAN_HELPER' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]',
		      'skipPostProcess' => 1,

		    },
		    'Exit_RemoveVLAN_SUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
             },
		    'Exit_RemoveVLAN_HELPER' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'MTU_1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_3_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_3_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_4_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_4_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'ConfigureTxRingSize128' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '128',
		       },
		      'iterations' => '1',
		    },
		    'ConfigureRx1RingSize128' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '128',
		       },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'ConfigureTxRingSize1024' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '1024',
		       },
		      'iterations' => '1',
		    },
		    'ConfigureRx1RingSize2048' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '2048',
		       },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'ConfigureTxRingSize4096' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '4096',
		       },
		      'iterations' => '1',
		    },
		    'ConfigureRx1RingSize256' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '256',
		       },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DefaultTxRingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '512',
		       },
		      'iterations' => '1'
		    },
		    'DefaultRx1RingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '512',
		       },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		  }
		},


		'IOMsgSizesSweep' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOMsgSizesSweep',
		  'Summary' => 'Verify IO with different message sizes doesn\'t wedge' .
		               ' the vNIC.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
		  'Version' => '2',
		  'ParentTDSID' => '96',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOMsgSizesSweep',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'Traffic1Byte'
		      ],
		      [
		        'TCPTraffic'
		      ],
		      [
		        'UDPTraffic'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'Traffic1Byte' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '2',
		      'expectedresult' => 'IGNORE',
		      'verification' => 'Traffic_Verification',
		      'l4protocol' => 'udp,tcp',
		      'sendmessagesize' => '1',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '2'
		    },
		    'TCPTraffic' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '2',
		      'maxtimeout' => '97200',
		      'verification' => 'Traffic_Verification_TCP',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '128,256,1024,2048,4096,8192,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '2'
		    },
		    'UDPTraffic' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '8192',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '2',
		      'maxtimeout' => '97200',
		      'verification' => 'Traffic_Verification',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '128,256,1024,2048,4096,8192',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '2'
		    },
		    'Traffic_Verification' => {
		      'PktCap' => {
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '10000+',
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        'verificationtype' => 'vsish'
		      }
		    },
		    'Traffic_Verification_TCP' => {
		      'PktCap' => {
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '10000+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'TxWithNetQueueCommitInput' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetQueueCommitInput',
		  'Summary' => 'Verify IO with NetQueueCommitInput stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '147',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetQueueCommitInput',
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
		        }
		      },
		      '[1]' => {
		        'portgroup' => {
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
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetQueueCommitInput",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp,udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetQueueCommitInput",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'verification' => 'PktCap',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'l4protocol' => 'tcp,udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768',
		      'noofinbound' => '3'
		    }
		  }
		},


		'BDTrafficwithLinkDownUP' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'BDTrafficwithLinkDownUP',
		  'Summary' => 'Verify IO works across link state changes.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,' .
		            'CAT_WIN_E1000E,CAT_LIN_VMXNET2,CAT_WIN_E1000,CAT_WIN_VMXNET2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::BDTrafficwithLinkDownUP',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DisableEnablevNIC',
		        'UDPTRAFFIC'
		      ],
		      [
		        'TCPTRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'DisableEnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP',
		      'sleepbetweenworkloads' => '360',
		      'maxtimeout' => '5000',
		      'iterations' => '10'
		    },
		    'UDPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '16384',
		      'toolname' => 'netperf',
		      'testduration' => '600',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '16384',
		      'maxtimeout' => '8100',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '8192',
		      'noofinbound' => '3'
		    },
		    'TCPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '8100',
		      'verification' => 'PacketCapture',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'l4protocol' => 'tcp',
		      'noofinbound' => '3'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'Target' => 'src,dst',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TxWithNetFailGPHeapAlloc' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailGPHeapAlloc',
		  'Summary' => 'Verify IO with NetFailGPHeapAlloc stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,' .
		            'CAT_WIN_E1000,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailGPHeapAlloc',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
				   'EnableStress'
		      ],
		      [
				   'ConfigureIP'
		      ],
		      [
				    'TRAFFICIPV4andIPV6'
		      ],
		      [
		            'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailGPHeapAlloc",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailGPHeapAlloc",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP'
		    }
		  }
		},


		'IOWithLinkHWUPDOWN' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOWithLinkHWUPDOWN',
		  'Summary' => 'Verify vNIC doesn\'t hang/wedge by disconnecting/' .
		               'reconnecting cable and link state changes during IO',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOWithLinkHWUPDOWN',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'TRAFFIC',
		        'DisconnectvNIC',
		        'DisableEnablevNic'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '900',
		      'toolname' => 'netperf',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'l4protocol' => 'tcp',
		      'noofinbound' => '3'
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'iterations' => '1',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '9000',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '25'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'iterations' => '1',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
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


		'ColdAddWithNoPG' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ColdAddWithNoPG',
		  'Summary' => 'Verify the link state on vNIC when cold adding the ' .
		               'vNIC with no PG',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_LIN_VMXNET2,CAT_WIN_E1000E,CAT_LIN_E1000,' .
		            'CAT_WIN_VMXNET3,CAT_WIN_E1000,CAT_WIN_VMXNET2,' .
		            'CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::ColdAddWithNoPG',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'VerifyPingPass_Vnic1'
		      ],
		      [
		        'PowerOff'
		      ],
		      [
		        'ColdAdd'
		      ],
		      [
		        'Addswitch'
		      ],
		      [
		        'AddVssPortgroup'
		      ],
		      [
		        'ChangePortgroup'
		      ],
		      [
		        'Deleteswitch'
		      ],
		      [
		        'ColdRemove'
		      ],
		      [
		        'PowerOn'
		      ],
		      [
		        'VerifyPingPass_Vnic2'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'PowerOn'
		      ],
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'PowerOff' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'poweroff'
		    },
		    'ColdAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'host.[1].portgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ColdRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]',
		    },
		    'Addswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'vss' => {
		        '[2]' => {}
		      }
		    },
		    'AddVssPortgroup' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[2]' => {
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[2]',
		    },
		    'Deleteswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'deletevss' => 'host.[1].vss.[2]'
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'poweron'
		    },
		    'VerifyPingPass_Vnic1' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		    },
		    'VerifyPingPass_Vnic2' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[2]',
		    },
		    'ConnectvNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'portgroup' =>'host.[1].portgroup.[1]',
		      'connected' => '1',
		      'reconfigure' => 'true',
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'Target' => 'dst',
		        'pktcount' => '0',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'ConcurrentResets' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ConcurrentResets',
		  'Summary' => 'Verify concurrent resets to the driver doesn\'t hang' .
		               ' or crash the VM.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,CAT_LIN_VMXNET2,CAT_WIN_E1000E,CAT_WIN_VMXNET2,' .
		            'CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::ConcurrentResets',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DeviceReset'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'DeviceReset' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '13500',
		      'iterations' => '20',
		      'mtu' => '9000,1500'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'remotesendsocketsize' => '32768',
		      'verification' => 'PacketCapture',
		      'localsendsocketsize' => '32768',
		      'sleepbetweencombos' => '60',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '32768'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TxWithNetCheckDupPkt' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetCheckDupPkt',
		  'Summary' => 'Verify IO with NetCheckDupPkt stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_WIN_E1000,' .
		            'CAT_WIN_E1000E,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetCheckDupPkt',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetCheckDupPkt",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,64512'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetCheckDupPkt",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,64512'
		    }
		  }
		},


		'WoLSetGetInConnDisconn' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'WoLSetGetInConnDisconn',
		  'Summary' => 'Verify enabling/disabling WoL filters independent of' .
		               ' link state of NIC.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '38',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::WoLSetGetInConnDisconn',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'WOL'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'Standby'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'Wake'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'Standby'
		      ],
		      [
		        'SuspendResume',
		        'Wake1'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'Standby'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'SuspendResume',
		        'ConnectvNIC',
		        'Wake1'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'Standby'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'SuspendResume',
		        'Wake1'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'Standby'
		      ],
		      [
		        'SuspendResume',
		        'ConnectvNIC',
		        'Wake1'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Reset'
		      ]
		    ],
		    'ConfigureIP' => CONFIGURE_IP,
		    'Ping' => PING_TRAFFIC,
		    'WOL' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'wol' => 'MAGIC',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Standby' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'operation' => 'standby'
		    },
		    'Wake' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'wakeupguest' => 'MAGIC',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'iterations' => '1',
		      'connected' => 0,
		      'iterations' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'sleepbetweenworkloads' => '300',
		      'iterations' => '1',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'bursttype' => 'rr'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'suspend,resume'
		    },
		    'Wake1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'sleepbetweenworkloads' => '600',
		      'wakeupguest' => 'MAGIC',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Reset' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'operation' => 'reset'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '100+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TxWithNetFailPortEnable' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortEnable',
		  'Summary' => 'Verify IO with NetFailPortEnable stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_E1000,CAT_WIN_E1000,' .
		            'CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortEnable',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'VerifyTrafficFAIL'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNICPASS'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNICPASS'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortEnable",
		       }
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'expectedresult' => 'FAIL',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'VerifyTrafficFAIL' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '60',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortEnable",
		       }
		    },
		    'ConnectvNICPASS' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PktCap',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    }
		  }
		},


		'TxWithNetVmxnetRxRing2Full' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnetRxRing2Full',
		  'Summary' => 'Verify Tx with NetVmxnetRxRing2Full stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '118',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnetRxRing2Full',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'TxQueue'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'TxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '2',
		      },
		      'iterations' => '1'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetRxRing2Full",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetRxRing2Full",
		       }
		    }
		  }
		},


		'TxWithNetForceSplitGiantPktTx' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetForceSplitGiantPktTx',
		  'Summary' => 'Verify IO with NetForceSplitGiantPktTx stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetForceSplitGiantPktTx',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetForceSplitGiantPktTx",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetForceSplitGiantPktTx",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '65536,131072'
		    }
		  }
		},


		'TxWithNetFailKseg' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailKseg',
		  'Summary' => 'Verify Tx with NetFailKseg stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_E1000,CAT_LIN_VMXNET2,CAT_WIN_E1000,' .
		            'CAT_WIN_E1000E,CAT_WIN_VMXNET2,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '115',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailKseg',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailKseg",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'minexpresult' => '1',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '150',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailKseg",
		       }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'testduration' => '150',
		      'toolname' => 'netperf',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'HighlyFragmentedPkts' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'HighlyFragmentedPkts',
		  'Summary' => 'Verify IO with highly fragment message sizes.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'LongDuration,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '150',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::HighlyFragmentedPkts',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICStream'
		      ],
		      [
		        'TRAFFICRR'
		      ],
		      [
		        'DisableEnablevNic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICStream' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '100',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '100',
		      'maxtimeout' => '108000',
		      'l4protocol' => 'tcp,udp',
		      'sendmessagesize' => '100-1,20',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'TRAFFICRR' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'responsesize' => '100',
		      'bursttype' => 'rr',
		      'noofoutbound' => '1',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '108000',
		      'l4protocol' => 'tcp,udp',
		      'noofinbound' => '1',
		      'requestsize' => '100-1,20'
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'LoadHibernateResume' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LoadHibernateResume',
		  'Summary' => 'Ensure driver resumes properly from hibernation.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_LIN_E1000,CAT_LIN_VMXNET2,CAT_WIN_E1000,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LoadHibernateResume',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Hibernate'
		      ],
		      [
		        'Resume'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Resume'
		      ]
		    ],
		    'Hibernate' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'operation' => 'hibernate'
		    },
		    'Resume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'resume'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'TxWithNetVmxnet3StopRxQueue' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3StopRxQueue',
		  'Summary' => 'Verify IO with NetVmxnet3StopRxQueue stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3StopRxQueue',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3StopRxQueue",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,65536',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3StopRxQueue",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
		      'noofinbound' => '3'
		    }
		  }
		},


		'TxWithNetFailCopyToSGMA' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailCopyToSGMA',
		  'Summary' => 'Verify Tx with NetFailCopyToSGMA stress option with ' .
		               'and without TSO',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '160',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailCopyToSGMA',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableTSO',
		      ],
		      [
		        'ConfigureIP',
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'TRAFFICTSO'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TrafficDisableStress'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'TrafficTSODisableStress'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'EnableTSO' => ENABLE_TSO ,
		    'DisableTSO' => DISABLE_TSO ,
		    'ConfigureIP' => CONFIGURE_IP,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetFailCopyToSGMA",
		       }
		    },
		    'TRAFFICTSO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'noofoutbound' => '3',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '16200',
		      'verification' => 'Stats',
                      'testadapter' => 'vm.[1].vnic.[1]',
		      'sendmessagesize' => '4096,32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '3',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '16200',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4096,32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetFailCopyToSGMA",
		       }
		    },
		    'TrafficDisableStress' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '3',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '16200',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4096,32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'TrafficTSODisableStress' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '3',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '16200',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4096,32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    }
		  }
		},


		'TxWithNetVmxnetRxRingFull' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnetRxRingFull',
		  'Summary' => 'Verify Tx with NetVmxnetRxRingFull stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '118',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnetRxRingFull',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'TxQueue'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'TxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetRxRingFull",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'noofinbound' => '3',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnetRxRingFull",
		       }
		    }
		  }
		},


		'MultiTxQueueINTX_MSIX' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiTxQueueINTX_MSIX',
		  'Summary' => 'Enables/disables Multi Tx Queue and tests TCP,UDP and ' .
		               'ICMPTraffic aross multiple queueswith MSIx and INTX Interrupt.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration,SMP',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiTxQueueINTX_MSIX',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'INTX'
		      ],
		      [
		        'MultiQueueTxTCP',
		        'MultiQueueRx'
		      ],
		      [
		        'MultiQueueTxUDP',
		        'MultiQueueRx',
		      ],
		      [
		        'MultiQueueTxICMP',
		        'MultiQueueRx',
		      ],
		      [
		        'MSIX'
		      ],
		      [
		        'MultiQueueTxTCP',
		        'MultiQueueRx'
		      ],
		      [
		        'MultiQueueTxUDP',
		        'MultiQueueRx',
		      ],
		      [
		        'MultiQueueTxICMP',
		        'MultiQueueRx',
		      ],
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'MultiQueueTxUDP',
		        'MultiQueueRx',
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'DisableRSS'
		      ],
		      [
		        'DefaultIntrMode'
		      ]
		    ],
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'INTX' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-INTX'
		    },
		    'MultiQueueTxTCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		      'maxtimeout' => '16200',
		      'verification' => 'TCPTraffic',
		      'iterations' => '1'
		    },
		    'MultiQueueRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'MultiQueueTxUDP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'verification' => 'UDPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'MultiQueueTxICMP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'verification' => 'ICMPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'MSIX' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    },
		    'DisableMultiTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		      'iterations' => '1'
		    },
		    'DisableMultiRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    },
		    'DefaultIntrMode' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    }
		  }
		},


		'ChkSupptFeaturesVmxnet3' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ChkSupptFeaturesVmxnet3',
		  'Summary' => 'Verify list of supported features and its values in '.
		               'various device states for vmxnet3.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_P0,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '44',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::ChkSupptFeaturesVmxnet3',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTU1500'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'DefaultTxRingSize',
		        'DefaultRx1RingSize',
		      ],
		      [
		        'VerifyTSOEnable'
		      ],
		      [
		        'VerifyMTU1500'
		      ],
		      [
		        'VerifyRingTxDefault'
		      ],
		      [
		        'VerifyRingRx1Default'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'Traffic_Ping',
		        'TRAFFIC_NoTSO',
		      ],
		      [
		        'MTU9000'
		      ],
		      [
		        'ConfigureTxRingSize',
		        'ConfigureRx1RingSize'
		      ],
		      [
		        'VerifyTSODisable'
		      ],
		      [
		        'VerifyMTU9000'
		      ],
		      [
		        'VerifyTxRing'
		      ],
		      [
		        'VerifyRx1Ring'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'VerifyTSODisable'
		      ],
		      [
		        'VerifyMTU9000'
		      ],
		      [
		        'VerifyTxRing'
		      ],
		      [
		        'VerifyRx1Ring'
		      ],
		      [
		        'DisableEnablevNIC'
		      ],
		      [
		        'VerifyTSODisable'
		      ],
		      [
		        'VerifyMTU9000'
		      ],
		      [
		        'Reboot'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'MTU1500'
		      ],
		      [
		        'DefaultTxRingSize',
		        'DefaultRx1RingSize'
		      ],
		      [
		        'VerifyTSOEnable'
		      ],
		      [
		        'VerifyMTU1500'
		      ],
		      [
		        'VerifyRingTxDefault'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'MTU9000'
		      ],
		      [
		        'ConfigureTxRingSize',
		        'ConfigureRx1RingSize',
		      ],
		      [
		        'VerifyTSODisable'
		      ],
		      [
		        'VerifyMTU9000'
		      ],
		      [
		        'VerifyTxRing'
		      ],
		      [
		        'VerifyRx1Ring'
		      ],
		      [
		        'TRAFFIC_NoTSO'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNIC'
		      ],
		      [
		        'MTU1500'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'DefaultTxRingSize',
		        'DefaultRx1RingSize',
		      ]
		    ],
		    'Traffic_Ping' => PING_TRAFFIC,
		    'MTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'DefaultTxRingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '512',
		       },
		      'iterations' => '1',
		    },
		    'DefaultRx1RingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '256',
		       },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'VerifyTSOEnable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'TSOIPV4',
		         'value'       => 'Enable',
		      },
		    },
		    'VerifyMTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'mtu',
		         'value'       => '1500',
		      },
		    },
		    'VerifyRingTxDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'TxRingSize',
		         'value'       => '512',
		      },
		    },
		    'VerifyRingRx1Default' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'Rx1RingSize',
		         'value'       => '256',
		      },
		    },
		    'DisableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'false',
		      },
		    },
		    'TRAFFIC_NoTSO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '8192',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'remotesendsocketsize' => '8192',
		      'verification' => 'Verification_NoTSO',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '8192,',
		      'sleepbetweenworkloads' => '60',
		    },
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'ConfigureTxRingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '2048',
		       },
		      'iterations' => '1'
		    },
		    'ConfigureRx1RingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '2048',
		       },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1',
		    },
		    'VerifyTSODisable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'sleepbetweenworkloads' => '120',
		      'check_featuressettings' =>{
		         'feature_type' => 'tsoipv4',
		         'value'       => 'Disable',
		      },
		    },
		    'VerifyMTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'mtu',
		         'value'       => '9000',
		      },
		    },
		    'VerifyTxRing' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'TxRingSize',
		         'value'       => '2048',
		      },
		    },
		    'VerifyRx1Ring' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'check_featuressettings' =>{
		         'feature_type' => 'Rx1RingSize',
		         'value'       => '2048',
		      },
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'suspend,resume'
		    },
		    'DisableEnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP'
		    },
		    'Reboot' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'operation' => 'reboot',
		      'waitforvdnet' => '1'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    },
		    'Verification_NoTSO' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'size < 1514',
		        'Target' => 'src',
		        'pktcount' => '100+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '100+',
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => 'nochange',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => 'nochange',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.bytes tx ok' => '100+',
		        'verificationtype' => 'vsish'
		      }
		    },
		    'Verification_TSO' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'size > 1514',
		        'Target' => 'src',
		        'pktcount' => '100+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '100+',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '100+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'MultiTxQueue_MSIX_TCP' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiTxQueue_MSIX_TCP',
		  'Summary' => 'Enables/disables Multi Tx Queue and tests TCPTraffic ' .
		               'aross multiple queueswith MSIx Interrupt.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration,SMP',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiTxQueue_MSIX_TCP',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'MSIX'
		      ],
		      [
		        'MultiQueueTxTCP',
		        'MultiQueueRxTCP',
		      ],
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'MultiQueueTxTCP',
		        'MultiQueueRxTCP',
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues'
		      ],
		      [
		        'DisableRSS'
		      ],
		      [
		        'DefaultIntrMode'
		      ]
		    ],
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'MSIX' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    },
		    'MultiQueueTxTCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'verification' => 'TCPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		    },
		    'MultiQueueRxTCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableMultiTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		    },
		    'DisableMultiRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    },
		    'DefaultIntrMode' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'UDPTraffic'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
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
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'requestsize' => '4096-1,128'
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


		'LROVmxnet2' => {
		  'Component' => 'Vmxnet2',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LROVmxnet2',
		  'Summary' => 'Verify LRO(Sw/Hw) is functional for vmxnet2 vNIC ' .
		               'over VGT and VST',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,CAT_LIN_VMNET2',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LROVmxnet2',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[1].vss.[2]'
		          },
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
		          }
		        },
		        'vss' => {
		          '[2]' => {},
		          '[1]' => {
		            'configureuplinks' => 'add',
		            'vmnicadapter' => 'host.[1].vmnic.[1]'
		          }
		        },
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigurePG2'
		      ],
		      [
		        'ChangePG2'
		      ],
		      [
		        'DisableHwLRO'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ],
		      [
		        'Switch_1'
		      ],
		      [
		        'Switch_2'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ],
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'Switch_3'
		      ],
		      [
		        'Switch_4'
		      ],
		      [
		        'Switch_5'
		      ],
		      [
		        'Switch_6'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'EnableHwLRO'
		      ],
		      [
		        'Switch_3'
		      ],
		      [
		        'Switch_4'
		      ]
		    ],
		    'ConfigurePG2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'testpglro',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePG2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'DisableHwLRO' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'disable'
		    },
		    'EnableLRO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'configure_offload' =>{
		         'offload_type' => 'lro',
		         'enable'       => 'true',
		      },
		    },
		    'TRAFFIC_LRO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_LRO',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '4096,32768,65536'
		    },
		    'DisableLRO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'configure_offload' =>{
		         'offload_type' => 'lro',
		         'enable'       => 'false',
		      },
		    },
		    'TRAFFIC_NoLRO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_NoLRO',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '4096,65536'
		    },
		    'Switch_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => '4095'
		    },
		    'gVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		    },
		    'gVLAN_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => '0'
		    },
		    'Switch_3' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_4' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => '0'
		    },
		    'Switch_5' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		    },
		    'Switch_6' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		    },
		    'EnableHwLRO' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'enable'
		    },
		    'Verification_LRO' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'avgpktlen' => '4000+',
		        'retransmission' => '5-',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '9000+',
		        'pktcount' => '1000+',
		        'badpkt' => '0',
		        'minpktsize' => '1000-'
		      }
		    },
		    'Verification_NoLRO' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'avgpktlen' => '1450-1515',
		        'retransmission' => '5-',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '1514',
		        'pktcount' => '1000+',
		        'badpkt' => '0',
		        'minpktsize' => '1000-'
		      }
		    }
		  }
		},


		'TxWithNetFailVmxnetMapTx' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailVmxnetMapTx',
		  'Summary' => 'Verify Tx with NetFailVmxnetMapTx stress option with ' .
		               'and without TSO.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '115',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailVmxnetMapTx',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableTSO'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC_2'
		      ],
		      [
		        'DisableTSO'
		      ],
		      [
		        'TRAFFIC_3'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'DisableTSO' => DISABLE_TSO ,
		    'EnableTSO'  => ENABLE_TSO ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailVmxnetMapTx",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '10800',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '10800',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailVmxnetMapTx",
		       }
		    },
		    'TRAFFIC_2' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '10800',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'TRAFFIC_3' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '100',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '10800',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '32768,65536,131072',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    }
		  }
		},


		'TxWithNetDelayProcessIocl' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetDelayProcessIocl',
		  'Summary' => 'Verify IO with NetDelayProcessIocl stress option',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetDelayProcessIocl',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetDelayProcessIocl",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetDelayProcessIocl",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    }
		  }
		},


		'TxWithNetIfForceRxSWCsum' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetIfForceRxSWCsum',
		  'Summary' => 'Verify IO with NetIfForceRxSWCsum stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '124',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetIfForceRxSWCsum',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetIfForceRxSWCsum",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'minexpresult' => '1',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetIfForceRxSWCsum",
		       }
		    }
		  }
		},


		'IOwithMaxMinRingSizes' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOwithMaxMinRingSizes',
		  'Summary' => 'Verify bi-directional IO with max and min ring sizes ' .
		               'supported with std and jumbo MTU sizes.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
		  'Version' => '2',
		  'ParentTDSID' => '100',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOwithMaxMinRingSizes',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTU1500'
		      ],
		      [
		        'ConfigureTxRingSize1500',
		        'ConfigureRx1RingSize',
		      ],
		      [
		        'MTU9000'
		      ],
		      [
		        'ConfigureTxRingSize9000',
		        'ConfigureRx1RingSize',
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'MTU1500'
		      ],
		      [
		        'DefaultTxRingSize',
		        'DefaultRx1RingSize',
		      ]
		    ],
		    'MTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '1500',
		      'ipv4' => 'AUTO'
		    },
		    'ConfigureTxRingSize1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '32400',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '32,512,4096',
		       },
		      'iterations' => '1'
		    },
		    'ConfigureRx1RingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '32,512,4096',
		       },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1',
		    },
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '9000'
		    },
		    'ConfigureTxRingSize9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '32400',
		      'verification' => 'TRAFFIC_1',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '32,512,4096',
		       },
		      'iterations' => '1',
		    },
		    'DefaultTxRingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'tx',
		         'value'     => '512',
		       },
		    },
		    'DefaultRx1RingSize' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_ringsize' => {
		         'ring_type' => 'rx1',
		         'value'     => '512',
		       },
		    },
		    'Traffic_9000' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '3000+'
		      },
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '4000+',
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        'verificationtype' => 'vsish'
		      }
		    },
		    'Traffic_1500' => {
		      'PktCap' => {
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '3000+'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '4000+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'CoalwithStressOpt' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'CoalwithStressOpt',
		  'Summary' => 'Verify setting coalescing works with NetFailGPHeapAlloc' .
		               ' stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '53',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::CoalwithStressOpt',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'DisableEnablevNic'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'DisableEnablevNic',
		        'UDPTRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'DisableEnablevNic_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'EnablevNIC'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::CoalwithStressOpt",
		       }
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '16200',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '25'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'IGNORE',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    },
		    'UDPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '16384',
		      'toolname' => 'netperf',
		      'testduration' => '300',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '16384',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '8192',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::CoalwithStressOpt",
		       }
		    },
		    'DisableEnablevNic_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '25'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP'
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTU9000'
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
		      [
		        'TRAFFIC_1'
		      ],
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
		      [
		        'NetAdapter_2'
		      ],
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
		      ]
		    ],
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
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
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		    },
		    'Switch_2_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream,rr',
		      'testadapter' => 'vm.[1].vnic.[1]',
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_4_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
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
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '21600',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'PacketCap',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '1024,2048,4096,8000'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
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
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_6_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
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


		'NetDelayBhTxComplete' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'NetDelayBhTxComplete',
		  'Summary' => 'Verify IO with NetDelayBhTxComplete stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_E1000,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '160',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::NetDelayBhTxComplete',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'Switch_1'
		      ],
		      [
		        'gVLAN_Set'
		      ],
		      [
		        'TRAFFIC_InterfaceVlan'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'gVLAN_SUT_Disable'
		      ],
		      [
		        'gVLAN_Helper_Disable'
		      ],
		      [
		        'Switch_2'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetDelayBhTxComplete",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'noofoutbound' => '3',
		      'maxtimeout' => '108000',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'noofinbound' => '3',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '131072'
		    },
		    'TRAFFIC_InterfaceVlan' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'noofoutbound' => '3',
		      'maxtimeout' => '108000',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'noofinbound' => '3',
		      'sendmessagesize' => '131072',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'Switch_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'gVLAN_Set' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		       'vlaninterface' => {
		        '[1]' => {
		          'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        }
		     }
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetDelayBhTxComplete",
		       }
		    },
		     'gVLAN_SUT_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' =>'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		     'gVLAN_Helper_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' =>'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		  }
		},


		'LinkStateChnge' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LinkStateChnge',
		  'Summary' => 'Verify link state during power on, suspend operations' .
		               ' works fine.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_E1000,LIN_VMXNET3_BOTH',
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
		  'ParentTDSID' => '86',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LinkStateChnge',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'VerifyPingPass'
		      ],
		      [
		        'PowerOff'
		      ],
		      [
		        'DisconnectvNic'
		      ],
		      [
		        'PowerOn'
		      ],
		      [
		        'VerifyPingFail'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'VerifyPingPass'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'PowerOn'
		      ],
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'VerifyPingPass' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		    },
		    'PowerOff' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'poweroff'
		    },
		    'DisconnectvNic' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'VerifyPingFail' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'poweron'
		    },
		  }
		},


		'TxWithNetFailPortWorldAssoc' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortWorldAssoc',
		  'Summary' => 'Verify IO with NetFailPortWorldAssoc stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,' .
		            'CAT_WIN_E1000,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '55',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortWorldAssoc',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNICPass'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNICPass'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortWorldAssoc",
		       }
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'FAIL',
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '60',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortWorldAssoc",
		       }
		    },
		    'ConnectvNICPass' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PktCap',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
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
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
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
		      'sendmessagesize' => '500-1,20',
		      'noofinbound' => '1'
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
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


		'TxWithNetVmxnet3StopTxQueue' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3StopTxQueue',
		  'Summary' => 'Verify IO with NetVmxnet3StopTxQueue stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '147',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3StopTxQueue',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3StopTxQueue",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'verification' => 'Stats',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3StopTxQueue",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    }
		  }
		},


		'LROVmxnet3' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LROVmxnet3',
		  'Summary' => 'Verify LRO(Sw/Hw) is functional for vmxnet3 vNIC ' .
		               'over VGT and VST',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LROVmxnet3',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[1].vss.[2]'
		          },
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
		          }
		        },
		        'vss' => {
		          '[2]' => {},
		          '[1]' => {
		            'configureuplinks' => 'add',
		            'vmnicadapter' => 'host.[1].vmnic.[1]'
		          }
		        },
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigurePG2'
		      ],
		      [
		        'ChangePG2'
		      ],
		      [
		        'DisableHwLRO'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ],
		      [
		        'Switch_1'
		      ],
		      [
		        'Switch_2'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'gVLAN'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ],
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'Switch_3'
		      ],
		      [
		        'Switch_4'
		      ],
		      [
		        'Switch_5'
		      ],
		      [
		        'Switch_6'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ],
		      [
		        'DisableLRO'
		      ],
		      [
		        'TRAFFIC_NoLRO'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'gVLAN_Disable'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'EnableHwLRO'
		      ],
		      [
		        'Switch_3'
		      ],
		      [
		        'Switch_4'
		      ]
		    ],
		    'ConfigurePG2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'testpglro2',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePG2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'DisableHwLRO' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'disable'
		    },
		    'EnableLRO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'sleepbetweenworkloads' => '15',
		      'iterations' => '1',
		      'lro' => 'Enable'
		    },
		    'TRAFFIC_LRO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_LRO',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '4096,32768,65536'
		    },
		    'DisableLRO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'sleepbetweenworkloads' => '30',
		      'iterations' => '1',
		      'lro' => 'Disable'
		    },
		    'TRAFFIC_NoLRO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_NoLRO',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '4096,65536'
		    },
		    'Switch_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => '4095'
		    },
		    'gVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		    },
		    'gVLAN_Disable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => '0'
		    },
		    'Switch_3' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_4' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => '0'
		    },
		    'Switch_5' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		    },
		    'Switch_6' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[3]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		    },
		    'EnableHwLRO' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'enable'
		    },
		    'Verification_LRO' => {
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.pktsRxOK' => '10000+',
		        'Target' => 'dst',
		        'verificationtype' => 'vsish'
		      }
		    },
		    'Verification_NoLRO' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'avgpktlen' => '1450-1515',
		        'retransmission' => '5-',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '1514',
		        'pktcount' => '1000+',
		        'badpkt' => '0',
		        'minpktsize' => '1000-'
		      },
		      'Vsish' => {
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.pktsRxOK' => '10000+',
		        'Target' => 'dst',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/rxSummary.LRO pkts rx ok' => 'nochange',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'IOWithPGChngWithSR' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices,CAT_WIN_E1000,CAT_WIN_E1000E,' .
		                'CAT_WIN_VMXNET2',
		  'TestName' => 'IOWithPGChngWithSR',
		  'Summary' => 'Verify changing port group when VM suspended while IO ' .
		               'was in progress and reconnecting the port group resumes IO',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '157',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOWithPGChngWithSR',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC',
		        'Suspend',
		        'Resume'
		      ],
		      [
		        'Suspend'
		      ],
		      [
		        'Addswitch'
		      ],
		      [
		        'AddVssPortgroup'
		      ],
		      [
		        'ChangePortgroup'
		      ],
		      [
		        'Deleteswitch'
		      ],
		      [
		        'Resume2'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'ConnectvNIC1'
		      ],
		      [
		        'ConnectvNIC2'
		      ],
		      [
		        'TRAFFIC_2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Resume2'
		      ],
		      [
		        'ConnectvNIC1'
		      ],
		      [
		        'ConnectvNIC2'
		      ]
		    ],
		    'ConfigureIP' => CONFIGURE_IP ,
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
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Suspend' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '200',
		      'iterations' => '1',
		      'vmstate' => 'suspend'
		    },
		    'Resume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '600',
		      'iterations' => '1',
		      'vmstate' => 'resume'
		    },
		    'Addswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'vss' => {
		        '[2]' => {}
		      }
		    },
		    'AddVssPortgroup' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'portgroup' => {
		        '[2]' => {
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[2]',
		    },
		    'Deleteswitch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'deletevss' => 'host.[1].vss.[2]'
		    },
		    'Resume2' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'resume'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '60',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'toolname' => 'ping'
		    },
		    'ConnectvNIC1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'portgroup' => 'host.[1].portgroup.[1]',
		      'connected' => '1',
		      'reconfigure' => 'true'
		    },
		    'ConnectvNIC2' => {
		     'Type' => 'NetAdapter',
		     'TestAdapter' => 'vm.[2].vnic.[1]',
		     'portgroup' => 'host.[1].portgroup.[1]',
		     'connected' => '1',
		     'reconfigure' => 'true'
		    },
		    'TRAFFIC_2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
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


		'TxWithNetE1000ForceLargeHdrCopy' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetE1000ForceLargeHdrCopy',
		  'Summary' => 'Verify IO with NetE1000ForceLargeHdrCopy stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_E1000',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetE1000ForceLargeHdrCopy',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceLargeHdrCopy",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceLargeHdrCopy",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    }
		  }
		},


		'TxRxHangWithStressOption' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxRxHangWithStressOption',
		  'Summary' => 'Verify IO works seamlessly with NetVmxnet3StopTxQueue, ' .
		               'NetVmxnet3StopRxQueue stress options',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxRxHangWithStressOption',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStressTx'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStressTx'
		      ],
		      [
		        'EnableStressRx'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'DisableStressRx'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStressTx'
		      ],
		      [
		        'DisableStressRx'
		      ]
		    ],
		    'EnableStressTx' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetVmxnet3StopTxQueue",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4094,131072',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStressTx' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetVmxnet3StopTxQueue",
		       }
		    },
		    'EnableStressRx' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetVmxnet3StopRxQueue",
		       }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'sendmessagesize' => '4094,131072',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStressRx' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::NetVmxnet3StopRxQueue",
		       }
		    }
		  }
		},


		'IPV6LPD' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IPV6LPD',
		  'Summary' => 'Verify vmxnet2\'s LPD for TSO6',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IPV6LPD',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableTSO'
		      ],
		      [
		        'EnableLRO'
		      ],
		      [
		        'TRAFFIC_LRO'
		      ]
		    ],
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		      'ipv4' => 'AUTO'
		    },
		    'EnableLRO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'configure_offload' =>{
		         'offload_type' => 'lro',
		         'enable'       => 'true',
		      },
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC_LRO' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_LPD',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '4096,32768,65536'
		    },
		    'Verification_LPD' => {
		      'PktCap' => {
		        'Target' => 'dst',
		        'avgpktlen' => '4000+',
		        'retransmission' => '5-',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '9000+',
		        'pktcount' => '1000+',
		        'badpkt' => '0',
		        'minpktsize' => '1000-'
		      }
		    }
		  }
		},


		'LinkStateCheckwithSR' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LinkStateCheckwithSR',
		  'Summary' => 'Verify connectivity across VM SR.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_VMNET2,' .
		            'CAT_WIN_E1000,LIN_VMXNET3_BOTH',
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
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LinkStateCheckwithSR',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],

		      [
		        'TRAFFIC'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'ConfigureIP' => CONFIGURE_IP ,
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'suspend,resume'
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]',

		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'MultiTxQueue_MSIX_ICMP' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiTxQueue_MSIX_ICMP',
		  'Summary' => 'Enables/disables Multi Tx Queue and tests ICMPTraffic ' .
		               'aross multiple queueswith MSIx Interrupt.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration,SMP',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiTxQueue_MSIX_ICMP',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'MSIX'
		      ],
		      [
		        'MultiQueueTxICMP',
		        'MultiQueueRxICMP',
		      ],
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'MultiQueueTxICMP',
		        'MultiQueueRxICMP',
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'DisableMultiTxQueues',
		        'DisableMultiRxQueues',
		      ],
		      [
		        'DisableRSS'
		      ],
		      [
		        'DefaultIntrMode'
		      ]
		    ],
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'MSIX' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    },
		    'MultiQueueTxICMP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'verification' => 'ICMPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,,8,4',
		      },
		      'iterations' => '1'
		    },
		    'MultiQueueRxICMP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,8,4',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableMultiTxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		    },
		    'DisableMultiRxQueues' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1',
		      },
		      'iterations' => '1',
		      'sleepbetweenworkloads' => '60',
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    },
		    'DefaultIntrMode' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'intrmode' => 'AUTO-MSIX'
		    }
		  }
		},


		'TxWithNetFailNDiscHeapAlloc' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailNDiscHeapAlloc',
		  'Summary' => 'Verify IO with NetFailNDiscHeapAlloc stress option',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_E1000,CAT_WIN_E1000,CAT_WIN_VMXNET2,' .
		            'CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailNDiscHeapAlloc',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {
		        'portgroup' => {
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
		        }
		      }
		    },
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'UplinkpNIC'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'UnlinkpNIC'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailNDiscHeapAlloc",
		       }
		    },
		    'UplinkpNIC' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailNDiscHeapAlloc",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'UnlinkpNIC' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    }
		  }
		},


		'LoadUnloadStress' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'LoadUnloadStress',
		  'Summary' => 'Verify loading and unloading the driver multiple times ' .
		               'doesn\'t crash/wedge',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Stress,WindowsNotSupported,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::LoadUnloadStress',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LoadUnload'
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
		        'LoadUnload_1'
		      ]
		    ],
		    'LoadUnload' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		      'iterations' => '3'
		    },
		    'ConfigureIP' => CONFIGURE_IP,
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'LoadUnload_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'IO_RSS' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IO_RSS',
		  'Summary' => 'Verifies the robustness of RSS IO Path.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IO_RSS',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1-2]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-2]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'TCPIPV4'
		      ],
		      [
		        'UDPTraffic'
		      ],
		      [
		        'IPV6'
		      ],
		      [
		        'ICMP'
		      ],
		      [
		        'ICMPIGNORE',
		        'DisableEnableRSS'
		      ],
		      [
		        'Switch_1'
		      ],
		      [
		        'Switch_2'
		      ],
		      [
		        'MTU9000'
		      ],
		      [
		        'UDPTraffic'
		      ],
		      [
		        'IPV6'
		      ],
		      [
		        'ICMP'
		      ],
		      [
		        'ICMPIGNORE',
		        'DisableEnableRSS'
		      ],
		      [
		        'MTU1500'
		      ],
		      [
		        'Switch_3'
		      ],
		      [
		        'Switch_4'
		      ],
		      [
		        'CSODisableTx',
		        'CSODisableRx',
		      ],
		      [
		        'TCPIPV4'
		      ],
		      [
		        'UDPTraffic'
		      ],
		      [
		        'IPV6'
		      ],
		      [
		        'ICMP'
		      ],
		      [
		        'CSOEnableTx',
		        'CSOEnableRx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'Switch_5'
		      ],
		      [
		        'Switch_6'
		      ],
		      [
		        'gVLAN',
		        'EnableTSO',
		      ],
		      [
		        'gVLANDisable'
		      ],
		      [
		        'TCPIPV4'
		      ],
		      [
		        'UDPTraffic'
		      ],
		      [
		        'IPV6'
		      ],
		      [
		        'ICMP'
		      ],
		      [
		        'ICMPIGNORE',
		        'DisableEnableRSS'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableRSS'
		      ],
		      [
		        'CSOEnableTx',
		        'CSOEnableRx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ]
		    ],
		    'CSODisableTx' => CSO_DISABLE_TX,
		    'CSODisableRx' => CSO_DISABLE_RX,
		    'CSOEnableTx' => CSO_ENABLE_TX,
		    'CSOEnableRx' => CSO_ENABLE_RX,
		    'EnableTSO' => ENABLE_TSO,
		    'EnableSG' => ENABLE_SG,
		    'EnableTSO' => ENABLE_TSO,
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'TCPIPV4' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '6',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats_Verify',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '8192',
		      'noofinbound' => '6',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'UDPTraffic' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '16384',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '8',
		      'remotesendsocketsize' => '16384',
		      'verification' => 'Stats_Verify',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '8192',
		      'noofinbound' => '8',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'IPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '5',
		      'remotesendsocketsize' => '65536',
		      'verification' => 'Stats_Verify',
		      'l3protocol' => 'ipv6',
		      'sendmessagesize' => '16384',
		      'noofinbound' => '5',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'ICMP' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'testduration' => '60',
		      'routingscheme' => 'unicast',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '20',
		      'maxtimeout' => '21600',
		      'noofinbound' => '20',
		      'L3Protocol'     => 'ipv4,ipv6',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'ICMPIGNORE' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'testduration' => '60',
		      'routingscheme' => 'unicast',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'noofoutbound' => '20',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '21600',
		      'noofinbound' => '20',
		      'supportadapter' => 'vm.[1].vnic.[2]'
		    },
		    'DisableEnableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'maxtimeout' => '10800',
		      'setrss' => 'Disable,Enable',
		      'iterations' => '30'
		    },
		    'Switch_1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'Switch_2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'MTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_3' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_4' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_5' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_6' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'gVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		      'sleepbetweenworkloads' => '60',
		    },
		    'gVLANDisable' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => '0'
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    },
		    'Stats_Verify' => {
		      'Vsish' => {
		        'dst./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesRxOK' => '10000+',
		        'Target' => 'src,dst',
		        'verificationtype' => 'vsish',
		        'src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        'src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK' => '10000+'
		      }
		    }
		  }
		},


		'TSOSGBoundaryTest' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TSOSGBoundaryTest',
		  'Summary' => 'Verify TSO works fine with message sizes that span ' .
		               'SG list boundaries.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,' .
		            'CAT_LIN_VMNET2,CAT_WIN_E1000E,CAT_WIN_E1000,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '95',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TSOSGBoundaryTest',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP',
		      ],

		      [
		        'EnableTSO'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'TCPTRAFFIC'
		      ]
		    ],
		    'EnableTSO' => ENABLE_TSO ,
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'Ping' => PING_TRAFFIC,
		    'TCPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'bursttype' => 'stream',
		      'maxtimeout' => '18000',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Traffic_Verification',
		      'l4protocol' => 'tcp',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'sendmessagesize' => '16384,32444,48504,64564,80624,96684,112744,128804'
		    },
		    'Traffic_Verification' => {
		      'PktCap' => {
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap',
		        'maxpktsize' => '9000+'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '10000+',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '10000+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'ConfigureIPInDisconnectedState' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ConfigureIPInDisconnectedState',
		  'Summary' => 'Verify configuring IP address when the link state is ' .
		               'disconnected works fine.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_E1000,CAT_WIN_E1000,LIN_VMXNET3_BOTH',
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
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::ConfigureIPInDisconnectedState',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'DisableEnablevNic'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'Traffic_Ping'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'ConfigureIP'=> CONFIGURE_IP ,
		    'Traffic_Ping' => PING_TRAFFIC,
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'iterations' => '1',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Ping' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'iterations' => '1',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '1'
		    },
		  }
		},


		'MultiTxQueueIntrusive' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'MultiTxQueueIntrusive',
		  'Summary' => 'Enables/disables Multi Tx Queue and simultaneously ' .
		               'performsEnable/Disable vNIC,enable/disable TSO &suspend' .
		               '/resume/snapshot/revert operations aross multiple queues.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'LongDuration,SMP',
		  'Version' => '2',
		  'Environment' => {
		    'NOOFMACHINES' => '2',
		    'Build' => 'NA',
		    'Platform' => 'ESX/ESXi',
		    'DriverVersion' => 'NA',
		    'GOS' => 'NA',
		    'Version' => 'NA',
		    'ToolsVersion' => 'NA',
		    'Driver' => 'vmxnet3',
		    'Setup' => 'INTER/INTRA'
		  },
		  'ParentTDSID' => '3.4',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::MultiTxQueueIntrusive',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1-2]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-2]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'RSS'
		      ],
		      [
		        'EnableTxQueue',
		        'DisableEnablevNic'
		      ],
		      [
		        'DisableTxQueue'
		      ],
		      [
		        'EnableTxQueue',
		        'DisableTSO',
		        'EnableTSO',
		      ],
		      [
		        'DisableTxQueue'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'EnableTxQueue'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableTxQueue'
		      ],
		      [
		        'DisableRSS'
		      ],
		      [
		        'SnapshotDelete'
		      ]
		    ],
		    'RSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Enable',
		      'iterations' => '1'
		    },
		    'EnableTxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'verification' => 'ICMPTraffic',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,8,4',
		      },
		      'iterations' => '1'
		    },
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'DOWN,UP',
		      'iterations' => '1'
		    },
		    'DisableTxQueue' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1',
		      },
		    },
		    'DisableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'configure_offload' =>{
		        'offload_type' => 'tsoipv4',
		        'enable'       => 'false',
		      },
		      'iterations' => '1'
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'configure_offload' =>{
		        'offload_type' => 'tsoipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1'
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'iterations' => '1',
		      'vmstate' => 'suspend,resume'
		    },
		    'SnapshotRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'tso_srd',
		      'iterations' => '1',
		      'snapshot' => 'create,revert',
		      'waitforvdnet' => 'true'
		    },
		    'SnapshotDelete' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'tso_srd',
		      'iterations' => '1',
		      'snapshot' => 'delete',
		      'waitforvdnet' => 'true'
		    },
		    'DisableRSS' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'Disable',
		      'iterations' => '1'
		    }
		  }
		},


		'InboundIOWithSO' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'InboundIOWithSO',
		  'Summary' => 'Verify IO with NetVmxnet3FailMapNextChunk and ' .
		               'NetVmxnet3KsegPartialRxBuf stress options.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '160',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::InboundIOWithSO',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::InboundIOwithSO",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '32400',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Stats',
		      'sendmessagesize' => '8192,65536,131072',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::InboundIOwithSO",
		       }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'verification' => 'Stats',
		      'testduration' => '120',
		      'toolname' => 'netperf',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    }
		  }
		},


		'IOwithNetFailPortEnable' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOwithNetFailPortEnable',
		  'Summary' => 'Verify IO with NetFailPortEnable set to 1 doesn\'t' .
		               ' wedge or panic.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_E1000,CAT_WIN_E1000,CAT_WIN_E1000E,' .
		            'CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '155',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOwithNetFailPortEnable',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortEnable",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '32768',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '4',
		      'remotesendsocketsize' => '32768',
		      'verification' => 'PktCap',
		      'sendmessagesize' => '32768',
		      'noofinbound' => '4',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortEnable",
		       }
		    }
		  }
		},


		'WOL' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'WOL',
		  'Summary' => 'This test verifies that WOL works fine.',
		  'ExpectedResult' => 'PASS',
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
		  'ParentTDSID' => '5.15',
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::WOL',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'WoLTest'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'WoLTest' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'wol' => 'ARP,MAGIC'
		    }
		  }
		},


		'TxWithNetDelayProcessDeferredInput' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetDelayProcessDeferredInput',
		  'Summary' => 'Verify IO with NetDelayProcessDeferredInput stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '146',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetDelayProcessDeferredInput',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetDelayProcessDeferredInput",
		       }
		     },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,65536',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'stress' => 'Disable',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetDelayProcessDeferredInput",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'verification' => 'PktCap',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '8192,16384,32768,65536',
		      'noofinbound' => '3'
		    }
		  }
		},


		'TxWithNetForcePktSGSpanPages' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetForcePktSGSpanPages',
		  'Summary' => 'Verify IO with NetForcePktSGSpanPages stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_WIN_E1000,' .
		            'CAT_WIN_E1000E,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetForcePktSGSpanPages',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetForcePktSGSpanPages",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetForcePktSGSpanPages",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TCPTraffic'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
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
		      'testadapter' => 'vm.[1].vnic.[1]',
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


		'TxWithNetFailPortsetEnablePort' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailPortsetEnablePort',
		  'Summary' => 'Verify IO with NetFailPortsetEnablePort stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '71',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailPortsetEnablePort',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNICFAIL'
		      ],
		      [
		        'VerifyPingFail'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'DisconnectvNIC'
		      ],
		      [
		        'ConnectvNIC'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'ConnectvNIC'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetEnablePort",
		       }
		    },
		    'DisconnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 0,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
		    },
		    'ConnectvNICFAIL' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'FAIL',
		      'iterations' => '1',
		    },
		    'VerifyPingFail' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailPortsetEnablePort",
		       }
		    },
		    'ConnectvNIC' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    }
		  }
		},


		'TxWithNetE1000ForceLowTcpUdpLen' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetE1000ForceLowTcpUdpLen',
		  'Summary' => 'Verify E1000 JF IO with NetE1000ForceLowTcpUdpLen ' .
		               'stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '124',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetE1000ForceLowTcpUdpLen',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTU9000'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DefaultMTU'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'DefaultMTU'
		      ]
		    ],
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '9000',
		      'ipv4' => 'AUTO'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceLowTcpUdpLen",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '2',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp,udp',
		      'sendmessagesize' => '128,256,1024,2048,4096,8192,65536',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DefaultMTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '1500'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000ForceLowTcpUdpLen",
		       }
		    }
		  }
		},


		'TxWithNetFailVmxnetPinBuffers' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetFailVmxnetPinBuffers',
		  'Summary' => 'Verify Tx with NetFailVmxnetPinBuffers stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'ParentTDSID' => '116',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetFailVmxnetPinBuffers',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC',
		        'Suspend',
		        'Resume'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC',
		        'Suspend',
		        'Resume'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'Resume'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailVmxnetPinBuffers",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'testduration' => '1200',
		      'toolname' => 'netperf',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'l4protocol' => 'tcp',
		      'noofinbound' => '3'
		    },
		    'Suspend' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '120',
		      'iterations' => '1',
		      'vmstate' => 'suspend'
		    },
		    'Resume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'sleepbetweenworkloads' => '600',
		      'iterations' => '1',
		      'vmstate' => 'resume'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disbale',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetFailVmxnetPinBuffers",
		       }
		    }
		  }
		},


		'TSOwith2powerNmsgsizes' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TSOwith2powerNmsgsizes',
		  'Summary' => 'Verify TSO with STD MTU and with 2 power N message sizes.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'LongDuration,LIN_VMXNET3_RELEASE',
		  'Version' => '2',
		  'ParentTDSID' => '99',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TSOwith2powerNmsgsizes',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TCPTraffic'
		      ]
		    ],
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TCPTraffic' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536,131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '2',
		      'maxtimeout' => '43200',
		      'remotesendsocketsize' => '65536,131072',
		      'verification' => 'Traffic_TSO',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '2048,4096,8192,16384,65536,63488',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '2'
		    },
		    'Traffic_TSO' => {
		      'PktCap' => {
		        'Target' => 'src',
		        'badpkt' => '0',
		        'pktcount' => '2000+',
		        'verificationtype' => 'pktcap'
		      },
		      'Vsish' => {
		        'Target' => 'src',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx' => '5-',
		        '/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTsoTxOK' => '10000+',
		        '/net/portsets/<PORTSET>/ports/<PORT>/vmxnet3/txsummary.TSO pkts tx ok' => '10000+',
		        'verificationtype' => 'vsish'
		      }
		    }
		  }
		},


		'BDTraffWithLoadUnload' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'BDTraffWithLoadUnload',
		  'Summary' => 'Verify data path works fine with load/unload operations.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::BDTraffWithLoadUnload',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LoadUnload',
		        'UDPTRAFFIC'
		      ],
		      [
		        'TCPTRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'LoadUnload_1'
		      ]
		    ],
		    'LoadUnload' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		      'iterations' => '25'
		    },
		    'UDPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '16384',
		      'toolname' => 'netperf',
		      'testduration' => '300',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '16384',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '8192',
		      'noofinbound' => '3'
		    },
		    'TCPTRAFFIC' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '3',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'noofinbound' => '3',
		      'bursttype' => 'stream'
		    },
		    'LoadUnload_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		    }
		  }
		},


		'TxWithNetVmxnet3KsegPartialRxBuf' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetVmxnet3KsegPartialRxBuf',
		  'Summary' => 'Verify IO with NetVmxnet3KsegPartialRxBuf stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_LIN_VMXNET3_G3,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '122',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3KsegPartialRxBuf',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3KsegPartialRxBuf",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3KsegPartialRxBuf",
		       }
		    },
		  }
		},


		'DriverReload' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'DriverReload',
		  'Summary' => 'Load the driver with the given command line ' .
		               'arguments (if any)',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,WindowsNotSupported,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::DriverReload',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DriverReload_1'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_2'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_3'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_4'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_5'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_6'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'DriverReload_7'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DriverReload_6'
		      ]
		    ],
		    'Iterations' => '1',
		    'DriverReload_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'tx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'verification' => 'PktCap',
		      'testduration' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'DriverReload_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setrss' => 'num_tqs:2::num_rqs:2::rss_ind_table:0:1:0:0:0:0:0:0:1:0:0:0:0:0:0:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0',
		      'iterations' => '1'
		    },
		    'DriverReload_3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
		      'set_intrmodparams' => 'num_tqs:2::num_rqs:2::share_tx_intr:1'
		    },
		    'DriverReload_4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
		      'set_intrmodparams' => 'num_tqs:2::num_rqs:2::buddy_intr:1'
		    },
		    'DriverReload_5' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
		      'set_intrmodparams' => 'num_tqs:2::num_rqs:2::share_tx_intr:1::buddy_intr:1'
		    },
		    'DriverReload_6' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reload_driver' => 'true',
		      'iterations' => '1'
		    },
		    'DriverReload_7' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'set_queues' => {
		         'direction' => 'rx',
		         'value'     => '1,2,4,8',
		      },
		      'iterations' => '1'
		    }
		  }
		},


		'Interop_SRD_Non_Ring' => {
		  'Component' => 'Vmxnet',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'Interop_SRD_Non_Ring',
		  'Summary' => 'Ensure driver works fine after snapshot revert delete ' .
		               'for non-support Ring.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Interop',
		  'Version' => '2',
		  'ParentTDSID' => '3.3',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::Interop_SRD_Non_Ring',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'MTU'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
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
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'SnapshotRevert'
		      ],
		      [
		        'SnapshotDelete'
		      ],
		      [
		        'Ping'
		      ]
		    ],
		    'ExitSequence' => [
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
		        'SnapshotDelete'
		      ]
		    ],
		    'Ping' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '2',
		      'testduration' => '20',
		      'toolname' => 'ping',
		      'noofinbound' => '3',
		      'pingpktsize' => '3000',
		      'L3Protocol'     => 'ipv4,ipv6',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		    },
		    'SnapshotRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'iterations' => '1',
		      'snapshot' => 'create,revert',
		      'waitforvdnet' => 'true'
		    },
		    'SnapshotDelete' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'name' => 'interop_srd',
		      'iterations' => '1',
		      'snapshot' => 'delete',
		      'waitforvdnet' => 'true'
		    },
		    'MTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'iterations' => '1',
		      'mtu' => '9000'
		    },
		    'Switch_1_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_1_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'Switch_2_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'Switch_2_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'vlan' => '113',
		      'mtu' => '9000'
		    },
		    'Switch_3_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_3_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'Switch_4_A' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    },
		    'Switch_4_B' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    }
		  }
		},


		'IOWithNetDelayBhRx' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'IOWithNetDelayBhRx',
		  'Summary' => 'Verify Tx with NetDelayBhRx stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_WIN_VMXNET2,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '109',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::IOWithNetDelayBhRx',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::IOWithNetDelayBhRx",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '64512',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'expectedresult' => 'IGNORE',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp,udp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,64512',
		      'noofinbound' => '3'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::IOWithNetDelayBhRx",
		       }
		    }
		  }
		},


		'TxWithNetVmxnet3FailMapNextChunk' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices,',
		  'TestName' => 'TxWithNetVmxnet3FailMapNextChunk',
		  'Summary' => 'Verify IO with NetVmxnet3FailMapNextChunk stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,,CAT_LIN_VMXNET3_G4,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '123',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetVmxnet3FailMapNextChunk',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailMapNextChunk",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'minexpresult' => '1',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetVmxnet3FailMapNextChunk",
		       }
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'remotesendsocketsize' => '131072',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '65536,131072',
		      'noofinbound' => '2',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    }
		  }
		},


		'TxWithNetPktDbgForceUseHeap' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetPktDbgForceUseHeap',
		  'Summary' => 'Verify IO with NetPktDbgForceUseHeap stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,' .
		            'CAT_WIN_E1000E,CAT_WIN_VMXNET2,LIN_VMXNET3_BETA',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetPktDbgForceUseHeap',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetPktDbgForceUseHeap",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '27000',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetPktDbgForceUseHeap",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536,131072'
		    }
		  }
		},


		'TxWithNetE1000FailTxZeroCopy' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'TxWithNetE1000FailTxZeroCopy',
		  'Summary' => 'Verify IO with NetE1000FailTxZeroCopy stress option.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'StressOption,CAT_WIN_E1000',
		  'Version' => '2',
		  'ParentTDSID' => '131',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::TxWithNetE1000FailTxZeroCopy',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableStress'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'TRAFFICIPV4andIPV6'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'TRAFFIC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'enable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000FailTxZeroCopy",
		       }
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFICIPV4andIPV6' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '900',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configure_stress' =>{
		          'operation' => 'Disable',
		          'stress_options' => "%VDNetLib::TestData::" .
		             "StressTestData::TxWithNetE1000FailTxZeroCopy",
		       }
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'noofoutbound' => '3',
		      'maxtimeout' => '10800',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv4,ipv6',
		      'sendmessagesize' => '32768,65536'
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
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
		      ]
		    ],
		    'DisableEnablevNic' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'maxtimeout' => '16200',
		      'devicestatus' => 'DOWN,UP',
		      'sleepbetweencombos' => '10',
		      'iterations' => '25'
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'verification' => 'PacketCapture',
		      'testduration' => '60',
		      'sleepbetweencombos' => '60',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'toolname' => 'netperf'
		    },
		    'EnablevNIC' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'UP'
		    },
		    'PacketCapture' => {
		      'Pktcap' => {
		        'pktcapfilter' => 'count 1500',
		        'Target' => 'src',
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'ZeroLengthFragswithJF' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ZeroLengthFragswithJF',
		  'Summary' => 'Verify bi-directional IO with 0 length fragments with JF.',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'Functional,CAT_WIN_VMXNET3,CAT_LIN_VMXNET3,CAT_LIN_VMXNET2,' .
		            'CAT_WIN_E1000E,CAT_LIN_E1000,CAT_WIN_E1000,LIN_VMXNET3_BOTH',
		  'Version' => '2',
		  'ParentTDSID' => '101',
		  'testID' => 'TDS::VirtualNetDevices::VDCommon::ZeroLengthFragswithJF',
		  'TestbedSpec' => {
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1]'
		      }
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
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'MTU1500'
		      ],
		      [
		        'TRAFFIC'
		      ],
		      [
		        'MTU9000'
		      ],
		      [
		        'TRAFFIC_JF'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'MTU1500'
		      ]
		    ],
		    'MTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500',
		      'ipv4' => 'AUTO'
		    },
		    'TRAFFIC' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '0',
		      'localsendsocketsize' => '10',
		      'toolname' => 'netperf',
		      'testduration' => '600',
		      'noofoutbound' => '5',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '10',
		      'verification' => 'PktCap',
		      'sendmessagesize' => '0',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '5'
		    },
		    'MTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'TRAFFIC_JF' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '0',
		      'localsendsocketsize' => '10',
		      'toolname' => 'netperf',
		      'testduration' => '600',
		      'noofoutbound' => '5',
		      'expectedresult' => 'IGNORE',
		      'remotesendsocketsize' => '10',
		      'verification' => 'PktCap',
		      'sendmessagesize' => '0',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofinbound' => '5'
		    }
		  }
		},


      'VerifyAdapterInfo' => {
        'Component' => 'Vmxnet3',
        'Category'  => 'Virtual Net Devices',
        'TestName'  => 'CheckPortAdditionAndDeletion',
        'Summary'  => 'Validates the port addition and deletion',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'precheckin',
        'Version' => '2',
        'ParentTDSID' => '',
        'testID' => '',
        'TestbedSpec' => {
          'vm' => {
            '[1]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[1].portgroup.[1]',
                  'driver' => 'vmxnet3'
                }
              },
              'host' => 'host.[1]'
            }
          },
          'host' => {
            '[1]' => {
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]'
                }
              },
              'vss' => {
                '[1]' => {}
              }
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            ['HotAddVnic2'],
            ['ReadActiveAdapter'],
            ['FLAPvNIC'],
            ['DisconnectConnectVnic1'],
            ['ReadActiveAdapterAfterDisconnectConnectVnic1'],
            ['VerifiyActiveAdapterBeforeDeletion'],
            ['DeleteVnic2'],
            ['VerifiyActiveAdapterAfterDeletion']
          ],
          'HotAddVnic2' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'vnic' => {
              '[2]' => {
                'portgroup' => 'host.[1].portgroup.[1]',
                'driver' => 'vmxnet3'
              }
            },
          },
          'ReadActiveAdapter' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].vnic.[2]',
            'PersistData' => 'Yes',
            'read_adapter' => {
               'macaddress[?]defined' => '', #unary operator, dont fil RHS
               'portid[?]defined' => '',
               'vswitch[?]defined' => '',
               'portgroup[?]defined' => '',
               'dvportid[?]not_defined' => '',
               'ipaddress[?]defined' => '',
               'teamuplink[?]defined' => '',
               'uplinkportid[?]defined' => '',
               'activefilters[?]not_defined' => '',
            },
          },
          'FLAPvNIC' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].vnic.[2]',
            'devicestatus' => 'DOWN,UP'
          },
          'DisconnectConnectVnic1' => {
            'Type' => 'NetAdapter',
            'reconfig' => 'true',
            'operation' => '0,1',
            'testadapter' => 'vm.[1].vnic.[2]'
          },
          'ReadActiveAdapterAfterDisconnectConnectVnic1' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'vm.[1].vnic.[2]',
            'PersistData' => 'Yes',
            'read_adapter' => {
               'macaddress[?]equal_to' => 'vm.[1].vnic.[2]->read->macaddress',
               'portid[?]not_equal_to' => 'vm.[1].vnic.[2]->read->portid',
               'vswitch[?]equal_to' => 'vm.[1].vnic.[2]->read->vswitch',
               'portgroup[?]equal_to' => 'vm.[1].vnic.[2]->read->portgroup',
               'dvportid[?]equal_to' => 'vm.[1].vnic.[2]->read->dvportid',
               'ipaddress[?]equal_to' => 'vm.[1].vnic.[2]->read->ipaddress',
               'teamuplink[?]equal_to' => 'vm.[1].vnic.[2]->read->teamuplink',
               'uplinkportid[?]equal_to' => 'vm.[1].vnic.[2]->read->uplinkportid',
               'activefilters[?]equal_to' => 'vm.[1].vnic.[2]->read->activefilters',
            },
          },
          'VerifiyActiveAdapterBeforeDeletion' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'queryadapters[?]contain_once' => [{
               'macaddress' => 'vm.[1].vnic.[2]->read->macaddress',
               'portid' => 'vm.[1].vnic.[2]->read->portid',
               'vswitch' => 'vm.[1].vnic.[2]->read->vswitch',
               'portgroup' => 'vm.[1].vnic.[2]->read->portgroup',
               'dvportid' => 'vm.[1].vnic.[2]->read->dvportid',
               'ipaddress' => 'vm.[1].vnic.[2]->read->ipaddress',
               'teamuplink' => 'vm.[1].vnic.[2]->read->teamuplink',
               'uplinkportid' => 'vm.[1].vnic.[2]->read->uplinkportid',
               'activefilters' => 'vm.[1].vnic.[2]->read->activefilters',
            },],
          },
          'DeleteVnic2' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'deletevnic' => 'vm.[1].vnic.[2]',
            'SkipPostProcess' => "1",
          },
          'VerifiyActiveAdapterAfterDeletion' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'queryadapters[?]not_contains' => [{
               'macaddress' => 'vm.[1].vnic.[2]->read->macaddress',
               'portid' => 'vm.[1].vnic.[2]->read->portid',
            },],
          },
        },
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
   my $self = $class->SUPER::new(\%VDCommon);
   if ($self eq FAILURE) {
      print "error ". VDGetLastError() ."\n";
      VDSetLastError(VDGetLastError());
   }
   return (bless($self, $class));
}

1;
