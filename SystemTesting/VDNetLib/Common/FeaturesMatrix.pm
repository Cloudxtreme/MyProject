#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::FeaturesMatrix;

#
# This package captures various features (for example, RSS, VLAN, JF etc
# under network adapter operations, suspend/resume, snapshot/revert under
# vm operations, stress, UPT, NPA etc under  host operations) support under
# various testbed configurations like host os, product, guest os, tools version,
# network driver etc.

# Before configuring/working on a feature, it is important to verify
# whether the feature is supported on the given testbed. If not supported, we
# can skip that configuration. This is better than returning error while
# trying to configure something on a testbed that does not support it.
# For example, stress options are not supported on release builds.
#
# Various testbed configurations and supported values:
#
# 'platform'     => "esx,vmkernel",
# 'guestos'      => "linux,win",
# 'ndisversion'  => "5.1,6.1,6.14",
# 'kernelversion'=> "2.4,2.6",
#
# The keys above are defined as of 08/18/2010. More keys can be added.
# Please note that the keys and values defined are in lower case.
#


use strict;
use warnings;

use base 'Exporter';
use File::Basename;
use strict;
use warnings;
use VDNetLib::Common::GlobalConfig;
our @EXPORT = qw(%vdFeatures);
our %vdFeatures;

#
# The hash %vdFeatures captures all NetAdapter related features.
# This package can be extended to add details about various VM, host,
# VC, switch features as and when the data is available.
#
%vdFeatures = (
   'verifypriorityvlan'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "5.0,5.1,6.1,6.14",
      },
   },
   'priorityvlan'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "5.0,5.1,6.1,6.14",
      },
   },
   'nicplacement'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
   },
   'wakeupguest'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
   },
   'devicestatus'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
      'be2net'   => {
         'platform'     => "all",
      },
      'ixgbe'   => {
         'platform'     => "all",
      },
   },

   'driverreload'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'vmxnet2'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6",
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },
      'vlance'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6",
      },
      'flexible'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6",
      },
      'ixgbe'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },
      'bnx2x'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },
   },

   'setmacaddr'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'vmxnet2'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => "5.0,5.1,6.1,6.14",
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => "5.1,6.0,6.1,6.14",
      },
      'e1000e'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'vlance'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'flexible'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'ipv4'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
      'ixgbe'   => {
         'platform'     => "all",
      },
      'bnx2x'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
   },

   'ipv6'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
   },

   'route'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
      'ixgbe'   => {
         'platform'     => "all",
      },
      'bnx2x'   => {
         'platform'     => "all",
      },
   },

   'mtu'    => {
      'vmxnet3'   => {
         'platform'     => "all",
      },
      'vmxnet2'   => {
         'platform'     => "all",
      },
      'e1000'   => {
         'platform'     => "all",
      },
      'e1000e'   => {
         'platform'     => "all",
      },
      'vlance'   => {
         'platform'     => "all",
      },
      'flexible'   => {
         'platform'     => "all",
      },
      'ixgbe'   => {
         'platform'     => "all",
      },
      'bnx2x'   => {
         'platform'     => "all",
      },
   },

   'wol'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'vmxnet2'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "5.1,6.0,6.1,6.14",
      },
      'e1000e'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'vlance'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'intrmode'    => {
      'vmxnet3'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => "6.1,6.14,6.20",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
      },
   },

   'vlan'    => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6",
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },
      'vlance'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6",
      },
      'flexible'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0,3.1,3.2.0",
      },
     'ixgbe'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },
      'bnx2x'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.4,2.6,3.0",
      },

   },

   'txringsize' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6,3.0",
      },
   },

   'rx1ringsize' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000'   => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e'  => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6,3.0",
      },
   },

   'rx2ringsize' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'intrmodparams' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_DRIVER_RELATED_KERNEL ,
         'driverversion'=> "1.0.16.0",
      },
   },

   'rss' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win,linux",
         'ndisversion'  => "6.1,6.14",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_DRIVER_RELATED_KERNEL ,
         'driverversion'=> "1.0.16.0",
      },
   },

   'maxtxqueues' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win,linux",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_DRIVER_RELATED_KERNEL ,
         'driverversion'=> "1.0.16.0",
      },
   },

   'maxrxqueues' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win,linux",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_DRIVER_RELATED_KERNEL ,
         'driverversion'=> "1.0.16.0",
      },
   },

   'smallrxbuffers' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'largerxbuffers' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'tsoipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
         'ndisversion'  => "5.1,6.0,6.1,6.14",
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.4,2.6,3.0",
         'ndisversion'  => "6.1,6.14",
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.4,2.6",
         'ndisversion'  => "5.0,5.1,6.1,6.14",
      },
      'vlance' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.4,2.6",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'ixgbe' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.4,2.6,3.0",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'bnx2x' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.4,2.6,3.0",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'tcptxchecksumipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
         'ndisversion'  => "5.1,6.0,6.1,6.14",
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.6,3.0",
         'ndisversion'  => "6.1,6.14",
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
      'vlance' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
   },

   'tcprxchecksumipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
         'ndisversion'  => "5.1,6.0,6.1,6.14",
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux,win",
         'kernelversion'=> "2.6,3.0",
         'ndisversion'  => "6.1,6.14",
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
      'vlance' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
   },


   'sg' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6,3.0",
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
      'vlance' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
   },


   'gso' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> VDNetLib::Common::GlobalConfig::VDNET_SUPPORT_MAXIMUM_KERNEL ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6,3.0",
      },
      'vmxnet2' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
      'vlance' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "linux",
         'kernelversion'=> "2.6",
      },
   },


   'udptxchecksumipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.0,6.1,6.14", #5 does not support
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },


   'udprxchecksumipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.0,6.1,6.14", #5 does not support
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'tcpgiantipv4' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14", #5 does not support
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'iptxchecksum' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'iprxchecksum' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'tsoipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'tcptxchecksumipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'tcprxchecksumipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'udptxchecksumipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'udprxchecksumipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
      'e1000e' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => "6.1,6.14",
      },
   },

   'tcpgiantipv6' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'interruptmoderation' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'offloadtcpoptions' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'offloadipoptions' => {
      'vmxnet3' => {
         'platform'     => "esx,vmkernel",
         'guestos'      => "win",
         'ndisversion'  => VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_NDISVER ,
      },
   },

   'lro' => {
       'vmxnet3' => {
          'platform'     => "esx,vmkernel",
          'guestos'      => "linux",
          'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
       },
       'vmxnet2' => {
          'platform'     => "esx,vmkernel",
          'guestos'      => "linux",
          'kernelversion'=> VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SUPPORT_KERNEL ,
       },
    },

   'setlro' => {
       'vmxnet3' => {
          'platform'     => "esx,vmkernel",
          'guestos'      => "linux",
          'kernelversion'=> "2.6,3.2.0",
       },
       'vmxnet2' => {
          'platform'     => "esx,vmkernel",
          'guestos'      => "linux",
          'kernelversion'=> "2.6,3.2.0",
       },
    },

   'nicstats' => {
      'ixgbe' => {
         # Nothing to declare here since only ixgbe is supported for this
         # method
      },
   },

   'qpktcnt' => {
      'ixgbe' => {
         # Nothing to declare here since only ixgbe is supported for this
         # method
      },
   },
);
$vdFeatures{'reconfigure'} = $vdFeatures{'devicestatus'};

1;
