########################################################################
#
# Copyright (C) 2015 VMWare, Inc.
#
# All Rights Reserved
#
########################################################################

package VDNetLib::NSXManager::StateSynchNode;


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
#     VDNetLib::NSXManager::StateSynchNode
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::StateSynchNode;
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
  $self->{_pyclass} = 'vmware.nsx.manager.state_synch_node.' .
                      'state_synch_node_facade.StateSynchNodeFacade';
  bless $self;
  return $self;
}

1;
