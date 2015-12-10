########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::FabricVm;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::NSXManager::FabricVm
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::FabricVm;
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
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.fabricvm.fabricvm_facade.FabricVmFacade';
   $self->{parentObj} = $args{parentObj};
   bless $self;
   return $self;
}

1;
