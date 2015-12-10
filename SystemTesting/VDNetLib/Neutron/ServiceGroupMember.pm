########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Neutron::ServiceGroupMember;
#
# This package allows to perform Grouping Object - Service Group Member addition and deletion
#      operations on Neutron
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
	'member' => {
         'payload'   => '_member_id',
         'attribute' => 'id',
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
#      An object of VDNetLib::Neutron::ServiceGroupMember
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
   my $inlinePyObj = CreateInlinePythonObject('servicegroupmember.ServiceGroupMember',
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