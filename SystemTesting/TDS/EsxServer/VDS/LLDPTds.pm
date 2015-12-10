#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::LLDPTds;

#
# This file contains the structured hash for vDS + (LLDP) category.
# Link Layer Discovery protocol is supported only with vNetwork
# Distributed Switch.
#
# This file has the following set of test cases. For details about
# each and every case please see the TDS at following location.
# //depot/documentation/MN/Networking-FVT/TDS/
# VMkernel_ESX_vDS+_Switching_Test_Design_Specification.doc
#
# a) ESX::Network.Switch.vDS+::Functional::LLDP.BasicConfiguration
# b) ESX::Network.Switch.vDS+::Functional::LLDP.BasicConfiguration.Persistance
# c) ESX::Network.Switch.vDS+::Functional::LLDP.Listen
# d) ESX::Network.Switch.vDS+::Functional::LLDP.Advertise
# e) ESX::Network.Switch.vDS+::Functional::LLDP.Both
# f) ESX::Network.Switch.vDS+::Functional::LLDP.DefaultSettings
#
# For running these tests one must have one ESX host with at least
# one pNIC connected to a cisco switch, one VC server, The cisco
# switch must support LLDP. To get LLDP support the IOS version
# must be later than 12.2(37)SE. The cisco switch must have
# telnet access enabled with default standard credentails as
# vmware/ca$ch0w.
#
# The command line to run the tests is as below
# ./main/vdNet.pl -sut "host=<esx_ip>,pswitch=<address>" -vc <address>
# -t EsxServer.VDS.LLDP.<testname>
#
# for e.g. to run LLDP advertise test.
# ./main/vdNet.pl -src 10.112.24.119
# -sut "host=10.112.24.37,pswitch=10.112.24.56"
# -vc 10.112.24.118 -t EsxServer.VDS.LLDP.LLDPAdvertise
#
# Some important keys used are -
#
# a) lldp - This is the key to set the lldp status, for vDS
#           one can pass either listen, advertise, both and
#           none. Passing none would disable the LLDP. For
#           physical switch these values don't matter except
#           none which would disable the LLDP on physical switch.
#           This is because for physical switch it enables the
#           global lldp.
#
# b) setlldptransmitport - this key is used to enable/disable
#                          the transmission of LLDP info for
#                          the specific port. The port id where
#                          one needs to enable or disable LLDP
#                          must be passed with this. We get the
#                          port id by passing the index to the pNIC
#                          which is initialized with the port id
#                          during the initialization part.
#
# c) setlldpreceive - this key is used to enable/disable the
#                     reception of LLDP info for the specific
#                     port. The port id where one needs to enable
#                     or disable the reception of LLDP info must
#                     be passed. As in transmit mode we get the
#                     port id by passing the index to the pNIC
#                     which is initialized with the port id
#                     during the initialization part.
#
# d) checklldponesx - This key is used to verify the lldp info
#                     received by ESX. Inside this method we
#                     verify the information presented by LLDP
#                     and make sure it matches with the info
#                     we have about pNIC. When value passed is
#                     "yes", it means we are expecting the info
#                      to be present. when the value passed is
#                      "no", it means we don't expect LLDP info.
#
# e)checklldponswitch - This same as checklldponesx except that
#                       it does the verification on the physical
#                       switch side.
#
#
#

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("BasicConfiguration","PersistentConfiguration","LLDPListen", "LLDPAdvertise",
             "LLDPBoth","LLDPDefaultSettings");
   %LLDP = (
		'LLDPAdvertise' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'LLDPAdvertise',
		  'Summary' => 'Verify that LLDP configuration works correctly when vDS ' .
		               'LLDP mode is Advertise ',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'rpmt,bqmt,physicalonly',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::LLDPAdvertise',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'ReceiveMode'
		      ],
		      [
		        'ReceiveInfo'
		      ],
		      [
		        'TransmitMode'
		      ],
		      [
		        'TransmitInfo'
		      ]
		    ],
		    'ExitSequence' => [
                      [
                        'SetSwitchPortLLDP'
                      ],
		      [
		        'CDP'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'advertise'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'listen'
		    },
		    'ReceiveMode' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Disable'
		    },
		    'ReceiveInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'no',
		      'checklldponswitch' => 'yes'
		    },
		    'TransmitMode' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Disable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'TransmitInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'no',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'no'
		    },
		    'SetSwitchPortLLDP' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
		},


		'LLDPListen' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'LLDPListen',
		  'Summary' => 'Verify that Basic LLDP configuration works when LLDP for' .
		               ' vDS is set to listen mode',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'physicalonly',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::LLDPListen',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'ReceiveMode'
		      ],
		      [
		        'ReceiveInfo'
		      ],
		      [
		        'TransmitMode'
		      ],
		      [
		        'TransmitInfo'
		      ]
		    ],
		    'ExitSequence' => [
		      [
                        'SetSwitchPortLLDP'
                      ],
                      [
		        'CDP'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'listen'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'listen'
		    },
		    'ReceiveMode' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Disable'
		    },
		    'ReceiveInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'no',
		      'checklldponswitch' => 'no'
		    },
		    'TransmitMode' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Disable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'TransmitInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'yes',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'no'
		    },
                    'SetSwitchPortLLDP' => {
                      'Type' => 'Port',
                      'TestPort' => 'host.[1].pswitchport.[1]',
                      'setlldpreceiveport' => 'Enable',
                      'setlldptransmitport' => 'Enable'
                    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
		},


		'BasicConfiguration' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'BasicConfiguration',
		  'Summary' => 'Verify that Basic LLDP configuration works for vDS and ' .
		               'for physical switch',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'CAT_P0,physicalonly',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::BasicConfiguration',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'EnableLLDPPort'
		      ],
		      [
		        'LLDPInfo'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPPort' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'LLDPInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'yes',
		      'checklldponswitch' => 'yes',
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
		},


		'LLDPDefaultSettings' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'LLDPDefaultSettings',
		  'Summary' => 'Verify that by default for a vDS LLDP should not be ' .
		               'enabled, and it should not receive any LLDP information',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'physicalonly',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::LLDPDefaultSettings',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'CheckDefaultSettings'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'LLDPOnSwitchPort'
		      ],
		      [
		        'ReceiveInfo'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'CheckDefaultSettings' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'no'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'listen'
		    },
		    'LLDPOnSwitchPort' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'ReceiveInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'no',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'no'
		    }
		  }
		},


		'LLDPBoth' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'LLDPBoth',
		  'Summary' => 'Verify that Basic configuration works when LLDP for vDS' .
		               ' is set to both mode',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'rpmt,bqmt,physicalonly',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::LLDPBoth',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'SetSwitchPortLLDP'
		      ],
		      [
		        'LLDPInfo'
		      ]
		    ],
		    'ExitSequence' => [
		      [
		        'CDP'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'listen'
		    },
		    'SetSwitchPortLLDP' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'LLDPInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'yes',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'yes'
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
		},


		'PersistentConfiguration' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'PersistentConfiguration',
		  'Summary' => 'Verify that Basic LLDP configuration persists for vDS ' .
		               'after host reboot',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'hostreboot,physicalonlygs',
		  'Version' => '2',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::PersistentConfiguration',
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
		        },
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'EnableLLDPPort'
		      ],
		      [
		        'LLDPInfo'
		      ],
		      [
		        'RebootHost'
		      ],
		      [
		        'LLDPInfo'
		      ]
		    ],
		    'Duration' => 'time in seconds',
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPPort' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'LLDPInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'yes',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'yes'
		    },
		    'RebootHost' => {
		      'Type' => 'Host',
		      'TestHost' => 'host.[1].x.[x]',
		      'reboot' => 'yes'
		    }
		  }
		},

                'ChangeMulticastMode' => {
		  'Component' => 'vDS',
		  'Category' => 'ESX Server',
		  'TestName' => 'ChangeMulticastMode',
		  'Summary' => 'Verify that after change Multicast filtering mode' .
		               ' LLDP can still work',
		  'ExpectedResult' => 'PASS',
		  'AutomationStatus'  => 'Automated',
		  'Tags' => 'rpmt,bqmt',
		  'Version' => '2',
		  'Duration' => 'time in seconds',
		  'AutomationStatus' => 'Automated',
		  'testID' => 'TDS::EsxServer::VDS::LLDP::ChangeMulticastMode',
		  'TestbedSpec' => {
		    'vc' => {
		      '[1]' => {
		        'datacenter' => {
		          '[1]' => {
		            'host' => 'host.[1]'
		          }
		        },
		        'vds' => {
		          '[1]' => {
		            'datacenter' => 'vc.[1].datacenter.[1]',
		            'vmnicadapter' => 'host.[1].vmnic.[1]',
		            'configurehosts' => 'add',
		            'host' => 'host.[1]'
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
		        'pswitchport' => {
		          '[1]' => {
		            'vmnic' => 'host.[1].vmnic.[1]'
		          }
		        }
		      }
		    },
		    'pswitch' => {
		      '[-1]' => {}
		    }
		  },
		  'WORKLOADS' => {
		    'Sequence' => [
                      [
		        'SetMulticastSnoopingMode'
		      ],
		      [
		        'LLDPOnVDS'
		      ],
		      [
		        'EnableLLDPOnSwitch'
		      ],
		      [
		        'SetSwitchPortLLDP'
		      ],
		      [
		        'LLDPInfo'
		      ]
		    ],
		    'ExitSequence' => [
                      [
                        'RevertMulticastSnoopingMode'
                      ],
		      [
		        'CDP'
		      ]
                    ],
                    'SetMulticastSnoopingMode' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'multicastfilteringmode' => "snooping",
		    },
                    'RevertMulticastSnoopingMode' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'multicastfilteringmode' => "legacyFiltering",
		    },
		    'LLDPOnVDS' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'lldp' => 'both'
		    },
		    'EnableLLDPOnSwitch' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'pswitch.[-1].x.[x]',
		      'lldp' => 'listen'
		    },
		    'SetSwitchPortLLDP' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'setlldpreceiveport' => 'Enable',
		      'setlldptransmitport' => 'Enable'
		    },
		    'LLDPInfo' => {
		      'Type' => 'Port',
		      'TestPort' => 'host.[1].pswitchport.[1]',
		      'checklldponesx' => 'yes',
		      'sleepbetweencombos' => '185',
		      'checklldponswitch' => 'yes'
		    },
		    'CDP' => {
		      'Type' => 'Switch',
		      'TestSwitch' => 'vc.[1].vds.[1]',
		      'configure_cdp_mode' => 'listen'
		    }
		  }
		},
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for LLDP.
#
# Input:
#       None.
#
# Results:
#       An instance/object of LLDP class.
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
   my $self = $class->SUPER::new(\%LLDP);
   return (bless($self, $class));
}
