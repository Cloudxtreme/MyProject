#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::MaintenanceModePCITds;

#
# This file contains the structured hash for category, MaintenanceMode
# PCI passhthrough tests.
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
%MaintenanceModePCI = (
		'EditPCIPassThroughTrue' => {
		  'Component' => 'Network Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'EditPCIPassThroughTrue',
		  'Summary' => 'Enable PCIPassThrough, Update PCIPassThru Config and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => '',
		  'TestcaseLevel' => 'Functional',
                  'AutomationLevel'  => 'Automated',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6600',
                  'TestbedSpec'      =>
                       $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::EditPCIPassThroughTrue',
		  'Procedure' =>
                    '1.Set PCIPassThru to True ' .
                    '2.Extract host profile ' .
                    '3.Generates an Answer File for the given profile ' .
                    '4.Change paramerter enable=true/false of  PCIPassThru Config policy/option.' .
                    '5.Get maintenanceMode status ',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['SetPassThroughTrue'],
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['ApplyOption'],
		        ['ConfigurerPciPassthru'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'SetPassThroughTrue' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1]',
		      'configurepcipassthru' => 'true',
                      'id' => VDNetLib::TestData::TestConstants::PCI_USB_UHCI_0_ID,
                    },
                   'ApplyOption' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'apply',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
                    'ConfigurerPciPassthru' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'true',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile' => '/tmp/hp.xml',
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                       'answerfile'   => '/tmp/ans.xml',
                    },
                    'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => '/tmp/hp.xml',
                      'answerfile'      => '/tmp/ans.xml',
                      'maintenancemodestatus' => 'true',
                    },
		  }
		},
		'IgnorePassThrough' => {
		  'Component' => 'Network Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'IgnorePassThrough',
		  'Summary' => 'Ignore PCIPassThrough and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'pci',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
                  'AutomationLevel'  => 'Automated',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6600',
                  'TestbedSpec'      =>
                       $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::IgnorePassThrough',
		  'Procedure' =>
                     '1.Extract host profile ' .
                     '2.Generates an Answer File for the given profile ' .
                     '3.Change PCIPassThru policy option to ignore ' .
                     '4.Get maintenanceMode status.',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['ApplyOption'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile' => '/tmp/hp.xml',
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                       'answerfile'   => '/tmp/ans.xml',
                    },
                    'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => '/tmp/hp.xml',
                      'answerfile'      => '/tmp/ans.xml',
                      'maintenancemodestatus' => 'false',
                    },
		    'ApplyOption' => {
		      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
		      'configurepcipassthru' => 'ignore',
                      'hostprofilefile'      => '/tmp/hp.xml',
		    },
		  }
		},
		'ApplyFalsePassThrough' => {
		  'Component' => 'Network Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'ApplyFalsePassThrough',
		  'Summary' => 'Set PCIPassThru Config policy option to False and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'pci',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
                  'AutomationLevel'  => 'Automated',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6600',
                  'TestbedSpec'      =>
                       $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::ApplyFalsePassThrough',
                  'Procedure' =>
                     '1.Extract host profile ' .
                     '2.Generates an Answer File for the given profile ' .
                     '3.Change PCIPassThru Config policy option to false ' .
                     '4.Get maintenanceMode status.',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['ApplyOption'],
		        ['GetMaintenanceModeStatus'],
		    ],
                    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                       'answerfile'   => '/tmp/ans.xml',
                    },
                    'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => '/tmp/hp.xml',
                      'answerfile'      => '/tmp/ans.xml',
                      'maintenancemodestatus' => 'false',
                    },
		    'ApplyOption' => {
		      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'false',
                      'hostprofilefile'      => '/tmp/hp.xml',
		    },
		  }
		},
		'EditPCIPassThroughFalse' => {
		  'Component' => 'Network Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'EditPCIPassThroughFalse',
		  'Summary' => 'Change PCIPassThru to False and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'pci',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
                  'AutomationLevel'  => 'Automated',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6600',
                  'TestbedSpec'      =>
                       $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::EditPCIPassThroughFalse',
                  'Procedure' =>
                     '1.Set PCIPassThru to False ' .
                     '2.Extract host profile ' .
                     '3.Generates an Answer File for the given profile ' .
                     '4.Set PCIPassThrue policy option to ignore ' .
                     '5.Set PCIPassThrue Config policy option with enalbe=true ' .
                     '6.Get maintenanceMode status.',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['SetPassThroughFalse'],
		        ['CreateProfile'],
		        ['GenerateAnswerFile'],
		        ['ApplyOption'],
		        ['RulesetTrue'],
		        ['GetMaintenanceModeStatus'],
		    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                       'answerfile'   => '/tmp/ans.xml',
                    },
                    'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => '/tmp/hp.xml',
                      'answerfile'      => '/tmp/ans.xml',
                      'maintenancemodestatus' => 'false',
                    },
                    'SetPassThroughFalse' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'setpcipassthrubyid' => 'false',
                      'pciid'  => VDNetLib::TestData::TestConstants::PCI_USB_UHCI_0_ID,
                    },
                   'ApplyOption' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'ignore',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
                    'RulesetTrue' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'true',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
		  }
		},
		'ApplyPassThrough' => {
		  'Component' => 'Network Plugin',
		  'Category' => 'Host Profiles',
		  'TestName' => 'ApplyPassThrough',
		  'Summary' => 'Set PCIPassThru policy option to apply and check for maintenance mode status',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'pci',
		  'Version' => 2,
		  'Status' => 'Execution Ready',
		  'QCPath' => 'OP\\Networking-FVT\\NetworkPlugin',
		  'Developer' => 'sho',
		  'TestcaseLevel' => 'Functional',
                  'AutomationLevel'  => 'Automated',
		  'Product' => 'ESX',
		  'Duration' => '',
		  'PMT' => '6600',
                  'TestbedSpec'      =>
                       $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost,
		  'TestcaseType' => 'Functional',
		  'Testbed' => '',
		  'testID' => 'TDS::EsxServer::NetworkPlugin::MaintenanceMode::ApplyPassThrough',
                  'Procedure' =>
                     '1.Extract host profile ' .
                     '2.Generates an Answer File for the given profile ' .
                     '3.Set PCIPassThru  policy option to apply ' .
                     '4.Get maintenanceMode status.',
		  'Priority' => 'P0',
		  'FullyAutomatable' => 'Y',
		  'AutomationLevel' => 'Automated',
		  'WORKLOADS' => {
		    'Sequence' => [
		        ['CreateProfile'],
                        ['GenerateAnswerFile'],
                        ['ApplyOption'],
                        ['GetMaintenanceModeStatus'],
                    ],
		    'Duration' => 'time in seconds',
                    'CreateProfile' => {
                       'Type'        => 'Host',
                       'TestHost'    => 'host.[1]',
                       'createprofile' => 'extractprofile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                    },
                    'GenerateAnswerFile' => {
                       'Type'         => 'Host',
                       'TestHost'     => 'host.[1]',
                       'generateanswerfile'  => 'genanswerfile',
                       'hostprofilefile'     => '/tmp/hp.xml',
                       'answerfile'   => '/tmp/ans.xml',
                    },
                    'GetMaintenanceModeStatus' => {
                      'Type' => 'Host',
                      'TestHost' => 'host.[1]',
                      'hostprofilefile' => '/tmp/hp.xml',
                      'answerfile'      => '/tmp/ans.xml',
                      'maintenancemodestatus' => 'false',
                    },
                   'ApplyOption' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'apply',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
                   'IgnoreOption' => {
                      'Type' => 'Host',
                      'TestHost'     => 'host.[1]',
                      'configurepcipassthru' => 'ignore',
                      'hostprofilefile'      => '/tmp/hp.xml',
                    },
		  }
		},
   );
}


#######################################################################
#
# new --
#       This is the constructor for MaintenanceModePCI.
#
# Input:
#       None.
#
# Results:
#       An instance/object of MaintenanceModePCI class.
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
   my $self = $class->SUPER::new(\%MaintenanceModePCI);
   return (bless($self, $class));
}

1;
