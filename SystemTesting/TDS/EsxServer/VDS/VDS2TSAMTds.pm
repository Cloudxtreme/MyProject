#!/usr/bin/perl
################################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
################################################################################
package TDS::EsxServer::VDS::VDS2TSAMTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %VDS2TSAM = (
		'VDS2EsxcliDVFilter' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'Esxcli',
		  'TestName' => 'VDS2EsxcliDVFilter',
		  'Summary' => 'Check whether the esxcli command for listing the ' .
		               'network port filter stats for DVPorts in VMs returns' .
		               ' the desired output',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_TwoVM,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['PowerOff'],
		      ['HostOperation_1'],
		      ['HostOperation_2'],
		      ['PowerOn'],
		      ['SetSUTTestNicIP'],
		      ['SetHelperTestNicIP'],
		      ['UnBlockTCP'],
		      ['NetperfTraffic1',
		       'MonitorDVFilterStats']
		    ],
		    'Duration' => 'time in seconds',
		    'PowerOff' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'poweroff'
		    },
		    'HostOperation_1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
		    },
		    'HostOperation_2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
		      'adapters' => 'vm.[1].vnic.[1]'
		    },
		    'PowerOn' => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vmstate' => 'poweron'
		    },
		    'SetSUTTestNicIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'ipv4' => 'auto'
		    },
		    'SetHelperTestNicIP' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'ipv4' => 'auto'
		    },
		    'UnBlockTCP' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'dvfilterctl' => 'dvfilter-generic',
		      'dvfilterconfigspec' => {
		         'inbound' => 0,
		         'udp' => 0,
		         'outbound' => 0,
		         'tcp' => 0,
		         'icmp' => 0
            },
		      'vm' => 'vm.[1]'
		    },
		    'NetperfTraffic1' => {
		      'Type' => 'Traffic',
		      'l4protocol' => 'tcp',
		      'testduration' => '360',
		      'portnumber' => '12865',
		      'toolname' => 'netperf',
		      'noofinbound' => '1',
		      'bursttype' => 'RR'
		    },
		    'MonitorDVFilterStats' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'sleepbetweenworkloads' => '360',
                      'check_dvfilter_packet' => {
                        'switch' => 'vc.[1].vds.[1]',
                      },
		    }
		  }
		},


		'VDS2TSAMTeaming' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'HealthcheckTSAM',
		  'TestName' => 'VDS2TSAMTeaming',
		  'Summary' => 'Verifying whether Healthcheck works with all modes of ' .
		               'NicTeaming except for IPHash',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_ThreeDVPG_TwoHost_TwoVmnicForEachHost_PSwitch,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['GetPortRunConfigSUT1'],
		      ['GetPortRunConfigSUT2'],
		      ['GetPortRunConfigHelper1'],
		      ['GetPortRunConfigHelper2'],
		      ['AddNativeVLAN'],
		      ['SetupHealthcheckTestbedSUT1'],
		      ['SetupHealthcheckTestbedSUT2'],
		      ['SetupHealthcheckTestbedHelper1'],
		      ['SetupHealthcheckTestbedHelper2'],
		      ['AddUplinkSUT'],
		      ['AddUplinkHelper'],
		      ['SetNICTeamingSrcID'],
		      ['SetTeamchk'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingSrcMACSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingpNICLoadSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingFOExplicitSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingFORollingSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingFOExplicitBeaconSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['SetNICTeamingFORollingBeaconSUT'],
		      ['CheckTeamchkMatchSUT1'],
		      ['CheckTeamchkMatchHelper1'],
		      ['ConfigureChannelGroupSUT1'],
		      ['ConfigureChannelGroupSUT2'],
		      ['ConfigureChannelGroupHelper1'],
		      ['ConfigureChannelGroupHelper2'],
		      ['CheckTeamchkMatchSUT2'],
		      ['CheckTeamchkMatchHelper2']
		    ],
		    'ExitSequence' => [
		      ['RemoveChannelGroupSUT1'],
		      ['RemoveChannelGroupSUT2'],
		      ['RemoveChannelGroupHelper1'],
		      ['RemoveChannelGroupHelper2'],
		      ['SetPortRunConfigSUT1'],
		      ['SetPortRunConfigSUT2'],
		      ['SetPortRunConfigHelper1'],
		      ['SetPortRunConfigHelper2'],
		      ['RemoveChannelGroup1'],
		      ['RemoveChannelGroup2']
		    ],
		    'GetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'AddNativeVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Add',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'AddUplinkSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'AddUplinkHelper' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'SetNICTeamingSrcID' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'portid',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetTeamchk' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'teaming',
		         'interval' => '1',
		         'operation' => 'Enable',
		      },
		    },
		    'CheckTeamchkMatchSUT1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'CheckTeamchkMatchHelper1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'SetNICTeamingSrcMACSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'mac',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetNICTeamingpNICLoadSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'loadbalance_loadbased',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetNICTeamingFOExplicitSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lbpolicy' => 'failover_explicit',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetNICTeamingFORollingSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'failover_explicit',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetNICTeamingFOExplicitBeaconSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lbpolicy' => 'failover_explicit',
		      'failover' => 'beaconprobing',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'SetNICTeamingFORollingBeaconSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'failover_explicit',
		      'failover' => 'beaconprobing',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ConfigureChannelGroupSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'mode' => 'On',
		      'configurechannelgroup' => '1'
		    },
		    'ConfigureChannelGroupSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'mode' => 'On',
		      'configurechannelgroup' => '1'
		    },
		    'ConfigureChannelGroupHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'mode' => 'On',
		      'configurechannelgroup' => '2'
		    },
		    'ConfigureChannelGroupHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'mode' => 'On',
		      'configurechannelgroup' => '2'
		    },
		    'CheckTeamchkMatchSUT2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'CheckTeamchkMatchHelper2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'RemoveChannelGroupSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'configurechannelgroup' => 'No'
		    },
		    'RemoveChannelGroupSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'configurechannelgroup' => 'No'
		    },
		    'RemoveChannelGroupHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'configurechannelgroup' => 'No'
		    },
		    'RemoveChannelGroupHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'configurechannelgroup' => 'No'
		    },
		    'SetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    },
		    'RemoveChannelGroup1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'removeportchannel' => '1'
		    },
		    'RemoveChannelGroup2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'removeportchannel' => '2'
		    }
		  }
		},


		'VDS2EsxcliVSTVLAN' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'Esxcli',
		  'TestName' => 'VDS2EsxcliVSTVLAN',
		  'Summary' => 'Check whether the esxcli command for listing a per-VLAN' .
		               ' packet breakdown on a NIC with running traffic through ' .
		               'it returns the desired output, when the DVPortGroup is ' .
		               'VLAN tagged',
		  'ExpectedResult' => undef,
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_TwoVM,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['SetVLAN1'],
		      ['NetperfTraffic1',
		       'MonitorVSTVLANPkt']
		    ],
		    'ExitSequence' => [
		      ['SetVLAN2']
		    ],
		    'Duration' => 'time in seconds',
		    'SetVLAN1' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
		    },
		    'NetperfTraffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp',
		      'testduration' => '300',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'MonitorVSTVLANPkt' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
                      'check_vlan_packet' => {
                        'adapter' => 'host.[1].vmnic.[1]',
                        'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                      },
		      'sleepbetweenworkloads' => '120',
		    },
		    'SetVLAN2' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    }
		  }
		},


		'VDS2TSAMEtherChannelTeaming' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'HealthcheckTSAM',
		  'TestName' => 'VDS2TSAMEtherChannelTeaming',
		  'Summary' => 'Verifying whether Healthcheck works with Ether channel ' .
		               'teaming so as to detect a match between server and ' .
		               'switch when etherchannel is configured with IP Hash ' .
		               'teaming policy on the other end',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_ThreeDVPG_TwoHost_TwoVmnicForEachHost_PSwitch,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['GetPortRunConfig'],
		      ['AddNativeVLAN'],
		      ['SetupHealthcheckTestbed'],
                      #['SetMTU'],
		      ['AddUplink1'],
		      ['AddUplink2'],
		      ['SetNICTeamingIPHash'],
		      ['SetTeamchk'],
		      ['CheckTeamchkMisMatch'],
		      ['RemoveUplink1'],
		      ['RemoveUplink2'],
		      ['AddUplink1'],
		      ['AddUplink2'],
		      ['ConfigureChannelGroup1'],
		      ['ConfigureChannelGroup2'],
		      ['CheckTeamchkMatch'],
		    ],
		    'ExitSequence' => [
		      ['RemovePortsFromChannelGroup'],
		      ['SetPortRunConfig'],
		      ['RemoveChannelGroup'],
		    ],
		    'GetPortRunConfig' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[-1].pswitchport.[-1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'AddNativeVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Add',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A,
		    },
		    'SetupHealthcheckTestbed' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[-1].pswitchport.[-1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A,
		    },
		    'SetMTU' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[-1].pswitchport.[-1]',
		      'mtu'      => '9000',
		    },
		    'AddUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'AddUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'RemoveUplink1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'RemoveUplink2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'SetNICTeamingIPHash' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'failback' => 'yes',
		      'lbpolicy' => 'iphash',
		      'notifyswitch' => 'yes',
		      'confignicteaming' => 'vc.[1].dvportgroup.[-1]'
		    },
		    'SetTeamchk' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'teaming',
		         'interval' => '1',
		         'operation' => 'Enable',
		      },
		    },
		    'CheckTeamchkMisMatch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1-2]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'ConfigureChannelGroup1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[-1]',
		      'mode' => 'On',
		      'configurechannelgroup' =>
                   VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
		    },
		    'ConfigureChannelGroup2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[-1]',
		      'mode' => 'On',
		      'configurechannelgroup' =>
                   VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
		    },
		    'CheckTeamchkMatch' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1-2]',
		      'check_teaming_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'RemovePortsFromChannelGroup' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[-1].pswitchport.[-1]',
		      'configurechannelgroup' => 'No'
		    },
		    'SetPortRunConfig' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[-1].pswitchport.[-1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'RemoveChannelGroup' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
                'removeportchannel' =>
                   VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                   VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
		    },
		  }
		},

		'VDS2TSAMVLANMTUCheck' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'HealthcheckTSAM',
		  'TestName' => 'VDS2TSAMVLANMTUCheck',
		  'Summary' => 'Verifying whether Healthcheck works with VLANMTU checks ' .
		               'between servers and physical switch connections',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_ThreeDVPG_TwoHost_TwoVmnicForEachHost_PSwitch,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['GetPortRunConfigSUT1'],
		      ['GetPortRunConfigSUT2'],
		      ['GetPortRunConfigHelper1'],
		      ['GetPortRunConfigHelper2'],
		      ['AddNativeVLAN'],
		      ['SetupHealthcheckTestbedSUT1'],
		      ['SetupHealthcheckTestbedSUT2'],
		      ['SetupHealthcheckTestbedHelper1'],
		      ['SetupHealthcheckTestbedHelper2'],
		      ['AddUplinkSUT1'],
		      ['AddUplinkHelper1'],
		      ['AddUplinkSUT2'],
		      ['AddUplinkHelper2'],
		      ['AddVLAN'],
		      ['SetVLANMTUCheck'],
		      ['ChangeVLANMTUParamSUT'],
		      ['ChangeVLANMTUParamHelper'],
		      ['CheckVLANMTUTrunkResultSUT1'],
		      ['CheckVLANMTUTrunkResultHelper1'],
		      ['CheckVLANMTUTrunkResultSUT2'],
		      ['CheckVLANMTUTrunkResultHelper2'],
		      ['RemoveUplinkSUT1'],
		      ['RemoveUplinkHelper1'],
		      ['RemoveUplinkSUT2'],
		      ['RemoveUplinkHelper2'],
		      ['AddUplinkSUT2'],
		      ['AddUplinkHelper2'],
		      ['AddUplinkSUT1'],
		      ['AddUplinkHelper1'],
		      ['ChangeVLANMTUParamSUT'],
		      ['ChangeVLANMTUParamHelper'],
		      ['CheckVLANMTUTrunkResultSUT1'],
		      ['CheckVLANMTUTrunkResultHelper1'],
		      ['CheckVLANMTUTrunkResultSUT2'],
		      ['CheckVLANMTUTrunkResultHelper2']
		    ],
		    'ExitSequence' => [
		      ['RemoveVLAN'],
		      ['SetPortRunConfigSUT1'],
		      ['SetPortRunConfigSUT2'],
		      ['SetPortRunConfigHelper1'],
		      ['SetPortRunConfigHelper2']
		    ],
		    'GetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'AddNativeVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Add',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'AddUplinkSUT1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'AddUplinkHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[2].vmnic.[1]'
		    },
		    'AddVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Add',
		      'vlan' => '200to205'
		    },
		    'SetVLANMTUCheck' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'vlanmtu',
		         'interval' => '1',
		         'operation' => 'Enable',
		      },
		    },
		    'ChangeVLANMTUParamSUT' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'vlanmtu',
		         'trunked_vlans' => '200to210',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'ChangeVLANMTUParamHelper' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'vlanmtu',
		         'trunked_vlans' => '200to210',
		         'switch' => 'vc.[1].vds.[1]',
		      },
		    },
		    'CheckVLANMTUTrunkResultSUT1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_healthcheck_vlanmtu' => {
		         'trunked_vlans' => '200to205',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[1]',
		         'untrunked_vlans' => '206to210',
		      },
		    },
		    'CheckVLANMTUTrunkResultHelper1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_healthcheck_vlanmtu' => {
		         'trunked_vlans' => '200to205',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[1]',
		         'untrunked_vlans' => '206to210',
		      },
		    },
		    'CheckVLANMTUTrunkResultSUT2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_healthcheck_vlanmtu' => {
		         'trunked_vlans' => '200to205',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[2]',
		         'untrunked_vlans' => '206to210',
		      },
		    },
		    'CheckVLANMTUTrunkResultHelper2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_healthcheck_vlanmtu' => {
		         'trunked_vlans' => '200to205',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[2]',
		         'untrunked_vlans' => '206to210',
		      },
		    },
		    'RemoveUplinkSUT1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[1]'
		    },
		    'RemoveUplinkHelper1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[2].vmnic.[1]'
		    },
		    'RemoveUplinkSUT2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'RemoveUplinkHelper2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'remove',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'AddUplinkSUT2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'AddUplinkHelper2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'RemoveVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Remove',
		      'vlan' => '200to205'
		    },
		    'SetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    }
		  }
		},


		'VDS2TSAMCheckFramework' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'HealthcheckTSAM',
		  'TestName' => 'VDS2TSAMCheckFramework',
		  'Summary' => 'Verifying whether healthcheck framework has been loaded' .
		               ' in the server correctly',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['CheckHealthcheckModule']
		    ],
		    'CheckHealthcheckModule' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'checkhealthcheckmodule' => 'true'
		    }
		  }
		},


		'VDS2TSAMMTUCheck' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'HealthcheckTSAM',
		  'TestName' => 'VDS2TSAMMTUCheck',
		  'Summary' => 'Verifying whether Healthcheck works with MTU checks ' .
		               'between servers and physical switch connections',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_ThreeDVPG_TwoHost_TwoVmnicForEachHost_PSwitch,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['GetPortRunConfigSUT1'],
		      ['GetPortRunConfigSUT2'],
		      ['GetPortRunConfigHelper1'],
		      ['GetPortRunConfigHelper2'],
		      ['AddNativeVLAN'],
		      ['SetupHealthcheckTestbedSUT1'],
		      ['SetupHealthcheckTestbedSUT2'],
		      ['SetupHealthcheckTestbedHelper1'],
		      ['SetupHealthcheckTestbedHelper2'],
		      ['AddUplinkSUT'],
		      ['AddUplinkHelper'],
		      ['SetVLANMTUCheck'],
		      ['SetMTUSUT'],
		      ['SetMTUHelper'],
		      ['CheckLocalMTUMatchSUT1'],
		      ['CheckLocalMTUMatchSUT2'],
		      ['CheckLocalMTUMatchHelper1'],
		      ['CheckLocalMTUMatchHelper2'],
		      ['SetMTU3'],
		      ['SetMTU4'],
		      ['CheckLocalMTUMatchSUT3'],
		      ['CheckLocalMTUMatchSUT4'],
		      ['CheckLocalMTUMatchHelper3'],
		      ['CheckLocalMTUMatchHelper4']
		    ],
		    'ExitSequence' => [
		      ['SetMTU3'],
		      ['SetMTU4'],
		      ['SetPortRunConfigSUT1'],
		      ['SetPortRunConfigSUT2'],
		      ['SetPortRunConfigHelper1'],
		      ['SetPortRunConfigHelper2']
		    ],
		    'GetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'getportrunningconfiguration' => '1'
		    },
		    'GetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'getportrunningconfiguration' => '1'
		    },
		    'AddNativeVLAN' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'configure_vlan' => 'Add',
		      'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'SetupHealthcheckTestbedHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setupnativetrunkvlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A
		    },
		    'AddUplinkSUT' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[1].vmnic.[2]'
		    },
		    'AddUplinkHelper' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configureuplinks' => 'add',
		      'vmnicadapter' => 'host.[2].vmnic.[2]'
		    },
		    'SetVLANMTUCheck' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_healthcheck' => {
		         'healthcheck_type' => 'vlanmtu',
		         'interval' => '1',
		         'operation' => 'Enable',
		      },
		    },
		    'SetMTUSUT' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1].vmnic.[1-2]',
		      'mtu' => '9000'
		    },
		    'SetMTUHelper' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[2].vmnic.[1-2]',
		      'mtu' => '9000'
		    },
		    'CheckLocalMTUMatchSUT1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[1]',
		      },
		    },
		    'CheckLocalMTUMatchSUT2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[2]',
		      },
		    },
		    'CheckLocalMTUMatchHelper1' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[1]',
		      },
		    },
		    'CheckLocalMTUMatchHelper2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MISMATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[2]',
		      },
		    },
		    'SetMTU3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1-2].vmnic.[1]',
		      'mtu' => '1500'
		    },
		    'SetMTU4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'host.[1-2].vmnic.[2]',
		      'mtu' => '1500'
		    },
		    'CheckLocalMTUMatchSUT3' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[1]',
		      },
		    },
		    'CheckLocalMTUMatchSUT4' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[1].vmnic.[2]',
		      },
		    },
		    'CheckLocalMTUMatchHelper3' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[1]',
		      },
		    },
		    'CheckLocalMTUMatchHelper4' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2].x.[x]',
		      'check_localmtu_match' => {
		         'expected_match_result' => 'MATCH',
		         'switch' => 'vc.[1].vds.[1]',
		         'vmnicadapter' => 'host.[2].vmnic.[2]',
		      },
		    },
		    'SetPortRunConfigSUT1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigSUT2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper1' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[1]',
		      'setportrunningconfiguration' => '1'
		    },
		    'SetPortRunConfigHelper2' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[2].pswitchport.[2]',
		      'setportrunningconfiguration' => '1'
		    }
		  }
		},


		'VDS2EsxcliInterhostTraffic' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'Esxcli',
		  'TestName' => 'VDS2EsxcliInterhostTraffic',
		  'Summary' => 'Check whether the esxcli command for listing the ' .
		               'network port statistics in VMs with running traffic ' .
		               'returns the desired output',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_TwoVM,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['NetperfTraffic1',
		       'MonitorPortStats'],
		      ['NetperfTraffic1',
		       'MonitorVmnicStats']
		    ],
		    'Duration' => 'time in seconds',
		    'NetperfTraffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp',
		      'testduration' => '180',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1]'
		    },
		    'MonitorPortStats' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'sleepbetweenworkloads' => VDNetLib::TestData::TestConstants::VDS2TSAM_SLEEP_STATS,
		      'check_port_packet' => {
                        'switch' => 'vc.[1].vds.[1]',
                      }
		    },
		    'MonitorVmnicStats' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'sleepbetweenworkloads' => VDNetLib::TestData::TestConstants::VDS2TSAM_SLEEP_STATS,
		      'check_adapter_packet' => {
                        'adapter' => 'host.[1].vmnic.[1]',
                      },
		    }
		  }
		},


		'VDS2EsxcliVGTVLAN' => {
		  'Component' => 'VDS2TSAM',
		  'Category' => 'Esxcli',
		  'TestName' => 'VDS2EsxcliVGTVLAN',
		  'Summary' => 'Check whether the esxcli command for listing a per-VLAN ' .
		               'packet breakdown on a NIC with running traffic through ' .
		               'it returns the desired output, when the VM is VLAN tagged',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_TwoVM,
		  'WORKLOADS' => {
		    'Sequence' => [
		      ['EnableIPv6'],
		      ['SwitchVLAN'],
		      ['NetAdapter_1'],
		      ['NetperfTraffic1',
		       'MonitorVSTVLANPkt']
		    ],
		    'ExitSequence' => [
		      ['RemoveGuestVLAN1'],
                      ['RemoveGuestVLAN2'],
		      ['RemoveVLAN']
		    ],
		    'Duration' => 'time in seconds',
		    'EnableIPv6' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
		      'ipv6' => 'ADD',
		      'ipv6addr' => 'DEFAULT'
		    },
		    'SwitchVLAN' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'trunk',
		      'vlan' => "[" . VDNetLib::Common::GlobalConfig::VDNET_VLAN_D .
                      "-" . VDNetLib::Common::GlobalConfig::VDNET_VLAN_E . "]"
		    },
		    'NetAdapter_1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1-2].vnic.[1]',
                      'vlaninterface' => {
                         '[1]' => {
                            'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                         },
                      }
		    },
		    'NetperfTraffic1' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'l4protocol' => 'tcp',
		      'testduration' => '300',
		      'toolname' => 'netperf',
		      'testadapter' => 'vm.[1].vnic.[1].vlaninterface.[1]',
		      'supportadapter' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'MonitorVSTVLANPkt' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
                      'check_vlan_packet' => {
                        'adapter' => 'host.[1].vmnic.[1]',
                        'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                      },
		      'sleepbetweenworkloads' => '120',
		    },
		    'RemoveGuestVLAN1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
                      'deletevlaninterface' => 'vm.[1].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveGuestVLAN2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
                      'deletevlaninterface' => 'vm.[2].vnic.[1].vlaninterface.[1]'
		    },
		    'RemoveVLAN' => {
		      'Type' => 'PortGroup',
		      'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
		      'vlantype' => 'access',
		      'vlan' => '0'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VDS2TSAM.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDS2TSAM class.
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
   my $self = $class->SUPER::new(\%VDS2TSAM);
   return (bless($self, $class));
}
