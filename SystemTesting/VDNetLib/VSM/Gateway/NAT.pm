########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::NAT;

use base qw(VDNetLib::InlinePython::AbstractInlinePythonClass VDNetLib::VM::ESXSTAFVMOperations);
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
use VDNetLib::Common::EsxUtils;

my $endpoint_version="";

use constant attributemapping => {
       'nat_rules' => {
                'payload' => 'natrules',
                'attribute' => undef,
                     },
       'original_address' => {
                'payload' => 'originaladdress',
                'attribute' => undef,
                     },
       'translated_address' => {
                'payload' => 'translatedaddress',
                'attribute' => undef,
                     },
       'logging_enabled' => {
                'payload' => 'loggingenabled',
                'attribute' => undef,
                     },
       'original_port' => {
                'payload' => 'originalport',
                'attribute' => undef,
                     },
       'edge_interface_index' => {
                'payload' => 'vnic',
                'attribute' => undef,
                     },
       'translated_port' => {
                'payload' => 'translatedport',
                'attribute' => undef,
                     }
};
########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Gateway::NAT
#
# Input:
#        None
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Gateway::NAT
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
   my %args = @_;
   my $inlinePyEdgeObj = $self->{gateway}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('nat.NAT',
                                               $inlinePyEdgeObj,
                                               $endpoint_version,
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
#     Methd to read and process the specifications for creating
#     NAT rules
#
# Input:
#     spec: reference to the spec (user spec/testcase spec)
#
# Results:
#    Modified spec to parameters of payload and api version of
#    REST call for Configuring NAT
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;
   my @newarrayOfSpec = {};
   my $mappingDuplicate = shift;

   if (!%$mappingDuplicate) {
      return $arrayOfSpec;
   }

   foreach my $spec (@$arrayOfSpec) {
       if (FAILURE eq $self->RecurseResolveTuple($spec, $mappingDuplicate)) {
         $vdLogger->Error("Error encountered while resolving tuples");
         VDSetLastError(VDGetLastError());
         return FAILURE;
       };

       last if(!keys %{$spec});

       if($spec->{endpoint_version} != ""){
         $endpoint_version = $spec->{endpoint_version};
       }
       push (@newarrayOfSpec, $spec);
   }
   $vdLogger->Info ("NATArrayOfSpec".Dumper(\@newarrayOfSpec));
   shift @newarrayOfSpec;
   return \@newarrayOfSpec;
}


1;

