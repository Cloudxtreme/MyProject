#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::NetworkPluginTds;

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{

%NetworkPlugin = (
      'ipv4ipv6vmknicstatic-vDS' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv4ipv6vmknicstatic-vDS',
        'Summary' => 'ipv4ipv6vmknicstatic-vDS',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'std',
        'Version' => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Stateless_Testbed,
        'WORKLOADS' => {
          'Sequence' => [
            ['EnableMaintenanceMode'],
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv4Set'],
            ['InterfaceIPv6Set'],
            ['CreateVDS'],
            ['CreateDVPG'],
            ['AddPort'],
            ['MigarateToVDS'],
            ['CreateProfile'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv4'],
            ['CheckInterfaceIPv6'],
           ],
           ExitSequence   =>
           [
            ['DisableMaintenanceMode'],
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['SleepToWaitProfile'],
            ['VswitchRemove'],
            ['RemoveHostFromVDS'],
            ['RemoveVDS']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv4Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 set',
            'args' => '-I ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP .
                      ' -N ' . VDNetLib::TestData::TestConstants::DEFAULT_NETMASK .
                      ' -t static -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 address add ',
            'args' => '-I ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IPV6 .
                      '/64 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => {
              '[1]' => {
                'datacenter' => 'vc.[1].datacenter.[1]',
                'vmnicadapter' => 'host.[1].vmnic.[1]',
                'configurehosts' => 'add',
                'name' => 'profiletest',
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'CreateDVPG' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'dvportgroup' => {
              '[1]' => {
                'name' => 'dvpga',
                'vds' => 'vc.[1].vds.[1]'
              }
            }
          },
          'AddPort' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
            'datacenter' => 'Profile-test',
            'addporttodvportgroup' => '5'
          },
          'MigarateToVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => 'vc.[1].vds.[1]',
            'opt' => 'migratevmknictovds',
            'dvpgname' => 'dvpga',
            'pgname'   => 'testpg100',
            'dcname' => 'Profile-test',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'ImportAnswer' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'importanswer' => 'myanswerfile.xml'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv4' => {
            'Type' => 'Command',
            'command' => 'ping ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv6' => {
            'Type' => 'Command',
            'command' => 'ping6 ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IPV6,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'VswitchRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network vswitch standard remove',
            'args' => '-v vSwitch100',
            'testhost' => 'host.[1].x.[x]'
          },
          'RemoveHostFromVDS' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'configurehosts' => 'remove',
            'host' => 'host.[1]',
          },
          'RemoveVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'deletevds' => 'vc.[1].vds.[1]'
          }
        }
      },
      'ipv6vmknicautoconf-vSwitch' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv6vmknicautoconf-vSwitch',
        'Summary' => 'ipv6vmknicautoconf-vSwitch',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'stdvss',
        'Version' => '2',
       TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Stateless_Testbed,
        'WORKLOADS' => {
          'Sequence' => [
            ['EnableMaintenanceMode'],
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv6Set'],
            ['CreateProfile'],
            ['EditNetworkPolicyOpt'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv4'],
            ['CheckIPv6AutoConf'],
           ],
           ExitSequence   =>
           [
            ['DisableMaintenanceMode'],
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['PortgroupRemove'],
            ['VswitchRemove']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 set',
            'args' => '-d false -r true -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'EditNetworkPolicyOpt' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'profilecategory' => 'Host port group',
            'policyoption' => 'UserInputIPAddress',
            'policyparams' => 'address:' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP .
                              ',subnetmask:' . VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
            'opt' => 'editpolicyopt',
            'applyprofile' => 'NetworkProfile',
            'subcategory' => 'IP address settings',
            'profiledevice' => 'testpg100',
            'policyid' => 'IpAddressPolicy',
            'targetprofile' => 'testprofile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv4' => {
            'Type' => 'Command',
            'command' => 'ping ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckIPv6AutoConf' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'vmk1           false                true     false',
            'args' => '-n vmk1 | grep vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
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
      'ipv4vmknicstatic-vSwitch' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv4vmknicstatic-vSwitch',
        'Summary' => 'Add new vmknic interface and save it',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'std',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['CreateProfile'],
            ['EditNetworkPolicyOpt'],
            ['AssociateProfile'],
            ['EnableMaintenanceMode'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['CheckInterface'],
           ],
           ExitSequence   =>
           [
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['PortgroupRemove'],
            ['VswitchRemove'],
            ["DisableMaintenanceMode"]
           ],
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'EditNetworkPolicyOpt' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'profilecategory' => 'Host port group',
            'policyoption' => 'UserInputIPAddress',
            'policyparams' => 'address:' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP .
                              ',subnetmask:' . VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
            'opt' => 'editpolicyopt',
            'applyprofile' => 'NetworkProfile',
            'subcategory' => 'IP address settings',
            'profiledevice' => 'testpg100',
            'policyid' => 'IpAddressPolicy',
            'targetprofile' => 'testprofile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
           "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1].x.[x]",
           },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 120',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterface' => {
            'Type' => 'Command',
            'command' => 'ping ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
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
      'ipv6vmknicstatic-vSwitch' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv6vmknicstatic-vSwitch',
        'Summary' => 'ipv6vmknicstatic-vSwitch',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'stdvss',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv6Set'],
            ['CreateProfile'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
           ],
           ExitSequence   =>
           [
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv6'],
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['PortgroupRemove'],
            ['VswitchRemove']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 address add ',
            'args' => '-I 2009::100/64 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv6' => {
            'Type' => 'Command',
            'command' => 'ping6 ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IPV6,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
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
      'ipv4ipv6vmknicdhcp-vDS' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv4ipv6vmknicdhcp-vDS',
        'Summary' => 'ipv4ipv6vmknicdhcp-vDS',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'std',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv4Set'],
            ['InterfaceIPv6Set'],
            ['CreateVDS'],
            ['CreateDVPG'],
            ['AddPort'],
            ['MigarateToVDS'],
            ['SleepToWaitProfile'],
            ['CreateProfile'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv4'],
            ['CheckInterfaceIPv6'],
           ],
           ExitSequence   =>
           [
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['SleepToWaitProfile'],
            ['VswitchRemove'],
            ['RemoveHostFromVDS'],
            ['RemoveVDS']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv4Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 set',
            'args' => '-i vmk1 -t dhcp',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 set',
            'args' => '-d true -r false -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => {
              '[1]' => {
                'datacenter' => 'vc.[1].datacenter.[1]',
                'vmnicadapter' => 'host.[1].vmnic.[1]',
                'version' => undef,
                'configurehosts' => 'add',
                'name' => 'profiletest',
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'CreateDVPG' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'dvportgroup' => {
              '[1]' => {
                'ports' => undef,
                'name' => 'dvpga',
                'binding' => undef,
                'nrp' => undef,
                'vds' => 'vc.[1].vds.[1]'
              }
            }
          },
          'AddPort' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
            'datacenter' => 'Profile-test',
            'addporttodvportgroup' => '5'
          },
          'MigarateToVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => 'vc.[1].vds.[1]',
            'opt' => 'migratevmknictovds',
            'dvpgname' => 'dvpga',
            'testhost' => 'host.[1].x.[x]',
            'pgname'   => 'testpg100',
            'dcname' => 'Profile-test',
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'CheckInterfaceIPv4' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'DHCP',
            'args' => '-i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv6' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'vmk1            true               false     false',
            'args' => '-n vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'VswitchRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network vswitch standard remove',
            'args' => '-v vSwitch100',
            'testhost' => 'host.[1].x.[x]'
          },
          'RemoveHostFromVDS' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'configurehosts' => 'remove',
            'host' => 'host.[1]',
          },
          'RemoveVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'deletevds' => 'vc.[1].vds.[1]'
          }
        }
      },
      'ipv4vmknicdhcp-vSwitch' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv4vmknicdhcp-vSwitch',
        'Summary' => 'Add new vmknic interface and save it',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'stdvss',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPSet'],
            ['SleeptoWaitIP'],
            ['CreateProfile'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleeptoWaitIP'],
            ['CheckInterface'],
           ],
           ExitSequence   =>
           [
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['PortgroupRemove'],
            ['VswitchRemove']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPSet' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 set',
            'args' => '-i vmk1 -t dhcp',
            'testhost' => 'host.[1].x.[x]'
          },
          'SleeptoWaitIP' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'CheckInterface' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'DHCP',
            'args' => '-i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
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
      'ipv6vmknicdhcp-vSwitch' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv6vmknicdhcp-vSwitch',
        'Summary' => 'ipv6vmknicdhcp-vSwitch',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'stdvss',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVSS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv6Set'],
            ['CreateProfile'],
            ['EditNetworkPolicyOpt'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv4'],
            ['CheckIPv6Dhcp6'],
           ],
           ExitSequence   =>
           [
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['PortgroupRemove'],
            ['VswitchRemove']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 set',
            'args' => '-d true -r false -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'EditNetworkPolicyOpt' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'profilecategory' => 'Host port group',
            'policyoption' => 'UserInputIPAddress',
            'policyparams' => 'address:' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP .
                              ',subnetmask:' . VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
            'opt' => 'editpolicyopt',
            'applyprofile' => 'NetworkProfile',
            'subcategory' => 'IP address settings',
            'profiledevice' => 'testpg100',
            'policyid' => 'IpAddressPolicy',
            'targetprofile' => 'testprofile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv4' => {
            'Type' => 'Command',
            'command' => 'ping ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckIPv6Dhcp6' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'vmk1            true               false     false',
            'args' => '-n vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
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
      'ipv6vmknicautoconf-vDS' => {
        'Component' => 'Network Plugin',
        'Category' => 'Host Profiles',
        'TestName' => 'ipv6vmknicautoconf-vDS',
        'Summary' => 'ipv6vmknicautoconf-vDS',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'std',
        'Version' => '2',
        TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_Stateless_Testbed,

        'WORKLOADS' => {
          'Sequence' => [
            ['VCOperation_1'],
            ['VswitchAdd'],
            ['PortgroupAdd'],
            ['InterfaceAdd'],
            ['InterfaceIPv4Set'],
            ['InterfaceIPv6Set'],
            ['CreateVDS'],
            ['CreateDVPG'],
            ['AddPort'],
            ['MigarateToVDS'],
            ['CreateProfile'],
            ['AssociateProfile'],
            ['ExportAnswerFile'],
            ['ImportAnswer'],
            ['GetAnswerFile'],
            ['ApplyImage'],
            ['RebootHost'],
            ['SleepToWaitProfile'],
            ['SleepToWaitProfile'],
            ['CheckInterfaceIPv4'],
            ['CheckInterfaceIPv6'],
           ],
           ExitSequence   =>
           [
            ['DestroyProfile'],
            ['InterfaceRemove'],
            ['SleepToWaitProfile'],
            ['VswitchRemove'],
            ['RemoveHostFromVDS'],
            ['RemoveVDS']
           ],
           'Duration' => 'time in seconds',
           'ImportAnswer' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'importanswer'  => 'myanswerfile.xml',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ExportAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'SrcHost'       => 'host.[1].x.[x]',
               'exportanswerfile' => 'myanswerfile.xml',
           },
           'GetAnswerFile' => {
               'Type'          => 'VC',
               'TestVC'        => 'vc.[1].x.[x]',
               'getanswerfile' => 'screen',
               'SrcHost'       => 'host.[1].x.[x]',
           },
           'ApplyImage' => {
               'Type'          => 'VM',
               'TestVM'        => 'powerclivm.[1].x.[x]',
               'applyimage'    => 'esx',
               'vc'            => 'vc.[1].x.[x]',
               'host'          => 'host.[1].x.[x]',
           },
           'EnableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'true',
           },
           'DisableMaintenanceMode' => {
              'Type'           => 'Host',
              'TestHost'       => 'host.[1].x.[x]',
              'maintenancemode' => 'false',
          },
          'VCOperation_1' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'opt' => 'connect'
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
            'args' => '-p testpg100 -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv4Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv4 set',
            'args' => '-I ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP .
                      ' -N ' . VDNetLib::TestData::TestConstants::DEFAULT_NETMASK .
                      ' -t static -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'InterfaceIPv6Set' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 set',
            'args' => '-d false -r true -i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'CreateVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => {
              '[1]' => {
                'datacenter' => 'vc.[1].datacenter.[1]',
                'vmnicadapter' => 'host.[1].vmnic.[1]',
                'version' => undef,
                'configurehosts' => 'add',
                'name' => 'profiletest',
                'host' => 'host.[1].x.[x]'
              }
            }
          },
          'CreateDVPG' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'dvportgroup' => {
              '[1]' => {
                'ports' => undef,
                'name' => 'dvpga',
                'binding' => undef,
                'nrp' => undef,
                'vds' => 'vc.[1].vds.[1]'
              }
            }
          },
          'AddPort' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
            'datacenter' => 'Profile-test',
            'addporttodvportgroup' => '5'
          },
          'MigarateToVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'vds' => 'vc.[1].vds.[1]',
            'opt' => 'migratevmknictovds',
            'dvpgname' => 'dvpga',
            'testhost' => 'host.[1].x.[x]',
            'pgname'   => 'testpg100',
            'dcname' => 'Profile-test',
          },
          'CreateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'targetprofile' => 'testprofile',
            'createprofile' => 'profile'
          },
          'AssociateProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'srchost' => 'host.[1].x.[x]',
            'associateprofile' => 'testprofile'
          },
          'RebootHost' => {
            'Type' => 'Host',
            'TestHost' => 'host.[1].x.[x]',
            'reboot' => 'yes'
          },
          'SleepToWaitProfile' => {
            'Type' => 'Command',
            'command' => 'sleep 70',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv4' => {
            'Type' => 'Command',
            'command' => 'ping ' . VDNetLib::TestData::TestConstants::DEFAULT_TEST_IP,
            'expectedresult' => 'PASS',
            'expectedstring' => ' 0% packet loss',
            'testhost' => 'host.[1].x.[x]'
          },
          'CheckInterfaceIPv6' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface ipv6 get',
            'expectedresult' => 'PASS',
            'expectedstring' => 'vmk1           false                true     false',
            'args' => '-n vmk1 | grep vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'DestroyProfile' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'destroyprofile' => 'testprofile'
          },
          'InterfaceRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network ip interface remove',
            'args' => '-i vmk1',
            'testhost' => 'host.[1].x.[x]'
          },
          'VswitchRemove' => {
            'Type' => 'Command',
            'command' => 'esxcli network vswitch standard remove',
            'args' => '-v vSwitch100',
            'testhost' => 'host.[1].x.[x]'
          },
          'RemoveHostFromVDS' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'configurehosts' => 'remove',
            'host' => 'host.[1]',
          },
          'RemoveVDS' => {
            'Type' => 'VC',
            'TestVC' => 'vc.[1].x.[x]',
            'deletevds' => 'vc.[1].vds.[1]'
          }
        }
      },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for NetworkPlugin.
#
# Input:
#       None.
#
# Results:
#       An instance/object of NetworkPlugin class.
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
   my $self = $class->SUPER::new(\%NetworkPlugin);
   return (bless($self, $class));
}
