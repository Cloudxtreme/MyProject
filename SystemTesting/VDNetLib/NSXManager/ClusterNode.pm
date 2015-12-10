########################################################################

# Copyright (C) 2014 VMWare, Inc.

# All Rights Reserved

########################################################################

package VDNetLib::NSXManager::ClusterNode;


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
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::ClusterNode
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::ClusterNode;
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
  $self->{parentObj} = $args{parentObj};
  $self->{_pyclass} = 'vmware.nsx.manager.cluster_node.' .
                      'cluster_node_facade.ClusterNodeFacade';
  bless $self;
  return $self;

}

1;
