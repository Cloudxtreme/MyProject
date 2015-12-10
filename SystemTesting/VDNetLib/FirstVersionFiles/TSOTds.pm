########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::TSOTds;

################################################################################
# This file contains the structured hash for category, TSO(Intra/Inter) tests
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
   @TESTS = ("TSO_VM-VM_Basic", "TSO_VM-VM_SR", "TSO_VM-VM_SRD",
             "TSO_VM-VM_SO", "TSO_VM-VM_gVLAN", "TSO_VM-VM_sVLAN",
             "TSO_VM-VM_SO_SR", "TSO_VM-VM_SO_SRD",  "TSO_VM-VM_S0_SRD_SR");

   %TSO = (
      'TSO_VM-VM_Basic' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_Basic",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
         'TSO_VM-VM_SR' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_SR",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SuspendResume,
          },
      'TSO_VM-VM_SO' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_Basic",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
          'TSO_VM-VM_SO_SR' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_Basic",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
      'TSO_VM-VM_SO_SRD' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_Basic",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
      'TSO_VM-VM_SO_SRD_SR' => {
                TestSet              => "TSO",
                TestName             => "TSO_VM-VM_Basic",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TSOData,
                Stress =>  \@VDNetLib::NPFunc::Stress,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "func",
                   },
                   STRESS => {
                      option => "",
                      value => "",
                      operation => "SRDSO",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::StressOpsController,
         },
          'TSO_VM-VM_SRD' => {
                TestSet            => "TSO",
                TestName           => "TSO_VM-VM_SRD",
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
                          TSO => "Enable",
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SnapshotRevertDelete,

          },
          'TSO_VM-VM_gVLAN' => {
                TestSet            => "TSO",
                TestName           => "TSO_VM-VM_gVLAN",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                UnSupportedGOS         => "windows",
                UnSupportedDrivers     => "VMXNET2",
                SupportedDrivers     => "VMXNET3, VMXNET2",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          VLAN => "9",
                          TSO => "Enable",
                       },
                        portGroup => {
                          VLAN => 4095,
                        },
                       },
                   Destination => {
                       nic => {
                          VLAN => "9",
                       },
                       portGroup => {
                          VLAN => 4095,
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
          },
          'TSO_VM-VM_sVLAN' => {
                TestSet            => "TSO",
                TestName           => "TSO_VM-VM_sVLAN",
                TestMethod           => "A",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          TSO => "Enable",
                       },
                       portGroup => {
                          VLAN => 9,
                        },
                       },
                   Destination => {
                       nic => {
                       },
                       portGroup => {
                          VLAN => 9,
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
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
          },
   ),
}

########################################################################
# new --
#       This is the constructor for TSOintraTds
#
# Input:
#       none
#
# Results:
#       An instance/object of TSOIntraTds class
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
   my $self = $class->SUPER::new(\%TSO);
   return (bless($self, $class));
}


1;
