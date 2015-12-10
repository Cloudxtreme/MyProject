########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlineJava::Portgroup::NSXNetwork;

#
# This package is a base class which stores attributes and
# implements methods relevant to nsx network
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
#     VDNetLib::InlineJava::Portgroup::NSXNetwork
#
# Input:
#     named hash:
#        'name' : nsx network name
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
   $self->{'id'} = $options{'id'};
   $self->{'type'} = $options{'type'} || "nsx";
   bless $self, $class;
   return $self;
}
1;

