########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXManager::LogicalSwitch;

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
#     Constructor to create an instance of this class
#
# Input:
#     None
#
# Results:
#     bless hash reference to instance of this class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{parentObj} = $args{parentObj};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.logical_switch.' .
                       'logical_switch_facade.LogicalSwitchFacade';
   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{parentObj} = $args{parentObj};
   bless $self;
   return $self;
}

########################################################################
#
# GetInlinePortgroupObject --
#       Method to get inline java object for logical switch
#
# Input:
#       NOne
#
# Results:
#       Instance of VDNetLib::InlineJava::Portgroup::NSXNetwork
#
# Side effects:
#       None
#
########################################################################

sub GetInlinePortgroupObject
{
    my $self = shift;
    return VDNetLib::InlineJava::Portgroup::NSXNetwork->new(
                                                'name' => $self->{'network'},
                                                'id'  => $self->{'id'},
                                                'type' => "logicalSwitch");
}

########################################################################
#
# GetId --
#     Method to get id of the logical switch
#
# Input:
#     None
#
# Results:
#     id of the logical switch
#
# Side effects:
#     None
#
########################################################################

sub GetId
{
   my $self   = shift;
   return $self->{'id'};
}
######################################################################
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
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $parentObj = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass}, $parentObj,
                                              $self->{id});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   return $inlinePyObj;
}


######################################################################
#
# ReadSwitchCCPMapping --
#     Method to get master ccp node for given logical switch,
#     it will be used for verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       master_ccp_ip     => undef
#                       slave_ccp_$slaveCCPIndex_ip     => undef
#                     }
#                  ],
#     controllerObjs: reference to controller objects
#     switchvni: the vni of logical switch
#     executionType: cli
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub ReadSwitchCCPMapping
{
   my $self           = shift;
   my $serverForm     = shift;
   my $endPointsPerlObjs = shift;
   my $executionType = shift;
   my $switchVNI = shift;
   my @arrayOfNodes;
   my $resultHash = {
      'status'      => undef,
      'response'    => undef,
      'error'       => undef,
      'reason'      => undef,
   };
   foreach my $perlObj (@$endPointsPerlObjs) {
      my $parentPyObj;
      if (exists $perlObj->{parentObj}) {
         my $parentPerlObj = $perlObj->{parentObj};
         $parentPyObj = $parentPerlObj->GetInlinePyObject();
         if ($parentPyObj eq "FAILURE") {
            $vdLogger->Error("Failed to get inline python object for" .
                             "$parentPerlObj");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }
      my $pyObj = $perlObj->GetInlinePyObject($parentPyObj);
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $perlObj");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfNodes, $pyObj;
   }

   my $args->{'endpoints'} = \@arrayOfNodes;
   $args->{'execution_type'} = $executionType;
   $args->{'switch_vni'} = $switchVNI;

   my $parentPerlObj = $self->{parentObj};
   my $parentPyObj = $parentPerlObj->GetInlinePyObject();
   my $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("We got pyObj, now executing read method");
   my $responseData;
   my $method = 'read_switch_ccp_mapping';
   my $masterCCPIP = CallMethodWithKWArgs($pyObj, $method, $args);
   if ((defined $masterCCPIP) && ($masterCCPIP eq FAILURE)) {
      $vdLogger->Error("Read component returned FAILURE: " .
                       Dumper(VDGetLastError()));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $slaveCCPIndex = 1;
   my $serverData;
   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $masterCCPIP) {
         $vdLogger->Info("The logical switch $switchVNI master CCP node" .
                         "is $perlObj->{ip},tuple is $perlObj->{'objID'}");
         $serverData->{'master_ccp_ip'} = $masterCCPIP;
      } else {
         $vdLogger->Info("The logical switch $switchVNI slave CCP node " .
                         "$slaveCCPIndex is $perlObj->{ip}," .
                         "tuple is $perlObj->{'objID'}");
         $serverData->{"slave_ccp_" . $slaveCCPIndex . "_ip"} = $perlObj->{ip};
         $slaveCCPIndex++;
      }
   }

   $vdLogger->Info("Read logical switch master ccp successfully");
   $resultHash->{status} = "SUCCESS";
   $resultHash->{response} = $serverData;
   return $resultHash;
}


########################################################################
#
# ChangeControllerVMState --
#     Method to poweron/poweroff/suspend/resume specified controller VM;
#
# Input:
#     controllerObjs: reference to controller objects
#     controllerIP: IP address of controller which will be powered on/off
#     vmstate: A value of poweron/poweroff/suspend/resume;
#
# Results:
#     "SUCCESS", if the controller VM was successfully powered on.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ChangeControllerVMState
{
   my $self           = shift;
   my $endPointsPerlObjs = shift;
   my $controllerIP = shift;
   my $vmState = shift;
   my $controllerObj;

   foreach my $perlObj (@$endPointsPerlObjs) {
      if ($perlObj->{ip} eq $controllerIP) {
         $controllerObj = $perlObj;
      }
   }
   if (($controllerObj->ChangeVMState($vmState)) eq 'FAILURE') {
      $vdLogger->Error("Failed to change the $controllerIP state to $vmState" .
                       Dumper($controllerObj));
      return FAILURE;
   }
   $vdLogger->Info("Change the $controllerIP state to $vmState successfully!");
   return SUCCESS;
}
1;
