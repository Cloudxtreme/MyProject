########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::IPSet;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base 'VDNetLib::Root::Root';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger);

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::IPSet
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::IPSet;
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
     $vdLogger->Error("Parent object not passed to create ipset");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }

   $self->{_pyIdName} = 'id_';
   $self->{_pyclass}  = 'vmware.nsx.manager.ipset.' .
                        'ipset_facade.IPSetFacade';
   bless $self;
   return $self;
}
1;
