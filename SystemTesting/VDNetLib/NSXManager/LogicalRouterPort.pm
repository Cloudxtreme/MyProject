########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::LogicalRouterPort;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::NSXManager::LogicalRouterPort
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::LogicalRouterPort;
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
   if (not defined $args{parentObj}) {
     $vdLogger->Error("Parent object not passed to create logical router port");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }
   $self->{_pyclass}  = 'vmware.nsx.manager.logical_router_port.logical_router_port_facade.LogicalRouterPortFacade';
   bless $self;
   return $self;
}

########################################################################
#
# GetIPv4 -
#       This method returns the IPv4 address configured for the
#       logical router port.
#
# Input:
#       None
#
# Results:
#       IPv4 address, if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetIPv4
{
   my $self = shift;
   return $self->get_ip();
}

########################################################################
#
# Reconfigure --
#     Method to edit the logical router port configuration
#
# Input:
#     Reference to a hash
#
# Results:
#     SUCCESS, if the logical router port is reconfigured correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Reconfigure
{
   my $self             = shift;
   my $payload          = shift;

   return $self->UpdateComponent($payload);
}

1;
