#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::DVFilter::DVFilterTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %DVFilter = (
      'dvFilterConfigLimits' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterConfigLimits',
         'Summary' => 'Add more than 16 filters to protected VM and it fails',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterConfigLimits',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[2].portgroup.[1]',
                        'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[1].portgroup.[1]',
                        'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                        'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                        'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockTCP','BlockTCP1','BlockTCP2','BlockTCP3','BlockTCP4','BlockTCP5','BlockTCP6','BlockTCP7','BlockTCP8','BlockTCP9','BlockTCP10','BlockTCP11','BlockTCP12','BlockTCP13','BlockTCP14','BlockTCP15'
               ],
               [
                  'VerifyIperfFail1','VerifyIperfFail2','VerifyIperfFail3','VerifyIperfFail4','VerifyIperfFail5','VerifyIperfFail6'
               ],
               [
                  'UnBlockTCP','UnBlockTCP1','UnBlockTCP2','UnBlockTCP3','UnBlockTCP4','UnBlockTCP5','UnBlockTCP6','UnBlockTCP7','UnBlockTCP8','UnBlockTCP9','UnBlockTCP10','UnBlockTCP11','UnBlockTCP12','UnBlockTCP13','UnBlockTCP14','UnBlockTCP15'
               ],
               [
                  'VerifyIperfPass1','VerifyIperfPass2','VerifyIperfPass3','VerifyIperfPass4','VerifyIperfPass5','VerifyIperfPass6','VerifyIperfPass7'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1-2]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add dvfilter-generic-1:add dvfilter-generic-2:add dvfilter-generic-3:add dvfilter-generic-4:add dvfilter-generic-5:add dvfilter-generic-6:add dvfilter-generic-7:add dvfilter-generic-8:add dvfilter-generic-9:add dvfilter-generic-10:add dvfilter-generic-11:add dvfilter-generic-12:add dvfilter-generic-13:add dvfilter-generic-14:add dvfilter-generic-15:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw-1 filter2:name:dvfilter-fw-2 filter3:name:dvfilter-fw-3 filter4:name:dvfilter-fw-4 filter5:name:dvfilter-fw-5 filter6:name:dvfilter-fw-6 filter7:name:dvfilter-fw-7 filter8:name:dvfilter-fw-8 filter9:name:dvfilter-fw-9 filter10:name:dvfilter-fw-10 filter11:name:dvfilter-fw-11 filter12:name:dvfilter-fw-12 filter13:name:dvfilter-fw-13 filter14:name:dvfilter-fw-14 filter15:name:dvfilter-fw-15 filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockTCP1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 100,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 200,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 300,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 400,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP5' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-5',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 500,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP6' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-6',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 600,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP7' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-7',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 700,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP8' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-8',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 800,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP9' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-9',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 900,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP10' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-10',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1000,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP11' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-11',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1100,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP12' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-12',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1200,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP13' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-13',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1300,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP14' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-14',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1400,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP15' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-15',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 1500,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'BlockTCP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 6000,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfFail1' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 100,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail2' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 200,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 300,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail4' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 400,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail5' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 500,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail6' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 600,
               'toolname' => 'iperf',
               'testduration' => '10',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'UnBlockTCP1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP5' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-5',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP6' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-6',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP7' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-7',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP8' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-8',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP9' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-9',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP10' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-10',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP11' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-11',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP12' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-12',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP13' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-13',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP14' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-14',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'UnBlockTCP15' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-15',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
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
            'VerifyIperfPass1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 700,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 800,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass3' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 900,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass4' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 1000,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass5' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 1100,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass6' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 1200,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfPass7' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 1300,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
         }
      },


      'dvFilterConfigModule' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterConfigModule',
         'Summary' => 'Add dvfilter-fw to protected VM',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterConfigModule',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ]
            ],
            'Duration' => 'time in seconds',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            }
         }
      },


      'dvFilterCrashProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterCrashProtectedVM',
         'Summary' => 'Crash protected Linux VM with filters and verify DVFilter',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterCrashProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'CrashLinuxVM'
               ],
               [
                  'CheckSUTHost'
               ],
               [
                  'ResetSUTVM'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw filter1:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFails' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '30',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'CrashLinuxVM' => {
               'Type' => 'Command',
               'command' => 'sleep 1;echo c > /proc/sysrq-trigger',
               'async' => '1',
               'testvm' => 'vm.[1]'
            },
            'CheckSUTHost' => {
               'Type' => 'Command',
               'command' => 'hostname',
               'testhost' => 'host.[1]'
            },
            'ResetSUTVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'operation' => 'reset'
            }
         }
      },


      'dvFilterDropTCP' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterDropTCP',
         'Summary' => 'Block TCP traffic to/from protected VM and , send/receive traffic and verify it fails',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterDropTCP',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[2].portgroup.[1]',
                        'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[1].portgroup.[1]',
                        'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                        'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                        'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                    '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                    }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                 'PowerOff'
               ],
               [
                 'DVFilterHostSetup'
               ],
               [
                 'AddDVFilter'
               ],
               [
                 'PowerOn'
               ],
               [
                 'SetTestNicIP'
               ],
               [
                 'BlockTCP'
               ],
               [
                 'VerifyTCPTrafficFails'
               ],
               [
                 'UnBlockTCP'
               ],
               [
                 'VerifyTCPTrafficPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilter' => {
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
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockTCP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 12865,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]',
            },
            'VerifyTCPTrafficFails' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'portnumber' => '12865',
               'toolname' => 'netperf',
               'testduration' => '30',
               'bursttype' => 'RR',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'noofinbound' => '1'
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
            'VerifyTCPTrafficPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'l4protocol' => 'TCP',
               'testduration' => '30',
               'portnumber' => '12865',
               'toolname' => 'netperf',
               'noofinbound' => '1',
               'bursttype' => 'RR'
            }
         }
      },


      'dvFilterDropUDP' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterDropUDP',
         'Summary' => 'Drop UDP to/from protected VM and generate UDP traffic and verify it fails',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterDropUDP',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockUDP'
               ],
               [
                  'VerifyUDPTrafficFails'
               ],
               [
                  'UnBlockUDP'
               ],
               [
                  'VerifyUDPTrafficPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilter' => {
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
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockUDP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 12865,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyUDPTrafficFails' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'UDP',
               'testduration' => '30',
               'portnumber' => 12865,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            },
            'UnBlockUDP' => {
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
            'VerifyUDPTrafficPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'l4protocol' => 'UDP',
               'testduration' => '30',
               'portnumber' => 12865,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            }
         }
      },


      'dvFilterFSR' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterFSR',
         'Summary' => 'Run DVFilter FSR on DVFilter fastpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterFSR',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'HotAddVNIC'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]',
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'HotAddVNIC' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vnic' => {
                  '[2]' => {
                     'portgroup' => 'host.[1].portgroup.[1]',
                     'driver' => 'vmxnet3'
                  }
               }
            },
            'ClearDVFilterCtl' => {
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
            }
         }
      },


      'dvFilterICMP' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterDropICMP,dvFilterICMPDelay,dvFilterICMPCopyDelay,dvFilterICMPCopy',
         'Summary' => 'Run all ICMP test cases on DVFilter fastpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterICMPTest',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'DelayICMP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'DelayCopyICMP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'SetCopyICMP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]',
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0,
                  'delay' => 0,
                  'copy' => 0,
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'DelayICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1,
                  'delay' => 100
               },
               'vm' => 'vm.[1]'
            },
            'DelayCopyICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1,
                  'copy' => 1,
                  'delay' => 100
               },
               'vm' => 'vm.[1]'
            },
            'SetCopyICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1,
                  'copy' => 1,
                  'delay' => 0
               },
               'vm' => 'vm.[1]'
            }
         }
      },


      'dvFilterKillProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterKillProtectedVM',
         'Summary' => 'Kill protected VM with filters and verify the filter is intact after powering on the VM',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterKillProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'KillVM'
               ],
               [
                  'VerifyDVFilterNotExist'
               ],
               [
                  'PowerOn'
               ],
               [
                  'VerifyDVFilterExist'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic-1:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw-1 filter0:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFails' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'KillVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'operation' => 'killvm'
            },
            'VerifyDVFilterNotExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'expectedresult' => 'FAIL',
               'getdvfiltername' => 'dvfilter-generic-1'
            },
            'VerifyDVFilterExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'getdvfiltername' => 'dvfilter-generic-1'
            }
         }
      },


      'dvFilterMaxVnicsInProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterMaxVnicsInProtectedVM',
         'Summary' => 'Add dvfilter-fw and dvfilter-dummy to multiple vnics in protected VM',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterMaxVnicsInProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1-4]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     },
                     '[5-8]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ]
            ],
            'ExitSequence' => [
               [
                  'HotRemove'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1-8],vm.[2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1-8]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'HotRemove' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'deletevnic' => 'vm.[1].vnic.[2],vm.[1].vnic.[3],vm.[1].vnic.[4],vm.[1].vnic.[5],vm.[1].vnic.[6],vm.[1].vnic.[7],vm.[1].vnic.[8]'
            }
         }
      },


      'dvFilterProcessPacket' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterProcessPacket',
         'Summary' => 'Run the test case of fake  processing packet on DVFilter fastpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterProcessPacket',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'FakeProcess'
               ],
               [
                  'VerifyNetperfPass'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'fakeprocessing' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'FakeProcess' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 5000,
                  'fakeprocessing' => 500,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyNetperfPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'portnumber' => '5000',
               'toolname' => 'netperf',
               'testduration' => '60',
               'bursttype' => 'RR',
               'noofoutbound' => '1',
               'l4protocol' => 'TCP',
               'noofinbound' => '1'
            }
         }
      },


      'dvFilterRebootProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterRebootProtectedVM',
         'Summary' => 'Reboot protected VM with filters and verify the filter is intact after the reboot',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterRebootProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'Reboot'
               ],
               [
                  'VerifyDVFilterExist'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'UnBlockICMP'
               ],
               [
                  'VerifyPingPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic-1:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw-1 filter0:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFails' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Reboot' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'operation' => 'reboot'
            },
            'VerifyDVFilterExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'getdvfiltername' => 'dvfilter-generic-1'
            },
            'UnBlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testduration' => '1000',
               'toolname' => 'ping',
               'noofinbound' => '1'
            }
         }
      },


      'dvFilterShutdownProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterShutdownProtectedVM',
         'Summary' => 'Shutdown protected VM with filters and verify the filter is gone after shutdown',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterShutdownProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'Shutdown'
               ],
               [
                  'VerifyDVFilterNotExist'
               ],
               [
                  'PowerOn'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic-1:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw-1 filter0:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFails' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'Shutdown' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'operation' => 'shutdown'
            },
            'VerifyDVFilterNotExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'expectedresult' => 'FAIL',
               'getdvfiltername' => 'dvfilter-generic-1'
            }
         }
      },


      'dvFilterStress' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterStress',
         'Summary' => 'Run the test case of Stress on DVFilter fastpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterStress',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMPTCPUDP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'VerifyIperfFail'
               ],
               [
                  'VerifyPingFail',
                  'VerifyIperfFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass',
                  'VerifyIperfPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'BlockICMPTCPUDP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 56001,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'VerifyIperfFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 56001,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'fakeprocessing' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfPass' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 56001,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            }
         }
      },


      'dvFilterSuspendResumeProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSuspendResumeProtectedVM',
         'Summary' => 'Suspend the protected VM with filters and verify the filter is intact after gets recreated after resuming the VM',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSuspendResumeProtectedVM',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilter'
               ],
               [
                  'PowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFails'
               ],
               [
                  'SuspendVM'
               ],
               [
                  'VerifyDVFilterNotExist'
               ],
               [
                  'ResumeVM'
               ],
               [
                  'VerifyDVFilterExist'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'PowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic-1:add)'
            },
             'AddDVFilter' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw-1 filter0:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'BlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFails' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '10',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1'
            },
            'SuspendVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'suspend'
            },
            'VerifyDVFilterNotExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'expectedresult' => 'FAIL',
               'getdvfiltername' => 'dvfilter-generic-1'
            },
            'ResumeVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'resume'
            },
            'VerifyDVFilterExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'getdvfiltername' => 'dvfilter-generic-1'
            }
         }
      },


      'dvFilterUnknownFilter' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterUnknownFilter',
         'Summary' => 'Add an unknown dvfilter and verify it fails',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterUnknownFilter',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'PowerOff'
               ],
               [
                  'HostOperation_1'
               ],
               [
                  'HostOperation_2'
               ],
               [
                  'PowerOn'
               ],
               [
                  'VerifyDVFilterExist'
               ]
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
               'adddvfilter' => 'qw(filter0:name:dvfilter-unknown filter0:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'PowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'VerifyDVFilterExist' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'expectedresult' => 'FAIL',
               'getdvfiltername' => 'dvfilter-unknown'
            }
         }
      },


      'dvFilterVerifyFilterOrder' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterVerifyFilterOrder',
         'Summary' => 'Run DVFilter NAT on DVFilter fastpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterVerifyFilterOrder',
         'TestbedSpec' => {
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
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
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'SetDVFilterCtl1'
               ],
               [
                  'SetDVFilterCtl2'
               ],
               [
                  'SetDVFilterCtl3'
               ],
               [
                  'SetDVFilterCtl4'
               ],
               [
                  'VerifyIperfNATPass'
               ],
               [
                  'ClearDVFilterCtl1'
               ],
               [
                  'ClearDVFilterCtl2'
               ],
               [
                  'ClearDVFilterCtl3'
               ],
               [
                  'ClearDVFilterCtl4'
               ],
               [
                  'VerifyIperfPass'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add dvfilter-generic-1:add dvfilter-generic-2:add dvfilter-generic-3:add dvfilter-generic-4:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw-1 filter2:name:dvfilter-fw-2 filter3:name:dvfilter-fw-3 filter4:name:dvfilter-fw-4)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'ping',
               'noofinbound' => '1'
            },
            'SetDVFilterCtl1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'dnaptport' => 20000,
                  'outbound' => 0,
                  'tcp' => 10000,
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'dnaptport' => 10000,
                  'outbound' => 0,
                  'tcp' => 5000,
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'dnaptport' => 10000,
                  'outbound' => 1,
                  'tcp' => 20000,
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'dnaptport' => 5000,
                  'outbound' => 1,
                  'tcp' => 10000,
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfNATPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'natedport' => 5000,
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            },
            'ClearDVFilterCtl1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'udp' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfPass' => {
               'Type' => 'Traffic',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'noofinbound' => '1'
            }
         }
      },


      'dvFilterVerifyOrderAfterVMotion' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'VerifyFilterOrderAfterVMotion',
         'Summary' => 'Verify DVFilter Order during vmotion on DVFilter setting',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::VerifyFilterOrderAfterVMotion',
         'TestbedSpec' => {
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               },
               '[1]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[1].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               }
            },
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'datastoreType' => 'shared',
                  'host' => 'host.[1]'
               }
            },
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1-2]'
                     }
                  },
                  'dvportgroup' => {
                     '[1]' => {
                        'vds'=> 'vc.[1].vds.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1-2]',
                        'vmnicadapter' => 'host.[1-2].vmnic.[2]',
                        'numuplinkports' => '3'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'EnableHostVMotion'
               ],
               [
                  'ChangePortgroup'
               ],
               [
                  'VerifyIperfPass'
               ],
               [
                  'SetDVFilterCtl1'
               ],
               [
                  'SetDVFilterCtl2'
               ],
               [
                  'SetDVFilterCtl3'
               ],
               [
                  'SetDVFilterCtl4'
               ],
               [
                  'VerifyIperfNATPass',
                  'Vmotion'
               ],
               [
                  'ClearDVFilterCtl1'
               ],
               [
                  'ClearDVFilterCtl2'
               ],
               [
                  'ClearDVFilterCtl3'
               ],
               [
                  'ClearDVFilterCtl4'
               ],
               [
                  'ChangeBackPortgroup'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1-2]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add dvfilter-generic-1:add dvfilter-generic-2:add dvfilter-generic-3:add dvfilter-generic-4:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw-1 filter2:name:dvfilter-fw-2 filter3:name:dvfilter-fw-3 filter4:name:dvfilter-fw-4)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'EnableHostVMotion' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1-2].vmknic.[1]',
               'configurevmotion' => 'ENABLE',
               'ipv4' => 'auto'
            },
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyIperfPass' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetDVFilterCtl1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 0,
                  'dnaptport' => 20000,
                  'tcp' => 10000
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 0,
                  'dnaptport' => 10000,
                  'tcp' => 5000
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 1,
                  'dnaptport' => 10000,
                  'tcp' => 20000
               },
               'vm' => 'vm.[1]'
            },
            'SetDVFilterCtl4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'outbound' => 1,
                  'dnaptport' => 5000,
                  'tcp' => 10000
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfNATPass' => {
               'Type' => 'Traffic',
               'natedport' => 5000,
               'l4protocol' => 'TCP',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'testduration' => '60',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmotion' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'priority' => 'high',
               'vmotion' => 'roundtrip',
               'dsthost' => 'host.[2]',
               'staytime' => '40'
            },
            'ClearDVFilterCtl1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'outbound' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0,
                  'tcp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'outbound' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0,
                  'tcp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl3' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-3',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'outbound' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0,
                  'tcp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ClearDVFilterCtl4' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-4',
               'dvfilterconfigspec' => {
                  'inbound' => 0,
                  'outbound' => 0,
                  'delay' => 0,
                  'dnaptport' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0,
                  'tcp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ChangeBackPortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true'
            }
         }
      },


      'dvFilterVmotion2DiffFilter' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterVmotion2DiffFilter',
         'Summary' => 'Test vmotion with two filters',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterVmotion2DiffFilter',
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
                        'vds'=> 'vc.[1].vds.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1-2]',
                        'vmnicadapter' => 'host.[1-2].vmnic.[2]',
                        'numuplinkports' => '3'
                     }
                  }
               },
            },
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1-2]' => {
                        'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[2].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                        'portgroup' => 'host.[2].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                        'driver' => 'any'
                     }
                  }
               },
               '[1]' => {
                  'portgroup' => {
                     '[1-2]' => {
                        'vss' => 'host.[1].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                        'configureuplinks' => 'add',
                        'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                        'portgroup' => 'host.[1].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                        'driver' => 'any'
                     }
                  }
               }
            },
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[2].portgroup.[1]',
                        'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'datastoreType' => 'shared',
                  'vnic' => {
                     '[1]' => {
                        'portgroup' => 'host.[1].portgroup.[1]',
                        'driver' => 'vmxnet3'
                     }
                  },
                  'host' => 'host.[1]'
               }
            },
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'EnableHostVMotion'
               ],
               [
                  'ChangePortgroup'
               ],
               [
                  'VerifyIperfPass'
               ],
               [
                  'DVFilterBlockTCP1'
               ],
               [
                  'DVFilterBlockTCP2'
               ],
               [
                  'VerifyIperfFail1',
                  'VerifyIperfFail2',
                  'Vmotion'
               ],
               [
                  'ClearDVFilterCtl1'
               ],
               [
                  'ChangeBackPortgroup'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1-2]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add dvfilter-generic-1:add dvfilter-generic-2:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-fw-1 filter2:name:dvfilter-fw-2)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'EnableHostVMotion' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1-2].vmknic.[1]',
               'configurevmotion' => 'ENABLE',
               'ipv4' => 'auto'
            },
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'driver' => 'vmxnet3',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyIperfPass' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 5000,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DVFilterBlockTCP1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 1,
                  'udp' => 0,
                  'tcp' => 5000,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'DVFilterBlockTCP2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-2',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 1,
                  'udp' => 0,
                  'tcp' => 6000,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfFail2' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 6000,
               'toolname' => 'iperf',
               'testduration' => '60',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyIperfFail1' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 5000,
               'toolname' => 'iperf',
               'testduration' => '60',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmotion' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'priority' => 'high',
               'vmotion' => 'roundtrip',
               'dsthost' => 'host.[2]',
               'staytime' => '40'
            },
            'ClearDVFilterCtl1' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic-1,dvfilter-generic-2',
               'dvfilterconfigspec' => {
               'delay' => 0,
               'outbound' => 0,
               'tcp' => 0,
               'fakeprocessing' => 0,
               'inbound' => 0,
               'copy' => 0,
               'udp' => 0,
               'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ChangeBackPortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'host.[1].portgroup.[1]'
            }
         }
      },


      'dvFilterVmotionOrdering' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterVmotionOrdering',
         'Summary' => 'Test vmotion ordering on DVFilter setting',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterVmotionOrdering',
         'TestbedSpec' => {
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               },
               '[1]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[1].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               }
            },
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'datastoreType' => 'shared',
                  'host' => 'host.[1]'
               }
            },
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1-2]'
                     }
                  },
                  'dvportgroup' => {
                     '[1]' => {
                        'vds'=> 'vc.[1].vds.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1-2]',
                        'vmnicadapter' => 'host.[1-2].vmnic.[2]',
                        'numuplinkports' => '3'
                     }
                  }
               },
            },
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'EnableHostVMotion'
               ],
               [
                  'ChangePortgroup'
               ],
               [
                  'VerifyIperfPass'
               ],
               [
                  'DVFilterBlockTCP'
               ],
               [
                  'VerifyIperfFail',
                  'Vmotion'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'ChangeBackPortgroup'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1-2]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'EnableHostVMotion' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1-2].vmknic.[1]',
               'configurevmotion' => 'ENABLE',
               'ipv4' => 'auto'
            },
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyIperfPass' => {
               'Type' => 'Traffic',
               'l4protocol' => 'TCP',
               'testduration' => '10',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DVFilterBlockTCP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'udp' => 0,
                  'outbound' => 1,
                  'tcp' => 20000,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'VerifyIperfFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'TCP',
               'portnumber' => 20000,
               'toolname' => 'iperf',
               'testduration' => '60',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmotion' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'priority' => 'high',
               'vmotion' => 'roundtrip',
               'dsthost' => 'host.[2]',
               'staytime' => '40'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'delay' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'fakeprocessing' => 0,
                  'inbound' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0
               },
               'vm' => 'vm.[1]'
            },
            'ChangeBackPortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true'
            }
         }
      },


      'dvFilterVmotionProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterVmotionProtectedVM',
         'Summary' => 'Test vmotion on DVFilter setting',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterVmotionProtectedVM',
         'TestbedSpec' => {
            'host' => {
               '[2]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[2].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[2].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               },
               '[1]' => {
                  'portgroup' => {
                     '[1-2]' => {
                       'vss' => 'host.[1].vss.[1]'
                     }
                  },
                  'vss' => {
                     '[1]' => {
                       'configureuplinks' => 'add',
                       'vmnicadapter' => 'host.[1].vmnic.[1]'
                     }
                  },
                  'vmknic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[2]'
                     }
                  },
                  'vmnic' => {
                     '[1-2]' => {
                       'driver' => 'any'
                     }
                  }
               }
            },
            'vm' => {
               '[2]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[2].portgroup.[1]',
                       'driver' => 'e1000'
                     }
                  },
                  'host' => 'host.[2]'
               },
               '[1]' => {
                  'vnic' => {
                     '[1]' => {
                       'portgroup' => 'host.[1].portgroup.[1]',
                       'driver' => 'vmxnet3'
                     }
                  },
                  'datastoreType' => 'shared',
                  'host' => 'host.[1]'
               }
            },
            'vc' => {
               '[1]' => {
                  'datacenter' => {
                     '[1]' => {
                        'host' => 'host.[1-2]'
                     }
                  },
                  'dvportgroup' => {
                     '[1]' => {
                        'vds'=> 'vc.[1].vds.[1]'
                     }
                  },
                  'vds' => {
                     '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1-2]',
                        'vmnicadapter' => 'host.[1-2].vmnic.[2]',
                        'numuplinkports' => '3'
                     }
                  }
               }
            }
         },
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'SUTPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'SUTPowerOn'
               ],
               [
                  'SetTestNicIP'
               ],
               [
                  'EnableHostVMotion'
               ],
               [
                  'ChangePortgroup'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'DVFilterBlockICMP'
               ],
               [
                  'VerifyPingFail',
                  'Vmotion'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'ChangeBackPortgroup'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'SUTPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1-2]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
            },
             'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-fw)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'SUTPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'vmstate' => 'poweron'
            },
            'SetTestNicIP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv4' => 'auto'
            },
            'EnableHostVMotion' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1-2].vmknic.[1]',
               'configurevmotion' => 'ENABLE',
               'ipv4' => 'auto'
            },
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testduration' => '10',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DVFilterBlockICMP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'inbound' => 1,
                  'outbound' => 1,
                  'udp' => 0,
                  'tcp' => 0,
                  'icmp' => 1
               },
               'vm' => 'vm.[1]'
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '70',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmotion' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'priority' => 'high',
               'vmotion' => 'roundtrip',
               'dsthost' => 'host.[2]',
               'staytime' => '40'
            },
            'ClearDVFilterCtl' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'dvfilterctl' => 'dvfilter-generic',
               'dvfilterconfigspec' => {
                  'delay' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'fakeprocessing' => 0,
                  'inbound' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0
               }
            },
            'ChangeBackPortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true'
            }
         }
      },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for DVFilter.
#
# Input:
#       None.
#
# Results:
#       An instance/object of DVFilter class.
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
   my $self = $class->SUPER::new(\%DVFilter);
   return (bless($self, $class));
}
