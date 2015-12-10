########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::DeploymentContainer;

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
      'datacenterid' => {
         'payload' => 'value',
         'attribute' => 'GetMORId',
      },
      'datastoreid' => {
         'payload' => 'value',
         'attribute' => 'GetMORId',
      },
      'key' => {
         'payload' => 'key',
         'attribute' => undef,
      },
      'name' => {
         'payload' => 'name',
         'attribute' => undef,
      },
      'hypervisortype' => {
         'payload' => 'hypervisortype',
         'attribute' => undef,
      },
      'cluster_id' => {
         'payload' => 'value',
         'attribute' => 'GetClusterMORId'
      },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::DeploymentContainer
#
# Input:
#     ip : ip address of the vsm
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::DeploymentContainer;
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
   $self->{vsm} = $args{vsm};
   bless $self, $class;

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();
   $self->{type} = "vsm";
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject(
                      'global_deployment_container.GlobalDeploymentContainer',
                                               $inlinePyVSMObj,
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
