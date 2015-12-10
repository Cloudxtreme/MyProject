########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::BasicSanityTds;

################################################################################
# This file contains the structured hash for basic sanity tests
# The following lines explain the keys of the internal                         #
# Hash in general.                                                              #
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
   @TESTS = ("PowerOnOff", "HotAddvNIC", "SuspendResume",
             "SnapshotRevertDelete, CableDisconnect", "DisableEnablevNIC");

   %BasicSanity = (
      'PowerOnOff' => {
       TDSID              => "1.1.0",
       TestSet            => "BasicSanity",
       TestName           => "PowerOnOff",
       TestMethod         => "M",
       SupportedPlatforms => "ALL",
       UnSupportedPlatforms => "NONE",
       SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
       Tags               => "PortableTools",
       NOOFMACHINES       => 2,
       SETUP              => "INTER|INTRA",
       TARGET             => "CONNECTION",
       CONNECTION         => {
          Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
       },
       WORKLOADS => {
          # TODO:
          # later this test case can have sub test
          # each one  for ipv4, ipv6, 3.1.0.1 will
          # be ipv4 and 3.1.0.1 will be ipv6
          # alternate method is use ping6 and netperf6 for ipv6
          VMOPS => {
              poweron => "1",
          },
          TRAFFIC => {
             netperf => "basic",
          },
       },
       # following entries are used by post processing
       VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
       VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
       VD_MAIN => \&VDNetLib::BasicSanity::PowerOnOff,
       },
       'SuspendResume' => {
          TestSet            => "BasicSanity",
          TestName           => "SuspendResume",
          TDSID              => "1.3.0",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
	     # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                addVNIC => "basic",
             },
             TRAFFIC => {
                netperf => "basic",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::SuspendResume,
       },
       'SnapshotRevertDelete' => {
          TestSet            => "BasicSanity",
          TestName           => "SnapshotRevertDelete",
          TDSID              => "1.3.0",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
	     # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                addVNIC => "basic",
             },
             TRAFFIC => {
                netperf => "basic",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::SnapshotRevertDelete,
       },
       'CableDisconnect' => {
          TDSID              => "1.4.0",
          TestSet            => "BasicSanity",
          TestName           => "CableDisconnect",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
	     # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                addVNIC => "cableDisconnect",
             },
             TRAFFIC => {
                ping => "-s 8192 -f",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::CableDisconnect,
       },
       'HotAddvNIC' => {
          TDSID              => "1.7.0",
          TestSet            => "BasicSanity",
          TestName           => "HotAddvNIC",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "E1000, VMXNET2, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => {
                PortGroup => {
                   Name => 'vdtest',
                }
             },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
	     # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                addVNIC => "HotAddRemove",
             },
             TRAFFIC => {
                ping => "-s 8192 -f",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::HotAddvNIC,
       },
       'DisableEnablevNIC' => {
          TDSID              => "1.5.0",
          TestSet            => "BasicSanity",
          TestName           => "DisableEnablevNIC",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
             # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                DisEnvNIC => "basic",
             },
             TRAFFIC => {
                netperf => "basic",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::DisableEnable,
       },
       'CableDisconnectBeforeDriverLoaded' => {
          TDSID              => "1.4.1",
          TestSet            => "BasicSanity",
          TestName           => "CableDisconnectBeforeDriverLoaded",
          TestMethod         => "M",
          SupportedPlatforms => "ALL",
          UnSupportedPlatforms => "NONE",
          SupportedDrivers   => "VLANCE, E1000, VMXNET, VMXNET3",
          Tags               => "PortableTools",
          NOOFMACHINES       => 2,
          SETUP              => "INTER|INTRA",
          TARGET             => "CONNECTION",
          CONNECTION         => {
             Source => { },
             # TODO: Empty Destination means same as Source
             Destination => { },
          },
          WORKLOADS => {
             # TODO:
	     # later this test case can have sub test
             # each one  for ipv4, ipv6, 3.1.0.1 will
             # be ipv4 and 3.1.0.1 will be ipv6
             # alternate method is use ping6 and netperf6 for ipv6
             VMOPS => {
                addVNIC => "cableDisconnect",
             },
             TRAFFIC => {
                ping => "-s 8192 -f",
             },
          },
          # following entries are used by post processing
          VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
          VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
          VD_MAIN => \&VDNetLib::BasicSanity::CableDisconnect,
       },
   ),
}

########################################################################
# new --
#       This is the constructor for BasicSanityTds
#
# Input:
#       none
#
# Results:
#       An instance/object of BasicSanityTds class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way getting class name is to allow new class as well as $class->new
   # In new class, proto itself is class, and $class->new, ref($class) return
   # the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%BasicSanity);
   return (bless($self, $class));
}

1;
