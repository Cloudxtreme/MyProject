###############################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::SessionManager;

#
# This class captures all common methods to configure or get information
# about a session. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with VC/ESX Host.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;


########################################################################
#
# new--
#     Constructor for this class VDNetLib::InlineJava::SessionManager
#
# Input:
#     vcAddress   : VC ip address (Required)
#     userid      : VC user name (Required)
#     password    : password to access VC (Required)
#     sdkPort     : port to connect to VC (Optional)
#
# Results:
#     An object of VDNetLib::InlineJava::SessionManager class,
#        if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my $address   = shift;
   my $userid    = shift;
   my $password  = shift;
   my $sdkPort   = shift || "443";

   if ((not defined $address) || (not defined $userid) ||
      (not defined $password)) {
      $vdLogger->Error("VC/Host address and/or access details not provided");
      return FALSE;
   }

   my $self;

   my ($anchor, $sessionMgr);
   eval {
      $anchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                   $address, $sdkPort);
      $sessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
                                       $anchor);
      $sessionMgr->login($anchor, $userid, $password);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create SessionManager object for VC $address");
      return FALSE;
   }

   $self->{'address'}   = $address;
   $self->{'userid'}    = $userid;
   $self->{'password'}  = $password;
   $self->{'anchor'}    = $anchor;
   $self->{'sessionManager'} = $sessionMgr;
   bless($self, $class);
   return $self;
}


########################################################################
#
# LoginVC--
#     This routine login VC.
#
# Input:
#     None
#
# Results:
#     TRUE will be returned if login is succceeded.
#     FALSE will be returned in case of any error
#
# Side effects:
#     None
#
########################################################################

sub LoginVC
{
   my $self = shift;
   my $userid     = $self->{'userid'};
   my $password   = $self->{'password'};
   my $anchor     = $self->{'anchor'};
   my $vcaddr     = $self->{'address'};
   my $sessionMgr = $self->{'sessionManager'};

   eval {
      if (!($sessionMgr->isLoggedIn())) {
         $vdLogger->Info("Login VC $vcaddr......");
         $sessionMgr->login($anchor, $userid, $password);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while login VC");
      return FALSE;
   }
   return TRUE;
}

########################################################################
#
# GetUUID--
#     Get VC UUID.
#
# Input:
#     None
#
# Results:
#     Returns VC UUID
#
# Side effects:
#     None
#
########################################################################

sub GetUUID
{
    my $self = shift;
    my $anchor = $self->{'anchor'};
    my $instanceUUID;
    eval {
        $instanceUUID = $anchor->getSC()->getAbout()->getInstanceUuid();
    };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while getting instance UUID");
      return FALSE;
   }

   return $instanceUUID;
}


########################################################################
#
# RestartVpxdServices --
#     Restart the vpxd services on VC
#
# Input:
#     None
#
# Results:
#     TRUE if successfully restart vc vpxd services
#     FALSE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub RestartVpxdServices
{
    my $self = shift;
    my $anchor = $self->{'anchor'};
    eval {
       my $vpxServices = CreateInlineObject(
                           "com.vmware.vcqa.util.services.VpxServices",
                           $anchor);
       $vpxServices->restart();
       if (!$self->{'sessionManager'}->isLoggedIn()) {
          $vdLogger->Info("User is no longer logged in");
       } else {
          $vdLogger->Error("User is still logged in after reboot vc");
          VDSetLastError(VDGetLastError());
          return FALSE;
       }
       $self->LoginVC();
    };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while restart vc vpx services");
      return FALSE;
   }

   return TRUE;
}


#############################################################################
#
# AddLicenseKey --
#     Add license key to VC for any product or feature
#
# Input:
#     license key
#
# Results:
#     TRUE, if the licensekey is successfully added in VC inventory
#     FALSE, in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub AddLicenseKey
{
   my $self  = shift;
   my %args  = @_;
   my $key   = $args{licensekey};
   my $anchor= $self->{'anchor'};

   my $ret = FALSE;
   eval {
      my $licenseManager= CreateInlineObject(
                           "com.vmware.vcqa.vim.LicenseManager",
                           $anchor);
      $ret = $licenseManager->addLicense($key, undef);
   };

  if ($@) {
     InlineExceptionHandler($@);
     $vdLogger->Error("Exception thrown while adding license to vc");
     return FALSE;
  }

  return $ret;
}


#############################################################################
#
# AssignLicenseToEntity--
#     Assign license key to feature/entity
#
# Input:
#     license key
#     feature/entity
#
# Results:
#     TRUE, if entity is assigned the license key
#     FALSE, in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub AssignLicenseToEntity
{
   my $self  = shift;
   my %args  = @_;
   my $key   = $args{licensekey};
   my $entity = $args{entity};
   my $anchor = $self->{'anchor'};
   my $ret;
   eval {
      my $licenseManager= CreateInlineObject( "com.vmware.vcqa.vim.LicenseManager",
                                              $anchor);
      my $licenseAssignmentManager = $licenseManager->getLicenseAssignmentManager();
      $ret = $licenseAssignmentManager->updateAssignedLicense($entity->GetMORId(),
                                                              $key,
                                                              undef);
   };

  if ($@) {
     InlineExceptionHandler($@);
     $vdLogger->Error("Exception thrown while registering entity");
     return FALSE;
  }

  return $ret;
}


########################################################################
#
# GetThumbprint--
#     Get VC thumbprint.
#
# Input:
#     None
#
# Results:
#     Returns VC thumbprint
#
# Side effects:
#     None
#
########################################################################

sub GetThumbprint
{
   my $self = shift;
   my $anchor = $self->{'anchor'};
   my $userid = $self->{'userid'};
   my $password = $self->{'password'};
   my $thumbprint;
   eval {
      my $xvcProvisioningHelper= CreateInlineObject( "com.vmware.vcqa.vim.xvcprovisioning.XvcProvisioningHelper",
                                             $anchor,$anchor);
      my $serviceLocator = $xvcProvisioningHelper->getServiceLocator($userid, $password);
      $thumbprint = $serviceLocator->getSslThumbprint();
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while getting thumbprint");
      return FALSE;
   }
   return $thumbprint;
}

1;

