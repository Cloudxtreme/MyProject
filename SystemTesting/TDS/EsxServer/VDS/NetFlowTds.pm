########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::NetFlowTds;

#
# This file contains the structured hash for ipfix/netflow.
# Netflow/ipfix is only supported for vds version 5.0 onwards.
# The tests here use the latest vds version.
#
# The master controller acts as a collecor to collect the
# the packets. We use nfcapd to capture the packets and nfdump
# to analyze the data. These two tools are the backend tools
# NFSane netflow collector.The nfcapd is responsible for
# capturing of the netflow data and nfdump is responsible
# for the analysis of the data.
#
#
# For details about each and every case please see the TDS
# at following location.
# //depot/documentation/MN/Networking-FVT/
# /TDS/VMkernel_ESX_vDS+_Switching_Test_Design_Specification.doc
#

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%NetFlow = (
		'Basic-Paramters-VM' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'Basic-Paramters-VM',
		  'Summary' => 'Verify the ipfix with basic settings for vm\'s',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::Basic-Paramters-VM',
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
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ],
		      [
		        'Ping'
		      ],
		      [
		        'UDP'
		      ]
		    ],
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '300',
		      'sampling' => '0',
		      'idletimeout' => '15'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Ping' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'verification' => 'Verification_2',
		      'toolname' => 'Ping',
		      'testduration' => '60',
		      'noofinbound' => '1',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'UDP' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_3',
		      'l4protocol' => 'udp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Verification_3' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'udp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    },
		    'Verification_2' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'icmp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},


		'Basic-Paramters-VMK' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'Basic-Paramters-VMK',
		  'Summary' => 'Verify the ipfix with basic settings between vmkernel nics',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::Basic-Paramters-VMK',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2]'
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
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '300',
		      'sampling' => '0',
		      'idletimeout' => '15'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'host.[2].vmknic.[1]'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'host.[1].vmknic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'host.[2].vmknic.[1]'
		      }
		    }
		  }
		},


		'ActiveFlowTimeOut' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'ActiveFlowTimeOut',
		  'Summary' => 'Verify the ipfix settings with active flow timeout',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::ActiveFlowTimeOut',
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
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '1000',
		      'sampling' => '0'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},


		'IdleFlowTimeOut' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'IdleFlowTimeOut',
		  'Summary' => 'Verify the ipfix settings with idle flow timeout',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::IdleFlowTimeOut',
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
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'sampling' => '0',
		      'idletimeout' => '600'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},


		'SamplingRate' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'SamplingRate',
		  'Summary' => 'Verify the ipfix settings with sampling rate',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::SamplingRate',
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
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '300',
		      'sampling' => '1000',
		      'idletimeout' => '15'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},


		'vmotion' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'vmotion',
		  'Summary' => 'Verify the ipfix settings and vmotion work fine',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::VMotion',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1-2]'
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
		            'portgroup' => 'vc.[1].dvportgroup.[3]'
		          }
		        }
		      },
		      '[1]' => {
		        'vmknic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[2]'
		          }
		        },
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
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
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
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1',
		        'vmotion'
		      ]
		    ],
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
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '300',
		      'sampling' => '0',
		      'idletimeout' => '15'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'toolname' => 'netperf',
		      'testduration' => '120',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'vmotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'sleepbetweenworkloads' => '60',
		      'dsthost' => 'host.[2]',
		      'staytime' => '30'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},


		'JumboFrame' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'JumboFrame',
		  'Summary' => 'Verify the netflow with jumbo frames',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::NetFlow::JumboFrame',
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
		        'SetVDSMTU'
		      ],
		      [
		        'SetVMMTU'
		      ],
		      [
		        'SetNetFlow'
		      ],
		      [
		        'EnableMonitoring'
		      ],
		      [
		        'Traffic1'
		      ]
		    ],
		    'SetVDSMTU' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'mtu' => '9000'
		    },
		    'SetVMMTU' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'SetNetFlow' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'confignetflow' => 'local',
		      'activetimeout' => '300',
		      'sampling' => '0',
		      'idletimeout' => '15'
		    },
		    'EnableMonitoring' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
                      'set_monitoring' => {
                        'status' => 'true',
                        'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                      }
		    },
		    'Traffic1' => {
		      'Type' => 'Traffic',
		      'localsendsocketsize' => '131072',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'expectedresult' => 'PASS',
		      'remotesendsocketsize' => '131072',
		      'verification' => 'Verification_1',
		      'l4protocol' => 'tcp',
		      'sendmessagesize' => '63488',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'Verification_1' => {
		      'NFdumpVerificaton' => {
		        'protocol' => 'tcp',
		        'src' => 'vm.[1].vnic.[1]',
		        'verificationtype' => 'nfdump',
		        'dst' => 'vm.[2].vnic.[1]'
		      }
		    }
		  }
		},
   );
}


#######################################################################
#
# new --
#       This is the constructor for VDS Netflow.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDS class.
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
   my $self = $class->SUPER::new(\%NetFlow);
   return (bless($self, $class));
}



