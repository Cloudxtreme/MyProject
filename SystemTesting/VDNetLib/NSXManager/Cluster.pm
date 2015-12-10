########################################################################

# Copyright (C) 2014 VMWare, Inc.

# All Rights Reserved

########################################################################

package VDNetLib::NSXManager::Cluster;


use base  qw(VDNetLib::Root::Root VDNetLib::Root::GlobalObject);

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              CallMethodWithKWArgs);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);


########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::NSXManager::Cluster
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXManager::Cluster;
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
  $self->{_pyIdName} = 'id_';
  $self->{parentObj} = $args{parentObj};
  $self->{_pyclass} = 'vmware.nsx.manager.cluster.' .
                      'cluster_facade.ClusterFacade';
  bless $self;
  return $self;

}

########################################################################
#
# ChangeStateSynchNodeVMState --
#     Method to poweron/poweroff/suspend/resume cluster node VM;
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     state synch node object. It performs specified VM action on
#     state synch node object.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of manager which will be powered on/off
#     vmstate: A value of poweron/poweroff/suspend/resume;
#
# Results:
#     "SUCCESS", if the change VM state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ChangeStateSynchNodeVMState
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $vmState = shift;
   my $managerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {
         $managerObj = $perlObj;
      }
   }
   if (($managerObj->ChangeVMState($vmState)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $managerIP state to $vmState" .
                       Dumper($managerObj));
      return FAILURE;
   }
   $vdLogger->Info("Change the $managerIP state to $vmState successfully!");
   return SUCCESS;
}

########################################################################
#
# ChangeNonStateSynchNodeVMState --
#     Method to poweron/poweroff/suspend/resume cluster node VM;
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     non-state synch node object. It performs specified VM action on
#     non-state synch node object.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of manager which will be powered on/off
#     vmstate: A value of poweron/poweroff/suspend/resume;
#
# Results:
#     "SUCCESS", if the change VM state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ChangeNonStateSynchNodeVMState
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $vmState = shift;
   my $managerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} ne $managerIP) {
         $managerObj = $perlObj;
      }
   }
   if (($managerObj->ChangeVMState($vmState)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $managerIP state to $vmState" .
                       Dumper($managerObj));
      return FAILURE;
   }
   $vdLogger->Info("Change the $managerIP state to $vmState successfully!");
   return SUCCESS;
}


########################################################################
#
# NetworkPartitionStateSynchNode --
#     Method to block/unblock traffic from state synch node;
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes and finds out
#     state synch node object. It performs specified action on
#     state synch node object to block/unblock state synch node.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of state synch node
#     controllerObjs : reference to controller objects
#     operation: operation to block/unblock state synch node;
#
# Results:
#     "SUCCESS", if block/unblock traffic operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub NetworkPartitionStateSynchNode
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $controllerObjs = shift;
   my $operation = shift;
   my $managerObj;
   my $controllerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {
         $managerObj = $perlObj;
      }
   }

   foreach my $controllerObj (@$controllerObjs) {
      my $pyObj = $managerObj->GetInlinePyObject();
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $managerObj");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $method = 'node_network_partitioning';
      my $args->{'manager_ip'} = $controllerObj->{ip};
      $args->{'operation'} = $operation;
      $args->{'execution_type'} = 'cli';

      if ((CallMethodWithKWArgs($pyObj, $method, $args)) eq 'FAILURE') {
         $vdLogger->Error("Failed to change network partition setting" .
         " on $managerIP" . Dumper($self));
         return FAILURE;
      }
      $vdLogger->Info("Changed network partitioning between $managerIP" .
       " and $controllerObj->{ip} successfully!");
   }
   return SUCCESS;
}


########################################################################
#
# NetworkPartitionNonStateSynchNode --
#     Method to block/unblock traffic from non-state synch node;
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes and finds out
#     non-state synch node object. It performs specified action on
#     non-state synch node object to block/unblock state synch node.
#
# Input:
#     managerObjs : reference to manager objects
#     managerIP: IP address of state synch node
#     controllerObjs : reference to controller objects
#     operation: operation to block/unblock state synch node
#     allNonStateSynchNodes: whether to block all non-state synch nodes;
#
# Results:
#     "SUCCESS", if block/unblock traffic operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub NetworkPartitionNonStateSynchNode
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $controllerObjs = shift;
   my $allNonStateSynchNodes = shift;
   my $operation = shift;
   my $managerObj;
   my $controllerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {
         $managerObj = $perlObj;
      }
   }

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} ne $managerIP) {
         $managerObj = $perlObj;

         foreach my $controllerObj (@$controllerObjs) {
            my $pyObj = $managerObj->GetInlinePyObject();
            if ($pyObj eq "FAILURE") {
               $vdLogger->Error("Failed to get inline python object for $managerObj");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            my $method = 'node_network_partitioning';
            my $args->{'manager_ip'} = $controllerObj->{ip};
            $args->{'operation'} = $operation;
            $args->{'execution_type'} = 'cli';

            if ((CallMethodWithKWArgs($pyObj, $method, $args)) eq 'FAILURE') {
               $vdLogger->Error("Failed to change network partition setting" .
               " on $managerIP" . Dumper($self));
               return FAILURE;
            }
            $vdLogger->Info("Changed network partitioning between " .
             "$managerObj->{ip} and $controllerObj->{ip} successfully!");
         }

         if (!$allNonStateSynchNodes) {
            last;
         }

      }
   }

   return SUCCESS;
}

########################################################################
#
# ChangeMasterBrokerNodeVMState --
#     Method to poweron/poweroff/suspend/resume cluster node VM;
#     This method compares IP of specified state synch node with IP
#     addresses of all NSXManager nodes in cluster and finds out
#     master broker node object. It performs specified VM action on
#     master broker node object.
#
# Input:
#     endPointsPerlObjs : reference to manager objects
#     managerIP: IP address of manager which will be powered on/off
#     vmstate: A value of poweron/poweroff/suspend/resume;
#
# Results:
#     "SUCCESS", if the change VM state operation was successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ChangeMasterBrokerNodeVMState
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $managerIP = shift;
   my $vmState = shift;
   my $managerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $managerIP) {
         $managerObj = $perlObj;
      }
   }
   if (($managerObj->ChangeVMState($vmState)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $managerIP state to $vmState" .
                       Dumper($managerObj));
      return FAILURE;
   }
   $vdLogger->Info("Change the $managerIP state to $vmState successfully!");
   return SUCCESS;
}

1;
