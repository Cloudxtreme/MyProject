########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Neutron::NeutronOperations;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use warnings;
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
   'edit_mode' => {
         'payload'   => 'operating_mode',
         'attribute' => undef,
      },
   'file' => {
         'payload'   => 'file',
         'attribute' => undef,
   }
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::Neutron::NeutronOperations
#
# Input:
#     ip : ip address of the Neutron node
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::Neutron::NeutronOperations;
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
   $self->{cert_thumbprint} = $args{cert_thumbprint};
   $self->{type}     = "neutron";

   bless $self, $class;

   #Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();

#   bless $self, $class;

   eval {
      my $inlineObj =  $self->GetInlinePyObject();

      $self->{id} = $inlineObj->init_neutron($self->{ip}, $self->{user}, $self->{password});
   };

   if ($@) {
      $vdLogger->Error("Exception thrown while initializing neutron " .
                       " instance in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $self;
}

########################################################################
#
# GetPeerName --
#     Method to get the action key of peer tuples of this class
#
# Input:
#     None
#
# Results:
#     Name of action key of peer tuples of this class
#
# Side effects:
#     None
#
########################################################################

sub GetPeerName
{
   my $self = shift;
   return "neutronpeer";
}


########################################################################
#
# UpdateOperatingMode --
#     Method to update the operating mode of neutron
#
# Input:
#     keyName       :   action key name
#     payload       :   payload for REST API call that contains the actual
#                       operating mode
#
# Results:
#     SUCCESS in case of success
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub UpdateOperatingMode
{
   my $self = shift;
   my $keyName = shift;
   my $payload = shift;

   eval {

       $payload->{'operating_mode'} = $payload->{'edit_mode'};
       delete $payload->{'edit_mode'};

       my $resultObj = $self->change_operating_mode($payload);
       if ($resultObj->{status_code} !~ /^2/i) {
          $vdLogger->Error("Failed to update component. Got:" .
                       $resultObj->{status_code});
          VDSetLastError("EOPFAILED");
          return FAILURE;
       } else {
          $vdLogger->Info("Operating mode changed  successfully");
       }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while changing neutron " .
                       " operating mode in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# Backup --
#     Method to backup neutron config state to file
#
# Input:
#     keyName       :   action key name
#     payload       :   payload for REST API call that contains the file
#                       name for storing backup
#
# Results:
#     SUCCESS in case of success
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub Backup
{
   my $self = shift;
   my $keyName = shift;
   my $payload = shift;

   eval {

       my $resultObj = $self->backup($payload);
       if ($resultObj->{status_code} !~ /^2/i) {
          $vdLogger->Error("Failed to backup neutron state. Got:" .
                     $resultObj->{status_code});
          VDSetLastError("EOPFAILED");
          return FAILURE;
       } else {
          $vdLogger->Info("Neutron backup taken successfully");
       }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while taking neutron " .
                       " backup in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# Restore --
#     Method to restore neutron config state from file
#
# Input:
#     keyName       :   action key name
#     payload       :   payload for REST API call that contains the file
#                       name containing the backup that has to be restored
#
# Results:
#     SUCCESS in case of success
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub Restore
{
   my $self = shift;
   my $keyName = shift;
   my $payload = shift;

   eval {

       my $resultObj = $self->restore($payload);
       if ($resultObj->{status_code} !~ /^2/i) {
          $vdLogger->Error("Failed to restore neutron state from file. Got:" .
                       $resultObj->{status_code});
            VDSetLastError("EOPFAILED");
          return FAILURE;
       } else {
         $vdLogger->Info("Neutron state successfully recovered from file");
       }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while recovering neutron " .
                       " state in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
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
# Side e containing the backup that has to be restored#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj = CreateInlinePythonObject('neutron.Neutron',
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password},
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}
1;
