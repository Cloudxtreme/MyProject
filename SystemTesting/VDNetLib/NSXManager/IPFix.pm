########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXManager::IPFix;

use strict;
use warnings;
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::NSXManager::IPFix
#
# Input:
#     Named hash parameter
#
# Results:
#     blessed hash reference to instance of this class
#     VDNetLib::NSXManager::IPFix
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.ipfix.ipfix_facade.IpfixFacade';
   bless $self;
   return $self;
}
1;
