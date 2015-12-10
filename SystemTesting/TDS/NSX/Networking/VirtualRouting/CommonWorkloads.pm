#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VirtualRouting::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use VDNetLib::TestData::TestConstants;

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'SEGMENTID_RANGE',
   'SET_SEGMENTID_RANGE',
   'SET_MULTICAST_RANGE',
   'INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1',
   'INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC2_VDS1',
   'INSTALLVIBS_CONFIGUREVXLAN_ClusterSFO_VDS2_VLAN22_MTU9000_FAILOVER_VMKNIC4',
   'DEPLOY_FIRSTCONTROLLER',
   'DEPLOY_SECONDCONTROLLER',
   'DEPLOY_THIRDCONTROLLER',
   'CREATE_NETWORKSCOPE_ClusterSJC',
   'CREATE_VIRTUALWIRES_NETWORKSCOPE1',
   'DELETE_ALL_VIRTUALWIRES',
   'DELETE_ALL_NETWORKSCOPES',
   'DELETE_ALL_EDGES',
   'DELETE_ALL_CONTROLLERS',
   'UNINSTALL_UNCONFIGURE_ALL_VDNCLUSTER',
   'RESET_SEGMENTID',
   'RESET_MULTICASTRANGE',
   'DELETE_ALL_IPPOOLS',
   'VDR_ONE_VDS_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGETHERCHANNEL_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGLACP_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGSRCMAC_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGSRCID_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGLOADBASED_TESTBEDSPEC',
   'VDR_ONE_VDS_TEAMINGFAILOVER_TESTBEDSPEC',
   'VDR_ONE_VDSTEAMING_FAILOVER_MULTIPLEVTEP_TESTBEDSPEC',
   'VDR_ONE_VDS_TRANSPORTVLAN_TESTBEDSPEC',
   'VDR_TWO_VDS_TESTBEDSPEC',
   'CREATEVXLANLIF1',
   'CREATEVXLANLIF2',
   'CREATEVXLANLIF3',
   'CREATEVXLANLIF4',
   'CREATEVLANLIF1',
   'CREATEVLANLIF2',
   'CREATEVLANLIF3',
   'UNCONFIGUREVXLAN_ClusterSJC_VDS1',
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant SEGMENTID_RANGE => {
   '[1]' => {
      name  => "AutoGenerate",
      begin => "5001-10001",
      end   => "99000",
   },
};

use constant SET_SEGMENTID_RANGE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   segmentidrange => SEGMENTID_RANGE,
};

use constant SET_MULTICAST_RANGE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   Multicastiprange => {
      '[1]' => {
         name  => "AutoGenerate",
         begin => "239.0.0.101",
         end   => "239.254.254.254",
      },
   },
};


use constant DEPLOY_FIRSTCONTROLLER => {
   Type       => "NSX",
   TestNSX    => "vsm.[1]",
   vxlancontroller  => {
      '[1]' => {
         name         => "AutoGenerate",
         firstnodeofcluster => "true",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
         host         => "host.[1]",
      },
   },
};

use constant DEPLOY_SECONDCONTROLLER => {
   Type       => "NSX",
   TestNSX    => "vsm.[1]",
   vxlancontroller  => {
      '[2]' => {
         name         => "AutoGenerate",
         firstnodeofcluster => "true",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
         host         => "host.[1]",
      },
   },
};

use constant DEPLOY_THIRDCONTROLLER => {
   Type       => "NSX",
   TestNSX    => "vsm.[1]",
   vxlancontroller  => {
      '[3]' => {
         name         => "AutoGenerate",
         firstnodeofcluster => "true",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
         host         => "host.[1]",
      },
   },
};

use constant INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1 => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
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
};

use constant INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC2_VDS1 => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   VDNCluster => {
      '[2]' => {
         cluster      => "vc.[1].datacenter.[1].cluster.[3]",
         vibs         => "install",
         switch       => "vc.[1].vds.[1]",
         vlan         => [21],
         mtu          => "1600",
         vmkniccount  => "1",
         teaming      => VDNetLib::TestData::TestConstants::ARRAY_VXLAN_CONFIG_TEAMING_POLICIES,
      },
   },
};

use constant INSTALLVIBS_CONFIGUREVXLAN_ClusterSFO_VDS2_VLAN22_MTU9000_FAILOVER_VMKNIC4 => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   VDNCluster => {
      '[2]' => {
         cluster      => "vc.[1].datacenter.[1].cluster.[3]",
         vibs         => "install",
         switch       => "vc.[1].vds.[2]",
	 vlan         => "22",
         mtu          => "1600",
         vmkniccount  => "1",
         #teaming      => "ETHER_CHANNEL",
         # Use 4 and FAILOVER_ORDER after PR 1082963 is fixed
         #mtu          => "9000",
         #vmkniccount  => "4",
         teaming      => "FAILOVER_ORDER",
      },
   },
};

use constant UNCONFIGUREVXLAN_ClusterSJC_VDS1 => {
   Type             => 'Cluster',
   testcluster      => "vsm.[1].vdncluster.[1]",
   vxlan            => "unconfigure",
};

use constant CREATE_NETWORKSCOPE_ClusterSJC => {
   Type         => "NSX",
   TestNSX      => "vsm.[1]",
   networkscope => {
      '[1]' => {
         name         => "network-scope-1-$$",
         clusters     => "vc.[1].datacenter.[1].cluster.[2]",
      },
   },
};

use constant CREATE_VIRTUALWIRES_NETWORKSCOPE1 => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[1]",
   VirtualWire       => {
      "[1]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "HYBRID_MODE",
      },
      "[2]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "UNICAST_MODE",
      },
      "[3]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "MULTICAST_MODE",
      },
      "[4-8]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
      },
   },
};

use constant DELETE_ALL_VIRTUALWIRES => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[-1]",
   deletevirtualwire => "vsm.[1].networkscope.[-1].virtualwire.[-1]",
};

use constant DELETE_ALL_NETWORKSCOPES => {
   Type              => "NSX",
   TestNSX           => "vsm.[1]",
   deletenetworkscope=> "vsm.[1].networkscope.[-1]",
};

use constant DELETE_ALL_EDGES => {
   Type       => "NSX",
   TestNSX    => "vsm.[1]",
   deletevse  => "vsm.[1].vse.[-1]",
};

use constant DELETE_ALL_CONTROLLERS => {
   Type                 => "NSX",
   TestNSX              => "vsm.[1]",
   deletevxlancontroller=> "vsm.[1].vxlancontroller.[-1]",
};

use constant RESET_SEGMENTID => {
   Type                  => "NSX",
   TestNSX               => "vsm.[1]",
   deletesegmentidrange  => "vsm.[1].segmentidrange.[-1]",
};

use constant RESET_MULTICASTRANGE => {
   Type                  => "NSX",
   TestNSX               => "vsm.[1]",
   deletemulticastiprange=> "vsm.[1].multicastiprange.[-1]",
};

use constant UNINSTALL_UNCONFIGURE_ALL_VDNCLUSTER => {
   Type                 => "NSX",
   TestNSX              => "vsm.[1]",
   deletevdncluster     => "vsm.[1].vdncluster.[-1]",
};

use constant DELETE_ALL_IPPOOLS => {
   Type                 => "NSX",
   TestNSX              => "vsm.[1]",
   deleteippool         => "vsm.[1].ippool.[-1]",
};

use constant VDR_ONE_VDS_TESTBEDSPEC => {
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
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
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
               name     => "dvpg-vlan18-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "18",
               vlantype => "access",
            },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host            => "host.[2]",
         vmstate         => "poweroff",
      },
      '[3-4]' => {
         host => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

use constant VDR_ONE_VDS_TEAMINGETHERCHANNEL_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength          => "xx",
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
               name  => "Autogenerate",
               begin => "239.1.1.1",
               end   => "239.1.1.100",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "ETHER_CHANNEL",
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
      '[2]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      },
      '[3]' => {
          vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      },
   },
   vc =>  $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   vm  => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TEAMINGLACP_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         assignrole  => "enterprise_admin",
         vc          => "vc.[1]",
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
               resourcepool => "vc.[1].datacenter.[1].cluster.[2]",
               host         => "host.[2]",
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
      },
   },
   'host' => {
      '[1]'  => {
      },
      '[2]'   => {
         vmnic => {
            '[1-3]'   => {
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
            '[3]'     => {
               vmnic => "host.[2].vmnic.[3]",
            },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1-3]'   => {
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
            '[3]'     => {
               vmnic => "host.[3].vmnic.[3]",
            },
         },
      },
   },
   pswitch => {
      '[1]' => {
         ip => "None",
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
               vmnicadapter   => "host.[2-3].vmnic.[1-3]",
               lag => {
                  '[1]' => {
                     hosts => "host.[2-3]",
                  },
               },
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            '[2]'   => {
               name     => "dvpg-vlan16-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "16",
               vlantype => "access",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            '[3]'   => {
               name     => "dvpg-vlan17-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "17",
               vlantype => "access",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            '[4]'   => {
               name     => "dvpg-vlan21-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "21",
               vlantype => "access",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
         },
      },
    },
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TEAMINGSRCMAC_TESTBEDSPEC => {
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
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "3",
               teaming      => "LOADBALANCE_SRCMAC",
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TEAMINGSRCID_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole => "enterprise_admin",
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
               name  => "multicastip-range-$$",
               begin => "239.1.1.0",
               end   => "239.1.1.100",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "3",
               teaming      => "LOADBALANCE_SRCID",
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TEAMINGLOADBASED_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole => "enterprise_admin",
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
               name  => "multicastip-range-$$",
               begin => "239.1.1.0",
               end   => "239.1.1.100",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "3",
               teaming      => "LOADBALANCE_LOADBASED",
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TEAMINGFAILOVER_TESTBEDSPEC => {
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
               name  => "multicastip-range-$$",
               begin => "239.1.1.100",
               end   => "239.254.254.254",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDSTEAMING_FAILOVER_MULTIPLEVTEP_TESTBEDSPEC => {
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
               name  => "multicastip-range-$$",
               begin => "239.1.1.1",
               end   => "239.1.1.100",
            },
         },
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "3",
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_ONE_VDS_TRANSPORTVLAN_TESTBEDSPEC => {
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
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
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
      },
      '[2-3]'   => {
         vmnic => {
            '[1-3]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithOneVDSThreeUplinkPorts,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant VDR_TWO_VDS_TESTBEDSPEC => {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterpise_admin",
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
               vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "ETHER_CHANNEL",
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
            '[1-2]'   => {
               driver => "any",
            },
         },
      }
   },
   'vc' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::VCWithTwoVDS,
   'vm' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHostWithThreeVMsEach,
};

use constant CREATEVXLANLIF1 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[1]'   => {
           name        => "lif-vwire1-$$",
           portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.31.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};

use constant CREATEVXLANLIF2 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[2]'   => {
           name        => "lif-vwire2-$$",
           portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.32.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};

use constant CREATEVXLANLIF3 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[3]'   => {
           name        => "lif-vwire3-$$",
           portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.33.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};

use constant CREATEVXLANLIF4 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[4]'   => {
           name        => "lif-vwire4-$$",
           portgroup   => "vsm.[1].networkscope.[1].virtualwire.[4]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.34.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};
use constant CREATEVLANLIF1 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[1]'   => {
           name        => "lif-vlan1-$$",
           portgroup   => "vc.[1].dvportgroup.[1]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.16.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};
use constant CREATEVLANLIF2 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[2]'   => {
           name        => "lif-vlan2-$$",
           portgroup   => "vc.[1].dvportgroup.[2]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.17.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};
use constant CREATEVLANLIF3 => {
    Type   => "VM",
    TestVM => "vsm.[1].vse.[1]",
    lif    => {
       '[3]'   => {
           name        => "lif-vlan3-$$",
           portgroup   => "vc.[1].dvportgroup.[3]",
           type        => "internal",
           connected   => 1,
           addressgroup => [{addresstype => "primary",
                             ipv4address => "172.18.1.1",
                             netmask     => "255.255.0.0",}],
        },
    },
};
1;
