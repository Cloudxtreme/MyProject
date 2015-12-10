#!/usr/bin/perl
########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Sample::SampleTds;

#
# This file contains the structured hash for category, Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use Tie::IxHash;
tie my %Sample, 'Tie::IxHash';

# For BridgeSetup testcase
use constant HOSTNUM  => "3";


#use constant HOSTSET_NUM1 => "4";
#use constant HOSTSET_NUM2 => "5";
use constant HOSTSET_NUM1 => "1";
use constant HOSTSET_NUM2 => "2";
use constant HOSTSET  => HOSTSET_NUM1 . "-" . HOSTSET_NUM2;
use constant VMHOST  => "9";
use constant VMHOST1  => "1";
use constant VMHOST2  => "2";
@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("DriverReload", "CreatevSwitch", "CreatePG","StressOptions",
             "ConfigurePGAndvSwitch","TestvSwitch","VSS_VDSPreCheckIn",
             "MTUChange","SuspendResume","ChangeRingParams",
             "EnableDisableRSS","ChangeTSOTraffic","vNicComboTest",
             "MultipleAdapters","UDPTraffic","TSOsVLAN","SetIPv6",
             "JumboFrame","TSOTCP","PingTraffic","IperfTraffic",
             "IperfTwoHelper", "VMKNictest", "MultipleHelpersTest",
             "VnicVmkNictest", "VmknicIperf", "EventHandler1", "VMNictest",
             "EventHandler2","FirewallTest","CommandTest", "TrafficPreCheckIn",
             "TrafficBetweenHelpers", "JumboFramegVLAN", "AllNewTraffic",
             "Multicast","RSPAN","WOL");

   %Sample = (
      'VSMScalability' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VSMComponents",
         Version          => "2" ,
         Tags              => "precheckin",
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
#               ['RegisterVCToVSM'],
#               ['CreateIPPool'],
#               ['DeployController'],
#               ['SetSegmentIDRange'],
#               ['SetMulticastRange'],
#               ['InstallVIBs_And_ConfigureVXLAN'],
#               ['CreateNetworkScope'],
#	       # VXLAN test - VMs on same vWire
               ['CreateVirtualWires'],
#               ['PlaceVMsOnVirtualWire'],
#               ['PoweronVM1','PoweronVM2'],
#               ['NetperfTest'],
#               ['PoweroffVM1','PoweroffVM2'],
#               ['RemovevNICFromVM1'], ['RemovevNICFromVM2'],

	       # VDR test - VXLAN to VXLAN rotuing
#               ['DeployVSE'],
#               ['CreateVXLANLIFs'],
#               ['PlaceVM1OnvWire1','PlaceVM2OnvWire2'],
#               ['PoweronVM1','PoweronVM2'],
#	       ['SetVXLANIPVM1','SetVXLANIPVM2'],
#	       ['AddVXLANRouteVM1','AddVXLANRouteVM2'],
#               ['NetperfTest'],
#               ['PoweroffVM1','PoweroffVM2'],
#               ['RemovevNICFromVM1'], ['RemovevNICFromVM2'],
#
#	       # VDR test - VLAN to VLAN rotuing
#               ['CreateVLANLIFs'],
#               ['PlaceVM1OnVLAN16','PlaceVM2OnVLAN17'],
#               ['PoweronVM1','PoweronVM2'],
#	       ['SetVLANIPVM1','SetVLANIPVM2'],
#	       ['AddVLANRouteVM1','AddVLANRouteVM2'],
#               ['NetperfTest'],
#               ['PoweroffVM1','PoweroffVM2'],
#               ['RemovevNICFromVM1'], ['RemovevNICFromVM2'],
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
                  '[1]' => {
                     name           => "demo-ippool-Host-121-$$",
                     gateway        => "10.115.173.1",
                     prefixlength   => "22",
                     ipranges       => ['10.115.173.106-10.115.173.107'],
                  },
                  '[2]' => {
                     name => "VTEP-ippool-$$",
                     gateway => "172.20.0.1",
                     prefixlength => "16",
                     ipranges => ['172.20.0.5-172.20.0.20'],
                  },
#                  '[1]' => {
#                     name           => "demo-ippool-PromE-$$",
#                     gateway        => "10.24.31.253",
#                     prefixlength   => "22",
#                     ipranges => ['10.24.29.25-10.24.29.28'],
#                  },
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
               vxlancontroller  => { # Generic spec to deploy any controller
                  '[1-10]' => {
			  #name          => "Controller-1",
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
                     cluster     => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs        => "install",
                     vxlan       => "Configure",
                     switch      => "vc.[1].vds.[1]",
                     vlan        => "20",
                     mtu         => "1600",
                     vmkniccount => "1",
                     teaming     => "ETHER_CHANNEL",
                     ippool      => "vsm.[1].ippool.[2]",
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
                  '[1-10]' => {
			  #name         => "demo-network-scope-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'CreateVirtualWires' => {
               Type  => "Scope",
               TestScope   => "vsm.[1].networkscope.[1]",
               VirtualWire  => {
                  "[1-100]" => {
			  #name     => "vWire-1-$$",
		     #tenantid => "$$",
                  },
                  '[2]' => {
                     name     => "vWire-2-$$",
                     tenantid => "2",
                  },
               },
            },
            'PlaceVMsOnVirtualWire' => {
               Type => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'RemovevNICFromVM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'RemovevNICFromVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'PlaceVM1OnvWire1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVM2OnvWire2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVM1OnVLAN16' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVM2OnVLAN17' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vc.[1].dvportgroup.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweroffVM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate  => "poweroff",
            },
            'PoweroffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate  => "poweroff",
            },
            'PoweronVM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate  => "poweron",
            },
            'PoweronVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate  => "poweron",
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
               ExpectedResult => "Ignore",
            },
            "DeployVSE"   => {
               Type  => "VSM",
               TestVSM  => "vsm.[1]",
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
               Type => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1:100]'   => {
		     name        => "lif-demo-vwire-1-$$",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1:100]",
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
               Type => "VM",
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
            'PoweroffVM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate  => "poweroff",
            },
            'PoweroffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate  => "poweroff",
            },
            'RemoveVM1FromVirtualWire' => {
               Type => "VM",
               TestVM => "vm.[1]",
	       deletevnic => "vm.[1].vnic.[1]",
            },
            'RemoveVM2FromVirtualWire' => {
               Type => "VM",
               TestVM => "vm.[1]",
	       deletevnic => "vm.[1].vnic.[2]",
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
      },
      'ControllerCluster'   => {
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
		       foldername => "vdnet-folder",
		       name => "vdnet-datacenter",
		       cluster => {
		          '[1]' => {
			     clustername => "controller-cluster-1",
			     host  => "host.[1]",
		          },
		       },
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
            Sequence          => [
		                  ['MoveHostToCluster'],
				  #["EditCluster"],
			         ],

	    "MoveHostToCluster" => {
                Type => "Cluster",
		TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
	        MoveHostsToCluster => "host.[1]",
            },
	    "EditCluster" => {
		Type => "Cluster",
		TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
		EditCluster => "edit", # No use of valuse of this key
		HA   => 1,
		DRS  => 1,
	    },
         },
      },
      'ControllerCluster2'   => {
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
		       foldername => "vdnet-folder",
		       name => "vdnet-datacenter",
		       cluster => {
		          '[1]' => {
			     clustername => "controller-cluster-2",
			     host  => "host.[2-3]",
		          },
		       },
		    },
	         },
              },
           },
            host  => {
               '[2-3]'   => {
               },
            },
	 },
         WORKLOADS => {
            Sequence          => [
		    #['MoveHostToCluster'],
				  #["EditCluster"],
			         ],

	    "MoveHostToCluster" => {
                Type => "Cluster",
		TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
	        MoveHostsToCluster => "host.[2-3]",
            },
	    "EditCluster" => {
		Type => "Cluster",
		TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
		EditCluster => "edit", # No use of valuse of this key
		HA   => 1,
		DRS  => 1,
	    },
         },
      },
      'Create8VMsOn1Host' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "HostPreCheckIn",
         Version           => "2" ,
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for Host and VSS related changes",
         ExpectedResult    => "PASS",
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
            },
            vm  => {
               '[1-8]'   => {
		       #'template' => 'rhel53-srv-32',
                  host  => "host.[1]",
#		  'datastoreType' => "shared",
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
            Sequence     => [
		         #   ['SetIPVM1','SetIPVM2','SetIPVM3','SetIPVM4','SetIPVM5','SetIPVM6'],
                             ['SetIPVM1'],
                             ['SetIPVM2'],
                             ['SetIPVM3'],
                             ['SetIPVM4'],
                             ['SetIPVM5'],
                             ['SetIPVM6'],
                             ['SetIPVM7'],
                             ['SetIPVM8'],
			 #      ['AddRouteVM1','AddRouteVM2','AddRouteVM3','AddRouteVM4','AddRouteVM5','AddRouteVM6'],
                             ['AddRouteVM1'],
                             ['AddRouteVM2'],
                             ['AddRouteVM3'],
                             ['AddRouteVM4'],
                             ['AddRouteVM5'],
                             ['AddRouteVM6'],
                            ],
            "VXLANTrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               TestDuration   => "10",
#               ParallelSession=> "yes",
               ToolName       => "Ping",
#               NoofInbound    => 3,
#               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[9-11].vnic.[1]",
            },
            "VLANTrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[12-14].vnic.[1]",
            },
            "Bridge1TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[15].vnic.[1]",
            },
            "Bridge2TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[8].vnic.[1]",
               SupportAdapter => "vm.[16].vnic.[1]",
            },
	    # VxLAN VMs
            "SetIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.31.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '172.33.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
	    # VLAN VMs 
            "SetIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '172.16.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
            "SetIPVM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               ipv4       => '172.17.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
            "SetIPVM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               ipv4       => '172.18.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
	    # Bridge network VM 7 in vxlan VM 8 in vlan
            "SetIPVM7" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[7].vnic.[1]",
               ipv4       => '172.21.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM8" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[8].vnic.[1]",
               ipv4       => '172.21.5.1'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },

            "AddRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.32.5.0,172.33.5.0",
               gateway    => "172.31.5.1",
            },
            "AddRouteVM2" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[2].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.33.5.0",
               gateway     => "172.32.5.1",
            },
            "AddRouteVM3" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[3].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.32.5.0",
               gateway     => "172.33.5.1",
            },
            "AddRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.17.5.0,172.18.5.0",
               gateway    => "172.16.5.1",
            },
            "AddRouteVM5" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[5].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.18.5.0",
               gateway     => "172.17.5.1",
            },
            "AddRouteVM6" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[6].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.17.5.0",
               gateway     => "172.18.5.1",
            },
         },
      },
      'AllVMTraffic' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "HostPreCheckIn",
         Version           => "2" ,
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for Host and VSS related changes",
         ExpectedResult    => "PASS",
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
               '[1-8]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
			portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
               '[9-16]'   => {
                  host  => "host.[2]",
		  'datastoreType' => "shared",
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
            Sequence     => [
#                             ['SetIP'.VMHOST1.'VM1','SetIP'.VMHOST1.'VM2','SetIP'.VMHOST1.'VM3','SetIP'.VMHOST1.'VM4','SetIP'.VMHOST1.'VM5','SetIP'.VMHOST1.'VM6','SetIP'.VMHOST1.'VM7','SetIP'.VMHOST1.'VM8'],
#                             ['SetIP'.VMHOST2.'VM8','SetIP'.VMHOST2.'VM7','SetIP'.VMHOST2.'VM6','SetIP'.VMHOST2.'VM5','SetIP'.VMHOST2.'VM4','SetIP'.VMHOST2.'VM3','SetIP'.VMHOST2.'VM2','SetIP'.VMHOST2.'VM1'],

#                             ['SetIP'.VMHOST1.'VM1','SetIP'.VMHOST2.'VM1','SetIP'.VMHOST1.'VM2','SetIP'.VMHOST2.'VM2','SetIP'.VMHOST1.'VM3','SetIP'.VMHOST2.'VM3','SetIP'.VMHOST1.'VM4','SetIP'.VMHOST2.'VM4','SetIP'.VMHOST1.'VM5','SetIP'.VMHOST2.'VM5','SetIP'.VMHOST1.'VM6','SetIP'.VMHOST2.'VM6','SetIP'.VMHOST1.'VM7','SetIP'.VMHOST2.'VM7','SetIP'.VMHOST1.'VM8','SetIP'.VMHOST2.'VM8'],

#		            ['AddRoute'.VMHOST1.'VM1'], 
#                            ['AddRoute'.VMHOST1.'VM1','AddRoute'.VMHOST1.'VM2','AddRoute'.VMHOST1.'VM3','AddRoute'.VMHOST1.'VM4','AddRoute'.VMHOST1.'VM5','AddRoute'.VMHOST1.'VM6'],
#                             ['AddRoute'.VMHOST2.'VM6','AddRoute'.VMHOST2.'VM5','AddRoute'.VMHOST2.'VM4','AddRoute'.VMHOST2.'VM3','AddRoute'.VMHOST2.'VM2','AddRoute'.VMHOST2.'VM1'],

#                             ['AddRoute'.VMHOST1.'VM1','AddRoute'.VMHOST2.'VM1','AddRoute'.VMHOST1.'VM2','AddRoute'.VMHOST2.'VM2','AddRoute'.VMHOST1.'VM3','AddRoute'.VMHOST2.'VM3','AddRoute'.VMHOST1.'VM4','AddRoute'.VMHOST2.'VM4','AddRoute'.VMHOST1.'VM5','AddRoute'.VMHOST2.'VM5','AddRoute'.VMHOST1.'VM6','AddRoute'.VMHOST2.'VM6'],

#                             ['EnableTSO'],
#                             ['DisableStress'],
#                             ['DisableStress2'],
                             ['EnableStress'],
#                             ['EnableStress2'],

                             ['VXLANTrafficDifferentHostSameSubnet'],
                             ['VXLANTrafficSameHostDifferentSubnet'],
                             ['VXLANTrafficSameHostDifferentSubnet2'],
			     # PR 1022466 
			     ['VXLANtoVLANTrafficSameHostDifferentSubnet'],
                             ['VXLANTrafficDifferentHostDifferentSubnet'],
                             # PR 1022466 ['VXLANtoAllJumboPing'],
                             ['VXLANFlood'],

                             ['VLANTrafficDifferentHostSameSubnet'],
                             ['VLANTrafficSameHostDifferentSubnet'],
#			     # PR 1022466
			     ['VLANtoVXLANTrafficSameHostDifferentSubnet'],
                             ['VLANTrafficDifferentHostDifferentSubnet'],
                             ['VLANFlood'],
##
#                             ['BridgeTrafficSameHostDifferentNetwork'],
#                             ['BridgeTrafficiDifferentHostDifferentNetwork'],
#                             ['BridgeFlood'],
###
#                             ['DisableStress'],

#                             ['SetIP'.VMHOST1.'VM1','SetIP'.VMHOST2.'VM1','SetIP'.VMHOST1.'VM2','SetIP'.VMHOST2.'VM2','SetIP'.VMHOST1.'VM3','SetIP'.VMHOST2.'VM3','SetIP'.VMHOST1.'VM4','SetIP'.VMHOST2.'VM4','SetIP'.VMHOST1.'VM5','SetIP'.VMHOST2.'VM5','SetIP'.VMHOST1.'VM6','SetIP'.VMHOST2.'VM6','SetIP'.VMHOST1.'VM7','SetIP'.VMHOST2.'VM7','SetIP'.VMHOST1.'VM8','SetIP'.VMHOST2.'VM8'],
#                             ['AddRoute'.VMHOST1.'VM1','AddRoute'.VMHOST2.'VM1','AddRoute'.VMHOST1.'VM2','AddRoute'.VMHOST2.'VM2','AddRoute'.VMHOST1.'VM3','AddRoute'.VMHOST2.'VM3','AddRoute'.VMHOST1.'VM4','AddRoute'.VMHOST2.'VM4','AddRoute'.VMHOST1.'VM5','AddRoute'.VMHOST2.'VM5','AddRoute'.VMHOST1.'VM6','AddRoute'.VMHOST2.'VM6'],

#			     #['VXLANTrafficDifferentHostSameSubnet'],
#                             ['VXLANTrafficSameHostDifferentSubnet'],
##			     # PR 1022466 ['VXLANtoVLANTrafficSameHostDifferentSubnet'],
#                             ['VXLANTrafficDifferentHostDifferentSubnet'],
#
#			     #['VLANTrafficDifferentHostSameSubnet'],
#                             ['VLANTrafficSameHostDifferentSubnet'],
##			     # PR 1022466 ['VLANtoVXLANTrafficSameHostDifferentSubnet'],
#                             ['VLANTrafficDifferentHostDifferentSubnet'],
##
#                             ['BridgeTrafficSameHostDifferentNetwork'],
#                             ['BridgeTrafficiDifferentHostDifferentNetwork'],
                            ],
            "EnableStress" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               Stress         => "Enable",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::vmxnet3Stress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::pktapiVmxnet3",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::networkStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::portStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::packetStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::portSetPortStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::dvFilterStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::uplinkStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPJFNetstress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPNetstress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::pktportSetPort",
               stressoptions  => "%VDNetLib::TestData::StressTestData::VXLANStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::TSOStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::netDVSStress",
            },
            "DisableStress" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               Stress         => "Disable",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::vmxnet3Stress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::pktapiVmxnet3",
               stressoptions  => "%VDNetLib::TestData::StressTestData::networkStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::portStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::packetStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::portSetPortStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::dvFilterStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::uplinkStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPJFNetstress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VMKTCPIPNetstress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::pktportSetPort",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::VXLANStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::TSOStress",
            },
            "EnableStress2" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               Stress         => "Enable",
               stressoptions  => "%VDNetLib::TestData::StressTestData::vmxnet3Stress",
            },
            "DisableStress2" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               Stress         => "Disable",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::dvFilterStress",
#               stressoptions  => "%VDNetLib::TestData::StressTestData::pktapiVmxnet3",
               stressoptions  => "%VDNetLib::TestData::StressTestData::netDVSStress",
            },

            "EnableTSO" => {
               TSOIPV4     => "Enable",
               TCPTxChecksumIPv4 => "Enable",
               TCPRxChecksumIPv4 => "Enable",
               Type        => "NetAdapter",
               Testadapter => "vm.[1-8].vnic.[1]",
               LRO         => "Enable",
               SG          => "Enable",
            },
            "VXLANTrafficDifferentHostSameSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[9].vnic.[1]",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "VXLANTrafficSameHostDifferentSubnet2" => {
               Type           => "Traffic",
	       #TestDuration   => "900",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[3].vnic.[1]",
	       #SupportAdapter => "vm.[2-3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
	       ExpectedResult        => "IGNORE",
            },
            "VXLANTrafficSameHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "900",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[9].vnic.[1]",
	       #SupportAdapter => "vm.[2-3].vnic.[1]",
               SupportAdapter => "vm.[11].vnic.[1]",
#	       SendMessageSize       => "4096,32768,65536,131072",
#               LocalSendSocketSize   => "131072",
#               RemoteSendSocketSize  => "131072",
#               MaxTimeout            => "92400",
	       ExpectedResult        => "IGNORE",
            },
            "VXLANtoVLANTrafficSameHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[9].vnic.[1]",
	       #SupportAdapter => "vm.[2-3].vnic.[1]",
               SupportAdapter => "vm.[12].vnic.[1]",
#	       SendMessageSize       => "4096,32768,65536",
#               LocalSendSocketSize   => "131072",
#               RemoteSendSocketSize  => "131072",
#               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "VXLANTrafficDifferentHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "800",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
	       #SupportAdapter => "vm.[9-11].vnic.[1]",
               SupportAdapter => "vm.[11].vnic.[1]",
#	       SendMessageSize       => "4096,32768,65536",
#               LocalSendSocketSize   => "131072",
#               RemoteSendSocketSize  => "131072",
#               MaxTimeout            => "92400",
	       ExpectedResult        => "IGNORE",
               Verification          => "PktCap",
            },
            "VXLANtoAllJumboPing" => {
               Type             => "Traffic",
               ToolName         => "ping",
               PktFragmentation => "no",
               PingPktSize      => "8000",
               TestDuration     => "60",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[9-14].vnic.[1]",
	       ExpectedResult   => "IGNORE",
            },
            "VXLANFlood" => {
               Type             => "Traffic",
               ToolName         => "ping",
	       RoutingScheme    => "flood",
               TestDuration     => "60",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[9-11].vnic.[1]",
	       ExpectedResult   => "IGNORE",
            },
            "VXLANtoVLANTrafficDifferentHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       #ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
	       #SupportAdapter => "vm.[9-11].vnic.[1]",
               SupportAdapter => "vm.[12].vnic.[1]",
	       SendMessageSize       => "4096,32768,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "VLANTrafficDifferentHostSameSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[12].vnic.[1]",
	       ExpectedResult        => "IGNORE",
            },
            "VLANtoVXLANTrafficSameHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[12].vnic.[1]",
	       #SupportAdapter => "vm.[5-6].vnic.[1]",
               SupportAdapter => "vm.[9].vnic.[1]",
	       #SendMessageSize       => "4096,32768,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "VLANTrafficSameHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "10",
	       #ToolName       => "Ping",
               TestAdapter    => "vm.[4].vnic.[1]",
	       #SupportAdapter => "vm.[5-6].vnic.[1]",
               SupportAdapter => "vm.[6].vnic.[1]",
	       SendMessageSize       => "4096,32768,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "VLANTrafficDifferentHostDifferentSubnet" => {
               Type           => "Traffic",
	       #TestDuration   => "100",
	       #ToolName       => "Ping",
               TestAdapter    => "vm.[4].vnic.[1]",
	       #SupportAdapter => "vm.[12-14].vnic.[1]",
               SupportAdapter => "vm.[14].vnic.[1]",
	       SendMessageSize       => "4096,32768,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
#               Verification          => "PktCap",
            },
            "VLANFlood" => {
               Type             => "Traffic",
               ToolName         => "ping",
	       RoutingScheme    => "flood",
               TestDuration     => "60",
               TestAdapter      => "vm.[12-14].vnic.[1]",
               SupportAdapter   => "vm.[5].vnic.[1]",
	       ExpectedResult   => "IGNORE",
            },
            "BridgeTrafficSameHostDifferentNetwork" => {
               Type           => "Traffic",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[15].vnic.[1]",
               SupportAdapter => "vm.[16].vnic.[1]",
	       #SendMessageSize       => "4096,32768,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
            },
            "BridgeTrafficiDifferentHostDifferentNetwork" => {
               Type           => "Traffic",
	       ToolName       => "Ping",
               TestAdapter    => "vm.[15].vnic.[1]",
               SupportAdapter => "vm.[8].vnic.[1]",
	       #SendMessageSize       => "4096,32768,65536",
#               LocalSendSocketSize   => "131072",
#               RemoteSendSocketSize  => "131072",
               MaxTimeout            => "32400",
	       ExpectedResult        => "IGNORE",
#               Verification          => "PktCap",
            },
            "BridgeFlood" => {
               Type             => "Traffic",
               ToolName         => "ping",
	       RoutingScheme    => "flood",
               TestDuration     => "60",
               TestAdapter      => "vm.[15-16].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
	       ExpectedResult   => "IGNORE",
            },
	    # VxLAN VMs
            "SetIP".VMHOST1."VM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.31.5.'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST1."VM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.5.'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST1."VM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '172.33.5.'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
	    # VLAN VMs 
            "SetIP".VMHOST1."VM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '172.16.5.1'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST1."VM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               ipv4       => '172.17.5.1'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST1."VM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               ipv4       => '172.18.5.1'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
	    # Bridge network VM 7 in vxlan VM 8 in vlan
            "SetIP".VMHOST1."VM7" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[7].vnic.[1]",
               ipv4       => '172.21.5.'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST1."VM8" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[8].vnic.[1]",
               ipv4       => '172.21.5.1'.VMHOST1.'5',
               netmask    => "255.255.255.0",
            },
	    # VxLAN VMs
            "SetIP".VMHOST2."VM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[9].vnic.[1]",
               ipv4       => '172.31.5.'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST2."VM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[10].vnic.[1]",
               ipv4       => '172.32.5.'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST2."VM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[11].vnic.[1]",
               ipv4       => '172.33.5.'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
	    # VLAN VMs 
            "SetIP".VMHOST2."VM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[12].vnic.[1]",
               ipv4       => '172.16.5.1'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST2."VM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[13].vnic.[1]",
               ipv4       => '172.17.5.1'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST2."VM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[14].vnic.[1]",
               ipv4       => '172.18.5.1'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
	    # Bridge network VM 7 in vxlan VM 8 in vlan
            "SetIP".VMHOST2."VM7" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[15].vnic.[1]",
               ipv4       => '172.21.5.'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },
            "SetIP".VMHOST2."VM8" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[16].vnic.[1]",
               ipv4       => '172.21.5.1'.VMHOST2.'5',
               netmask    => "255.255.255.0",
            },

            "AddRoute".VMHOST1."VM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.32.5.0,172.33.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway    => "172.31.5.1",
            },
            "AddRoute".VMHOST1."VM2" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[2].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.33.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway     => "172.32.5.1",
            },
            "AddRoute".VMHOST1."VM3" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[3].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.32.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway     => "172.33.5.1",
            },
            "AddRoute".VMHOST1."VM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.17.5.0,172.18.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway    => "172.16.5.1",
            },
            "AddRoute".VMHOST1."VM5" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[5].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.18.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway     => "172.17.5.1",
            },
            "AddRoute".VMHOST1."VM6" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[6].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.17.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway     => "172.18.5.1",
            },
            "AddRoute".VMHOST2."VM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[9].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.32.5.0,172.33.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway    => "172.31.5.1",
            },
            "AddRoute".VMHOST2."VM2" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[10].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.33.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway     => "172.32.5.1",
            },
            "AddRoute".VMHOST2."VM3" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[11].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.32.5.0,172.16.5.0,172.17.5.0,172.18.5.0",
               gateway     => "172.33.5.1",
            },
            "AddRoute".VMHOST2."VM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[12].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.17.5.0,172.18.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway    => "172.16.5.1",
            },
            "AddRoute".VMHOST2."VM5" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[13].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.18.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway     => "172.17.5.1",
            },
            "AddRoute".VMHOST2."VM6" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[14].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.17.5.0,172.31.5.0,172.32.5.0,172.33.5.0",
               gateway     => "172.18.5.1",
            },
         },
      },
      'Create8VMsOn1Host' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "HostPreCheckIn",
         Version           => "2" ,
         Tags              => "precheckin",
         Summary           => "This is the precheck-in unit test case ".
                              "for Host and VSS related changes",
         ExpectedResult    => "PASS",
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
            },
            vm  => {
               '[1-8]'   => {
		       #'template' => 'rhel53-srv-32',
                  host  => "host.[1]",
#		  'datastoreType' => "shared",
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
            Sequence     => [
		         #   ['SetIPVM1','SetIPVM2','SetIPVM3','SetIPVM4','SetIPVM5','SetIPVM6'],
                             ['SetIPVM1'],
                             ['SetIPVM2'],
                             ['SetIPVM3'],
                             ['SetIPVM4'],
                             ['SetIPVM5'],
                             ['SetIPVM6'],
                             ['SetIPVM7'],
                             ['SetIPVM8'],
			 #      ['AddRouteVM1','AddRouteVM2','AddRouteVM3','AddRouteVM4','AddRouteVM5','AddRouteVM6'],
                             ['AddRouteVM1'],
                             ['AddRouteVM2'],
                             ['AddRouteVM3'],
                             ['AddRouteVM4'],
                             ['AddRouteVM5'],
                             ['AddRouteVM6'],
                            ],
            "VXLANTrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               TestDuration   => "10",
#               ParallelSession=> "yes",
               ToolName       => "Ping",
#               NoofInbound    => 3,
#               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[9-11].vnic.[1]",
            },
            "VLANTrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[12-14].vnic.[1]",
            },
            "Bridge1TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[15].vnic.[1]",
            },
            "Bridge2TrafficAllHostAllSubnetVMs" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[8].vnic.[1]",
               SupportAdapter => "vm.[16].vnic.[1]",
            },
	    # VxLAN VMs
            "SetIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.31.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '172.33.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
	    # VLAN VMs 
            "SetIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '172.16.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
            "SetIPVM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               ipv4       => '172.17.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
            "SetIPVM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               ipv4       => '172.18.5.1'.VMHOST.'6',
               netmask    => "255.255.255.0",
            },
	    # Bridge network VM 7 in vxlan VM 8 in vlan
            "SetIPVM7" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[7].vnic.[1]",
               ipv4       => '172.21.5.'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },
            "SetIPVM8" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[8].vnic.[1]",
               ipv4       => '172.21.5.1'.VMHOST.'5',
               netmask    => "255.255.255.0",
            },

            "AddRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.32.5.0,172.33.5.0",
               gateway    => "172.31.5.1",
            },
            "AddRouteVM2" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[2].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.33.5.0",
               gateway     => "172.32.5.1",
            },
            "AddRouteVM3" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[3].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.31.5.0,172.32.5.0",
               gateway     => "172.33.5.1",
            },
            "AddRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "172.17.5.0,172.18.5.0",
               gateway    => "172.16.5.1",
            },
            "AddRouteVM5" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[5].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.18.5.0",
               gateway     => "172.17.5.1",
            },
            "AddRouteVM6" => {
               Type        => "NetAdapter",
               Testadapter => "vm.[6].vnic.[1]",
               netmask     => "255.255.255.0",
               route       => "add",
               network     => "172.16.5.0,172.17.5.0",
               gateway     => "172.18.5.1",
            },
         },
      },
      'BridgeSetup'   => {
         TestName         => 'VLANTrafficDifferentHostJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
		        foldername => "vdnet-folder",
		        name => "vdnet-datacenter",
		        cluster => {
		          '[1]' => {
                             host => "host.[1-3]",
			     clustername => "Compute-Cluster-A-$$",
		           },
		        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
			name => "VDS-A-$$",
			#configurehosts => "add",
			#host => "host.[1-3]",
			#vmnicadapter => "host.[1-3].vmnic.[1]",
                        mtu => "1600",
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
			name    => "dvpg-vlan18-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "18",
                        vlantype => "access",
                     },
                     '[4]'   => {
			name    => "dvpg-mgmt-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[5]'   => {
			name    => "dvpg-park-vmknics-$$",
                        vds     => "vc.[1].vds.[1]",
                     },
                     '[6]'   => {
			name    => "dvpg-vlan21-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                     '[7]'   => {
			name    => "dvpg-vlan22-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "22",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '[1-3]'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet31-netstack",
                     },
                     '[2]' => {
                        name => "subnet32-netstack",
                     },
                     '[3]' => {
                        name => "subnet33-netstack",
                     },
                     '[4]' => {
                        name => "subnet16-netstack",
                     },
                     '[5]' => {
                        name => "subnet17-netstack",
                     },
                     '[6]' => {
                        name => "subnet18-netstack",
                     },
                     '[7]' => {
                        name => "subnet21-netstack",
                     },
                     '[8]' => {
                        name => "subnet22-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
#                             ['AddHostsToVDS'],
#
#                             ['AddHost1Vmk1','AddHost2Vmk1'],
##                             ['AddHost1Vmk2','AddHost2Vmk2'],
#                             ['AddHost1Vmk3','AddHost2Vmk3'],
##                             ['AddHost1Vmk4','AddHost2Vmk4'],
#                             ['AddHost1Vmk5','AddHost2Vmk5'],
##                             ['AddHost1Vmk6','AddHost2Vmk6'],
#                             ['Add'.HOSTNUM.'Vmk1'],
##                             ['Add'.HOSTNUM.'Vmk2'],
#                             ['Add'.HOSTNUM.'Vmk3'],
##                             ['Add'.HOSTNUM.'Vmk4'],
#                             ['Add'.HOSTNUM.'Vmk5'],
##                             ['Add'.HOSTNUM.'Vmk6'],
#
#                             ['VLANAddHost1Vmk1','VLANAddHost2Vmk1'],
##                             ['VLANAddHost1Vmk2','VLANAddHost2Vmk2'],
#                             ['VLANAddHost1Vmk3','VLANAddHost2Vmk3'],
##                             ['VLANAddHost1Vmk4','VLANAddHost2Vmk4'],
#                             ['VLANAddHost1Vmk5','VLANAddHost2Vmk5'],
##                             ['VLANAddHost1Vmk6','VLANAddHost2Vmk6'],
#                             ['VLANAdd'.HOSTNUM.'Vmk1'],
##                             ['VLANAdd'.HOSTNUM.'Vmk2'],
#                             ['VLANAdd'.HOSTNUM.'Vmk3'],
##                             ['VLANAdd'.HOSTNUM.'Vmk4'],
#                             ['VLANAdd'.HOSTNUM.'Vmk5'],
##                             ['VLANAdd'.HOSTNUM.'Vmk6'],
#
#		             ['BridgeAddHost1Vmk1','BridgeAddHost2Vmk1'],
##                             ['BridgeAddHost1Vmk2','BridgeAddHost2Vmk2'],
#                             ['BridgeAddHost1Vmk3','BridgeAddHost2Vmk3'],
##                             ['BridgeAddHost1Vmk4','BridgeAddHost2Vmk4'],
#                             ['BridgeAdd'.HOSTNUM.'Vmk1'],
##                             ['BridgeAdd'.HOSTNUM.'Vmk2'],
#                             ['BridgeAdd'.HOSTNUM.'Vmk3'],
##                             ['BridgeAdd'.HOSTNUM.'Vmk4'],
#
#                             ['SetNetstack1Gateway'],
#                             ['SetNetstack2Gateway'],
#                             ['SetNetstack3Gateway'],
#
#                             ['VLANSetNetstack1Gateway'],
#                             ['VLANSetNetstack2Gateway'],
#                             ['VLANSetNetstack3Gateway'],
#
#                             ['BridgeSetNetstack1Gateway'],
#                             ['BridgeSetNetstack2Gateway'],

#                             ['SetNetstack1Gateway','SetNetstack2Gateway','SetNetstack3Gateway'],


#			     ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
#			     ['TrafficDifferentSubnetSameHost','TrafficDifferentSubnetSameHost2'],
#			     ['TrafficSameSubnetDifferentHost'],
#			     ['TrafficDifferentSubnetDifferentHost'],
#			     ['TrafficDifferentSubnetDifferentHost2'],
#                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
                             ['RemoveAllHost1Vmks'],
                             ['RemoveAllHost2Vmks'],
                             ['RemoveAll'.HOSTNUM.'Vmks'],
                            ],
            'AddHostsToVDS' => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
	       configurehosts => "add",
	       host           => "host.[1-3]",
	       vmnicadapter   => "host.[1-3].vmnic.[1]",
	    },
            'AddHost2Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.31.5.20',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[1]",
                  ipv4address => '172.31.5.21',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.32.5.20',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[2]",
                  ipv4address => '172.32.5.21',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[5]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[3]",
                  ipv4address => '172.33.5.20',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost2Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[6]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[3]",
                  ipv4address => '172.33.5.21',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.31.5.10',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[1]",
                  ipv4address => '172.31.5.11',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.32.5.10',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[2]",
                  ipv4address => '172.32.5.11',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[5]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[3]",
                  ipv4address => '172.33.5.10',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'AddHost1Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[6]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[3]",
                  ipv4address => '172.33.5.11',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[1]",
                  ipv4address => '172.31.5.'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
		  netstack    => "host.[".HOSTNUM."].netstack.[1]",
		  ipv4address => '172.31.5.'.HOSTNUM.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTNUM.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTNUM.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTNUM.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },




            'VLANAddHost2Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[7]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[4]",
                  ipv4address => '172.16.5.120',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost2Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[8]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[2].netstack.[4]",
                  ipv4address => '172.16.5.121',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost2Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[9]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[5]",
                  ipv4address => '172.17.5.120',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost2Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[10]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[2].netstack.[5]",
                  ipv4address => '172.17.5.121',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost2Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[11]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[2].netstack.[6]",
                  ipv4address => '172.18.5.120',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost2Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[12]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[2].netstack.[6]",
                  ipv4address => '172.18.5.121',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[7]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[4]",
                  ipv4address => '172.16.5.110',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[8]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[1].netstack.[4]",
                  ipv4address => '172.16.5.111',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[9]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[5]",
                  ipv4address => '172.17.5.110',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[10]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[1].netstack.[5]",
                  ipv4address => '172.17.5.111',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[11]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[1].netstack.[6]",
                  ipv4address => '172.18.5.110',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAddHost1Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[12]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[1].netstack.[6]",
                  ipv4address => '172.18.5.111',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[".HOSTNUM."].netstack.[4]",
                  ipv4address => '172.16.5.1'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
		  netstack    => "host.[".HOSTNUM."].netstack.[4]",
		  ipv4address => '172.16.5.1'.HOSTNUM.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTNUM."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTNUM."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTNUM.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTNUM."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTNUM.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTNUM."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTNUM.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },


            'BridgeAddHost2Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[13]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[7]",
                  ipv4address => '172.21.5.20',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost2Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[14]" =>{
                  portgroup   => "vc.[1].dvportgroup.[6]",
                  netstack    => "host.[2].netstack.[7]",
                  ipv4address => '172.21.5.120',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost2Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[15]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[2].netstack.[8]",
                  ipv4address => '172.22.5.20',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost2Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[2]",
               vmknic => {
               "[16]" =>{
                  portgroup   => "vc.[1].dvportgroup.[7]",
                  netstack    => "host.[2].netstack.[8]",
                  ipv4address => '172.22.5.120',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost1Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[13]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[7]",
                  ipv4address => '172.21.5.10',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost1Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[14]" =>{
                  portgroup   => "vc.[1].dvportgroup.[6]",
                  netstack    => "host.[1].netstack.[7]",
                  ipv4address => '172.21.5.110',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost1Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[15]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[1].netstack.[8]",
                  ipv4address => '172.22.5.10',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAddHost1Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[1]",
               vmknic => {
               "[16]" =>{
                  portgroup   => "vc.[1].dvportgroup.[7]",
                  netstack    => "host.[1].netstack.[8]",
                  ipv4address => '172.22.5.110',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTNUM.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[7]",
                  ipv4address => '172.21.5.'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTNUM.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[6]",
                  netstack    => "host.[".HOSTNUM."].netstack.[7]",
		  ipv4address => '172.21.5.1'.HOSTNUM.'0',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTNUM.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTNUM."].netstack.[8]",
                  ipv4address => '172.22.5.'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTNUM.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTNUM."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[7]",
                  netstack    => "host.[".HOSTNUM."].netstack.[8]",
                  ipv4address => '172.22.5.1'.HOSTNUM.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },


            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.5.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.5.1",
            },
            "SetNetstack3Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[3]",
               setnetstackgateway => "add",
               route => "172.33.5.1",
            },

            "VLANSetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[4]",
               setnetstackgateway => "add",
               route => "172.16.5.1",
            },
            "VLANSetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[5]",
               setnetstackgateway => "add",
               route => "172.17.5.1",
            },
            "VLANSetNetstack3Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[6]",
               setnetstackgateway => "add",
               route => "172.18.5.1",
            },

            "BridgeSetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[7]",
               setnetstackgateway => "add",
               route => "172.21.5.1",
            },
            "BridgeSetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1-3].netstack.[8]",
               setnetstackgateway => "add",
               route => "172.22.5.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[2]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2-3].vmknic.[1-6]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            'RemoveAll'.HOSTNUM.'Vmks' => {
               Type => "Host",
               TestHost => "host.[3]",
               removevmknic => "host.[3].vmknic.[-1]",
            },
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[1-2].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
         },
      },
      'HostNtoNBridgeSetup'   => {
         TestName         => 'VLANTrafficDifferentHostJustPing',
         Category         => 'ESX Server',
         Component        => 'network vDR',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route VLAN traffic to ' .
                             ' different VLANs spanning multiple hosts',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '2host,sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
		        foldername => "vdnet-folder",
		        name => "vdnet-datacenter",
		        cluster => {
		          '[1]' => {
		             host => "host.[".HOSTSET."]",
			     clustername => "Compute-Cluster-B-$$",
		           },
		        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
			name => "VDS-B-$$",
			#configurehosts => "add",
			#host => "host.[3]",
			#vmnicadapter => "host.[3].vmnic.[1]",
                        mtu => "1600",
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
			name    => "dvpg-vlan18-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "18",
                        vlantype => "access",
                     },
                     '[4]'   => {
			name    => "dvpg-mgmt-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                     },
                     '[5]'   => {
			name    => "dvpg-park-vmknics-$$",
                        vds     => "vc.[1].vds.[1]",
                     },
                     '[6]'   => {
			name    => "dvpg-vlan21-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "21",
                        vlantype => "access",
                     },
                     '[7]'   => {
			name    => "dvpg-vlan22-$$",
                        vds     => "vc.[1].vds.[1]",
                        ports   => "8",
                        vlan => "22",
                        vlantype => "access",
                     },
                  },
               },
            },
            host  => {
               '['.HOSTSET.']'   => {
                  netstack => {
                     '[1]' => {
                        name => "subnet31-netstack",
                     },
                     '[2]' => {
                        name => "subnet32-netstack",
                     },
                     '[3]' => {
                        name => "subnet33-netstack",
                     },
                     '[4]' => {
                        name => "subnet16-netstack",
                     },
                     '[5]' => {
                        name => "subnet17-netstack",
                     },
                     '[6]' => {
                        name => "subnet18-netstack",
                     },
                     '[7]' => {
                        name => "subnet21-netstack",
                     },
                     '[8]' => {
                        name => "subnet22-netstack",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
			# Selecting 1G so that vmnics with correct
			# vlan are selected.
			# TODO: remove before checking. vESX have all 10G nics
			#speed  => "1G",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
#                             ['MoveHostsToCluster'],
                             ['AddHostsToVDS'],
                             ['Add'.HOSTSET_NUM1.'Vmk1','Add'.HOSTSET_NUM2.'Vmk1'],
#                             ['Add'.HOSTSET_NUM1.'Vmk2','Add'.HOSTSET_NUM2.'Vmk2'],
                             ['Add'.HOSTSET_NUM1.'Vmk3','Add'.HOSTSET_NUM2.'Vmk3'],
#                             ['Add'.HOSTSET_NUM1.'Vmk4','Add'.HOSTSET_NUM2.'Vmk4'],
                             ['Add'.HOSTSET_NUM1.'Vmk5','Add'.HOSTSET_NUM2.'Vmk5'],
#                             ['Add'.HOSTSET_NUM1.'Vmk6','Add'.HOSTSET_NUM2.'Vmk6'],

                             ['VLANAdd'.HOSTSET_NUM1.'Vmk1','VLANAdd'.HOSTSET_NUM2.'Vmk1'],
#                             ['VLANAdd'.HOSTSET_NUM1.'Vmk2','VLANAdd'.HOSTSET_NUM2.'Vmk2'],
                             ['VLANAdd'.HOSTSET_NUM1.'Vmk3','VLANAdd'.HOSTSET_NUM2.'Vmk3'],
#                             ['VLANAdd'.HOSTSET_NUM1.'Vmk4','VLANAdd'.HOSTSET_NUM2.'Vmk4'],
                             ['VLANAdd'.HOSTSET_NUM1.'Vmk5','VLANAdd'.HOSTSET_NUM2.'Vmk5'],
#                             ['VLANAdd'.HOSTSET_NUM1.'Vmk6','VLANAdd'.HOSTSET_NUM2.'Vmk6'],

                             ['BridgeAdd'.HOSTSET_NUM1.'Vmk1','BridgeAdd'.HOSTSET_NUM2.'Vmk1'],
#                             ['BridgeAdd'.HOSTSET_NUM1.'Vmk2','BridgeAdd'.HOSTSET_NUM2.'Vmk2'],
                             ['BridgeAdd'.HOSTSET_NUM1.'Vmk3','BridgeAdd'.HOSTSET_NUM2.'Vmk3'],
#                             ['BridgeAdd'.HOSTSET_NUM1.'Vmk4','BridgeAdd'.HOSTSET_NUM2.'Vmk4'],

                             ['SetNetstack1Gateway'],
                             ['SetNetstack2Gateway'],
                             ['SetNetstack3Gateway'],

                             ['VLANSetNetstack1Gateway'],
                             ['VLANSetNetstack2Gateway'],
                             ['VLANSetNetstack3Gateway'],

                             ['BridgeSetNetstack1Gateway'],
                             ['BridgeSetNetstack2Gateway'],

#			     ['TrafficSameSubnetSameHost','TrafficSameSubnetSameHost2'],
#			     ['TrafficDifferentSubnetSameHost','TrafficDifferentSubnetSameHost2'],
#			     ['TrafficSameSubnetDifferentHost'],
#			     ['TrafficDifferentSubnetDifferentHost'],
#			     ['TrafficDifferentSubnetDifferentHost2'],
#                             ['TrafficDifferentHostAllSubnet'],
                            ],
           ExitSequence  => [
#                             ['RemoveAll'.HOSTSET_NUM1.'Vmks'],
#                             ['RemoveAll'.HOSTSET_NUM2.'Vmks'],
                            ],
            'MoveHostsToCluster' => {
                Type => "Cluster",
		TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
	        MoveHostsToCluster => "host.[2]",
	    },
            'AddHostsToVDS' => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
	       configurehosts => "add",
	       host           => "host.[".HOSTSET."]",
	       vmnicadapter   => "host.[".HOSTSET."].vmnic.[1]",
	    },
            'Add'.HOSTSET_NUM1.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[1]",
                  ipv4address => '172.31.5.'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM1.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
		  netstack    => "host.[".HOSTSET_NUM1."].netstack.[1]",
		  ipv4address => '172.31.5.'.HOSTSET_NUM1.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM1.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM1.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTSET_NUM1.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM1.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[5]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM1.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[6]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTSET_NUM1.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },

            'VLANAdd'.HOSTSET_NUM1.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[7]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[4]",
                  ipv4address => '172.16.5.1'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM1.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[8]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
		  netstack    => "host.[".HOSTSET_NUM1."].netstack.[4]",
		  ipv4address => '172.16.5.1'.HOSTSET_NUM1.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM1.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[9]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM1.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[10]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTSET_NUM1.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM1.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[11]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM1.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[12]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTSET_NUM1.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },


            'BridgeAdd'.HOSTSET_NUM1.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[13]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[7]",
                  ipv4address => '172.21.5.'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM1.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[14]" =>{
                  portgroup   => "vc.[1].dvportgroup.[6]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[7]",
		  ipv4address => '172.21.5.1'.HOSTSET_NUM1.'0',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM1.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[15]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[8]",
                  ipv4address => '172.22.5.'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM1.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM1."]",
               vmknic => {
               "[16]" =>{
                  portgroup   => "vc.[1].dvportgroup.[7]",
                  netstack    => "host.[".HOSTSET_NUM1."].netstack.[8]",
                  ipv4address => '172.22.5.1'.HOSTSET_NUM1.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },


            'Add'.HOSTSET_NUM2.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[1]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[1]",
                  ipv4address => '172.31.5.'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM2.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[2]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
		  netstack    => "host.[".HOSTSET_NUM2."].netstack.[1]",
		  ipv4address => '172.31.5.'.HOSTSET_NUM2.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM2.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[3]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM2.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[4]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[2]",
                  ipv4address => '172.32.5.'.HOSTSET_NUM2.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM2.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[5]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'Add'.HOSTSET_NUM2.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[6]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[3]",
                  ipv4address => '172.33.5.'.HOSTSET_NUM2.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },

            'VLANAdd'.HOSTSET_NUM2.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[7]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[4]",
                  ipv4address => '172.16.5.1'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM2.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[8]" =>{
                  portgroup   => "vc.[1].dvportgroup.[1]",
		  netstack    => "host.[".HOSTSET_NUM2."].netstack.[4]",
		  ipv4address => '172.16.5.1'.HOSTSET_NUM2.'1',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM2.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[9]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM2.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[10]" =>{
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[5]",
                  ipv4address => '172.17.5.1'.HOSTSET_NUM2.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM2.'Vmk5' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[11]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'VLANAdd'.HOSTSET_NUM2.'Vmk6' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[12]" =>{
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[6]",
                  ipv4address => '172.18.5.1'.HOSTSET_NUM2.'1',
                  netmask     => "255.255.255.0",
               },
               },
            },


            'BridgeAdd'.HOSTSET_NUM2.'Vmk1' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[13]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[7]",
                  ipv4address => '172.21.5.'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM2.'Vmk2' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[14]" =>{
                  portgroup   => "vc.[1].dvportgroup.[6]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[7]",
		  ipv4address => '172.21.5.1'.HOSTSET_NUM2.'0',
		  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM2.'Vmk3' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[15]" =>{
                  portgroup   => "vc.[1].dvportgroup.[5]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[8]",
                  ipv4address => '172.22.5.'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },
            'BridgeAdd'.HOSTSET_NUM2.'Vmk4' => {
               Type         => "Host",
               TestHost     => "host.[".HOSTSET_NUM2."]",
               vmknic => {
               "[16]" =>{
                  portgroup   => "vc.[1].dvportgroup.[7]",
                  netstack    => "host.[".HOSTSET_NUM2."].netstack.[8]",
                  ipv4address => '172.22.5.1'.HOSTSET_NUM2.'0',
                  netmask     => "255.255.255.0",
               },
               },
            },


            "SetVDRPortProperty" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               dvsname      => "vc.[1].vds.[1]",
               vdrportproperty => "enable",
               networktype  => "vlan",
            },
            "SetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[1]",
               setnetstackgateway => "add",
               route => "172.31.5.1",
            },
            "SetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[2]",
               setnetstackgateway => "add",
               route => "172.32.5.1",
            },
            "SetNetstack3Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[3]",
               setnetstackgateway => "add",
               route => "172.33.5.1",
            },

            "VLANSetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[4]",
               setnetstackgateway => "add",
               route => "172.16.5.1",
            },
            "VLANSetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[5]",
               setnetstackgateway => "add",
               route => "172.17.5.1",
            },
            "VLANSetNetstack3Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[6]",
               setnetstackgateway => "add",
               route => "172.18.5.1",
            },

            "BridgeSetNetstack1Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[7]",
               setnetstackgateway => "add",
               route => "172.21.5.1",
            },
            "BridgeSetNetstack2Gateway" => {
               Type => "Netstack",
               TestNetstack => "host.[".HOSTSET."].netstack.[8]",
               setnetstackgateway => "add",
               route => "172.22.5.1",
            },
            "TrafficSameSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
            },
            "TrafficSameSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[3]",
            },
            "TrafficSameSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[4]",
            },
            "TrafficDifferentSubnetSameHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentSubnetSameHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[4]",
               SupportAdapter => "host.[3].vmknic.[2]",
            },
            "TrafficDifferentSubnetDifferentHost" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestDuration   => "60",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[4]",
            },
            "TrafficDifferentSubnetDifferentHost2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[3].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[3]",
            },
            "TrafficDifferentHostAllSubnet" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               ParallelSession=> "yes",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2-3].vmknic.[1-6]",
            },
            "DeleteConnection" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               Connection   => "delete",
               dvsname      => "vc.[1].vds.[1]",
               connectionid => "1",
            },
            'RemoveAllHost1Vmks' => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[-1]",
            },
            'RemoveAllHost2Vmks' => {
               Type => "Host",
               TestHost => "host.[2]",
               removevmknic => "host.[2].vmknic.[-1]",
            },
            'RemoveAll'.HOSTSET_NUM1.'Vmks' => {
               Type => "Host",
               TestHost => "host.[".HOSTSET_NUM1."]",
               removevmknic => "host.[".HOSTSET_NUM1."].vmknic.[-1]",
            },
            'RemoveAll'.HOSTSET_NUM2.'Vmks' => {
               Type => "Host",
               TestHost => "host.[".HOSTSET_NUM2."]",
               removevmknic => "host.[".HOSTSET_NUM2."].vmknic.[-1]",
            },
            "ReSetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
            "SetLogLevel" => {
               Type         => "LocalVDR",
               Testvdr      => "host.[3].vdr.[1]",
               vdrloglevel  => "0",
               vdrsetup     => "1",
            },
         },
      },
      'DriverReload' => {
           Component         => "Virtual Net Devices",
           Category           => "Sample",
           TestName          => "DriverReload",
           Summary           => "Load the driver with the given " .
                                "command line arguments (if any)",
           ExpectedResult    => "PASS",

           Parameters  => {
            SUT => {
               vnic        => ['vmxnet3:1'],
               },
            helper1 => {
               vnic        => ['vmxnet3:1'],
               },
            },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['DriverReload_1'],['NetperfTraffic']],

            "DriverReload_1" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               DriverReload     => "null",
            },
            "NetperfTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "udp",
               TestDuration   => "10",
            },
         },
      },

      #
      # Test script for WOL
      #
      'WOL' => {
         Component            => "VirtualNetDevices",
         Category             => "VD",
         TestName             => "SampleWOLTest",
         Summary              => "Sample test to check WOL API testing",
         ExpectedResult       => "PASS",
         Parameters           => {
            SUT               => {
               'vnic'         => ['vmxnet3:1'],
            },
            helper1           => {
               'vnic'         => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['ConfigureIP'],['SetWOL'],['Standby'],['WOL'],
				  ['SetWOL1'],['Standby'],['WOL1']],

            "ConfigureIP" => {
               Type               => "NetAdapter",
               Target             => "SUT,helper1",
               IPv4               => "AUTO",
            },
            "SetWOL1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               SetWol         => "ARP",
            },
            "WOL1" => {
               Type               => "NetAdapter",
               Target             => "SUT",
               WakeupGuest        => "ARP", # Sample values are ARP,UNICAST,MAGIC
            },
            "SetWOL" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               SetWol         => "MAGIC",
            },
            "Standby" => {
               Type               => "VM",
               Target             => "SUT",
               Operation          => "standby",
            },
            "WOL" => {
               Type               => "NetAdapter",
               Target             => "SUT",
               WakeupGuest        => "MAGIC", # Sample values are ARP,UNICAST,MAGIC
            },
         },
      },

      'CreatevSwitch' => {
         Component         => "Virtual Switch",
         Category           => "Sample",
         TestName          => "CreatevSwitch",
         Summary           => "Create a vSwitch with vSwitch Name generated " .
                              "automatically",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['HostOperation_2']],
            Duration          => "time in seconds",

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "add",
            },

            "HostOperation_2" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "delete",
               vswitchName    => "1", # 1 is the index of vswitch added in
                                      # "HostOperation_1"
            },
         },
      },

      'CreatePG' => {
         Component         => "Virtual Portgroup",
         Category           => "Sample",
         TestName          => "CreatePG",
         Summary           => "Create a portgroup on the given vswitch",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
            helper1     => {
               host        => 1,
            },
         },

         WORKLOADS => {
            # Run workloads in parallel
            Sequence          => [['HostOperation_1','HostOperation_2']],
            Duration          => "time in seconds",

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "ADD",
               vswitchName    => "testswitchSUT",
               Portgroup      => "ADD",
               PortGroupName  => "testPGSUT",
            },

            "HostOperation_2" => {
               Type           => "Host",
               Target         => "helper1",
               vswitch        => "ADD",
               vswitchName    => "testswitchHpr",
               Portgroup      => "ADD",
               PortGroupName  => "testPGHpr",
            },

         },
      },

      'StressOptions' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "StressOptions",
         Summary           => "Run traffic with network stress options",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['EnableStress'],['NetperfTraffic'],['DisableStress']],
            # Note the workload name (example EnableStress) can be anything intuitive.
            # Just make sure it is exactly same when specified in Sequence field
            "EnableStress" => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Enable",
               stressoptions  => "%VDNetLib::TestData::StressTestData::networkStress",
            },

            "NetperfTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
            },

            "DisableStress" => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Disable",
               stressoptions  => "%VDNetLib::TestData::StressTestData::networkStress",
            },
         },
      },

      'ConfigurePGAndvSwitch' => {
         Component         => "Virtual Portgroup",
         Category           => "Sample",
         TestName          => "ConfigurePGAndvSwitch",
         Summary           => "Configure portgroup and vswitch",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               'vnic'      => ['vmxnet3:1'],
            },
            helper1     => {
               'vnic'      => ['vmxnet3:1'],
               host        => 1,
            }
         },

         WORKLOADS => {
            Sequence          => [['ConfigureMTU'],['ConfigureVLAN']],

            "ConfigureMTU" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               # Testkeys in SwitchWorkload can take specific,
               # list, range of values
               MTU            => "1500-9000,500",
            },

            "ConfigureVLAN" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               # Testkeys in SwitchWorkload can take specific,
               # list, range of values
               VLAN           => "10-20,1",
            },
         },
      },

      'ChangeRingParams' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "ChangeRingParams",
         Summary           => "Configure a list of Tx/Rx ring sizes before running traffic",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },
         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['ConfigureTxRing'],['ConfigureRxRing'],
                                  ['TRAFFIC_1']],

            "ConfigureTxRing" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               TxRingSize     => "32,64,128,256,512,1024,2048,4096,512",
            },

            "ConfigureRxRing" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               Rx1RingSize    => "32,64,128,256,512,1024,2048,4096,512",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
            },
         },
      },

      # Command to run the TestvSwitch testcase:
      # ./vdNet.pl -sut <ESX_HOST_IP> -t Sample.Sample.TestvSwitch
      # e.g:  ./vdNet.pl -sut 10.12.13.14 -t Sample.Sample.TestvSwitch

      'TestvSwitch' => {
         Component         => "Virtual Switch",
         Category           => "Sample",
         TestName          => "TestvSwitch",
         Summary           => "Exerciess different features available for" .
                              " vSwitch",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               vmnic       => ['any:2'],
               switch      => ['vss:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['SetMacChange'],
                                  ['SetForgedXmit'],
                                  ['SetPromiscuous'],
                                  ['SetBeacon'],
                                  ['AddUplink1'],
                                  ['AddUplink2'],
                                  ['ConfigurePortGroup'],
                                  ['ConfigurePortGroups'],
                                  ['SetTrafficShaping'],
                                  ['SetNicTeaming'],
                                  ['SetFailover1'],
                                  ['SetFailover2']],

            "SetMacChange" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setmacaddresschange => "Enable,Disable",
		MaxTimeout     => "300",    # Maximum  timeout  value in
					    # seconds for this workload.
					    # This is a case-insensitive
					    # key.
            },

            "SetForgedXmit" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setforgedtransmit => "Enable,Disable",
		maxTimeout     => "300",
            },

            "SetPromiscuous" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setpromiscuous => "Enable,Disable",
		maxtimeout     => "300",
            },

            "SetBeacon" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setbeacon      => "Enable,Disable",
		MaxTimeout     => "300",
            },

            # In the workload sequence below, "Delete" operation
            # is being performed twice. Once before "Add" is done
            # and once after it. The reason for calling it twice
            # is that as we are getting the free pnic/vmnic dynamically
            # from the vdNet utilities. By default the vdNet infrastructure
	    # uplinks the very first free vmnic to the vSwitch created.
            # Hence for our purpose we first remove that uplink
            # from vSwitch using "Delete", then use further.

            "AddUplink1" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                configureuplinks => "Delete,Add",
                VmnicAdapter   => "1",
		MaxTimeout     => "300",
            },

            "AddUplink2" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                configureuplinks => "Add",
                VmnicAdapter   => "2",
		MaxTimeout     => "300",
            },

            "ConfigurePortGroup" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                configureportgroup => "Add,Delete",
                pgname         => "vss-pg",
		MaxTimeout     => "300",
            },

            "ConfigurePortGroups" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                configureportgroup => "Add,Delete",
                pgname         => "vss-pgs",
                pgnumber       => "5",
		MaxTimeout     => "300",
            },

            "SetTrafficShaping" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                settrafficshaping  => "Enable,Disable",
                avgbandwidth   => "250000",
                peakbandwidth  => "400000",
                burstsize      => "8192",
            },

            "SetNicTeaming" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setnicteaming  => "Enable",
                VmnicAdapter   => "1",
                failback       => "true, false",
                lbpolicy       => "portid, iphash, mac, explicit",
                failuredetection => "link, beacon",
                notifyswitch   => "true, false",
            },

            "SetFailover1" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setfailoverorder => "1+2",
            },
            "SetFailover2" => {
                Type           => "Switch",
                Target         => "SUT",
                SwitchType     => "vswitch",
                TestSwitch     => "1",
                setfailoverorder => " 2+ 1 ",
            },
         },
      },

      'EnableDisableRSS' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "EnableDisableRSS",
         Summary           => "Enable and Disable RSS for 10 times on both " .
                              "and helper",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['NetAdapter_1'],['TRAFFIC_1']],

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               #
               # NetAdapterWorkload can understand the 'Iterations' key and run
               # the set of operations for given number of iterations.
               #
               Iterations     => "10",
               #
               # Note that NetAdapter workload can take SUT,helper1 together
               # for the key 'Target'. This avoids the necessity to write 2
               # different hashes for each machine.
               #
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               RSS            => "Enable,Disable",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "30",
            },
         },
      },
      #
      # This test case explains how to run workloads in parallel with other
      # workloads of same type of different type. This feature of vdNet to
      # run workloads in parallel does not guarantee exact functional
      # verification, but would be useful to find whether the stress causes
      # any vm/host crash.
      #
      'ChangeTSOTraffic' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "ChangeTSOTraffic",
         Summary           => "Change NIC state while running traffic",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            # FlipNicState and TRAFFIC_1 are run in parallel.
            Sequence          => [['EnableNic'],['FlipTSO','Traffic_1']],

            "EnableNic" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               TSOIPv4        => "Enable",
            },

            "FlipTSO" => {
               Type           => "NetAdapter",
               Iterations     => "8",
               Target         => "SUT",
               TestAdapter    => "1",
               TSOIPv4        => "Enable,Disable",
            },

            "Traffic_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "120",
               NoOfinbound    => "1",
               BurstType      => "RR",
               L4Protocol     => "TCP",
            },
         },
      },

      #
      # This test case demonstrates the ability of vdNet to generate various
      # combinations when multiple operations are given in the same workload.
      # vdNet has another feature called 'Iterator' which allows to generate
      # combinations when the values passed to a particular key has specific,
      # list, range of values.
      #
      'vNicComboTest' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "vNicComboTest",
         Summary           => "Test combination of various vNic Configurations",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['NetAdapter_1']],

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               # The following specification would first generate MTU values
               # 1500 to 4000 in steps of 500. One value from MTU, RSS and
               # set_queues will be selected for one combination.
               #
               MTU            => "1000-3000,1000",
               RSS            => "Enable,Disable",
               set_queues     => {
                  'direction' => "tx",
                  'value'     => "1,2,4,8",
                },
            },
         },
      },

      #
      # This test case demonstrates the ability of vdNet to take multiple
      # test adapters as input. It is important that the index a test adapter
      # is always less than or equal to the max number of adapters.
      # Max adapters is sum of count value (<type>:<count>) in  "vnic"
      # under Parameters key
      #
      'MultipleAdapters' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "MultipleAdapters",
         Summary           => "Configuring multiple adapter at same time",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               # note number of adapters to be
               # enabled before running any workload is 2
               vnic        => ['vmxnet3:2'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['NetAdapter_1','NetAdapter_2']],
            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1", # refers to 1st adapter
               MTU            => "9000",
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "2", # refers to second adapter
               MTU            => "9000",
            },
         },
      },


      #
      # This test case demonstrates the VM workload using Suspend/Resume
      # operation.
      #
      'SuspendResume' => {
         Component         => "Virtual Net Devices",
         Category           => "Sample",
         TestName          => "SuspendResume",
         Summary           => "Test connectivity after Suspend/Resume",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['VMOperation_1'],['TRAFFIC_1']],
            Duration          => "time in seconds",

            "VMOperation_1" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestDuration   => "60",
            },
         },
      },

      #
      # 1) This test case shows that a traffic tool is picked even if the
      #    user is not aware of any traffic tool to use.
      # 2) It shows how parallel inbound(RX path) and parallel outbound(TX path)
      #    can be stressed.
      # 3) It shows the type of data stream,(rr,stream) which can be used to
      #    stress both inbound and outbound path
      # 4) Verify all the sessions using Packet capture library
      #
      'UDPTraffic' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "UDPTraffic",
         Summary           => "Run UDP traffic stressing both inbound and " .
                              "outbound path",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               Iterations        => "1",
               ToolName       => "netperf",
               #BurstType      => "stream,rr",
               L4Protocol     => "udp",
               NoofInbound    => "3",
               #NoofOutbound   => "2",
               Verification   => "PktCap", # This will allow verification using
                                           # packet capture
            },
         },
      },

      'SetIPv6' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "SetIPv6",
         Summary           => "Set IPv6 address on both SUT and helper and run IPv6 " .
                              "traffic using netperf, then remove the IPv6 addresses ".
         "and run IPv4 traffic",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['NetAdapter_1'],['TRAFFIC_1'],
                                  ['NetAdapter_2'],['TRAFFIC_2']],

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               'IPV6ADDR' => 'DEFAULT',
               'IPV6' => 'ADD',
            },
            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "udp",
               L3Protocol     => "ipv6",
               TestDuration   => "3",
            },
            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               'IPV6ADDR' => 'DEFAULT',
               'IPV6' => 'DELETE',
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "udp",
               TestDuration   => "3",
            },
         },
      },

      #
      # This test case demonstrates:
      #  - sVLAN configuration on the portgroups
      #  - enabling TSO on test and support adapters
      #  - send tcp traffic
      #  - verification using packet capture library
      #

      'TSOsVLAN' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "TSOsVLAN",
         Summary           => "Testing TSO with sVLAN",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['Switch_1'],['Switch_2'],['NetAdapter_1'],
                                 ['TRAFFIC_1']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D, #sVLAN id
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               # Note that both SUT and helper1 are configured ony by one
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               # Specific tool name is mentioned here
               # Only TCP is used
               ToolName       => "netperf",
               BurstType      => "stream",
               L4Protocol     => "tcp",
               Verification   => "PktCap",
               TestDuration   => "30",
            },
         },
      },

      #
      # This test case demonstrates vdNet framework's ability to easily
      # loop through a range of packet sizes for testing TSO.
      #
      'TSOTCP' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "TSOTCP",
         Summary           => "TSO TCP testing with wide range of packet size",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['NetAdapter_1'],['TRAFFIC_1']],

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPv4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "1",
               RequestSize    => "4000-12000,2000",
               ResponseSize   => "6000",
               Verification   => "Stats",
            },
         },
      },

      #
      # This test case demonstrates end-to-end JumboFrame testing.
      # The following hash specifies JF configuration on adapters and
      # vSwitch. Also, indicates the type of traffic to generate.
      #

      'JumboFrame' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "JumboFrame",
         Summary           => "Test JF end-to-end",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['NetAdapter_1'],['TRAFFIC_1'],['NetAdapter_2']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "20",
               LocalSendSocketSize => "4000",
               LocalReceiveSocketSize => "5000",
               RemoteSendSocketSize => "6000",
               RemoteReceiveSocketSize => "7000",
               RequestSize => "8050-8010,10",
               Verification   => "PktCap",
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "1500",
            }
         },
      },


      'PingTraffic' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "PingTraffic",
         Summary           => "Run Ping traffic stressing both inbound and " .
                              "outbound path",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "ping",
               NoofInbound    => "3",
               RoutingScheme  => "unicast,broadcast,flood",
               NoofOutbound   => "2",
            },
         },
      },


      'IperfTraffic' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "IperfTraffic",
         Summary           => "Run TCP and UDP Iperf traffic stressing both ".
                              "inbound and outbound path",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf,netperf",
               l4protocol     => "tcp,udp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
            },
         },
      },

      'IperfTwoHelper' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "IperfTwoHelper",
         Summary           => "Run TCP and UDP Iperf traffic stressing both ".
                              "inbound and outbound path",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
            helper2     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1'],['TRAFFIC_2']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               SleepBetweenCombos => "20",
               l4protocol     => "tcp,udp",
               TestAdapter    => "helper1:vnic:1",
               SupportAdapter => "helper2:vnic:1",
               NoofOutbound   => "1",
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               l4protocol     => "tcp,udp",
               SleepBetweenCombos => "40",
               SupportAdapter => "helper2:vnic:1",
               TestAdapter    => "SUT:vnic:1",
               NoofInbound   => "1",
            },
         },
      },

      'TrafficBetweenHelpers' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "TrafficBetweenHelpers",
         Summary           => "Run ping amongst helper machines without using SUT ".
                              "this is required in test cases for vSS. In next ".
                              "traffic test run Netperf amongst all machine ".
                              "including helper1 to helper2 combination",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
            helper2     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1'],['TRAFFIC_2']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               WhichHelper    => "1,2",
               NoofInbound    => "1",
               NoofOutbound   => "1",
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Netperf",
               WhichHelper    => "all",
            },
         },
      },

      'AllNewTraffic' => {
         Component         => "Virtual Net Devices",
         Category          => "Sample",
         TestName          => "AllNewTraffic",
         Summary           => "Run various combination of traffic using ".
                              "various formats",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
            },
            helper2     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
#            Sequence          => [['TRAFFIC_10'],['TRAFFIC_11']],
            Sequence          => [['TRAFFIC_1'],['TRAFFIC_2'],['TRAFFIC_3'],
                                  ['TRAFFIC_4'],['TRAFFIC_5'],['TRAFFIC_6'],
                                  ['TRAFFIC_7'],['TRAFFIC_8'],['TRAFFIC_9'],
                                  ['TRAFFIC_10'],['TRAFFIC_11']],

            "TRAFFIC_11" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               TestDuration   => "10",
               Verification   => "PktCap",
            },
            "TRAFFIC_10" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               TestDuration   => "10",
            },
            "TRAFFIC_9" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               SleepBetweenCombos => "20",
               TestDuration   => "10",
            },
            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "10",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               TestAdapter    => "sUT:vnic:1",
               SupportAdapter => "helper2:vnic:1",
               Verification   => "PktCap",
               VerificationAdapter   => "helper1:vnic:1",
            },
            "TRAFFIC_3" => {
               Type           => "Traffic",
               WhichHelper    => "1,2",
               Verification   => "PktCap",
            },
            "TRAFFIC_4" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               WhichHelper    => "1",
               Verification   => "PktCap",
            },
            "TRAFFIC_5" => {
               Type           => "Traffic",
               TestAdapter    => "sUT:vmknic:1",
               SupportAdapter    => "1",
               SupportIntType    => "vnic",
               VerificationAdapter   => "helper2:vnic:1",
            },
            "TRAFFIC_6" => {
               Type           => "Traffic",
               SupportAdapter    => "1",
               SupportIntType    => "vnic",
               TestAdapter    => "1",
               TestIntType    => "vmknic",
            },
            "TRAFFIC_7" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               Verification   => "PktCap",
            },
            "TRAFFIC_8" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "Helper1:vnic:1",
               SupportAdapter => "SUT:vmknic:1,helper2:vnic:1",
            },
         },
      },

      'TrafficPreCheckIn' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "AllNewTraffic",
         Summary           => "Run various combination of traffic using ".
                              "various formats",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
            },
            helper2     => {
               vnic        => ['vmxnet3:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
            },
         },
         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1'],['TRAFFIC_2'],['TRAFFIC_5'],
                                  ['TRAFFIC_4'],['TRAFFIC_3'],['TRAFFIC_6'],
                                  ['TRAFFIC_7'],['TRAFFIC_8'],
                                  ['TRAFFIC_10'],['TRAFFIC_11'],
                                  ['TRAFFIC_12'],['TRAFFIC_13'],
                                  ['TRAFFIC_14']],
            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "10",
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
               Verification   => "PktCap",
               VerificationAdapter   => "SUT:vnic:1",
            },
            "TRAFFIC_3" => {
               Type           => "Traffic",
               ToolName       => "ping",
               SleepBetweenCombos => "20",
               NoofInbound    => "2",
               RoutingScheme  => "broadcast,flood",
               NoofOutbound   => "2",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
            },
            "TRAFFIC_4" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               Verification   => "PktCap",
            },
            "TRAFFIC_5" => {
               Type           => "Traffic",
               TestAdapter    => "SUT:vmknic:1",
               SupportAdapter    => "1",
               SupportIntType    => "vnic",
               VerificationAdapter   => "helper1:vnic:1",
            },
            # Old Standard for representing
            "TRAFFIC_6" => {
               Type           => "Traffic",
               SupportAdapter    => "1",
               SupportIntType    => "vnic",
               TestAdapter    => "1",
               TestIntType    => "vmknic",
            },
            "TRAFFIC_7" => {
               Type           => "Traffic",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
               Verification   => "Verification_1",
               VerificationAdapter   => "SUT:vnic:1",
            },
            "TRAFFIC_8" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "helper1:vnic:1",
               SupportAdapter => "SUT:vmknic:1,helper1:vnic:1",
            },
            "TRAFFIC_9" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               SleepBetweenCombos => "20",
               TestDuration   => "10",
            },
            "TRAFFIC_10" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               TestDuration   => "10",
            },
            "TRAFFIC_11" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               TestDuration   => "10",
               Verification   => "PktCap",
            },
            "TRAFFIC_12" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "SUT:vnic:1","SUT:vmknic:1",
               SupportAdapter => "SUT:vmknic:1",
            },
            "TRAFFIC_13" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L3Protocol     => "ipv6",
               TestDuration   => "3",
            },
            "TRAFFIC_14" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               BurstType             => "stream",
               NoofOutbound          => "1",
               NoofInbound           => "1",
               TestAdapter           => "SUT:vnic:1,helper1:vmknic:1",
               SupportAdapter        => "SUT:vmknic:1",
               Verification          => "PktCap",
            },
            "Stats_Verify2" => {
               'Vsish' => {
                  verificationtype => "vsish",
                  Target => "src,dst",
                  "src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx" => "5-",
                  "src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK" => "dst./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesRxOK",
               },
            },
            "Stats_Verify1" => {
               'Vsish' => {
                  verificationtype => "vsish",
                  Target => "src,dst",
                  "src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesTxOK" => "10000+",
                  "src./net/portsets/<PORTSET>/ports/<PORT>/clientstats.droppedTx" => "5-",
                  "dst./net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesRxOK" => "10000+",
               },
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
         },
      },

      'VSSPreCheckIn' => {
         Component         => "VDnet",
         Category          => "Internal",
         TestName          => "Covering switch testing for testadapter, testswitch," .
                              "testportgroup, vmnicadapters",
         Summary           => "Verify the function of port mirror create and destroy",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT           => {
               host       => 1,
               switch     => ['vss:3'],
               vm         => 1,
               vnic       => ['e1000:2'],
               vmnic      => ['any:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['VSS'],['VSS_1'],['VSS_2'],['VSS_3'],
                                  ['VSS_4'],['VSS_5'],['VSS_6'],['VSS_7'],
                                  ['VSS_8'],['VSS_9'],['VSS_10']],
            Duration          => "time in seconds",
            "VSS" => {
               Type          => "Switch",
               Target        => "SUT",
               TestAdapter    => "1-2",
               MTU           => "6997",
               VLAN           => "4095",
               setbeacon      => "Enable,Disable",
            },
            "VSS_1" => {
               Type          => "Switch",
               Target        => "SUT",
               TestAdapter    => "1",
               configureportgroup => "Add,Delete",
               pgname         => "vss_pg",
            },
            "VSS_8" => {
               Type          => "Switch",
               Target        => "SUT",
               TestAdapter    => "SUT:vnic:1",
               configureportgroup => "Add,Delete",
               pgname         => "vss_pg5",
            },
            "VSS_2" => {
               Type          => "Switch",
               Target        => "SUT",
               TestSwitch    => "1-3",
               MTU           => "6997",
               setbeacon      => "Enable,Disable",
            },
            "VSS_10" => {
               Type          => "Switch",
               Target        => "SUT",
               TestAdapter    => "SUT:vnic:1,SUT:vnic:2",
               MTU           => "6997",
            },
            "VSS_3" => {
               Type          => "Switch",
               Target        => "SUT",
               TestSwitch    => "1",
               configureportgroup => "Add,Delete",
               pgname         => "vss_pg",
            },
            "VSS_4" => {
               Type          => "Switch",
               Target        => "SUT",
               TestPG    => "1",
               MTU           => "6997",
               VLAN           => "4095",
               setbeacon      => "Enable,Disable",
            },
            "VSS_5" => {
               Type          => "Switch",
               Target        => "SUT",
               TestPG    => "1",
               configureportgroup => "Add",
               pgname         => "vss_pg,vss_pg2,vss_pg3",
            },
            "VSS_9" => {
               Type          => "Switch",
               Target        => "SUT",
               TestPG    => "1-3",
               MTU           => "6997",

            },
            "VSS_6" => {
               Type          => "Switch",
               Target        => "SUT",
               TestSwitch    => "SUT:switch:1",
               configureportgroup => "Add,Delete",
               pgname         => "vss_pg4",
            },
            "VSS_7" => {
               Type          => "Switch",
               Target        => "SUT",
               TestPG        => "SUT:portgroups:1",
               MTU           => "6997",
               VLAN           => "4095",
               setbeacon      => "Enable,Disable",
            },
         },
      },

      'VDSPreCheckIn' => {
         Component         => "VDnet",
         Category          => "Internal",
         TestName          => "Covering switch testing for testadapter, testswitch," .
                              "testportgroup, vmnicadapters",
         Summary           => "Verify the function of port mirror create and destroy",
         ExpectedResult    => "PASS",
         Parameters        => {
            vc => 1,
            SUT           => {
               host       => 1,
               switch     => ['vds:1'],
               vnic       => ['e1000:1'],
               vmknic      => ['switch1:1'],
               vmnic      => ['any:2'],
            },
            helper1      => {
               vnic       => ['e1000:1'],
               switch      => ['vds:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['ConfigIPHashTeaming'],
                                  ['CreateDVPG_A'],['CreateDVPG_C'],['RemoveDVPortgroup'],
                                  ['AddPorts_B'],
                                  ['EnableShaping1'],['EnableMonitoring'],
                                  ['TrunkRange1'], ['TrunkRange2'], ['TrunkRange3']],
            Duration          => "time in seconds",
            "ConfigIPHashTeaming"  => {
                Type           => "Switch",
                Target         => "SUT",
                TestPG         => "1",
                SwitchType     => "vdswitch",
                confignicteaming => "2",
                lbpolicy       => "iphash",
                notifyswitch   => "yes,no",
                failback       => "yes,no",
            },
            "CreateDVPG_A"   => {
               Type           => "Switch",
               SwitchType     => "vdswitch",
               Target         => "helper1",
               TestSwitch     => "1",
               createdvportgroup => "promiscuous_a,promiscuous_b",
            },
            "CreateDVPG_C"   => {
               Type           => "Switch",
               SwitchType     => "vdswitch",
               Target         => "helper1",
               TestSwitch     => "SUT:switch:1",
               createdvportgroup => "promiscuous_c,promiscuous_d",
            },
            "RemoveDVPortgroup"  => {
               Type              => "Switch",
               Target            => "helper1",
               TestSwitch        => "1",
               removedvportgroup => "promiscuous_a",
            },
            "AddPorts_B" => {
               Type            => "Switch",
               SwitchType      => "vdswitch",
               Target          => "helper1",
               TestSwitch      => "1",
               ports           => "5",
               addporttodvportgroup => "promiscuous_b",
            },
            "TrunkRange1"   => {
               Type           => "Switch",
               SwitchType     => "vdswitch",
               Target         => "SUT",
               TestSwitch     => "SUT:switch:1",
               createdvportgroup => "vlan_c",
            },
            "TrunkRange2"      => {
               Type           => "Switch",
               SwitchType     => "vdswitch",
               Target         => "SUT",
               TestSwitch     => "1",
               ports          => "10",
               addporttodvportgroup => "vlan_c",
            },
            "TrunkRange3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestSwitch     => "1",
               TrunkRange     => "[1-2]",
               Portgroup      => "vlan_c",
            },
            "EnableShaping1"   => {
               Type           => "Switch",
               Target         => "helper1",
               TestSwitch     => "1",
               EnableInShaping => "promiscuous_b",
               PeakBandwidth  => "1000000", # in Kbps
               AvgBandwidth   => "1000000", # in Kbps
               BurstSize      => "102400", # in Kbytes
            },
            "EnableMonitoring" => {
               Type          => "Switch",
               Target        => "SUT",
               TestSwitch    => "1",
               set_monitoring => {
                  'status' => 'true',
                  'dvportgroup'   => "1",
               }
            },
         },
      },

      'PswitchPreCheckIn' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "CDP",
         Summary           => "Test CDP support on vds",
         ExpectedResult    => "PASS",
         Parameters        => {
            vc             => 1,
            SUT            => {
               vmnic       => ['any:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['VerifyCDPOnSwitch']],
            "VerifyCDPOnSwitch"  => {
                Type             => "Switch",
                TestAdapter      => "SUT:vmnic:1",
                VmnicAdapter     => "SUT:vmnic:1",
                CheckCDPOnSwitch => "yes",
            },
         },
      },

      'VDSPreCheckIn2' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "CDP",
         Summary           => "Test CDP support on vds",
         ExpectedResult    => "PASS",
         Parameters        => {
            vc             => 1,
            SUT            => {
               switch      => ['vds:1'],
               vmnic       => ['any:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [["VerifyCDPOnEsx1"],["VerifyCDPOnEsx2"]],
            "VerifyCDPOnEsx1"  => {
                Type           => "Switch",
                Target         => "SUT",
                TestSwitch     => "1",
                SwitchType     => "vdswitch",
                CheckCDPOnEsx  => "yes",
                VmnicAdapter     => "1",
            },
            "VerifyCDPOnEsx2"  => {
                Type           => "Switch",
                TestAdapter      => "SUT:vmnic:1",
                VmnicAdapter     => "SUT:vmnic:1",
                CheckCDPOnEsx  => "yes",
            },
         },
      },

      'NetAdapterPreCheckIn' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "NetAdpaterPreCheckIn",
         Summary           => "Pre check in tests for NetAdpater" .
                              "verify 'ExitSequence' operation",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
               switch      => ['vss:1'],
               vmknic      => ['switch1:1'],
            },
            helper1            => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['DisableEnablevmknic'],['MTU'],['IPv4'],['WOL'],['MTU_2'],
                                  ['DisableEnablevNic'],['IPv4_2'],
                                  ['SetWOL1'],['INTX']],
            "MTU" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntType          => "vnic",
               TestAdapter    => "1",
               MTU            => "3000,1500",
            },
            "IPv4" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               ipv4           => "192.168.111.1",
               TestAdapter    => "1",
            },
            "MTU_2" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "SUT:vnic:1",
               MTU            => "3000,1500",
            },
            "IPv4_2" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               ipv4           => "192.168.116.31",
               TestAdapter    => "SUT:vnic:1",
            },
            "DisableEnablevNic" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               DeviceStatus   => "DOWN,UP",
               MaxTimeout     => "16200",
            },
            "DisableEnablevmknic" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmknic",
               DeviceStatus   => "DOWN,UP",
            },
            "WOL" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               wakeupguest    => "MAGIC",
            },
           "INTX" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-INTX",
            },
            "SetWOL1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               SetWol         => "ARP",
            },
         },
      },

      'HostPreCheckInVSS' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "HostPreCheckIn",
         Summary           => "PreCheckIn tests for HostWorkload",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               switch      => ['vss:1'],
               vnic        => ['vmxnet3:1'],
               vmknic      => ['switch1:1'],
            },
         },

         WORKLOADS => {
            Sequence   => [['HostOperation_1'],['HostOperation_1A'],
                           ['HostOperation_1B'],['HostOperation_1C'],
                           ['DisableHwLRO'],['DVFilterHostSetup'],
                           ['AddRemDVFilterToVM']],
            Duration          => "time in seconds",

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "add",
               TestSwitch     => "test",
               AbleIPv6       => "ENABLE",
            },
            "HostOperation_1A" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "delete",
               TestSwitch     => "SUT:switch:2",
            },
            "HostOperation_1B" => {
               Type           => "Host",
               Target         => "SUT",
               portgroup      => "add",
               portgroupname  => "migrate-pg",
               vswitchname    => "migrate-to-net",
            },
            "HostOperation_1C" => {
               Type           => "Host",
               Target         => "SUT",
               portgroup      => "delete",
               TestPG         => "migrate-pg",
               vswitchname    => "migrate-to-net",
            },
            "DisableHwLRO"  => {
               Type           => "Host",
               TestAdapter    => "SUT:vnic:1",
               Lro            => "disable",
               LroType        => "Hw",
            },
            "DVFilterHostSetup" => {
               Type           => "Host",
               Target         => "SUT",
               DVFilterHostSetup => "qw(dvfilter-generic-1:add)",
            },
            "PowerOff" => {
               Type           => "VM",
               Operation      => "poweroff",
            },
            "AddRemDVFilterToVM" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1",
               AddRemDVFilterToVM =>
                   "qw(filter0:name:dvfilter-fw-1 filter0:onFailure:failOpen)",
            },
            "VmknicAddDelete" => {
               Type           => "Host",
               Target         => "SUT",
               TestPG         => "1",
               IP             => "192.168.0.222",
               Vmknic         => "Add",
            },
         },
      },

      'HostPreCheckInVDS' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "HostPreCheckIn",
         Summary           => "PreCheckIn tests for HostWorkload",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               vm          => 1,
               switch      => ['vds:1'],
               vmnic       => ['any:1'],
               vmknic      => ['switch1:1'],
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence   => [['SetPortUp'],['VDS2EsxcliVMPortListVerify']],
#                           ['MonitorVSTVLANPkt']],
            Duration          => "time in seconds",

            "MonitorVSTVLANPkt" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1",
               MonitorVstVlanPkt => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },
            "SetPortUp" => {
               Type => "Host",
               Target => "SUT",
               switch => "1",
               vmnicadapter => "1",
               port_status => "up",
            },
            "VDS2EsxcliVMPortListVerify" => {
               Type           => "Host",
               Target         => "SUT",
               EsxcliVMPortListVerify => 1,
            },
         },
      },

      'VMPreCheckIn' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "VMPreCheckIn",
         Summary           => "PreCheckIn tests for VMWorkload",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vm          => 1,
               vnic        => ['vmxnet3:2'],
               switch      => ['vss:1'],
            },
         },

         WORKLOADS => {
            Sequence   => [['PowerOnOff'],['DisconnectConnectvNic_B'],
                           ['SuspendResume'],['Addswitch'],['ChangePortgroup1'],['HotAdd']],
            Duration   => "time in seconds",

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "suspend,resume",
            },
            "DisconnectConnectvNic_B" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2",
               Operation      => "DISCONNECTVNIC,CONNECTVNIC",
            },
            "HotAdd" => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "hotaddvnic,hotremovevnic",
               TestAdapter    => "1", # to pick same driver as what is
                                      # defined under parameters hash
               PortgroupName  => "1", # to pick portgroup same as SUT:vnic:1
            },
            "PowerOnOff" => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "poweroff,poweron",
            },
            "Addswitch" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "ADD",
               vswitchName    => "test",
               Portgroup      => "ADD",
               PortGroupName  => "testpglink",
            },
            "ChangePortgroup1" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               PortGroupName  => "testpglink",
               Operation      => "ChangePortgroup",
            },
         },
      },

      'VCPreCheckIn' => {
         Component         => "VDNet",
         Category          => "Internal",
         TestName          => "VCPreCheckIn",
         Summary           => "PreCheckIn tests for VCWorkload",
         ExpectedResult    => "PASS",
         Parameters        => {
            VC             => 1,
            SUT            => {
               vm          => 1,
               vnic        => ['vmxnet3:1'],
               vmnic       => ['any:3'],
            },
         },
         WORKLOADS => {
            Sequence     => [['CreateDC'],['CreateVDS'],['OptOut_Enable'],
                             ['AddUplinks'],['RemoveUplink1'],['CreateDVPG2'],
                             ['ADDVMK1']],
            Duration     => "time in seconds",
            ExitSequence => [ ['RMVMK1'], ['RemoveVDS'],['RemoveDC']],

            "CreateDC" => {
               Type             => "VC",
               OPT              => "adddc",
               DCName           => "/testDC",
#               Hosts            => ["SUT","helper"], #TODOver2 - Ask Gagan
               Hosts            => "SUT",
            },
            "CreateVDS" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vdstest",
               DCName         => "testDC",
               Uplink         => "SUT::1",
            },
            "OptOut_Enable" => {
               Type           => "VC",
               OPT            => "optout",
               VDSName        => "vdstest",
               Host           => "SUT",
               Value          => "0",
            },
            "AddUplinks"     => {
               Type           => "VC",
               OPT            => "adduplink",
               VDS            => "2",
               Uplink         => "SUT::1",
            },
            "CreateDVPG2" => {
               Type              => "Switch",
               SwitchType        => "vdswitch",
               Target            => "SUT",
               TestSwitch        => "2",
               datacenter        => "testDC",
               createdvportgroup => "vmkpg",
            },
            "ADDVMK1" => {
               Type            => "VC",
               OPT             => "addvmk",
               Host            => "SUT",
               VDS             => "2",
               DCName          => "testDC",
               DVPORTGROUPNAME => "vmkpg",
               IPAdd           => "192.168.111.1",
            },
            "RemoveUplink1" => {
               Type          => "VC",
               OPT           => "removeuplink",
               VDS           => "2",
               Uplink        => "SUT::3",
               Host          => "SUT",
            },
            "RMVMK1" => {
               Type            => "VC",
               OPT             => "removevmk",
               Host            => "SUT",
               IPAdd           => "192.168.111.1",
            },
            "RemoveVDS" => {
               Type           => "VC",
               OPT            => "removevds",
               VDSName        => "vdstest",
            },
            "RemoveDC" => {
               Type             => "VC",
               OPT              => "removedc",
               DCName           => "/testDC",
            },
         },
      },

      # Sample test case to test vmknic and vmnic
      'VMNictest'   => {
         Component         => "networking unknown",
         Category          => "Esx Server",
         TestName          => "VMNicTest",
         Summary           => "Simple test on vmnic",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               # vmnic can also be represented vmnic => ['any:2:1000'],
               'vmnic'     => [
                               {
                                  driver => "any",
                                  count  => 2,
                                  speed  => "1G",
                               },
                               ],
               'switch'    => ['vss:1'],
               'host'      => 1,
            },
         },
         WORKLOADS => {
            # The tests run below are given in a random order and may be run
            # in any sequence that that the tester needs. The below examples
            # are only for illustration purposes
            Sequence          => [['NetAdapter_1'],['NetAdapter_2'],
                                  ['NetAdapter_3'],['NetAdapter_4'],
                                  ['NetAdapter_5'],['NetAdapter_6'],
                                  ['NetAdapter_7'],['NetAdapter_8'],
                                  ['NetAdapter_9'],['NetAdapter_10'],
                                  ['NetAdapter_11'],['NetAdapter_12'],
                                  ['NetAdapter_13'],['NetAdapter_14'],
                                  ['NetAdapter_15'],['NetAdapter_16'],
                                  ['NetAdapter_17'],['NetAdapter_18'],
                                  ['NetAdapter_19'],['NetAdapter_20'],
                                  ['NetAdapter_21'],['NetAdapter_22'],
                                  ['NetAdapter_23'],['NetAdapter_24']],

            #
            # Method to get stats from a vmnic
            #
            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NICStats       => "inttxdrp",
            },
            #
            # Method to check if TSO is supported
            #
            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               TSOSupported   => "Check",
            },
            #
            # Method to set TSO
            #
            "NetAdapter_3" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               TSOIPv4        => "1,0",
            },
            #
            # Method to enable / disable Net High DMA
            #
            "NetAdapter_4" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NetHighDMA     => "1,0",
            },
            #
            # Method to enable / disable Net SG Span Pages
            #
            "NetAdapter_5" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NetSGSpanPgs   => "1,0",
            },
            #
            # Method to enable hardware / software Net SG
            #
            "NetAdapter_6" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NetSG          => "1,0",
            },
            #
            # Method to enable / disable IPCheckSum
            #
            "NetAdapter_7" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               IPCheckSum     => "1,0",
            },
            #
            # Method to enable / disable VLAN Rx
            #
            "NetAdapter_8" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "2",
               IntType        => "vmnic",
               VLANRx         => "1,0",
            },
            #
            # Method to enable / disable VLAN Tx
            #
            "NetAdapter_9" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "2",
               IntType        => "vmnic",
               VLANTx         => "1,0",
            },
            #
            # Method to enable / disable WOL on pNIC
            #
            "NetAdapter_10" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NicWOL         => "1,0",
            },
            #
            # Method to retrieve Tx Queue info:
            # "numQueues" for Number of active Tx Queues
            # "defaultQid" for Default Queue ID
            #
            "NetAdapter_11" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               TxQInfo        => "numQueues,defaultQid",
            },
            #
            # Method to retrieve Rx Queue info:
            # "maxQueues" for # of supported queues
            # "numFilters" for # of supported filters
            # "numActiveFilters" for # of active filters
            #
            "NetAdapter_12" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               RxQInfo        => "maxQueues,numFilters,numActiveFilters",
            },
            #
            # Method to retrieve Rx Filter info:
            # RxQID: Rx queue ID where filter is present
            # RxFilterID: Rx filter ID
            #
            "NetAdapter_13" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               RxFilterInfo   => "Get",
               RXQID          => "1",
               RXFILTERID     => "0",
            },
            #
            # Method to retrieve list of Rx Queues
            #
            "NetAdapter_14" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               GetRxQ         => "Get",
            },
            #
            # Method to retrieve number of Tx Queues
            #
            "NetAdapter_15" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               GetTxNumQ      => "Get",
            },
            #
            # Method to retrieve Tx Queue ID:
            # PORTID: Port ID of which Tx queue is to be calculated
            # NUMACTQ: Number of active queues
            #
            "NetAdapter_16" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               GetTxQID       => "Get",
               PORTID         => "50331667",
               NUMACTQ        => "5,4,6,10",
            },
            #
            # Method to retrieve Rx Queue Filters. User should pass the
            # Queue ID as an input as shown below
            #
            "NetAdapter_17" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               GetRxQFilter   => "1,0",
            },
            #
            # Method to retrieve Rx Queue packet count. User should pass the
            # Queue ID as an input as shown below
            #
            "NetAdapter_18" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               QPktCnt        => "Get",
               TRANSTYPE      => "Tx,Rx",
               TXRXQUEUEID    => "1,0",
            },
            #
            # Method to set NIC speed / duplex mode.
            # NOTE: Either Speed and Duplex OR Auto should be passed
            # Speed    : Speed to be set (Optional)
            # DupMode  : Duplex mode to be set (Optional)
            # Auto     : Speed and Duplex mode in Auto negotiation (Optional)
            #
            "NetAdapter_19" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               NicSpeedDup    => "Set",
               AUTO           => "Y",
            },
            #
            # Method to get Rx Pool info
            # PoolId    : Pool Id from which information is to be retrieved
            #             (Mandatory)
            # PoolParam : Argument to be checked, accepts any ONE of values:
            # "attr", "features", "nQueues", "maxQueues", "ratio", "active"
            #
            "NetAdapter_20" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               RxPoolInfo     => "Get",
               POOLID         => "1",
               POOLPARAM      => "attr,features,nQueues,active,maxQueues,".
                                 "ratio",
            },
            #
            # Method to get Rx Pool queues. Enter the pool ID as param next
            # to method call "RxPoolQ"
            #
            "NetAdapter_21" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               RxPoolQ        => "0,1",
            },
            #
            # Method to get Rx Pools
            #
            "NetAdapter_22" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               RxPools        => "Get",
            },
            #
            # Method to get Tx Queue Stats:
            # QueueId  : Queue ID from where information is to be retrieved
            #            (Mandatory)
            # TxQParam : Only one of the values can be passed at a time:
            #            "pktsTransmitted", "txErrors", "txBusy",
            #            "queueStops", "queueStarts"
            #
            "NetAdapter_23" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               TxQStats       => "Get",
               TXQUEUEID      => "1",
               TXQPARAM       => "pktsTransmitted,txErrors,txBusy,queueStops".
                                 ",queueStarts",
            },
            #
            # Method to set packet scheduled algo for vmnics:
            # "1" for SFQ  Note: bnx2 driver not support SFQ, PR 683587
            # "0" for FIFO
            #
            "NetAdapter_24" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               IntType        => "vmnic",
               SetPktSched    => "0,1",
            },
         },
      },

      # Sample test case to demonstrate usage of multiple helpers in test case
      'MultipleHelpersTest'   => {
         Component         => "networking unknown",
         Category          => "Esx Server",
         TestName          => "MultipleHelpersTest",
         Summary           => "Simple test it to demonstrate multiple " .
                              "helpers usage",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
            helper2     => {  # helper2 represents that 2 helpers machines
                              # are needed. If 2 -helper options are not given
                              # at command line, then error will be thrown.
                              # If the # of -helper options is greater than the
                              # machines required by the testcase (represented
                              # here under Parameters key), then the additional
                              # machines given at command line will be ignored.
                              #
               vnic         => ['vmxnet3:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['NetAdapter_2']],
            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1,2,3",
               IntType        => "vmknic",
               DeviceStatus   => "DOWN,UP",
            },
            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1,helper2,",
               TestAdapter    => "1",
               IntType        => "vnic",
               DeviceStatus   => "DOWN,UP",
            },
         },
      },

      #
      # Example to demonstrate event handler implementation. In this case,
      # one workload is requesting parent to run another workload for verification
      #
      'EventHandler1'   => {
         Component         => "vmxnet3",
         Category          => "Virtual Net Devices",
         TestName          => "EventHandler1",
         Summary           => "Simple test to run traffic workload " .
                              "as verification for each TSO option given",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               'switch'    => ['vss:1'],
               'vnic'      => ['vmxnet3:1'],
            },
            helper1        => {
               'switch'    => ['vss:1'],
               'vnic'      => ['vmxnet3:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['NetAdapter_1']],
            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               TSOIPv4        => "Disable,Enable",
               RunWorkload    => "TRAFFIC_1", # indicates TRAFFIC_1 workload
                                              # to run first with TSO disabled,
                                              # then after enabled.
            },
            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "1",
               Verification   => "PktCap",
            },
         },
      },

      #
      # Example to demonstrate event handler implementation. In this case,
      # a workload creating a vswitch and requesting parent to update the
      # testbed hash with this new switch, so that the following workloads
      # can refer to.
      #
      'EventHandler2'   => {
         Component         => "network mgmt and vswitch platform",
         Category          => "Esx Server",
         TestName          => "EventHandler2",
         Summary           => "Simple test to demonstrate event handler. " .
                              "Create a vswitch and update parent about it. ",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               'switch'    => ['vss:1'], # This is TestSwitch 1
            },
         },
         WORKLOADS => {
            Sequence          => [['AddvSwitch'],['ConfigureMTU']],
            "AddvSwitch" => {
               Type           => "Host",
               Target         => "SUT",
               vswitch        => "add",  # This is TestSwitch 2
            },
            "ConfigureMTU" => {
               Type           => "Switch",
               Target         => "SUT",
               TestSwitch     => "2",
               # Testkeys in SwitchWorkload can take specific,
               # list, range of values
               MTU            => "1500,9000",
            },
         },
      },

      # Sample test to demonstrate trafficworkload on vmknic.
      # In this test case,
      'VmknicIperf'   => {
         Component         => "network mgmt and vswitch platform",
         Category          => "Esx Server",
         TestName          => "VmknicIperf",
         Summary           => "Simple test to demonstrate event handler. " .
                              "Create a vswitch and update parent about it. ",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               'vmnic'     => ['any:1'],
               'switch'    => ['vss:1'],     # This is TestSwitch 1 on SUT
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on SUT of type
                                             # "vmknic"
            },
            helper1           => {
               'switch'    => ['vss:1'],     # This is TestSwitch 1 on helper
               'vmnic'     => ['any:1'],
               'vmknic'    => ['switch1:1'], # TestAdapter 1 on helper1 of type
                                             # "vmknic"
               'host'      => 1,
            },
         },
         WORKLOADS => {
            Sequence          => [['TRAFFIC_2']],
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "SUT:vmknic:1",
               SupportAdapter => "helper1:vmknic:1",
               l4protocol     => "udp,tcp",
               PortNumber     => "8000",
               NoofInbound    => "1",
               NoofOutbound   => "1",
            },
         },
      },

      # Sample test demonstrate traffic workload between vnic and vmknic.
      'VnicVmkNictest'   => {
         Component         => "networking unknown",
         Category          => "Esx Server",
         TestName          => "VnicVmkNictest",
         Summary           => "Sample traffic test on vnic andvmknic",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               'vnic'      => ['vmxnet3:1'], # This is TestAdapter "1" of type
                                             # "vnic" on SUT
            },
            helper1       => {
               'switch'    => ['vss:1'],
               'vmknic'    => ['switch1:1'], # This is TestAdapter "1" of type
                                             # "vmknic" on helper1
            },
         },
         WORKLOADS => {
            Sequence          => [['TRAFFIC_2']],
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf,iperf",
               TestAdapter    => "SUT:vnic:1",       # vnic is the test adapter on SUT
               SupportAdapter => "helper1:vmknic:1", # vmknic is the support adapter on
                                            # helper1
               l4protocol     => "tcp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
            },
         },
      },
      'SnapShot' => {
         Component         => "VM operation",
         Category           => "Sample",
         TestName          => "SnapShot",
         Summary           => "Test connectivity after Create&Revert snapshot",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['NetAdapter_1'],['NetAdapter_2'],['CreateSnap'],['RevertSnap'],
                                  ['Iperf_1']],
            Duration          => "time in seconds",

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               ipv4           => "192.168.111.1",
               TestAdapter    => "1",
            },
            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "helper1",
               ipv4           => "192.168.111.2",
               TestAdapter    => "1",
            },
            "CreateSnap" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "CREATESNAP",
               Snapshotname   => "snapshot_sut",
            },
            "RevertSnap" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "REVERTSNAP",
               Snapshotname   => "snapshot_sut",
            },
            "Iperf_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               l4protocol     => "tcp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
            },
         },
      },
      'FirewallTest' => {
         Component         => "ESXi firewall",
         Category           => "Sample",
         TestName          => "SetFirewallStatus",
         Summary           => "set firewall status to given value(enabled or disabled)",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['SetEnabled'],['RuleList1'],['RuleList2'],
                                  ['EnabledService'],['DisabledService'],
                                  ['DisabledAllowedALL'],['AddAllowedIP'],
                                  ['RemoveAllowedIP'],['EnabledAllowedALL'],
                                  ['SetDisabled']],
            Duration          => "time in seconds",

            "SetEnabled" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setstatus",
               status         => "enabled",
            },
            "RuleList1" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "list",
            },
            "RuleList2" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "list",
               Servicename    => "sshClient",
            },
            "EnabledService" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setenabled",
               Servicename    => "sshClient",
               Flag           => "enabled"
            },
            "DisabledService" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setenabled",
               Servicename    => "sshClient",
               Flag           => "enabled"
            },
            "DisabledAllowedALL" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setallowedall",
               Servicename    => "sshClient",
               Flag           => "false"
            },
             "AddAllowedIP" => {
               Type            => "Host",
               Target          => "SUT",
               Firewall        => "IPSet",
               ServiceName     => "sshClient",
               flag            => "add",
               IP              => "192.168.20.2,192.168.10.1/24",
            },
             "RemoveAllowedIP" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "IPSet",
               ServiceName    => "sshClient",
               flag           => "remove",
               IP             => "192.168.20.2,192.168.10.1/24",
            },
            "EnabledAllowedALL" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setallowedall",
               Servicename    => "sshClient",
               Flag           => "true"
            },
            "SetDisabled" => {
               Type           => "Host",
               Target         => "SUT",
               Firewall       => "setstatus",
               status         => "disabled",
            },
         },
      },
      'CommandTest' => {
         Component         => "Command",
         Category           => "Sample",
         TestName          => "CommandTest",
         Summary           => "command test",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['connectionlistnegative'],['connectionlisttcp'],['connectionlistudp'],
                                  ['connectionlistip'],['connectionlist'],],
            Duration          => "time in seconds",

            "connectionlistnegative" => {
               Type           => "Command",
               Target         => "SUT",
               HostType         => "esx",
               Command        => "esxcli network ip connection list",
               Args           => "-t t",
               expectedString => "Invalid data constraint for parameter",
            },
            "connectionlisttcp" => {
               Type           => "Command",
               Target         => "SUT",
               HostType         => "esx",
               Command        => "esxcli network ip connection list",
               Args           => "-t tcp",
            },
            "connectionlistudp" => {
               Type           => "Command",
               Target         => "SUT",
               HostType         => "esx",
               Command        => "esxcli network ip connection list",
               Args           => "-t udp",
            },
            "connectionlistip" => {
               Type           => "Command",
               Target         => "SUT",
               HostType         => "esx",
               Command        => "esxcli network ip connection list",
               Args           => "-t ip",
            },
            "connectionlist" => {
               Type           => "Command",
               Target         => "SUT",
               HostType         => "esx",
               Command        => "esxcli network ip connection list",
            },
         },
      },

      'Multicast' => {
           Component        => "VMKTCPIP",
           Category         => "ESX Server",
           TestName         => "Multicast",
           Summary          => "Multicast between two esx hosts" ,
           ExpectedResult    => "PASS",
           Parameters   => {
               SUT      => {
                   'vmnic'  => ['any:1'],
                   'switch' => ['vss:1'],
                   'vmknic' => ['switch1:1'],
                   host   => 1,
                },
               helper1 => {
                   'vmnic'  => ['any:1'],
                   'switch' => ['vss:1'],
                   'vmknic' => ['switch1:1'],
                  host    => 1,
               },
            },
          WORKLOADS => {
            Iterations =>  "1",

            Sequence   => [['IperfTraffic']],

           "IperfTraffic" => {
               Type                => "Traffic",
               ToolName            => "Iperf",
               Routingscheme       => "multicast",
               Multicasttimetolive => "32",
               TestDuration        => "10",
               TestAdapter         => "SUT:vmknic:1",
               SupportAdapter      => "helper1:vmknic:1",
               Verification        => "PktCap",
              },
           },
         },

      'JumboFramegVLAN' => {
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Pots",
         TestName          => "JumboFramegVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests JumboFrame with gVLAN and also" .
                              "verify 'ExitSequence' operation",
         ExpectedResult    => "FAIL", # indicates a negative test
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['ConfigureSUTSwitch'],
                                  ['ConfigureHelperSwitch'],
                                  ['VnicConfig'],],
            #
            # The following sequence will start after workloads above are
            # executed.
            #
            ExitSequence      => [['VnicReset'],['ResetSUTSwitch'],
                                  ['ResetHelperSwitch']],

            "ConfigureSUTSwitch" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
               VLAN           => "4095",
            },

            "ConfigureHelperSwitch" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "8000",
               VLAN           => "4095",
            },

            "VnicConfig" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "2000,9500,9500",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "ResetHelperSwitch" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "ResetSUTSwitch" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "VnicReset" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

         },
      },
      "RSPAN" => {
         Component         => "vDS",
         Category          => "Sample",
         TestName          => "RSPAN",
         Summary           => "Configure RSPAN on switch",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               switch      => ['vss:1'],
               vmnic       => ['any:1'],
               pswitch     => "1",
            },
            helper1     => {
               host        => 1,
               switch => ['vss:1'],
               vmnic       => ['any:1'],
               pswitch     => "1",
            },
         },
         WORKLOADS => {
            Sequence          => [['RSPANSource'],['RSPANDestination'],],
            ExitSequence      => [['RemoveSource'],['RemoveDst'],],

            "RSPANSource" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               SwitchType => "pswitch",
               VmnicAdapter => "1",
               rspan => "source",
               rspanvlan => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
               rspansession => "3",
            },
            "RSPANDestination" => {
               Type => "Switch",
               Target => "helper1",
               TestSwitch => "1",
               SwitchType => "pswitch",
               VmnicAdapter => "1",
               rspan => "destination",
               rspanvlan => VDNetLib::Common::GlobalConfig::VDNET_RSPAN_VLAN_A,
               rspansession => "4",
            },
            "RemoveSource" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               SwitchType => "pswitch",
               rspan => "remove",
               rspansession => "3",
            },
            "RemoveDst" => {
               Type => "Switch",
               Target => "helper1",
               TestSwitch => "1",
               SwitchType => "pswitch",
               rspan => "remove",
               rspansession => "4",
            },
         },
      },
      PreCheckin => {
         Component         => "Infrastructure",
         Category          => "VDNet",
         TestName          => "PreCheckin",
         Summary           => "Pre-Checkin test for vdnet",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
               switch      => ['vds:1'],
               vmnic       => ['any:1'],
            },
            helper1        => {
               vnic        => ['e1000:1'],
               switch      => ['vds:1',],
               vmnic       => ['any:1'],
            },
            Rules          => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence          => [['Traffic']],
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf,iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
               TestDuration   => "10",
               Verification   => "pktcap",
            },
         },
      },
      'PCILimit'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "PCILimit",
         Version          => "2" ,
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies the maximum # of VFs ".
                             "that can be registered on a host",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                        speed  => "10G",
                        passthrough => {
                           type => "sriov",
                           maxvfs => "max",
                        },
                     },
                  },
               },
            },
            vm => {
               '[1]' =>   {
                  host  => "host.[1].x.x",
                  pci   => {
                     '[1]'   => {
                        passthrudevice => "host.[1].vmnic.[1]",
                        virtualfunction => "any",
                     },
                  },
               },
               '[2-6]' =>   {
                  host  => "host.[1].x.x",
                  pci   => {
                     '[1-6]'   => {
                        passthrudevice => "host.[1].vmnic.[1]",
                        virtualfunction => "any",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [
                        ['TCPTraffic'],
                        ],

            "TCPTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               MaxTimeout     => "5000",
               TestAdapter    => "vm.[1].pci.[1]",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               TestDuration   => "20",
            },
         },
      },
      'Unicast'   => {
         Component        => "network CHF/BFN/VDL2/VXLAN",
         Category         => "ESX Server",
         QCPath           => "",
         TestName         => "Unicast",
         Summary          => "Verify unicast connectivity/isolation of VMs " .
                             "which are deployed in VxLAN networks",
         ExpectedResult   => "PASS",
         Tags             => "sample",
         "PMT"            => "",
         Procedure       => "use this only for manual test",
         AutomationLevel  => "",
         FullyAutomatable => "",
         Duration         => "",
         Testbed          => "",
         Version          => "2" ,
         TestbedSpec      => {
            vc    => {
               "[1]"   => {
                  datacenter  => {
                     "[1]"   => {
                        name  => "auto",
                     },
                  },
                  vds   => {
                     "[1-2]"   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        mtu   => "1550",
                        vdl2  => "enable",
                     },
                  },
                  dvpg  => {
                     "[1-2]"   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                        vdl2id  => "100",
                        mcastIP => "239.0.0.8",
                     },
                     "[3-4]"   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                        vdl2id  => "1000",
                        mcastIP => "239.0.0.9",
                     },
                  },
               },
            },
            host  => {
               '[1-2]'   => {
                  datacenter  => "vc.[1].datacenter.[1]",
                  vdl2  => "install",
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        switch => "vc.[1].vds.[1]",
                        vlan   => "0",
                     },
                  },
               },
            },
            vm => {
               '[1]' =>   {
                  host  => "host.[1]",
                  vnic  => {
                     '[1]'   => {
                        driver    => "vmxnet3",
                        portgroup => "vc.[1].dvpg.[1]",
                        tsoipv4   => "Enable",
                        ipv4      => "AUTO",
                     },
                  },
               },
               '[2]' =>   {
                  host  => "host.[1]",
                  vnic  => {
                     '[1]'   => {
                        driver    => "vmxnet3",
                        portgroup => "vc.[1].dvpg.[3]",
                        tsoipv4   => "Enable",
                        ipv4      => "AUTO",
                     },
                  },
               },
               '[3]' =>   {
                  host  => "host.[2]",
                  vnic  => {
                     '[1]'   => {
                        driver    => "vmxnet3",
                        portgroup => "vc.[1].dvpg.[2]",
                        tsoipv4   => "Enable",
                        ipv4      => "AUTO",
                     },
                  },
               },
               '[4]' =>   {
                  host  => "host.[2]",
                  vnic  => {
                     '[1]'   => {
                        driver   => "vmxnet3",
                        portgroup => "vc.[1].dvpg.[4]",
                        tsoipv4   => "Enable",
                        ipv4      => "AUTO",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [
                        ['Ping1','Iperf_1'],
                        ['Ping2'],['Iperf_2'],
                        ['Ping3'],['Iperf_3'],
                        ],

             "Ping1" => {
               Type             => "Traffic",
               ToolName         => "ping",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[3].vnic.[1]",
               TestDuration     => "5",
            },
             "Iperf_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               NoofInbound    => "1",
               TestDuration   => "20",
            },
            "Ping2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[4].vnic.[1]",
               TestDuration   => "5",
            },
            "Iperf_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[4].vnic.[1]",
               l4protocol     => "tcp",
               NoofInbound    => "1",
               TestDuration   => "20",
            },
            "Ping3" => {
               Type           => "Traffic",
               ToolName       => "ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "5",
               expectedresult => "FAIL",
            },
            "Iperf_3" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               NoofInbound    => "1",
               TestDuration   => "20",
               expectedresult => "FAIL",
            },
         },
      },
      'DVFilterTest' => {
           Component        => "DVFilter/vmsafe-net",
           Category         => "ESX Server",
           TestName         => "DVFiltertest",
           Summary          => "Test Dvfilter set-up " .
                                 "is working",
           ExpectedResult    => "PASS",
           Parameters   => {
              vc  =>1,
            SUT            => {
               vm          => 1,
               switch      => ['vds:1'],
               host        => 1,
               vmnic       => ['any:1'],
               vnic        => ['e1000:1'],
            }, # End of SUT key.
           # slowpath vm
            helper1      => {
               vm          => 1,
               host        => 1,
               switch      => ['vds:1'],
               vmnic       => [{ driver => "any",
                                     count  => 1,},],
               vnic        => ['e1000:1','vmxnet3:1'],
              }, #  End of helper2 Key

         },

          WORKLOADS => {
            Iterations =>  "1",
            IgnoreFailure => "1",

           Sequence => [ #['DVFilterHostSetup'],
                         ['AddCustomAgent'],
                         #['StartSlowpath'],
                       ],
          "DVFilterHostSetup" => {
               Type           => "DVFilter",
               Target         => "SUT:host",
               HostSetup      => "dvfilter-generic-hp",
             },
          "AddCustomAgent"   => {
               Type                 => "Switch",
               Target               => "SUT",
               SwitchType           => "vdswitch",
               TestSwitch           => "1",
               ConfigureProtectedVM => "qw(SUT:vnic:1)",
               DVFilterOperation    => "qw(add)",
               Filters              => "qw(dvfilter-generic-hp)",
               SlotDetails          => "qw(0:1)",
               DVFilterParams       => "qw(10:foobar)",
               OnFailure            => "qw(failOpen)",
            },
           "StartSlowpath" => {
               Type           => "DVFilter",
               Target         => "helper1:slowpath",
               SlowpathType   => "classic",
               StartSlowpath  => "dvfilter-generic-hp",
             },
           },
         },

      'UpgraderBaseline' => {
         Component         => "VDnet",
         Category          => "Internal",
         TestName          => "UpgraderUnitTest",
         Summary           => "Unit Test for upgrader script",
         ExpectedResult    => "PASS",
         Parameters        => {
            vc => 1,
            SUT           => {
               host       => 1,
               switch     => ['vss:1'],
               vmknic     => ['switch1:2'],
               vmnic      => ['any:1'],
               vnic       => ['vmxnet3:1'],
            },
            helper1      => {
               vmknic     => ['switch1:2'],
               switch      => ['vss:1'],
               vmnic      => ['any:1'],
            },
            Rules => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence          => [['mtu'],['Ping'], ['VSS'],['DisableHwLRO'],
                                  ['DisconnectConnectvNic_B']],
            Duration          => "time in seconds",
            'mtu' => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntType        => "vmknic",
               TestAdapter    => "1,2",
               #MTU            => "1500,2000",
               ipv4           => "auto",
            },
            "Ping" => {
               Type           => "Traffic",
               ToolName       => "ping",
               TestAdapter    => "SUT:vmknic:1",
               SupportAdapter => "helper1:vmknic:2",
            },
            "VSS" => {
               Type          => "Switch",
               Target        => "SUT",
               TestAdapter    => "1-2",
               MTU           => "6997",
            },
            "DisableHwLRO"  => {
               Type           => "Host",
               TestAdapter    => "SUT:vnic:1",
               Lro            => "disable",
               LroType        => "Hw",
            },
            "DisconnectConnectvNic_B" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               Operation      => "DISCONNECTVNIC,CONNECTVNIC",
            },
            "CreateDC" => {
               Type             => "VC",
               OPT              => "adddc",
               DCName           => "/testDC",
               Hosts            => "SUT",
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

