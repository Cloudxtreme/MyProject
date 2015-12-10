########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::ServiceProfile;

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
   'id' => {
      'payload' => 'id',
      'attribute' => 'id'
   },
   'vendorid' => {
      'payload' => 'idfromvendor',
      'attribute' => undef
   },
   'vendortemplateattribute' => {
      'payload' => 'vendortemplate',
      'attribute' => undef
   },
   'serviceprofilebinding' => {
      'pyClass' => 'service_profile_binding.ServiceProfileBinding',
   },
   'string' => {
      'payload' => 'string',
      'attribute' => 'GetMORId'
   },
   'virtualwireid' => {
      'payload' => 'string',
      'attribute' => 'id'
   },
   'getserviceprofileflag' => {
      'payload' => '_getserviceprofileflag',
      'attribute' => undef
   },
   'serviceprofilename' => {
      'payload' => '_serviceprofilename',
      'attribute' => undef
   },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::ServiceProfile
#
# Input:
#     vsm : vsm ip
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::ServiceProfile;
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
   my $inlinePyObj = CreateInlinePythonObject('service_profile.ServiceProfile',
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
