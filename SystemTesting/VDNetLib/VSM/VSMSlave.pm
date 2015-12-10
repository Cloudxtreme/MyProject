########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::VSMSlave;
#
# This package allows to perform Cluster Nodes relation operations on Neutron
#

use base qw (VDNetLib::InlinePython::AbstractInlinePythonClass VDNetLib::Root::GlobalObject);

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

# Database of attribute mappings

use constant attributemapping => {
   'ipaddress' => {
      'payload' => 'nsxmanagerip',
      'attribute' => 'ip'
   },
   'username' => {
      'payload' => 'nsxmanagerusername',
      'attribute' => 'user'
   },
   'password' => {
      'payload' => 'nsxmanagerpassword',
      'attribute' => 'password'
   },
   'cert_thumbprint' => {
      'payload' => 'certificatethumbprint',
      'attribute' => "GetCertThumbprint",
   },
   'isPrimary' => {
      'payload' => 'isprimary',
      'attribute' => "isPrimary",
   },
};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      neutron : Neutron node (Required)
#
# Results:
#      An object of VDNetLib::Neutron::ClusterNodes
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
   $self->{type}     = "vsm";
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
   my $inlinePyObj = CreateInlinePythonObject('vsm_register.VSMRegister',
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
# GetKeepChildren --
#     Method returns true if this nodes children need to be retained once
#     it is removed from a cluster
#
# Input:
#     None
#
# Results:
#     boolean
#
# Side effects:
#     None
#
########################################################################

sub GetKeepChildren
{
   my $self = shift;
   return VDNetLib::Common::GlobalConfig::TRUE;
}

1;
