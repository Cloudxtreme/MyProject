###############################################################################
#  Copyright (C) 2009 VMware, Inc.                                            #
#  All Rights Reserved                                                        #
###############################################################################

package VDNetLib::TDS::PowerMgmtTds;

################################################################################
# This file contains the structured hash for category, PowerMgmt tests
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
use VDNetLib::BasicSanity;
use Data::Dumper;

@ISA = qw(VDNetLib::TDS::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("WakeOnPktRcv", "WoLMagicPktRcv");
   # TODO: remove workloads, and verification procedure as it is not required
   %PowerMgmt = (
      'WakeOnPktRcv' => {
                TestSet              => "PowerMgmt",
                TestName             => "WakeOnPktRcv",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "Linux",
                UnSupportedDrivers     => "E1000, VMXNET2, VLANCE",
                SupportedDrivers     => "VLANCE,VMXNET2,VMXNET3,E1000",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          WoL => "ARP",
                       },
                       vSwitch => {
                          MTU => 1500,
                       },
                   },
                   Destination => {
                       nic => {
                          MTU => "1500",
                       },
                   },
                },
                WORKLOADS => {
                   TRAFFIC => {
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::PowerMgmt,
         },
         'WoLMagicPktRcv' => {
                TestSet              => "PowerMgmt",
                TestName             => "WoLMagicPktRcv",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                UnSupportedDrivers     => "VLANCE,VMXNET2,E1000",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA/INTER",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          MTU => "1500",
                          WoL => "MAGIC",
                       },
                       vSwitch => {
                          MTU => 1500,
                       },
                   },
                   Destination => {
                   },
                },
                WORKLOADS => {
                   TRAFFIC => {
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                    },
                },
                VD_PRE =>  \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::BasicSanity::PowerMgmt,
          },
   ),
}

########################################################################
# new --
#       This is the constructor for PowerMgmtTds
#
# Input:
#       none
#
# Results:
#       An instance/object of PowerMgmtTds class
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
   my $self = $class->SUPER::new(\%PowerMgmt);
   return (bless($self, $class));
}

1;
