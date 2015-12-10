########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::NetFlowIPv6Tds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%NetFlowIPv6 = (
		'Basic-Paramters-VM' => {
                'TestName' => 'Basic-Paramters-VM',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                'Summary'  => 'Verify the ipfix IPv6 function with basic settings' .
                                'can record the flows between vnics',
                'Procedure'=> '1. Add one host into the VDS' .
                              '2. Add two VMs to the host' .
                              '3. Enable netflow for IPv6 on the portgroup' .
                              '4. Verify the IPv6 traffic between vnics' .
                              'can generate flow records',
                'ExpectedResult'   => 'PASS',
                'Status'           => 'Execution Ready',
                'PMT'              => '7835',
                'AutomationLevel'  => 'Automated',
                'FullyAutomatable' => 'Y',
                'TestcaseLevel'    => 'Functional',
                'TestcaseType'     => 'Functional',
                'Priority'         => 'P0',
                'Developer'        => 'shawntu',
                'Partnerfacing'    => 'N',
                'Duration'         => '100',
                'Version'          => '2' ,
		'Tags'             => 'CAT_P0',
		'AutomationStatus' => 'Automated',
		'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::Basic-Paramters-VM',
		'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM,
		'WORKLOADS' => {
		    'Sequence' => [
                      ['ConfigureIPv6'],
		      ['SetIpfix'],
                      ['EnableIpfix'],
                      ['TcpTraffic'],
                      ['PingTraffic'],
                      ['UDPTraffic'],
                      ['UDPFragment'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '60',
		      'samplerate'	 => '0',
		      'idletimeout'	 => '10'
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'TcpTraffic' => {
		      'Type'           => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification'   => 'Verification_1',
		      'l4protocol'     => 'tcp',
                      'L3Protocol'     => "ipv6",
		      'toolname'       => 'netperf',
		      'testduration'   => '120',
		      'testadapter'    => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
                    'Verification_1' => {
		      'NFdumpVerificaton' => {
                        'addressfamily'	  => 'ipv6',
		        'src'             => 'vm.[1].vnic.[1]',
		        'verificationtype'=> 'nfdump',
		        'dst'             => 'vm.[2].vnic.[1]',
                        'target'          => 'vm.[3].vnic.[1]',
                        }
		    },
                    'PingTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "Ping",
                        'L3Protocol'     => "ipv6",
                        'NoofInbound'    => "1",
                        'NoofOutbound'   => "1",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'verification'   => "Verification_2",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_2' => {
                        'NFdumpVerificaton' => {
                           'verificationtype'   => "nfdump",
                           'addressfamily'	=> 'ipv6',
                           'src'                => "vm.[1].vnic.[1]",
                           'dst'                => "vm.[2].vnic.[1]",
                           'target'             => 'vm.[3].vnic.[1]',
                        },
                     },
                    'UDPTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '1000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'UDPFragment' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '2000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_3' => {
                        'NFdumpVerificaton' => {
                        'verificationtype'   => "nfdump",
                        'addressfamily'	     => 'ipv6',
                        'src'                => "vm.[1].vnic.[1]",
                        'dst'                => "vm.[2].vnic.[1]",
                        'target'             => 'vm.[3].vnic.[1]',
                     },
                  },
		}
	    },
            'Basic-Paramters-VMK' => {
                    'TestName' => 'Basic-Paramters-VMK',
                    'Category' => 'ESX Server',
                    'Component'=> 'vDS',
                    'Product'  => 'ESX',
                    'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                    'Summary'  => 'Verify the ipfix IPv6 function with basic settings' .
                                  'can record the flows between vmk and vnic',
                    'Procedure'=> '1. Add one host into the VDS' .
                                  '2. Add one vmknic to the host'.
                                  '3. Add one VM to the host'.
                                  '3. Enable netflow for IPv6 on the portgroup' .
                                  '4. Verify the IPv6 traffic between vmk and vnic'.
                                  'can generate flow records',
                    'ExpectedResult'   => 'PASS',
                    'Status'           => 'Execution Ready',
                    'PMT'              => '7835',
                    'AutomationLevel'  => 'Automated',
                    'FullyAutomatable' => 'Y',
                    'TestcaseLevel'    => 'Functional',
                    'TestcaseType'     => 'Functional',
                    'Priority'         => 'P0',
                    'Developer'        => 'shawntu',
                    'Partnerfacing'    => 'N',
                    'Duration'         => '100',
                    'Version'          => '2' ,
		    'Tags'             => 'CAT_P0',
		    'AutomationStatus' => 'Automated',
		    'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::Basic-Paramters-VMK',
		    'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM,
                    'WORKLOADS' => {
                        'Sequence' => [
                            ['ConfigureIPv6'],
                            ['SetIpfix'],
                            ['EnableIpfix'],
                            ['TcpTraffic'],
                            ['PingTraffic'],
                            ['UDPTraffic'],
                            ['UDPFragment'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '60',
		      'samplerate'	 => '0',
		      'idletimeout'	 => '10'
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'TcpTraffic' => {
		      'Type'           => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification'   => 'Verification_1',
		      'l4protocol'     => 'tcp',
                      'L3Protocol'     => "ipv6",
		      'toolname'       => 'netperf',
		      'testduration'   => '120',
		      'testadapter'    => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
                    'Verification_1' => {
		      'NFdumpVerificaton' => {
                        'addressfamily'	  => 'ipv6',
		        'src'             => 'host.[1].vmknic.[1]',
		        'verificationtype'=> 'nfdump',
		        'dst'             => 'vm.[2].vnic.[1]',
                        'target'          => 'vm.[3].vnic.[1]',
                        }
		    },
                    'PingTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "Ping",
                        'L3Protocol'     => "ipv6",
                        'NoofInbound'    => "1",
                        'NoofOutbound'   => "1",
                        'TestAdapter'    => "host.[1].vmknic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'verification'   => "Verification_2",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_2' => {
                        'NFdumpVerificaton' => {
                           'verificationtype'   => "nfdump",
                           'addressfamily'	=> 'ipv6',
                           'src'                => "host.[1].vmknic.[1]",
                           'dst'                => "vm.[2].vnic.[1]",
                           'target'             => 'vm.[3].vnic.[1]',
                        },
                     },
                    'UDPTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "host.[1].vmknic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '1000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'UDPFragment' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "host.[1].vmknic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '2000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_3' => {
                        'NFdumpVerificaton' => {
                        'verificationtype'   => "nfdump",
                        'addressfamily'	     => 'ipv6',
                        'src'                => "host.[1].vmknic.[1]",
                        'dst'                => "vm.[2].vnic.[1]",
                        'target'             => 'vm.[3].vnic.[1]',
                     },
                  },
		}
	    },
            'ActiveFlowTimeOut' => {
                    'TestName' => 'ActiveFlowTimeOut',
                    'Category' => 'ESX Server',
                    'Component'=> 'vDS',
                    'Product'  => 'ESX',
                    'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                    'Summary'  => 'Verify after active flow time out, the ESX' .
                                  'can record the flows between vnic and vnic',
                    'Procedure'=> '1. Add one host into the VDS' .
                                  '2. Add two VMs to the host'.
                                  '3. Enable netflow for IPv6 on the portgroup' .
                                  'set active flow timeout to 60' .
                                  'set idle flow timeout to 200' .
                                  '4. Send traffic for 70 seconds, the IPv6 traffic'.
                                  'can generate flow records',
                    'ExpectedResult'   => 'PASS',
                    'Status'           => 'Execution Ready',
                    'Tags'             => 'sanity',
                    'PMT'              => '7835',
                    'AutomationLevel'  => 'Automated',
                    'FullyAutomatable' => 'Y',
                    'TestcaseLevel'    => 'Functional',
                    'TestcaseType'     => 'Functional',
                    'Priority'         => 'P1',
                    'Developer'        => 'shawntu',
                    'Partnerfacing'    => 'N',
                    'Duration'         => '100',
                    'Version'          => '2' ,
		    'AutomationStatus' => 'Automated',
		    'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::ActiveFlowTimeOut',
		    'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM,
                    'WORKLOADS' => {
                        'Sequence' => [
                            ['ConfigureIPv6'],
                            ['SetIpfix'],
                            ['EnableIpfix'],
                            ['TcpTraffic'],
                            ['PingTraffic'],
                            ['UDPTraffic'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '60',
		      'samplerate'	 => '0',
		      'idletimeout'	 => '200'
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'TcpTraffic' => {
		      'Type'           => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification'   => 'Verification_1',
		      'l4protocol'     => 'tcp',
                      'L3Protocol'     => "ipv6",
		      'toolname'       => 'netperf',
		      'testduration'   => '70',
		      'testadapter'    => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
                    'Verification_1' => {
		      'NFdumpVerificaton' => {
                        'addressfamily'	  => 'ipv6',
		        'src'             => 'vm.[1].vnic.[1]',
		        'verificationtype'=> 'nfdump',
		        'dst'             => 'vm.[2].vnic.[1]',
                        'target'          => 'vm.[3].vnic.[1]',
                        }
		    },
                    'PingTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "Ping",
                        'L3Protocol'     => "ipv6",
                        'NoofInbound'    => "1",
                        'NoofOutbound'   => "1",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'verification'   => "Verification_2",
                        'TestDuration'   => "70",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_2' => {
                        'NFdumpVerificaton' => {
                           'verificationtype'   => "nfdump",
                           'addressfamily'	=> 'ipv6',
                           'src'                => "vm.[1].vnic.[1]",
                           'dst'                => "vm.[2].vnic.[1]",
                           'target'             => 'vm.[3].vnic.[1]',
                        },
                     },
                    'UDPTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '1000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "70",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_3' => {
                        'NFdumpVerificaton' => {
                        'verificationtype'   => "nfdump",
                        'addressfamily'	     => 'ipv6',
                        'src'                => "vm.[1].vnic.[1]",
                        'dst'                => "vm.[2].vnic.[1]",
                        'target'             => 'vm.[3].vnic.[1]',
                     },
                  },
		}
	    },
            'IdleFlowTimeOut' => {
                    'TestName' => 'IdleFlowTimeOut',
                    'Category' => 'ESX Server',
                    'Component'=> 'vDS',
                    'Product'  => 'ESX',
                    'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                    'Summary'  => 'Verify after idle flow time out, the ESX' .
                                  'can record the flows between vnic and vnic',
                    'Procedure'=> '1. Add one host into the VDS' .
                                  '2. Add two VMs to the host'.
                                  '3. Enable netflow for IPv6 on the portgroup' .
                                  'set active flow timeout to 200' .
                                  'set idle flow timeout to 20' .
                                  '4. Send traffic for 20 seconds, then wait 20 seconds' .
                                  'the IPv6 traffic can generate flow records',
                    'ExpectedResult'   => 'PASS',
                    'Status'           => 'Execution Ready',
                    'Tags'             => 'sanity',
                    'PMT'              => '7835',
                    'AutomationLevel'  => 'Automated',
                    'FullyAutomatable' => 'Y',
                    'TestcaseLevel'    => 'Functional',
                    'TestcaseType'     => 'Functional',
                    'Priority'         => 'P1',
                    'Developer'        => 'shawntu',
                    'Partnerfacing'    => 'N',
                    'Duration'         => '100',
                    'Version'          => '2' ,
		    'AutomationStatus' => 'Automated',
		    'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::IdleFlowTimeOut',
		    'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM,
                    'WORKLOADS' => {
                        'Sequence' => [
                            ['ConfigureIPv6'],
                            ['SetIpfix'],
                            ['EnableIpfix'],
                            ['TcpTraffic'],
                            ['PingTraffic'],
                            ['UDPTraffic'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '200',
		      'samplerate'	 => '0',
		      'idletimeout'	 => VDNetLib::TestData::TestConstants::NETFLOW_IDLE_TIMEOUT,
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'TcpTraffic' => {
		      'Type'           => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification'   => 'Verification_1',
		      'l4protocol'     => 'tcp',
                      'L3Protocol'     => "ipv6",
		      'toolname'       => 'netperf',
		      'testduration'   => '20',
		      'testadapter'    => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
                    'Verification_1' => {
                      'sleepbeforefinal'   => VDNetLib::TestData::TestConstants::NETFLOW_IDLE_TIMEOUT,
		      'NFdumpVerificaton' => {
                        'addressfamily'	  => 'ipv6',
		        'src'             => 'vm.[1].vnic.[1]',
		        'verificationtype'=> 'nfdump',
		        'dst'             => 'vm.[2].vnic.[1]',
                        'target'          => 'vm.[3].vnic.[1]',
                        }
		    },
                    'PingTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "Ping",
                        'L3Protocol'     => "ipv6",
                        'NoofInbound'    => "1",
                        'NoofOutbound'   => "1",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'verification'   => "Verification_2",
                        'TestDuration'   => "20",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_2' => {
                        'sleepbeforefinal'   => VDNetLib::TestData::TestConstants::NETFLOW_IDLE_TIMEOUT,
                        'NFdumpVerificaton' => {
                           'verificationtype'   => "nfdump",
                           'addressfamily'	=> 'ipv6',
                           'src'                => "vm.[1].vnic.[1]",
                           'dst'                => "vm.[2].vnic.[1]",
                           'target'             => 'vm.[3].vnic.[1]',
                        },
                     },
                    'UDPTraffic' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '1000',
                        'verification'   => "Verification_3",
                        'TestDuration'   => "20",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_3' => {
                        'sleepbeforefinal'   => VDNetLib::TestData::TestConstants::NETFLOW_IDLE_TIMEOUT,
                        'NFdumpVerificaton' => {
                        'verificationtype'   => "nfdump",
                        'addressfamily'	     => 'ipv6',
                        'src'                => "vm.[1].vnic.[1]",
                        'dst'                => "vm.[2].vnic.[1]",
                        'target'             => 'vm.[3].vnic.[1]',
                     },
                  },
		}
	    },
            'Vmotion' => {
                    'TestName' => 'Vmotion',
                    'Category' => 'ESX Server',
                    'Component'=> 'vDS',
                    'Product'  => 'ESX',
                    'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                    'Summary'  => 'Verify before and after Vmotion,the ESX' .
                                  'can record the flows between vnic and vnic',
                    'Procedure'=> '1. Add one host into the VDS' .
                                  '2. Add two VMs to the host'.
                                  '3. Enable netflow for IPv6 on the portgroup' .
                                  'set active flow timeout to 100' .
                                  'set idle flow timeout to 20' .
                                  '4. Send traffic for 200 seconds, do vmotion in the same time' .
                                  'the IPv6 traffic can generate flow records' .
                                  '5. After do vmotion, send traffic for 100 seconds' .
                                  'the IPv6 traffic can generate flow records',
                    'ExpectedResult'   => 'PASS',
                    'Status'           => 'Execution Ready',
                    'Tags'             => 'sanity',
                    'PMT'              => '7835',
                    'AutomationLevel'  => 'Automated',
                    'FullyAutomatable' => 'Y',
                    'TestcaseLevel'    => 'Functional',
                    'TestcaseType'     => 'Functional',
                    'Priority'         => 'P1',
                    'Developer'        => 'shawntu',
                    'Partnerfacing'    => 'N',
                    'Duration'         => '300',
                    'Version'          => '2' ,
		    'AutomationStatus' => 'Automated',
		    'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::Vmotion',
		    'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_TwoVmknic_OneVmnicEachHost_ThreeVM,
                    'WORKLOADS' => {
                        'Sequence' => [
                            ['ConfigureIPv6'],
                            ['SetIpfix'],
                            ['EnableIpfix'],
                            ['EnableVMotion'],
                            ['TcpTraffic','vmotion'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1-2].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '60',
		      'samplerate'	 => '0',
		      'idletimeout'	 => '10',
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'EnableVMotion' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1-2].vmknic.[1]',
		      'configurevmotion' => 'ENABLE',
		    },
                    'TcpTraffic' => {
		      'Type'           => 'Traffic',
		      'expectedresult' => 'PASS',
		      'verification'   => 'Verification_1',
		      'l4protocol'     => 'tcp',
                      'L3Protocol'     => "ipv6",
		      'toolname'       => 'netperf',
		      'testduration'   => '180',
		      'testadapter'    => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
                    'vmotion' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'priority' => 'high',
		      'vmotion' => 'roundtrip',
		      'dsthost' => 'host.[2]',
		      'staytime' => '30',
                      'Iterations'   => "3",
		    },
                    'Verification_1' => {
		      'NFdumpVerificaton' => {
                        'addressfamily'	  => 'ipv6',
		        'src'             => 'vm.[1].vnic.[1]',
		        'verificationtype'=> 'nfdump',
		        'dst'             => 'vm.[2].vnic.[1]',
                        'target'          => 'vm.[3].vnic.[1]',
                        }
		    },
		}
	    },
            'JumboFrame' => {
                'TestName' => 'JumboFrame',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\IPfixIPv6',
                'Summary'  => 'Verify the ipfix IPv6 function with basic settings' .
                                'can record the jumbo frame packets between vnics',
                'Procedure'=> '1. Add one host into the VDS' .
                              '2. Add two VMs to the host' .
                              '3. Enable netflow for IPv6 on the portgroup' .
                              '4. Verify the IPv6 jumbo frame traffic between vnics' .
                              'can generate flow records',
                'ExpectedResult'   => 'PASS',
                'Status'           => 'Execution Ready',
                'PMT'              => '7835',
                'AutomationLevel'  => 'Automated',
                'FullyAutomatable' => 'Y',
                'TestcaseLevel'    => 'Functional',
                'TestcaseType'     => 'Functional',
                'Priority'         => 'P0',
                'Developer'        => 'shawntu',
                'Partnerfacing'    => 'N',
                'Duration'         => '100',
                'Version'          => '2' ,
		'Tags'             => 'Sanity',
		'AutomationStatus' => 'Automated',
		'testID'           => 'TDS::EsxServer::VDS::NetFlowIPv6::JumboFrame',
		'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM,
		'WORKLOADS' => {
		    'Sequence' => [
                      ['ConfigureIPv6'],
		      ['SetIpfix'],
                      ['EnableIpfix'],
                      ['SetVDSMTU'],
                      ['SetVMMTU'],
                      ['UDPJumboFrame'],
		    ],
                    'ConfigureIPv6' => {
                        'Type'		 => "NetAdapter",
                        'TestAdapter'	 => "host.[1].vmknic.[1],vm.[3].vnic.[1]",
                        'IPV6ADDR'	 => "default",
                        'IPV6'		 => "add",
                    },
		    'SetIpfix' => {
		      'Type'		 => 'Switch',
		      'TestSwitch'	 => 'vc.[1].vds.[1]',
                      'ipfix'		 => 'add',
		      'collector'	 => 'vm.[3].vnic.[1]',
                      'addressfamily'	 => 'ipv6',
		      'activetimeout'	 => '60',
		      'samplerate'	 => '0',
		      'idletimeout'	 => '10'
		    },
                    'EnableIpfix' => {
			 'Type'		 => "PortGroup",
                         'TestPortgroup' => "vc.[1].dvportgroup.[1]",
			 'configureipfix'=> "enable",
		    },
                    'SetVDSMTU' => {
		      'Type'        => 'Switch',
		      'TestSwitch'  => 'vc.[1].vds.[1]',
		      'mtu'         => '9000'
		    },
                    'SetVMMTU' => {
		      'Type'        => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
		      'mtu'         => '9000'
		    },
                    'UDPJumboFrame' => {
                        'Type'           => "Traffic",
                        'ToolName'       => "netperf",
                        'L3Protocol'     => "ipv6",
                        'L4Protocol'     => "udp",
                        'TestAdapter'    => "vm.[1].vnic.[1]",
                        'SupportAdapter' => "vm.[2].vnic.[1]",
                        'sendmessagesize'=> '8900',
                        'verification'   => "Verification_1",
                        'TestDuration'   => "120",
                        'ExpectedResult' => "PASS",
                     },
                    'Verification_1' => {
                        'NFdumpVerificaton' => {
                        'verificationtype'   => "nfdump",
                        'addressfamily'	     => 'ipv6',
                        'src'                => "vm.[1].vnic.[1]",
                        'dst'                => "vm.[2].vnic.[1]",
                        'target'             => 'vm.[3].vnic.[1]',
                     },
                  },
		}
	    },
        );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for NetFlow.
#
# Input:
#       None.
#
# Results:
#       An instance/object of NetFlow class.
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
   my $self = $class->SUPER::new(\%NetFlowIPv6);
   return (bless($self, $class));
}
