#!/usr/bin/perl
#########################################################################
## Copyright (C) 2013 VMWare, Inc.
## # All Rights Reserved
#########################################################################
package TDS::EsxServer::Firewall::FirewallTds;
use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;


@ISA = qw(TDS::Main::VDNetMainTds);
{
%Firewall = (
		'VerifyAddDelIPv6AllowHost' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyAddDelIPv6AllowHost',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Add Del IPv6 Allow Host,NFC as an example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'hostreboot',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyAddDelIPv6AllowHost',
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
		            'portgroup' => 'host.[2].portgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableIPv6'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'SleeptoWaitIP'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'SleeptoWaitIP'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnableIPv6' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'ableipv6' => 'ENABLE'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'reboot' => 'yes'
		    },
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'NFC'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'NFC'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '2001:bd6::c:2957:101',
		      'operation' => 'add',
		      'service_name' => 'NFC'
		    },
		    'SleeptoWaitIP' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => '2001:bd6::c:2957:101/64'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv6',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '2001:bd6::c:2957:101',
		      'operation' => 'remove',
		      'service_name' => 'NFC'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv6',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'NFC'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT'
		    }
		  }
		},


		'VerifyOutputDefaultServicevpxHeartbeats' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServicevpxHeartbeats',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service vpxHeartbeats',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServicevpxHeartbeats',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vpxHeartbeats'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},

		'VerifyFunctionalVMotion' => {
		  'Component' => 'Firewall',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyFunctionalVMotion',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'VMotion',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyFunctionalVMotion',
		  'TestbedSpec' => {
		    'vc' => {
		        '[1]' => {
		            'datacenter' => {
		                '[1]' => {
		                    'host' =>'host.[1-2].x.[x]'
		                }
		            },
		            'dvportgroup' => {
		                '[1]' => {
		                    'name' => 'dvpga',
		                    'vds' => 'vc.[1].vds.[1]',
		                    'addporttodvportgroup' => '5'
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
		            'portgroup' => 'vc.[1].dvportgroup.[1]'
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
		            'portgroup' => 'vc.[1].dvportgroup.[1]'
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
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'SetSUTIP'
		      ],
		      [
		        'SetHelperIP'
		      ],
		      [
		        'Iperftraffic',
		        'vmotion'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vMotion'
		    },
		    'EnableVMotion1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => 'dhcp'
		    },
		    'EnableVMotion2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		      'ipv4' => 'dhcp'
		    },
		    'SetSUTIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetHelperIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '2323',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'vmotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'dsthost' => 'host.[2].x.[x]',
		      'staytime' => '10'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},

		'VerifyFunctionalVLAN' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyFunctionalVLAN',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verifying the VLAN with different Firewall options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyFunctionalVLAN',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'setSutVmknicVlan1'
		      ],
		      [
		        'setHelperVmknicVlan'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'setHelperVMVlan'
		      ],
		      [
		        'setSutVmknicVlan2'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_3'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisabledFirewall'
		      ],
		      [
		        'RemoveGuestVLAN'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vMotion'
		    },
		    'setSutVmknicVlan1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[2]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'setHelperVmknicVlan' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[2].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '4095'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'setHelperVMVlan' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'vlaninterface' => {
		          '[1]' => {
		              'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                              'ipv4' => 'dhcp'
		          },
		      }
		    },
		    'setSutVmknicVlan2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[2]',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'RemoveGuestVLAN' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		    }
		  }
		},

		'VerifyAddDelIPv4AllowHostSubnet' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyAddDelIPv4AllowHostSubnet',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Add Del IPv4 Allow Host subnet,vMotion as an example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyAddDelIPv4AllowHostSubnet',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vMotion'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'vMotion'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.0.0/16',
		      'operation' => 'add',
		      'service_name' => 'vMotion'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '176.10.1.8'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => '176.10.1.9'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.0.0/16',
		      'operation' => 'remove',
		      'service_name' => 'vMotion'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'vMotion'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    }
		  }
		},


		'VerifyAddDelIPv4AllowHost' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyAddDelIPv4AllowHost',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Add Del IPv4 Allow Host,vMotion as an example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyAddDelIPv4AllowHost',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vMotion'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'vMotion'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'add',
		      'service_name' => 'vMotion'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '176.10.1.8'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => '176.10.1.9'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'remove',
		      'service_name' => 'vMotion'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'vMotion'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    }
		  }
		},


		'ListFirewallRule' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'ListFirewallRule',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'List all of default esxi firewall rules ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::ListPorts',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'list'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'list',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'VerifyInputOutputDefaultServiceNFC' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServiceNFC',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Input/OutputDefault Service NFC tcp 902',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServiceNFC',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'NFC'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServiceCIMHttpServer' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServiceCIMHttpServer',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service CIMHttpServer tcp port 5988',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServiceCIMHttpServer',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'CIMHttpServer'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'CIMHttpServer'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'add',
		      'service_name' => 'CIMHttpServer'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '176.10.1.8'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => '176.10.1.9'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '5988',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'remove',
		      'service_name' => 'CIMHttpServer'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'CIMHttpServer'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    }
		  }
		},


		'VerifyInputOutputDefaultServicevMotion' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServicevMotion',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service vmotion tcp port 8000',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,CAT_P0',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServicevMotion',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vMotion'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8000',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'ConfigurationEnableService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'ConfigurationEnableService',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Enabled given service name ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::ConfigurationEnableService',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'CheckRule',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'ConfigurationAddDelAllowHost' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'ConfigurationAddDelAllowHost',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Add or remove ip address for given service name ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::ConfigurationAddDelAllowHost',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ],
		      [
		        'HostOperation_3'
		      ],
		      [
		        'HostOperation_4'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '10.117.14.12,192.168.10.1/24',
		      'operation' => 'add',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_3' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '10.117.14.12,192.168.10.1/24',
		      'operation' => 'remove',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_4' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'VerifyInputDefaultServiceDVFilter' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServiceDVFilter',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service DVFilter,tcp port 2222',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServiceDVFilter',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'DVFilter'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '2222',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyServiceConsistency' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyServiceConsistency',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify the given service consistency',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyServiceConsistency',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ],
		      [
		        'HostOperation_3'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_3' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'CheckRule',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'VerifyResetService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyResetService',
        'AutomationStatus'  => 'Automated',
		  'Summary' => 'Reset service damon status ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyResetService',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'reset',
		      'firewall' => 'setstatus',
		      'service_name' => 'ntpClient'
		    }
		  }
		},


		'VerifyDisabledService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyDisabledService',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify disabled service,use dvfilter as example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyDisabledService',
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
		        'EnabledFirewall'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'DVFilter'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '2222',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'ConfigurationDisableService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'ConfigurationDisableService',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Disabled given service name ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bat,batnovc',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::ConfigurationDisableService',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'EnableSSH'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'CheckRule',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    },
		    'EnableSSH' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'VerifyInputOutputDefaultServicefaultTolerance' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServicefaultTolerance',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Input/OutputDefault Service faultTolerance tcp 80/8100 udp 8200',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServicefaultTolerance',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic3'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic4'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic5'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'faultTolerance'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8100',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8200',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic3' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8200',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic4' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '80',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic5' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8100',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServicesshWebAccess' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServicesshWebAccess',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service WebAccess tcp port 80',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServicesshWebAccess',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'webAccess'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '80',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputOutputDefaultServiceDHCPv6' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServiceDHCPv6',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Input/OutputDefault Service DHCPv6 tcp 547/546 udp 547/546',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServiceDHCPv6',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic3'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic4'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'DHCPv6'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '546',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '546',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic3' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '547',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic4' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '547',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'DHCPv6'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyOutputDefaultServicentpClient' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServicentpClient',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service ntpClient,tcp port 123',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServicentpClient',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'ntpClient'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '123',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'ntpClient'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyOutputDefaultServicesshClient' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServicesshClient',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service sshClient,tcp port 22',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServicesshClient',
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
		            'driver' => ''
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'StopSSHdOnVM'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisabledFirewall'
		      ],
		      [
		        'StartSSHdOnVM'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    },
		    'StopSSHdOnVM' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'configure_linux_service_state' => 'stop',,
		      'service_name' => 'sshd'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '22',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'sleepbetweencombos' => '5',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'StartSSHdOnVM' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1].x.[x]',
		      'configure_linux_service_state' => 'start',
		      'service_name' => 'sshd'
		    }
		  }
		},


		'VerifyInputOutputDefaultServicedhcp' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServicedhcp',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Input/OutputDefault Service dhcp udp 68',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServicedhcp',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'dhcp'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'auto'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'auto'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '68',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServiceCIMHttpsServer' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServiceCIMHttpsServer',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service CIMHttpServer tcp port 5989',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServiceCIMHttpsServer',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'CIMHttpsServer'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'CIMHttpsServer'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'add',
		      'service_name' => 'CIMHttpsServer'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '176.10.1.8'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => '176.10.1.9'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '5989',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '176.10.1.9',
		      'operation' => 'remove',
		      'service_name' => 'CIMHttpsServer'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'CIMHttpsServer'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    }
		  }
		},


		'VerifyOutputDefaultServiceHBR' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServiceHBR',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service HBR tcp 1234/1235',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServiceHBR',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'HBR'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '31031',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '44046',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyOutputDefaultServiceiSCSI' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServiceiSCSI',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service iSCSI,tcp port 3260',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServiceiSCSI',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'iSCSI'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '3260',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyAddDelIPv6AllowHostSubnet' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyAddDelIPv6AllowHostSubnet',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Add Del IPv6 Allow Host,NFC as an example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'hostreboot',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyAddDelIPv6AllowHostSubnet',
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
		        'EnableIPv6'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'DisalbedAllowedAll'
		      ],
		      [
		        'AddAllowedIP'
		      ],
		      [
		        'SleeptoWaitIP'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'RemoveAllowedIP'
		      ],
		      [
		        'SleeptoWaitIP'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'EnabledAllowedALL'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'SetVmkIPDefault'
		      ],
		      [
		        'SetVMIPDefault'
		      ]
		    ],
		    'EnableIPv6' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'ableipv6' => 'ENABLE'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'reboot' => 'yes'
		    },
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'NFC'
		    },
		    'DisalbedAllowedAll' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'false',
		      'service_name' => 'NFC'
		    },
		    'AddAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '2001:bd6::1/64',
		      'operation' => 'add',
		      'service_name' => 'NFC'
		    },
		    'SleeptoWaitIP' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => '2001:bd6::c:2957:101/64'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv6',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'RemoveAllowedIP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'IPSet',
		      'ipaddress' => '2001:bd6::1/64',
		      'operation' => 'remove',
		      'service_name' => 'NFC'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'FAIL',
		      'l4protocol' => 'tcp',
		      'l3protocol' => 'ipv6',
		      'noofinbound' => '1',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'EnabledAllowedALL' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setallowedall',
		      'operation' => 'true',
		      'service_name' => 'NFC'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    },
		    'SetVmkIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT'
		    },
		    'SetVMIPDefault' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT'
		    }
		  }
		},


		'VerifyInputOutputDefaultServiceDNS' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServiceDNS',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service DNS UDP port 53',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServiceDNS',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'dns'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '53',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '53',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyEnabledService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyEnabledService',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify enabled service,use snmp server as example',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyEnabledService',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'snmp'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '161',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'snmp'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyOutputDefaultServiceactiveDirectoryAll' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServiceactiveDirectoryAll',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service activeDirectoryAll',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServiceactiveDirectoryAll',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'IperftrafficUdp88'
		      ],
		      [
		        'IperftrafficUdp123'
		      ],
		      [
		        'IperftrafficUdp137'
		      ],
		      [
		        'IperftrafficUdp389'
		      ],
		      [
		        'IperftrafficUdp464'
		      ],
		      [
		        'IperftrafficTcp88'
		      ],
		      [
		        'IperftrafficTcp445'
		      ],
		      [
		        'IperftrafficTcp139'
		      ],
		      [
		        'IperftrafficTcp389'
		      ],
		      [
		        'IperftrafficTcp464'
		      ],
		      [
		        'IperftrafficTcp51915'
		      ],
		      [
		        'IperftrafficTcp3268'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'activeDirectoryAll'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'IperftrafficUdp88' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '88',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficUdp123' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '123',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficUdp137' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '137',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficUdp389' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '389',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficUdp464' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '464',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp88' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '88',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp445' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '445',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp139' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '139',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp389' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '389',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp464' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '464',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp51915' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '51915',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'IperftrafficTcp3268' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '3268',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'snmp'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServicevSphereClient' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServicevSphereClient',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service vSphereClient tcp port 443 902',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServicevSphereClient',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'vSphereClient'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '443',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '902',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyDuplicateServices' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyDuplicateServices',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'check the duplicate service in all of default esxi firewall rules ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyDuplicateServices',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'CheckDupService',
		      'service_name' => 'sshClient,DVFilter'
		    }
		  }
		},


		'VerifyOutputDefaultServiceupdateManager' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServiceupdateManager',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service updateManager',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServiceupdateManager',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'Iperftraffic3'
		      ],
		      [
		        'Iperftraffic4'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'updateManager'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '80',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '9000',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic3' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '9050',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic4' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '9100',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyRebootConsistency' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyRebootConsistency',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify the given service reboot consistency',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt,hostreboot',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyRebootConsistency',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnabledsshClient'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'CheckRule'
		      ]
		    ],
		    'EnabledsshClient' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'reboot' => 'yes'
		    },
		    'CheckRule' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'CheckRule',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    }
		  }
		},


		'VerifyStartStopService' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyStartStopService',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'start or stop service damon status ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyStartStopService',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HostOperation_1'
		      ],
		      [
		        'HostOperation_2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'stop',
		      'firewall' => 'setstatus',
		      'service_name' => 'ntpClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'start',
		      'firewall' => 'setstatus',
		      'service_name' => 'ntpClient'
		    }
		  }
		},


		'VerifyInputOutputDefaultServiceCIMSLP' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServiceCIMSLP',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service vmotion tcp/udp port 427',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServiceCIMSLP',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'CIMSLP'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '427',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '427',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputOutputDefaultServiceDVSSync' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputOutputDefaultServiceDVSSync',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify Input/OutputDefault Service DVSSync udp 8301/8301',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputOutputDefaultServiceDVSSync',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic3'
		      ],
		      [
		        'SleepToClean'
		      ],
		      [
		        'Iperftraffic4'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'DVSSync'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8301',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'SleepToClean' => {
		      'Type' => 'Command',
		      'command' => 'sleep 60',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8302',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic3' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8301',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic4' => {
		      'Type' => 'Traffic',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '8302',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'DVSSync'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServicesnmp' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServicesnmp',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service snmp,udp port 161',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServicesnmp',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledService'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'snmp'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'udp',
		      'udpbandwidth' => '10000M',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '161',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'snmp'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyInputDefaultServicesshServer' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyInputDefaultServicesshServer',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify InputDefault Service sshServer tcp port 22',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyInputDefaultServicesshServer',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshServer'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic' => {
		      'Type' => 'Traffic',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'toolname' => 'Iperf',
		      'testduration' => '15',
		      'portnumber' => '22',
		      'noofinbound' => '1',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


		'VerifyOutputDefaultServicehttpClient' => {
		  'Component' => 'network tools',
		  'Category' => 'Esx Server',
		  'TestName' => 'VerifyOutputDefaultServicehttpClient',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Verify service httpClient,tcp port 80/443',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::Firewall::Firewall::VerifyOutputDefaultServicehttpClient',
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
		        'EnabledFirewall'
		      ],
		      [
		        'EnabledService'
		      ],
		      [
		        'NetAdapter_1'
		      ],
		      [
		        'NetAdapter_2'
		      ],
		      [
		        'Iperftraffic1'
		      ],
		      [
		        'Iperftraffic2'
		      ],
		      [
		        'DisabledFirewall'
		      ]
		    ],
		    'EnabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'enabled',
		      'firewall' => 'setstatus'
		    },
		    'EnabledService' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'httpClient'
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'NetAdapter_2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Iperftraffic1' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '80',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'Iperftraffic2' => {
		      'Type' => 'Traffic',
		      'toolname' => 'Iperf',
		      'testduration' => '60',
		      'portnumber' => '443',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'expectedresult' => 'PASS',
		      'l4protocol' => 'tcp',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'DisabledFirewall' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'status' => 'disabled',
		      'firewall' => 'setstatus'
		    }
		  }
		},


   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for Firewall.
#
# Input:
#       None.
#
# Results:
#       An instance/object of Firewall class.
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
   my $self = $class->SUPER::new(\%Firewall);
   return (bless($self, $class));
}
