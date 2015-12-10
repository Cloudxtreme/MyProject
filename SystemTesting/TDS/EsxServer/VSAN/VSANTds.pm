########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VSAN::VSANTds;


use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestConstants;
use TDS::EsxServer::VSAN::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Test constants
use constant TRAFFIC_TESTDURATION => "300";
use constant STRESS_ITERATIONS => "10";

# Import Workloads which are very common across all tests
use TDS::EsxServer::VSAN::CommonWorkloads ':AllConstants';

{
%VSAN = (
   'HAFailover' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "HAFailover",
      Version          => "2" ,
      Tags             => "",
      Summary          => "Verify HA Failover works when VM's present on ".
                          "VSAN-datastore. This test case required because, ".
                          "now .dvsdata is moved from common directory to VM ".
                          "specific directory.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      # Enable VSAN after hosts are added in Cluster
                      # so that they join same disk group
                      ['EnableVSANonCluster'],
                      ['EnableHAonVSANCluster'],
                      ['CheckVmknicVSAN'],
                      ['JoinDiskGroup'],
                      # Verify they are in same disk group
                      ['VerifyVSANDiskGroup'],
                      ['CreateVMonVSAN'],
                      ['RunDTInVM1'],
                      ['RebootHostWithVM1'],
                      ['DiscoverVM'],
                      ['RunDTInVM1'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["DisableHAonVSANCluster"],
                          ["LeaveDiskGroup"],
                          ['DisableVSANonCluster'],
                         ],

         "CheckVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup" => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVMonVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "RunDTInVM1" => RUN_DATA_TEST_PROGRAM_VM1_120_SEC,

         "EnableHAonVSANCluster" => {
            Type => "Cluster",
            TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
            EditCluster => "edit",
            ha   => 1,
         },

         "RebootHostWithVM1" => {
            Type       => "Host",
            Testhost   => "host.[1]",
            reboot     => "yes",
         },

         "DiscoverVM" => {
            Type        => "VM",
            TestVM      => "vm.[1]",
            sleepbetweenworkloads => "180",
            findvmin    => "vc.[1].datacenter.[1]",
         },

         "DeleteAllVMs" => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableHAonVSANCluster" => {
            Type => "Cluster",
            TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
            EditCluster => "edit",
            ha   => 0,
         },

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'VMotion' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "VMotion",
      Version          => "2" ,
      Tags             => "",
      Summary          => "Verify VMotion works between VSAN-datastore".
                          " and local storage. This internally verifies ".
                          "VMKernel interface functionalities.  This test ".
                          "case required because, now .dvsdata is moved ".
                          "from common directory to VM specific directory.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['GetDHCPIP'],
                      ['NetperfTestAllVMs'],
                      ['vMotionVM1ToHost2'],
                      ['vMotionVM2ToHost3','vMotionVM3ToHost1'],
                      ['RunDTInVM1'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDTInVM1"      => RUN_DATA_TEST_PROGRAM_VM1_120_SEC,

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "vMotionVM1ToHost2" => {
            Type            => "VM",
            TestVM          => "vm.[1]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[2]",
         },
         "vMotionVM2ToHost3" => {
            Type            => "VM",
            TestVM          => "vm.[2]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[3]",
         },
         "vMotionVM3ToHost1" => {
            Type            => "VM",
            TestVM          => "vm.[3]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[1]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'StorageVMotion' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "StorageVMotion",
      Version          => "2" ,
      Tags             => "",
      Summary          => "Verify StorageVMotion works between VSAN-datastore ".
      "and local storage. This internally verifies VMKernel interface ".
      "functionalities. This test case required because, now .dvsdata is moved ".
      "from common directory to VM specific directory.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onLocal','CreateVM3onNFS'],
                      ['CreateDataStoreObjHost1','CreateDataStoreObjHost2','CreateDataStoreObjHost3'],
                      # VSAN to Local
                      ['GetDHCPIP'],
                      ['StorageVMotionVM1','NetperfTestAllVMs'],
                      # Local to VSAN and NFS to VSAN
                      ['StorageVMotionVM2','StorageVMotionVM3'],
                      ['RunDTInVM1'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,
         "CreateDataStoreObjHost1" => CREATE_ALL_DATASTORE_OBJ_HOST1,
         "CreateDataStoreObjHost2" => CREATE_ALL_DATASTORE_OBJ_HOST2,
         "CreateDataStoreObjHost3" => CREATE_ALL_DATASTORE_OBJ_HOST3,

         "CreateVM2onLocal" => {
            Type     => "Root",
            TestNode => "root.[1]",
            sleepbetweenworkloads => "30",
            vm => {
               '[2]' => {
                  template => "rhel53-srv-32",
                  host     => "host.[2]",
                  vnic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        driver => "vmxnet3",
                     },
                  },
               },
            },
         },

         "CreateVM3onNFS" => {
            Type     => "Root",
            TestNode => "root.[1]",
            sleepbetweenworkloads => "60",
            vm => {
               '[3]' => {
                  template => "rhel53-srv-32",
                  host     => "host.[3]",
                  datastoreType => "shared",
                  vnic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        driver => "vmxnet3",
                     },
                  },
               },
            },
         },

         "RunDTInVM1"      => RUN_DATA_TEST_PROGRAM_VM1_120_SEC,

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
            ExpectedResult => "ignore",
         },

         "StorageVMotionVM1" => {
            Type            => "VM",
            TestVM          => "vm.[1]",
            vmotion         => "storage",
            datastore       => "host.[1].datastore.[2]",
            maxtimeout      => '7200',
         },
         "StorageVMotionVM2" => {
            Type            => "VM",
            TestVM          => "vm.[2]",
            vmotion         => "storage",
            datastore       => "host.[2].datastore.[3]",
            maxtimeout      => '7200',
         },
         "StorageVMotionVM3" => {
            Type            => "VM",
            TestVM          => "vm.[3]",
            vmotion         => "storage",
            datastore       => "host.[3].datastore.[3]",
            maxtimeout      => '7200',
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'xVMotion' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "xVMotion",
      Version          => "2" ,
      Tags             => "VDNet_P0",
      Summary          => "Verify xVMotion (VMotion and storageVMotion) works ".
      "on ESX hosts having VSAN-datastore. This test case required because, ".
      "now .dvsdata is moved from common directory to VM specific directory",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onLocal'],
                      ['CreateDataStoreObjHost1','CreateDataStoreObjHost2','CreateDataStoreObjHost3'],
                      # VSAN to shared with regular vmotion
                      ["GetDHCPIP"],
                      ['xVMotionVM1','RunDTInVM1'],
                      # local to VSAN with regular vmotion
                      ['xVMotionVM2','NetperfTestAllVMs'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateDataStoreObjHost1" => CREATE_ALL_DATASTORE_OBJ_HOST1,
         "CreateDataStoreObjHost2" => CREATE_ALL_DATASTORE_OBJ_HOST2,
         "CreateDataStoreObjHost3" => CREATE_ALL_DATASTORE_OBJ_HOST3,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onLocal" => {
            Type     => "Root",
            TestNode => "root.[1]",
            sleepbetweenworkloads => "30",
            vm => {
               '[2]' => {
                  template => "rhel53-srv-32",
                  host     => "host.[2]",
                  vnic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        driver => "vmxnet3",
                     },
                  },
               },
            },
         },

         "RunDTInVM1"      => RUN_DATA_TEST_PROGRAM_VM1_120_SEC,

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "xVMotionVM1" => {
            Type            => "VM",
            TestVM          => "vm.[1]",
            vmotion         => "hostandstorage",
            datastore       => "host.[2].datastore.[2]",
            dsthost         => "host.[2]",
            maxtimeout      => '7200',
         },
         "xVMotionVM2" => {
            Type            => "VM",
            TestVM          => "vm.[2]",
            vmotion         => "hostandstorage",
            datastore       => "host.[3].datastore.[3]",
            dsthost         => "host.[3]",
            maxtimeout      => '7200',
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'vMotionWithJFVLAN' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "vMotionWithJFVLAN",
      Version          => "2" ,
      Tags             => "PhysicalOnly",
      Summary          => "Verify VSAN works fine with the Jumbo frame, VLAN ".
      "configured and Vmotion is performed.",

      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['SetVmknicMTU1','SetVmknicMTU2','SetVmknicMTU3'],
                      ['SetVDS1MTU'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN'],
                      ['SetAdapterMTU'],
                      ['vMotionVM1ToHost2'],
                      ['NetperfTestAllVMs'],
                      ['vMotionVM2ToHost3','RunDTInVM1'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["UnSetVDS1MTU"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                          ["UnSetVmknicMTU1","UnSetVmknicMTU2","UnSetVmknicMTU3"],
                         ],
         'UnSetVmknicMTU1' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[1].vmknic.[1]',
           'mtu' => '1500',
           'ExpectedResult' => 'Ignore',
         },
         'UnSetVmknicMTU2' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[2].vmknic.[1]',
           'mtu' => '1500',
           'ExpectedResult' => 'Ignore',
         },
         'UnSetVmknicMTU3' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[3].vmknic.[1]',
           'mtu' => '1500',
           'ExpectedResult' => 'Ignore',
         },
         'SetVmknicMTU1' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[1].vmknic.[1]',
           'mtu' => '9000',
           'ExpectedResult' => 'Ignore',
         },
         'SetVmknicMTU2' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[2].vmknic.[1]',
           'mtu' => '9000',
           'ExpectedResult' => 'Ignore',
         },
         'SetVmknicMTU3' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'host.[3].vmknic.[1]',
           'mtu' => '9000',
           'ExpectedResult' => 'Ignore',
         },
         'SetAdapterMTU' => {
            'Type'       => 'NetAdapter',
            'Testadapter'=> 'vm.[1-2].vnic.[1]',
            'mtu'        => '9000',
            'ipv4'       => 'dhcp',
         },
         'UnSetVDS1MTU' => {
            'Type'       => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'mtu'        => '1500'
         },
         'SetVDS1MTU' => {
            'Type'       => 'Switch',
            'TestSwitch' => 'vc.[1].vds.[1]',
            'mtu'        => '9000'
         },

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => {
            Type     => "Root",
            TestNode => "root.[1]",
            sleepbetweenworkloads => "30",
            vm => {
               '[2]' => {
                  template => "rhel53-srv-32",
                  host     => "host.[2]",
                  datastoreType => "vsan",
                  vnic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        driver => "vmxnet3",
                     },
                  },
               },
            },
         },

         "RunDTInVM1"      => RUN_DATA_TEST_PROGRAM_VM1_120_SEC,

         "NetperfTestAllVMs" => {
           Type => 'Traffic',
           localsendsocketsize => '64512',
           toolname => 'netperf',
           testduration => '120',
           testadapter => 'vm.[1].vnic.[1]',
           noofoutbound => '1',
           remotesendsocketsize => '131072',
           l4protocol => 'tcp,udp',
           sendmessagesize => '32768',
           noofinbound => 1,
           supportadapter => 'vm.[2].vnic.[1]'
         },

         "vMotionVM1ToHost2" => {
            Type            => "VM",
            TestVM          => "vm.[1]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[2]",
         },
         "vMotionVM2ToHost3" => {
            Type            => "VM",
            TestVM          => "vm.[2]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[3]",
         },
         "vMotionVM3ToHost1" => {
            Type            => "VM",
            TestVM          => "vm.[3]",
            Iterations      => "1",
            vmotion         => "oneway",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },
   'EnableDisableVmnic' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "EnableDisableVmnic",
      Version          => "2" ,
      Tags             => "",
      Summary          => "While VSAN traffic is active on an uplink, ".
      "enable/disable vmnic/uplink, disconnect the NIC from pswitch and ".
      "connect again (check if this host is added back to the VSAN groups list)",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_1,
      'WORKLOADS' => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['RunDT',"DisableEnableVmnic"],
                      # Verify Disk Group to make sure host joined disk group again
                      ['RunDT'],
                      ['VerifyVSANDiskGroup'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "DisableEnableVmnic" => {
            Type             => "Switch",
            Iterations       => STRESS_ITERATIONS,
            TestSwitch       => "vc.[1].vds.[1]",
            SleepBetweenCombos=> "20",
            ConfigureUplinks => "remove,add",
            vmnicadapter     => "host.[1].vmnic.[1]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'PVLAN' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "PVLAN",
      Version          => "2" ,
      Tags             => "PhysicalSetup,Topology_3",
      Summary          => 'Verify VSAN network configured with PVLAN on VDS',
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      'WORKLOADS' => {
        Sequence => [
                      ['AddPVLAN_P'],
                      ['AddPVLAN_I'],
                      ['AddPVLAN_C'],
                      ['SetPVLAN_P'],
                      ['SetPVLAN_I'],
                      ['SetPVLAN_C'],
                      ['ChangevmknicPortgroup1'],
                      ['ChangevmknicPortgroup2'],
                      ['ChangevmknicPortgroup3'],
                      ['SetAutoIP'],
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      # Verify disk group
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['RunDT','NetperfTraffic1'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                          ['ResetVmknicPortgroup'],
                         ],

         "SetAutoIP" => {
            Type       => "NetAdapter",
            Testadapter=> "host.[-1].vmknic.[1]",
            ipv4       => 'auto',
         },
         'AddPVLAN_P' => {
           'Type' => 'Switch',
           'TestSwitch' => 'vc.[1].vds.[1]',
           'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
           'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
           'addpvlanmap' => 'promiscuous'
         },
         'AddPVLAN_I' => {
           'Type' => 'Switch',
           'TestSwitch' => 'vc.[1].vds.[1]',
           'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A,
           'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
           'addpvlanmap' => 'isolated'
         },
         'AddPVLAN_C' => {
           'Type' => 'Switch',
           'TestSwitch' => 'vc.[1].vds.[1]',
           'secondaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A,
           'primaryvlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A,
           'addpvlanmap' => 'community'
         },
         'SetPVLAN_P' => {
           'Type' => 'PortGroup',
           'TestPortGroup' => 'vc.[1].dvportgroup.[2]',
           'vlantype' => 'pvlan',
           'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_PRI_A
         },
         'SetPVLAN_I' => {
           'Type' => 'PortGroup',
           'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
           'vlantype' => 'pvlan',
           'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_ISO_A
         },
         'SetPVLAN_C' => {
           'Type' => 'PortGroup',
           'TestPortGroup' => 'vc.[1].dvportgroup.[4]',
           'vlantype' => 'pvlan',
           'vlan' => VDNetLib::Common::GlobalConfig::VDNET_PVLAN_SEC_COM_A
         },
         'ResetVmknicPortgroup' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[1-3].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'vc.[1].dvportgroup.[1]'
         },
         'ChangevmknicPortgroup1' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[1].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'vc.[1].dvportgroup.[2]'
         },
         'ChangevmknicPortgroup2' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[2].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'vc.[1].dvportgroup.[4]'
         },
         'ChangevmknicPortgroup3' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[3].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'vc.[1].dvportgroup.[4]'
         },
         'ChangevNICPortgroup1' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'vm.[1].vnic.[1]',
           'reconfigure' => 'true',
           'portgroup' => 'vc.[1].dvportgroup.[2]'
         },
         'ChangevNICPortgroup2' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'vm.[2].vnic.[1]',
           'reconfigure' => 'true',
           'portgroup' => 'vc.[1].dvportgroup.[3]'
         },
         'ChangevNICPortgroup3' => {
           'Type' => 'NetAdapter',
           'TestAdapter' => 'vm.[3].vnic.[1]',
           'reconfigure' => 'true',
           'portgroup' => 'vc.[1].dvportgroup.[4]'
         },
         'NetperfTraffic1' => {
           'Type' => 'Traffic',
           'noofoutbound' => '1',
           'l4protocol' => 'tcp',
           'testduration' => '60',
           'toolname' => 'netperf'
         },
         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      }
   },

   'NetIORM'   => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "NetIORM",
      Version          => "2" ,
      Tags             => "Topology_3",
      Summary          => "Verify VSAN network configured with NetIORM Load Balancing ".
      "(Route based on physical NIC load)",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      WORKLOADS => {
         Sequence => [
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['EnableNIOC'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['RunDT'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ['DisableVSANonCluster'],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup" => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "DeleteAllVMs" => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableHAonVSANCluster" => {
            Type => "Cluster",
            TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
            EditCluster => "edit",
            ha   => 0,
         },

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
         SetVMReservation => {
            Type       => "Switch",
            TestSwitch => "vc.[1].vds.[1]",
            niocinfrastructuretraffic  => {
               'virtualMachine' => "50:100:500",
            },
         },
         EditReservation => {
            Type        => "NetAdapter",
            TestAdapter => "vm.[1].vnic.[1]",
            reconfigure => "true",
            reservation => "100",
            portgroup   => "vc.[1].dvportgroup.[1]",
         },
         VerifyPlacementPos => {
            Type         => "NetAdapter",
            TestAdapter  => "vm.[1].vnic.[1]",
            nicplacement => "1",
         },
         VerifyPlacementNeg => {
            Type         => "NetAdapter",
            TestAdapter  => "vm.[1].vnic.[1]",
            nicplacement => "0",
         },
         EnableNIOC => {
            Type       => "Switch",
            TestSwitch => "vc.[1].vds.[1]",
            nioc  => "enable",
         },
         DisableNIOC => {
            Type       => "Switch",
            TestSwitch => "vc.[1].vds.[1]",
            nioc  => "disable",
         },
      },
   },

   'Teaming-SourceMAC' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "Teaming-SourceMAC",
      Version          => "2" ,
      Tags             => "Topology_3,PR1357500",
      Summary          => "Test the VSAN configured network with teaming ".
      "feature - Load Balancing (Route based on source MAC address) of VDS.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      'WORKLOADS' => {
         Sequence => [
                      ['AddMoreUplinksToVDS'],
                      ['ConfigureTeamingPolicy'],
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ["GetDHCPIP"],
                      ['NetperfTestAllVMs','RunDT'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["RemoveUplinksFromVDS"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "AddMoreUplinksToVDS" => {
            Type           => "Switch",
            TestSwitch     => "vc.[1].vds.[1]",
            configureuplinks=> "add",
            vmnicadapter   => "host.[1-3].vmnic.[2]",
         },

         "ConfigureTeamingPolicy" => {
            Type           => 'Switch',
            TestSwitch     => 'vc.[1].vds.[1]',
            failback       => 'yes',
            lbpolicy       => "loadbalance_srcmac",
            notifyswitch   => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
         },

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "RemoveUplinksFromVDS" => {
            Type           => "Switch",
            TestSwitch     => "vc.[1].vds.[1]",
            configureuplinks=> "remove",
            vmnicadapter   => "host.[1-3].vmnic.[2]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },
   'Teaming-IPHash' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "Teaming-IPHash",
      Version          => "2" ,
      Tags             => "Topology_3",
      Summary          => "Test the VSAN network configured with teaming " .
      "feature Load Balancing (Route based on IP hash) of VDS",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      'WORKLOADS' => {
         Sequence => [
                      ['AddMoreUplinksToVDS'],
                      ['ConfigureTeamingPolicy'],
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['GetDHCPIP'],
                      ['NetperfTestAllVMs','RunDT'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["RemoveUplinksFromVDS"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "AddMoreUplinksToVDS" => {
            Type           => "Switch",
            TestSwitch     => "vc.[1].vds.[1]",
            configureuplinks=> "add",
            vmnicadapter   => "host.[1-3].vmnic.[2]",
         },

         "ConfigureTeamingPolicy" => {
            Type           => 'Switch',
            TestSwitch     => 'vc.[1].vds.[1]',
            failback       => 'yes',
            lbpolicy       => "loadbalance_ip",
            notifyswitch   => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
         },
         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "RemoveUplinksFromVDS" => {
            Type           => "Switch",
            TestSwitch     => "vc.[1].vds.[1]",
            configureuplinks=> "remove",
            vmnicadapter   => "host.[1-3].vmnic.[2]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'MigrateVmkInterfaceVssToVDS' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "MigrateVmkInterfaceVssToVDS",
      Version          => "2" ,
      Tags             => "Topology_3",
      Summary          => "Verify that migrating vmkernel interface from VSS ".
      "to VDS and vice-versa will not impact on VSAN operation.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      'WORKLOADS' => {
         Sequence => [
                      ['CreateVSSallHosts'],
                      ['CreatePortGroup1'],
                      ['CreatePortGroup2'],
                      ['CreatePortGroup3'],
                      ['MigrateHost1VmkToVSS'],
                      ['MigrateHost2VmkToVSS'],
                      ['MigrateHost3VmkToVSS'],
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      # Verify disk group
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['GetDHCPIP'],
                      ['NetperfTestAllVMs','RunDT'],
                      ['MigrateAllHostVmkToVDS'],
                      # Verify disk group
                      ['VerifyVSANDiskGroup'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ['DeleteHost1VSSandPortgroup'],
                          ['DeleteHost2VSSandPortgroup'],
                          ['DeleteHost3VSSandPortgroup'],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                         ],

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         'MigrateHost1VmkToVSS' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[1].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'host.[1].portgroup.[1]'
         },
         'MigrateHost2VmkToVSS' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[2].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'host.[2].portgroup.[1]'
         },
         'MigrateHost3VmkToVSS' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[3].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'host.[3].portgroup.[1]'
         },
         'MigrateAllHostVmkToVDS' => {
           'Type'        => 'NetAdapter',
           'TestAdapter' => 'host.[1-3].vmknic.[1]',
           'reconfigure' => 'true',
           'portgroup'   => 'vc.[1].dvportgroup.[1]'
         },
         "DeleteHost1VSSandPortgroup" => {
            Type            => "Host",
            Testhost        => "host.[1]",
            deletevss       => "host.[1].vss.[1]",
            deleteportgroup => "host.[1].portgroup.[1]",
         },
         "DeleteHost2VSSandPortgroup" => {
            Type            => "Host",
            Testhost        => "host.[2]",
            deletevss       => "host.[2].vss.[1]",
            deleteportgroup => "host.[2].portgroup.[1]",
         },
         "DeleteHost3VSSandPortgroup" => {
            Type            => "Host",
            Testhost        => "host.[3]",
            deletevss       => "host.[3].vss.[1]",
            deleteportgroup => "host.[3].portgroup.[1]",
         },
         "CreateVSSallHosts" => {
            Type            => "Host",
            Testhost        => "host.[1-3]",
            'vss' => {
               '[1]' => {
                  'configureuplinks' => 'add',
                  'vmnicadapter' => 'host.[x=host_index].vmnic.[2]'
               },
            },
         },
         "CreatePortGroup1" => {
            Type            => "Host",
            Testhost        => "host.[1]",
            'portgroup' => {
               '[1]' => {
                  'vss' => 'host.[1].vss.[1]',
                  'vlantype' => 'access',
                  'vlan' => '16',
               },
            },
         },
         "CreatePortGroup2" => {
            Type            => "Host",
            Testhost        => "host.[2]",
            'portgroup' => {
               '[1]' => {
                  'vss' => 'host.[2].vss.[1]',
                  'vlantype' => 'access',
                  'vlan' => '16',
               },
            },
         },
         "CreatePortGroup3" => {
            Type            => "Host",
            Testhost        => "host.[3]",
            'portgroup' => {
               '[1]' => {
                  'vss' => 'host.[3].vss.[1]',
                  'vlantype' => 'access',
                  'vlan' => '16',
               },
            },
         },
         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "vMotionVM1ToHost2" => {
            Type            => "VM",
            TestVM          => "vm.[1]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[2]",
         },
         "vMotionVM2ToHost3" => {
            Type            => "VM",
            TestVM          => "vm.[2]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[3]",
         },
         "vMotionVM3ToHost1" => {
            Type            => "VM",
            TestVM          => "vm.[3]",
            Iterations      => "1",
            vmotion         => "oneway",
            dsthost         => "host.[1]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },

   'LACP-NetIOC' => {
      Category         => 'VSAN',
      Component        => 'Unknown',
      TestName         => "LACP-NetIOC",
      Version          => "2" ,
      Tags             => "PhysicalSetup,Topology_3",
      Summary          => "Verify VSAN works consistently on LACP and NetIOC".
      " configured network.",
      TestbedSpec      => $TDS::EsxServer::VSAN::TestbedSpec::Topology_3,
      'WORKLOADS' => {
         Sequence => [
                      ['CreateLAGv2'],
                      ['CreatePswitchPortHost1'],
                      ['CreatePswitchPortHost2'],
                      ['CreatePswitchPortHost3'],
                      ['AddUplinkToLAG'],
                      ['ConfigureChannelGroupForHost1'],
                      ['ConfigureChannelGroupForHost2'],
                      ['ConfigureChannelGroupForHost3'],
                      ['SetActiveUplink'],
                      ['CheckUplinkStateAllHosts'],
                      ['EnableVmknicVSAN'],
                      ['EnableVSANonCluster'],
                      ['JoinDiskGroup'],
                      ['VerifyVSANDiskGroup'],
                      ['CreateVM1onVSAN','CreateVM2onVSAN','CreateVM3onVSAN'],
                      ['GetDHCPIP'],
                      ['NetperfTestAllVMs','RunDT'],
                     ],
         ExitSequence => [
                          ["DeleteAllVMs"],
                          ["LeaveDiskGroup"],
                          ["DisableVSANonCluster"],
                          ["RemoveUplinksFromLAG"],
                          ["RemovePortsFromChannelGroup"],
                          ['ReSetActiveUplink'],
                          ["DeleteLAG"],
                          ['AddUplinkBackToVDS'],
                         ],

         "GetDHCPIP" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[-1].vnic.[1]",
            ipv4       => 'dhcp',
         },

         "CreateLAGv2" => {
            Type            => "Switch",
            TestSwitch      => "vc.[1].vds.[1]",
            'lag' => {
               '[1]' => {
                  lacpversion => "multiplelag",
               },
            },
         },
         "DeleteLAG" => {
            Type            => "Switch",
            TestSwitch      => "vc.[1].vds.[1]",
            'deletelag'     => "vc.[1].vds.[1].lag.[1]",
         },
         "AddUplinkToLAG" => {
            Type            => "LACP",
            TestLag         => "vc.[1].vds.[1].lag.[1]",
            configuplinktolag => "add",
            vmnicadapter    => "host.[-1].vmnic.[1-2]",
         },
         "SetActiveUplink" => {
            Type          => "PortGroup",
            TestPortgroup => "vc.[1].dvportgroup.[1]",
            failoverorder => "vc.[1].vds.[1].lag.[1]",
            failovertype  => "active",
         },
         "ReSetActiveUplink" => {
            Type          => "PortGroup",
            TestPortgroup => "vc.[1].dvportgroup.[1]",
            failoverorder => "uplink[1-4]",
            failovertype  => "active",
         },
         "CheckUplinkStateAllHosts" => {
            Type            => "LACP",
            TestLag         => "vc.[1].vds.[1].lag.[1]",
            sleepbetweenworkloads => "120",
            checkuplinkstate => "Bundled",
            vmnicadapter    => "host.[-1].vmnic.[-1]",
         },
         "CreatePswitchPortHost1" => {
            Type            => "Host",
            Testhost        => "host.[1]",
            pswitchport => {
               '[1]'     => {
                  vmnic => "host.[1].vmnic.[1]",
               },
               '[2]'     => {
                  vmnic => "host.[1].vmnic.[2]",
               },
            },
         },
         "CreatePswitchPortHost2" => {
            Type            => "Host",
            Testhost        => "host.[2]",
            pswitchport => {
               '[1]'     => {
                  vmnic => "host.[2].vmnic.[1]",
               },
               '[2]'     => {
                  vmnic => "host.[2].vmnic.[2]",
               },
            },
         },
         "CreatePswitchPortHost3" => {
            Type            => "Host",
            Testhost        => "host.[3]",
            pswitchport => {
               '[1]'     => {
                  vmnic => "host.[3].vmnic.[1]",
               },
               '[2]'     => {
                  vmnic => "host.[3].vmnic.[2]",
               },
            },
         },
         "ConfigureChannelGroupForHost1" => {
            Type            => "Port",
            TestPort        => "host.[1].pswitchport.[-1]",
            configurechannelgroup =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            Mode            => "Active",
         },
         "ConfigureChannelGroupForHost2" => {
            Type            => "Port",
            TestPort        => "host.[2].pswitchport.[-1]",
            configurechannelgroup =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            Mode            => "Active",
         },
         "ConfigureChannelGroupForHost3" => {
            Type            => "Port",
            TestPort        => "host.[3].pswitchport.[-1]",
            configurechannelgroup =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C,
            Mode            => "Active",
         },
         "RemovePortsFromChannelGroup" => {
            Type            => "Port",
            TestPort        => "host.[-1].pswitchport.[-1]",
            configurechannelgroup => "no",
         },
         "DeleteChannelGroup1" => {
            Type                 => "Switch",
            TestSwitch           => "pswitch.[-1]",
            removeportchannel    =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
         },
         "DeleteChannelGroup2" => {
            Type                 => "Switch",
            TestSwitch           => "pswitch.[-1]",
            removeportchannel    =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
         },
         "DeleteChannelGroup3" => {
            Type                 => "Switch",
            TestSwitch           => "pswitch.[-1]",
            removeportchannel    =>
                       VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C,
         },
         "EnableVmknicVSAN" => ALL_HOST_ENABLE_VSAN_VMKNIC1,

         "EnableVSANonCluster" => ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1,

         "JoinDiskGroup"   => ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP,

         "VerifyVSANDiskGroup" => ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP,

         "CreateVM1onVSAN" => CREATE_VM1_VSAN_DATASTORE_HOST1,

         "CreateVM2onVSAN" => CREATE_VM2_VSAN_DATASTORE_HOST2,

         "CreateVM3onVSAN" => CREATE_VM3_VSAN_DATASTORE_HOST3,

         "RunDT" => RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC,

         "AddUplinkBackToVDS" => {
            Type           => "Switch",
            TestSwitch     => "vc.[1].vds.[1]",
            configureuplinks=> "add",
            vmnicadapter   => "host.[1-3].vmnic.[1]",
         },

         "ConfigureTeamingPolicy" => {
            Type           => 'Switch',
            TestSwitch     => 'vc.[1].vds.[1]',
            failback       => 'yes',
            lbpolicy       => "loadbalance_ip",
            notifyswitch   => 'yes',
            confignicteaming => 'vc.[1].dvportgroup.[1]'
         },
         "NetperfTestAllVMs" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2-3].vnic.[1]",
            NoofOutbound   => 1,
            NoofOutbound   => 1,
            TestDuration   => "60",
         },

         "RemoveUplinksFromLAG" => {
            Type            => "LACP",
            TestLag         => "vc.[1].vds.[1].lag.[1]",
            configuplinktolag => "remove",
            vmnicadapter    => "host.[-1].vmnic.[1-2]",
         },

         "DeleteAllVMs"   => REMOVE_ALL_VMs,

         "LeaveDiskGroup" => ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP,

         "DisableVSANonCluster" => DISABLE_VSAN_AUTOCLAIM_CLUSTER1,
      },
   },
);
}


#######################################################################
#
# new --
#       This is the constructor for VDS.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDS class.
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
   my $self = $class->SUPER::new(\%VSAN);
   return (bless($self, $class));
}



