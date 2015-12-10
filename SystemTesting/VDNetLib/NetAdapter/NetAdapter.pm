#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::NetAdapter::NetAdapter;
#
# The NetAdapter Class defines an network adapter on a machine, be it
# on a host or a virtual machine.
# This package is a Parent class for all different adapter type packages.
#

my $version = "1.0";

use FindBin;
use strict;
use warnings;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/VIX/";
use Data::Dumper;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Utilities;
use VDNetLib::Host::HostOperations;
use VDNetLib::NetAdapter::Vnic::Vnic;
use VDNetLib::NetAdapter::Vmnic::Vmnic;
use VDNetLib::NetAdapter::Vmknic::Vmknic;
use base 'VDNetLib::Root::Root';
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);


########################################################################
#
# new -
#       This is the constructor module for NetAdapterClass
#
# Input:
#       A named parameter (hash) with following keys:
#       controlIP : IP address of a control adapter (required)
#       interface : Interface name (ethx in linux, GUID in windows) (Required)
#       intType   : Interface type that is to be worked upon- vmnic/vmknic/vnic
#                  (optional, default is "vnic")
#       pgName    : portgroup name (Required if intType is "vmknic")
#       hostObj   : reference to object of VDNetLib::Host::HostOperations
#                   (optional)
#       switch    : Type of switch to which vnic is attached, this could be
#                   either vdswitch or vswitch (optional)
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
   my %args = @_;
   my $self;


   $self = {
      'interface'  => $args{interface},
      'controlIP'  => $args{controlIP},
      'name'       => $args{name},
      'macAddress' => $args{macAddress},
      #
      # Storing the current MAC address into the originalMAC key in case the
      # MAC is changed later on
      #
      'originalMAC' => $args{macAddress},
      'intType'    => $args{intType},
      'deviceId'   => $args{deviceId},
      'hostObj'    => $args{hostObj},
      'switchObj'  => $args{switchObj},
      'switch'     => $args{switch} || $args{switchObj}{switch},
      'switchType' => $args{switchType} || $args{switchObj}{switchType},
      'netstackObj'=> $args{netstackObj},
      'pgObj'      => $args{pgObj},
      'pgName'     => $args{pgName},
      'vmOpsObj'   => $args{vmOpsObj},
   };

   my $pgObj = $self->{pgObj};

   $self->{pgName} = (defined $self->{pgName}) ? $self->{pgName} :
                     $pgObj->{'pgName'};

   $self->{intType} = (not defined $self->{intType}) ? "vnic" :
                      $self->{intType};

   # Initializing variables to store objects of vmnic, vmknic and vnic
   my $vmnicObj = undef;
   my $vmknicObj = undef;
   my $vnicObj = undef;
   # Add a physical switch object, will be inintialized in vmnic sub-class
   $self->{pswitchObj} = undef;
   # encapsulate device ID in windows with ^, since STAF throws error when
   # the curly braces in the device id are used
   if ((defined $self->{'interface'}) && ($self->{'interface'} =~ "{")) {
      $self->{'interface'} = "^" . $self->{'interface'} . "^";
   }

   #
   # NOTE: Checking for intType - if it is NOT passed by the user, the
   # framework behaves in the existing manner as before
   #
   if ((not defined $self->{'controlIP'}) &&
      (not defined $self->{'interface'})) {
         $vdLogger->Error("Insufficient parameters to create NetAdapter object");
         VDSetLastError("ENOTDEF");
         return FAILURE;
   }

   if ($self->{'intType'} =~ /vmknic/i || $self->{'intType'} =~ /vmnic/i) {
      if (not defined $self->{hostObj}) {
         $vdLogger->Error("hostObj not passed in new() of NetAdapter class");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $childClass = $class; # default to this (Parent) class
   if ($self->{'intType'} =~ /vnic|pci/i) { # pci and vnic currently use same
                                            # class
      $childClass = "VDNetLib::NetAdapter::Vnic::Vnic";
      my %options;
      $vnicObj = VDNetLib::NetAdapter::Vnic::Vnic->new(interface => $self->{interface},
                                                       controlIP => $self->{controlIP},
                                                       intType   => $self->{intType},
                                                       vmOpsObj  => $self->{vmOpsObj});
      if ($vnicObj eq FAILURE) {
         $vdLogger->Error("Failed to create VDNetLib::Vnic::Vnic object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self = $vnicObj; # replacing the class variable with child class
   } elsif ($self->{'intType'} =~ /vmknic/i) {
      $childClass = "VDNetLib::NetAdapter::Vmknic::Vmknic";

      $vmknicObj = VDNetLib::NetAdapter::Vmknic::Vmknic->new(
                                           controlIP => $self->{'controlIP'},
                                           pgName   => $self->{'pgName'},
                                           deviceId => $self->{'deviceId'},
                                           hostObj => $self->{'hostObj'},
                                           switchObj => $self->{switchObj},
                                           netstackObj => $self->{netstackObj});
      if ($vmknicObj eq FAILURE) {
         $vdLogger->Error("Failed to create VDNetLib::Vmknic::Vmknic object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self = $vmknicObj; # updating the class variable
   } elsif ($self->{'intType'} =~ /vmnic/i) {
      $childClass = "VDNetLib::NetAdapter::Vmnic::Vmnic";
      $vmnicObj = VDNetLib::NetAdapter::Vmnic::Vmnic->new(
                                           controlIP => $self->{'controlIP'},
                                           interface => $self->{'interface'},
                                           hostObj => $self->{'hostObj'});
      if ($vmnicObj eq FAILURE) {
         $vdLogger->Error("Failed to create VDNetLib::Vmnic::Vmnic object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self = $vmnicObj; # updating class variable
   } else {
      $vdLogger->Error("Invalid adapter type \"$self->{'intType'}\" provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $self->{originalMAC} = $self->{macAddress};

   # Combining attibutes of both parent and child class
   foreach my $key (keys %args) {
      $self->{$key} = $args{$key} if not $self->{$key};
   }

   bless ($self,$childClass);

   return $self;
}


########################################################################
#
# CheckIPValidity --
#        Checks whether the given address has valid IP format and each octet is
#        within the range. This is just a utility function currently placed in
#        this package. This sub-routine is not part of the methods that can be
#        used on a NetAdapter object
#
# Input:
#        Address in IP format (xxx.xxx.xxx.xxx)
#
# Results:
#        "SUCCESS", if the given address has correct format and range
#        "FAILURE", if the given address has invalid format or range
#
# Side effects:
#        None
#
########################################################################

sub CheckIPValidity
{
   my $address = shift;

   if (not defined $address) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($address =~ /^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/) {
      if ($1 > 255 || $2 > 255 || $3 > 255 || $3 > 255 || $4 > 255) {
         $vdLogger->Error("Address out of range: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid address: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetInterface--
#     Method to get adapter interface name
#
# Input:
#     None
#
# Results:
#     interface name
#
# Side effects:
#     None
#
########################################################################

sub GetInterface
{
   my $self = shift;
   if ($self->{'intType'} eq "vmknic") {
      return $self->{deviceId};
   } else {
      return $self->{interface};
   }
}


################################################################################
#
# ConfigureRoute -
#  Add/Delete/Update route for vmknic. Returns SUCCESS if it is successful.
#  TODO: Implement Update route
#
# Input -
#  operation   - add/delete/update. Update not implemented yet.
#
# Results -
#  Returns return value of method which is called
#  Returns FAILURE if operation is not supported
#
# Side effects -
#  None
#
################################################################################

sub ConfigureRoute
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{route}; # add, delete
   if ($operation =~ /add/i) {
      return $self->AddRoute(%args);
   } elsif ($operation =~ /delete/i) {
      return $self->DeleteRoute(%args);
   }
   $vdLogger->Error("Unknown route operation:$operation defined in".
                    Dumper(%args));
   VDSetLastError("ENOTDEF");
   return FAILURE;
}



1;
