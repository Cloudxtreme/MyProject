########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::VDSTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use TDS::EsxServer::VDS::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %VDS = (
        'Security-PromiscuousMode' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Security-PromiscuousMode',
          'Summary' => 'Test security options of vds',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'RAT,VDS_Virtual',
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
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'DisablePromiscuous'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic1'
              ],
              [
                'EnablePromiscuous'
              ],
              [
                'Traffic2'
              ]
            ],
            'Duration' => 'time in seconds',
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'DisablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'setpromiscuous' => 'disable',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'ipv4' => 'auto'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'verification' => 'Verification_1',
              'toolname' => 'netperf',
              'testduration' => 18,
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
                'pktcount' => '0',
                'pktcapfilter' => 'count 999',
                'verificationtype' => 'pktcap'
              }
            }
          }
        },


        'DVUplinkSingleVLANRange' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVUplinkSingleVLANRange',
          'Summary' => 'Test the vds uplink portgroup vlan functionality with' .
                       ' single vlan range',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'RAT',
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
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'SetVLAN'
              ],
              [
                'SetUplinkSingleVLAN1'
              ],
              [
                'ConfigureIP'
              ],
              [
                'TrafficPass'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'SetVLAN' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
            },
            'SetUplinkSingleVLAN1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].vds.[1].uplinkportgroup.[1]',
              'vlantype' => 'trunk',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'TrafficPass' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'toolname' => 'netperf',
              'testduration' => 60,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },


        'Failover-NotifySwitches' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Failover-NotifySwitches',
          'Summary' => 'Test notifySwitches after failover of teaming',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'physicalonly',
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
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[1-2];;host.[2].vmnic.[1]',
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
            'vm' => {
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1]'
              },
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2]'
              },
            },
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'ConfigTeaming'
              ],
              [
                'VerifyvNicPort2'
              ],
              [
                'Traffic'
              ],
              [
                'DisablePort2'
              ],
              [
                'VerifyActiveNIC1'
              ],
              [
                'VerifyvNicPort1'
              ],
              [
                'EnablePort2'
              ],
              [
                'VerifyvNicPort2'
              ],
              [
                'VerifyActiveNIC2'
              ],
              [
                'DisableNotify'
              ],
              [
                'DownvNic'
              ],
              [
                'DisablePort2'
              ],
              [
                'VerifyvNicPort1Fail'
              ]
            ],
            'ExitSequence' => [
              [
                'EnablePort2'
              ],
              [
                'UpvNic'
              ],
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'ConfigTeaming' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[1]',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyvNicPort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
            },
            'Traffic' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'testduration' => 10,
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DisablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'portstatus' => 'disable'
            },
            'VerifyActiveNIC1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'verifyactivevmnic' => 'host.[1].vmnic.[1]'
            },
            'VerifyvNicPort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
            },
            'EnablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'portstatus' => 'enable'
            },
            'VerifyActiveNIC2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'verifyactivevmnic' => 'host.[1].vmnic.[2]'
            },
            'DisableNotify' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'no',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'DownvNic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'devicestatus' => 'DOWN'
            },
            'VerifyvNicPort1Fail' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'expectedresult' => 'FAIL',
              'verifyvnicswitchport' => 'vm.[1].vnic.[1]'
            },
            'UpvNic' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'devicestatus' => 'UP'
            },
          }
        },


        'DVUplinkMultipleVLANRange' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'DVUplinkMultipleVLANRange',
          'Summary' => 'Test the vds uplink portgroup vlan functionality',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'RAT',
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
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'SetVLAN'
              ],
              [
                'SetUplinkMultipleVLAN1'
              ],
              [
                'TrafficPass'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'SetVLAN' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            'SetUplinkMultipleVLAN1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].vds.[1].uplinkportgroup.[1]',
              'vlantype' => 'trunk',
              'vlan' => "[" . VDNetLib::Common::GlobalConfig::VDNET_VLAN_D . "-" .
                        VDNetLib::Common::GlobalConfig::VDNET_VLAN_E . "]"
            },
            'TrafficPass' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'toolname' => 'netperf',
              'testduration' => 60,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },


        'VLAN' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'VLAN',
          'Summary' => 'Test the VLAN function of vDS',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'BAT,batwithvc',
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'CreateDVPG_C'
              ],
              [
                'AddPorts1'
              ],
              [
                'AddPorts2'
              ],
              [
                'AddPorts3'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'DVPGAVLAN302'
              ],
              [
                'DVPGBVLAN303'
              ],
              [
                'DVPGCVLANRANGE'
              ],
              [
                'Helper2gVLAN303'
              ],
              [
                'DhcpVlanInterface'
              ],
              [
                'Traffic1'
              ],
              [
                'TrafficFail'
              ],
              [
                'DVPGAVLAN303'
              ],
              [
                'DhcpVlanInterface'
              ],
              [
                'Traffic2'
              ],
              [
                'ChangeRange'
              ],
              [
                'TrafficFail'
              ]
            ],
            'ExitSequence' => [
              [
                'Helper2gVLAN0'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'vlan_a',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'vlan_b',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_C' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[4]' => {
                  'ports' => undef,
                  'name' => 'vlan_c',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPorts1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '10'
            },
            'AddPorts2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '10'
            },
            'AddPorts3' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'addporttodvportgroup' => '10'
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'DVPGAVLAN302' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
            },
            'DVPGBVLAN303' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
            },
            'DVPGCVLANRANGE' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'trunk',
              'vlan' => "[" . VDNetLib::Common::GlobalConfig::VDNET_VLAN_C . "-" .
                        VDNetLib::Common::GlobalConfig::VDNET_VLAN_E . "]"
            },
            'Helper2gVLAN303' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'vlaninterface' => {
                '[1]' => {
                  'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
                  'ipv4' => 'dhcp'
                }
              }
            },
            'DhcpVlanInterface' => {
              'Type'=> 'NetAdapter',
              'testadapter' => 'vm.[3].vnic.[1].vlaninterface.[1],vm.[1-2].vnic.[1]',
              'ipv4' => 'dhcp'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'toolname' => 'netperf',
              'l3protocol' => 'ipv4,ipv6',
              'testduration' => 60,
              'noofinbound' => 1,
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
            },
            'TrafficFail' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'FAIL',
              'toolname' => 'ping',
              'testduration' => 20,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
            },
            'DVPGAVLAN303' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_E
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'toolname' => 'netperf',
              'l3protocol' => 'ipv4,ipv6',
              'testduration' => 60,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1].vlaninterface.[1]'
            },
            'ChangeRange' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'trunk',
              'vlan' => '[100-110]'
            },
            'Helper2gVLAN0' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'deletevlaninterface'   => 'vm.[3].vnic.[1].vlaninterface.[1]',
            }
          }
        },


        'vMotionWithMultipleInterfaces' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vMotionWithMultipleInterfaces',
          'Summary' => 'Test the vmotion functionality with multiple interfaces' .
                       '  on same subnet enabled for vmotion',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[5]' => {
                    'vds' => 'vc.[1].vds.[2]'
                  },
                  '[2]' => {
                    'vds' => 'vc.[1].vds.[2]'
                  },
                  '[3]' => {
                    'vds' => 'vc.[1].vds.[2]'
                  },
                  '[4]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  },
                  '[1]' => {
                    'vds' => 'vc.[1].vds.[1]'
                  }
                },
                'vds' => {
                  '[2]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                  '[1-2]' => {
                    'driver' => 'any'
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[5]'
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
                  '[2]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[4]'
                  },
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
                'vmstate' => 'poweroff',
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
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'EnableVMotion3'
              ],
              [
                'NetperfTraffic1',
                'vmotion',
                'VmknicDisable'
              ],
              [
                'NetperfTraffic1',
                'vmotion',
                'VmknicEnable'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => '192.168.111.1'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[2]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => '192.168.111.2'
            },
            'EnableVMotion3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => '192.168.111.3'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'tcp',
              'toolname' => 'netperf',
              'testduration' => '120',
              'noofinbound' => '1',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2].x.[x]',
              'staytime' => '30'
            },
            'VmknicDisable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'sleepbetweenworkloads' => '60',
              'devicestatus' => 'DOWN'
            },
            'VmknicEnable' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'sleepbetweenworkloads' => '60',
              'devicestatus' => 'UP'
            }
          }
        },


        'ForgedTransmit' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'ForgedTransmit',
          'Summary' => 'Test security options of vds, forged transmit',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic1'
              ],
              [
                'ChangeMACAddr'
              ],
              [
                'Traffic2'
              ],
              [
                'AcceptForgedTx'
              ],
              [
                'AcceptMACChange'
              ],
              [
                'Traffic1'
              ]
            ],
            'ExitSequence' => [
              [
                'ResetMACAddr'
              ]
            ],
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => 5,
                  'name' => 'macchange_a',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => 5,
                  'name' => 'macchange_b',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'toolname' => 'netperf',
              'testduration' => 60,
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'sleepbetweencombos' => '25',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'ChangeMACAddr' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'setmacaddr' => '00:11:22:33:44:66'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'FAIL',
              'testduration' => 20,
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'AcceptForgedTx' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
              'setforgedtransmit' => 'Enable'
            },
            'AcceptMACChange' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
              'setmacaddresschange' => 'Enable'
            },
            'ResetMACAddr' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'setmacaddr' => 'reset'
            }
          }
        },


        'VDSVersion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'VDSVersion',
          'Summary' => 'Test the network connectivity with different vds versions.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                  },
                  '[2]' => {
                    'vds' => 'vc.[1].vds.[2]'
                  },
                  '[3]' => {
                    'vds' => 'vc.[1].vds.[3]'
                  },
                  '[4]' => {
                    'vds' => 'vc.[1].vds.[4]'
                  },
                  '[5]' => {
                    'vds' => 'vc.[1].vds.[5]'
                  },
                  '[6]' => {
                    'vds' => 'vc.[1].vds.[6]'
                  },
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[1]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[2]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[2]',
                    'version' => '4.1',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[3]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[3]',
                    'version' => '5.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[4]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[1]',
                    'version' => '5.1',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                  '[5]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[2]',
                    'version' => '5.5',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                  '[6]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[3]',
                    'version' => '6.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                },
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1-3]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1-3]' => {
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
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[2]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[4]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[4]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[5]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[5]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[6]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[6]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              # As saw issue that not able to get VM control IP when multiple VMs
              # powered on concurrently, as a result power on 2 each time to get
              # cat stability
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'PoweronVM3','PoweronVM4'
              ],
              [
                'PoweronVM5','PoweronVM6'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic'
              ],
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2','PoweroffVM3'
              ],
              [
                'PoweroffVM4','PoweroffVM5','PoweroffVM6'
              ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'PoweroffVM4' => POWEROFF_VM4,
            'PoweroffVM5' => POWEROFF_VM5,
            'PoweroffVM6' => POWEROFF_VM6,
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-6].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'l4protocol' => 'tcp,udp',
              'testduration' => '10',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1-6].vnic.[1]',
              'supportadapter' => 'vm.[1-6].vnic.[1]'
            },
          }
        },


        'Failover-BeaconProbing' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Failover-BeaconProbing',
          'Summary' => 'Test the network failover detection (Beacon  probing)' .
                       ' of vDS on port group level',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                },
                'pswitchport' => {
                  '[2]' => {
                    'vmnic' => 'host.[1].vmnic.[2]'
                  },
                  '[3]' => {
                    'vmnic' => 'host.[1].vmnic.[3]'
                  },
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]'
                  }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'SetFailover1'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','DisablePort1'
              ],
              [
                'Traffic1','VerifyVMNic2'
              ],
              [
                'Traffic1','EnablePort1'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','DisablePort2'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','EnablePort2'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','DisablePort3'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
            ],
            'ExitSequence' => [
              [
                'ResetPort1'
              ],
              [
                'ResetPort2'
              ],
              [
                'ResetPort3'
              ],
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'SetFailover1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[2];;host.[1].vmnic.[3]',
              'lbpolicy' => 'explicit',
              'failover' => 'beaconprobing',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]',
              'notifyswitch' => 'yes'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'testduration' => 70,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyVMNic1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads' => "30",
              'verifyactivevmnic' => {
                'adapters' => 'host.[1].vmnic.[1]'
              }
            },
            'DisablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads' => '10',
              'portstatus' => 'disable'
            },
            'VerifyVMNic2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads' => '30',
              'verifyactivevmnic' => {
                'adapters' => 'host.[1].vmnic.[2]'
              }
            },
            'EnablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads' => '10',
              'portstatus' => 'enable'
            },
            'DisablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads' => '10',
              'portstatus' => 'disable'
            },
            'EnablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads' => '10',
              'portstatus' => 'enable'
            },
            'DisablePort3' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[3]',
              'sleepbetweenworkloads' => '10',
              'portstatus' => 'disable'
            },
            'ResetPort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'portstatus' => 'enable'
            },
            'ResetPort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'portstatus' => 'enable'
            },
            'ResetPort3' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[3]',
              'portstatus' => 'enable'
            }
          }
        },


        'dvPortBlock' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'dvPortBlock',
          'Summary' => 'Verify that the port-block function at port level ' .
                       'and vDS level.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'ConfigureIP'
              ],
              [
                'Iperf1'
              ],
              [
                'BlockAllPorts'
              ],
              [
                'Iperf2'
              ],
              [
                'PingTraffic1'
              ],
              [
                'UnBlockAllPorts'
              ],
              [
                'Iperf1'
              ],
              [
                'PingTraffic2'
              ]
            ],
            'Duration' => 'time in seconds',
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Iperf1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'Iperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'BlockAllPorts' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'blockport' => 'vm.[1].vnic.[1]'
            },
            'Iperf2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'noofoutbound' => '1',
              'noofinbound' => '1',
              'l4protocol' => 'tcp',
              'toolname' => 'Iperf',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PingTraffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'noofoutbound' => '1',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'UnBlockAllPorts' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'unblockport' => 'vm.[1].vnic.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'PingTraffic2' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'noofoutbound' => '1',
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },


        'Teaming-FailoverOrder' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Teaming-FailoverOrder',
          'Summary' => 'Test failover order of teaming feature of vDS',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                },
                'pswitchport' => {
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[2]'
                  }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'AddUplinks'
              ],
              [
                'ConfigTeaming1'
              ],
              [
                'VerifyActiveNIC1'
              ],
              [
                'Traffic1'
              ],
              [
                'DisablePort1'
              ],
              [
                'VerifyActiveNIC2'
              ],
              [
                'Traffic1'
              ]
            ],
            'ExitSequence' => [
              [
                'EnablePort1'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'ConfigTeaming1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[3];;host.[1].vmnic.[1]',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyActiveNIC1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'verifyactivevmnic' => 'host.[1].vmnic.[2]'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'l4protocol' => 'tcp',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DisablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'portstatus' => 'disable'
            },
            'VerifyActiveNIC2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'verifyactivevmnic' => 'host.[1].vmnic.[3]'
            },
            'EnablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'portstatus' => 'enable'
            }
          }
        },


        'PortStatistics_Multicast' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PortStatistics_Multicast',
          'Summary' => 'Test the Statistics function of dvPorts of vDS.Statistics' .
                       ' for dvPorts should be accurate in connected/disconnected' .
                       '/vmotion status.Tx/Rx counters of Multicast packets will ' .
                       'bechecked in this test.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'vmstate' => 'poweroff',
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
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'IperfTraffic'
              ],
              [
                'vmotion'
              ],
              [
                'IperfTraffic'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => 'auto'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => 'auto'
            },
            'IperfTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'Iperf',
              'testduration' => '60',
              'verificationadapter' => 'vm.[1].vnic.[1]',
              'routingscheme' => 'multicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => '1',
              'statstype' => 'InMulticast',
              'verification' => 'dvPortStats',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2].x.[x]',
              'staytime' => '30'
            }
          }
        },


        'vMotionVerifyPortState' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vMotionVerifyPortState',
          'Summary' => 'Make sure that dvport state is preserved during vmotion' .
                       ' operation',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'BAT,vmotion,batwithvc',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'vmstate' => 'poweroff',
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
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'BlockPort'
              ],
              [
                'TrafficFAIL'
              ],
              [
                'vmotion',
                'TrafficFAIL'
              ],
              [
                'TrafficFAIL'
              ],
              [
                'UnBlockPort'
              ],
              [
                'TrafficPASS'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
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
            'BlockPort' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'blockport' => 'vm.[1].vnic.[1]'
            },
            'TrafficFAIL' => {
              'Type' => 'Traffic',
              'expectedresult' => 'FAIL',
              'l4protocol' => 'tcp',
              'testduration' => '30',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'dsthost' => 'host.[2].x.[x]',
              'iterations' => '3',
              'staytime' => '60'
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
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },


        'UplinkPortStatus' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'UplinkPortStatus',
          'Summary' => 'Verify that setting the dvport status to down to which' .
                       ' a pnic is connected doesn\'t bring the system down',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'ConfigureIP'
              ],
              [
                'Traffic',
                'TogglePort'
              ]
            ],
            'ExitSequence' => [
              [
                'SetPortUp'
              ]
            ],
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1-2].vmknic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '64512',
              'toolname' => 'netperf',
              'testduration' => '120',
              'testadapter' => 'host.[1].vmknic.[1]',
              'remotesendsocketsize' => '131072',
              'l4protocol' => 'tcp',
              'sendmessagesize' => '32768',
              'supportadapter' => 'host.[2].vmknic.[1]'
            },
            'TogglePort' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'sleepbetweenworkloads' => '120',
              'port_status' => 'down,up,down,up,down,up',
              'switch' => 'vc.[1].vds.[1]',
              'vmnicadapter' => 'host.[1].vmnic.[1]'
            },
            'SetPortUp' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1]',
              'port_status' => 'up',
              'switch' => 'vc.[1].vds.[1]',
              'vmnicadapter' => 'host.[1].vmnic.[1]'
            }
          }
        },


        'TrafficShaping' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'TrafficShaping',
          'Summary' => 'Test the ingress and egress traffic shaping function' .
                       ' of vds',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'AddPorts1'
              ],
              [
                'AddPorts2'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'EnableInShaping1'
              ],
              [
                'EnableOutShaping1'
              ],
              [
                'Traffic1',
              ],
              [
                'EnableInShaping2'
              ],
              [
                'EnableOutShaping2'
              ],
              [
                'Traffic2',
              ],
              [
                'EnableInShaping3'
              ],
              [
                'EnableOutShaping3'
              ],
              [
                'Traffic3',
              ]
            ],
            'ExitSequence' => [
              [
                'DisableInShaping'
              ],
              [
                'DisableOutShaping'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'shaping_a',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'shaping_b',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPorts1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '10'
            },
            'AddPorts2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '10'
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'noofoutbound' => 1,
              'toolname' => 'ping',
              'testduration' => 200,
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768',
              'minexpresult' => '0',
              'l4protocol' => 'udp',
              'maxthroughput' => '125',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768',
              'minexpresult' => '0',
              'l4protocol' => 'udp',
              'maxthroughput' => '1',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'EnableInShaping1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'iterations' => '10',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => 'random',
                'avg_bandwidth' => 'random',
                'burst_size' => 'random'
              }
            },
            'EnableOutShaping1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'iterations' => '10',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => 'random',
                'avg_bandwidth' => 'random',
                'burst_size' => 'random'
              }
            },
            'EnableInShaping2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '100000',
                'avg_bandwidth' => '100000',
                'burst_size' => '50000'
              }
            },
            'EnableOutShaping2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '100000',
                'avg_bandwidth' => '100000',
                'burst_size' => '50000'
              }
            },
            'EnableInShaping3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '10',
                'avg_bandwidth' => '10',
                'burst_size' => '10'
              }
            },
            'EnableOutShaping3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '10',
                'avg_bandwidth' => '10',
                'burst_size' => '10'
              }
            },
            'DisableInShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'shaping_direction' => 'in'
              }
            },
            'DisableOutShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'shaping_direction' => 'out'
              }
            }
          }
        },


        'vDSBasicConfiguration' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vDSBasicConfiguration',
          'Summary' => 'Verify that Basic VDS configuration works.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'PingTraffic'
              ]
            ],
            'Duration' => 'time in seconds',
            'PingTraffic' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'testduration' => '60',
              'toolname' => 'ping',
              'noofinbound' => '1'
            }
          }
        },


        'Teaming-VirtualPort' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Teaming-VirtualPort',
          'Summary' => 'Test the teaming feature load balancing (Route based' .
                       ' on virtual portid)',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1-2]' => {
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'AddUplinks'
              ],
              [
                'ConfigTeaming'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ConfigureIP'
              ],
              [
                'DisableSUTvNic2'
              ],
              [
                'Traffic1'
              ],
              [
                'DisableSUTvNic1'
              ],
              [
                'EnableSUTvNic2'
              ],
              [
                'ConfigureIPVM1'
              ],
              [
                'Traffic2'
              ],
              [
                'Traffic3'
              ]
            ],
            'ExitSequence' => [
              [
                'EnablevNics'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'ConfigTeaming' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'portid',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1],vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'ConfigureIPVM1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'DisableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'DOWN'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DisableSUTvNic1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'devicestatus' => 'DOWN'
            },
            'EnableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[2]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EnablevNics' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            }
          }
        },


        'CDP' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'CDP',
          'Summary' => 'Test CDP support on vds',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => undef,
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
                'pswitchport' => {
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]'
                  }
                }
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'ListenMode'
              ],
              [
                'VerifyCDPOnEsx'
              ],
              [
                'AdvertiseMode'
              ],
              [
                'VerifyCDPOnSwitch'
              ],
              [
                'BothMode'
              ],
              [
                'VerifyCDPOnSwitch'
              ],
              [
                'VerifyCDPOnEsx'
              ],
              [
                'DisableCDP'
              ],
              [
                'NoCDPOnEsx'
              ],
              [
                'NoCDPOnSwitch'
              ]
            ],
            'ExitSequence' => [
              [
                'ListenMode'
              ]
            ],
            'ListenMode' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configure_cdp_mode' => 'listen'
            },
            'VerifyCDPOnEsx' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'checkcdponesx' => 'yes',
              'sleepbetweencombos' => '30'
            },
            'AdvertiseMode' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configure_cdp_mode' => 'advertise'
            },
            'VerifyCDPOnSwitch' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweencombos' => '180',
              'checkcdponswitch' => 'yes'
            },
            'BothMode' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configure_cdp_mode' => 'both'
            },
            'DisableCDP' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configure_cdp_mode' => 'none'
            },
            'NoCDPOnEsx' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'checkcdponesx' => 'no',
              'sleepbetweencombos' => '60'
            },
            'NoCDPOnSwitch' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweencombos' => '180',
              'checkcdponswitch' => 'no'
            }
          }
        },


        'vMotionWithJFVLAN' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vMotionWithJFVLAN',
          'Summary' => 'Test the vmotion functionality with vDS, Jumbo Frame' .
                       ' and VLAN enabled',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'vmstate' => 'poweroff',
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
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'SetVDS1MTU1'
              ],
              [
                'SetVDS2MTU1'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'SetVLAN'
              ],
              [
                'SetVMMTU1'
              ],
              [
                'NetperfTraffic1',
                'vmotion'
              ]
            ],
            'ExitSequence' => [
              [
                'SetVMMTU2'
              ],
              [
                'SetVDS1MTU2'
              ],
              [
                'SetVDS2MTU2'
              ],
              [
                'PoweroffVM1','PoweroffVM2'
              ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
            'SetVDS1MTU1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'SetVDS2MTU1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'mtu' => '9000'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => '192.168.111.1',
              'mtu' => '9000'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => '192.168.111.2',
              'mtu' => '9000'
            },
            'SetVLAN' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
              'vlantype' => 'access',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
            },
            'SetVMMTU1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '9000'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '64512',
              'toolname' => 'netperf',
              'testduration' => '120',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => '1',
              'remotesendsocketsize' => '131072',
              'l4protocol' => 'tcp,udp',
              'sendmessagesize' => '32768',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2].x.[x]',
              'iterations' => '3',
              'staytime' => '30'
            },
            'SetVMMTU2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '1500'
            },
            'SetVDS1MTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            },
            'SetVDS2MTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'mtu' => '1500'
            }
          }
        },


        'TrafficShaping-Egress' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'TrafficShaping-Egress',
          'Summary' => 'Test the egress traffic shaping function of vds',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'AddPorts1'
              ],
              [
                'AddPorts2'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'EnableOutShaping1'
              ],
              [
                'Traffic1'
              ],
              [
                'EnableOutShaping2'
              ],
              [
                'Traffic2'
              ],
              [
                'EnableOutShaping3'
              ],
              [
                'Traffic3'
              ],
              [
                'EnableOutShaping4'
              ]
            ],
            'ExitSequence' => [
              [
                'DisableOutShaping'
              ]
            ],
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'outshaping_a',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'outshaping_b',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPorts1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '10'
            },
            'AddPorts2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '10'
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableOutShaping1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '1000000',
                'avg_bandwidth' => '1000000',
                'burst_size' => '102400'
              }
            },
            'EnableOutShaping2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '10000',
                'avg_bandwidth' => '10000',
                'burst_size' => '1024'
              }
            },
            'EnableOutShaping3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '1',
                'avg_bandwidth' => '1',
                'burst_size' => '1'
              }
            },
            'EnableOutShaping4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'expectedresult' => 'FAIL',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'out',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '0',
                'avg_bandwidth' => '0',
                'burst_size' => '0'
              }
            },
            'DisableOutShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'shaping_direction' => 'out'
              }
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'minexpresult' => '1',
              'l4protocol' => 'udp',
              'maxthroughput' => '10',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'l4protocol' => 'udp',
              'maxthroughput' => '1000',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'FAIL',
              'remotesendsocketsize' => '32768,65535',
              'l4protocol' => 'udp',
              'maxthroughput' => '1',
              'sendmessagesize' => '1470',
              'noofinbound' => 1,
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            }
          }
        },


        'HostManagement' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'HostManagement',
          'Summary' => 'Verify that VDS Host management works.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual,batwithvc',
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
                'iperfTraffic'
              ]
            ],
            'Duration' => 'time in seconds',
            'iperfTraffic' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'udp',
              'testduration' => '60',
              'toolname' => 'Iperf',
              'noofinbound' => '1'
            }
          }
        },


        'PortStatistics_Unicast' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PortStatistics_Unicast',
          'Summary' => 'Test the Statistics function of dvPorts of vDS.Statistics' .
                       ' for dvPorts should be accurate in connected/disconnected' .
                       '/vmotion status.Tx/Rx counters of Unicast packets will be' .
                       'checked in this test.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'vmotion,VDS_Virtual',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'PingTraffic'
              ],
              [
                'vmotion'
              ],
              [
                'PingTraffic'
              ]
            ],
            'Duration' => 'time in seconds',
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
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
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'Ping',
              'verificationadapter' => 'vm.[1].vnic.[1]',
              'routingscheme' => 'unicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'statstype' => 'OutUnicast',
              'verification' => 'dvPortStats',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
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


        'TrafficShaping-Ingress' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'TrafficShaping-Ingress',
          'Summary' => 'Test the ingress traffic shaping function of vds',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'AddPorts1'
              ],
              [
                'AddPorts2'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'EnableInShaping1'
              ],
              [
                'Traffic1',
              ],
              [
                'EnableInShaping2'
              ],
              [
                'Traffic2',
              ],
              [
                'EnableInShaping3'
              ],
              [
                'Traffic3',
              ],
              [
                'EnableInShaping4'
              ]
            ],
            'ExitSequence' => [
              [
                'DisableInShaping'
              ]
            ],
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'inshaping_a',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => undef,
                  'name' => 'inshaping_b',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'AddPorts1' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'addporttodvportgroup' => '10'
            },
            'AddPorts2' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'addporttodvportgroup' => '10'
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableInShaping1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '1000000',
                'avg_bandwidth' => '1000000',
                'burst_size' => '102400'
              }
            },
            'EnableInShaping2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '10000',
                'avg_bandwidth' => '10000',
                'burst_size' => '1024'
              }
            },
            'EnableInShaping3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '1',
                'avg_bandwidth' => '1',
                'burst_size' => '1'
              }
            },
            'EnableInShaping4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'expectedresult' => 'FAIL',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'peak_bandwidth' => '0',
                'avg_bandwidth' => '0',
                'burst_size' => '0'
              }
            },
            'DisableInShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[2]',
                'shaping_direction' => 'in'
              }
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'l4protocol' => 'udp',
              'maxthroughput' => '10',
              'sendmessagesize' => '1470',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'remotesendsocketsize' => '32768,65535',
              'l4protocol' => 'udp',
              'maxthroughput' => '1000',
              'sendmessagesize' => '1470',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '32768,65535',
              'toolname' => 'netperf',
              'testduration' => 10,
              'bursttype' => 'stream',
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'FAIL',
              'remotesendsocketsize' => '32768,65535',
              'l4protocol' => 'udp',
              'maxthroughput' => '1',
              'sendmessagesize' => '1470',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            }
          }
        },


        'SuspendResume' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'SuspendResume',
          'Summary' => 'Test the Statistics function of dvPorts of vDS.Statistics' .
                       ' for dvPorts should be accurate during/after suspend resu' .
                       'me operationTx/Rx counters of Broadcast packets will bech' .
                       'ecked in this test.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'Traffic'
              ],
              [
                'SuspendResume'
              ],
              [
                'Traffic'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => 5,
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'Traffic' => {
              'Type' => 'Traffic',
              'verification' => 'dvPortStats',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '60',
              'verificationadapter' => 'vm.[1].vnic.[1]',
              'routingscheme' => 'unicast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SuspendResume' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'iterations' => '1',
              'vmstate' => 'suspend,resume'
            }
          }
        },


        'MACAddressChanges' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'MACAddressChanges',
          'Summary' => 'Test security options of vds, mac address change',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
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
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
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
                  '[1]' => {}
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_A'
              ],
              [
                'CreateDVPG_B'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'Traffic1'
              ],
              [
                'ChangeMACAddr'
              ],
              [
                'Traffic2'
              ],
              [
                'AcceptMACChange'
              ],
              [
                'AcceptForgedTx'
              ],
              [
                'Traffic1'
              ]
            ],
            'ExitSequence' => [
              [
                'ResetMACAddr'
              ]
            ],
            'CreateDVPG_A' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => 5,
                  'name' => 'macchange_a',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'CreateDVPG_B' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'dvportgroup' => {
                '[3]' => {
                  'ports' => 5,
                  'name' => 'macchange_b',
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'toolname' => 'netperf',
              'testduration' => 60,
              'testadapter' => 'vm.[1].vnic.[1]',
              'noofoutbound' => 1,
              'expectedresult' => 'PASS',
              'sleepbetweencombos' => '25',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'ChangeMACAddr' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'setmacaddr' => '00:11:22:33:44:66'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'expectedresult' => 'FAIL',
              'testduration' => 60,
              'toolname' => 'ping',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]'
            },
            'AcceptMACChange' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
              'setmacaddresschange' => 'Enable'
            },
            'AcceptForgedTx' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[2]',
              'setforgedtransmit' => 'Enable'
            },
            'ResetMACAddr' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'setmacaddr' => 'reset'
            }
          }
        },


        'Failover-LinkStatusOnly' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Failover-LinkStatusOnly',
          'Summary' => 'Test the network failover detection (link  status only) ' .
                       'of vDS on port group level',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                },
                'pswitchport' => {
                  '[3]' => {
                    'vmnic' => 'host.[1].vmnic.[3]'
                  },
                  '[2]' => {
                    'vmnic' => 'host.[1].vmnic.[2]'
                  },
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]'
                  },
                }

              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'SetFailover1'
              ],
              [
                'Traffic1','DisablePort1'
              ],
              [
                'Traffic1','VerifyVMNic2'
              ],
              [
                'Traffic1','EnablePort1'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','DisablePort2'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','EnablePort2'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ],
              [
                'Traffic1','DisablePort3'
              ],
              [
                'Traffic1','VerifyVMNic1'
              ]
            ],
            'ExitSequence' => [
              [
                'ResetPort1'
              ],
              [
                'ResetPort2'
              ],
              [
                'ResetPort3'
              ],
              [
                'PoweroffVM1','PoweroffVM2'
              ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'SetFailover1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[2];;host.[1].vmnic.[3]',
              'lbpolicy' => 'explicit',
              'failover' => 'linkstatusonly',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]',
              'notifyswitch' => 'yes'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'testduration' => 70,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DisablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'disable'
            },
            'EnablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'enable'
            },
            'VerifyVMNic2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads' => '30',
              'verifyactivevmnic' => 'host.[1].vmnic.[2]'
            },
            'VerifyVMNic1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads' => '30',
              'verifyactivevmnic' => 'host.[1].vmnic.[1]'
            },
            'DisablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'disable'
            },
            'EnablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'enable'
            },
            'DisablePort3' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[3]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'disable'
            },
            'EnablePort3' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[3]',
              'sleepbetweenworkloads'=> '10',
              'portstatus' => 'enable'
            },
            'ResetPort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'portstatus' => 'enable'
            },
            'ResetPort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'portstatus' => 'enable'
            },
            'ResetPort3' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[3]',
              'portstatus' => 'enable'
            }
          }
        },


        'Failover-Failback' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Failover-Failback',
          'Summary' => 'Test the function of failback option of vDS',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                },
                'pswitchport' => {
                  '[2]' => {
                    'vmnic' => 'host.[1].vmnic.[2]'
                  },
                  '[1]' => {
                    'vmnic' => 'host.[1].vmnic.[1]'
                  }
                }
              }
            },
            'vm' => {
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              }
            },
            'pswitch' => {
              '[-1]' => {}
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'SetFailover1'
              ],
              [
                'NetAdapter_DHCP'
              ],
              [
                'Traffic1',
                'VerifyVMNic1'
              ],
              [
                'Traffic1',
                'DisablePort1'
              ],
              [
                'Traffic1',
                'VerifyVMNic2'
              ],
              [
                'Traffic1',
                'DisablePort2'
              ],
              [
                'Traffic1',
                'VerifyVMNic3'
              ],
              [
                'Traffic1',
                'EnablePort2'
              ],
              [
                'Traffic1',
                'VerifyVMNic2'
              ],
              [
                'Traffic1',
                'DisableFailback'
              ],
              [
                'Traffic1',
                'EnablePort1'
              ],
              [
                'Traffic1',
                'VerifyVMNic2'
              ],
              [
                'Traffic1',
                'EnableFailback'
              ],
              [
                'Traffic1',
                'VerifyVMNic1'
              ],
            ],
            'ExitSequence' => [
              [
                'EnablePort1'
              ],
              [
                'EnablePort2'
              ],
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'SetFailover1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[2];;host.[1].vmnic.[3]',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'NetAdapter_DHCP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-2].vnic.[1]',
              'ipv4' => 'dhcp'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyVMNic1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads'=> '30',
              'verifyactivevmnic' => 'host.[1].vmnic.[1]'
            },
            'DisablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads'=> '5',
              'portstatus' => 'disable'
            },
            'VerifyVMNic2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads'=> '30',
              'verifyactivevmnic' => 'host.[1].vmnic.[2]'
            },
            'DisablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads'=> '5',
              'portstatus' => 'disable'
            },
            'VerifyVMNic3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'sleepbetweenworkloads'=> '30',
              'verifyactivevmnic' => 'host.[1].vmnic.[3]'
            },
            'EnablePort2' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[2]',
              'sleepbetweenworkloads'=> '5',
              'portstatus' => 'enable'
            },
            'DisableFailback' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'no',
              'sleepbetweenworkloads'=> '5',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]',
            },
            'EnablePort1' => {
              'Type' => 'Port',
              'TestPort' => 'host.[1].pswitchport.[1]',
              'sleepbetweenworkloads'=> '5',
              'portstatus' => 'enable'
            },
            'EnableFailback' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'yes',
              'sleepbetweenworkloads'=> '5',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]',
            },
          }
        },

        'PVLAN_Promiscuous' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PVLAN_Promiscuous',
          'Summary' => 'Test the promiscuous port mode of PVLAN feature of vDS.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => undef,
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'CreateDVPG1'
              ],
              [
                'AddPort1'
              ],
              [
                'CreateDVPG2'
              ],
              [
                'AddPort2'
              ],
              [
                'CreateDVPG3'
              ],
              [
                'AddPort3'
              ],
              [
                'AddPVLAN_P'
              ],
              [
                'AddPVLAN_I'
              ],
              [
                'AddPVLAN_C'
              ],
              [
                'SetPVLAN_P'
              ],
              [
                'SetPVLAN_I'
              ],
              [
                'SetPVLAN_C'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'NetperfTraffic1'
              ]
            ],
            'ExitSequence' => [
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
            'AddPVLAN_P' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'promiscuous'
            },
            'AddPVLAN_I' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'isolated'
            },
            'AddPVLAN_C' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'community'
            },
            'SetPVLAN_P' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
            },
            'SetPVLAN_I' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
            },
            'SetPVLAN_C' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf'
            }
          }
        },


        'PVLAN_Isolated' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PVLAN_Isolated',
          'Summary' => 'Test the Isolated port mode of PVLAN feature of vDS.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => undef,
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'CreateDVPG1'
              ],
              [
                'AddPort1'
              ],
              [
                'CreateDVPG2'
              ],
              [
                'AddPort2'
              ],
              [
                'CreateDVPG3'
              ],
              [
                'AddPort3'
              ],
              [
                'AddPVLAN_P'
              ],
              [
                'AddPVLAN_I'
              ],
              [
                'AddPVLAN_C'
              ],
              [
                'SetPVLAN_P'
              ],
              [
                'SetPVLAN_I'
              ],
              [
                'SetPVLAN_C'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'NetperfTraffic1'
              ]
            ],
            'ExitSequence' => [
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
            'AddPVLAN_P' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'promiscuous'
            },
            'AddPVLAN_I' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'isolated'
            },
            'AddPVLAN_C' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'community'
            },
            'SetPVLAN_P' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
            },
            'SetPVLAN_I' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
            },
            'SetPVLAN_C' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },


        'VDSUpgrade' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'VDSUpgrade',
          'Summary' => 'Test the network connectivity with different vds versions' .
                       ' after upgrading them',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  },
                  '[2]' => {
                    'vds' => 'vc.[1].vds.[2]'
                  },
                  '[3]' => {
                    'vds' => 'vc.[1].vds.[3]'
                  },
                  '[4]' => {
                    'vds' => 'vc.[1].vds.[4]'
                  },
                  '[5]' => {
                    'vds' => 'vc.[1].vds.[5]'
                  },
                  '[6]' => {
                    'vds' => 'vc.[1].vds.[6]'
                  },
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[1]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[2]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[2]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[3]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[3]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[1].x.[x]'
                  },
                  '[4]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[1]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                  '[5]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[2]',
                    'version' => '4.0',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                  '[6]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[2].vmnic.[3]',
                    'version' => '4.1',
                    'configurehosts' => 'add',
                    'host' => 'host.[2].x.[x]'
                  },
                },
              }
            },
            'host' => {
              '[2]' => {
                'vmnic' => {
                  '[1-3]' => {
                    'driver' => 'any'
                  }
                }
              },
              '[1]' => {
                'vmnic' => {
                  '[1-3]' => {
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
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[2]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[4]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[4]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[5]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[5]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[6]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[6]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'PoweronVM1','PoweronVM2'
              ],
              [
                'PoweronVM3','PoweronVM4'
              ],
              [
                'PoweronVM5','PoweronVM6'
              ],
              [
                'ConfigureIP'
              ],
              [
                'Traffic'
              ],
              [
                'UpgradeVDS1','UpgradeVDS2','UpgradeVDS3','UpgradeVDS4','UpgradeVDS5'
              ],
              [
                'Traffic'
              ],
              [
                'CreateVDS1'
              ],
              [
                'CreateDVPG1'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'DeleteVDS1'
              ],
              [
                'UpgradeVDS6','UpgradeVDS7','UpgradeVDS8'
              ],
              [
                'AddUplink1'
              ],
              [
                'Traffic'
              ],
              [
                'CreateVDS2'
              ],
              [
                'CreateDVPG2'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'ChangePortgroup4'
              ],
              [
                'DeleteVDS2'
              ],
              [
                'DeleteVDS3'
              ],
              [
                'UpgradeVDS9','UpgradeVDS10'
              ],
              [
                'AddUplink2'
              ],
              [
                'AddUplink3'
              ],
              [
                'AddUplink4'
              ],
              [
                'Traffic'
              ],
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2','PoweroffVM3'
              ],
              [
                'PoweroffVM4','PoweroffVM5','PoweroffVM6'
              ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'PoweroffVM4' => POWEROFF_VM4,
            'PoweroffVM5' => POWEROFF_VM5,
            'PoweroffVM6' => POWEROFF_VM6,
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-6].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'Traffic' => {
              'Type' => 'Traffic',
              'expectedresult' => 'PASS',
              'l4protocol' => 'tcp,udp',
              'testduration' => '10',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1-6].vnic.[1]',
              'supportadapter' => 'vm.[1-6].vnic.[1]',
            },
            'UpgradeVDS1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => '4.1.0'
            },
            'UpgradeVDS2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2],vc.[1].vds.[6]',
              'upgradevds' => '5.0.0'
            },
            'UpgradeVDS3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[3]',
              'upgradevds' => '5.1.0'
            },
            'UpgradeVDS4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[4]',
              'upgradevds' => '5.5.0'
            },
            'UpgradeVDS5' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[5]',
              'upgradevds' => '6.0.0'
            },
            'CreateVDS1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'vds' => {
                '[7]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[2].vmnic.[2]',
                  'version' => '4.1.0',
                  'name' => 'VDS1',
                  'host' => 'host.[2].x.[x]'
                }
              }
            },
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[7]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_170_170',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[7]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[7]'
            },
            'DeleteVDS1' => {
              'Type' => "VC",
              'TestVC' => "vc.[1]",
              'deletevds' => "vc.[1].vds.[5]",
            },
            'AddUplink1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[7]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
            'UpgradeVDS6' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1-2]',
              'upgradevds' => '5.1.0'
            },
            'UpgradeVDS7' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[3],vc.[1].vds.[6-7]',
              'upgradevds' => '5.5.0'
            },
            'UpgradeVDS8' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[4]',
              'upgradevds' => '6.0.0'
            },
            'CreateVDS2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'vds' => {
                '[8]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[2].vmnic.[1]',
                  'version' => '5.0.0',
                  'name' => 'VDS2',
                  'host' => 'host.[2].x.[x]'
                },
                '[9]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[2].vmnic.[2]',
                  'version' => '5.0.0',
                  'name' => 'VDS3',
                  'host' => 'host.[2].x.[x]'
                },
                '[10]' => {
                  'datacenter' => 'vc.[1].datacenter.[1]',
                  'vmnicadapter' => 'host.[2].vmnic.[3]',
                  'version' => '4.1.0',
                  'name' => 'VDS4',
                  'host' => 'host.[2].x.[x]'
                },
              }
            },
            'CreateDVPG2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[8]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_800_800',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[8]'
                 },
                '[9]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_190_190',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[9]'
                },
                '[10]' => {
                  'ports' => undef,
                  'name' => 'dvpg_p_100_100',
                  'binding' => undef,
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[10]'
                },
              }
          },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[8]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[9]'
            },
            'ChangePortgroup4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[6].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[10]'
            },
            'DeleteVDS2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'deletevds' => 'vc.[1].vds.[4]'
            },
            'DeleteVDS3' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'deletevds' => 'vc.[1].vds.[6-7]'
            },
            'AddUplink2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[8]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
            },
            'AddUplink3' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[9]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
            'AddUplink4' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[10]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[3]'
            },
            'UpgradeVDS9' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1],vc.[1].vds.[8]',
              'upgradevds' => '5.5.0'
            },
            'UpgradeVDS10' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2-3],vc.[1].vds.[9-10]',
              'upgradevds' => '6.0.0'
            },
          }
        },

        'Teaming-SourceMAC' => {
            'Component' => 'vDS',
            'Category' => 'ESX Server',
            'TestName' => 'Teaming-SourceMAC',
            'Summary' => 'Test the teaming feature load balancing (Route based on ' .
                         'source MAC address)',
            'ExpectedResult' => 'PASS',
            'AutomationStatus'  => 'Automated',
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
                            '[1-3]' => {
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
                        'vmstate' => 'poweroff',
                        'vnic' => {
                            '[1]' => {
                                'portgroup' => 'vc.[1].dvportgroup.[1]',
                                'driver' => 'vmxnet3'
                            }
                        },
                        'host' => 'host.[1].x.[x]'
                   },
                   '[3]' => {
                       'vmstate' => 'poweroff',
                       'vnic' => {
                           '[1]' => {
                               'portgroup' => 'vc.[1].dvportgroup.[1]',
                               'driver' => 'vmxnet3'
                           }
                        },
                        'host' => 'host.[2].x.[x]'
                   },
                   '[1]' => {
                       'vmstate' => 'poweroff',
                       'vnic' => {
                           '[1-2]' => {
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'AddUplinks'
              ],
              [
                'ConfigTeaming'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ConfigureIP'
              ],
              [
                'DisableSUTvNic2'
              ],
              [
                'Traffic1'
              ],
              [
                'DisableSUTvNic1'
              ],
              [
                'EnableSUTvNic2'
              ],
              [
                'ConfigureIPVM1'
              ],
              [
                'Traffic2'
              ],
              [
                'Traffic3'
              ]
            ],
            'ExitSequence' => [
              [
                'EnablevNics'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'ConfigTeaming' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'mac',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'DisableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'DOWN'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1],vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'ConfigureIPVM1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DisableSUTvNic1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'devicestatus' => 'DOWN'
            },
            'EnableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[2]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EnablevNics' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            }
          }
        },

        'Teaming-IPHash' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'Teaming-IPHash',
          'Summary' => 'Test the teaming feature load balancing (Route based on ' .
                       'IP hash)',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                  '[1-3]' => {
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3'
                  }
                },
                'host' => 'host.[2].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1-2]' => {
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'AddUplinks'
              ],
              [
                'ConfigTeaming'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ConfigureIP'
              ],
              [
                'DisableSUTvNic2'
              ],
              [
                'Traffic1'
              ],
              [
                'DisableSUTvNic1'
              ],
              [
                'EnableSUTvNic2'
              ],
              [
                'ConfigureIPVM1'
              ],
              [
                'Traffic2'
              ],
              [
                'Traffic3'
              ]
            ],
            'ExitSequence' => [
              [
                'EnablevNics'
              ],
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1],vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2-3]'
            },
            'ConfigTeaming' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'iphash',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'DisableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'DOWN'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-3].vnic.[1],vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'ConfigureIPVM1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'ipv4' => 'AUTO'
            },
            'Traffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DisableSUTvNic1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'devicestatus' => 'DOWN'
            },
            'EnableSUTvNic2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            },
            'Traffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[2]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Traffic3' => {
              'Type' => 'Traffic',
              'noofoutbound' => 1,
              'verification' => 'activeVMNic',
              'testduration' => 60,
              'toolname' => 'netperf',
              'testadapter' => 'vm.[2].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'EnablevNics' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[1].vnic.[2]',
              'devicestatus' => 'UP'
            }
          }
        },


        'vMotion' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vMotion',
          'Summary' => 'Test the vmotion functionality with vDS',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'vmotion,CAT_P0',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'vmstate' => 'poweroff',
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
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'NetperfTraffic1',
                'vmotion'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2'
              ],
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
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
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '120',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2].x.[x]',
              'iterations' => '3',
              'staytime' => '30'
            }
          }
        },


        'vMotionOverIPv6' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vMotionOverIPv6',
          'Summary' => 'Test the vmotion functionality with vDS over IPv6',
          'Tags' => 'VDS_Virtual',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'NetperfTraffic1',
                'vmotion'
              ]
            ],
            'Duration' => 'time in seconds',
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv6' => 'ADD',
              'ipv6addr' => 'static'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv6' => 'ADD',
              'ipv6addr' => 'static'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv4,ipv6',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '120',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'vmotion' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'priority' => 'high',
              'vmotion' => 'roundtrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2].x.[x]',
              'iterations' => '3',
              'staytime' => '30'
            }
          }
        },


        'vNicMigration' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'vNicMigration',
          'Summary' => 'Test migrating vNIC of VM between vSS and vDS,make sure ' .
                       'that vNIC migration willn’t affectnegively on vNIC and' .
                       ' vDS.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
                }
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'AddVSwitch'
              ],
              [
                'AddPortgroup'
              ],
              [
                'AddVMK'
              ],
              [
                'CreateDVPortgroup'
              ],
              [
                'AddPort'
              ],
              [
                'MigrateManagementToVDS'
              ],
              [
                'MigrateManagementToVSS'
              ],
              [
                'DelVMK'
              ]
            ],
            'Duration' => 'time in seconds',
            'AddVSwitch' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => 'migrate-to-net'
                }
              }
            },
            'AddPortgroup' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'portgroup' => {
                '[1]' => {
                  'name' => 'migrate-pg',
                  'vss' => 'host.[1].vss.[1]'
                }
              }
            },
            'AddVMK' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vmknic' => {
                '[1]' => {
                  'portgroup' => 'host.[1].portgroup.[1]',
                  'ipv4' => 'dhcp',
                  'netmask' => '255.255.0.0'
                }
              }
            },
            'CreateDVPortgroup' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => undef,
                  'name' => 'migrate-dvportgroup',
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
            'MigrateManagementToVDS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[2]',
            },
            'MigrateManagementToVSS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[1]',
            },
            'DelVMK' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'deletevmknic' => 'host.[1].vmknic.[1]'
            }
          }
        },


        'PortStatistics_Broadcast' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PortStatistics_Broadcast',
          'Summary' => 'Test the Statistics function of dvPorts of vDS.Statistics' .
                       ' for dvPorts should be accurate in connected/disconnected' .
                       '/vmotion status.Tx/Rx counters of Broadcast packets will ' .
                       'bechecked in this test.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'vmotion,VDS_Virtual',
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
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2].x.[x]'
                  },
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
                'AddUplinks'
              ],
              [
                'EnableVMotion1'
              ],
              [
                'EnableVMotion2'
              ],
              [
                'ConfigureIP'
              ],
              [
                'PingTraffic'
              ],
              [
                'vmotion'
              ],
              [
                'PingTraffic'
              ]
            ],
            'Duration' => 'time in seconds',
            'AddUplinks' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[2]',
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2];;host.[2].vmnic.[2]'
            },
            'EnableVMotion1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => 'auto'
            },
            'EnableVMotion2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[2].vmknic.[1]',
              'configurevmotion' => 'ENABLE',
              'ipv4' => 'auto'
            },
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'PingTraffic' => {
              'Type' => 'Traffic',
              'toolname' => 'Ping',
              'verificationadapter' => 'vm.[1].vnic.[1]',
              'routingscheme' => 'broadcast',
              'testadapter' => 'vm.[1].vnic.[1]',
              'statstype' => 'OutBroadcast',
              'verification' => 'dvPortStats',
              'noofinbound' => '1',
              'supportadapter' => 'vm.[2].vnic.[1]'
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


        'PVLAN_Community' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PVLAN_Community',
          'Summary' => 'Test the Community port mode of PVLAN feature of vDS.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => undef,
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'CreateDVPG1'
              ],
              [
                'AddPort1'
              ],
              [
                'CreateDVPG2'
              ],
              [
                'AddPort2'
              ],
              [
                'CreateDVPG3'
              ],
              [
                'AddPort3'
              ],
              [
                'AddPVLAN_P'
              ],
              [
                'AddPVLAN_I'
              ],
              [
                'AddPVLAN_C'
              ],
              [
                'SetPVLAN_P'
              ],
              [
                'SetPVLAN_I'
              ],
              [
                'SetPVLAN_C'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'NetperfTraffic1'
              ]
            ],
            'ExitSequence' => [
              [ 'PoweroffVM1','PoweroffVM2','PoweroffVM3' ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'CreateDVPG1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
              'TestVC' => 'vc.[1].x.[x]',
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
            'AddPVLAN_P' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'promiscuous'
            },
            'AddPVLAN_I' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'isolated'
            },
            'AddPVLAN_C' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
              'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
              'addpvlanmap' => 'community'
            },
            'SetPVLAN_P' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
            },
            'SetPVLAN_I' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
            },
            'SetPVLAN_C' => {
              'Type' => 'PortGroup',
              'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
              'vlantype' => 'pvlan',
              'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'NetperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'tcp',
              'testduration' => '60',
              'toolname' => 'netperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            }
          }
        },

        'PortBinding' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PortBinding',
          'Summary' => 'Test the port binding of vDS which includestatic binding,' .
                       ' dynamic-binding and Ephemeral no binding,each have its o' .
                       'wn characteristic such as port number, vPortallocation an' .
                       'd withdrawal.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => 'VDS_Virtual',
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
              '[5]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              },
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              },
              '[6]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              },
              '[4]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              },
              '[1]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]',
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'CreateDVPG_static_dynamic_ephemeral'
              ],
              [
                'PoweronVM1','PoweronVM2','PoweronVM3'
              ],
              [
                'PoweronVM4','PoweronVM5','PoweronVM6'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'ChangePortgroup4'
              ],
              [
                'ChangePortgroup5'
              ],
              [
                'ChangePortgroup6'
              ],
              [
                'iperfTraffic1',
                'iperfTraffic2',
                'ChangePortgroup7'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2','PoweroffVM3'
              ],
              [
                'PoweroffVM4','PoweroffVM5','PoweroffVM6'
              ],
            ],
            'Duration' => 'time in seconds',
            'CreateDVPG_static_dynamic_ephemeral' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => 2,
                  'autoExpand' => 'false',
                  'name' => 'dvpg_static',
                  'binding' => 'earlyBinding',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                },
                '[3]' => {
                  'ports' => 2,
                  'name' => 'dvpg_dynamic',
                  'binding' => 'lateBinding',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                },
                '[4]' => {
                  'ports' => 2,
                  'name' => 'dvpg_ephemeral',
                  'binding' => 'ephemeral',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'PoweroffVM4' => POWEROFF_VM4,
            'PoweroffVM5' => POWEROFF_VM5,
            'PoweroffVM6' => POWEROFF_VM6,
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'expectedresult' => 'FAIL',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroup5' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup6' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[6].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'iperfTraffic1' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'udp',
              'testduration' => '60',
              'toolname' => 'Iperf',
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'iperfTraffic2' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'udp',
              'testduration' => '60',
              'toolname' => 'Iperf',
              'testadapter' => 'vm.[5].vnic.[1]',
              'supportadapter' => 'vm.[6].vnic.[1]'
            },
            'ChangePortgroup7' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'expectedresult' => 'FAIL',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            }
          }
        },

        'PortBindingSnapshot' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'PortBindingSnapshot',
          'Summary' => 'Test the port binding during VM snapshot.',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
          'Tags' => undef,
          'Version' => '2',
          'TestbedSpec' => {
            'vc' => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1].x.[x]'
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
                    'host' => 'host.[1].x.[x]'
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
              '[5]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[2]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[3]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[6]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[4]' => {
                'vmstate' => 'poweroff',
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1].x.[x]'
              },
              '[1]' => {
                'vmstate' => 'poweroff',
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
                'PoweronVM1','PoweronVM2'
              ],
              [
                'PoweronVM3','PoweronVM4'
              ],
              [
                'PoweronVM5','PoweronVM6'
              ],
              [
                'CreateDVPG_static_dynamic_ephemeral'
              ],
              [
                'ChangePortgroup1'
              ],
              [
                'ChangePortgroup2'
              ],
              [
                'ChangePortgroup3'
              ],
              [
                'ChangePortgroup4'
              ],
              [
                'ChangePortgroup5'
              ],
              [
                'ChangePortgroup6'
              ],
              [
                'ConfigureIP'
              ],
              [
                'iperfTraffic'
              ],
              [
                'CreateSnap1'
              ],
              [
                'CreateSnap2'
              ],
              [
                'CreateSnap3'
              ],
              [
                'CreateSnap4'
              ],
              [
                'CreateSnap5'
              ],
              [
                'CreateSnap6'
              ],
              [
                'RevertSnap1'
              ],
              [
                'RevertSnap2'
              ],
              [
                'RevertSnap3'
              ],
              [
                'RevertSnap4'
              ],
              [
                'RevertSnap5'
              ],
              [
                'RevertSnap6'
              ]
            ],
            'ExitSequence' => [
              [
                'PoweroffVM1','PoweroffVM2','PoweroffVM3'
              ],
              [
                'PoweroffVM4','PoweroffVM5','PoweroffVM6'
              ]
            ],
            'Duration' => 'time in seconds',
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweroffVM1' => POWEROFF_VM1,
            'PoweroffVM2' => POWEROFF_VM2,
            'PoweroffVM3' => POWEROFF_VM3,
            'PoweroffVM4' => POWEROFF_VM4,
            'PoweroffVM5' => POWEROFF_VM5,
            'PoweroffVM6' => POWEROFF_VM6,
            'ConfigureIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1-6].vnic.[1]',
              'ipv4' => 'AUTO'
            },
            'CreateDVPG_static_dynamic_ephemeral' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1].x.[x]',
              'dvportgroup' => {
                '[2]' => {
                  'ports' => '2',
                  'autoExpand' => 'false',
                  'name' => 'dvpg_static',
                  'binding' => 'earlyBinding',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                },
                 '[3]' => {
                  'ports' => '2',
                  'name' => 'dvpg_dynamic',
                  'binding' => 'lateBinding',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                },
                '[4]' => {
                  'ports' => '2',
                  'name' => 'dvpg_ephemeral',
                  'binding' => 'ephemeral',
                  'nrp' => undef,
                  'vds' => 'vc.[1].vds.[1]'
                }
              }
            },
            'ChangePortgroup1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[2].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[2]'
            },
            'ChangePortgroup3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[3].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup4' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[4].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup5' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[5].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroup6' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[6].vnic.[1]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'iperfTraffic' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l4protocol' => 'udp',
              'testduration' => '60',
              'toolname' => 'Iperf'
            },
            'CreateSnap1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'name' => 'VDS_snap_SUT',
              'snapshot' => 'create'
            },
            'CreateSnap2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2].x.[x]',
              'name' => 'VDS_snap_helper1',
              'snapshot' => 'create'
            },
            'CreateSnap3' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[3].x.[x]',
              'name' => 'VDS_snap_helper2',
              'snapshot' => 'create'
            },
            'CreateSnap4' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[4].x.[x]',
              'name' => 'VDS_snap_helper3',
              'snapshot' => 'create'
            },
            'CreateSnap5' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[5].x.[x]',
              'name' => 'VDS_snap_helper4',
              'snapshot' => 'create'
            },
            'CreateSnap6' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[6].x.[x]',
              'name' => 'VDS_snap_helper5',
              'snapshot' => 'create'
            },
            'RevertSnap1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1].x.[x]',
              'name' => 'VDS_snap_SUT',
              'snapshot' => 'revert'
            },
            'RevertSnap2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2].x.[x]',
              'name' => 'VDS_snap_helper1',
              'snapshot' => 'revert'
            },
            'RevertSnap3' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[3].x.[x]',
              'name' => 'VDS_snap_helper2',
              'snapshot' => 'revert'
            },
            'RevertSnap4' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[4].x.[x]',
              'name' => 'VDS_snap_helper3',
              'snapshot' => 'revert'
            },
            'RevertSnap5' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[5].x.[x]',
              'name' => 'VDS_snap_helper4',
              'snapshot' => 'revert'
            },
            'RevertSnap6' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[6].x.[x]',
              'name' => 'VDS_snap_helper5',
              'snapshot' => 'revert'
            }
          }
        },


        'JumboFrame' => {
          'Component' => 'vDS',
          'Category' => 'ESX Server',
          'TestName' => 'JumboFrame',
          'Summary' => 'Verify the function of vds with jumbo frames',
          'ExpectedResult' => 'PASS',
          'AutomationStatus'  => 'Automated',
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
                'SetMTU1'
              ],
              [
                'SetVMMTU1'
              ],
              [
                'NetperfTraffic'
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
            'SetMTU1' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '9000'
            },
            'SetVMMTU1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '9000'
            },
            'NetperfTraffic' => {
              'Type' => 'Traffic',
              'localsendsocketsize' => '131072',
              'toolname' => 'netperf',
              'testduration' => '60',
              'verificationadapter' => 'vm.[2].vnic.[1]',
              'testadapter' => 'vm.[1].vnic.[1]',
              'expectedresult' => 'PASS',
              'verificationresult' => 'PASS',
              'remotesendsocketsize' => '131072',
              'verification' => 'pktCap',
              'l4protocol' => 'tcp',
              'sendmessagesize' => '63488',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetVMMTU2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
              'mtu' => '1500'
            },
            'SetMTU2' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'mtu' => '1500'
            }
          }
        },
   );
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
   my $self = $class->SUPER::new(\%VDS);
   return (bless($self, $class));
}
