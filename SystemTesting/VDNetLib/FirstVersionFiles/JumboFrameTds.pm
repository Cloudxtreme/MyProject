########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::JumboFrameTds;

################################################################################
# This file contains the structured hash for category, JumboFrame tests
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
   @TESTS = ("JF_VM-VM_Basic", "JF_VM-VM_SR", "JF_VM-VM_SRD", "JF_VM-VM_SO",
             "JF_VM-VM_gVLAN", "JF_VM-VM_gVLAN", "JF_VM-VM_sVLAN",
             "JF_VM-VM_SO_SR", "JF_VM-VM_SO_SRD",  "JF_VM-VM_S0_SRD_SR");

   %JumboFrame = (
      'JF_VM-VM_Basic' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_Basic",
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
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
         'JF_VM-VM_SR' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_SR",
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
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SuspendResume,
          },
          'JF_VM-VM_SRD' => {
                TestSet            => "JumboFrame",
                TestName           => "JF_VM-VM_SRD",
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
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SnapshotRevertDelete,

          },
      'JF_VM-VM_SO' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_SO",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFData,
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
      'JF_VM-VM_SO_SR' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_SO_SR",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFData,
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
      'JF_VM-VM_SO_SRD' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_SO_SRD",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFData,
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
      'JF_VM-VM_SO_SRD_SR' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_SO_SRD_SR",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFData,
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
          'JF_VM-VM_gVLAN' => {
                TestSet            => "JumboFrame",
                TestName           => "JF_VM-VM_gVLAN",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                UnSupportedGOS       => "windows",
                UnSupportedDrivers     => "VMXNET2",
                SupportedDrivers     => "VLANCE, E1000, VMXNET2, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                          VLAN => "9",
                       },
                       portGroup => {
                          VLAN => 4095,
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                   },
                   Destination => {
                       nic => {
                          MTU => "9000",
                          VLAN => "9",
                       },
                       portGroup => {
                          VLAN => 4095,
                       },
                       vSwitch => {
                         MTU => 9000,
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
          },
          'JF_VM-VM_sVLAN' => {
                TestSet            => "JumboFrame",
                TestName           => "JF_VM-VM_sVLAN",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "9000",
                       },
                       portGroup => {
                          VLAN => 9,
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },
                       portGroup => {
                          VLAN => 9,
                       },
                       vSwitch => {
                         MTU => 9000,
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
          },
          'JF_VM-VM_PingSR' => {
                TestSet              => "JumboFrame",
                TestName             => "JF_VM-VM_PingSR",
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
                          MTU => "9000",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                       nic => {
                          MTU => "9000",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::JFData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
          }
   ),
}

########################################################################
# new --
#       This is the constructor for JumboFrameTds
#
# Input:
#       none
#
# Results:
#       An instance/object of JumboFrameTds class
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
   my $self = $class->SUPER::new(\%JumboFrame);
   return (bless($self, $class));
}

1;
