########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXManager::NSXManager;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base qw(VDNetLib::Root::Root VDNetLib::VM::ESXSTAFVMOperations VDNetLib::Root::GlobalObject);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger
                                              CallMethodWithKWArgs);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     hostOpsObj  : reference to host object
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
   $self->{ip}       = $args{ip};
   $self->{user}     = $args{username};
   $self->{password} = $args{password};
   $self->{root_password} = $args{root_password};
   $self->{cert_thumbprint} = $args{cert_thumbprint};
   $self->{build} = $args{build};
   $self->{ui_ip} = $args{ui_ip};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.manager.manager_client.NSXManagerFacade';
   bless $self, $class;

   eval {
      my $inlineObj =  $self->GetInlinePyObject();
      $self->{id} = $inlineObj->get_node_id();
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while initializing NSXManager " .
                       " instance in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $self;
}

#####################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
##     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{ip},
                                              $self->{user},
                                              $self->{password},
                                              $self->{root_password},
                                              $self->{cert_thumbprint},
                                              $self->{build},
                                              $self->{ui_ip});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
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
   return "clusternode";
}

########################################################################
#
# GetNSXManagerLog --
#     Method to get NSX Manager logs (Tech support Bundle)

# Input:
#     LogDir : Log directory to which NSXManager logs have to be copied on master
#              controller.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetNSXManagerLog
{
   my $self = shift;
   my $logDir = shift;
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Destination dir for storing NSXManager logs not provided");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   my $className = 'VDNetLib::NSXManager::TechSupportBundleLog';
   eval "require $className";
   my $componentPerlObj = $className->new('parentObj' => $self);

   my $packageName = blessed $self;
   my $parentPyObj = $self->GetInlinePyObject();
   if ($parentPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $componentPyObj = $componentPerlObj->GetInlinePyObject($parentPyObj);
   if ($componentPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline python object $className");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $method = "create";
   my $args;
   $args->{logdir} = $logDir;

   $result = CallMethodWithKWArgs($componentPyObj, $method, $args);
   if ((defined $result) && ($result eq FAILURE)) {
      $vdLogger->Error("Create/discover $className returned FAILURE: " .
      Dumper(VDGetLastError()));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


######################################################################
#
# ReadNextHopGateway --
#     Method to get next hop edge vm object
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       edgevm_vdnet_index => undef
#                     }
#                  ],
#     edges: edge vm objects
#     adapter_label: network adapter
#     nexthopmapping: next hop ip address
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub ReadNextHopGateway
{
   my $self         = shift;
   my $serverForm   = shift;
   my $edgeVmObjs   = shift;
   my $adapterLabel = shift;
   my $nexthopIp    = shift;

   my $matched_edge_obj;
   OUTER:
   foreach my $edgeVmObj (@$edgeVmObjs) {
      my $arrayOfGuestNetInfo = $edgeVmObj->GetGuestNetInfo();
      if ($arrayOfGuestNetInfo eq FAILURE) {
         # edge vm may be powered off, so no guestnetinfo
         # will be returned
         $vdLogger->Warn("GetGuestNetInfo() failed for " .
                                "$edgeVmObj->{'vmName'}");
         next;
      }
      foreach my $element (@$arrayOfGuestNetInfo) {
         my %options = %$element;
         if ($options{'device_label'} eq $adapterLabel) {
            my %params = map { $_ => 1 } @{$options{'ipv4_array'}};
            if (exists($params{$nexthopIp})) {
               $matched_edge_obj = $edgeVmObj;
               last OUTER;
            }
         }
      }
   }
   if (not defined $matched_edge_obj) {
      $vdLogger->Error("No edge vm was found with nexthop ip, $nexthopIp");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Info("Succeeded to get next hop edge vm, ".
             "vm name is $matched_edge_obj->{'vmName'}");

   # store next_hop as array for
   # further ip migration verification
   my @next_hop_array;
   push @next_hop_array, $nexthopIp;
   my $resultHash = {
      'status'      => undef,
      'response'    => undef,
      'error'       => undef,
      'reason'      => undef,
   };
   my $serverData;
   $serverData->{'gateway'} = $matched_edge_obj;
   $serverData->{'next_hop_array'} = \@next_hop_array;
   $resultHash->{status} = SUCCESS;
   $resultHash->{response} = $serverData;
   return $resultHash;
}

1;
