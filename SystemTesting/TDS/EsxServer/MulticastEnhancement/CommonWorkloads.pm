#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::MulticastEnhancement::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'IGMP1_MCAST_ADDR',
   'IGMP2_MCAST_ADDR',
   'IGMP3_MCAST_ADDR',
   'MLD1_MCAST_ADDR',
   'MLD2_MCAST_ADDR',
   'MLD1_MCAST_VSI_NODE',
   'MLD2_MCAST_VSI_NODE',
   'POWERON_VM1',
   'POWERON_VM2',
   'POWERON_VM3',
   'POWEROFF_VM1',
   'POWEROFF_VM2',
   'POWEROFF_VM3',
   'DELETE_VNIC1_ON_VM1',
   'DELETE_VNIC1_ON_VM2',
   'DELETE_VNIC1_ON_VM3',
   'PLACE_VM1_ON_DVPG1',
   'PLACE_VM2_ON_DVPG1',
   'PLACE_VM3_ON_DVPG1',
   'MCAST_QUIT_ON_VM1',
   'SET_SNOOPING_MODE',
   'SET_LEGACY_MODE',
   'SET_IGMP1_ON_VM1',
   'IGMP1_JOIN_REPORT_ON_VM1',
   'VERIFY_IGMP1_JOIN_ON_VM1',
   'SET_IGMP2_ON_VM1',
   'IGMP2_JOIN_REPORT_ON_VM1',
   'VERIFY_IGMP2_JOIN_ON_VM1',
   'SET_IGMP3_ON_VM1',
   'IGMP3_JOIN_REPORT_ON_VM1',
   'VERIFY_IGMP3_JOIN_ON_VM1',
   'SET_MLD1_ON_VM1',
   'MLD1_JOIN_REPORT_ON_VM1',
   'VERIFY_MLD1_JOIN_ON_VM1',
   'SET_MLD2_ON_VM1',
   'MLD2_JOIN_REPORT_ON_VM1',
   'VERIFY_MLD2_JOIN_ON_VM1',
   'GROUP_MEMBERSHIP_TIMEOUT',
   'SET_DEFAULT_IGMP_QUERY_INTERVAL',
   'SET_MINIMUM_IGMP_QUERY_INTERVAL',
   'SECOND_SERVER_PORT',
   'MCAST_SECOND_SERV_QUIT_ON_VM1',
   'IGMP3_SRC1_ADDRS_STR',
   'IGMP3_SRC2_ADDR',
   'IGMP3_SRC1_ADDRS_ARRAY',
   'VERIFY_IGMP3_EXCLUDE_EMPTY_SRC',
   'MLD2_SRC1_ADDRS_STR',
   'MLD2_SRC2_ADDR',
   'MLD2_SRC1_ADDRS_ARRAY',
   'VERIFY_MLD2_EXCLUDE_EMPTY_SRC',
   'GROUP_QUERY_WAITING_TIME',
   'SET_IGMP_QUERY_VERSION2_ON_HOST1',
   'SET_IGMP_QUERY_VERSION3_ON_HOST1',
   'SET_MLD_QUERY_VERSION1_ON_HOST1',
   'SET_MLD_QUERY_VERSION2_ON_HOST1',
   'VERIFY_SNOOPING_MCASTFILTERMODE',
   'VERIFY_LEGACY_MCASTFILTERMODE',
   'ADD_UPLINK_TO_VDS',
   'REMOVE_UPLINK_FROM_VDS',
   'CREATE_VDS2',
   'DELETE_VDS2',
   'CREATE_DVPG_ON_VDS2',
   'ADD_VMKNIC_TO_HOSTS',
   'REMOVE_VMKNIC_FROM_HOST1',
   'REMOVE_VMKNIC_FROM_HOST2',
   'VM3_VMOTION',
   'Mcast_Topology_1_VDS_Without_Pnic',
   'Mcast_Vmotion_Topology',
);

our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant IGMP1_MCAST_ADDR => "239.1.1.1";
use constant IGMP2_MCAST_ADDR => "239.2.1.1";
use constant IGMP3_MCAST_ADDR => "239.3.1.1";
use constant MLD1_MCAST_ADDR  => "ff39::1:1";
use constant MLD2_MCAST_ADDR  => "ff39::2:1";
use constant MLD1_MCAST_VSI_NODE => "ff390000:00000000:00000000:00010001";
use constant MLD2_MCAST_VSI_NODE => "ff390000:00000000:00000000:00020001";

use constant POWERON_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweron",
};
use constant POWERON_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweron",
};
use constant POWERON_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweron",
};
use constant POWEROFF_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweroff",
};
use constant DELETE_VNIC1_ON_VM1 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[1]',
     'deletevnic' => 'vm.[1].vnic.[1]'
};
use constant DELETE_VNIC1_ON_VM2 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[2]',
     'deletevnic' => 'vm.[2].vnic.[1]'
};
use constant DELETE_VNIC1_ON_VM3 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[3]',
     'deletevnic' => 'vm.[3].vnic.[1]'
};
use constant MCAST_QUIT_ON_VM1 => {
   Type             => "Traffic",
   toolName         => "Mcast",
   TestAdapter      => "vm.[2].vnic.[1]",
   SupportAdapter   => "vm.[1].vnic.[1]",
   McastMethod      => "QUIT",
   connectivitytest => "0",
};
use constant SET_SNOOPING_MODE => {
   Type       => "Switch",
   TestSwitch => "vc.[1].vds.[1]",
   multicastfilteringmode => "snooping",
};
use constant SET_LEGACY_MODE => {
   Type       => "Switch",
   TestSwitch => "vc.[1].vds.[1]",
   multicastfilteringmode => "legacyFiltering",
};
use constant PLACE_VM1_ON_DVPG1 => {
   Type   => "VM",
   TestVM => "vm.[1]",
   vnic => {
     '[1]'   => {
       driver            => "e1000",
       portgroup         => "vc.[1].dvportgroup.[1]",
       connected         => 1,
       startconnected    => 1,
       allowguestcontrol => 1,
     },
   },
};
use constant PLACE_VM2_ON_DVPG1 => {
   Type   => "VM",
   TestVM => "vm.[2]",
   vnic => {
     '[1]'   => {
       driver            => "e1000",
       portgroup         => "vc.[1].dvportgroup.[1]",
       connected         => 1,
       startconnected    => 1,
       allowguestcontrol => 1,
     },
   },
};
use constant PLACE_VM3_ON_DVPG1 => {
   Type   => "VM",
   TestVM => "vm.[3]",
   vnic => {
     '[1]'   => {
       driver            => "e1000",
       portgroup         => "vc.[1].dvportgroup.[1]",
       connected         => 1,
       startconnected    => 1,
       allowguestcontrol => 1,
     },
   },
};
use constant SET_IGMP1_ON_VM1 => {
   Type    => "VM",
   TestVM  => "vm.[1]",
   configuremulticast => "igmp",
   multicastversion => "1",
};
use constant IGMP1_JOIN_REPORT_ON_VM1 => {
   Type             => "Traffic",
   toolName         => "Mcast",
   TestAdapter      => "vm.[2].vnic.[1]",
   SupportAdapter   => "vm.[1].vnic.[1]",
   McastMethod      => "MCAST_JOIN_GROUP",
   McastGroupAddr   => IGMP1_MCAST_ADDR,
   McastIpFamily    => "ipv4",
   connectivitytest => "0",
};
use constant VERIFY_IGMP1_JOIN_ON_VM1 => {
   Type           => "NetAdapter",
   TestAdapter    => "vm.[1].vnic.[1]",
   McastProtocol  => "igmp",
   McastAddr      => IGMP1_MCAST_ADDR,
   VerifyMcastReportStats => [
      {
         'mcastprotocol[?]equal_to'   => 'IGMP',
         'mcastversion[?]equal_to'    => '1',
         'mcastmode[?]equal_to'       => 'exclude',
         'groupaddr[?]equal_to'       => IGMP1_MCAST_ADDR,
      },
   ]
};
use constant SET_IGMP2_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    configuremulticast => "igmp",
    multicastversion => "2",
};
use constant IGMP2_JOIN_REPORT_ON_VM1 => {
    Type             => "Traffic",
    toolName         => "Mcast",
    TestAdapter      => "vm.[2].vnic.[1]",
    SupportAdapter   => "vm.[1].vnic.[1]",
    McastMethod      => "MCAST_JOIN_GROUP",
    McastGroupAddr   => IGMP2_MCAST_ADDR,
    McastIpFamily    => "ipv4",
    connectivitytest => "0",
};
use constant VERIFY_IGMP2_JOIN_ON_VM1 => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "igmp",
    McastAddr      => IGMP2_MCAST_ADDR,
    VerifyMcastReportStats => [
       {
          'mcastprotocol[?]equal_to'   => 'IGMP',
          'mcastversion[?]equal_to'    => '2',
          'mcastmode[?]equal_to'       => 'exclude',
          'groupaddr[?]equal_to'       => IGMP2_MCAST_ADDR,
       },
    ]
};
use constant SET_IGMP3_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    configuremulticast => "igmp",
    multicastversion => "3",
};
use constant IGMP3_JOIN_REPORT_ON_VM1 => {
    Type             => "Traffic",
    toolName         => "Mcast",
    TestAdapter      => "vm.[2].vnic.[1]",
    SupportAdapter   => "vm.[1].vnic.[1]",
    McastMethod      => "MCAST_JOIN_GROUP",
    McastGroupAddr   => IGMP3_MCAST_ADDR,
    McastIpFamily    => "ipv4",
    connectivitytest => "0",
};
use constant VERIFY_IGMP3_JOIN_ON_VM1 => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "igmp",
    McastAddr      => IGMP3_MCAST_ADDR,
    VerifyMcastReportStats => [
       {
           'mcastprotocol[?]equal_to'   => 'IGMP',
           'mcastversion[?]equal_to'    => '3',
           'mcastmode[?]equal_to'       => 'exclude',
           'groupaddr[?]equal_to'       => IGMP3_MCAST_ADDR,
       },
    ]
};
use constant SET_MLD1_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    configuremulticast => "mld",
    multicastversion => "1",
};
use constant MLD1_JOIN_REPORT_ON_VM1 => {
    Type             => "Traffic",
    toolName         => "Mcast",
    TestAdapter      => "vm.[2].vnic.[1]",
    SupportAdapter   => "vm.[1].vnic.[1]",
    McastMethod      => "MCAST_JOIN_GROUP",
    McastGroupAddr   => MLD1_MCAST_ADDR,
    McastIpFamily    => "ipv6",
    connectivitytest => "0",
};
use constant VERIFY_MLD1_JOIN_ON_VM1 => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "mld",
    McastAddr      => MLD1_MCAST_VSI_NODE,
    VerifyMcastReportStats => [
       {
          'mcastprotocol[?]equal_to'   => 'MLD',
          'mcastversion[?]equal_to'    => '1',
          'mcastmode[?]equal_to'       => 'exclude',
          'groupaddr[?]equal_to'       => MLD1_MCAST_VSI_NODE,
       },
    ]
};
use constant SET_MLD2_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    configuremulticast => "mld",
    multicastversion => "2",
};
use constant MLD2_JOIN_REPORT_ON_VM1 => {
    Type             => "Traffic",
    toolName         => "Mcast",
    TestAdapter      => "vm.[2].vnic.[1]",
    SupportAdapter   => "vm.[1].vnic.[1]",
    McastMethod      => "MCAST_JOIN_GROUP",
    McastGroupAddr   => MLD2_MCAST_ADDR,
    McastIpFamily    => "ipv6",
    connectivitytest => "0",
};
use constant VERIFY_MLD2_JOIN_ON_VM1 => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "mld",
    McastAddr      => MLD2_MCAST_VSI_NODE,
    VerifyMcastReportStats => [
       {
          'mcastprotocol[?]equal_to'   => 'MLD',
          'mcastversion[?]equal_to'    => '2',
          'mcastmode[?]equal_to'       => 'exclude',
          'groupaddr[?]equal_to'       => MLD2_MCAST_VSI_NODE,
       },
    ]
};
use constant DEFAULT_IGMP_QUERY_INTERVAL => "125";
use constant MINIMUM_IGMP_QUERY_INTERVAL => "32";
use constant GROUP_QUERY_WAITING_TIME    => "50";
use constant GROUP_MEMBERSHIP_TIMEOUT    => "150";
use constant SET_DEFAULT_IGMP_QUERY_INTERVAL => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.IGMPQueryInterval' => DEFAULT_IGMP_QUERY_INTERVAL,
    },
};
use constant SET_MINIMUM_IGMP_QUERY_INTERVAL => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.IGMPQueryInterval' => MINIMUM_IGMP_QUERY_INTERVAL,
    },
};
use constant SET_IGMP_QUERY_VERSION2_ON_HOST1 => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.IGMPVersion' => "2",
    },
};
use constant SET_IGMP_QUERY_VERSION3_ON_HOST1 => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.IGMPVersion' => "3",
    },
};
use constant SET_MLD_QUERY_VERSION1_ON_HOST1 => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.MLDVersion' => "1",
    },
};
use constant SET_MLD_QUERY_VERSION2_ON_HOST1 => {
    Type  => "Host",
    TestHost => "host.[1]",
    reconfigure => "True",
    advancedoptions => {
       'Net.MLDVersion' => "2",
    },
};
use constant SECOND_SERVER_PORT => 50007;
use constant MCAST_SECOND_SERV_QUIT_ON_VM1 => {
   Type             => "Traffic",
   toolName         => "Mcast",
   TestAdapter      => "vm.[2].vnic.[1]",
   SupportAdapter   => "vm.[1].vnic.[1]",
   McastMethod      => "QUIT",
   portnumber       => SECOND_SERVER_PORT,
   connectivitytest => "0",
};
use constant IGMP3_SRC1_ADDRS_STR => "192.168.1.1; 192.168.1.2; ".
                                     "192.168.1.3; 192.168.1.4; ".
                                     "192.168.1.5; 192.168.1.6; ".
                                     "192.168.1.7; 192.168.1.8; ".
                                     "192.168.1.9; 192.168.1.10 ";
use constant IGMP3_SRC2_ADDR => "192.168.1.11";
use constant IGMP3_SRC1_ADDRS_ARRAY => [
    '192.168.1.1', '192.168.1.2',
    '192.168.1.3', '192.168.1.4',
    '192.168.1.5', '192.168.1.6',
    '192.168.1.7', '192.168.1.8',
    '192.168.1.9', '192.168.1.10',
];
use constant VERIFY_IGMP3_EXCLUDE_EMPTY_SRC => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "igmp",
    McastAddr      => IGMP3_MCAST_ADDR,
    VerifyMcastReportStats => [
       {
         'mcastprotocol[?]equal_to'   => 'IGMP',
         'mcastversion[?]equal_to'    => '3',
         'mcastmode[?]equal_to'       => 'exclude',
         'groupaddr[?]equal_to'       => IGMP3_MCAST_ADDR,
         'sourceaddrs[?]contain_once' => ['empty'],
       },
    ]
};
use constant MLD2_SRC1_ADDRS_STR => "2002::1:1; 2002::2:1; ".
                                    "2002::3:1; 2002::4:1; ".
                                    "2002::5:1; 2002::6:1; ".
                                    "2002::7:1; 2002::8:1; ".
                                    "2002::9:1; 2002::10:1 ";
use constant MLD2_SRC2_ADDR => "2002::11:1";
use constant MLD2_SRC1_ADDRS_ARRAY => [
    '20020000:00000000:00000000:00010001',
    '20020000:00000000:00000000:00020001',
    '20020000:00000000:00000000:00030001',
    '20020000:00000000:00000000:00040001',
    '20020000:00000000:00000000:00050001',
    '20020000:00000000:00000000:00060001',
    '20020000:00000000:00000000:00070001',
    '20020000:00000000:00000000:00080001',
    '20020000:00000000:00000000:00090001',
    '20020000:00000000:00000000:00100001',
];
use constant VERIFY_MLD2_EXCLUDE_EMPTY_SRC => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    McastProtocol  => "mld",
    McastAddr      => MLD2_MCAST_VSI_NODE,
    VerifyMcastReportStats => [
       {
         'mcastprotocol[?]equal_to'   => 'MLD',
         'mcastversion[?]equal_to'    => '2',
         'mcastmode[?]equal_to'       => 'exclude',
         'groupaddr[?]equal_to'       => MLD2_MCAST_VSI_NODE,
         'sourceaddrs[?]contain_once' => ['empty'],
       },
    ]
};
use constant VERIFY_SNOOPING_MCASTFILTERMODE => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    verifymcastfiltermode => [
       {
         'mcastfiltermode[?]equal_to' => 'snooping',
       },
    ]
};
use constant VERIFY_LEGACY_MCASTFILTERMODE => {
    Type           => "NetAdapter",
    TestAdapter    => "vm.[1].vnic.[1]",
    verifymcastfiltermode => [
       {
         'mcastfiltermode[?]equal_to' => 'legacy',
       },
    ]
};
use constant ADD_UPLINK_TO_VDS => {
    Type => 'Switch',
    TestSwitch => 'vc.[1].vds.[1]',
    configureuplinks => 'add',
    vmnicadapter => 'host.[1-2].vmnic.[1]'
};
use constant REMOVE_UPLINK_FROM_VDS => {
    Type => 'Switch',
    TestSwitch => 'vc.[1].vds.[1]',
    configureuplinks => 'remove',
    vmnicadapter => 'host.[1-2].vmnic.[1]'
};
use constant CREATE_VDS2 => {
    Type => 'VC',
    TestVC => 'vc.[1]',
    vds => {
       '[2]' => {
            name           => '2-vds-vmotion',
            datacenter     => 'vc.[1].datacenter.[1]',
            vmnicadapter   => 'host.[1-2].vmnic.[2]'
       },
    },
};
use constant CREATE_DVPG_ON_VDS2 => {
    Type => 'VC',
    TestVC => 'vc.[1]',
    dvportgroup => {
        '[2]' => {
            name     => '2-dvpg-vmotion',
            vds      => 'vc.[1].vds.[2]',
            vlantype => 'access',
         }
    },
};
use constant DELETE_VDS2 => {
    Type => "VC",
    TestVC => "vc.[1]",
    deletevds => "vc.[1].vds.[2]",
};
use constant ADD_VMKNIC_TO_HOSTS => {
    Type     => "Host",
    TestHost => "host.[1-2]",
    vmknic   => {
       '[1]' => {
          portgroup   => "vc.[1].dvportgroup.[2]",
          ipv4address => "dhcp",
          configurevmotion => "enable",
       },
    },
    SleepBetweenCombos => '60',
};
use constant REMOVE_VMKNIC_FROM_HOST1 => {
    Type => "Host",
    TestHost => "host.[1]",
    removevmknic => "host.[1].vmknic.[1]",
};
use constant REMOVE_VMKNIC_FROM_HOST2 => {
    Type => "Host",
    TestHost => "host.[2]",
    removevmknic => "host.[2].vmknic.[1]",
};
use constant VM3_VMOTION => {
    Type        => "VM",
    TestVM      => "vm.[3]",
    Iterations  => "1",
    vmotion     => "roundtrip",
    dsthost     => "host.[1]",
};

use constant Mcast_Topology_1_VDS_Without_Pnic => {
   'host' => {
      '[1-2]'   => {
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
                     host => "host.[1-2]",
                     name => "Multicast-Cluster-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-2]",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mcast-$$",
               vds      => "vc.[1].vds.[1]",
               vlantype => "access",
            },
         },
      },
   },
   'vm'  => {
      '[1-2]'   => {
         host    => "host.[1]",
         vmstate => "poweroff",
      },
      '[3]' => {
         host    => "host.[2]",
         vmstate => "poweroff",
      },
   },
};
use constant Mcast_Vmotion_Topology => {
   'host' => {
      '[1-2]'   => {
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
                     host => "host.[1-2]",
                     name => "Multicast-Cluster-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-2]",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mcast-$$",
               vds      => "vc.[1].vds.[1]",
               vlantype => "access",
            },
         },
      },
   },
   'vm'  => {
      '[1-2]'   => {
         host    => "host.[1]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
      '[3]' => {
         host    => "host.[2]",
         vmstate => "poweroff",
         datastoreType => 'shared',
      },
   },
};

1;
