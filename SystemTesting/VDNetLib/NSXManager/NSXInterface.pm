########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::NSXInterface;

use strict;
use warnings;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::NSXInterface
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::NSXInterface;
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
   $self->{_pyclass} = 'vmware.nsx.manager.appliancemanagement.interface'.
   '.interface_facade.InterfaceFacade';
   $self->{_pyIdName} = 'id_';
   bless $self;
   return $self;
}

1;
