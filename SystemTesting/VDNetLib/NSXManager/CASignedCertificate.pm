########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::CASignedCertificate;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::CASignedCertificate
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::CASignedCertificate;
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
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.ca_signed_certificate' .
   '.ca_signed_certificate_facade.CASignedCertificateFacade';
   bless $self;
   return $self;
}

1;
