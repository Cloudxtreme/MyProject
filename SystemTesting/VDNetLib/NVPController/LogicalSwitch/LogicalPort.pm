########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::NVPController::LogicalSwitch::LogicalPort;
#
# This package allows to perform various operations on Logical switch port
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

use constant attributemapping => {
   'transportzones' => {
      'payload' => 'transport_zones',
      'attribute' => undef,
   },
   'name' => {
      'payload' => 'display_name',
      'attribute' => undef,
   },
   'attachment' => {
      'payload'   => 'attachment',
      'attribute' => undef,
      'pyClass'   => 'nvp_attachment.LogicalPortAttachment',
   },
   'vifuuid' => {
      'payload' => 'vif_uuid',
      'attribute' => "GetUUID",
   },
   'type' => {
      'payload' => 'type',
      'attribute' => undef,
   },
};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      nvpController : NVP Controller (Required)
#
# Results:
#      An object of VDNetLib::NVPController::TransportZone
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
   $self->{type} = "nvpController";
   $self->{logicalSwitch} = $args{logicalSwitch};
   bless $self, $class;
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
   my $inlinePyLSwitchControllerObj = $self->{logicalSwitch}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('nvp_logical_switch_port.LogicalSwitchPort',
                                               $inlinePyLSwitchControllerObj,
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
