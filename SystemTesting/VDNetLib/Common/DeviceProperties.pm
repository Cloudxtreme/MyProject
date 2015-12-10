#!/usr/bin/perl -w
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::DeviceProperties;

# The features of network adapters, for example, jumbo frame, offload operations,
# vlan support, etc are available on many network adapters. These features can
# be configured on a network adapter using existing command-line utilities,
# special tools, registry etc. The arguments, registry keys that identienfies a
# property varies among different adapters. All such features, corresponding
# key values for an adapter are captured in a hash format and are being
# exported from this package

use strict;
use warnings;

use base 'Exporter';
use File::Basename;
use strict;
use warnings;

our @EXPORT = qw(%e1000 %vmxnet2 %vmxnet3 %vlance %e1000e %ixgbe);
our %e1000;
our %vmxnet3;
our %vmxnet2;
our %vlance;
our %e1000e;
our %ixgbe;

# The registry settings for e1000 is given below. The ndis
# version for e1000 is 6.x in post-vista and 5.x for pre-vista
# There are difference in the registry keys and values between
# ndis version 5.x and 6.x

%e1000 = (
  'Ndis5'  => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
     TSOIPv4 => {
         'Registry' =>  'TcpSegmentation',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  'ChecksumTxTcp',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  'ChecksumRxTcp',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     IPTxChecksum   => {
         'Registry' =>  'ChecksumTxIp',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     IPRxChecksum   => {
         'Registry' =>  'ChecksumRxIp',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TSOIPv6      => 'NA',
     TCPGiantIPv4 => 'NA',
     TCPTxChecksumIPv6   => 'NA',
     TCPRxChecksumIPv6   => 'NA',
     UDPTxChecksumIPv6   => 'NA',
     UDPRxChecksumIPv6   => 'NA',
     JumboFrame => {
        'Registry' => 'MaxFrameSize',
        'Enable'   => '9000',
        'Disable'  => '1500',
        'Default'  => '1500',
                },
             },

  Ndis6  => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
     TSOIPv4 => {
         'Registry' =>  '*LsoV1IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPGiantIPv4 => {
         'Registry' =>  '*LsoV2IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     IPTxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3',
                },
     IPRxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     TSOIPv6      => 'NA',
     TCPGiantIPv6 => 'NA',
     TCPTxChecksumIPv6   => 'NA',
     TCPRxChecksumIPv6   => 'NA',
     UDPTxChecksumIPv6   => 'NA',
     UDPRxChecksumIPv6   => 'NA',
     WakeOnLAN => 'NA',
     InterruptModeration => 'NA',
     MaxRxQueues => 'NA',
     MaxTxQueues => 'NA',
     TxRingSize => 'NA',
     RxRing1Size => 'NA',
     RxRing2Size => 'NA',
     LargeRxBuffers => 'NA',
     SmallRxBuffers => 'NA',
     OffloadIPOptions => 'NA',
     OffloadTCPOptions => 'NA',
     RSS => 'NA',
     JumboFrame => {
        'Registry' => '*JumboPacket',
        'Enable'   => '9014',
        'Disable'  => '1514',
        'Default'  => '1514',
                },
             },
        );

$e1000{'Default'} = $e1000{'Ndis6'};

# The registry settings for vmxnet3 is given below. The ndis
# version for vmxnet3 is 6.x in post-vista and 5.x for pre-vista
# But there are no difference in the registry keys and values between
# different ndis versions

%vmxnet3 = (
  'Ndis5'  => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
     TSOIPv4 => {
         'Registry' =>  '*LsoV1IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TSOIPv6 => {
         'Registry' =>  '*LsoV1IPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPGiantIPv4 => {
         'Registry' =>  '*LsoV2IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     IPTxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     IPRxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPGiantIPv6 => {
         'Registry' =>  '*LsoV2IPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     JumboFrame => {
        'Registry' => '*JumboPacket',
        'Enable'   => '9014',
        'Disable'  => '1514',
        'Default'  => '1514',
                },
     WakeOnLAN => {
        'Registry' => 'EnableWakeOnLan',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     InterruptModeration => {
        'Registry' => '*InterruptModeration',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     MaxRxQueues => {
        'Registry' => 'MaxRxQueues',
        'Default'  => '8',
                },
     MaxTxQueues => {
        'Registry' => 'MaxTxQueues',
        'Default'  => '1',
                },
     TxRingSize => {
        'Registry' => 'MaxTxRingLength',
        'Default'  => '512',
                },
     RxRing1Size => {
        'Registry' => 'MaxRxRing1Length',
        'Default'  => '512',
                },
     RxRing2Size => {
        'Registry' => 'MaxRxRing2Length',
        'Default'  => '512',
                },
     LargeRxBuffers => {
        'Registry' => 'NumRxBuffersLarge',
        'Default'  => '768',
                },
     SmallRxBuffers => {
        'Registry' => 'NumRxBuffersSmall',
        'Default'  => '1024',
                },
     OffloadIPOptions => {
        'Registry' => 'OffloadIpOptions',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     OffloadTCPOptions => {
        'Registry' => 'OffloadTcpOptions',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     RSS => {
        'Registry' => '*RSS',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '0',
                },
     VLAN => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '2',
        'Disable'  => '0',
        'Default'  => '3',
                },
     Priority => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '3',
                },
             },

  'Ndis6'  => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
     TSOIPv4 => {
         'Registry' =>  '*LsoV1IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TSOIPv6 => {
         'Registry' =>  '*LsoV1IPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPGiantIPv4 => {
         'Registry' =>  '*LsoV2IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     IPTxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     IPRxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPGiantIPv6 => {
         'Registry' =>  '*LsoV2IPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     JumboFrame => {
        'Registry' => '*JumboPacket',
        'Enable'   => '9014',
        'Disable'  => '1514',
        'Default'  => '1514',
                },
     WakeOnLAN => {
        'Registry' => 'EnableWakeOnLan',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     InterruptModeration => {
        'Registry' => '*InterruptModeration',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     MaxRxQueues => {
        'Registry' => '*MaxRSSProcessors',
        'Default'  => '8',
                },
     MaxTxQueues => {
        'Registry' => 'MaxTxQueues',
        'Default'  => '1',
                },
     TxRingSize => {
        'Registry' => 'MaxTxRingLength',
        'Default'  => '512',
                },
     RxRing1Size => {
        'Registry' => 'MaxRxRing1Length',
        'Default'  => '512',
                },
     RxRing2Size => {
        'Registry' => 'MaxRxRing2Length',
        'Default'  => '512',
                },
     LargeRxBuffers => {
        'Registry' => 'NumRxBuffersLarge',
        'Default'  => '768',
                },
     SmallRxBuffers => {
        'Registry' => 'NumRxBuffersSmall',
        'Default'  => '1024',
                },
     OffloadIPOptions => {
        'Registry' => 'OffloadIpOptions',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     OffloadTCPOptions => {
        'Registry' => 'OffloadTcpOptions',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     RSS => {
        'Registry' => '*RSS',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '0',
                },
     VLAN => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '2',
        'Disable'  => '0',
        'Default'  => '3',
                },
     Priority => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '3',
                },
             },
        );

$vmxnet3{'Default'} = $vmxnet3{'Ndis6'};

# The registry settings for vmxnet2 is defined below
%vmxnet2 = (
   'Ndis5' => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
       TSOIPv4 => {
         'Registry' => 'TsoEnable',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1',
                 },
       JumboFrame => {
          'Registry' => 'MTU',
          'Enable'   => '9000',
          'Disable'  => '1500',
          'Default'  => '1500',
                     },
       TCPGiantIPv4 => 'NA',
       TCPTxChecksumIPv4   => 'NA',
       TCPRxChecksumIPv4   => 'NA',
       UDPTxChecksumIPv4   => 'NA',
       UDPRxChecksumIPv4   => 'NA',
       TCPGiantIPv6 => 'NA',
       TSOIPv6      => 'NA',
       TCPTxChecksumIPv6   => 'NA',
       TCPRxChecksumIPv6   => 'NA',
       UDPTxChecksumIPv6   => 'NA',
       UDPRxChecksumIPv6   => 'NA',
       WakeOnLAN => 'NA',
       InterruptModeration => 'NA',
       MaxRxQueues => 'NA',
       MaxTxQueues => 'NA',
       TxRingSize => 'NA',
       RxRing1Size => 'NA',
       RxRing2Size => 'NA',
       LargeRxBuffers => 'NA',
       SmallRxBuffers => 'NA',
       OffloadIPOptions => 'NA',
       OffloadTCPOptions => 'NA',
       RSS => 'NA',
              }
           );

# There is no difference in the registry settings for vmxnet2 between
# Ndis5 and Ndis6. The NDIS version of vmxnet2 is 5.0
$vmxnet2{'Ndis6'} = $vmxnet2{'Ndis5'};
$vmxnet2{'Default'} = $vmxnet2{'Ndis5'};

# Assuming the vmware tools has been installed inside the guest
# and the vmxnet driver loads on AMD PCNet device during boot time

%vlance = %vmxnet2;

%e1000e = (
  Ndis6  => {
     SetMAC => {
         'Registry' =>  'NetworkAddress',
         'Default' => ''
                },
     TSOIPv4 => {
         'Registry' =>  '*LsoV1IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '1'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     TCPTxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3',
                },
     TCPRxChecksumIPv6   => {
         'Registry' =>  '*TCPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     UDPTxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv6   => {
         'Registry' =>  '*UDPChecksumOffloadIPv6',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     IPTxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3',
                },
     IPRxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     TSOIPv6      => 'NA',
     TCPGiantIPv4 => {
         'Registry' =>  '*LsoV2IPv6',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     WakeOnLAN => 'NA',
     InterruptModeration => {
        'Registry' => '*InterruptModeration',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '1',
                },
     MaxRxQueues => 'NA',
     MaxTxQueues => 'NA',
     TxRingSize => {
        'Registry' => '*TransmitBuffers',
        'Default'  => '512',
                },
     RxRing1Size => {
        'Registry' => '*ReceiveBuffers',
        'Default'  => '256',
                },
     RxRing2Size => 'NA',
     LargeRxBuffers => 'NA',
     SmallRxBuffers => 'NA',
     OffloadIPOptions => 'NA',
     OffloadTCPOptions => 'NA',
     VLAN => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '2',
        'Disable'  => '0',
        'Default'  => '3',
                },
     Priority => {
        'Registry' => '*PriorityVLANTag',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '3',
                },
     RSS => {
        'Registry' => '*RSS',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '0',
                },
     RSSQueus => {
        'Registry' => '*NumRssQueues',
        'Default'  => '1',
                },
     JumboFrame => {
        'Registry' => '*JumboPacket',
        'Enable'   => '9014',
        'Disable'  => '1514',
        'Default'  => '1514',
                },
     AdaptiveIFS => {
        'Registry' => 'AdaptiveIFS',
        'Enable'   => '1',
        'Disable'  => '0',
        'Default'  => '0',
                },
             },
        );

$e1000e{'Default'} = $e1000e{'Ndis6'};
%ixgbe = (
  Ndis6  => {
     TCPGiantIPv4 => {
         'Registry' =>  '*LsoV2IPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '0'
                },
     TCPTxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     TCPRxChecksumIPv4   => {
         'Registry' =>  '*TCPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPTxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3'
                },
     UDPRxChecksumIPv4   => {
         'Registry' =>  '*UDPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     IPTxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '1',
         'Disable' => '0',
         'Default' => '3',
                },
     IPRxChecksum   => {
         'Registry' =>  '*IPChecksumOffloadIPv4',
         'Enable'  => '2',
         'Disable' => '0',
         'Default' => '3',
                },
     TSOIPv6      => 'NA',
     TCPGiantIPv6 => 'NA',
     TCPTxChecksumIPv6   => 'NA',
     TCPRxChecksumIPv6   => 'NA',
     UDPTxChecksumIPv6   => 'NA',
     UDPRxChecksumIPv6   => 'NA',
     WakeOnLAN => 'NA',
     InterruptModeration => 'NA',
     MaxRxQueues => 'NA',
     MaxTxQueues => 'NA',
     TxRingSize => 'NA',
     RxRing1Size => 'NA',
     RxRing2Size => 'NA',
     LargeRxBuffers => 'NA',
     SmallRxBuffers => 'NA',
     OffloadIPOptions => 'NA',
     OffloadTCPOptions => 'NA',
     RSS => 'NA',
     JumboFrame => {
        'Registry' => '*JumboPacket',
        'Enable'   => '9014',
        'Disable'  => '1514',
        'Default'  => '1514',
                },
             },
        );
$ixgbe{'Default'} = $ixgbe{'Ndis6'};


1;
