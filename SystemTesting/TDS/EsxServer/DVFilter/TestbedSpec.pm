########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::EsxServer::DVFilter::TestbedSpec;

# All DVFilterSlowpath based tests
$Topology_1 = {
  'vm' => {
     '[2]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[2].portgroup.[1]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[2]'
     },
     '[3]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet3'
           },
           '[2]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet2'
           },
           '[3]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'e1000'
           }
        },
        'host' => 'host.[1]'
     },
     '[1]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[3]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[1]'
     }
  },
  'host' => {
     '[2]' => {
        'portgroup' => {
           '[1-2]' => {
             'vss' => 'host.[2].vss.[1]'
           }
        },
        'vmnic' => {
           '[1]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[2].portgroup.[2]',
           }
        },
        'vss' => {
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
           }
        }
     },
     '[1]' => {
        'portgroup' => {
           '[3]' => {
             'vss' => 'host.[1].vss.[1]'
           },
           '[1-2]' => {
             'vss' => 'host.[1].vss.[2]'
           }
        },
        'vmnic' => {
           '[1-2]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[1].portgroup.[2]',
           }
        },
        'vss' => {
           '[2]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
           },
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[1]'
           }
        }
     }
  }
};
$Topology_2 = {
  'vm' => {
     '[2]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[2].portgroup.[1]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[2]'
     },
     '[3]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet3'
           },
           '[2]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet2'
           },
           '[3]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'e1000'
           }
        },
        'host' => 'host.[1]'
     },
     '[4]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[4]',
             'driver' => 'vmxnet3'
           },
           '[2]' => {
             'portgroup' => 'host.[1].portgroup.[4]',
             'driver' => 'vmxnet2'
           },
           '[3]' => {
             'portgroup' => 'host.[1].portgroup.[4]',
             'driver' => 'e1000'
           }
        },
        'host' => 'host.[1]'
     },
     '[1]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[3]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[1]'
     }
  },
  'host' => {
     '[2]' => {
        'portgroup' => {
           '[1-2]' => {
             'vss' => 'host.[2].vss.[1]'
           }
        },
        'vmnic' => {
           '[1]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[2].portgroup.[2]',
           }
        },
        'vss' => {
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
           }
        }
     },
     '[1]' => {
        'portgroup' => {
           '[3]' => {
             'vss' => 'host.[1].vss.[1]'
           },
           '[1-2]' => {
             'vss' => 'host.[1].vss.[2]'
           },
           '[4-5]' => {
             'vss' => 'host.[1].vss.[3]'
           }
        },
        'vmnic' => {
           '[1-3]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[1].portgroup.[2]',
           },
           '[2]' => {
              'portgroup' => 'host.[1].portgroup.[5]',
           }
        },
        'vss' => {
           '[3]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[3]'
           },
           '[2]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
           },
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[1]'
           }
        }
     }
  }
};
$Topology_3 = {
  'vm' => {
     '[2]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[2].portgroup.[1]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[2]'
     },
     '[3]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet3'
           },
           '[2]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'vmxnet2'
           },
           '[3]' => {
             'portgroup' => 'host.[1].portgroup.[1]',
             'driver' => 'e1000'
           }
        },
        'host' => 'host.[1]'
     },
     '[4]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[3]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[1]'
     },
     '[1]' => {
        'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[3]',
             'driver' => 'vmxnet3'
           }
        },
        'host' => 'host.[1]'
     }
  },
  'host' => {
     '[2]' => {
        'portgroup' => {
           '[1-2]' => {
             'vss' => 'host.[2].vss.[1]'
           }
        },
        'vmnic' => {
           '[1]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[2].portgroup.[2]',
           }
        },
        'vss' => {
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[2].vmnic.[1]'
           }
        }
     },
     '[1]' => {
        'portgroup' => {
           '[3]' => {
             'vss' => 'host.[1].vss.[1]'
           },
           '[1-2]' => {
             'vss' => 'host.[1].vss.[2]'
           }
        },
        'vmnic' => {
           '[1-2]' => {
             'driver' => 'any'
           }
        },
        'vmknic' => {
           '[1]' => {
              'portgroup' => 'host.[1].portgroup.[2]',
           }
        },
        'vss' => {
           '[2]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[2]'
           },
           '[1]' => {
              'configureuplinks' => 'add',
              'vmnicadapter' => 'host.[1].vmnic.[1]'
           }
        }
     }
  }
};
1;
