#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::IPFIXFunctionalTds;

#
# This file contains the structured hash for VSFW IPFIX
# flow collection.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %IPFIXFunctional = (
      'PreIPFIXSetup' => {
         TestName         => 'PreIPFIXSetup',
         Category         => 'vShield-REST-APIs',
         Component        => 'IPFIX',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Setup prereq config for IPFIX',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'setup,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '1000',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs,
         WORKLOADS => {
            'Sequence' => [
               ['PrepCluster'],
               ['SetDFWRules'],
            ],
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'SetDFWRules' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                        layer => "layer3",
                        name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
                        action  => 'allow',
                        logging_enabled => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[2]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[1]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'IPV6ICMP',
                                               },
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                               {
                                                  protocolname => 'TCP',
                                               },
                                               {
                                                  protocolname => 'UDP',
                                               },
                                            ],
                  },
               },
            },
         },
      },
      'IPFIXIPv4Flows' => {
         TestName         => 'IPFIXIPv4Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'IPFIX',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for IPFIX flow collection',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '10000000000',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs,
         WORKLOADS => {
            'Sequence' => [
               ['ConfigureIPFIX'],
               ['EnableGlobalFlowCollection'],
               ['TCPTraffic'],
               ['PingTraffic'],
               ['UDPTraffic'],
            ],
            ExitSequence => [
               ['CleanupIPFIXConf'],
               ['DisableGlobalFlowCollection'],
            ],
            'EnableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "true",
                  }
               },
               'sleepbetweenworkloads' => "50",
            },
            'DisableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "false",
                  }
               },
            },
            'ConfigureIPFIX' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               ipfixconfig => {
                  '[1]' => {
                     'id' => 'globalroot-0',
                     'enabled' => 'true',
                     'flowtimeout' => '1',
                     'collector' => [{
                        'v4ip' => 'vm.[3].vnic.[1]',
                        'port' => VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT,
                     },],
                  },
               },
            },
            'CleanupIPFIXConf' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteipfixconf => "vsm.[1].ipfixconfig.[1]",
            },
            'TCPTraffic' => {
               'Type' => 'Traffic',
               'verification' => 'Verification_1',
               'l4protocol' => 'tcp',
               'toolname' => 'iperf',
               'testduration' => '200',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'PingTraffic' => {
               'Type' => 'Traffic',
               'noofoutbound' => '1',
               'verification' => 'Verification_2',
               'toolname' => 'Ping',
               'testduration' => '200',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'UDPTraffic' => {
               'Type' => 'Traffic',
               'expectedresult' => 'PASS',
               'verification' => 'Verification_3',
               'l4protocol' => 'udp',
               'toolname' => 'iperf',
               'testduration' => '200',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'Verification_3' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'udp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
            'Verification_2' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'icmp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
            'Verification_1' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'tcp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
         },
      },
      'IPFIXIPv6Flows' => {
         TestName         => 'IPFIXIPv6Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'IPFIX',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for IPFIX flow collection',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '10000000000',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs,
         WORKLOADS => {
            'Sequence' => [
               ['EnableGlobalFlowCollection'],
               ['ConfigureIPFIX'],
               ['TCPTraffic'],
               ['PingTraffic'],
               ['UDPTraffic'],
            ],
            ExitSequence => [
               ['CleanupIPFIXConf'],
               ['DisableGlobalFlowCollection'],
            ],
            'EnableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               sleepbetweenworkloads => "30",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "true",
                  }
               },
            },
            'DisableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "false",
                  }
               },
            },
            'ConfigureIPFIX' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               ipfixconfig => {
                  '[1]' => {
                     'id' => 'globalroot-0',
                     'enabled' => 'true',
                     'flowtimeout' => '1',
                     'collector' => [{
                        'v4ip' => 'vm.[3].vnic.[1]',
                        'port' => VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT,
                     },],
                  },
               },
            },
            'CleanupIPFIXConf' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteipfixconf => "vsm.[1].ipfixconfig.[1]",
            },
            'TCPTraffic' => {
               'Type' => 'Traffic',
               'verification' => 'Verification_1',
               'l3protocol' => 'ipv6',
               'l4protocol' => 'tcp',
               'toolname' => 'iperf',
               'testduration' => '300',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'PingTraffic' => {
               'Type' => 'Traffic',
               'noofoutbound' => '1',
               'verification' => 'Verification_2',
               'toolname' => 'Ping',
               'l3protocol' => 'ipv6',
               'testduration' => '300',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'UDPTraffic' => {
               'Type' => 'Traffic',
               'expectedresult' => 'PASS',
               'verification' => 'Verification_3',
               'l3protocol' => 'ipv6',
               'l4protocol' => 'udp',
               'toolname' => 'iperf',
               'testduration' => '300',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
            },
            'Verification_3' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'udp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
            'Verification_2' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'icmp6',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
            'Verification_1' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'tcp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
         },
      },
      'IPFIXMultipleCollector' => {
         TestName         => 'IPFIXMultipleCollector',
         Category         => 'vShield-REST-APIs',
         Component        => 'IPFIX',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Multiple collectors collecting IPFIX flows',
         ExpectedResult   => 'PASS',
         Status           => 'Execution ready after PR 1268593 is resolved',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '10000000000',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs,
         WORKLOADS => {
            'Sequence' => [
               ['EnableGlobalFlowCollection'],
               ['ConfigureIPFIX'],
               ['TCPTraffic'],
            ],
            ExitSequence => [
               ['CleanupIPFIXConf'],
               ['DisableGlobalFlowCollection'],
            ],
            'EnableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "true",
                  }
               },
            },
            'DisableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "false",
                  }
               },
            },
            'ConfigureIPFIX' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               ipfixconfig => {
                  '[1]' => {
                     'id' => 'globalroot-0',
                     'enabled' => 'true',
                     'flowtimeout' => '1',
                     'collector' => [{
                        'v4ip' => 'vm.[3].vnic.[1]',
                        'port' => VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT,
                     },
                     {
                        'v4ip' => 'vm.[4].vnic.[1]',
                        'port' => VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT,
                     },
                     ],
                  },
               },
            },
            'CleanupIPFIXConf' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteipfixconf => "vsm.[1].ipfixconfig.[1]",
            },
            'TCPTraffic' => {
               'Type' => 'Traffic',
               'verification' => 'Verification_1',
               'l4protocol' => 'tcp',
               'toolname' => 'iperf',
               'testduration' => '300',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'sleepbetweenworkloads' => "10",
            },
            'Verification_1' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'tcp',
                  'src' => 'vm.[1].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1],vm.[4].vnic.[1]',
               }
            },
         },
      },
      'IPFIXIPv6Collector' => {
         TestName         => 'IPFIXIPv6Collector',
         Category         => 'vShield-REST-APIs',
         Component        => 'IPFIX',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Functional test for IPv6 address for collector',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '1000',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs,
         WORKLOADS => {
            'Sequence' => [
               ['EnableGlobalFlowCollection'],
               ['ConfigureIPFIX'],
               ['TCPTraffic'],
            ],
            ExitSequence => [
               ['CleanupIPFIXConf'],
               ['DisableGlobalFlowCollection'],
            ],
            'EnableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "true",
                  }
               },
            },
            'DisableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "false",
                  }
               },
            },
            'ConfigureIPFIX' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               ipfixconfig => {
                  '[1]' => {
                     'id' => 'globalroot-0',
                     'enabled' => 'true',
                     'flowtimeout' => '1',
                     'collector' => [{
                        'v6ip' => 'vm.[3].vnic.[1]',
                        'port' => VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT,
                     },
                     ],
                  },
               },
            },
            'CleanupIPFIXConf' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteipfixconf => "vsm.[1].ipfixconfig.[1]",
            },
            'TCPTraffic' => {
               'Type' => 'Traffic',
               'verification' => 'Verification_1',
               'l4protocol' => 'tcp',
               'toolname' => 'iperf',
               'testduration' => '300',
               'noofoutbound' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'sleepbetweenworkloads' => "10",
            },
            'Verification_1' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'tcp',
                  'addressfamily' => 'ipv6',
                  'verificationtype' => 'nfdump',
                  'src' => 'vm.[1].vnic.[1]',
                  'dst' => 'vm.[2].vnic.[1]',
                  'target' => 'vm.[3].vnic.[1]',
               }
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for VSFW IPFIXFunctional TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VSFW IPFIXFunctional class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
      # Below way of getting class name is to allow new class as well as
      # $class->new.  In new class, proto itself is class, and $class->new,
      # ref($class) return the class
      my $class = ref($proto) || $proto;
      my $self = $class->SUPER::new(\%IPFIXFunctional);
      return (bless($self, $class));
}

1;

