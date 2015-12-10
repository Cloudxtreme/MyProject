########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDL2::TestbedSpec;

# Export testbedspec which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'Functional_Topology_1',
   'Functional_Topology_2'
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

#OneVC_TwoVDS_SixDVPG_TwoHost_TwoVmnicEachHost_FourVM
use constant Functional_Topology_1 => {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2]'
            }
         },
         'dvportgroup' => {
            '[2]' => {
               'vds' => 'vc.[1].vds.[2]'
            },
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            },
            '[3]' => {
               'name' => 'dvportgroup3',
               'vds' => 'vc.[1].vds.[1]'
            },
            '[4]' => {
               'name' => 'dvportgroup4',
               'vds' => 'vc.[1].vds.[1]'
            },
            '[5]' => {
               'name' => 'dvportgroup5',
               'vds' => 'vc.[1].vds.[2]'
            },
            '[6]' => {
               'name' => 'dvportgroup6',
               'vds' => 'vc.[1].vds.[2]'
            }
         },
         'vds' => {
            '[2]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[2]',
               'configurehosts' => 'add',
               'numuplinkports' => 1,
               'host' => 'host.[1-2]'
            },
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
               'numuplinkports' => 1,
               'host' => 'host.[1-2]'
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            }
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[2]'
            }
         }
      },
      '[2]' => {
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[2]'
      },
      '[3]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      },
      '[4]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[2]'
      },
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      }
   }
};
#OneVC_TwoVDS_SixDVPG_TwoHost_TwoVmnicOneVDS_FourVM
use constant Functional_Topology_2 => {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2]'
            }
         },
         'dvportgroup' => {
            '[2]' => {
               'vds' => 'vc.[1].vds.[2]'
            },
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            },
            '[3]' => {
               'name' => 'dvportgroup3',
               'vds' => 'vc.[1].vds.[1]'
            },
            '[4]' => {
               'name' => 'dvportgroup4',
               'vds' => 'vc.[1].vds.[1]'
            },
            '[5]' => {
               'name' => 'dvportgroup5',
               'vds' => 'vc.[1].vds.[2]'
            },
            '[6]' => {
               'name' => 'dvportgroup6',
               'vds' => 'vc.[1].vds.[2]'
            }
         },
         'vds' => {
            '[2]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[2-3]',
               'configurehosts' => 'add',
               'numuplinkports' => 2,
               'host' => 'host.[1-2]'
            },
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
               'numuplinkports' => 1,
               'host' => 'host.[1-2]'
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1-3]' => {
               'driver' => 'any'
            }
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[2]'
            }
         }
      },
      '[2]' => {
         'vmnic' => {
            '[1-3]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[2]'
      },
      '[3]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      },
      '[4]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[2]'
      },
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      }
   }
};

1;

