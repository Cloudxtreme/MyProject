########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Service::ClusterDeploymentConfigs;

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
use VDNetLib::Common::EsxUtils;
use Data::Dumper;

use constant attributemapping => {
   'clusterid' => {
      'payload' => 'clusterid',
      'attribute' => 'GetClusterMORId'
   },
   'datastore' => {
      'payload' => 'datastore',
      'attribute' => 'GetMORId'
   },
   'dvportgroup' => {
      'payload' => 'dvportgroup',
      'attribute' => 'GetMORId'
   },
   'serviceinstanceid' => {
      'payload' => 'serviceinstanceid',
      'attribute' => 'id'
   },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Service::ClusterDeploymentConfigs
#
# Input:
#     vsm : vsm ip
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Service::ClusterDeploymentConfigs;
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
   $self->{service} = $args{service};
   if ("VDNetLib::VSM::Service" ne blessed($self->{service})) {
      $vdLogger->Error("Invalid object reference passed for service");
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
   my $inlinePyServiceObj = $self->{service}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('cluster_deployment_configs.ClusterDeploymentConfigs',
                                               $inlinePyServiceObj,
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
# Setter --
#      This method stores the cluster id in the object
#      E.g. ClusterDeploymentConfigs needs to save the pointer to VC's cluster obj
#      so that update calls and delete calls of ClusterDeploymentConfigs can
#      use the mob id of the cluster
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub Setter
{
   my $self = shift;
   my $specReference = shift;

   my %spec = %$specReference;
   foreach my $key ( keys %spec ) {
      foreach my $temp ( @{$spec{$key}} ) {
         $self->{clustermobid} = $temp->{clusterid};
      }
   }
   return SUCCESS;
}

1;
