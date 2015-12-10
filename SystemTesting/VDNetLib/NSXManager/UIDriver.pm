########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::UIDriver;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::UIDriver
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::UIDriver;
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
   $self->{ip}       = $args{ip};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   my $build = $args{build};
   $self->{_pyclass} = 'vmware.nsx.manager.ui_driver.ui_driver_facade.UIDriverFacade';
   bless $self;
   return $self;
}

1;
