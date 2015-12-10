########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::IPDiscoveryProfile;

use strict;
use warnings;
use Data::Dumper;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS VDCleanErrorStack);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::IPDiscoveryProfile
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::IPDiscoveryProfile;
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
   $self->{_pyclass} = 'vmware.nsx.manager.ipdiscovery_profile.' .
                       'ipdiscovery_profile_facade.IPDiscoveryProfileFacade';
   $self->{_pyIdName} = "id_";
   if (not defined $self->{parentObj}) {
      $vdLogger->Error("Parent object not passed to create IP Discovery profile");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless $self;
   return $self;
}

1;
