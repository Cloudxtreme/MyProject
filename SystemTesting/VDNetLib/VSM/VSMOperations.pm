########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::VSMOperations;

use strict;
use warnings;
use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use Data::Dumper;
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant attributemapping => {
   'build' => {
         'payload'   => 'build',
         'attribute' => undef,
   },
   'ptep_cluster_entries' => {
         'attribute' => undef,
         'payload' => 'ptepclusterentries'
   },
   'ptep_cluster_entry' => {
         'attribute' => 'GetMORId',
         'payload' => 'ptepclusterentry'
   }
};

use VDNetLib::Common::Result;

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NVP::NVPOperations
#
# Input:
#     ip : ip address of the nvp controller
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NVP::NVPOperations;
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
   $self->{ip}       = $args{ip};
   $self->{user}     = $args{username};
   $self->{password} = $args{password};
   $self->{type}     = "vsm";
   $self->{cert_thumbprint} = $args{cert_thumbprint};
   $self->{isPrimary} = $args{isPrimary};
   $self->{root_password} = $args{root_password};
   $self->{upgrade_build} = $args{upgrade_build};
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
   my %args = @_;
   # Currently most of the endpoint are at version 2.0, so setting
   # default 2.0 (same as in vsm.py)
   my $endpoint_version = $args{endpoint_version} || "2.0";

   my $inlinePyObj = CreateInlinePythonObject('vsm.VSM',
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password},
                                              $self->{cert_thumbprint},
                                              $endpoint_version,
                                                );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# Upgrade --
#     Method to upgrade vsm
#     TODO: Add comment for not abstracting
#
# Input:
#     name          : Action key name
#     build         : This contains vsm build information for build to upgrade
#                     to
#     build_product : Build product name (e.g. vsmva)
#     build_branch  : Build product branch (e.g. vshield-main)
#     build_context : Build product context (e.g. ob/sb)
#     build_type    : Build type (e.g. Beta/Release)
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
   my $self = shift;
   my %args = @_;



   my $operation = $args{operation};
   my $build = $args{build};
   my $name  = $args{name};

   my $payload;

   if ($build eq "from_yaml") {
      $payload->{'build'} = "$self->{upgrade_build}";
    } elsif ($build eq "from_buildweb") {
      $payload->{'build_product'} = $args{build_product};
      $payload->{'build_branch'} = $args{build_branch};
      $payload->{'build_context'} = $args{build_context};
      $payload->{'build_type'} = $args{build_type};
      $payload->{'build'} = $build;
    } else {
      $payload->{'build'} = $build;
   }

   $payload->{'name'} = $name;

   # Adding root password information. This is needed to get root access on the
   # appliance
   $payload->{'root_password'} = $self->{root_password};

   my $result;

   $vdLogger->Info("VSM upgrade starting now");

   eval {

       my $inlinePyObj = $self->GetInlinePyObject();
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'nsxapi_appliance_management.NSXAPIApplianceManagement',
                      $inlinePyObj);
       $result = $inlinePyApplObj->upgrade($payload);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while upgrading " .
                       " vsm in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to upgrade vsm $self->{ip} to build: $payload->{'build'}");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("vsm $self->{ip} upgraded successfully to build: $payload->{'build'}");
   }
   return SUCCESS;
}


########################################################################
#
# DeleteVXLANController --
#     Method to delete components/managed objects/entities. This
#     method invokes Py layer's delete method from baseController.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called
#
# Results:
#     TBD TODO:
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub DeleteVXLANController
{
   my $self                = shift;
   my $arrayOfPerlObjects  = shift;
   my $arrayOfCorrespondingArgs;
   my $args;
   $args->{forceremovalforlast} = "true";
   push(@$arrayOfCorrespondingArgs, $args);
   my $result = $self->DeleteComponent($arrayOfPerlObjects,
                                       $arrayOfCorrespondingArgs);
   foreach my $templateObj (@$arrayOfPerlObjects) {
      # To list controller VMs on the host in order to find which test case
      # leaves stale controller VMs after cleanup.
      $templateObj->ListControllerVMs();
   }
   return $result;
};


########################################################################
#
# DeleteActiveController --
#     Method to delete the controller which used by vxlan logical switch.
#     method invokes Py layer's delete method from baseController.
#
# Input:
#     arrayOfControlerObjects: reference to array of controler objects
#     vWireObj: reference to the virtual wire object whose controller
#               will be deleted.
#
# Results:
#     A controller object,in case of success;
#     FAILURE, in case of failure.
#
# Side effects:
#     None
#
########################################################################

sub DeleteActiveController
{
   my $self = shift;
   my (undef, $arrayOfControlerObjects, $vWireObj) = @_;
   my $controller = $vWireObj->[0]->get_controller_based_on_vni(
                                                   $arrayOfControlerObjects);
   if ($controller eq 'FAILURE') {
      $vdLogger->Error("Failed to get controler info:" . Dumper($controller));
      return FAILURE;
   }

   my $controllerIP = $controller->get_ip();
   foreach my $controllerObj (@$arrayOfControlerObjects) {
      if ($controllerObj->get_ip() eq $controllerIP) {
         my $arraycontrollerObj;
         push(@$arraycontrollerObj, $controllerObj);
         my $result = $self->DeleteComponent($arraycontrollerObj);
         if ($result eq 'FAILURE') {
            $vdLogger->Error("Failed to delete controller " .
                              Dumper($controllerObj));
            return FAILURE;
         }

         return $controllerObj;
      }
   }

   return FAILURE;
};


########################################################################
#
# ChangeActiveControllerState --
#     Method to change the active controller state, like poweroff
#
# Input:
#     state: only poweroff supported now
#     arrayOfControlerObjects: reference to array of controler objects
#     vWireObj: reference to the virtual wire object whose controller
#               will be deleted.
#
# Results:
#     SUCCESS if succesfully changed the active controller state
#     FAILURE, in case of failure.
#
# Side effects:
#     None
#
########################################################################

sub ChangeActiveControllerState
{
   my $self = shift;
   my ($state, $arrayOfControlerObjects, $vWireObj) = @_;
   $state = lc($state);

   my $controller = $vWireObj->[0]->get_controller_based_on_vni(
                                                   $arrayOfControlerObjects);
   if ($controller eq 'FAILURE') {
      $vdLogger->Error("Failed to get controler info:" . Dumper($controller));
      return FAILURE;
   }

   my $result = $controller->ChangeVMState($state);
   return $result;
};


########################################################################
#
# DeleteVDNCluster --
#     Method to delete components/managed objects/entities
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called
#
# Results:
#     TBD TODO:
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub DeleteVDNCluster
{
   my $self                = shift;
   my $arrayOfPerlObjects  = shift;
   my $arrayOfCorrespondingArgs;
   foreach my $obj (@$arrayOfPerlObjects) {
      my $clusterMappingSpec->{resourceid} = $obj->{vccluster}->GetClusterMORId();
      my $arrayOfResourceConfig;
      push(@$arrayOfResourceConfig, $clusterMappingSpec);
      my $tempSpec->{resourceconfig} = $arrayOfResourceConfig;
      push(@$arrayOfCorrespondingArgs, $tempSpec);
   }
   return $self->DeleteComponent($arrayOfPerlObjects, $arrayOfCorrespondingArgs);
};


########################################################################
#
# AssignRoleToUser --
#     Method to assign a role to use of VSM
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub AssignRoleToUser
{
   my $self     = shift;
   my $spec     = shift;
   my $tempSpec->{accesscontrolentry}->{role} = $spec->{role} || "enterprise_admin";
   return $self->assign_role($tempSpec);
};


########################################################################
#
# GetCertThumbprint --
#     Method to get cert_thumbprint of VSM
#
# Input:
#
# Results:
#     thumbprint
#     return 'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetCertThumbprint
{
   my $self = shift;

   if ((defined $self->{certThumbprint}) && ($self->{certThumbprint} =~ /:/)) {
      return $self->{certThumbprint};
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'certificate.Certificate', $inlinePyObj);
       $self->{certThumbprint} = $inlinePyApplObj->get_thumbprint_sha1();
       $vdLogger->Debug("Thumbprint Certificate of VSM:" . $self->{ip} .
                        " is " . $self->{certThumbprint});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while restarting " .
                       " vsm in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $self->{certThumbprint};
}


########################################################################
#
# CreateApplianceVM --
#     Method to create VXLAN/VDR components .
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

sub CreateApplianceVM
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $onePerlObj         = undef;
   my @arrayOfPerlObjs      = ();
   my @originalPerlObjs     = ();
   my @arrayOfApplianceObjs = ();

   my $elementCount = @$arrayOfSpec;
   $vdLogger->Debug("Appliance VM count is ".$elementCount);
   # fix PR: 1219677
   my $allSuccess = 1;
   for (my $i =0; $i < $elementCount; $i++) {
      my @oneController = ();
      push @oneController, $arrayOfSpec->[$i];
      $onePerlObj = $self->CreateAndVerifyComponent($componentName,
                                                   \@oneController);
      if ((not defined $onePerlObj) or ($onePerlObj eq "FAILURE")) {
         $vdLogger->Error("Failed to create appliance VM");
         VDSetLastError(VDGetLastError());
         $allSuccess = 0;
         last;
      }
      # @arrayOfPerlObjs only save those succesfully deployed controllers
      push @arrayOfPerlObjs, $onePerlObj->[0];
   }

   # some of controllers in array deployed failed, thus we should delete
   # those succesfully deployed controllers also.
   if (0 == $allSuccess) {
      my $ret = $self->DeleteComponent(\@arrayOfPerlObjs);
      if ((not defined $ret) or ($ret eq "FAILURE")) {
         $vdLogger->Error("Failed to delete controller");
      } else {
         $vdLogger->Error("At least one of controller deploy failed," .
                          "remove all the successfully deployed " .
                          "controllers also");
      }
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   @originalPerlObjs = @arrayOfPerlObjs;

   for (my $i =0; $i < $elementCount; $i++){
      my $hostObj = $arrayOfSpec->[$i]->{host};
      my $perlObj = $arrayOfPerlObjs[$i];
      my $applianceObj = $perlObj->InitVxlanControllerVM($hostObj);
      if ((not defined $applianceObj) or
          ($applianceObj eq "FAILURE")) {
         $vdLogger->Error("Failed to init appliance with vm attributes");
         next;
      }
      push @arrayOfApplianceObjs, $applianceObj;
   }
   my @perlObjsAndApplianceObjs = (\@originalPerlObjs, \@arrayOfApplianceObjs);
   return \@perlObjsAndApplianceObjs;
}

########################################################################
#
# ChangeVSMState --
#     Method to restart vsm or other operations for vsm in the future
#
# Input:
#     operation   : restart
#
# Results:
#     SUCCESS in case of success
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ChangeVSMState
{
   my $self = shift;
   my $operation = shift;

   my $resultObj;

   if($operation ne "restart") {
      $vdLogger->Error("Currently only supports restart,
                 wrong operation passed in:".Dumper(\$operation));
      return FAILURE;
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'nsxapi_appliance_management.NSXAPIApplianceManagement',
                      $inlinePyObj);
       $resultObj = $inlinePyApplObj->restart();
       $vdLogger->Debug("Restart vsm with result".Dumper(\$resultObj));
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while restarting " .
                       " vsm in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($resultObj->{status_code} != '202') {
       $vdLogger->Error("Failed to restart vsm $self->{ip}");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("vsm $self->{ip} restart successfully");
   }
   return SUCCESS;
}


########################################################################
#
# SetNetworkFeatures --
#     Method to enable network features for ipdiscovery, maclearning
#     for dvportgroup/vwire
#
# Input:
#     Reference to array of hash
#
# Results:
#     Reference to an array
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub SetNetworkFeatures
{
   my $self = shift;
   my %args = @_;
   my $portgroup = $args{portgroup};
   my $componentName = "networkfeatures";
   my $spec;
   my @arrayOfSpec;
   my $templateObj;
   $spec->{network} = $portgroup->GetId();
   $spec->{networkfeatures} = $args{networkfeatures};
   push(@arrayOfSpec, $spec);
   my $type = $self->{type};
   my $componentInfo = $self->ComponentMap("networkfeatures", $type);
   my $componentClass = $componentInfo->{'perlClass'};
   eval "require $componentClass";
   if ($@) {
      $vdLogger->Error("Failed to load $componentClass $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   eval {
      $templateObj =
         $componentClass->new($componentInfo->{parentName} => $self);
      if ($templateObj eq FAILURE) {
         $vdLogger->Error("Failed to create an instance of $componentName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component $componentName instances:\n". $@);
      my @ret;
      return \@ret;
   }

   my $arrayOfPerlObjs = $templateObj->UpdateComponent($spec);

   if ((not defined $arrayOfPerlObjs) or ($arrayOfPerlObjs eq "FAILURE")) {
      $vdLogger->Error("Failed to create virtual wire");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


########################################################################
#
# ManageVxlanControllers --
#     Method to upgrade/downgrade vxlan controllers within a cluster
#
# Input:
#     vxlancontrollers : UPGRADE/DOWNGRADE(not support yet)
#
# Results:
#     SUCCESS in case of controller upgrade/downgrade finished
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ManageVxlanControllers
{
   my $self   = shift;
   my %params = @_;
   my $operation = uc($params{'vxlancontrollers'});
   my $result = undef;

   if ($operation ne "UPGRADE") {
      $vdLogger->Error("invalid operation, only support
                 'UPGRADE', but passed in: $operation");
      return FAILURE;
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'nsxapi_appliance_management.NSXAPIApplianceManagement',
                      $inlinePyObj);
       $result = $inlinePyApplObj->upgrade_controller();
       $vdLogger->Debug("Upgrade controllers within the cluster with result" .
                         "$result");
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while upgrade controllers " .
                       "in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $result;
}


######################################################################
#
# GetVxlanControllerUpgradeCapability --
#     Method to get vxlan controllers upgrade capability, whether they
#         support upgrade to the new version
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       capability  => undef,
#                     }
#                  ],
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVxlanControllerUpgradeCapability
{
   my $self           = shift;
   my $serverForm     = shift;
   my $result         = undef;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'nsxapi_appliance_management.NSXAPIApplianceManagement',
                      $inlinePyObj);
       $result = $inlinePyApplObj->query_controller_upgrade_capability();
       $result = uc($result);
   };
   if ($@) {
      my $errorInfo = "Exception thrown while query controllers upgrade capability" .
                       " in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = {capability => $result};
   return $resultHash;
}


######################################################################
#
# GetVxlanControllerUpgradeStatus --
#     Method to get vxlan controllers cluster upgrade status, or
#        specific controller upgrade status(if param 'controller' specified)
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       controllerupgradestatus  => undef,
#                     }
#                  ],
#     controllers : controllers list which user want to check upgrade status
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVxlanControllerUpgradeStatus
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllers    = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                              'nsxapi_appliance_management.NSXAPIApplianceManagement',
                              $inlinePyObj);
       if (defined $controllers) {
       # query specific controller upgrade status
          my $resultArray = $inlinePyApplObj->query_specific_controller_upgrade_status(
                                                        $controllers);
          my $elementCount = @$resultArray;
          if ($elementCount > 0) {
             $result = $resultArray->[0];
             for (my $i = 1; $i < $elementCount; $i++) {
                if ($resultArray->[$i] ne $resultArray->[$i-1]) {
                   $vdLogger->Error("controllers upgrade status are not all same " .
                                       "within all controllers list");
                   VDSetLastError("EOPFAILED");
                   $result = "NOT SAME";
                   last;
                }
             }
          }
       } else {
       # query controller cluster upgrade status
          $result = $inlinePyApplObj->query_controller_cluster_upgrade_status();
          $result = uc($result);
       }
   };
   if ($@) {
      if (defined $controllers) {
          $errorInfo = "Exception thrown while query specific controllers upgrade status" .
                           " in python";
      } else {
          $errorInfo = "Exception thrown while query controllers cluster upgrade status" .
                           " in python";
      }
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   #push @serverData, {'status'  => $result};
   $resultHash->{response} = {'status'  => $result};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# GetVxlanControllerDelayDivvy --
#     Method to get vxlan controllers delay divvy value during upgrade
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       divvy  => undef,
#                     }
#                  ],
#     controllers : controllers list which user want to check upgrade status
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVxlanControllerDelayDivvy
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllers    = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result    = undef;

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                              'nsxapi_appliance_management.NSXAPIApplianceManagement',
                              $inlinePyObj);
       # query specific controller upgrade status
       my $resultArray = $inlinePyApplObj->query_specific_controller_divvy_num(
                                                  $controllers);
       my $elementCount = @$resultArray;
       if ($elementCount > 0) {
          $result = $resultArray->[0];
          for (my $i = 1; $i < $elementCount; $i++) {
             if ($resultArray->[$i] ne $resultArray->[$i-1]) {
                $vdLogger->Error("controllers delay divvy num are not all same " .
                                    "within all controllers list");
                VDSetLastError("EOPFAILED");
                $result = "NOT SAME";
                last;
             }
          }
       }
   };
   if ($@) {
      my $errorInfo = "Exception thrown while query specific controllers delay divvy num" .
                           "in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'divvy' => $result};
   $resultHash->{status} = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# ExecuteRabbitMQCommand --
#     Method to execute rabbit mq command on vsm
#
# Input:
#     rabbitmq: 'start/stop'
#
# Results:
#     SUCCESS or FAILURE
#
# Side effects:
#     None
#
########################################################################
sub ExecuteRabbitMQCommand
{
   my $self   = shift;
   my %params = @_;
   my $result = SUCCESS;

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                              'rabbitmq.RabbitMQ',
                              $inlinePyObj);
       # Execute rabbitmq command in python
       my $result = $inlinePyApplObj->execute_command(
                                                  $inlinePyObj,
                                                  $self->{root_password},
                                                  $params{'rabbitmq'});
   };
   if ($@) {
      my $errorInfo = "Exception thrown while executing rabbitmq command on VSM" .
                       " in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      return 'FAILURE';
   }
   return $result;
}


######################################################################
#
# SetCmdOnController --
#     Method to set commands on vxlan controllers, like set divvy value
#
# Input:
#     setcmdoncontroller : feature that need to be configured, currently
#                           only 'divvy' supported.
#     controllers : controllers list which user want to set command on
#     value       : feature value
#
# Results:
#     SUCCESS if succesfully configured commands on all controllers
#     FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetCmdOnController
{
   my $self    = shift;
   my %params  = @_;
   my $feature = lc($params{'setcmdoncontroller'});
   my $controllers = $params{'controllers'};
   my $value   = $params{'value'};
   my $endPoint = $self->SetCmdEndPoint($feature);
   my $result  = undef;

   if ($endPoint eq "FAILURE") {
      $vdLogger->Error("invalid operation, only support
                 'divvy' yet, but passed in: $feature");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                              'nsxapi_appliance_management.NSXAPIApplianceManagement',
                              $inlinePyObj);
       $result = $inlinePyApplObj->set_cmd_on_controller($controllers,
                                                         $endPoint, $value);
   };
   if ($@) {
      my $errorInfo = "Exception thrown while set command on controller" .
                           "in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $result;
}


######################################################################
#
# SetCmdEndPoint --
#     Get the endpoint corresponding to the feature
#
# Input:
#     featue : feature that need to be configured, currently
#                           only 'divvy' supported.
#
# Results:
#     Corresponding end point to the feature.
#     FAILURE in case of any error.
#
# Side effects:
#     None
#
########################################################################

sub SetCmdEndPoint
{
   my $self    = shift;
   my $feature = shift;

   my %endPointHash = (
       'divvy' => "set control-cluster core cluster-param divvy_num_nodes_required",
   );

   if (exists ($endPointHash{$feature})) {
      return $endPointHash{$feature};
   } else {
      return FAILURE;
   }
}


########################################################################
#
# ReadDFWEvents --
#     Method to check if DFW 'cpu/memory/cps threshold crossed'
#     event occured
#
# Input:
#     None
#
# Results:
#     CPU/Memory/CPS threshold crossed event timestamps and count
#
########################################################################
sub ReadDFWEvents
{
   my $self = shift;
   my $checkevent = shift;
   my $timeout = shift;

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $inlinePyApplObj = CreateInlinePythonObject(
                           'system_event.SystemEvent',
                           $inlinePyObj);

   my $server_data = $inlinePyApplObj->read_dfw_events();

   my $resultHash = {
       'status' => 'SUCCESS',
       'response' => $server_data,
       'error' => undef,
       'reason' => undef,
   };

   return $resultHash;

}


########################################################################
#
# RegisterUnregisterNSXSlaves --
#     API to register/unregister NSX Slaves with replicator service on
#     NSX Master
#
# Input:
#     operation: register/unregister
#     arrayofVSMs: array of Slave VSM objects
#
# Results:
#     SUCCESS in case of controller upgrade/downgrade finished
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub RegisterUnregisterNSXSlaves
{
   my $self   = shift;
   my %params = @_;
   my $operation = uc($params{'replicator_registration'});
   my $result = undef;
   my $VSMs = $params{'managers'};
   foreach $_ (@$VSMs) {
      my @arrayofSpec = ($_) ;

      if ($operation eq "REGISTER") {
         $result = $self->CreateAndVerifyComponent("replicator_registration",
                                                          \@arrayofSpec);
         # If UUID of regisgerted slaves is required to store in Master
         # then we can do it here.
      } elsif ($operation eq "UNREGISTER") {
         # Create obj of ReplicatorRegistration and call DeleteComponent on it

      } elsif ($operation eq "UNREGISTER_ALL") {
         # Call DeleteComponent on this node. It will unregister all Slaves
         my $templateObj;
         my $type = 'vsm';
         my $componentInfo = $self->ComponentMap("replicator_registration", $type);
         my $componentClass = $componentInfo->{'perlClass'};
         eval "require $componentClass";
         if ($@) {
            $vdLogger->Error("Failed to load $componentClass $@");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         $templateObj =
            $componentClass->new($componentInfo->{parentName} => $self);
         if ($templateObj eq FAILURE) {
            $vdLogger->Error("Failed to create an instance of replicator_registration");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $templateObj->{id} = "";
         my @arrayOfPerlObjects = ($templateObj);
         $result = $self->DeleteComponent(\@arrayOfPerlObjects);
      } else {
         $vdLogger->Error("invalid operation, only support
                    'REGISTER and UNREGISTER', but passed: $operation");
         return FAILURE;

      }
   }
   return $result;
}


########################################################################
#
# GetPeerName --
#     Method to get the action key of peer tuples of this class
#
# Input:
#     None
#
# Results:
#     Name of action key of peer tuples of this class
#
# Side effects:
#     None
#
########################################################################

sub GetPeerName
{
   my $self = shift;
   return "nsxslave";
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
# GetUUID
#     Method to get uuid of VSM
#
# Input:
#
# Results:
#     uuid
#     return 'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################


sub GetUUID
{
   my $self = shift;

   if ((defined $self->{id}) && ($self->{id} =~ /-/)) {
      return $self->{id};
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'vsmconfig.VsmConfig', $inlinePyObj);
       $self->{id} = $inlinePyApplObj->get_uuid();
       $vdLogger->Debug("UUID of VSM:" . $self->{ip} . " is " . $self->{id});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while restarting " .
                       " vsm in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $self->{id};
}

########################################################################
#
# VerifyCliCommand --
#     Method to execute command on nsx manager
#
# Input:
#     command : which to be executed and verified on nsx manager
#     host    : the related host object
#     switch  : the related switch object
#     controllers : the related controller object
#
# Results:
#     A result hash containing the following attribute
#         status_code => SUCCESS/FAILURE
#         response    => array consisting of serverdata
#         error       => error code
#         reason      => error reason
#
# Side effects:
#     None
#
########################################################################


sub VerifyCliCommand
{
   my $self = shift;
   my $result = undef;
   my @serverData;
   my $resultHash = {
     'status' => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $command = $self->ProcessCliCommand(@_);
   eval {
      my $inlinePyObj = $self->GetInlinePyObject();
      my $inlinePyApplObj = CreateInlinePythonObject(
                             'centralized_cli.CentralizedCli',
                             $inlinePyObj);
      $result = $inlinePyApplObj->run_cli($command);
   };
   if ($@) {
      my $errorInfo = "Exception thrown while run $command on vsm in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   push @serverData, {'output' => $result};
   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


########################################################################
#
# ProcessCliCommand --
#     Method to process the command
#
# Input:
#     command : which to be executed and verified on nsx manager
#     host    : the related host object
#     switch  : the related switch object
#     controllers : the related controller object
#
# Results:
#     the processed command
#
# Side effects:
#     None
#
########################################################################


sub ProcessCliCommand
{
   my $self = shift;
   my (undef,$command,$hostObj,$controllerObj,$switchObj,$vseObj,$lifObj,
       $bridgeObj) = @_;

   if ($command =~ m/<host-ip>/i) {
      my $hostip = $hostObj->{hostIP};
      $command =~ s/<host-ip>/$hostip/ig;
   }

   if ($command =~ m/<host-id>/i) {
      my $hostid = $hostObj->GetMORId();
      $command =~ s/<host-id>/$hostid/ig;
   }

   if ($command =~ m/<vni-id>/i) {
      my $vxlanId = $switchObj->{vxlanId};
      $command =~ s/<vni-id>/$vxlanId/ig;
   }

   if ($command =~ m/<controller-id>/i) {
      my $controllerId = $controllerObj->{id};
      $command =~ s/<controller-id>/$controllerId/ig;
   }

   if ($command =~ m/<controller-ip>/i) {
      my $controllerip = $controllerObj->{vmIP};
      $command =~ s/<controller-ip>/$controllerip/ig;
   }

   if ($command =~ m/<vxlan-port>/i) {
      my $portid = $lifObj->Getdvport();
      $command =~ s/<vxlan-port>/$portid/ig;
   }

   if ($command =~ m/<ldr-name>/i) {
      my $inlinePyObj = $vseObj->GetInlinePyObject();
      my $edge = $inlinePyObj->get_edge();
      $command =~ s/<ldr-name>/$edge->{edgeAssistInstanceName}/ig;
   }

   if ($command =~ m/<ldr-id>/i) {
      my $inlinePyObj = $vseObj->GetInlinePyObject();
      my $edge = $inlinePyObj->get_edge();
      $command =~ s/<ldr-id>/$edge->{objectId}/ig;
   }

   if ($command =~ m/<lif-name>/i) {
      my $inlinePyObj = $lifObj->GetInlinePyObject();
      my $interface = $inlinePyObj->get_interface();
      $command =~ s/<lif-name>/$interface->{label}/ig;
   }

   if ($command =~ m/<bridge-name>/i) {
      my $switchinlinePyObj = $switchObj->GetInlinePyObject();
      my $switch = $switchinlinePyObj->read();
      my $inlinePyObj = $bridgeObj->GetInlinePyObject();
      my $bridge = $inlinePyObj->get_bridge($switch->{objectId});
      $command =~ s/<bridge-name>/$bridge->{name}/ig;
   }

   if ($command =~ m/<bridge-id>/i) {
      my $switchinlinePyObj = $switchObj->GetInlinePyObject();
      my $switch = $switchinlinePyObj->read();
      my $inlinePyObj = $bridgeObj->GetInlinePyObject();
      my $bridge = $inlinePyObj->get_bridge($switch->{objectId});
      $command =~ s/<bridge-id>/$bridge->{bridgeId}/ig;
   }

   $vdLogger->Info("processed cmd:" . Dumper($command));
   return $command;
}


########################################################################
#
# GetLogicalswitchList --
#     Method to get virtual logical switch list from vsm.
#
# Input:
#     None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetLogicalswitchList
{
   my $self        = shift;
   my $serverForm  = shift;
   my $hostPerlObj = shift;
   my $command;

   if (not defined $hostPerlObj) {
      $command = "show logical-switch list all";
   } else {
      my $hostid = $hostPerlObj->GetMORId();
      $command = "show logical-switch list host $hostid vni";
   }

   my $result = $self->RunCentralizedCliAndGetOutput($command,"vni-list");
   if ($result eq FAILURE) {
      $vdLogger->Error("run command: $command failed on vsm");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'switch_name' => $entry->{'name'},
                         'uuid' => $entry->{'uuid'},
                         'switch_vni' => $entry->{'vni'},
                         'name' => $entry->{'vdnscopename'},
                         'id' => $entry->{'vdnscopeid'}};
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# GetHostListForLogicalSwitch --
#     Method to get host list info of an virtual logical switch from vsm.
#
# Input:
#     None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################


sub GetHostListForLogicalSwitch
{
   my $self          = shift;
   my $serverForm    = shift;
   my $switchPerlObj = shift;
   my $vxlanid = $switchPerlObj->{vxlanId};
   my $command = " show logical-switch list vni $vxlanid host";
   my @serverData;

   my $result = $self->RunCentralizedCliAndGetOutput($command,"vni-hostlist");
   if ($result eq FAILURE) {
      $vdLogger->Error("run command: $command failed on vsm");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   foreach my $entry (@$result) {
      push @serverData, {'id' => $entry->{'id'},
                         'ipaddress' => $entry->{'ip'},
                         'switch_name' => $entry->{'vdsname'}};
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# RunCentralizedCliAndGetOutput --
#     Method to execute a centralized cli on vsm and analyze it's output.
#
# Input:
#     command: which to be executed on vsm
#     schematype: the schema type used to analyze the output
#
# Results:
#     Success: return cli's output in the format of assigned horizontal table.
#     FAILURE: Return FAILURE.
#
# Side effects:
#     None
#
########################################################################

sub RunCentralizedCliAndGetOutput
{
   my ($self,$command,$schematype) = @_;
   my $result;

   if ((not defined $command) or ($command eq "")) {
      $vdLogger->Error("command is not provided: $command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ((not defined $schematype) or ($schematype eq "")) {
      $vdLogger->Error("schematype is not provided: $schematype");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("run command: " . Dumper($command));
   eval {
      my $inlinePyObj = $self->GetInlinePyObject();
      my $inlinePyApplObj = CreateInlinePythonObject(
                             'centralized_cli.CentralizedCli',
                             $inlinePyObj);
      $result = $inlinePyApplObj->get_table($command,$schematype);
   };
   if ($@) {
      my $errorInfo = "Python exception thrown while running the
                       command $command on vsm: $self->{ip}";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $result;
}


########################################################################
#
# GetMacTable --
#     Method to get mac-table for virtual logical switch on controller
#     via vsm.
#
# Input:
#     targetObj: Object for which the mac-table will be retrieved
#     controllerObj: controller object
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetMacTable
{
   my ($self,undef,$targetObj,$controllerObj,$switchObj) = @_;
   my $command;
   my $schema_name = "mac-table";
   my $isHorizontal = "true";
   if ($targetObj =~ m/VDNetLib::Host::HostOperations/) {
      my $hostip = $targetObj->{hostIP};
      if (defined $controllerObj) {
         my $controllerip = $controllerObj->{vmIP};
         $command = "show logical-switch controller $controllerip host $hostip mac";
      } elsif (defined $switchObj) {
         my $vxlanid = $switchObj->{vxlanId};
         $command = "show logical-switch host $hostip vni $vxlanid mac";
         $schema_name = "mac-table-host";
         $isHorizontal = "false";
      } else {
         $vdLogger->Error("target is not provided:" . Dumper($targetObj));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } elsif ($targetObj =~ m/VDNetLib::VSM::NetworkScope::VirtualWire/) {
      my $vxlanid = $targetObj->{vxlanId};
      my $controllerip = $controllerObj->{vmIP};
      $command = "show logical-switch controller $controllerip vni $vxlanid mac";
   } else {
      $vdLogger->Error("target is not provided:" . Dumper($targetObj));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   if ($isHorizontal eq "true") {
      foreach my $entry (@$result) {
         push @serverData, {'switch_vni' => $entry->{'vni'},
                            'adapter_mac' => uc($entry->{'mac'})};
      }
   } else {
      if ($result) {
         my $macEntryListArray = $result->{macEntryList};
         foreach my $macEntryList (@$macEntryListArray) {
            my $macEntryArray = $macEntryList->{macEntry};
            foreach my $macentry (@$macEntryArray) {
               push @serverData, {'switch_vni' => $switchObj->{vxlanId},
                                  'adapter_mac' => uc($macentry->{'innerMac'}),
                                  'macentrycount' => $result->{macEntryCount}
                                  };
            }
         }
      }
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# GetArpTable --
#     Method to get arp-table for virtual logical switch on controller
#     via vsm.
#
# Input:
#     targetObj: the object which to get arp-table for
#     controllerObj: controller object
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetArpTable
{
   my ($self,undef,$targetObj,$controllerObj,$switchObj) = @_;
   my $command;
   my $schema_name = "arp-table";
   my $isHorizontal = "true";
   if ($targetObj =~ m/VDNetLib::Host::HostOperations/) {
      my $hostip = $targetObj->{hostIP};
      if (defined $controllerObj) {
         my $controllerip = $controllerObj->{vmIP};
         $command = "show logical-switch controller $controllerip host $hostip arp";
      } elsif (defined $switchObj) {
         my $vxlanid = $switchObj->{vxlanId};
         my $hostid = $targetObj->GetMORId();
         $command = "show logical-switch host $hostid vni $vxlanid arp";
         $schema_name = "arp-table-host";
         $isHorizontal = "false";
      } else {
         $vdLogger->Error("target is not provided:" . Dumper($targetObj));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } elsif ($targetObj =~ m/VDNetLib::VSM::NetworkScope::VirtualWire/) {
      my $vxlanid = $targetObj->{vxlanId};
      my $controllerip = $controllerObj->{vmIP};
      $command = "show logical-switch controller $controllerip vni $vxlanid arp";
   }

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   if ($isHorizontal eq "true") {
      foreach my $entry (@$result) {
         push @serverData, {'switch_vni' => $entry->{'vni'},
                            'ipaddress'  => $entry->{'ip'},
                            'adapter_mac' => uc($entry->{'mac'})};
      }
   } else {
      if ($result) {
         my $arpEntryListArray = $result->{arpEntryList};
         foreach my $arpEntryList (@$arpEntryListArray) {
            my $arpEntryArray = $arpEntryList->{arpEntry};
            foreach my $arpentry (@$arpEntryArray) {
               push @serverData, {'switch_vni' => $switchObj->{vxlanId},
                                  'adapter_mac' => uc($arpentry->{'mac'}),
                                  'ipaddress' => $arpentry->{'ip'},
                                  'macentrycount' => $result->{arpEntryCount}
                                  };
            }
         }
      }
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# GetControllers --
#     Method to get all controller's information via vsm.
#
# Input:
#     None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetControllers
{
   my $self  = shift;
   my $command = "show controller list all";
   my $schema_name = "controller";

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'name' => $entry->{'name'},
                         'ipaddress'  => $entry->{'ip'},
                         'state' => uc($entry->{'state'})};
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# GetVNIBrief --
#     Method to get all vni's brief information via vsm.
#
# Input:
#     None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVNIBrief
{
   my ($self,undef,$targetObj,$controllerObj) = @_;
   my $command;
   my $schema_name = "vni-brief";
   my $controllerip = $controllerObj->{vmIP};

   if ($targetObj =~ m/VDNetLib::Host::HostOperations/) {
      my $hostid = $targetObj->GetMORId();
      $command = "show logical-switch controller $controllerip host $hostid joined-vnis";
   } elsif ($targetObj =~ m/VDNetLib::VSM::NetworkScope::VirtualWire/) {
      my $vxlanid = $targetObj->{vxlanId};
      $command = "show logical-switch controller $controllerip vni $vxlanid brief";
   } else {
      $vdLogger->Error("target is not provided:" . Dumper($targetObj));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'switch_vni' => $entry->{'vni'},
                         'ipaddress'  => $entry->{'controller'},
                         'bum-replication'  => $entry->{'bum_replication'},
                         'arp-proxy'  => $entry->{'arp_proxy'},
                         'connections' => uc($entry->{'connections'})};
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}



########################################################################
#
# GetVNIConnection --
#     Method to get all connection information for vni via vsm.
#
# Input:
#     None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVNIConnection
{
   my ($self,undef,$switchObj,$controllerObj) = @_;
   my $vxlanid = $switchObj->{vxlanId};
   my $controllerip = $controllerObj->{vmIP};
   my $command = "show logical-switch controller $controllerip vni $vxlanid connection";
   my $schema_name = "connection";

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'ipaddress' => uc($entry->{'host_ip'})};
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# GetVTEPTable --
#     Method to get vtep-table for virtual logical switch on controller
#     via vsm.
#
# Input:
#     targetObj: the object which to get arp-table for
#     controllerObj: controller object
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVTEPTable
{
   my ($self,undef,$targetObj,$controllerObj,$switchObj) = @_;
   my $command;
   my $schema_name = "vtep-table";
   my $isHorizontal = "true";

   if ($targetObj =~ m/VDNetLib::Host::HostOperations/) {
      my $hostip = $targetObj->{hostIP};
      if (defined $controllerObj) {
         my $hostip = $targetObj->{hostIP};
         my $controllerip = $controllerObj->{vmIP};
         $command = "show logical-switch controller $controllerip host $hostip vtep";
      } elsif (defined $switchObj) {
         my $hostid = $targetObj->GetMORId();
         my $vxlanid = $switchObj->{vxlanId};
         $command = "show logical-switch host $hostid vni $vxlanid vtep";
         $schema_name = "vtep-table-host";
         $isHorizontal = "false";
      } else {
         $vdLogger->Error("target is not provided:" . Dumper($targetObj));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } elsif ($targetObj =~ m/VDNetLib::VSM::NetworkScope::VirtualWire/) {
      my $vxlanid = $targetObj->{vxlanId};
      my $controllerip = $controllerObj->{vmIP};
      $command = "show logical-switch  controller $controllerip vni $vxlanid vtep";
   } else {
      $vdLogger->Error("target is not provided:" . Dumper($targetObj));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $result = $self->RunCentralizedCliAndGetOutput($command,$schema_name);
   if ($result eq FAILURE) {
      return FAILURE;
   }

   my @serverData;
   if ($isHorizontal eq "true") {
      foreach my $entry (@$result) {
         push @serverData, {'switch_vni' => $entry->{'vni'},
                            'ipaddress' => $entry->{'ip'},
                            'adapter_mac' => uc($entry->{'mac'}),
                            'segmentid' => $entry->{'segment'}};
      }
   } else {
      if ($result) {
         my $vtepEntryListArray = $result->{vtepEntryList};
         foreach my $vtepEntryList (@$vtepEntryListArray) {
            my $vtepEntryArray = $vtepEntryList->{vtepEntry};
            foreach my $vtepentry (@$vtepEntryArray) {
               push @serverData, {'ipaddress' => $vtepentry->{'vtepip'},
                                  'segmentid' => $vtepentry->{'segmentid'}
                                 };
            }
         }
      }
   }

   return VDNetLib::Common::Result->new('status'   => SUCCESS,
                                        'response' => {'table' => \@serverData});
}


########################################################################
#
# RemovePTEP
#     Method to remove a PTEP from PTEP cluster
#
# Input:
#     key ptep
#     spec the delete configuration for ptep
#
# Results:
#     return SUCCESS, in case of success
#     return FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub RemovePTEP
{
   my $self = shift;
   my $key = shift;
   my $spec = shift;

   my $attributeMapping = $self->GetAttributeMapping();
   my $processedSpec = $self->ProcessSpec($spec, $attributeMapping);
   $vdLogger->Info("Removing PTEPs from PTEP cluster");
   my $result;

   eval {
       my $inlinePyObj = $self->GetInlinePyObject();
       my $inlinePyPTEPObj = CreateInlinePythonObject(
                      'ptep.PTEP',
                      $inlinePyObj);
       $result = $inlinePyPTEPObj->remove_ptep(@$processedSpec[0]);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while removing PTEP " .
                       " from PTEP cluster in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to remove PTEP from PTEP Cluster");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("successfully removed PTEP from PTEP cluster");
   }

   return SUCCESS;
}


########################################################################
#
# GetPTEPEndpointAttributes
#     Method to obtin PTEP schema attributes
#
# Input:
#     None
#
# Results:
#     return hash representation of ptep schema object
#     return FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPTEPEndpointAttributes
{
   my $self = shift;

   my $result;

   eval {
       my $inlinePyObj = $self->GetInlinePyObject();
       my $inlinePyPTEPObj = CreateInlinePythonObject(
                      'ptep.PTEP',
                      $inlinePyObj);
       $result = $inlinePyPTEPObj->read()->get_py_dict_from_object();
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while reading " .
                       " from PTEP cluster in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to read from PTEP Cluster");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   }

   return $result;
}


########################################################################
#
# ReadReplicatorServiceStatus--
#     API to read the status of replicator service
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

sub ReadReplicatorServiceStatus
{
   my $self           = shift;
   my $serverForm     = shift;
   my $result         = undef;
   my $inlinePyApplObj;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
      $inlinePyApplObj = CreateInlinePythonObject(
                             'replicator_status.ReplicatorStatus',
                             $inlinePyObj);
      $result = $inlinePyApplObj->read();
      $result = $result->{result};
   };
   if ($@) {
      my $errorInfo = "Exception thrown while reading replicator" .
                       " in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   # WORKAROUND(gaggarwal): PR 1396374
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = {'status'  => $result};
   return $resultHash;
}


########################################################################
#
# ReadReplicationStatus--
#     API to read the status of replication across all slave VSMs
#
# Input:
#     userStatus: VSM index
#
# Results:
#     SUCCESS in case of userStatus and serverStatus matches
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ReadReplicationStatus
{
   my $self           = shift;
   my $serverForm     = shift;
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
      $inlinePyApplObj = CreateInlinePythonObject(
                             'vsm_replication_status.ReplicationStatus',
                             $inlinePyObj);
      $result = $inlinePyApplObj->read();
      $resultForVerification = $result->get_py_dict_from_object();
   };
   if ($@) {
      my $errorInfo = "Exception thrown while reading replication" .
                       "status from vsm_replication_status";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $resultHash->{status}   = SUCCESS;
   $resultHash->{response} = $resultForVerification;
   return $resultHash;
}

########################################################################
#
# ReadEntityReplicationStatus--
#     API to read the status of replication for one entity
#
# Input:
#     userStatus: Object type and its id
#
# Results:
#     SUCCESS in case of userStatus and serverStatus matches
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ReadEntityReplicationStatus
{
   my $self           = shift;
   my $serverForm     = shift;
   my $parameters      = shift;
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
   my $object_id = $parameters->{'object_id'}->{'id'};
   my $object_type = $parameters->{'object_type'};
   eval {
      $inlinePyApplObj = CreateInlinePythonObject(
                             'vsm_universal_entity_replication_status.VSMUniversalEntityReplicationStatus',
                             $inlinePyObj);
      $result = $inlinePyApplObj->read($object_type, $object_id);
      $resultForVerification = $result->get_py_dict_from_object();
   };
   if ($@) {
      my $errorInfo = "Exception thrown while reading replication" .
                       "status from vsm_replication_status";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $resultHash->{status}   = SUCCESS;
   $resultHash->{response} = $resultForVerification;
   return $resultHash;
}


######################################################################
#
# get_global_bfd --
#     Method to get global BFD config parameters
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                       'bfd_enabled'  => undef,
#                       'probe_interval'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_global_bfd
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllers    = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject('bfd.BFD', $inlinePyObj);
       # get bfd status from python
       $result = $inlinePyApplObj->read();
   };
   if ($@) {
      $errorInfo = "Exception thrown while read global BFD params in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'bfd_enabled'    => $result->{bfdEnabled},
                              'probe_interval' => $result->{probeInterval}};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# get_tor_instance --
#     Method to get tor instances
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                       'name'  => undef,
#                       'description'  => undef,
#                       'connectionstatus'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_tor_instance
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllers    = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject('tor.TOR', $inlinePyObj);
       # get tor instances from python
       $result = $inlinePyApplObj->get_tor_instance();
   };
   if ($@) {
      $errorInfo = "Exception thrown while get TOR instances in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'name' => $entry->{'name'},
                         'description'  => $entry->{'description'},
                         'bfd_enabled' => $entry->{'bfdEnabled'},
                         'id'  => $entry->{'objectId'},
                         'status' => lc($entry->{'status'}),
                        };
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'table'    => \@serverData};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# get_tor_binding --
#     Method to get tor binding list
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                       'tor_id'  => undef,
#                       'tor_switch_name'  => undef,
#                       'tor_port_name'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_tor_binding
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllers    = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject('tor_binding.TORBinding', $inlinePyObj);
       # get tor binding from python
       $result = $inlinePyApplObj->get_tor_binding();
   };
   if ($@) {
      $errorInfo = "Exception thrown while get TOR binding in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'tor_id' => $entry->{'hardwareGatewayId'},
                         'tor_switch_name'  => $entry->{'switchName'},
                         'tor_port_name' => $entry->{'portName'},
                         'vlan'  => $entry->{'vlan'},
                         'switch_id' => $entry->{'virtualWire'},
                        };
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'table'    => \@serverData};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################
#
# get_ptep_cluster --
#     Method to get tor ptep cluster list
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                       'objectId'  => undef,
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_ptep_cluster
{
   my $self           = shift;
   my $serverForm     = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $result     = undef;
   my $errorInfo  = undef;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject('ptep.PTEP', $inlinePyObj);
       # get ptep cluster from python
       $result = $inlinePyApplObj->get_ptep_cluster();
   };
   if ($@) {
      $errorInfo = "Exception thrown while get PTEP cluster in python";
      $vdLogger->Error("$errorInfo:\n". $@);
      VDSetLastError("EOPFAILED");
      $resultHash->{reason} = $errorInfo;
      return $resultHash;
   }

   my @serverData;
   foreach my $entry (@$result) {
      push @serverData, {'id' => $entry->{'objectId'}};
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper($result));
   $resultHash->{response} = {'table'    => \@serverData};
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


########################################################################
#
# ReadReplicatorRole--
#     API to read the replication role on vsm
#
# Input:
#     userStatus: PRIMARY/SECONDARY/STANDALONE
#
# Results:
#     SUCCESS in case of userStatus and serverStatus matches
#     FAILURE in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ReadReplicatorRole
{
   my $self           = shift;
   my $serverForm     = shift;
   my $result         = undef;
   my $inlinePyApplObj;
   my $resultForVerification = undef;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
      $inlinePyApplObj = CreateInlinePythonObject(
                             'replicator_role.ReplicatorRole',
                             $inlinePyObj);
      $result = $inlinePyApplObj->read();
      $resultForVerification = $result->get_py_dict_from_object();
   };
   if ($@) {
      my $errorInfo = "Exception thrown while reading replicator" .
                       "role in python";
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


########################################################################
#
# GetNodeID
#     Method to get node id of VSM
#
# Input:
#
# Results:
#     node id
#     return 'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################


sub GetNodeID
{
   my $self = shift;

   if ((defined $self->{id}) && ($self->{id} =~ /-/)) {
      return $self->{id};
   }

   my $inlinePyObj = $self->GetInlinePyObject();
   if ($inlinePyObj eq 'FAILURE') {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   eval {
       my $inlinePyApplObj = CreateInlinePythonObject(
                      'vsmconfig.VsmConfig', $inlinePyObj);
       $self->{id} = $inlinePyApplObj->get_node_id();
       $vdLogger->Debug("Node ID of VSM:" . $self->{ip} . " is " . $self->{id});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while restarting " .
                       " vsm in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $self->{id};
}
1;
