#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::TDS::FunctionalTds;
################################################################################
# This file contains the structured hash for category, Functional tests
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
   @TESTS = ("NetperfIntra", "NetperfInter", "Blaster", "Iozone", "IozoneSR", "IozoneSnR", "ftp", "scp", "rsync", "DataIntegrity", "NDIS1C", "NDIS2C", "NDIS2M", "http", "UDPFloodSR", "Multicast", "MediaStreaming", "Morphing", "Morphing2vnics", "MorphingSn", "LinkStateChange", "UnloadLoadNetperf", "FunctionalStressEthtool", "LoadUnloadSO", "PXEBoot", "RSS", "IOP", "NetPoll", "kdump");

   %Functional = (
      'NetperfIntra' => {
                TDSID                => "3.1.0",
                TestSet              => "Functional",
                TestName             => "NetperfIntra",
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4%',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::DataTrafficController,
         },
      'UnloadLoadNetperf' => {
           TDSID                => "3.1.22",
           TestSet              => "Functional",
           TestName             => "UnloadLoadNetperf",
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
                  },
                    vSwitch => {
                      MTU => 1500,
                    },
                   },
             Destination => {
             },
           },
          #following entries are used by testcase routine
          SCOPE => "DATASET",
          DATASET => \@VDNetLib::NPFunc::testData,
          WORKLOADS => {
            TRAFFIC  => {
               ping => "-s 8192 -f",
               netperf => {
                  nic => nic,
               },
            },
          },
          # following entries are used by post processing
           VERIFICATION => {
              TCPDUMP => {
                 LOC=>"Destination",
                 Macro=>"COUNT",
                 tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4%',
              },
           },
            VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
            VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
            VD_MAIN => \&VDNetLib::VDTestCases::LoadUnloadController,
        },
    ),
}
########################################################################
# new --
#       This is the constructor for FunctionalTds
#
# Input:
#       none
#
# Results:
#       An instance/object of FunctionalTds class
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
   my $self = $class->SUPER::new(\%Functional);
   return (bless($self, $class));
}

1;
