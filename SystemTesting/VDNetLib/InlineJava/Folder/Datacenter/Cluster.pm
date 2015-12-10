###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Folder::Datacenter::Cluster;

#
# This class captures all common methods to configure or get information
# from a Cluster. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with Cluster.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;


########################################################################
#
# new--
#     Constructor for this class VDNetLib::InlineJava::Cluster
#
# Input:
#     Named value parameters with following keys:
#     anchor      : connection anchor  (Mandtory)
#
# Results:
#     An object of VDNetLib::InlineJava::Cluster class if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;
   $self->{'datacenterObj'}  = $options{'datacenterObj'};
   $self->{'clusterName'}  = $options{'clusterName'};
   $self->{'anchor'}  = $self->{'datacenterObj'}{'anchor'};

   if (not defined $self->{'anchor'}) {
      $vdLogger->Error("Connect anchor not provided as parameter");
      return FALSE;
   }

   eval {
      $self->{'clusterObj'} = CreateInlineObject(
                              "com.vmware.vcqa.vim.ClusterComputeResource",
                              $self->{'anchor'} );
      $self->{'clusterHelper'} = CreateInlineObject(
                              "com.vmware.vcqa.vim.ClusterHelper",
                              $self->{'anchor'} );
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::Cluster object");
      return FALSE;
   }

   my $folderObj = $self->{'datacenterObj'}->{'folderObj'};
   $self->{'clusterMor'} = $folderObj->GetClusterMor($self->{'clusterName'},
				$self->{'datacenterObj'}{'datacenterName'});
   if (!$self->{'clusterMor'}){
      $vdLogger->Error("Cluster $self->{'clusterName'} does not exists in" .
		       " Datacenter $self->{'datacenterObj'}{'datacenterName'}");
      return FALSE;
   }
   bless($self, $class);
   return $self;
}


########################################################################
#
# SetDRS--
#     Method to Enable/Disable DRS in a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     enable       : Boolean 1, enable drs
#                    Boolean 0, disable drs (Mandtory)
#
# Results:
#     TRUE, if DRS enabled and clusterspec reconfigured successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetDRS
{
   my $self = shift;
   my %options = @_;
   my $enable        = $options{"enable"};
   my $compResMor    = $self->{'clusterMor'};

   if ((not defined $compResMor) ||
       (not defined $enable)) {
      $vdLogger->Error("One or more of clusterObj ,compResMor and " .
                       "enable are missing.");
      return FALSE;
   }

   my $setDrsRes = FALSE;
   eval {
      $setDrsRes = $self->{'clusterObj'}->setDRS($compResMor,
                                                 $enable );
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in SetDRS.");
      return FALSE;
   }

   return $setDrsRes;
}


########################################################################
#
# SetDAS--
#     Method to Enable/Disable DAS in a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     enable      :  Boolean 1 to enable das
#                    Boolean 0 to disable das   (Mandtory)
#     admissionControl : Boolean 1, enable admission control
#                        Boolean 0, disable admission control
#                                                    (Optional)
#     failoverLevel : Failover level                 (Optional)
#     isolationResponse  : Pass "none" for default isolation response,
#                          Pass poweroff or shutdown otherwise. (Optional)
#     waitHAConf    : Boolean 1, wait for configuring/unconfiguring HA
#                     finished on all hosts in the cluster
#                     Boolean 0, return directly (Optional)
#
# Results:
#     TRUE, if DAS enabled and clusterspec reconfigured successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetDAS
{
   my $self = shift;
   my %options = @_;

   my $enable             = $options{"enable"};
   my $admissionControl   = $options{"admissionControl"};
   my $failoverLevel      = $options{"failoverLevel"};
   my $isolationResponse  = $options{"isolationResponse"};
   my $waitHAConf         = $options{"waitHAConf"};
   my $compResMor         = $self->{'clusterMor'};

   if ((not defined $compResMor) || (not defined $enable)) {
      $vdLogger->Error("One or more of compResMor, enable, " .
                       "are missing.");
      return FALSE;
   }

   my $setDasRes = FALSE;
   eval {
      if (defined $isolationResponse) {
	 if (not defined $waitHAConf) {
	    $vdLogger->Error("waitHAConf should be defined.");
	    return FALSE;
	 }
         $setDasRes = $self->{'clusterObj'}->setDAS($compResMor,
                                                 $enable,
                                                 $admissionControl,
                                                 $failoverLevel,
                                                 $isolationResponse,
                                                 $waitHAConf);
     } elsif (defined $admissionControl) {
	 if (not defined $failoverLevel) {
	    $vdLogger->Error("failoverLevel should be defined.");
	    return FALSE;
	 }
	 if (defined $waitHAConf) {
         $setDasRes = $self->{'clusterObj'}->setDAS($compResMor,
                                                 $enable,
                                                 $admissionControl,
                                                 $failoverLevel,
						 $waitHAConf);
	 } else {
         $setDasRes = $self->{'clusterObj'}->setDAS($compResMor,
                                                 $enable,
                                                 $admissionControl,
                                                 $failoverLevel);
	 }
     } else {
         $setDasRes = $self->{'clusterObj'}->setDAS($compResMor,
                                                 $enable);
     }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in SetDAS.");
      return FALSE;
   }

   return $setDasRes;
}


########################################################################
#
# MoveHostIntoCluster--
#     Method to move a host in a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostObj     :  Inline Host Object    (Mandtory)
#     resourcePoolMor  :  Existing resource pool mor in the destination
#			  cluster (Optional)
#
# Results:
#     TRUE, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MoveHostIntoCluster
{
   my $self = shift;
   my %options = @_;
   my $hostObj		  = $options{"hostObj"};
   my $resourcePoolMor    = $options{"resourcePoolMor"};
   my $compResMor         = $self->{'clusterMor'};
   my $hostMor		  = $hostObj->{'hostMOR'};

   my $result;
   eval {
      $result = $self->{clusterObj}->moveHostInto($compResMor,$hostMor,
						  $resourcePoolMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in moveHostInto.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# AddHostToCluster--
#     Method to add a new host into a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostObj     :  Inline Host Object    (Mandatory)
#     compResMor  :  Existing compute resource mor for the cluster (Mandatory)
#     resourcePoolMor  :  Existing resource pool mor in the destination
#			  cluster (Optional)
#     FolderObj   :  Inline Folder Object  (Mandatory)
#     forceAddHost:  flag to enable forcefull adding of host into Cluster (Optional)
#
# Results:
#     hostMOR, returns host Managed Reference Object(MOR) if successfull;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub AddHostToCluster
{
   my $self = shift;
   my %options = @_;
   my $hostObj = $options{"hostObj"};
   my $resourcePoolMor = $options{"resourcePoolMor"};
   my $allowexisthost = $options{"allowexisthost"};
   my $compResMor = $self->{'clusterMor'};
   my $folderObj = $options{"folderObj"};
   my $forceAddHost = $options{'forceAddHost'};
   my $result;
   my $hostObjInline = $hostObj->GetInlineHostObject();
   my $find = 0;
   my $ipAddress;

   if ($allowexisthost && $self->HasHost($hostObj)) {
      return TRUE;
   }
   my $hostConnectSpecObj = $folderObj->CreateHostConnectSpec(
                             hostName => $hostObjInline->{'host'},
                             userName => $hostObjInline->{'user'},
                             password => $hostObjInline->{'password'},
                             forceAddHost => $forceAddHost);
   eval {
      $result = $self->{clusterObj}->addHost($compResMor,$hostConnectSpecObj,"true",
							$resourcePoolMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in addHost.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# AddHostsToCluster--
#     Method to add new hosts into a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostsObj     :  Inline Hosts Object    (Mandatory)
#     compResMor  :  Existing compute resource mor for the cluster (Mandatory)
#     resourcePoolMor  :  Existing resource pool mor in the destination
#			  cluster (Optional)
#     FolderObj   :  Inline Folder Object  (Mandatory)
#     forceAddHost:  flag to enable forcefull adding of host into Cluster (Optional)
#
# Results:
#     TRUE, if all hosts are added into the cluster successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub AddHostsToCluster
{
   my $self = shift;
   my %options = @_;
   my $hostsObj = $options{"hostsObj"};
   my $resourcePoolMor = $options{"resourcePoolMor"};
   my $allowexisthost = $options{"allowexisthost"};
   my $compResMor = $self->{'clusterMor'};
   my $folderObj = $options{"folderObj"};
   my $forceAddHost = $options{'forceAddHost'};
   my $result = TRUE;

   my $hostsObjArray = [];
   foreach my $hostObj (@$hostsObj) {
       if (!($allowexisthost && $self->HasHost($hostObj))) {
          push @$hostsObjArray, $hostObj;
       }
   }
   my $hostTaskHash = {};
   eval {
      # There is no restriction on max # of async jobs, host limitation
      # needs to be added outside of this API as of now.
      my $tasksArray = [];
      foreach my $hostObj (@$hostsObjArray) {
          my $hostObjInline = $hostObj->GetInlineHostObject();
          my $hostConnectSpecObj = $folderObj->CreateHostConnectSpec(
                                 hostName => $hostObjInline->{'host'},
                                 userName => $hostObjInline->{'user'},
                                 password => $hostObjInline->{'password'},
                                 forceAddHost => $forceAddHost);
          my $taskMor = $self->{clusterObj}->asyncAddHost(
                                 $compResMor,
                                 $hostConnectSpecObj,
                                 "true",
                                 $resourcePoolMor);
          push @$tasksArray, $taskMor;
          $hostTaskHash->{$taskMor} = $hostObj;
      }
      my $mTasks = CreateInlineObject("com.vmware.vcqa.vim.Task",
                                              $self->{'anchor'});
      foreach my $activeTaskMor (@$tasksArray) {
            my $activeHostObj = $hostTaskHash->{$activeTaskMor};
            my $host = $activeHostObj->GetInlineHostObject->{host};
            if (($mTasks->monitorTask($activeTaskMor) == FALSE) &&
                ($self->HasHost($activeHostObj) == FALSE)) {
               #
               # When adding many hosts into a cluster at the same time,
               # taskInfo of some taskMors may be cleared if the tasks have
               # completed for some time, which would cause monitorTask()
               # to fail, so check if the host has added into the cluster to
               # avoid reporting a fake failure.
               #
               $result = FALSE;
               $vdLogger->Error("Failed to add host ($host) into cluster.");
            } else {
               $vdLogger->Info("Succeeded to add host ($host) into cluster.");
            }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in addHosts. $@");
      return FALSE;
   }

   return $result;
}


########################################################################
#
# MoveHostFromClusterToSAHost--
#     Method to move a host from a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostObj     :  Host object inline    (Mandtory)
#
# Results:
#     TRUE, if successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MoveHostFromClusterToSAHost
{
   my $self = shift;
   my %options = @_;
   my $hostObj		  = $options{"hostObj"};
   my $hostMor		  = $hostObj->{'hostMOR'};
   my $compResMor         = $self->{'clusterMor'};

   my $folderObjInline = $self->{datacenterObj}{folderObj};
   my $dcMor = $folderObjInline->GetDataCenterMor(
				$self->{datacenterObj}{datacenterName});
   if (!$dcMor) {
      $vdLogger->Error("Failure to get MOR of datacenter");
      VDSetLastError("EINLINE");
      return FALSE;
   }
   my $hostFolderMor = $folderObjInline->GetHostFolderMor($dcMor);
   if (!$hostFolderMor) {
      $vdLogger->Error("Failure to get MOR of host folder");
      VDSetLastError("EINLINE");
      return FALSE;
   }

   my $result;
   eval {
      $result = $self->{clusterObj}->moveHostFromClusterToSAHost($compResMor,
				                   $hostMor, $hostFolderMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in moveHostFromClusterToSAHost.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# DestroyCluster--
#     Method to remove cluster
#
# Input:
#
# Results:
#     TRUE, if successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DestroyCluster
{
   my $self = shift;

   my $compResMor = $self->{'clusterMor'};

   my $result;
   eval {
      $result = $self->{clusterObj}->destroy($compResMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in DestroyCluster.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# GetDASStatus--
#     Method to return DAS status on cluster
#
# Input:
#
# Results:
#     TRUE, if DAS enabled;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDASStatus
{
   my $self = shift;
   my $result = 0;
   eval {
      $result = $self->{clusterObj}->isDASEnabled($self->{'clusterMor'});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in GetDASStatus.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# GetDRSStatus--
#     Method to return DAS status on cluster
#
# Input:
#
# Results:
#     TRUE, if DAS enabled;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDRSStatus
{
   my $self = shift;
   my $result = 0;
   eval {
      $result = $self->{clusterObj}->isDRSEnabled($self->{'clusterMor'});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in GetDRSStatus.");
      return FALSE;
   }
   return $result;
}

#############################################################################
#
# GetClusterMORID--
#     Method to get Cluster Managed Object ID (MOID) from Cluster's
#     display/registered name
#
# Input:
#     clusterName : Cluster display/registered Name as in the inventory
#
# Results:
#	   ClusterMORID, of the Cluster found with the vmName
#	   0, if Cluster is not found or in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetClusterMORID
{
   my $self        = shift;
   my $clusterName = shift;
   my $clusterMOR;
   my $clusterMORID;
   eval {
      $clusterMOR = $self->{clusterObj}->getClusterByName($clusterName);
      $clusterMORID = $clusterMOR->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the Cluster MOID " .
                       "of $self->{clusterName} ");
      return FALSE;
   }
   return $clusterMORID;
}


#############################################################################
#
# GetResourcePoolMOR--
#     Method to get ResourcePool Managed Object of resource pool.
#
# Input:
#     resourcepooName : ResourcePool display/registered Name as in the inventory
#
# Results:
#	ResourcePoolMOR, of the ResourcePool found with .
#	0, if ResourcePool is not found or in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetResourcePoolMOR
{
   my $self   = shift;
   my $resourcePool = shift;
   my $clusterName = $self->{clusterName};
   my $clusterMOR;
   my $resourcePoolMOR;

   eval {
      $clusterMOR = $self->{clusterObj}->getClusterByName($clusterName);
      $resourcePoolMOR = $self->{clusterObj}->getResourcePool($clusterMOR,
                                                              $resourcePool);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the ResourcePool MOR" .
                       "for $resourcePool");
      return FALSE;
   }
   return $resourcePoolMOR;
}


#############################################################################
#
# GetClusterRootResourcePool--
#     Method to get ResourcePool Managed Object of cluster.
#
# Input:
#     clusterName : ResourcePool display/registered Name as in the inventory
#
# Results:
#	ResourcePoolMOR, of the ResourcePool found with the clusterName
#	0, if ResourcePool is not found or in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetClusterRootResourcePool
{
   my $self   = shift;
   my $clusterName = $self->{clusterName};
   my $clusterMOR;
   my $resourcePoolMOR;

   eval {
      $clusterMOR = $self->{clusterObj}->getClusterByName($clusterName);
      $resourcePoolMOR = $self->{clusterObj}->getResourcePool($clusterMOR);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the root ResourcePool " .
                       "of $self->{clusterName} ");
      return FALSE;
   }
   return $resourcePoolMOR;
}


#############################################################################
#
# GetResourcePoolMORID--
#     Method to get ResourcePool Managed Object ID (MOID) from Cluster name
#
# Input:
#     clusterName : ResourcePool display/registered Name as in the inventory
#
# Results:
#	ResourcePoolMORID, of the ResourcePool found with the clusterName
#	0, if ResourcePool is not found or in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetResourcePoolMORID
{
   my $self   = shift;
   my $clusterName = shift;
   my $clusterMOR;
   my $clusterMORID;
   my $allResourcePools;
   my $resgroup = undef;

   eval {
      $clusterMOR = $self->{clusterObj}->getClusterByName($clusterName);
      $allResourcePools = $self->{clusterObj}->getAllResourcePools($clusterMOR);
      for (my $i = 0; $i < $allResourcePools->size(); $i++) {
         my $key = $allResourcePools->get($i);
         $resgroup = $allResourcePools->get($i)->getValue();
         if ($resgroup =~ /resgroup/i) {
            $vdLogger->Debug("Cluster:$clusterName has resource pool:".
                            "$resgroup ");
            last;
         }
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the ResourcePoolMOID " .
                       "of $self->{clusterName} ");
      return FALSE;
   }
   return $resgroup;

}


########################################################################
#
# RemoveHostFromCluster--
#     Method to remove a host from a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostObj     :  Inline Host Object    (Mandtory)
#
# Results:
#     TRUE, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RemoveHostFromCluster
{
   my $self = shift;
   my %options = @_;
   my $hostObj = $options{"hostObj"};
   my $hostMor = $hostObj->{'hostMOR'};
   my $result;

   if (not defined $hostObj) {
      $vdLogger->Error("Paremeter Inline host Object is missing");
      return FALSE;
   }

   eval {
      $result = $hostObj->{'hostSystem'}->disconnectHost($hostMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in disconnectHost.");
      return FALSE;
   }
   return $result;
}

########################################################################
#
# CreateResourcePool--
#     Method to create a resource pool.
#
# Input:
#   Named value parameter with following keys:
#   name :  Name of the resource pool    (Mandtory)
#   cpuAllocation : parameter to specify the cpu allocation for RP
#   memoryAllocation: paramter to specify the memory allocation for RP.
#
# Results:
#     TRUE, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateResourcePool
{
   my $self = shift;
   my %options = @_;
   my $poolName = $options{'name'};
   my $cpuShares = $options{'cpu'}->{'shares'};
   my $memoryShares = $options{'memory'}->{'shares'};
   my $cpuReservation = $options{'cpu'}->{'reservation'};
   my $memoryReservation = $options{'memory'}->{'reservation'};
   my $memoryLimit = $options{'memory'}->{'limit'};
   my $cpuLimit = $options{'cpu'}->{'limit'};
   my $clusterName = $self->{clusterName};
   my $resSpec;
   my $resourcePoolObj;
   my $resourcePoolSpecObj;
   my $result;


   # shares hashmap
   LoadInlineJavaClass("com.vmware.vc.SharesLevel");
   my %shares = (
      HIGH => $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::HIGH,
      LOW => $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::LOW,
      NORMAL => $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::NORMAL,
   );
   # get the cluster resource pool id which would be parent pool.
   my $parentPool = $self->GetClusterRootResourcePool();

   eval {
      $resourcePoolObj = CreateInlineObject(
                         "com.vmware.vcqa.vim.ResourcePool",
                         $self->{'anchor'});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create ResourcePool inline object");
      return FALSE;
   }

   #
   # create resource pool passing the parent mor
   # which in this case is cluster mor.
   #
   eval {
      $resSpec = $resourcePoolObj->createDefaultResourceConfigSpec();
      if(defined $cpuShares) {
         my $cpuLevel;
         my $cpuSharesInfo = CreateInlineObject("com.vmware.vc.SharesInfo");
         if ($cpuShares =~ m/normal|high|low/i) {
            $cpuLevel = $shares{$cpuShares};
            $cpuSharesInfo->setLevel($cpuLevel);
         } else {
            #
            # the user has specified the value in this case
            # set the shares type as custom and set the value as well.
            #
            $cpuLevel = $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::CUSTOM;
            $cpuSharesInfo->setLevel($cpuLevel);
            $cpuSharesInfo->setShares($cpuShares);
         }
         $resSpec->getCpuAllocation()->setShares($cpuSharesInfo);
      }
      if (defined $memoryShares) {
         my $memSharesInfo = CreateInlineObject("com.vmware.vc.SharesInfo");
         my $memLevel;
         if ($memoryShares =~ m/high|low|normal/i) {
            $memLevel = $shares{$memoryShares};
            $memSharesInfo->setLevel($memLevel);
         } else {
            $memLevel = $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::CUSTOM;
            $memSharesInfo->setLevel($memLevel);
            $memSharesInfo->setShares($memoryShares);
         }
         $resSpec->getMemoryAllocation()->setShares($memSharesInfo);
      }
      if(defined $cpuReservation) {
         $resSpec->getCpuAllocation()->setReservation($cpuReservation);
      }
      if (defined $memoryReservation) {
         $resSpec->getMemoryAllocation()->setReservation($memoryReservation);
      }
      if(defined $cpuLimit) {
         $resSpec->getCpuAllocation()->setLimit($cpuLimit);
      }
      if (defined $memoryLimit) {
         $resSpec->getMemoryAllocation()->setLimit($memoryLimit);
      }
      $result = $resourcePoolObj->createResourcePool($parentPool, $poolName,
                                                     $resSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create ResourcePool");
      return FALSE;
   }
   return $result;
}



#######################################################################
#
# RemoveResourcePool--
#     Method to remove a resource pool.
#
# Input:
#   None
#
# Results:
#     TRUE, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
##########################################################################

sub RemoveResourcePool
{
   my $self = shift;
   my $poolName = shift;
   my $resourcePoolObj;;
   my $result;

   eval {
      $resourcePoolObj = CreateInlineObject(
                         "com.vmware.vcqa.vim.ResourcePool",
                         $self->{'anchor'});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create ResourcePool inline object");
      return FALSE;
   }



   my $parentPool = $self->GetClusterRootResourcePool();
   eval {
      $resourcePoolObj->destroyChildren($parentPool);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to remove ResourcePool $poolName");
      return FALSE;
   }
   return TRUE;
}

########################################################################
#
# HasHost--
#     Method to check whether the host is in a cluster compute resource
#
# Input:
#     Named value parameter with following keys:
#     hostObj     :  Host Object    (Mandatory)
#
# Results:
#     TRUE, if the host is in the cluster;
#     FALSE, in case of any error or the host isn't in the cluster;
#
# Side effects:
#     None
#
########################################################################

sub HasHost
{
   my $self = shift;
   my $hostObj = shift;
   my $compResMor = $self->{'clusterMor'};
   my $find = 0;
   my $ipAddress;

   eval {
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",
                                               $self->{'anchor'});
      my $refArrayofHosts =
         $util->vectorToArray($self->{clusterObj}->getConnectedHosts($compResMor));
      foreach my $hostMor (@$refArrayofHosts){
         if ($hostMor) {
            $ipAddress = $hostSystem->getIPAddress($hostMor);
            $vdLogger->Debug("Has the following host $ipAddress;");
            if ($ipAddress eq $hostObj->{'hostIP'}){
               $vdLogger->Debug("The cluster already has the following host $ipAddress");
               $find = 1;
               last;
            }
         }
      }
   };
   if ($@){
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in checking host in cluster.");
      return FALSE;

   }
   if ($find) {
      $vdLogger->Debug("The host $ipAddress is already in cluster
                                return directly;");
      return TRUE;
   }
   return FALSE;
}


########################################################################
#
# GetAllHostIPs--
#     Method to get the IP addresses of all the hosts in the cluster.
#
# Input:
#     None
#
# Results:
#     ipAddressArray, array of IP addresses of hosts in the cluster;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetAllHostIPs
{
   my $self = shift;
   my $compResMor = $self->{'clusterMor'};

   my @ipAddressArray = ();

   eval {
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",
                                               $self->{'anchor'});
      my $refArrayofHosts =
         $util->vectorToArray($self->{clusterObj}->getConnectedHosts($compResMor));
      foreach my $hostMor (@$refArrayofHosts){
         if ($hostMor) {
            my $ipAddress = $hostSystem->getIPAddress($hostMor);
            push(@ipAddressArray, $ipAddress);
         }
      }
   };
   if ($@){
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in obtaining IP addresses of hosts in cluster. $@");
      return FALSE;
   }

   return \@ipAddressArray;
}


########################################################################
#
# SetAutoClaimStorageAndVSAN
#     Method to Enable/Disable VSAN in a cluster compute resource
#     Also set auto claim storage
#
# Input:
#     Named value parameter with following keys:
#     vsan         : true, enable vsan
#                    false, disable vsan (Mandtory)
#     autoclaim    : true, enable vsan
#                    false, disable vsan (Mandtory)
#
# Results:
#     TRUE, if VSAN enabled and clusterspec reconfigured successfully;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetAutoClaimStorageAndVSAN
{
   my $self = shift;
   my %options = @_;
   my $clusterMor    = $self->{'clusterMor'};
   my $autoClaimStorage = $options{"autoclaimstorage"};
   my $vsan = $options{"vsan"};

   my $setVSANRes = FALSE;
   eval {
      my $vsanClusterHelper = CreateInlineObject("com.vmware.vcqa.vsan.VsanClusterHelper",
                                               $self->{'anchor'});
      my $clusterSpecEx = $self->{'clusterObj'}->getConfigurationEx($clusterMor);
      my $vsanConfig = CreateInlineObject("com.vmware.vc.VsanClusterConfigInfo");
      $vsanConfig->setEnabled($vsan);
      my $vsanConfigHostDefInfo = CreateInlineObject("com.vmware.vc.VsanClusterConfigInfoHostDefaultInfo");
      $vsanConfigHostDefInfo->setAutoClaimStorage($autoClaimStorage);
      $vsanConfig->setDefaultConfig($vsanConfigHostDefInfo);
      $clusterSpecEx->setVsanConfig($vsanConfig);
      $setVSANRes = $self->{'clusterObj'}->reconfigureEx($clusterMor, $clusterSpecEx, TRUE);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in SetAutoClaimStorageAndVSAN");
      return FALSE;
   }
   return $setVSANRes;
}


########################################################################
#
# GetVSANStatus--
#     Method to return VSAN status on cluster
#
# Input:
#
# Results:
#     TRUE, if VSAN enabled;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetVSANStatus
{
   my $self = shift;
   my $result = FALSE;
   eval {
      $result = $self->{clusterHelper}->isVsanEnabled($self->{'clusterMor'});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in GetVSANStatus.");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# SetAdvancedOptions--
#     Method to enable advanced options inside a HA enabled Cluster
#
# Input:
#     Named value parameters with following keys:
#     advancedoptions      :  array of advancedoption hash  (Mandatory)
#
# Results:
#     An object of VDNetLib::InlineJava::Cluster class if successful
#
# Side effects:
#     None
#
########################################################################

sub SetAdvancedOptions
{
   my $self = shift;
   my $compResMor  = $self->{'clusterMor'};

   my %advancedoptions   = @_;
   my $clustercomputeresource;
   my $computeresource;
   my $clusterconfigspec;
   my $clusterconfigspecex;
   my $clusterdasinfo;
   my $options;
   my $folder;
   my $result = FALSE;
   eval {
      $folder = CreateInlineObject(
                              "com.vmware.vcqa.vim.Folder",
                              $self->{'anchor'} );

      #$clustercomputeresource =  CreateInlineObject(
                              #"com.vmware.vcqa.vim.ClusterComputeResource",
                              #$self->{'anchor'} );

      $computeresource =  CreateInlineObject(
                              "com.vmware.vcqa.vim.ComputeResource",
                              $self->{'anchor'} );

      $clusterconfigspec = $self->{'clusterObj'}->getClusterSpec($compResMor);

      $clusterconfigspecex = $folder->createClusterConfigSpecEx();
      $clusterdasinfo = $clusterconfigspec->getDasConfig();
      $options = CreateInlineObject('java.util.ArrayList');

      foreach my $key (keys %advancedoptions){
         my $translated_key;
         my $option_val =  CreateInlineObject("com.vmware.vc.OptionValue");
         if ($key eq "maxSmpFtVmsPerHost"){
             $translated_key = VDNetLib::TestData::TestConstants::MAXSMPFTVMPERHOST;
         }elsif ($key eq "maxFtVmsPerHost"){
             $translated_key = VDNetLib::TestData::TestConstants::MAXFTVMPERHOST;
         }elsif ($key eq "ignoreInsufficientHbDatastore"){
             $translated_key = VDNetLib::TestData::TestConstants::IGNOREINSUFFICIENTHBDATASTORE;
         }
         $option_val->setKey($translated_key);
         $option_val->setValue($advancedoptions{$key});
         $options->add($option_val);
     }

      $clusterdasinfo->setOption($options);
      $clusterconfigspecex->setDasConfig($clusterdasinfo);

      $result = $computeresource->reconfigureEx($compResMor,$clusterconfigspecex,1);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::ClusterComputeResource objects");
      return FALSE;
   }

   return $result;
}

1;
