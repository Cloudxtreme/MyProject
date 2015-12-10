########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NVPController::NVPControllerOperations;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use warnings;
use Data::Dumper;
use vars qw{$AUTOLOAD};
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
#     VDNetLib::NVP::NVPControllerOperations
#
# Input:
#     ip : ip address of the nvp controller
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NVP::NVPControllerOperations;
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
   $self->{ip}       = $args{ip};
   $self->{user}     = $args{username};
   $self->{password} = $args{password};
   $self->{cert_thumbprint} = $args{cert_thumbprint};
   $self->{type}  = "nvpController";
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
   my $inlinePyObj = CreateInlinePythonObject('nvpController.NVPController',
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password},
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}
1;

