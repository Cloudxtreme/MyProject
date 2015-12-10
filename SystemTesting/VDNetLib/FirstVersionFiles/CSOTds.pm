########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::CSOTds;

################################################################################
# This file contains the structured hash for category, CSO tests
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
   @TESTS = ("Basic");

   %CSO = (
      'Basic' => {
                TDSID                => "10.1.0",
                TestSet              => "CSO",
                TestName             => "Basic",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          CSO => 'Enable',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                      nic => {
                         MTU => "1500",
                         CSO => 'Enable',
                      }
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
                      Macro=>"CHECKSUM",
                      tcpdumpExpr => '-p -c 50 src host %srcipv4% and dst host %dstipv4% and greater 1520',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
      'IPv6' => {
                TDSID                => "10.1.0",
                TestSet              => "CSO",
                TestName             => "IPv6",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VMXNET, VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          IPv6 => '',
                          CSO => 'Enable',
                       },
                        vSwitch => {
                          MTU => 1500,
                        },
                       },
                   Destination => {
                      nic => {
                         MTU => "1500",
                         IPv6 => '',
                         CSO => 'Enable',
                      }
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
                      Macro=>"CHECKSUM",
                      tcpdumpExpr => '-p -c 50 ip6 and ether dst host %dstmac% ',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
   ),
}

#######################################################################
# new --
#       This is the constructor for TSOintraTds
#
# Input:
#       none
#
# Results:
#       An instance/object of CSOTds class
#
# Side effects:
#       None
#
#######################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%CSO);
   return (bless($self, $class));
}

1;
