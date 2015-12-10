########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Common::Result;
#
# The Result Class to represent result attributes and methods in vdnet
#

use strict;
use warnings;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

########################################################################
#
# new -
#       This is the constructor module for Result
#
# Input:
#       A named parameter (hash) with following keys:
#       status : SUCCESS or FAILURE (required)
#       response : result hash of the server data(Required)
#       error    : indicate where is wrong
#       reason   : Indicate why is wrong
# Results:
#       An instance/object of Result class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = {
      'status'   => "FAILURE",
      'response' => undef,
      'error'    => undef,
      'reason'   => undef,
   };

   $self->{'status'} = $args{'status'};
   $self->{'response'} = $args{'response'};
   $self->{'error'} = $args{'error'};
   $self->{'reason'} = $args{'reason'};

   return $self;
}

1;
