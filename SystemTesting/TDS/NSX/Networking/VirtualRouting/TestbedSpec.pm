
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::NSX::Networking::VirtualRouting::TestbedSpec;
# A Master testbedspec of VDR Setup with Two VDSes, Five Hosts, Four clusters
$OneVC_OneDC_TwoVDS_FourClusters_FiveHost_SevenVMs = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => 'vc.[1]',
         assignrole => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength => "yy",
               ipranges     => ['a.a.a.a-b.b.b.b'],
            },
         },
         vxlancontroller  => {
            '[1]' => {
               name         => "AutoGenerate",
               ippool       => "vsm.[1].ippool.[1]",
               resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
               host         => "host.[1]",
            },
      },
         VDNCluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => [18],
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => VDNetLib::TestData::TestConstants::ARRAY_VXLAN_CONFIG_TEAMING_POLICIES,
            },
            '[2]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[3]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => "18",
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
            '[3]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[4]",
               vibs         => "install",
               switch       => "vc.[1].vds.[2]",
               vlan         => "19",
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "FAILOVER_ORDER",
            },
   },
         segmentidrange => {
            '[1]' => {
               name  => "AutoGenerate",
               begin => "10000",
               end   => "19000",
            },
         },
         multicastiprange => {
            '[1]' => {
               name  => "AutoGenerate",
               begin => "239.1.1.1",
               end   => "239.1.1.100",
            },
         },
},
},
   'host' => {
      '[1]'  => {
      },
      '[2-5]'   => {
         vmnic => {
            '[1-2]'   => {
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
                     name => "Controller-Cluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2-3]",
                     name => "Compute-Cluster-SJC-$$",
                  },
                  '[3]' => {
                     host => "host.[4]",
                     name => "Compute-Cluster-SFO-$$",
                  },
                  '[4]' => {
                     host => "host.[5]",
                     name => "Compute-Cluster-LAX-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               name           => "VDS-1-$$",
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[2-4]",
               vmnicadapter   => "host.[2-4].vmnic.[1]",
               numuplinkports => "1",
            },
            '[2]'   => {
               name           => "VDS-2-$$",
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[5]",
               vmnicadapter   => "host.[5].vmnic.[1]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-VDS1-vlan16-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "16",
               vlantype => "access",
            },
            '[2]'   => {
               name     => "dvpg-VDS-vlan17-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "17",
               vlantype => "access",
            },
            '[3]'   => {
               name     => "dvpg-VDS1-vlan18-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "18",
               vlantype => "access",
            },
            '[4]'   => {
               name     => "dvpg-VDS1-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "19",
               vlantype => "access",
            },
            '[5]'   => {
               name     => "dvpg-VDS1-vlan21-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "21",
               vlantype => "access",
            },
            '[6]'   => {
               name     => "dvpg-VDS1-vlan22-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "22",
               vlantype => "access",
            },
            '[7]'   => {
               name     => "dvpg-VDS2-vlan16-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "16",
               vlantype => "access",
            },
            '[8]'   => {
               name     => "dvpg-VDS2-vlan17-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "17",
               vlantype => "access",
            },
            '[9]'   => {
               name     => "dvpg-VDS2-vlan18-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "18",
               vlantype => "access",
            },
            '[10]'   => {
               name     => "dvpg-VDS2-vlan19-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "19",
               vlantype => "access",
            },
            '[11]'   => {
               name     => "dvpg-VDS2-vlan21-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "21",
               vlantype => "access",
            },
            '[12]'   => {
               name     => "dvpg-VDS2-vlan22-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "22",
               vlantype => "access",
            },
         },
      },
   },
   vm  => {
      '[1]'   => {
         'datastoreType' => 'shared',
         host            => "host.[2]",
         vmstate         => "poweroff",
      },
      '[2]'   => {
         'datastoreType' => 'shared',
         host            => "host.[3]",
         vmstate         => "poweroff",
      },
      '[3]'   => {
         'datastoreType' => 'shared',
         host            => "host.[4]",
         vmstate         => "poweroff",
      },
      '[4]'   => {
         'datastoreType' => 'shared',
         host            => "host.[5]",
         vmstate         => "poweroff",
      },
      '[5]'   => {
         'datastoreType' => 'shared',
         host            => "host.[2]",
         vmstate         => "poweroff",
      },
      '[6]'   => {
         'datastoreType' => 'shared',
         host            => "host.[3]",
         vmstate         => "poweroff",
      },
      '[7]'   => {
         'datastoreType' => 'shared',
         host            => "host.[4]",
         vmstate         => "poweroff",
      },
   },
};


$OneVC_OneDC_OneVDS_TwoCluster_ThreeHost_TenVMs = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => 'vc.[1]',
         assignrole => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength => "yy",
               ipranges     => ['a.a.a.a-b.b.b.b'],
            },
         },
         vxlancontroller  => {
            '[1]' => {
               name         => "AutoGenerate",
               ippool       => "vsm.[1].ippool.[1]",
               resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
               host         => "host.[1]",
            },
         },
         VDNCluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => [21],
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => VDNetLib::TestData::TestConstants::ARRAY_VXLAN_CONFIG_TEAMING_POLICIES,
      },
   },
         segmentidrange => {
            '[1]' => {
               name  => "AutoGenerate",
               begin => "10000",
               end   => "19000",
            },
         },
         multicastiprange => {
            '[1]' => {
               name  => "AutoGenerate",
               begin => "239.1.1.1",
               end   => "239.1.1.100",
            },
         },
 },
},
   'host' => {
      '[1]'  => {
      },
      '[2-3]'   => {
         vmnic => {
            '[1-2]'   => {
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
               name     => "dvpg-vlan21-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "21",
               vlantype => "access",
            },
         },
      },
   },
   vm  => {
      '[1-8]'   => {
         host            => "host.[2]",
         vmstate         => "poweroff",
         'datastoreType' => 'shared',
      },
   },
   dhcpserver => {
       '[1-2]'  => {
       }
   }
};

1;
