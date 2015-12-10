#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::SampleVC::SampleVCTds;

#
# This file contains the structured hash for VC category, Sample tests
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
   @TESTS = ("VCUnitTest", "VDSUnitTest","ChangePortgroupWork","SetNetIORM","Profile",
            "VMotion","SetPNicMode","AddRemoveVDS","VDL2UnitTest","HealthCheckUnitTest");

   %SampleVC = (
      'VCUnitTest' => {
         Component         => "Virtual Center",
         Category          => "SampleVC",
         TestName          => "VCOperate",
         Summary           => "Operate VC through STAF ",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
            helper1        => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['VCOperation_1'],['VCOperation_4'],['VCOperation_2'],['VCOperation_7'],
                                  ['AddUplink'],['RemoveHostFromVDS'],
                                  ['VCOperation_3'],['VCOperation_5'],],
            Duration          => "time in seconds",

            "VCOperation_1" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "VCOperation_2" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/folder_1/dc_1",
               Hosts          => "SUT,helper1",
            },
            "VCOperation_3" => {
               Type           => "VC",
               OPT            => "removedc",
               DCName         => "/folder_1/dc_1",
            },
            "VCOperation_4" => {
               Type           => "VC",
               OPT            => "addfolder",
               FolderName     => "/folder_1",
            },
            "VCOperation_5" => {
               Type           => "VC",
               OPT            => "removefolder",
               FolderName     => "/folder_1",
            },
            "VCOperation_7" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vds_1",
               DCName         => "dc_1",
               Uplink         => "SUT::1,helper1::1",
            },
            "AddUplink" => {
               Type           => "VC",
               OPT            => "adduplink",
               VDSName        => "vds_1",
              Uplink         => "SUT::1,helper1::1",
            },
            "RemoveHostFromVDS" => {
               Type           => "VC",
               OPT            => "removehostfromvds",
               VDSName        => "vds_1",
               Hosts          => "SUT,helper1",
            },
            "RemoveHostFromDC" => {
               Type           => "VC",
               OPT            => "removehostfromdc",
               Hosts          => "SUT,helper1",
            },
         },
      },

      "VDSUnitTest" => {
         Component         => "vNetwork Distributed Switch",
         Category          => "SampleVC",
         TestName          => "vDS Operations",
         Summary           => "Operations on vds",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               switch      => ['vds:1'],
            },
            helper1     => {
               host        => 1,
               switch => ['vds:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['CreateDVPortgroup'], ['AddPort'], ['AddMirror'],
                                  ['EditMirror'],['RemoveMirror'], ['LLDP_Listen'],
                                  ['LLDP_Advertise'],['LLDP_Both'], ['NetFlow'],
                                  ['SetJumbo'],['SetTeaming'],['EnableForged'],
                                  ['DisableForged'], ['EnableMACChange'],
                                  ['DisableMACChange'], ['DisablePromisc'],
                                  ['EnablePromisc'],['AccessVLAN'],['TrunkRange'],
                                  ['EnableInShaping'],['EnableOutShaping'],
                                  ['DisableInShaping'], ['DisableOutShaping'],
                                  ['AddPVLAN'], ['SetPVLAN'], ['RemoveDVPortgroup']],

            "CreateDVPortgroup" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               createdvportgroup => "vds-test-dvportgroup",
            },
            "AddPort" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               ports => "10",
               addporttodvportgroup => "vds-test-dvportgroup",
            },
            "AddMirror" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               addmirrorsession => "Test_Mirror",
               dstpg => "vds-test-dvportgroup",
               desc => "Basic_Mirror_Test",
               stripvlan => "true",
               length => "100",
               normaltraffic => "false",
            },
            "EditMirror" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               editmirrorsession => "Test_Mirror",
               dstpg => "vds-test-dvportgroup",
               desc => "Basic_Mirror_Test",
               stripvlan => "false",
               length => "10",
               normaltraffic => "true",
            },
            "RemoveMirror" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               removemirrorsession => "Test_Mirror",
            },
            "LLDP_Listen" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               lldp => "listen",
            },
          "LLDP_Advertise" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               lldp => "advertise",
            },
            "LLDP_Both" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               lldp => "both",
            },
            "SetTeaming" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               confignicteaming => "vds-test-dvportgroup",
               failover => "beaconprobing",
               notifyswitch => "N",
               failback => "false",
               lbpolicy => "loadbalance_ip",
             },
             "EnableForged" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setforgedtransmit => "Enable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "DisableForged" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setforgedtransmit => "Disable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "EnableMACChange" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setmacaddresschange => "Enable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "DisableMACChange" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setmacaddresschange => "Disable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "DisablePromisc" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setpromiscuous => "Disable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "EnablePromisc" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setpromiscuous => "Enable",
               dvportgroup => "vds-test-dvportgroup",
            },
            "BlockPort" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               blockport => "20",
               portgroup => "vds-test-dvportgroup",
            },
            "UnBlockPort" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               unblockport => "20",
               portgroup => "vds-test-dvportgroup",
            },
            "AccessVLAN" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               accessvlan => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
               portgroup => "vds-test-dvportgroup",
            },
            "TrunkRange" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               trunkrange => "[0-4094]",
               portgroup => "vds-test-dvportgroup",
            },
            "EnableInShaping" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               enableinshaping => "vds-test-dvportgroup",
               avgbandwidth => "500",
               peakbandwidth => "600",
               burstsize => "500",
            },
            "EnableOutShaping" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               enableoutshaping => "vds-test-dvportgroup",
               avgbandwidth => "500",
               peakbandwidth => "600",
               burstsize => "500",
           },
           "DisableInShaping" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               disableinshaping => "vds-test-dvportgroup",
            },
            "DisableOutShaping" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               disableoutshaping => "vds-test-dvportgroup",
            },
            "AddPVLAN" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => 1,
               addpvlanmap => "promiscuous",
               primaryvlan => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
               secondaryvlan => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
            },
            "SetPVLAN" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               setpvlantype => "vds-test-dvportgroup",
               pvlan => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
            },
            "NetFlow" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               confignetflow => "192.168.10.1",
               internal => "false",
               idletimeout => "30",
               activetimeout => "120",
               sampling => "1",
               vdsIP => "192.168.10.10",
            },
            "SetJumbo" => {
                Type => "Switch",
                Target => "SUT",
                TestSwitch => "1",
                mtu => "9000",
            },
            "RemoveDVPortgroup" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               removedvportgroup => "vds-test-dvportgroup",
            },
         },
      },
      "MigrateToVDS" => {
         Component         => "vNetwork Distributed Switch",
         Category          => "SampleVC",
         TestName          => "vDS Operations",
         Summary           => "Operations on vds",
         ExpectedResult    => "PASS",
         Parameters        => {
            vc             => 1,
            SUT            => {
               host        => 1,
               switch      => ['vds:1'],
               vmnic       => ['any:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['AddVSwitch'],['AddPortgroup'],
                                  ['AddVMK'],['CreateDVPortgroup'],['AddPort'],
                                  ['MigrateToVDS'],['MigrateToVSS'],['DelVMK']],
            Duration          => "time in seconds",
            "AddVSwitch" => {
               Type  => "Host",
               Target => "SUT",
               vswitch => "add",
               vswitchname => "migrate-to-net",
            },
            "AddPortgroup" => {
               Type => "Host",
               Target => "SUT",
               portgroup => "add",
               portgroupname => "migrate-pg",
               vswitchname => "migrate-to-net",
            },
            "AddVMK" => {
               Type => "Host",
               Target => "SUT",
               vmknic => "add",
               pgname => "migrate-pg",
               ip     => "dhcp",
            },
            "CreateDVPortgroup" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               createdvportgroup => "migrate-dvportgroup",
            },
            "AddPort" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               ports => "5",
               addporttodvportgroup => "migrate-dvportgroup",
            },
           "MigrateToVDS" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               migratemgmtnettovds => "migrate-dvportgroup",
               portgroup => "migrate-pg",
            },
            "MigrateToVSS" => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               migratemgmtnettovss => "SUT",
               portgroup => "migrate-pg",
               dvportgroup => "migrate-dvportgroup",
               vss => "migrate-to-net",
            },
            "DelVMK" => {
               Type => "Host",
               Target => "SUT",
               vmknic => "delete",
               portgroup => "migrate-pg",
            },
         },
      },
      "ChangePortgroupWork" => {
         Component         => "vNetwork Distributed Switch",
         Category          => "SampleVC",
         TestName          => "Change VNIC from PG to DVPG",
         Summary           => "Change VNIC from PG to DVPG",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
              vnic        => ['vmxnet3:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['Connect'],['datacenter'],['createvds'],['CreateDVPortgroup'],
                                  ['AddPort1'],['ChangePortgroupWork_1'],['ChangePortgroupWork_2'],['RemoveDC']],
            Duration          => "time in seconds",

            "Connect" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "datacenter" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dc_1",
               Hosts          => "SUT",
            },
            "createvds" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vds-test",
               DCName         => "dc_1",
               Uplink         => "SUT::1",
            },
            "CreateDVPortgroup" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               TestSwitch => "vds-test",
               datacenter => "dc_1",
               createdvportgroup => "vds-test-dvportgroup",
            },
            "AddPort1" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               datacenter => "dc_1",
               TestSwitch => "vds-test",
               ports => "5",
               addporttodvportgroup => "vds-test-dvportgroup",
            },
            "RemoveDC" => {
               Type => "VC",
               OPT => "removedc",
               DCName => "/dc_1",
            },
            "ChangePortgroupWork_1" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               PortGroupName  => "vds-test-dvportgroup",
               Operation      => "ChangePortGroup",
               Anchor         => "vc",
             },
             "ChangePortgroupWork_2" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               PortGroupName  => "vdtest",
               Operation      => "ChangePortGroup",
               Anchor         => "vc",
             },
          }
      },
      "SetNetIORM" => {
         Component         => "vNetwork Distributed Switch",
         Category          => "SampleVC",
         TestName          => "Enable/Disable NetIORM feature in VDS",
         Summary           => "Enable/Disable NetIORM feature in VDS",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },
         WORKLOADS => {
            Sequence          => [['Connect'],['datacenter'],['createvds'],['EnableNetIORM'],
                                  ['AddNRPs'],['AddNRP'],['DisableNetIORM'],['RemoveDC']],
            Duration          => "time in seconds",

            "Connect" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "datacenter" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dc_1",
            },
            "createvds" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vdstest",
               DCName         => "dc_1",
            },
            "EnableNetIORM" => {
                Type => "Switch",
                Target => "VC",
                SwitchType => "vdswitch",
                datacenter => "dc_1",
                TestSwitch => "vdstest",
                enablenetiorm => "1",
            },
            "AddNRP" => {
               Type           => "VC",
               OPT            => "addnrp",
               VDSName        => "vdstest",
               NRPName        => "testnrp",
               NRPShare       => "100",
            },
            "AddNRPs" => {
               Type           => "VC",
               OPT            => "addnrp",
               VDSName        => "vdstest",
               NRPName        => "testnrp",
               NRPShare       => "100",
               NRPLimit       => "40",
               NRPNumber      => "3",
            },
            "DisableNetIORM" => {
                Type => "Switch",
                Target => "VC",
                SwitchType => "vdswitch",
                datacenter => "dc_1",
                TestSwitch => "vdstest",
                disablenetiorm => "1",
            },
            "RemoveDC" => {
               Type => "VC",
               OPT => "removedc",
               DCName => "/dc_1",
            },
         }
      },
      "VMotion" => {
         Component         => "Virtual Center",
         Category          => "VMotion",
         TestName          => "VMotion",
         Summary           => "VMotion",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT             => {
               'switch'    => ['vss:1'],
               'vmknic'    => ['switch1:1'],
               'vnic'      => ['vmxnet3:1'],
               'datastoreType'  => "shared",
            },
            helper1        => {
               'switch'    => ['vss:1'],
               'vmknic'    => ['switch1:1'],
               'host'      => 1,
            },
         },
         WORKLOADS => {
            Sequence          => [['EnableVMotion1'],['EnableVMotion2'],['Connect'],['datacenter'],['createvds'],
                                  ['Createdvpga'],['AddPort1'],['ChangePortgroupWork_1'],['vmotion'],['ChangePortgroupWork_2'],
                                  ['RemoveDC']],
            Duration          => "time in seconds",

            "Connect" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "datacenter" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dctest",
               Hosts          => "SUT,helper1",
            },
            "createvds" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vdstest",
               DCName         => "dctest",
               Uplink         => "SUT::1,helper1::1",
            },
            "Createdvpga" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               TestSwitch => "vdstest",
               datacenter => "dctest",
               createdvportgroup => "dvpga",
            },
            "AddPort1" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               datacenter => "dctest",
               TestSwitch => "vdstest",
               ports => "5",
               addporttodvportgroup => "dvpga",
            },
            "ChangePortgroupWork_1" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               PortGroupName  => "dvpga",
               Operation      => "ChangePortGroup",
               Anchor         => "vc",
            },
            "ChangePortgroupWork_2" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               PortGroupName  => "vdtest",
               Operation      => "ChangePortGroup",
               Anchor         => "vc",
            },
            "RemoveDC" => {
               Type => "VC",
               OPT => "removedc",
               DCName => "/dctest",
            },
            "EnableVMotion1" => {
               Type             => "NetAdapter",
               Target           => "SUT",
               TestAdapter      => "1",
               IntType          => "vmknic",
               VMotion          => "ENABLE",
               ipv4             => "192.168.111.1",
            },
            "EnableVMotion2" => {
               Type             => "NetAdapter",
               Target           => "helper1",
               TestAdapter      => "1",
               IntType          => "vmknic",
               VMotion          => "ENABLE",
               ipv4             => "192.168.111.2",
            },
            "vmotion" => {
               Type           => "VC",
               OPT            => "vMotion",
               VM             => "SUT",
               DstHost        => "helper1",
               Priority       => "high",
               Staytime       => "10",
               RoundTrip      => "yes",
            },
         }
      },
      'Profile' => {
         Component         => "Virtual Center",
         Category          => "SampleVC",
         TestName          => "Profile",
         Summary           => "Operate hostprofile through STAF ",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },

         },

         WORKLOADS => {
            Sequence          => [['VCOperation_1'],['VswitchAdd'],['PortgroupAdd'],
                                  ['InterfaceAdd'],['CreateProfile'],['EditNetworkPolicyOpt'],
                                  ['CheckCompliance'],['AssociateProfile'],['ApplyProfile'],
                                  ['DestroyProfile'],['InterfaceRemove'],['PortgroupRemove'],
                                  ['VswitchRemove'],],
            Duration          => "time in seconds",
            IgnoreFailure     => "1",
            "VCOperation_1" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "VswitchAdd" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network vswitch standard add",
               Args           => "-v vSwitch100",
            },
            "PortgroupAdd" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network vswitch standard portgroup add",
               Args           => "-v vSwitch100 -p testpg100",
            },
            "InterfaceAdd" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network ip interface add",
               Args           => "-p testpg100 -i vmk1",
            },
            "CreateProfile" => {
               Type           => "VC",
               OPT            => "createprofile",
               Host           => "SUT",
               targetprofile  => "testprofile",
               referencehost  => "SUT"
            },
            "EditNetworkPolicyOpt" => {
               Type             => "VC",
               OPT              => "editpolicyopt",
               Host             => "SUT",
               applyprofile     => "NetworkProfile",
               targetprofile    => "testprofile",
               profiledevice    => "testpg100",
               profilecategory  => "Host port group",
               policyid         => "IpAddressPolicy",
               policyoption     => "FixedIpConfig",
               policyparams     => "address:176.10.1.100,subnetmask:255.255.255.0",
               subcategory      => "IP address settings",
            },
            "CheckCompliance" => {
               Type           => "VC",
               OPT            => "checkcompliance",
               Host           => "SUT",
               targetprofile  => "testprofile",
            },
            "AssociateProfile" => {
               Type           => "VC",
               OPT            => "associateprofile",
               Host           => "SUT",
               targetprofile  => "testprofile",
            },
            "ApplyProfile" => {
               Type           => "VC",
               OPT            => "applyprofile",
               Host           => "SUT",
               targetprofile  => "testprofile",
            },
            "InterfaceRemove" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network ip interface remove",
               Args           => "-i vmk1",
            },
            "PortgroupRemove" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network vswitch standard portgroup remove",
               Args           => "-v vSwitch100 -p testpg100",
            },
            "VswitchRemove" => {
               Type           => "Command",
               Target         => "SUT",
               HostType       => "esx",
               Command        => "esxcli network vswitch standard remove",
               Args           => "-v vSwitch100",
            },
            "DestroyProfile" => {
               Type           => "VC",
               OPT            => "destroyprofile",
               targetprofile  => "testprofile",
            },
         },
      },
      "SetPNicMode" => {
         Component         => "Example for setting physical switch port",
         Category          => "SampleVC",
         TestName          => "Set physical switch port mode",
         Summary           => "Set physical switch port mode",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               switch      => ['vds:1'],
               pswitch     => 1,
               vmnic       => ['any:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['SetPortMode1'],[SetPortMode2]],
            Duration          => "time in seconds",

            "SetPortMode1" => {
               Type          => "Switch",
               TestSwitch    => "1",
               SwitchType    => "pswitch",
               VmnicAdapter  => "1",
               accessvlan    => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },
            "SetPortMode2" => {
               Type          => "Switch",
               TestSwitch    => "1",
               SwitchType    => "pswitch",
               trunkrange    => "yes",
               VmnicAdapter  => "1",
               NativeVlan    => VDNetLib::Common::GlobalConfig::VDNET_NATIVE_VLAN,
               VLANRange     => "[301-310]",
            },
         },
      },
      "SetVDSUplink" => {
         Component         => "Example for setting physical switch port",
         Category          => "SampleVC",
         TestName          => "Set physical switch port mode",
         Summary           => "Set physical switch port mode",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },
         WORKLOADS => {
         	IgnoreFailure     => 1,
            Sequence          => [['Connect'],['datacenter'],['createvds'],
                                  ['AddUplink'],['SetVDSUplink1'],['SetVDSUplink2'],['RemoveDC']],
            Duration          => "time in seconds",
            "Connect" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "datacenter" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dctest",
               Hosts          => "SUT",
            },
            "createvds" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vdstest",
               DCName         => "dctest",
               Uplink         => "SUT::1",
            },
            "RemoveDC" => {
               Type => "VC",
               OPT => "removedc",
               DCName => "/dctest",
            },
            "AddUplink" => {
               Type           => "VC",
               OPT            => "adduplink",
               VDSName        => "vdstest",
               Uplink          => "SUT::1",
            },
            "SetVDSUplink1" => {
               Type           => "VC",
               OPT            => "setvdsuplink",
               VDSName        => "vdstest",
               PortMode       => "access",
               vlanid         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
               host           => "SUT",
               Count          => 1,
            },
            "SetVDSUplink2" => {
               Type           => "VC",
               OPT            => "setvdsuplink",
               PortMode       => "trunk",
               NativeVlan     => VDNetLib::Common::GlobalConfig::VDNET_NATIVE_VLAN,
               VlanRange      => "301-310",
               host           => "SUT",
            },
         },
      },
      'AddRemoveVDS' => {
         Component         => "Virtual Center",
         Category          => "SampleVC",
         TestName          => "AddRemoveVDS",
         Summary           => "Operate VC through STAF ",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['VCOperation_1'],['VCOperation_2'],['VCOperation_3'],
                                  ['Createdvpga'],['AddPort1'],['RemoveVDS'],['RemoveDC'],],
            Duration          => "time in seconds",
            IgnoreFailure     => "1",

            "VCOperation_1" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "VCOperation_2" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dc_test",
               Hosts          => "SUT,",
            },
            "VCOperation_3" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vds_test",
               DCName         => "dc_test",
               Uplink         => "SUT::1",
            },
            "Createdvpga" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               TestSwitch => "vds_test",
               datacenter => "dc_test",
               createdvportgroup => "dvpga",
            },
            "AddPort1" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               datacenter => "dc_test",
               TestSwitch => "vds_test",
               ports => "20",
               addporttodvportgroup => "dvpga",
            },
            "RemoveVDS" => {
               Type           => "VC",
               OPT            => "removevds",
               VDSName        => "vds_test",
            },
            "RemoveDC" => {
               Type => "VC",
               OPT => "removedc",
               DCName => "/dc_test",
            },
         },
      },
      "VDL2UnitTest" => {
         Component         => "network vl2/CHF/BFN",
         Category          => "ESX Server",
         TestName          => "vdl2 basic operation",
         Summary           => "Simple example about how to set vdl2",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
            },
         },
        WORKLOADS => {
            Sequence          => [['ConnectVC'],['CreateDC'],['CreateVDS'],['EnableVDL2'],
                                  ['CreateDVPG'],['CreateVDL2VMKNic'],['AttachVDL2'],
                                  ['AttachVDL2id'],['AttachVDL2MCIP'],
                                  ['DetachVDL2'],['RemoveVDL2VMKNic'],
                                  ['DisableVDL2'],['RemoveDC'],
                                   ],
            Duration          => "time in seconds",
            IgnoreFailure     => "1",

            "DetachVDL2" => {
               Type            => "VC",
               OPT             => "detachvdl2",
               VDSName         => "vdstest",
               PGName          => "dvpga",
            },
            "AttachVDL2" => {
               Type            => "VC",
               OPT             => "attachvdl2",
               VDSName         => "vdstest",
               PGName          => "dvpga",
               VDL2ID          => "100",
               MCASTIP         => "224.100.11.1",
            },
            "AttachVDL2id" => {
               Type            => "VC",
               OPT             => "attachvdl2id",
               VDSName         => "vdstest",
               PGName          => "dvpga",
               VDL2ID          => "101",
            },
            "AttachVDL2MCIP" => {
               Type            => "VC",
               OPT             => "attachvdl2mcip",
               VDSName         => "vdstest",
               PGName          => "dvpga",
               MCASTIP         => "224.100.11.2",
            },
            "CreateVDL2VMKNic" => {
               Type            => "VC",
               OPT             => "createvdl2vmknic",
               VDSIndex        => "1",
               VDSName         => "vdstest",
               VLANID          => "3001",
               VMKNICIP        => "172.168.1.1",
            },
            "RemoveVDL2VMKNic"     => {
               Type            => "VC",
               OPT             => "removevdl2vmknic",
               VDSIndex        => "1",
               VDSName         => "vdstest",
               VLANID          => "3001",
            },
            "EnableVDL2" => {
               Type           => "VC",
               OPT            => "enablevdl2",
               VDSIndex       => "1",
               VDSName        => "vdstest",
            },
            "DisableVDL2" => {
               Type           => "VC",
               OPT            => "disablevdl2",
               VDSIndex       => "1",
               VDSName        => "vdstest",
            },
            "ConnectVC" => {
               Type           => "VC",
               OPT            => "connect",
            },
            "CreateDC" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/dctest",
               Hosts          => "SUT",
            },
            "RemoveDC" => {
               Type           => "VC",
               OPT            => "removedc",
               DCName         => "/dctest",
            },
            "CreateVDS" => {
               Type           => "VC",
               OPT            => "createvds",
               VDSName        => "vdstest",
               DCName         => "dctest",
               Uplink         => "SUT::1",
            },
            "CreateDVPG" => {
               Type => "Switch",
               SwitchType => "vdswitch",
               Target => "VC",
               TestSwitch => "vdstest",
               datacenter => "dctest",
               createdvportgroup => "dvpga",
            },
         },
      },
       "HealthCheckUnitTest" => {
         Component         => "vNetwork Distributed Switch",
         Category          => "SampleVC",
         TestName          => "vDS healthcheck",
         Summary           => "Operations on vds healthcheck",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               host        => 1,
               switch      => ['vds:1'],
               vmnic       => ['any:1'],
            },
         },
         WORKLOADS => {
            Sequence          => [['EnableVLANMTUCheck'],['DisableVLANMTUCheck'],
                                  ['EnableTeamingCheck'],['DisableTeamingCheck']],
            "EnableTeamingCheck" => {
                Type => "Switch",
                Target => "SUT",
                TestSwitch => "1",
                configurehealthcheck => "teaming",
                operation => "Enable",
                healthcheckinterval => "10",
            },
            "DisableTeamingCheck" => {
                Type => "Switch",
                Target => "SUT",
                TestSwitch => "1",
                configurehealthcheck => "teaming",
                operation => "Disable",
                healthcheckinterval => "10",
            },
            "EnableVLANMTUCheck" => {
                Type => "Switch",
                Target => "SUT",
                TestSwitch => "1",
                configurehealthcheck => "vlanmtu",
                operation => "Enable",
                healthcheckinterval => "10",
            },
            "DisableVLANMTUCheck" => {
                Type => "Switch",
                Target => "SUT",
                TestSwitch => "1",
                configurehealthcheck => "vlanmtu",
                operation => "Disable",
                healthcheckinterval => "10",
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for SampleVCTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleVCTds class
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
   my $self = $class->SUPER::new(\%SampleVC);
   return (bless($self, $class));
}
1;
