########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::VDS2BkpRstTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
%VDS2BkpRst = (
		'ImportVDS' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportVDS',
		  'Summary' => 'Creates the VDS configuration from the backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSConfig'
		      ],
		      [
		        'ImportVDSConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ImportVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},


		'RestoreDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'RestoreDVPG',
		  'Summary' => 'Restores the dvPort group configuration from the' .
		               ' backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportDVPGConfig'
		      ],
		      [
		        'RestoreDVPGConfig'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'RestoreDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'restoredvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'PingTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1'
		    }
		  }
		},


		'ExportVDSDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ExportVDSDVPG',
		  'Summary' => 'Exports the VDS and its dvPort groups configuration.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSDVPGConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},


		'ImportVDSDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportVDSDVPG',
		  'Summary' => 'Creates the VDS and dvPort groups configuration from ' .
		               'backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSDVPGConfig'
		      ],
		      [
		        'ImportVDSDVPGConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ImportVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},


		'ExportDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ExportDVPG',
		  'Summary' => 'Exports the dvPort group configuration.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportDVPGConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},


		'RestoreVDSDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'RestoreVDSDVPG',
		  'Summary' => 'Restores the VDS and its dvPort groupconfiguration ' .
		               'from the backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => 'CAT_P0',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSDVPGConfig'
		      ],
		      [
		        'RestoreVDSDVPGConfig'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'RestoreVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'restorevdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'PingTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1'
		    }
		  }
		},


		'RestoreVDS' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'RestoreVDS',
		  'Summary' => 'Restores the VDS configuration fromthe backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
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
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSConfig'
		      ],
		      [
		        'RestoreVDSConfig'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'RestoreVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'restorevds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'PingTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1'
		    }
		  }
		},


		'ExportVDS' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ExportVDS',
		  'Summary' => 'Exports the VDS configuration.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},


		'ImportDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportDVPG',
		  'Summary' => 'Creates the dvPort group configuration from backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportDVPGConfig'
		      ],
		      [
		        'ImportDVPGConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ImportDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},

		'ImportOrigDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportOrigDVPG',
		  'Summary' => 'Creates the dvPort group configuration ' .
		               'with original identifier from backup file.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VDS::VDS2BkpRst::ImportOrigDVPG',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
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
		      },
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
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportDVPGConfig'
		      ],
		      [
		        'ChangePortgroup1'
		      ],
		      [
		        'ChangePortgroup2'
		      ],
		      [
		        'RemoveDVPortgroup'
		      ],
		      [
		        'ImportOrigDVPGConfig'
		      ],
		      [
		        'ChangePortgroup3'
		      ],
		      [
		        'ChangePortgroup4'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[1]'
		    },
		    'ChangePortgroup2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[2].portgroup.[1]'
		    },
		    'RemoveDVPortgroup' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'deleteportgroup' => 'vc.[1].dvportgroup.[1]',
		      'skipPostProcess' => 1
		    },
		    'ImportOrigDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importorigdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'PingTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1'
		    }
		  }
		},

		'ImportOrigVDSDVPG' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportOrigVDSDVPG',
		  'Summary' => 'Creates VDS and dvpg with original identifier.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::VDS2BkpRst::ImportOrigVDSDVPG',
		  'TestbedSpec' => {
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
		    'vm' => {
		      '[2]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[2].x.[x]'
		      },
		      '[1]' => {
		        'vnic' => {
		          '[1]' => {
		            'portgroup' => 'vc.[1].dvportgroup.[1]',
		            'driver' => 'e1000'
		          }
		        },
		        'host' => 'host.[1].x.[x]'
		      }
		    },
		    'host' => {
		      '[2]' => {
		        'portgroup' => {
		          '[1]' => {
		            'vss' => 'host.[2].vss.[1]'
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
		      },
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
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSDVPGConfig'
		      ],
		      [
		        'ChangePortgroup1'
		      ],
		      [
		        'ChangePortgroup2'
		      ],
		      [
		        'RemoveVDS'
		      ],
		      [
		        'ImportOrigVDSDVPGConfig'
		      ],
		      [
		        'ChangePortgroup3'
		      ],
		      [
		        'ChangePortgroup4'
		      ],
		      [
		        'PingTraffic'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup1' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[1].portgroup.[1]'
		    },
		    'ChangePortgroup2' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'host.[2].portgroup.[1]'
		    },
		    'RemoveVDS' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'deletevds' => 'vc.[1].vds.[1]',
		      'skipPostProcess' => 1
		    },
		    'ImportOrigVDSDVPGConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importorigvdsdvpg',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup3' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[1].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'ChangePortgroup4' => {
		      'Type' => 'NetAdapter',
		      'TestAdapter' => 'vm.[2].vnic.[1]',
		      'reconfigure' => 'true',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'PingTraffic' => {
		      'Type' => 'Traffic',
		      'noofoutbound' => '1',
		      'testduration' => '30',
		      'toolname' => 'ping',
		      'noofinbound' => '1'
		    }
		  }
		},

		'ImportOrigVDS' => {
		  'Component' => 'VPX',
		  'Category' => 'Virtual-Networking',
		  'TestName' => 'ImportOrigVDS',
		  'Summary' => 'Creates VDS config with original identifier.',
		  'ExpectedResult' => 'PASS',
		  'Tags' => undef,
		  'Version' => '2',
		  'testID' => 'TDS::EsxServer::VDS::VDS2BkpRst::ImportOrigVDS',
		  'AutomationStatus' => 'Automated',
		  'TestbedSpec' => {
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
		        }
		      }
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'ExportVDSConfig'
		      ],
		      [
		        'RemoveVDS'
		      ],
		      [
		        'ImportOrigVDSConfig'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'ExportVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'exportvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    },
		    'RemoveVDS' => {
		      'Type' => 'VC',
		      'TestVC' => 'vc.[1].x.[x]',
		      'deletevds' => 'vc.[1].vds.[1]',
		      'skipPostProcess' => 1
		    },
		    'ImportOrigVDSConfig' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'backuprestore' => 'importorigvds',
		      'portgroup' => 'vc.[1].dvportgroup.[1]'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VDS2BkpRst.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDS2BkpRst class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VDS2BkpRst);
   return (bless($self, $class));
}
