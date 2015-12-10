########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlineJava::Portgroup::Portgroup;

#
# This package is a base class which stores attributes and
# implements methods relevant to portgroup.
#
use strict;
use warnings;

use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);


########################################################################
#
# new --
#     Contructore to create an object of
#     VDNetLib::InlineJava::Portgroup::Portgroup
#
# Input:
#     named hash:
#        'name' : portgroup name
#
# Results:
#     blessed reference to this class instance
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;


   my $self;
   $self->{'name'} = $options{'name'};
   $self->{'type'} = "standard";
   bless $self, $class;
   return $self;
}
1;

