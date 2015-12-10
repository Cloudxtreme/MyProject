########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::EsxServer::VDS::TestbedSpec;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
    # VM, mainly vnic of VM, configuration
    'Vnic_e1000_on_dvpg1',
    'Vnic_vmxnet3_on_dvpg1',
    'One_vnic_e1000_on_host1_on_dvpg1',
    'Two_vnic_e1000_on_host1_on_dvpg1',
    'One_vnic_e1000_on_host2_on_dvpg1',
    'One_vnic_vmxnet3_on_host1_on_dvpg1',
    'One_vnic_vmxnet3_on_host2_on_dvpg1',
    'One_vnic_e1000_on_host2_on_dvpg2',
    'One_vnic_e1000_on_host1_on_dvpg1_shared',
    'One_vnic_e1000_on_host2_on_pg1',
    # VC/DC configuration
    'OneDC_TwoHost_OneVDS_OneDVPG',
    'OneDC_TwoHost_OneVDS_TwoDVPG',
    'OneDC_TwoHost_OneVDS_ThreeDVPG',
    'OneDC_TwoHost_TwoVDS_TwoDVPG',
    'OneDC_TwoHost_OneVDSLastSupported_OneDVPG',
    'OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG',
    'OneDC_TwoHost_OneVDS_HasHost1Alone_ThreeDVPG',
    # Host configuration
    'HostConfig_OneVmnic',
    'HostConfig_OneVmnic_OnePswitchPort',
    'HostConfig_OneVmnic_VSSnoUplink_OnePG',
    'HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2',
    'HostConfig_OneVmnic_VSS_OnePG_Pswitch',
    'HostConfig_TwoVmnic_TwoVSS_TwoPG_TwoPswitchPort',
    'HostConfig_ThreeVmnic_VSSnoUplink_OnePG_Pswitch',
    'HostConfig_ThreeVmnic_ThreeVSS_ThreePG_ThreePswitchPort',
    'HostConfig_TwoVmnic_VSS_OnePG_VmkForVmotion',
    'HostConfig_TwoVmnic_VSS_Vmk_OnePG_Pswitch',
    'HostConfig_TwoVmnic_VSS_VmkOnDVPG_Pswitch',
    'HostConfig_OneVmnic_VmkOnDVPG1',
    'HostConfig_OneVmnic_TwoVmknic_onDVPG2_3',
);

our %EXPORT_TAGS = (VDSTestbedSpec => \@EXPORT_OK);

# Start from element:
use constant Vnic_e1000_on_dvpg1 => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'e1000',
             };

use constant Vnic_vmxnet3_on_dvpg1 => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'driver' => 'vmxnet3',
             };

use constant One_vnic_e1000_on_host1_on_dvpg1 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[1]',
             };
use constant Two_vnic_e1000_on_host1_on_dvpg1 => {
                    vnic => {
                        '[1-2]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[1]',
             };
use constant One_vnic_e1000_on_host1_on_dvpg1_shared => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[1]',
                    datastoreType => 'shared',
                };

use constant One_vnic_e1000_on_host2_on_dvpg1 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[2]',
                };
use constant One_vnic_e1000_on_host2_on_dvpg2 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[2]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[2]',
                };
use constant One_vnic_e1000_on_host2_on_pg1 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'host.[2].portgroup.[1]',
                            'driver' => 'e1000',
                        },
                    },
                    host => 'host.[2]',
                };
use constant One_vnic_vmxnet3_on_host1_on_dvpg1 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'vmxnet3',
                        },
                    },
                    host => 'host.[1]',
                };
use constant One_vnic_vmxnet3_on_host2_on_dvpg1 => {
                    vnic => {
                        '[1]' => {
                            'portgroup' => 'vc.[1].dvportgroup.[1]',
                            'driver' => 'vmxnet3',
                        },
                    },
                    host => 'host.[2]',
                };

use constant OneDC_TwoHost_OneVDS_OneDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1-2]',
                      },
                   },
                },
             };

use constant OneDC_TwoHost_OneVDS_TwoDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1-2]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1-2]',
                      },
                   },
                },
             };

use constant OneDC_TwoHost_OneVDS_ThreeDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1-3]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1-2]',
                      },
                   },
                },
             };

use constant OneDC_TwoHost_TwoVDS_TwoDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1-2]' => {
                         'vds' => 'vc.[1].vds.[x]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1-2]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1-2].vmnic.[x]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1-2]',
                      },
                   },
                },
             };

use constant OneDC_TwoHost_OneVDSLastSupported_OneDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1-2]',
                         'version' => VDNetLib::TestData::TestConstants::VDS_LAST_SUPPORTED_VERSION,
                      },
                   },
                },
             };

use constant OneDC_TwoHost_OneVDS_HasHost1Alone_TwoDVPG => {
                '[1]' => {
                   'datacenter' => {
                      '[1]' => {
                         'host' => 'host.[1-2]',
                      },
                   },
                   'dvportgroup' => {
                      '[1-2]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'ports' => '6',
                      },
                   },
                   'vds' => {
                      '[1]' => {
                         'datacenter' => 'vc.[1].datacenter.[1]',
                         'vmnicadapter' => 'host.[1].vmnic.[1]',
                         'configurehosts' => 'add',
                         'host' => 'host.[1]',
                      },
                   },
                },
            };

use constant OneDC_TwoHost_OneVDS_HasHost1Alone_ThreeDVPG => {
              '[1]' => {
                'datacenter' => {
                  '[1]' => {
                    'host' => 'host.[1-2]',
                  },
                },
                'dvportgroup' => {
                  '[1-3]' => {
                    'vds' => 'vc.[1].vds.[1]',
                    'ports' => 6,
                  },
                },
                'vds' => {
                  '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1]',
                  },
               },
             },
          };

use constant HostConfig_OneVmnic => {
                vmnic => {
                   '[1]'   => {
                      driver => "any",
                   },
                },
             };

use constant HostConfig_OneVmnic_OnePswitchPort => {
                'vmnic' => {
                   '[1]' => {
                      'driver' => 'any',
                   },
                },
                'pswitchport' => {
                   '[1]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[1]',
                   },
                },
             };

use constant HostConfig_OneVmnic_VSSnoUplink_OnePG => {
                'vmnic' => {
                   '[1]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1]' => {},
                },
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
             };

use constant HostConfig_OneVmnic_VSSnoUplink_OnePG_VmkDvpg2 => {
                'vmnic' => {
                   '[1]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1]' => {},
                },
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[2]',
                   },
                },
             };

use constant HostConfig_OneVmnic_VSS_OnePG_Pswitch => {
                'vmnic' => {
                   '[1]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[1]',
                   },
                },
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'pswitchport' => {
                   '[1]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[1]',
                   },
                },
             };

use constant HostConfig_TwoVmnic_TwoVSS_TwoPG_TwoPswitchPort => {
                'vmnic' => {
                   '[1-2]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1-2]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[x]',
                   },
                },
                'portgroup' => {
                   '[1-2]' => {
                      'vss' => 'host.[x=host_index].vss.[x]',
                   },
                },
                'pswitchport' => {
                   '[1-2]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[x]',
                   },
                },
             };

use constant HostConfig_ThreeVmnic_ThreeVSS_ThreePG_ThreePswitchPort => {
                'vmnic' => {
                   '[1-3]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1-3]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[x]',
                   },
                },
                'portgroup' => {
                   '[1-3]' => {
                      'vss' => 'host.[x=host_index].vss.[x]',
                   },
                },
                'pswitchport' => {
                   '[1-3]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[x]',
                   },
                },
             };

use constant HostConfig_TwoVmnic_VSS_OnePG_VmkForVmotion => {
                'vmnic' => {
                   '[1-2]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'vmknic' => {
                   '[1]' => {
                       'portgroup' => 'host.[x=host_index].portgroup.[1]',
                   },
                },
             };

use constant HostConfig_ThreeVmnic_VSSnoUplink_OnePG_Pswitch => {
                'vmnic' => {
                   '[1-3]' => {
                      'driver' => 'any',
                   },
                },
                'vss' => {
                   '[1]' => {},
                },
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'pswitchport' => {
                   '[1]' => {
                       'vmnic' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
             };

use constant HostConfig_TwoVmnic_VSS_Vmk_OnePG_Pswitch => {
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'vss' => {
                   '[1]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
                'vmnic' => {
                   '[1-2]' => {
                      'driver' => 'any'
                   },
                },
                'pswitchport' => {
                   '[1]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'host.[x=host_index].portgroup.[1]',
                   },
                },
             };

use constant HostConfig_TwoVmnic_VSS_VmkOnDVPG_Pswitch => {
                'portgroup' => {
                   '[1]' => {
                      'vss' => 'host.[x=host_index].vss.[1]',
                   },
                },
                'vss' => {
                   '[1]' => {
                      'configureuplinks' => 'add',
                      'vmnicadapter' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
                'vmnic' => {
                   '[1-2]' => {
                      'driver' => 'any'
                   },
                },
                'pswitchport' => {
                   '[1]' => {
                      'vmnic' => 'host.[x=host_index].vmnic.[2]',
                   },
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[2]',
                   },
                },
             };

use constant HostConfig_OneVmnic_VmkOnDVPG1 => {
                'vmnic' => {
                   '[1]' => {
                      'driver' => 'any'
                   },
                },
                'vmknic' => {
                   '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[1]'
                   },
                },
             };

use constant HostConfig_OneVmnic_TwoVmknic_onDVPG2_3 => {
                'vmnic' => {
                  '[1]' => {
                    'driver' => 'any',
                  },
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[2]',
                  },
                  '[2]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]',
                  },
                },
              };
1;
