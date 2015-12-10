########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXManager::LogicalPort;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError FAILURE SUCCESS);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);

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
   $self->{_pyIdName} = 'id_';
   $self->{parentObj} = $args{parentObj};
   $self->{_pyclass} = 'vmware.nsx.manager.' .
                       'logical_port.logical_port_facade.LogicalPortFacade';
   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for Logical Port");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless $self;
   return $self;
}


######################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $parentObj = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass}, $parentObj,
                                              $self->{id});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   return $inlinePyObj;
}

1;
