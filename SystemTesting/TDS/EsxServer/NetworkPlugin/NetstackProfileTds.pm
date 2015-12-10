#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::NetstackProfileTds;

#
# This file contains the structured hash for category, Netstack  tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS

   %NetstackProfile = (

      'TcpipStackmaxConnection'   => {
         TestName         => 'TcpipStackmaxConnection',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the maxConnection in updated ' .
                             'in hostprofile ',
         Procedure        =>
           '1. For each of the netstackInstance '.
           '2. Add TcpipStack instance ' .
           '3. Extract Hostprofile '.
           '4. Edit maxConnection  ' .
           '5. Does Compliance Check- result should be Compliant' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["SetConnections"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ],
            ExitSequence   =>
                        [
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
            "SetConnections" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "2700",
            },
         },
      },
      'TcpipStackAlgorithm'   => {
         TestName         => 'TcpipStackAlgorithm',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the Algorithm updated ' .
                             'in hostprofile ',
         Procedure        =>
           '1. For each of the netstackInstance '.
           '2. Add TcpipStack instance ' .
           '3. Extract Hostprofile '.
           '4. Edit Congestion Algorithm (cubic/newreno)  ' .
           '5. Does Compliance Check- should be nonCompliant' .
           '6. Apply profile stateless/stateful' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },

            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["SetCCAlgorith_cubic"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ],
            ExitSequence   =>
                        [
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
            "SetCCAlgorith_cubic" => {
               Type           => "Netstack",
               TestNetstack   => "host.[1].netstack.[1]",
               setccalgorithm => "cubic",
            },
         },
      },
      'TcpipStackComplianceCheck'   => {
         TestName         => 'TcpipStackComplianceCheck',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the tcpipstack status' .
                             'in hostprofile ',
         Procedure        =>
           '1. For each of the netstackInstance '.
           '2. Add TcpipStack instance ' .
           '3. Extract Hostprofile '.
           '4. Add new netstack instance '.
           '5. Does Compliance Check- should be nonCompliant' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ['AddNetstack2'],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ],
            ExitSequence   =>
                        [
                        ["DestroyProfile"],
                        ['RemoveNetstack2'],
                        ["DisableMaintenanceMode"]
                        ],
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
            "AddNetstack2" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[2]" => {
                    netstackname => "ovs",
                  },
               },
            },
            "RemoveNetstack2" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[2]",
            },
         },
      },
      'TcpipStackIPv6Enabled'   => {
         TestName         => 'TcpipStackIPv6Enabled',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the IPv6Enabled status ' .
                             'in hostprofile ',
         Procedure        =>
           '1. For each of the netstackInstance '.
           '2. Add TcpipStack instance ' .
           '2.1 Add IPv6 IP address to vmknic ' .
           '3. Extract Hostprofile '.
           '4. Edit IPv6Enabled;false  ' .
           '5. Does Compliance Check- should be Compliant' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                  },
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddVMK1_IPv6"],
                        ["EnableMaintenanceMode"],
                        ["CreateProfile"],
                        ["AssociateProfile"],
                        ["SetNetStackIPv6_disable"],
                        ["ComplianceCheck"],
                        ],
            ExitSequence   =>
                        [
                        ["DestroyProfile"],
                        ['SetNetStackIPv6_enable'],
                        ['RemoveVmk1'],
                        ["DisableMaintenanceMode"]
                        ],
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
            "SetNetStackIPv6_enable" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackipv6 => "enable",
	    },
            "SetNetStackIPv6_disable"  => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackipv6 => "disable",
            },
            "AddVMK1_IPv6" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" =>{
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv6addr => VDNetLib::TestData::TestConstants::DEFAULT_TEST_IPV6,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIX_IPV6,
               },
             },
            },
            "RemoveVmk1" => {
               Type => "Host",
               TestHost => "host.[1]",
               deletevmknic => "host.[1].vmknic.[1]",
            },
         },
      },
      'TcpipStackIPRouteStateless'   => {
         TestName         => 'TcpipStackIPRouteStateless',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the IProute status ' .
                             'in hostprofile ',
         Procedure        =>
           '1. Add an ESXi to VC ' .
           ' For netstackInstance '.
           '   defaultTcpipStack ' .
           '2. Create vSwitch, portgroup, add interface ' .
	   '3. Add static vmknic  (address and gateway) ' .
           '4. Extract Hostprofile '.
           '5. Does Compliance Check: result nonCompliant ' .
	   '5.1 Associate Profile '.
	   '6. Stateless reboot ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
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
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                     '[2]' => {
                       netstackname => "ovs",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
              },
              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
        },
        WORKLOADS => {
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["SetNetStackGateway"],
                        ["CreateProfile"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveNetStackGateway"],
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
           "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
           'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
           },
           'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
           },
            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[1]" =>{
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[1]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
           },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              =>  VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         =>  VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
           "RemoveNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "remove",
              route              =>  VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         =>  VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
      'TcpipStackCheckDnsConfig'   => {
         TestName         => 'TcpipStackCheckDnsConfig',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the DnsConfig status ' .
                             'in hostprofile ' ,
         Procedure        =>
           '1. The netstackInstance  defaultTcpipStack ' .
           '2. Create VSS vmknic vmknic on TcpipStack instance ' .
           '3. Extract Hostprofile ' .
           '4. Edit ' .
           '5. Does Compliance Check- result nonCompliant' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },

            host  => {
               '[1]'   => {
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                  },
               },
            },
         },

        WORKLOADS => {
           Sequence => [
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["SetNetStackDNS"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveNetStackDNS"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"] ],

            "SetNetStackDNS" => {
                Type => "Netstack",
                TestNetstack => "host.[1].netstack.[1]",
                setnetstackdns => "add",
                dns => "192.168.0.1",
            },

            "RemoveNetStackDNS" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackdns => "remove",
               dns => "192.168.0.1",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
         },
      },
      'TcpipStackIPv4RouteStateful'   => {
         TestName         => 'TcpipStackIPv4RouteStatful',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the IPv4Route status ' .
                             'in hostprofile ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2. Extract Hostprofile ' .
           '3. Add Ipv4 interface ' .
           '4. Add static route in ESXi host  ' .
           '5. Does Compliance Check - nonCompliant'.
           '6. Apply profile stateful' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
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
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                     '[2]' => {
                       netstackname => "ovs",
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
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["CreateProfile"],
                        ["SetNetStackGateway"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                       ],
            ExitSequence   =>
                       [
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                       ],
            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[1]" =>{
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[1]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },

            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
           },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
               netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
           "RemoveNetStackGateway"  => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "remove",
               route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
               netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
        },
      },
      'IPRouteComplianceCheck'   => {
         TestName         => 'IPRouteComplianceCheck',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the IPv6Enabled status ' .
                             'in hostprofile ',
         Procedure        =>
           '1. Add vmknic vmkx on TcpipStack instance ' .
           '2. Add static gateway '.
           '3. Extract Hostprofile '.
           '4. Add static gateway '.
           '7. Do Compliance Check -nonCompliant'.
           '8. Do clean up ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
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
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                     '[2]' => {
                       netstackname => "ovs",
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
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["AddVmknicInterface"],
                        ["SetNetStackGateway"],
                        ["AddVmknicInterface_1"],
                        ["CreateProfile"],
                        ["SetNetStackGateway_1"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                       ],
            ExitSequence   =>
                        [
                        ["DeleteVmknicInterface_1"],
                        ["RemoveNetStackGateway"],
                        ["DeleteVmknicInterface"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"] ],
            "AddVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[1]" =>{
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknicInterface" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[1]",
            },
           "AddVmknicInterface_1" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[2]" =>{
                  portgroup => "host.[1].portgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_2,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknicInterface_1" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1]",
              maintenancemode => "false",
           },
           "SetNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
          "SetNetStackGateway_1"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[2]",
              setnetstackgateway => "add",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_2,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_2,
           },
           "RemoveNetStackGateway"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "remove",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_1,
           },
           "RemoveNetStackGateway_1"  => {
              Type => "Netstack",
              TestNetstack => "host.[1].netstack.[1]",
              setnetstackgateway => "remove",
              route              => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_2,
              netaddress         => VDNetLib::TestData::TestConstants::DEFAULT_NETWORK_2,
           },
        },
      },
      'VSSVmknicTag'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding VSS Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VSS 1, VSPG 1' .
           '2.3 vmk2 -> vmotion -> VSS 2, VSPG 2' .
           '3. Extract Hostprofile ' .
           '4. Modify tags on vmk1 and vmk2 ' .
           '5. Apply Hostprofile ' .
           '6. Verify that tag assigment is done correctly post-apply, Compliance check should also succeed',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
          vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1-2]'   => {
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1-4]'   => {
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
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
              },
              '[2]' => {
              },
           },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["RemoveTag"],
                        ["RemoveTag_1"],
                        ["AddTag_2"],
                        ["AddTag_3"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],

            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "Management",
            },
            "AddTag_3" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "Management",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
         },
      },
      'VSSVmknicTag01Stateless'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding VSS Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VSS 1, VSPG 1' .
           '2.3 vmk2 ->  ft tag -> VSS 2, VSPG 1' .
           '3. Extract Hostprofile ' .
           '4. Associate profile to host ' .
           '5. Apply Hostprofile and stateless reboot ' .
           '6. Verify that tag assigment is done correctly post-apply, Compliance check should also succeed',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
          vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1-2]'   => {
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1-4]'   => {
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
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
              },
              '[2]' => {
              },
           },
          powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_1"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",

            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'VSSVmknicTagStateless'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding VSS Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VSS 1, VSPG 1' .
           '2.3 vmk2 -> vmotion -> VSS 2, VSPG 1' .
           '3. Extract Hostprofile ' .
           '4. Modify tags on vmk1 and vmk2 ' .
           '5. Associate Hostprofile ' .
           '6. Stateless reboot ' .
           '7. Verify that tag assigment is done correctly post-apply, Compliance check should also succeed',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
          vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1-2]'   => {
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
                     },
                  },
                  portgroup   => {
                     '[1-4]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
              },
              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddVmknic"],
                        ["AddVmknic_1"],
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["RemoveTag"],
                        ["RemoveTag_1"],
                        ["AddTag_2"],
                        ["AddTag_3"],
                        ["ComplianceCheck"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["GetAnswerFile"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["DeleteVmknic_1"],
                        ["DeleteVmknic"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
            },
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
           "AddVmknic" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[1]" =>{
                  portgroup => "host.[1].portgroup.[1]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_1,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknic" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[1]",
            },
           "AddVmknic_1" => {
                Type => "Host",
                TestHost => "host.[1]",
                vmknic => {
                "[2]" =>{
                  portgroup => "host.[1].portgroup.[2]",
                  ipv4address => VDNetLib::TestData::TestConstants::DEFAULT_VMK_IP_2,
                  netmask => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                  prefixlen => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                },
              },
            },
            "DeleteVmknic_1" => {
                Type => "Host",
                TestHost => "host.[1]",
                deletevmknic => "host.[1].vmknic.[2]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "Management",
            },
            "AddTag_3" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "Management",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               getanswerfile  => "screen",
            },
            "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
            },
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
         },
      },
      'VDSManagementVSSVMotionTag'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VDS ' .
           '2.2 vmk1 -> vmotion -> VSS ' .
           '3. Extract Hostprofile ' .
           '5. Associate Hostprofile ' .
           '5.1 Stateless reboot' .
           '6. Verify that tag assigment is done correctly after stateless reboot',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'DVSDVPGVmknicTagCheck'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2. Extract Hostprofile ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VDS 6 0, DVPG 6 0' .
           '2.3 vmk2 -> ft      -> VDS 6 0, DVPG 6 0' .
           '5. Associate Hostprofile ' .
           '6. Apply profile to host '.
           '7. Verify that tag assigment is done correctly after apply profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
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
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["AddTag"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag_1"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheckStateless'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2. Extract Hostprofile ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VDS 1, DVPG 1' .
           '2.3 vmk2 -> ft      -> VDS 1, DVPG 1' .
           '5. Associate Hostprofile ' .
           '6. Stateless reboot the host '.
           '7. Verify that tag assigment is done correctly after apply profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
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
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[2]'   => {
               },
            },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["AddTag"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ["RebootHost"],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag_1"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheck01'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VDS 1, DVPG 1' .
           '2.3 vmk2 -> ft      -> VDS 2, DVPG 2' .
           '3. Extract Hostprofile ' .
           '5. Associate  Hostprofile ' .
           '6. Apply Profile '.
           '7. Verify that tag assigments are correct after apply profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_1"],
			["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],

            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'DVSDVPGVmknicTagCompliant'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VDS 1, DVPG 1' .
           '3. Extract Hostprofile ' .
           '3.1 vmk2 -> ft      -> VDS 2, DVPG 2' .
           '5. Associate  Hostprofile ' .
           '6. Apply Profile '.
           '7. Verify that tag assigments are correct after apply profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["CreateProfile"],
                        ["AddTag_1"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
			["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "nonCompliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheck00Stateless'   => {
         TestName         => 'DVSDVPGVmknicTagCheck00Stateless',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> ft -> VDS 1, DVPG 1' .
           '2.3 vmk2 -> VMotion -> VDS 2, DVPG 2' .
           '3. Extract Hostprofile ' .
           '5. Associate  Hostprofile ' .
           '6. Stateless reboot '.
           '7. Verify that tag assigments are correct after reboot ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
              '[2]'   => {
              },
            },
            powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_1"],
			["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 160",
               testhost => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheck01Stateless'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> management -> VSS ' .
           '2.2 vmk1 -> vmotion -> VDS 6 0, DVPG 6 0' .
           '2.3 vmk2 -> ft      -> VDS 6 1, DVPG 6 1' .
           '3. Extract Hostprofile ' .
           '5. Associate  Hostprofile ' .
           '6. Stateless reboot '.
           '7. Verify that tag assigments are correct after reboot ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
              '[2]'   => {
              },
            },
            powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["AddTag"],
                        ["AddTag_1"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_1"],
			["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheck02'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> Management -> VSS ' .
           '2.2 vmk1 -> Management, vmotion  -> VDS 6 0, DVPG 6 0' .
           '2.3 vmk2 -> faultToleranceLogging, vmotion  -> VDS 6 0, DVPG 6 0' .
           '2.4 vmk3 -> Management, VMotion  -> VDS 6 1, DVPG 6 1' .
           '3. Extract Hostprofile ' .
           '3.1 Associate Profile ' .
           '5.0 Apply profile '.
           '6. Verify that tag assigment is done correctly after apply profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => 'sanity',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[3]",
                     },
                     '[4]' => {
                        portgroup => "vc.[1].dvportgroup.[4]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
			["AddTag"],
                        ["AddTag_00"],
                        ["AddTag_1"],
                        ["AddTag_01"],
                        ["AddTag_2"],
                        ["AddTag_02"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_00"],
                        ["RemoveTag_1"],
                        ["RemoveTag_01"],
                        ["RemoveTag_2"],
                        ["RemoveTag_02"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
           "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
           },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "Management",
            },
            "AddTag_00" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "AddTag_01" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "add",
               tagname => "Management",
            },
            "AddTag_02" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "Management",
            },
            "RemoveTag_00" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag_01" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "remove",
               tagname => "Management",
            },
            "RemoveTag_02" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'DVSDVPGVmknicTagCheck02Stateless'   => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         Procedure        =>
           '1. For netstackInstance '.
           '   defaultTcpipStack ' .
           '2.1 vmk0 -> Management -> VSS ' .
           '2.2 vmk1 -> Management, VMotion  -> VDS 6 0, DVPG 6 0' .
           '2.3 vmk2 -> faultToleranceLogging, VMotion  -> VDS 6 0, DVPG 6 0' .
           '2.4 vmk3 -> Management, VMotion -> VDS 6 1, DVPG 6 1' .
           '3. Extract Hostprofile ' .
           '3.1 Associate Profile ' .
           '5. Stateless reboot '.
           '6. Verify that tag assigment is done correctly after reboot ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'stateless',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                     '[2]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[2]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                     '[3]' => {
                        portgroup => "vc.[1].dvportgroup.[3]",
                     },
                     '[4]' => {
                        portgroup => "vc.[1].dvportgroup.[4]",
                     },
                  },
               },
              '[2]'   => {
              },
            },
            powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
            },
         },
         WORKLOADS => {
            Sequence => [
			["AddTag"],
                        ["AddTag_00"],
                        ["AddTag_1"],
                        ["AddTag_01"],
                        ["AddTag_2"],
                        ["AddTag_02"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ComplianceCheck"],
                        ["GetAnswerFile"],
                        ["ExportAnswerFile"],
                        ["ImportAnswer"],
                        ["ApplyImage"],
                        ['RebootHost'],
                        ['SleepToWaitProfile'],
                        ],
            ExitSequence   =>
                        [
                        ["RemoveTag"],
                        ["RemoveTag_00"],
                        ["RemoveTag_1"],
                        ["RemoveTag_01"],
                        ["RemoveTag_2"],
                        ["RemoveTag_02"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ],
            "ImportAnswer" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               importanswer   => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
               SrcHost       => "host.[1]",
            },
            "ExportAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               SrcHost        => "host.[1]",
               exportanswerfile => VDNetLib::TestData::TestConstants::DEFAULT_ANSWERFILE,
            },
            "GetAnswerFile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               getanswerfile => "screen",
               SrcHost       => "host.[1]",
            },
            "ApplyImage" => {
               Type        => "VM",
               TestVM      => "powerclivm.[1]",
               applyimage  => "esx",
               vc          => "vc.[1]",
               host        => "host.[1]",
            },
            'RebootHost' => {
               Type     => "Host",
               TestHost => "host.[1]",
               reboot   => "yes",
            },
            'SleepToWaitProfile' => {
               Type     => "Command",
               command  => "sleep 140",
               testhost => "host.[1]",
            },
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "Management",
            },
            "AddTag_00" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
            "AddTag_01" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "AddTag_02" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "add",
               tagname => "Management",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_00" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "Management",
            },
            "RemoveTag_1" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "RemoveTag_01" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[2]",
               Tagging => "remove",
               tagname => "faultToleranceLogging",
            },
            "RemoveTag_2" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "remove",
               tagname => "Management",
            },
            "RemoveTag_02" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[3]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
            },
            "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
            },
            "ComplianceCheck" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               CheckCompliance => "testprofile",
               SrcHost        => "host.[1]",
               compliancestatus => "Compliant",
            },
         },
      },
      'CreateVSSs'   => {
         TestName         => 'CreateVSSs',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'create vss, create profile ' .
                             'apply profilei without error ',
         Procedure        =>
           '1. setup testbed to create 50 vSS  '.
           '1.1 Extract Hostprofile ' .
           '2. associate profile'.
           '3. Apply profile stateless/stateful' .
           '4. destroy profile',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
        },
        WORKLOADS => {
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["CreateVSS"],
                        ["SleepToWaitVSS"],
                        ["CreateProfile"],
                        ["AssociateProfile"],
                        ["ApplyProfile"],
                       ],
            ExitSequence   =>
                       [
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                       ],
            "SleepToWaitVSS" => {
              Type         => "Command",
              command      => "sleep 60",
              testhost      => "host.[1]",
            },
            "CreateVSS"     => {
              Type          => "Host",
              TestHost      => "host.[1]",
              vss           => {
                '[1-50]'     => {
                        timeout => "360",
                     },
                 },
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
           },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
        },
      },
      'CreateVSSPortgroups'   => {
         TestName         => 'CreateVSSPortgroups',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'create VSS portgroup ' .
                             'extract hostprofile, apply profile without error ',
         Procedure        =>
           '1. setup testbed to create 250 vss portgroup '.
           '1.1 Extract Hostprofile ' .
           '2. associate profile'.
           '3. Apply profile stateless/stateful' .
           '4. destroy profile',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
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
           Sequence => [
                        ["EnableMaintenanceMode"],
                        ["CreatePortgroup"],
                        ["SleepToWaitPortgroup"],
                        ["CreateProfile"],
                        ["AssociateProfile"],
                        ["ApplyProfile"],
                       ],
            ExitSequence   =>
                       [
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                       ],
            "SleepToWaitPortgroup" => {
              Type         => "Command",
              command      => "sleep 60",
              testhost      => "host.[1]",
            },
            "CreatePortgroup" => {
              Type          => "Host",
              TestHost      => "host.[1]",
              portgroup => {
                     '[1-100]' => {
                        vss => "host.[1].vss.[1]",
                        timeout => "600",
                     },
              },
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
           },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
        },
      },
      'CreateVDSPortgroups'   => {
         TestName         => 'CreateVDSPortgroups',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'create dvs portgroup   ' .
                             'extract proifle, apply profile without error ',
         Procedure        =>
           '1. setup testbed to create 250 dvportgroup '.
           '2. Extract Hostprofile ' .
           '5. Associate Hostprofile ' .
           '6. Apply profile to host '.
           '7. destroy profile ',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                 },
                 dvportgroup  => {
                     '[1-100]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
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
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ["EnableMaintenanceMode"],
                        ["SleepToWaitDvportgroup"],
                        ["CreateProfile"],
                        ["AssociateProfile"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],
            "SleepToWaitDvportgroup" => {
              Type         => "Command",
              command      => "sleep 60",
              testhost      => "host.[1]",
            },
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
         },
      },
      'CreateLACP' => {
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Adding DVS, DVPG and Tags configured on the vmknic can be  ' .
                             'uniquely identify a vmknic ',
         TestName          => "CreateLACP",
         Version           => "2",
         Tags              => "lacp",
         Summary           => "create LACP ".
                              "extract profile with lacp and no error occures",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        'lag' => {
                           '[1-3]' => {
                              lagtimeout => "short",
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
           Sequence => [
                        ["AddMoreLAG"],
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateProfile"],
                        ["ApplyProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["DeleteAllLAG"],
                        ["DisAssociateProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],

            Duration     => "time in seconds",
            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               createprofile  => "profile",
               SrcHost        => "host.[1]",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               associateprofile  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               disassociateprofiles  => "testprofile",
               SrcHost        => "host.[1]",
            },
            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[1]",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               destroyprofile => "testprofile",
            },
           "EnableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               maintenancemode => "false",
           },
            "AddMoreLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               'lag' => {
                  '[4-5]' => {
                     lagtimeout => "short",
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
   );
}


########################################################################
#
# new --
#       This is the constructor for NetstackProfileTds
#
# Input:
#       none
#
# Results:
#       An instance/object of NetstackProfileTds class
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
   my $self = $class->SUPER::new(\%NetstackProfile);
   return (bless($self, $class));
}

1;
