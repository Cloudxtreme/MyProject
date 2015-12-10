###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::DVSManager;

#
# This class captures all common methods DistributedVirtualSwithManager
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


use constant DVSMGR  =>
     'com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager';

use constant INTERNALDVSMGR  =>
     'com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager';

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::DVSManager
#
# Input:
#     Named value parameters with following keys:
#     anchor      : Anchor to the VC on which given DVS exists (Required)
#
# Results:
#     An object of VDNetLib::InlineJava::DVSManager class if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;
   $self->{'anchor'}        = $options{'anchor'};

   if (not defined $self->{'anchor'}) {
      $vdLogger->Error("Anchor is not provided");
      return FALSE;
   }

   eval {
      $self->{'dvsMgrObj'} = CreateInlineObject(DVSMGR, $self->{'anchor'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating " .
                       "VDNetLib::InlineJava::DVSManager object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# UpdateOpaqueData--
#     Method to update opaque data on the DVS
#
# Input:
#     Named value parameter with following keys:
#     dvsManagerMor: DVS Manager Object
#     selectionSet: Selection Set
#     DVSOpaqueDataConfigSpec: populated with appropriate fields
#     isRunTime: a boolean
#
# Results:
#     Returns 1 if opaque data is updated
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpdateOpaqueData
{
   my $self = shift;
   my $selectionSet = shift;
   my $opaqueDataSpec = shift;
   my $isRuntime = shift;
   my $DVSMgr = $self->{'dvsMgrObj'};
   eval {
         $self->{internalDVSMgr} = CreateInlineObject(
                                     INTERNALDVSMGR, $self->{'anchor'});
	if ($self->GetDVSMgrMor() eq FALSE) {
           $vdLogger->Error("GetDVSMgrMor returned FALSE");
           return FALSE;
        }
   my $dvsMgrMor = $DVSMgr->getDvSwitchManager();


   return $self->{internalDVSMgr}->updateOpaqueData(
                                           $dvsMgrMor,
                                           $selectionSet,
                                           $opaqueDataSpec,
                                           $isRuntime);
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetDVSMgrMor--
#     Returns a reference to the new DVSSWITCHMANAGER CLASS
#
# Input:
#     None
#
# Results:
#     returns reference to DVSSWITCHMANAGER class
#     FALSE in case of exception
#
# Side effects:
#     None
#
########################################################################

sub GetDVSMgrMor
{
   my $self = shift;
   eval {
      if (defined $self->{dvsMgr} && $self->{dvsMgr}) {
         $self->{dvsMgrMor} = $self->{dvsMgr}->getDvSwitchManager();
      } else {
         $self->{dvsMgrMor} =  CreateInlineObject("com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager", $self->{'anchor'});
      }
      return TRUE;
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
}


########################################################################
#
# GetInternalDVSMgr--
#     Returns a reference to the new INTERNALDVSMGR CLASS
#
# Input:
#     None
#
# Results:
#     returns reference to INTERNALDVSMGR class
#     FALSE in case of exception
#
# Side effects:
#     None
#
########################################################################

sub GetInternalDVSMgr
{
   my $self = shift;
   eval {

         my $internalDVSMgr = CreateInlineObject(
                                     INTERNALDVSMGR, $self->{'anchor'});
        return $internalDVSMgr;
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
}


########################################################################
#
# ExportEntity--
#     Call exportEntity method to save the given config in the
#     SelectionSet
#
# Input:
#     dvsMgrMor - Reference DVS manager
#     selectionSet - Reference to arry of selection set that has
#                    the dvs or dvpg configuration to be saved
#
# Results:
#     returns the reference to saved configuration
#     FALSE in case of exception
#
# Side effects:
#     None
#
########################################################################

sub ExportEntity
{
   my $self = shift;
   my $dvsMgrMor = shift;
   my $selectionSet = shift;

   eval {
      if (not defined $dvsMgrMor) {
         return FALSE if (!($dvsMgrMor = $self->GetDVSMgrMor()));
      }
      return $self->{dvsMgr}->exportEntity($dvsMgrMor, $selectionSet);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

}


1;
