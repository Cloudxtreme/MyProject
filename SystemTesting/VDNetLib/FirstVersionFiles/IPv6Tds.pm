########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::IPv6Tds;

################################################################################
# This file contains the structured hash for category, IPv6 tests
# The following lines explain the keys of the internal                         #
# Hash in general.                                                             #
#                                                                              #
# =============================================================================#
# Key in hash           Description                                            #
# =============================================================================#
# TestSet             => Test Category name                                    #
# TestName            => Test Name                                             #
# TestMethod          => M for manual and A for automation, A/M for both       #
# SupportedSWPlatforms=> Supported Test platforms(Takes ALL for ALL            #
#                        platforms mentioned in the TDS or specific);          #
# SupportedDrivers    => Supported drivers (Takes ALL for if ALL the drivers   #
#                        supported else takes specific                         #
# Tags                => Marks a test case with part of a particular testing   #
# NOOFMACHINES        => Min no. of machines requried to test                  #
# SETUP               => INTER|INTRA                                           #
# TARGET              => INTERFACE or CONNECTION                               #
# CONNECTION          => has two ends: Source and Destination each with NIC    #
#                        definition                                            #
#			 INTERFACE will not have destination end point, it
#			 reflects the standalone interface on the SUT
# WORKLOADS           => modules like netperf iperf or VM operations           #
# VD_PRE              => pointer to pre-processing routine                     #
# VD_POST             => pointer to post-processing routine                    #
# VD_MAIN             => pointer to main                                       #
################################################################################

use FindBin;
use lib "$FindBin::Bin/..";
use VDNetLib::TDS::VDNetMainTds;
use VDNetLib::VDCommonSrvs;
use VDNetLib::VDTestCases;
use VDNetLib::NPFunc;
use Data::Dumper;

@ISA = qw(VDNetLib::TDS::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("NetperfTCP", "NetperfUDP");

   %IPv6 = (
      'NetperfTCP' => {
                TestSet              => "IPv6",
                TestName             => "NetperfTCP",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          IPv6 => '',
                       },
                   },
                }, 
                # following entries are used by testcase routine 
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::testData,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and less 1500',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
         'TSO6_VM-VM_SO_SR' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_SO_SR",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                      operation => "Suspend",
                   },

                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
          },
         'TSO6_VM-VM_SO_SRD' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_SO_SRD",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                      operation => "SRD",
                   },

                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
          },
         'TSO6_VM-VM_SO_SRD_SR' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_SO_SRD_SR",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                      operation => "SuspendSRD",
                   },

                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
          },
         'TSO6_VM-VM_SO' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_SO",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                      operation => "",
                   },

                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
          },

      'NetperfUDP' => {
                TestSet              => "IPv6",
                TestName             => "NetperfUDP",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                   },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          'IPv6' => '',
                       },
                   },
                }, 
                # following entries are used by testcase routine 
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::UDP,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and less 1500',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
      'sVLAN' => {
                TestSet              => "IPv6",
                TestName             => "sVLAN",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VMXNET2, VMXNET3",
                # e1000 currently not automated/supported on windows
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          IPv6 => '',
                       },
                       portGroup => {
                          VLAN => 9,
                        },
                       },
                   Destination => {
                       nic => {
                          IPv6 => '',
                       },
                       portGroup => {
                          VLAN => 9,
                        },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::testData,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% ',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
               },
      'gVLAN' => {
                TestSet              => "IPv6",
                TestName             => "gVLAN",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                UnSupportedGOS       => "windows",
                UnSupportedDrivers     => "VMXNET2",
                SupportedDrivers     => "VMXNET3, VMXNET2",
                # e1000 currently not automated/supported on windows
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          VLAN => "9",
                          IPv6 => '',
                       },
                        portGroup => {
                          VLAN => 4095,
                        },
                       },
                   Destination => {
                       nic => {
                          VLAN => "9",
                          IPv6 => '',
                       },
                       portGroup => {
                          VLAN => 4095,
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::testData,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% ',
                    },
                },
           VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
           VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
           VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
      },
      'TSO6_VM-VM_Basic' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_Basic",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TSOData,
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                }, 
                # following entries are used by testcase routine 
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
         'TSO6_VM-VM_SR' => {
                TestSet              => "IPv6",
                TestName             => "TSO6_VM-VM_SR",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                }, 
                # following entries are used by testcase routine 
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SuspendResume,
          },
          'TSO6_VM-VM_SRD' => {
                TestSet            => "IPv6",
                TestName           => "TSO6_VM-VM_SRD",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                       vSwitch => {
                          MTU => 1500,
                       },
                   },
                   Destination => {
                       nic => {
                          MTU => "1500",
                          TSO => 'Enable',
                          IPv6 => '',
                       },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                WORKLOADS => {
                   TRAFFIC => {
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 ip6 and ether dst host %dstmac% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SnapshotRevertDelete,

          },
   ),
}

########################################################################
# new --
#       This is the constructor for IPv6Tds
#
# Input:
#       none
#
# Results:
#       An instance/object of IPv6Tds class
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
   my $self = $class->SUPER::new(\%IPv6);
   return (bless($self, $class));
}

1;
