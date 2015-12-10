###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::VC::ResourcePool
#
#   This package allows to perform various operations on VC ResourcePool
#   and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::VC::ResourcePool;

use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Net::IP;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::Folder::Datacenter::Cluster;
use VDNetLib::InlineJava::Folder::Datacenter::Cluster::ResourcePool;

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::VC::ResourcPool).
#
# Input:
#      dcObj	   - Datacenter Object
#      cluster     - Cluster Name
#      stafHelper  - STAFHelper Object
#
# Results:
#      An object of VDNetLib::VC::ResourcePool package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self  = {};

   $self->{clusterObj}	   = $args{clusterObj};
   $self->{resourcePoolName}    = $args{resourcePoolName};

   bless($self, $class);

   return $self;
}


###############################################################################
#
# GetInlineResourcePoolObj --
#      Method to return inline object
#
# Input:
#    None
#
# Results:
#      An object of
#      VDNetLib::InlineJava::Folder::Datacenter::Cluster::ResourcePool.
#
# Side effects:
#      None
#
###############################################################################

sub GetInlineResourcePoolObj
{
   my $self = shift;
   my $inlineCluster = $self->{'clusterObj'}->GetInlineClusterObj();
   my $inlineResourcePool
    = VDNetLib::InlineJava::Folder::Datacenter::Cluster::ResourcePool->new(
			clusterObj => $inlineCluster,
			resourcePoolName => $self->{resourcePoolName},
			);
   return $inlineResourcePool
}


#############################################################################
#
# GetMORId--
#     Method to get the resourcepool's Managed Object Ref ID.
#
# Input:
#
# Results:
#     resourcepoolMORId,
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self   = shift;
   my $resourcepoolMORId;

   my $inlineRPObj = $self->GetInlineResourcePoolObj();
   if (!($resourcepoolMORId = $inlineRPObj->GetMORId())) {
      $vdLogger->Error("Failed to get the Managed Object ID for ".
	               "the resourcepool: $self->{resourcePoolName}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the resourcepool:" .
	            $self->{resourcePoolName} .  " is MORId:". $resourcepoolMORId);
   return $resourcepoolMORId;
}


1;
