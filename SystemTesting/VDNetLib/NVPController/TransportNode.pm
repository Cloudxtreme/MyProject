########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::NVPController::TransportNode;
#
# This package allows to perform CRUD operations on Transport node
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
   'mgmtaddress' => {
      'payload' => 'mgmt_address',
      'attribute' => 'hostIP',
   },
   'type' => {
      'payload' => 'type',
      'attribute' => undef,
   },
   'transport_connectors' => {
      'payload' => 'transport_connectors',
      'attribute' => undef,
   },
   'integrationbridgeid' => {
      'payload' => 'integration_bridge_id',
      'attribute' => undef,
   },
   'transport_zone_uuid' => {
      'payload' => 'transport_zone_uuid',
      'attribute' => 'id',
   },
   'ip_address' => {
      'payload' => 'ip_address',
      'attribute' => 'GetUplinkTunnelIP',
   },
};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      nvpController : nvpController node (Required)
#
# Results:
#      An object of VDNetLib::nvpController::VSMRegistration
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
   $self->{nvpController} = $args{nvpController};
   bless $self, $class;
   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();

   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Method to get Python equivalent object of this class
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
   my $inlinePyNVPControllerObj = $self->{nvpController}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('nvp_transport_node.TransportNode',
                                               $inlinePyNVPControllerObj,
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
