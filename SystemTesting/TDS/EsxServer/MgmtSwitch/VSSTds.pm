#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::MgmtSwitch::VSSTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %VSS = (
		'PromiscuousMode' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'PromiscuousMode',
		  'Summary' => 'Test security options of VSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
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
		        'DisablePromiscuous'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'EnablePromiscuous'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'DisablePromiscuous' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setpromiscuous' => 'disable'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => 10,
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => 1,
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'FAIL',
		      'verification' => 'pktcap',
		      'noofinbound' => 1,
		      'supportadapter' => 'host.[1].vmknic.[1],vm.[3].vnic.[1]'
		    },
		    'EnablePromiscuous' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setpromiscuous' => 'Enable'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '10',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktcap',
		      'noofinbound' => '1',
		      'supportadapter' => 'host.[1].vmknic.[1],vm.[3].vnic.[1]'
		    }
		  }
		},


 		'Failover-NotifySwitches' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Failover-NotifySwitches',
		  'Summary' => 'Test the Notify Switches option of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'physicalonly',
		  'Version' => '2',
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
		            'vmnicadapter' => 'host.[1].vmnic.[1-2]'
		          }
		        },
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'pswitchport' => {
		          '[2]' => {
		            'vmnic' => 'host.[1].vmnic.[2]'
		          },
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnablePort1'
		      ],
		      [
		        'SetFailover1'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'VerifyvNicPort1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1',
		      ],
		      [
		        'DisablePort1'
		      ],
		      [
		        'VerifyvNicPort2'
		      ],
		      [
		        'EnablePort1'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'VerifyvNicPort1'
		      ],
		      [
		        'DisableNotify'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1',
		      ],
		      [
		        'DownvNic',
		      ],
		      [
		        'DisablePort1'
		      ],
		      [
		        'VerifyvNicPortFail'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'UpvNic',
		      ],
		      [
		        'EnablePort1'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'EnablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'portstatus' => 'enable'
		    },
		    'SetFailover1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setfailoverorder' => 'host.[1].vmnic.[1];;host.[1].vmnic.[2]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'explicit',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'VerifyvNicPort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'portstatus' => 'disable',
		    },
		    'VerifyvNicPort2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
		    },
		    'DisableNotify' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'explicit',
		      'notifyswitch' => 'no',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
                    'DownvNic' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[1].vnic.[1]',
                      'devicestatus' => 'DOWN'
                    },
                    'UpvNic' => {
                      'Type' => 'NetAdapter',
                      'TestAdapter' => 'vm.[1].vnic.[1]',
                      'devicestatus' => 'UP'
                    },
		    'VerifyvNicPortFail' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'expectedresult' => 'FAIL',
		      'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
		    }
		  }
		},

		'Vmotion' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'Vmotion',
		  'Summary' => 'Exercises the Vmotion functionality for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'BAT,vmotion,batwithvc,physicalonly',
		  'Version' => '2',
		  'TestbedSpec' => {
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[2].vss.[1]'
		          },
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]',
                            'name' => 'vmotion-network'
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
		            'vss' => 'host.[1].vss.[1]',
                            'name' => 'vmotion-network'
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
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'vc' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'CreateDC'
		      ],
		      [
		        'ConfigureVMForvMotion'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'DisableVmkStress1'
		      ],
		      [
		        'DisableVmkStress2'
		      ],
		      [
		        'Traffic_1',
		        'DoVmotion_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnableVmkStress1'
		      ],
		      [
		        'EnableVmkStress2'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1],host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'CreateDC' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'maxtimeout' => '600',
		      'datacenter' => {
		        '[1]' => {
		          'name' => 'vssdctest',
		          'host' => 'host.[1].x.[x];;host.[2].x.[x]'
		        }
		      }
		    },
		    'ConfigureVMForvMotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'operation' => 'configurevmotion'
		    },
		    'EnableVMotion1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.3'
		    },
		    'EnableVMotion2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => '192.168.111.4'
		    },
		    'DisableVmkStress1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 0'
                      }
		    },
		    'DisableVmkStress2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 0'
                      }
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'toolname' => 'netperf',
		      'testduration' => '180',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DoVmotion_1' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'sleepbetweenworkloads' => '30',
		      'dsthost' => 'host.[2].x.[x]',
		      'iterations' => '3',
		      'staytime' => '60'
		    },
		    'EnableVmkStress1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 1'
                      }
		    },
		    'EnableVmkStress2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 1'
                      }
		    }
		  }
		},


		'Vmotion_IPv6' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'Vmotion',
		  'Summary' => 'Exercises the Vmotion functionality for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Version' => '2',
		  'TestbedSpec' => {
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[2].vss.[1]'
		          },
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]',
                            'name' => 'vmotion-network'
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
		            'vss' => 'host.[1].vss.[1]',
                            'name' => 'vmotion-network'
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
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'vc' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'CreateDC'
		      ],
		      [
		        'ConfigureVMForvMotion'
		      ],
		      [
		        'NetAdapter_Auto'
		      ],
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'DisableVmkStress1'
		      ],
		      [
		        'DisableVmkStress2'
		      ],
		      [
		        'Traffic_1',
		        'DoVmotion_1'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'EnableVmkStress1'
		      ],
		      [
		        'EnableVmkStress2'
		      ]
		    ],
		    'NetAdapter_Auto' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'auto'
		    },
		    'CreateDC' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'maxtimeout' => '600',
		      'datacenter' => {
		        '[1]' => {
		          'name' => 'vssdctest',
		          'host' => 'host.[1].x.[x];;host.[2].x.[x]'
		        }
		      }
		    },
		    'ConfigureVMForvMotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'operation' => 'configurevmotion'
		    },
		    'EnableVMotion1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'static'
		    },
		    'EnableVMotion2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'static'
		    },
		    'DisableVmkStress1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 0'
                      }
		    },
		    'DisableVmkStress2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 0'
                      }
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l3protocol' => 'ipv4,ipv6',
		      'l4protocol' => 'tcp,udp',
		      'toolname' => 'netperf',
		      'testduration' => '80',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DoVmotion_1' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'sleepbetweenworkloads' => '30',
		      'dsthost' => 'host.[2].x.[x]',
		      'iterations' => '5',
		      'staytime' => '60'
		    },
		    'EnableVmkStress1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 1'
                      }
		    },
		    'EnableVmkStress2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '/config/Misc/intOpts/VmkStressEnable = 1'
                      }
		    },
		  }
		},


		'VLAN' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'VLAN',
		  'Summary' => 'Test the VLAN function of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
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
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HelperSVLAN4095'
		      ],
		      [
		        'SUTSVLAN302'
		      ],
		      [
		        'HelperVnicgVLAN302'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'SUTSVLAN303'
		      ],
		      [
		        'HelperVnicgVLAN303'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'SUTSVLAN301'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'HelperVnicgVLAN0'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1],vm.[3].vnic.[1].vlaninterface.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'HelperSVLAN4095' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[2].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'SUTSVLAN302' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
		    },
		    'HelperVnicgVLAN302' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'vlaninterface' => {
		          '[1]' => {
		              'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                              'ipv4' => 'dhcp'
		          },
		      },
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'l3protocol' => 'ipv4,ipv6',
		      'expectedresult' => 'PASS',
		      'toolname' => 'netperf',
		      'testduration' => 60,
		      'noofinbound' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'SUTSVLAN303' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
		    },
		    'HelperVnicgVLAN303' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'vlaninterface' => {
		          '[1]' => {
		              'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
                              'ipv4' => 'dhcp'
		          },
		      },
		    },
		    'SUTSVLAN301' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'expectedresult' => 'FAIL',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'HelperVnicgVLAN0' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'deletevlaninterface' => 'vm.[3].vnic.[1].vlaninterface.[1]',
		    }
		  }
		},


		'MACAddressChanges' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'MACAddressChanges',
		  'Summary' => 'Test security options of VSS, mac address change',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
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
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'ChangeMACAddr'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'RejectMACChange'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'AcceptMACChange'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ResetMACAddr'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => 60,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => 1,
		      'expectedresult' => 'PASS',
		      'sleepbetweencombos' => '25',
		      'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1],host.[1].vmknic.[1]'
		    },
		    'ChangeMACAddr' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setmacaddr' => '00:11:22:33:44:66'
		    },
		    'RejectMACChange' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setmacaddresschange' => 'Disable'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'expectedresult' => 'FAIL',
		      'testduration' => 60,
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1],host.[1].vmknic.[1]'
		    },
		    'AcceptMACChange' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setmacaddresschange' => 'Enable'
		    },
		    'ResetMACAddr' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setmacaddr' => 'reset'
		    }
		  }
		},


		'ForgedTransmit' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'ForgedTransmit',
		  'Summary' => 'Test security options of VSS, forged transmit',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
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
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'ChangeMACAddr'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'RejectForgedTx'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'AcceptForgedTx'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ResetMACAddr'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => 60,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'noofoutbound' => 1,
		      'sleepbetweencombos' => '15',
		      'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
		    },
		    'ChangeMACAddr' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setmacaddr' => '00:11:22:33:44:66'
		    },
		    'RejectForgedTx' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setforgedtransmit' => 'Disable'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'expectedresult' => 'FAIL',
		      'testduration' => 60,
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1],host.[1].vmknic.[1]'
		    },
		    'AcceptForgedTx' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setforgedtransmit' => 'Enable'
		    },
		    'ResetMACAddr' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'setmacaddr' => 'reset'
		    }
		  }
		},


		'Uplinks' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'Uplinks',
		  'Summary' => 'Exercises adding/removing the uplink functionality for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic_1'
		      ],
		      [
		        'Traffic_2'
		      ],
		      [
		        'DeleteUplinkonSUT'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic_1'
		      ],
		      [
		        'Traffic_3'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Traffic_2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'DeleteUplinkonSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'Traffic_3' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'StressOptions' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'StressOptions',
		  'Summary' => 'Run traffic with network stress options',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'Traffic_1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::portStress'
                      }
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::portStress'
                      }
		    }
		  }
		},


		'Failover-Failback' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Failover-Failback',
		  'Summary' => 'Test the function of failback option of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'physicalonly',
		  'Version' => '2',
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
		          '[1-3]' => {
		            'driver' => 'any'
		          }
		        },
		        'pswitchport' => {
		          '[2]' => {
		            'vmnic' => 'host.[1].vmnic.[2]'
		          },
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'CreateUplinks'
		      ],
		      [
		        'SetFailover1'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic1',
		      ],
		      [
		        'Traffic1',
		        'DisablePort1',
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic2',
		      ],
		      [
		        'Traffic1',
		        'DisablePort2',
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic3',
		      ],
		      [
		        'Traffic1',
		        'EnablePort2',
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic2',
		      ],
		      [
		        'Traffic1',
		        'DisableFailback',
		      ],
		      [
		        'Traffic1',
		        'EnablePort1',
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic2'
		      ],
		      [
		        'Traffic1',
		        'EnableFailback'
		      ],
		      [
		        'Traffic1',
		        'VerifyVMNic1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablePort1',
		      ],
		      [
		        'EnablePort2',
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'CreateUplinks' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2-3]'
		    },
		    'SetFailover1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setfailoverorder' => 'host.[1].vmnic.[1];;host.[1].vmnic.[2];;host.[1].vmnic.[3]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'explicit',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'VerifyVMNic1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'check_adapter_status' => 'active',
                      'adapters' => 'host.[1].vmnic.[1]',
		      'sleepbetweenworkloads'=> '30'
		    },
		    'DisablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'sleepbetweenworkloads' => '5',
		      'portstatus' => 'disable'
		    },
		    'VerifyVMNic2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'check_adapter_status' => 'active',
                      'adapters' => 'host.[1].vmnic.[2]',
		      'sleepbetweenworkloads'=> '30'
		    },
		    'DisablePort2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'sleepbetweencombos' => '5',
		      'portstatus' => 'disable'
		    },
		    'VerifyVMNic3' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'check_adapter_status' => 'active',
                      'adapters' => 'host.[1].vmnic.[3]',
		      'sleepbetweenworkloads'=> '30'
		    },
		    'EnablePort2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'sleepbetweencombos' => '5',
		      'portstatus' => 'enable'
		    },
		    'DisableFailback' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'no',
		      'confignicteaming' => 'host.[1].portgroup.[1]',
		      'sleepbetweenworkloads'=> '5'
		    },
		    'EnablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'sleepbetweencombos' => '5',
		      'portstatus' => 'enable'
		    },
		    'EnableFailback' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'explicit',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]',
		      'sleepbetweenworkloads'=> '5'
		    }
		  }
		},


		'MultipleSwitches' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'MultipleSwitches',
		  'Summary' => 'Exercises the multiple switches functionality for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[1].vss.[2]'
		          },
		          '[3]' => {
		            'vss' => 'host.[1].vss.[3]'
		          },
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
		          }
		        },
		        'vss' => {
		          '[2-3]' => {},
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
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ConfigurePortGroup2'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'ChangePortgroup_2'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic_1'
		      ],
		      [
		        'Traffic_2'
		      ],
		      [
		        'Traffic_3'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[4]' => {
		          'name' => 'vss-pg-multivss-1',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ConfigurePortGroup2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[5]' => {
		          'name' => 'vss-pg-multivss-2',
		          'vss' => 'host.[1].vss.[3]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[4]'
		    },
		    'ChangePortgroup_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[5]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Traffic_2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '1',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic_3' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'noofoutbound' => '1',
		      'toolname' => 'ping',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'Populate' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'Populate',
		  'Summary' => 'Exercises the stress by populating portgroups for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		          '[1-3]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1-3]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-3]' => {
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'ChangePortgroup_2'
		      ],
		      [
		        'ChangePortgroup_3'
		      ],
		      [
		        'ChangePortgroup_4'
		      ],
		      [
		        'ChangePortgroup_5'
		      ],
		      [
		        'ChangePortgroup_6'
		      ],
		      [
		        'ChangePortgroup_7'
		      ],
		      [
		        'ChangePortgroup_8'
		      ],
		      [
		        'ChangePortgroup_9'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic_1'
		      ],
		      [
		        'Traffic_2'
		      ],
		      [
		        'Traffic_3'
		      ],
		      [
		        'Traffic_4'
		      ],
		      [
		        'Traffic_5'
		      ],
		      [
		        'Traffic_6'
		      ],
		      [
		        'Traffic_7'
		      ],
		      [
		        'Traffic_8'
		      ],
		      [
		        'Traffic_9'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1-3]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-populate-2',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[6]' => {
		          'name' => 'vss-pg-populate-5',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[4]' => {
		          'name' => 'vss-pg-populate-3',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[2]' => {
		          'name' => 'vss-pg-populate-1',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[5]' => {
		          'name' => 'vss-pg-populate-4',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[10]' => {
		          'name' => 'vss-pg-populate-9',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[8]' => {
		          'name' => 'vss-pg-populate-7',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[9]' => {
		          'name' => 'vss-pg-populate-8',
		          'vss' => 'host.[1].vss.[1]'
		        },
		        '[7]' => {
		          'name' => 'vss-pg-populate-6',
		          'vss' => 'host.[1].vss.[1]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[2]'
		    },
		    'ChangePortgroup_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'ChangePortgroup_3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[3]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[4]'
		    },
		    'ChangePortgroup_4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[5]'
		    },
		    'ChangePortgroup_5' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[6]'
		    },
		    'ChangePortgroup_6' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[3]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[7]'
		    },
		    'ChangePortgroup_7' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[8]'
		    },
		    'ChangePortgroup_8' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[9]'
		    },
		    'ChangePortgroup_9' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[3]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[10]'
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Traffic_2' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[2].vnic.[2]',
		      'supportadapter' => 'vm.[3].vnic.[2]'
		    },
		    'Traffic_3' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[3].vnic.[3]',
		      'supportadapter' => 'vm.[1].vnic.[3]'
		    },
		    'Traffic_4' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[2].vnic.[2]'
		    },
		    'Traffic_5' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[2].vnic.[3]',
		      'supportadapter' => 'vm.[3].vnic.[3]'
		    },
		    'Traffic_6' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[3].vnic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Traffic_7' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[1].vnic.[3]',
		      'supportadapter' => 'vm.[2].vnic.[3]'
		    },
		    'Traffic_8' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic_9' => {
		      'Type' => 'Traffic',
		      'testduration' => '60',
		      'toolname' => 'Iperf',
		      'testadapter' => 'vm.[3].vnic.[2]',
		      'supportadapter' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'Teaming-FailoverOrder' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Teaming-FailoverOrder',
		  'Summary' => 'Test failover order of teaming feature of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'BAT,batnovc,physicalonly',
		  'Version' => '2',
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
		          '[1-3]' => {
		            'driver' => 'any'
		          }
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[3]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'CreateUplink1'
		      ],
		      [
		        'CreateUplink2'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'SetFailover1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'SetFailover2'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'DisablePort1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablePort1'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'CreateUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'CreateUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[3]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'explicit',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'SetFailover1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setfailoverorder' => 'host.[1].vmnic.[2];;host.[1].vmnic.[1];;host.[1].vmnic.[3]',
                      'check_adapter_status' => 'active',
		      'adapters' => 'host.[1].vmnic.[2]'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'SetFailover2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setfailoverorder' => 'host.[1].vmnic.[3];;host.[1].vmnic.[1];;host.[1].vmnic.[2]',
                      'check_adapter_status' => 'active',
                      'adapters' => 'host.[1].vmnic.[2]'
		    },
		    'DisablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'sleepbetweencombos' => '80',
		      'portstatus' => 'disable'
		    },
		    'EnablePort1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'portstatus' => 'enable'
		    }
		  }
		},


		'NetworkHint' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'NetworkHint',
		  'Summary' => 'Exercises the network hint functionality for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup'
		      ],
		      [
		        'SetVlan_1'
		      ],
		      [
		        'SetVlan_2'
		      ],
		      [
		        'ConfigureIP'
		      ],
		      [
		        'PingTraffic_1'
		      ],
		      [
		        'VerifyNetworkHint'
		      ]
		    ],
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[2]' => {
		          'name' => 'vss-pg-nethint',
		          'vss' => 'host.[1].vss.[1]'
		        }
		      }
		    },
		    'ChangePortgroup' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[2]'
		    },
		    'SetVlan_1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
		    },
		    'SetVlan_2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[2]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
		    },
		    'ConfigureIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'ipv4' => 'auto'
		    },
		    'PingTraffic_1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'routingscheme' => 'broadcast',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'IGNORE',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'VerifyNetworkHint' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmnic.[1]',
		      'check_network_hint' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D .
		                       "," . VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
		    }
		  }
		},


		'VLAN-StressOptions' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'VLAN-StressOptions',
		  'Summary' => 'Test stress option of vlan on vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      },
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
		        'SUTSVLAN302'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SUTSVLAN302' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'expectedresult' => 'PASS',
		      'toolname' => 'netperf',
		      'testduration' => 60,
		      'noofinbound' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::vlanStress'
                      }
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::vlanStress'
                      }
		    }
		  }
		},


		'BasicConfiguration' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'vSS',
		  'TestName' => 'BasicConfiguration',
		  'Summary' => 'Exercises basic configuration for vSwitch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic_1'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Traffic_1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp,udp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    }
		  }
		},


		'Teaming-SourceMAC' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Teaming-SourceMAC',
		  'Summary' => 'Test the teaming feature load balancing (source mac address) of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		          '[1-3]' => {
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-2]' => {
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
		        'CreateUplink1'
		      ],
		      [
		        'CreateUplink2'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'ChangePortgroup1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'DisableSUTvNic2'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'DisableSUTvNic1'
		      ],
		      [
		        'EnableSUTvNic2'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'Traffic3'
		      ],
		      [
		        'ConfigStandby'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNics'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1-2],vm.[2-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'CreateUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'CreateUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[3]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'mac',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[1]'
		    },
		    'DisableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'DOWN'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'DisableSUTvNic1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN'
		    },
		    'EnableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic3' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'ConfigStandby' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'standbynics' => 'host.[1].vmnic.[3]',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'EnablevNics' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'Teaming-IPHash' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Teaming-IPHash',
		  'Summary' => 'Test the teaming feature load balancing (IP Hash) of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		          '[1-3]' => {
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-2]' => {
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
		        'CreateUplink1'
		      ],
		      [
		        'CreateUplink2'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'ChangePortgroup1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'DisableSUTvNic2'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'DisableSUTvNic1'
		      ],
		      [
		        'EnableSUTvNic2'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'Traffic3'
		      ],
		      [
		        'ConfigStandby'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNics'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1-2],vm.[2-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'CreateUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'CreateUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[3]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'iphash',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[1]'
		    },
		    'DisableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'DOWN'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'DisableSUTvNic1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN'
		    },
		    'EnableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic3' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'ConfigStandby' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'standbynics' => 'host.[1].vmnic.[3]',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'EnablevNics' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'TrafficShaping' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'TrafficShaping',
		  'Summary' => 'Test the traffic shaping function of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
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
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableShaping1'
		      ],
                      [
                        'Traffic1'
                      ],
		      [
		        'EnableShaping2'
		      ],
                      [
                        'Traffic2'
                      ],
		      [
		        'EnableShaping3'
		      ],
                      [
                        'Traffic3'
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
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'EnableShaping1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'set_trafficshaping_policy' => {
                        'operation' => 'enable',
                        'peak_bandwidth' => '1000000',
                        'avg_bandwidth' => '500000',
                        'burst_size' => '50000'
                      }
		    },
		    'EnableShaping2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'set_trafficshaping_policy' => {
                        'operation' => 'enable',
                        'peak_bandwidth' => '500000',
                        'avg_bandwidth' => '125000',
                        'burst_size' => '50000'
                      }
		    },
		    'EnableShaping3' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
                      'set_trafficshaping_policy' => {
                        'operation' => 'enable',
                        'peak_bandwidth' => '1000',
                        'avg_bandwidth' => '125',
                        'burst_size' => '25'
                      }
		    },
		    'EnableShaping4' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'expectedresult' => 'FAIL',
                      'set_trafficshaping_policy' => {
                        'operation' => 'enable',
                        'peak_bandwidth' => '0',
                        'avg_bandwidth' => '0',
                        'burst_size' => '0'
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
		      'testadapter' => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'expectedresult' => 'PASS',
		      'remotesendsocketsize' => '32768,65535',
		      'l4protocol' => 'udp',
		      'maxthroughput' => '600',
		      'sendmessagesize' => '1470',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '32768,65535',
		      'toolname' => 'netperf',
		      'testduration' => 10,
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'expectedresult' => 'PASS',
		      'remotesendsocketsize' => '32768,65535',
		      'l4protocol' => 'udp',
		      'maxthroughput' => '150',
		      'sendmessagesize' => '1470',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Traffic3' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => 10,
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'minexpresult' => '0',
		      'l4protocol' => 'udp',
		      'maxthroughput' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    }
		  }
		},


		'Teaming-VirtualPort' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'Teaming-VirtualPort',
		  'Summary' => 'Test the teaming feature load balancing (virtual port) of vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		          '[1-3]' => {
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1-2]' => {
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
		        'CreateUplink1'
		      ],
		      [
		        'CreateUplink2'
		      ],
		      [
		        'ConfigTeaming'
		      ],
		      [
		        'ChangePortgroup1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'DisableSUTvNic2'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'DisableSUTvNic1'
		      ],
		      [
		        'EnableSUTvNic2'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'Traffic3'
		      ],
		      [
		        'ConfigStandby'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnablevNics'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1-2],vm.[2-3].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },

		    'CreateUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'CreateUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[3]'
		    },
		    'ConfigTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'portid',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[1]'
		    },
		    'DisableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'DOWN'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'DisableSUTvNic1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'devicestatus' => 'DOWN'
		    },
		    'EnableSUTvNic2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic3' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => 1,
		      'verification' => 'activeVMNic',
		      'testduration' => 60,
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'ConfigStandby' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'standbynics' => 'host.[1].vmnic.[3]',
		      'confignicteaming' => 'host.[1].portgroup.[1]'
		    },
		    'EnablevNics' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'devicestatus' => 'UP'
		    }
		  }
		},


		'CDP' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'CDP',
		  'Summary' => 'Test CDP support on vSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => 'physicalonly',
		  'Version' => '2',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ListenMode'
		      ],
		      [
		        'VerifyCDPOnEsx'
		      ],
		      [
		        'AdvertiseMode'
		      ],
		      [
		        'VerifyCDPOnSwitch'
		      ],
		      [
		        'DisableCDP'
		      ],
		      [
		        'NoCDPOnEsx'
		      ],
		      [
		        'NoCDPOnSwitch'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ListenMode'
		      ]
		    ],
		    'ListenMode' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configure_cdp_mode' => 'listen'
		    },
		    'VerifyCDPOnEsx' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checkcdponesx' => 'yes',
		      'sleepbetweencombos' => '30'
		    },
		    'AdvertiseMode' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'expectedresult' => 'pass',
		      'configure_cdp_mode' => 'advertise'
		    },
		    'VerifyCDPOnSwitch' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'sleepbetweencombos' => '180',
		      'checkcdponswitch' => 'yes'
		    },
		    'DisableCDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'expectedresult' => 'pass',
		      'configure_cdp_mode' => 'down'
		    },
		    'NoCDPOnEsx' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checkcdponesx' => 'no',
		      'sleepbetweencombos' => '30'
		    },
		    'NoCDPOnSwitch' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'sleepbetweencombos' => '180',
		      'checkcdponswitch' => 'no'
		    }
		  }
		},


		'JumboFrame' => {
		  'Component' => 'Virtual Switch',
		  'Category' => 'ESX Server',
		  'TestName' => 'JumboFrame',
		  'Summary' => 'Test the jumbo frame feature of VSS',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus' => 'Automated',
		  'Tags' => undef,
		  'Version' => '2',
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
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
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
		        'HelperSwitchJF'
		      ],
		      [
		        'HelperVnicJF'
		      ],
		      [
		        'Vnic9000'
		      ],
		      [
		        'Vmknic9000'
		      ],
		      [
		        'Switch4500'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'PingTraffic1'
		      ],
		      [
		        'Switch9000'
		      ],
		      [
		        'Traffic2'
		      ],
		      [
		        'PingTraffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ResetSwitchJF'
		      ],
		      [
		        'ResetVnicJF'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1],host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'HelperSwitchJF' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[2].vss.[1]',
		      'mtu' => '9000'
		    },
		    'HelperVnicJF' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'Vnic9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'Vmknic9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'mtu' => '9000'
		    },
		    'Switch4500' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '4500'
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'testduration' => 60,
		      'toolname' => 'ping',
		      'pingpktsize' => '4472',
		      'testadapter' => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
		      'pktfragmentation' => 'disable',
		      'noofoutbound' => 1,
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'PingTraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'testduration' => 60,
		      'pingpktsize' => '4473',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'pktfragmentation' => 'disable',
		      'expectedresult' => 'FAIL',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Switch9000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '65535',
		      'toolname' => 'netperf',
		      'testduration' => 60,
		      'bursttype' => 'stream',
		      'testadapter' => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'remotesendsocketsize' => '65535',
		      'l4protocol' => 'udp',
		      'sendmessagesize' => '8971',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'PingTraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'ping',
		      'testduration' => 60,
		      'pingpktsize' => '8975',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => 1,
		      'pktfragmentation' => 'disable',
		      'expectedresult' => 'FAIL',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'ResetSwitchJF' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
		      'mtu' => '1500'
		    },
		    'ResetVnicJF' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VSS.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VSS class.
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
   my $self = $class->SUPER::new(\%VSS);
   return (bless($self, $class));
}
