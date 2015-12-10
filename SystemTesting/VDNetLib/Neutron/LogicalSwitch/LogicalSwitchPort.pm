########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Neutron::LogicalSwitch::LogicalSwitchPort;
#
# This package allows to perform logical switch related operations on Neutron
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
      'attachment' => {
         'payload'   => 'attachment',
         'attribute' => undef,
         'pyClass'   => 'vif_attachment.VifAttachment',
      },
      'peer_id' => {
         'payload'   => 'peer_id',
         'attribute' => 'id',
      },
      'vif_uuid' => {
         'payload'   => 'vif_uuid',
         'attribute' => 'GetUUID',
      },
      'type'  => {
         'payload'  => 'type',
         'attribute' => undef,
      },
      # workaround for Bug 1123879
      'host' => {
         'payload'  => '_host_type',
         'attribute' => undef,
      }
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
#      An object of VDNetLib::Neutron::LogicalSwitch
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
   $self->{type} = "neutron";
   bless $self, $class;

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();
   $self->{componentname} = "logicalswitchport";

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
   my $inlinePyObj = CreateInlinePythonObject('logical_switch_port.LogicalSwitchPort',
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
