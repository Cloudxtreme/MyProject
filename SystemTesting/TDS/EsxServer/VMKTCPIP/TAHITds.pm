#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::EsxServer::VMKTCPIP::TAHITds;

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
    %TAHI = (
        'icmp' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'icmp',
          'Summary' => 'Run INDEX_p2_host_icmp module ',
          'ExpectedResult' => 'PASS',
          'Tags' => 'CAT_P0',
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_icmp'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_icmp' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '3600',
              'tahi' => [
                'ipv6ready_p2_host_icmp'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'pmtu' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'pmtu',
          'Summary' => 'Run INDEX_p2_host_pmtu module ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_pmtu'
              ]
            ],
            'ExitSequence' => [
              [
                'DisablePromiscuous'
              ],
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_pmtu' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '3600',
              'tahi' => [
                'ipv6ready_p2_host_pmtu'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'DisablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Disable'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'IPSec' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'IPSec',
          'Summary' => 'Run INDEX_p2_end_node IPSec module ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_spec'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_spec' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '3600',
              'tahi' => [
                'ipv6ready_p2_end_node'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'Core' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'Core',
          'Summary' => 'Run INDEX_p2_host_spec module ',
          'ExpectedResult' => 'PASS',
          'Tags' => 'CAT_CANDIDATE',
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_spec'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_spec' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '10800',
              'tahi' => [
                'ipv6ready_p2_host_spec'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'RFC3315' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'RFC3315',
          'Summary' => 'Run INDEX_p2_client_rfc3315 module ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_client_rfc3315'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_client_rfc3315' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '14400',
              'tahi' => [
                'ipv6ready_p2_client_rfc3315'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'NeighborDiscovery' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'NeighborDiscovery',
          'Summary' => 'Run INDEX_p2_host_nd module ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_nd'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_nd' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '14400',
              'tahi' => [
                'ipv6ready_p2_host_nd'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },

        'StatelessAddress' => {
          'Component' => 'VMKTCPIP',
          'Category' => 'ESX Server',
          'TestName' => 'StatelessAddress',
          'Summary' => 'Run INDEX_p2_host_addr module ',
          'ExpectedResult' => 'PASS',
          'Tags' => undef,
          'AutomationLevel'  => 'Automated',
          'FullyAutomatable' => 'Y',
          'Version' => '2',
          'TestbedSpec' => {
            'host' => {
              '[1]' => {
                'portgroup' => {
                  '[1-2]' => {
                    'vss' => 'host.[1].vss.[1]'
                  },
                },
                'vss' => {
                  '[1]' => {
                  }
                },
                'vmknic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[2]'
                  }
                },
              }
            },
            'vm' => {
              '[1]' => {
                'vnic' => {
                  '[1]' => {
                    'portgroup' => 'host.[1].portgroup.[1]',
                    'driver' => 'e1000'
                  }
                },
                'host' => 'host.[1]'
              }
            }
          },
          'WORKLOADS' => {
            'Sequence' => [
              [
                'EnablePromiscuous'
              ],
              [
                'Index_p2_host_addr'
              ]
            ],
            'ExitSequence' => [
              [
                  'PowerOffVM'
              ]
            ],
            'Iterations' => '1',
            'EnablePromiscuous' => {
              'Type' => 'Switch',
              'TestSwitch' => 'host.[1].vss.[1]',
              'setpromiscuous' => 'Enable'
            },
            'Index_p2_host_addr' => {
              'Type' => 'Suite',
              'testadapter' => 'host.[1].vmknic.[1]',
              'maxtimeout' => '18000',
              'tahi' => [
                'ipv6ready_p2_host_addr'
              ],
              'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'PowerOffVM' => {
                'Type' => 'VM',
                'TestVM' => 'vm.[1]',
                'vmstate' => 'poweroff',
            }
          }
        },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for TAHI.
#
# Input:
#       None.
#
# Results:
#       An instance/object of TAHI class.
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
   my $self = $class->SUPER::new(\%TAHI);
   return (bless($self, $class));
}
