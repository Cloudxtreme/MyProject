#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::ESXCLI::ESXCLITds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("ConnectionList","NeighborList","VswitchList","VswitchAddRemove",
             "VswitchUplinkAddRemove","VswitchSet","VswitchPolicyFailover",
             "VswitchPolicySecurity","VswitchPolicyShaping","PortgroupList",
             "PortgroupAddRemove","PortgroupSet","PortgroupPolicyFailover",
             "PortgroupPolicySecurity","PortgroupPolicyShaping","Dnslistsearch",
             "Dnslistserver","DnsAddRemoveSearch","DnsAddRemoveServer",
             "NicList","NicDownUp","NicGetSetInfo",
             "NicNegativeGetSetInfo","InterfaceList","InterfaceAddRemove",
             "InterfaceIPv4SetGet","InterfaceIPv6SetGet","InterfaceNegativeRemove",
             "VDSList");

   %ESXCLI = (
		'PortgroupSet' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortgroupSet',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup '.
		               'set(vlan id)',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupSet',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'portgroupadd'
		      ],
		      [
		        'portgroupset'
		      ],
		      [
		        'checkset'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupset' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup set',
		      'args' => '-v 200 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkset' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup list',
		      'expectedstring' => '200',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchAddDel' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchAddDel',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup' .
		               ' add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupAddRemove',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'portgroupadd'
		      ],
		      [
		        'checkportgroup'
		      ],
		      [
		        'portgroupremove'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkportgroup' => {
		      'Type' => 'Command',
		      'command' => ' esxcli network vswitch standard portgroup list',
		      'expectedstring' => 'testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup remove',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'Dnslistserver' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'Dnslistserver',
		  'Summary' => 'Test command esxcli network ip dns server list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::Dnslistserver',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Dnslistserver'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'Dnslistserver' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns server list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchList',
		  'Summary' => 'Test command esxcli network vswitch standard list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchlistnegative'
		      ],
		      [
		        'vswitchlistone'
		      ],
		      [
		        'vswitchlist'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchlistnegative' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedresult' => 'FAIL',
		      'args' => '-v vswitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchlistone' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'args' => '-v vSwitch0',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchlist' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'InterfaceIPv4SetGet' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'InterfaceIPv4SetGet',
		  'Summary' => 'Test command esxcli network ip interface ipv4 set/get',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::InterfaceIPv4SetGet',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'VswitchAdd'
		      ],
		      [
		        'PortgroupAdd'
		      ],
		      [
		        'InterfaceAdd'
		      ],
		      [
		        'InterfaceIPv4Static'
		      ],
		      [
		        'InterfaceCheckIPv4Static'
		      ],
		      [
		        'InterfaceIPv4None'
		      ],
		      [
		        'InterfaceCheckIPv4None'
		      ],
		      [
		        'InterfaceIPv4Dhcp'
		      ],
		      [
		        'InterfaceCheckIPv4Dhcp'
		      ],
		      [
		        'InterfaceRemove'
		      ],
		      [
		        'PortgroupRemove'
		      ],
		      [
		        'VswitchRemove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'VswitchAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface add',
		      'args' => '-p testpg100 -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv4Static' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 set',
		      'args' => '-I 192.168.20.20 -N 255.255.255.0 -t static -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv4Static' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 get',
		      'expectedstring' => 'vmk99  192.168.20.20  255.255.255.0  192.168.20.255  STATIC',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv4None' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 set',
		      'args' => '-t none -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv4None' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 get',
		      'expectedstring' => 'vmk99  0.0.0.0       0.0.0.0       0.0.0.0         NONE',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv4Dhcp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 set',
		      'args' => '-t dhcp -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv4Dhcp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv4 get',
		      'expectedstring' => 'DHCP',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface remove',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup remove',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'VswitchRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'NicList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'NicList',
		  'Summary' => 'Test command esxcli network nic list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::NicList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NicList'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'NicList' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'NicGetSetInfo' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'NicGetSetInfo',
		  'Summary' => 'Test command esxcli network nic set/get',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::NicGetSetInfo',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NicSetHalfSpeed'
		      ],
		      [
		        'SleeptoWaitUP'
		      ],
		      [
		        'CheckHalfSpeed'
		      ],
		      [
		        'NicSetFullSpeed'
		      ],
		      [
		        'SleeptoWaitUP'
		      ],
		      [
		        'CheckFullSpeed'
		      ],
		      [
		        'NicSetAuto'
		      ],
		      [
		        'SleeptoWaitUP'
		      ],
		      [
		        'CheckAuto'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'NicSetHalfSpeed' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'args' => '-D half -S 100 -n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'SleeptoWaitUP' => {
		      'Type' => 'Command',
		      'command' => 'sleep 15',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'CheckHalfSpeed' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic list',
		      'expectedstring' => 'Up\s+100\s+Half',
		      'args' => '|grep vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicSetFullSpeed' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'args' => '-D full -S 100 -n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'CheckFullSpeed' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic list',
		      'expectedstring' => 'Up\s+100\s+Full',
		      'args' => '|grep vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicSetAuto' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'args' => '-a -n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'CheckAuto' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic get',
		      'expectedstring' => 'Auto Negotiation: true',
		      'args' => ' -n vmnic1 |grep \'   Auto\'',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'NeighborList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'NeighborList',
		  'Summary' => 'Test command esxcli network ip neighbor list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::NeighborList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'neighborlistnegative'
		      ],
		      [
		        'neighborlistipv4'
		      ],
		      [
		        'neighborlistipv6'
		      ],
		      [
		        'neighborlistall'
		      ],
		      [
		        'neighborlist'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'neighborlistnegative' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip neighbor list',
		      'expectedstring' => 'Invalid data constraint for parameter',
		      'args' => '-v 3',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'neighborlistipv4' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip neighbor list',
		      'args' => '-v 4',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'neighborlistipv6' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip neighbor list',
		      'args' => '-v 6',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'neighborlistall' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip neighbor list',
		      'args' => '-v all',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'neighborlist' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip neighbor list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'NicNegativeGetSetInfo' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'NicNegativeGetSetInfo',
		  'Summary' => 'Test command esxcli network nic set/get',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::NicNegativeGetSetInfo',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NicNegativeSetSpeed'
		      ],
		      [
		        'NicNegativeSetDuplex'
		      ],
		      [
		        'NicNegativeSetNic'
		      ],
		      [
		        'NicNegativeGetInfo'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'NicNegativeSetSpeed' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'expectedstring' => 'Invalid data constraint for parameter \'speed\'',
		      'args' => '-D full -S 1000000 -n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicNegativeSetDuplex' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'expectedstring' => 'Invalid data constraint for parameter \'duplex\'',
		      'args' => '-D fullhalf -S 100 -n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicNegativeSetNic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic set',
		      'expectedstring' => 'There is no pnic with name vmnic100',
		      'args' => '-D full -S 100 -n vmnic100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicNegativeGetInfo' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic get',
		      'expectedstring' => 'There is no pnic with name vmnic100',
		      'args' => '-n vmnic100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchPolicySecurity' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchPolicySecurity',
		  'Summary' => 'Test command esxcli network vswitch standard policy' .
		               ' security set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchPolicySecurity',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'setsecurity'
		      ],
		      [
		        'checkPromiscuous'
		      ],
		      [
		        'checkMAC'
		      ],
		      [
		        'checkForged'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setsecurity' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy security set',
		      'args' => '-f false -m false -p true -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkPromiscuous' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy security get',
		      'expectedstring' => 'true',
		      'args' => '-v vSwitch100 |grep \'Allow Promiscuous\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkMAC' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy security get',
		      'expectedstring' => 'false',
		      'args' => '-v vSwitch100 |grep \'Allow MAC Address Change\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkForged' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy security get',
		      'expectedstring' => 'false',
		      'args' => '-v vSwitch100 |grep \'Allow Forged Transmits\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'InterfaceList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'InterfaceList',
		  'Summary' => 'Test command esxcli network ip interface list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::InterfaceList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'InterfaceList'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'InterfaceList' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'InterfaceIPv6SetGet' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'InterfaceIPv6SetGet',
		  'Summary' => 'Test command esxcli network ip interface ipv6 set/get',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt,hostreboot',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::InterfaceIPv6SetGet',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EanbledIPv6'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'VswitchAdd'
		      ],
		      [
		        'PortgroupAdd'
		      ],
		      [
		        'InterfaceAdd'
		      ],
		      [
		        'InterfaceIPv6Static'
		      ],
		      [
		        'InterfaceCheckIPv6Static'
		      ],
		      [
		        'InterfaceIPv6RemoveStatic'
		      ],
		      [
		        'InterfaceCheckIPv6RemoveStatic'
		      ],
		      [
		        'InterfaceIPv6Dhcp6'
		      ],
		      [
		        'InterfaceCheckIPv6Dhcp6'
		      ],
		      [
		        'InterfaceIPv6AD'
		      ],
		      [
		        'InterfaceCheckIPv6AD'
		      ],
		      [
		        'InterfaceRemove'
		      ],
		      [
		        'PortgroupRemove'
		      ],
		      [
		        'VswitchRemove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'EanbledIPv6' => {
		      'Type' => 'Command',
		      'command' => 'esxcfg-vmknic',
		      'args' => '-6 true',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'reboot' => 'yes'
		    },
		    'VswitchAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface add',
		      'args' => '-p testpg100 -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv6Static' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 address add',
		      'args' => '-I 2011::1/64 -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv6Static' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 address list',
		      'expectedstring' => '2011::1',
		      'args' => '|grep \'2011::1\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv6RemoveStatic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 address remove',
		      'args' => '-I 2011::1/64 -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv6RemoveStatic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 address list',
		      'expectedresult' => 'FAIL',
		      'expectedstring' => '2011::1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv6Dhcp6' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 set',
		      'args' => '-d true -r false -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv6Dhcp6' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 get',
		      'expectedstring' => 'vmk99            true               false',
		      'args' => '-n vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceIPv6AD' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 set',
		      'args' => '-d false -r true -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceCheckIPv6AD' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface ipv6 get',
		      'expectedstring' => 'vmk99           false                true',
		      'args' => '-n vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface remove',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup remove',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'VswitchRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'PortgroupPolicyShaping' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortgroupPolicyShaping',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup' .
		               ' policy shaping set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupPolicyShaping',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'portgroupadd'
		      ],
		      [
		        'setshaping'
		      ],
		      [
		        'checkEnabled'
		      ],
		      [
		        'checkAverageBandwidth'
		      ],
		      [
		        'checkPeakBandwidth'
		      ],
		      [
		        'checkBursSize'
		      ],
		      [
		        'setdisabled'
		      ],
		      [
		        'checkDisabled'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setshaping' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping set',
		      'args' => '-b 102400 -t 1024 -k 1024000 -p testpg100 -e true',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkEnabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping get',
		      'expectedstring' => 'true',
		      'args' => '-p testpg100 |grep \'Enabled\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkAverageBandwidth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping get',
		      'expectedstring' => '102400',
		      'args' => '-p testpg100 |grep \'Average Bandwidth\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkPeakBandwidth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping get',
		      'expectedstring' => '1024000',
		      'args' => '-p testpg100 |grep \'Peak Bandwidth\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkBursSize' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping get',
		      'expectedstring' => '1024',
		      'args' => '-p testpg100 |grep \'Burst Size\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setdisabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping set',
		      'args' => '-p testpg100 -e false',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkDisabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy shaping get',
		      'expectedstring' => 'false',
		      'args' => '-p testpg100 |grep \'Enabled\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'ConnectionList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'ConnectionList',
		  'Summary' => 'Test command esxcli network ip connection list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::ConnectionList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'connectionlistnegative'
		      ],
		      [
		        'connectionlisttcp'
		      ],
		      [
		        'connectionlistudp'
		      ],
		      [
		        'connectionlistip'
		      ],
		      [
		        'connectionlistall'
		      ],
		      [
		        'connectionlist'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'connectionlistnegative' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'expectedstring' => 'Invalid data constraint for parameter',
		      'args' => '-t t',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'connectionlisttcp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'args' => '-t tcp',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'connectionlistudp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'args' => '-t udp',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'connectionlistip' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'args' => '-t ip',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'connectionlistall' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'args' => '-t all',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'connectionlist' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip connection list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'PortgroupPolicySecurity' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortgroupPolicySecurity',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup' .
		               ' policy security set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupPolicySecurity',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'portgroupadd'
		      ],
		      [
		        'setsecurity'
		      ],
		      [
		        'checkPromiscuous'
		      ],
		      [
		        'checkMAC'
		      ],
		      [
		        'checkForged'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setsecurity' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy security set',
		      'args' => '-f false -m false -o true -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkPromiscuous' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy security get',
		      'expectedstring' => 'true',
		      'args' => '-p testpg100 |grep \'Allow Promiscuous\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkMAC' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy security get',
		      'expectedstring' => 'false',
		      'args' => '-p testpg100 |grep \'Allow MAC Address Change\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkForged' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy security get',
		      'expectedstring' => 'false',
		      'args' => '-p testpg100 |grep \'Allow Forged Transmits\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'NicDownUp' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'NicDownUp',
		  'Summary' => 'Test command esxcli network nic down/up',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::NicDownUp',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NicDown'
		      ],
		      [
		        'CheckDown'
		      ],
		      [
		        'SleeptoWaitUP'
		      ],
		      [
		        'NicUp'
		      ],
		      [
		        'SleeptoWaitUP'
		      ],
		      [
		        'CheckUp'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'NicDown' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic down',
		      'args' => '-n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'CheckDown' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic list',
		      'expectedstring' => 'Down',
		      'args' => '|grep vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'SleeptoWaitUP' => {
		      'Type' => 'Command',
		      'command' => 'sleep 15',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'NicUp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic up',
		      'args' => '-n vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'CheckUp' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network nic list',
		      'expectedstring' => 'Up',
		      'args' => '|grep vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchPolicyFailover' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchPolicyFailover',
		  'Summary' => 'Test command esxcli network vswitch standard policy ' .
		               'failover set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchPolicyFailover',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'vswitchuplinkadd1'
		      ],
		      [
		        'vswitchuplinkadd2'
		      ],
		      [
		        'setfailover'
		      ],
		      [
		        'checkactivenic'
		      ],
		      [
		        'checkstandbynic'
		      ],
		      [
		        'checkLoadbalance'
		      ],
		      [
		        'checkDetection'
		      ],
		      [
		        'checkNotifySW'
		      ],
		      [
		        'checkFailback'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkadd1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink add',
		      'args' => '-v vSwitch100 -u vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkadd2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink add',
		      'args' => '-v vSwitch100 -u vmnic2',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setfailover' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover set',
		      'args' => '-a vmnic1 -b false -f beacon -l mac -n false -s vmnic2 -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkactivenic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'vmnic1',
		      'args' => '-v vSwitch100 |grep \'Active Adapters\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkstandbynic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'vmnic2',
		      'args' => '-v vSwitch100 |grep \'Standby Adapters\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkLoadbalance' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'srcmac',
		      'args' => '-v vSwitch100 |grep \'Load Balancing\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkDetection' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'beacon',
		      'args' => '-v vSwitch100 |grep \'Network Failure Detection\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkNotifySW' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'false',
		      'args' => '-v vSwitch100 |grep \'Notify Switches\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkFailback' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy failover get',
		      'expectedstring' => 'false',
		      'args' => '-v vSwitch100 |grep \'Failback\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchUplinkAddRemove' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchUplinkAddRemove',
		  'Summary' => 'Test command esxcli network vswitch standard uplink ' .
		               'add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchUplinkAddRemove',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'vswitchuplinkadd'
		      ],
		      [
		        'checkuplink1'
		      ],
		      [
		        'vswitchuplinkremove'
		      ],
		      [
		        'checkuplink2'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink add',
		      'args' => '-v vSwitch100 -u vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkuplink1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'vmnic1',
		      'args' => '-v vSwitch100 |grep Uplinks',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink remove',
		      'args' => '-v vSwitch100 -u vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkuplink2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => ' ',
		      'args' => '-v vSwitch100 |grep Uplinks',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'DnsAddRemoveSearch' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'DnsAddRemoveSearch',
		  'Summary' => 'Test command esxcli network ip dns search add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::DnsAddRemoveSearch',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Addsearch'
		      ],
		      [
		        'checkSearch1'
		      ],
		      [
		        'RemoveSearch'
		      ],
		      [
		        'checkSearch2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'Addsearch' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns search add',
		      'args' => '-d test.eng.vmware.com',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkSearch1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns search list',
		      'expectedstring' => 'test.eng.vmware.com',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'RemoveSearch' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns search remove',
		      'args' => '-d test.eng.vmware.com',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkSearch2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns search list',
		      'expectedresult' => 'FAIL',
		      'expectedstring' => 'test.eng.vmware.com',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchSet' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchSet',
		  'Summary' => 'Test command esxcli network vswitch standard set(cdp mtu)',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchSet',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'setcdpdown'
		      ],
		      [
		        'checksetcdpdown'
		      ],
		      [
		        'setcdplisten'
		      ],
		      [
		        'checksetcdplisten'
		      ],
		      [
		        'setcdpboth'
		      ],
		      [
		        'checksetcdpboth'
		      ],
		      [
		        'setcdpadvertise'
		      ],
		      [
		        'checksetcdpadvertise'
		      ],
		      [
		        'setmtu'
		      ],
		      [
		        'checkmtu'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setcdpdown' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard set',
		      'args' => '-c down -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checksetcdpdown' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'down',
		      'args' => '-v vSwitch100 |grep \'CDP Status\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setcdplisten' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard set',
		      'args' => '-c listen -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checksetcdplisten' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'listen',
		      'args' => '-v vSwitch100 |grep \'CDP Status\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setcdpboth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard set',
		      'args' => '-c both -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checksetcdpboth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'both',
		      'args' => '-v vSwitch100 |grep \'CDP Status\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setcdpadvertise' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard set',
		      'args' => '-c advertise -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checksetcdpadvertise' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'advertise',
		      'args' => '-v vSwitch100 |grep \'CDP Status\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setmtu' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard set',
		      'args' => '-m 9000 -v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkmtu' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => '9000',
		      'args' => '-v vSwitch100 |grep MTU',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchPolicyShaping' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchPolicyShaping',
		  'Summary' => 'Test command esxcli network vswitch standard policy' .
		               ' shaping set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchPolicyShaping',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'setshaping'
		      ],
		      [
		        'checkEnabled'
		      ],
		      [
		        'checkAverageBandwidth'
		      ],
		      [
		        'checkPeakBandwidth'
		      ],
		      [
		        'checkBursSize'
		      ],
		      [
		        'setdisabled'
		      ],
		      [
		        'checkDisabled'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setshaping' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping set',
		      'args' => '-b 102400 -t 1024 -k 1024000 -v vSwitch100 -e true',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkEnabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping get',
		      'expectedstring' => 'true',
		      'args' => '-v vSwitch100 |grep \'Enabled\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkAverageBandwidth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping get',
		      'expectedstring' => '102400',
		      'args' => '-v vSwitch100 |grep \'Average Bandwidth\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkPeakBandwidth' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping get',
		      'expectedstring' => '1024000',
		      'args' => '-v vSwitch100 |grep \'Peak Bandwidth\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkBursSize' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping get',
		      'expectedstring' => '1024',
		      'args' => '-v vSwitch100 |grep \'Burst Size\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setdisabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping set',
		      'args' => '-v vSwitch100 -e false',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkDisabled' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard policy shaping get',
		      'expectedstring' => 'false',
		      'args' => '-v vSwitch100 |grep \'Enabled\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'Dnslistsearch' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'Dnslistsearch',
		  'Summary' => 'Test command esxcli network ip dns search list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::Dnslistsearch',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Dnslistsearch'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'Dnslistsearch' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns search list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'InterfaceNegativeRemove' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'InterfaceNegativeRemove',
		  'Summary' => 'Test command esxcli network ip interface list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::InterfaceNegativeRemove',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'InterfaceNegativeRemove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'InterfaceNegativeRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface remove',
		      'expectedstring' => 'Invalid data constraint for parameter \'interface-name\'',
		      'args' => ' -i vmk9999',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VDSList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VDSList',
		  'Summary' => 'Test command esxcli network vswitch dvs vmware list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VDSList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'AddDVSStep1'
		      ],
		      [
		        'AddDVSStep2'
		      ],
		      [
		        'AddDVSStep3'
		      ],
		      [
		        'VDSListOne'
		      ],
		      [
		        'VDSListAll'
		      ],
		      [
		        'DelDVSStep1'
		      ],
		      [
		        'DelDVSStep2'
		      ],
		      [
		        'DelDVSStep3'
		      ],
		      [
		        'DelDVSStep4'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'AddDVSStep1' => {
		      'Type' => 'Command',
		      'command' => 'net-dvs',
		      'args' => '-a foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'AddDVSStep2' => {
		      'Type' => 'Command',
		      'command' => 'net-dvs',
		      'args' => '-A -p port1 foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'AddDVSStep3' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'VDSListOne' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch dvs vmware list',
		      'args' => '-v foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'VDSListAll' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch dvs vmware list',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'DelDVSStep1' => {
		      'Type' => 'Command',
		      'command' => 'net-dvs',
		      'args' => '-Y foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'DelDVSStep2' => {
		      'Type' => 'Command',
		      'command' => 'net-dvs',
		      'args' => '-D -p port1 foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'DelDVSStep3' => {
		      'Type' => 'Command',
		      'command' => 'net-dvs',
		      'args' => '-d foo1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'DelDVSStep4' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v foo1',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'PortgroupPolicyFailover' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortgroupPolicyFailover',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup ' .
		               'policy failover set',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupPolicyFailover',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd'
		      ],
		      [
		        'vswitchuplinkadd1'
		      ],
		      [
		        'vswitchuplinkadd2'
		      ],
		      [
		        'portgroupadd'
		      ],
		      [
		        'setfailover'
		      ],
		      [
		        'checkactivenic'
		      ],
		      [
		        'checkstandbynic'
		      ],
		      [
		        'checkLoadbalance'
		      ],
		      [
		        'checkDetection'
		      ],
		      [
		        'checkNotifySW'
		      ],
		      [
		        'checkFailback'
		      ],
		      [
		        'vswitchremove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkadd1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink add',
		      'args' => '-v vSwitch100 -u vmnic1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchuplinkadd2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard uplink add',
		      'args' => '-v vSwitch100 -u vmnic2',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'portgroupadd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'setfailover' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover set',
		      'args' => '-a vmnic1 -b false -f beacon -l mac -n false -s vmnic2 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkactivenic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'vmnic1',
		      'args' => '-p testpg100 |grep \'Active Adapters\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkstandbynic' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'vmnic2',
		      'args' => '-p testpg100 |grep \'Standby Adapters\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkLoadbalance' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'srcmac',
		      'args' => '-p testpg100 |grep \'Load Balancing\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkDetection' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'beacon',
		      'args' => '-p testpg100 |grep \'Network Failure Detection\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkNotifySW' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'false',
		      'args' => '-p testpg100 |grep \'Notify Switches\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkFailback' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup policy failover get',
		      'expectedstring' => 'false',
		      'args' => '-p testpg100 |grep \'Failback\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'PortgroupList' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'PortgroupList',
		  'Summary' => 'Test command esxcli network vswitch standard portgroup' .
		               ' list',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::PortgroupList',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'portgrouplist'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'portgrouplist' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup list',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'InterfaceAddRemove' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'InterfaceAddRemove',
		  'Summary' => 'Test command esxcli network ip interface add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::InterfaceAddRemove',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'VswitchAdd'
		      ],
		      [
		        'PortgroupAdd'
		      ],
		      [
		        'Interface1Add'
		      ],
		      [
		        'Interface1CheckName'
		      ],
		      [
		        'Interface1CheckMac'
		      ],
		      [
		        'Interface1CheckMTU'
		      ],
		      [
		        'InterfaceRemove1'
		      ],
		      [
		        'PortgroupRemove'
		      ],
		      [
		        'VswitchRemove'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'VswitchAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupAdd' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup add',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Interface1Add' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface add',
		      'args' => '-M 00:00:00:00:00:01  -m 2000 -p testpg100 -i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Interface1CheckName' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface list',
		      'expectedstring' => 'Name: vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Interface1CheckMac' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface list',
		      'expectedstring' => 'MAC Address: 00:00:00:00:00:01',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'Interface1CheckMTU' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface list',
		      'expectedstring' => 'MTU: 2000',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'InterfaceRemove1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip interface remove',
		      'args' => '-i vmk99',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'PortgroupRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard portgroup remove',
		      'args' => '-v vSwitch100 -p testpg100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'VswitchRemove' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'DnsAddRemoveServer' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'DnsAddRemoveServer',
		  'Summary' => 'Test command esxcli network ip dns server add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::DnsAddRemoveServer',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'Addserver'
		      ],
		      [
		        'checkServer1'
		      ],
		      [
		        'RemoveServer'
		      ],
		      [
		        'checkServer2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'Addserver' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns server add',
		      'args' => '-s 192.168.20.1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkServer1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns server list',
		      'expectedstring' => '192.168.20.1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'RemoveServer' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns server remove',
		      'args' => '-s 192.168.20.1',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkServer2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network ip dns server list',
		      'expectedresult' => 'FAIL',
		      'expectedstring' => '192.168.20.1',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},


		'VswitchAddDel' => {
		  'Component' => 'esxcli-network',
		  'Category' => 'ESX Server',
		  'TestName' => 'VswitchAddDel',
		  'Summary' => 'Test command esxcli network vswitch standard add/remove',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::ESXCLI::ESXCLI::VswitchAddRemove',
		  'TestbedSpec' => {
		    'host' => {
		      '[1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'vswitchadd1'
		      ],
		      [
		        'vswitchadd2'
		      ],
		      [
		        'checkvswitch1'
		      ],
		      [
		        'checkvswitch2'
		      ],
		      [
		        'vswitchremove1'
		      ],
		      [
		        'vswitchremove2'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'vswitchadd1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchadd2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard add',
		      'args' => '-v vSwitch101 -P 20',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkvswitch1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => 'vSwitch100',
		      'args' => '-v vSwitch100 |grep Name',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'checkvswitch2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard list',
		      'expectedstring' => '20',
		      'args' => '-v vSwitch101 |grep \'Configured Ports\'',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove1' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch100',
		      'testhost' => 'host.[1].x.[x]'
		    },
		    'vswitchremove2' => {
		      'Type' => 'Command',
		      'command' => 'esxcli network vswitch standard remove',
		      'args' => '-v vSwitch101',
		      'testhost' => 'host.[1].x.[x]'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for ESXCLI.
#
# Input:
#       None.
#
# Results:
#       An instance/object of ESXCLI class.
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
   my $self = $class->SUPER::new(\%ESXCLI);
   return (bless($self, $class));
}
