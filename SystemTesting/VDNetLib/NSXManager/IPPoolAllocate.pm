########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::IPPoolAllocate;

use strict;
use warnings;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::IPPoolAllocate
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::IPPoolAllocate;
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
   $self->{_pyclass} = 'vmware.nsx.manager.' .
                       'ippool_allocate.ippool_allocate_facade.' .
                       'IPPoolAllocateFacade';
   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for IPPool Allocate");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   bless $self;
   return $self;
}

1;