#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::PortMirrorTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use Data::Dumper;

use TDS::EsxServer::VDS::TestbedSpec ':VDSTestbedSpec';
# Import Workloads which are very common across all tests
use TDS::EsxServer::VDS::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);
{
%PortMirror = (
        'Security-PromiscuousMode' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Security-PromiscuousMode',
          'Summary' => 'Test security PromiscuousMode options of vds from ' .
                       'last_supported_version to current_version since ' .
                       'PromiscuousMode is implemented by PortMirror code',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDSLastSupported_OneDVPG,
            'vm' => {
              '[1-2]' => One_vnic_vmxnet3_on_host1_on_dvpg1,
              '[3]'   => One_vnic_vmxnet3_on_host2_on_dvpg1,
            },
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateDVPG_A'],
              ['CreateDVPG_B'],
              ['ChangePortgroup1'],
              ['ChangePortgroup2'],
              ['NetAdapter_Back'],
              ['DisablePromiscuous'],
              ['Traffic1'],
              ['EnablePromiscuous'],
              ['Traffic2'],
              ['UpgradeVDS1'],
              ['DisablePromiscuous'],
              ['Traffic1'],
              ['EnablePromiscuous'],
              ['Traffic2'],
              ['UpgradeVDS2'],
              ['DisablePromiscuous'],
              ['Traffic1'],
              ['EnablePromiscuous'],
              ['Traffic2'],
            ],
            'Duration' => 'time in seconds',
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => 2,
                  'name' => 'promiscuous_a',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => 2,
                  'name' => 'promiscuous_b',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'DisablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'setpromiscuous' => 'disable',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'toolname' => 'netperf',
              'testduration' => 10,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'setpromiscuous' => 'Enable',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'toolname' => 'netperf',
              'testduration' => '10',
              'noofinbound' => '1',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'UpgradeVDS1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_LAST_RELEASED_VERSION,
            },
            'UpgradeVDS2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'ERSPANSource-MultiSourceMultiDestination' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'ERSPANSource-MultiSourceMultiDestination',
          'Summary' => 'Verify the function of ERSPAN source session with multiple' .
                       ' source and multiple destinaiton',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_ThreeDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[2]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]'
                  },
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[2]'
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
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3-4]' => One_vnic_e1000_on_host2_on_dvpg1,
            },
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['NetAdapter_Back1'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['NetAdapter_3'],
              ['NetAdapter_4'],
              ['CreateSession'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['NetAdapter_Back2'],
              ['NetAdapter_Back3']
            ],
            'Duration' => 'time in seconds',
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => '176.10.1.10'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '176.10.1.11'
            },
            'NetAdapter_3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'ipv4' => '176.11.1.10'
            },
            'NetAdapter_4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[2]',
              'ipv4' => '176.11.1.11'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'erspanip'  => ['vm.[3].vnic.[1]->IPv4','vm.[4].vnic.[1]->IPv4'],
                 'sessiontype' => 'encapsulatedRemoteMirrorSource',
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','vm.[2].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','vm.[2].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetAdapter_Back2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3-4].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_Back3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1-2]',
              'ipv4' => 'auto'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,src host 176.11.1.11,dst host 176.11.1.10',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,src host 176.10.1.11,dst host 176.10.1.10',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANSource-AllowNormalIO' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANSource-AllowNormalIO',
          'Summary' => 'Verify the function of RSPAN source session enable normal IO',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => {
                'portgroup' => {
                  '[2]' => {
                    'vss' => 'host.[2].vss.[2]'
                  },
                  '[1]' => {
                    'vss' => 'host.[2].vss.[1]'
                  }
                },
                'vss' => {
                  '[2]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[2]'
                  },
                  '[1]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[1]'
                  }
                },
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  }
                },
                'pswitchport' => {
                  '[1]' => {
                    'vmnic' => 'host.[2].vmnic.[2]'
                  }
                }
              },
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3-4]' => One_vnic_e1000_on_host2_on_pg1,
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['ConfigurePortGroup1'],
              ['ChangePortgroup_1'],
              ['CreateSession'],
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['NetperfTraffic3'],
              ['EditSession1'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['NetperfTraffic4']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'ConfigurePortGroup1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'portgroup' => {
                '[3]' => {
                  'name' => 'rspandestination',
                  'vss' => 'host.[2].vss.[2]'
                }
              }
            },
            'ChangePortgroup_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[3]'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[2]',
              'setpromiscuous' => 'Enable'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1],host.[1].vmknic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EditSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'sessiontype' => 'remoteMirrorSource',
              },
            },
            'NetperfTraffic4' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANSource-PortToUplink' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANSource-PortToUplink',
          'Summary' => 'Verify the function of RSPAN source session',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSS_OnePG_Pswitch,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]'   => One_vnic_e1000_on_host2_on_pg1,
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1],host.[1].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-AllowNormalIO' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-AllowNormalIO',
          'Summary' => 'Verify the function of normal IO when set port as ' .
                       'mirror destinaiton',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['DisableEnablevNic'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['EditSession1'],
              ['DisableEnablevNic'],
              ['NetperfTraffic3'],
              ['NetperfTraffic1']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'DisableEnablevNic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'devicestatus' => 'DOWN,UP',
              'iterations' => '1'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'EditSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'sessiontype' => 'dvPortMirror',
              },
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-SessionEnabledDisabled' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-SessionEnabledDisabled',
          'Summary' => 'Verify the function of port mirror enabled/disabled',
          'ExpectedResult' => 'PASS',
          'Tags' => 'CAT_P0',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['DisabledSession'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '60',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DisabledSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'version' => 'v2',
                 'sessiontype' => 'dvPortMirror',
                 'enabled' => 'false',
              },
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '0',
                'truncatedpkt' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'MIXDestination-PreserveOrigVlan' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'MIXDestination-PreserveOrigVlan',
          'Summary' => 'Test the MixDestination session type with preserve ' .
                       'original vlan id functionaliy,test Null VLAN,VGT, VST,' .
                       ' and types of PVLAN',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_TwoVmnic_VSS_Vmk_OnePG_Pswitch,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3-4]' => One_vnic_e1000_on_host2_on_dvpg1,
              '[5]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              },
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetAdapter_Back'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetperfTraffic11'],
              ['NetperfTraffic12'],
              ['SetVLAN'],
              ['setvlan4095'],
              ['NetperfTraffic11'],
              ['NetperfTraffic13'],
              ['SetVLANTrunk'],
              ['SetGuestVLAN'],
              ['NetperfTraffic21'],
              ['NetperfTraffic22'],
              ['RemoveGuestVLAN1'],
              ['RemoveGuestVLAN3'],
              ['CreateDVPG1'],
              ['AddPort1'],
              ['CreateDVPG2'],
              ['AddPort2'],
              ['CreateDVPG3'],
              ['AddPort3'],
              ['AddPVLAN_Promiscuos'],
              ['AddPVLAN_Isolated'],
              ['AddPVLAN_Community'],
              ['SetPVLAN_Promiscuous'],
              ['SetPVLAN_Isolated'],
              ['SetPVLAN_Community'],
              ['ChangePortgroup11'],
              ['ChangePortgroup12'],
              ['ChangePortgroup13'],
              ['RemoveSession1'],
              ['RemoveSession2'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetperfTraffic31'],
              ['NetperfTraffic32'],
              ['ChangePortgroup21'],
              ['ChangePortgroup22'],
              ['ChangePortgroup23'],
              ['RemoveSession1'],
              ['RemoveSession2'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetperfTraffic41'],
              ['NetperfTraffic42'],
              ['ChangePortgroup31'],
              ['ChangePortgroup32'],
              ['ChangePortgroup33'],
              ['RemoveSession1'],
              ['RemoveSession2'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetperfTraffic51'],
              ['NetperfTraffic52']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '1500',
                 'sessiontype' => 'mixedDestMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'stripvlan' => 'false',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'mirrorlength' => '1500',
                 'sessiontype' => 'mixedDestMirror',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'stripvlan' => 'false',
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic11' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic12' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'SetVLAN' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
            },
            'setvlan4095' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[1].portgroup.[1]',
              'vlantype' => 'access',
              'vlan' => '4095'
            },
            'NetperfTraffic13' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic22' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
              'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]',
            },
            'SetVLANTrunk' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'trunk',
              'vlan' => '[0-4094]'
            },
            'SetGuestVLAN' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'vlaninterface' => {
                          '[1]' => {
                              vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                          },
                      },
            },
            'NetperfTraffic21' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_4',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
              'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]',
            },
            'RemoveGuestVLAN1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]',
            },
            'RemoveGuestVLAN3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'deletevlaninterface' => 'vm.[3].vnic.[1].vlaninterface.[1]',
            },
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_170_170',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '2'
            },
            'CreateDVPG2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'dvpg_i_170_171',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '2'
            },
            'CreateDVPG3' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[4]' => {
                  'ports' => undef,
                  'name' => 'dvpg_c_170_173',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort3' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'addporttodvportgroup' => '2'
            },
            'AddPVLAN_Promiscuos' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'promiscuous'
            },
            'AddPVLAN_Isolated' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'isolated'
            },
            'AddPVLAN_Community' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'community'
            },
            'SetPVLAN_Promiscuous' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
            },
            'SetPVLAN_Isolated' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
            },
            'SetPVLAN_Community' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
            },
            'ChangePortgroup11' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup12' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup13' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'RemoveSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session1',
                 'version' => 'v2',
              },
            },
            'RemoveSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session2',
                 'version' => 'v2',
              },
            },
            'NetperfTraffic31' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_5',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic32' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'ChangePortgroup21' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup22' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup23' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic41' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_7',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic42' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_8',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'ChangePortgroup31' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup32' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup33' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic51' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_9',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic52' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_10',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_10' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_9' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_7' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan '. VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_4' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_8' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_6' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_5' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'VDSVersionHostVersionCompatibility' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'VDSVersionHostVersionCompatibility',
          'Summary' => 'This case test the compatibility of different VDS and ' .
                       'host combinations',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDSLastSupported_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
              '[1]' => HostConfig_OneVmnic,
            },
            'vm' => {
              '[1-3]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[4-6]' => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['IPConfigure'],
              ['NetperfTraffic1'],
              ['CreateSession2'],
              ['NetperfTraffic2'],
              ['RemoveSession1'],
              ['RemoveSession2'],
              ['ChangePortgroupWork_1'],
              ['RemoveHostFromVDS'],
              ['RemoveHostFromDC'],
              ['UpgradeVDS'],
              ['CreateSession1'],
              ['NetperfTraffic1'],
              ['UpgradeVDS2'],
              ['CreateSession4'],
              ['NetperfTraffic1'],
              ['CreateDC'],
              ['CreateVDS']
            ],
            'ExitSequence' => [
              ['RemoveDC']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
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
            'IPConfigure' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3-4].vnic.[1],vm.[6].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'srcrxport'  => ['vm.[4].vnic.[1]->dvport'],
                 'dstport'  => ['vm.[5].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[4].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'iperf',
              'testduration' => '10',
              'testadapter' => 'vm.[4].vnic.[1]',
              'supportadapter' => 'vm.[6].vnic.[1]'
            },
            'RemoveSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session1'
              },
            },
            'RemoveSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session2'
              },
            },
            'ChangePortgroupWork_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4-6].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[1]'
            },
            'RemoveHostFromVDS' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configurehosts' => 'remove',
              'host' => 'host.[2]',
            },
            'RemoveHostFromDC' => {
              'Type' => 'Datacenter',
              'TestDatacenter' => 'vc.[1].datacenter.[1]',
              'deletehostsfromdc'=> 'host.[2]',
            },
            'UpgradeVDS' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_LAST_RELEASED_VERSION,
            },
            'UpgradeVDS2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
            },
            'CreateSession4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'CreateDC' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'datacenter' => {
                '[2]' => {
                  'name' => 'portmirrortest',
                  'host' => 'host.[2]'
                }
              }
            },
            'CreateVDS' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'expectedresult' => 'FAIL',
              'vds' => {
                '[2]' => {
                  'datacenter' => 'vc.[1].datacenter.[2]',
                  'vmnicadapter' => 'host.[2].vmnic.[1]',
                  'version' => undef,
                  'configurehosts' => 'add',
                  'name' => 'portmirrortest',
                  'host' => 'host.[1-2]',
                }
              }
            },
            'RemoveDC' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'deletedatacenter' => 'vc.[1].datacenter.[2]'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },

        'ERSPANSource-PortToIP' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'ERSPANSource-PortToIP',
          'Summary' => 'Verify the function of ERSPAN source session with one ' .
                       'source and destination',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]'   => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['CreateSession'],
              ['NetperfTraffic1']
            ],
            'ExitSequence' => [
              ['NetAdapter_Back1'],
              ['NetAdapter_Back2']
            ],
            'Duration' => 'time in seconds',
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => '176.10.1.10'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '176.10.1.11'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'erspanip'  => ['vm.[3].vnic.[1]->IPv4'],
                 'mirrorlength' => '256',
                 'sessiontype' => 'encapsulatedRemoteMirrorSource',
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_Back2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,src host 176.10.1.11,dst host 176.10.1.10',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-CreateDestroySession' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-CreateDestroySession',
          'Summary' => 'Verify the function of port mirror create and destroy',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['RemoveSession'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'RemoveSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session1',
                 'version' => 'v2',
              },
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'MIXDestination-PortToPort' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'MIXDestination-PortToPort',
          'Summary' => 'Verify the function of Port Mirror MIX destinaiton ' .
                       'session type',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSS_OnePG_Pswitch,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2,
            },
            'vm' => {
              '[1-3]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[4]'   => One_vnic_e1000_on_host2_on_pg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1_Ingress'],
              ['NetperfTraffic2_Ingress'],
              ['NetperfTraffic3_Ingress'],
              ['EditSession1'],
              ['NetperfTraffic1_Egress'],
              ['NetperfTraffic2_Egress'],
              ['NetperfTraffic3_Egress'],
              ['EditSession2'],
              ['NetperfTraffic1_Ingress'],
              ['NetperfTraffic2_Ingress'],
              ['NetperfTraffic3_Ingress'],
              ['NetperfTraffic1_Egress'],
              ['NetperfTraffic2_Egress'],
              ['NetperfTraffic3_Egress']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'sessiontype' => 'mixedDestMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1],host.[1].vmknic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1_Ingress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2_Ingress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic3_Ingress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EditSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'srcrxport'  => ['null'],
                 'version' => 'v2',
                 'sessiontype' => 'mixedDestMirror',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
              },
            },
            'NetperfTraffic1_Egress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetperfTraffic2_Egress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'NetperfTraffic3_Egress' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'EditSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'version' => 'v2',
                 'sessiontype' => 'mixedDestMirror',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
              },
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestination-JumboFrame' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestination-JumboFrame',
          'Summary' => 'Verify the RSPAN destination with Jumbo frame',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_OnePswitchPort,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1]' => Two_vnic_e1000_on_host1_on_dvpg1,
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => One_vnic_e1000_on_host2_on_dvpg1,
            },
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['RSPANSource'],
              ['SetMTU1'],
              ['SetVMMTU1'],
              ['SetVMMTU2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['SetVMMTU3'],
              ['SetVMMTU4'],
              ['SetMTU2'],
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '6000',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'source',
              'rspansession' => '4'
            },
            'SetMTU1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'SetVMMTU1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'mtu' => '9000'
            },
            'SetVMMTU2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'mtu' => '9000'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2-3].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetVMMTU3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'mtu' => '1500'
            },
            'SetVMMTU4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'mtu' => '1500'
            },
            'SetMTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,size < 6010,size > 1400',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-AcrossVLAN' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-AcrossVLAN',
          'Summary' => 'Verify the function of dvport session can cross ' .
                       'different VLAN',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateDVPortgroup'],
              ['AddPort'],
              ['ChangePortgroupWork_1'],
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['SetVLAN1'],
              ['NetperfTraffic1'],
              ['SetVLAN2'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateDVPortgroup' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'dvmirrorpg',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '5'
            },
            'ChangePortgroupWork_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'SetVLAN1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'SetVLAN2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999,vlan ' . VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANSource-Vmotion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANSource-Vmotion',
          'Summary' => 'Verify the function of RSPAN source session with vmotion',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_TwoVmnic_VSS_VmkOnDVPG_Pswitch,
              '[1]' => HostConfig_OneVmnic_VmkOnDVPG1,
            },
            'vm' => {
              '[1]' => One_vnic_e1000_on_host1_on_dvpg1_shared,
              '[2]' => One_vnic_e1000_on_host2_on_pg1,
              '[3]' => One_vnic_e1000_on_host2_on_dvpg2,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['AddUplinkonHelper1'],
              ['AddUplinkonHelper2'],
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['EnableVMotion1'],
              ['EnableVMotion2'],
              ['CreateSession'],
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetperfTraffic2'],
              ['NetperfTraffic1',
               'vmotion'
              ],
              ['NetperfTraffic1',
               'vmotion'
              ],
              ['NetperfTraffic1',
               'vmotion'
              ],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN'],
              ['NetAdapter_Back1']
            ],
            'Duration' => 'time in seconds',
            'AddUplinkonHelper1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
            'AddUplinkonHelper2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'toolname' => 'ping',
              'testduration' => '240',
              'pingpktsize' => '300',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'staytime' => '60'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1],host.[2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '100+',
                'pktcapfilter' => 'count 199',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-SnapshotLength' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-SnapshotLength',
          'Summary' => 'Verify that length of the packet to be mirrored can be '.
                       ' changed',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['Traffic1'],
              ['EditSession1'],
              ['Traffic2'],
              ['EditSession2'],
              ['Traffic3']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '128',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'verificationresult' => 'PASS',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EditSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'mirrorlength' => '100',
                 'version' => 'v2',
                 'sessiontype' => 'dvPortMirror',
              },
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'verificationresult' => 'PASS',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EditSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'mirrorlength' => '1500',
                 'version' => 'v2',
                 'sessiontype' => 'dvPortMirror',
              },
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'verificationresult' => 'PASS',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 1000,size < 1510,',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 1000,size < 110,',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 1000,size < 138,',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-PortToPort' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-PortToPort',
          'Summary' => 'Verify the function of mirroring from dvport to dvport',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]'   => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['NetperfTraffic3']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['host.[1].vmknic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1],host.[1].vmknic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'host.[1].vmknic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-JumboFrame' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-JumboFrame',
          'Summary' => 'Verify the function of Port Mirror with jumbo frames',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['SetMTU1'],
              ['SetVMMTU1'],
              ['NetAdapter_Back'],
              ['NetperfTraffic'],
              ['SetVMMTU2'],
              ['SetMTU2']
            ],
            'ExitSequence' => [
              ['SetVMMTU2'],
              ['SetMTU2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '5000',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
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
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'mtu' => '9000'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '65535',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '65535',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'SetVMMTU2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'mtu' => '1500'
            },
            'SetMTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999,size < 5010,size > 4800',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-VerifyPacket' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-VerifyPacket',
          'Summary' => 'Verify the mirror source packet should be same as ' .
                       'mirror packet',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['CreateSession'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['NetAdapter_Back']
            ],
            'Duration' => 'time in seconds',
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'ipv4' => '176.10.1.10'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => '176.10.1.11'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '1500',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'testduration' => '60',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'testduration' => '60',
              'toolname' => 'ping',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'srcpktcapfilter' => 'count 200,src host 176.10.1.11,dst host 176.10.1.10',
                'target' => 'src,vm.[2].vnic.[1]',
                'pktcount' => '50+',
                'pktcapfilter' => 'count 200,src host 176.10.1.11,dst host 176.10.1.10',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'srcpktcapfilter' => 'count 200,dst host 176.10.1.11,src host 176.10.1.10',
                'target' => 'src,vm.[2].vnic.[1]',
                'pktcount' => '50+',
                'pktcapfilter' => 'count 200,dst host 176.10.1.11,src host 176.10.1.10',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-MirrorWithPromiscuousMode' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-MirrorWithPromiscuousMode',
          'Summary' => 'Verify the DVPort session with PromiscuousMode',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-3]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[4]'   => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateDVPG1'],
              ['ChangePortgroup1'],
              ['CreateSession1'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['EnablePromiscuous'],
              ['NetperfTraffic1'],
              ['NetperfTraffic3']
            ],
            'Duration' => 'time in seconds',
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => 5,
                  'name' => 'dvpg_promiscuous',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1],vm.[4].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '18',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'setpromiscuous' => 'Enable',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'verificationresult' => 'PASS',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '18',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'ERSPANSource-Vmotion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'ERSPANSource-Vmotion',
          'Summary' => 'Verify the function of ERSPAN source session with vmotion',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[1-2]' => HostConfig_TwoVmnic_VSS_OnePG_VmkForVmotion,
            },
            'vm' => {
              '[1]' => One_vnic_e1000_on_host1_on_dvpg1_shared,
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => One_vnic_e1000_on_host2_on_dvpg2,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['NetAdapter_3'],
              ['EnableVMotion1'],
              ['EnableVMotion2'],
              ['CreateSession'],
              ['NetperfTraffic1'],
              [
               'NetperfTraffic1',
               'vmotion',
               'NetperfTraffic2'
              ],
              [
               'NetperfTraffic1',
               'vmotion',
               'NetperfTraffic2'
              ],
              [
               'NetperfTraffic1',
               'vmotion',
               'NetperfTraffic2'
              ],
              ['NetperfTraffic1']
            ],
            'ExitSequence' => [
              ['NetAdapter_Back1'],
              ['NetAdapter_Back2']
            ],
            'Duration' => 'time in seconds',
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => '176.10.1.23'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => '176.10.1.21'
            },
            'NetAdapter_3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => '176.10.1.22'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'erspanip'  => ['vm.[3].vnic.[1]->IPv4'],
                 'sessiontype' => 'encapsulatedRemoteMirrorSource',
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'toolname' => 'iperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'sleepbetweenworkloads' => '300',
              'staytime' => '300'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'toolname' => 'iperf',
              'testduration' => '180',
              'testadapter' => 'vm.[2].vnic.[1]',
              'PortNumber' => '45000',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'sleepbetweenworkloads' => '450',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_Back2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1-2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '100+',
                'pktcapfilter' => 'count 999,src host 176.10.1.21,dst host 176.10.1.23',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '100+',
                'pktcapfilter' => 'count 999,src host 176.10.1.22,dst host 176.10.1.23',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestination-VlanToPort' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestination-VlanToPort',
          'Summary' => 'Verify the function of RSPAN destination',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSS_OnePG_Pswitch,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => One_vnic_e1000_on_host2_on_pg1,
              '[1]' => {
                'vnic' => {
                  '[1-2]' => Vnic_e1000_on_dvpg1,
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['RSPANSource'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'source',
              'rspansession' => '4'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANSource-MultipleSourceMultipleDestination' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANSource-MultipleSourceMultipleDestination',
          'Summary' => 'Verify the function of RSPAN souce with multiple source' .
                       ' and multiple destination',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_TwoVDS_TwoDVPG,
            'host' => {
              '[1-2]' => HostConfig_ThreeVmnic_VSSnoUplink_OnePG_Pswitch,
            },
            'vm' => {
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => {
                'vnic' => {
                  '[1-2]' => Vnic_e1000_on_dvpg1,
                },
                'host' => 'host.[2]'
              },
              '[1]' => {
                'vnic' => {
                  '[1-2]' => Vnic_e1000_on_dvpg1,
                },
                'host' => 'host.[1]'
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateDVPG_A'],
              ['ChangePortgroup1'],
              ['CreateDVPG_B'],
              ['ChangePortgroup2'],
              ['AddUplinks'],
              ['EnablePromiscuous_A'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['RSPANDestination1'],
              ['RSPANDestination2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN1'],
              ['RemoveRSPAN2']
            ],
            'Duration' => 'time in seconds',
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => 5,
                  'name' => 'dvpg_a',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[4]' => {
                  'ports' => 5,
                  'name' => 'promiscuous_a',
                  'vds' => 'vc.[1].vds.[2]'
                }
              }
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2],vm.[3].vnic.[2]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[3];;host.[2].vmnic.[3]'
            },
            'EnablePromiscuous_A' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'setpromiscuous' => 'enable',
              'portgroup' => 'vc.[1].dvportgroup.[4]',
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink','host.[1].vmnic.[3]->uplink'],
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'dstuplink'  => ['host.[2].vmnic.[1]->uplink','host.[2].vmnic.[3]->uplink'],
                 'mirrorlength' => '128',
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
                 'srcrxport'  => ['vm.[3].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[3].vnic.[1]->dvport'],
              },
            },
            'RSPANDestination1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'RSPANDestination2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
              'rspan' => 'destination',
              'rspansession' => '5'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveRSPAN1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'RemoveRSPAN2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '5'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[2]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANSource-PreserveOrigVlan' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANSource-PreserveOrigVlan',
          'Summary' => 'Test the  RSPAN source type with keep oringinal vlan ' .
                       'functional,test Null VLAN,VGT, VST, and types of PVLAN',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSS_OnePG_Pswitch,
              '[1]' => HostConfig_OneVmnic,
            },
            'vm' => {
              '[1-3]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[4]'   => One_vnic_e1000_on_host2_on_pg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['CreateSession1'],
              ['NetAdapter_Back'],
              ['NetperfTraffic12'],
              ['SetVLAN'],
              ['setvlan4095'],
              ['NetperfTraffic13'],
              ['SetVLANTrunk'],
              ['SetGuestVLAN'],
              ['NetperfTraffic22'],
              ['RemoveGuestVLAN1'],
              ['RemoveGuestVLAN2'],
              ['CreateDVPG1'],
              ['AddPort1'],
              ['CreateDVPG2'],
              ['AddPort2'],
              ['CreateDVPG3'],
              ['AddPort3'],
              ['AddPVLAN_Promiscuos'],
              ['AddPVLAN_Isolated'],
              ['AddPVLAN_Community'],
              ['SetPVLAN_Promiscuous'],
              ['SetPVLAN_Isolated'],
              ['SetPVLAN_Community'],
              ['ChangePortgroup11'],
              ['ChangePortgroup12'],
              ['ChangePortgroup13'],
              ['RemoveSession1'],
              ['CreateSession1'],
              ['NetperfTraffic32'],
              ['ChangePortgroup21'],
              ['ChangePortgroup22'],
              ['ChangePortgroup23'],
              ['RemoveSession1'],
              ['CreateSession1'],
              ['NetperfTraffic42'],
              ['ChangePortgroup31'],
              ['ChangePortgroup32'],
              ['ChangePortgroup33'],
              ['RemoveSession1'],
              ['CreateSession1'],
              ['NetperfTraffic52']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN'],
            ],
            'Duration' => 'time in seconds',
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'mirrorlength' => '1500',
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'stripvlan' => 'false',
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'ipv4' => 'auto',
              'vlan' => '0'
            },
            'NetperfTraffic12' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetVLAN' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
            },
            'setvlan4095' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'host.[2].portgroup.[1]',
              'vlantype' => 'access',
              'vlan' => '4095'
            },
            'NetperfTraffic13' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'NetperfTraffic22' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
              'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]',
            },
            'SetVLANTrunk' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'trunk',
              'vlan' => '[0-4094]'
            },
            'SetGuestVLAN' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'vlaninterface' => {
                          '[1]' => {
                              vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                          },
                      },
            },
            'RemoveGuestVLAN1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]',
            },
            'RemoveGuestVLAN2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]',
            },
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_170_170',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '2'
            },
            'CreateDVPG2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'dvpg_i_170_171',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '2'
            },
            'CreateDVPG3' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[4]' => {
                  'ports' => undef,
                  'name' => 'dvpg_c_170_173',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPort3' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'addporttodvportgroup' => '2'
            },
            'AddPVLAN_Promiscuos' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'promiscuous'
            },
            'AddPVLAN_Isolated' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'isolated'
            },
            'AddPVLAN_Community' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'community'
            },
            'SetPVLAN_Promiscuous' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
            },
            'SetPVLAN_Isolated' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
            },
            'SetPVLAN_Community' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
            },
            'ChangePortgroup11' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup12' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup13' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'RemoveSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'remove',
                 'name' => 'Session1',
                 'version' => 'v2',
              },
            },
            'NetperfTraffic32' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'ChangePortgroup21' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup22' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup23' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic42' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_4',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'ChangePortgroup31' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup32' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup33' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic52' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_5',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_4' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => "count 999,vlan " . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => "count 999,vlan " . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => "count 999,vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_5' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => "count 999,vlan " . VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-MirrorLoop' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-MirrorLoop',
          'Summary' => 'Verify the DVPort session with mirror loop the destination' .
                       ' port of one mirror session is source port of another ' .
                       'mirror session',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM,
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[2].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[2].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestination-MultipleSourceMulitpleDestinaiton' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestination-MultipleSourceMulitpleDestinaiton',
          'Summary' => 'Verify the function of RSPAN destination with multiple ' .
                       'source and multiple destionation',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG,
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  },
                },
                'vss' => {
                  '[1-2]' => {
                    'configureuplinks' => 'add',
                    'vmnicadapter' => 'host.[2].vmnic.[x]'
                  }
                },
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[2].vss.[x]'
                  },
                },
                'pswitchport' => {
                  '[1-2]' => {
                    'vmnic' => 'host.[2].vmnic.[x]'
                  },
                },
              },
              '[1]' => HostConfig_OneVmnic,
            },
            'vm' => {
              '[1]' => Two_vnic_e1000_on_host1_on_dvpg1,
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => One_vnic_e1000_on_host2_on_pg1,
              '[4]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[2]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['ConfigurePortGroup1'],
              ['ChangePortgroup_1'],
              ['CreateSession1'],
              ['CreateSession2'],
              ['RSPANSource1'],
              ['RSPANSource2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['NetperfTraffic3'],
              ['NetperfTraffic4']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN1'],
              ['RemoveRSPAN2']
            ],
            'Duration' => 'time in seconds',
            'ConfigurePortGroup1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'portgroup' => {
                '[3]' => {
                  'name' => 'rspansource2',
                  'vss' => 'host.[2].vss.[2]'
                }
              }
            },
            'ChangePortgroup_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[3]'
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '1024',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport','vm.[1].vnic.[2]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport','vm.[1].vnic.[2]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'source',
              'rspansession' => '4'
            },
            'RSPANSource2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[2]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
              'rspan' => 'source',
              'rspansession' => '5'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2-4].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[4].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic4' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_4',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[4].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveRSPAN1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'RemoveRSPAN2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '5'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_4' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-Vmotion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-Vmotion',
          'Summary' => 'Verify the vmotion with DVPort session',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[1-2]' => HostConfig_TwoVmnic_VSS_OnePG_VmkForVmotion,
            },
            'vm' => {
              '[1]' => One_vnic_e1000_on_host1_on_dvpg1_shared,
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => One_vnic_e1000_on_host2_on_dvpg2,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['EnableVMotion1'],
              ['EnableVMotion2'],
              ['CreateSession'],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['NetAdapter_Back1']
            ],
            'Duration' => 'time in seconds',
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '1500',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'testduration' => '240',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'staytime' => '60',
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'testduration' => '240',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1-2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '100+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '240-',
                'pktcapfilter' => 'count 300',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestinationRSPANSource' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestinationRSPANSource',
          'Summary' => 'Verify the function of RSAPN source and destination',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]' => {
                'vnic' => {
                  '[1-2]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['CreateSession2'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[3].vnic.[1]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[2]',
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'ConfigurationPersistence' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'ConfigurationPersistence',
          'Summary' => 'Verify the port mirror session Configuration Persistence',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_HasHost1Alone_ThreeDVPG,
            'host' => {
              '[1]' => HostConfig_OneVmnic_TwoVmknic_onDVPG2_3,
              '[2]' => HostConfig_ThreeVmnic_ThreeVSS_ThreePG_ThreePswitchPort,
            },
            'vm' => {
              '[1]' => Two_vnic_e1000_on_host1_on_dvpg1,
              '[2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3-5]' => One_vnic_e1000_on_host2_on_pg1,
              '[6]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[2].portgroup.[3]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2]'
              },
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['ConfigurePortGroup1'],
              ['ChangePortgroup_1'],
              ['ConfigurePortGroup2'],
              ['ChangePortgroup_2'],
              ['ConfigurePortGroup3'],
              ['ChangePortgroup_3'],
              ['NetAdapter_Back'],
              ['CreateSession1'],
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['CreateSession2'],
              ['NetperfTraffic3'],
              ['CreateSession3'],
              ['RSPANSource'],
              ['NetperfTraffic4'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['CreateSession4'],
              ['NetperfTraffic5'],
              ['PowerOffSUT'],
              ['PowerOffhelper1'],
              ['RebootHost1'],
              ['PowerOnSUT'],
              ['PowerOnhelper1'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['NetperfTraffic3'],
              ['NetperfTraffic4'],
              ['NetperfTraffic5']
            ],
            'ExitSequence' => [
              ['RemoveRSPANDestination'],
              ['RemoveRSPANSource'],
              ['NetAdapter_Back1'],
              ['NetAdapter_Back2']
            ],
            'Duration' => 'time in seconds',
            'ConfigurePortGroup1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'portgroup' => {
                '[5]' => {
                  'name' => 'rspansource',
                  'vss' => 'host.[2].vss.[2]'
                }
              }
            },
            'ChangePortgroup_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[5]'
            },
            'ConfigurePortGroup2' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'portgroup' => {
                '[6]' => {
                  'name' => 'rspandestination',
                  'vss' => 'host.[2].vss.[3]'
                }
              }
            },
            'ChangePortgroup_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[6].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[6]'
            },
            'ConfigurePortGroup3' => {
              'Type' => 'Host',
              'TestHost' => 'host.[2]',
              'portgroup' => {
                '[7]' => {
                  'name' => 'erspandestination',
                  'vss' => 'host.[2].vss.[1]'
                }
              }
            },
            'ChangePortgroup_3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[2].portgroup.[7]'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]',
              'ipv4' => 'auto'
            },
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'mirrorlength' => '1000',
                 'sessiontype' => 'remoteMirrorSource',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','host.[1].vmknic.[1]->dvport'],
              },
            },
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[3]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[3]',
              'setpromiscuous' => 'Enable'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'host.[1].vmknic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'mirrorlength' => '1000',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'CreateSession3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session3',
                 'mirrorlength' => '1500',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[2]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[2]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_B,
              'rspan' => 'source',
              'rspansession' => '5'
            },
            'NetperfTraffic4' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_4',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[4].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'ipv4' => '176.10.1.12'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[2]',
              'ipv4' => '176.10.1.13'
            },
            'CreateSession4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session4',
                 'erspanip'  => ['vm.[5].vnic.[1]->IPv4'],
                 'mirrorlength' => '1500',
                 'sessiontype' => 'encapsulatedRemoteMirrorSource',
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'version' => 'v2',
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
              },
            },
            'NetperfTraffic5' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_5',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '180',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'PowerOffSUT' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'vmstate' => 'poweroff'
            },
            'PowerOffhelper1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2].x.[x]',
              'vmstate' => 'poweroff'
            },
            'RebootHost1' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'reboot' => 'yes'
            },
            'PowerOnSUT' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'vmstate' => 'poweron'
            },
            'PowerOnhelper1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2].x.[x]',
              'vmstate' => 'poweron'
            },
            'RemoveRSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'RemoveRSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '5'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_Back2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[2]',
              'ipv4' => 'auto'
            },
            'Verification_4' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[2]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[6].vnic.[1]',
                'truncatedpkt' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_5' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'pktcount' => '100+',
                'pktcapfilter' => 'count 999,src host 176.10.1.13,dst host 176.10.1.12',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'VDSUpgrade' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'VDSUpgrade',
          'Summary' => 'Verify the Port Mirror functional with upgrade vds ' .
                       'from last_supported_version to current_version',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
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
                    'ports' => 6,
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[1]',
                    'version' => VDNetLib::TestData::TestConstants::VDS_LAST_SUPPORTED_VERSION,
                    'configurehosts' => 'add',
                    'host' => 'host.[1]'
                  }
                }
              }
            },
            'host' => {
              '[2]' => HostConfig_OneVmnic_VSS_OnePG_Pswitch,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-4]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[5]'   => One_vnic_e1000_on_host2_on_pg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['CreateSession2'],
              ['RSPANDestination'],
              ['EnablePromiscuous'],
              ['NetperfTraffic2'],
              ['UpgradeVDS'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['UpgradeVDS2'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
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
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3-4].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '10',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'CreateSession2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session2',
                 'encapvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'dstuplink'  => ['host.[1].vmnic.[1]->uplink'],
                 'srcrxport'  => ['vm.[3].vnic.[1]->dvport'],
                 'normaltraffic' => 'true',
                 'srctxport'  => ['vm.[3].vnic.[1]->dvport'],
              },
            },
            'RSPANDestination' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'destination',
              'rspansession' => '4'
            },
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'iperf',
              'testduration' => '10',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'UpgradeVDS' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_LAST_RELEASED_VERSION,
            },
            'UpgradeVDS2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[5].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-SamplingRate' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-SamplingRate',
          'Summary' => 'Verify the function of sampling rate with port mirror',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1-2]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-2]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[3]'   => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession1'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2'],
              ['EditSession1'],
              ['NetperfTraffic3']
            ],
            'Duration' => 'time in seconds',
            'CreateSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[2].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'toolname' => 'ping',
              'testduration' => '100',
              'pingpktsize' => '1600',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EditSession1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'edit',
                 'name' => 'Session1',
                 'samplingrate' => '8',
                 'version' => 'v2',
                 'sessiontype' => 'dvPortMirror',
              },
            },
            'NetperfTraffic3' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_3',
              'toolname' => 'ping',
              'testduration' => '200',
              'pingpktsize' => '1600',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Verification_3' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '20-30',
                'pktcapfilter' => 'count 400',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '90+',
                'pktcapfilter' => 'count 200',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[2].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestination-Vmotion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestination-Vmotion',
          'Summary' => 'Verify the function of RSPAN destinaiton session with' .
                       ' vmotion',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_TwoDVPG,
            'host' => {
              '[2]' => HostConfig_TwoVmnic_VSS_Vmk_OnePG_Pswitch,
              '[1]' => HostConfig_TwoVmnic_VSS_OnePG_VmkForVmotion,
            },
            'vm' => {
              '[1]' => One_vnic_e1000_on_host1_on_dvpg1_shared,
              '[2]' => One_vnic_e1000_on_host2_on_pg1,
              '[3]' => One_vnic_e1000_on_host2_on_dvpg2,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['AddUplinkonHelper1'],
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetAdapter_2'],
              ['EnableVMotion1'],
              ['EnableVMotion2'],
              ['CreateSession'],
              ['RSPANSource'],
              ['NetperfTraffic2'],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              [
               'NetperfTraffic1',
               'vmotion'
              ],
              ['NetperfTraffic2']
            ],
            'ExitSequence' => [
              ['RemoveRSPAN'],
              ['NetAdapter_Back1']
            ],
            'Duration' => 'time in seconds',
            'AddUplinkonHelper1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[2].vss.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE'
            },
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'source',
              'rspansession' => '4'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'toolname' => 'ping',
              'testduration' => '240',
              'pingpktsize' => '300',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2]',
              'staytime' => '30'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'NetAdapter_Back1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1-2].vmknic.[1]',
              'ipv4' => 'auto'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '40+',
                'pktcapfilter' => 'count 399',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'RSPANDestination-TSOLRO' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'RSPANDestination-TSOLRO',
          'Summary' => 'Verify the RSPANDestination session with TSO and LRO',
          'ExpectedResult' => 'PASS',
          'Tags' => 'physicalonly',
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic_OnePswitchPort,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-2]' => One_vnic_vmxnet3_on_host1_on_dvpg1,
              '[3]'   => One_vnic_vmxnet3_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['RSPANSource'],
              ['SetMTU1'],
              ['NetAdapter_Back'],
              ['NetAdapter_1'],
              ['NetperfTraffic1'],
              ['NetAdapter_0'],
              ['NetAdapter_1'],
              ['NetAdapter_3'],
              ['NetperfTraffic1'],
              ['NetAdapter_2'],
              ['NetAdapter_1'],
              ['NetperfTraffic1'],
              ['NetAdapter_0'],
              ['NetAdapter_4'],
              ['NetperfTraffic1'],
              ['NetAdapter_2'],
              ['NetAdapter_1'],
              ['NetperfTraffic1']
            ],
            'ExitSequence' => [
              ['SetVMMTU2'],
              ['SetMTU2'],
              ['RemoveRSPAN']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'mirrorlength' => '5000',
                 'sessiontype' => 'remoteMirrorDest',
                 'dstport'  => ['vm.[1].vnic.[1]->dvport'],
                 'srcvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
                 'normaltraffic' => 'true',
                 'version' => 'v2',
              },
            },
            'RSPANSource' => {
              'Type' => 'Port',
              'TestPort' => 'host.[2].pswitchport.[1]',
              'rspanvlan' => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
              'rspan' => 'source',
              'rspansession' => '4'
            },
            'SetMTU1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2-3].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetAdapter_1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'mtu' => '9000'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[3].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetAdapter_0' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'lro',
                 'enable'       => 'true',
              }
            },
            'NetAdapter_3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'true',
              },
              'mtu' => '9000'
            },
            'NetAdapter_2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'lro',
                 'enable'       => 'false',
              }
            },
            'NetAdapter_4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'configure_offload' =>{
                 'offload_type' => 'tsoipv4',
                 'enable'       => 'false',
              },
              'mtu' => '9000'
            },
            'SetVMMTU2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'mtu' => '1500'
            },
            'SetMTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'RemoveRSPAN' => {
              'Type' => 'Port',
              'TestPort' => 'host.[-1].pswitchport.[-1]',
              'rspan' => 'remove',
              'rspansession' => '4'
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[1].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVPortSession-MultipleSourceMultipleDestination' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVPortSession-MultipleSourceMultipleDestination',
          'Summary' => 'Verify the function of DVPort session with multiple ' .
                       'source and multiple destination',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'Version' => '2',
          'AutomationStatus' => 'Automated',
          'TestbedSpec' => {
            'vc' => OneDC_TwoHost_OneVDS_OneDVPG,
            'host' => {
              '[2]' => HostConfig_OneVmnic,
              '[1]' => HostConfig_OneVmnic_VSSnoUplink_OnePG,
            },
            'vm' => {
              '[1-4]' => One_vnic_e1000_on_host1_on_dvpg1,
              '[5]'   => One_vnic_e1000_on_host2_on_dvpg1,
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              ['CreateSession'],
              ['NetAdapter_Back'],
              ['NetperfTraffic1'],
              ['NetperfTraffic2']
            ],
            'Duration' => 'time in seconds',
            'CreateSession' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mirrorsession' => {
                 'operation' => 'add',
                 'name' => 'Session1',
                 'sessiontype' => 'dvPortMirror',
                 'dstport'  => ['vm.[3].vnic.[1]->dvport','vm.[4].vnic.[1]->dvport'],
                 'srcrxport'  => ['vm.[1].vnic.[1]->dvport','vm.[2].vnic.[1]->dvport'],
                 'srctxport'  => ['vm.[1].vnic.[1]->dvport','vm.[2].vnic.[1]->dvport'],
                 'version' => 'v2',
              },
            },
            'NetAdapter_Back' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1],vm.[5].vnic.[1]',
              'ipv4' => 'auto',
              'ipv6' => 'add',
              'ipv6addr' => 'default'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[5].vnic.[1]'
            },
            'NetperfTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'verification' => 'Verification_2',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[5].vnic.[1]'
            },
            'Verification_2' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[4].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            },
            'Verification_1' => {
              'PktCapVerificaton' => {
                'target' => 'vm.[3].vnic.[1]',
                'pktcount' => '800+',
                'pktcapfilter' => 'count 999',
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
#       This is the constructor for PortMirror.
#
# Input:
#       None.
#
# Results:
#       An instance/object of PortMirror class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   my $class     = shift;
   my %options = @_;

   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class

   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%PortMirror);

   $self->{'testSession'} = $options{"testSession"};
   return (bless($self, $class));
}


#######################################################################
#
# Setup --
#       Do pre-configuration for PortMirror;
#
# Input:
#       None.
#
# Results:
#       SUCCESS always;
#
# Side effects:
#       None.
#
########################################################################

sub Setup
{
   my $self    = shift;
   my $logger  = $self->{'testSession'}->{'logger'};

   if (FAILURE eq $self->SUPER::Setup(@_)) {
      $logger->Error("Failed to initialize using parent method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ( ( ! $testSession->{"dontUpgSTAFSDK"} ) &&
        ($ENV{CLASSPATH} !~ "commons-cli-1.2.jar" ||
         $ENV{CLASSPATH} !~ "vspancfgtool.jar") ) {

      $logger->Info("Append commons-cli-1.2.jar and vspancfgtool.jar to" .
                    "CLASSPATH for PortMirror Java tools");

      my $globalConfig = VDNetLib::Common::GlobalConfig->new();
      my $vdNetRootPath = $globalConfig->GetVdNetRootPath();
      my $myLibPath = "$vdNetRootPath/bin/PortMirror_jar/vspanCfgTool/lib";
      my $libClassPath = "$myLibPath/commons-cli-1.2.jar:".
                         "$myLibPath/vspancfgtool.jar";
      $ENV{CLASSPATH} = $libClassPath . ":" . $ENV{CLASSPATH};
   }

   return SUCCESS;
}


#######################################################################
#
# Cleanup --
#       Clean settings changed in Setup.
#
# Input:
#       None.
#
# Results:
#       SUCCESS always;
#
# Side effects:
#       None.
#
########################################################################

sub Cleanup
{
   my $self = shift;
   my $logger  = $self->{'testSession'}->{'logger'};

   if ( FAILURE eq $self->SUPER::Cleanup(@_) ) {
      $logger->Error("Failed to initialize using parent method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}

1;

