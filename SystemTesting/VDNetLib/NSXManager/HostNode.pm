########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::HostNode;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::NSXManager::HostNode
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::HostNode;
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
   $self->{_pyclass} = 'vmware.nsx.manager.hostnode.hostnode_facade.HostNodeFacade';
   $self->{parentObj} = $args{parentObj};
   bless $self;
   return $self;
}

1;
