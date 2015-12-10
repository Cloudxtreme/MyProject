########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VDNCluster;

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

use constant attributemapping => {};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM:VDNCluster
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM:VDNCluster
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{vsm} = $args{vsm};
   $self->{vccluster} = $args{cluster};
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
   my $inlinePyObj = CreateInlinePythonObject('network_fabric.NetworkFabric',
                                               $inlinePyVSMObj,
                                             );
   # Using MOR id of cluster as id for vdn cluster object
   if (defined $self->{vccluster}) {
      $inlinePyObj->{id} = $self->{vccluster}->GetClusterMORId();
   } else {
      $inlinePyObj->{id} = $self->{id};
   }
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

   foreach my $spec (@$arrayOfSpec) {
      my $tempSpec;
      $tempSpec->{featureid} = "com.vmware.vshield.vsm.vxlan";
      my $arrayOfResourceConfig;
      my $switchMOR = undef;
      if (defined $spec->{switch}){
         my $switchMappingSpec;
         $switchMOR = $spec->{switch}{switchObj}->GetMORId();
         $switchMappingSpec->{resourceid} = $switchMOR;
         $switchMappingSpec->{configspecclass} = "VDSContext";
         $switchMappingSpec->{configspec}{switch}{objectid} = $switchMOR;
         $switchMappingSpec->{configspec}{mtu} = $spec->{mtu};
         $switchMappingSpec->{configspec}{teaming} = $spec->{teaming};
         push(@$arrayOfResourceConfig, $switchMappingSpec);
      }
      if (defined $self->{vccluster}){
         $spec->{cluster} = $self->{vccluster};
      }
      if (defined $spec->{cluster}){
         my $clusterMappingSpec;
         $clusterMappingSpec->{resourceid} = $spec->{cluster}->GetClusterMORId();
         if (defined $spec->{switch}){
            $clusterMappingSpec->{configspecclass} = "ClusterMappingSpec";
            $clusterMappingSpec->{configspec}{switch}{objectid} = $switchMOR;
            $clusterMappingSpec->{configspec}{vlanid} = $spec->{vlan};
            $clusterMappingSpec->{configspec}{vmkniccount} = $spec->{vmkniccount};
            $clusterMappingSpec->{configspec}{ippoolid} = $spec->{ippool}{id};
         }
         push(@$arrayOfResourceConfig, $clusterMappingSpec);
      }
      $tempSpec->{resourceconfig} = $arrayOfResourceConfig;
      push(@newArrayOfSpec, $tempSpec);
   }

   return \@newArrayOfSpec;
}


########################################################################
#
# Setter --
#      newComponentObj need to store the obj or some value given by
#      user in the spec.
#      E.g. vdncluster needs to save the pointer to VC's cluster obj
#      so that update calls and delete calls of vdncluster can
#      call GetClusterMORId on the VC's cluster obj. Thus we pass
#      the spec to setter API of that obj and allow it to set whatever it wants
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
   $self->{vccluster} = $spec->{cluster};
   return SUCCESS;
}


########################################################################
#
# ConfigureVXLAN--
#     Can be used to configure and unconfiure vxlan in a cluster.
#     A Create call is used for configure most of the time. This is
#     doing unconfigure only as of now.
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVXLAN
{
   my $self      = shift;
   my %args      = @_;
   my $spec      = \%args;
   my @arrayOfSpec;
   if ($spec->{vxlan} =~ /unconfigure/i) {
      push(@arrayOfSpec, $spec);
      my $processedSpec = $self->ProcessSpec(\@arrayOfSpec);
      my @arrayOfPerlObjs;
      push(@arrayOfPerlObjs, $self);
      return $self->DeleteComponent(\@arrayOfPerlObjs, $processedSpec);
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# Upgrade--
#     This method is used to upgrade vibs on the hosts of a particular
#     VDNCluster. An Update call is used to install the new vibs.
#
# Input:
#     cluster   :   cluster obj of the cluster that is to be upgraded
#
# Results:
#     SUCCESS in case of success
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub Upgrade
{
   my $self         = shift;
   my $cluster      = shift;

   my $payload->{cluster} = $cluster;

   my @arrayOfSpec;
   push(@arrayOfSpec, $payload);
   my @arrayOfPerlObjs;
   push(@arrayOfPerlObjs, $self);
   my $result = $self->UpdateComponent(@arrayOfSpec);
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to upgrade vibs on hosts in vdn cluster");
       VDSetLastError("EOPFAILED");
       return FAILURE;
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
