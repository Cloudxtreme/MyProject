########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Networking::VXLAN::TestbedSpec;
use TDS::NSX::Networking::VXLAN::CommonWorkloads ':AllConstants';

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'MAC_FILTER_TESTBEDSPEC',
   'Functional_Topology_1',
   'Functional_Topology_2',
   'Functional_Topology_3',
   'Functional_Topology_4',
   'Functional_Topology_5',
   'Functional_Topology_6',
   'Functional_Topology_7',
   'Functional_Topology_8',
   'Functional_Topology_9',
   'Functional_Topology_10',
   'Functional_Topology_11',
   'Functional_Topology_12',
   'Functional_Topology_13',
   'Functional_Topology_14',
   'Functional_Topology_15',
   'Functional_Topology_16',
   'Functional_Topology_17', # this topology for VXLAN Offload case
   'Functional_Topology_18', # this topology for stateless test
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

#mac filter testbed spec
use constant MAC_FILTER_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength         => "xx",
               ipranges     => ['a.a.a.a-b.b.b.b'],
            },
         },
         vxlancontroller  => {
            '[1]' => {
               name         => "AutoGenerate",
               firstnodeofcluster => "true",
               ippool       => "vsm.[1].ippool.[1]",
               resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
               host         => "host.[1]",
            },
         },
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => {
            '[1]' => {
               name  => "AutoGenerate",
               begin => "239.1.1.1",
               end   => "239.1.1.100",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => "19",
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2]",
            },
         },
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
         vmknic   => {
            '[1]' => {
               portgroup   => "vc.[1].dvportgroup.[1]",
               ipv4address => 'dhcp',
               configurevmotion => "enable",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     name => "Controller-Cluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     name => "Compute-Cluster-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[2-3]",
               vmnicadapter   => "host.[2-3].vmnic.[1]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "20",
               vlantype => "access",
            },
            '[2]'   => {
               name     => "dvpg-vlan16-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "16",
               vlantype => "access",
            },
            '[3]'   => {
               name     => "dvpg-vlan17-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "17",
               vlantype => "access",
            },
            '[4]'   => {
               name     => "dvpg-vlanTrunk1-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "0-4094",
               vlantype => "trunk",
            },
            '[5]' => {
               name => "dvpg-vlanTrunk2-$$",
               vds => "vc.[1].vds.[1]",
               vlan => "0-4094",
               vlantype => "trunk",
            },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host            => "host.[2]",
         vmstate         => "poweroff",
         datastoreType     => "shared",
      },
      '[3-4]' => {
         host => "host.[3]",
         vmstate => "poweroff",
         datastoreType => "shared",
      },
   },
};

#TwoIPPool_FourHosts_TwoCLUSTER_TwoVDS_ThreeController_TwelveVMs
use constant Functional_Topology_1 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
            '[3]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               ippool       => "vsm.[1].ippool.[3]",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               ippool      => "vsm.[1].ippool.[3]",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
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
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[7-9]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[10-12]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
};

#ThreeIPPool_TwoHosts_TwoCluster_TwoVDS_OneController_SixVMs
use constant Functional_Topology_2 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
            '[3]' => IP_POOL,
            '[4]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               ippool       => "vsm.[1].ippool.[3]",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               ippool      => "vsm.[1].ippool.[4]",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3]",
              vmnicadapter => "host.[3].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_FourHosts_FourCluster_TwoVDS_OneDVPG_ThreeController_TwelveVMs
use constant Functional_Topology_3 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[1]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
            '[3]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[4]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "FAILOVER_ORDER",
            },
            '[4]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[5]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-5]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
    },
    'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
                  '[4]' => {
                     host => "host.[4]",
                     clustername => "ComputeCluster3-$$",
                  },
                  '[5]' => {
                     host => "host.[5]",
                     clustername => "ComputeCluster4-$$",
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
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1]",
           },
         },
         'dvportgroup' => {
          '[1]' => {
             'vds' => 'vc.[1].vds.[1]'
          }
        },
      },
    },
    vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[7-9]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[10-12]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_TwoHosts_TwoCluster_TwoVDS_ThreeController_SixVMs
use constant Functional_Topology_4 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "demo-network-scope-$$",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
            '[2]' => {
               name         => "demo-network-scope-$$",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3]",
              vmnicadapter => "host.[3].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_TwoHosts_TwoCluster_TwoVDS_ThreeController_TwoVMs
use constant Functional_Topology_5 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "demo-network-scope-$$",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3]",
              vmnicadapter => "host.[3].vmnic.[1]",
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
};

#OneIPPool_FourHosts_TwoCluster_TwoVDS_ThreeController_TwelveVMs
use constant Functional_Topology_6 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
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
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[7-9]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[10-12]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_FourHosts_OnePswitch_TwoCluster_TwoVDS_ThreeController_EightVMs
use constant Functional_Topology_7 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[2]",
               vibs        => "install",
               switch        => "vc.[1].vds.[1]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu           => "1600",
               vmkniccount => "1",
               teaming     => "LACP_V2",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount   => "4",
               teaming => "LOADBALANCE_SRCID",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[2].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[2].vmnic.[2]",
             },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[3].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[3].vmnic.[2]",
             },
         },
      },
      '[4-5]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2-3]",
              'lag' => {
                  '[1]' => {
                     lagtimeout => "short",
                     hosts => "host.[2-3]",
                     lagports => "2",
                     configuplinktolag => "add",
                     vmnicadapter    => "host.[2-3].vmnic.[1-2]",
                  },
              },
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              numuplinkports => "4",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1-2]",
           },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[3-4]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[5-6]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[7-8]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
   pswitch => {
      '[1]' => {
         ip => "XX.XX.XX.XX",
      },
   },
};

#OneIPPool_FourHosts_TwoPswitch_TwoCluster_TwoVDS_ThreeController_EightVMs
use constant Functional_Topology_8 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[2]",
               vibs        => "install",
               switch        => "vc.[1].vds.[1]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu           => "1600",
               vmkniccount   => "1",
               teaming => "LACP_ACTIVE",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "LACP_PASSIVE",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[2].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[2].vmnic.[2]",
             },
         },
      },
     '[3]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[3].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[3].vmnic.[2]",
             },
         },
      },
      '[4]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[4].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[4].vmnic.[2]",
             },
         },
      },
      '[5]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[5].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[5].vmnic.[2]",
             },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              version    => "5.1.0",
              host => "host.[2-3]",
              vmnicadapter => "host.[2-3].vmnic.[1-2]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              version    => "5.1.0",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1-2]",
           },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[3-4]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[5-6]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[7-8]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
   pswitch => {
      '[1]' => {
         ip => "XX.XX.XX.XX",#host2 and host3 connected physical switch
      },
      '[2]' => {
         ip => "XX.XX.XX.XX",#host4 and host5 connected physical switch
      },
   },
};

#TwoIPPool_TwoHosts_TwoCluster_ThreeVDS_OneDVPG_ThreeController_SixVMs
use constant Functional_Topology_9 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "demo-network-scope-$$",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3]",
              vmnicadapter => "host.[3].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_FourHosts_OneCluster_OneVDS_OneDVPG_ThreeController_FourVMsOnSharedStorage
use constant Functional_Topology_10 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => THREE_CONTROLLERS,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "network-scope-$$",
               clusters     => "vc.[1].datacenter.[1].cluster.[2]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-5]",
                     clustername => "ComputeCluster-$$",
                  },
               },
            },
         },
         dvportgroup => {
            '[1]' => {
              'vds' => 'vc.[1].vds.[1]'
            }
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2-5]",
              vmnicadapter => "host.[2-5].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
      '[2]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
      '[3]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
      '[4]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
   },
};

#OneIPPool_FourHosts_TwoCluster_TwoVDS_ThreeController_FourVMs
use constant Functional_Topology_11 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange   => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_C,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "4",
               teaming     => "LOADBALANCE_SRCMAC",
            },
         },
         networkscope => {
            '[1]' => {
               name        => "AutoGenerate",
               clusters    => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
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
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[4-5]",
              vmnicadapter => "host.[4-5].vmnic.[1]",
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
      '[3]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[4]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_FourHosts_FourCluster_FourVDS_ThreeController_FourVMs
use constant Functional_Topology_12 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange   => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[2]",
               vibs        => "install",
               switch      => "vc.[1].vds.[1]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_B,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_C,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "FAILOVER_ORDER",
            },
            '[3]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[4]",
               vibs        => "install",
               switch      => "vc.[1].vds.[3]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "4",
               teaming     => "LOADBALANCE_SRCMAC",
            },
            '[4]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[5]",
               vibs        => "install",
               switch      => "vc.[1].vds.[4]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_E,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "FAILOVER_ORDER",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-5]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-5]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
                  '[4]' => {
                     host => "host.[4]",
                     clustername => "ComputeCluster3-$$",
                  },
                  '[5]' => {
                     host => "host.[5]",
                     clustername => "ComputeCluster4-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[2]",
               vmnicadapter => "host.[2].vmnic.[1]",
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[3]",
               vmnicadapter => "host.[3].vmnic.[1]",
            },
            '[3]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[4]",
               vmnicadapter => "host.[4].vmnic.[1]",
            },
            '[4]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[5]",
               vmnicadapter => "host.[5].vmnic.[1]",
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
      '[3]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[4]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
};

#OneIPPool_FourHosts_OnePswitch_TwoCluster_TwoVDS_ThreeController_EightVMs_Teaming_FailOver_SRCMAC
use constant Functional_Topology_13 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange   => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[2]",
               vibs        => "install",
               switch      => "vc.[1].vds.[1]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "4",
               teaming     => "LOADBALANCE_SRCMAC",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[2].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[2].vmnic.[2]",
             },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[3].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[3].vmnic.[2]",
             },
         },
      },
      '[4-5]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[2-3]",
               vmnicadapter => "host.[2-3].vmnic.[1-2]",
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[4-5]",
               vmnicadapter => "host.[4-5].vmnic.[1]",
            },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[3-4]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[5-6]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[7-8]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
   pswitch => {
      '[1]' => {
         ip => "XX.XX.XX.XX",
      },
   },
};

#OneIPPool_FourHosts_OnePswitch_TwoCluster_TwoVDS_ThreeController_EightVMs_Teaming_FailOverEtherChanel
use constant Functional_Topology_14 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => FIRST_CONTROLLER,
         segmentidrange   => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[2]",
               vibs        => "install",
               switch      => "vc.[1].vds.[1]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "FAILOVER_ORDER",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[2].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[2].vmnic.[2]",
             },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[3].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[3].vmnic.[2]",
             },
         },
      },
      '[4-5]'   => {
         vmnic => {
            '[1-2]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[4-5]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[2-3]",
               vmnicadapter => "host.[2-3].vmnic.[1-2]",
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[4-5]",
               vmnicadapter => "host.[4-5].vmnic.[1]",
            },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[3-4]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
      '[5-6]'   => {
         host  => "host.[4]",
         vmstate => "poweroff",
      },
      '[7-8]'   => {
         host  => "host.[5]",
         vmstate => "poweroff",
      },
   },
   pswitch => {
      '[1]' => {
         ip => "XX.XX.XX.XX",
      },
   },
};

#OneIPPool_ThreeHosts_TwoCLUSTER_TwoVDS_ThreeController_NineVMs
use constant Functional_Topology_15 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => IP_POOL,
         },
         vxlancontroller  => THREE_CONTROLLERS,
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_C,
               mtu         => "1600",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
           '[0]' => {
             interface => "vmnic0",
           },
        },
      },
      '[2-4]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3-4]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3-4]",
              vmnicadapter => "host.[3-4].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
        '[1]'      => {
           host    => "host.[2]",
           vmstate => "poweroff",
        },
        '[2]'      => {
           host    => "host.[3]",
           vmstate => "poweroff",
        },
        '[3]'      => {
           host    => "host.[4]",
           vmstate => "poweroff",
        },
        '[4]'      => {
           host    => "host.[2]",
           vmstate => "poweroff",
        },
        '[5]'      => {
           host    => "host.[3]",
           vmstate => "poweroff",
        },
        '[6]'      => {
           host    => "host.[4]",
           vmstate => "poweroff",
        },
        '[7]'      => {
           host    => "host.[2]",
           vmstate => "poweroff",
        },
        '[8]'      => {
           host    => "host.[3]",
           vmstate => "poweroff",
        },
        '[9]'      => {
           host    => "host.[4]",
           vmstate => "poweroff",
       },
   },
};
#NoIPPool_TwoHosts_TwoCluster_TwoVDS_NoController_SixVMs
use constant Functional_Topology_16 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         ippool   => {
            '[1]' => IP_POOL,
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               vmkniccount => "1",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
            },
         },
      },
   },
   'host' => {
      '[1]'  => {
         vmnic => {
            '[1]'   => {
               driver => "any",
           },
        },
      },
      '[2-3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[2]",
              vmnicadapter => "host.[2].vmnic.[1]",
              version    => "5.1.0",
           },
           '[2]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[3]",
              vmnicadapter => "host.[3].vmnic.[1]",
              version    => "5.1.0",
           },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};
#NoIPPool_TwoHosts_OneCluster_OneVDS_NoController_TwoVMs
use constant Functional_Topology_17 => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[1]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[1]",
            },
         },
      },
   },
   'host' => {
      '[1]'   => {
         vmnic => {
            '[1]'   => {
               driver => "elxnet",
            },
         },
      },
      '[2]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1-2]",
                     clustername => "ComputeCluster1-$$",
                  },
               },
            },
         },
         vds   => {
           '[1]'   => {
              datacenter => "vc.[1].datacenter.[1]",
              configurehosts => "add",
              host => "host.[1-2]",
              vmnicadapter => "host.[1-2].vmnic.[1]",
           },
         },
      },
   },
   vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vmstate => "poweroff",
      },
      '[2]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
   },
};
use constant Functional_Topology_18 => {
    'vsm' => {
       '[1]' => {
          reconfigure => "true",
          vc          => "vc.[1]",
          assignrole  => "enterprise_admin",
          ippool   => {
             '[1]' => IP_POOL,
          },
          vxlancontroller  => FIRST_CONTROLLER,
          segmentidrange   => SEGMENTID_RANGE,
          multicastiprange => MULTICAST_RANGE,
          vdncluster => {
             '[1]' => {
                cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                vibs         => "install",
                switch       => "vc.[1].vds.[1]",
                vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_C,
                mtu          => "1600",
                vmkniccount  => "1",
                teaming      => "FAILOVER_ORDER",
             },
             '[2]' => {
                cluster     => "vc.[1].datacenter.[1].cluster.[3]",
                vibs        => "install",
                switch      => "vc.[1].vds.[2]",
                vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
                mtu         => "1600",
                vmkniccount => "4",
                teaming     => "LOADBALANCE_SRCMAC",
             },
          },
          networkscope => {
             '[1]' => {
                name        => "AutoGenerate",
                clusters    => "vc.[1].datacenter.[1].cluster.[2-3]",
             },
          },
       },
    },
    'host' => {
       '[1]'  => {
          vmnic => {
             '[1]'   => {
                driver => "any",
            },
         },
       },
       '[2-5]'   => {
          vmnic => {
             '[1]'   => {
                driver => "any",
             },
          },
       },
    },
    'vc' => {
       '[1]' => {
          datacenter  => {
             '[1]'   => {
                foldername => "Profile",
                name => "Profile-test",
                Cluster => {
                   '[1]' => {
                      host => "host.[1]",
                      clustername => "ControllerCluster-$$",
                   },
                   '[2]' => {
                      host => "host.[2-3]",
                      clustername => "Profile-Cluster",
                      allowedexception => ['hostalreadyexists'],
                   },
                   '[3]' => {
                      host => "host.[4-5]",
                      clustername => "ComputeCluster2-$$",
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
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[4-5]",
               vmnicadapter => "host.[4-5].vmnic.[1]",
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
       '[3]'   => {
          host  => "host.[4]",
          vmstate => "poweroff",
       },
       '[4]'   => {
          host  => "host.[5]",
          vmstate => "poweroff",
       },
    },
};

1;

