########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::GlobalDFWSections;
#
# This package allows creation of empty sections in
#

use base qw(VDNetLib::VSM::DFWSections VDNetLib::Root::GlobalObject);

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

use constant attributemapping => {};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      vsm : vsm ip(Required)
#
# Results:
#      An object of VDNetLib::VSM::GlobalDFWSections
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject(endpoint_version => "4.0");
   my $inlinePyObj = CreateInlinePythonObject('dfw_sections.DFWSections',
                                               $inlinePyVSMObj,
                                               'universal',
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $inlinePyObj->{id} = $self->{id};
   return $inlinePyObj;
}

########################################################################
#
# ProcessSpec --
#     Method to process the given array of rule spec and convert them
#     to a single hash form required Inline Python API
#     for bulk config. Overrides the method in AbstractInlinePythonClass
#
# Input:
#     Reference to an array of hash:
#
#        '[1]' => {
#              layer => "layer3",
#              sectionname    => 'Section1',
#        },
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;

   foreach my $spec (@$arrayOfSpec) {

       if(exists $spec->{layer} and exists $spec->{sectionname}) {
          if($spec->{layer} =~ /^layer3redirect$/i) {
              $spec->{_tag_name} = "L3REDIRECT_" . $spec->{sectionname};
              $spec->{_tag_type} = "L3REDIRECT";
              $spec->{_tag_managedby} = "universalroot-0";
          }
          elsif($spec->{layer} =~ /^layer3$/i) {
              $spec->{_tag_name} = "L3_" . $spec->{sectionname};
              $spec->{_tag_type} = "LAYER3";
              $spec->{_tag_managedby} = "universalroot-0";
          }
          elsif($spec->{layer} =~ /^layer2$/i) {
              $spec->{_tag_name} = "L2_" . $spec->{sectionname};
              $spec->{_tag_type} = "LAYER2";
              $spec->{_tag_managedby} = "universalroot-0";
          }
          else {
             $vdLogger->Error("Unknown layer $spec->{layer}");
             VDSetLastError("EINLINE");
             return FAILURE;
          }
          delete $spec->{layer};
          delete $spec->{sectionname};
       }
   }

   return $arrayOfSpec;
}

1;
