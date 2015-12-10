########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VSE::GlobalLIF;

use base qw (VDNetLib::Root::GlobalObject VDNetLib::VSM::VSE::LIF);

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
#     VDNetLib::VSM::VSE::GlobalLIF
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::VSE::GlobalLIF
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
   $self->{globaldistributedlogicalrouter} = $args{globaldistributedlogicalrouter};
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
   my $inlinePyEdgeObj = $self->{globaldistributedlogicalrouter}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('interfaces.Interfaces',
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


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
 return "globaldistributedlogicalrouter";
}
1;
