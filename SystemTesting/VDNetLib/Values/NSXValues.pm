########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Values::NSXValues;

use strict;
use warnings;

use base qw(VDNetLib::Values::ParentValues);

use constant CONSTRAINTSDATABASE => {};

########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Values::NSXValues
#      class.
#
# Input:
#      None
#
# Results:
#      Returns a VDNetLib::Values::NSXValues object, if successful;
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my $self;
   bless($self, $class);

   # Adding Constraint Database

   $self->{constraintValue} = $self->GetConstraintsTable();

   return $self;
}
1;
