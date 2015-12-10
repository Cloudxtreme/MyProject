########################################################################
#  Copyright (C) 2015 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::Port::OVSPort;

use strict;
use warnings;
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

########################################################################
#
# new --
#   Creates an instance of OVS port object that provides API for
#   various port operations.
#
# Input:
#   Hash with the following keys:
#     parentObj - Reference to object of type VDNetLib::Switch::Bridge::Bridge
#
# Results:
#   blessed hash reference to instance of this class.
#
# Side effects:
#   None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'name';
   $self->{_pyclass} = 'vmware.kvm.ovs.port.port_facade.PortFacade';
   bless $self;
   return $self;
}
1;
