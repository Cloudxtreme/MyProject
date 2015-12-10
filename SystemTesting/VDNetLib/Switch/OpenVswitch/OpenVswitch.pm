########################################################################
#  Copyright (C) 2013 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::OpenVswitch::OpenVswitch;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::NetAdapter::NetAdapter;

use VDNetLib::Switch::OpenVswitch::Port;

use constant NVS_FLOW_CTL => "nsx-flowctl-internal";
use constant NVS_VS_CTL => "nsx-dbctl-internal";
use constant NVS_DP_CTL => "nsx-dpctl-internal";
use constant NVS_APP_CTL => "nsx-appctl-internal";
use constant NVSCLI => "nsxcli";


########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     hostOpsObj  : reference to host object
#     switch      : name of the open vswitch
#     stafHelper  : reference to stafHelper object
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
   my $self = {
      'hostOpsObj'   => $args{'hostOpsObj'},
      'switch'       => $args{'switch'},
      'stafHelper'   => $args{'stafHelper'},
      'switchType'   => 'ovs', # having openvswitch will cause parsing
                               # confusion with vswitch? because, both
                               # match "vswitch"
   };

   bless $self;
   if (FAILURE eq $self->SetFailMode()) {
      $vdLogger->Error("Failed to set fail mode for the switch $args{'switch'}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self;
}


########################################################################
#
# AddBridge --
#     Method to add bridges on the instance of open vswitch
#
# Input:
#     Reference to array of hash with following keys:
#     name     : name of the bridge
#     bridge   : name of an existing bridge (cannot be used with 'name')
#
#
# Results:
#     Reference to an array of bridge objects
#     VDNetLib::Switch::OpenVswitch::Bridge
#
# Side effects:
#     None
#
########################################################################

sub AddBridge
{
   my $self          = shift;
   my $arrayOfSpecs  = shift;
   my @arrayOfObjects;
   foreach my $spec (@$arrayOfSpecs) {
      my $bridge = $spec->{bridge};
      my $name = $spec->{name};
      if (defined $bridge) {
         #check if exists
      } else {
         my $command = NVS_VS_CTL . " add-br $name";
      }

      my $bridgeObj = VDNetLib::Switch::OpenVswitch::Bridge->new();
      push (@arrayOfObjects, $bridgeObj);
   }
   return \@arrayOfObjects;
}


########################################################################
#
# DeleteBridge --
#     Method to delete given bridge
#
# Input:
#     Reference to array of bridge objects
#
# Results:
#     SUCCESS, if the bridges are deleted successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     The bridge won't be accessible after this operation
#
########################################################################

sub DeleteBridge
{
   my $self = shift;
   my $arrayOfObjects = shift;
   foreach my $bridgeObj (@$arrayOfObjects) {
      # NOT IMPLEMENTED

   }
   return SUCCESS;
}


########################################################################
#
# AddPorts --
#     Method to add ports
#
# Input:
#     Reference to array of hashes with following keys:
#     bridge         : name of the bridge
#     name           : name of the port
#     type           : port type
#     remotetunnel   : reference to remote tunnel interface
#                    (vmknic object)
#
# Results:
#     Reference to an array of VDNetLib::Switch::OpenVswitch::Port
#     objects;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddPorts
{
   my $self = shift;
   my $arrayOfSpecs  = shift;
   my @objArray;
   foreach my $spec (@$arrayOfSpecs) {
      my $bridge = $spec->{bridge};
      my $port = $spec->{name};
      my $intType = $spec->{type};
      my $remoteInterface = $spec->{remotetunnel};
      my $remoteIP = $remoteInterface->GetUplinkTunnelIP();
      my $command = NVS_VS_CTL . " add-port " . $bridge . " " .
                    $port . " -- set interface " . $port . " " .
                    "type=" . $intType . " options:remote_ip=" .
                    $remoteIP . " options:key=145";
      my $hostIP = $self->{hostOpsObj}{hostIP};
      $vdLogger->Info("Adding port on $hostIP: $command");
      my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                        $command);

      if (($result->{rc} != 0) || ($result->{exitCode})) {
         $vdLogger->Error("Failed to add port on $hostIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Create port objects
      my $portObj = VDNetLib::Switch::OpenVswitch::Port->new('portid' => $port,
                                          'switchObj' => $self,
                                          'stafHelper' => $self->{selfHelper});
      if ($portObj eq FAILURE) {
         $vdLogger->Error("Failed to get port object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push(@objArray, $portObj);
   }
   return \@objArray;
}


########################################################################
#
# DeletePorts --
#     Method to delete ports
#
# Input:
#     Reference to an array of port objects
#
# Results:
#     SUCCESS, if the bridges are deleted successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     These ports cannot be used anymore
#
########################################################################

sub DeletePorts
{
   my $self = shift;
   my $arrayofPorts = shift;
   foreach my $port (@$arrayofPorts) {
      my $command = NVS_VS_CTL . " del-port " . $port->{portid};
      $vdLogger->Debug("Deleting port: $command");
      my $hostIP = $self->{hostOpsObj}{hostIP};
      my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                        $command);

      # check for success or failure of the command executed using staf
      if (($result->{rc} != 0) || ($result->{exitCode})) {
         $vdLogger->Error("Failed to delete port on $hostIP");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# AddFlows --
#     Method to add flows
#
# Input:
#     Reference to an array of hashes with following keys:
#     destination : destination adapter (Netadapter object)
#     gateway     : gateway port on local switch (port object)
#     protocol    : reference to list of protocols with values
#                   ip/arp/tcp/ipv6/udp
#
# Results:
#     SUCCESS, if the flows are added successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub AddFlows
{
   my $self = shift;
   my $arrayOfSpecs  = shift;
   my @objArray;
   my $hostIP = $self->{hostOpsObj}{hostIP};
   foreach my $spec (@$arrayOfSpecs) {
      my $destinationAdapter = $spec->{destination};
      my $gatewayInterface = $spec->{gateway};
      my $ofpid = $gatewayInterface->GetOFPort();
      chomp($ofpid);
      my $protocol = $spec->{protocol};
      my $dstIP;
      foreach my $item (@$protocol) {
         if ($item =~ /ipv6/) {
            $dstIP = $destinationAdapter->GetIPv6();
         } else {
            $dstIP = $destinationAdapter->GetIPv4();
         }
         my $command = NVS_FLOW_CTL . " add-flow " . "br-int " .
            $item . ",nw_dst=" . $dstIP .
            ",actions=output:" . $ofpid;

         $vdLogger->Info("Adding flow on $hostIP: $command");
         my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                           $command);

         if (($result->{rc} != 0) || ($result->{exitCode})) {
            $vdLogger->Error("Failed to add flow " . $command . " on $hostIP");
            $vdLogger->Debug(Dumper($result));
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureUplinks --
#     Method to configure uplinks on the given switch
#
# Input:
#     action:        add/edit/delete
#     vmnicArrayRef: reference to vmnic/netadapter objects
#     executionType: api/cli
#     ipv4address  : ip address to configure on the uplink
#                    (for action:edit)
#
# Results:
#     SUCCESS, if the uplinks are configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureUplinks
{
   my $self = shift;
   my $action = shift;
   my $vmnicArrayRef = shift;
   my $executionType = shift;
   my $ipv4address   = shift;
   if ($action eq "edit") {
      return $self->EditUplinks($vmnicArrayRef, $ipv4address);
   }
   $action = ($action eq "add") ? "connect" : "disconnect";
   my $hostIP = $self->{hostOpsObj}{hostIP};
   foreach my $vmnic (@$vmnicArrayRef) {
      my $command = NVSCLI . " uplink/" . $action .
                    " " . $vmnic->{interface};
      $vdLogger->Debug("Configure uplink: $command");
      my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                        $command);

      if (($result->{rc} != 0) || ($result->{exitCode})) {
         $vdLogger->Error("Failed to $action uplink " . $command .
                          " on $hostIP");
         $vdLogger->Debug(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# EditUplinks --
#     Method to edit uplink configuration on the switch
#
# Input:
#     vmnicArrayRef: reference to vmnic/netadapter objects
#     ipv4address  : ip address to configure on the uplink
#                    (for action:edit)
#
#
# Results:
#     SUCCESS, if the uplinks are configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub EditUplinks
{
   my $self = shift;
   my $vmnicArrayRef = shift;
   my $ipv4address      = shift;
   foreach my $vmnic (@$vmnicArrayRef) {
      if (FAILURE eq $self->ConfigureUplinkIP($vmnic->{interface}, $ipv4address)) {
         $vdLogger->Error("Failed to edit $vmnic->{interface} configuration");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureUplinkIP --
#     Method to configure ip address on the switch's uplink
#
# Input:
#     uplink: uplink/vmnic interface name
#     ipv4  : ipv4 address
#
# Results:
#     SUCCESS, if the uplink ip address is configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureUplinkIP
{
   my $self  = shift;
   my $uplink = shift;
   my $ipv4   = shift || "dhcp";

   my $hostIP = $self->{hostOpsObj}{hostIP};
   my $command;
   if ($ipv4 ne "none") {
      $command = NVSCLI . " uplink/set-ip " .
         $uplink . " " . $ipv4;
   } else {
      $command = NVSCLI . " uplink/clear-ip " .
         $uplink;
   }
   $vdLogger->Debug("Configure IP: $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode})) {
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}




########################################################################
#
# SetFailMode --
#     Method to configur fail mode on the switch
#
# Input:
#     mode: standalone or secure (optional)
#
# Results:
#     SUCCESS, if fail mode is configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetFailMode
{
   my $self = shift;
   my $mode = shift || "standalone";
   my $host = $self->{hostOpsObj}{hostIP};
   my $command = "nsx-dbctl set bridge br-int fail-mode=$mode";
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to configure fail mode $mode on $host");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureController --
#     Method to configure nsx controller/manager on switch
#
# Input:
#     action    : set/clear (Required)
#     controller: ip address of the controller (Required)
#     protocol  : ssl or tcp (Optional, default ssl)
#
# Results:
#     SUCCESS, if the controlle is configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureController
{
   my $self       = shift;
   my $action     = shift;
   my $controller = shift;
   my $protocol   = shift || "ssl";

   my $host = $self->{hostOpsObj}{hostIP};
   my $command = "nsxcli manager/";
   $command .= ($action =~ /set/i) ? "set $protocol\:$controller->{ip}" : "clear";
   $vdLogger->Info("Setting nsx controller: $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to $action controller $controller on $host");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# MigrateUplinks --
#     Method to migrate vmknic/uplinks to/from this NVS
#
# Input:
#     Named parameters with following keys:
#     operation: rollback/migrate
#     uplinks  : reference to an array of Vmnic objects
#     services : comma separated list of services like mgmt/vmotion
#     vmknics  : reference to an array of Vmknic objects
#
# Results:
#     SUCCESS, if the uplinks are migrated successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     Moving uplinks will affect the ports on the switch that was
#     originally using it
#
########################################################################

sub MigrateUplinks
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{'migrateuplinks'};
   my $uplinks   = $args{'vmnicadapter'};
   my $services  = $args{'services'};
   my $vmknics   = $args{'vmknics'};
   my $vmnicList = "";
   my $command = "nsxcli vmknic";
   if ($operation =~ /rollback/i) {
      return $self->Rollback($uplinks);
   } else {
      return $self->MigrateToNVS(uplinks  => $uplinks,
                                 services =>$services,
                                 vmknics  => $vmknics);
   }
}


########################################################################
#
# MigrateToNVS --
#     Method to migrate vmknic/uplinks to this NVS
#
# Input:
#     Named parameters with following keys:
#     uplinks  : reference to an array of Vmnic objects
#     services : comma separated list of services like mgmt/vmotion
#     vmknics  : reference to an array of Vmknic objects
#
# Results:
#     SUCCESS, if the uplinks are migrated successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     Moving uplinks will affect the ports on the switch that was
#     originally using it
#
########################################################################

sub MigrateToNVS
{
   my $self     = shift;
   my %args = @_;
   my $uplinks   = $args{'uplinks'};
   my $services  = $args{'services'};
   my $vmknics   = $args{'vmknics'};

   my $command = "nsxcli vmknic/migrate";
   if (defined $services) {
      $command .= " service=$services";
   }
   my $vmknicList = "";
   my $vmnicList = "";
   if (defined $vmknics) {
      foreach my $vmknic (@$vmknics) {
         $vmknicList = join(",", $vmknic->{deviceId});
      }
     $command .= " vmknic=$vmknicList";
   }
     #$command .= " vmknic=vmk0";
   foreach my $uplink (@$uplinks) {
      $vmnicList = join(",", $uplink->{interface});
   }
   $command .= " uplink=$vmnicList";
   $vdLogger->Info("Setting nsx controller: $command");
   my $host = $self->{hostOpsObj}{hostIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to migrate on $host");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   foreach my $uplink (@$uplinks) {
   my $uplinkInfo = $uplink->GetUplinkInfo();
      my $found = 0;
      my $uplinkName = $uplink->{interface};
      foreach my $existingUplink (@$uplinkInfo) {
         if ($existingUplink->{name} eq $uplinkName) {
            $found = 1;
         }
      }
      if (!$found) {
         $vdLogger->Warn("Uplink $uplinkName is not migrated to NVS on $host");
      }
   }
   return SUCCESS;
}


########################################################################
#
# Rollback --
#     Method to rollback vmknic/uplinks from this NVS
#     to previous configuration
#
# Input:
#     uplinks  : reference to an array of Vmnic objects
#                that are expected to be migrated
#
# Results:
#     SUCCESS, if the uplinks are rollbacked successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     Moving uplinks will affect the ports on that were relying
#     on these uplinks and services
#
########################################################################

sub Rollback
{
   my $self    = shift;
   my $uplinks = shift;
   my $command = "nsxcli vmknic/rollback";
   $vdLogger->Info("Rollback vmknic/uplink on NVS: $command");
   my $host = $self->{hostOpsObj}{hostIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to migrate on $host");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   foreach my $uplink (@$uplinks) {
   my $uplinkInfo = $uplink->GetUplinkInfo();
      my $found = 0;
      my $uplinkName = $uplink->{interface};
      foreach my $existingUplink (@$uplinkInfo) {
         if ($existingUplink->{name} eq $uplinkName) {
            $found = 1;
         }
      }
      if ($found) {
         $vdLogger->Warn("Uplink $uplinkName is not migrated to NVS on $host");
      }
   }
   return SUCCESS;
}
1;
