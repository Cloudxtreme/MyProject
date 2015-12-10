########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Service::VendorTemplate;

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
   'vendorid' => {
      'payload' => 'idfromvendor',
      'attribute' => undef
   },
};



########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Service::VendorTemplate
#
# Input:
#     vsm : vsm ip
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::VendorTemplate;
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
   my $inlinePyObj = CreateInlinePythonObject('vendor_template.VendorTemplate',
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

1;
