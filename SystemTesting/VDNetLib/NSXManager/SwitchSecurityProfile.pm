########################################################################
#  Copyright (C) 2015 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXManager::SwitchSecurityProfile;

use strict;
use warnings;
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     None
#
# Results:
#     bless hash reference to instance of this class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.' .
                       'switch_security_profile.switch_security_profile_facade.' .
                       'SwitchSecurityProfileFacade';
   bless $self;
   return $self;
}
1;
