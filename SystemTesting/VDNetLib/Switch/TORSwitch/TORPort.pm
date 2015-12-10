#######################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::TORSwitch::TORPort;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base 'VDNetLib::Root::Root';

use VDNetLib::Common::GlobalConfig qw($vdLogger OVS_VS_CTL);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );


#######################################################################
#
# new --
#      Constructur to create an instance of this class
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'portid'    : port id
#      'switchObj' : TOR switch object.
#      'stafHelper': Reference to the staf helper object.
#
# Results:
#      An object of VDNetLib::Switch::TORSwitch::TORPort, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub new
{
  my $class = shift;
  my %args = @_;
  my $self = {};
  $self->{_pyIdName} = 'id';
  $self->{_pyclass} = 'vmware.torgateway.tor_port.' .
                      'tor_port_facade.TORPortFacade';
  $self->{id} = '';
  $self->{name} = '';
  if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for TORPort");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

  $self->{parentObj} = $args{parentObj};
  bless $self;
  return $self;
}
1;
