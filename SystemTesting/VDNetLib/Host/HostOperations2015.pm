##########################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
################################################################################
package VDNetLib::Host::HostOperations2015;

# File description:
#
# This package allows an ESX/ESXi host with version 6 to overide the
# operations of its parent class HostOperations. An object of this
# class refers to one ESX/ESXi host.
#

# Used to enforce coding standards
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";

# Inheriting from VDNetLib::Host::HostOperations package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Host::HostOperations);
use VDNetLib::Common::Utilities;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::EsxUtils;
use VDNetLib::Common::SshHost;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::ParseFile;
use VDNetLib::Common::FindBuildInfo;
use VDNetLib::InlineJava::Host;
use VDNetLib::InlineJava::SessionManager;
use VDNetLib::Switch::OpenVswitch::OpenVswitch;
use VDNetLib::TestData::TestConstants;
use VDNetLib::Switch::Port::Cisco;
use Data::Dumper;
use VDNetLib::TestData::TestConstants;

use constant attributemapping => {};

#########################################################################
#
#  GetPassthruNICPCIID --
#      Given the physical Nic intefaces ike vmnic4 or vmnic5 in passthrough
#      mode,this method returns the pci ID of the interface.
#
# Input:
#      physical Nic interface like 'vmnic4'
#
# Results:
#      Returns PCI ID of the interface given,
#      if there was no error executing the command.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetPassthruNICPCIID
{

   my $self   = shift;
   my $host   = shift;
   my $nic    = shift;

   my $command;
   my $pciid;

   if (not defined $nic) {
      $vdLogger->Error("Physical Nic is not provided to obtain PCIID");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = "vmkchdev -l|grep passthru\.$nic";
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                       $command);
   # check for failure of the command

   if ($result->{rc} != 0) {
       $vdLogger->Error("$nic is not in passthrough mode");
       return FAILURE;
     }

   if ($result->{stdout} eq ""){
      $vdLogger->Error("No STAF result is returned for :$nic");
      VDSetLastError("EINVALID");
      return FAILURE;
    }

   my @pcivalue=split(' ',$result->{stdout});
   #The PCI ID should be like this 0000:06:00.0
   if ($pcivalue[0] =~ /[a-f0-9]{4}:[a-f0-9]{2}:[a-f0-9]{2}\.\d/) {
      $pciid = $pcivalue[0];
   } else {
      $vdLogger->Error("Not a valid PCI value :$pcivalue[0]");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   return $pciid;
}

#########################################################################
#
#  ConvertBDFtoPCIId --
#      Given the BDF ID
#      returns the PCI ID for configuring passthrough device
#
# Input:
#      bdfInHex - BDF ID like 0000:44:1d.4
#
# Results:
#      Returns the PCI ID if there was no error executing the command
#      Returns FAILURE, in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub ConvertBDFtoPCIId
{
   my $self =shift;
   my $bdfInHex  = shift;
   my $pciid = FAILURE;

   if (not defined $bdfInHex) {
      $vdLogger->Error("BDF isn't provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($bdfInHex =~ /([0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}.\d)$/) {
      $vdLogger->Debug("Set the PCI ID to $1");
      $pciid = $1;
   }
   return $pciid;
}

#########################################################################
#
#  ConvertPCIIdToDecimal --
#      Given the PCI ID in hex format
#      returns the PCI ID in decimal format
#
# Input:
#      pciIdInHex - PCI ID like 0000:44:1d.4
#
# Results:
#      Returns the PCI ID in decimal
#      Returns FAILURE, in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub ConvertPCIIdToDecimal
{
   my $self =shift;
   my $pciIdInHex  = shift;
   my $pciIdInDecimal = FAILURE;

   if (not defined $pciIdInHex) {
      $vdLogger->Error("PCI Id isn't provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("The PCI ID is $pciIdInHex");
   if ($pciIdInHex =~ /([0-9a-f]{4}):([0-9a-f]{2}):([0-9a-f]{2}).(\d)$/) {
      $pciIdInDecimal = sprintf("%05d:%03d:%02d.%d",hex($1),hex($2),hex($3),hex($4));
      $vdLogger->Debug("Convert the PCI ID to $pciIdInDecimal");
   }
   return $pciIdInDecimal;
}

1;
