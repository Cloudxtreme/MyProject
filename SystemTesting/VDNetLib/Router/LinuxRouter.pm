########################################################################
#  Copyright (C) 2015 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Router::LinuxRouter;
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE);
#XXX(dbadiani): How to make this support deployment on KVM as well ?
use base ('VDNetLib::Root::Root','VDNetLib::VM::ESXSTAFVMOperations');
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger);
########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     vmOpsObj: reference to vmops object
#     hostOpsObj  : reference to host object
#     vmx         : vmx path
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
   my $self = shift; ### This is reference to vmOps object
   my $hostObj = shift;
   my $vmx = shift;
   # Point to the python class of linux router
   $self->{_pyclass} = 'vmware.linuxrouter.linuxrouter_facade.LinuxRouterFacade';
   $self->{_pyIdName} = $self->{vmIP};  # Unique ID to create python object
   bless $self , $class;
   return $self;
}

#####################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
##     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{vmIP},
                                              $self->{_username},
                                              $self->{_password});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". Dumper($@));
      return FAILURE;
   }
   return $inlinePyObj;
}
1;
