########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::AuthServer::AuthServerOperations;

use strict;
use warnings;
use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use Data::Dumper;
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant attributemapping => {
   'build' => {
         'payload'   => 'build',
         'attribute' => undef,
   }
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::AuthServer::AuthServerOperations
#
# Input:
#     ip       : ip address of the AuthServer
#     username : username of the AuthServer
#     password : password of the AuthServer
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::AuthServer::AuthServerOperations;
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
   bless $self, $class;
   return $self;
}


########################################################################
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
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my %args = @_;

   my $inlinePyObj = CreateInlinePythonObject('auth_server.AuthServer',
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

######################################################################
#
# ExecuteCommand --
#     Method to execute command on Authentication Server
#
# Input:
#     authserver_command: 'ls'
#
# Results:
#     SUCCESS or FAILURE
#
# Side effects:
#     None
#
########################################################################
sub ExecuteCommand
{
   my $self   = shift;
   my %params = @_;
   my $result = SUCCESS;

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
       # Execute command
       my $result = $inlinePyObj->execute_command(
                                      $params{'authserver_command'});
   };
   if ($@) {
      my $errorInfo = "Exception thrown while executing command on" .
                       "AuthServer in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      return 'FAILURE';
   }
   return $result;
}

1;
