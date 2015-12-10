########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::AuthServer::AuthServer;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use base 'VDNetLib::Root::Root';

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::AuthServer::AuthServer
#
# Input:
#     ip       : ip address of the AuthServer
#     username : username of the AuthServer
#     password : password of the AuthServer
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::AuthServer::AuthServer
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{ip}       = $args{ip};
   $self->{user}     = $args{username};
   $self->{password} = $args{password};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.auth_server.auth_server_facade.AuthServerFacade';
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Method to get Python equivalent object of this class
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
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my %args = @_;

   my $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password});
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object for AuthServer");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}

1;

