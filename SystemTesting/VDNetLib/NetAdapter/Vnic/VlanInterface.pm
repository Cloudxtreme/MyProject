#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::NetAdapter::Vnic::VlanInterface;

use strict;
use warnings;
use Data::Dumper;
# Inheriting from VDNetLib::NetAdapter::NetAdapter package.
use vars qw /@ISA/;

use base qw(VDNetLib::NetAdapter::Vnic::Vnic);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError
                                   VDGetLastError VDCleanErrorStack );
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use constant STANDBY_TIMEOUT => 120;
use constant DEFAULT_SLEEP => 20;



########################################################################
#
# new -
#       This is the constructor module for NetAdapterClass
#
# Input:
#       vnicObj       - parent object of vlan interface object (Required)
#       vlanInterface - should look like eth0.17 which means vlan id 17
#                       has been added to interface eth0
#
# Results:
#       An instance/object of NetAdapter class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class         = shift;
   my %options       = @_;
   my $vnicObj       = $options{'vnicObj'};
   my $vlanInterface = $options{'vlanInterface'};

   my $self = {
      controlIP   => $vnicObj->{controlIP},
      interface   => $vlanInterface,
      macAddress  => $vnicObj->{macAddress},
      nicType     => $vnicObj->{nicType},
      deviceLabel => $vnicObj->{deviceLabel},
      vnicObj     => $vnicObj,
      vmOpsObj    => $vnicObj->{'vmOpsObj'},
      driver      => $vnicObj->{driver},
      @_,
   };

   #
   # Key parentObj below is used to store parent vnic object after vlan
   # interface creation;
   #
   $self->{'parentObj'} = undef;
   bless $self, $class;
   $self->{'intType'} = "vnic";
   return $self;
}
1;