########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::QosProfile;

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
#     VDNetLib::NSXManager::QosProfile
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::QosProfile;
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
   $self->{_pyclass} = 'vmware.nsx.manager.qos_profile.qos_profile_facade.QosProfileFacade';
   $self->{_pyIdName} = "id_";
   if (not defined $self->{parentObj}) {
      $vdLogger->Error("Parent object not passed to create qos profile");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless $self;
   return $self;
}

1;
