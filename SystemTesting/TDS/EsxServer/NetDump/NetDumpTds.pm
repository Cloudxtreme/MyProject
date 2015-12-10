#!/usr/bin/perl
#########################################################################
#Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetDump::NetDumpTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%NetDump = (
		'NetDump_vSS' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetDump_vSS',
		  'Summary' => 'Verify the Netdump Client with multiple vSS Configurations',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'vlan',
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
		          '[1-2]' => {
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
		        'host' => 'host.[2]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'SetNicTeaming'
		      ],
		      [
		        'ClientVLANSetting'
		      ],
		      [
		        'ServerVLANSetting'
		      ],
		      [
		        'NetdumpClientServerHello'
		      ],
		      [
		        'DeleteUplink2'
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
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'SetNicTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'setnicteaming' => 'add',
		      'failuredetection' => 'link',
		      'failback' => 'true',
		      'vmnicadapter' => 'host.[1].vmnic.[2]',
		      'lbpolicy' => 'mac',
		      'notifyswitch' => 'true'
		    },
		    'ClientVLANSetting' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[1].portgroup.[2]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
		    },
		    'ServerVLANSetting' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'host.[2].portgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
		    },
		    'DeleteUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[1].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'BackupHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdump' => 'backuphost'
		    },
		    'CleanupNetdumperLogs' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'sleepbetweenworkloads' => '100',
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
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetdumpClientInvalidConfiguration' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientInvalidConfiguration',
		  'Summary' => 'Validating the NetDumpClientConfiguration by giving improper ip & port and vmknic',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
		      ],
		      [
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'VmknicValidation'
		      ],
		      [
		        'IpValidation'
		      ],
		      [
		        'PortValidation'
		      ],
		      [
		        'SetCommandValidation'
		      ],
		      [
		        'EnableCommandValidation'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'VmknicValidation' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'name' => VDNetLib::TestData::TestConstants::INVALIDVMK,
		      'expectedresult' => 'FAIL',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'IpValidation' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => '0.0.0.0'
		    },
		    'PortValidation' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpsvrport' => 'abcde',
		      'netdump' => 'set',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'SetCommandValidation' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'EnableCommandValidation' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpstatus' => 'tru',
		      'netdump' => 'configure'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetdumpHostproiles_Negative' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpHostproiles_Negative',
		  'Summary' => 'Verifying a netdump Hostprofile withinvalid Netdump client\'s Configurationparameters',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VDS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableMaintenanceMode'
		      ],
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'CreateProfile'
		      ],
		      [
		        'EditNetdumpPolicyOptIP'
		      ],
		      [
		        'EditNetdumpPolicyOptPort'
		      ],
		      [
		        'EditNetdumpPolicyOptVMK'
		      ],
		      [
		        'AssociateProfile'
		      ],
		      [
		        'ApplyProfile'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ],
		      [
		        'DestroyProfile'
		      ],
		      [
		        'DisableMaintenanceMode'
		      ],
		    ],
                    'EnableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'true',
                    },
                    'DisableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'false',
                    },
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'CreateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'targetprofile' => 'testprofile',
		      'createprofile' => 'profile'
		    },
		    'EditNetdumpPolicyOptIP' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'profilecategory' => 'Network Coredump Settings',
		      'policyoption' => 'netdumpConfig.netdump.NetdumpProfilePolicyOption',
		      'policyparams' => 'Enabled:True,HostVNic:vmk0,NetworkServerIP:10.112.26.256,NetworkServerPort:6600',
		      'opt' => 'editpolicyopt',
		      'applyprofile' => 'NetworkProfile',
		      'testhost' => 'host.[2]',
		      'expectedresult' => 'FAIL',
		      'profiledevice' => 'Fixed Network Coredump Policy',
		      'policyid' => 'netdumpConfig.netdump.NetdumpProfilePolicy',
		      'targetprofile' => 'testprofile'
		    },
		    'EditNetdumpPolicyOptPort' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'profilecategory' => 'Network Coredump Settings',
		      'policyoption' => 'netdumpConfig.netdump.NetdumpProfilePolicyOption',
		      'policyparams' => 'Enabled:True,HostVNic:vmk0,NetworkServerIP:10.112.26.34,NetworkServerPort:67000',
		      'opt' => 'editpolicyopt',
		      'applyprofile' => 'NetworkProfile',
		      'testhost' => 'host.[2]',
		      'expectedresult' => 'FAIL',
		      'profiledevice' => 'Fixed Network Coredump Policy',
		      'policyid' => 'netdumpConfig.netdump.NetdumpProfilePolicy',
		      'targetprofile' => 'testprofile'
		    },
		    'EditNetdumpPolicyOptVMK' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'profilecategory' => 'Network Coredump Settings',
		      'policyoption' => 'netdumpConfig.netdump.NetdumpProfilePolicyOption',
		      'policyparams' => 'Enabled:True,HostVNic:vmk50,NetworkServerIP:10.112.26.72,NetworkServerPort:6600',
		      'opt' => 'editpolicyopt',
		      'applyprofile' => 'NetworkProfile',
		      'testhost' => 'host.[2]',
		      'profiledevice' => 'Fixed Network Coredump Policy',
		      'policyid' => 'netdumpConfig.netdump.NetdumpProfilePolicy',
		      'targetprofile' => 'testprofile'
		    },
		    'AssociateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'associateprofile' => 'testprofile'
		    },
		    'ApplyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'expectedresult' => 'FAIL',
		      'srchost' => 'host.[1]',
		      'applyprofile' => 'testprofile'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    },
		    'DestroyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'destroyprofile' => 'testprofile'
		    }
		  }
		},
		'NetdumpClientFunctionality_EndtoEnd' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientFunctionality_EndtoEnd',
		  'Summary' => 'Setting&Verifying NetDumpClientConfiguration',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'BAT,NeedPSOD,hostreboot,batnovc',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'UplinkParameter'
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
		      [
		        'NetdumpSetClientIP'
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
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'NetdumpSvrConfRevert'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
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
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'UplinkParameter' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmnic.[1]',
		      'auto' => 'Y',
		      'speed' => '10',
		      'duplex' => 'half'
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
		      'TestVM' => 'vm.[1]',
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
		      'TestVM' => 'vm.[1]',
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
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetdumpClientServerConnectivityCheck' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientServerConnectivityCheck',
		  'Summary' => 'Checking the Connectivity between theNetDumpClient-server by the Hellopackets on the specified port&interface',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'NetdumpClientServerHello'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetdumpSvrCorruptedConfig' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpSvrCorruptedConfig',
		  'Summary' => 'Verifying Behaviour of NetDumpServer when Configured with invalid port numbers',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'OutBoundPort'
		      ],
		      [
		        'PrevillagedPort'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpSvrConfRevert'
		      ],
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'OutBoundPort' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '-1',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'PrevillagedPort' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '80',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSvrConfRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetdumpClientFunctionality_Firewall' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientFunctionality_Firewall',
		  'Summary' => 'Verifying NetDump functionality whenFirewall is enabled on netdumpserver',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'NeedPSOD,hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'DisableFirewallonsvr'
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
		      ]
		    ],
		    'ExitSequence' => [
                      [
	                'NetdumpDisable'
	              ],
	              [
	                'HotRemovevnic'
	              ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'EnableFirewallonsvr' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'serviceaction' => 'start',
		      'operation' => 'configureservice',
		      'servicename' => 'firewall'
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
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'sleepbetweenworkloads' => '40',
		      'netdumpclientip' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'DisableFirewallonsvr' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'serviceaction' => 'stop',
		      'operation' => 'configureservice',
		      'servicename' => 'firewall'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'Network' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'Network',
		  'Summary' => 'Verify the behavior when a clienttries to dump a core over networkand the network link is broken',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'NeedPSOD,hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpGeneratePanicReboot',
		        'BrokenUplink'
		      ],
		      [
		        'NetdumpServerDumpCheck'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'operation' => 'netdumpesxclicheck'
		    },
		    'BackupHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdump' => 'backuphost'
		    },
		    'CleanupNetdumperLogs' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'BrokenUplink' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'host.[2].vss.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[2].vmnic.[1]'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'FAIL',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'netdumpclient' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetDump_vDs' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetDump_vDs',
		  'Summary' => 'Verify the Netdump Client withmultiple vDS Configurations',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'vlan',
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
		      '[1]' => {
		        'vmnic' => {
		          '[1]' => {
		            'driver' => 'any'
		          },
		          '[2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vmknic' => {
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
		      },
		      '[2]' => {
		        'vmnic' => {
		          '[1]' => {
		            'driver' => 'any'
		          },
		          '[2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vmknic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[2]'
		          }
		        },
		        'vss' => {
		          '[1]' => {}
		        },
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
		          }
		        }
		      }
		    },
		    'vm' => {
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
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
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'AddUplink2'
		      ],
		      [
		        'SetNicTeaming'
		      ],
		      [
		        'ClientVLANSetting'
		      ],
		      [
		        'ServerVLANSetting'
		      ],
                      [
                        'NetdumpClientServerHello'
                      ],
		      [
		        'DeleteUplink2'
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
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'AddUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'SetNicTeaming' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'true',
		      'lbpolicy' => 'mac',
		      'failover' => 'beaconprobing',
		      'notifyswitch' => 'true',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ClientVLANSetting' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
		    },
		    'ServerVLANSetting' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B
		    },
		    'DeleteUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
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
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
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
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetdumpClientvmknicRobustness' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientvmknicRobustness',
		  'Summary' => 'Verifying NetDumpClient\'s vmknicRobustness',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpVerifyClient_enable'
		      ],
		      [
		        'RobustnessCheck'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient_enable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'RobustnessCheck' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'expectedresult' => 'FAIL',
		      'netdump' => 'deletenetdumpvmk',
		      'testadapter' => 'host.[1].vmknic.[1]'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'WinNetdumpSvrChangeDebugLevel' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'WinNetdumpSvrChangeDebugLevel',
		  'Summary' => 'Verifying Behaviour of NetDumpServer when Configured with invalid Debuglevel',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'NetdumpClientServerHello'
		      ],
		      [
		        'InvalidLogLevel'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'RevertLogLevel'
		      ],
		      [
		        'NetdumpDisable'
		      ],
#		      [
#		        'HotRemovevnic'
#		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'InvalidLogLevel' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'FAIL',
		      'netdumpparam' => 'level',
		      'netdumpvalue' => '-2',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'RevertLogLevel' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
                      'netdumpparam' => 'level',
		      'netdumpvalue' => '2',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'DifferentServicesOnSamePort' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'DifferentServicesOnSamePort',
		  'Summary' => 'Verifying Behaviour of NetDumpServer when we start otherservice on same port thatnetdumpserver is using',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'StopNetdumpService'
		      ],
		      [
                        'NetperfUDP',
		        'VerifyNetdumpService'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'StartNetdumpService'
		      ],
		      [
		        'NetdumpSvrConfRevert'
		      ],
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
          	    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6501',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6501',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6501',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'StopNetdumpService' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'action' => 'stop',
		      'iterations' => '1',
		      'operation' => 'netdumperservice'
		    },
		    'NetperfUDP' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'bindingenable' => '0',
		      'l4protocol' => 'UDP',
		      'toolname' => 'Iperf',
		      'testduration' => '250',
		      'portnumber' => '6501',
		      'bursttype' => 'stream',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'VerifyNetdumpService' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'sleepbetweenworkloads' => '120',
		      'action' => 'start',
		      'iterations' => '1',
		      'operation' => 'netdumperservice'
		    },
		    'StartNetdumpService' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'action' => 'start',
		      'iterations' => '1',
		      'operation' => 'netdumperservice'
		    },
		    'NetdumpSvrConfRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetdumpClientSideFunctional' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpClientSideFunctional',
		  'Summary' => 'Setting&Verifying NetDumpClient Configuration',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpVerifyClient_enable'
		      ],
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'NetdumpVerifyClient_disable'
		      ],
		      [
		        'NetdumpSetClientParams'
		      ],
		      [
		        'NetdumpEnable'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'NetdumpVerifyClient_enable'
		      ],
		      [
		        'NetdumpDisable'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient_enable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient_disable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'false',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'reboot' => 'yes'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetdumpSvrCoreLogPathChange' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpSvrCoreLogPathChange',
		  'Summary' => 'Verify the behavior when the loglocationand corelocation is changed from default',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'NeedPSOD,hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'ChangeLoglocation'
		      ],
		      [
		        'VerifyLogTemplocation'
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
		      [
		        'UnChangeLoglocation'
		      ],
		      [
		        'VerifyOriginLoglocation'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'ChangeLoglocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'changepath',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'VerifyLogTemplocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'temppath',
		      'iterations' => '1',
		      'operation' => 'verifynetdumperconfig'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'operation' => 'netdumpesxclicheck'
		    },
		    'BackupHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdump' => 'backuphost'
		    },
		    'CleanupNetdumperLogs' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'netdumpclientip' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'UnChangeLoglocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'revertpath',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'VerifyOriginLoglocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'originalpath',
		      'iterations' => '1',
		      'operation' => 'verifynetdumperconfig'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetDump_LogReadOnly' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetDump_LogReadOnly',
		  'Summary' => 'Verifying the Netdump FunctionalityWhen Server\'s Log file is ReadOnly',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpSvrConfChange'
		      ],
		      [
		        'NetdumpSvrConfEditFail'
		      ],
		      [
		        'NetdumpSvrConfRevert'
		      ],
		      [
		        'NetdumpSvrConfEditSuccess'
		      ],
		      [
		        'NetdumpClientServerHelloSuccess'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpSvrConfRevert'
		      ],
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpSvrConfChange' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'readonly',
		      'iterations' => '1',
		      'operation' => 'logpathpermissions'
		    },
		    'NetdumpSvrConfEditFail' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSvrConfRevert' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'readwrite',
		      'iterations' => '1',
		      'operation' => 'logpathpermissions'
		    },
		    'NetdumpSvrConfEditSuccess' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpClientServerHelloSuccess' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'StatefulConfigPersistenceCheck' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'StatefulConfigPersistenceCheck',
		  'Summary' => 'Setting&Verifying Stateful NetDumpClient Configuration',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'NetdumpVerifyClient_enable'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'NetdumpVerifyClient_enable'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient_enable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'reboot' => 'yes'
		    },
		    'NetdumpVerifyClient_disable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'false',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
                'ConcurrentNetdumpClientSessions' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'ConcurrentNetdumpClientSessions',
		  'Summary' => 'Validating a random number of concurrent netdump session that could be handledby the Netdump server',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'NeedPSOD,hostreboot',
		  'Version' => '2',
		  'TestbedSpec' => {
		    'host' => {
		      '[3]' => {
		        'portgroup' => {
		          '[2]' => {
		            'vss' => 'host.[3].vss.[1]'
		          },
		          '[1]' => {
		            'vss' => 'host.[3].vss.[1]'
		          }
		        },
		        'vss' => {
		          '[1]' => {
		            'configureuplinks' => 'add',
		            'vmnicadapter' => 'host.[3].vmnic.[1]'
		          }
		        },
		        'vmnic' => {
		          '[1-2]' => {
		            'driver' => 'any'
		          }
		        },
		        'vmknic' => {
		          '[1]' => {
		            'portgroup' => 'host.[3].portgroup.[2]'
		          }
		        }
		      },
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
		          '[1-2]' => {
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
		        'host' => 'host.[2]'
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClient1IP'
		      ],
		      [
		        'NetdumpSetServerIP'
		      ],
		      [
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'NetdumpSetClient1Params'
		      ],
		      [
		        'NetdumpSetClient2IP'
		      ],
		      [
		        'NetdumpSetClient2Params'
		      ],
		      [
		        'NetdumpEnable1'
		      ],
		      [
		        'NetdumpEnable2'
		      ],
		      [
		        'NetdumpVerifyClient1'
		      ],
		      [
		        'NetdumpVerifyClient2'
		      ],
		      [
		        'NetdumpClient1ServerHello'
		      ],
		      [
		        'BackupSUT'
		      ],
		      [
		        'NetdumpClient2ServerHello'
		      ],
		      [
		        'Backuphelper1'
		      ],
		      [
		        'CleanupNetdumperLogs'
		      ],
		      [
		        'NetdumpGeneratePanicReboot1',
		        'NetdumpGeneratePanicReboot2'
		      ],
		      [
		        'NetdumpServerDumpCheck1'
		      ],
		      [
		        'NetdumpServerDumpCheck2'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable1'
		      ],
		      [
		        'NetdumpDisable2'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'Iterations' => 1,
		    'NetdumpSetClient1IP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClient1Params' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpSetClient2IP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[3].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetClient2Params' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[3].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpEnable2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpVerifyClient2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'testadapter' => 'host.[3].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClient1ServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'BackupSUT' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdump' => 'backuphost'
		    },
		    'NetdumpClient2ServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'Backuphelper1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'netdump' => 'backuphost'
		    },
		    'CleanupNetdumperLogs' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpGeneratePanicReboot2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck1' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'netdumpclientip' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'NetdumpServerDumpCheck2' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'clientadapter' => 'host.[3].vmknic.[1]',
		      'netdumpclientip' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'NetdumpDisable1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'NetdumpDisable2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[3]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


		'NetdumpHostprofiles_Positive' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpHostprofiles_Positive',
		  'Summary' => 'Performing HostProfiles operationsRegarding Netdump',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VDS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'EnableMaintenanceMode'
		      ],
		      [
		        'NetdumpSetClient1IP'
		      ],
		      [
		        'NetdumpSvrConfEdit'
		      ],
		      [
		        'NetdumpSetServerIP'
		      ],
		      [
		        'NetdumpSetClient1Params'
		      ],
		      [
		        'NetdumpEnable'
		      ],
		      [
		        'NetdumpVerifyClient1'
		      ],
		      [
		        'CreateProfile'
		      ],
		      [
		        'EditNetdumpPolicyOpt'
		      ],
		      [
		        'AssociateProfile'
		      ],
		      [
		        'CheckCompliance'
		      ],
		      [
		        'ApplyProfile'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisableonSUT'
		      ],
		      [
		        'HotRemovevnic'
		      ],
		      [
		        'DestroyProfile'
		      ],
		      [
		        'DisableMaintenanceMode'
		      ],
		    ],
                    'EnableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'true',
                    },
                    'DisableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'false',
                    },
		    'NetdumpSetClient1IP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetClient1Params' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
		    },
		    'NetdumpEnable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'true',
		      'netdump' => 'configure'
		    },
		    'NetdumpVerifyClient1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpstatus' => 'true',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'CreateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'targetprofile' => 'testprofile',
		      'createprofile' => 'profile'
		    },
		    'EditNetdumpPolicyOpt' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'profilecategory' => 'Network Coredump Settings',
		      'policyoption' => 'netdumpConfig.netdump.NetdumpProfilePolicyOption',
		      'policyparams' => 'Enabled:True,HostVNic:vmk0,NetworkServerIP:10.111.7.153,NetworkServerPort:6510',
		      'opt' => 'editpolicyopt',
		      'applyprofile' => 'NetworkProfile',
		      'testhost' => 'host.[2]',
		      'profiledevice' => 'Fixed Network Coredump Policy',
		      'policyid' => 'netdumpConfig.netdump.NetdumpProfilePolicy',
		      'targetprofile' => 'testprofile'
		    },
		    'AssociateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'associateprofile' => 'testprofile'
		    },
		    'CheckCompliance' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'compliancestatus' => 'compliant',
		      'checkcompliance' => 'testprofile'
		    },
		    'ApplyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'applyprofile' => 'testprofile'
		    },
		    'NetdumpDisableonSUT' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    },
		    'DestroyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'destroyprofile' => 'testprofile'
		    }
		  }
		},
		'NetdumpFailure_Hostprofiles' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpFailure_Hostprofiles',
		  'Summary' => 'Verify applying a netdump hostprofilewith valid but ineffective netdumpserver ip address',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'NeedPSOD,hostreboot',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VDS,
		  'WORKLOADS' => {
		    'Sequence' => [
                      [
                        'EnableMaintenanceMode'
                      ],

		      [
		        'NetdumpSetClientsIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'CreateProfile'
		      ],
		      [
		        'AssociateProfile'
		      ],
		      [
		        'CheckCompliance'
		      ],
		      [
		        'ApplyProfile'
		      ],
		      [
		        'StopNetdumpService'
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
		        'StopNetdumpService'
		      ],
		      [
		        'NetdumpGeneratePanicReboot'
		      ],
		      [
		        'NetdumpServerDumpCheck'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'StartNetdumpService'
		      ],
		      [
		        'NetdumpDisableonSUT'
		      ],
		      [
		        'DestroyProfile'
		      ],
		      [
		        'HotRemovevnic'
		      ],
                      [
                        'DisableMaintenanceMode'
                      ],
		    ],
                    'EnableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'true',
                    },
                    'DisableMaintenanceMode' => {
                       'Type'           => 'Host',
                       'TestHost'       => 'host.[1]',
                       'maintenancemode' => 'false',
                   },
		    'NetdumpSetClientsIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'CreateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'targetprofile' => 'testprofile',
		      'createprofile' => 'profile'
		    },
		    'AssociateProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'associateprofile' => 'testprofile'
		    },
		    'CheckCompliance' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'compliancestatus' => 'compliant',
		      'checkcompliance' => 'testprofile'
		    },
		    'ApplyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'srchost' => 'host.[1]',
		      'applyprofile' => 'testprofile'
		    },
		    'StopNetdumpService' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'action' => 'stop',
		      'iterations' => '1',
		      'operation' => 'netdumperservice'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'expectedresult' => 'FAIL',
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
		      'TestVM' => 'vm.[1]',
		      'operation' => 'cleanupnetdumperlogs'
		    },
		    'NetdumpGeneratePanicReboot' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'paniclevel' => '1',
		      'panictype' => 'normal',
		      'netdump' => 'panicandreboot'
		    },
		    'NetdumpServerDumpCheck' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'FAIL',
		      'clientadapter' => 'host.[1].vmknic.[1]',
		      'netdumpclient' => 'AUTO',
		      'iterations' => '1',
		      'operation' => 'checknetdumpstatus'
		    },
		    'StartNetdumpService' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'expectedresult' => 'PASS',
		      'action' => 'start',
		      'iterations' => '1',
		      'operation' => 'netdumperservice'
		    },
		    'NetdumpDisableonSUT' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'DestroyProfile' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1]',
		      'destroyprofile' => 'testprofile'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},
		'NetdumpSvrCoreLogPathVerify' => {
		  'Component' => 'NetDump',
		  'Category' => 'ESX Server',
		  'TestName' => 'NetdumpSvrCoreLogPathVerify',
		  'Summary' => 'Verifying NetDumpServer ConfigurationSettings like log path, Data path',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'sanity',
		  'Version' => '2',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::Netdump_VSS,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'NetdumpSetClientIP'
		      ],
		      [
		        'NetdumpSetServerIP'
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
		        'VerifyOriginCorelocation'
		      ],
		      [
		        'VerifyOriginLoglocation'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'NetdumpDisable'
		      ],
		      [
		        'HotRemovevnic'
		      ]
		    ],
		    'NetdumpSetClientIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmknic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSetServerIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'AUTO'
		    },
		    'NetdumpSvrConfEdit' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'port',
		      'netdumpvalue' => '6510',
		      'iterations' => '1',
		      'operation' => 'configurenetdumpserver'
		    },
		    'NetdumpSetClientParams' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpsvrport' => '6510',
		      'netdump' => 'set',
		      'testadapter' => 'host.[1].vmknic.[1]',
		      'netdumpsvrip' => 'AUTO',
		      'supportadapter' => 'vm.[1].vnic.[1]'
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
		      'netdumpsvrport' => '6510',
		      'netdump' => 'verifynetdumpclient',
		      'supportadapter' => 'vm.[1].vnic.[1]',
		      'netdumpsvrip' => 'AUTO'
		    },
		    'NetdumpClientServerHello' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'iterations' => '1',
		      'netdump' => 'netdumpesxclicheck'
		    },
		    'VerifyOriginCorelocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'corepath',
		      'netdumpvalue' => 'originalpath',
		      'iterations' => '1',
		      'operation' => 'verifynetdumperconfig'
		    },
		    'VerifyOriginLoglocation' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'netdumpparam' => 'logpath',
		      'netdumpvalue' => 'originalpath',
		      'iterations' => '1',
		      'operation' => 'verifynetdumperconfig'
		    },
		    'NetdumpDisable' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'netdumpstatus' => 'false',
		      'netdump' => 'configure'
		    },
		    'HotRemovevnic' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'deletevnic' => 'vm.[1].vnic.[1]'
		    }
		  }
		},


   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for NetDump.
#
# Input:
#       None.
#
# Results:
#       An instance/object of NetDump class.
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
   my $self = $class->SUPER::new(\%NetDump);
   return (bless($self, $class));
}
