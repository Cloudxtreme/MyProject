#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::EventThresholdsTds;

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %EventThresholds = (
      'VerifyThresholdEvents'   => {
         TestName         => 'VerifyThresholdEvents',
         Category         => 'vShield-REST-APIs',
         Component        => 'System Events',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Verification for CPU/MEMORY/CPS events',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'paib',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      =>  {
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
                               name => "Cluster-1",
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
               '[1-2]'   => {
                  host  => "host.[1]",
                  datastoreType => 'shared',
                  installtype => 'ovfdeploy',
                  ovfurl => 'http://engweb.eng.vmware.com/~netfvt/ovf/lighttpdtool/VMTrafficTool.ovf',
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
         },
         WORKLOADS => {
            Sequence => [
               ['PrepCluster'],
               ['ConfigureThresholds'],
               ['EnableGlobalFlowCollection'],
               ['SetDFWRules'],
               ['CheckSystemEvents'],
               ['HTTPTraffic'],
               ['CheckNewSystemEvents'],
            ],
            ExitSequence => [
               ['RevertThresholds'],
               ['DisableGlobalFlowCollection'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'PrepCluster' => {
               Type    => 'NSX',
               TestNSX => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'EnableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "true",
                  }
               },
            },
            'DisableGlobalFlowCollection' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               config_flow_exclusion   => {
                  '[1]' => {
                     collectflows => "false",
                  }
               },
            },
            'ConfigureThresholds' => {
               Type   => 'NSX',
               TestNSX  => 'vsm.[1]',
               thresholdconfig => {
                  '[1]' => {
                      cputhreshold => {
                         percentvalue => 1,
                      },
                      cpsthreshold => {
                         value => 1000,
                      },
                      memorythreshold => {
                         percentvalue => 1,
                      },
                  },
               },
            },
            'RevertThresholds' => {
               Type   => 'NSX',
               TestNSX  => 'vsm.[1]',
               thresholdconfig => {
                  '[1]' => {
                      cpsthreshold => {
                         value => 10000,
                      },
                      cputhreshold => {
                         percentvalue => 100,
                      },
                      memorythreshold => {
                         percentvalue => 100,
                      },
                  },
               },
            },
            'CheckSystemEvents' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               PersistData => 'Yes',
               checkthresholdevent => {
                   'cpu_ts[?]defined' => '',
                   'cpu_event_count[?]defined' => '',
                   'mem_ts[?]defined' => '',
                   'mem_event_count[?]defined' => '',
                   'cps_ts[?]defined' => '',
                   'cps_event_count[?]defined' => '',
               },
            },
            'CheckNewSystemEvents' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               PersistData => 'Yes',
               checkthresholdevent => {
                   'cpu_ts[?]>' => 'vsm.[1]->checkthresholdevent->cpu_ts',
                   'cpu_event_count[?]>' => 'vsm.[1]->checkthresholdevent->cpu_event_count',
                   #will uncommnet after PR 1291170 is resolved
                   #'mem_ts[?]>' => 'vsm.[1]->checkthresholdevent->mem_ts',
                   #'mem_event_count[?]>' => 'vsm.[1]->checkthresholdevent->mem_event_count',
                   'cps_ts[?]>' => 'vsm.[1]->checkthresholdevent->cps_ts',
                   'cps_event_count[?]>' => 'vsm.[1]->checkthresholdevent->cps_event_count',
               },
            },
            'SetDFWRules' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                        layer => "layer3",
                        name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
                        action  => 'allow',
                        logging_enabled => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value	=> "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value	=> "vm.[2]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value	=> "vm.[1]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value	=> "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                               },
                                            ],
                  },
               },
            },
            'HTTPTraffic' => {
               Type => 'Traffic',
		       toolname => 'lighttpd',
               requestcount => '1000000',
               threadcount => '50',
               concurrentclients => '300',
		       testadapter => 'vm.[2].vnic.[1]',
	           supportadapter => 'vm.[1].vnic.[1]',
               connectivitytest => "0",
               iterations => "2",
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for DFW Event Thresholds TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of EventThresholds class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
      # Below way of getting class name is to allow new class as well as
      # $class->new.  In new class, proto itself is class, and $class->new,
      # ref($class) return the class
      my $class = ref($proto) || $proto;
      my $self = $class->SUPER::new(\%EventThresholds);
      return (bless($self, $class));
}

1;

