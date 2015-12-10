########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TDS::TxRxTds;

########################################################################
# This file contains the structured hash for category, TxRx tests
# The following lines explain the keys of the internal
# Hash in general.
#
# ============================================================================
# Key in hash           Description
# ============================================================================
# TestSet             => Test Category name
# TestName            => Test Name
# TestMethod          => M for manual and A for automation
# SupportedSWPlatforms=> Supported Test platforms(Takes ALL for ALL
#                        platforms mentioned in the TDS or specific);
# SupportedDrivers    => Supported drivers (Takes ALL for if ALL the drivers
#                        supported else takes specific
# Tags                => Marks a test case with part of a particular testing
# NOOFMACHINES        => Min no. of machines requried to test
# SETUP               => INTER|INTRA
# TARGET              => INTERFACE or CONNECTION
# CONNECTION          => has two ends: Source and Destination each with NIC
#                        definition
#			 INTERFACE will not have destination end point, it
#			 reflects the standalone interface on the SUT
# WORKLOADS           => modules like netperf iperf or VM operations
# VD_PRE              => pointer to pre-processing routine
# VD_POST             => pointer to post-processing routine
# VD_MAIN             => pointer to main
########################################################################

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
   @TESTS = ("TxQueues", "RxQueues", "SmallRxBuffers", "LargeRxBuffers",
             "TxRing", "RxRing1", "RxRing2", "TxQueues-JF", "RxQueues-JF",
             "SmallRxBuffers-JF", "LargeRxBuffers-JF", "TxRing-JF",
             "RxRing1-JF", "RxRing2-JF" );

   %TxRx = (
      'TxQueues' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "TxQueues",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "outbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxQueues' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxQueues",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'SmallRxBuffers' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "SmallRxBuffers",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'LargeRxBuffers' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "LargeRxBuffers",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'TxRing' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "TxRing",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "outbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxRing1' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxRing1",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxRing2' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxRing2",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::TxRxData,
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
                       nic => {
                          MTU => "1500",
                       },

                   },
                },
                # following entries are used by testcase routine
                SCOPE => "DATASET",
                DATASET => \@VDNetLib::NPFunc::TxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 500 src host %srcipv4% and dst host %dstipv4% and less 1500'
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'TxQueues-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "TxQueues-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "outbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxQueues-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxQueues-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'SmallRxBuffers-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "SmallRxBuffers-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'LargeRxBuffers-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "LargeRxBuffers-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'TxRing-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "TxRing-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "outbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Destination",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxRing1-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxRing1-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
      'RxRing2-JF' => {
                TDSID                => "50.1.0",
                TestSet              => "TxRx",
                TestName             => "RxRing2-JF",
                TestMethod           => "A",
                SupportedPlatforms   => "WINDOWS",
                UnSupportedPlatforms => "LINUX",
                SupportedDrivers     => "VMXNET3",
                Tags                 => "RR",
                NOOFMACHINES         => 2,
                SETUP                => "INTER/INTRA",
                DATASET              => \@VDNetLib::NPFunc::JFTxRxData,
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
                DATASET => \@VDNetLib::NPFunc::JFTxRxData,
                WORKLOADS => {
                   TRAFFIC => {
                      ping => "-s 8192 -f",
                      netperf => "inbound",
                   },
                },
                # following entries are used by post processing
                VERIFICATION => {
                   TCPDUMP => {
                      LOC=>"Source",
                      Macro=>"COUNT",
                      tcpdumpExpr => '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and greater 1600',
                    },
                },
                VD_PRE => \&VDNetLib::VDCommonSrvs::VdPreProcessing,
                VD_POST => \&VDNetLib::VDCommonSrvs::VdPostProcessing,
                VD_MAIN => \&VDNetLib::VDTestCases::TxRxConfigTests,
         },
   ),
}

########################################################################
# new --
#       This is the constructor for TxRxTds
#
# Input:
#       none
#
# Results:
#       An instance/object of TxRxTds class
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
   my $self = $class->SUPER::new(\%TxRx);
   return (bless($self, $class));
}

1;
