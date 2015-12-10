########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Neutron::LogicalServicesNodeInterface;
#
# This package allows creation of logical services node interface on Neutron
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
      'interface_number' => {
         'payload' => 'interface_number',
         'attribute' => undef,
      },
      'interface_type' => {
         'payload' => 'interface_type',
         'attribute' => undef,
     },
     'interface_options' => {
         'payload' => 'interface_options',
         'attribute' => undef,
     },
     'enable_send_redirects' => {
         'payload' => 'enable_send_redirects',
         'attribute' => undef,
     },
     'enable_proxy_arp' => {
         'payload' => 'enable_proxy_arp',
         'attribute' => undef,
     },
     'address_groups' => {
         'payload' => 'address_groups',
         'attribute' => undef,
     },
     'primary_ip_address' => {
         'payload' => 'primary_ip_address',
         'attribute' => undef,
     },
     'subnet' => {
         'payload' => 'subnet',
         'attribute' => undef,
     },
     'secondary_ip_addresses' => {
         'payload' => 'secondary_ip_addresses',
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
#      An object of VDNetLib::Neutron::LogicalServicesNodeInterface
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
   my $inlinePyObj = CreateInlinePythonObject('logical_services_interface.LogicalServicesInterface',
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
