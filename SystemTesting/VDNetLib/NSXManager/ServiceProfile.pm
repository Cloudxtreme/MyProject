########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::ServiceProfile;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::ServiceProfile
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::ServiceProfile;
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
   $self->{_pyclass} = 'vmware.nsx.manager.service_profile.' .
                       'service_profile_facade.ServiceProfileFacade';
   if (not defined $args{parentObj}) {
     $vdLogger->Error("Parent object not passed to create service profile");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }
   bless $self;
   return $self;
}

1;
