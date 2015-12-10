########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::DHCPServer::DHCPServer;
use VDNetLib::VM::VMOperations;
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
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
   ## point to the python class of dhcpserver
   $self->{_pyclass} = 'vmware.dhcpserver.dhcpserver_facade.DHCPServerFacade';
   $self->{_pyIdByName} = $self->{vmIP};
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
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}
1;
