########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::Route;

use strict;
use warnings;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::Route
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::Route;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyclass} = 'vmware.nsx.manager.appliancemanagement.route'.
   '.route_facade.RouteFacade';
   $self->{_pyIdName} = 'id_';
   bless $self;
   return $self;
}

1;
