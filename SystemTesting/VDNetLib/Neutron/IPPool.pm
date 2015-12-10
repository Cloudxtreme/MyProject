########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Neutron::IPPool;

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

use constant attributemapping => {
   'name' => {
      'payload' => 'display_name',
      'attribute' => undef,
   },
   'groupingobject_desc' => {
      'payload' => 'description',
      'attribute' => undef,
   },
   'subnets' => {
      'payload' => 'subnets',
      'attribute' => undef,
   },
   'static_routes' => {
      'payload' => 'static_routes',
      'attribute' => undef,
   },
   'destination_cidr' => {
      'payload' => 'destination_cidr',
      'attribute' => undef,
   },
   'next_hop' => {
      'payload' => 'next_hop',
      'attribute' => undef,
   },
   'dns_nameservers' => {
      'payload' => 'dns_nameservers',
      'attribute' => undef,
   },
   'allocation_ranges' => {
      'payload' => 'allocation_ranges',
      'attribute' => undef,
   },
   'start' => {
      'payload' => 'start',
      'attribute' => undef,
   },
   'end' => {
      'payload' => 'end',
      'attribute' => undef,
   },
   'gateway_ip' => {
      'payload' => 'gateway_ip',
      'attribute' => undef,
   },
   'ip_version' => {
      'payload' => 'ip_version',
      'attribute' => undef,
   },
   'cidr' => {
      'payload' => 'cidr',
      'attribute' => undef,
   },
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::Neutron::IPPool
#
# Input:
#     ip : ip address of the neutron controller
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::Neutron::IPPool;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{neutron} = $args{neutron};
   $self->{type} = "neutron";
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
   my $inlinePyObj = CreateInlinePythonObject('ippool.IPPool',
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
