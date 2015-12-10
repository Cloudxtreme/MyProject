	#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::MaintenanceModeFirewallTds;

#
# This file contains the structured hash for category, MaintenanceMode
# Firewall tests.
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%MaintenanceModeFirewall = (
		'WebAccess' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'WebAccess',
		  'Summary' => 'Change ruleset webAccess and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec'      =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::WebAccess',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile webAccess Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'webAccess' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'CIMSLP' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'CIMSLP',
		  'Summary' => 'Change ruleset CIMSLP and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::CIMSLP',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile CIMSLP Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'CIMSLP' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'vSphereClient' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vSphereClient',
		  'Summary' => 'Change ruleset vSphereClient and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::VSphereClient',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vSphereClient Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vSphereClient' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'Staf' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'Staf',
		  'Summary' => 'Change ruleset Staf and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::Staf',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile Staf Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'Staf' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'DHCPv6' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'DHCPv6',
		  'Summary' => 'Change ruleset DHCPv6 and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::DHCPv6',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile DHCPv6 Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'DHCPv6' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'CIMHttpsServer' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'CIMHttpsServer',
		  'Summary' => 'Change ruleset CIMHttpsServer and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::CIMHttpsServer',
                  'Procedure'        =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile CIMHttpsServer Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'CIMHttpsServer' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'DVSSync' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'DVSSync',
		  'Summary' => 'Change ruleset DVSSync and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::DVSSync',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile DVSSync Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'DVSSync' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'DVFilter' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'DVFilter',
		  'Summary' => 'Change ruleset DVFilter and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::DVFilter',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile DVFilter Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'DVFilter' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'cmmds' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'cmmds',
		  'Summary' => 'Change ruleset cmmds and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::Cmmds',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile cmmds Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'cmmds' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'dns' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'dns',
		  'Summary' => 'Change ruleset dns and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::DNS',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile dns Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'dns' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'updateManager' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'updateManager',
		  'Summary' => 'Change ruleset updateManager and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::UpdateManager',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile updateManager Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'updateManager' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'syslog' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'syslog',
		  'Summary' => 'Change ruleset syslog and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::Syslog',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile syslog Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'syslog' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'CIMHttpServer' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'CIMHttpServer',
		  'Summary' => 'Change ruleset CIMHttpServer and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::CIMHttpServer',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile CIMHttpServer Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'CIMHttpServer' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'rdt' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'rdt',
		  'Summary' => 'Change ruleset rdt and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::RDT',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile rdt Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'rdt' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'vsanvp' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vsanvp',
		  'Summary' => 'Change ruleset vsanvp and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::Vsanvp',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vsanvp Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vsanvp' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'IKED' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'IKED',
		  'Summary' => 'Change ruleset IKED and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::IKED',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile IKED Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'IKED' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'vMotion' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vMotion',
		  'Summary' => 'Change ruleset vMotion and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::VMotion',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vMotion Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vMotion' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'gdbserver' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'gdbserver',
		  'Summary' => 'Change ruleset gdbserver and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::GDBServer',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile gdbserver Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'gdbserver' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'httpClient' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'httpClient',
		  'Summary' => 'Change ruleset httpClient and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::HTTPClient',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile httpClient Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'httpClient' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'WOL' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'WOL',
		  'Summary' => 'Change ruleset WOL and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::WOL',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile WOL Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'WOL' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'ftpClient' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'ftpClient',
		  'Summary' => 'Change ruleset ftpClient and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::FTPClient',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile ftpClient Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'ftpClient' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'dhcp' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'dhcp',
		  'Summary' => 'Change ruleset dhcp and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::DHCP',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile dhcp Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'dhcp' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'snmp' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'snmp',
		  'Summary' => 'Change ruleset snmp and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::SNMP',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile snmp Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'snmp' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'vSPC' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vSPC',
		  'Summary' => 'Change ruleset vSPC and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::VSPC',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vSPC Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vSPC' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'HBR' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'HBR',
		  'Summary' => 'Change ruleset HBR and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::HBR',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile HBR Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'HBR' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'sshClient' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'sshClient',
		  'Summary' => 'Change ruleset sshClient and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::SSHClient',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile sshClient Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'sshClient' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'ntpClient' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'ntpClient',
		  'Summary' => 'Change ruleset ntpClient and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::NTPClient',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile ntpClient Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'ntpClient' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'activeDirectoryAll' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'activeDirectoryAll',
		  'Summary' => 'Change ruleset activeDirectoryAll and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::ActiveDirectoryAll',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile activeDirectoryAll Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
                  'WORKLOADS' => {
                    'Sequence' => [
                        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['EditFirewallRuleset'],
                        ['GetMaintenanceModeStatus'],
                    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'activeDirectoryAll' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
                  }
                },
		'vprobeServer' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vprobeServer',
		  'Summary' => 'Change ruleset vprobeServer and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::VprobeServer',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vprobeServer Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vprobeServer' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
		'ipfam' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'ipfam',
		  'Summary' => 'Change ruleset ipfam and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::ipfam',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile ipfam Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'ipfam' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
		'nfs41Client' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'nfs41Client',
		  'Summary' => 'Change ruleset nfs41Client and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::nfs41Client',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile nfs41Client Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'nfs41Client' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
		'rabbitmqproxy' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'rabbitmqproxy',
		  'Summary' => 'Change ruleset rabbitmqproxy and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::rabbitmqproxy',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile rabbitmqproxy Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'rabbitmqproxy' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
		'remoteSerialPort' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'remoteSerialPort',
		  'Summary' => 'Change ruleset remoteSerialPort and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::remoteSerialPort',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile remoteSerialPort Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'remoteSerialPort' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
		'vvold' => {
		  'Component' => 'Firewall Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'vvold',
		  'Summary' => 'Change ruleset vvold and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => '',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6598',
                  'TestbedSpec' =>
                      $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::vvold',
                  'Procedure' =>
                     '1. Extract hostprofile  ' .
                     '2. Generate Answer file for the given profile ' .
                     '3. Edit firewall profile vvold Ruleset ' .
                     '4. Get maintenance mode status',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['EditFirewallRuleset'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1].x.[x]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1].x.[x]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'answerfile'   => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                    },
                    'EditFirewallRuleset' => {
                       'Type'     => 'Host',
                       'TestHost' => 'host.[1].x.[x]',
                       'editprofile'  => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                       'profilepath'  => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_PATH .
                                           'vvold' . '"]',
                       'policyid'     => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_POLICY,
                       'policyoption' => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_OPTION,
                       'name'         => VDNetLib::TestData::TestConstants::FIREWALL_RULESET_ALLOWALL,
                       'value'        => VDNetLib::TestData::TestConstants::DEFAULT_FALSE
                    },
                   'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE,
                      'answerfile'      => VDNetLib::TestData::TestConstants::ANSWER_FILE,
                      'maintenancemodestatus' => 'false',
                    },
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for MaintenanceModeFirewall.
#
# Input:
#       None.
#
# Results:
#       An instance/object of MaintenanceMode Firewall class.
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
   my $self = $class->SUPER::new(\%MaintenanceModeFirewall);
   return (bless($self, $class));
}

1;
