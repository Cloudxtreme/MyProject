#!/usr/bin/perl
#########################################################################
#Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VMKTCPIP::TCPIP4RSSTds;

#
# This file contains the structured hash for TCPIP4 RSS TDS.
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of test cases
   @TESTS = ("NICTeamIndividualQueueMixRSS",
             "VerifyAddRemoveTableSupport",
             "MACChangeVmknic",
             "UDPVmknicStress",
             "SCCAlgorithm",
             "ARPTable",
             "VerifyMigrateMTUSupport");

   %TCPIP4RSS = (
      'NICTeamIndividualQueueMixRSS'   => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'NICTeamIndividualQueueMixRSS',
         Summary          => 'NIC Teaming: To verify whether the RSS supported queues take the'.
                             ' individually supported RSS queues in each of the pNICs.'.
                             'Also, for NIC Teaming: To verify whether RSS works with '.
                             'the default NIC teaming policy.'.
                             'Also, to verify whether RSS works in a team where one NIC '.
                             'supports RSS and the other one does not'.
                             'Also, to verify whether the RSS supported pNICs are ' .
                             'showing the required number of queues reserved '.
                             'for RSS',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Functional.NICTeam.IndividualQueue:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches.'.
                             '2. On each vSwitch, add RSS supported uplinks to it but each '.
                             '   uplink should have different number of suported queues.'.
                             '3. Create 2 vmknics connected to each of the vSwitches.'.
                             '4. Pass traffic between both the vmknics'.
                             'Verification: Ensure that the number of RSS supported queues per '.
                             'NIC team is equal to the individually supported queues per pNIC. '.
                             'Also, ensure that traffic is running fine.'.
                             'For TC ESX.Network.TCPIP4.RSS.Functional.NICTeam:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches and '.
                             'add 2 or more RSS supported uplinks to each of them.'.
                             '2. Create 2 vmknics connected to each of the vSwitches.'.
                             '3. Enable the default NIC teaming policy.'.
                             '4. Pass traffic between both the vmknics.'.
                             'Verification: RSS should be indexing the flows correctly in the '.
                             'indirection table, through the default NIC teaming policy.'.
                             'For TC ESX.Network.TCPIP4.RSS.Load.NICTeam.MixRSS:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches.'.
                             '2. On each vSwitch, add one RSS supported uplink and another than '.
                             '   does not support RSS.'.
                             '3. Create 2 vmknics connected to each of the vSwitches.'.
                             '4. Pass traffic between both the vmknics'.
                             'Verification: Ensure that the RSS supported NIC allocates indexes '.
                             'the flows correctly in the indirection table, and the RSS '.
                             'unsupported NIC passes traffic correctly.'.
                             'For TC ESX.Network.TCPIP4.RSS.Functional.VerifyQueues.pNIC:'.
                             '1. On a freshly installed ESX build, check the '.
                             'following VSI node to check whether RSS is activated:'.
                             '/> get /net/pNics/vmnic#/rxqueues/pools/3/info'.
                             'rx netq pools {'.
                             '   attr:rx netq pool attributes: 0 -> No matching defined enum value found.'.
                             '   features:features: 0x20 -> RSS'.
                             '   # queues reserved:1'.
                             '   # queues max:2'.
                             '   distrib ratio:1'.
                             '   active:1'.
                             '}'.
                             'Check whether the value active is set to 1, and the queues '.
                             'reserved is set to 1'.
                             'For TC ESX.Network.TCPIP4.RSS.Load.VmknicNetQueue:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches and '.
                             '   add an RSS supported uplink to each of them.'.
                             '2. Create 2 vmknics connected to each of the vSwitches.'.
                             '3. Pass traffic between the vmknics.'.
                             'Verification: NetQueue should allocate queues for vmknic traffic '.
                             '-assuming it is above 10 MBps- even though RSS is not supported on '.
                             'this NIC',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                        configureuplinks => "add",
                        vmnicadapter   => "host.[1].vmnic.[1-2]",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "ixgbe",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[1].portgroup.[1]",
                        ipv4address => "192.111.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[1].portgroup.[2]",
                        ipv4address => "192.112.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[1].portgroup.[3]",
                        ipv4address => "192.113.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[1].portgroup.[4]",
                        ipv4address => "192.114.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[1].portgroup.[5]",
                        ipv4address => "192.115.1.1",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                        configureuplinks => "add",
                        vmnicadapter   => "host.[1].vmnic.[1-2]",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "ixgbe",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[2].portgroup.[1]",
                        ipv4address => "192.111.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[2].portgroup.[2]",
                        ipv4address => "192.112.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[2].portgroup.[3]",
                        ipv4address => "192.113.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[2].portgroup.[4]",
                        ipv4address => "192.114.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[2].portgroup.[5]",
                        ipv4address => "192.115.2.2",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['UnloadDriverA'],['LoadDriverA'],
                         ['UnloadDriverB'],['LoadDriverB'],
                         ['UnloadDriverA'],['LoadDriver1'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality',],
                         ['UnloadDriverA'],['LoadDriver2'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality',],
                         ['UnloadDriverA'],['LoadDriverNonRSS'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',],
                         ['UnloadDriverA'],['LoadDriver3'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality',]],
            Duration => "9000",

            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "LoadDriver1" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::2",
            },
            "LoadDriver2" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=0::4",
            },
            "LoadDriver3" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=100::500",
            },
            "LoadDriverNonRSS" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=0::0",
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1];;host.[2].vmnic.[2]",
               VmkInfo        => "host.[2].vmknic.[1-5]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "600",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "1015"
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "1000"
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "985"
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "970"
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "955"
            },
         },
      },

      'VerifyAddRemoveTableSupport'   => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'VerifyAddRemoveTableSupport',
         Summary          => 'To verify whether the management vmknic is already added to the '.
                             'RSS queues'.
                             'Also, to verify whether newly created vmknics are automatically '.
                             'added as part of the RSS pool, and deleted vmknics MACs are '.
                             'removed from the RSS pool'.
                             'Also, to verify whether the RSS Indrection table is functioning as per '.
                             'the Toeplitz hash function',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Functional.VerifyMgmtVmknicSupport:'.
                             '1. Check the appropriate VSI nodes of the RSS supported pNICs to '.
                             '   see whether the exsting default vmknics are already part of '.
                             '   the RSS queues.'.
                             'Verification: The Management vmknic should already be part of the '.
                             'RSS pool'.
                             'For TC ESX.Network.TCPIP4.RSS.Functional.VerifyAddRemoveVmknicSupport:'.
                             '1. Check the appropriate VSI nodes of the RSS supported pNICs to see '.
                             '   whether the newly added vmknics are automatically part of the RSS '.
                             '   queues.'.
                             '2. Afterwards, check the appropriate VSI nodes of the RSS supported '.
                             '   pNICs to see whether deleted vmknics MACs are removed from the '.
                             '   RSS pools.'.
                             'Verification: All newly created vmknics should be automatically part '.
                             'of the RSS pool. And all deleted vmknics MACs should be removed from '.
                             'the RSS pools.'.
                             'For TC ESX.Network.TCPIP4.RSS.Functional.IndirectionTable:'.
                             '1. On a freshly installed ESX build, create a vSwitch and add an '.
                             '   RSS supported uplink to it.'.
                             '2. Add 4 vmknics to the vSwitch and check whether the RSS pool '.
                             '   reflects the correct information per vmknic'.
                             '3. Send multiple threads of traffic to all 4 vmknics and verify that '.
                             '   the RSS queues being assigned to these threads follow the Toeplitz '.
                             '   hash function'.
                             '4. Verify this using VSI nodes and ethtool for mapping which queue is '.
                             '   being used'.
                             '5. Repeat the same for vDS.'.
                             '4. Once the max number of vmknics are reached, create more to check '.
                             '   behavior of the RSS pool',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[1].portgroup.[1]",
                        ipv4address => "192.111.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[1].portgroup.[2]",
                        ipv4address => "192.112.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[1].portgroup.[3]",
                        ipv4address => "192.113.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[1].portgroup.[4]",
                        ipv4address => "192.114.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[1].portgroup.[5]",
                        ipv4address => "192.115.1.1",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[2].portgroup.[1]",
                        ipv4address => "192.111.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[2].portgroup.[2]",
                        ipv4address => "192.112.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[2].portgroup.[3]",
                        ipv4address => "192.113.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[2].portgroup.[4]",
                        ipv4address => "192.114.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[2].portgroup.[5]",
                        ipv4address => "192.115.2.2",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['UnloadDriverA'],['LoadDriverA'],
                         ['UnloadDriverB'],['LoadDriverB'],
                         ['AddUplink1'],['AddUplink2'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality'],
                         ['RemoveUplink1'],['RemoveUplink2'],
                         ['AddUplink1'],['AddUplink2'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality']],
            Duration => "9000",

            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "AddUplink1" => {
               Type           => "Switch",
               TestSwitch     => "host.[1].vss.[1]",
               ConfigureUplinks => "add",
               VMNicAdapter   => "host.[1].vmnic.[1]",
            },
            "AddUplink2" => {
               Type           => "Switch",
               TestSwitch     => "host.[2].vss.[1]",
               ConfigureUplinks => "add",
               VMNicAdapter   => "host.[2].vmnic.[1]",
            },
            "RemoveUplink1" => {
               Type           => "Switch",
               TestSwitch     => "host.[1].vss.[1]",
               ConfigureUplinks => "remove",
               VMNicAdapter   => "host.[1].vmnic.[1]",
            },
            "RemoveUplink2" => {
               Type           => "Switch",
               TestSwitch     => "host.[2].vss.[1]",
               ConfigureUplinks => "remove",
               VMNicAdapter   => "host.[2].vmnic.[1]",
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1]",
               VmkInfo        => "host.[2].vmknic.[1-5]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "600",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "1015"
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "1000"
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "985"
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "970"
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "955"
            },
         },
      },

      'VerifyMigrateMTUSupport'   => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'VerifyMigrateMTUSupport',
         Summary          => 'To verify whether a vmknic thats been migrated from one vSwitch / '.
                             'vDS to another vDS / vSwitch is automatically added to the RSS pool '.
                             'on those uplinks'.
                             'Also, to verify whether RSS works with different MTU sizes on the pNICs',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Functional.VerifyMigratedVmknicSupport:'.
                             '1. Create a vDS and a vSwitch on the same host'.
                             '2. Add a new vmknic to the vDS with uplinks that may or may not '.
                             '   support RSS.'.
                             '3. Migrate the vmknic from the vDS to the vSwitch that has uplinks '.
                             '   that support RSS.'.
                             '4. Ensure that the migrated vmknic is automatically added to the RSS '.
                             '   pool of the vSwitchs uplinks'.
                             '5. Repeat the same test the other way round - migrate the vmknic from '.
                             '   the vSwitch to the vDS and then check expected results'.
                             'Verification: All migrated vmknics must be automatically added to the '.
                             'RSS pool of vSwitch / vDS that it is being migrated to'.
                             'For TC ESX.Network.TCPIP4.RSS.Functional.TrafficMTU:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches and add an '.
                             '   RSS supported uplink to each of them.'.
                             '2. Create 2 vmknics connected to each of the vSwitches.'.
                             '3. Pass traffic from one vmknic to the other.'.
                             '4. Change the MTU size of the connected uplinks from 1500 to 9000 '.
                             '   and back'.
                             'Verification: RSS should be indexing the flows correctly in the '.
                             'indirection table, with different MTU sized uplinks',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc => {
               '[1]' => {
                  datacenter => {
                     '[1]' => {
                        host => "host.[1-2]",
                     },
                  },
                  vds => {
                     '[1]' => {
                        datacenter => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds      => "vc.[1].vds.[1]",
                        ports    => "8",
                     },
                     '[2]'   => {
                        vds      => "vc.[1].vds.[1]",
                        ports    => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4address => "192.111.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4address => "192.112.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4address => "192.113.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4address => "192.114.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        ipv4address => "192.115.1.1",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => { # create VSS
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4address => "192.111.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4address => "192.112.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4address => "192.113.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4address => "192.114.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "vc.[1].dvportgroup.[2]",
                        ipv4address => "192.115.2.2",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['UnloadDriverA'],['LoadDriverA'],
                         ['UnloadDriverB'],['LoadDriverB'],
                         ['Traffic6','Traffic7','Traffic8','Traffic9','Traffic10',
                          'ChangeMTU9000','ChangeMTU1500'],
                         ['VerifyUplinkStatus'],
                         ['MigrateVdsVss11'],['MigrateVdsVss12'],
                         ['MigrateVdsVss13'],['MigrateVdsVss14'],
                         ['MigrateVdsVss15'],['MigrateVdsVss21'],
                         ['MigrateVdsVss22'],['MigrateVdsVss23'],
                         ['MigrateVdsVss24'],['MigrateVdsVss25'],
                         ['RemoveUplink1'],['AddUplink1'],
                         ['RemoveUplink2'],['AddUplink2'],
                         ['Traffic6','Traffic7','Traffic8','Traffic9','Traffic10',
                          'ChangeMTU9000','ChangeMTU1500'],
                         ['VerifyUplinkStatus'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality']],
            Duration => "150000",

            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "AddUplink1" => {
               Type           => "Switch",
               TestSwitch     => "host.[1].vss.[1]",
               ConfigureUplinks => "add",
               VMNicAdapter   => "host.[1].vmnic.[1]",
            },
            "RemoveUplink1" => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
               ConfigureUplinks => "remove",
               VMNicAdapter   => "host.[1].vmnic.[1]",
            },
            "AddUplink2" => {
               Type           => "Switch",
               TestSwitch     => "host.[2].vss.[1]",
               ConfigureUplinks => "add",
               VMNicAdapter   => "host.[2].vmnic.[1]",
            },
            "RemoveUplink2" => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
               ConfigureUplinks => "remove",
               VMNicAdapter   => "host.[2].vmnic.[1]",
            },
            "VerifyUplinkStatus" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmnic.[1]",
               check_featuressettings => {
                 feature_type  => "NICStatus",
                 value    => "Enable",
               }
            },
            "MigrateVdsVss11" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmknic.[1]",
               reconfigure    => "true",
               portgroup      => "host.[1].portgroup.[1]",
            },
            "MigrateVdsVss12" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmknic.[2]",
               reconfigure    => "true",
               portgroup      => "host.[1].portgroup.[2]",
            },
            "MigrateVdsVss13" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmknic.[3]",
               reconfigure    => "true",
               portgroup      => "host.[1].portgroup.[3]",
            },
            "MigrateVdsVss14" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmknic.[4]",
               reconfigure    => "true",
               portgroup      => "host.[1].portgroup.[4]",
            },
            "MigrateVdsVss15" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmknic.[5]",
               reconfigure    => "true",
               portgroup      => "host.[1].portgroup.[5]",
            },
            "MigrateVdsVss21" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[2].vmknic.[1]",
               reconfigure    => "true",
               portgroup      => "host.[2].portgroup.[1]",
            },
            "MigrateVdsVss22" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[2].vmknic.[2]",
               reconfigure    => "true",
               portgroup      => "host.[2].portgroup.[2]",
            },
            "MigrateVdsVss23" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[2].vmknic.[3]",
               reconfigure    => "true",
               portgroup      => "host.[2].portgroup.[3]",
            },
            "MigrateVdsVss24" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[2].vmknic.[4]",
               reconfigure    => "true",
               portgroup      => "host.[2].portgroup.[4]",
            },
            "MigrateVdsVss25" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[2].vmknic.[5]",
               reconfigure    => "true",
               portgroup      => "host.[2].portgroup.[5]",
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1]",
               VmkInfo        => "host.[2].vmknic.[1-5]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "200",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "515",
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "500",
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "485",
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "470",
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "455",
            },
            "Traffic6" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "515",
               ExpectedResult => "IGNORE",
            },
            "Traffic7" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "500",
               ExpectedResult => "IGNORE",
            },
            "Traffic8" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "485",
               ExpectedResult => "IGNORE",
            },
            "Traffic9" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "470",
               ExpectedResult => "IGNORE",
            },
            "Traffic10" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "455",
               ExpectedResult => "IGNORE",
            },
            "ChangeMTU9000" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmnic.[1]",
               IntType        => "vmnic",
               MTU            => "9000",
               SleepBetweenCombos => "150", # Starting this after all traffic
                                            # threads have been started
            },
            "ChangeMTU1500" => {
               Type           => "NetAdapter",
               TestAdapter    => "host.[1].vmnic.[1]",
               IntType        => "vmnic",
               MTU            => "1500",
               SleepBetweenCombos => "250", # Keeping a > 90 second recommended
                                            # interval, as per PR 934096: comment #17
            },
         },
      },

      'MACChangeVmknic'   => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'MACChangeVmknic',
         Summary          => 'To verify whether RSS accepts only vmknics into its queues by '.
                             'changing the MAC of a vNIC of a VM to a vmknic MAC address',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Security.MACChangeVmknic:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches and '.
                             '   add an RSS supported uplink to each of them.'.
                             '2. Create one VM and another vmknic on either of the vSwitches'.
                             '3. Change the MAC of vNIC to the same range as that'.
                             '   of a vmknic.'.
                             '4. Pass traffic between the VM and the vmknic'.
                             'Verification: RSS should NOT allocate queues to the VM even '.
                             'though its MAC is in the same range as that of a vmknic',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter   => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup  => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter   => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[2].portgroup.[1]",
                        ipv4address => "192.111.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[2].portgroup.[2]",
                        ipv4address => "192.112.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[2].portgroup.[3]",
                        ipv4address => "192.113.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[2].portgroup.[4]",
                        ipv4address => "192.114.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[2].portgroup.[5]",
                        ipv4address => "192.115.2.2",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
            },
            vm => {
               '[1]'   => {
                  host => "host.[1]",
                  vnic => {
                     '[1-5]'   => {
                        driver    => "vmxnet3",
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['UnloadDriverA'],['LoadDriverA'],
                         ['UnloadDriverB'],['LoadDriverB'],
                         ['SetIPv4Vnic1'],['SetIPv4Vnic2'],['SetIPv4Vnic3'],
                         ['SetIPv4Vnic4'],['SetIPv4Vnic5'],
                         ['ChangeMACAddressVnic1'],['ChangeMACAddressVnic2'],
                         ['ChangeMACAddressVnic3'],['ChangeMACAddressVnic4'],
                         ['ChangeMACAddressVnic5'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality']],
            ExitSequence => [['ResetMACAddress']],
            Duration => "4000",

            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "SetIPv4Vnic1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               IPv4           => "192.111.1.1",
            },
            "SetIPv4Vnic2" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[2]",
               IPv4           => "192.112.1.1",
            },
            "SetIPv4Vnic3" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[3]",
               IPv4           => "192.113.1.1",
            },
            "SetIPv4Vnic4" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[4]",
               IPv4           => "192.114.1.1",
            },
            "SetIPv4Vnic5" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[5]",
               IPv4           => "192.115.1.1",
            },
            "ChangeMACAddressVnic1" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               SetMACAddr     => "00:50:56:11:11:11",
            },
            "ChangeMACAddressVnic2" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[2]",
               SetMACAddr     => "00:50:56:22:22:22",
            },
            "ChangeMACAddressVnic3" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[3]",
               SetMACAddr     => "00:50:56:33:33:33",
            },
            "ChangeMACAddressVnic4" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[4]",
               SetMACAddr     => "00:50:56:44:44:44",
            },
            "ChangeMACAddressVnic5" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[5]",
               SetMACAddr     => "00:50:56:55:55:55",
            },
            "ResetMACAddress" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1-5]",
               SetMACAddr     => "reset",
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1]",
               VmkInfo        => "host.[2].vmknic.[1-5]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "600",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "1015"
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "vm.[1].vnic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "1000"
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "vm.[1].vnic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "985"
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "vm.[1].vnic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "970"
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "vm.[1].vnic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "955"
            },
         },
      },

      'UDPVmknicStress'   => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'VmknicStress',
         Summary          => 'To verify whether deletion and addition of a vmknic, over '.
                             'a period of time,  has any adverse effect on RSS functionality',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Stress.VmknicAdditionSubtraction:'.
                             '1. On a freshly installed ESX server, create 2 vSwitches '.
                             '   and add an RSS supported uplink to each of them.'.
                             '2. Create 2 vmknics connected to each of the vSwitches.'.
                             '3. Pass traffic from one vmknic to the other.'.
                             '4. Remove one of the vmknics and add it again. Repeat this '.
                             '   a number of times.'.
                             '5. Continue to run traffic between both the vmknics'.
                             'Verification: RSS be able to allocate queues to newly created'.
                             ' vmknics and reallocate queues to deleted vmknics',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter   => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[1].portgroup.[1]",
                        ipv4address => "192.111.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[1].portgroup.[2]",
                        ipv4address => "192.112.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[1].portgroup.[3]",
                        ipv4address => "192.113.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[1].portgroup.[4]",
                        ipv4address => "192.114.1.1",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[1].portgroup.[5]",
                        ipv4address => "192.115.1.1",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter   => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup  => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup   => "host.[2].portgroup.[1]",
                        ipv4address => "192.111.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[2]'   => {
                        portgroup   => "host.[2].portgroup.[2]",
                        ipv4address => "192.112.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[3]'   => {
                        portgroup   => "host.[2].portgroup.[3]",
                        ipv4address => "192.113.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[4]'   => {
                        portgroup   => "host.[2].portgroup.[4]",
                        ipv4address => "192.114.2.2",
                        netmask     => "255.255.0.0",
                     },
                     '[5]'   => {
                        portgroup   => "host.[2].portgroup.[5]",
                        ipv4address => "192.115.2.2",
                        netmask     => "255.255.0.0",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['UnloadDriverA'],['LoadDriverA'],
                         ['UnloadDriverB'],['LoadDriverB'],
                         ['Traffic6'],['RemoveVmknic11'],['RemoveVmknic21'],
                         ['Traffic7'],['RemoveVmknic12'],['RemoveVmknic22'],
                         ['Traffic8'],['RemoveVmknic13'],['RemoveVmknic23'],
                         ['Traffic9'],['RemoveVmknic14'],['RemoveVmknic24'],
                         ['Traffic10'],['RemoveVmknic15'],['RemoveVmknic25'],
                         ['AddVmknic11'],['AddVmknic12'],
                         ['AddVmknic13'],['AddVmknic14'],
                         ['AddVmknic15'],['AddVmknic21'],
                         ['AddVmknic22'],['AddVmknic23'],
                         ['AddVmknic24'],['AddVmknic25'],
                         ['Traffic1','Traffic2','Traffic3','Traffic4','Traffic5',
                          'VerifyRSSFunctionality']],
            Duration => "15000",

            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "RemoveVmknic11"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               removevmknic   => "host.[1].vmknic.[1]",
            },
            "RemoveVmknic12"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               removevmknic   => "host.[1].vmknic.[2]",
            },
            "RemoveVmknic13"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               removevmknic   => "host.[1].vmknic.[3]",
            },
            "RemoveVmknic14"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               removevmknic   => "host.[1].vmknic.[4]",
            },
            "RemoveVmknic15"  => {
               Type           => "Host",
               TestHost       => "host.[1]",
               removevmknic   => "host.[1].vmknic.[5]",
            },
            "RemoveVmknic21"  => {
               Type           => "Host",
               TestHost       => "host.[2]",
               removevmknic   => "host.[2].vmknic.[1]",
            },
            "RemoveVmknic22"  => {
               Type           => "Host",
               TestHost       => "host.[2]",
               removevmknic   => "host.[2].vmknic.[2]",
            },
            "RemoveVmknic23"  => {
               Type           => "Host",
               TestHost       => "host.[2]",
               removevmknic   => "host.[2].vmknic.[3]",
            },
            "RemoveVmknic24"  => {
               Type           => "Host",
               TestHost       => "host.[2]",
               removevmknic   => "host.[2].vmknic.[4]",
            },
            "RemoveVmknic25"  => {
               Type           => "Host",
               TestHost       => "host.[2]",
               removevmknic   => "host.[2].vmknic.[5]",
            },
            "AddVmknic11" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic => {
               "[1]" =>{
                  ipv4address => "192.111.1.1",
                  portgroup   => "host.[1].portgroup.[1]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic12" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic => {
               "[2]" =>{
                  ipv4address => "192.112.1.1",
                  portgroup   => "host.[1].portgroup.[2]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic13" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic => {
               "[3]" =>{
                  ipv4address => "192.113.1.1",
                  portgroup   => "host.[1].portgroup.[3]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic14" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic => {
               "[4]" =>{
                  ipv4address => "192.114.1.1",
                  portgroup   => "host.[1].portgroup.[4]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic15" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic => {
               "[5]" =>{
                  ipv4address => "192.115.1.1",
                  portgroup   => "host.[1].portgroup.[5]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic21" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vmknic => {
               "[1]" =>{
                  ipv4address => "192.111.2.2",
                  portgroup   => "host.[2].portgroup.[1]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic22" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vmknic => {
               "[2]" =>{
                  ipv4address => "192.112.2.2",
                  portgroup   => "host.[2].portgroup.[2]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic23" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vmknic => {
               "[3]" =>{
                  ipv4address => "192.113.2.2",
                  portgroup   => "host.[2].portgroup.[3]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic24" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vmknic => {
               "[4]" =>{
                  ipv4address => "192.114.2.2",
                  portgroup   => "host.[2].portgroup.[4]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "AddVmknic25" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               vmknic => {
               "[5]" =>{
                  ipv4address => "192.115.2.2",
                  portgroup   => "host.[2].portgroup.[5]",
                  netmask     => "255.255.0.0",
               },
               },
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1]",
               VmkInfo        => "host.[2].vmknic.[1-5]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "600",
            },
            "Traffic6" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "udp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               TestDuration   => "30",
            },
            "Traffic7" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "udp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               TestDuration   => "30",
            },
            "Traffic8" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "udp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               TestDuration   => "30",
            },
            "Traffic9" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "udp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               TestDuration   => "30",
            },
            "Traffic10" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "udp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               TestDuration   => "30",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "1015",
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               l4protocol     => "tcp",
               SendMessageSize => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "30",
               TestDuration   => "1000",
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "128000",
               RemoteSendSocketSize=> "128000",
               SleepBetweenCombos => "45",
               TestDuration   => "985",
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               l4protocol     => "tcp",
               SendMessageSize => "8192",
               LocalSendSocketSize => "256000",
               RemoteSendSocketSize=> "256000",
               SleepBetweenCombos => "60",
               TestDuration   => "970",
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               SleepBetweenCombos => "75",
               TestDuration   => "955",
            },
         },
      },

      'SCCAlgorithm'   => {
         Component        => 'SCC',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'SCCAlgorithmTests',
         Summary          => 'To verify whether  all available Congestion alogrithm are '.
                             'displayed'.
                             'Also, To verify that newreno  congestion alogirthm is '.
                             'displayed as default.'.
                             'Also, To verify weather an application written for newReno, '.
                             'is using newreno  and not cubic'.
                             'Also, To verify weather an application written for cubic CCA,'.
                             ' is using cubic and not newreno',
         ExpectedResult   => 'PASS',
         Tags             => 'physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.SCC.Functional.ListCCA:'.
                             '1. On installed ESX build host,use VSISH & ESXCLI command to '.
                             '   list CCA '.
                             'Verification: Verify that  newreno and cubic congestion '.
                             'alogirthm are displayed '.
                             'For TC ESX.Network.TCPIP4.SCC.Functional.DefaultCCA:'.
                             '1. On  installed ESX build host,use VSISH/ ESX CLI to check '.
                             '   the default Congestion control alogritm used '.
                             'Verification: we should see that newreno  congestion '.
                             'alogirthm is displayed as default'.
                             'For TC ESX.Network.TCPIP4.SCC.Functional.verifynewReno:'.
                             '1. On installed ESX build host, use VSISH/ ESXCLI to check '.
                             '   whether the application running traffic is using newreno '.
                             '   CCA'.
                             'Verification: we should see that newreno CCA is the chosen CCA'.
                             ' for this application'.
                             'For TC ESX.Network.TCPIP4.SCC.Functional.verifyCubic:'.
                             '1. On installed ESX build host, use VSISH/ ESXCLI to check '.
                             '   whether the application running traffic is using cubic '.
                             '   CCA'.
                             'Verification: we should see that cubic CCA is the chosen CCA'.
                             ' for this application',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  netstack   => {
                     '[1]'   => {
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  netstack   => {
                     '[1]'   => {
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['VerifyDefaultCCAlgo'],
                         ['SetCCAlgoCubic'],['Traffic','VerifyConnectionCCACubic'],
                         ['SetCCAlgoNewreno'],['Traffic','VerifyConnectionCCANewreno'],
                         ['VerifyAvailableCCAlgo']],

            "SetCCAlgoCubic" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               setccalgorithm => "cubic",
            },
            "SetCCAlgoNewreno" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               setccalgorithm => "newreno",
            },
            "VerifyAvailableCCAlgo" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               verifycc => "available",
               ccname => "newreno",
            },
            "VerifyDefaultCCAlgo" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               verifycc => "default",
               ccname => "newreno",
            },
            "VerifyConnectionCCACubic" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               verifyconnectioncc => "cubic",
               sleepbetweenworkloads => "60",
            },
            "VerifyConnectionCCANewreno" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1],host.[2].netstack.[1]",
               verifyconnectioncc => "newreno",
               sleepbetweenworkloads => "60",
            },
            "Traffic" => {
               Type => "Traffic",
               L4Protocol => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "180",
               verification => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "2000+",
               },
            },
         },
      },

      'ARPTable'   => {
         Component        => 'ARP',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'ARPTableTests',
         Summary          => 'To verify the ARP cache table is displayed '.
                             'Also, To verify a new entry  is added in the ARP cache '.
                             'when  the source host sends  an arp request to destination'.
                             ' host .'.
                             'Also, To verify  that Invalid  D.host entry would show a mac of'.
                             ' incomplete In the ARP cache  when  source sends arp requests'.
                             ' to dummy host.'.
                             'Also, To verify that ARP cache  gets refreshed based on the arp '.
                             'request / reponse .'.
                             'Also, To verify  ARP response is received with in the 20 min '.
                             'when ARP request is broadcasted. ',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,CAT_P0,physicalonly',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.ARP.Functional.ListARPtable:'.
                             '1. On  installed ESX build host,use  ESXCLI   command to list '.
                             '   ARP table esxcli network ip neighbor list.'.
                             'Verification: Verify that  ARP table is displayed with all ARP '.
                             'associated entries. '.
                             'For TC ESX.Network.TCPIP4.ARP.Functional.HostUp:'.
                             '1. Install ESX build on two  hosts,use  ESXCLI   command to '.
                             '   list ARP table esxcli network ip neighbor list'.
                             '2. Create a vswitch1 on both ESX host and add an uplink to '.
                             '   vswitches on either hosts'.
                             '3. Add VMKNIC to vSwitch on both ESX hosts '.
                             '4. Ping the Other host s VMKNIC '.
                             'Verification: Verify that  ARP cache is added  a new entry '.
                             'for the Destination  host.'.
                             'For TC ESX.Network.TCPIP4.ARP.Functional.HostDown:'.
                             '1. Install ESX build on two  hosts,use  ESXCLI   command to '.
                             '   list ARP table esxcli network ip neighbor list '.
                             '2. Create a vswitch1 on both ESX host and add an uplink to '.
                             '   vswitches   on either hosts'.
                             '3. Add VMKNIC to vSwitch on both ESX  hosts'.
                             '4. Delete the created VMKNIC on destination host'.
                             '5. Now Ping the destination hosts VMKNIC'.
                             'Verification: Verify that  ARP cache is   added  a new entry '.
                             ' for the dummy  host , but would show a mac of incomplete'.
                             'For TC ESX.Network.TCPIP4.ARP.Functional.HostUpHostDown:'.
                             '1. Install ESX build on two  hosts,use  ESXCLI   command to '.
                             '   list ARP table esxcli network ip neighbor list'.
                             '2. Create a vswitch1 on both ESX host and add an uplink to '.
                             '   vswitches   on either hosts '.
                             '3. Add VMKNIC to vSwitch on both ESX  hosts'.
                             '4. Ping the Other host s VMKNIC '.
                             '5. Verify the ARP cache is aded the new entry for the '.
                             '   destination host'.
                             '6. Now delete  the vmknic  on Destination   host '.
                             '7. ping again the destination host'.
                             'Verification: Verify that  ARP cache is added  a new entry '.
                             'for the Destination  host. Verify that later ARP cache should '.
                             'delete the destination host entry  once its  n/w interface  '.
                             'goes down.'.
                             'For TC ESX.Network.TCPIP4.ARP.Functional.HostDownHostUp:'.
                             '1. Install ESX build on two  hosts,use  ESXCLI   command to '.
                             '   list ARP table esxcli network ip neighbor list'.
                             '2. Create a vswitch1 on both ESX host and add an uplink to '.
                             '   vswitches   on either hosts'.
                             '3. Add VMKNIC to vSwitch on both ESX  hosts'.
                             '4. Delete  the vmknic  on Destination   host '.
                             '5. Ping the Other host s VMKNIC '.
                             '6. Verify the   ARP cache does not  displays the destination '.
                             '   host '.
                             '7. Now  bring up the vmknic  on Destinaation   host '.
                             '8. ping again the destination host'.
                             'Verification: Verify that  initially , ARP cache  should not '.
                             'display the Destination host entry , but once the D. host n/w '.
                             'interface comes up it should get added to the ARP cache.  '.
                             'For TC ESX.Network.TCPIP4.ARP.Functional.ArpTimer.HostUp:'.
                             '1. Install ESX build on two  hosts,use  ESXCLI   command to '.
                             '   list ARP table esxcli network ip neighbor list'.
                             '2. Create a vswitch1 on both ESX host and add an uplink to '.
                             '   vswitches   on either hosts'.
                             '3. Add VMKNIC to vSwitch on both ESX  hosts'.
                             '4. Ping the Other host s VMKNIC '.
                             'Verification: Verify that  ARP cache is added  a new entry '.
                             'for the Destination  host and also verify the ARP response '.
                             'is received with in 20 min.',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'amukherjee',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['Ping'],['verifyvmknicarpcache'],
                         ['RemoveUplink'],
                         ['verifyvmknicarpcacheFail'],
                         ['PingFail','verifyarpnegativetimer']],

            "verifyvmknicarpcache" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               verifyvmknicarpcache => "host.[2].vmknic.[1]",
            },
            "verifyvmknicarpcacheFail" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               verifyvmknicarpcache => "host.[2].vmknic.[1]",
               sleepbetweencombos => "1200",
               ExpectedResult => "FAIL",
            },
            "verifyarpnegativetimer" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               verifyarpnegativetimer => "host.[2].vmknic.[1]",
               sleepbetweencombos => "15",
            },
            "Ping" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration   => "5",
            },
            "PingFail" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration   => "5",
               ExpectedResult => "FAIL",
            },
            "RemoveUplink" => {
               Type           => "Switch",
               TestSwitch     => "host.[2].vss.[1]",
               ConfigureUplinks => "remove",
               VMNicAdapter   => "host.[2].vmnic.[1]",
            },
         },
      },


      'MaxVmknicSupport'  => {
         Component        => 'RSS',
         Category         => 'Networking',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TCPIP4',
         TestName         => 'MaxVmknicSupport',
         Summary          => 'To verify whether the RSS pool supports the max number of '.
                             'vmknics per pool',
         ExpectedResult   => 'PASS',
         'PMT'            => '4083',
         Procedure        => 'For TC ESX.Network.TCPIP4.RSS.Load.MaxVmknicSupport:'.
                             '1. On a freshly installed ESX build, create a vSwitch and '.
                             '   add an RSS supported uplink to it.'.
                             '2. Add the max number of vmknics supported by RSS and '.
                             '   check whether the RSS pool reflects the correct '.
                             '   information per vmknic'.
                             '3. Repeat the same for vDS.'.
                             '4. Once the max number of vmknics are reached, create more '.
                             '   to check behavior of the RSS pool'.
                             'Verification: RSS pools should be able to support the max '.
                             'number of vmknics specified for it. There should be no '.
                             'PSOD, loss of network connectivity once the max number is '.
                             'crossed.',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'yanxuez',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc => {
               '[1]' => {
                  datacenter => {
                     '[1]' => {
                        host => "host.[1]",
                     },
                  },
                  vds => {
                     '[1]' => {
                        datacenter => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1-35]'   => {
                        vds      => "vc.[1].vds.[1]",
                        ports    => "8",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1-35]'   => {
                        portgroup   => "vc.[1].dvportgroup.[x]",
                        ipv4 => "auto"
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter   => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup  => {
                     '[1-35]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1-2]'   => {
                        driver => "ixgbe",
                     },
                  },
                  vmknic => {
                     '[1-35]'   => {
                        portgroup   => "host.[2].portgroup.[x]",
                        ipv4 => "auto"
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
               ['UnloadDriverA'],['LoadDriverA'],['UnloadDriverB'],['LoadDriverB'],
               ['Traffic1','VerifyRSSFunctionality'],
               ['UnloadDriverA'],['LoadDriverA'],['UnloadDriverB'],['LoadDriverB'],
               ['Traffic2','VerifyRSSFunctionality2'],
               ['AddDVPG'],
               ['AddVmknic'],
               ['Traffic3']
            ],
            Duration => "9000",
            "UnloadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               UnloadDriver   => "host.[1].vmnic.[1]",
            },
            "LoadDriverA" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               LoadDriver     => "host.[1].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "UnloadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               UnloadDriver   => "host.[2].vmnic.[1]",
            },
            "LoadDriverB" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               LoadDriver     => "host.[2].vmnic.[1]",
               ModuleParam    => "RSS=4::4",
            },
            "AddDVPG" => {
               Type           => "VC",
               TestVC         => "vc.[1]",
               dvportgroup    => {
                  '[36]' => {
                     ports    => "8",
                     name     => "test",
                     vds      => 'vc.[1].vds.[1]'
                  }
               }
            },
            "AddVmknic" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               vmknic         => {
                  '[36]' => {
                     portgroup => 'vc.[1].dvportgroup.[36]',
                     ipv4      => 'auto'
                  }
               }
            },
            "VerifyRSSFunctionality" => {
               Type           => "Host",
               TestHost       => "host.[2]",
               VerifyRSSFunctionality => "host.[2].vmnic.[1]",
               VmkInfo        => "host.[2].vmknic.[1-35]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "500",
            },
            "VerifyRSSFunctionality2" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               VerifyRSSFunctionality => "host.[1].vmnic.[1]",
               VmkInfo        => "host.[1].vmknic.[1-35]",
               RSSQueueNum    => "1",
               SleepBetweenVerification => "500",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1-35]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "200",
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[1-35]",
               l4protocol     => "tcp",
               SendMessageSize => "32768",
               LocalSendSocketSize => "64512",
               RemoteSendSocketSize=> "131072",
               SleepBetweenCombos => "15",
               TestDuration   => "200",
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "host.[2].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[36]",
               l4protocol     => "tcp",
               SendMessageSize => "64000",
               LocalSendSocketSize => "32728",
               RemoteSendSocketSize=> "57344",
               TestDuration   => "20",
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for TCPIP4RSS
#
# Input:
#       none
#
# Results:
#       An instance/object of VMKTCPIPTds class
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
      my $self = $class->SUPER::new(\%TCPIP4RSS);
      return (bless($self, $class));
}

1;
