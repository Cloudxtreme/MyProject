#!/usr/bin/perl
#########################################################################
## Copyright (C) 2013 VMWare, Inc.
## # All Rights Reserved
#########################################################################
package TDS::EsxServer::VmkAPI::PktAPITds;
#
##
## This file contains the structured hash for category, PKTAPI tests
## The following lines explain the keys of the internal
## Hash in general.
##
use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;


@ISA = qw(TDS::Main::VDNetMainTds);
{
   %PktAPI = (
		'VNICCSO' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VNICCSO',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'CSO testing with wide range of packet size',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VNICCSO',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'BasicTRAFFIC'
		      ],
		      [
		        'NetAdapter_Checksum_TxD',
		        'NetAdapter_Checksum_RxD',
		      ],
		      [
		        'TRAFFIC_Netperf'
		      ],
		      [
		        'NetAdapter_Checksum_TxD',
		        'NetAdapter_Checksum_RxE',
		      ],
		      [
		        'TRAFFIC_Netperf'
		      ],
		      [
		        'NetAdapter_Checksum_TxE',
		        'NetAdapter_Checksum_RxD',
		      ],
		      [
		        'TRAFFIC_Netperf'
		      ],
		      [
		        'NetAdapter_Checksum_TxE',
		        'NetAdapter_Checksum_RxE',
		      ],
		      [
		        'TRAFFIC_Netperf'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetAdapter_Checksum_TxE',
		        'NetAdapter_Checksum_RxE',
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'BasicTRAFFIC' => {
		      'Type' => 'Traffic',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]',
		      'noofoutbound' => '1',
		      'l4protocol' => 'TCP',
		      'testduration' => '30',
		      'toolname' => 'netperf',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'bursttype' => 'stream'
		    },

		    'TRAFFIC_Netperf' => {
		      'Type' => 'Traffic',
                      'testadapter' => 'vm.[1].vnic.[1]',
                      'supportadapter' => 'vm.[2].vnic.[1]',
		      'receivemessagesize' => '32768',
		      'localsendsocketsize' => '32768',
		      'toolname' => 'netperf',
		      'testduration' => '360',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32768',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '32768',
		      'noofinbound' => '1'
		    },
		    'NetAdapter_Checksum_TxE' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'iterations' => '1'
		    },
		    'NetAdapter_Checksum_RxE' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1'
		    },
		    'NetAdapter_Checksum_TxD' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'false',
		      },
		      'iterations' => '1'
		    },
		    'NetAdapter_Checksum_RxD' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'false',
		      },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1'
		    },
		  }
		},


		'UplinkStress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'UplinkStress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'uplink Stress Test on same host',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::UplinkStress',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableChecksumTx',
		        'EnableChecksumRx'
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'NetperfTraffic'
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
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'EnableChecksumTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'iterations' => '1'
		    },
		    'EnableChecksumRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1'
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'sg',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => 'NetCopyToLowSG = 150'
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '65536',
		      'receivemessagesize' => '16384',
		      'localreceivesocketsize' => '65536',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '1200',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'maxtimeout' => '56000',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'noofinbound' => '1'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => 'NetCopyToLowSG = 0'
                      }
		    }
		  }
		},


		'packetStress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'packetStress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run traffic with packet stress options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::PacketStress',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableChecksumTx',
		        'EnableChecksumRx'
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'SUTSwitchMTU'
		      ],
		      [
		        'helper1SwitchMTU'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'VmkAPITest'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'EnableChecksumTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '30',
		      'iterations' => '1'
		    },
		    'EnableChecksumRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		      'iterations' => '1'
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'sg',
		        'enable'       => 'true',
		      },
		    },
		    'SUTSwitchMTU' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'helper1SwitchMTU' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'mtu' => '9000'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktpacket'
                      }
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '1200',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'maxtimeout' => '56000',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'sleepbetweenworkloads' => '30',
		      'noofinbound' => '1'
		    },
		    'VmkAPITest' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'testesx' => '-S -n net/vmknet-required.sh'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktpacket'
                      }
		    }
		  }
		},


		'e1000Stress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'e1000Stress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run traffic with E1000 stress options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::E1000Stress',
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
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'EnableTCPChecksumTx',
		        'EnableTCPChecksumRx'
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiE1000'
                      }
		    },
		    'EnableTCPChecksumTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTCPChecksumRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'sg',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '300',
		      'bursttype' => 'stream',
		      'parallelsession' => 'yes',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'sleepbetweenworkloads' => '30',
		      'noofinbound' => '1'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiE1000'
                      }
		    }
		  }
		},


		'VNICTSO' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VNICTSO',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Change NIC Tso state while running tcp/udp traffic',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VNICTSO',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'DisableTSO',
		        'EnableTSO',
		        'Traffic_ping'
		      ],
		      [
		        'Traffic_netperf'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		       'sleepbetweenworkloads' => '60',
		      'iterations' => '10',
		    },
		    'DisableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'false',
		      },
		      'iterations' => '10'
		    },
		    'Traffic_ping' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'expectedresult' => 'Ignore',
		      'testduration' => '360',
		      'toolname' => 'ping',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'routingscheme' => 'flood'
		    },
		    'Traffic_netperf' => {
		      'Type' => 'Traffic',
		      'testduration' => '360',
		      'toolname' => 'netperf',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'minexpresult' => '0.1',
		      'l4protocol' => 'TCP',
		      'noofinbound' => '1'
		    }
		  }
		},


		'VmkLRO_Vmxnet3' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VmkLRO Vmxnet3',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'VM Lro, TcpipLro, Vmxnet3 Sw/Hw Lro test',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt,CAT_P0',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VmkVmxnet3LRO',
		  'TestbedSpec' => {
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
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
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
		            'vmnicadapter' => 'host.[2].vmnic.[1]'
		          }
		        }
		      },
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
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'DTD3Hw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'DTE3Hw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'DTD3Sw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'DTE3Sw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'ETE3Hw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'ETD3Hw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'ETD3Sw'
		      ],
		      [
		        'Netperf'
		      ],
		      [
		        'ETE3Sw'
		      ],
		      [
		        'Netperf'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'Netperf' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '25600',
		      'receivemessagesize' => '25600',
		      'localreceivesocketsize' => '25600',
		      'localsendsocketsize' => '25600',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'remotesendsocketsize' => '25600',
		      'l4protocol' => 'TCP',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'sendmessagesize' => '25600'
		    },
		    'DTD3Hw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'disable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'disable'
		    },
		    'DTE3Hw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'disable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'enable'
		    },
		    'DTD3Sw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'disable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw',
		      'lro' => 'disable'
		    },
		    'DTE3Sw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'disable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw',
		      'lro' => 'enable'
		    },
		    'ETE3Hw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'enable'
		    },
		    'ETD3Hw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'disable'
		    },
		    'ETD3Sw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw',
		      'lro' => 'disable'
		    },
		    'ETE3Sw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw',
		      'lro' => 'enable'
		    }
		  }
		},


		'VmkLRO_LroE3' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VmkLRO LroE3',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Enable Lro for vmxne3 inside VM and set default for vmxnet3 Lro on backend',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::LroE3',
		  'TestbedSpec' => {
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
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
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
		            'vmnicadapter' => 'host.[2].vmnic.[1]'
		          }
		        }
		      },
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
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableLro'
		      ],
		      [
		        'ETE3Hw'
		      ],
		      [
		        'ETE3Sw'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Netperf'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableHwSwLro'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'EnableLro' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
                       'configure_offload' =>{
		           'offload_type' => 'lro',
		           'enable'       => 'true',
                       }
		    },
		    'ETE3Hw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Hw',
		      'lro' => 'enable'
		    },
		    'ETE3Sw' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'enable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw',
		      'lro' => 'enable'
		    },
		    'Netperf' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '25600',
		      'receivemessagesize' => '25600',
		      'localreceivesocketsize' => '25600',
		      'localsendsocketsize' => '25600',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'remotesendsocketsize' => '25600',
		      'l4protocol' => 'TCP',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'sendmessagesize' => '25600'
		    },
		    'DisableHwSwLro' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'tcpiplro' => 'disable',
		      'adapter' => 'vm.[1].vnic.[1]',
		      'lrotype' => 'Sw,Hw',
		      'lro' => 'disable'
		    }
		  }
		},


		'VMKAPI' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VMKAPI',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run Packet API Test Suite',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VmkAPI',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'VmkAPICore'
		      ]
		    ],
		    'Iterations' => '1',
		    'VmkAPICore' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'testesx' => '-S -n vmkapi/vmkapi-core.sh'
		    }
		  }
		},


		'vmxnet3Stress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'vmxnet3Stress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run traffic with vmxnet3 stress options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::Vmxnet3Stress',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'Switch_Sut_MTU_9000'
		      ],
		      [
		        'Switch_Helper_MTU_9000'
		      ],
		      [
		        'SetAdapterMTU9000'
		      ],
		      [
		        'EnableTCPChecksumTx',
		        'EnableTCPChecksumRx'
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'BasicNetperf'
		      ],
		      [
		        'EnableStress',
		        'NetperfTraffic'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ],
		      [
		        'SetAdapterMTU1500'
		      ],
		      [
		        'Switch_Sut_MTU_1500'
		      ],
		      [
		        'Switch_Helper_MTU_1500'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'Switch_Sut_MTU_9000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000',
		    },
		    'Switch_Helper_MTU_9000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'mtu' => '9000',
		    },
		    'SetAdapterMTU9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'mtu' => '9000',
		    },
		    'EnableTCPChecksumTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTCPChecksumRx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'sg',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'BasicNetperf' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '20',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'l4protocol' => 'TCP',
		      'sleepbetweenworkloads' => '30',
		      'sendmessagesize' => '16384'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiVmxnet3'
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '1200',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'maxtimeout' => '6000',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'noofinbound' => '1'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiVmxnet3'
                      }
		    },
		    'SetAdapterMTU1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'mtu' => '1500',
		    },
		    'Switch_Sut_MTU_1500' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500',
		    },
		    'Switch_Helper_MTU_1500' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'mtu' => '1500',
		    }
		  }
		},


		'VmkJF' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VmkJF',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Vmk Jumbo Frame Test between two hosts',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VmkJF',
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Switch_mtu_9000'
		      ],
		      [
		        'NetAdapter_SUT_mtu_9000'
		      ],
		      [
		        'NetAdapter_helper_mtu_9000'
		      ],
		      [
		        'TRAFFIC_Netperf_9000'
		      ],
		      [
		        'Switch_mtu_6000'
		      ],
		      [
		        'NetAdapter_SUT_mtu_6000'
		      ],
		      [
		        'NetAdapter_helper_mtu_6000'
		      ],
		      [
		        'TRAFFIC_Netperf_6000'
		      ],
		      [
		        'Switch_mtu_3000'
		      ],
		      [
		        'NetAdapter_SUT_mtu_3000'
		      ],
		      [
		        'NetAdapter_helper_mtu_3000'
		      ],
		      [
		        'TRAFFIC_Netperf_3000'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'Switch_mtu_1500'
		      ],
		      [
		        'NetAdapter_SUT_mtu_1500'
		      ],
		      [
		        'NetAdapter_helper_mtu_1500'
		      ]
		    ],
		    'Switch_mtu_9000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_SUT_mtu_9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '192.168.10.1',
		      'mtu' => '9000'
		    },
		    'NetAdapter_helper_mtu_9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'ipv4' => '192.168.10.2',
		      'mtu' => '9000'
		    },
		    'TRAFFIC_Netperf_9000' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '32728',
		      'localreceivesocketsize' => '32728',
		      'localsendsocketsize' => '32728',
		      'toolname' => 'Netperf',
		      'testduration' => '240',
		      'bursttype' => 'stream',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32728',
		      'verification' => 'PktCap',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '9000',
		      'supportadapter' => 'host.[2].vmknic.[1]'
		    },
		    'Switch_mtu_6000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
		      'mtu' => '6000'
		    },
		    'NetAdapter_SUT_mtu_6000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '192.168.10.1',
		      'mtu' => '6000'
		    },
		    'NetAdapter_helper_mtu_6000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'ipv4' => '192.168.10.2',
		      'mtu' => '6000'
		    },
		    'TRAFFIC_Netperf_6000' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '32728',
		      'localreceivesocketsize' => '32728',
		      'localsendsocketsize' => '32728',
		      'toolname' => 'Netperf',
		      'testduration' => '240',
		      'bursttype' => 'stream',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32728',
		      'verification' => 'PktCap',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '6000',
		      'supportadapter' => 'host.[2].vmknic.[1]'
		    },
		    'Switch_mtu_3000' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
		      'mtu' => '3000'
		    },
		    'NetAdapter_SUT_mtu_3000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '192.168.10.1',
		      'mtu' => '3000'
		    },
		    'NetAdapter_helper_mtu_3000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'ipv4' => '192.168.10.2',
		      'mtu' => '3000'
		    },
		    'TRAFFIC_Netperf_3000' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '32728',
		      'localreceivesocketsize' => '32728',
		      'localsendsocketsize' => '32728',
		      'toolname' => 'Netperf',
		      'testduration' => '240',
		      'bursttype' => 'stream',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '32728',
		      'verification' => 'PktCap',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '3000',
		      'supportadapter' => 'host.[2].vmknic.[1]'
		    },
		    'Switch_mtu_1500' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1],host.[2].vss.[1]',
		      'mtu' => '1500'
		    },
		    'NetAdapter_SUT_mtu_1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => '192.168.10.1',
		      'mtu' => '1500'
		    },
		    'NetAdapter_helper_mtu_1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmknic.[1]',
		      'ipv4' => '192.168.10.2',
		      'mtu' => '1500'
		    }
		  }
		},


		'PortSetPortStress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'PortSetPortStress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'PortSet Port Stress Test ',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::PortSetPortStress',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'BasicTraffic'
		      ],
		      [
		        'NetperfTraffic',
		        'EnableStress'
		      ],
		      [
		        'DisableStress'
		      ],
		      [
		        'VmkAPITest'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'BasicTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '30',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'l4protocol' => 'TCP',
		      'sendmessagesize' => '16384',
		      'sleepbetweenworkloads' => '30',
		      'noofinbound' => '1'
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '1200',
		      'postmortem' => '0',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'maxtimeout' => '56000',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'noofinbound' => '1'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
                      'sleepbetweenworkloads' => '200',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktportSetPort'
                      }
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktportSetPort'
                      }
		    },
		    'VmkAPITest' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'testesx' => '-S -n net/vmknet-required.sh'
		    }
		  }
		},


		'vmxnet2Stress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'vmxnet2Stress',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run traffic with vmxnet2 stress options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::Vmxnet2Stress',
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
		        'host' => 'host.[1].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'host.[1].portgroup.[1]',
		            'driver' => 'vmxnet2'
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
		        'AddUplinkonHelper1'
		      ],
		      [
		        'EnableStress'
		      ],
		      [
		        'EnableCSOTx',
		        'EnableCSORx',
		      ],
		      [
		        'EnableSG'
		      ],
		      [
		        'EnableTSO'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'NetperfTraffic'
		      ],
		      [
		        'EnableLro'
		      ],
		      [
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiVmxnet2'
                      }
		    },
		    'EnableCSOTx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcptxchecksumipv4',
		        'enable'       => 'true',
		      },
		    },
		    'EnableCSORx' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'tcprxchecksumipv4',
		        'enable'       => 'true',
		      },
		      'sleepbetweenworkloads' => '60',
		    },
		    'EnableSG' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		        'offload_type' => 'sg',
		        'enable'       => 'true',
		      },
		    },
		    'EnableTSO' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'configure_offload' =>{
		         'offload_type' => 'tsoipv4',
		         'enable'       => 'true',
		      },
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '300',
		      'bursttype' => 'stream',
		      'parallelsession' => 'yes',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'sleepbetweenworkloads' => '30',
		      'noofinbound' => '1'
		    },
		    'EnableLro' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
                       'configure_offload' =>{
		           'offload_type' => 'lro',
		           'enable'       => 'true',
                       }
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktapiVmxnet2'
		      }
                    }
		  }
		},


		'vmkLinuxStress' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'vmkLinuxStress',
                  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Run traffic with vmkLinux stress options',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,StressOption',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VmkLinuxStress',
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
		        'EnableStress',
		        'NetperfTraffic'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'DisableStress'
		      ]
		    ],
		    'Iterations' => '1',
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'EnableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
                      'sleepbetweenworkloads' => '100',
		      'configure_stress' => {
		          'operation' => 'enable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktvmkLinux'
                      }
		    },
		    'NetperfTraffic' => {
		      'Type' => 'Traffic',
		      'receivemessagesize' => '16384',
		      'localsendsocketsize' => '65536',
		      'toolname' => 'netperf',
		      'testduration' => '1200',
		      'bursttype' => 'stream',
		      'noofoutbound' => '1',
		      'remotesendsocketsize' => '65536',
		      'minexpresult' => 'IGNORE',
		      'maxtimeout' => '56000',
		      'l4protocol' => 'TCP,UDP',
		      'sendmessagesize' => '16384',
		      'sleepbetweenworkloads' => '30',
		      'noofinbound' => '1'
		    },
		    'DisableStress' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_stress' => {
                          'operation' => 'disable',
		          'stress_options' => '%VDNetLib::TestData::StressTestData::pktvmkLinux'
                      }
		    }
		  }
		},


		'VmkLRO_LroD3' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'Esx Server',
		  'TestName' => 'VmkLRO LroD3',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Disable Lro for vmxnet3 inside VM',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::LroD3',
		  'TestbedSpec' => {
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
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
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
		            'vmnicadapter' => 'host.[2].vmnic.[1]'
		          }
		        }
		      },
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
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'DisableLro'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'Netperf'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'DisableLro' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'iterations' => '1',
                       'configure_offload' =>{
		           'offload_type' => 'lro',
		           'enable'       => 'false',
                       }
		    },
		    'Netperf' => {
		      'Type' => 'Traffic',
		      'remotereceivesocketsize' => '25600',
		      'receivemessagesize' => '25600',
		      'localreceivesocketsize' => '25600',
		      'localsendsocketsize' => '25600',
		      'toolname' => 'netperf',
		      'testduration' => '60',
		      'bursttype' => 'stream',
		      'remotesendsocketsize' => '25600',
		      'l4protocol' => 'TCP',
		      'noofinbound' => '1',
		      'sleepbetweenworkloads' => '30',
		      'sendmessagesize' => '25600'
		    }
		  }
		},


		'VNICJF' => {
		  'Component' => 'VmkAPI',
		  'Category' => 'ESX Server',
		  'TestName' => 'VNICJF',
		  'AutomationStatus'  => 'Automated',
		  'Summary' => 'Test Jambo Frame end-to-end',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VmkAPI::PktAPI::VNICJF',
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
		        'ConfigurePortGroup1'
		      ],
		      [
		        'ChangePortgroup_1'
		      ],
		      [
		        'AddUplinkonHelper1'
		      ],
		      [
		        'Switch_sut'
		      ],
		      [
		        'Switch_help'
		      ],
		      [
		        'NetAdapter_mtu_9000'
		      ],
		      [
		        'NetAdapter_DHCP'
		      ],
		      [
		        'TRAFFIC_Ping'
		      ],
		      [
		        'TRAFFIC_Netperf'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetAdapter_mtu_1500'
		      ],
		      [
		        'Reset_Switch_sut'
		      ],
		      [
		        'Reset_Switch_help'
		      ]
		    ],
		    'NetAdapter_DHCP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv4' => 'dhcp'
		    },
		    'ConfigurePortGroup1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'portgroup' => {
		        '[3]' => {
		          'name' => 'vss-pg-helper',
		          'vss' => 'host.[1].vss.[2]'
		        }
		      }
		    },
		    'ChangePortgroup_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[3]'
		    },
		    'AddUplinkonHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'Switch_sut' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '9000'
		    },
		    'Switch_help' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'mtu' => '9000'
		    },
		    'NetAdapter_mtu_9000' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '9000'
		    },
		    'TRAFFIC_Ping' => {
		      'Type' => 'Traffic',
		      'pktfragmentation' => 'no',
		      'noofoutbound' => '1',
		      'verification' => 'Verification_1',
		      'testduration' => '60',
		      'toolname' => 'ping',
		      'sleepbetweenworkloads' => '30',
		      'pingpktsize' => '8000-2000,2000'
		    },
		    'TRAFFIC_Netperf' => {
		      'Type' => 'Traffic',
                      'TestAdapter' => 'vm.[1].vnic.[1]',
                      'SupportAdapter' => 'vm.[2].vnic.[1]',
		      'remotereceivesocketsize' => '128000',
		      'remotesendsocketsize' => '128000',
		      'verification' => 'Verification_2',
		      'localreceivesocketsize' => '128000',
		      'localsendsocketsize' => '128000',
		      'testduration' => '60',
		      'toolname' => 'netperf'
		    },
		    'NetAdapter_mtu_1500' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
		      'mtu' => '1500'
		    },
		    'Reset_Switch_sut' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'mtu' => '1500'
		    },
		    'Reset_Switch_help' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[2]',
		      'mtu' => '1500'
		    },
		    'Verification_2' => {
		      'PktCapVerificaton' => {
		        'pktcount' => '1000+',
		        'verificationtype' => 'pktcap'
		      }
		    },
		    'Verification_1' => {
		      'PktCapVerificaton' => {
		        'pktcount' => '55-60',
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
#       This is the constructor for PktAPI.
#
# Input:
#       None.
#
# Results:
#       An instance/object of PktAPI class.
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
   my $self = $class->SUPER::new(\%PktAPI);
   return (bless($self, $class));
}
1;
