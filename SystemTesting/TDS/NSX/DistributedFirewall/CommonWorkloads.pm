#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'SEGMENTID_RANGE',
   'MULTICAST_RANGE',
   'FIRST_CONTROLLER',
   'IP_POOL',
   'SET_SEGMENTID_RANGE',
   'SET_MULTICAST_RANGE',
   'CREATE_VIRTUALWIRES_NETWORKSCOPE1',
   'POWERON_VM1',
   'POWERON_VM2',
   'POWERON_VM3',
   'POWEROFF_VM1',
   'POWEROFF_VM2',
   'POWEROFF_VM3',
   'DELETE_VM1_VNIC1',
   'DELETE_VM2_VNIC1',
   'DELETE_VM3_VNIC1',
   'ADD_VM1_VNIC1',
   'ADD_VM2_VNIC1',
   'ADD_VM3_VNIC1',
   'ADD_HOST1_VMKNIC1',
   'DELETE_HOST1_VMKNIC1',
   'REBOOT_CTRLR_HOST',
   'HOST_PREP_AND_VTEPCREATE',
   'HOST_UNPREP',
   'COMMON_TESTBEDSPEC',
   'MOVE_HOST2_TO_CLUSTER1',
   'MOVE_HOST3_TO_CLUSTER2',
   'ADD_HOST2_TO_VDS1',
   'ADD_HOST3_TO_VDS2',
   'REVERT_DEFAULT_RULES',
   'IP_LIST',
   'MAC_LIST',
   'COMMON_TESTBEDSPEC_VC_60_HOSTS_55_60',
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant REVERT_DEFAULT_RULES => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   firewallrule => {
      '[-1]' => {}
   }
};
use constant SEGMENTID_RANGE => {
   '[1]' => {
      name  => "AutoGenerate",
      begin => "5001-10001",
      end   => "99000",
   },
};
use constant MULTICAST_RANGE => {
   '[1]' => {
         name  => "AutoGenerate",
         begin => "239.0.0.101",
         end   => "239.254.254.254",
   },
};
use constant COMMON_TESTBEDSPEC => {
   vsm => {
      '[1]' => {
         reconfigure => "true",
         vc => 'vc.[1]',
         assignrole  => "enterprise_admin",
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[1]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
            },
            '[2]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[2]",
            },
         },
         networkscope => {
            '[1]' => {
               name     => "AutoGenerate",
               clusters => "vc.[1].datacenter.[1].cluster.[1-2]",
               controlplanemode => 'MULTICAST_MODE',
            },
         },
      },
   },
   vc => {
      '[1]' => {
         datacenter => {
         '[1]' => {
            cluster => {
               '[1]' => {
                   host => "host.[1-2]",
                   clustername => "cluster-5.5",
                   ha => 0,
                   drs => 1,
               },
               '[2]' => {
                  host => "host.[3]",
                  clustername => "cluster-5.1",
                  ha => 0,
                  drs => 1,
               },
            },
          },
        },
        vds => {
          '[1]'   => {
             datacenter => "vc.[1].datacenter.[1]",
             configurehosts => "add",
             host => "host.[1-2]",
             vmnicadapter => "host.[1-2].vmnic.[1]",
          },
          '[2]'   => {
             datacenter => "vc.[1].datacenter.[1]",
             version => "5.1.0",
             configurehosts => "add",
             host => "host.[3]",
             vmnicadapter => "host.[3].vmnic.[1]",
          },
       },
       dvportgroup => {
          '[1]'   => {
             vds     => "vc.[1].vds.[1]",
             ports   => "12",
          },
          '[2]'   => {
             vds     => "vc.[1].vds.[2]",
             ports   => "8",
          },
       },
     },
   },
   host => {
      '[1-2]' => {
         vmnic => {
            '[1]' => {
              driver => "any",
            },
         },
         vmknic => {
            '[1]' => {
               portgroup   => "vc.[1].dvportgroup.[1]",
               configureservices => {
                  'VMOTION' => 1,
               },
            },
         },
      },
      '[3]' => {
         vmnic => {
            '[1]' => {
              driver => "any",
            },
         },
      },
   },
   vm => {
     '[1]'   => {
        host  => "host.[1]",
        vmstate => "poweron",
        datastoreType => 'shared',
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[1]",
           },
        },
     },
     '[2]'   => {
        host  => "host.[2]",
        datastoreType => 'shared',
        vmstate => "poweron",
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[1]",
           },
        },
     },
     '[3]'   => {
        host  => "host.[3]",
        datastoreType => 'shared',
        vmstate => "poweron",
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[2]",
           },
        },
     },
   },
};
use constant COMMON_TESTBEDSPEC_VC_60_HOSTS_55_60 => {
   vsm => {
      '[1]' => {
         reconfigure => "true",
         vc => 'vc.[1]',
         assignrole  => "enterprise_admin",
         segmentidrange => SEGMENTID_RANGE,
         multicastiprange => MULTICAST_RANGE,
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[1]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
            },
            '[2]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[2]",
            },
         },
         networkscope => {
            '[1]' => {
               name     => "AutoGenerate",
               clusters => "vc.[1].datacenter.[1].cluster.[1-2]",
               controlplanemode => 'MULTICAST_MODE',
            },
         },
      },
   },
   vc => {
      '[1]' => {
         datacenter => {
         '[1]' => {
            cluster => {
               '[1]' => {
                   host => "host.[1-2]",
                   clustername => "cluster-6.0",
                   ha => 0,
                   drs => 1,
               },
               '[2]' => {
                  host => "host.[3]",
                  clustername => "cluster-5.5",
                  ha => 0,
                  drs => 1,
               },
            },
          },
        },
        vds => {
          '[1]'   => {
             datacenter => "vc.[1].datacenter.[1]",
             configurehosts => "add",
             host => "host.[1-2]",
             vmnicadapter => "host.[1-2].vmnic.[1]",
          },
          '[2]'   => {
             datacenter => "vc.[1].datacenter.[1]",
             version => "5.5.0",
             configurehosts => "add",
             host => "host.[3]",
             vmnicadapter => "host.[3].vmnic.[1]",
          },
       },
       dvportgroup => {
          '[1]'   => {
             vds     => "vc.[1].vds.[1]",
             ports   => "12",
          },
          '[2]'   => {
             vds     => "vc.[1].vds.[2]",
             ports   => "8",
          },
       },
     },
   },
   host => {
      '[1-2]' => {
         vmnic => {
            '[1]' => {
              driver => "any",
            },
         },
         vmknic => {
            '[1]' => {
               portgroup   => "vc.[1].dvportgroup.[1]",
               configureservices => {
                  'VMOTION' => 1,
               },
            },
         },
      },
      '[3]' => {
         vmnic => {
            '[1]' => {
              driver => "any",
            },
         },
      },
   },
   vm => {
     '[1]'   => {
        host  => "host.[1]",
        vmstate => "poweron",
        datastoreType => 'shared',
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[1]",
           },
        },
     },
     '[2]'   => {
        host  => "host.[2]",
        datastoreType => 'shared',
        vmstate => "poweron",
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[1]",
           },
        },
     },
     '[3]'   => {
        host  => "host.[3]",
        datastoreType => 'shared',
        vmstate => "poweron",
        vnic => {
           '[1]' => {
              driver    => "vmxnet3",
              portgroup => "vc.[1].dvportgroup.[2]",
           },
        },
     },
   },
};
use constant ADD_HOST2_TO_VDS1 => {
   Type        => "Switch",
   TestSwitch  => "vc.[1].vds.[1]",
   configurehosts => "add",
   configureuplinks => "add",
   host           => "host.[2]",
   vmnicadapter   => "host.[2].vmnic.[1]",
};
use constant MOVE_HOST2_TO_CLUSTER1 => {
   Type        => "Cluster",
   TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
   MoveHostsToCluster => "host.[2]",
};
use constant MOVE_HOST3_TO_CLUSTER2 => {
   Type        => "Cluster",
   TestCluster => "vc.[1].datacenter.[1].cluster.[2]",
   MoveHostsToCluster => "host.[3]",
};
use constant ADD_HOST3_TO_VDS2 => {
   Type        => "Switch",
   TestSwitch  => "vc.[1].vds.[2]",
   configurehosts => "add",
   configureuplinks=> "add",
   host           => "host.[3]",
   vmnicadapter   => "host.[3].vmnic.[1]",
};
use constant HOST_PREP_AND_VTEPCREATE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   VDNCluster => {
      '[1]' => {
         cluster      => "vc.[1].datacenter.[1].cluster.[1]",
         vibs         => "install",
         switch       => "vc.[1].vds.[1]",
      },
      '[2]' => {
         cluster      => "vc.[1].datacenter.[1].cluster.[2]",
         vibs         => "install",
         switch       => "vc.[1].vds.[2]",
      },
   },
};
use constant HOST_UNPREP => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   VDNCluster => {
      '[1]' => {
         cluster      => "vc.[1].datacenter.[1].cluster.[1]",
         vibs         => "uninstall",
      },
   },
};
use constant REBOOT_CTRLR_HOST => {
   Type            => "Host",
   TestHost        => "host.[1]",
   reboot          => "yes",
};
# IP Pool 1-2 used for Controller
# IP Pool 3-4 used for static VTEP
use constant IP_POOL => {
   name   => "ippool-controller-1",
   gateway  => "XX.XX.XX.XX",
   prefixlength  => "XX",
   ipranges => ['XX.XX.XX.XX-XX.XX.XX.XX'],
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
use constant FIRST_CONTROLLER => {
   '[1]' => {
      name         => "AutoGenerate",
      ippool       => "vsm.[1].ippool.[1]",
      resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
      host         => "host.[1]",
   },
};
use constant CREATE_VIRTUALWIRES_NETWORKSCOPE1 => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[1]",
   VirtualWire       => {
      "[1]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "MULTICAST_MODE",
      },
      "[2]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "UNICAST_MODE",
      },
      "[3]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "HYBRID_MODE",
      },
   },
};
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
use constant DELETE_VM1_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[1]",
   deletevnic => "vm.[1].vnic.[1]",
};
use constant DELETE_VM2_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[2]",
   deletevnic => "vm.[2].vnic.[1]",
};
use constant DELETE_VM3_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[3]",
   deletevnic => "vm.[3].vnic.[1]",
};
use constant ADD_VM1_VNIC1 => {
   Type   => "VM",
   TestVM => "vm.[1]",
   vnic   => {
      '[1]'   => {
         ipv4      => "auto",
         driver    => "vmxnet3",
         portgroup => "vc.[1].dvportgroup.[1]",
      },
   },
};
use constant ADD_VM2_VNIC1 => {
   Type   => "VM",
   TestVM => "vm.[2]",
   vnic   => {
      '[1]'   => {
         ipv4      => "auto",
         driver    => "vmxnet3",
         portgroup => "vc.[1].dvportgroup.[1]",
      },
   },
};
use constant ADD_VM3_VNIC1 => {
   Type   => "VM",
   TestVM => "vm.[3]",
   vnic   => {
      '[1]' => {
         ipv4      => "auto",
         driver    => "vmxnet3",
         portgroup => "vc.[1].dvportgroup.[2]",
      },
   },
};
use constant ADD_HOST1_VMKNIC1 => {
   Type     => "Host",
   TestHost => "host.[1]",
   vmknic	=> {
      "[1]" => {
         ipv4address => "auto",
         portgroup	=> "vc.[1].dvportgroup.[1]",
      },
   },
};
use constant DELETE_HOST1_VMKNIC1 => {
   Type         => "Host",
   TestHost     => "host.[1]",
   removevmknic => "host.[1].vmknic.[1]",
};
use constant IP_LIST => "56.106.107.245,179.54.210.39,139.49.53.74,".
   "39.234.192.14,227.51.29.119,121.42.168.189,133.70.118.139,".
   "26.131.55.10,215.107.211.6,170.253.50.185,100.140.166.138,".
   "120.103.152.93,153.180.212.20,222.125.209.10,94.72.239.220,".
   "203.40.229.163,147.85.168.62,183.218.47.28,104.159.166.223,".
   "7.63.62.160,243.19.179.211,144.133.57.84,205.41.49.153,".
   "81.24.61.227,208.229.35.137,192.28.165.41,186.77.10.192,".
   "140.71.98.129,90.22.85.233,155.141.62.105,182.111.3.8,".
   "134.64.235.88,38.15.225.230,143.84.226.60,157.131.4.253,".
   "77.220.71.52,208.235.17.225,164.237.145.31,161.205.63.204,".
   "229.80.56.239,157.76.163.45,160.135.104.63,11.107.62.88,".
   "73.132.139.26,112.156.250.22,138.141.52.44,92.114.248.66,".
   "193.49.51.96,124.213.140.30,93.244.92.104,97.153.191.169,".
   "31.75.194.142,231.190.163.114,76.215.157.168,74.150.234.13,".
   "199.30.108.69,242.248.98.81,237.190.185.79,88.121.247.118,".
   "196.187.6.172,122.169.32.198,129.188.112.202,84.91.215.28,".
   "82.142.138.121,28.171.95.219,50.118.225.230,209.166.80.196,".
   "236.168.65.85,227.184.6.55,23.1.16.85,99.148.124.180,".
   "35.7.47.63,177.141.27.227,4.252.202.213,163.28.154.145,".
   "195.219.230.168,149.235.222.171,236.237.1.80,131.124.6.165,".
   "131.52.227.53,192.254.26.196,251.228.154.160,1.54.51.196,".
   "18.26.110.167,7.78.84.243,60.85.68.190,209.74.101.85,".
   "125.73.138.62,73.163.3.70,136.157.229.137,210.26.79.228,".
   "51.188.141.58,11.224.46.71,30.13.127.36,106.41.127.84,".
   "91.208.90.248,179.182.46.51,16.191.51.40,116.24.13.88,".
   "94.211.27.172,149.15.229.178,27.101.214.132,142.87.216.233,".
   "40.51.226.218,232.17.15.248,208.66.33.69,89.46.157.183,".
   "2.109.101.151,124.75.75.150,176.34.28.64,120.243.42.159,".
   "40.14.123.18,30.138.11.238,203.44.52.38,89.209.221.91,".
   "64.67.241.187,142.61.82.63,95.110.127.214,99.168.119.138,".
   "181.241.155.211,125.166.194.73,209.246.111.43,200.77.133.9,".
   "170.176.216.23,131.239.19.84,162.15.232.132,67.230.104.146,".
   "192.214.66.192,225.63.238.208,76.11.105.200,126.166.191.42,".
   "87.152.10.218,136.118.47.44,28.24.175.95,254.25.241.191,".
   "238.52.128.209,114.112.163.190,8.14.135.134,180.72.175.12,".
   "223.184.230.105,47.22.149.75,46.70.169.46,94.156.236.78,".
   "207.110.32.67,221.195.3.229,208.137.108.133,208.28.145.177";

use constant MAC_LIST => "7C:F1:F2:E8:1E:E8,3D:96:CB:10:9F:1A,".
   "66:7C:DE:08:61:4B,79:C5:96:91:80:85,56:6D:B8:BF:4E:68,".
   "11:CB:5A:04:B3:78,EC:F1:0F:B7:02:AE,D1:68:2B:B0:70:8C,".
   "FC:EA:51:92:7B:D2,17:D2:3F:D0:91:8E,38:A3:5A:93:A7:0D,".
   "0B:94:FF:1A:4B:01,C9:1D:69:F4:CE:DA,81:CA:C4:D2:5D:40,".
   "A4:75:12:E4:45:A4,72:7E:48:CC:11:EF,DA:1D:84:D9:37:D0,".
   "DB:01:EE:44:F6:BC,1F:77:87:E3:4A:E4,24:EF:5A:37:D3:9F,".
   "DB:46:1E:23:13:2F,13:EE:4C:97:C7:84,67:A3:86:55:E7:7C,".
   "12:06:F3:9A:EA:3D,7E:0F:2D:D8:46:00,78:22:47:96:45:5B,".
   "C6:59:49:12:F1:11,97:59:B4:1D:AF:9C,99:C1:A3:8D:5B:8D,".
   "95:C6:B2:15:07:49,37:4F:61:5B:31:AE,E5:FF:7B:4A:90:E3,".
   "6D:35:5F:E7:76:F6,D7:4A:B9:82:B4:4C,D2:4A:13:85:5F:1A,".
   "CE:97:6A:30:F3:9B,DE:D8:9B:5A:22:2C,3D:8F:61:9D:77:D8,".
   "93:4E:22:4C:D1:D7,99:A3:21:AD:29:81,C8:F7:18:32:27:0B,".
   "CE:06:E3:69:61:06,96:9E:95:F7:3B:0D,D0:CF:5C:F3:1C:2D,".
   "CA:B5:D1:EC:62:FA,6E:2A:F2:86:5D:1A,92:2C:21:76:96:82,".
   "7C:2C:20:12:23:5C,20:F4:2B:7C:E7:47,AA:B1:FD:7B:9D:60,".
   "75:0C:8B:68:92:E8,82:25:14:A3:9B:AB,26:18:D7:46:2B:FB,".
   "A2:4B:EF:CE:C8:D6,16:72:88:13:ED:26,73:63:32:FE:CB:C4,".
   "E7:4E:EA:FC:F2:86,A7:18:9F:7E:5E:CA,7A:01:16:69:D0:DF,".
   "A0:EB:45:D7:CC:55,B7:6C:79:80:CC:54,08:95:3C:90:0C:B4,".
   "92:5F:A2:A9:20:39,F1:61:12:C5:11:61,DA:B2:4D:20:8A:19,".
   "75:41:86:EF:C2:53,43:CA:E9:80:5A:F5,35:EC:55:D8:96:76,".
   "11:87:D8:23:4C:E9,85:27:9B:D2:47:25,EC:BC:67:72:AC:29,".
   "C6:F0:F4:AF:70:4F,A5:A6:3B:FA:7E:D1,71:90:59:49:B3:A6,".
   "32:39:CD:CE:0B:14,F4:F7:D1:5C:6A:7E,86:30:6E:7A:DF:DF,".
   "C9:84:85:05:7F:04,D7:F0:94:31:39:48,D7:6C:81:A4:3B:8C,".
   "B9:30:84:8B:8C:EE,09:13:1F:78:8E:FE,57:57:83:DC:5D:02,".
   "E0:34:F3:75:65:2D,BD:3D:9A:3F:E2:D5,CC:9B:06:50:27:93,".
   "3F:31:A6:5E:A9:34,5D:00:8C:E1:DD:E9,E4:BE:1E:D7:33:83,".
   "78:CB:1E:85:5F:C3,6B:BC:AF:81:54:D5,29:B1:9F:4B:26:7F,".
   "F3:B7:E6:02:C1:BB,C4:65:9D:48:E4:55,0B:5D:21:2A:E2:80,".
   "ED:4D:3D:9D:CF:91,72:F8:43:12:43:69,91:37:20:77:3A:E2,".
   "33:FE:48:D0:47:2C,25:53:8A:46:7D:6C,C7:6B:BA:05:08:89,".
   "96:7B:81:DA:8D:C5,43:1E:FD:64:96:37,47:C9:36:8F:9A:7E,".
   "BC:BF:D1:46:06:4E,B2:CE:B9:6C:D3:C2,F5:6A:3D:77:44:CB,".
   "3D:88:EA:3A:EC:80,72:33:4A:A9:C3:E4,27:7F:A4:F9:C5:AB,".
   "48:77:79:01:E4:4D,C4:DA:B8:02:51:FC,CD:8E:84:B7:C9:71,".
   "38:3C:A5:82:E5:68,67:0D:E7:0B:06:AD,B6:4E:24:30:50:09,".
   "7E:14:E3:36:17:34,32:E4:C3:B7:9C:8D,29:D4:C9:CE:56:AF,".
   "08:90:EC:A4:F2:0F,CB:71:45:E7:66:70,D4:12:E6:F0:8B:A1,".
   "CC:2C:59:AB:BB:23,66:BF:A6:21:B9:81,12:C1:11:FE:66:04,".
   "0E:31:75:54:19:DC,C4:EE:EF:AB:DF:7A,4C:AB:A7:A6:57:62,".
   "C9:BD:22:6F:DF:DB,F1:F1:9D:02:F0:03,06:FF:35:7C:53:4F,".
   "58:18:3D:47:C3:1C,C1:0F:C8:68:B5:1F,CB:7F:DC:EE:EF:BC,".
   "CA:E0:AD:67:E3:9D,6B:E9:9D:A1:66:F0,F0:BE:08:2E:05:CB,".
   "4A:C7:DB:13:30:91,32:FC:10:0F:EA:00,CB:B4:E1:78:1C:C4,".
   "16:88:AE:B3:29:14,A4:1A:D3:AC:48:D9,78:93:A1:54:A6:D1,".
   "E5:D9:CD:F6:E8:B8,F7:B4:6D:D8:2C:89,9D:43:12:4B:F7:3B,".
   "60:9B:56:33:47:9F,0D:C0:33:AE:15:DA,7F:FB:B3:4D:F1:9C";
1;
