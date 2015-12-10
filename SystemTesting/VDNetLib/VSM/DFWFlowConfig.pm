########################################################################
# Copyright (C) 2014 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::DFWFlowConfig;
#
# This package allows configuration of Flow capture and exclusions for
# DFW.
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
use Inline::Python qw(eval_python
                     py_bind_class
                     py_eval
                     py_study_package
                     py_call_function
                     py_call_method
                     py_is_tuple);

# Database of attribute mappings

use constant attributemapping => {
     'config_flow_exclusion' => {
         'payload'   => 'config_flow_exclusion',
         'attribute' => undef,
         'pyClass'   => 'flow_configuration.FlowConfiguration',
     },
    };

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      vsm : vsm ip(Required)
#
# Results:
#      An object of VDNetLib::VSM::DFWFlowConfig
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
   $self->{vsm} = $args{vsm};
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject(endpoint_version => "2.1");
   my $inlinePyObj = CreateInlinePythonObject('flow_configuration.FlowConfiguration',
                                               $inlinePyVSMObj,
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $inlinePyObj->{id} = $self->{id};
   return $inlinePyObj;
}

1;
