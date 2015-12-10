########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Neutron::LogicalServicesNode;
#
# This package allows creation of logical services node on Neutron
#

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

# Database of attribute mappings

use constant attributemapping => {
      'name' => {
         'payload' => 'display_name',
         'attribute' => undef,
      },
      'schema' => {
         'payload' => 'schema',
         'attribute' => undef,
      },
      'location' => {
         'payload' => 'location',
         'attribute' => 'GetMORId',
      },
      'node_capacity' => {
         'payload' => 'node_capacity',
         'attribute' => undef,
     },
     'dhcpservice' => {
         'payload'   => 'dhcpservice',
         'attribute' => undef,
         'pyClass'   => 'services_node_dhcp_config.ServicesNodeDhcpConfig',
     },
     'interface_id' => {
         'payload'   => 'interface_id',
         'attribute' => 'id',
      },
     'firewallservice' => {
         'payload'   => 'firewallservice',
         'attribute' => undef,
         'pyClass'   => 'services_node_firewall_config.ServicesNodeFirewallConfig',
     },
     'source' => {
         'payload' => 'source',
         'attribute' => 'id',
     },
     'destination' => {
         'payload' => 'destination',
         'attribute' => 'id',
     },
     'services' => {
         'payload' => 'services',
         'attribute' => 'id',
     },
     'loadbalancerservice' => {
         'payload'   => 'loadbalancerservice',
         'attribute' => undef,
         'pyClass'   => 'services_node_load_balancer_config.ServicesNodeLoadBalancerConfig',
     },
     'lb_sub_component_name' => {
         'payload' => 'name',
         'attribute' => undef,
      },
      'ipaddress' => {
         'payload' => 'ip_address',
         'attribute' => undef,
      },
      'capacity' => {
         'payload' => 'capacity',
         'attribute' => undef,
      },
      'dns_settings' => {
         'payload' => 'dns_settings',
         'attribute' => undef,
      },
      'domain_name' => {
         'payload' => 'domain_name',
         'attribute' => undef,
      },
      'primary_dns' => {
         'payload' => 'primary_dns',
         'attribute' => undef,
      },
      'secondary_dns' => {
         'payload' => 'secondary_dns',
         'attribute' => undef,
      },
      'dhcp_options' => {
         'payload' => 'dhcp_options',
         'attribute' => undef,
      },
      'hostname' => {
         'payload' => 'hostname',
         'attribute' => undef,
      },
      'default_lease_time' => {
         'payload' => 'default_lease_time',
         'attribute' => undef,
      },
};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      neutron : Neutron node (Required)
#
# Results:
#      An object of VDNetLib::Neutron::LogicalServicesNode
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{neutron} = $args{neutron};
   bless $self, $class;

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();
   $self->{type}     = "neutron";

   return $self;
}

########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyNeutronObj = $self->{neutron}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('logical_services_node.LogicalServicesNode',
                                               $inlinePyNeutronObj,
                                             );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


1;
