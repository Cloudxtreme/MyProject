########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Neutron::MulticastRange;

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
   'schema' => {
      'payload' => 'schema',
      'attribute' => undef,
   },
   'begin' => {
      'payload' => 'start',
      'attribute' => undef,
   },
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::Neutron::MulticastRange
#
# Input:
#     neutron : neutron ip
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::Neutron::MulticastRange;
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
   my $inlinePyObj = CreateInlinePythonObject('multicast_range.MulticastRange',
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
