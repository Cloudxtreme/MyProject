###############################################################################
# Copyright (C) 2014 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::VC::Cluster
#
#   This package allows to perform various operations on VC Cluster
#   and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::VC::Cluster;

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
use VDNetLib::VC::ResourcePool;
use VDNetLib::InlineJava::Folder::Datacenter::Cluster;
use VDNetLib::InlineJava::Folder::Datacenter;
use VDNetLib::InlineJava::Host;

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::VC::Cluster).
#
# Input:
#      dcObj	   - Datacenter Object
#      cluster     - Cluster Name
#      stafHelper  - STAFHelper Object
#
# Results:
#      An object of VDNetLib::VC::Cluster package.
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

   $self->{dcObj}	   = $args{dcObj};
   $self->{clusterName}    = $args{clusterName};

   bless($self, $class);

   return $self;
}


###############################################################################
#
# GetInlineClusterObj --
#      Method to return inline object
#
# Input:
#
# Results:
#      An object of VDNetLib::InlineJava::Folder::Datacenter::Cluster.
#
# Side effects:
#      None
#
###############################################################################

sub GetInlineClusterObj
{
   my $self = shift;
   my $inlineDatacenter = $self->{dcObj}->GetInlineDatacenterObj();
   my $inlineCluster = VDNetLib::InlineJava::Folder::Datacenter::Cluster->new(
			datacenterObj => $inlineDatacenter,
			clusterName => $self->{clusterName},
			);
   return $inlineCluster;
}

###############################################################################
#
# MoveHostsToCluster --
#      This method moves host into a cluster from datacenter
#
# Input:
#      hostObjArray - Reference to an array of Host Objects
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub MoveHostsToCluster
{
   my $self        = shift;
   my @hostObjAray = @_; # mandatory
   my @hostList;

   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my $result;

   foreach my $hostObj (@hostObjAray) {
      my $hostIP = $hostObj->{hostIP};
      #
      # Check if the host is already in the list of hosts added to
      # the given cluster.
      #
      my $isPresent = grep{/^$hostIP$/} @hostList;
      if ($isPresent != 0) {
         $vdLogger->Debug("$hostIP is already present in Cluster: $cluster");
         next;
      }

      $vdLogger->Info("Moving host $hostIP into cluster ($cluster)......");
      my $hostObjInline = $hostObj->GetInlineHostObject();
      $result = $clusterObjInline->MoveHostIntoCluster(hostObj => $hostObjInline);
      if (!$result) {
         $vdLogger->Error("Failure to move host($hostIP) to ".
                          "cluster ($cluster)" . Dumper($result));
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      push(@hostList, $hostIP);
   }

   return SUCCESS;
}


###############################################################################
#
# AddHostsToCluster --
#      This method is to add a new host into a cluster
#
# Input:
#      folderObj - folder inline object used by vc session anchor
#      hostObjArray - Reference to an array of Host Objects
#      forceAddHost - flag to enable forcefull adding of host into Cluster
#                    (Optional)
#      allowexisthost - flag to enable return existing host in cluster
#
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddHostsToCluster
{
   my $self = shift;
   my $folderObjInline = shift;
   my $refToHostObjArray = shift;
   my $forceAddHost = shift;
   my $allowexisthost = shift;
   my @hostList;

   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my $result;

   $vdLogger->Info("Adding hosts into cluster ($cluster)......");
   $result = $clusterObjInline->AddHostsToCluster(
                          hostsObj => $refToHostObjArray,
                          folderObj => $folderObjInline,
                          forceAddHost => $forceAddHost,
                          allowexisthost => $allowexisthost);
   if (!$result) {
       $vdLogger->Error("Failed to add hosts cluster ($cluster)" .
                                                 Dumper($result));
        VDSetLastError("EINLINE");
        return FAILURE;
   }

   foreach my $hostObj (@$refToHostObjArray) {
      my $hostIP = $hostObj->{hostIP};
      #
      # Check if the host is already in the list of hosts added to
      # the given cluster.
      #
      my $isPresent = grep{/^$hostIP$/} @hostList;
      if ($isPresent != 0) {
         $vdLogger->Debug("$hostIP is already present in Cluster: $cluster");
         next;
      }

      # Update the VC information in the host object
      my $vcObj = $self->{dcObj}{vcObj};
      $hostObj->UpdateVCObj($vcObj);
      $hostObj->UpdateCurrentVMAnchor($vcObj->{vmAnchor});
      push(@hostList, $hostIP);
   }

   return SUCCESS;
}

###############################################################################
#
# MoveHostsFromCluster --
#      This method moves host from cluster to datacenter
#
# Input:
#      hostObjArray - Reference to an array of Host Objects
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub MoveHostsFromCluster
{
   my $self        = shift;
   my @hostObjAray = @_; # mandatory
   my @hostList;

   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my $result;

   foreach my $hostObj (@hostObjAray) {
      my $hostIP = $hostObj->{hostIP};
      #
      # Check if the host is already in the list of hosts added to
      # the given cluster.
      #
      my $isPresent = grep{/^$hostIP$/} @hostList;
      if ($isPresent != 0) {
         $vdLogger->Debug("$hostIP is already moved from Cluster: $cluster");
         next;
      }

      $vdLogger->Info("Moving host $hostIP from cluster ($cluster)......");
      my $hostObjInline = $hostObj->GetInlineHostObject();
      $result = $clusterObjInline->MoveHostFromClusterToSAHost(
                                                hostObj => $hostObjInline);
      if (!$result) {
         $vdLogger->Error("Failure to move host($hostIP) from ".
                          "cluster $cluster)" . Dumper($result));
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      push(@hostList, $hostIP);
   }

   return SUCCESS;
}


###############################################################################
#
# EditClusterSettings --
#      This method used to edit the configuration of cluster
#
# Input:
#      clusterHash : @array of format
#	 ( ha, 0/1,
#	   drs, 0/1, )
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub EditClusterSettings
{
   my $self = shift;
   my %clusterHash = @_;
   my $ha = $clusterHash{ha};
   my $drs = $clusterHash{drs};
   my $vsan = $clusterHash{vsan};
   my $autoclaim = $clusterHash{autoclaimstorage};

   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();

   #
   # Configure HA settings
   #
   if (defined $ha){
      if (FAILURE eq $self->ConfigureDAS(%clusterHash)){
	 $vdLogger->Error("Failed to configure HA in cluster $cluster");
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }
   }
   #
   # Configure DRS settings
   #
   if (defined $drs){
      if (FAILURE eq $self->ConfigureDRS(%clusterHash)){
	 $vdLogger->Error("Failed to configure DRS in cluster $cluster");
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }
   }
   #
   # Configure VSAN settings
   #
   if (defined $vsan || defined $autoclaim){
      if (FAILURE eq $self->ConfigureAutoClaimStorageAndVSAN(%clusterHash)){
	 $vdLogger->Error("Failed to configure VSAN in cluster $cluster");
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }
   }
   $vdLogger->Info("Cluster is successfully configured");
   return SUCCESS;
}


###############################################################################
#
# ConfigureDAS --
#      This method used to configuration HA in cluster
#
# Input:
#      clusterHash : @array of format
#	 ( ha, 1/0,
#	   admissioncontrol, 1/0,
#	   failoverlevel, 1-31,
#	   waithaconf, 1/0)
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureDAS
{
   my $self = shift;
   my %clusterHash = @_;
   my $ha = $clusterHash{ha};
   my $advancedoptions = $clusterHash{advancedoptions};
   my $admissionControl = $clusterHash{admissioncontrol};
   my $failoverLevel = $clusterHash{failoverlevel};
   my $isolationResponse = $clusterHash{isolationresponse};
   my $waitHAConf = $clusterHash{waithaconf};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my $cluster     = $self->{clusterName};
   my $result;

   $vdLogger->Info("Configuring HA in cluster $cluster");
   $result = $clusterObjInline->SetDAS( 'enable' => $ha,
                       'admissionControl' => undef,
                       'failoverLevel' => undef,
                       'isolationResponse' => undef,
                       'waitHAConf' => undef);
   if ((not defined $result) || !$result) {
      $vdLogger->Error("HA is not configured in cluster " .
			  "$self->{clusterName}" . Dumper(\%clusterHash));
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   if ((defined %{$advancedoptions}) && ($ha == 1)){
      $vdLogger->Info("Configuring HA Advanced Options in cluster $cluster");
      $result = $clusterObjInline->SetAdvancedOptions(%{$advancedoptions});
      if ((not defined $result) || !$result) {
         $vdLogger->Error("Advanced Options is not configured in cluster " .
                          "$self->{clusterName}" . Dumper(\%clusterHash));
         VDSetLastError("EINLINE");
         return FAILURE;
      }
   }

   $result = $clusterObjInline->GetDASStatus();
   if ($result){
      $vdLogger->Info("Enabled HA in cluster $cluster");
   } else {
      $vdLogger->Info("Disabled HA in cluster $cluster");
   }

   return SUCCESS;
}


###############################################################################
#
# ConfigureDRS --
#      This method used to configure DRS in cluster
#
# Input:
#      clusterHash : @array of format
#	 (drs, "enable/disable", )
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureDRS
{
   my $self = shift;
   my %clusterHash = @_;
   my $drs = $clusterHash{drs};

   my $clusterObjInline = $self->GetInlineClusterObj();
   my $cluster     = $self->{clusterName};
   my $result;

   $vdLogger->Info("Configuring DRS in cluster $cluster");
   $result = $clusterObjInline->SetDRS('enable' => $drs);
   if ((not defined $result) || !$result) {
      $vdLogger->Error("DRS is not configured in cluster " .
			  "$cluster" . Dumper(\%clusterHash));
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $result = $clusterObjInline->GetDRSStatus();
   if ($result){
      $vdLogger->Info("DRS is enabled in cluster $cluster");
   } else {
      $vdLogger->Info("DRS is disabled in cluster $cluster");
   }

   return SUCCESS;
}


#############################################################################
#
# GetClusterMORId--
#     Method to get the Cluster's Managed Object Ref ID.
#
# Input:
#     clusterName : Cluster display/registered name as in the inventory
#
# Results:
#     clusterMORID,
#     "FAILURE", if cluster is not found or in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetClusterMORId
{
   my $self   = shift;
   my $clusterName = $self->{'clusterName'};

   my $clusterMORID;

   my $inlineClusterObj = $self->GetInlineClusterObj();
   if (!($clusterMORID = $inlineClusterObj->GetClusterMORID($clusterName))) {
      $vdLogger->Error("Failed to get the Managed Object ID for the Cluster:".$clusterName);
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object ID for the Cluster:".$clusterName.
                    " is MORID:". $clusterMORID);
   return $clusterMORID;
}


#############################################################################
#
# GetMORId--
#     Method to get the Cluster's Managed Object Ref ID.
#
# Input:
#     none
#
# Results:
#     clusterMORID,
#     "FAILURE", if cluster is not found or in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self = shift;
   return $self->GetClusterMORId();
}


#############################################################################
#
# GetResourcePoolMORID--
#     Method to get the ResourcePool's Managed Object Ref ID.
#
# Input:
#     clusterName : ResourcePool display/registered name as in the inventory
#
# Results:
#     clusterMORID,
#     "FAILURE", if cluster is not found or in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetResourcePoolMORID
{
   my $self   = shift;
   my $clusterName = $self->{'clusterName'};

   my $clusterMORID;
   my $resourcePoolMORID;

   my $inlineClusterObj = $self->GetInlineClusterObj();
   if (!($resourcePoolMORID = $inlineClusterObj->GetResourcePoolMORID($clusterName))) {
      $vdLogger->Error("Failed to get the Managed Object ID for the ResourcePool ".
	               "in Cluster:".$clusterName);
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object ID for the ResourcePool in Cluster:".$clusterName.
                    " is MORID:". $resourcePoolMORID);
   return $resourcePoolMORID;
}


###############################################################################
#
# RemoveHostsFromCluster --
#      This method is for disconnecting Hosts from cluster
#
# Input:
#     arrayOfHostObjects: reference to array of Host objects
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

sub RemoveHostsFromCluster
{
   my $self = shift;
   my $refToHostObjArray = shift;

   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my $result;
   my @hostList;

   foreach my $hostObj (@$refToHostObjArray) {
      my $hostIP = $hostObj->{hostIP};
      #
      # Check if the host is already in the list of hosts removed from
      # the given cluster.
      #
      my $isPresent = grep{/^$hostIP$/} @hostList;
      if ($isPresent != 0) {
         $vdLogger->Debug("$hostIP is already removed from Cluster: $cluster");
         next;
      }

      $vdLogger->Info("Removing host $hostIP from cluster ($cluster)......");
      my $hostObjInline = $hostObj->GetInlineHostObject();
      $result = $clusterObjInline->RemoveHostFromCluster(hostObj => $hostObjInline);
      if (!$result) {
         $vdLogger->Error("Failure to remove host($hostIP) from ".
                          "cluster ($cluster)" . Dumper($result));
         VDSetLastError("EINLINE");
         return FAILURE;
      }

      # Remove the VC information in the host object
      my $vcObj = $self->{dcObj}{vcObj};
      # Without any argument undef will be updated in the vcObj
      $hostObj->UpdateVCObj();
      #
      # Without any argument undef will be sent and default host
      # anchor will get updated in the currentVMAnchor
      #
      $hostObj->UpdateCurrentVMAnchor();
      push(@hostList, $hostIP);
   }
   return SUCCESS;
}

###############################################################################
#
# CreateResourcePool --
#      This method adds a resource pool with specified parameter.
#
# Input:
#     ResourcePoolName - Name of the resource pool
#     cpuAllocation - Information related to cpu allocation for RP
#     memoryAllocation - Information related to mem allocation for RP
#
# Results:
#      Returns "SUCCESS", if resouce pool get created.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateResourcePool
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my $cluster     = $self->{clusterName};
   my $clusterObjInline = $self->GetInlineClusterObj();
   my @arrayOfResourcePoolObjects;
   my $result;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Resource Pool  spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      if (not defined $options{name}) {
         $vdLogger->Error("Name of the resource pool is not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $clusterObjInline->CreateResourcePool(%options);
      if (! $result) {
         $vdLogger->Error("Failure to create resource pool $options{name}".
                          "for cluster ($cluster)" . Dumper($result));
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      # create resourcepool obj.
      my $resourcePoolObj = VDNetLib::VC::ResourcePool->new(
                                        clusterObj => $self,
                                        resourcePoolName => $options{name});
      if ($resourcePoolObj eq FAILURE) {
         $vdLogger->Error("Failed to create RP object for $cluster");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfResourcePoolObjects, $resourcePoolObj;
   }
   return \@arrayOfResourcePoolObjects;
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
#################################################################################

sub RemoveResourcePool
{
   my $self = shift;
   my $arrayOfResourcePoolObjects = shift;

   foreach my $resourcePoolObject (@$arrayOfResourcePoolObjects) {
      my $clusterObjInline = $self->GetInlineClusterObj();
      if (! $clusterObjInline->RemoveResourcePool()){
         $vdLogger->Error("INLINE: remove resource pool failed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("remove RP  $resourcePoolObject->{'resourcePoolName'} ".
                      "from cluster $self->{'clusterObj'}->{'clusterName'}");
   }
   return SUCCESS;
}


###############################################################################
#
# RebootHostsInClusterSequentially --
#      This method reboots all the hosts in the cluster one by one.
#
# Input:
#      None
#
# Results:
#
#      Returns "SUCCESS", if all hosts rebooted successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RebootHostsInClusterSequentially
{
   my $self = shift;
   my $refToHostObjArray = shift;

   foreach my $hostObj (@$refToHostObjArray) {
      my $result = $hostObj->Reboot();
      if ($result eq "FAILURE" ) {
         $vdLogger->Error("Reboot failed on host");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# RebootHostsInCluster --
#      This method reboots all the hosts in the cluster.
#
# Input:
#      mode                 :   e.g. parallel/sequential
#      refToHostObjArray    :   Array of Host objects
#
# Results:
#
#      Returns "SUCCESS", if all hosts rebooted successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RebootHostsInCluster
{
   my $self = shift;
   my $mode = shift;
   my $refToHostObjArray = shift;

   my $inlineClusterObj = $self->GetInlineClusterObj();
   my $clusterHostIPs = $inlineClusterObj->GetAllHostIPs();

   my @clusterHostsArray = ();
   foreach my $clusterHost (@$refToHostObjArray) {
      my $inCluster = 0;
      foreach my $hostIP (@$clusterHostIPs) {
         if ($clusterHost->{hostIP} eq $hostIP) {
            $inCluster = 1;
         }
      }
      if ($inCluster eq 1) {
         push(@clusterHostsArray, $clusterHost);
      }
   }

   my $result;
   if ($mode eq 'parallel') {
      $vdLogger->Debug("Rebooting hosts in parallel");
      $result = $self->RebootAllClusterHostsInParallel(\@clusterHostsArray);
   } else {
      $vdLogger->Debug("Rebooting hosts in sequence");
      $result = $self->RebootHostsInClusterSequentially(\@clusterHostsArray);
   }

   if ($result eq 'FAILURE') {
      $vdLogger->ERROR("Rebooting hosts failed");
      return FAILURE;
   }

   return SUCCESS;
}


###############################################################################
#
# RebootAllClusterHostsInParallel --
#      This method reboots all the hosts in the cluster in parallel.
#
# Input:
#      None
#
# Results:
#
#      Returns "SUCCESS", if all hosts rebooted successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RebootAllClusterHostsInParallel
{
   my $self = shift;
   my $refToHostObjArray = shift;

   my $result;
   foreach my $hostObj (@$refToHostObjArray) {

      $result = $hostObj->AsyncReboot();
      if ($result eq "FAILURE" ) {
         $vdLogger->Error("Reboot failed on host");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   #Waiting for ESX host rebooting.
   $vdLogger->Info("Waiting 2 min for the Hosts to Reboot...");
   sleep(120);

    my $inputHash;
    $inputHash->{'method'} = 'AreHostsAccessible';
    $inputHash->{'obj'} = $self;
    $inputHash->{'param'} = $refToHostObjArray;
    $inputHash->{'timeout'} = 20*60;
    $inputHash->{'sleep'} = 60;
    VDNetLib::Common::Utilities::RetryMethod($inputHash);

   for my $hostObj (@$refToHostObjArray) {
       if ($hostObj->RecoverFromReboot eq 'FAILURE') {
          $vdLogger->Error("$hostObj->{hostIP} didnot recover from reboot");
          return FAILURE;
       }
   }

   return SUCCESS;
}

###############################################################################
#
# ConfigureAutoClaimStorageAndVSAN --
#      This method used to
#      - Enable Disables vsan
#      - set/unset auto claim storoage
#
# Input:
#      clusterHash : @array of format
#
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureAutoClaimStorageAndVSAN
{
   my $self = shift;
   my %clusterHash = @_;

   my $clusterObjInline = $self->GetInlineClusterObj();
   my $cluster     = $self->{clusterName};
   my $result;

   $result = $clusterObjInline->SetAutoClaimStorageAndVSAN(%clusterHash);
   if ((not defined $result) || !$result) {
      $vdLogger->Debug("SetAutoClaimStorageAndVSAN failed for cluster " .
                       "$cluster" . Dumper(\%clusterHash));
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $result = $clusterObjInline->GetVSANStatus();
   if ($result){
      $vdLogger->Info("VSAN is enabled in cluster $cluster");
   } else {
      $vdLogger->Info("VSAN is disabled in cluster $cluster");
   }

   return SUCCESS;
}


###############################################################################
#
# ConfigureLicense
#      This method calls VC's ConfigureLicense to assign license key to cluster
#
# Input:
#      license key
#
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureLicense
{
   my $self       = shift;
   my %args       = @_;
   my $license    = $args{'license'};
   my $licenseKey = $args{'licensekey'};
   my $vcObj = $self->{dcObj}{vcObj};
   return $vcObj->ConfigureLicense(license    => $license,
                                   entity     => $self,
                                   licensekey => $licenseKey);
}


###############################################################################
#
# AreHostsAccessible
#      This method checks if all the hosts are up or not
#
# Input:
#      refToHostObjArray : array of host objects
#
# Results:
#      Returns "SUCCESS", if successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AreHostsAccessible
{
   my $self = shift;
   my $refToHostObjArray = shift;

   for my $hostObj (@$refToHostObjArray) {
      if ($hostObj->IsAccessible eq 'FAILURE') {
         return FAILURE;
      }
   }

   return SUCCESS;
}

1;
