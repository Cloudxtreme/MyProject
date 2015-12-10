#!/usr/bin/perl
########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Internal::VDNet::SampleTds;

#
# This file contains the structured hash for category, Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("UnitTest");

   %Sample = (
      'UnitTest'   => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "UnitTest",
         Version          => "2" ,
         Tags              => "unit,precheckin",
         Summary          => "This test case verifies the host ".
                             "initialization part of testbed version2",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         # ;; separated list of hosts, can be given
                         host  => "host.[1]",
                     },
                     '[2]'   => {
                        name  => "auto",
                     },
                  },
                  vds   => {
                     '[1-2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[3]'   => {
                        datacenter  => "vc.[1].datacenter.[2]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "3",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[2]",
                        dvport   => {
                         '[1]' => {
                          },
                        },
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[2]",
                        dvport   => {
                         '[1-3]' => {
                          },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                        name => "firstvswitch", # only an optional key,
                                                # not recommended
                                                # to use
                     },
                     '[2]'   => { # create VSS
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1-3]'   => { # create a vm portgroup on vss
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => { # create 2 vmknic on vss 1
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                     '[2]'   => { # create 2 vmknic on vss 1
                        portgroup  => "host.[1].portgroup.[2]",
                     },
                     '[3]'   => { # create 1 more vmknic on vds1
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                     '[2]'   => {
                        driver => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[2]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                     '[2]'   => {
                        driver => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[2]",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [],
         },
      },

      'VDRPreCheckIn' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "DeployVDREdge",
         Tags             => "precheckin",
         Version          => "2" ,
         Summary          => "This is the edge deployment testcase ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['Install_Config_ClusterSJC'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                        ],
            'SetSegmentIDRange'  => SET_SEGMENTID_RANGE,
            'SetMulticastRange'  => SET_MULTICAST_RANGE,
            'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
            'CreateVirtualWires' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'Install_Config_ClusterSJC' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
         },
      },

      'SamplePrePostProcess' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "SamplePrePostProcess",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies the PreProcess ".
                              "and PostProcess handling of workload API's",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            host  => {
               '[1]'   => {
                  vss    => {
                     '[1]'   => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => { # create a vm portgroup on vss
                        vss  => "host.[1].vss.[1]",
                        vlan => "200",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                        ipv6     => "ADD",
                        ipv6addr => "2001:bd6::c:2957:156",
                        mtu      => "1600",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                        connected => 1,
                        startconnected => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [],
            Duration     => "time in seconds",
         },
      },

      'LinkUnitTest' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "LinkUnitTest",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies the end to end code ".
                              "flow of Sub Component Configuration",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        'lag' => {
                           '[1-3]' => {
                               'lagtimeout' => 'short',
                               host => "host.[1]",
                              },
                           },
                        'mtu' => '1450',
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddMoreLAG"], ["DeleteAllLAG"]],
            Duration     => "time in seconds",
            "AddMoreLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               'lag' => {
                  '[4-5]' => {
                     'lagtimeout' => 'short',
                     host => "host.[1]",
                     },
                  },
            },
            "DeleteAllLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               DeleteLag    => "vc.[1].vds.[1].lag.[-1]",
            },
         },
      },

      'LACPUnitTest' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "LACPUnitTest",
         Version           => "2",
         Summary           => "This test case verifies LACP APIs",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1]",
                        'lag' => {
                           '[1-2]' => {
                              'lagtimeout' => 'short',
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["SetActiveUplink"],["AddUplinkToLag"]],
            Duration     => "time in seconds",
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1-2]",
               failoverorder => "vc.[1].vds.[1].lag.[2]",
               failovertype  => "active",
            },
            "AddUplinkToLag" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag   => "add",
               vmnicadapter => "host.[1].vmnic.[1-2]",
            },
         },
      },

      'APIPrecheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "APIPrecheckIn",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies behaviour of iterator" .
                              " and constrant database code.",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'nvpcontroller' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddTransportZoneWithMagic"],
                             ["AddTransportZone"],
                             ["AddTransportZoneNegative"]],
            Duration     => "time in seconds",
            "AddTransportZoneWithMagic" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               transportzone => {
                  '[1]' => {
                     'name' => "magic",
                     'tags' => [
                        {
                         'Tag' =>
                           {
                            'tag' => 'TAG1234567891234567891234567891234567890',
                            'scope' => "magic"
                           }
                        }
                     ],
                  },
               },
            },
            "AddTransportZone" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               transportzone => {
                  '[1]' => {
                     'name' => "TZ1",
                     'tags' => [
                        {
                         'Tag' =>
                           {
                            'tag' => 'TAG1234567891234567891234567891234567890',
                            'scope' => "scope1"
                           }
                        }
                     ],
                     'expectedresultcode' => "201",
                     'metadata' => {
                       'expectedValue' => "name:<Uuid>, scope:scope1"
                     },
                  },
               },
            },
            "AddTransportZoneNegative" => {
               Type          => "NSX",
               TestNSX       => "nvpcontroller.[1]",
               transportzone => {
                  '[1]' => {
                     'name' => "T1234567890123456789012345678901234567890",
                     'tags' => [
                        {
                         'Tag' =>
                           {
                            'tag' => 'TAG1234567891234567891234567891234567890',
                            'scope' => "scope1"
                           }
                        }
                     ],
                     'expectedresultcode' => "400",
                     'metadata' => {
                       'expectedValue' => "name:<Uuid>, scope:scope1"
                     },
                  },
               },
            },
         },
      },



      'DatacenterPreCheckIn'   => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "DatacenterPreCheckIn",
         Version          => "2" ,
         Tags              => "",
         Summary          => "This test case verifies the datacenter ".
                             "initialization part of testbed version2",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        host  => "host.[1];;host.[2]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
               },
               '[2]' => {
               },
            },
         },

         WORKLOADS => {
            Sequence     => [['RemoveHostFromDC']],
            Duration     => "time in seconds",

            "RemoveHostFromDC" => {
               Type              => "Datacenter",
               TestDatacenter    => "vc.[1].datacenter.[1]",
               DeleteHostsFromDC => "host.[1];;host.[2]",
            },
         },
      },

      'SpirentTrafficPreCheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "SpirentTrafficPreCheckIn",
         Version           => "2",
         Summary           => "This is the precheck-in unit test case ".
                              "for Spirent Traffic Workload related changes",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup  => {
                     '[1-2]' => { # create a vm portgroup on vss
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        switch => "host.[1].vss.[1]",
			portgroup => "host.[1].portgroup.[2]",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup  => {
                     '[1-2]' => { # create a vm portgroup on vss
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        switch => "host.[2].vss.[1]",
			portgroup => "host.[2].portgroup.[2]",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {     # Let this be a Spirent VM
                  host  => "host.[1]",
		  type  => "spirent",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                        label      => "Network adapter 2",
                     },
                  },
               },
               '[2]'   => {     # Let this be a Spirent VM
                  host  => "host.[2]",
		  type  => "spirent",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[2].portgroup.[1]",
                        label      => "Network adapter 2",
                     },
                  },
               },
               '[3]'   => {     # Let this be a Non-Spirent VM
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[2].portgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [['TRAFFIC_1'],['TRAFFIC_2']],
            Duration     => "time in seconds",

	    # Frame structure is: "eth:ip:data"
            "TRAFFIC_1" => {
               Type            => "Traffic",
               ToolName        => "spirent",
               NoofOutbound    => "4",           # 4 Parallel Streams
               TestDuration    => "20",
               TestAdapter     => "vm.[1-2].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1],host.[1-2].vmknic.[1],",
               StreamBlockSize => "1024",
               StreamBlockType => "Fixed",
	       Stream	       =>  {
				      srcMac	=> "",   # Optional
				      dstMac	=> "",   # Optional
				      payload => {
						srcIP	   => "",   # Optional
						dstIP	   => "",   # Optional
						TimeToLive => "50", # Optional
						DSCP       => "38",
				      },
				   },
            },
	    # Frame structure is: "eth:ip:ip:data"
            "TRAFFIC_2" => {
               Type            => "Traffic",
               ToolName        => "spirent",
               NoofOutbound    => "4",           # 4 Parallel Streams
               TestDuration    => "20",
               TestAdapter     => "vm.[1-2].vnic.[1]",
               SupportAdapter  => "host.[1-2].vmknic.[1],",
               StreamBlockSize => "1024",
               StreamBlockType => "Fixed",
               Stream          =>  {
                                      srcMac    => "",   # Optional
                                      dstMac    => "",   # Optional
                                      payload => {
                                                srcIP      => "",   # Optional
                                                dstIP      => "",   # Optional
                                                TimeToLive => "50", # Optional
                                                DSCP       => "38",
						payload => {
                                                   srcIP      => "",   # Optional
                                                   dstIP      => "",   # Optional
                                                   TimeToLive => "50", # Optional
                                                   DSCP       => "38"
						},
                                      },
                                   },
               Verificaion    => "Verification_1",
            },
            "Verification_1" => {
               'Verificaton' => {

                  #
                  # Sprirent Verification should not need the target.
                  # As the verification is done at the port level.
                  verificationtype   => "Spirent",
                  Tx                 => "2000+",
                  Rx                 => "1500+",
                  DSCPPacketsRcvd    => "1000+",
                  AvgTransferDelay   => "5-",   # Lesser than 5 micro second
                  MaxFrameLengthRcvd => "160+",
                  MinFrameLengthRcvd => "128+",
                  PercentageOfDroppedFramess  => "10-", # Less than 10%
               },
            },
         },
      },

      'TrafficPreCheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "TrafficPreCheckIn",
         Version           => "2",
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for Traffic Workload related changes",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup  => {
                     '[1-2]' => { # create a vm portgroup on vss
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                     '[2]'   => {
                        portgroup  => "host.[1].portgroup.[2]",
                     },
                  },
               },
            },
            vm  => {
               '[1-2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1-2]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
             Sequence     => [['TRAFFIC_1'],['TRAFFIC_2'],
                              ['TRAFFIC_3'],['TRAFFIC_4'],
                              ['TRAFFIC_5'],['TRAFFIC_6'],
                              ['TRAFFIC_8'],['TRAFFIC_7'],
                              ],
            Duration     => "time in seconds",

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               BurstType      => "stream",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_1",
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               SleepBetweenCombos => "20",
               NoofInbound    => "2",
               RoutingScheme  => "broadcast,flood",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TRAFFIC_3" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_1",
            },
            "TRAFFIC_4" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               TestDuration   => "10",
                Verification  => "Verification_1",
            },
            "TRAFFIC_5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L3Protocol     => "ipv6",
               TestDuration   => "3",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_1",
            },
            "TRAFFIC_6" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_2",
            },
            "TRAFFIC_7" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               BurstType      => "stream",
               NoofOutbound   => "1",
               TestDuration   => "10",
               Verification   => "Verification_3",
               ExpectedResult => "PASS",
            },
            "TRAFFIC_8" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               L3Protocol     => "ipv6",
               L4Protocol     => "tcp",
               BurstType      => "stream",
               NoofOutbound   => "1",
               TestDuration   => "10",
               Verification   => "Verification_4",
               ExpectedResult => "PASS",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 2000",
                  pktcount         => "400+",
                  badpkt           => "0",
               },
	       'Vsish' => {
		  verificationtype => "vsish",
		  Target => "src",
		  "/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK" => "10000+",
		  "/net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx" => "9-",
	       },
            },
            "Verification_3" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-syn != 0,dst host vm.[1].vnic.[1],src host ipv4/vm.[2].vnic.[1]",
                  pktcount         => "1+",
                  badpkt           => "0",
               },
            },
            "Verification_4" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-fin != 0,dst host ipv6/vm.[1].vnic.[1],src host ipv6/vm.[2].vnic.[1]",
                  pktcount         => "1+",
                  badpkt           => "0",
               },
            },
         },
      },

      'VCPreCheckIn' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VCPreCheckIn",
         Version          => "2" ,
         Tags              => "",
         Summary          => "This is the precheck-in unit test case ".
                             "for VC Workload related changes",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup      => {
                     '[1]'  => {
                        vds  => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss    => {
                     '[1]'   => {
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup  => {
                     '[1-2]' => { # create a vm portgroup on vss
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                     '[2]'   => {
                        portgroup  => "host.[1].portgroup.[2]",
			#mtu => "1500",
                     },
                  },
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [['OptOut_Enable'], ['RestartVC']],
            Duration     => "time in seconds",

            "OptOut_Enable" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               OPT            => "optout",
               TestSwitch     => "vc.[1].vds.[1]",
               TestHost       => "host.[1]",
               Value          => "0",
            },
            'RestartVC' => {
               Type      => "VC",
               TestVC    => "vc.[1]",
               operation => "restart",
               services  => "vpxd",
            },
         },
      },

      'VMPreCheckIn' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VMPreCheckIn",
         Version          => "2" ,
         Tags              => "precheckin",
         Summary          => "This is the precheck-in unit test case ".
                             "for VM Workload related changes",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1-2]'   => {
                        driver     => "e1000",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence   => [['SuspendResume'], ['DisconnectConnectvNic_B']],
            Duration   => "time in seconds",

            "SuspendResume" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               vmstate        => "suspend,resume",
            },
            "DisconnectConnectvNic_B" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               TestAdapter    => "vm.[1].vnic.[1],vm.[1].vnic.[2]",
               Operation      => "DISCONNECTVNIC,CONNECTVNIC",
            },
         },
      },

      'NetAdapterPreCheckIn' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "NetAdapterPreCheckIn",
         Version          => "2" ,
         Tags             => "",
         Summary          => "This is the precheck-in unit test case ".
                             "for NetAdapter Workload related changes",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        vmnicadapter => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence          => [['DisableEnablevNic']],

            "DisableEnablevNic" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1],host.[1].vmknic.[1]",
               DeviceStatus   => "DOWN,UP",
            },
         },
      },

      'VSSPreCheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "VSSPreCheckIn",
         Version           => "2" ,
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for VSS Workload related changes",
         ExpectedResult    => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                        mtu           => "6997",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence          => [['VSS_1']],
            Duration          => "time in seconds",
            "VSS_1" => {
               Type          => "Switch",
               TestSwitch    => "host.[1].vss.[1]",
               setbeacon     => "Disable",
            },
         },
      },

      'VDSPswitchPreCheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "VDSPswitchPreCheckIn",
         Version           => "2" ,
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for VDS Workload related changes",
         ExpectedResult    => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        host => "host.[1]",
                        mtu => "1500"
                     },
                  },
                  dvportgroup      => {
                     '[1-3]'  => {
                        vds  => "vc.[1].vds.[1]",
                     },
                     '[4]'  => {
                        name => "promiscuous_b",
                        vds  => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss    => {
                     '[1]'   => {
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configureuplinks => "add",
                        mtu => "1502",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
			#mtu         => "1503",
                        #ipv4address => "dhcp",
                     },
                  },
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                        mtu => "1504",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence          => [['RemoveUplink']],
            Duration          => "time in seconds",
            "RemoveUplink"  => {
                Type             => "Switch",
                TestSwitch       => "vc.[1].vds.[1]",
                VmnicAdapter     => "host.[1].vmnic.[1]",
                ConfigureUplinks => "remove",
            },
         },
      },

      'HostPreCheckIn' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "HostPreCheckIn",
         Version           => "2" ,
         Tags              => "",
         Summary           => "This is the precheck-in unit test case ".
                              "for Host and VSS related changes",
         ExpectedResult    => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        host => "host.[1]",
                        mtu => "1500"
                     },
                  },
                  dvportgroup      => {
                     '[1]'  => {
                        vds  => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence   => [['DisableHwLRO']],
            Duration          => "time in seconds",
            "DisableHwLRO"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Lro            => "disable",
               LroType        => "Hw",
            },
         },
      },

     'DVFilterPreCheckIn' => {
         Category         => 'ESX Server',
         Component        => 'vmsafe-net',
         Product          => 'ESX',
         TestName         => 'DVFilterPreCheckIn',
         Summary          => 'Precheckin test for DVFilter ' ,
         ExpectedResult   => 'PASS',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
               },
             },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
         },

     WORKLOADS => {
           Sequence => [['DVFilterHostSetup'] ],
          "DVFilterHostSetup" => {
               Type           => "DVFilter",
               TestDvfilter   => "vm.[1].x.x",
               Role           => "Host",
               TestAdapter    => "vm.[1].vnic.[1]",
               HostSetup      => "dvfilter-generic-hp",
             },
         },
     },

     'CreateComponentInWorkload'   => {
        Component        => "Infrastructure",
        Category         => "vdnet",
        TestName         => "CreateComponentInWorkload",
        Version          => "2" ,
        Tags             => "unit,precheckin",
        Summary          => "This test case verifies creating ".
                            "component in workloads and accessing " .
                            "it's object in another workload",
        ExpectedResult   => "The new component should be accessible " .
                            "in other workloads too",
        TestbedSpec      => {
           host  => {
              '[1]'   => {
                 vss   => {
                    '[1]'   => { # create VSS
                    },
                 },
                 netstack => {
                    '[1]' => {
                       'name'   => 'teststack',
                    },
                 },
                 portgroup => {
                    '[1-2]'   => { # create a portgroup on vss 1
                       vss  => "host.[1].vss.[1]",
                    },
                 },
                 vmknic => {
                    '[1]'   => { # create a vmknic on vss 1
                       portgroup  => "host.[1].portgroup.[1]",
                    },
                 },
              },
           },
        },
        WORKLOADS => {
           Sequence => [["AddVmk1"], ["Traffic_1"]],

           "AddVmk1" => {
              Type => "Host",
              TestHost => "host.[1]",
              vmknic => {
              "[2]" => {
                 ipv4address => "dhcp",
                 portgroup   => "host.[1].portgroup.[2]",
                 netstack    => "host.[1].netstack.[1]",
              },
              },
           },
           "Traffic_1" => {
              Type           => "Traffic",
              TestAdapter    => "host.[1].vmknic.[1]",
              SupportAdapter => "host.[1].vmknic.[2]",
              TestDuration   => "10",
           },
        },
     },


     'ClusterPreCheckIn'   => {
        TestName         => 'ClusterPreCheckIn',
        Category         => 'VDNet',
        Component        => 'Infrastructure',
        Product          => 'ESX',
        Summary          => 'Cluster support in setup and workload',
        Status           => 'Draft',
        AutomationLevel  => 'Manual',
        FullyAutomatable => 'Y',
        Developer        => 'vermap',
        Version          => '2',
        ExpectedResult  => 'PASS',

        TestbedSpec      => {
	       vc => {
	         '[1]' => {
                datacenter => {
                   '[1]' => {
                      cluster => {
                         '[1]' => {
                            host => "host.[1]",
                            clustername => "cluster1",
                            ha => 0,
                            drs => 0,
                            forceaddhost => "true",
                         },
		                 '[2]' => {
			                clustername => "cluster2",
		                 },
		              },
		           },
	            },
             },
           },

           host  => {
              '[1-2]'   => {
              },
           },
	    },
        WORKLOADS => {
           Sequence => [['CreateCluster_3'],['MoveHostFromCluster_1'],
              ['EditCluster'],['MoveHostToCluster_2'],['DeleteCluster_1'],
              ['RemoveHostFromCluster_3'],['DeleteCluster_3']],

           "CreateCluster_3" => {
              Type => "Datacenter",
              TestDatacenter => "vc.[1].datacenter.[1]",
              Cluster => {
                 '[3]' => {
                    host => "host.[2]",
                    clustername => "cluster3",
                    ha => 0,
                    drs => 0,
                    forceaddhost => "false",
                 },
              },
           },
           "EditCluster" => {
              Type => "Cluster",
              TestCluster => "vc.[1].datacenter.[1].cluster.[2-3]",
              EditCluster => "edit", # No use of values of this key
              HA   => 1,
              DRS  => 1,
           },
           "MoveHostToCluster_2" => {
              Type => "Cluster",
              TestCluster => "vc.[1].datacenter.[1].cluster.[2]",
              MoveHostsToCluster => "host.[1]",
           },
           "MoveHostFromCluster_1" => {
              Type => "Cluster",
              TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
              MoveHostsFromCluster => "host.[1]",
           },
           "RemoveHostFromCluster_3" => {
              Type => "Cluster",
              TestCluster => "vc.[1].datacenter.[1].cluster.[3]",
              RemoveHostsFromCluster => "host.[2]",
           },
           "DeleteCluster_1" => {
              Type => "Datacenter",
              TestDatacenter => "vc.[1].datacenter.[1]",
              deletecluster => "vc.[1].datacenter.[1].cluster.[1]",
           },
           "DeleteCluster_3" => {
              Type => "Datacenter",
              TestDatacenter => "vc.[1].datacenter.[1]",
              deletecluster => "vc.[1].datacenter.[1].cluster.[3]",
           },
        },
      },


      "CreateDeleteInstance" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "CreateDeleteInstance",
         Version          => "2" ,
         Summary          => "This test case verifies that traffic
                             can be run between vmknics which belongs to
                             different instances",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]'   => { # create a portgroup on vss 1
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup  => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]'   => { # create a portgroup on vss 1
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "host.[1].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup  => "host.[1].portgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp,udp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[1]",
                  pktcount           => "1000+",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[2]",
                  pktcount           => "3000+",
               },
            },
         },
       },


      'ParallelWorkload' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "ParallelWorkload",
         Version           => "2",
         Tags              => "precheckin",
         Summary           => "This test case verifies the execution of ".
                              "running workloads in parallel",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            host  => {
               '[1]'   => {
                  vss    => {
                     '[1]'   => {
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [['AddVmk1','AddPG3']],
            'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                  "[1]" => {
                     portgroup => "host.[1].portgroup.[1]",
                  },
               },
            },
            'AddPG3' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               portgroup => {
                  "[3]" => {
                      vss  => "host.[1].vss.[1]",
                  },
               },
            },
         },
      },


     "Netstack" => {
         Component        => "Infrastructure",
         Category         => "VDNet",
         TestName         => "Netstack",
         Version          => "2",
         Tags             => "",
         Summary          => "Precheckin test for netstack",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['AddNetstack1'],
                         ['AddVMK1'],['AddNetstack2'],
                         ['AddVMK2'],['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "10",
            },
             "Traffic2" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               TestDuration => "10",
            },
            "AddNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[3]" => {
                     name =>"test1",
                  },
               },
            },
            "AddNetstack2" => {
               Type => "Host",
               TestHost => "host.[2]",
               netstack => {
                  "[3]" => {
                     name =>"test1",
                  },
               },
            },
            "AddVMK1" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" => {
                  portgroup => "host.[1].portgroup.[2]",
                  netstack => "host.[1].netstack.[3]",
                  ipv4address => "dhcp",
               },
               },
            },
            "AddVMK2" => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[3]" => {
                  portgroup => "host.[2].portgroup.[2]",
                  netstack => "host.[1].netstack.[3]",
                  ipv4address => "dhcp",
               },
               },
            },
         },
      },
      'ScalabilityTest' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "ScalabilityTest",
         Version          => "2" ,
         Summary          => "This is to verify large scale deployment of VMs ".
                             "using vdnet",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
               },
            },
            vm  => {
               '[1-10]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1-2]'   => {
                        driver     => "e1000",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
               '[11-20]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1-2]'   => {
                        driver     => "e1000",
                        portgroup  => "host.[2].portgroup.[1]",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence   => [['poweroff']],
            "poweroff" => {
               Type           => "VM",
               TestVM         => "vm.[1-10]",
               Operation      => "poweroff",
            },
         },
      },
      'VSMComponents' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VSMComponents",
         Version          => "2" ,
         Summary          => "This is the precheck-in unit test case ",
         'TestbedSpec' => {
            'vsm' => {
               '[1]' => {
               },
            },
            'host' => {
               '[1]'  => {
               },
               '[2-3]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               }
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                        Cluster => {
                           '[1]' => {
                              host => "host.[1]",
                              clustername => "Demo-Controller-Cluster-$$",
                           },
                           '[2]' => {
                              host => "host.[2-3]",
                              clustername => "Demo-Compute-Cluster-$$",
                           },
                        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[2-3]",
                        vmnicadapter => "host.[2-3].vmnic.[1]",
                        numuplinkports => "1",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        name    => "dvpg-vlan16-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
                        name    => "dvpg-vlan17-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                     '[3]'   => {
                        name    => "dvpg-mgmt-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[2]",
                  vmstate => "poweroff",
               },
               '[2]'   => {
                  host  => "host.[3]",
                  vmstate => "poweroff",
               },
            },
         },
         'WORKLOADS' => {
                 'Sequence' => [
                 ['RegisterVCToVSM'],
                 ['CreateIPPool'],
                 ['DeployController'],
                 ['SetSegmentIDRange'],
                 ['SetMulticastRange'],
                 ['InstallVIBs_And_ConfigureVXLAN'],
                 ['CreateNetworkScope'],
                 # VXLAN test - VMs on same vWire
                 ['CreateVirtualWires'],
                 ['PlaceVMsOnVirtualWire'],
                 ['PoweronVM1','PoweronVM2'],
                 ['NetperfTest'],

                # VDR test - VXLAN to VXLAN rotuing
                ['DeployVSE'],
                ['CreateVXLANLIFs'],
                ['PlaceVM1OnvWire1','PlaceVM2OnvWire2'],
                ['SetVXLANIPVM1','SetVXLANIPVM2'],
                ['AddVXLANRouteVM1','AddVXLANRouteVM2'],
                ['NetperfTest'],

                # VDR test - VLAN to VLAN rotuing
                ['CreateVLANLIFs'],
                ['PlaceVM1OnVLAN16','PlaceVM2OnVLAN17'],
                ['SetVLANIPVM1','SetVLANIPVM2'],
                ['AddVLANRouteVM1','AddVLANRouteVM2'],
                ['NetperfTest'],
                 ],

            'RegisterVCToVSM' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               reconfigure => "true",
               vc => 'vc.[1]',
            },
            'CreateIPPool' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               ippool   => {
                  '[2]' => {
                     name => "VTEP-ippool-$$",
                     gateway => "172.20.0.1",
                     prefixlength => "16",
                     ipranges => ['172.20.0.5-172.20.0.20'],
                  },
                  '[1]' => {
                     name           => "demo-ippool-PromE-$$",
                     gateway        => "10.24.31.253",
                     prefixlength   => "22",
                     ipranges => ['10.24.29.25-10.24.29.28'],
                  },
#                  '[1]' => {
#                     name           => "demo-ippool-wdc-$$",
#                     gateway        => "10.138.112.253",
#                     prefixlength   => "25",
#                     ipranges       => ['10.138.112.168-10.138.112.170'],
#                  },
               },
            },
            'SetSegmentIDRange' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               Segmentidrange => {
                  '[1]' => {
                     name  => "demo-segmentid-$$",
                     begin => "10000",
                     end   => "11000",
                  },
               },
            },
            'SetMulticastRange' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               Multicastiprange => {
                  '[1]' => {
                     name  => "demo-multicastip-$$",
                     begin => "239.0.0.100",
                     end   => "239.0.0.200",
                  },
               },
            },
            "DeployController"   => {
               Type  => "VSM",
               TestVSM  => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name          => "Controller-1",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[1]",
                     host          => "host.[1]",
                  },
               },
            },
            'InstallVIBs_And_ConfigureVXLAN' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     vxlan        => "Configure",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "20",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "ETHER_CHANNEL",
                     ippool       => "vsm.[1].ippool.[2]",
                  },
               },
            },
            'UnConfigureVXLAN' => {
               Type        => 'Cluster',
               TestCluster => "vsm.[1].vdncluster.[1]",
               EditCluster => "1",
               vxlan       => "unconfigure",
            },
            'UnInstallVIBs' => {
               Type        => 'Cluster',
               TestCluster => "vsm.[1].vdncluster.[1]",
               EditCluster => "1",
               vibs        => "uninstall",
            },
            'CreateNetworkScope' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "demo-network-scope-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'CreateVirtualWires' => {
               Type      => "Scope",
               TestScope => "vsm.[1].networkscope.[1]",
               VirtualWire  => {
                  "[1]" => {
                     name     => "vWire-1-$$",
                     tenantid => "$$",
                  },
                  '[2]' => {
                     name     => "vWire-2-$$",
                     tenantid => "2",
                  },
               },
            },
            'PlaceVMsOnVirtualWire' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'RemovevNICFromVM1' => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'RemovevNICFromVM2' => {
               Type       => "VM",
               TestVM     => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'PlaceVM1OnvWire1' => {
               Type        => "NetAdapter",
	       reconfigure => "true",
	       testadapter => "vm.[1].vnic.[1]",
               portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            'PlaceVM2OnvWire2' => {
               Type        => "NetAdapter",
	       reconfigure => "true",
	       testadapter => "vm.[2].vnic.[1]",
               portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
            },
            'PlaceVM1OnVLAN16' => {
               Type        => "NetAdapter",
	       reconfigure => "true",
	       testadapter => "vm.[1].vnic.[1]",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            'PlaceVM2OnVLAN17' => {
               Type        => "NetAdapter",
	       reconfigure => "true",
	       testadapter => "vm.[2].vnic.[1]",
               portgroup   => "vc.[1].dvportgroup.[2]",
            },
            'PoweronVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PoweronVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            "SetVLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.16.1.5',
               netmask    => "255.255.0.0",
            },
            "SetVLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.17.1.5',
               netmask    => "255.255.0.0",
            },
            "AddVLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.0.0",
               route      => "add",
               network    => "172.17.0.0",
               gateway    => "172.16.1.1",
            },
            "AddVLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.0.0",
               route      => "add",
               network    => "172.16.0.0",
               gateway    => "172.17.1.1",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.31.1.5',
               netmask    => "255.255.0.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.1.5',
               netmask    => "255.255.0.0",
            },
            "AddVXLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.0.0",
               route      => "add",
               network    => "172.32.0.0",
               gateway    => "172.31.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.0.0",
               route      => "add",
               network    => "172.31.0.0",
               gateway    => "172.32.1.1",
            },
            "NetperfTest" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               TestDuration   => "30",
            },
            "DeployVSE"   => {
               Type    => "VSM",
               TestVSM => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "VSE-demo-$$",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
		     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]", # To pick datastore
		     portgroup     => "vc.[1].dvportgroup.[3]",
                  },
               },
            },
            'CreateVXLANLIFs' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
		     name        => "lif-demo-vwire-1-$$",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
		     type        => "internal",
                     connected   => 1,
		     addressgroup => [{addresstype => "primary",
				       ipv4address => "172.31.1.1",
		                       netmask     => "255.255.0.0",}]
                  },
                  '[2]'   => {
		     name        => "lif-demo-vwire2-$$",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
		     type        => "internal",
                     connected   => 1,
		     addressgroup => [{addresstype => "primary",
				       ipv4address => "172.32.1.1",
		                       netmask     => "255.255.0.0",}]
                  },
               },
            },
            'CreateVLANLIFs' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[3]'   => {
		     name        => "lif-demo-16-$$",
                     portgroup   => "vc.[1].dvportgroup.[1]",
		     type        => "internal",
                     connected   => 1,
		     addressgroup => [{addresstype => "primary",
				       ipv4address => "172.16.1.1",
		                       netmask     => "255.255.0.0",}]
                  },
                  '[4]'   => {
		     name        => "lif-demo-17-$$",
                     portgroup   => "vc.[1].dvportgroup.[2]",
		     type        => "internal",
                     connected   => 1,
		     addressgroup => [{addresstype => "primary",
				       ipv4address => "172.17.1.1",
		                       netmask     => "255.255.0.0",}]
                  },
               },
            },
            'DeleteNetworkScope' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               deletenetworkscope => "vsm.[1].networkscope.[1]",
             },
            'DeleteVirtualWires' => {
               Type  => "Scope",
               TestScope   => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[4-5]",
            },
            'DeleteIPPool' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
	       deleteippool => "vsm.[1].ippool.[1]",
            },
            'DeleteSegmentIDRange' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               deleteSegmentidrange => "vsm.[1].segmentidrange.[1]",
            },
            'DeleteMulticastRange' => {
               Type => 'VSM',
               TestVSM => "vsm.[1]",
               deleteMulticastiprange => "vsm.[1].multicastiprange.[1]",
            },
            "DeleteController"   => {
               Type  => "VSM",
               TestVSM  => "vsm.[1]",
               deletevxlancontroller => "vsm.[1].vxlancontroller.[1]",
            },
         },
      },,
      'NeutronComponents' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "NeutronComponents",
         Version          => "2" ,
         Summary          => "This is the precheck-in unit test case ",
         'TestbedSpec' => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         'WORKLOADS' => {
                 'Sequence' => [
                 ['VSMRegistration'],
                 ],

            'VSMRegistration' => {
               Type => 'VSM',
               TestVSM => "neutron.[1]",
               vsmregistration => {
                  '[1]' => {
                        name         => "10.110.28.190",
                        uuid      => "uuid-2",
                        ipaddress    => "10.110.28.190",
                  },
               },
            },
         },
      },
      'NVPControllerComponents' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "NVPControllerComponents",
         Version          => "2" ,
         Summary          => "This is the precheck-in unit test case ",
         'TestbedSpec' => {
            'nvpcontroller' => {
               '[1]' => {
               transportzone => {
                  '[1-2]' => {
                     name         => "autogenerate",
                  },
               },
               },
            },
         },
         'WORKLOADS' => {
                 'Sequence' => [
                 ['CreateTransportZone'],
                 ['CreateLogicalSwitch'],
                 ],

            'CreateTransportZone' => {
               Type      => "NSX",
               TestNSX   => "nvpcontroller.[1]",
               transportzone => {
                  '[1-2]' => {
                     name         => "autogenerate",
                  },
               },
            },
            'CreateLogicalSwitch' => {
               Type      => "NSX",
               TestVSM   => "nvpcontroller.[1]",
               logicalswitch  => {
                  "[1]" => {
                     name     => "lswitch-1-$$",
                     transportzones => "nvpcontroller.[1].transportzone.[1-2]",
                     transporttypes => ["stt","gre"],
                  },
               },
            },
         },
      },
     'VDRDeployment'   => {
        TestName         => 'VDRDeployment',
        Category         => 'VDNet',
        Component        => 'Infrastructure',
        Product          => 'ESX',
        Summary          => 'Workflow of deployment'.
	   '1) Deploy VC and VSM in parallel'.
	   '2) Register VC in VSM'.
	   '3) Create IP Pool on VSM'.
	   'Create All clusters and add hosts in clusters'. # Parallel operations
	   'Set Segmentation ID and multicast range'.
	   '4) Deploy Controllers on Cluster1'.
	   '5) Do vib install and vxlan configuration on Cluster2'. # 4) and 5) can be done in parallel
	   # but there is a product bug as of today
           '6) Create networkscope binded to cluster2'.
           '7) Create VirtualWires in this networkscope',
        Status           => 'Draft',
        AutomationLevel  => 'Manual',
        FullyAutomatable => 'Y',
        Developer        => 'vermap',
        Version          => '2',
        ExpectedResult  => 'PASS',

        TestbedSpec      => {
	   vc => {
	      '[1]' => {
	         datacenter => {
		    '[1]' => {
                       foldername => "vdnet-folder",
                       name => "vdnet-datacenter",
		       cluster => {
		          '[1]' => {
                             host => "host.[1]",
			     clustername => "Mgmt_Rack_A-$$",
			     ha => 1,
			     drs => 1,
		          },
		          '[2]' => {
			     clustername => "Compute_Rack_A-$$",
                             host => "host.[2]",
		          },
		       },
		    },
	         },
                 vds   => {
                    '[1]'   => {
                       datacenter     => "vc.[1].datacenter.[1]",
		       name           => "VDS_Compute_Rack_A-$$",
		       configurehosts => "add",
		       host           => "host.[2]",
		       vmnicadapter   => "host.[2].vmnic.[1]",
                       mtu            => "1600",
                       numuplinkports => "1",
                    },
                 },
                  dvportgroup  => {
	             # For testing VLAN routing
                     '[1]'   => {
			name    => "dvpg-vlan16-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "16",
                        vlantype => "access",
                     },
                     '[2]'   => {
			name    => "dvpg-vlan17-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "17",
                        vlantype => "access",
                     },
                     '[3]'   => {
			name    => "dvpg-vlan18-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "18",
                        vlantype => "access",
                     },
		     # For placing vnic of VSE
                     '[4]'   => {
			name    => "dvpg-mgmt-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
		     # For bridging
                     '[5]'   => {
			name    => "dvpg-vlan21-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                  },
              },
           },
            host  => {
               '[1-2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
		  'datastoreType' => "shared",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
			portgroup  => "vsm.[1].datacenter.[1].networkscope.[1].VirtualWire.[1]", # vWire should have been Created
			# before we can do this1
                     },
                  },
               },
            },
            vsm => {
               '[1]' =>  {
                  vc => "vc.[1]",
                  ippool => {
                     '[1]' => {
		        name          => "pool-3-$$",
                        gateway       => "10.138.112.253",
                        prefixLength  => "25", # Product uses prefixLength, what do we want to use?
                        # Optional params
		        # dnsSuffix
                        # dnsServer1
                        # dnsServer2
                        ipranges      => ["10.138.112.177-10.138.112.179",
			                  "10.138.112.187-10.138.112.189"],
                     },
                  },
		  # One can create multiple SegmentIDs and MulticastIP Ranges
		  # in VSM. Though we are using just one default for this release
                  # Scope of the Segment ID and Multicast range is per VC
                  Segmentidrange => {
                     '[1]' => {
	                name  => "first_vdnet_seg-$$",
	                begin => "6050",
			end   => "7000",
                     },
                  },
                  Multicastiprange => {
                     '[1]' => {
	                begin => "239.0.0.100",
			end   => "239.0.0.200",
                     },
                  },
                  VDNCluster => {
		     # VDN is a VSM terminology to describe
	             # a cluster which can have network services. VSM
		     # maintains its own ID for VDN Cluster and also
		     # points to VC's cluster to do VC specific operations
		     # we will also do the same here.
                     '[1]' => {
                        cluster       => "vc.[1].cluster.[2]",
                        # VXLAN/VDR HostPrep is generic and is two operations
                        # 1) Fabric/vib install 2) VXLAN enablement. Thus renaming this key
                        vibs          => "install",
                        feature       => "VXLAN", # this can support multiple features in future
                        switch        => "vc.[1].vds.[1]",
                        vlan          => "0",
                        mtu           => "1600",
                        vmknicCount   => "1",
                        teamingpolicy => "ethernetchannel",
                        ipv4          => "dhcp" # Fix ipv4 action key to take
                        # ips from a pool in preprocess.
                     },
                  },
                  networkscope => {
                     '[1]' => {
		        name         => "network-scope-1",
                        cluster      => "vc.[1].datacenter.[1].cluster.[1]",
		        # TODO: Find how to enable headend replication
                        VirtualWire  => {
                           '[1]' => {
			      name     => "vWire-1",
                              tenantid => "1",
                              # optional params(not sure yet)
                              # multicastproxy => "true",
                              # multicast      => "disable",
                           },
                           '[2]' => {
			      name     => "vWire-1",
                              tenantid => "2",
                           },
                           '[3-10]' => { # Make it 100,000 and kill the system :-)
			      # auto generate name and tenant id
                           },
                        },
                     },
                  },
              },
           },
           VSE => {
              '[1]' => {
                 datacenter    => "vsm.[1].datacenter.[1]", # find the corresponding
                 edgetype      => "distributedRouter", # other is edge gateway
                 appliancesize => "compact",
                 resourcepool  => "vc.[1].resourcepool.[1]", # Need to create this component under VC inventory
                 datastoretype => "shared", # deploy on shared so that vMotion can be done
                 # Rest API takes datastore MOB id. vdnet can calculate datastore based on max free space
                 # or use the shared store if datastoretype is shared.
                 portgroup     => "host.[1].portgroup.[0]", # Need to create obj for control channel portgroup
                 # deployType (optional params)
		 # ipv4          => "1.1.1.1", # ip address of mgmt interface(optional params)
		 # subnetmask    => "255.255.0.0", # ip address of mgmt interface(optional params)
                 nic => {
                    '[1]' => {
                       nictype     => "internal", # other is uplink
                       ipv4        => "172.31.1.1", # future will have multiple ips per LIF
                       subnetmask  => "255.255.0.0",
                       portgroup   => "vc.[1].dvportgroup.[1]", # Either a dvportgroup or virtualwire needs
		       # to be specified as values of portgroup key
		       portgroup => "vsm.[1].datacenter.[1].networkscope.[1].virtualwire.[1]",
		       # mtu => "9000" (not supported yet)
		       isConnected => "true", # (do we have any existing key for this??)
                    },
		 },
                 bridge => {
                    '[1]' => {
                       name        => "bridge1",
                       portgroup   => "vc.[1].dvportgroup.[5]",
                       virtualwire => "vsm.[1].datacenter.[1].networkscope.[1].VirtualWire.[4]", # This
		       # is the only place where we need to use both keys portgroup and virtualwire
                    },
                 },
              },
	   },
           Controller  => { # Generic spec to deploy any controller
              '[1]' => {
                 name          => "Controller-1",
                 # ippool can be fetched from vsm. IPPool creation should happen
		 # before controller deployment can start
                 ippool        => "vsm.[1].ippool.[1]",
                 resourcepool  => "vc.[1].resourcepool.[1]", # Need to create this component under VC inventory
                 host          => "host.[1]",
                 datastoretype => "shared", # deploy on shared so that vMotion can be done
                 # Rest API takes datastore MOB id. vdnet can calculate datastore based on max free space
                 # or use the shared store if datastoretype is shared.
                 portgroup     => "host.[1].portgroup.[0]", # Need to create obj for control channel portgroup
                 # deployType (optional param)
              },
	   },
	},
        WORKLOADS => {
           Sequence => [ ],
        },
     },
     'PylibPreCheckin' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "PylibPreCheckin",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "Precheckin test for pylib using VSM",
         'TestbedSpec' => {
            'vsm' => {
               '[1]' => {
                  reconfigure => "true",
                  vc          => 'vc.[1]',
               },
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                        Cluster => {
                           '[1]' => {
                              name => "Controller-Cluster-$$",
                           },
                           '[2]' => {
                              name => "Prep-Cluster-$$",
                           },
                        },
                     },
                  },
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
                         ['CreateIPPool'],
                         ['PrepCluster'],
                        ],
            ExitSequence => [
                             ['DeleteIPPool'],
                            ],
            'CreateIPPool' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               ippool   => {
                  '[1]' => {
                     # Some junk IPs
                     name         => "AutoGenerate",
                     gateway      => "10.10.10.253",
                     prefixlength => "22",
                     ipranges     => ['10.10.10.1-10.10.10.5'],
                  },
               },
            },
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'DeleteIPPool' => {
               Type         => 'NSX',
               TestNSX      => "vsm.[1]",
	       deleteippool => "vsm.[1].ippool.[1]",
            },
         },
      },

      'ConfigurePIM' => {
         Product           => 'ESX',
         Category          => 'VDNet',
         Component         => 'Infrastructure',
         TestName          => "ConfigurePIM",
         Priority          => 'P0',
         Version           => '2' ,
         Summary           => "Configure ip pim for given vlan on physical switch",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                  },
               },
            },
            pswitch => {
               '[-1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                             ["DisableIPPIM"],
                             ["EnableIPPIM"]
                             ],
            Duration     => "time in seconds",

            "DisableIPPIM" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               disablepim      => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               Mode            => VDNetLib::TestData::TestConstants::IP_PIM_SPARSE_DENSE_MODE
            },
            "EnableIPPIM" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               enablepim      => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               Mode            => VDNetLib::TestData::TestConstants::IP_PIM_SPARSE_DENSE_MODE
            },
         },
      },

      'TrafficFragRoutePreCheckin' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "TrafficFragRoutePreCheckin",
         Version           => "2",
         Summary           => "This is a unit test case to check the ".
                              "working of fragroute tool",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_01,
         WORKLOADS => {
            Sequence     => [['FRAGROUTE','TRAFFIC_1',],],
            Duration     => "time in seconds",

            "FRAGROUTE" => {
               Type           => "Traffic",
               ToolName       => "fragroute",
               FragmentSize   => "24",
               NoofOutbound   => "1",
               TestDuration   => "50",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "ping",
               SleepBetweenCombos => "20",
               PingPktSize    => "1024",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
         },
      },

   );
}


########################################################################
#
# new --
#       This is the constructor for SampleTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%Sample);
   return (bless($self, $class));
}

1;

