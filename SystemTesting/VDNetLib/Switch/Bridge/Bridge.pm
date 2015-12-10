#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Switch::Bridge::Bridge;
my $version = "1.0";

use strict;
use warnings;
use Data::Dumper;
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use vars qw /@ISA/;
@ISA = qw(VDNetLib::NetAdapter::Vnic::Vnic);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError
                                   VDGetLastError VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger);

########################################################################
#
# new -
#       This is the constructor module for Bridge
#
# Input:
#       IP address of a control adapter (required)
#       Interface (ethx in linux, GUID in windows) (Required)
#
# Results:
#       An instance/object of Bridge class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   $options{vmOpsObj} = $options{hostObj};
   my $self = VDNetLib::NetAdapter::Vnic::Vnic->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::Switch::Bridge::Bridge".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{hostObj} = $options{hostObj};
   bless ($self, $class);
   $self->{_pyIdName} = 'name';
   $self->{_pyclass} = 'vmware.kvm.ovs.bridge.bridge_facade.BridgeFacade';
   $self->SetControlIP($options{controlIP});
   $self->SetInterface($options{name});
   if (not defined $self->{interface}) {
      $vdLogger->Error("Failed to create VDNetLib::Switch::Bridge::Bridge".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

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
   my $hostInlineObj = $self->{hostObj}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $hostInlineObj,
                                              $self->{interface},
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object of $self->{_pyclass}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}
