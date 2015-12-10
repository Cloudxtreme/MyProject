########################################################################
#       Copyright (C) 2009 VMware, Inc.                                #
#       All Rights Reserved                                            #
########################################################################

package VDNetLib::TDS::InterruptModeTds;

########################################################################
# This file contains the structured hash for category, Interrupt mode  #
# tests. The following lines explain the keys of the internal hash in  #
# general.                                                             #
#                                                                      #
# =====================================================================#
# Key in hash           Description                                    #
# =====================================================================#
# TestSet             => Test Category name                            #
# TestName            => Test Name                                     #
# TestMethod          => M for manual and A for automation.            #
# SupportedSWPlatforms=> Supported Test platforms(Takes ALL for ALL    #
#                        platforms mentioned in the TDS or specific);  #
# SupportedDrivers    => Supported drivers (Takes ALL for if ALL the   #
#                        drivers supported else takes specific.        #
# Tags                => Marks a test case with part of a particular   #
#                        testing                                       #
# NOOFMACHINES        => Min no. of machines requried to test          #
# SETUP               => INTER|INTRA                                   #
# TARGET              => INTERFACE or CONNECTION                       #
# CONNECTION          => has two ends: Source and Destination each with#
#                        NIC definition.                               #
#			 INTERFACE will not have destination end point, it            #
#			 reflects the standalone interface on the SUT                 #
# WORKLOADS           => modules like netperf iperf or VM operations   #
# VD_PRE              => pointer to pre-processing routine             #
# VD_POST             => pointer to post-processing routine            #
# VD_MAIN             => pointer to main                               #
########################################################################

# Load required modules
use FindBin;
use lib "$FindBin::Bin/..";

use VDNetLib::TDS::VDNetMainTds;
use VDNetLib::VDTestCases;
use VDNetLib::NPFunc;

@ISA = qw(VDNetLib::TDS::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("NetperfActiveMasking");

   %InterruptMode = (
      'NetperfActiveMasking' => {
          TDSID                => "17.1.0",
          TestSet              => "InterruptMode",
          TestName             => "NetperfActiveMasking",
          TestMethod           => "A",
          SupportedPlatforms   => "ALL",
          UnSupportedPlatforms => "VLANCE, E1000, VMXNET",
          SupportedDrivers     => "VMXNET3",
          Tags                 => "Networking Tests",
          NOOFMACHINES         => 2,
          SETUP                => "INTER/INTRA",
          TARGET               => "CONNECTION",
          CONNECTION           => {
             Source => {
                nic => {
                   INTR => "ACTIVE-INTX",
                },
                vSwitch => {
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
                #tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500',
                tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4%',
             },
          },
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::VDTestCases::InterruptProcessing,
      },
   ),
}

########################################################################
# new -
#       This is the constructor for InterruptModeTds
#
# Input:
#       none
#
# Results:
#       An instance/object of InterruptModeTds class
#
# Side effects:
#       None
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%InterruptMode);
   return(bless($self, $class));
}

1;
