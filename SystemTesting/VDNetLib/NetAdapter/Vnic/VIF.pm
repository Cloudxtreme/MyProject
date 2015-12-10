#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::NetAdapter::Vnic::VIF;
my $version = "1.0";

use strict;
use warnings;
use Data::Dumper;
use base qw(VDNetLib::NetAdapter::Vnic::Vnic);
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError
                                   VDGetLastError VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::NetAdapter::Vnic::Vnic;

########################################################################
#
# new -
#       This is the constructor module for PIF
#
# Input:
#       IP address of a control adapter (required)
#       Interface (ethx in linux, GUID in windows) (Required)
#
# Results:
#       An instance/object of NetAdapter class
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
   my $self = VDNetLib::NetAdapter::Vnic::Vnic->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::NetAdapter::Vnic::VIF".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.kvm.vif.vif_facade.VIFFacade';
   bless ($self, $class);
   return $self;
}


########################################################################
#
# GetInlineVirtualAdapter --
#     Method to get inline python object to manage to this adapter
#
# Input:
#     None
#
# Results:
#     reference to an object of TBD_vif.TBD_VIF
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $vmInlineObj = $self->{vmOpsObj}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{name},
                                              $vmInlineObj,
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object of $self->{_pyclass}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# GetInlineVirtualAdapter
#     Wrapper method for GetInlinePyObject, as legacy code calls it.
#
# Input:
#     None
#
# Results:
#     password in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVirtualAdapter
{
   my $self = shift;
   return $self->GetInlinePyObject();
}

########################################################################
#
# GetDriverVersion -
#       This method returns the driver version of the given adapter
#
# Input:
#       None
#
# Results:
#       Adapter/Driver version is returned
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetDriverVersion
{
   my $self = shift;
   my $version = $self->SUPER::GetDriverVersion();
   if (not defined $version || $version eq FAILURE) {
       # On RHEL KVM hosted VMs, ethtool/lspci do not return the driver version
       # and so hardcoding it here. (Related bugzilla #1386020)
       # https://bugzilla.redhat.com/show_bug.cgi?id=645646
       return 'virtio1.2';
   }
}
