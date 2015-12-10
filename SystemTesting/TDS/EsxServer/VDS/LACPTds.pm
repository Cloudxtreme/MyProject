########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::LACPTds;


use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{

   %LACP = (
      ModulesOnBoot => {
        Product => 'ESX',
        Category => 'Networking',
        Component => 'Teaming/LACP',
        TestName => 'ModulesOnBoot',
        Summary => 'Test if lacp modles are loaded',
        ExpectedResult => 'PASS',
        Tags => undef,
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::ModulesOnBoot',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'host' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  [ 'CheckLACPModules' ],
                                  [ 'CheckLACPDaemon' ],
                                  [ 'LoadAlreadyLoadedModule' ],
                                  [ 'EsxcliModuleList' ],
                                  [ 'EsxcliModuleGet' ],
                                ],
          CheckLACPModules => {
            Type => 'Command',
            command => 'ps | grep -ri lacp',
            expectedstring => 'net-lacp',
            testhost => 'host.[1]',
          },
          CheckLACPDaemon => {
            Type => 'Command',
            command => 'ps -c |grep -ri lacp',
            expectedstring => 'watchdog',
            testhost => 'host.[1]',
          },
          LoadAlreadyLoadedModule => {
            Type => 'Command',
            command => 'esxcli system module load -m lacp',
            expectedstring => 'Unable to load module /usr/lib/vmware/vmkmod/lacp: Busy',
            testhost => 'host.[1]',
          },
          EsxcliModuleList => {
            Type => 'Command',
            command => 'esxcli system module list | grep -ri lacp',
            expectedresult => 'FAIL',
            expectedstring => 'false',
            testhost => 'host.[1]',
          },
          EsxcliModuleGet => {
            Type => 'Command',
            command => 'esxcli system module get -m lacp ',
            expectedstring => 'Module File: /usr/lib/vmware/vmkmod/lacp',
            testhost => 'host.[1]',
          },
        },
      },

     'BasicEnableDisable' => {
         Product           => 'ESX',
	 Category          => 'Networking',
	 Component         => 'Teaming/LACP',
         TestName          => "BasicEnableDisable",
         Summary           => "Test basic enable disable lacp," .
                              " with uplinks",
         AutomationLevel   => 'Automated',
         ExpectedResult    => "PASS",
         Tags    => 'physicalonly',
         Version => "2",
         testID  => "TDS::EsxServer::VDS::LACP::BasicEnableDisable",

         TestbedSpec => {
           vc => {
             '[1]' => {
               datacenter => {
                 '[1]' => {
                   host => "host.[1]",
                 },
               },
               vds => {
                 '[1]' => {
                   datacenter => "vc.[1].datacenter.[1]",
                   vmnicadapter => "host.[1].vmnic.[1-3]",
                   configurehosts => "add",
                   host => "host.[1]",
                   version => "5.1.0",
                 },
               },
             },
           },
           host => {
             '[1]' => {
               vmnic => {
                 '[1-3]' => {
                   driver => "any",
                 },
               },
               pswitchport => {
                 '[1]'     => {
                      vmnic => "host.[1].vmnic.[1]",
                 },
                 '[2]'     => {
                      vmnic => "host.[1].vmnic.[2]",
                 },
                 '[3]'     => {
                      vmnic => "host.[1].vmnic.[3]",
                 },
               },
             },
           },
           pswitch => {
             '[1]' => {
               ip => "XX.XX.XX.XX",
             },
           },
         },

         WORKLOADS => {
            Sequence => [
                         ['EnableLACP'],
                         ['ConfigureChannelGroup'],
                         ['CheckUplinkState_Enable'],
                         ['DisableLACP'],
                         ['CheckUplinkState_Disable'],
                        ],
            ExitSequence => [
                                ['RemovePortsFromChannelGroup'],
                                ['DeleteChannelGroup'],
                              ],
            EnableLACP  => {
                Type           => "Switch",
                TestSwitch     => "vc.[1].vds.[1]",
                lacp           => "Enable",
                lacpmode       => "Active",
                host           => "host.[1]",
            },
            DisableLACP => {
                Type           => "Switch",
                TestSwitch     => "vc.[1].vds.[1]",
                lacp           => "Disable",
                host           => "host.[1]",
            },
            ConfigureChannelGroup => {
                Type            => "Port",
                TestPort        => "host.[1].pswitchport.[-1]",
                configurechannelgroup =>
                       VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
                Mode            => "Active",
            },
            CheckUplinkState_Enable => {
                sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
                Type            => "Command",
                TestHost        => "host.[1]",
                Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
                expectedString  => "3",
            },
            CheckUplinkState_Disable => {
                sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
                Type            => "Command",
                TestHost        => "host.[-1]",
                Command         => "esxcli network vswitch dvs vmware lacp config get",
                expectedString  => "LACP is disabled on DVSwitch",
            },
            RemovePortsFromChannelGroup => {
              Type => 'Port',
              TestPort => 'host.[1].pswitchport.[-1]',
              configurechannelgroup => 'no',
            },
            DeleteChannelGroup => {
              Type => 'Switch',
              TestSwitch => 'pswitch.[-1]',
              removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
          },
        },

      vmknicInDVPG => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'vmknicInDVPG',
        Summary => 'Test lacp with a vmknic present in dvPG',
        AutomationLevel => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::vmknicInDVPG',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]'
                }
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '2',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
              'pswitchport' => {
                '[1]'     => {
                     vmnic => "host.[1].vmnic.[1]",
                },
                '[2]'     => {
                     vmnic => "host.[1].vmnic.[2]",
                },
              },
            },
          },
          pswitch => {
            '[1]' => {
            },
          },
        },

        WORKLOADS => {
          Sequence => [
                                  ['ConfigIPHashTeaming1'],
                                  ['EnableLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigIPHashTeaming2'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigIPHashTeaming3'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigIPHashTeaming4'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigExplicitTeaming'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Error'],
                                  ['DisableLACP'],
                                  ['ConfigSrcMACTeaming'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Error'],
                                  ['ConfigStandbyNics'],
                                  ['DisableLACP'],
                                  # if no vmknic or vnic is present in dvPG
                                  # enabling lacp works on nonIPHash
                                  ['RemoveVMKNIC'],
                                  ['ConfigExplicitTeaming'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigSrcMACTeaming'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['ConfigStandbyNics'],
                                  ['EnableLACP'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                 ],
          ExitSequence => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                 ],
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          DisableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable',
            host => 'host.[1]'
          },
          ConfigIPHashTeaming1 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigIPHashTeaming2 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'no',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigIPHashTeaming3 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'no',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigIPHashTeaming4 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'no',
            lbpolicy => 'iphash',
            notifyswitch => 'no',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigExplicitTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'explicit',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigSrcMACTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'mac',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigStandbyNics => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            standbynics => 'host.[1].vmnic.[-1]',
            lbpolicy => 'iphash',
            failover => 'beaconprobing',
            confignicteaming => 'vc.[1].dvportgroup.[1]',
            notifyswitch => 'yes'
          },
          RemoveVMKNIC => {
            Type => 'Host',
            TestHost => 'host.[1]',
            deletevmknic => 'host.[1].vmknic.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkState_Enable => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          CheckLACPUplinkState_Error => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get ",
             expectedString  => "No running LACP group on the host",
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no',
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      TrafficAddRemoveUplinks => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'TrafficAddRemoveUplinks',
        Summary => 'Test traffic distribution across multiple uplinks joining leaving',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::TrafficAddRemoveUplinks',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]',
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '4',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-3]' => {
                  'driver' => 'any',
                },
              },
              'pswitchport' => {
                '[1-3]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any',
                },
              },
            },
          },
          'vm' => {
            '[1-2]' => {
              'vnic' => {
                '[1-2]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'driver' => 'vmxnet3',
                },
              },
              'host' => 'host.[x]',
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['ConfigTeaming'],
                                  ['SourceIP_1'],
                                  ['SourceIP_2'],
                                  ['DestinationIP_1'],
                                  ['DestinationIP_2'],
                                  ['BeforeLACPTraffic'],
                                  # Add uplinks to VDS while traffic is flowing,
                                  # Order in which uplinks are added is important,
                                  ['BeforeLACPTraffic','AddUplink2'],
                                  ['BeforeLACPTraffic','AddUplink3'],
                                  ['ConfigureLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['Flow1'],
                                  ['Flow2'],
                                  ['Flow3'],
                                  ['AllFlows'],
                                  ['BeforeLACPTraffic','RemoveUplink3','RemoveUplink2'],
                                ],
          ExitSequence => [
                                  ['ResetIP'],
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                ],
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "3",
          },
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]',
          },
          SourceIP_1 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[1]',
            ipv4 => '192.168.111.1',
          },
          SourceIP_2 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[2]',
            ipv4 => '192.168.111.5',
          },
          DestinationIP_1 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[2].vnic.[1]',
            ipv4 => '192.168.111.2',
          },
          DestinationIP_2 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[2].vnic.[2]',
            ipv4 => '192.168.111.3',
          },
          BeforeLACPTraffic => {
            Type => 'Traffic',
            noofoutbound => 1,
            testduration => 60,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[-1]',
            supportadapter => 'vm.[2].vnic.[-1]',
          },
          AddUplink2 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[2]',
          },
          AddUplink3 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[3]',
          },
          ConfigureLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          Flow1 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_ActiveVmnics',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'vm.[2].vnic.[1]',
          },
          Flow2 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_ActiveVmnics',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'vm.[2].vnic.[2]',
          },
          Flow3 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_ActiveVmnics',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[2]',
            supportadapter => 'vm.[2].vnic.[1]',
          },
          AllFlows => {
            Type => 'Traffic',
            parallelsession => 'yes',
            noofoutbound => 1,
            verification => 'Verification_ActiveVmnics',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[-1]',
            supportadapter => 'vm.[2].vnic.[-1]',
          },
          Verification_ActiveVmnics => {
             ActiveVMNicVerificaton => {
               target => 'src',
               verificationtype => 'activeVMNic',
             },
          },
          RemoveUplink3 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'remove',
            vmnicadapter => 'host.[1].vmnic.[3]',
          },
          RemoveUplink2 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'remove',
            vmnicadapter => 'host.[1].vmnic.[2]',
          },
          ResetIP => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[-1].vnic.[-1]',
            ipv4 => 'AUTO',
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no',
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      VDSMTU => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'VDSMTU',
        Summary => 'Test lag formation after VDS MTU is reset',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::VDSMTU',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-3]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-3]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1-3]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  [ 'ConfigTeaming' ],
                                  [ 'ConfigureLACP' ],
                                  [ 'ConfigureActiveChannelGroup' ],
                                  [ 'CheckLACPUplinkState_Enable' ],
                                  [ 'SetVDSMTU9000' ],
                                  [ 'CheckLACPUplinkState_Enable' ],
                                  [ 'SetVDSMTU1500' ],
                                  [ 'CheckLACPUplinkState_Enable' ],
                                 ],
          ExitSequence => [
                                  [ 'RemovePortsFromChannelGroup' ],
                                  [ 'DeleteChannelGroup' ],
                                 ],
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigureLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkState_Enable => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "3",
          },
          SetVDSMTU9000 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            mtu => '9000'
          },
          SetVDSMTU1500 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            mtu => '1500'
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      BasicvNICLACPTraffic => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'BasicvNICLACPTraffic',
        Summary => 'Test traffic when vNIC is present in dvPG. Flip active passive mode ',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::BasicvNICLACPTraffic',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]',
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '3',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1-2].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
              'pswitchport' => {
                '[1-2]' => {
                  'vmnic' => 'host.[1].vmnic.[x]'
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
          },
          'vm' => {
            '[1]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'driver' => 'vmxnet3'
                },
              },
              'host' => 'host.[1]'
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['ConfigTeaming'],
                                  ['ConfigureLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['BasicTraffic'],
                                  ['LACPTraffic','FlipActivePassive'],
                                 ],
          ExitSequence => [
                                  [ 'RemovePortsFromChannelGroup' ],
                                  [ 'DeleteChannelGroup' ],
                            ],
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          ConfigureLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          BasicTraffic => {
            Type => 'Traffic',
            noofoutbound => 1,
            testduration => 10,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'host.[2].vmknic.[1]',
            Verification    => "Verification_withlacp",
          },
          LACPTraffic => {
             Type            => "Traffic",
             ToolName        => "netperf",
             L3Protocol      => "ipv4",
             L4Protocol      => "tcp",
             BurstType       => "stream",
             NoofOutbound    => "1",
             NoofInbound     => "1",
             TestAdapter     => "vm.[1].vnic.[1],host.[1].vmknic.[1]",
             SupportAdapter  => "host.[2].vmknic.[1]",
             TestDuration    => "30",
             Verification    => "Verification_withlacp",
          },
          Verification_withlacp => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "host.[2].vmknic.[1]",
                  pktcapfilter     => "count 5000",
                  pktcount         => "4900+",
               },
          },
          FlipActivePassive => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Passive,Active',
            iterations => 20,
            host => 'host.[1]'
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      vNICConnectDisconnect => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'vNICConnectDisconnect',
        Summary => 'Do a connect disconnect of vNIC and enable disable LACP',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::vNICConnectDisconnect',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]',
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '9',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any',
                },
              },
              'pswitchport' => {
                '[1-2]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any',
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
          },
          'vm' => {
            '[1]' => {
              'vnic' => {
                '[1-2]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'driver' => 'vmxnet3',
                },
              },
              'host' => 'host.[1]',
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['AddUplinks'],
                                  ['SetVMIP1n2'],
                                  ['SetvmknicIP'],
                                  ['ConfigTeaming'],
                                  ['EnableLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['LACPTraffic_1'],
                                  ['DisableLACP'],
                                  # Hot Add then enable lacp
                                  ['HotAddE1000'],
                                  ['SetVMIP3n4'],
                                  ['EnableLACP'],
                                  ['LACPTraffic_2'],
                                  # Hot Add on already enabled lacp
                                  ['HotAddVmxnet2'],
                                  ['SetVMIP5n6'],
                                  ['HotAddE1000AndVmxnet3'],
                                  ['SetVMIP7n8'],
                                  ['DisableLACP'],
                                  ['EnableLACP'],
                                  ['LACPTraffic_3'],
                                  ['EnableDisableLACPLoop','DisconnectConnectvNic'],
                                  ['EnableLACP'],
                                  ['LACPTraffic_1'],
                                ],
          ExitSequence => [
                                  ['HotRemoveExtraAdded'],
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                ],
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          AddUplinks => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[2]',
          },
          SetVMIP1n2 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[1-2]',
            ipv4 => 'Auto',
          },
          SetvmknicIP => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[2].vmknic.[1]',
            ipv4 => 'Auto',
          },
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]',
          },
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          LACPTraffic_1 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_withlacp',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[1-2]',
            supportadapter => 'host.[2].vmknic.[1]',
          },
          DisableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable',
            host => 'host.[1]',
          },
          HotAddE1000 => {
            Type => 'VM',
            TestVM => 'vm.[1]',
            vnic => {
              '[3-4]' => {
                portgroup => 'vc.[1].dvportgroup.[1]',
                driver => 'e1000',
              },
            },
          },
          SetVMIP3n4 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[3-4]',
            ipv4 => 'Auto',
          },
          LACPTraffic_2 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_withlacp',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[3-4]',
            supportadapter => 'host.[2].vmknic.[1]',
          },
          HotAddVmxnet2 => {
            Type => 'VM',
            TestVM => 'vm.[1]',
            vnic => {
              '[5-6]' => {
                portgroup => 'vc.[1].dvportgroup.[1]',
                driver => 'vmxnet2',
              },
            },
          },
          SetVMIP5n6 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[5-6]',
            ipv4 => 'Auto',
          },
          HotAddE1000AndVmxnet3 => {
            Type => 'VM',
            TestVM => 'vm.[1]',
            vnic => {
              '[7]' => {
                portgroup => 'vc.[1].dvportgroup.[1]',
                driver => 'vmxnet3',
              },
              '[8]' => {
                portgroup => 'vc.[1].dvportgroup.[1]',
                driver => 'e1000',
              },
            },
          },
          SetVMIP7n8 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[7-8]',
            ipv4 => 'Auto',
          },
          LACPTraffic_3 => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_withlacp',
            testduration => 30,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[5-8]',
            supportadapter => 'host.[2].vmknic.[1]',
          },
          Verification_withlacp => {
            ActiveVMNicVerificaton => {
              target => 'src',
              verificationtype => 'activeVMNic',
            },
          },
          DisconnectConnectvNic => {
            Type => 'NetAdapter',
            testadapter => 'vm.[1].vnic.[-1]',
            reconfigure => 'true',
            iterations => '4',
            connected => '0,1',
          },
          EnableDisableLACPLoop => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable,Enable',
            lacpmode => 'Active',
            iterations => '8',
            host => 'host.[1]',
          },
          HotRemoveExtraAdded => {
            Type => 'VM',
            TestVM => 'vm.[1]',
            deletevnic => 'vm.[1].vnic.[1-6]',
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no',
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      ActivePassiveModeStress => {
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Teaming/LACP',
         TestName         => 'ActivePassiveModeStress',
         Summary          => 'Uplinks should not leave LAG while stressing'.
                             ' active/passive 100 times',
         AutomationLevel   => 'Automated',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         Version          => '2',
         testID           => 'TDS::EsxServer::VDS::LACP::ActivePassiveModeStress',
         TestbedSpec => {
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => '5.1.0',
                     }
                  }
               }
            },
            'host' => {
               '[1]' => {
                  'vmnic' => {
                     '[1-2]' => {
                        'driver' => 'any'
                     }
                  },
                  'pswitchport' => {
                     '[1]' => {
                        'vmnic' => 'host.[1].vmnic.[1]'
                     },
                     '[2]' => {
                        'vmnic' => 'host.[1].vmnic.[2]'
                     }
                  }
               }
            },
            'pswitch' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                                    ['ConfigureActiveLACP'],
                                    ['ConfigureActiveChannelGroup'],
                                    ['CheckLACPUplinkState_Enable'],
                                    ['LACPStress'],
                                    ['CheckLACPUplinkState_Enable'],
                                   ],
            ExitSequence => [
                                    ['RemovePortsFromChannelGroup'],
                                    ['DeleteChannelGroup'],
                                   ],
            ConfigureActiveChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               mode => 'Active',
               configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
            ConfigureActiveLACP => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Enable',
               lacpmode => 'Active',
               host => 'host.[1]'
            },
            LACPStress => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Enable',
               lacpmode => 'Passive,Active',
               iterations => '100',
               host => 'host.[1]'
            },
            CheckLACPUplinkState_Enable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
               expectedString  => "2",
            },
            RemovePortsFromChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               configurechannelgroup => 'no'
            },
            DeleteChannelGroup => {
              Type => 'Switch',
              TestSwitch => 'pswitch.[-1]',
              removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
         },
      },

      EnableDisableStress => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'EnableDisableStress',
        Summary => 'We are able to form lag after stressing'.
                   ' enable disable 1000 times',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::EnableDisableStress',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                }
              }
            }
          },
          'pswitch' => {
            '[1]' => {
            },
          }
        },
        WORKLOADS => {
          Sequence => [
                         ['ConfigureActiveChannelGroup'],
                         ['LACPStress'],
                         ['ConfigureActiveLACP'],
                         ['CheckLACPUplinkState_Enable'],
                        ],
          ExitSequence => [
                         ['RemovePortsFromChannelGroup'],
                         ['DeleteChannelGroup'],
                        ],
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          ConfigureActiveLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          LACPStress => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable,Disable',
            lacpmode => 'Active',
            iterations => '500',
            host => 'host.[1]',
          },
          CheckLACPUplinkState_Enable => {
              # According to real expr, 5 seconds is not enough
              sleepbetweenworkloads => 10,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "2",
          },
          RemovePortsFromChannelGroup => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      UplinkJoinLeaveStress => {
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Teaming/LACP',
         TestName         => 'UplinkJoinLeaveStress',
         Summary          => 'We are able to form lag after stressing'.
                             ' uplink to join/leave 100 times',
         AutomationLevel   => 'Automated',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         Version          => '2',
         testID           => 'TDS::EsxServer::VDS::LACP::UplinkJoinLeaveStress',

         TestbedSpec => {
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[1-3]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => '5.1.0',
                     }
                  }
               }
            },
            'host' => {
               '[1]' => {
                  'vmnic' => {
                     '[1-3]' => {
                        'driver' => 'any'
                     }
                  },
                  'pswitchport' => {
                     '[1]' => {
                        'vmnic' => 'host.[1].vmnic.[1]'
                     },
                     '[2]' => {
                        'vmnic' => 'host.[1].vmnic.[2]'
                     },
                     '[3]' => {
                        'vmnic' => 'host.[1].vmnic.[3]'
                     }
                  }
               }
            },
            'pswitch' => {
               '[1]' => {
               },
            }
         },
         WORKLOADS => {
            Sequence => [
                                   ['ConfigureActiveLACP'],
                                   ['ConfigureActiveChannelGroup'],
                                   ['CheckLACPUplinkState_Enable'],
                                   ['UplinkStressOne'],
                                   ['CheckLACPUplinkState_Enable'],
                                   ['UplinkStressAll'],
                                   ['ConfigureActiveLACP'],
                                   ['CheckLACPUplinkState_Enable'],
                                  ],
            ExitSequence => [
                                   ['RemovePortsFromChannelGroup'],
                                   ['DeleteChannelGroup'],
                                  ],
            ConfigureActiveChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               mode => 'Active',
               configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
            ConfigureActiveLACP => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Enable',
               lacpmode => 'Active',
               host => 'host.[1]'
            },
            # Same aggregator id is maintained when at least one
            # uplinks is there in lag
            UplinkStressOne => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               configureuplinks => 'remove,add',
               maxtimeout => '45000',
               vmnicadapter => 'host.[1].vmnic.[1]',
               iterations => '100',
            },
            # A new aggregator id is created when all uplinks leave
            # and then join back again
            UplinkStressAll => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               configureuplinks => 'remove,add',
               maxtimeout => '75000',
               vmnicadapter => 'host.[1].vmnic.[1-3]',
               iterations => '50',
            },
            CheckLACPUplinkState_Enable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
               expectedString  => "3",
            },
            RemovePortsFromChannelGroup => {
              Type            => "Port",
              TestPort        => "host.[-1].pswitchport.[-1]",
              configurechannelgroup => "no",
            },
            DeleteChannelGroup => {
              Type => 'Switch',
              TestSwitch => 'pswitch.[-1]',
              removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
         },
      },

      TrafficUplinkFailures => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'TrafficUplinkFailures',
        Summary => 'Uplinks fail in a lag while the traffic is still going on',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::TrafficUplinkFailures',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]'
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '6',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-3]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-3]' => {
                  'driver' => 'any'
                },
              },
              'pswitchport' => {
                '[1-3]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
          },
          'vm' => {
            '[1-2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'driver' => 'vmxnet3'
                },
              },
              'host' => 'host.[x]',
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['SourceIP_1'],
                                  ['DestinationIP_1'],
                                  ['SourceIP_2'],
                                  ['DestinationIP_2'],
                                  ['AddHost2Uplinks'],
                                  ['ConfigTeaming'],
                                  ['ConfigureActiveLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['AllUplinksTraffic'],
                                  ['LACPTraffic_Vnic','LACPTraffic_Vmknic','UplinkStress12'],
                                  ['LACPTraffic_Vnic','LACPTraffic_Vmknic','UplinkStress23'],
                                  ['UplinkSpeedDuplexChange1'],
                                  ['UplinkSpeedDuplexChange2'],
                                  ['UplinkSpeedDuplexChange3'],
                                  ['UplinkSpeedDuplexChange4'],
                                  ['LACPTraffic_Vnic','LACPTraffic_Vmknic','UplinkAuto'],
                                  ['AllUplinksTraffic']
                              ],
          ExitSequence => [
                                  [ 'UplinkAuto' ],
                                  [ 'RemovePortsFromChannelGroup' ],
                                  [ 'DeleteChannelGroup' ]
                              ],
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "3",
          },
          SourceIP_1 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[1].vnic.[1]',
            ipv4 => '192.168.111.1'
          },
          DestinationIP_1 => {
            Type => 'NetAdapter',
            TestAdapter => 'vm.[2].vnic.[1]',
            ipv4 => '192.168.111.2'
          },
          SourceIP_2 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmknic.[1]',
            ipv4 => '192.168.111.5'
          },
          DestinationIP_2 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[2].vmknic.[1]',
            ipv4 => '192.168.111.3'
          },
          AddHost2Uplinks => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[2].vmnic.[1]',
          },
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigureActiveLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          AllUplinksTraffic => {
            Type => 'Traffic',
            noofoutbound => 1,
            #verification => 'Verification_allvmnics',
            toolname => 'netperf',
            testduration => 10,
            testadapter => 'vm.[1].vnic.[1],host.[1].vmknic.[1]',
            supportadapter => 'vm.[2].vnic.[1],host.[2].vmknic.[1]'
          },
          LACPTraffic_Vnic => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_vnic',
            toolname => 'netperf',
            testduration => 30,
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'vm.[2].vnic.[1],host.[2].vmknic.[1]'
          },
          LACPTraffic_Vmknic => {
            Type => 'Traffic',
            noofoutbound => 1,
            verification => 'Verification_vmknic',
            toolname => 'netperf',
            testduration => 30,
            testadapter => 'host.[1].vmknic.[1]',
            supportadapter => 'vm.[2].vnic.[1],host.[2].vmknic.[1]'
          },
          Verification_vnic => {
             PktCapVerificaton => {
                verificationtype => "pktcap",
                target           => "srcvm",
                pktcapfilter     => "count 9999",
                pktcount         => "9000+",
            },
          },
          Verification_vmknic => {
             PktCapVerificaton => {
                verificationtype => "pktcap",
                target           => "host.[1].vmknic.[1]",
                pktcapfilter     => "snaplen 256",
                pktcount         => "2800+",
            },
          },
          UplinkStress12 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'remove,add',
            vmnicadapter => 'host.[1].vmnic.[1-2]',
            iterations => '5'
          },
          UplinkStress23 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'remove,add',
            vmnicadapter => 'host.[1].vmnic.[2-3]',
            SleepBetweenCombos => '5',
            iterations => '20'
          },
          UplinkSpeedDuplexChange1 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1-2]',
            configure_link_properties => {
              speed => '10',
              duplex => 'half'
            }
          },
          UplinkSpeedDuplexChange2 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1-2]',
            configure_link_properties => {
              speed => '10',
              duplex => 'full'
            }
          },
          UplinkSpeedDuplexChange3 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1-2]',
            configure_link_properties => {
              speed => '100',
              duplex => 'half'
            }
          },
          UplinkSpeedDuplexChange4 => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1-2]',
            configure_link_properties => {
              speed => '100',
              duplex => 'full'
            }
          },
          UplinkAuto => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1-2]',
            configure_link_properties => {
              autoconfigure => 'true'
            }
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      MaxLAGLimit => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'MaxLAGLimit',
        Summary => 'Test max no. of vds in a datacenter and enabling lacp on all of them',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::MaxLAGLimit',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]'
                }
              },
              'vds' => {
                '[1-16]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[x]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-16]' => {
                  'driver' => 'any'
                },
              },
              'pswitchport' => {
                 '[1-16]' => {
                    'vmnic' => 'host.[1].vmnic.[x]',
                 },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['EnableLACP_All'],
                                  ['ConfigureChannelGroup1'],
                                  ['ConfigureChannelGroup2'],
                                  ['ConfigureChannelGroup3'],
                                  ['ConfigureChannelGroup4'],
                                  ['ConfigureChannelGroup5'],
                                  ['ConfigureChannelGroup6'],
                                  ['ConfigureChannelGroup7'],
                                  ['ConfigureChannelGroup8'],
                                  ['ConfigureChannelGroup9'],
                                  ['ConfigureChannelGroup10'],
                                  ['ConfigureChannelGroup11'],
                                  ['ConfigureChannelGroup12'],
                                  ['ConfigureChannelGroup13'],
                                  ['ConfigureChannelGroup14'],
                                  ['ConfigureChannelGroup15'],
                                  ['ConfigureChannelGroup16'],
                                  ['CheckLACPUplinkState_Enable'],
                                 ],
          ExitSequence      => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                 ],
          EnableLACP_All => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1-16]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          RemovePortsFromChannelGroup => {
             Type => 'Port',
             TestPort => 'host.[1].pswitchport.[-1]',
             configurechannelgroup => 'no'
          },
          ConfigureChannelGroup1=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[1]',
              configurechannelgroup => 21,
              Mode            => 'Active',
          },
          ConfigureChannelGroup2=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[2]',
              configurechannelgroup => 22,
              Mode            => 'Active',
          },
          ConfigureChannelGroup3=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[3]',
              configurechannelgroup => 23,
              Mode            => 'Active',
          },
          ConfigureChannelGroup4=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[4]',
              configurechannelgroup => 24,
              Mode            => 'Active',
          },
          ConfigureChannelGroup5=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[5]',
              configurechannelgroup => 25,
              Mode            => 'Active',
          },
          ConfigureChannelGroup6=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[6]',
              configurechannelgroup => 26,
              Mode            => 'Active',
          },
          ConfigureChannelGroup7=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[7]',
              configurechannelgroup => 27,
              Mode            => 'Active',
          },
          ConfigureChannelGroup8=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[8]',
              configurechannelgroup => 28,
              Mode            => 'Active',
          },
          ConfigureChannelGroup9=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[9]',
              configurechannelgroup => 29,
              Mode            => 'Active',
          },
          ConfigureChannelGroup10=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[10]',
              configurechannelgroup => 30,
              Mode            => 'Active',
          },
          ConfigureChannelGroup11=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[11]',
              configurechannelgroup => 31,
              Mode            => 'Active',
          },
          ConfigureChannelGroup12=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[12]',
              configurechannelgroup => 32,
              Mode            => 'Active',
          },
          ConfigureChannelGroup13=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[13]',
              configurechannelgroup => 33,
              Mode            => 'Active',
          },
          ConfigureChannelGroup14=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[14]',
              configurechannelgroup => 34,
              Mode            => 'Active',
          },
          ConfigureChannelGroup15=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[15]',
              configurechannelgroup => 35,
              Mode            => 'Active',
          },
          ConfigureChannelGroup16=> {
              Type            => 'Port',
              TestPort        => 'host.[1].pswitchport.[16]',
              configurechannelgroup => 36,
              Mode            => 'Active',
          },
          CheckLACPUplinkState_Enable => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "16",
          },
        },
      },

      TwoLAGSameSwitch => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'TwoLAGSameSwitch',
        Summary => 'Test 2 LACP groups behavior when pswitch in 1 or 2 channelgroups.',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::TwoLAGSameSwitch',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]'
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                   vmnicadapter => 'host.[1].vmnic.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
                '[2]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                   vmnicadapter => 'host.[1].vmnic.[2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                },
              },
              'pswitchport' => {
                 '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]'
                 },
                 '[2]' => {
                    'vmnic' => 'host.[1].vmnic.[2]'
                 },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['EnableLACP_All'],
                                  ['ConfigureVDS1_ChannelGroupA'],
                                  ['ConfigureVDS2_ChannelGroupA'],
                                  # When 2 VDS connect to 1 ChannelGroup,
                                  # Only one VDS can work normally.
                                  ['CheckLACPUplinkState_1Bundled'],
                                  ['RemovePortsFromChannelGroup'],
                                  ['ConfigureVDS1_ChannelGroupA'],
                                  ['ConfigureVDS2_ChannelGroupB'],
                                  ['CheckLACPUplinkState_2Bundled'],
                                 ],
          ExitSequence      => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroupA'],
                                  ['DeleteChannelGroupB'],
                                 ],
          EnableLACP_All => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1-2]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          ConfigureVDS1_ChannelGroupA => {
              Type            => "Port",
              TestPort        => "host.[1].pswitchport.[1]",
              configurechannelgroup => VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
              Mode            => "Active",
          },
          ConfigureVDS2_ChannelGroupA => {
              Type            => "Port",
              TestPort        => "host.[1].pswitchport.[2]",
              configurechannelgroup => VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
              Mode            => "Active",
          },
          ConfigureVDS2_ChannelGroupB => {
              Type            => "Port",
              TestPort        => "host.[1].pswitchport.[2]",
              configurechannelgroup => VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
              Mode            => "Active",
          },
          CheckLACPUplinkState_1Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "1",
          },
          CheckLACPUplinkState_2Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          RemovePortsFromChannelGroup => {
             Type => 'Port',
             TestPort => 'host.[1].pswitchport.[-1]',
             configurechannelgroup => 'no'
          },
          DeleteChannelGroupA => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
          },
          DeleteChannelGroupB => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
          },
        },
      },

      ActivePassiveCombinations => {
         Product          => 'ESX',
         Category         => 'Networking',
         Component        => 'Teaming/LACP',
         TestName         => 'ActivePassiveCombinations',
         Summary          => 'Test combinations of active passive'.
                             ' with peer pswitch',
         AutomationLevel   => 'Automated',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         Version          => '2',
         testID           => 'TDS::EsxServer::VDS::LACP::ActivePassiveCombinations',

         TestbedSpec => {
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[1-3]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => '5.1.0',
                     }
                  }
               }
            },
            'host' => {
               '[1]' => {
                  'vmnic' => {
                     '[1-3]' => {
                        'driver' => 'any'
                     }
                  },
                  'pswitchport' => {
                     '[1]' => {
                        'vmnic' => 'host.[1].vmnic.[1]'
                     },
                     '[2]' => {
                        'vmnic' => 'host.[1].vmnic.[2]'
                     },
                     '[3]' => {
                        'vmnic' => 'host.[1].vmnic.[3]'
                     }
                  }
               }
            },
            'pswitch' => {
               '[1]' => {
               },
            }
         },
         WORKLOADS => {
            Sequence => [
                                   # (VDS LACP - Pswitch LACP)
                                   # Active - Active
                                   ['ConfigureActiveLACP'],
                                   ['ConfigureActiveChannelGroup'],
                                   ['CheckLACPUplinkState_Enable'],
                                   ['DisableLACP'],
                                   # Passive - Active
                                   ['ConfigurePassiveLACP'],
                                   ['ConfigureActiveChannelGroup'],
                                   ['CheckLACPUplinkState_Enable'],
                                   ['DisableLACP'],
                                   # Active - Passive
                                   ['ConfigureActiveLACP'],
                                   ['ConfigurePassiveChannelGroup'],
                                   ['CheckLACPUplinkState_Enable'],
                                   ['DisableLACP'],
                                   ['RemovePortsFromChannelGroup'],
                                   # Passive - Passive
                                   ['ConfigurePassiveLACP'],
                                   ['ConfigurePassiveChannelGroup'],
                                   ['CheckLACPUplinkState_Standalone'],
                                   # Disable - Passive
                                   ['ConfigurePassiveChannelGroup'],
                                   ['DisableLACP'],
                                   ['CheckLACPUplinkState_Disable'],
                                   # Enable  - Remove Ports from ChannelGroup
                                   ['ConfigureActiveLACP'],
                                   ['ConfigureActiveChannelGroup'],
                                   ['CheckLACPUplinkState_Enable'],
                                  ],
            ExitSequence => [
                                   ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                  ],
            ConfigureActiveChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               mode => 'Active',
               configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
            ConfigureActiveLACP => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Enable',
               lacpmode => 'Active',
               host => 'host.[1]'
            },
            DisableLACP => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Disable',
               host => 'host.[1]'
            },
            ConfigurePassiveLACP => {
               Type => 'Switch',
               TestSwitch => 'vc.[1].vds.[1]',
               lacp => 'Enable',
               lacpmode => 'Passive',
               host => 'host.[1]'
            },
            ConfigurePassiveChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               mode => 'Passive',
               configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
            CheckLACPUplinkState_Enable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
               expectedString  => "3",
            },
            CheckLACPUplinkState_Disable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[-1]",
               Command         => "esxcli network vswitch dvs vmware lacp config get",
               expectedString  => "LACP is disabled on DVSwitch",
            },
            CheckLACPUplinkState_Standalone => {
               # With passive-passive combination, we need a longer waiting time.
               sleepbetweenworkloads => 10,
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get | grep Stand-alone | wc -l ",
               expectedString  => "3",
            },
            RemovePortsFromChannelGroup => {
               Type => 'Port',
               TestPort => 'host.[1].pswitchport.[-1]',
               configurechannelgroup => 'no'
            },
            DeleteChannelGroup => {
              Type => 'Switch',
              TestSwitch => 'pswitch.[-1]',
              removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
         },
      },

      NonLACPPswitch => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'NonLACPPswitch',
        Summary => 'Test lacp behavior when pswitch is in different nonLACP modes',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::NonLACPPswitch',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                }
              }
            }
          },
          'pswitch' => {
            '[1]' => {
            },
          }
        },
        WORKLOADS => {
          Sequence => [
                                  ['EnableLACP'],
                                  ['ConfigureNonLACPChannelGroup1'],
                                  # Per real experiment, the status is 'Stand-alone' for ESXi 6.0
                                  ['CheckLACPUplinkStatus_Standalone'],
                                  ['DisableLACP'],
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                  ['ConfigureNonLACPChannelGroup2'],
                                  ['EnableLACP'],
                                  # Per real experiment, the status is 'Stand-alone' for ESXi 6.0
                                  ['CheckLACPUplinkStatus_Standalone'],
                                  ['DisableLACP'],
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                  ['ConfigureNonLACPChannelGroup3'],
                                  ['EnableLACP'],
                                  # Per real experiment, the status is 'Stand-alone' for ESXi 6.0
                                  ['CheckLACPUplinkStatus_Standalone'],
                                  ['DisableLACP'],
                                 ],
          ExitSequence => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                 ],
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          DisableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable',
            host => 'host.[1]',
          },
          ConfigureNonLACPChannelGroup1 => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'on',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          ConfigureNonLACPChannelGroup2 => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'desirable',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          ConfigureNonLACPChannelGroup3 => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'auto',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkStatus_Standalone => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Stand-alone | wc -l ",
              expectedString  => "2",
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      RecreateVDS => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'RecreateVDS',
        Summary => 'Test basic enable disable lacp, when a VDS with same name is recreated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::RecreateVDS',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
                datacenter => {
                   '[1]' => {
                      host  => "host.[1]",
                   },
                },
                vds        => {
                   '[1]'   => {
                      datacenter => "vc.[1].datacenter.[1]",
                      name       => "vds-test",
                      configurehosts => "add",
                      vmnicadapter => "host.[1].vmnic.[1-2]",
                      host  => "host.[1]",
                      version => "5.1.0",
                   },
                },
             },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1-2]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          }
        },
        WORKLOADS => {
          Sequence => [
                         [ 'EnableLACP' ],
                         [ 'ConfigureActiveChannelGroup' ],
                         [ 'CheckLACPUplinkState_Enable' ],
                         [ 'RemoveVDS' ],
                         [ 'CheckLACPUplinkState_NoDVS' ],
                         [ 'CreateVDS' ],
                         [ 'EnableLACP' ],
                         [ 'ConfigureActiveChannelGroup' ],
                         [ 'CheckLACPUplinkState_Enable' ],
                        ],
          ExitSequence => [
                         [ 'RemovePortsFromChannelGroup' ],
                                  ['DeleteChannelGroup'],
                        ],
          EnableLACP => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'lacp' => 'Enable',
            'lacpmode' => 'Active',
            'host' => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            'Type' => 'Port',
            'TestPort' => 'host.[1].pswitchport.[-1]',
            'mode' => 'Active',
            'configurechannelgroup' => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkState_Enable => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "2",
          },
          RemoveVDS => {
            'Type'            => "VC",
            'TestVC'          => "vc.[1]",
            'deletevds'       => "vc.[1].vds.[1]",
          },
          CheckLACPUplinkState_NoDVS => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp config get",
              expectedString  => "there is no DVSwitch configured on host",
          },
          CreateVDS => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1]',
            'vds' => {
              '[1]' => {
                'datacenter' => 'vc.[1].datacenter.[1]',
                'configurehosts' => 'add',
                'name' => 'vds-test',
                'host' => 'host.[1]',
                'vmnicadapter' => 'host.[1].vmnic.[-1]',
                'version' => '5.1.0',
              },
            },
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      LACPvMotion => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'LACPvMotion',
        Summary => 'Test the vmotion functionality with LACP',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly,vmotion',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::LACPvMotion',
        AutomationLevel => 'Automated',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]',
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '4',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1-2].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any',
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'configurevmotion' => 'enable',
                },
              },
              'pswitchport' => {
                '[1-2]' => {
                  'vmnic' => 'host.[1].vmnic.[x]',
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any',
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'configurevmotion' => 'enable',
                },
              },
            },
          },
          'vm' => {
            '[1]' => {
              'datastoreType' => 'shared',
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]',
                  'driver' => 'vmxnet3',
                },
              },
              'host' => 'host.[1]',
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['ConfigTeaming'],
                                  ['EnableLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['BeforevMotionTraffic'],
                                  ['vmotion'],
                                  ['NetperfTraffic1','vmotion'],
                                 ],
          ExitSequence => [
                                  [ 'RemovePortsFromChannelGroup' ],
                                  [ 'DeleteChannelGroup' ],
                                ],
          Duration => 'time in seconds',
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]',
          },
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          BeforevMotionTraffic => {
            Type => 'Traffic',
            noofoutbound => 1,
            testduration => 10,
            toolname => 'netperf',
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'host.[2].vmknic.[1]',
          },
          vmotion => {
            Type => 'VM',
            TestVM => 'vm.[1]',
            priority => 'high',
            vmotion => 'roundtrip',
            dsthost => 'host.[2]',
            iterations => '3',
            staytime => '30',
          },
          NetperfTraffic1 => {
            Type => 'Traffic',
            noofoutbound => 1,
            l4protocol => 'tcp',
            toolname => 'netperf',
            testduration => '180',
            noofinbound => 1,
            testadapter => 'vm.[1].vnic.[1]',
            supportadapter => 'host.[2].vmknic.[1]',
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            configurechannelgroup => 'no',
          },
          DeleteChannelGroup => {
            Type => 'Switch',
            TestSwitch => 'pswitch.[-1]',
            removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      'OldVDSVersion' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => 'OldVDSVersion',
         Summary           => 'Make sure that LACP is not enabled on pre 5.1 '.
                              'Versions of VDS',
         AutomationLevel   => 'Automated',
         ExpectedResult    => 'PASS',
         Tags => 'physicalonly',
         Version => '2',
         testID => 'TDS::EsxServer::VDS::LACP::OldVDSVersion',
         TestbedSpec => {
           'vc' => {
             '[1]' => {
               'datacenter' => {
                 '[1]' => {
                   'host' => 'host.[1]'
                 }
               },
               'vds' => {
                 '[1]' => {
                   'datacenter' => 'vc.[1].datacenter.[1]',
                   'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                   'version' => '4.0',
                   'configurehosts' => 'add',
                   'host' => 'host.[1]',
                 }
               }
             }
           },
           'host' => {
             '[1]' => {
               'vmnic' => {
                 '[1-2]' => {
                   'driver' => 'any'
                 },
               },
               'pswitchport' => {
                 '[1]' => {
                   'vmnic' => 'host.[1].vmnic.[1]'
                 },
                 '[2]' => {
                   'vmnic' => 'host.[1].vmnic.[2]'
                 },
               },
             },
           },
           'pswitch' => {
             '[1]' => {
             },
           },
         },

         WORKLOADS => {
            Sequence          => [
                                  # try to enable lacp on old vds
                                  ['KL_Next_VDS'],
                                  ['EnableLACPError'],
                                  ['MN_VDS'],
                                  ['EnableLACPError'],
                                  ['MN_Next_VDS'],
                                  ['EnableLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkState_Enable'],
                                  ['DisableLACP'],
                                  ['CheckLACPUplinkState_Disable'],
                                 ],
            ExitSequence     => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                 ],
           KL_Next_VDS => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             upgradevds => '4.1.0'
           },
           MN_VDS => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             upgradevds => '5.0.0'
           },
           MN_Next_VDS => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             upgradevds => '5.1.0'
           },
           EnableLACP => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             lacp => 'Enable',
             lacpmode => 'Active',
             verification => 'Verification_success',
             host => 'host.[1]',
           },
           DisableLACP => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             lacp => 'Disable',
             host => 'host.[1]',
           },
           EnableLACPError => {
             Type => 'Switch',
             TestSwitch => 'vc.[1].vds.[1]',
             lacp => 'Enable',
             lacpmode => 'Active',
             expectedresult => 'FAIL',
             host => 'host.[1]',
           },
           ConfigureActiveChannelGroup => {
             Type => 'Port',
             TestPort => 'host.[1].pswitchport.[-1]',
             mode => 'Active',
             configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
           },
           CheckLACPUplinkState_Enable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
               expectedString  => "2",
           },
           CheckLACPUplinkState_Disable => {
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               Type            => "Command",
               TestHost        => "host.[-1]",
               Command         => "esxcli network vswitch dvs vmware lacp config get",
               expectedString  => "LACP is disabled on DVSwitch",
           },
           RemovePortsFromChannelGroup => {
             Type            => "Port",
             TestPort        => "host.[-1].pswitchport.[-1]",
             configurechannelgroup => "no",
           },
           DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
           },
        },
     },

      '10G' => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => '10G',
        Summary => 'Test traffic distribution across 10G links',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::10G',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1-2]'
                }
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '6',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1-2].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1-2]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'speed' => '10G',
                },
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
            '[2]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any'
                },
              },
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'vc.[1].dvportgroup.[1]'
                },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                                  ['ConfigTeaming'],
                                  ['ConfigureLACP'],
                                  ['ConfigureActiveChannelGroup'],
                                  ['CheckLACPUplinkStatus_Bundled'],
                                  ['LACPTraffic'],
                                 ],
          ExitSequence => [
                                  ['RemovePortsFromChannelGroup'],
                                  ['DeleteChannelGroup'],
                                 ],
          ConfigTeaming => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            failback => 'yes',
            lbpolicy => 'iphash',
            notifyswitch => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
          },
          ConfigureLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]'
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkStatus_Bundled => {
             sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             Type            => "Command",
             TestHost        => "host.[1]",
             Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
             expectedString  => "2",
          },
          LACPTraffic => {
               Type            => "Traffic",
               ToolName        => "netperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "host.[1].vmknic.[1]",
               SupportAdapter  => "host.[2].vmknic.[1]",
               TestDuration    => "30",
               Verification    => "Verification_withlacp",
          },
          Verification_withlacp => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "host.[1].vmknic.[1]",
                  pktcapfilter     => "count 5000",
                  pktcount         => "4900+",
               },
          },
          RemovePortsFromChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[1-2]',
            configurechannelgroup => 'no'
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      LACPImportExportVDSConfig => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'LACPImportExportVDSConfig',
        Summary => 'Negative testing. LACP should not '.
                   'be a part of Import Export Config.',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::LACPImportExportVDSConfig',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                },
              },
              'dvportgroup' => {
                '[1]' => {
                  'vds' => 'vc.[1].vds.[1]',
                  'ports' => '2',
                },
                '[2]' => {
                  'vds' => 'vc.[1].vds.[2]',
                  'ports' => '3',
                },
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
                '[2]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any'
                },
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
            },
          },
        },
        WORKLOADS => {
          Sequence => [
                         # Export enabled lacp
                         # Apply profile on same VDS
                         ['EnableLACP'],
                         ['ConfigureActiveChannelGroup'],
                         ['CheckLACPUplinkState_Enable'],
                         ['ExportVDSConfig'],
                         ['DisableLACP'],
                         ['CheckLACPUplinkState_Disable'],
                         ['RestoreVDSConfig'],
                         # Apply profile on different VDS
                         ['ImportVDSConfig'],
                         ['CheckLACPUplinkState_Disable'],
                         ['ImportOrigVDSConfig'],
                         ['CheckLACPUplinkState_Disable'],
                         # Export disabled lacp
                         ['ExportVDSConfig'],
                         ['RestoreVDSConfig'],
                         ['CheckLACPUplinkState_Disable'],
                         ['EnableLACP'],
                         ['CheckLACPUplinkState_Enable'],
                        ],
          ExitSequence => [
                         ['RemovePortsFromChannelGroup'],
                         ['DeleteChannelGroup'],
                        ],
          Duration => 'time in seconds',
          ExportVDSConfig => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            backuprestore => 'exportvds',
            portgroup => 'vc.[1].dvportgroup.[1]'
          },
          RestoreVDSConfig => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[2]',
            backuprestore => 'restorevds',
            portgroup => 'vc.[1].dvportgroup.[2]',
          },
          ImportVDSConfig => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[2]',
            backuprestore => 'importvds',
            portgroup => 'vc.[1].dvportgroup.[2]',
          },
          ImportOrigVDSConfig => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[2]',
            backuprestore => 'importorigvds',
            portgroup => 'vc.[1].dvportgroup.[2]',
          },
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          DisableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable',
            host => 'host.[1]',
          },
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          CheckLACPUplinkState_Enable => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "1",
          },
          CheckLACPUplinkState_Disable => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[-1]",
              Command         => "esxcli network vswitch dvs vmware lacp config get",
              expectedString  => "LACP is disabled on DVSwitch",
          },
          RemovePortsFromChannelGroup => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      'LongDurationLAG' => {
         Product           => 'ESX',
	 Category          => 'Networking',
	 Component         => 'Teaming/LACP',
         TestName => 'LongDurationLAG',
         Summary => 'LAG should remain intact for long duration. It should not reset',
         AutomationLevel   => 'Automated',
         ExpectedResult => 'PASS',
         Tags => 'physicalonly',
         Version => '2',
         testID => 'TDS::EsxServer::VDS::LACP::LongDurationLAG',
         TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-2]' => {
                  'driver' => 'any',
                }
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                },
              },
            },
          },
          'pswitch' => {
            '[1]' => {
              'ip' => "XX.XX.XX.XX",
            },
          },
        },
        'WORKLOADS' => {
          'Sequence' => [
                         ['ConfigureActiveChannelGroup'],
                         ['EnableLACP'],
                         ['CheckUplinkState_Enable'],
                       ],
            ExitSequence => [
                                ['RemovePortsFromChannelGroup'],
                                ['DeleteChannelGroup'],
                              ],
          'ConfigureActiveChannelGroup' => {
            'Type' => 'Port',
            'TestPort' => 'host.[1].pswitchport.[-1]',
            'mode' => 'Active',
            'configurechannelgroup' => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          'EnableLACP' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'lacp' => 'Enable',
            'lacpmode' => 'Active',
            'host' => 'host.[1]'
          },
          'CheckUplinkState_Enable' => {
            # Sleeping for 1000 seconds is only for this case, LongDurationLAG
            sleepbetweenworkloads => 1000,
            Type            => "Command",
            TestHost        => "host.[1]",
            Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
            expectedString  => "2",
          },
          RemovePortsFromChannelGroup => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      'MaxUplinkLimit' => {
        Product           => 'ESX',
	Category          => 'Networking',
	Component         => 'Teaming/LACP',
        TestName => 'MaxUplinkLimit',
        Summary => 'LAG should be formed with 8 uplinks',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::MaxUplinkLimit',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1-9]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                },
              },
            },
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-9]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                },
                '[3]' => {
                  'vmnic' => 'host.[1].vmnic.[3]'
                },
                '[4]' => {
                  'vmnic' => 'host.[1].vmnic.[4]'
                },
                '[5]' => {
                  'vmnic' => 'host.[1].vmnic.[5]'
                },
                '[6]' => {
                  'vmnic' => 'host.[1].vmnic.[6]'
                },
                '[7]' => {
                  'vmnic' => 'host.[1].vmnic.[7]'
                },
                '[8]' => {
                  'vmnic' => 'host.[1].vmnic.[8]'
                },
                '[9]' => {
                  'vmnic' => 'host.[1].vmnic.[9]'
                }
              }
            }
          },
          'pswitch' => {
            '[1]' => {
              'ip' => "XX.XX.XX.XX",
            },
          },
        },
        'WORKLOADS' => {
          'Sequence' => [
                         ['ConfigureActiveChannelGroup'],
                         ['EnableLACP'],
                         ['CheckUplinkState_Enable'],
                         ['DisableLACP'],
                         ['CheckUplinkState_Disable'],
                       ],
            ExitSequence => [
                                ['RemovePortsFromChannelGroup'],
                                ['DeleteChannelGroup'],
                              ],
          'ConfigureActiveChannelGroup' => {
            'Type' => 'Port',
            'TestPort' => 'host.[1].pswitchport.[-1]',
            'mode' => 'Active',
            'configurechannelgroup' => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          'EnableLACP' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'lacp' => 'Enable',
            'lacpmode' => 'Active',
            'host' => 'host.[1]'
          },
          'CheckUplinkState_Enable' => {
            sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            Type            => "Command",
            TestHost        => "host.[1]",
            Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
            expectedString  => "8",
          },
          'DisableLACP' => {
             'Type'           => "Switch",
             'TestSwitch'     => "vc.[1].vds.[1]",
             'lacp'           => "Disable",
             'host'           => "host.[1]",
          },
          CheckUplinkState_Disable => {
             'sleepbetweenworkloads' => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
             'Type'            => "Command",
             'TestHost'        => "host.[-1]",
             'Command'         => "esxcli network vswitch dvs vmware lacp config get",
             'expectedString'  => "LACP is disabled on DVSwitch",
          },
          RemovePortsFromChannelGroup => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

      FalseUplinkJoinLAG => {
        Product          => 'ESX',
        Category         => 'Networking',
        Component        => 'Teaming/LACP',
        TestName => 'FalseUplinkJoinLAG',
        Summary => 'Test when uplinks with different speed and '.
                   ' duplexity join and leave LAGs',
        AutomationLevel   => 'Automated',
        ExpectedResult => 'PASS',
        Tags => 'physicalonly',
        Version => '2',
        testID => 'TDS::EsxServer::VDS::LACP::FalseUplinkJoinLAG',
        TestbedSpec => {
          'vc' => {
            '[1]' => {
              'datacenter' => {
                '[1]' => {
                  'host' => 'host.[1]',
                }
              },
              'vds' => {
                '[1]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[1].vmnic.[1]',
                  'configurehosts' => 'add',
                  'host' => 'host.[1]',
                  'version' => '5.1.0',
                }
              }
            }
          },
          'host' => {
            '[1]' => {
              'vmnic' => {
                '[1-3]' => {
                  'driver' => 'any'
                }
              },
              'pswitchport' => {
                '[1]' => {
                  'vmnic' => 'host.[1].vmnic.[1]'
                },
                '[2]' => {
                  'vmnic' => 'host.[1].vmnic.[2]'
                },
                '[3]' => {
                  'vmnic' => 'host.[1].vmnic.[3]'
                }
              }
            }
          },
          'pswitch' => {
            '[1]' => {
            },
          }
        },
        WORKLOADS => {
          Sequence => [
                         ['EnableLACP'],
                         ['ConfigureActiveChannelGroup'],
                         ['CheckLACPUplinkStatus_1Bundled'],
                         ['Uplink2SpeedChange'],
                         ['AddUplink2'],
                         ['CheckLACPUplinkStatus_1Bundled'],
                         ['CheckLACPUplinkStatus_1Independent'],
                         ['Uplink3DuplexChange'],
                         ['AddUplink3'],
                         ['CheckLACPUplinkStatus_1Bundled'],
                         ['CheckLACPUplinkStatus_2Independent'],
                         ['Uplink1SpeedDuplexChange'],
                         ['AddUplink1'],
                         ['CheckLACPUplinkStatus_2Independent'],
                         ['CheckLACPUplinkStatus_1Standalone'],
                         ['DisableLACP'],
                         ['EnableLACPDifferentUplinks'],
                         ['CheckLACPUplinkStatus_2Independent'],
                         ['CheckLACPUplinkStatus_1Standalone'],
                        ],
          ExitSequence => [
                         ['AllUplinksAuto'],
                         ['CheckLACPUplinkStatus_AllBundled'],
                         ['RemovePortsFromChannelGroup'],
                         ['DeleteChannelGroup'],
                        ],
          ConfigureActiveChannelGroup => {
            Type => 'Port',
            TestPort => 'host.[1].pswitchport.[-1]',
            mode => 'Active',
            configurechannelgroup => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
          EnableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          DisableLACP => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Disable',
            host => 'host.[1]',
          },
          EnableLACPDifferentUplinks => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            lacp => 'Enable',
            lacpmode => 'Active',
            host => 'host.[1]',
          },
          AddUplink1 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[1]'
          },
          AddUplink2 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[2]'
          },
          AddUplink3 => {
            Type => 'Switch',
            TestSwitch => 'vc.[1].vds.[1]',
            configureuplinks => 'add',
            vmnicadapter => 'host.[1].vmnic.[3]'
          },
          AllUplinksAuto => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[-1]',
            configure_link_properties => {
              autoconfigure => 'true',
            }
          },
          Uplink1SpeedDuplexChange => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[1]',
            configure_link_properties => {
              speed => '10',
              duplex => 'half'
            }
          },
          Uplink2SpeedChange => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[2]',
            configure_link_properties => {
              speed => '10',
              duplex => 'full'
            }
          },
          Uplink3DuplexChange => {
            Type => 'NetAdapter',
            TestAdapter => 'host.[1].vmnic.[3]',
            configure_link_properties => {
              speed => '100',
              duplex => 'half',
            }
          },
          CheckLACPUplinkStatus_1Bundled => {
              # for uplink adding, we need more time to wait for a stable result
              sleepbetweenworkloads => 10,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "1",
          },
          CheckLACPUplinkStatus_1Independent => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Independent | wc -l ",
              expectedString  => "1",
          },
          CheckLACPUplinkStatus_2Independent => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Independent | wc -l ",
              expectedString  => "2",
          },
          CheckLACPUplinkStatus_1Standalone => {
              sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
              Type            => "Command",
              TestHost        => "host.[1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Stand-alone | wc -l ",
              expectedString  => "1",
          },
          CheckLACPUplinkStatus_AllBundled => {
              # for uplink speed/duplex change, we need more time to wait for a stable result
              sleepbetweenworkloads => 10,
              Type            => "Command",
              TestHost        => "host.[-1]",
              Command         => "esxcli network vswitch dvs vmware lacp status get | grep Bundled | wc -l ",
              expectedString  => "3",
          },
          RemovePortsFromChannelGroup => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
          },
          DeleteChannelGroup => {
             Type => 'Switch',
             TestSwitch => 'pswitch.[-1]',
             removeportchannel => VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
          },
        },
      },

   ); # End of LACPv1.
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VDS.
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
   my $self = $class->SUPER::new(\%LACP);
   return (bless($self, $class));
}

