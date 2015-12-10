########################################################################
#  Copyright (C) 2015 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::TORSwitch::TORSwitch;

use base 'VDNetLib::Root::Root';

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession OVS_VS_CTL OVS_VTEP_CTL);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::Switch::TORSwitch::TORPort;

########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     torGatewayObj  : reference to TOR Gateway object
#     name        : name of the TOR switch, if specify to 'autogenerate',
#                   will choose the first non-occupied bridge
#     stafHelper  : reference to stafHelper object
#
# Results:
#     bless hash reference to instance of this class
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
  $self->{_pyIdName} = 'id';
  $self->{_pyclass} = 'vmware.torgateway.tor_switch.' .
                      'tor_switch_facade.TORSwitchFacade';
  $self->{id} = ' ';
  $self->{name} = ' ';
  if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for TORSwitch");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

  $self->{parentObj} = $args{parentObj};
  bless $self;
  return $self;
}
1;
