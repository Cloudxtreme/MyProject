#!/usr/bin/perl
################################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
################################################################################
package TDS::EsxServer::VDS::RollbackTds;

#
# This file contains test cases for the TDS VDS2.0 Rollback
# The TDS document is present in following location:
#
# http://engweb.vmware.com/~qa/p4depot/documentation/MN.Next
# /Networking-FVT/TDS/NetworkingVDS2.0ManagementNetworkRollbackRecovery.docx
#
# Since the set of test cases here deal with configuration/reconfiguration
# related to the management network. The rollback here is for the
# management network so there are couple of things that needs to taken
# care before running these tests otherwise the host would loose
# network connectivity.
#
# One of the major requirement for these test cases to work properly
# is to make sure that the "vmnic1" (or the first free pnic)  of the
# esx host should be in same subnet as that of management.
#
# The pNIC for the other host should also be in the same subnet as
# that of the nics in first host.
#
# The reason to have above requirements is because there is the tests
# move management network from vss to vds and vice versa, in the absence
# of above requirements things would not work properly.
#

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec qw($One_VC_One_Host);

@ISA = qw(TDS::Main::VDNetMainTds);


{
   # List of test cases in this TDS
   @TESTS = ("InvalidMTU", "InvalidVLAN","InvalidShaping",
             "BlockDVPortgroup", "OverridePortGroupPolicies", "RemoveVMKNIC",
             "RemovePNIC", "MigrateVMKNICWithIncorrectVLAN",
             "MigrateVMKNICWithBlockPort","MigrateVMKNICWithIncorrectShaping",
             "VSSInvalidVLAN", "VSSInvalidMTU", "VSSInvalidSpeed", "VSSRemoveVMKNIC",
             "VSSRemovePNIC", "VSSInvalidShaping", "VSSInvalidIP");

   %Rollback = (
      'InvalidMTU' => {
        'Component' => 'VPX',
        'Category' => 'Virtual Networking',
        'TestName' => 'InvalidMTU',
        'Summary' => "Verify that when invalid mtu is specified " .
                     "for the vds the network doesn't disconnect",
        'ExpectedResult' => 'PASS',
        'Tags' => undef,
        'Version' => '2',
        'AutomationStatus'  => 'Automated',
        'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
        'WORKLOADS' => {
          'Sequence' => [
            ['MigrateManagementToVDS'],
            ['InvalidMTU'],
            ['PingTraffic']
          ],
          'ExitSequence' => [
            ['MigrateManagementToVSS']
          ],
          'MigrateManagementToVDS' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[0]',
            'reconfigure' => 'true',
            'portgroup' => 'vc.[1].dvportgroup.[1]',
          },
          'InvalidMTU' => {
            'Type' => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'expectedresult' => 'FAIL',
            'mtu' => '900'
          },
          'PingTraffic' => {
            'Type' => 'Traffic',
            'toolname' => 'Ping',
            'routingscheme' => 'unicast',
            'testadapter' => 'host.[1].vmknic.[0]',
            'supportadapter' => 'host.[2].vmknic.[1]'
          },
          'MigrateManagementToVSS' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[0]',
            'reconfigure' => 'true',
            'portgroup' => 'host.[1].portgroup.[0]',
          }
        }
      },

      'InvalidVLAN' => {
        'Component' => 'VPX',
        'Category' => 'Virtual Networking',
        'TestName' => 'InvalidVLAN',
        'Summary' => "Verify that when invalid vlan is specified " .
                     "for the vds the management network doesn't disconnect",
        'ExpectedResult' => 'PASS',
        'Tags' => undef,
        'Version' => '2',
        'AutomationStatus'  => 'Automated',
        'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,

        'WORKLOADS' => {
          'Sequence' => [
            ['MigrateManagementToVDS'],
            ['InvalidVLAN'],
            ['PingTraffic']
          ],
          'ExitSequence' => [
            ['MigrateManagementToVSS']
          ],
          'MigrateManagementToVDS' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[0]',
            'reconfigure' => 'true',
            'portgroup' => 'vc.[1].dvportgroup.[1]',
          },
          'InvalidVLAN' => {
            'Type' => 'PortGroup',
            'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
            'expectedresult' => 'IGNORE',
            'vlantype' => 'access',
            'vlan' => '900'
          },
          'PingTraffic' => {
            'Type' => 'Traffic',
            'sleepbetweencombos' => '30',
            'toolname' => 'Ping',
            'routingscheme' => 'unicast',
            'testadapter' => 'host.[1].vmknic.[0]',
            'supportadapter' => 'host.[2].vmknic.[1]'
          },
          'MigrateManagementToVSS' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[0]',
            'reconfigure' => 'true',
            'portgroup' => 'host.[1].portgroup.[0]',
          }
        }
      },

      'InvalidShaping' => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'InvalidShaping',
         'Summary' => "Verify that when invalid shaping (or lowest) is ".
                      "specified for the vds the managemnet network" .
                      "doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
                            ['MigrateManagementToVDS'],
                            ['InvalidShaping'],
                            ['PingTraffic']
                          ],
            'ExitSequence' => [
                                ['MigrateManagementToVSS']
                              ],
             'MigrateManagementToVDS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]',
             },
            'InvalidShaping' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'expectedresult' => 'IGNORE',
               'set_trafficshaping_policy' => {
                 'operation' => 'enable',
                 'shaping_direction' => 'in',
                 'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                 'peak_bandwidth' => '1',
                 'avg_bandwidth' => '1',
                 'burst_size' => '1'
               }
             },
            'PingTraffic' => {
                'Type' => 'Traffic',
                'sleepbetweencombos' => '30',
                'toolname' => 'Ping',
                'routingscheme' => 'unicast',
                'testadapter' => 'host.[1].vmknic.[0]',
                'supportadapter' => 'host.[2].vmknic.[1]'
              },
             'MigrateManagementToVSS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[0]',
             }
          }
       },

      'BlockDVPortGroup' => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'BlockDVPortGroup',
         'Summary' => "Verify that when the specific dvporgroup" .
                      "is block to which management network is " .
                      "connected it doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
                            ['MigrateManagementToVDS'],
                            ['BlockDVPortGroup'],
                            ['PingTraffic']
                          ],
            'ExitSequence' => [
                                ['MigrateManagementToVSS']
                              ],
             'MigrateManagementToVDS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]',
             },
            'BlockDVPortGroup' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'expectedresult' => 'IGNORE',
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'blockport' => 'host.[1].vmknic.[0]'
             },
            'PingTraffic' => {
               'Type' => 'Traffic',
               'sleepbetweencombos' => '30',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[0]',
             }
          }
       },

      'RemoveVMKNIC'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'RemoveVMKNIC',
         'Summary' => "Verify that when trying to remove the vmknic " .
                      "the operation is rolled back to previous configuration",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
                            ['MigrateManagementToVDS'],
                            ['RemoveVMKNIC'],
                            ['PingTraffic']
                          ],
            'ExitSequence' => [
                                ['MigrateManagementToVSS']
                              ],
             'MigrateManagementToVDS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]',
             },
            'RemoveVMKNIC' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'expectedresult' => 'FAIL',
              'deletevmknic' => 'host.[1].vmknic.[0]',
            },
            'PingTraffic' => {
               'Type' => 'Traffic',
               'sleepbetweencombos' => '30',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[0]',
             }
          }
       },

      'RemovePNIC'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'RemovePNIC',
         'Summary' => "Verify that when trying to remove the vmknic the " .
                      "operation is rolled back to previous configuration",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
                            ['MigrateManagementToVDS'],
                            ['RemovePNIC'],
                            ['PingTraffic']
                          ],
            'ExitSequence' => [
                                ['MigrateManagementToVSS']
                              ],
             'MigrateManagementToVDS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]',
             },
             'RemovePNIC' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'expectedresult' => 'IGNORE',
               'configureuplinks' => 'remove',
               'vmnicadapter' => 'host.[1].vmnic.[1]'
             },
            'PingTraffic' => {
               'Type' => 'Traffic',
               'sleepbetweencombos' => '30',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmknic.[0]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[0]',
             }
          }
       },

      'MigrateVMKNICWithIncorrectVLAN'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'MigrateVMKNICWithIncorrectVLAN',
         'Summary' => "Verify that when vmknic is migrated to dvportgroup " .
                      "with incorrect vlan id the network continues to work",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
           'Sequence' => [
                           ['InvalidVLAN'],
                           ['MigrateManagementToVDS1'],
                           ['NoVLAN'],
                           ['MigrateManagementToVDS2'],
                           ['PingTraffic']
                         ],
           'ExitSequence' => [
                           ['MigrateManagementToVSS']
                             ],
           'InvalidVLAN' => {
             'Type' => 'PortGroup',
             'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
             'vlantype' => 'access',
             'vlan' => '900'
           },
           'MigrateManagementToVDS1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'FAIL',
           },
           'NoVLAN' => {
             'Type' => 'PortGroup',
             'TestPortGroup' => 'vc.[1].dvportgroup.[1]',
             'vlantype' => 'access',
             'vlan' => '0'
           },
           'MigrateManagementToVDS2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
           'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
            'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
            }
          }
       },


      'MigrateVMKNICWithIncorrectShaping'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'MigrateVMKNICWithIncorrectShaping',
         'Summary' => 'Verify that when vmknic is migrated to dvportgroup'.
                      'with incorrect shaping policy the network continues'.
                      'to work',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
           'Sequence' => [
                           ['InvalidShaping'],
                           ['MigrateManagementToVDS1'],
                           ['NoInShaping'],
                           ['NoOutShaping'],
                           ['MigrateManagementToVDS2'],
                           ['PingTraffic']
                         ],
           'ExitSequence' => [
                           ['MigrateManagementToVSS']
                             ],
           'InvalidShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'expectedresult' => 'IGNORE',
              'set_trafficshaping_policy' => {
                'operation' => 'enable',
                'shaping_direction' => 'in',
                'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                'peak_bandwidth' => '1',
                'avg_bandwidth' => '1',
                'burst_size' => '1'
              }
           },
           'MigrateManagementToVDS1' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'FAIL',
           },
           'NoInShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                'shaping_direction' => 'in'
              }
           },
           'NoOutShaping' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'set_trafficshaping_policy' => {
                'operation' => 'disable',
                'dvportgroup' => 'vc.[1].dvportgroup.[1]',
                'shaping_direction' => 'out'
              }
           },
           'MigrateManagementToVDS2' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
           'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
            'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
            }
          }
       },


      'MigrateVMKNICWithBlockPort'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'MigrateVMKNICWithBlockPort',
         'Summary' => 'Verify that when vmknic is migrated to dvportgroup'.
                      'with blocked dvport the network continues to work',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
           'Sequence' => [
                           ['MigrateManagementToVDS'],
                           ['BlockDVPort'],
                           ['UnBlockDVPort'],
                           ['PingTraffic']
                         ],
           'ExitSequence' => [
                           ['MigrateManagementToVSS']
                             ],
           'BlockDVPort' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'expectedresult' => 'IGNORE',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'blockport' => 'host.[1].vmknic.[0]'
            },
           'UnBlockDVPort' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'unblockport' => 'host.[1].vmknic.[0]'
            },
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
           'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
            'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
            }
          }
       },


      'VSSInvalidSpeed'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'VSSInvalidSpeed',
         'Summary' => "Verify that when invalid speed is specified for " .
                      "the vmnic the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['InvalidSpeed'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'InvalidSpeed' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[2]',
               'expectedresult' => 'IGNORE',
               'configure_link_properties' => {
                 'speed' => '0',
               }
             },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             }
          },
       },


      'VSSInvalidMTU'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'VSSInvalidMTU',
         'Summary' => "Verify that when invalid MTU is specified for the " .
                      "mknic the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['InvalidMTU'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'InvalidMTU' => {
                'Type' => 'Switch',
                'TestSwitch' => 'host.[1].vss.[1]',
                'expectedresult' => 'FAIL',
                'mtu' => '18000'
              },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             }
          },
       },


      'VSSRemoveVMKNIC'  => {
         'Component' => 'VPX',
         'Category'  => 'Virtual Networking',
         'TestName'  => 'VSSRemoveVMKNIC',
         'Summary'   => "Verify that when try to remove vmk NIC from VSS " .
                      "the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['RemoveVMKNIC'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'RemoveVMKNIC' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1].x.[x]',
               'expectedresult' => 'FAIL',
               'deletevmknic' => 'host.[1].vmknic.[0]',
               'maxtimeout' => '60',
             },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             }
          },
       },


      'VSSRemovePNIC'  => {
         'Component' => 'VPX',
         'Category' => 'Virtual Networking',
         'TestName' => 'VSSRemovePNIC',
         'Summary'  => "Verify that when try to remove pNIC from VSS, ".
                       "the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['RemovePNIC'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'RemovePNIC' => {
               'Type' => 'Switch',
               'TestSwitch' => 'host.[1].vss.[1]',
               'expectedresult' => 'FAIL',
               'configureuplinks' => 'remove',
               'maxtimeout' => '60',
               'vmnicadapter' => 'host.[1].vmnic.[2]',
               'ExecutionType'  =>  "API",
             },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             }
          },
       },

      'VSSInvalidShaping'  => {
         'Component' => 'VPX',
         'Category'  => 'Virtual Networking',
         'TestName'  => 'VSSInvalidShaping',
         'Summary'   => "Verify that when incorrect traffic shaping policies ".
                        " are set then the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['InvalidShaping'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'InvalidShaping' => {
               'Type' => 'Switch',
               'TestSwitch' => 'host.[1].vss.[1]',
               'expectedresult' => 'FAIL',
               'set_trafficshaping_policy' => {
                 'operation' => 'enable',
                 'peak_bandwidth' => '1',
                 'avg_bandwidth' => '1',
                 'burst_size' => '1'
               },
               'ExecutionType'  =>  "API",
             },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             }
          },
       },


      'VSSInvalidIP2'  => {
         'Component' => 'VPX',
         'Category'  => 'Virtual Networking',
         'TestName'  => 'VSSInvalidIP',
         'Summary'   => "Verify that when try to set invalid IP then ".
                        "the network doesn't disconnect",
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'AutomationStatus'  => 'Automated',
         'TestbedSpec' =>
           $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost,
         'WORKLOADS' => {
            'Sequence' => [
               ['MigrateManagementToVDS'],
               ['CreateVSSPG'],
               ['AddUplink'],
               ['MigrateManagementToNewVSS'],
               ['InvalidIP'],
               ['PingTraffic']
             ],
            'ExitSequence' => [
               ['MigrateManagementToVDS'],
               ['MigrateManagementToVSS']
             ],
           'MigrateManagementToVDS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'expectedresult' => 'PASS',
           },
            'CreateVSSPG' => {
              'Type' => 'Host',
              'TestHost' => 'host.[1].x.[x]',
              'vss' => {
                '[1]' => {
                  'name' => undef
                }
              },
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                }
              },
            },
            'AddUplink' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'configureuplinks' => 'add',
              'maxtimeout' => '300',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
            'MigrateManagementToNewVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[1]',
             },
             'InvalidIP' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'ipv4address' => '192.168.0.1',
              'netmask' => '255.255.0.0',
              'expectedresult' => 'IGNORE',
            },
             'PingTraffic' => {
               'Type' => 'Traffic',
               'toolname' => 'Ping',
               'routingscheme' => 'unicast',
               'testadapter' => 'host.[1].vmknic.[0]',
               'supportadapter' => 'host.[2].vmknic.[1]'
             },
             'MigrateManagementToVSS' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmknic.[0]',
              'reconfigure' => 'true',
              'portgroup' => 'host.[1].portgroup.[0]',
             },
         },
      },
   );
}


################################################################################
#
# new --
#       This is the constructor for Rollback TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of Rollback class
#
# Side effects:
#       None
#
################################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%Rollback);
   return (bless($self, $class));
}

1;



