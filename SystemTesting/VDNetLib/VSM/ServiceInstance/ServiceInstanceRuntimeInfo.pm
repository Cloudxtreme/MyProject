########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::ServiceInstance::ServiceInstanceRuntimeInfo;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use Scalar::Util qw(blessed);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant attributemapping => {
   'versioneddeploymentspecid' => {
      'payload' => 'versioneddeploymentspecid',
      'attribute' => 'id'
   },
   'datastore' => {
      'payload' => 'datastore',
      'attribute' => 'GetMORId'
   },
   'clustermorid' =>{
      'payload' => 'string',
      'attribute' => 'GetClusterMORId'
   },
   'dvpgmorid' => {
      'payload' => 'string',
      'attribute' => 'GetMORId'
   },
   'objectid' => {
      'payload' => 'objectid',
      'attribute' => 'GetMORId'
   },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::ServiceInstance::ServiceInstanceRuntimeInfo
#
# Input:
#     ServiceInstance : ServiceInstance Object
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::$self->GetAttributeMapping();
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
   $self->{serviceinstance} = $args{serviceinstance};
   if ("VDNetLib::VSM::ServiceInstance" ne blessed($self->{serviceinstance})) {
      $vdLogger->Error("Invalid object reference passed for service instance");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
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
   my $inlinePyServiceInstanceObj = $self->{serviceinstance}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('service_instance_runtime_info.ServiceInstanceRuntimeInfo',
                                               $inlinePyServiceInstanceObj,
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
