########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::NVPController::TransportZone;
#
# This package allows to perform various operations on Transport Zone
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

use constant attributemapping => {};

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
   $self->{nvpController} = $args{nvpController};
   bless $self, $class;
   $self->GetInlinePyObject();
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
   my $inlinePyNVPControllerObj = $self->{nvpController}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('nvp_transport_zone.TransportZone',
                                               $inlinePyNVPControllerObj,
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
# ProcessSpec --
#     Method to process the given array of transport zone spec
#     and convert them a form required Inline Python API
#
# Input:
#     Reference to an array of hash
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
   my @newArrayOfSpec;

   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      $tempSpec->{display_name} = $spec->{name};
      my @tagArray;
      foreach my $tagSpec (@{$spec->{tags}}) {
         push @tagArray, $tagSpec->{Tag};
      }
      $tempSpec->{tags} = \@tagArray;
      push(@newArrayOfSpec, $tempSpec);
   }
   return \@newArrayOfSpec;
}


1;
