########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::NetworkFeatures;

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
#     Contructor to create an instance of this class
#     VDNetLib::VSM::NetworkFeatures
#
# Input:
#     id  : python id of the component
#     vsm : vsm on which the call is made
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::NetworkFeatures
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
   $self->{network} = $args{network};
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $network = $self->{network};
   my $inlinePyObj = CreateInlinePythonObject('vsm_network_feature.NetworkFeature',
                                               $inlinePyVSMObj,
                                               $network
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
#     Method to create a spec for assigning role to user
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
   my $ipConfig;
   my $macConfig;


   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      $self->{network} = $spec->{network};
      my $networkFeatures = $spec->{networkfeatures};
      if (defined ($networkFeatures->{ipDiscovery}) &&
           ($networkFeatures->{ipDiscovery} eq "enable") ) {
         $ipConfig->{enabled} = "true";
      } else {
         $ipConfig->{enabled} = "false";
      }
      if (defined ($networkFeatures->{macLearning}) &&
           ($networkFeatures->{macLearning} eq "enable")) {
         $macConfig->{enabled} = "true";
      } else {
         $macConfig->{enabled} = "false";
      }
      $tempSpec->{ipDiscoveryConfig} = $ipConfig;
      $tempSpec->{macLearningConfig} = $macConfig;
      push(@newArrayOfSpec, $tempSpec);
   }

   return \@newArrayOfSpec;
}

1;
