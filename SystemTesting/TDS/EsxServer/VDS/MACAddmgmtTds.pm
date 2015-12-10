#!/usr/bin/perl
########################################################################
# Copyrighta(C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::MACAddmgmtTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS =("VMwareOUIbasedAllocation", "addRemoveprefixBasedAllocation",
    "powerOnprefixBasedAllocation", "netperfTrafficprefixBasedAllocation",
    "SuspendResumeprefixBasedAllocation", "invalidPrefix",
    "addRemoverangeBasedAllocation", "powerOnrangeBasedAllocation",
    "netperfTrafficrangeBasedAllocation", "SuspendResumerangeBasedAllocation",
    "invalidRange", "rangeLimit", "reallocateMACaddress");

   %MACAddmgmt = (
		'SuspendResumerangeBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'SuspendResumerangeBasedAllocation',
		  'Summary' => 'Range based mac is retain on suspend resume.' .
		               ' Test case to run after fresh install VC or ' .
		               'when already range scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'range',
		        'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff',
                      }
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'suspend,resume'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'reallocateMACaddress' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'reallocateMACaddress',
		  'Summary' => 'Reallocate MAC address of the deleted vnic to the newly'.
		               ' added vnic. Test case to run after fresh install VC or'.
		               ' when already range scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P1',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAddThreeAdapters'
		      ],
		      [
		        'FourthHotAddFail'
		      ],
		      [
		        'HotRemove'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ThreeHotRemove'
		      ]
		    ],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:00:00-00:50:20:00:00:02'
                      }
		    },
		    'HotAddThreeAdapters' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2-4]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'FourthHotAddFail' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'expectedresult' => 'FAIL',
		      'vnic' => {
		        '[4]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'sleepbetweenworkloads' => '5',
		      'deletevnic' => 'vm.[1].vnic.[4]'
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[4]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'range',
		        'mac_range' => '00:50:20:00:00:00-00:50:20:00:00:02',
                      }
		    },
		    'ThreeHotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2],vm.[1].vnic.[3],vm.[1].vnic.[4]'
		    }
		  }
		},


		'invalidPrefix' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'invalidPrefix',
		  'Summary' => 'Ensure vpxd discards invalid Prefix values. Test case ' .
		               'to run after fresh install VC or when already prefix ' .
		               'scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'prefix',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'expectedresult' => 'FAIL',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'prefix',
		         'mac_range' => '00:XX:20-24'
                      }
		    }
		  }
		},


		'invalidrange' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'invalidrange',
		  'Summary' => 'Ensure vpxd discards invalid Range values. Test case to' .
		               ' run after fresh install VC or when already range scheme' .
		               ' is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'expectedresult' => 'FAIL',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:XX:00-00:50:20:ff:ff:ff'
                      }
		    }
		  }
		},


		'netperTrafficrangeBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'netperTrafficrangeBasedAllocation',
		  'Summary' => 'Ensure that TCP/UDP traffic runs when vNIC is up on ' .
		               'range based MAC. Test case to run after fresh install' .
		               ' VC or when already range scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'NetperfUDP'
		      ],
		      [
		        'NetperfTCP'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'range',
		        'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff',
                      }
		    },
		    'NetperfUDP' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '32K',
		      'receivemessagesize' => '32K',
		      'localreceivesocketsize' => '32K',
		      'localsendsocketsize' => '32K',
		      'toolname' => 'netperf',
		      'bursttype' => 'STREAM',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32K',
		      'l4protocol' => 'UDP',
		      'sendmessagesize' => '32K',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'NetperfTCP' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '128K',
		      'receivemessagesize' => '128K',
		      'localreceivesocketsize' => '128K',
		      'localsendsocketsize' => '128K',
		      'toolname' => 'netperf',
		      'bursttype' => 'STREAM',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '128K',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '128K',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'powerOnrangeBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'powerOnrangeBasedAllocation',
		  'Summary' => 'Ensure that that vNIC takes MAC from the specified ' .
		               'range after poweron. Test case to run after fresh ' .
		               'install VC or when already range scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        'SetMACScheme'
		      ],
		      [
		        'ColdAdd'
		      ],
		      [
		        'PowerOn'
		      ],
		      [
		        'ValidateMAC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'PowerOn'
		      ]
		    ],
		    'PowerOff' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'poweroff'
		    },
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff'
                      }
		    },
		    'ColdAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'poweron'
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'range',
		        'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff',
                      }
		    }
		  }
		},


		'powerOnPrefixBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'powerOnPrefixBasedAllocation',
		  'Summary' => 'Ensure that vNIC takes prefix based mac after powering' .
		               ' on. Test case to run after fresh install VC or when ' .
		               'already prefix scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'prefix',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        'SetMACScheme'
		      ],
		      [
		        'ColdAdd'
		      ],
		      [
		        'PowerOn'
		      ],
		      [
		        'ValidateMAC'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'PowerOn'
		      ]
		    ],
		    'PowerOff' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'poweroff'
		    },
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'prefix',
		         'mac_range' => '00:51:22-24'
                       }
		    },
		    'ColdAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'poweron'
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'prefix',
		        'mac_range' => '00:51:22-24',
                      }
		    }
		  }
		},


		'VMWareOUIbaseAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'VMWareOUIbaseAllocation',
		  'Summary' => 'To ensure that VMwareOUI based allocation works. Test ' .
		               'case to run when no scheme is set on VC. ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'vmwareoui',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        'ValidateMAC'
		      ],
		      [
		        'PingTest'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
                        'mac_allocschema' => 'oui'
                      }
		    },
		    'PingTest' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '10',
		      'toolname' => 'Ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'rangeLimit' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'rangeLimit',
		  'Summary' => 'Ensure error message pops up when range is exhausted.' .
		               ' Test case to run after fresh install VC or when ' .
		               'already range scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAddThreeAdapters'
		      ],
		      [
		        'FourthHotAddFail'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'HotRemoveAll'
		      ]
		    ],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'range',
		         'mac_range' => '00:50:20:00:00:00-00:50:20:00:00:02'
                      }
		    },
		    'HotAddThreeAdapters' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2-4]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'FourthHotAddFail' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'expectedresult' => 'FAIL',
		      'vnic' => {
		        '[5]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'HotRemoveAll' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2],vm.[1].vnic.[3],vm.[1].vnic.[4]'
		    }
		  }
		},


		'netperTrafficprefixBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'netperTrafficprefixBasedAllocation',
		  'Summary' => 'Ensure that TCP/UDP traffic runs when vNIC has prefix ' .
		               'based MAC. Test case to run after fresh install VC or ' .
		               'when already prefix scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'prefix,CAT_P0',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'NetperfUDP'
		      ],
		      [
		        'NetperfTCP'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1-2],vm.[2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'prefix',
		         'mac_range' => '00:50:22-24'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'prefix',
		        'mac_range' => '00:50:22-24',
                      }
		    },
		    'NetperfUDP' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '32768',
		      'receivemessagesize' => '32768',
		      'localreceivesocketsize' => '32768',
		      'localsendsocketsize' => '32768',
		      'toolname' => 'netperf',
		      'bursttype' => 'STREAM',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32768',
		      'l4protocol' => 'UDP',
		      'sendmessagesize' => '32768',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'NetperfTCP' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '131072',
		      'receivemessagesize' => '131072',
		      'localreceivesocketsize' => '131072',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'bursttype' => 'STREAM',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '131072',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '131072',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'addRemovePrefixBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'addRemovePrefixBasedAllocation',
		  'Summary' => 'To ensure that prefix based allocation works. Test case'.
		               ' to run after fresh install VC or when already prefix ' .
		               'scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'prefix',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'PingTest'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1-2],vm.[2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'prefix',
		         'mac_range' => '00:50:13-24'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'prefix',
		        'mac_range' => '00:50:13-24',
                      }
		    },
		    'PingTest' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '10',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'SuspendResumeprefixBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'SuspendResumeprefixBasedAllocation',
		  'Summary' => 'Prefix based MAC address allocation is retained after' .
		               ' Suspend Resume Operation.Test case to run after fresh' .
		               ' install VC or when already prefix scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'prefix',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'SuspendResume'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
		         'mac_allocschema' => 'prefix',
		         'mac_range' => '00:50:23-24'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'prefix',
		        'mac_range' => '00:50:23-24',
                      }
		    },
		    'SuspendResume' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vmstate' => 'suspend,resume'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},


		'addRemoverangeBasedAllocation' => {
		  'Component' => 'VDS2.0',
		  'Category' => 'ESX Server',
		  'TestName' => 'addRemoverangeBasedAllocation',
		  'Summary' => 'To ensure that range base allocation works. Test case ' .
		               'to run after fresh install VC or when already range ' .
		               'scheme is set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'range',
		  'Version' => '2',
		  'AutomationStatus' => 'automated',
		  'Priority' => 'P0',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2].x.[x]'
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
		            'host' => 'host.[1-2].x.[x]'
		          }
		        }
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'vmxnet3'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'SetMACScheme'
		      ],
		      [
		        'HotAdd'
		      ],
		      [
		        'ValidateMAC'
		      ],
		      [
		        'PingTest'
		      ],
		      [
		        'HotRemove'
		      ]
		    ],
		    'ExitSequence' => [],
		    'SetMACScheme' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
                      'set_vpxd_macallocation_schema' =>{
                         'mac_allocschema' => 'range',
                         'mac_range' => '00:50:20:00:00:00-00:50:20:ff:ff:ff'
                      }
		    },
		    'HotAdd' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'vnic' => {
		        '[2]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'ValidateMAC' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
                      'validate_mac' => {
		        'mac_allocschema' => 'range',
		        'mac_range' => '00:50:20:00:00:00-00:50:29:ff:ff:ff',
                      }
		    },
		    'PingTest' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '10',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'deletevnic' => 'vm.[1].vnic.[2]'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for MACAddmgmt.
#
# Input:
#       None.
#
# Results:
#       An instance/object of MACAddmgmt class.
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
   my $self = $class->SUPER::new(\%MACAddmgmt);
   return (bless($self, $class));
}
