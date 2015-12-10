########################################################################
# Copyright (C) 2014 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::Gateway;
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

use constant attributemapping => {
   'name' => {
      'payload' => 'name',
      'attribute' => undef,
   },
   'version' => {
      'payload' => 'version',
      'attribute' => undef,
   },
   'resourcepool' => {
      'payload' => 'resourcePoolId',
      'attribute' => 'GetMORId',
   },
   'datacenter' => {
      'payload' => 'datacenterMoid',
      'attribute' => 'GetMORId',
   },
   'host' => {
      'payload' => 'hostId',
      'attribute' => 'GetMORId',
   },
   'portgroup' => {
      'payload' => 'portgroupId',
      'attribute' => 'GetMORId',
   },
   'type' => {
      'payload' => 'type',
      'attribute' => undef,
   },
   'primaryaddress' => {
      'payload' => 'primaryAddress',
      'attribute' => undef,
   },
   'subnetmask' => {
      'payload' => 'subnetMask',
      'attribute' => undef,
   },
   'username' => {
      'payload' => 'userName',
      'attribute' => undef,
   },
   'remote_access' => {
      'payload' => 'remoteAccess',
      'attribute' => undef,
   },
};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      IP : IP address of the VSM (Required)
#
# Results:
#      An object of VDNetLib::VSM::Gateway
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
   my %args = @_;

   my $endpoint_version = $args{endpoint_version} || "4.0";

   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('edge.Edge',
                                               $inlinePyVSMObj,
                                               $endpoint_version,
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
#     Method to process the given array of gateway edge spec
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
      $tempSpec->{version} = $spec->{version};
      if (defined $spec->{edge_features}) {
         $tempSpec->{features} = $spec->{edge_features};
      }
      $tempSpec->{datacentermoid} = $spec->{datacenter}->GetMORId();

      my $arrayOfAppliances;
      my $appliance;
      my $arrayOfAddressGroup;
      my $addressGroup;
      my $arrayOfVnic;
      my $vnic;

      if (defined $spec->{datastore}) {
         $appliance->{datastoreid} = $spec->{datastore}->GetMORId();
      } else {
         $spec->{datastoretype} = "shared" if not defined $spec->{datastoretype};
         if ($spec->{datastoretype} !~ /shared/i) {
           $vdLogger->Info("Local datastore chosen: $spec->{datastoretype}");
            # Find the datastore with max free space
           my $datastoreMORId;
           my $util = VDNetLib::Common::EsxUtils->new($vdLogger,
                                                      $spec->{host}{stafHelper});
           my $maxDatastore = $util->GetMaxVMFSPartition($spec->{host}->{hostIP});
            if (not defined $maxDatastore) {
               $vdLogger->Debug("Couldn't find the datastore with max free space");
               $appliance->{datastoreid} = $spec->{host}->GetDatastoreMORId($sharedDatastore);
            }
            $datastoreMORId = $spec->{host}->GetDatastoreMORId(
                                                      $maxDatastore);
            if ($datastoreMORId eq FAILURE) {
               $vdLogger->Debug("Failed to find datastore MOR id");
               $appliance->{datastoreid} = $spec->{host}->GetDatastoreMORId($sharedDatastore);
            }
            $useSharedDS = 0;
            $appliance->{datastoreid} = $datastoreMORId;
         } else {
            $vdLogger->Info("Shared datastore chosen");
            $appliance->{datastoreid} = $spec->{host}->GetDatastoreMORId($sharedDatastore);
         }
      }

      $appliance->{resourcepoolid} = $spec->{resourcepool}->GetResourcePoolMORID();
      $appliance->{hostid} = $spec->{host}->GetMORId();
      $vnic->{type} = "internal";
      $vnic->{portgroupid} = $spec->{'portgroup'}->GetMORId();
      $vnic->{"index"} = 0;
      $vnic->{name} = "mgmt";
      $vnic->{isconnected} = "True";
      $addressGroup->{primaryaddress} = $spec->{primaryaddress};
      $addressGroup->{subnetmask} = $spec->{subnetmask};
      push(@$arrayOfAddressGroup, $addressGroup);
      $vnic->{addressgroups} = \@$arrayOfAddressGroup;
      push(@$arrayOfVnic, $vnic);
      $tempSpec->{vnics} = \@$arrayOfVnic;

      push(@$arrayOfAppliances, $appliance);
      $tempSpec->{appliances}->{appliancesize} = "compact";
      $tempSpec->{appliances}->{appliance} = \@$arrayOfAppliances;

    #Adding Remote Access for Gateway EDGE creation
      my $cliSettings;
      $cliSettings->{username} = $spec->{username};
      $cliSettings->{password} = $spec->{password};
      $cliSettings->{remoteaccess} = $spec->{remote_access};
      $tempSpec->{clisettings}=$cliSettings;

      push(@newArrayOfSpec, $tempSpec);

   }
   return \@newArrayOfSpec;
}


########################################################################
#
# CreateVnic --
#     Method to create Vnics
#
# Input:
#     Reference to an array of hash
#
# Results:
#     Reference to an array of vNIC objects;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateVnic
{
   my $self = shift;
   my $arrayOfSpec = shift;
   my $componentClass = "VDNetLib::VSM::Gateway::Vnic";
   eval "require $componentClass";
   if ($@) {
      $vdLogger->Error("Failed to load $componentClass $@");
      VDSetLastError("EFAIL");
      return FAILURE;
  }
   my $templateObj = $componentClass->new(gateway => $self);
   my $newArrayOfSpec = $templateObj->ProcessSpec($arrayOfSpec);
   $vdLogger->Trace("Spec for vnic:" . Dumper($newArrayOfSpec));
   my $arrayOfPerlObjs = $self->CreateAndVerifyComponent($templateObj,
                                                         $newArrayOfSpec);
   # TODO: check for error after return class is checked-in in Py layer
   return $arrayOfPerlObjs;
}

########################################################################
#
# SetupVM-
#    Dummy method to setup Gateway VM
#
########################################################################

sub SetupVM
{
   $vdLogger->Debug("Skipping Gateway edge Setup");
   return SUCCESS;
}


########################################################################
#
# ExecuteEdgeCommand-
#    This subroutine will execute the Edge Command
#
# Input:
#     Edge Command
#     Edge schema key
#
# Results:
#     Result Hash containing the cli output response;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
#
########################################################################

sub ExecuteEdgeCommand
{
   my $self         = shift;
   my $edge_command = shift;
   my $edge_schema_key = shift;

   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my @serverData;
   my $result;
   my $edge_default_username = VDNetLib::Common::GlobalConfig::DEFAULT_EDGE_USERNAME;
   my $edge_default_password = VDNetLib::Common::GlobalConfig::DEFAULT_EDGE_PASSWORD;

   $vdLogger->Info("Executing Edge command: $edge_command");
   $vdLogger->Info("Edge schema key inside Execute Edge Command Subroutine: $edge_schema_key");

   my $inlinePyObj = $self->GetInlinePyObject();
   $result = $inlinePyObj->execute_edge_cli($edge_command,$edge_default_username,$edge_default_password,$edge_schema_key);
   if ($result eq 'FAILURE') {
      return $resultHash;
   }

   $resultHash->{response} = $result;

   $vdLogger->Debug("Result HASH : ". Dumper($resultHash));
   $vdLogger->Debug("ResultHASH -> Status : ". $resultHash->{'status'});
   $vdLogger->Debug("ResultHASH -> Response : ". $resultHash->{response});

   my @serverData = $resultHash->{response};

   $vdLogger->Info("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   $resultHash->{'status'}  = 'SUCCESS';
   return $resultHash;
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
