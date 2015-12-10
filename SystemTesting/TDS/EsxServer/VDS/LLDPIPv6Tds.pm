#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::LLDPIPv6Tds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::Common::GlobalConfig;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %LLDPIPv6 = (
            'LLDPAdvertise' => {
                'TestName' => 'LLDPAdvertise',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\LLDPIPv6',
                'Summary'  => 'Verify that LLDP sends out IPv6 address correctly when vDS' .
                                'LLDP mode is Advertise',
                'Procedure'=> '1. Connect two hosts back to back' .
                              '2. Add each host into a seperate VDS' .
                              '3. Enable LLDP advertise on both VDS' .
                              '4. Configure LLDP advertise IPv6 address on the first VDS' .
                              '5. Verify on the second VDS, it can not receive the IPv6 info' .
                              '6. Enable LLDP listen on the second VDS' .
                              '7. Verify on the second VDS, it can receive the IPv6 info',
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
		'testID'           => 'TDS::EsxServer::VDS::LLDPIPv6::LLDPAdvertise',
	        'TestbedSpec' =>
                $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoVDS_TwoHost_OneVmnicEachHost,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPAdvertiseOnBothVDS'
		      ],
                      [
                        'ConfigureLLDPIPv6AddrInfo'
                      ],
                      [
		        'HasNotLLDPInfoOnHost2'
		      ],
                      [
		        'LLDPListenOnVDS2'
		      ],
                      [
		        'HasLLDPInfoOnHost2'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
		    'LLDPAdvertiseOnBothVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'lldp' => 'advertise'
		    },
                    'LLDPListenOnVDS2' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[2]',
		      'lldp' => 'listen'
		    },
                    'ConfigureLLDPIPv6AddrInfo' => {
                       'Type' => 'Switch',
                       'TestSwitch' => 'vc.[1].vds.[1]',
                       'lldpipv6addr' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       'sourcehost'  => 'host.[1]'
                    },
		    'HasLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
                    'HasNotLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]not_contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
	       },
            'LLDPListen' => {
                'TestName' => 'LLDPListen',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\LLDPIPv6',
                'Summary'  => 'Verify that LLDP works correctly when vDS' .
                                'LLDP mode is Listen',
                'Procedure'=> '1. Connect two hosts back to back' .
                              '2. Add each host into a seperate VDS' .
                              '3. Enable LLDP listen on both VDSs' .
                              '4. Configure LLDP advertise IPv6 address on the ' .
                              'first VDS'.
                              '5. Verify on the second VDS, it can not receive the IPv6 info' .
                              '6. Enable LLDP advertise on the first VDS' .
                              '7. Verify on the second VDS, it can receive the IPv6 info',
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
		'testID'           => 'TDS::EsxServer::VDS::LLDPIPv6::LLDPListen',
	        'TestbedSpec' =>
                $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoVDS_TwoHost_OneVmnicEachHost,
		  'WORKLOADS' => {
		    'Sequence' => [
                      [
		        'LLDPListenOnBothVDS'
		      ],
                      [
                        'ConfigureLLDPIPv6AddrInfo'
                      ],
		      [
		        'HasNotLLDPInfoOnHost2'
		      ],
                      [
		        'LLDPAdvertiseOnVDS1'
		      ],
                      [
		        'HasLLDPInfoOnHost2'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
                    'LLDPListenOnBothVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'lldp' => 'listen'
		    },
		    'LLDPAdvertiseOnVDS1' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'advertise'
		    },
                    'ConfigureLLDPIPv6AddrInfo' => {
                       'Type' => 'Switch',
                       'TestSwitch' => 'vc.[1].vds.[1]',
                       'lldpipv6addr' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       'sourcehost'  => 'host.[1]'
                    },
		    'HasLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
                    'HasNotLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]not_contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
	       },
            'LLDPBoth' => {
                'TestName' => 'LLDPBoth',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\LLDPIPv6',
                'Summary'  => 'Verify that LLDP works correctly when vDS' .
                                'LLDP mode is Both',
                'Procedure'=> '1. Connect two hosts back to back' .
                              '2. Add each host into a seperate VDS' .
                              '3.Verify by default,there is no LLDP information on the second host' .
                              '4. Enable LLDP both on one VDS' .
                              '5. Enable LLDP both on another VDS' .
                              '6. Configure LLDP advertise IPv6 address on the ' .
                              'first VDS'.
                              '7. Verify on the second VDS, it can receive the IPv6 info',
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
		'testID'           => 'TDS::EsxServer::VDS::LLDPIPv6::LLDPAdvertise',
	        'TestbedSpec' =>
                $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoVDS_TwoHost_OneVmnicEachHost,
		  'WORKLOADS' => {
		    'Sequence' => [
                      [
		        'HasNotLLDPInfoOnHost2'
		      ],
		      [
		        'LLDPBothOnVDS'
		      ],
                      [
                        'ConfigureLLDPIPv6AddrInfo'
                      ],
		      [
		        'HasLLDPInfoOnHost2'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
		    'LLDPBothOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'lldp' => 'both'
		    },
                    'ConfigureLLDPIPv6AddrInfo' => {
                       'Type' => 'Switch',
                       'TestSwitch' => 'vc.[1].vds.[1]',
                       'lldpipv6addr' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       'sourcehost'  => 'host.[1]'
                    },
		    'HasLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
                    'HasNotLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]not_contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
	       },
            'PersistentConfiguration' => {
                'TestName' => 'PersistentConfiguration',
                'Category' => 'ESX Server',
                'Component'=> 'vDS',
                'Product'  => 'ESX',
                'QCPath'   => 'OP\Networking-FVT\LLDPIPv6',
                'Summary'  => 'Verify that LLDP works correctly when vDS' .
                                'LLDP mode is Both and after host reboots',
                'Procedure'=> '1. Connect two hosts back to back' .
                              '2. Add each host into a seperate VDS' .
                              '3. Enable LLDP both on one VDS' .
                              '4. Enable LLDP both on another VDS' .
                              '5. Configure LLDP advertise IPv6 address on the ' .
                              'first VDS' .
                              '6. Verify on the second VDS, it can receive the IPv6 info' .
                              '7. reboot the second host' .
                              '8. Verify on the second VDS, it can receive the IPv6 info',
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
		'Tags'             => 'CAT_P0,hostreboot',
		'AutomationStatus' => 'Automated',
		'testID'           => 'TDS::EsxServer::VDS::LLDPIPv6::LLDPAdvertise',
	        'TestbedSpec' =>
                $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoVDS_TwoHost_OneVmnicEachHost,
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPBothOnVDS'
		      ],
                      [
                        'ConfigureLLDPIPv6AddrInfo'
                      ],
		      [
		        'HasLLDPInfoOnHost2'
		      ],
                      [
                        'RebootHost2'
                      ],
                      [
		        'HasLLDPInfoOnHost2'
		      ],
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
		    'LLDPBothOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'lldp' => 'both'
		    },
                    'ConfigureLLDPIPv6AddrInfo' => {
                       'Type' => 'Switch',
                       'TestSwitch' => 'vc.[1].vds.[1]',
                       'lldpipv6addr' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       'sourcehost'  => 'host.[1]'
                    },
		    'HasLLDPInfoOnHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
                      'sleepbetweenworkloads' => '60',
                      'dvsname'  => 'vc.[1].vds.[2]',
		      "verifylldpipv6address[?]contains" => [
                       {
                        'ipv6' => VDNetLib::Common::GlobalConfig::LLDP_IPV6_ADDRESS,
                       },
                      ],
		    },
                    'RebootHost2' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[2]',
		      'reboot' => 'yes'
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1-2]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
	       },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for LLDP.
#
# Input:
#       None.
#
# Results:
#       An instance/object of LLDP class.
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
   my $self = $class->SUPER::new(\%LLDPIPv6);
   return (bless($self, $class));
}
