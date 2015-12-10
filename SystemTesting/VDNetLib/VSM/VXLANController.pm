#######################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::VXLANController;
#
# This package allows to perform various operations on an VXLAN controller
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
# For deploying min of 3 controllers size should be ~90GB
# TODO: Also we need to calculate the total size of all disks in the machine
# it might have 3 disks with 30 GB free space, controller deployment should
# not bail out in that case
use constant DATASTORE_MIN_SIZE_MB_PER_CONTR => 36160;

use constant attributemapping => {};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Contoller::VXLANControllerOperations).
#
# Input:
#      controllerIP : IP address of the controller.
#               (Required)
#
# Results:
#      An object of VDNetLib::Contoller::VXLANControllerOperations package.
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
   $self->{username} = undef;
   $self->{password} = undef;
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
   my $inlinePyObj = CreateInlinePythonObject('vxlan_controller.VXLANController',
                                               $inlinePyVSMObj,
                                             );
   $inlinePyObj->{id} = $self->{id};
   $inlinePyObj->{username} = $self->{username};
   $inlinePyObj->{password} = $self->{password};
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
#     Method to process the given array of VXLAN controller spec
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
   my @newArrayOfSpec;
   my $useSharedDS = 1;
   #
   # We need 30 GB space per controller thus we multiple the minimum
   # space with num of specs = num of controllers user wants to deploy
   #
   my $numControllers = scalar(@$arrayOfSpec);
   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      $tempSpec->{name} = $spec->{name};
      $tempSpec->{deploytype} = "small";
      $tempSpec->{firstnodeofcluster} = "true";
      $tempSpec->{hostid} = $spec->{host}->GetMORId();
      $tempSpec->{ippoolid} = $spec->{ippool}{id};
      $tempSpec->{password} = $spec->{password};
      if (not defined $tempSpec->{password}) {
         $tempSpec->{password} = VDNetLib::Common::GlobalConfig::DEFAULT_NSX_CONTROLLER_PASSWORD;
      }
      #
      # Store username and password will update
      # to python layer by GetInlinePyObject
      #
      $self->{password} = $tempSpec->{password};
      $self->{username} = $spec->{username};
      if (not defined $self->{username}) {
         $self->{username} = "admin";
      }
      if (defined $spec->{portgroup}) {
         my $portgroupObj = $spec->{portgroup};
         my $networkid = $portgroupObj->GetMORId();
         $tempSpec->{networkid} = $networkid;
         $vdLogger->Info("VXLAN controller VM connected to " .
                        "portgroup $portgroupObj->{name}");
      }
      # Check the datastore type
      $spec->{datastoretype} = "local" if not defined $spec->{datastoretype};
      if ($spec->{datastoretype} !~ /shared/i) {
         # Find the datastore with max free space
        my $util = VDNetLib::Common::EsxUtils->new($vdLogger,
                                                   $spec->{host}{stafHelper});
        my $maxDatastore = $util->GetMaxVMFSPartition($spec->{host}->{hostIP});
         if (not defined $maxDatastore) {
            $vdLogger->Debug("Couldn't find the datastore with max free space");
            goto SHARED_DS;
         }
         $tempSpec->{datastoreid} = $spec->{host}->GetDatastoreMORId(
                                                   $maxDatastore);
         if ($tempSpec->{datastoreid} eq FAILURE) {
            $vdLogger->Debug("Failed to find datastore MOR id");
            goto SHARED_DS;
         }
         # Check the amount of free space, it should be greater than 30GB
         # (30720MB) for deploying one controller
         my $size = $util->GetVMFSSpaceAvail(
                                              $spec->{host}->{hostIP},
                                              $maxDatastore);
         if (not defined $size) {
            $vdLogger->Debug("Failed to get datastore size");
            goto SHARED_DS;
         }
         if ($size < (DATASTORE_MIN_SIZE_MB_PER_CONTR * $numControllers)) {
            $vdLogger->Debug("Insufficient datastore size");
            goto SHARED_DS;
         }
         $useSharedDS = 0;
      }
      # This is the fallback option (to use shared datastore)
      SHARED_DS:
      if ($useSharedDS == 1) {
      $tempSpec->{datastoreid} = $spec->{host}->GetDatastoreMORId(
	                                        "vdnetSharedStorage");
         if ($tempSpec->{datastoreid} eq FAILURE) {
            $vdLogger->Error("Failed to find datastore MOR id");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      # replace resourcepool by cluster once resourcepool class is created
      $tempSpec->{resourcepoolid} = $spec->{resourcepool}->GetResourcePoolMORID();
      #$tempSpec->{networkid} = $spec->{cluster}->GetResourcePoolMORID();
      push(@newArrayOfSpec, $tempSpec);
   }
   return \@newArrayOfSpec;
}


########################################################################
#
# Setter --
#      newComponentObj need to store the obj or some value given by
#      user in the spec.
#      E.g. vxlancontroller needs to save the pointer to host obj
#      so that name of controller vm may be found in it.
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub Setter
{
   my $self = shift;
   my $spec = shift;
   $self->{hostObj} = $spec->{host};
   return SUCCESS;
}


########################################################################
#
# ListControllerVMs --
#     Method to list all VMs whose names start with 'NSX_Controller_'
#
# Input:
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub ListControllerVMs
{
   my $self = shift;
   my $prefixVmName = "NSX_Controller_";
   my $result = $self->{hostObj}->GetAllVMNames("Y");
   if ($result eq "FAILURE") {
      $vdLogger->Warn("Failed to get vm names from host: ".
                     $self->{hostObj}->{hostIP});
      return;
   }
   foreach my $vmName (@$result) {
       if ($vmName =~ m/^$prefixVmName(.*)/) {
          $vdLogger->Warn("Found controller VM $vmName on host ".
                           $self->{hostObj}->{hostIP});
       }
   }
}

1;
