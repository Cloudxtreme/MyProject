###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Vmknic;

#
# This package contains attributes and methods to configure virtual
# ethernet adapter on a vmk
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler);


use constant TRUE  => 1;
use constant FALSE => 0;
use constant VNIC_SPEC => 'com.vmware.vc.HostVirtualNicSpec';
use constant IPV6_CONFIGURATION => 'com.vmware.vc.HostIpConfigIpV6AddressConfiguration';
use constant IPV6_ADDRESS => 'com.vmware.vc.HostIpConfigIpV6Address';
use constant IPCONFIG => 'com.vmware.vc.HostIpConfig';


########################################################################
#
# new--
#     Constructor for class  VDNetLib::InlineJava::Vmknic
#     TODO: Create Host folder and move this class to that folder
#
# Input:
#     host    : reference to VDNetLib::InlineJava::Host
#     deviceId: device label, for example "vmk1"
#     anchor  : Inline Host anchor
#
# Results:
#     Blessed reference of VDNetLib::InlineJava::Vmknic
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;
   $self->{'host'}  = $options{'host'};
   $self->{'deviceId'}  = $options{'deviceId'};
   $self->{'anchor'} = $self->{'host'}{'anchor'};
   bless $self, $class;
   eval {
      if (not defined $self->{'networkSystem'}) {
         $self->{networkSystem} = CreateInlineObject("com.vmware.vcqa.vim.host.NetworkSystem",
                                                     $self->{'anchor'});
      }
      if (not defined $self->{'networkMOR'}) {
        $self->{networkMOR} = $self->{networkSystem}->getNetworkSystem($self->{host}{hostMOR});
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating " .
                       "VDNetLib::InlineJava::Host object");
      return FALSE;
   }
   return $self;
}


########################################################################
#
# ConfigureVmknicSpec --
#     Method to configure vmknic spec using the given
#     parameters
#
# Input:
#     spec  : inlineVmknicSpec spec that needs to applied on vmknic
#             adapter on host
#
# Results:
#     Configure vmknic on host, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVmknicSpec
{
   my $self            = shift;
   my $spec            = shift;
   my %args            = %$spec;
   my $inlinePortgroup = $args{'portgroup'} || "";
   my $ip              = $args{'ip'} || "";
   my $mac             = $args{'macaddress'};
   my $netmask         = $args{'netmask'};
   my $prefixLen       = $args{'prefixLen'};
   my $mtu             = $args{'mtu'};
   my $netstack        = $args{'netstack'};
   my $networkSystem   = $self->{networkSystem};
   my $networkMOR      = $self->{networkMOR};
   my ($portgroup, $portConnection, $nicSpec, $hostNetworkInfo, $hostVirtualNic);
   my @beforeAddArray = ();
   my @afterAddArray = ();
   my $deviceId;

   eval {
      # create vnic spec.
      $nicSpec = CreateInlineObject(VNIC_SPEC);
      if (defined $netstack) {
         $nicSpec->setNetStackInstanceKey($netstack);
      }

      if ($ip ne "") {
         my $ipConfig = CreateInlineObject(IPCONFIG);
         $nicSpec->setIp($ipConfig);
         if ($ip eq "dhcp") {
            $nicSpec->getIp()->setDhcp("true");
         } elsif ($ip eq "dhcpv6") {
            my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
            $ipv6Config->setDhcpV6Enabled("true");
            $nicSpec->getIp()->setIpV6Config($ipv6Config);
         } elsif ($ip eq "autoconf") {
            my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
            $ipv6Config->setAutoConfigurationEnabled("true");
            $ipv6Config->setIpV6Config($ipv6Config);
         } elsif ($ip =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/i) {
            $ipConfig->setIpAddress($ip);
            $ipConfig->setSubnetMask($netmask);
         } else {
            my $ipv6Address = CreateInlineObject(IPV6_ADDRESS);
            $ipv6Address->setIpAddress($ip);
            $ipv6Address->setPrefixLength($prefixLen);
            my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
            $ipv6Config->getIpV6Address()->add($ipv6Address);
            $nicSpec->getIp()->setIpV6Config($ipv6Config);
         }
      }
      if (defined $mtu) {
         $nicSpec->setMtu($mtu);
      }
      if (defined $mac) {
         $nicSpec->setMac($mac);
      }
      if ($inlinePortgroup ne "") {
         if ($inlinePortgroup->{type} eq "standard") {
            $portgroup = $inlinePortgroup->{name};
            $nicSpec->setPortgroup($portgroup);
         } else {
            $portConnection = $inlinePortgroup->GetPortConnection();
            $nicSpec->setDistributedVirtualPort($portConnection);
            $portgroup = "";
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure the vmknic spec");
      return FALSE;
   } else {
     return $nicSpec;
   }
}


########################################################################
#
# Reconfigure --
#     Method to configure vmknic on Host
#
# Input:
#     inlineVmknicSpec: vmknic spec that needs to applied on vmknic
#                       vmknic adapter on host
#
#
# Results:
#     Updated vmknic spec, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Reconfigure
{
   my $self = shift;
   my $inlineVmknicSpec = shift;
   my $deltaSpec = $self->ConfigureVmknicSpec($inlineVmknicSpec);
   eval {
      my $networkSystem = $self->{networkSystem};
      my $networkMOR = $self->{networkMOR};
     $networkSystem->updateVirtualNic($networkMOR, "$self->{deviceId}", $deltaSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure vmknic spec for $self->{deviceId}");
      return FALSE;
   }
}

1;