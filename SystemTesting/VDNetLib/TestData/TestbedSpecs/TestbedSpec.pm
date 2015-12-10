########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TestData::TestbedSpecs::TestbedSpec;

$OneVC_OneDC_OneVDS_TwoDVPG_TwoHost_TwoVmnicForEachHost = {
   'vc' => {
     '[1]' => {
       'datacenter' => {
         '[1]' => {
           'host' => 'host.[1-2].x.[x]'
         }
       },
       'dvportgroup' => {
         '[1]' => {
           'vds' => 'vc.[1].vds.[1]',
         },
         '[2]' => {
           'vds' => 'vc.[1].vds.[1]',
         }
       },
       'vds' => {
         '[1]' => {
           'datacenter' => 'vc.[1].datacenter.[1]',
           'vmnicadapter' => 'host.[1-2].vmnic.[1]',
           'configurehosts' => 'add',
           'host' => 'host.[1-2].x.[x]'
         }
       }
     }
   },
   'host' => {
     '[1]' => {
       'vmnic' => {
         '[1-2]' => {
           'driver' => 'any'
         },
       },
       'vmknic' => {
         '[0]' => {
           'portgroup' => "host.[1].portgroup.[0]",
           'interface' => "vmk0",
         }
       },
       'portgroup' => {
         '[0]' => {
           'vss' => "host.[1].vss.[0]",
           'name' => "VMKernel",
         }
       },
       'vss' => {
         '[0]' => {
           'name' => "vSwitch0",
         }
       },
     },
     '[2]' => {
       'vmknic' => {
         '[1]' => {
           'portgroup' => 'vc.[1].dvportgroup.[2]'
         }
       },
       'vmnic' => {
         '[1]' => {
           'driver' => 'any'
         }
       }
     },
   },
};

$OneHost = {
   'host' => {
      '[1]' => {}
   }
};

$OneVC_OneDC_OneVDS_ThreeDVPG_TwoHost_TwoVmnicForEachHost_PSwitch = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            },
            '[2]' => {
               'vds' => 'vc.[1].vds.[1]'
            },
            '[3]' => {
               'vds' => 'vc.[1].vds.[1]'
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
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
         },
         'pswitchport' => {
            '[2]' => {
               'vmnic' => 'host.[1].vmnic.[2]'
            },
            '[1]' => {
               'vmnic' => 'host.[1].vmnic.[1]'
            }
         }
      },
      '[2]' => {
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            }
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            }
         },
         'pswitchport' => {
            '[2]' => {
               'vmnic' => 'host.[2].vmnic.[2]'
            },
            '[1]' => {
               'vmnic' => 'host.[2].vmnic.[1]'
            }
         }
      }
   },
   pswitch => {
      '[1]' => {
         ip => "XX.XX.XX.XX",
      },
   },
};

$OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_TwoVM = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1].x.[x]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1].vmnic.[1]',
               'configurehosts' => 'add',
               'host' => 'host.[1].x.[x]'
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      },
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]',
      }
   }
};

$OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_TwoVM = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2].x.[x]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
               'host' => 'host.[1-2].x.[x]'
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         },
      },
      '[2]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      },
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[2].x.[x]'
      }
   }
};

$OneVC_OneDC_OneVDS_OneDVPG_TwoHost_OneVmnicEachHost_ThreeVM = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2].x.[x]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'ports' => 6,
               'vds' => 'vc.[1].vds.[1]'
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
               'host' => 'host.[1-2].x.[x]'
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         }
      },
      '[2]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      },
      '[2]' => {
         'vnic' => {
            '[1]' => {
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      },
      '[3]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[2].x.[x]'
      }
   }
};

# VXLAN/VDR Setup, Same VDS
# 2 VMs on Same Host, use vmotion to test
# different host scenarios on same testbed
$OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM = {
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
      '[2-4]'   => {
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
                  '[3]' => {
                     host => "host.[4]",
                     name => "Compute-Cluster2-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[2-4]",
               vmnicadapter   => "host.[2-4].vmnic.[1]",
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
      '[1-2]'   => {
         host            => "host.[2]",
         vmstate         => "poweroff",
         'datastoreType' => 'shared',
      },
      '[3]'   => {
         host            => "host.[3]",
         vmstate         => "poweroff",
         'datastoreType' => 'shared',
      },
   },
};

# VXLAN Setup Two VDSes, Five Hosts
$OneVSM_OneVC_OneDC_TwoVDS_FiveHost_SixVM = {
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
#            '[2]' => {
#               name         => "AutoGenerate",
#               ippool       => "vsm.[1].ippool.[1]",
#               resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
#               host         => "host.[1]",
#            },
#            '[3]' => {
#               name         => "AutoGenerate",
#               ippool       => "vsm.[1].ippool.[1]",
#               resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
#               host         => "host.[1]",
#            },
         },
#         VDNCluster => {
#            '[1]' => {
#               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
#               vibs         => "install",
#               switch       => "vc.[1].vds.[1]",
#               vlan         => [21],
#               mtu          => "1600",
#               vmkniccount  => "1",
#               teaming      => VDNetLib::TestData::TestConstants::ARRAY_VXLAN_CONFIG_TEAMING_POLICIES,
#            },
#            '[2]' => {
#               cluster      => "vc.[1].datacenter.[1].cluster.[3]",
#               vibs         => "install",
#               switch       => "vc.[1].vds.[2]",
#               vlan         => "22",
#               mtu          => "1600",
#               vmkniccount  => "1",
#               teaming      => "FAILOVER_ORDER",
#            },
#         },
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
               host => "host.[2-5]",
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     name => "Controller-Cluster-$$",
                  },
                  '[2]' => {
                     name => "Compute-Cluster-SJC-$$",
                  },
                  '[3]' => {
                     name => "Compute-Cluster-SFO-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               name           => "VDS-1-SJC-$$",
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[2-3]",
               vmnicadapter   => "host.[2-3].vmnic.[1]",
               numuplinkports => "1",
            },
            '[2]'   => {
               name           => "VDS-2-SFO-$$",
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[4-5]",
               vmnicadapter   => "host.[4-5].vmnic.[1]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-SJC-vlan16-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "16",
               vlantype => "access",
            },
            '[2]'   => {
               name     => "dvpg-SJC-vlan17-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "17",
               vlantype => "access",
            },
            '[3]'   => {
               name     => "dvpg-SJC-vlan18-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "18",
               vlantype => "access",
            },
            '[4]'   => {
               name     => "dvpg-SJC-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "19",
               vlantype => "access",
            },
            '[5]'   => {
               name     => "dvpg-SJC-vlan21-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "21",
               vlantype => "access",
            },
            '[6]'   => {
               name     => "dvpg-SJC-vlan22-$$",
               vds      => "vc.[1].vds.[1]",
               vlan     => "22",
               vlantype => "access",
            },
            '[7]'   => {
               name     => "dvpg-SFO-vlan16-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "16",
               vlantype => "access",
            },
            '[8]'   => {
               name     => "dvpg-SFO-vlan17-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "17",
               vlantype => "access",
            },
            '[9]'   => {
               name     => "dvpg-SFO-vlan18-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "18",
               vlantype => "access",
            },
            '[10]'   => {
               name     => "dvpg-SFO-vlan19-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "19",
               vlantype => "access",
            },
            '[11]'   => {
               name     => "dvpg-SFO-vlan21-$$",
               vds      => "vc.[1].vds.[2]",
               vlan     => "21",
               vlantype => "access",
            },
            '[12]'   => {
               name     => "dvpg-SFO-vlan22-$$",
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
   },
};

$OneVSM_OneVC_OneDC_OneVDS_TwoHost_OneCluster = {
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
      },
   },
   'host' => {
      '[1-2]'  => {
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1-2]",
                     name => "Controller-Cluster-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-2]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
            },
         },
      },
   },
};

$OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster = {
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
      },
   },
   'host' => {
      '[1-2]'  => {
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
                     host => "host.[2]",
                     name => "Compute-Cluster-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter     => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host           => "host.[1-2]",
               numuplinkports => "1",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               name     => "dvpg-mgmt-$$",
               vds      => "vc.[1].vds.[1]",
            },
         },
      },
   },
};

$ovsTwoHostTopology01 = {
   host  => {
       '[1]'   => {
         vib               => "install",
         maintenance       => 1,
         signaturecheck    => 0,
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch",
            },
         },
         nvpnetwork   => {
            '[1]' => {
               network => "nvp-1",
               ovs     => "host.[1].ovs.[1]",
            },
         },
         vmnic => {
            '[1]'   => {
               driver   => "any",
            },
         },
      },
      '[2]'   => {
         vib               => "install",
         maintenance       => 1,
         signaturecheck    => 0,
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch",
            },
         },
         nvpnetwork   => {
            '[1]' => {
               network => "nvp-1",
               ovs     => "host.[2].ovs.[1]",
            },
         },
         vmnic => {
            '[1]'   => {
               driver   => "any",
            },
         },
      },
   },
   vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "host.[1].nvpnetwork.[1]",
            },
         },
      },
      '[2]'   => {
         host  => "host.[2]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "host.[1].nvpnetwork.[1]",
            },
         },
      },
   },
};

$ovsOneHostTopology01 = {
   host  => {
      '[1]'   => {
         vib               => "install",
         maintenance       => 1,
         signaturecheck    => 0,
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               network => "nvp-1",
               ovs     => "host.[1].ovs.[1]",
            },
         },
      },
   },
   vm  => {
      '[1-2]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "host.[1].nvpnetwork.[1]",
            },
         },
      },
   },
};

$ovsVmotionTopology01 = {
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[1].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
         },
         vib               => "install",
         maintenance       => 1,
         signaturecheck    => 0,
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               network => "nvp-1",
               ovs     => "host.[1].ovs.[1]",
            },
         },
      },
      '[2]' => {
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[2].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[2].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
         },
         vib               => "install",
         maintenance       => 1,
         signaturecheck    => 0,
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               network => "nvp-1",
               ovs     => "host.[2].ovs.[1]",
            },
         },
      },
   },
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[2].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[2].x.[x]'
      },
      '[1]' => {
         'datastoreType' => 'shared',
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[1].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      }
   },
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2].x.[x]'
            }
         },
      },
   },
};

$OneHostNIOCv3VDS = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1].x.[x]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]'
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1].vmnic.[1]',
               'configurehosts' => 'add',
               'host' => 'host.[1].x.[x]',
               'nioc' => 'enable',
               'niocversion'    => "version3",
               'version'        => "6.0.0",
            }
         }
      }
   },
   'host' => {
      '[1]' => {
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         }
      }
   },
   'vm' => {
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1].x.[x]'
      },
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1].x.[x]',
      }
   }
};

$TwoHostWithThreeVMsEach = {
   '[1-3]'   => {
         host            => "host.[2]",
         vmstate         => "poweroff",
   },
   '[4-6]' => {
      host => "host.[3]",
      vmstate => "poweroff",
   },
};

$VCWithOneVDSThreeUplinkPorts = {
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
            numuplinkports => "3",
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
};

$VCWithTwoVDS = {
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
         '[2]'   => {
            datacenter     => "vc.[1].datacenter.[1]",
            configurehosts => "add",
            host           => "host.[2-3]",
            vmnicadapter   => "host.[2-3].vmnic.[2]",
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
            vds      => "vc.[1].vds.[2]",
            vlan     => "16",
            vlantype => "access",
         },
         '[3]'   => {
            name     => "dvpg-vlan17-$$",
            vds      => "vc.[1].vds.[2]",
            vlan     => "17",
            vlantype => "access",
         },
         '[4]'   => {
            name     => "dvpg-vlan18-$$",
            vds      => "vc.[1].vds.[2]",
            vlan     => "18",
            vlantype => "access",
         },
      },
   },
};

$OneVC_OneDC_OneVDS_Netstack = {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1].x.[x]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        version => "5.5.0",
                        name => "VDS55",
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1-2]",
                        configurehosts => "add",
                        host => "host.[1].x.[x]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "4",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                     '[2]' => {
                       netstackname => "ovs",
                     },
                  },
               },
            },

};

$OneVC_OneDC_OneVSS_Netstack = {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1].x.[x]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                       netstackname => "vxlan",
                     },
                     '[2]' => {
                       netstackname => "ovs",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
};

$OneVC_OneDC_OneVDS_Upgrade = {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1-2].x.[x]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        version => '5.1.0',
                        configurehosts => "add",
                        host => "host.[2].x.[x]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[2]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[1]' => {
               },
            },
};

$OneVC_OneDC_OneVDS_Upgrade_Stateless = {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                        foldername => "Profile",
                        name => "Profile-test",
                        host  => "host.[1-2].x.[x]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        version => '5.1.0',
                        configurehosts => "add",
                        host => "host.[2].x.[x]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[2]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[1]' => {
               },
               '[3]' => {
               },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[3].x.[x]",
              },
           },
};

$OneVC_OneDC_OneVDS_OneCluster = {
           vc => {
              '[1]' => {
                 datacenter => {
                    '[1]' => {
                       foldername => "Profile",
                       name => "Profile-test",
                       cluster => {
                          '[1]' => {
                             host => "host.[1-2].x.[x]",
                             clustername => "Profile-Cluster",
                          },
                       },
                    },
                 },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1-2]",
                        configurehosts => "add",
                        host => "host.[1].x.[x]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "4",
                     },
                  },

              },
           },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
               },
            },
};

$OneVC_OneDC_OneVDS_Stateless_Testbed = {

          vc    => {
              '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => "Profile",
                       name => "Profile-test",
                       host => "host.[1].x.[x]",
                    },
                 },
              },
           },
          host  => {
             '[1]'   => {
                 vmnic => {
                    '[1]'   => {
                       driver => "any",
                    },
                 },
              },

              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2].x.[x]",
              },
           },
};

$OneVC_OneDC_OneVSS_Stateless_Testbed = {
           vc    => {
              '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => "Profile",
                       name => "Profile-test",
                       host => "host.[1].x.[x]",
                    },
                 },
              },
           },
          host  => {
              '[1]'   => {
              },
              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2].x.[x]",
              },
           },
};

$OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnic_ThreeVM = {
    'vc' => {
	'[1]' => {
	    'datacenter' => {
		'[1]' => {
		    'host' => 'host.[1].x.[x]'
		    }
		},
	    'dvportgroup' => {
		'[1]' => {
		    'vds' => 'vc.[1].vds.[1]',
                    'ports'   => '6',
		    }
		},
	    'vds' => {
		'[1]' => {
		    'datacenter' => 'vc.[1].datacenter.[1]',
		    'vmnicadapter' => 'host.[1].vmnic.[1]',
		    'configurehosts' => 'add',
		    'host' => 'host.[1].x.[x]'
		    }
		}
	    }
	},
    'host' => {
	'[1]' => {
	    'vmnic' => {
		'[1]' => {
		    'driver' => 'any'
		    }
		},
            'vmknic' => {
		'[1]' => {
		    'portgroup' => 'vc.[1].dvportgroup.[1]',
		    }
		}
	    }
	},
    'vm' => {
	'[1-3]' => {
	    'vnic' => {
		'[1]' => {
		    'portgroup' => 'vc.[1].dvportgroup.[1]',
                     driver     => "vmxnet3",
		    }
		},
	'host' => 'host.[1].x.[x]',
        },
    }
};

$OneNeutron_L2L3VSphere_CAT_Setup = {
    'neutron' => {
       '[1]' => {
       },
    },
    host  => {
       '[1-2]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
    },
    'vc' => {
        '[1]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX1-Cluster-$$",
                          drs  => 1,
                          host => "host.[1]",
                       },
                      '[2]' => {
                          name => "ESX2-Cluster-$$",
                          drs  => 1,
                          host => "host.[2]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[1]",
                   vmnicadapter => "host.[1].vmnic.[1]",
                 },
               '[2]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[2]",
                   vmnicadapter => "host.[2].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[1].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
               '[2]'   => {
                   vds     => "vc.[1].vds.[2]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
     },
     'vsm' => {
         '[1]' => {
             reconfigure => "true",
             vc          => 'vc.[1]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
               '[2]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[2]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
             },
         },
     },
     vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[1].dvportgroup.[1]",
            },
         },
      },
      '[2]'   => {
         host  => "host.[2]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[1].dvportgroup.[2]",
            },
         },
      },
   },
};

$OneNeutron_L2L3VSphere_functional = {
    'neutron' => {
       '[1]' => {
       },
    },
    host  => {
       '[1-4]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
    },
    'vc' => {
        '[1]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX1-Cluster-$$",
                          drs  => 1,
                          host => "host.[1]",
                       },
                      '[2]' => {
                          name => "ESX2-Cluster-$$",
                          drs  => 1,
                          host => "host.[2]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[1]",
                   vmnicadapter => "host.[1].vmnic.[1]",
                 },
               '[2]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[2]",
                   vmnicadapter => "host.[2].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[1].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
               '[2]'   => {
                   vds     => "vc.[1].vds.[2]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
        '[2]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX1-Cluster-$$",
                          drs  => 1,
                          host => "host.[3]",
                       },
                      '[2]' => {
                          name => "ESX2-Cluster-$$",
                          drs  => 1,
                          host => "host.[4]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[2].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[3]",
                   vmnicadapter => "host.[3].vmnic.[1]",
                 },
               '[2]'   => {
                   datacenter  => "vc.[2].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[4]",
                   vmnicadapter => "host.[4].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[2].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
               '[2]'   => {
                   vds     => "vc.[2].vds.[2]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        }
     },
     'vsm' => {
         '[1]' => {
             reconfigure => "true",
             vc          => 'vc.[1]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
               '[2]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[2]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
             },
         },
       '[2]' => {
             reconfigure => "true",
             vc          => 'vc.[2]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[2].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[2].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
               '[2]' => {
                  cluster      => "vc.[2].datacenter.[1].cluster.[2]",
                  vibs         => "install",
                  switch       => "vc.[2].vds.[2]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
             },
         },
     },
     vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[1].dvportgroup.[1]",
            },
         },
      },
      '[2]'   => {
         host  => "host.[2]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[1].dvportgroup.[2]",
            },
         },
      },
      '[3]'   => {
         host  => "host.[3]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[2].dvportgroup.[1]",
            },
         },
      },
      '[4]'   => {
         host  => "host.[4]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "vc.[1].dvportgroup.[2]",
            },
         },
      },
   },
};

$OneNeutron_VSphere_functional = {
    'neutron' => {
       '[1]' => {
       },
    },
    host  => {
       '[1]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
       '[2]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
       '[3]'   => {
           vib               => "install",
           maintenance       => 1,
           signaturecheck    => 0,
           ovs   => {
               '[1]' => {
                   switch  => "nsx-vswitch",
               },
           },
           nvpnetwork   => {
               '[1]' => {
                   network => "nvp-1",
                   ovs     => "host.[3].ovs.[1]",
               },
           },
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
       '[4]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
       '[5]'   => {
           vib               => "install",
           maintenance       => 1,
           signaturecheck    => 0,
           ovs   => {
               '[1]' => {
                   switch  => "nsx-vswitch",
               },
           },
           nvpnetwork   => {
               '[1]' => {
                   network => "nvp-1",
                   ovs     => "host.[5].ovs.[1]",
               },
           },
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
    },
    'vc' => {
        '[1]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX2-Cluster-$$",
                          drs  => 1,
                          host => "host.[2]",
                       },
                       '[2]' => {
                          name => "ESX3-Cluster-$$",
                          drs  => 1,
                          host => "host.[3]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[2]",
                   vmnicadapter => "host.[2].vmnic.[1]",
                 },
               '[2]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[3]",
                   vmnicadapter => "host.[3].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[1].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
        '[2]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX4-Cluster-$$",
                          drs  => 1,
                          host => "host.[4]",
                       },
                       '[2]' => {
                          name => "ESX5-Cluster-$$",
                          drs  => 1,
                          host => "host.[5]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[2].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[4]",
                   vmnicadapter => "host.[4].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[2].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
     },
     'vsm' => {
         '[1]' => {
             reconfigure => "true",
             vc          => 'vc.[1]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1-2]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[1-2]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[1-2]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
             },
         },
         '[2]' => {
             reconfigure => "true",
             vc          => 'vc.[2]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[2].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[2].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                     teaming      => "FAILOVER_ORDER",
                },
             },
         },
     },
   vm  => {
      '[1]'   => {
         host  => "host.[3]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "host.[3].nvpnetwork.[1]",
            },
         },
      },
      '[2]'   => {
         host  => "host.[5]",
         vnic => {
            '[1]'   => {
               driver     => "e1000",
               portgroup  => "host.[5].nvpnetwork.[1]",
            },
         },
      },
   },
};

$TwoHosts_OneDataCenter_TwoVDS_ThreeControllers_sixVMs = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength  => "xx",
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
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[1].cluster.[3]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
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
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
                  '[3]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[2]",
               vmnicadapter => "host.[2].vmnic.[1]",
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[3]",
               vmnicadapter => "host.[3].vmnic.[1]",
            },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

$TwoHosts_TwoDataCenter_TwoCluster_TwoVDS_ThreeControllers_sixVMs = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => "vc.[1]",
         assignrole  => "enterprise_admin",
         ippool   => {
            '[1]' => {
               name         => "AutoGenerate",
               gateway      => "x.x.x.x",
               prefixlength  => "xx",
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
         vdncluster => {
            '[1]' => {
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vibs         => "install",
               switch       => "vc.[1].vds.[1]",
               vlan         => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu          => "1600",
               teaming      => "FAILOVER_ORDER",
            },
            '[2]' => {
               cluster     => "vc.[1].datacenter.[2].cluster.[1]",
               vibs        => "install",
               switch      => "vc.[1].vds.[2]",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
               mtu         => "1600",
               teaming     => "ETHER_CHANNEL",
            },
         },
         networkscope => {
            '[1]' => {
               name         => "AutoGenerate",
               clusters     => "vc.[1].datacenter.[1].cluster.[2];;vc.[1].datacenter.[2].cluster.[1]",
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
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1]",
                     clustername => "ControllerCluster-$$",
                  },
                  '[2]' => {
                     host => "host.[2]",
                     clustername => "ComputeCluster1-$$",
                  },
               },
            },
            '[2]'   => {
               Cluster => {
                  '[1]' => {
                     host => "host.[3]",
                     clustername => "ComputeCluster2-$$",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[2]",
               vmnicadapter => "host.[2].vmnic.[1]",
            },
            '[2]'   => {
               datacenter => "vc.[1].datacenter.[2]",
               configurehosts => "add",
               host => "host.[3]",
               vmnicadapter => "host.[3].vmnic.[1]",
            },
         },
      },
   },
   vm  => {
      '[1-3]'   => {
         host  => "host.[2]",
         vmstate => "poweroff",
      },
      '[4-6]'   => {
         host  => "host.[3]",
         vmstate => "poweroff",
      },
   },
};

$OneNeutron_TwovSphere_TwoESX_TwoVsm_functional = {
    'neutron' => {
       '[1]' => {
       },
    },
    host  => {
       '[1]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
       '[2]'   => {
           vmnic  => {
              '[1]'   => {
                  driver => "any",
               },
           },
       },
    },
    'vc' => {
        '[1]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX1-Cluster-$$",
                          drs  => 1,
                          host => "host.[1]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[1].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[1]",
                   vmnicadapter => "host.[1].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[1].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
        '[2]' => {
            datacenter  => {
               '[1]'   => {
                   cluster => {
                      '[1]' => {
                          name => "ESX2-Cluster-$$",
                          drs  => 1,
                          host => "host.[2]",
                       },
                   },
               },
            },
            vds   => {
               '[1]'   => {
                   datacenter  => "vc.[2].datacenter.[1]",
                   configurehosts => "add",
                   host => "host.[2]",
                   vmnicadapter => "host.[2].vmnic.[1]",
                 },
               },
            dvportgroup  => {
               '[1]'   => {
                   vds     => "vc.[2].vds.[1]",
                   dvport   => {
                      '[1-4]' => {
                      },
                   },
                },
            },
        },
     },
     'vsm' => {
         '[1]' => {
             reconfigure => "true",
             vc          => 'vc.[1]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[1].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[1].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                  teaming      => "FAILOVER_ORDER",
                },
             },
         },
         '[2]' => {
             reconfigure => "true",
             vc          => 'vc.[2]',
             assignrole  => "enterprise_admin",
             VDNCluster => {
               '[1]' => {
                  cluster      => "vc.[2].datacenter.[1].cluster.[1]",
                  vibs         => "install",
                  switch       => "vc.[2].vds.[1]",
                  vlan         => "22",
                  mtu          => "1600",
                  vmkniccount  => "1",
                     teaming      => "FAILOVER_ORDER",
                },
             },
         },
     },
};

$OneVDS_OneDVPG_OneLAG_TwoHost_OneVMandThreeVmnicForEachHost = {
   vc    => {
      '[1]'   => {
         datacenter => {
            '[1]' => {
               host  => "host.[1-2]",
            },
         },
         vds        => {
            '[1]'   => {
               datacenter => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host  => "host.[1-2]",
               'lag' => {
                  '[1]' => {
                  },
               },
            },
         },
         dvportgroup  => {
            '[1]'   => {
               vds     => "vc.[1].vds.[1]",
               ports   => "2",
            },
         },
      },
   },
   host  => {
      '[1]'   => {
         vmnic  => {
            '[1-3]'   => {
               driver => "any",
            },
         },
         pswitchport => {
             '[1]'     => {
                vmnic => "host.[1].vmnic.[1]",
             },
             '[2]'     => {
                vmnic => "host.[1].vmnic.[2]",
             },
             '[3]'     => {
                vmnic => "host.[1].vmnic.[3]",
             },
         },
      },
      '[2]'   => {
         vmnic  => {
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
   },
   vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "vmxnet3",
               portgroup  => "vc.[1].dvportgroup.[1]",
            },
         },
      },
      '[2]'   => {
         host  => "host.[2]",
         vnic => {
            '[1]'   => {
               driver     => "vmxnet3",
               portgroup  => "vc.[1].dvportgroup.[1]",
            },
         },
      },
   },
   pswitch => {
      '[-1]' => {
      },
   },
};

$OneHost_TwoVMs_01 = {
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      },
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      }
   },
   'host' => {
      '[1]' => {
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[1].vss.[1]'
            }
         },
         'vmnic' => {
            '[1]' => {
               'driver' => 'any'
            }
         },
         'vss' => {
            '[1]' => {}
         }
      }
   }
};

$OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost_FourVMs = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => 'vc.[1]',
         assignrole  => "enterprise_admin",
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               cluster => {
                  '[1]' => {
                      name => "Controller-Cluster-1",
                      drs  => 1,
                      host => "host.[1]",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter  => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               vds     => "vc.[1].vds.[1]",
               dvport   => {
                  '[1-8]' => {
                  },
               },
            },
         },
      },
   },
   host  => {
      '[1]'   => {
         vmnic  => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   vm  => {
      '[1-4]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "vmxnet3",
               portgroup  => "vc.[1].dvportgroup.[1]",
               connected => 1,
               startconnected => 1,
               allowguestcontrol => 1,
            },
         },
      },
   },
};

$OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost = {
   'vsm' => {
      '[1]' => {
         reconfigure => "true",
         vc          => 'vc.[1]',
         assignrole  => "enterprise_admin",
      },
   },
   'vc' => {
      '[1]' => {
         datacenter  => {
            '[1]'   => {
               cluster => {
                  '[1]' => {
                      name => "Controller-Cluster-$$",
                      drs  => 1,
                      host => "host.[1]",
                  },
               },
            },
         },
         vds   => {
            '[1]'   => {
               datacenter  => "vc.[1].datacenter.[1]",
               configurehosts => "add",
               host => "host.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
            },
         },
         dvportgroup  => {
            '[1]'   => {
               vds     => "vc.[1].vds.[1]",
               dvport   => {
                  '[1-4]' => {
                  },
               },
            },
         },
      },
   },
   host  => {
      '[1]'   => {
         vmnic  => {
            '[1]'   => {
               driver => "any",
            },
         },
      },
   },
   vm  => {
      '[1]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "vmxnet3",
               portgroup  => "vc.[1].dvportgroup.[1]",
               connected => 1,
               startconnected => 1,
               allowguestcontrol => 1,
            },
         },
      },
      '[2]'   => {
         host  => "host.[1]",
         vnic => {
            '[1]'   => {
               driver     => "vmxnet3",
               portgroup  => "vc.[1].dvportgroup.[1]",
               connected => 1,
               startconnected => 1,
               allowguestcontrol => 1,
            },
         },
      },
   },
};

$OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost = {
            'vsm' => {
               '[1]' => {
                  reconfigure => "true",
                  vc          => 'vc.[1]',
                  assignrole  => "enterprise_admin",
               },
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                         cluster => {
                           '[1]' => {
                              name => "Controller-Cluster-$$",
                              drs  => 1,
                              host => "host.[1]",
                           },
                        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        connected => 1,
                        startconnected => 1,
                        allowguestcontrol => 1,
                     },
                  },
                  vmstate         => "poweron",
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        connected => 1,
                        startconnected => 1,
                        allowguestcontrol => 1,
                     },
                  },
                  vmstate         => "poweron",
               },
            },
};

$OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs = {
            'vsm' => {
               '[1]' => {
                  reconfigure => "true",
                  vc          => 'vc.[1]',
                  assignrole  => "enterprise_admin",
               },
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                         cluster => {
                           '[1]' => {
                              name => "Cluster",
                              drs  => 1,
                              host => "host.[1]",
                           },
                        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1-4]'   => {
                  host  => "host.[1]",
                  vmstate         => "poweroff",
               },
            },
};

$TwoNeutron_Clustering_functional = {
    'neutron' => {
       '[1]' => {
       },
       '[2]' => {
       },
       '[3]' => {
       },
       '[4]' => {
       },
    },
};

$Netdump_VDS  = {
    'vc' => {
      '[1]' => {
        'datacenter' => {
          '[1]' => {
            'host' => 'host.[1-2]'
          }
        },
        'dvportgroup' => {
          '[2]' => {
            'vds' => 'vc.[1].vds.[1]'
          },
          '[1]' => {
            'vds' => 'vc.[1].vds.[1]'
          }
        },
        'vds' => {
          '[1]' => {
            'datacenter' => 'vc.[1].datacenter.[1]',
            'vmnicadapter' => 'host.[1-2].vmnic.[1]',
            'configurehosts' => 'add',
            'host' => 'host.[1-2]'
          }
        }
      }
    },
    'host' => {
      '[2]' => {
        'vmnic' => {
          '[1]' => {
            'driver' => 'any'
          }
        }
      },
      '[1]' => {
        'vmnic' => {
          '[1]' => {
            'driver' => 'any'
          }
        },
        'vmknic' => {
          '[1]' => {
            'portgroup' => 'vc.[1].dvportgroup.[2]'
          }
        },
        'vss' => {
          '[1]' => {}
        },
        'portgroup' => {
          '[1]' => {
            'vss' => 'host.[1].vss.[1]'
          }
        }
      }
    },
    'vm' => {
      '[1]' => {
        'vnic' => {
          '[1]' => {
            'portgroup' => 'vc.[1].dvportgroup.[1]',
            'driver' => 'e1000'
          }
        },
        'host' => 'host.[2]'
      }
    }
};

$Netdump_VSS  = {
    'host' => {
       '[2]' => {
         'portgroup' => {
           '[1]' => {
             'vss' => 'host.[2].vss.[1]',
           },
         },
         'vss' => {
           '[1]' => {
             'configureuplinks' => 'add',
             'vmnicadapter' => 'host.[2].vmnic.[1]',
           },
         },
         'vmnic' => {
           '[1]' => {
             'driver' => 'any',
           },
         },
       },
       '[1]' => {
         'portgroup' => {
           '[2]' => {
             'vss' => 'host.[1].vss.[1]',
           },
           '[1]' => {
             'vss' => 'host.[1].vss.[1]',
           },
         },
         'vss' => {
           '[1]' => {
             'configureuplinks' => 'add',
             'vmnicadapter' => 'host.[1].vmnic.[1]',
           },
         },
         'vmnic' => {
           '[1]' => {
             'driver' => 'any',
           },
         },
         'vmknic' => {
           '[1]' => {
             'portgroup' => 'host.[1].portgroup.[2]',
           },
         },
       },
     },
     'vm' => {
       '[1]' => {
         'vnic' => {
           '[1]' => {
             'portgroup' => 'host.[2].portgroup.[1]',
             'driver' => 'e1000',
           },
         },
         'host' => 'host.[2]',
       },
     },
};

$OneVC_OneDC_OneVDS_OneDVPG_TwoHost_TwoVmknic_OneVmnicEachHost_ThreeVM = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1-2]'
            }
         },
         'dvportgroup' => {
            '[1]' => {
               'vds' => 'vc.[1].vds.[1]',
               'ports' => '6',
            }
         },
         'vds' => {
            '[1]' => {
               'datacenter' => 'vc.[1].datacenter.[1]',
               'vmnicadapter' => 'host.[1-2].vmnic.[1]',
               'configurehosts' => 'add',
               'host' => 'host.[1-2]'
            }
         }
      }
   },
   'host' => {
	'[1-2]' => {
	    'vmnic' => {
		'[1]' => {
		    'driver' => 'any'
		    }
		},
            'vmknic' => {
		'[1]' => {
		    'portgroup' => 'vc.[1].dvportgroup.[1]',
		    }
		}
	    }
	},
   'vm' => {
      '[1]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]',
         'datastoreType' => 'shared',
      },
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'vc.[1].dvportgroup.[1]',
               'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[1]'
      },
      '[3]' => {
         'vnic' => {
            '[1]' => {
              'portgroup' => 'vc.[1].dvportgroup.[1]',
              'driver' => 'vmxnet3'
            }
         },
         'host' => 'host.[2]'
      },
   }
};

$OneHost_TwoVMs_NETIOC = {
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               'host' => 'host.[1]'
            },
         },
       'dvportgroup' => {
          '[1]' => {
             'vds' => 'vc.[1].vds.[1]',
                dvport  => {
                   '[1-10]' => {
                   },
                },
         },
         '[2]' => {
            'vds' => 'vc.[1].vds.[2]',
            dvport   => {
               '[1-10]' => {
               },
            },
         },
      },

     'vds' => {
        '[1]' => {
            'datacenter' => 'vc.[1].datacenter.[1]',
            'vmnicadapter' => 'host.[1].vmnic.[1]',
            'configurehosts' => 'add',
            'host' => 'host.[1]',
            'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
            'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
            'niocinfrastructuretraffic'  => {
                 'virtualMachine' => "500:100:1000",
             },
        },
        '[2]' => {
            'datacenter' => 'vc.[1].datacenter.[1]',
            'vmnicadapter' => 'host.[1].vmnic.[2]',
            'configurehosts' => 'add',
            'host' => 'host.[1]',
            'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
          },
       },
      },
     },
     'host' => {
        '[1]' => {
           'vmnic' => {
                '[1-2]' => {
                    'driver' => 'any'
                },
           },
        },
     },
     'vm' => {
        '[1]' => {
            'vnic' => {
               '[1-2]' => {
                   'portgroup' => 'vc.[1].dvportgroup.[1]',
                   'driver' => 'vmxnet3',
                   shares      => "50",
                   reservation => "100",
                   limit       => "1000",
                   connected   => 1,
                   startconnected    => 1,
                   allowguestcontrol => 1,
               },
            },
            'host' => 'host.[1]'
      },
      '[2]' => {
          'vnic' => {
             '[1]' => {
                 'portgroup' => 'vc.[1].dvportgroup.[2]',
                 'driver' => 'vmxnet3',
             },
           },
           'host' => 'host.[1]'
       },
    },

};

$OneHost_FiveVMs_NETIOC = {
   'vc' => {
      '[1]' => {
          'datacenter' => {
              '[1]' => {
                  'host' => 'host.[1]'
              },
           },
           'dvportgroup' => {
                '[1]' => {
                    'vds' => 'vc.[1].vds.[1]',
                        dvport   => {
                           '[1-10]' => {
                           },
                        },
                },
                '[2]' => {
                    'vds' => 'vc.[1].vds.[2]',
                        dvport   => {
                           '[1-10]' => {
                           },
                        },
                     },
                 },

                 'vds' => {
                    '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[1]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                        'niocinfrastructuretraffic'  => {
                            'virtualMachine' => "750:100:1000",
                        },
                   },
                   '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                   },
                },
              },
       },
       'host' => {
          '[1]' => {
             'vmnic' => {
                 '[1-2]' => {
                     'driver' => 'any'
                 },
              },
           },
       },
       'vm' => {
          '[1]' => {
              'vnic' => {
                 '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[1]',
                      'driver' => 'vmxnet3',
                       shares      => "50",
                       reservation => "450",
                       limit       => "1000",
                       connected   => 1,
                       startconnected    => 1,
                       allowguestcontrol => 1,
                },
             },
             'host' => 'host.[1]'
          },
          '[2-4]'   => {
	     host  => "host.[1]",
             vnic => {
                '[1]'   => {
                        driver	   => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "100",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                },
             },
         },
         '[5]' => {
             'vnic' => {
                '[1]' => {
                   'portgroup' => 'vc.[1].dvportgroup.[2]',
                   'driver' => 'vmxnet3',
                },
             },
             'host' => 'host.[1]'
         },
    },
    };

$nvsWithNVPTopology01 = {
      'nvpcontroller' => {
         '[1]' => {
         },
      },
      'host' => {
         '[1]' => {
            vib               => "install",
            maintenance   => 1,
            signaturecheck    => 0,
            'vmnic' => {
               '[0]' => {
                   'interface' => "vmnic0",
                },
               '[1-2]' => {
                  'driver' => 'any'
               },
            },
            'portgroup' => {
               '[0]' => {
                  'name' => "Management Network",
                  'vss' => 'host.[1].vss.[0]',
               },
               '[1]' => {
                  'vss' => 'host.[1].vss.[1]'
               },
            },
            'vmknic' => {
               '[0]' => {
                  'interface'  => "vmk0",
                  'portgroup' => 'host.[1].portgroup.[1]',
               },
               '[1]' => {
                  'portgroup' => 'host.[1].portgroup.[1]'
               },
            },
            'vss' => {
               '[1]' => {
                  'configureuplinks' => 'add',
                  'vmnicadapter' => 'host.[1].vmnic.[2]'
               },
            },
            ovs   => {
               '[1]' => {
                  switch  => "nsx-vswitch"
               },
            },
            nvpnetwork   => {
               '[1]' => {
                  name   => "nvp-1",
                  ovs    => "host.[1].ovs.[1]",
               },
            },
         },
         '[2]' => {
            vib               => "install",
            maintenance   => 1,
            signaturecheck    => 0,
            'vmnic' => {
               '[1-2]' => {
                  'driver' => 'any'
               },
            },
            'portgroup' => {
               '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
               },
            },
            'vmknic' => {
               '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]'
               },
            },
            'vss' => {
               '[1]' => {
                  'configureuplinks' => 'add',
                  'vmnicadapter' => 'host.[2].vmnic.[2]'
               },
            },
            ovs   => {
               '[1]' => {
                  switch  => "nsx-vswitch"
               },
            },
            nvpnetwork   => {
               '[1]' => {
                  name  => "nvp-1",
                  ovs   => "host.[2].ovs.[1]",
               },
            },
         },
      },
      'vm' => {
         '[2]' => {
            'vnic' => {
               '[1]' => {
                  'portgroup' => 'host.[2].nvpnetwork.[1]',
                  'driver' => 'e1000'
               }
            },
            'host' => 'host.[2]'
         },
         '[1]' => {
            'datastoreType' => 'shared',
            'vnic' => {
               '[1]' => {
                  'portgroup' => 'host.[1].nvpnetwork.[1]',
                  'driver' => 'e1000'
               }
            },
            'host' => 'host.[1]'
         }
      },
      'vc' => {
         '[1]' => {
            'datacenter' => {
               '[1]' => {
                  Cluster => {
                     '[1]' => {
                        host => "host.[1-2]",
                        name => "NVS-Cluster-$$",
                     },
                  },
               },
            },
         },
      },
};

$nvpStandardTopology01 = {
   'nvpcontroller' => {
      '[1]' => {
      },
   },
   'host' => {
      '[1]' => {
         vib               => "install",
         maintenance   => 1,
         signaturecheck    => 0,
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[1].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
         },
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               name   => "nvp-1",
               ovs    => "host.[1].ovs.[1]",
            },
         },
      },
      '[2]' => {
         vib               => "install",
         maintenance   => 1,
         signaturecheck    => 0,
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[2].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[2].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
         },
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               name  => "nvp-1",
               ovs   => "host.[2].ovs.[1]",
            },
         },
      },
   },
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[2].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[2].x.[x]'
      },
      '[1]' => {
         'datastoreType' => 'shared',
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[1].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      }
   },
   'vc' => {
      '[1]' => {
         'datacenter' => {
            '[1]' => {
               Cluster => {
                  '[1]' => {
                     host => "host.[1-2]",
                     name => "NVS-Cluster-$$",
                  },
               },
            },
         },
      },
   },
};

$nvpWithNoVCTopology01 = {
   'nvpcontroller' => {
      '[1]' => {
      },
   },
   'host' => {
      '[1]' => {
         vib               => "install",
         maintenance   => 1,
         signaturecheck    => 0,
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[1].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[1].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[1].vmnic.[2]'
            },
         },
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               name   => "nvp-1",
               ovs    => "host.[1].ovs.[1]",
            },
         },
      },
      '[2]' => {
         vib               => "install",
         maintenance   => 1,
         signaturecheck    => 0,
         'vmnic' => {
            '[1-2]' => {
               'driver' => 'any'
            },
         },
         'portgroup' => {
            '[1]' => {
               'vss' => 'host.[2].vss.[1]'
            },
         },
         'vmknic' => {
            '[1]' => {
               'portgroup' => 'host.[2].portgroup.[1]'
            },
         },
         'vss' => {
            '[1]' => {
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[2].vmnic.[2]'
            },
         },
         ovs   => {
            '[1]' => {
               switch  => "nsx-vswitch"
            },
         },
         nvpnetwork   => {
            '[1]' => {
               name  => "nvp-1",
               ovs   => "host.[2].ovs.[1]",
            },
         },
      },
   },
   'vm' => {
      '[2]' => {
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[2].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[2].x.[x]'
      },
      '[1]' => {
         'datastoreType' => 'shared',
         'vnic' => {
            '[1]' => {
               'portgroup' => 'host.[1].nvpnetwork.[1]',
               'driver' => 'e1000'
            }
         },
         'host' => 'host.[1].x.[x]'
      }
   },
};

$OneHost_FiveVMs_NETIOC_Teaming = {
   'vc' => {
      '[1]' => {
          'datacenter' => {
              '[1]' => {
                  'host' => 'host.[1]'
              },
           },
           'dvportgroup' => {
                '[1]' => {
                    'vds' => 'vc.[1].vds.[1]',
                        dvport   => {
                           '[1-10]' => {
                           },
                        },
                },
                '[2]' => {
                    'vds' => 'vc.[1].vds.[2]',
                        dvport   => {
                           '[1-10]' => {
                           },
                        },
                     },
                 },

                 'vds' => {
                    '[1]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                        'niocinfrastructuretraffic'  => {
                            'virtualMachine' => "750:100:1000",
                        },
                   },
                   '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[3]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                   },
                },
              },
       },
       'host' => {
          '[1]' => {
             'vmnic' => {
                 '[1-3]' => {
                     'driver' => 'any'
                 },
              },
           },
       },
       'vm' => {
          '[1]' => {
              'vnic' => {
                 '[1]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[1]',
                      'driver' => 'vmxnet3',
                       shares      => "50",
                       reservation => "450",
                       limit       => "1000",
                       connected   => 1,
                       startconnected    => 1,
                       allowguestcontrol => 1,
                },
             },
             'host' => 'host.[1]'
          },
          '[2-4]'   => {
	     host  => "host.[1]",
             vnic => {
                '[1]'   => {
                        driver	   => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "100",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                },
             },
         },
         '[5]' => {
             'vnic' => {
                '[1]' => {
                   'portgroup' => 'vc.[1].dvportgroup.[2]',
                   'driver' => 'vmxnet3',
                },
             },
             'host' => 'host.[1]'
         },
    },

};

$OneVC_OneDC_TwoVDS_TwoHost_OneVmnicEachHost = {
    'vc' => {
      '[1]' => {
        'datacenter' => {
          '[1]' => {
            'host' => 'host.[1-2]'
          }
        },
        'vds' => {
          '[1]' => {
            'datacenter' => 'vc.[1].datacenter.[1]',
            'vmnicadapter' => 'host.[1].vmnic.[1]',
            'configurehosts' => 'add',
            'host' => 'host.[1]'
          },
          '[2]' => {
            'datacenter' => 'vc.[1].datacenter.[1]',
            'vmnicadapter' => 'host.[2].vmnic.[1]',
            'configurehosts' => 'add',
            'host' => 'host.[2]'
          },
        }
      }
    },
    'host' => {
      '[1-2]' => {
        'vmnic' => {
          '[1]' => {
            'driver' => 'any'
          }
        },
      }
    },
};

$OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM = {
  'vc' => {
    '[1]' => {
            'datacenter' => {
                     '[1]' => {
                        'cluster' => {
                              '[1]'  => {
                              host => "host.[1-2]",
                              ha => "1",
                              clustername => "FT",
                              },
                        },
                        'host' => 'host.[3]',
                     }
            },
            'dvportgroup' => {
                      '[1]' => {
                         'vds' => 'vc.[1].vds.[1]',
                         'name' => 'FT-Portgroup',
                       },
                      '[2]' => {
                         'vds' => 'vc.[1].vds.[2]',
                         'name' => 'vMotion-Portgroup',
                      },
                      '[3]' => {
                         'vds' => 'vc.[1].vds.[3]',
                         'name' => 'VM-Portgroup',
                     },
            },
            'vds' => {
                '[1]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]',
                    'name' => 'VDS-FT',
                    },
                '[2]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-2].vmnic.[2]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-2]',
                    'name' => 'VDS-vMotion',
                    },
                '[3]' => {
                    'datacenter' => 'vc.[1].datacenter.[1]',
                    'vmnicadapter' => 'host.[1-3].vmnic.[3]',
                    'configurehosts' => 'add',
                    'host' => 'host.[1-3]',
                    'name' => 'VDS-VM',
                    }
            }
     }
  },
  'host' => {
        '[1-2]' => {
            'vmnic' => {
                '[1]' => {
                    'driver' => 'ixgbe',
                    },
                '[2]' => {
                    'driver' => 'ixgbe',
                    },
                '[3]' => {
                    'driver' => 'any',
                    }
                },
            'vmknic' => {
                '[1]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[1]',
                    'configureservices' => {
                                           'FTLOGGING' => 1,
                                           },
                    },
                '[2]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[2]',
                    'configureservices' => {
                                           'VMOTION' => 1,
                                           },
                    },
                '[3]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]',
                    },
                }
         },
        '[3]' => {
            'vmnic' => {
                '[3]' => {
                    'driver' => 'any',
                    }
                },
            'vmknic' => {
                '[3]' => {
                    'portgroup' => 'vc.[1].dvportgroup.[3]',
                    }
                }
        }
  },
  'vm' => {
       '[1]' => {
            'vnic' => {
                '[1]' => {
                      portgroup => 'vc.[1].dvportgroup.[3]',
                      connected => 1,
                      startconnected => 1,
                      allowguestcontrol => 1,
                     }
                  },
        'host' => 'host.[1]',
        },
        '[2]' => {
            'vnic' => {
                '[1]' => {
                     portgroup => 'vc.[1].dvportgroup.[3]',
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                    }
                },
        'host' => 'host.[3]',
        },
        '[3]' => {
            'vnic' => {
                '[1]' => {
                      portgroup => 'vc.[1].dvportgroup.[3]',
                      connected => 1,
                      startconnected => 1,
                      allowguestcontrol => 1,
                     }
                  },
        'host' => 'host.[2]',
        }
  }
};

1;
