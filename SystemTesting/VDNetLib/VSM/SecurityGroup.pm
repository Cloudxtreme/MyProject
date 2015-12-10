########################################################################
# Copyright (C) 2014 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::SecurityGroup;
#
# This package allows to perform Grouping Object - Security Group operations
# on VSM
#

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

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
use Inline::Python qw(eval_python
                     py_bind_class
                     py_eval
                     py_study_package
                     py_call_function
                     py_call_method
                     py_is_tuple);

# Database of attribute mappings
use constant attributemapping => {
   'objecttype' => {
      'payload' => 'objecttypename',
      'attribute' => undef,
   },
   'vsmuuid' => {
      'payload' => 'vsmuuid',
      'attribute' => undef,
   },
   'name' => {
      'payload' => 'name',
      'attribute' => undef,
   },
   'sg_description' => {
      'payload' => 'description',
      'attribute' => undef,
   },
   'revision' => {
      'payload' => 'revision',
      'attribute' => undef,
   },
   'type' => {
      'payload' => 'type',
      'attribute' => undef,
   },
   'scope' => {
      'payload' => 'scope',
      'attribute' => undef,
   },
   'clienthandle' => {
      'payload' => 'clienthandle',
      'attribute' => undef,
   },
   'extendedattributes' => {
      'payload' => 'extendedattributes',
      'attribute' => undef,
   },
   'inheritanceallowed' => {
      'payload' => 'inheritanceallowed',
      'attribute' => undef,
   },
   'member' => {
      'payload' => 'member',
      'attribute' => undef,
   },
   'excludemember' => {
      'payload' => 'excludemember',
      'attribute' => undef,
   },
   'dynamicmemberdefinition' => {
      'payload' => 'dynamicmemberdefinition',
      'attribute' => undef,
   },
   'datacenter_id' => {
      'payload' => 'objectid',
      'attribute' => 'GetMORId',
   },
   'cluster_id' => {
      'payload' => 'objectid',
      'attribute' => 'GetClusterMORId',
   },
   'securitygroup_id' => {
      'payload' => 'objectid',
      'attribute' => 'id',
   },
   'vm_id' => {
      'payload' => 'objectid',
      'attribute' => 'GetVMMoID',
   },
   'vnic_id' => {
      'payload' => 'objectid',
      'attribute' => 'GetVnicUUID',
   },
   'dvpg_id' => {
      'payload' => 'objectid',
      'attribute' => 'id',
   },
   'grouping_object_id' => {
      'payload' => 'objectid',
      'attribute' => 'id'
   }

};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      vsm : VSM IP (Required)
#      id : id of any vsm component to be passed to python layer(future
#           purpose)
#
# Results:
#      An object of VDNetLib::VSM::SecurityGroup
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

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();

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
   my $inlinePyObj = CreateInlinePythonObject('security_group_bulk_config.SecurityGroupBulkConfig',
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


########################################################################
#
# CompareTranslationList--
#     API to read the translation list from security group
#
# Input:
#     userStatus: RUNNING/STOPPED
#
# Results:
#     SUCCESS in case of userStatus and serverStatus matches
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CompareTranslationList
{
   my $self           = shift;
   my $serverForm     = shift;
   my $params         = shift;
   my $result         = undef;
   my $resultForVerification = undef;
   my $inlinePyApplObj;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq FAILURE) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
      if ($params->{translation_entity} eq "ipaddress") {
         $inlinePyApplObj = CreateInlinePythonObject(
                             'vsm_security_group_translate_ipaddresses.SecurityGroupTranslateIPAddresses',
                             $inlinePyObj);
      } elsif ($params->{translation_entity} eq "macaddress") {
         $inlinePyApplObj = CreateInlinePythonObject(
                             'vsm_security_group_translate_macaddresses.SecurityGroupTranslateMACAddresses',
                             $inlinePyObj);
      } else {
         $vdLogger->Error("Invalid object passed for Translation, support only
                          for 'ipaddress' and 'macaddress'");
         return FAILURE;
      }
      $result = $inlinePyApplObj->read();
      $resultForVerification = $result->get_py_dict_from_object();
   };
   if ($@) {
      my $errorInfo = "Exception thrown while reading translation list" .
                       " in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $vdLogger->Debug("ServerData: " . Dumper($resultForVerification));
   $resultHash->{status}   = SUCCESS;
   $resultHash->{response} = $resultForVerification;
   return $resultHash;
}

1;
