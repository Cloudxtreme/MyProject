#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VXLAN::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'SEGMENTID_RANGE',
   'MULTICAST_RANGE',
   'FIRST_CONTROLLER',
   'THREE_CONTROLLERS',
   'IP_POOL',
   'SET_SEGMENTID_RANGE',
   'SET_MULTICAST_RANGE',
   'CREATE_VIRTUALWIRES_NETWORKSCOPE1',
   'CREATE_VIRTUALWIRE_MULTICAST',
   'CREATE_VIRTUALWIRE_UNICAST',
   'CREATE_VIRTUALWIRE_HYBRID',
   'DELETE_ALL_VIRTUALWIRES',
   'POWERON_VM',
   'POWEROFF_VM',
   'POWERON_VM1',
   'POWERON_VM2',
   'POWERON_VM3',
   'POWERON_VM4',
   'POWERON_VM5',
   'POWERON_VM6',
   'POWERON_VM7',
   'POWERON_VM8',
   'POWERON_VM9',
   'POWERON_VM10',
   'POWERON_VM11',
   'POWERON_VM12',
   'POWEROFF_VM1',
   'POWEROFF_VM2',
   'POWEROFF_VM3',
   'POWEROFF_VM4',
   'POWEROFF_VM5',
   'POWEROFF_VM6',
   'POWEROFF_VM7',
   'POWEROFF_VM8',
   'POWEROFF_VM9',
   'DELETE_VM1_VNIC1',
   'DELETE_VM2_VNIC1',
   'DELETE_VM3_VNIC1',
   'DELETE_VM4_VNIC1',
   'DELETE_VM5_VNIC1',
   'DELETE_VM6_VNIC1',
   'DELETE_VM7_VNIC1',
   'DELETE_VM8_VNIC1',
   'DELETE_VM9_VNIC1',
   'DELETE_VM1_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM2_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM3_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM4_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM5_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM6_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM7_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM8_VNIC1_IN_EXIT_SEQ',
   'DELETE_VM9_VNIC1_IN_EXIT_SEQ',
   'REBOOT_CTRLR_HOST',
   'DEPLOY_FIRST_CONTROLLER',
   'DEPLOY_SECOND_CONTROLLER',
   'DEPLOY_THIRD_CONTROLLER',
   'DELETE_ALL_CONTROLLERS',
   'VXLAN_VNIC_DRIVER'
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant VXLAN_VNIC_DRIVER => "vmxnet3";
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

use constant REBOOT_CTRLR_HOST => {
   Type            => "Host",
   TestHost        => "host.[1]",
   reboot          => "yes",
};

# IP Pool 1-2 used for Controller
# IP Pool 3-4 used for static VTEP
use constant IP_POOL => {
   name   => "ippool-controller-1-$$",
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
use constant THREE_CONTROLLERS => {
   '[1]' => {
      name         => "AutoGenerate",
      ippool       => "vsm.[1].ippool.[1]",
      resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
      host         => "host.[1]",
   },
   '[2]' => {
      name         => "AutoGenerate",
      ippool       => "vsm.[1].ippool.[1]",
      resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
      host         => "host.[1]",
   },
   '[3]' => {
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
use constant CREATE_VIRTUALWIRE_MULTICAST => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[1]",
   VirtualWire       => {
      "[1]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "MULTICAST_MODE",
      },
   },
};
use constant CREATE_VIRTUALWIRE_UNICAST => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[1]",
   VirtualWire       => {
      "[2]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "UNICAST_MODE",
      },
   },
};
use constant CREATE_VIRTUALWIRE_HYBRID => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[1]",
   VirtualWire       => {
      "[3]" => {
         name        => "AutoGenerate",
         tenantid    => "AutoGenerate",
         controlplanemode => "HYBRID_MODE",
      },
   },
};
use constant DELETE_ALL_VIRTUALWIRES => {
   Type              => "TransportZone",
   TestTransportZone => "vsm.[1].networkscope.[-1]",
   deletevirtualwire => "vsm.[1].networkscope.[-1].virtualwire.[-1]",
   sleepbetweenworkloads => "20",
};
use constant DEPLOY_FIRST_CONTROLLER   => {
   Type  => "NSX",
   testnsx  => "vsm.[1]",
   vxlancontroller  => {
      '[1]' => {
         name         => "AutoGenerate",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool  => "vc.[1].datacenter.[1].cluster.[1]",
         host          => "host.[1]",
         datastore     => "host.[1]",
      },
   },
};
use constant DEPLOY_SECOND_CONTROLLER   => {
   Type  => "NSX",
   testnsx  => "vsm.[1]",
   vxlancontroller  => {
      '[2]' => {
         name         => "AutoGenerate",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool  => "vc.[1].datacenter.[1].cluster.[1]",
         host          => "host.[1]",
         datastore     => "host.[1]",
      },
   },
};
use constant DEPLOY_THIRD_CONTROLLER   => {
   Type  => "NSX",
   testnsx  => "vsm.[1]",
   vxlancontroller  => {
      '[3]' => {
         name         => "AutoGenerate",
         ippool       => "vsm.[1].ippool.[1]",
         resourcepool  => "vc.[1].datacenter.[1].cluster.[1]",
         host          => "host.[1]",
         datastore     => "host.[1]",
      },
   },
};
use constant DELETE_ALL_CONTROLLERS => {
   Type                 => "NSX",
   TestNSX              => "vsm.[1]",
   deletevxlancontroller=> "vsm.[1].vxlancontroller.[-1]",
};
use constant POWERON_VM => {
   Type => "VM",
   TestVM => "vm.[-1]",
   vmstate  => "poweron",
};
use constant POWEROFF_VM => {
   Type => "VM",
   TestVM => "vm.[-1]",
   vmstate  => "poweroff",
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
use constant POWERON_VM4 => {
   Type => "VM",
   TestVM => "vm.[4]",
   vmstate  => "poweron",
};
use constant POWERON_VM5 => {
   Type => "VM",
   TestVM => "vm.[5]",
   vmstate  => "poweron",
};
use constant POWERON_VM6 => {
   Type => "VM",
   TestVM => "vm.[6]",
   vmstate  => "poweron",
};
use constant POWERON_VM7 => {
   Type => "VM",
   TestVM => "vm.[7]",
   vmstate  => "poweron",
};
use constant POWERON_VM8 => {
   Type => "VM",
   TestVM => "vm.[8]",
   vmstate  => "poweron",
};
use constant POWERON_VM9 => {
   Type => "VM",
   TestVM => "vm.[9]",
   vmstate  => "poweron",
};
use constant POWERON_VM10 => {
   Type => "VM",
   TestVM => "vm.[10]",
   vmstate  => "poweron",
};
use constant POWERON_VM11 => {
   Type => "VM",
   TestVM => "vm.[11]",
   vmstate  => "poweron",
};
use constant POWERON_VM12 => {
   Type => "VM",
   TestVM => "vm.[12]",
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
use constant POWEROFF_VM4 => {
   Type => "VM",
   TestVM => "vm.[4]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM5 => {
   Type => "VM",
   TestVM => "vm.[5]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM6 => {
   Type => "VM",
   TestVM => "vm.[6]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM7 => {
   Type => "VM",
   TestVM => "vm.[7]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM8 => {
   Type => "VM",
   TestVM => "vm.[8]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM9 => {
   Type => "VM",
   TestVM => "vm.[9]",
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
use constant DELETE_VM4_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[4]",
   deletevnic => "vm.[4].vnic.[1]",
};
use constant DELETE_VM5_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[5]",
   deletevnic => "vm.[5].vnic.[1]",
};
use constant DELETE_VM6_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[6]",
   deletevnic => "vm.[6].vnic.[1]",
};
use constant DELETE_VM7_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[7]",
   deletevnic => "vm.[7].vnic.[1]",
};
use constant DELETE_VM8_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[8]",
   deletevnic => "vm.[8].vnic.[1]",
};
use constant DELETE_VM9_VNIC1 => {
   Type       => "VM",
   TestVM     => "vm.[9]",
   deletevnic => "vm.[9].vnic.[1]",
};
use constant DELETE_VM1_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[1]",
   deletevnic => "vm.[1].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM2_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[2]",
   deletevnic => "vm.[2].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM3_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[3]",
   deletevnic => "vm.[3].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM4_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[4]",
   deletevnic => "vm.[4].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM5_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[5]",
   deletevnic => "vm.[5].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM6_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[6]",
   deletevnic => "vm.[6].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM7_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[7]",
   deletevnic => "vm.[7].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM8_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[8]",
   deletevnic => "vm.[8].vnic.[1]",
   expectedResult => "ignore",
};
use constant DELETE_VM9_VNIC1_IN_EXIT_SEQ => {
   Type       => "VM",
   TestVM     => "vm.[9]",
   deletevnic => "vm.[9].vnic.[1]",
   expectedResult => "ignore",
};

1;
