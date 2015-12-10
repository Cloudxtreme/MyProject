########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::GlobalSecurityGroup;
#
# This package allows to perform Grouping Object - Security Group operations
# on VSM
#

use base qw(VDNetLib::VSM::SecurityGroup VDNetLib::Root::GlobalObject);

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
#      An object of VDNetLib::VSM::GlobalSecurityGroup
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
   my $inlinePyObj = CreateInlinePythonObject(
                        'security_group_bulk_config.SecurityGroupBulkConfig',
                        $inlinePyVSMObj,
                        'universal'
                                              );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}

1;
