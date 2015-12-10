#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::Stability::RPMTTds;

#
# This file contains the structured hash for RPMT tests.
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use TDS::Main::VDNetMainTds;
use TDS::EsxServer::VDS::VDSTds;
use TDS::EsxServer::MgmtSwitch::VSSTds;
use TDS::EsxServer::Firewall::FirewallTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );

@ISA = qw(TDS::Main::VDNetMainTds);

{

   %RPMT = (
     'HotAddvNIC' => {
	     'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'HotAddvNIC',
		  'Summary' => 'Tests connectivity after hot adding adapter',
		  'ExpectedResult' => 'PASS',
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
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::EsxServer::Stability::RPMT::HotAddvNIC',
		  'Priority' => 'P0',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_01,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'HotRemove'
		      ],
		      [
		        'HotAddE1000'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		      [
		        'HotRemove'
		      ],
		      [
		        'HotAddVmxnet3'
		      ],
		      [
		        'TRAFFIC_1'
		      ],
		    ],
		    'TRAFFIC_1' => {
		      'Type'            => 'Traffic',
		      'testduration'    => '10',
		      'toolname'        => 'ping',
		      'testadapter'     => 'vm.[1].vnic.[1]',
		      'supportadapter'  => 'vm.[2].vnic.[1]',
            'Verification'    => "Verification_1",
		    },
		    'HotAddVmxnet3' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[1]' => {
		          'portgroup' => 'host.[1].portgroup.[1]',
		          'driver' => 'vmxnet3'
		        }
		      }
		    },
		    'HotRemove' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    },
		    'HotAddE1000' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[1]' => {
		          'portgroup' => 'host.[1].portgroup.[1]',
		          'driver' => 'e1000'
		        }
		      }
          },
          "Verification_1" => {
             'PktCapVerificaton' => {
                verificationtype => "pktcap",
                target           => "dstvm",
                pktcount         => "5+",
                badpkt           => "0",
             },
          },
        },
		},

		'ChangevNICStateDuringBoot' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'ChangevNICStateDuringBoot',
		  'Summary' => 'Tests vNIC link state changesduring VM power off/on.',
		  'ExpectedResult' => 'PASS',
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
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::EsxServer::Stability::RPMT::ChangevNICStateDuringBoot',
		  'Priority' => 'P0',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_01,
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
		        'TRAFFIC_2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'ConnectvNic'
		      ]
		    ],
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
		      'TestAdapter' => "vm.[1].vnic.[1]",
		      'SupportAdapter' => "vm.[2].vnic.[1]",
		      'expectedresult' => 'FAIL',
		      'testduration' => '5',
		      'toolname' => 'ping'
		    },
		    'ConnectvNic' => {
		      'Type' => 'NetAdapter',
		      'reconfigure' => 'true',
		      'connected' => 1,
		      'testadapter' => 'vm.[1].vnic.[1]'
		    },
		    'TRAFFIC_2' => {
		      'Type' => 'Traffic',
		      'TestAdapter' => "vm.[2].vnic.[1]",
		      'SupportAdapter' => "vm.[1].vnic.[1]",
		      'expectedresult' => 'PASS',
		      'testduration' => '5',
		      'sleepbetweenworkloads' => '5',
		      'toolname' => 'ping'
		    }
		  }
		},

		'DriverConfig' => {
		  'Component' => 'Vmxnet3',
		  'Category' => 'Virtual Net Devices',
		  'TestName' => 'DriverConfig',
		  'Summary' => 'Tests basic driver config operations',
		  'ExpectedResult' => 'PASS',
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
		  'AutomationStatus' => 'automated',
		  'testID' => 'TDS::EsxServer::Stability::RPMT::DriverConfig',
		  'Priority' => 'P0',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_01,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DisableSG',
		        'EnableSG'
		      ],
		      [
		        'DisableTSO',
		        'EnableTSO'
		      ],
		      [
		        'CSOEnableTx',
		        'CSOEnableRx'
		      ],
		      [
		        'CSODisableTx',
		        'CSODisableRx'
		      ],
		      [
		        'TRAFFIC_1'
		      ]
		    ],
		    'DisableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'sg',
		         'enable'       => 'false',
		      },
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'sg',
		         'enable'       => 'true',
		      },
		       'sleepbetweenworkloads' => '60',
		    },
		    'DisableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'false',
		      },
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		       'sleepbetweenworkloads' => '60',
		    },
		    'CSOEnableTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		    },
		    'CSOEnableRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		    },
		    'CSODisableTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'false',
		      },
		    },
		    'CSODisableRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'false',
		      },
		      'sleepbetweenworkloads' => '60',
		    },
		    'TRAFFIC_1' => {
		      'Type' => 'Traffic',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'SupportAdapter' => 'vm.[2].vnic.[1]',
		      'testduration' => '5',
		      'toolname' => 'ping'
		    }
		  }
		},

      'TCPAndUDPWithIPv4IPv6AndMulticast' => {
        'Component' => 'VMKTCPIP',
		  'Category' => 'Esx Server',
		  'TestName' => 'TCPAndUDPWithIPv4IPv6AndMulticast',
		  'Summary' => 'This test sends various types of traffic.',
		  'ExpectedResult' => 'PASS',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
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
		        'host' => 'host.[1]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
                ['InitVmknics'],
                ['TCPTraffic'],
                ['UDPTraffic'],
                ['MulticastTraffic1'],
                ['MulticastTraffic2'],
            ],
          'InitVmknics'   => {
              Type        => "NetAdapter",
              TestAdapter => "host.[1-2].vmknic.[1],vm.[1].vnic.[1]",
              IPv4        => "dhcp",
              'sleepbetweencombos' => '60',
          },
          'TCPTraffic' => {
             'Type' => 'Traffic',
             'toolname' => 'netperf',
             'testduration' => '10',
             'testadapter' => 'vm.[1].vnic.[1],host.[2].vmknic.[1]',
             'maxtimeout' => '1800',
             'l4protocol' => 'tcp',
             'l3protocol' => 'ipv4,ipv6',
             'supportadapter' => 'host.[1].vmknic.[1]'
          },
          'UDPTraffic' => {
             'Type' => 'Traffic',
             'toolname' => 'netperf',
             'testduration' => '10',
             'testadapter' => 'vm.[1].vnic.[1],host.[2].vmknic.[1]',
             'maxtimeout' => '1800',
             'l4protocol' => 'udp',
             'l3protocol' => 'ipv4,ipv6',
	     'minexpresult'   => "IGNORE",
             'supportadapter' => 'host.[1].vmknic.[1]'
          },
          'MulticastTraffic1' => {
             'Type' => 'Traffic',
             'toolname' => 'Iperf',
             'testduration' => '10',
             'testadapter' => 'vm.[1].vnic.[1]',
             'supportadapter' => 'host.[1].vmknic.[1]',
             'routingscheme' => 'multicast',
             'multicasttimetolive' => '32'
          },
          'MulticastTraffic2' => {
             'Type' => 'Traffic',
             'toolname' => 'Iperf',
             'testduration' => '10',
             'testadapter' => 'host.[2].vmknic.[1]',
             'supportadapter' => 'host.[1].vmknic.[1]',
             'routingscheme' => 'multicast',
             'multicasttimetolive' => '32'
          },
        },
      },

      'vMotionVerifyPortState' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'vMotionVerifyPortState',
		  'Summary' => 'Make sure that dvport state is preserved during vmotion' .
		               ' operation',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
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
		            'configurehosts' => 'add',
		            'host' => 'host.[1-2]'
		          },
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
		        'AddUplinks'
		      ],
		      [
		        'InitVmknics'
		      ],
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'InitVnics'
		      ],
		      [
		        'BlockPort'
		      ],
		      [
		        'TrafficFAIL'
		      ],
		      [
		        'vmotion'
		      ],
		      [
		        'UnBlockPort'
		      ],
		      [
		        'TrafficPASS'
		      ]
		    ],
           'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
           },
           'InitVnics'   => {
              Type        => "NetAdapter",
              TestAdapter => "vm.[1-2].vnic.[1]",
              IPv4        => "dhcp",
           },
           'InitVmknics'   => {
              Type        => "NetAdapter",
              TestAdapter => "host.[1-2].vmknic.[1]",
              IPv4        => "dhcp",
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
           'BlockPort' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'blockport' => 'vm.[1].vnic.[1]'
           },
           'TrafficFAIL' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'testduration' => '10',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'staytime' => '10'
           },
           'UnBlockPort' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'unblockport' => 'vm.[1].vnic.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
           },
           'TrafficPASS' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'l4protocol' => 'tcp',
              'testduration' => '10',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
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
		        'host' => 'host.[2]'
		      },
		      '[1]' => {
		        'datastoreType' => 'shared',
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'e1000'
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
		        'ConnectVC'
		      ],
		      [
		        'CreateDC'
		      ],
		      [
		        'ConfigureVMForvMotion'
		      ],
		      [
		        'EnableVMotion1'
		      ],
		      [
		        'EnableVMotion2'
		      ],
		      [
		        'InitVmknics'
		      ],
		      [
		        'DisableVmkStress1'
		      ],
		      [
		        'DisableVmkStress2'
		      ],
		      [
		        'DoVmotion_1'
		      ],
		      [
		        'Traffic_1',
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
          'ConnectVC' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'opt' => 'connect'
          },
          'CreateDC' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'maxtimeout' => '600',
             'datacenter' => {
                '[1]' => {
                   'name' => 'vssdctest',
                   'host' => 'host.[1];;host.[2]'
                }
              }
           },
           'InitVmknics'   => {
              Type        => "NetAdapter",
              TestAdapter => "vm.[1-2].vnic.[1]",
              IPv4        => "dhcp",
              'sleepbetweencombos' => '60',
           },
           'ConfigureVMForvMotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'operation' => 'configurevmotion'
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
           'DisableVmkStress1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'stress' => 'Disable',
              'stressoptions' => '/config/Misc/intOpts/VmkStressEnable = 0'
           },
           'DisableVmkStress2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'stress' => 'Disable',
              'stressoptions' => '/config/Misc/intOpts/VmkStressEnable = 0'
           },
           'Traffic_1' => {
              'Type' => 'Traffic',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'DoVmotion_1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'staytime' => '60'
           },
           'EnableVmkStress1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'stress' => 'Enable',
              'stressoptions' => '/config/Misc/intOpts/VmkStressEnable = 1'
           },
           'EnableVmkStress2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'stress' => 'Enable',
              'stressoptions' => '/config/Misc/intOpts/VmkStressEnable = 1'
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
		  'Version' => '2',
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
		      'TestHost' => 'host.[1]',
		      'firewall' => 'setenabled',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'firewall' => 'CheckRule',
		      'operation' => 'disabled',
		      'service_name' => 'sshClient'
		    },
		    'EnableSSH' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'firewall' => 'setenabled',
		      'operation' => 'enabled',
		      'service_name' => 'sshClient'
		    }
		  }
		},

      "CreateDeleteInstance" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "CreateDeleteInstance",
         Version          => "2" ,
         Summary          => "This test case verifies that traffic
                             can be run between vmknics which belongs to
                             different instances",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['InitVmknics'],['Traffic1'],['Traffic2']],
           'InitVmknics'   => {
              Type        => "NetAdapter",
              TestAdapter => "host.[1-2].vmknic.[1-2]",
              IPv4        => "dhcp",
              'sleepbetweencombos' => '60',
           },
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp,udp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "10",
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "10",
            },
         },
      },

      # For this test to work vmnic3 should be backed by a TRUNK PG
      'VmknicVlan' => {
         'Component' => 'VMKTCPIP',
         'Category' => 'ESX Server',
         'TestName' => 'VmknicVlan',
         'Summary' => 'Verify that network traffic between Vmknics using ' .
                      'vswitch vlan tagging',
         'ExpectedResult' => 'PASS',
         'Version' => '2',
         'AutomationStatus' => 'Automated',
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
                        'vmnicadapter' => 'host.[1].vmnic.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]'
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
                  'portgroup' => {
                     '[1]' => {
                        'vss' => 'host.[2].vss.[1]'
                     },
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
                        'portgroup' => 'host.[2].portgroup.[1]',
                     }
                  }
               },
            },
         },
         'WORKLOADS' => {
           'Sequence' => [['SwitchVlan'],['InitVmknics'],['Netperf'],
                          ['SwitchVlanDisable']],
           'SwitchVlan' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[2].portgroup.[1],vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
           },
           'InitVmknics'   => {
              Type        => "NetAdapter",
              TestAdapter => "host.[1-2].vmknic.[1]",
              IPv4        => "dhcp",
              'sleepbetweencombos' => '60',
           },
           'Netperf' => {
              'Type' => 'Traffic',
              'toolname' => 'Netperf',
              'testduration' => '5',
              'testadapter' => 'host.[1].vmknic.[1]',
              'l4protocol' => 'TCP',
              'supportadapter' => 'host.[2].vmknic.[1]'
           },
           'SwitchVlanDisable' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[2].portgroup.[1],vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => '0'
           },
        }
      },

      'NetdumpClientFunctionality_EndtoEnd' => {
         'Component' => 'NetDump',
         'Category' => 'ESX Server',
         'TestName' => 'NetdumpClientFunctionality_EndtoEnd',
         'Summary' => 'Setting&Verifying NetDumpClientConfiguration',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
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
		      '[3]' => {
		        'host' => 'host.[2]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'HotAddE1000'
		      ],
		      [
		        'NetdumpSetClientServerIPs'
		      ],
		      [
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'NetdumpSetClientParams'
		      ],
		      [
		        'NetdumpEnable'
		      ],
		      [
		        'NetdumpVerifyClient'
		      ],
		      [
		        'NetdumpClientServerHello'
		      ],
		      [
		        'BackupHost'
		      ],
		      [
		        'CleanupNetdumperLogs'
		      ],
		      [
		        'NetdumpGeneratePanicReboot'
		      ],
		      [
		        'NetdumpServerDumpCheck'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
          'HotAddE1000' => {
             'Type' => 'VM',
             'TestVM' => 'vm.[3]',
             'vnic' => {
                '[1]' => {
                   'portgroup' => 'host.[2].portgroup.[1]',
                   'driver' => 'e1000'
                }
             }
          },
         'NetdumpSetClientServerIPs' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[1],vm.[3].vnic.[1]',
            'ipv4' => 'dhcp',
         },
         'NetdumpSvrConfEdit' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[3]',
            'netdumpparam' => 'port',
            'netdumpvalue' => '6600',
            'iterations' => '1',
            'operation' => 'configurenetdumpserver'
         },
         'NetdumpSetClientParams' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'netdumpsvrport' => '6600',
            'netdump' => 'set',
            'testadapter' => 'host.[1].vmknic.[1]',
            'netdumpsvrip' => 'AUTO',
            'supportadapter' => 'vm.[3].vnic.[1]',
            'sleepbetweenworkloads' => '30'
         },
         'NetdumpEnable' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'netdumpstatus' => 'true',
            'netdump' => 'configure'
         },
         'NetdumpVerifyClient' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'testadapter' => 'host.[1].vmknic.[1]',
            'netdumpstatus' => 'true',
            'netdumpsvrport' => '6600',
            'netdump' => 'verifynetdumpclient',
            'supportadapter' => 'vm.[3].vnic.[1]',
            'netdumpsvrip' => 'AUTO'
         },
         'NetdumpClientServerHello' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'iterations' => '1',
            'netdump' => 'netdumpesxclicheck'
         },
         'BackupHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'netdump' => 'backuphost'
         },
         'CleanupNetdumperLogs' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[3]',
            'operation' => 'cleanupnetdumperlogs'
         },
         'NetdumpGeneratePanicReboot' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'paniclevel' => '4',
            'panictype' => 'normal',
            'netdump' => 'panicandreboot'
         },
         'NetdumpServerDumpCheck' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[3]',
            'clientadapter' => 'host.[1].vmknic.[1]',
            'netdumpclientip' => 'AUTO',
            'iterations' => '1',
            'operation' => 'checknetdumpstatus'
         },
         'NetdumpDisable' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1]',
            'netdumpstatus' => 'false',
            'netdump' => 'configure'
         },
         'NetdumpSvrConfRevert' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[3]',
            'netdumpparam' => 'port',
            'netdumpvalue' => '6500',
            'iterations' => '1',
            'operation' => 'configurenetdumpserver'
         },
         'HotRemovevnic' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[3]',
            'deletevnic' => 'vm.[3].vnic.[1]'
         }
      }
    },

  );
}


########################################################################
#
# new --
#       This is the constructor for RPMT tests
#
# Input:
#       none
#
# Results:
#       An instance/object of RPMT class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%RPMT);
   if ($self eq FAILURE) {
      print "error ". VDGetLastError() ."\n";
      VDSetLastError(VDGetLastError());
   }
   return (bless($self, $class));
}

1;
