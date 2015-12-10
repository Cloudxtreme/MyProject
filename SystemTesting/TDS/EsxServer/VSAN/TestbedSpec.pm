########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::EsxServer::VSAN::TestbedSpec;

# All vMotion HA xVMotion StorageVMotion based tests
$Topology_1 = {
   'host' => {
      '[1]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
            },
         },
      },
      '[2]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
            },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1]'   => {
               driver => "any",
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
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
                     host => "host.[1-3]",
                     name => "VSAN-Cluster-$$",
                     vsan => 1,
                     autoclaimstorage => 0,
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-3]",
               vmnicadapter   => "host.[1-3].vmnic.[1]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1-3]'   => {
               vds      => "vc.[1].vds.[1]",
            },
         },
      },
   },
};


# All Teaming
# PVALN NetIORM etc based tests
$Topology_3 = {
   'host' => {
      '[1]'   => {
         vmnic => {
            '[1-2]'   => {
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
            },
         },
      },
      '[2]'   => {
         vmnic => {
            '[1-2]'   => {
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
            },
         },
      },
      '[3]'   => {
         vmnic => {
            '[1-2]'   => {
            },
         },
         vmknic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               configurevmotion => "enable",
               vsan => "enable",
               ipv4 => "dhcp",
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
                     host => "host.[1-3]",
                     name => "VSAN-Cluster-$$",
                     vsan => 1,
                     autoclaimstorage => 0,
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-3]",
               vmnicadapter   => "host.[1-3].vmnic.[1]",
               nioc => 'enable',
               version => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
               niocversion => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "50:100:500",
                  'iSCSI'          => "100:100:500",
                  'vmotion'        => "100:100:500",
                  'nfs'            => "100:100:500",
                  'hbr'            => "100:100:500",
                  'vsan'           => "100:100:500",
               },
            },
         },
         dvportgroup  => {
            '[1]'   => {
               vds      => "vc.[1].vds.[1]",
            },
           '[2]' => {
             'ports' => 2,
             'name' => 'dvpg_p_170_170',
             'binding' => undef,
             'nrp' => undef,
             'vds' => 'vc.[1].vds.[1]',
           },
           '[3]' => {
             'ports' => 2,
             'name' => 'dvpg_i_170_171',
             'binding' => undef,
             'nrp' => undef,
             'vds' => 'vc.[1].vds.[1]',
           },
           '[4]' => {
             'ports' => undef,
             'name' => 'dvpg_c_170_173',
             'binding' => undef,
             'nrp' => undef,
             'vds' => 'vc.[1].vds.[1]',
           },
         },
      },
   },
};
1;

