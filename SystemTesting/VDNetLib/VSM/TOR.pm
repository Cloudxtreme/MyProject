########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::TOR;
#
# This package allows to perform various operations on TOR
#

use base qw(VDNetLib::InlinePython::AbstractInlinePythonClass);
use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::EsxUtils;

use constant attributemapping => {
   'tor_switch_name' => {
      'payload' => 'name',
      'attribute' => 'switchid'
   },
   'certificate' => {
      'payload' => 'certificate',
      'attribute' => 'get_certificate'
   },
   'bfd_enabled' => {
      'payload' => 'bfdenabled',
      'attribute' => undef
   },
};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      controllerIP : IP address of the VSM (Required)
#
# Results:
#      An object of VDNetLib::VSM::TOR
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{vsm} = $args{vsm};
   $self->{type} = "vsm";
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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('tor.TOR',
                                               $inlinePyVSMObj,
                                             );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


######################################################################
#
# get_tor_switch --
#     Method to get tor switch
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                       'tor_switch_name'  => undef,
#                       'description'  => undef,
#                       'faults'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_tor_switch
{
   my $self           = shift;
   my $serverForm     = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyTorObj = CreateInlinePythonObject('tor.TOR', $inlinePyObj);
       $inlinePyTorObj->{id} = $self->{id};
       # get tor instances from python
       $result = $inlinePyTorObj->get_tor_switch();
   };
   if ($@) {
      $errorInfo = "Exception thrown while get TOR switch in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'tor_switch_name' => $entry->{'switchname'},
                         'description'  => $entry->{'description'},
                         'faults'  => $entry->{'faults'},
                        };
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'table'    => \@serverData};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# get_tor_switch_port --
#     Method to get tor ports for one tor switch
#
# Input:
#     switch_name: tor switch name, like 1-switch-153
#     serverForm : hash generate from userData, like
#                   {
#                       'tor_port_name'  => undef,
#                       'description'  => undef,
#                       'faults'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_tor_switch_port
{
   my $self           = shift;
   my $switchName     = shift;
   my $serverForm     = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyTorObj = CreateInlinePythonObject('tor.TOR', $inlinePyObj);
       $inlinePyTorObj->{id} = $self->{id};
       # get tor instances from python
       $result = $inlinePyTorObj->get_tor_switch_port($switchName);
   };
   if ($@) {
      $errorInfo = "Exception thrown while get TOR switch ports in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'tor_port_name' => $entry->{'portname'},
                         'description'  => $entry->{'description'},
                         'faults'  => $entry->{'faults'},
                        };
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'table'    => \@serverData};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}
1;
