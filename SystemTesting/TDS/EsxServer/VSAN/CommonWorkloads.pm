#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VSAN::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'CREATE_VM1_VSAN_DATASTORE_HOST1',
   'CREATE_VM2_VSAN_DATASTORE_HOST2',
   'CREATE_VM3_VSAN_DATASTORE_HOST3',
   'REMOVE_ALL_VMs',
   'RUN_DATA_TEST_PROGRAM_VM1_120_SEC',
   'RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC',
   'ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP',
   'ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP',
   'ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP',
   'ALL_HOST_ENABLE_VSAN_VMKNIC1',
   'ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1',
   'DISABLE_VSAN_AUTOCLAIM_CLUSTER1',
   'CREATE_ALL_DATASTORE_OBJ_HOST1',
   'CREATE_ALL_DATASTORE_OBJ_HOST2',
   'CREATE_ALL_DATASTORE_OBJ_HOST3',
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);


use constant DISABLE_VSAN_AUTOCLAIM_CLUSTER1 => {
   Type => "Cluster",
   TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
   EditCluster => "edit",
   vsan => 0,
   autoclaimstorage => 0,
};
use constant ALL_HOST_ENABLE_VSAN_VMKNIC1 => {
  'Type'        => 'NetAdapter',
  'TestAdapter' => 'host.[1-3].vmknic.[1]',
  'vsan'        => 'enable',
};

use constant ENABLE_VSAN_DISABLE_AUTOCLAIM_CLUSTER1 => {
   Type => "Cluster",
   TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
   EditCluster => "edit",
   vsan => 1,
   autoclaimstorage => 0,
};

use constant CREATE_VM1_VSAN_DATASTORE_HOST1 => {
   Type     => "Root",
   TestNode => "root.[1]",
   vm => {
      '[1]' => {
         template => "rhel53-srv-32",
         host     => "host.[1]",
         datastoreType => "vsan",
         vnic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               driver => "e1000",
            },
         },
      },
   },
};

use constant CREATE_VM2_VSAN_DATASTORE_HOST2 => {
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
};

use constant CREATE_VM3_VSAN_DATASTORE_HOST3 => {
   Type     => "Root",
   TestNode => "root.[1]",
   sleepbetweenworkloads => "60",
   vm => {
      '[3]' => {
         template => "rhel53-srv-32",
         host     => "host.[3]",
         datastoreType => "vsan",
         vnic => {
            '[1]' => {
               portgroup => "vc.[1].dvportgroup.[1]",
               driver => "e1000",
            },
         },
      },
   },
};


use constant REMOVE_ALL_VMs => {
   Type     => "Root",
   TestNode => "root.[1]",
   deletevm => "vm.[-1]",
   sleepbetweenworkloads => "30",
};

use constant RUN_DATA_TEST_PROGRAM_VM1_120_SEC => {
   Type          => "Root",
   TestNode      => "root.[1]",
   diskio => {
      '[1]' => {
         toolname     => "dt",
         testdisk     => "vm.[1]",
         testduration => "120",
         operation     => "startsession",
      },
   },
};

use constant RUN_DATA_TEST_PROGRAM_ALL_3VMs_300_SEC => {
   Type          => "Root",
   TestNode      => "root.[1]",
   diskio => {
      '[1]' => {
         toolname     => "dt",
         testdisk     => "vm.[1]",
         testduration => "3",
         operation     => "startsession",
      },
      '[2]' => {
         toolname     => "dt",
         testdisk     => "vm.[2]",
         testduration => "3",
         operation     => "startsession",
      },
      '[3]' => {
         toolname     => "dt",
         testdisk     => "vm.[3]",
         testduration => "3",
         operation     => "startsession",
      },
   },
};


use constant ALL_HOST_SSD_HDD_JOIN_VSAN_DISK_GROUP => {
   Type          => "Host",
   Testhost      => "host.[-1]",
   vsandiskgroup => "join"
};

use constant ALL_HOST_VERIFY_SAME_VSAN_DISK_GROUP => {
   Type       => "Host",
   Testhost   => "host.[-1]",
   sleepbetweenworkloads => "120",
   noofretries           => 5,
   verifyvsancluster => {
      'Sub-Cluster Master UUID[?]equal_to' => "host.[1]",
   }
};

use constant ALL_HOST_SSD_HDD_LEAVE_VSAN_DISK_GROUP => {
   Type          => "Host",
   Testhost      => "host.[-1]",
   sleepbetweenworkloads => "60",
   vsandiskgroup => "leave",
   vsancluster   => "leave",
};

use constant CREATE_ALL_DATASTORE_OBJ_HOST1 => {
   Type     => "Host",
   TestHost => "host.[1]",
   datastore => {
      '[1]' => {
         name => "datastore1",
      },
      '[2]' => {
         name => "vdnetSharedStorage",
      },
      '[3]' => {
         name => "vsanDatastore",
      },
   },
};

use constant CREATE_ALL_DATASTORE_OBJ_HOST2 => {
   Type     => "Host",
   TestHost => "host.[2]",
   datastore => {
      '[1]' => {
         name => "datastore1",
      },
      '[2]' => {
         name => "vdnetSharedStorage",
      },
      '[3]' => {
         name => "vsanDatastore",
      },
   },
};

use constant CREATE_ALL_DATASTORE_OBJ_HOST3 => {
   Type     => "Host",
   TestHost => "host.[3]",
   datastore => {
      '[1]' => {
         name => "datastore1",
      },
      '[2]' => {
         name => "vdnetSharedStorage",
      },
      '[3]' => {
         name => "vsanDatastore",
      },
   },
};

1;
