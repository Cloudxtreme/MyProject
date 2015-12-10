###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::VC::Datacenter
#
#   This package allows to perform various operations on VC datacenter
#   and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::VC::Datacenter;

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
use base 'VDNetLib::Root::Root';
use VDNetLib::InlineJava::Folder::Datacenter;
use VDNetLib::InlineJava::Folder;

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::VC::Datacenter).
#
# Input:
#      vcObj	   - VC Object
#      datacenter  - Datacenter Name
#      folder	   - Folder Name
#      stafHelper  - STAFHelper Object
#
# Results:
#      An object of VDNetLib::VC::Datacenter package.
#
# Side effects:
#      None
#
###############################################################################

sub new {
   my $class = shift;
   my %args  = @_;
   my $self  = {};

   $self->{vcObj}	   = $args{vcObj};
   $self->{datacentername} = $args{datacenter};
   $self->{foldername}     = $args{folder};
   $self->{stafHelper}     = $args{stafHelper};
   $self->{parentObj} = $self->{vcObj};
   $self->{name} = $self->{datacentername};
   $self->{_pyIdName} = "name";
   $self->{_pyclass} = "vmware.vsphere.vc.datacenter.datacenter_facade.DatacenterFacade";
   bless( $self, $class );

   return $self;
}


###############################################################################
#
# AddHostsToDC --
#      This method adds specified hosts to the given datacenter
#
# Input:
#      hostObjArray - Reference to an array of Host Objects
#      $hostFolder  - absolute path of the location of DC Folder
#
# Results:
#      Returns "SUCCESS", if all the given hosts are added to datacenter
#                         successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddHostsToDC
{
   my $self        = shift;
   my $hostObjAray = shift; # mandatory
   my $hostFolder  = shift; # mandotory
   my $esx_root    = undef;
   my $esx_passwd  = undef;
   my $vcObj	   = $self->{vcObj};
   my $proxy       = $vcObj->{proxy};
   my @hostList;

   my $dcname      = $self->{datacentername};
   my $foldername  = $self->{foldername};

   foreach my $hostObj (@$hostObjAray) {
      my $hostIP = $hostObj->{hostIP};
      #
      # Check if the host is already in the list of hosts added to
      # the given datacenter.
      #
      my $i = grep{/^$hostIP$/} @hostList;
      if ($i != 0) {
         $vdLogger->Debug("$hostIP is already added to Datacenter: $dcname");
         next;
      }

      $esx_root = $hostObj->{userid};
      if (not defined $esx_root) {
         $esx_root = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_USER;
      }

      $esx_passwd = $hostObj->{sshPassword};
      if (not defined $esx_passwd) {
         $esx_passwd = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_PASSWD;
      }
      $vdLogger->Info("Adding host $hostIP into DC ($dcname).........");
      my $command = " addhost anchor ". $vcObj->{hostAnchor}.
                 " host ". $hostIP . " login " . $esx_root.
                 " password " . $esx_passwd . " hostfolder " . $hostFolder;
      my $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to add host($hostIP) to ".
                          "datacenter($dcname) using command $command" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Update the VC information in the host object
      $hostObj->UpdateVCObj($vcObj);
      $hostObj->UpdateCurrentVMAnchor($vcObj->{vmAnchor});

      push(@hostList, $hostIP);
   }

   return SUCCESS;
}


###############################################################################
#
# RemoveHostFromDC --
#      This method will remove hosts from DC
#
# Input:
#      hostObjs         - reference to array of hostObj
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveHostFromDC
{
   my $self     = shift;
   my @hostObjs = @_;

   my $vcObj    = $self->{vcObj};
   my $proxy    = $vcObj->{proxy};
   my $cmd;
   my $result;
   my $count = @hostObjs;
   if ($count < 1) {
      $vdLogger->Error("host object is null not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $hostObj (@hostObjs) {
      my $tmpip = $hostObj->{hostIP};
      $cmd = " HOSTREMOVE anchor ".$vcObj->{hostAnchor}." HOST ".$tmpip;
      $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to remove host($tmpip) from ".
                          "DC using command $cmd" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Info("Successfully removed host($tmpip) from DC..");

      # Remove the VC information in the host object

      # Without any argument undef will be updated in the vcObj
      $hostObj->UpdateVCObj();

      #
      # Without any argument undef will be sent and default host
      # anchor will get updated in the currentVMAnchor
      #
      $hostObj->UpdateCurrentVMAnchor();
   }
   return SUCCESS;
}


###############################################################################
#
# CreateCluster --
#      This method create clusters in Datacenter
#
# Input:
#     refToClusterArray: in below format
#          [
#            {
#              'host' => 'host.[1].x.[x]',
#              'clustername' => 'cluster1'
#            },
#            {
#              'clustername' => 'cluster2'
#            }
#          ]
#
# Results:
#
#      Returns reference to cluster objects, if success
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateCluster
{
   my $self = shift;
   my $refToClusterArray = shift;
   my $inlineDatacenter = $self->GetInlineDatacenterObj();
   my @clusterObjects;
   my $allowexisthost = 0;
   my $count = "1";

   foreach my $clusterSpec (@$refToClusterArray) {
      if (ref($clusterSpec) !~ /HASH/){
         $vdLogger->Error("Cluster spec is not in hash format");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $clusterName = $clusterSpec->{clustername} || $clusterSpec->{name};
      if (not defined $clusterName) {
         $clusterName = VDNetLib::Common::Utilities::GenerateNameWithRandomId("cluster", $count);
         $clusterSpec->{clustername} = $clusterName;
         $clusterSpec->{name} = $clusterName;
      }
      my $refToHostObjArray = $clusterSpec->{host};
      my $allowedexception = $clusterSpec->{allowedexception};
      $vdLogger->Debug("allowedexception is ".Dumper($allowedexception));
      if (defined @$allowedexception && @$allowedexception) {
         $allowexisthost = grep /hostalreadyexists/, @$allowedexception;
         $vdLogger->Debug("allowexisthost is $allowexisthost");
      }
      my $clusterMor = $inlineDatacenter->CreateCluster($clusterSpec);
      if (!$clusterMor) {
         $vdLogger->Error("Error while creating cluster $clusterName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("New Cluster ($clusterName) created.");
      my $clusterObj = VDNetLib::VC::Cluster->new(dcObj => $self,
                                             clusterName => $clusterName);
      if ($clusterObj eq FAILURE) {
         $vdLogger->Error("Failed to create Cluster object for ".
                          "cluster: $clusterName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (defined $refToHostObjArray) {
         $vdLogger->Debug("Adding hosts directly to the Cluster");
         my $forceAddHost = $clusterSpec->{forceaddhost};
         my $inlineFolderObj = $self->{vcObj}->GetInlineFolder();
         if ($clusterObj->AddHostsToCluster($inlineFolderObj, $refToHostObjArray,
                                 $forceAddHost,$allowexisthost) eq FAILURE) {
            $vdLogger->Error("Failed to add hosts into cluster: $clusterName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      push(@clusterObjects, $clusterObj);
      $count++;
   }

   return \@clusterObjects;
}


###############################################################################
#
# RemoveCluster --
#      This method Remove cluster from Datacenter
#
# Input:
#     arrayOfClusterObjects: reference to array of cluster objects
#
# Results:
#
#      Returns "SUCCESS", if all cluster removed successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveCluster
{
   my $self = shift;
   my $arrayOfClusterObjects = shift;

   foreach my $clusterObject (@$arrayOfClusterObjects) {
      my $clusterObjInline = $clusterObject->GetInlineClusterObj();
      if (!$clusterObjInline->DestroyCluster()){
         $vdLogger->Error("INLINE: DestroyCluster remove cluster failed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Deleted cluster:$clusterObject->{clusterName} from DC:" .
		      "$self->{datacentername}");
   }
   return SUCCESS;
}


###############################################################################
#
# DoesClusterExist --
#      This method check that cluster exists under datacenter
#
# Input:
#     clusterName : Name of cluster under this datacenter
# Results:
#      Returns 1, if cluster already exists to datacenter
#      Returns 0, in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub DoesClusterExist
{
   my $self = shift;
   my $cluster = shift;
   my $datacenter = $self->{datacentername};
   my $result = undef;
   if (not defined $cluster) {
      $vdLogger->Error("clustername name is not defined.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Checking for cluster existance");
   my $session = $self->{vcObj}->GetInlineVCSession();
   my $anchor  = $session->{anchor};
   my $inlineFolder = VDNetLib::InlineJava::Folder->new('anchor' => $anchor);
   $result = $inlineFolder->GetClusterMor($cluster,$datacenter);
   if ((not defined $result) || !$result) {
      $vdLogger->Debug("Cluster:($cluster) does not exists.");
      VDSetLastError("EINLINE");
      return 0;
   }
   return 1;
}


########################################################################
#
# ImportVDS --
#      This method imports VDS configuration.
#
# Input:
#      importType  : Type of Import (createEntityWithNewIdentifier or
#				     createEntityWithOriginalIdentifier)
# Results:
#      "SUCCESS", if import operation is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      Creates a new VDS/DVPG.
#
########################################################################

sub ImportVDS
{
   my $self	   = shift;
   my $importType  = shift;
   my $result;

   my $inlineDatacenter = $self->GetInlineDatacenterObj();

   $result = $inlineDatacenter->ImportVDSConfig($importType);
   if ((not defined $result) || !$result) {
      $vdLogger->Error("Failed to perform import VDS operation" .
                       " from DC: $self->{datacentername}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $vdsObj = VDNetLib::Switch::Switch->new(
					'switch'     => $result,
					'switchType' => "vdswitch",
					'datacenter' => $self->{datacentername},
					'vcObj'      => $self->{vcObj},
					'stafHelper' => $self->{stafHelper});

   if ($vdsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VDSwitch object for $result");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $vdsObj;
}


###############################################################################
#
# GetInlineDatacenterObj --
#      This method return datacenter inline object
#
# Input:
# Results:
#      Returns FAILURE, in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub GetInlineDatacenterObj
{
   my $self = shift;
   my $session = $self->{vcObj}->GetInlineVCSession();
   my $anchor  = $session->{anchor};
   my $inlineFolder = VDNetLib::InlineJava::Folder->new('anchor' => $anchor);
   my $inlineDatacenter = VDNetLib::InlineJava::Folder::Datacenter->new(
			folderObj => $inlineFolder,
			datacenterName => $self->{datacentername}
			);
   return $inlineDatacenter;
}


#############################################################################
#
# GetMORId--
#     Method to get the datacenter's Managed Object Ref ID.
#
# Input:
#
# Results:
#     datacenterMORId,
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self   = shift;
   my $datacenterMORId;

   my $inlinedatacenterObj = $self->GetInlineDatacenterObj();
   if (!($datacenterMORId = $inlinedatacenterObj->GetMORId())) {
      $vdLogger->Error("Failed to get the Managed Object ID for ".
	               "the datacenter: $self->{datacentername}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the datacenter:" .
	            $self->{datacentername} .  " is MORId:". $datacenterMORId);
   return $datacenterMORId;
}

1;
