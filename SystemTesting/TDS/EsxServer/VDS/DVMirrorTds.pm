#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::DVMirrorTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%DVMirror = (
		'MirrorSessionWithBidings' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'MirrorSessionWithBidings',
		  'Summary' => 'Verify the existence of mirror sessions with vds binding',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateDVPortgroup'
		      ],
		      [
		        'AddPort'
		      ],
		      [
		        'ChangePortgroup'
		      ],
		      [
		        'CreateSession'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateDVPortgroup' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'dvportgroup' => {
		        '[2]' => {
		          'ports' => undef,
		          'name' => 'vds-test-dvportgroup',
		          'binding' => 'lateBinding',
		          'nrp' => undef,
		          'vds' => 'vc.[1].vds.[1]'
		        }
		      }
		    },
		    'AddPort' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
		      'addporttodvportgroup' => '1'
		    },
		    'ChangePortgroup' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'vc.[1].dvportgroup.[2]'
		    },
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'SessionDisabled' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'SessionDisabled',
		  'Summary' => 'Verify that the vm doesn\'t receive traffic if session' .
		               ' is disabled',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'EditSession'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'EditSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'edit',
                         'name' => 'Session1',
		         'enabled' => 'false',
                      },
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'FAIL',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'CreateMirrorSession' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'CreateMirrorSession',
		  'Summary' => 'Verify the function of mirroring from port to uplink',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'version' => '5.0.0',
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['0'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'NormalIOOnDestinationPort' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'NormalIOOnDestinationPort',
		  'Summary' => 'Verify that dst port can send/receive the traffic',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'Traffic2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'normaltraffic' => 'true',
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                      },
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'Traffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[2].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'MirrorVGTTraffic' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'MirrorVGTTraffic',
		  'Summary' => 'Verify that GVT can be mirrored to the destination ports',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'version' => '5.0.0',
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'SetVLANTrunk'
		      ],
		      [
		        'CreateSession'
		      ],
		      [
		        'SetGuestVLAN'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      ['RemoveGuestVLAN1'],
		      ['RemoveGuestVLAN2']
		    ],
		    'Duration' => 'time in seconds',
		    'SetVLANTrunk' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'trunk',
		      'vlan' => '[0-4094]'
		    },
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'normaltraffic' => 'true',
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['0'],
                      },
		    },
		    'SetGuestVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
                      'vlaninterface' => {
                         '[1]' => {
                            'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                         },
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		  }
		},


		'MirrorSnapshotLength' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'MirrorSnapshotLength',
		  'Summary' => 'Verify that length of the packet to be mirrored ' .
		               'can be changed',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'EditSession1'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'EditSession2'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'mirrorlength' => '128',
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                      },
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'EditSession1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'edit',
                         'name' => 'Session1',
		         'mirrorlength' => '100',
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'enabled' => 'true',
                      },
		    },
		    'EditSession2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'edit',
                         'name' => 'Session1',
		         'mirrorlength' => '1500',
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'enabled' => 'true',
                      },
		    }
		  }
		},


		'CreateMirrorSession' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'CreateMirrorSession',
		  'Summary' => 'Verify the function of creating session for DVMirror',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'PreserveOriginalVLAN' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'PreserveOriginalVLAN',
		  'Summary' => 'Verify that destination port sees the original vlan id',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
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
		            'version' => '5.0.0',
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'SetVLANTrunk'
		      ],
		      [
		        'CreateSession'
		      ],
		      [
		        'SetGuestVLAN'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      ['RemoveGuestVLAN1'],
		      ['RemoveGuestVLAN2']
		    ],
		    'Duration' => 'time in seconds',
		    'SetVLANTrunk' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'trunk',
		      'vlan' => '[0-4094]'
		    },
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'stripvlan' => 'false',
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                      },
		    },
		    'SetGuestVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
                      'vlaninterface' => {
                         '[1]' => {
                            'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                         },
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'deletevlaninterface' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'Verification_1' => {
		      'PktCapVerificaton' => {
		        'target' => 'vm.[2].vnic.[1]',
		        'pktcount' => '800+',
		        'pktcapfilter' => 'count 5000,vlan ' .
		                           VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'PortToPortMirroring' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortToPortMirroring',
		  'Summary' => 'Verify the function of mirroring from port to port',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    }
		  }
		},


		'vMotionWithMirror' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'vMotionWithMirror',
		  'Summary' => 'Verify the vmotion function with dvmirror enabled',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'vmotion',
		  'Version' => '2',
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
		            'vds' => 'vc.[1].vds.[2]'
		          },
		          '[3]' => {
		            'vds' => 'vc.[1].vds.[2]'
		          },
		          '[4]' => {
		            'vds' => 'vc.[1].vds.[2]'
		          },
		          '[1]' => {
		            'vds' => 'vc.[1].vds.[1]'
		          }
		        },
		        'vds' => {
		          '[2]' => {
		            'datacenter' => 'vc.[1].datacenter.[1]',
		            'vmnicadapter' => 'host.[1-2].vmnic.[2]',
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
		          },
		          '[1]' => {
		            'datacenter' => 'vc.[1].datacenter.[1]',
		            'vmnicadapter' => 'host.[1-2].vmnic.[1]',
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		            'portgroup' => 'vc.[1].dvportgroup.[4]'
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
		            'portgroup' => 'vc.[1].dvportgroup.[3]'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'CreateSession'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'vmotion'
		      ],
		      [
		        'Traffic1'
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
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'vmotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'dsthost' => 'host.[2].x.[x]',
		      'staytime' => '10'
		    }
		  }
		},


		'JumboFrameMirrorSession' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'JumboFrameMirrorSession',
		  'Summary' => 'Verify the function of dvMirror with jumbo frames',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'SetMTU1'
		      ],
		      [
		        'SetVMMTU1'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'SetVMMTU2'
		      ],
		      [
		        'SetMTU2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVMMTU2'
		      ],
		      [
		        'SetMTU2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'SetMTU1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mtu' => '9000'
		    },
		    'SetVMMTU1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1],vm.[3].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'SetVMMTU2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1],vm.[3].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'SetMTU2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mtu' => '1500'
		    }
		  }
		},


		'EncapSulateVLAN' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'EncapSulateVLAN',
		  'Summary' => 'Verify that mirrored packet can be encapsulated in a ' .
		               'specific vlan id',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
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
		            'version' => '5.0.0',
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
		        }
		      },
		      '[1]' => {
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
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'SetVLANTrunk'
		      ],
		      [
		        'CreateSession'
		      ],
		      [
		        'SetGuestVLAN'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      ['RemoveGuestVLAN1'],
		      ['RemoveGuestVLAN2']
		    ],
		    'Duration' => 'time in seconds',
		    'SetVLANTrunk' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'trunk',
		      'vlan' => '[0-4094]'
		    },
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A,
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                      },
		    },
		    'SetGuestVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
                      'vlaninterface' => {
                         '[1]' => {
                            'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                         },
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'testduration' => '60',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[3].vnic.[1]',
		      'deletevlaninterface' => 'vm.[3].vnic.[1].vlaninterface.[1]'
		    },
		    'Verification_1' => {
		      'PktCapVerificaton' => {
		        'target' => 'vm.[2].vnic.[1]',
		        'pktcount' => '800+',
		        'pktcapfilter' => 'count 5000,vlan ' .
		                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_A,
		        'verificationtype' => 'pktcap'
		      }
		    }
		  }
		},


		'DestryMirrorSession' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'DestryMirrorSession',
		  'Summary' => 'Verify the function of removing a dvmirror session',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
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
		            'version' => '5.0.0',
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2].x.[x]'
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
		        }
		      },
		      '[1]' => {
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[1].vss.[1]'
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[3]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'CreateSession'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'RemoveSession'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CreateSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'add',
                         'name' => 'Session1',
		         'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
		         'dstport'  => ['vm.[2].vnic.[1]->dvport'],
		         'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'verificationadapter' => 'vm.[2].vnic.[1]',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'verificationresult' => 'PASS',
		      'verification' => 'pktCap',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[3].vnic.[1]'
		    },
		    'RemoveSession' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mirrorsession' => {
                         'operation' => 'remove',
                         'name' => 'Session1',
                      },
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for DVMirror.
#
# Input:
#       None.
#
# Results:
#       An instance/object of DVMirror class.
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
   my $self = $class->SUPER::new(\%DVMirror);
   return (bless($self, $class));
}
