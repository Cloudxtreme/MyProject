########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Service;

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
   'objectid' => {
      'payload' => 'objectid',
      'attribute' => 'id'
   },
   'clusterid' => {
      'payload' => 'string',
      'attribute' => 'GetClusterMORId',
   },
   'deploymentscope' => {
      'payload' => 'string',
      'attribute' => 'GetClusterMORId',
      'pyClass'   => 'deployment_scope.DeploymentScope',
   },
   'progressstatus' => {
      'payload' => 'progressStatus',
      'attribute' => undef,
   },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Service
#
# Input:
#     class : VDNetLib::VSM::Service
#     args  : Hash of args - vsm and VSMOperations Object
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Service;
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
   $self->{type} = "vsm";
   bless $self, $class;
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('service_si.Service',
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


########################################################################
#
# DeleteDeployCluster --
#     Method to delete components/managed objects/entities
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#                         delete is called
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub DeleteDeployCluster
{
   my $self                = shift;
   my $arrayOfPerlObjects  = shift;
   my $arrayOfCorrespondingArgs;

   foreach my $templateObj (@$arrayOfPerlObjects) {
      my $tempSpec = $templateObj->{clustermobid};
      push(@$arrayOfCorrespondingArgs, $tempSpec);
   }
   return $self->DeleteComponent($arrayOfPerlObjects, $arrayOfCorrespondingArgs);
}

1;
