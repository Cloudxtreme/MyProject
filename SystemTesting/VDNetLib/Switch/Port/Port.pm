#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::Port::Port;

#
# This package is responsible for handling all the interaction with
# VMware vNetwork Ports.
#

use strict;
use warnings;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::Switch::Port::Port
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'portid'    : speed of the port 1G/10G
#      'switchObj' : pswitch object.
#      'vmnicObj'  : vmnic object (peer port on host)
#      'stafHelper': Reference to the staf helper object.
#
# Results:
#      An object of VDNetLib::Switch::Port::Port, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self;
   my $portid     = $args{portid};
   my $switchObj  = $args{switchObj};
   my $vmnicObj   = $args{vmnicObj};
   my $stafHelper = $args{stafHelper};
   my $result;

   # check parameters.
   if (not defined $switchObj) {
      $vdLogger->Error("PSwitch objects is not is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{switchObj}  = $switchObj;
   $self->{stafHelper} = $stafHelper;
   $self->{vmnicObj}   = $vmnicObj;
   $self->{portid}     = $portid;

   bless($self, $class);
}

1;
