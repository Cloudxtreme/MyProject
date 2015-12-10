########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::DNKeys;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::DNKeys
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::DNKeys;
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
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.dnkeys.dnkeys_facade.DNKeysFacade';
   bless $self;
   return $self;
}

1;
