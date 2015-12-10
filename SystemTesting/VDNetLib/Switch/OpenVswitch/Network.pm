########################################################################
#  Copyright (C) 2013 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::OpenVswitch::Network;

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::InlineJava::Portgroup::NSXNetwork;

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::Switch::OpenVswitch::Network
#
# Input:
#     named hash parameter with following keys:
#     network: name of the network
#     switchObj: reference to OVS switch object
#     hostOpsObj: reference to host object
#     stafHelper: reference to stafhelper object
#
# Results:
#     blessed hash reference of VDNetLib::Switch::OpenVswitch::Network
#
# Side effects:
#     None
#
########################################################################

sub new
{

    my $class      = shift;
    my %args       = @_;
    my $self       = {
       'network'     => $args{'network'},
       'id'     => $args{'id'},
       'swictchObj'  => $args{'switchObj'},
       'type'        => 'nsx.network',
       'hostOpsObj'  => $args{'hostOpsObj'},
       'stafHelper'  => $args{'stafHelper'},
    };

    bless $self;
}


########################################################################
#
# GetId --
#     Method to return id of this network object
#
# Input:
#     None
#
# Results:
#     network id
#
# Side effects:
#     None
#
########################################################################

sub GetId
{
   my $self   = shift;
   return $self->{'id'};
}


########################################################################
#
# GetInlinePortgroupObject --
#   Implements the method to get inline portgroup object
#   (referring to portgroup since all other inherited classes implements
#   this method)
#
# Input:
#     None
#
# Results:
#     An instance of VDNetLib::InlineJava::Portgroup::NSXNetwork
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePortgroupObject
{
    my $self = shift;
    return VDNetLib::InlineJava::Portgroup::NSXNetwork->new(
                                                'name' => $self->{'network'},
                                                'id'  => $self->{'id'});
}
1;
