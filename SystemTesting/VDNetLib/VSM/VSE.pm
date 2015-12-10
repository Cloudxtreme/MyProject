########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::VSE;
#
# This package allows to perform various operations on VSE
#

use base qw(VDNetLib::InlinePython::AbstractInlinePythonClass VDNetLib::VM::ESXSTAFVMOperations);
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

use constant attributemapping => {};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      controllerIP : IP address of the VSM (Required)
#
# Results:
#      An object of VDNetLib::VSM::VSE
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
   my $inlinePyObj = CreateInlinePythonObject('edge.Edge',
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


########################################################################
#
# ProcessSpec --
#     Method to process the given array of VSE/edge spec
#     and convert them a form required Inline Python API
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;
   my $useSharedDS = 1;
   my @newArrayOfSpec;
   my $sharedDatastore = VDNetLib::Common::GlobalConfig::DEFAULT_SHARED_MOUNTPOINT;

   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      $tempSpec->{name} = $spec->{name};
      $tempSpec->{datacentermoid} = $spec->{datacenter}->GetMORId();
      $tempSpec->{type} = $spec->{type} || "distributedRouter";
      # replace resourcepool by cluster once resourcepool class is created
      my $arrayOfAppliances;
      my $appliance;
      my $arrayOfAddressGroup;
      my $addressGroup;

      $appliance->{resourcepoolid} = $spec->{resourcepool}->GetResourcePoolMORID();
      $appliance->{hostid} = $spec->{host}->GetMORId();

      if (defined $spec->{datastore}) {
         $appliance->{datastoreid} = $spec->{datastore}->GetMORId();
      } else {
         # Check the datastore type
         my $datastoreMORId;
         $spec->{datastoretype} = "local" if not defined $spec->{datastoretype};
         if ($spec->{datastoretype} !~ /shared/i) {
           $vdLogger->Info("Local datastore chosen: $spec->{datastoretype}");
            # Find the datastore with max free space
           my $util = VDNetLib::Common::EsxUtils->new($vdLogger,
                                                      $spec->{host}{stafHelper});
           my $maxDatastore = $util->GetMaxVMFSPartition($spec->{host}->{hostIP});
            if (not defined $maxDatastore) {
               $vdLogger->Debug("Couldn't find the datastore with max free space");
               goto SHARED_DS;
            }
            $datastoreMORId = $spec->{host}->GetDatastoreMORId(
                                                      $maxDatastore);
            if ($datastoreMORId eq FAILURE) {
               $vdLogger->Debug("Failed to find datastore MOR id");
               goto SHARED_DS;
            }
            $useSharedDS = 0;
            $appliance->{datastoreid} = $datastoreMORId;
         } else {
            $vdLogger->Info("Shared datastore chosen");
            $appliance->{datastoreid} = $spec->{host}->GetDatastoreMORId($sharedDatastore);
         }
         # This is the fallback option (to use shared datastore)
         SHARED_DS:
         if ($useSharedDS == 1) {
            $datastoreMORId = $spec->{host}->GetDatastoreMORId(
                                                   "vdnetSharedStorage");
            if ($datastoreMORId eq FAILURE) {
               $vdLogger->Error("Failed to find datastore MOR id");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      }

      $addressGroup->{primaryaddress} = $spec->{primaryaddress};
      $addressGroup->{subnetmask} = $spec->{subnetmask};
      push(@$arrayOfAppliances, $appliance);
      push(@$arrayOfAddressGroup, $addressGroup);
      my $addressGroups = \@$arrayOfAddressGroup;
      $tempSpec->{appliances}->{appliancesize} = "compact";
      $tempSpec->{appliances}->{appliance} = \@$arrayOfAppliances;
      $tempSpec->{mgmtinterface}->{connectedtoid} = $spec->{portgroup}->GetId();
      if (defined $spec->{localegressenabled}) {
         $vdLogger->Debug("Find localegressenabled for UDLR: " . $spec->{localegressenabled});
         $tempSpec->{localegressenabled} = $spec->{localegressenabled};
      }
      if ($tempSpec->{mgmtinterface}->{connectedtoid} eq FAILURE) {
          vdLogger->Error("Failed to find mgmtinterface id");
          vdsetlasterror("EFAIL");
          return FAILURE;
      }
      $tempSpec->{mgmtinterface}->{addressgroups} = \@$arrayOfAddressGroup;
      push(@newArrayOfSpec, $tempSpec);
   }
   return \@newArrayOfSpec;
}


########################################################################
#
# CreateLIF --
#     Method to create LIFs
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of LIF objects;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateLIF
{
   my $self = shift;
   my $arrayOfSpec = shift;
   my $componentClass = "VDNetLib::VSM::VSE::LIF";
   eval "require $componentClass";
   if ($@) {
      $vdLogger->Error("Failed to load $componentClass $@");
      VDSetLastError("EFAIL");
      return FAILURE;
  }
   my $templateObj = $componentClass->new(vse => $self);
   my $newArrayOfSpec = $templateObj->ProcessSpec($arrayOfSpec);
   $vdLogger->Trace("Spec for lif:" . Dumper($newArrayOfSpec));
   my $arrayOfPerlObjs = $self->CreateAndVerifyComponent($templateObj,
                                                         $newArrayOfSpec);
   # TODO: check for error after return class is checked-in in Py layer
   return $arrayOfPerlObjs;
}

########################################################################
#
# SetupVM-
#    Dummy method to setup VSE VM
#
########################################################################

sub SetupVM
{
   $vdLogger->Debug("Skipping VSE Setup");
   return SUCCESS;
}


########################################################################
#
# Upgrade --
#      Method for upgrading VSE
#
# Input:
#      profile: value of this param is update
#
# Results:
#      Returns "SUCCESS", in case of SUCCESS
#      Returns "FAILURE", in case of FAILURE
#
# Side effects:
#      None
#
########################################################################

sub Upgrade
{
   my $self         = shift;
   my $profile      = shift;

   my $result;
   $vdLogger->Info("VSE upgrade starting now");
   eval {

       my $inlinePyObj = $self->GetInlinePyObject();
       $result = $inlinePyObj->upgrade();
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while upgrading " .
                       " vse in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to upgrade vse");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("vse upgraded successfully");
   }
   return SUCCESS;

}


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
   return "vsm";
}

1;
