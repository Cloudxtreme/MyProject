########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::ClusterProfile;

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
#     VDNetLib::NSXManager::ClusterProfile
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::ClusterProfile
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
   if (not defined $args{parentObj}) {
     $vdLogger->Error("Parent object not passed to create Cluster Profile");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass}  = 'vmware.nsx.manager.cluster_profile.'.
                        'cluster_profile_facade.ClusterProfileFacade';
   bless $self;
   return $self;
}

1;
