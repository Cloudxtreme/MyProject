########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::LoadBalancerConfig;

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
   'serviceid' => {
      'payload' => 'serviceid',
      'attribute' => 'id'
   },
   'instancetemplateuniqueid' => {
      'payload' => 'instancetemplateuniqueid',
      'attribute' => 'id'
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
#     VDNetLib::VSM::Gateway::LoadBalancerConfig
#
# Input:
#        None
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Gateway::LoadBalancerConfig
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
   $self->{gateway} = $args{gateway};
   bless $self, $class;
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
   my $inlinePyEdgeObj = $self->{gateway}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('load_balancer.LoadBalancer',
                                               $inlinePyEdgeObj,
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
