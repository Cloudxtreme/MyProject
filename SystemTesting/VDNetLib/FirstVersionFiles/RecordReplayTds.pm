#!/usr/bin/perl

package VDNetLib::TDS::RecordReplayTds;

use VDNetLib::TDS::VDNetMainTds;
use vd_common_srvs;
use vd_testcases;
use VDNetLib::NPFunc;
use Data::Dumper;

@ISA = qw(VDNetLib::TDS::VDNetMainTds);

################################################################################
# This file contains the structured hash for category, VLAN tests
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
   @TESTS = ("basic", "jumboFrame");

   %RecordReplay = (
      'basic' => {
                TDSID                => "2.1.1", # confirm the ID with Kishore
                TestSet              => "RR",
                TestName             => "basic",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VMXNET3", # e1000 currently not
                                                   # automated/supported on windows
                Tags                 => "RR, PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                       },
                       portGroup => {
                        },
                       },
                   Destination => {
                       nic => {
                       },
                       portGroup => {
                        },
                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::testData,
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
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500',
                    },
                },
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&vd_testcases::RecordReplayController,
               },
      'gVLAN' => {
                TDSID                => "2.1.2", # confirm the ID with Kishore
                TestSet              => "VLAN",
                TestName             => "gVLAN",
                TestMethod           => "A",
                SupportedPlatforms   => "ALL",
                UnSupportedPlatforms => "none",
                SupportedDrivers     => "VMXNET3", # e1000 currently not
                                                   # automated/supported on windows
                Tags                 => "PortableTools",
                NOOFMACHINES         => 2,
                SETUP                => "INTRA",
                TARGET               => "CONNECTION",
                CONNECTION           => {
                   Source => {
                       nic => {
                          VLAN => "9,192.168.1.100,255.255.255.0",
                       },
                        portGroup => {
                          VLAN => 4095,
                        },
                       },
                   Destination => {
                       nic => {
                          VLAN => "9,192.168.1.200,255.255.255.0",
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
                      ping => "-s 8192 -f",
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
                VD_PRE => \&vd_common_srvs::VdPreProcessing,
                VD_POST => \&vd_common_srvs::VdPostProcessing,
                VD_MAIN => \&vd_testcases::DataTrafficController,
                },
   ),
}

#-----------------------------------------------------------------------------
# new -
#       This is the constructor for RecordReplay
# Input:
#       none
#
# Output:
#       An instance/object of RecordReplay class
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
   print "class " . Dumper(\%RecordReplay) ."\n";
   my $self = $class->SUPER::new(\%RecordReplay);
   print "self " . Dumper($self) ."\n";

   return (bless($self, $class));
}

1;
