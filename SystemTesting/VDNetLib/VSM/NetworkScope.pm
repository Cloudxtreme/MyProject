########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::NetworkScope;

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
#     VDNetLib::VSM:NetworkScope
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM:NetworkScope
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
   $self->{type} = "vsm";
   bless $self, $class;
   $self->GetInlinePyObject();
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
   my $inlinePyObj = CreateInlinePythonObject('vdn_scope.VDNScope',
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
#     Method to process the given array of network scope
#     and convert them to a form required by Inline Python API
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
      my @allClustersInThisSpec;
      if (defined $spec->{clusters}) {
         @allClustersInThisSpec = @{$spec->{clusters}};
         delete $spec->{clusters};
         my @clusterArray;
         foreach my $cluster (@allClustersInThisSpec) {
            my $clusterMORID = $cluster->GetClusterMORId();
            my $clusterSpec;
            $clusterSpec->{cluster}->{objectId} = $clusterMORID;
            push(@clusterArray, $clusterSpec);
         }
         $spec->{clusters}{cluster} = \@clusterArray;
      }
      push(@newArrayOfSpec, $spec);
   }
   return \@newArrayOfSpec;
}


########################################################################
#
# ExecuteAction --
#     Method to execute any action on transportzone
#
# Input:
#     transportzoneaction - expand/shrink......
#     clusters to expand or shrink to
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ExecuteAction
{
   my $self            = shift;
   my %args            = @_;
   my $action          = $args{transportzoneaction};
   my $arrayOfClusters = $args{clusters};
   my $newSpec ;

   # Use ProcessSpec to convert everything
   if (defined $arrayOfClusters) {
      my $spec->{clusters} = $arrayOfClusters;
      my @arrayOfSpec;
      push(@arrayOfSpec, $spec);
      my $newArrayOfSpec = $self->ProcessSpec(\@arrayOfSpec);
      $newSpec = pop(@$newArrayOfSpec);
   }

   $newSpec->{objectid} = $self->{id};
   $self->execute_action($action, $newSpec);
}


########################################################################
#
# CreateVirtualWire --
#     Method to create VXLAN virtual wire, use this method to create the
#      virtual wire with attribute 'vxlanId' supported .
#
# Input:
#     componentName: name of the component to be created
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     return 'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub CreateVirtualWire
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $arrayOfPerlObjs;
   my @arrayOfVirtualWireObjs = ();

   $arrayOfPerlObjs = $self->CreateAndVerifyComponent($componentName,
                                                        $arrayOfSpec);

   if ((not defined $arrayOfPerlObjs) or ($arrayOfPerlObjs eq "FAILURE")) {
      $vdLogger->Error("Failed to create virtual wire");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $elementCount = @$arrayOfSpec;
   $vdLogger->Debug("virtual wire count is ".$elementCount);
   for (my $i =0; $i < $elementCount; $i++) {
        my $vWireinlineObj = $arrayOfPerlObjs->[$i]->read();
        my $vxlanid = $vWireinlineObj->{vdnId};
        $arrayOfPerlObjs->[$i]->{vxlanId} = $vxlanid;
   }
   return $arrayOfPerlObjs;
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
