########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXManager::NSXService;

use strict;
use warnings;
use Data::Dumper;

use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              CallMethodWithKWArgs);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);


########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::NSXService
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::NSXService;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.appliancemanagement.'.
   'nodeservices.nodeservices_facade.NodeServicesFacade';
   bless $self;
   return $self;
}

########################################################################
#
# ConfigureServiceStateOnStateSynchNode --
#     Method to start/stop/restart service on state synch node.
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     state synch node object. It performs specified service action on
#     state synch node object.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of state synch node
#     serviceName: Name of service on which action will be performed
#     serviceState: Service state to be configured
#
# Results:
#     "SUCCESS", if the change service state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ConfigureServiceStateOnStateSynchNode
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $serviceName = shift;
   my $serviceState = shift;
   my $serviceParentObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {
         $serviceParentObj = $perlObj;
      }
   }

   my $parentPyObj = $serviceParentObj->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for" .
                       "$serviceParentObj");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $self");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $method = 'configure_service_state';
   my $args->{'service_name'} = $serviceName;
   $args->{'state'} = $serviceState;

   if ((CallMethodWithKWArgs($pyObj, $method, $args)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $serviceName state to $serviceState" .
                       Dumper($self));
      return FAILURE;
   }
   $vdLogger->Info("Change the $serviceName state to $serviceState successfully!");
   return SUCCESS;
}

########################################################################
#
# ConfigureServiceStateOnNonStateSynchNode --
#     Method to start/stop/restart service on non-state synch node.
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     non-state synch node object. It performs specified service action on
#     non-state synch node object.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of state synch node
#     serviceName: Name of service on which action will be performed
#     serviceState: Service state to be configured
#
# Results:
#     "SUCCESS", if the change service state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ConfigureServiceStateOnNonStateSynchNode
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $serviceName = shift;
   my $serviceState = shift;
   my $serviceParentObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} ne $managerIP) {
         $serviceParentObj = $perlObj;
      }
   }
   $vdLogger->Info("Non-state synch node selected for action: $serviceParentObj->{ip}");

   my $parentPyObj = $serviceParentObj->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for" .
                       "$serviceParentObj");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $self");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $method = 'configure_service_state';
   my $args->{'service_name'} = $serviceName;
   $args->{'state'} = $serviceState;

   if ((CallMethodWithKWArgs($pyObj, $method, $args)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $serviceName state to $serviceState" .
                       Dumper($self));
      return FAILURE;
   }
   $vdLogger->Info("Change the $serviceName state to $serviceState successfully!");
   return SUCCESS;
}

########################################################################
#
# ConfigureServiceStateOnMasterBrokerNode --
#     Method to start/stop/restart service on master broker node.
#     This method compares IP of specified master broker node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     master broker node object. It performs specified service action on
#     master broker node object.
#
# Input:
#     endPointsPerlObjs : reference to manager objects
#     managerIP: IP address of master broker node
#     serviceName: Name of service on which action will be performed
#     serviceState: Service state to be configured
#
# Results:
#     "SUCCESS", if the change service state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ConfigureServiceStateOnMasterBrokerNode
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $serviceName = shift;
   my $serviceState = shift;
   my $serviceParentObj;

   if (not defined $endPointsPerlObjs){
      $vdLogger->Error("endPointsPerlObjs: reference to manager objects is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {

         $serviceParentObj = $perlObj;
         $vdLogger->Debug("match found for $managerIP");
      }
   }
   $vdLogger->Info("Master broker node selected for action: $serviceParentObj->{ip}");

   my $parentPyObj = $serviceParentObj->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for" .
                       "$serviceParentObj");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $self");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $method = 'configure_service_state';
   my $args->{'service_name'} = $serviceName;
   $args->{'state'} = $serviceState;

   if ((CallMethodWithKWArgs($pyObj, $method, $args)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $serviceName state to $serviceState" .
                       Dumper($self));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Change the $serviceName state to $serviceState successfully!");
   return SUCCESS;
}

1;
