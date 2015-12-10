###############################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Folder;

#
# This class captures all common methods to configure or get information
# from a VC. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with VC.
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

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;


########################################################################
#
# new--
#     Constructor for this class VDNetLib::InlineJava::Folder
#
# Input:
#     Named value parameters with following keys:
#     anchor      : connection anchor (Required)
#
# Results:
#     An object of VDNetLib::InlineJava::Folder class if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class   = shift;
   my $self;
   my %options = @_;

   $self->{'anchor'} = $options{'anchor'};

   if (not defined $self->{'anchor'}) {
      $vdLogger->Error("Connect anchor not provided as parameter");
      return FALSE;
   }

   eval {
      $self->{'folderObj'} = CreateInlineObject("com.vmware.vcqa.vim.Folder",
                                                $self->{'anchor'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::Folder object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# CreateDistributedVirtualSwitch--
#     Method to create DistributedVirtualSwitch on given datacenter
#
# Input:
#     Named value parameter with following keys:
#     dvsName : name of the DVS    (Required)
#     datacenterName : name of the datacenter (Required)
#     verion  : version of the DVS (Optional)
#
# Results:
#     Returns  VDNetLib::InlineJava::DVS object, if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateDistributedVirtualSwitch
{
   my $self = shift;
   my %options = @_;

   my $dvsName        = $options{dvsName};
   my $version        = $options{version};
   my $datacenterName = $options{datacenter};

   my $folderObj = $self->{'folderObj'};
   my $anchor    = $self->{'anchor'};

   if ((not defined $dvsName) || (not defined $datacenterName)) {
      $vdLogger->Error("DVS name and/or datacenter name not provided");
      return FALSE;
   }

   my $dvsMor = 0;
   eval {
      my $dcMor = $folderObj->getDataCenter($datacenterName);
      my $networkFolder = $folderObj->getNetworkFolder($dcMor);
      my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $dvsConfigSpec = $dvsUtil->createDefaultDVSConfigSpec($dvsName);
      $dvsConfigSpec->setName($dvsName);
      if (defined $version) {
         my $spec = $dvsUtil->getProductSpec($anchor, $version);
         my $DVSCapability;
         my $dvsCreateSpec = $dvsUtil->createDVSCreateSpec($dvsConfigSpec, $spec, $DVSCapability);
         $dvsCreateSpec->setConfigSpec($dvsConfigSpec);
         $dvsMor = $folderObj->createDistributedVirtualSwitch($networkFolder,
                                                              $dvsCreateSpec);
      } else {
         $dvsMor = $folderObj->createDistributedVirtualSwitch($networkFolder,
                                                           $dvsConfigSpec);
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   my $dvsObj = VDNetLib::InlineJava::DVS->new('anchor' => $anchor,
                                           'datacenter' => $datacenterName,
                                           'dvsName'  => $dvsName,
                                           'folderObj' => $folderObj,
                                           );
   if (!$dvsObj) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::DVS object");
      return FALSE;
   }

   #
   # VDS 5.1 is with LACPv1 by default, while VDS 5.5 or later is with LACPv2
   # by default. Other versions (4.0/4.1.0/5.0.0) don't support LACP.
   #
   my $ret = TRUE;

   my %versionMap = (
      "4.0"   => "nolag",
      "4.1.0" => "nolag",
      "5.0.0" => "nolag",
      "5.1.0" => "singlelag",
      "5.5.0" => "multiplelag",
      "6.0.0" => "multiplelag",
   );

   if (defined $version) {
      $ret = $dvsObj->SetVMwareDVSLacpApiVersion(lacpversion => $versionMap{$version});
   } else {
      $ret = $dvsObj->SetVMwareDVSLacpApiVersion(lacpversion => "multiplelag");
   }

   if ($ret ne TRUE) {
      $vdLogger->Error("Failed to set LacpApiVersion on $dvsName");
      return FALSE;
   }
   return $dvsObj;
}


########################################################################
#
# RegisterVM--
#     Method to register a VM using the given vmx file.
#
# Input:
#     Named value parameters with following keys:
#     vmName         : Display name for the VM (Required)
#     vmxFile        : vmx file in format
#                      [<datastore>] <folder>/<vmx file>
#                      (Required)
#     asTemplate     : boolean value to indicate if the VM should be
#                      registered as template (optional)
#     resourcePoolMOR: resource pool MOR (optional)
#     folderMOR      : folder MOR (optional)
#     hostMOR        : host MOR (optional)
#
# Results:
#     1, if the VM is registered successfully;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RegisterVM
{
   my $self = shift;
   my %args = @_;

   my $vmName           = $args{'vmName'};
   my $vmxFile          = $args{'vmxFile'};
   my $asTemplate       = $args{'asTemplate'};
   my $resourcePoolMOR  = $args{'resourcePoolMOR'};
   my $folderMOR        = $args{'folderMOR'};
   my $hostMOR          = $args{'hostMOR'};

   $asTemplate = (defined $asTemplate) ? $asTemplate : 0;

   if (not defined $folderMOR) {
      my $datacenterMORs = [];
      $datacenterMORs = $self->{folderObj}->getDataCenters();
      $folderMOR = $self->{folderObj}->getVMFolder($datacenterMORs->get(0));
   }

   if (not defined $resourcePoolMOR) {
      my $resourcePoolObj =
         CreateInlineObject("com.vmware.vcqa.vim.ResourcePool",
                            $self->{anchor});
      $resourcePoolMOR = $resourcePoolObj->getResourcePool();
   }

   my $vmMOR;
   eval {
      $vmMOR = $self->registerVm(
                                 $folderMOR,
                                 $vmxFile,
                                 $vmName,
                                 $asTemplate,
                                 $resourcePoolMOR,
                                 $hostMOR,
                                 );
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while registering $vmxFile");
      return FALSE;
   }

   return $vmMOR;
}


########################################################################
#
# AddHost--
#     Method to add a host to a particular folder.
#
# Input:
#     Named value parameters with following keys:
#     hostCnxSpec   : hostCnxSpec HostConnectionSpec object (Mandtory)
#     folderMor     : folder MOR, default is the first host folder (Optional)
#
# Results:
#     Host Mor object, if host added successfully;
#     FALSE, if host is not not added;
#
# Side effects:
#     None
#
########################################################################

sub AddHost
{
   my $self = shift;
   my %options = @_;

   my $hostCnxSpec      = $options{'hostCnxSpec'};
   my $folderMor        = $options{'folderMor'};

   if (not defined $hostCnxSpec) {
      $vdLogger->Error("hostCnxSpec name not provided");
      return FALSE;
   }

   my $folderObj  = $self->{'folderObj'};
   if (not defined $folderMor) {
      my $datacenterMORs = [];
      $datacenterMORs = $folderObj->getDataCenters();
      $folderMor = $folderObj->getHostFolder($datacenterMORs->get(0));
   }

   my $hostMor;
   eval {
      $hostMor = $folderObj->addStandaloneHost($folderMor,
                                               $hostCnxSpec,
                                               undef,
                                               1,
                                               undef);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while adding host to datacenter");
      return FALSE;
   }

   return $hostMor;
}


########################################################################
#
# CreateHostConnectSpec--
#     Method to create hostConnectSpec from HostConnectInfo.
#
# Input:
#     Named value parameters with following keys:
#     hostName      : Host name or IP address (Mandtory)
#     userName      : Login user name, default root (Optional)
#     password      : Login user password, default ca$hc0w (Optional)
#     port          : Service port number, default 443 (Optional)
#     forceAddHost  : flag to enable forcefully add host (Optional)
#
# Results:
#     hostCnxSpec, if host added successfully;
#     FALSE, if hostConnectSpec creation fails;
#
# Side effects:
#     None
#
########################################################################

sub CreateHostConnectSpec
{
   my $self = shift;
   my %options = @_;

   my $hostName    = $options{'hostName'};
   my $userName    = $options{'userName'};
   my $password    = $options{'password'};
   my $port        = $options{'port'};
   my $forceAddHost = $options{'forceAddHost'} || "true";

   if (not defined $hostName ) {
      $vdLogger->Error("HostName missing while creating HostConnectSpec");
      return FALSE;
   }

   if (not defined $userName ) {
      $userName = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_USER;
   }

   if (not defined $password ) {
      $password = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_PASSWD;
   }

   if (not defined $port ) {
      $port = "443";
   }

   my $hostCnxSpec;
   $vdLogger->Debug( "Create HostConnectSpec with hostName/userName/password/" .
                   "port: $hostName/$userName/$password/$port" .
                   "setForce: $forceAddHost");
   eval {
      $hostCnxSpec = CreateInlineObject("com.vmware.vc.HostConnectSpec");
      $hostCnxSpec->setHostName( $hostName );
      $hostCnxSpec->setUserName( $userName );
      $hostCnxSpec->setPassword( $password );
      $hostCnxSpec->setPort( $port );
      if ($forceAddHost =~ /true/i) {
         $hostCnxSpec->setForce(1);
      } else {
         $hostCnxSpec->setForce(0);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while while creating HostConnectSpec.");
      return FALSE;
   }

   return $hostCnxSpec;
}


########################################################################
#
# CreateCluster--
#     Method to create a new compute resource in this folder for a
#     cluster of hosts.
#
# Input:
#     Named value parameters with following keys:
#     parentFolderMor  : Destination parent folder mor object (Mandtory)
#     clusterName      : Name of the ComputerResource folder (Mandtory)
#     clusterSpec      : ClusterSpecification (Mandtory)
#
# Results:
#     cluster Mor, if cluster created successfully;
#     FALSE, if cluster creation fails;
#
# Side effects:
#     None
#
########################################################################

sub CreateCluster
{
   my $self = shift;
   my %options = @_;

   my $parentFolderMor = $options{'parentFolderMor'};
   my $clusterName     = $options{'clusterName'};
   my $clusterSpec     = $options{'clusterSpec'};

   if (not defined $parentFolderMor ||
       not defined $clusterName ||
       not defined $clusterSpec ) {
      $vdLogger->Error("One or more of parentFolderMor, " .
                       "clusterName and clusterSpec are missing.");
      return FALSE;
   }

   my $compResMor;
   eval {
      $compResMor = $self->{'folderObj'}->createCluster($parentFolderMor,
                                                        $clusterName,
                                                        $clusterSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while while creating cluster.");
      return FALSE;
   }

   return $compResMor;
}


########################################################################
#
# CreateClusterSpec--
#     Method to create default cluster specification.
#
# Input:
#     None
#
# Results:
#     ClusterSpec Mor, if ClusterSpec created successfully;
#     FALSE, if ClusterSpec creation fails;
#
# Side effects:
#     None
#
########################################################################

sub CreateClusterSpec
{
   my $self = shift;

   my $clusterSpec;
   eval {
      $clusterSpec = $self->{'folderObj'}->createClusterSpec();
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while CreateClusterSpec");
      return FALSE;
   }

   return $clusterSpec;
}


########################################################################
#
# CreateClusterConfigSpecEx--
#     Method to create default cluster configuration specification
#
# Input:
#     None
#
# Results:
#     ClusterConfigSpecEx object, if created successfully;
#     FALSE, if creation fails;
#
# Side effects:
#     None
#
########################################################################

sub CreateClusterConfigSpecEx
{
   my $self = shift;

   my $clusterConfigSpecEx;
   eval {
      $clusterConfigSpecEx = $self->{'folderObj'}->createClusterConfigSpecEx();
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating ClusterConfigSpecEx");
      return FALSE;
   }

   return $clusterConfigSpecEx;
}

########################################################################
#
# GetHostFolderMor--
#     Method to Get Host Folder from datacenter
#
# Input:
#     Mor of datacenter
#     None
#
# Results:
#     MOR of host folder, if created successfully;
#     FALSE, if creation fails;
#
# Side effects:
#     None
#
########################################################################

sub GetHostFolderMor
{
   my $self = shift;
   my $dcMor = shift;

   if (not defined $dcMor) {
      $vdLogger->Error("Datacenter MOR is not defined while creating " .
		       "host folder mor.");
      return FALSE;
   }

   my $hostFolderMor = undef;
   eval {
      $hostFolderMor = $self->{folderObj}->getHostFolder($dcMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating GetHostFolderMor");
      return FALSE;
   }

   return $hostFolderMor;
}


########################################################################
#
# GetDataCenterMor--
#     Method to Datacenter MOR from datacenter name
#
# Input:
#     Name of datacenter
#     None
#
# Results:
#     MOR of host folder, if created successfully;
#     FALSE, if creation fails;
#
# Side effects:
#     None
#
########################################################################

sub GetDataCenterMor
{
   my $self = shift;
   my $dcName = shift;

   if (not defined $dcName) {
      $vdLogger->Error("Datacenter name is not defined while creating " .
		       "datacenter mor.");
      return FALSE;
   }

   my $dcMor = undef;

   eval {
      $dcMor = $self->{folderObj}->getDataCenter($dcName);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating GetDataCenterMor");
      return FALSE;
   }

   return $dcMor;
}


########################################################################
#
# GetClusterMor--
#     Method to Get cluster Mor by cluster name
#
# Input:
#     Name of cluster
#     Name of datacenter
#
# Results:
#     MOR of cluster, if created successfully;
#     FALSE, if creation fails;
#
# Side effects:
#     None
#
########################################################################

sub GetClusterMor
{
   my $self = shift;
   my $clusterName = shift;
   my $dcName = shift;

   if ((not defined $clusterName) || (not defined $dcName)) {
      $vdLogger->Error("Cluster name/Datacenter name is not defined while " .
		       "creating cluster mor.");
      return FALSE;
   }

   my $clusterMor = undef;

   eval {
      my $dcMor = $self->GetDataCenterMor($dcName);
      $clusterMor = $self->{folderObj}->getClusterByName($clusterName, $dcMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while GetClusterMor");
      return FALSE;
   }

   return $clusterMor;
}

1;
