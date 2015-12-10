#!/usr/bin/perl

package VDNetLib::TDS::TSOIntraTds;

use VDNetLib::TDS::VDNetMainTds;
use vd_common_srvs;
use vd_testcases;
#use VDNetLib::BasicSanity;
use VDNetLib::NPFunc;
use Data::Dumper;

@ISA = qw(VDNetLib::TDS::VDNetMainTds);

################################################################################
# This file contains the structured hash for category, TSOIntra tests
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
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("TSO_VM-VM_Basic", "TSO_VM-VM_SR", "TSO_VM-VM_SRD", "TSO_VM-VM_SO", "TSO_VM-VM_gVLAN_Linux", "TSO_VM-VM_gVLAN_win", "TSO_VM-VM_sVLAN", "TSO_VM-VM_SO_SR", "TSO_VM-VM_SO_SRD",  "TSO_VM-VM_S0_SRD_SR");

   %TSOIntra = (
      'TSO_VM-VM_Basic' => {
                TDSID                => "7.1.0",
                TestSet              => "TSOIntra",
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
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&vd_testcases::DataTrafficController,
         },
         'TSO_VM-VM_SR' => {
                TDSID                => "7.2.0",
                TestSet              => "TSOIntra",
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::SuspendResume,
                VD_MAIN => \&vd_testcases::DataTrafficController,
          },
          'TSO_VM-VM_SRD' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_SRD",
                TDSID              => '7.3.0',
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
               # VD_MAIN => \&VDNetLib::BasicSanity::SnapshotRevertDelete,
                VD_MAIN => \&vd_testcases::DataTrafficController,

          },
          'TSO_VM-VM_SO' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_SO",
                TDSID              => "7.4.0",
                TestMethod         => "A",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          },
          # 
          'TSO_VM-VM_gVLAN_Linux' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_gVLAN_Linux",
                TDSID              => "7.5.0",
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&vd_testcases::DataTrafficController,
          },
          'TSO_VM-VM_gVLAN_win' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_gVLAN_win",
                TDSID              => "7.6.0",
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
                          VLANId => "104",
                          IP => "192.168.200.110",
                          MASK => "255.255.255.0",
                       },
                        vSwitch => {
                          MTU => 9000,
                        },
                       },
                   Destination => {
                        nic => {
                        VLANId => "104",
                        MTU => "1500",
                          IP => "192.168.200.111",
                          MASK => "255.255.255.0",

                       },
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&vd_testcases::DataTrafficController,

          },
          'TSO_VM-VM_sVLAN' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_sVLAN",
                TDSID              => "7.7.0",
                TestMethod         => "A",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          },
          'TSO_VM-VM_SO_SR' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_SO_SR",
                TDSID              => "7.8.0",
                TestMethod         => "A",
                TestPriority       => "P1",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          },
          'TSO_VM-VM_SO_SRD' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_SO_SRD",
                TDSID              => "7.9.0",
                TestMethod         => "M",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          },
          'TSO_VM-VM_S0_SRD_SR' => {
                TestSet            => "TSOIntra",
                TestName           => "TSO_VM-VM_S0_SRD_SR",
                TDSID              => "7.10.0",
                TestMethod         => "M",
                SupportedPlatforms => "ALL",
                UnSupportedPlatforms => "ALL",
                SupportedDrivers   => "VMXNET, VMXNET3",
          },
   ),
}

#-----------------------------------------------------------------------------
# new -
#       This is the constructor for TSOintraTds
# Input:
#       none
#
# Output:
#       An instance/object of TSOIntraTds class
#
# Side effects:
#       None
#-----------------------------------------------------------------------------

sub
new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%TSOIntra);
   return (bless($self, $class));
}

1;
