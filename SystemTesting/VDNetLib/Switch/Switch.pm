########################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Switch::Switch;

#
# This package is the entry point for interaction with  different
# types of switches. Different switches includes vNetwork Standard
# Switch, vNetwork Distributed Switch, Cisco N1KV, Physcial switches.
# In other words, this package is a wrapper to all switch packages
# written with different method names, attributes.
#
# NOTE
#  this is copied from the VDNetLib::vSwitchConfig. The older version
#  is still there and would continue to work for the time being,
#  eventually this would be the one used moving forward.
#
#
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );

use VDNetLib::Switch::PSwitch::PSwitch;
use VDNetLib::Switch::TORSwitch::TORSwitch;
use VDNetLib::Switch::TORSwitch::TORPort;
use VDNetLib::Switch::VDSwitch::VDSwitch;
use VDNetLib::Switch::VSSwitch::VSSwitch;
use VDNetLib::Switch::VSSwitch::PortGroup;
use VDNetLib::Switch::VDSwitch::DVPortGroup;
use VDNetLib::Switch::VDSwitch::DVPort;
use VDNetLib::Switch::VMNetSwitch::VMNetSwitch;
use VDNetLib::Switch::OpenVswitch::Network;

########################################################################
#
# new --
#      This method is the entry point to this package.
#
# Input:
#      A named parameter hash with following keys:
#      'switch' : Name/identifier of the switch (Required)
#      'switchType' : "vswitch" or "dvs" (Required)
#                       (This are currently supported types. Will be
#                       extended when including additional switches)
#      'host'       : IP address of the host or switch itself which is
#                      required to access and configure the switch.
#      'switchAddress': Name or IP address of the switch (for physical
#                       switch and for vds in some cases).
#      'datacenter': name of the vc datacenter, required for the
#                    vds case.
#      'vcObj'     : Reference to the vcOperation object (required
#                    for the vds).
#
# Results:
#      None
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $switch = $args{'switch'};
   my $switchType =  $args{'switchType'};
   my $username = $args{'username'};
   my $password =  $args{'password'};
   my $host = $args{'host'};
   my $vswitchObj;
   my $pswitchObj;
   my $torSwitchObj;
   my $vdswitchObj;
   my $self;

   if (not defined $switchType) {
      $vdLogger->Error("switch Type not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # switch name is must for the vds and vSS.
   if ($switchType !~ /pswitch/i) {
      if (not defined $switch) {
         $vdLogger->Error("name of the switch must be ".
                          "defined for vSS and vDS");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   #
   # the vc information and datacenter name must be specified
   # for the vds case.
   #
   if ($switchType =~ /vdswitch/i) {
      if (not defined $args{vcObj}) {
          $vdLogger->Error("name or the vcObj must be defined ".
                          "for vDS");
          VDSetLastError("ENOTDEF");
          return FAILURE;
      }
      if (not defined $args{datacenter}) {
         $vdLogger->Error("Switch : Datacenter name not defined");
          VDSetLastError("ENOTDEF");
          return FAILURE;
      }
   }

   #
   # ip address or hostname of the physical switch must
   # be specified if switch type is physical switch.
   #
   if ($switchType =~ /pswitch/i) {
      if (not defined $args{switchAddress}) {
         $vdLogger->Error("Address of the switch must be ".
                          "specified for the physical switch");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   $self = {
      'name' => $switch,
      'switchType' => $switchType,
      'stafHelper' => $args{'stafHelper'},
      'hostOpsObj' => $args{'hostOpsObj'},
      'switchAddress' => $args{'switchAddress'},
      'type' => $args{'type'},
      'vcObj' => $args{'vcObj'},
      'datacenter' => $args{'datacenter'},
   };

   #
   # Based on the switch type, create appropriate object and store it in
   # 'switchObj' attribute.
   #
   if ($switchType =~ /vswitch/i) {
      $vswitchObj = VDNetLib::Switch::VSSwitch::VSSwitch->new(
                                                    host => $host,
                                                    switch => $self->{name},
                                                    hostOpsObj => $self->{'hostOpsObj'}
                                                    );
      if ($vswitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create ".
                      "VDNetLib::Switch::VSSwitch::VSSwitch".
                       " object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{'switchObj'} = $vswitchObj;
   }

   if ($switchType =~ /pswitch/i) {
      $pswitchObj = VDNetLib::Switch::PSwitch::PSwitch->new(
                                                NAME => $self->{switchAddress},
                                                TRANSPORT => $self->{transport},
                                                TYPE => $self->{type},
                                                username => $username,
                                                password => $password,
                                                );
      if ($pswitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create PSwitch object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{'switchObj'} = $pswitchObj;
   }

   if ($switchType =~ /torswitch/i) {
      if (not defined $args{'torGatewayObj'}) {
         $vdLogger->Error("TORSwitch must has the TOR Gateway object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $torSwitchObj = VDNetLib::Switch::TORSwitch::TORSwitch->new(
                                        name => $self->{name},
                                        torGatewayObj => $args{'torGatewayObj'},
                                        );
      if ($torSwitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create TORSwitch object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{'switchObj'} = $torSwitchObj;
   }

   if ($switchType =~ /vdswitch/i) {
      $vdswitchObj = VDNetLib::Switch::VDSwitch::VDSwitch->new(
                                                           switch => $switch,
                                                           vcObj => $self->{vcObj},
                                                           datacenter => $self->{datacenter}
                                                           );
      if ($vdswitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create vDS switch object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{switchObj} = $vdswitchObj;
   }

   if ($switchType =~ /vmnet/i) {
      $vswitchObj = VDNetLib::Switch::VMNetSwitch::VMNetSwitch->new(
                                                    host => $host,
                                                    switch => $self->{name},
                                                    hostOpsObj => $self->{'hostOpsObj'}
                                                    );
      if ($vswitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create ".
                      "VDNetLib::Switch::VMNetSwitch::VMNetSwitch".
                       " object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{'switchObj'} = $vswitchObj;
   }
   #
   # Create a VDNetLib::STAFHelper object with default options
   # if reference to this object is not provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

#   $self->{name} = $self->{'switch'};
   bless ($self,$class);
   return $self;
}


########################################################################
#
# SetMTU --
#      This method is used to configure the MTU size on the switch
#      object. As mentioned in the package description, this is wrapper
#      method to configure MTU on type of switch.
#
# Input:
#      mtu: MTU size to be set (Required)
#
# Results:
#      "SUCCESS", if MTU is configured successfully on the switch;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub SetMTU
{
   my $self     = shift;
   my $mtuValue = shift;
   my $result;

   if (not defined $mtuValue) {
      $vdLogger->Error("MTU value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchMTU($mtuValue);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }
   # for vds.
   if ($self->{switchType} =~/vdswitch/) {
      $result = $self->{switchObj}->SetVDSMTU(MTU => $mtuValue);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set mtu $mtuValue for vds");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }
}


########################################################################
#
# Enable CDP --
#      This method Enables cdp on the specified switch, for vSwitch and
#      vDS one needs to specify mode either listen, advertisement and
#      both. For physical switch the cdp global state is enabled.
#
#
# Input:
#      MODE
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the cdp state gets enabled for the switch.
#
########################################################################

sub EnableCDP
{
   my $self = shift;
   my $mode = shift;
   my $result = undef;
   my $pswitchObj;

   #
   # mode can only have listen, advertisement, both or down.
   #
   if ($mode !~ /advertise|listen|both|down|none/i) {
      $vdLogger->Error("Incorrect parameter $mode, The valid ".
                       "values are advertise, listen, both and down");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # if switch is a physical switch then enable
   # cdp global state.
   #
   if ($self->{switchType} =~ /pswitch/i) {
      $pswitchObj = $self->{switchObj};
      $result = $pswitchObj->{EnableCDPGlobalState};
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to enable CDP Global state".
                          "for physical switch ".
                          "$pswitchObj->{switchAddress}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # if switch is vSS, enable cdp state with the specified
   # mode.
   #
   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->{switchObj}->EnableCDP(MODE => $mode);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set CDP state for switch
                          $self->{name} to $mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # if switchtype is vds, then since vds supports lldp as well
   # so pass the cdp flag to indicate we need the cdp.
   #
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $self->{switchObj}->ConfigDiscoveryProtocol(MODE => $mode,
                                                            TYPE => "cdp");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set CDP state for switch ".
                          "$self->{name} to $mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
}

########################################################################
#
# EnableLLDP --
#      This method Enables LLDP (Link Lyer Discovery Protocol) for the
#      specified switch. This is applicable only for vDS and physical
#      switch. vSS doesn't support LLDP.
#
# Input:
#      MODE
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      LLDP state gets enabled.
#
########################################################################

sub EnableLLDP
{
   my $self = shift;
   my $mode = shift;
   my $result = undef;
   my $switchObj = $self->{switchObj};

   #
   # LLDP is not supported for vSS.
   #
   if ($self->{switchType} =~ /vswitch/i) {
      $vdLogger->Error("LLDP is not supported for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   #
   # mode can only have listen, advertisement, both and down.
   #
   if ($mode !~ /advertise|listen|both|none/i) {
      $vdLogger->Error("Incorrect parameter $mode, The valid ".
                       "values are advertise, listen and both");
      VDSetLastError(VDGetLastError());
      return SUCCESS;
   }

   #
   # for pswitch set lldp global state.
   # If the mode is "down" for physical switch it means
   # disable LLDP global state.
   #
   if ($self->{switchType} =~ /pswitch/i) {
      if ($mode =~ m/none/i) {
         $result = $switchObj->DisableLLDPGlobalState(SWITCH => $switchObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to disable LLDP ".
                            "on switch $switchObj->{switchAddress}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $result = $switchObj->EnableLLDPGlobalState(SWITCH => $switchObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to enable LLDP ".
                            "on switch $switchObj->{switchAddress}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->ConfigDiscoveryProtocol(MODE => $mode,
                                                    TYPE => "lldp");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set LLDP state for switch ".
                          "$self->{name} to $mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   # wait for switches to populate the information.
   $vdLogger->Info("Waiting for switches to populate the info");
   sleep 30;
   return SUCCESS;
}

########################################################################
#
# SetLLDPTransmitInterface --
#      This method Enables/Disables the LLDP Transmit interface State
#      for the specific switch port.
#
# Input:
#      mode : Enable/Disable, specifies wether to enable or disable
#             the lldp tx for the interface.
#      port : Name of the port for which this lldp tx state to be
#             set.
#
# Results:
#      "SUCCESS", if LLDP state gets set.
#      "FAILURE", in case of any error,
#
# Side effects:
#      LLDP state either gets enabled or disabled.
#
#################################################################

sub SetLLDPTransmitInterface
{
   my $self = shift;
   my $mode = shift || "Enable";
   my $port = shift;
   my $result = undef;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : SetLLDPTransmitInterface : ";

   #
   # This is only supported for pswitches.
   #
   if ($self->{switchType} !~ /pswitch/i) {
      $vdLogger->Error("Setting LLDP tx state is not supported".
                       " for $self->{switchType}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   # the port must be defined.
   if (not defined $port) {
      $vdLogger->Error("The port name where lldp tx to be set ".
                       "is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($mode !~ m/Enable|Disable/i) {
      $vdLogger->Error("$tag Invalid parameter while setting LLDP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # set LLDP transmit state.
   $result = $switchObj->{setLLDPTransmitInterfaceState} (
                                           PORT => $port,
                                           SWITCH => $switchObj,
                                           MODE => $mode
                                           );
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to enable LLDP ".
                       "on switch $self->{host}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }
   #
   # wait for switches to populate the information.
   # the hold time normally is 120-160 secs, the reason
   # for having large time in sleep is because it takes a while
   # for switches to age out the old entries.
   #
   $vdLogger->Info("$tag Waiting for switches to populate the info");
   sleep 90;
   return SUCCESS;
}


########################################################################
#
# SetLLDPReceiveInterface --
#      This method Enables/Disables the LLDP Receive interface State
#      for the specific switch port.
#
# Input:
#      mode : Enable/Disable, specifies wether to enable or disable
#             the lldp RX state for the interface.
#      port : Name of the port for which this lldp tx state to be
#             set.
#
# Results:
#      "SUCCESS", if LLDP rx state gets set.
#      "FAILURE", in case of any error,
#
# Side effects:
#      LLDP rx state either gets enabled or disabled.
#
#################################################################

sub SetLLDPReceiveInterface
{
   my $self = shift;
   my $mode = shift || "Enable";
   my $port = shift;
   my $result = undef;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : SetLLDPReceiveInterface : ";

   #
   # This is only supported for pswitches.
   #
   if ($self->{switchType} !~ /pswitch/i) {
      $vdLogger->Error("Setting LLDP RX state is not supported".
                       " for $self->{switchType}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   # the port must be defined.
   if (not defined $port) {
      $vdLogger->Error("The port name where lldp rx to be set ".
                       "is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # mode can have only enable,disable values.
   if ($mode !~ m/Enable|Disable/i) {
      $vdLogger->Error("$tag Invalid parameter while setting LLDP");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # set the lldp state on the rx side for the port.
   $result = $switchObj->{setLLDPReceiveInterfaceState} (
                                           PORT => $port,
                                           SWITCH => $switchObj,
                                           MODE => $mode
                                           );
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to enable LLDP Receive ".
                       "on switch $self->{host}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }
   #
   # wait for switches to populate the information.
   # the hold time normally is 120-160 secs, the reason
   # for having large time in sleep is because it takes a while
   # for switches to age out the old entries.
   #
   $vdLogger->Info("$tag Waiting for switches to populate the info");
   sleep 90;
   return SUCCESS;
}


########################################################################
#
# CreateDVPortgroup
#      This method creates the dv portgroup for the vds.
#
#
# Input:
#      dvPortgroup : Name of the dvportgroup.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub CreateDVPortgroup
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $nrp         = shift;
   my $binding     = shift;
   my $ports       = shift;
   my $result = undef;
   my $tag = "Switch : CreateDVPortgroup : ";
   my $switchObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag dvs portgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $switchObj = $self->{switchObj};

   # this is applicable only for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->CreateDVPortgroup(
                            DVPORTGROUP => $dvPortgroup,
                            NRP         => $nrp,
                            PGTYPE      => $binding,
                            PORTS       => $ports
                            );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dvPortgroup");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("$tag successfully created $dvPortgroup ".
                      "for vds $switchObj->{switch}");
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switches of type $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Trace("Created dvportgroup $dvPortgroup for ".
                   "$switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# CreateDVPortgroupWithPorts
#      This method creates the dv portgroup with ports.
#
#
# Input:
#      dvPortgroup : Name of the dvportgroup.
#      ports : Number of ports to be added.
#
# Results:
#      "SUCCESS", if dvportgroup with ports is added.
#      "FAILURE", in case of any error,
#
# Side effects:
#      dvportgroup with specified ports gets created.
#
########################################################################

sub CreateDVPortgroupWithPorts
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $ports  = shift;
   my $result = undef;
   my $tag = "Switch : CreateDVPortgroupWithPorts : ";
   my $switchObj = $self->{switchObj};

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag dvs portgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $ports) {
      $ports = VDNetLib::Common::GlobalConfig::DEFAULT_DV_PORTS;
   }

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag the specified switch is not VDS");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # check if dvportgroup already exists,
   # we don't need this check in ver2 but keep
   # it for now so that there aren't any issues
   # for v1 tests.
   #
   $result = $switchObj->DVPortGroupExists(
                                        DVPG => $dvPortgroup
                                        );
   if ($result eq SUCCESS) {
      return SUCCESS;
   }
   $result = $switchObj->CreateDVPortgroup(DVPORTGROUP => $dvPortgroup,
                                           PORTS => $ports
                                           );
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to create DVPortgroup");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("$tag created DVPortgroup with $ports ports");
   return SUCCESS;
}


########################################################################
#
# UpgradeVDSVersion
#      This method upgrades the vds version.
#
# Input:
#     version : the new version of the vds upgrade to be upgraded.
#
# Results:
#      "SUCCESS", if vds upgrade works fine
#      "FAILURE", in case of any error,
#
# Side effects:
#      the version of the vds gets updated to the one specified.
#
########################################################################

sub UpgradeVDSVersion
{
   my $self = shift;
   my $version = shift;
   my $result = undef;
   my $tag = "Switch : UpgradeVDSVersion : ";
   my $switchObj;

   if (not defined $version) {
      $vdLogger->Error("$tag dvs version not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $switchObj = $self->{switchObj};

   # this is applicable only for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->UpgradeVDSVersion(
                            VERSION => $version
                            );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to upgrade vDS version");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("$tag successfully upgraded $switchObj->{switch} ".
                      "to version $version");
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switches of type $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# AddVMKNIC
#     This method creates the vmknic.
#
# Input:
#      host : Name of the esx host to which vmknic is to be attached.
#      dvPortgroup : Name of the dvportgroup.
#      IP : IP address of the vmknic to be created (IPv4 or IPv6).
#      netmask : Netmask of the vmknic to be created.
#      prefix  : prefix (default is 64)
#      route   : Router advertisement address (boolean,default is disabled)
#      mtu     : MTU of the vmknic to be created.
#
# Results:
#      "SUCCESS", if vmknic gets created.
#      "FAILURE", in case of any error while creating vmknic,
#
# Side effects:
#      vmknic gets attached to the specified dvport(dvportgroup).
#
# Note:
#   This methods currently attaches vmknic to the vds portgroup.
#
########################################################################

sub AddVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $host = $args{host};
   my $dvPortgroup = $args{dvportgroup};
   my $ip = $args{ip};
   my $netmask = $args{netmask};
   my $prefix = $args{prefix};
   my $route = $args{route};
   my $mtu = $args{mtu};
   my $result = undef;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : AddVMKNIC : ";
   my $dvPortgroupObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag dvs portgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag the specified switch is not VDS");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # create dvportgourp object.
   $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
   if ($dvPortgroupObj eq FAILURE) {
      $vdLogger->Error("$tag Failed to create dv portgroup object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $result = $dvPortgroupObj->AddVMKNIC(HOST => $host,
                                        IP => $ip,
                                        NETMASK => $netmask,
                                        PREFIX => $prefix,
                                        ROUTE => $route,
                                        MTU => $mtu,
                                        );
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to attach VMkernel nic to $dvPortgroup");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RemoveVMKNIC
#     This method removes the vmknic.
#
#
# Input:
#      Host : ESX host where vmknic is to be created.
#      IP : IP address of the vmknic to be removed.
#      device id : Device id of the vmknic to be removed.
#
# Results:
#      "SUCCESS", if vmknic gets deleted.
#      "FAILURE", in case of any error while deleting vmknic.
#
# Side effects:
#      vmknic gets removed from the specified dvport(dvportgroup).
#
# Note:
#   This methods currently removes the vmknic from vds portgroup.
#
########################################################################

sub RemoveVMKNIC
{
   my $self = shift;
   my $host = shift;
   my $deviceID = shift;
   my $ip = shift;
   my $anchor = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : RemoveVMKNIC : ";
   my $result;

   if ($self->{switchType} !~ /vdswitch|vswitch/i) {
      $vdLogger->Error("$tag this removes vmknic from vds or vss only");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $result = $switchObj->RemoveVMKNIC(HOST => $host,
                                      DEVICEID => $deviceID,
                                      IP => $ip,
                                      ANCHOR => $anchor);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to remove vmknic from vds");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# DeleteDVPortgroup
#      This method removes the dv portgroup for the vds.
#
#
# Input:
#      arrayOfDVPG : array of dvpg objects to be deleted.
#
# Results:
#      "SUCCESS", if given dvpg is deleted successfully.
#      "FAILURE", in case of any error,
#
# Side effects:
#      the dvportgroup gets created.
#
########################################################################

sub DeleteDVPortgroup
{
   my $self = shift;
   my $arrayOfDVPG = shift;
   my $result = undef;
   my $tag = "Switch : DeleteDVPortgroup : ";

   my $switchObj = $self->{switchObj};

   # this is applicable only for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      my $dvpgName;
      my @arrayOfDVPGName = ();
      foreach my $dvpgObj (@$arrayOfDVPG) {
         $dvpgName = $dvpgObj->{DVPGName};
         push @arrayOfDVPGName, $dvpgName;
      }
      $result = $switchObj->DeleteDVPortgroup(\@arrayOfDVPGName);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to remove dvPortgroup");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switches of type $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("$tag Removed dvportgroup of $switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# AddPortToDVPG
#      This method would add the dvports to the dvportgroup.
#
#
# Input:
#      dvportgroup : Name of the dvportgroup.
#      port : number of ports to be added.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the ports would be added to the dv portgroup.
#
########################################################################

sub AddPortToDVPG
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $port = shift;
   my $result = undef;
   my $tag = "Switch : AddPortToDVPG : ";
   my $switchObj;
   my $dvPortgroupObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("Name of the dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $port) {
      $port = 1;
   }
   $switchObj = $self->{switchObj};

   # this is applicable only for vds.
   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag This operation is only for vds");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   } else {
      #
      # TO DO
      # get dvPortgroup Object via switch object.
      # this would be done once we've some sort of
      # IPC mechanism, at the moment it won't work.
      #
      # for now create dvportgroup object.
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # add port to dvportgroup.
      for (my $i = 1; $i <= $port; $i++) {
         $result = $dvPortgroupObj->AddPortToDVPG();
         if ($result eq FAILURE) {
            $vdLogger->Error("$tag Failed to add dv port to $dvPortgroup");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      return SUCCESS;
   }
}

########################################################################
#
# CreateDVMirrorSession --
#      This method creates the dvmirror session.
#
#
# Input:
#     MIRRORNAME : Name of the mirror session.
#     SRCRXPORT : source output ports.
#     SRCTXPORT : source input ports.
#     DSTUPLINK: Name of uplink port for destination.
#     DESC: Description for the mirror session.
#     DSTPORT: Destination port.
#     STRIPVLAN: Flag for stripping the vlan while mirroring the traffic.
#     ENABLE: Flag whether by default mirror session should be enabled or not.
#     DSTPG: Name of the destination portgroup.
#     LENGTH: Length of the packet to be mirrored at the destination port.
#     SRCRXPG: Source output dvportgroup.
#     SRCTXPG: Source input dvportgroup.
#     TRAFFIC: Flag to specify whether the detination port should be allowed
#              to do the normal traffic or not.
#     ENCAPVLAN: Vlan id which is to be encapsulated while mirroring the traffic.
#     SRCTXWC : Wild card to select the list of source input ports.
#     SRCRXWC: Wild card to select to the list of source output ports.
#     SESSIONTYPE: MN.Next PortMirror has 5 session type:
#                  dvPortMirror, remoteMirrorSource,remoteMirrorDest,
#                  encapsulatedRemoteMirrorSource and mixedDestMirror.
#     MIRRORVERSION: MN is v1,MN.Next is v2.
#     SAMPLINGRATE: one of every n packets is mirrored.
#     SRCVLAN: RSPAN destinaiton session mirrored VLAN ID.
#     ERSPANIP: ESPAN source session defined mirror destination IP address.
#
# Results:
#      "SUCCESS", if mirror session gets created.
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub CreateDVMirrorSession
{
   my $self = shift;
   my $tag = "Switch : CreateDVMirrorSession: ";
   my $mirrorName = shift;
   my $srcRxPort = shift;
   my $srcTxPort = shift;
   my $dstUplink = shift;
   my $desc = shift;
   my $dstport = shift;
   my $stripVlan = shift;
   my $enabled = shift;
   my $dstPG = shift;
   my $mirrorlength = shift;
   my $srcRxPG = shift;
   my $srcTxPG = shift;
   my $normalTraffic = shift;
   my $encapVlan = shift;
   my $srcTxWC = shift;
   my $srcRxWC = shift;
   my $sessionType = shift;
   my $mirrorVersion = shift;
   my $samplingRate = shift;
   my $srcVlan = shift;
   my $erspanIP = shift;
   my $result;
   my $switchObj = $self->{switchObj};

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag This operation is only for vds");
      VDSetLastError("ENOTSUP");
   } else {
      $result = $switchObj->CreateMirrorSession(
                            MIRRORNAME => $mirrorName,
                            SRCRXPORT => $srcRxPort,
                            SRCTXPORT => $srcTxPort,
                            DSTUPLINK => $dstUplink,
                            DESC => $desc,
                            DSTPORT => $dstport,
                            STRIPVLAN => $stripVlan,
                            ENABLED => $enabled,
                            DSTPG => $dstPG,
                            MIRRORLENGTH => $mirrorlength,
                            SRCRXPG => $srcRxPG,
                            SRCTXPG => $srcTxPG,
                            TRAFFIC => $normalTraffic,
                            ENCAPVLAN => $encapVlan,
                            SRCTXWC => $srcTxWC,
                            SRCRXWC => $srcRxWC,
                            SESSIONTYPE => $sessionType,
                            MIRRORVERSION => $mirrorVersion,
                            SAMPLINGRATE => $samplingRate,
                            SRCVLAN => $srcVlan,
                            ERSPANIP => $erspanIP,
                            );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to create mirrorSession");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   $vdLogger->Info("$tag Created mirror session $mirrorName ".
                   "for vds $switchObj->{switch}");
   return SUCCESS;
}


#######################################################################
#
# RemoveDVMirrorSession --
#      This method removes the dvmirror session
#
#
# Input:
#      MODE
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets removed.
#
########################################################################

sub RemoveDVMirrorSession
{
   my $self = shift;
   my $mirrorName = shift;
   my $mirrorVersion = shift;
   my $tag = "Switch : RemoveDVMirrorSession";
   my $switchObj = $self->{switchObj};
   my $result;


   if ($self->{switchType} !~/vdswitch/i) {
      $vdLogger->Error("This operation is applicable only for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   if (not defined $mirrorName) {
      $vdLogger->Error("$tag Name of the mirror session not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $result = $switchObj->RemoveMirrorSession(MIRRORNAME => $mirrorName,
                                             MIRRORVERSION => $mirrorVersion,);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to remove the mirror session ".
                       "$mirrorName for $switchObj->{switch}");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# EnableDVMirrorSession --
#      This method enables the vds mirror session.
#
#
# Input:
#      MODE
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets enabled
#
########################################################################

sub EnableDVMirrorSession
{

}


#######################################################################
#
# DisableDVMirrorSession --
#      This method disables the vds mirror session.
#
#
# Input:
#      MODE
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets disabled
#
########################################################################

sub DisableDVMirrorSession
{

}


########################################################################
#
# ListDVMirrorSession --
#      This method would list the mirror sessions for the vds.
#
#
# Input:
#      None.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################


sub ListDVMirrorSession
{
   my $self = shift;
   my $tag = "Switch : ListDVMirrorSession";
   my $switchObj = $self->{switchObj};
   my $result;


   if ($self->{switchType} !~/vdswitch/i) {
      $vdLogger->Error("This operation is applicable only for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $result = $switchObj->ListDVMirrorSession();
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to list the mirror session for ".
                       "$switchObj->{switch}");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   #
   # return list of mirror sessions, to be added after
   # staf 5.x support.
   #
}


########################################################################
#
# EditDVMirrorSession --
#      This method would edit the existing dvmirror sessionm
#
#
# Input:
#     MIRRORNAME : Name of the mirror session.
#     SRCRXPORT : source output ports.
#     SRCTXPORT : source input ports.
#     DSTUPLINK: Name of uplink port for destination.
#     DESC: Description for the mirror session.
#     DSTPORT: Destination port.
#     STRIPVLAN: Flag for stripping the vlan while mirroring the traffic.
#     ENABLE: Flag whether by default mirror session should be enabled or not.
#     DSTPG: Name of the destination portgroup.
#     LENGTH: Length of the packet to be mirrored at the destination port.
#     SRCRXPG: Source output dvportgroup.
#     SRCTXPG: Source input dvportgroup.
#     TRAFFIC: Flag to specify whether the detination port should be allowed
#              to do the normal traffic or not.
#     ENCAPVLAN: Vlan id which is to be encapsulated while mirroring the traffic.
#     SRCTXWC : Wild card to select the list of source input ports.
#     SRCRXWC: Wild card to select to the list of source output ports.
#     SESSIONTYPE: MN.Next PortMirror has 5 session type:
#                  dvPortMirror, remoteMirrorSource,remoteMirrorDest,
#                  encapsulatedRemoteMirrorSource and mixedDestMirror.
#     MIRRORVERSION: MN is v1,MN.Next is v2.
#     SAMPLINGRATE: one of every n packets is mirrored.
#     SRCVLAN: RSPAN destinaiton session mirrored VLAN ID.
#     ERSPANIP: ESPAN source session defined mirror destination IP address.
#
#
# Results:
#      "SUCCESS", if editing mirror session is successful,
#      "FAILURE", in case of any error,
#
# Side effects:
#      The properties of the mirror session gets changed.
#
########################################################################

sub EditDVMirrorSession
{
   my $self = shift;
   my $tag = "Switch : EditDVMirrorSession: ";
   my $mirrorName = shift;
   my $srcRxPort = shift;
   my $srcTxPort = shift;
   my $dstUplink = shift;
   my $desc = shift;
   my $dstport = shift;
   my $stripVlan = shift;
   my $enabled = shift;
   my $dstPG = shift;
   my $mirrorlength = shift;
   my $srcRxPG = shift;
   my $srcTxPG = shift;
   my $normalTraffic = shift;
   my $encapVlan = shift;
   my $srcTxWC = shift;
   my $srcRxWC = shift;
   my $sessionType = shift;
   my $mirrorVersion = shift;
   my $samplingRate = shift;
   my $srcVlan = shift;
   my $erspanIP = shift;
   my $result;
   my $switchObj = $self->{switchObj};

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag This operation is only for vds");
      VDSetLastError("ENOTSUP");
   } else {
      $result = $switchObj->EditMirrorSession(
                            MIRRORNAME => $mirrorName,
                            SRCRXPORT => $srcRxPort,
                            SRCTXPORT => $srcTxPort,
                            DSTUPLINK => $dstUplink,
                            DESC => $desc,
                            DSTPORT => $dstport,
                            STRIPVLAN => $stripVlan,
                            ENABLE => $enabled,
                            DSTPG => $dstPG,
                            MIRRORLENGTH => $mirrorlength,
                            SRCRXPG => $srcRxPG,
                            SRCTXPG => $srcTxPG,
                            TRAFFIC => $normalTraffic,
                            ENCAPVLAN => $encapVlan,
                            SRCTXWC => $srcTxWC,
                            SRCRXWC => $srcRxWC,
                            SESSIONTYPE => $sessionType,
                            MIRRORVERSION => $mirrorVersion,
                            SAMPLINGRATE => $samplingRate,
                            SRCVLAN => $srcVlan,
                            ERSPANIP => $erspanIP,
                            );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to edit mirrorSession");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   $vdLogger->Info("$tag Successfully edited mirror session $mirrorName ".
                   "for vds $switchObj->{switch}");
   return SUCCESS;
}

########################################################################
#
# ConfigureNetFlow --
#      This method would configure the dvs netflow.
#
#
# Input:
#  CollectoreIP : IP address of the ipfix collector,
#  interonly : If set to true the traffic analysis would be limited
#              to the internal traffic i.e. same host. The default
#              is false.
#  idleTimeout: the time after which idle flows are automatically
#               exported to the ipfix collector, the default is 15
#               seconds.
#  collectorPort : port for the ipfix collector.
#  vdsIP      : Parameter to specify the (IPv4 )ip address of the vds.
#  activeTimeout: the time after which active flows are automatically
#                 exported to the ipfix collector.default is 60 seconds.
#  samplingRate: Ratio of total number packets to the total number
#                packets analyzed.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub ConfigureNetFlow
{
   my $self = shift;
   my $collectorIP = shift;
   my $vdsIP = shift;
   my $internalOnly = shift;
   my $idleTimeout = shift;
   my $collectorPort = shift;
   my $activeTimeout = shift;
   my $samplingRate = shift;
   my $tag = "Switch : ConfigureNetFlow : ";
   my $switchObj = $self->{switchObj};
   my $result;

   # netflow/ipfix is supported for vds only.
   if ($self->{switchType} !~/vdswitch/i) {
      $vdLogger->Error("This operation is applicable only for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $result = $switchObj->ConfigureVDSNetFlow(
                             COLLECTORIP => $collectorIP,
                             INTERNAL => $internalOnly,
                             IDLETIMEOUT => $idleTimeout,
                             COLLECTORPORT => $collectorPort,
                             ACTIVETIMEOUT => $activeTimeout,
                             SAMPLINGRATE => $samplingRate,
                             VDSIP => $vdsIP
                             );
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag configure vds netflow failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("$tag Successfully configured netflow for ".
                   "$switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# EnableNetIORM
#      This method enable NetIORM feature in specified VDS.
#
# Input:
#      none
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
########################################################################

sub EnableNetIORM
{
   my $self = shift;
   my $tag = "Switch : Enabel NetIORM :";
   my $switchObj = $self->{switchObj};
   my $result;
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->EnableNetIORM();
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to Enable NetIORM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switches of type $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


########################################################################
#
# DisableNetIORM
#      This method disable NetIORM feature in specified VDS.
#
# Input:
#      none
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
########################################################################

sub DisableNetIORM
{
   my $self = shift;
   my $tag = "Switch : Disable NetIORM :";
   my $switchObj = $self->{switchObj};
   my $result;
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->DisableNetIORM();
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to Disable NetIORM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switches of type $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

#######################################################################
#
# BlockPort -
#      This method would set the port state to down.
#
#
# Input:
#      port: Name of the port.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
#######################################################################

sub BlockPort
{
   my $self = shift;
   my $port = shift;
   my $dvportgroupObj = shift;
   my $dvportgroup = $dvportgroupObj->{'pgName'};
   my $tag = "Switch : BlockPort : ";
   my $switchObj = $self->{switchObj};
   my $result;

   if ( $self->{switchType} !~ /vdswitch/i ) {
      $vdLogger->Error("$tag Block port is not applicable for ".
                      "switch type $self->{switchType}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   } else {
      $result = $switchObj->SetPortState(PORT => $port,
                                         BLOCK => "true",
                                         DVPG => $dvportgroup);
      if ( $result eq FAILURE ) {
         $vdLogger->Error("$tag Failed to block the port $port");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("$tag Port $port is in blocked state");
      return SUCCESS;
   }
}


########################################################################
#
# UnBlockPort -
#      This method would set the dvport state to up.
#
#
# Input:
#      port: Name of the port.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub UnBlockPort
{
   my $self = shift;
   my $port = shift;
   my $dvportgroupObj = shift;
   my $dvportgroup = $dvportgroupObj->{'pgName'};
   my $tag = "Switch : UnBlockPort : ";
   my $switchObj = $self->{switchObj};
   my $result;

   if ( $self->{switchType} !~ /vdswitch/i ) {
      $vdLogger->Error("$tag Block port is not applicable for ".
                      "switch type $self->{switchType}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   } else {
      $result = $switchObj->SetPortState(PORT => $port,
                                         BLOCK => "false",
                                         DVPG => $dvportgroup);
      if ( $result eq FAILURE ) {
         $vdLogger->Error("$tag Failed to block the port $port");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("$tag Port $port is in blocked state");
      return SUCCESS;
   }
}


########################################################################
#
# SetMACAddressChange -
#      This method would set the mac address change policy for vSwitch,
#      or for the dvportgroup, in case of vds.
#
# Input:
#      expectedState: enable or disable
#      dvportgroupObj: the dvportgroup object in case of vds,
#          or none in case of vSS.
#
# Results:
#      "SUCCESS", if mac address change policy gets enabled/disabled.
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub SetMACAddressChange
{
   my $self = shift;
   my $expectedState = shift;
   my $dvPortgroupObj = shift;
   my $enable;

   if (not defined $expectedState) {
      $vdLogger->Error("Expected state not specified!");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif ($expectedState =~ /enable/i) {
      $enable = "Y";
   } elsif ($expectedState =~ /disable/i) {
      $enable = "N";
   } else {
      $vdLogger->Error("Expected state $expectedState is neither ".
          "enable nor disable!");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("Going to $expectedState the mac address change policy");

   my $tag = "Switch : SetMACAddressChange : ";
   my $switchObj = $self->{switchObj};
   my $result;

   # for vds.
   if ($self->{switchType} eq "vdswitch") {
      if (not defined $dvPortgroupObj) {
         $vdLogger->Error("The dvportgroup object not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $dvPortgroupObj->SetMACAddressChange(ENABLE => "$enable");
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to $expectedState MAC Address Change ".
                          "for specified dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return SUCCESS;
   }

   # for vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchMacChange($expectedState);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   $vdLogger->Error("$tag This operation is only for vds or vSS");
   VDSetLastError("ENOTSUP");
   return FAILURE;
}


########################################################################
#
# GetMacChange --
#      This method is used to get the current Mac Address
#      change flag status on the switch object. (Only available for
#      vSS).
#
# Input:
#      None
#
# Results:
#      0 (unset) - Mac Address change is rejected
#      1 (set)   - Mac Address change is accepted
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetMacChange
{
   my $self     = shift;
   my $result;

   # this operation is available only for vSS
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetvSwitchMacChange();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetForgedTransmit-
#      This method would set the forged transmit policy for vSwitch,
#      or for the dvportgroup, in case of vds.
#
# Input:
#      expectedState: enable or disable
#      dvportgroupObj: the dvportgroup object in case of vds,
#          or none in case of vSS.
#
# Results:
#      "SUCCESS", if forged transmit policy gets enabled/disabled.
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub SetForgedTransmit
{
   my $self = shift;
   my $expectedState = shift;
   my $dvPortgroupObj = shift;
   my $enable;

   if (not defined $expectedState) {
      $vdLogger->Error("Expected state not specified!");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif ($expectedState =~ /enable/i) {
      $enable = "Y";
   } elsif ($expectedState =~ /disable/i) {
      $enable = "N";
   } else {
      $vdLogger->Error("Expected state $expectedState is neither ".
          "enable nor disable!");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("Going to $expectedState the forged transmit policy");

   my $tag = "Switch : SetForgedTransmit : ";
   my $switchObj = $self->{switchObj};
   my $result;

   # for vds.
   if ($self->{switchType} eq "vdswitch") {
      if (not defined $dvPortgroupObj) {
         $vdLogger->Error("The dvportgroup object not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $dvPortgroupObj->SetForgedTransmit(ENABLE => "$enable");
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to $expectedState Forged transmit ".
                          "for specified dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return SUCCESS;
   }

   # for vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchForgedXmit($expectedState);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   $vdLogger->Error("$tag This operation is only for vds or vSS");
   VDSetLastError("ENOTSUP");
   return FAILURE;
}


########################################################################
#
# GetForgedXmit --
#      This method is used to get the current Forged Transmit
#      flag status on the switch object. (only available for vSS).
#
# Input:
#      None
#
# Results:
#      0 (unset) - Forged Transmit is rejected (disabled)
#      1 (set)   - Forged Transmit is accepted (enabled)
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetForgedXmit
{
   my $self     = shift;
   my $result;

   # this operation is available only for vSS
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetvSwitchForgedXmit();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetPromiscuous
#      This method would set promiscuous mode policy for vSwitch,
#      or for the dvportgroup, in case of vds.
#
# Input:
#      expectedState: enable or disable
#      dvportgroupObj: the dvportgroup object in case of vds,
#          or none in case of vSS.
#
# Results:
#      "SUCCESS", if promiscuous mode gets enabled/disabled.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub SetPromiscuous
{
   my $self = shift;
   my $expectedState = shift;
   my $dvPortgroupObj = shift;
   my $enable;

   if (not defined $expectedState) {
      $vdLogger->Error("Expected state not specified!");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } elsif ( $expectedState =~ /enable/i ) {
      $enable = "Y";
   } elsif ( $expectedState =~ /disable/i ) {
      $enable = "N";
   } else {
      $vdLogger->Error("Expected state $expectedState is neither ".
          "enable nor disable!");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("Going to $expectedState the promiscuous mode ... ");

   my $tag = "Switch : SetPromiscuous : ";
   my $switchObj;
   my $result;

   $switchObj = $self->{switchObj};

   # for vds.
   if ($self->{switchType} eq "vdswitch") {
      if (not defined $dvPortgroupObj) {
         $vdLogger->Error("The dvportgroup object not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $dvPortgroupObj->SetPromiscuous( ENABLE => "$enable" );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to $expectedState promiscuous ".
                          "for specified dvportgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return SUCCESS;
   }

    # for vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchProm($expectedState);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   $vdLogger->Error("$tag This operation is only for vds or vSS");
   VDSetLastError("ENOTSUP");
   return FAILURE;
}


########################################################################
#
# GetPromiscuous --
#      This method is used to get the current promiscous mode
#      status on the switch object.(only available for vSS)
#
# Input:
#      None
#
# Results:
#      0 (unset) - Promiscous mode is unset
#      1 (set)   - Promiscous mode is set
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetPromiscuous
{
   my $self     = shift;
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetvSwitchProm();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetAccessVLAN
#      This method would set the access vlan id for the dvs portgroup.
#
# Input:
#      dvportgroup name of the dvportgroup.
#
# Results:
#      "SUCCESS", if dvportgroup is set to the access vlan id.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub SetAccessVLAN
{
   my $self = shift;
   my $accessVLAN  = shift;
   my $dvPortgroup = shift;
   my $port        = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : SetAccessVLAN : ";
   my $result;
   my $dvPortgroupObj;

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      if (not defined $dvPortgroup ) {
         $vdLogger->Error("$tag Name of the dvportgroup not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->SetAccessVLAN(VLAN => $accessVLAN);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to set access vlan $accessVLAN".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   #
   # Add case for pswitch.
   #
   if ($self->{switchType} =~ /pswitch/i) {
      if (not defined $port ) {
         $vdLogger->Error("$tag physical switch port not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $result = $switchObj->{setPortAccessMode}(
             PORT => $port,SWITCH => $switchObj,VLANID =>$accessVLAN);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set port $port to access mode.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# SetVLANTrunking
#     This method would set the vlan trunk range for the dvs portgroup.
#
# Input:
#      trunkRange : The vlan range to be allowd on the portgroup.
#      dvportgroup: name of the dvportgroup.
#
# Results:
#      "SUCCESS", if dvportgroup is set to vlan trunk range.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub SetVLANTrunking
{
   my $self = shift;
   my $trunkRange = shift;
   my $dvPortgroup = shift;
   my $port       = shift;
   my $nativevlan = shift;
   my $vlanrange  = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : SetVLANTrunking : ";
   my $result;
   my $dvPortgroupObj;

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      if (not defined $trunkRange) {
         $vdLogger->Error("$tag vlan trunk range not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      if (not defined $dvPortgroup) {
         $vdLogger->Error("$tag Name of the dvportgroup not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # remove [];
      $trunkRange =~ s/\[|\]//g;
      $result = $dvPortgroupObj->SetVLANTrunking(RANGE => $trunkRange);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to set vlan trunking ".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   #
   # Add case for pswitch.
   #
   if ($self->{switchType} =~ /pswitch/i) {
      if (not defined $port) {
         $vdLogger->Error("$tag physical switch port not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      #
      #  TO DO :
      #  Use the Parameter $trunkrange here as well as in case
      #  of vds.
      #
      $vlanrange =~ s/\[|\]//g; # user passes vlan range as [a-b]. [] should be
                                # removed
      $result = $switchObj->{setPortTrunkMode}(PORT => $port,
               SWITCH => $switchObj,NATIVEVLAN =>$nativevlan,VLANRANGE =>$vlanrange);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set port $port to trunk mode.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# SetVdsTrafficShapingPolicy:
#      This method would configure the Traffic Shaping policy for
#      given VDS.
#
# Input:
#       shaping-policy - Enable/Disable
#       avg-bandwidth  - (in bits/secs)
#       peak-bandwidth - (in bits/secs)
#       burst-size     - (in Bytes)
#       dvportgroup - The name of the dvportgroup
#       shaping_direction - in/out
# Results:
#      "SUCCESS", if traffic shaping policies are set successfully
#       for the given VDS.
#      "FAILURE", in case of any error.
#
# Side effects
#      Traffic Shaping Policies gets changed for the given VDS.
#########################################################################

sub SetVdsTrafficShapingPolicy
{
   my $self      = shift;
   my $policy    = shift;
   my $avg       = shift;
   my $peak      = shift;
   my $burstSz   = shift;
   my $dvpgObj   = shift;
   my $direction = shift;
   my $result;

   if (not defined $dvpgObj) {
      $vdLogger->Error("Traffic Shaping dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvpg = $dvpgObj->{name};

   if (not defined $policy) {
      $vdLogger->Error("Traffic Shaping policy not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($policy =~ /enable/i) {
      if (not defined $avg || not defined $peak ||
          not defined $burstSz || not defined $direction ||
          not defined $dvpg) {
         $vdLogger->Error("Shaping parameters not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } elsif ($policy =~ /disable/i) {
      if (not defined $direction || not defined $dvpg) {
         $vdLogger->Error("Shaping parameters not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Shaping policy is invalid, should be enable or disable");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Operate VDS porgroup traffic shaping with parameters".
   " dvportgroup: $dvpg, avg_bandwidth: $avg, peak_bandwidth: $peak, burst_size: $burstSz".
   " policy: $policy, direction: $direction");

   if ($policy =~ /Enable/i) {
      if ($direction =~ /in/i) {
         $result = $self->EnableInTrafficShaping($dvpg, $avg, $peak, $burstSz);
         if ($result eq FAILURE) {
            $vdLogger->Error("EnableInTrafficShaping failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ($direction =~ /out/i) {
         $result = $self->EnableOutTrafficShaping($dvpg, $avg, $peak, $burstSz);
         if ($result eq FAILURE) {
            $vdLogger->Error("EnableOutTrafficShaping failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $vdLogger->Error("The value of shaping_direction is invalid, should be in or out");
         $vdLogger->Error("Key shaping_direction: " . Dumper($direction));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif ($policy =~ /Disable/i) {
      if ($direction =~ /in/i) {
         $vdLogger->Debug("Disable DVPortgroup $dvpg in Shaping");
         $result = $self->DisableInTrafficShaping($dvpg);
         if ($result eq FAILURE) {
            $vdLogger->Error("DisableInTrafficShaping failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ($direction =~ /out/i) {
         $vdLogger->Debug("Disable DVPortgroup $dvpg out Shaping");
         $result = $self->DisableOutTrafficShaping($dvpg);
         if ($result eq FAILURE) {
            $vdLogger->Error("DisableOutTrafficShaping failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $vdLogger->Error("The value of shaping_direction is invalid, should be in or out");
         $vdLogger->Error("Key shaping_direction: " . Dumper($direction));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("The value of set_shaping_policy is invalid, should be Enable or Disable");
      $vdLogger->Error("Key set_shaping_policy: " . Dumper($policy));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# EnableInTrafficShaping
#     This method would enable the "IN" Traffic Shaping for the dvs
#     portgroup.
#
# Input:
#      dvportgroup: name of the dvportgroup.
#      avgBandwidth : parameter to specify the Average Bandwidth.
#      peakBandwidth : parameter to specify the peak bandwidth.
#      burstSize : parameter to specify the burst size.
#
#      The parameters avgBandwidth, peakBandwidth, and burstSize can
#      also take value as "random", in that case a random value is
#      computed.
#
# Results:
#      "SUCCESS", if inbound traffic shaping gets enabled for
#                 dvportgroup.
#      "FAILURE", in case of any error.
#
# Side effects:
#      inbound traffic shaping is enabled for the dvportgroup.
#
########################################################################

sub EnableInTrafficShaping
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $avgBandwidth = shift;
   my $peakBandwidth = shift;
   my $burstSize = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : EnableInTrafficShaping : ";
   my $result;
   my $dvPortgroupObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $avgBandwidth || not defined $peakBandwidth ||
       not defined $burstSize) {
      $vdLogger->Error("$tag shaping parameters not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $min = 10; # keeping a minimum of 10 kbps
   # maximum value is 100000
   if ($avgBandwidth =~ /random/i) {
      $avgBandwidth = int(99990 * (rand(100)/100)) + $min;
      $vdLogger->Info("Inshaping: Selecting a random value of $avgBandwidth " .
                      "for avgBandwidth");
   }

   # maximum value is 100000
   if ($peakBandwidth =~ /random/i) {
      $peakBandwidth = int(99990 * (rand(100)/100)) + $min; # peakBandwidth >
                                                           # avg
      if (int($peakBandwidth) < int($avgBandwidth)) {
         $peakBandwidth = $avgBandwidth;
      }

      $vdLogger->Info("Inshaping: Selecting a random value of $peakBandwidth " .
                      "for peakBandwidth");
   }

   # maximum value is 102400
   if ($burstSize =~ /random/i) {
      $burstSize = int(102390 * (rand(100)/100)) + $min;
      $vdLogger->Info("Inshaping: Selecting a random value of $burstSize " .
                      "for burstSize");
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->EnableShaping(AVGBANDWIDTH => $avgBandwidth,
                                               PEAKBANDWIDTH => $peakBandwidth,
                                               BURSTSIZE => $burstSize,
                                               TYPE => "INBOUND"
                                               );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to set shaping prameters ".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $vdLogger->Info("Enabled inbound traffic shaping for ".
                   "dvportgroup $dvPortgroup");
   return SUCCESS;
}


########################################################################
#
# DisableInTrafficShaping
#     This method would disable the "IN" Traffic Shaping for the dvs
#     portgroup.
#
# Input:
#      dvportgroup: name of the dvportgroup.
#      avgBandwidth : parameter to specify the Average Bandwidth.
#      peakBandwidth : parameter to specify the peak bandwidth.
#      burstSize : parameter to specify the burst size.
#
# Results:
#      "SUCCESS", if inbound traffic shaping gets disabled for
#                 dvportgroup.
#      "FAILURE", in case of any error.
#
# Side effects:
#      inbound traffic shaping gets disabled for the dvportgroup.
#
########################################################################

sub DisableInTrafficShaping
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : DisableInTrafficShaping : ";
   my $result;
   my $dvPortgroupObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->DisableShaping( TYPE => "INBOUND" );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to disable shaping ".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $vdLogger->Info("Disabled inbound traffic shaping for ".
                   "dvportgroup $dvPortgroup");
   return SUCCESS;
}


########################################################################
#
# EnableOutTrafficShaping
#     This method would enable the "OUT" Traffic Shaping for the dvs
#     portgroup.
#
# Input:
#      dvportgroup: name of the dvportgroup.
#      avgBandwidth : parameter to specify the Average Bandwidth.
#      peakBandwidth : parameter to specify the peak bandwidth.
#      burstSize : parameter to specify the burst size.
#
#      The parameters avgBandwidth, peakBandwidth, and burstSize can
#      also take value as "random", in that case a random value is
#      computed.
#
# Results:
#      "SUCCESS", if outbound traffic shaping gets enabled for
#                 dvportgroup.
#      "FAILURE", in case of any error.
#
# Side effects:
#      outbound traffic shaping is enabled for the dvportgroup.
#
########################################################################

sub EnableOutTrafficShaping
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $avgBandwidth = shift;
   my $peakBandwidth = shift;
   my $burstSize = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : EnableOutTrafficShaping : ";
   my $result;
   my $dvPortgroupObj;

   if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $avgBandwidth || not defined $peakBandwidth ||
       not defined $burstSize) {
      $vdLogger->Error("$tag shaping parameters not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $min = 10; # keeping a minimum of 10 kbps
   # maximum value is 100000
   if ($avgBandwidth =~ /random/i) {
      $avgBandwidth = int(99990 * (rand(100)/100)) + $min;
      $vdLogger->Info("Outshaping: Selecting a random value of $avgBandwidth " .
                      "for avgBandwidth");
   }

   # maximum value is 100000
   if ($peakBandwidth =~ /random/i) {
      $peakBandwidth = int(99990 * (rand(100)/100)) + $min;
      if (int($peakBandwidth) < int($avgBandwidth)) {
         $peakBandwidth = $avgBandwidth;
      }
      $vdLogger->Info("Outshaping: Selecting a random value of $peakBandwidth " .
                      "for peakBandwidth");
   }

   # maximum value is 102400
   if ($burstSize =~ /random/i) {
      $burstSize = int(102390 * (rand(100)/100)) + $min;
      $vdLogger->Info("Outshaping: Selecting a random value of $burstSize " .
                      "for burstSize");
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->EnableShaping(AVGBANDWIDTH => $avgBandwidth,
                                            PEAKBANDWIDTH => $peakBandwidth,
                                            BURSTSIZE => $burstSize,
                                            TYPE => "OUTBOUND"
                                            );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to set OUT shaping prameters ".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $vdLogger->Info("Enabled outbound traffic shaping for ".
                   "dvportgroup $dvPortgroup");
   return SUCCESS;
}


########################################################################
#
# DisableOutTrafficShaping
#     This method would disable the "OUT" Traffic Shaping for the dvs
#     portgroup.
#
# Input:
#      dvportgroup: name of the dvportgroup.
#
# Results:
#      "SUCCESS", if outbound traffic shaping gets disabled for
#                 dvportgroup.
#      "FAILURE", in case of any error.
#
# Side effects:
#      outbound traffic shaping gets disabled for the dvportgroup.
#
########################################################################

sub DisableOutTrafficShaping
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : EnableInTrafficShaping : ";
   my $result;
   my $dvPortgroupObj;

    if (not defined $dvPortgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->DisableShaping(TYPE => "OUTBOUND");
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to disable OUT shaping ".
                          "for dvportgroup $dvPortgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $vdLogger->Info("Disabled outbound traffic shaping for ".
                   "dvportgroup $dvPortgroup");
   return SUCCESS;
}

########################################################################
#
# SetTeaming
#     This method would set the nic teaming policy.
#
# Input:
#      Reference to a hash with the following keys:
#      dvportgroup: name of the dvportgroup.
#      failover: Specifies the failover detection policy, valid values
#                are BEACONPROBING and LINKSTATUSONLY.
#      notifySwitch : parameter to specify the notify switch, valid
#                      values are  Y, N.
#      failback : parameter to specify the failback setting (boolean).
#      lbPolicy : parameter to specify the load balancing policy.
#                 valid values are loadbalance_ip, loadbalance_srcmac,
#                 loadbalance_srcid, loadbalance_loadbased,
#                 failover_explicit.
#      standbyNics: Parameter to specify the standby nics.
#
#
# Results:
#      "SUCCESS", if teaming gets set for the
#                 dvportgroup.
#      "FAILURE", in case of any error.
#
# Side effects
#      Teaming configuration gets changed for the specified dvportgroup.
#
########################################################################

sub SetTeaming
{
   my $self = shift;
   my $refOfDvpgObj = shift;
   my $failback = shift;
   my $lbPolicy = shift;
   my $notifySwitch = shift;
   my $standbyNics = shift;
   my $failover = shift;

   my $switchObj = $self->{switchObj};
   my $result;
   my $uplinks = undef;
   my $uplink;

   if (defined $standbyNics) {
      foreach my $vmnicObj (@$standbyNics) {
         $vdLogger->Debug("vmnic : " . Dumper($vmnicObj->{'vmnic'}));
         if ($self->{switchType} =~ /vdswitch/i) {
            $uplink = $vmnicObj->{hostObj}->GetDVUplinkNameOfVMNic(
                           $switchObj->{'switch'},
                           $vmnicObj->{'vmnic'});
            if ($uplink eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         } else {
            $uplink = $vmnicObj->{'vmnic'};
         }
         if (not defined $uplinks) {
            $uplinks = $uplink;
         } else {
            $uplinks = $uplinks. "," . $uplink;
         }
      }
   }
   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      if (not defined $refOfDvpgObj) {
         $vdLogger->Error("Name of the dvportgroup not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # This is to support backward compatibility. Don't use it.
      if ($refOfDvpgObj =~ /all/i) {
         $result = $switchObj->SetTeaming(FAILOVER => $failover,
                                          NOTIFYSWITCH => $notifySwitch,
                                          FAILBACK => $failback,
                                          LBPOLICY => $lbPolicy,
                                          STANDBYNICS => $uplinks
                                          );
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to set teaming policy ".
                             "for dvportgroup $refOfDvpgObj");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $vdLogger->Info("Successfully set nic teaming for ".
                         "$refOfDvpgObj");
      } else {
         # This is to support dvportgoup tuples like vc.[1].dvportgroup.[1-2]
         foreach my $dvpgObj (@$refOfDvpgObj) {
            $result = $dvpgObj->SetTeaming(FAILOVER => $failover,
                                           NOTIFYSWITCH => $notifySwitch,
                                           FAILBACK => $failback,
                                           LBPOLICY => $lbPolicy,
                                           STANDBYNICS => $uplinks
                                           );
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to set teaming policy ".
                                "for dvportgroup $dvpgObj->{DVPGName}");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            $vdLogger->Info("Successfully set nic teaming for ".
                            "$dvpgObj->{DVPGName}");
         }
      }
   } else {
       my $args;
       $args->{failback}         = $failback;
       $args->{loadbalancing}    = $lbPolicy;
       $args->{notifyswitches}   = $notifySwitch;
       $args->{standbynics}      = $uplinks;

       $result = $self->{'switchObj'}->SetvSwitchNicTeamingPolicy($args);
       if ($result eq FAILURE) {
          $vdLogger->Error("Failed to configure teaming policy of " .
                           "$self->{name}");
          VDSetLastError("ENOTSUP");
          return FAILURE;
       }
   }
   $vdLogger->Info("Successfully set nic teaming for ".
                   "$self->{name}");
   return SUCCESS;
}

########################################################################
#
# SetFailoverOrder --
#      This method is used to set the failover order for the given
#      vSwitch. As mentioned in the package description, this is a
#      wrapper method to set the failover order.
#
# Input:
#      vmnicList: A comma separated list of vmnics.
#
# Results:
#      "SUCCESS", if failover order is set successfully to switch;
#      "FAILURE", in case of any error.
#
# Side effects:
#      New failover order is set for the given vSwitch.
#
########################################################################

sub SetFailoverOrder
{
   my $self      = shift;
   my $vmnicList = shift;
   my $tag       = "Switch : SetFailoverOrder : ";
   my $result    = undef;
   my @vmnicArray = ();

   if (not defined $vmnicList || $vmnicList eq "") {
      $vdLogger->Error("No failover order is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   @vmnicArray = split("," , $vmnicList);
   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSSFailoverOrder(\@vmnicArray);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# MigrateManagementNetToVDS
#     This method would migrate the management network (vmknic) from
#     vSS to vDS.
#
# Input:
#      PGHost: ESX Host Name
#      dvPortgroup : Name of the dvportgroup to which management
#                    network will be moved.
#      portgroup : Name of the dvportgroup to which vmknic is
#                  connected.
#
# Results:
#      "SUCCESS", if management network gets migrated to vDS.
#      "FAILURE", in case of any error.
#
# Side effect:
#      management network gets migrated to vDS from vSS.
#
########################################################################

sub MigrateManagementNetToVDS
{
   my $self = shift;
   my $PGHost = shift;
   my $dvPortgroup = shift;
   my $portgroup = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : MigrateManagementNetToVDS : ";
   my $result;
   my $dvPortgroupObj;

    if ((not defined $dvPortgroup) && (not defined $PGHost)
        && (not defined $portgroup) ) {
      $vdLogger->Error("$tag Parameters not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # for vds.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->MigrateManagementNetToVDS(
                                                    HOST => $PGHost,
                                                    PORTGROUP => $portgroup
                                                    );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to migrate management network to vds");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This is applicable only vds");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $vdLogger->Info("$tag Migrated management network to VDS");
   return SUCCESS;
}


########################################################################
#
# MigrateManagementNetToVSS
#     This method would migrate the management network (vmknic) from
#     vDS to vSS.
#
# Input:
#      hostObj  : ESX Host object
#      vmknicObj: specifies the vmkniv obj to be migrated to vSS.
#      vssObj   : Object of the vswitch.
#
# Results:
#      "SUCCESS", if management network gets migrated to vDS.
#      "FAILURE", in case of any error.
#
# Side effect:
#      management network gets migrated to vDS from vSS.
#
########################################################################

sub MigrateManagementNetToVSS
{
   my $self = shift;
   my $hostObj = shift;
   my $vmknicObj = shift;
   my $vssObj = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : MigrateManagementNetToVSS : ";
   my $result;

   if ((not defined $hostObj) || (not defined $vmknicObj) || (not defined $vssObj)) {
      $vdLogger->Error("$tag Parameters not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ( $self->{switchType} !~ /vdswitch/i ) {
      $vdLogger->Error("$tag This is not applicable for ".
                      "switch type $self->{switchType}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   } else {
      $result = $switchObj->MigrateManagementNetToVSS(HOSTOBJ => $hostObj,
                                                      VMKNICOBJ => $vmknicObj,
                                                      SWOBJ => $vssObj,
                                                      );
      if ( $result eq FAILURE ) {
         $vdLogger->Error("$tag Failed to migrate $vmknicObj in $hostObj ".
                          "to vSS");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("$tag Migrated $vmknicObj in $hostObj to vSS");
      return $result;
   }
}


########################################################################
#
# AddPVLANMap
#     This method would add the pvlan map.
#
# Input:
#      pvlanType: PVLAN type, it could be promiscuous, community and
#                 isolated.
#      primaryVLAN : Primary vlan id.
#      secondaryVLAN : Secondary vlan id.
#
# Results:
#      "SUCCESS", if pvlan map gets added to the switch.
#      "FAILURE", in case of any error.
#
# Side effect:
#      pvlan map gets added to the switch.
#
########################################################################

sub AddPVLANMap
{
   my $self = shift;
   my $pvlanType = shift;
   my $primaryVLAN = shift;
   my $secondaryVLAN = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : AddPVLANMap : ";
   my $result;

   # This is applicable for vDS.
   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->AddPVLANMap(PVLANTYPE => $pvlanType,
                                        PRIMARYID => $primaryVLAN,
                                        SECONDARYID => $secondaryVLAN
                                        );
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to add pvlan map ".
                          "for switch $self->{switch}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $vdLogger->Info("$tag Successfully added pvlan map ".
                   "for $switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# SetPVLANType
#     This method would set the pvlan type for the dvportgroup.
#
# Input:
#      pvlanType: PVLAN type, it could be promiscuous, community and
#                 isolated.
#      primaryVLAN : Primary vlan id.
#      secondaryVLAN : Secondary vlan id.
#
# Results:
#      "SUCCESS", if pvlan map gets added to the switch.
#      "FAILURE", in case of any error.
#
# Side effect:
#      the dvportgroup gets associated with the pvlan type.
#
########################################################################

sub SetPVLANType
{
   my $self = shift;
   my $dvPortgroup = shift;
   my $pvlanid = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : SetPVLANType : ";
   my $dvPortgroupObj;
   my $result;

   # This is applicable for vDS.
   if ($self->{switchType} =~ /vdswitch/i) {
      $dvPortgroupObj = VDNetLib::Switch::VDSwitch::DVPortGroup->new(
                                               DVPGName => $dvPortgroup,
                                               switchObj => $switchObj,
                                               stafHelper => $self->{stafHelper}
                                               );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $dvPortgroupObj->SetPVLANType(PVLANID => $pvlanid);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to add pvlan map for dvportgroup ".
                          "$dvPortgroup for switch $self->{switch}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$tag This operation is applicable for vds only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $vdLogger->Info("$tag Successfully set pvlan type for dvportgroup ".
                   "$dvPortgroup for $switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# GetBeacon --
#      This method is used to get the current status of
#      Beacon Probing flag on the switch. (only available
#      for vSS).
#
# Input:
#      None
#
# Results:
#      0 (unset) - Beacon Probing is disabled
#      1 (set)   - Beacon Probing is enabled
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetBeacon
{
   my $self     = shift;
   my $tag = "Switch : GetBeacon : ";
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetvSwitchBeacon();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("$tag This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetBeacon --
#      This method is used to enable the Beacon Probing
#      on the switch. (only available for vSS).
#
# Input:
#      None
#
# Results:
#      "SUCCESS", on successful operation
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub SetBeacon
{
   my $self     = shift;
   my $tag = "Switch : SetBeacon : ";
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchBeacon();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("$tag This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# ResetBeacon --
#      This method is used to disable the Beacon Probing
#      on the switch. (only available for vSS).
#
# Input:
#      None
#
# Results:
#      "SUCCESS", on successful operation
#      "FAILURE" - in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ResetBeacon
{
   my $self     = shift;
   my $tag = "Switch : ResetBeacon : ";
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->ResetvSwitchBeacon();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("$tag This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# ConfigureHosts --
#      This method is used to decide which api needs to called for adding
#      or deleting host to a particular vds
#
# Input:
#      operation       : <add/remove> host to the vdswitch
#      refArrayObjHost : reference to an array of host objects
#      refArrayObjVmnic: reference to an array of vminc objects
#
# Results:
#      "SUCCESS", if the operation is successfull.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureHosts
{
   my $self             = shift;
   my $operation        = shift;
   my $refArrayObjHost  = shift;
   my $refArrayObjVmnic = shift;

   if ((not defined $operation) || (not defined $refArrayObjHost)) {
      $vdLogger->Error("Either operation or refArrayObjHost is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $operationRef = {
      'add'    => 'AddMultipleHostsToVDS',
      'remove' => 'RemoveHosts'
   };

   my $method  = $operationRef->{$operation};

   $vdLogger->Debug("$operation Host on vds: $self->{'name'}");

   my @arrMapping;
   if ($refArrayObjHost) {
      #create $refArrayObjVmnic
      foreach my $hostObj (@$refArrayObjHost) {
         my @arr;
         my $hashRef;
         foreach my $vmnicObj (@$refArrayObjVmnic) {
            my $hostObjVmnic = $vmnicObj->{hostObj};
            my $hostIPVmnic = $hostObjVmnic->{hostIP};
            if ($hostObj->{hostIP} eq $hostIPVmnic) {
               $vdLogger->Debug("$operation host to vds $self->{'name'} with $vmnicObj->{vmnic}");
               push (@arr, $vmnicObj);
            }
         }
         $hashRef = { 'hostObj' => $hostObj,
                      'vmnicObj'=> \@arr
                    };
         push(@arrMapping, $hashRef);
      }
   } else {
      $vdLogger->Debug("$operation host to vds $self->{'name'} without vmnic");
      foreach my $hostObj (@$refArrayObjHost) {
         my $hashRef = { 'hostObj' => $hostObj };
         push(@arrMapping, $hashRef);
      }
   }
   return $self->{'switchObj'}->$method(\@arrMapping);
}


########################################################################
#
# ConfigureUplinks --
#      This method is used to decide which api needs to called for adding
#      or deleting uplinks
#
# Input:
#      operation    : <add/remove> vmnic adapter on switch
#      vmnicArrayRef: Reference to an array containing Vmnic Objects
#
# Results:
#      "SUCCESS", if the operation is successfull.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureUplinks
{
   my $self          = shift;
   my $operation     = shift;
   my $vmnicArrayRef = shift;
   my $executiontype  = shift;
   if ((not defined $vmnicArrayRef) && (not defined $operation)) {
      $vdLogger->Error("Either vmnic adapter or operation is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $operationRef = {
      'add'    => 'AddUplinks',
      'remove' => 'RemoveUplinks'
   };

   $vdLogger->Debug("Running operation $operation on vmnics");
   my $method = $operationRef->{$operation};
   my $anchor;
   if ($self->{'switchType'} eq "vdswitch") {
      my $vcObj = $self->{'vcObj'};
      $anchor = $vcObj->{'hostAnchor'};
      $vdLogger->Debug("Host anchor for vds: $anchor");
   }
   if ((defined $executiontype) && ($executiontype =~ /api/i)) {
      $anchor = $self->{hostOpsObj}{'stafVMAnchor'};
   }
   return $self->$method($vmnicArrayRef, $anchor);
}


########################################################################
#
# AddUplinks --
#      This method is used to  add the pnics/vmnics to the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to add the uplinks to switch.
#
# Input:
#      vmnicList: A comma separated list of vmnics to be added.
#
# Results:
#      "SUCCESS", if all the given vmnics are added successfully to switch;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub AddUplinks
{
   my $self          = shift;
   my $vmnicArrayRef = shift;
   my $anchor        = shift;
   my $executionType = shift;
   my $tag           = "Switch : AddUplilnks : ";
   my $result;

   if (not defined $vmnicArrayRef) {
      $vdLogger->Error("No vmnic reference is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Trace("vmnicList to AddUplinks() is:$vmnicArrayRef");
   foreach my $vmnicObj (@$vmnicArrayRef) {
      my $vmnic = $vmnicObj->{vmnic};
      if ($self->{'switchType'} eq "vswitch") {
         next if ($self->{'switchObj'}->AddvSwitchUplink($vmnic) eq "SUCCESS");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         my $hostIP = $vmnicObj->{hostObj}{hostIP};
         if (not defined $hostIP) {
            $vdLogger->Error("Not able to find hostIP:$hostIP to adduplink");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         my $result = $self->{'switchObj'}->AddRemoveVDSUplink(operation => "add",
                                                               vmnic     => $vmnic,
                                                               anchor    => $anchor,
                                                               hostIP    => $hostIP);
         if ($result eq "FAILURE") {
            $vdLogger->Error("Not able to add $vmnic to switch");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# RemoveUplinks --
#      This method is used to  remove the pnics/vmnics from the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to remove the uplinks from switch. (only available
#      for vSS);
#
# Input:
#      vmnicList: A comma separated list of vmnics to be removed.
#
# Results:
#      "SUCCESS", if all the given vmnics are removed successfully
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub RemoveUplinks
{
   my $self      = shift;
   my $vmnicArrayRef = shift;
   my $anchor    = shift;
   my $hostIP    = shift;
   my $tag = "Switch : RemoveUplinks : ";
   my $result;

   if (not defined $vmnicArrayRef) {
      $vdLogger->Error("No vmnic reference is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Trace("vmnicList to RemoveUplinks() is:$vmnicArrayRef");
   foreach my $vmnicObj (@$vmnicArrayRef) {
      my $vmnic = $vmnicObj->{vmnic};
      if ($self->{'switchType'} eq "vswitch") {
         next if ($self->{'switchObj'}->UnlinkvSwitchPNIC($vmnic, $anchor) eq "SUCCESS");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $hostIP = $vmnicObj->{hostObj}{hostIP};
         if (not defined $hostIP) {
            $vdLogger->Error("Not able to find hostIP:$hostIP to adduplink");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         my $result = $self->{'switchObj'}->AddRemoveVDSUplink(operation => "remove",
                                                               vmnic     => $vmnic,
                                                               anchor    => $anchor,
                                                               hostIP    => $hostIP);
         if ($result eq "FAILURE") {
            $vdLogger->Error("Not able to remove $vmnic from switch");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# AddPortGroup --
#      This method is used to  add a port-group to the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to add the given port-group to switch. (only
#      applicable to vSS).
#
# Input:
#      pgname  : Name of the port-group to be added.    (mandatory)
#      pgnumber: Number of the port-groups to be added. (optional)
#
# Results:
#      "SUCCESS", if port-group is added successfully to switch;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub AddPortGroup
{
   my $self   = shift;
   my $pgname = shift;
   my $pgnum  = shift;
   my $index;
   my $result;

   if (not defined $pgname) {
      $vdLogger->Error("No port-group name is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      if (defined $pgnum && $pgnum =~ /^\d+$/) {
	 my $mypgname;
	 for ($index=1; $index <= $pgnum; $index++) {
	    $mypgname =  $pgname . "-" . $index;
	    $result = $self->{'switchObj'}->AddPortGroupTovSwitch($mypgname);
	    if ($result eq FAILURE) {
	       VDSetLastError(VDGetLastError());
	       return FAILURE;
	    }
	 }
      } else {
	 $result = $self->{'switchObj'}->AddPortGroupTovSwitch($pgname);
	 if ($result eq FAILURE) {
	    VDSetLastError(VDGetLastError());
	    return FAILURE;
	 }
      }

      return SUCCESS;
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# DeletePortGroup --
#      This method is used to delete the port-group(s) from the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to delete the given port-group(s) from switch.
#      (Only applicable for vSS).
#
# Input:
#      pgname  : Name of the port-group to be deleted.    (mandatory)
#      pgnumber: Number of the port-groups to be deleted. (optional)
#
# Results:
#      "SUCCESS", if port-group is deleted successfully
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub DeletePortGroup
{
   my $self   = shift;
   my $pgname = shift;
   my $pgnum  = shift;
   my $index;
   my $result;

   if (not defined $pgname) {
      $vdLogger->Error("No port-group name is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      if (defined $pgnum && $pgnum =~ /^\d+$/) {
         my $mypgname;
         for ($index=1; $index <= $pgnum; $index++) {
            $mypgname =  $pgname . "-" . $index;
            $result = $self->{'switchObj'}->DeletePortGroupFromvSwitch($mypgname);
            if ($result eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      } else {
         $result = $self->{'switchObj'}->DeletePortGroupFromvSwitch($pgname);
         if ($result eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      return SUCCESS;
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetProperties --
#      This method is used to get all the properties of the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to get the properties of switch. (only applicable
#      for vSS);
#
# Input:
#      None
#
# Results:
#      Reference to a hash with the following keys:
#      'switch', 'numports', 'usedports', 'confports', 'mtu', 'uplink',
#       if successful;
#
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetProperties
{
   my $self     = shift;
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetvSwitchProps();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("This operation is only for vSS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetTeamingPolicies --
#      This method is used to get NIC Temaing Policies of the switch
#      object. As mentioned in the package description, this is a
#      wrapper method to get the NIC Teaming policies of switch.
#      (only applicable for vSS).
#
# Input:
#      portgroup - portgroup name
#      hostObject - host object needed to find teaming policy on dvs
#
# Results:
#      Reference to the Result hash on success
#      FAILURE on failure
#
# Format of the Result hash:
# --------------------------
#       The result hash will have the following
#       format for the key-value pairs:-
#
#  KEY                    |  VALUE(s) (Description)
#  -----------------------|------------------------------
#                         |
#  ActiveAdapters         |  Reference to an array of
#                         |  virtual nics
#                         |(e.g. {vmnic1, vmnic2, vmnic3})
#                         |
#  Failback               |  'true' or 'false'
#                         |
#  LoadBalancing          |  'portid' or 'iphash'
#                         |  'mac' or 'explicit'
#                         |
#  NetworkFailureDetection|  'link' or 'beacon'
#                         |
#  NotifySwitches         |  'true' or 'false'
#  -----------------------|------------------------------
#
# Side effects:
#      None
#
########################################################################

sub GetTeamingPolicies
{
   my $self     = shift;
   my $portgroup = shift;
   my $hostOpsObj = shift; #optional
   my $result;

   if ($self->{'switchType'} eq "vswitch") {
      # for vswitch
      $result = $self->{'switchObj'}->GetvSwitchNicTeamingPolicy();
   } else {
      # in case of vdswitch
      $result = $hostOpsObj->GetDVSTeamPolicy($self->{'switch'}, $portgroup);
   }

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get team policies on $self->{'switch'}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } else {
      return $result;
   }

}


########################################################################
#
# SetvSSTeaming:
#      This method would set the nic teaming policy for given vSwitch.
#      (only applicable for vSS).
#
# Input:
#
#       ActiveAdapters         |  A string containing list of
#                              |  virtual nics (separated by
#                              |  commas) to be added as the
#                              |  uplink
#                              |(e.g. {vmnic1,vmnic2,vmnic3})
#                              |
#       Failback               |  'true' or 'false'
#                              |
#       LoadBalancing          |  'portid' or 'iphash'
#                              |  'mac' or 'explicit'
#                              |
#       NetworkFailureDetection|  'link' or 'beacon'
#                              |
#       NotifySwitches         |  'true' or 'false'
#
# Results:
#      "SUCCESS", if teaming gets set successfully for the given
#       vSwitch.
#      "FAILURE", in case of any error.
#
# Side effects
#      Teaming configuration gets changed for the given vSwtich.
#
########################################################################

sub SetvSSTeaming
{
   my $self             = shift;
   my $actAdapters      = shift;
   my $failback         = shift;
   my $lbPolicy         = shift;
   my $failureDetection = shift;
   my $notifySwitch     = shift;
   my $result;

   if (not defined $actAdapters) {
      $vdLogger->Error("No vmnic/active-adapter name is provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("ActiveAdapters" => $actAdapters,
                "Failback"       => $failback,
                "LoadBalancing"  => $lbPolicy,
                "NetworkFailureDetection" => $failureDetection,
                "NotifySwitches" => $notifySwitch);

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchNicTeamingPolicy(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("This operation is applicable for vSS only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetTrafficShapingPolicy:
#      This method would configure the Traffic Shaping policy for
#      given VSS/VDS.
#
# Input:
#       shaping-policy - Enable/Disable
#       avg-bandwidth  - (in bits/secs)
#       peak-bandwidth - (in bits/secs)
#       burst-size     - (in Bytes)
#       dvportgroup - The name of the dvportgroup, VDS only
#       shaping_direction - VDS only(in/out)
# Results:
#      "SUCCESS", if traffic shaping policies are set successfully
#       for the given VSS/VDS.
#      "FAILURE", in case of any error.
#
# Side effects
#      Traffic Shaping Policies gets changed for the given VSS/VDS.
#########################################################################

sub SetTrafficShapingPolicy
{
   my $self      = shift;
   my $options   = shift;
   my $policy    = $options->{'operation'};
   my $avg       = $options->{'avg_bandwidth'};
   my $peak      = $options->{'peak_bandwidth'};
   my $burstSz   = $options->{'burst_size'};
   my $dvpg      = $options->{'dvportgroup'};
   my $direction = $options->{'shaping_direction'};
   my $result;

   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->SetVSSTrafficShapingPolicy($policy, $avg, $peak, $burstSz);
      if ($result eq FAILURE) {
         $vdLogger->Error("Fail to set vss traffic shaping");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif ($self->{switchType} =~ /vdswitch/i) {
      $result = $self->SetVdsTrafficShapingPolicy($policy, $avg, $peak, $burstSz, $dvpg, $direction);
      if ($result eq FAILURE) {
         $vdLogger->Error("Fail to set vds traffic shaping");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("The switch type is invalid, should be vswitch or vdswitch");
      $vdLogger->Error("Switch type: " . Dumper($self->{switchType}));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# SetVSSTrafficShapingPolicy:
#      This method would configure the Traffic Shaping policy for
#      given VSS/VDS.
#
# Input:
#       shaping-policy - Enable/Disable
#       avg-bandwidth  - (in bits/secs)
#       peak-bandwidth - (in bits/secs)
#       burst-size     - (in Bytes)
# Results:
#      "SUCCESS", if traffic shaping policies are set successfully
#       for the given vSwitch.
#      "FAILURE", in case of any error.
#
# Side effects
#      Traffic Shaping Policies gets changed for the given VSS.
#########################################################################

sub SetVSSTrafficShapingPolicy
{
   my $self      = shift;
   my $policy    = shift;
   my $avg       = shift;
   my $peak      = shift;
   my $burstSz   = shift;
   my $result;

   if (not defined $policy) {
      $vdLogger->Error("Traffic shaping policy is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($policy =~ /enable/i) {
      if (not defined $avg || not defined $peak ||
          not defined $burstSz || not defined $self) {
         $vdLogger->Error("Shaping parameters not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } elsif ($policy =~ /disable/i) {
      if (not defined $self) {
         $vdLogger->Error("The switch obj not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Shaping policy is invalid, should be enable or disable");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($policy =~ /Enable/i) {
      $vdLogger->Debug("Enable VSS traffic shaping with parameters".
         " avg_bandwidth: $avg, peak_bandwidth: $peak, burst_size: $burstSz");
      $result = $self->SetvSSShaping($avg, $peak, $burstSz);
      if ($result eq FAILURE) {
         $vdLogger->Error("EnableVSSTrafficShaping failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif ($policy =~ /Disable/i) {
      $vdLogger->Debug("Disable VSS traffic shaping");
      $result = $self->ResetvSSShaping();
      if ($result eq FAILURE) {
         $vdLogger->Error("DisableVSSTrafficShaping failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("The value of set_shaping_policy is invalid, should be Enable or Disable");
      $vdLogger->Error("Key set_trafficshaping_policy: " . Dumper($policy));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# SetvSSShaping:
#      This method would set the Traffic Shaping policy for given vSwitch.
#      (only applicable for vSS).
#
# Input:
#
#       avg-bandwidth  (in bits/secs)
#       peak-bandwidth (in bits/secs)
#       burst-size     (in Bytes)
#
# Results:
#      "SUCCESS", if traffic shaping policies are set successfully
#       for the given vSwitch.
#      "FAILURE", in case of any error.
#
# Side effects
#      Traffic Shaping Policies gets changed for the given vSwtich.
#
########################################################################

sub SetvSSShaping
{
   my $self     = shift;
   my $avg      = shift;
   my $peak     = shift;
   my $burstSz  = shift;
   my $anchor   = shift;
   my $result;

   my %input = ("avgbandwidth"  => $avg,
                "peakbandwidth" => $peak,
                "burstsize"     => $burstSz);

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->SetvSwitchShaping(\%input, $anchor);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("This operation is applicable for vSS only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# ResetvSSShaping:
#     This method would disable the Traffic Shaping policy for given
#     vSwitch. (only applicable for vSS).
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if traffic shaping policies are disabled successfully
#       for the given vSwitch.
#      "FAILURE", in case of any error.
#
# Side effects
#      Traffic Shaping Policies gets disabled for the given vSwtich.
#
########################################################################

sub ResetvSSShaping
{
   my $self = shift;
   my $result;

   # this operation is only applicable to vSS.
   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->ResetvSwitchShaping();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("This operation is applicable for vSS only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


#######################################################################
#
# CheckDiscoveryOnESX:
#     This method would verify the status of lldp in ESX server.
#     It makes sure that LLDP info passed by the physical switch is
#     correct.
#
# Input:
#     flag     : Indicates what is expected, possible values are-
#                "yes" which means the lldp info should be present.
#                "no" means the lldp info should not be present.
#     vmnicObj : NetAdapter object for the pnic.
#
# Results:
#      "SUCCESS", if lldp info is correct.
#      "FAILURE", in case lldp info in esx is not correct.
#
# Side effects:
#      None.
#
# Note:
#
# Sample output for LLDP .
#  ~ # vsish -pe get /vmkModules/cdp/pNics/vmnic2/lldpSummary
# {
#   "status" : 1,
#   "timeout" : 0,
#   "samples" : 82125,
#   "chassisID" : "00:21:1b:53:90:8f",
#   "portID" : "Gi0/15",
#   "ttl" : 98,
#   "optTLVNum" : 6,
#   "optTLVLen" : 190,
#   "optTLVBuf" : "
#                  ",
# }
# ~ #
#
#
########################################################################

sub CheckDiscoveryOnESX
{
   my $self = shift;
   my $flag = shift || "yes";
   my $vmnicObj = shift;
   my $protocol = shift || "cdp";
   my $vmnic = $vmnicObj->{vmnic};
   my $host = $vmnicObj->{hostObj}->{hostIP};
   my $tag = "Switch : CheckDiscoveryOnESX : ";
   my $status;
   my $DPInfo;
   my $LLDPInfo;
   my $port;
   my $cmd;
   my $result;

   if (not defined $vmnicObj) {
      $vdLogger->Error("$tag Netadapter hash for vmnic not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($flag !~ m/yes|no/i) {
      $vdLogger->Error("$tag $flag is invalid value, valid ones are ".
                       "'yes' and 'no' ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($protocol !~ m/lldp|cdp/i) {
      $vdLogger->Error("$tag $protocol is invalid value for discovery protocol ".
                       "valid values are 'cdp' and 'lldp'");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # First check that Discovery Protocol status on esx
   # should be LLDP which is "1".
   #
   $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/DPStatus";
   $vdLogger->Info("Getting LLDP information - $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($result->{rc} != 0 && $result->{exitCode} != 0) {
      $vdLogger->Error("$tag Failed to get Discovery protocol info on ".
                       "$host for $vmnic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $DPInfo =  VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                            RESULT => $result->{stdout}
                                            );
   $vdLogger->Debug("DPStatus: " . Dumper($DPInfo));

   if ($DPInfo eq "") {
      if ($flag =~ m/no/i) {
         $vdLogger->Info("$tag information not available as expected");
         return SUCCESS;
      } else {
         $vdLogger->Error("$tag The information is not available for ".
                         "$vmnic via $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   # protocol status should be 1 for lldp and 0 for CDP.
   if ($protocol =~ m/cdp/i) {
      $status = 0;
   } else {
      $status = 1;
   }
   if ($DPInfo->{protocol} eq "$status") {
      $vdLogger->Info("$tag Discovery Protocol is $protocol");
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag Discovery protocol is not $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   # the info status should be 1.
   if ($DPInfo->{infoAvailable} eq "1") {
      if ($flag =~ m/yes/i) {
         $vdLogger->Info("$tag The information is available for $vmnic ".
                         "via $protocol");
      }
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag The information is not available for ".
                         "$vmnic via $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   # command to check discovery protocol info;
   if ($protocol =~ m/lldp/i) {
      $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/lldpSummary";
   } else {
      $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/cdpSummary";
   }

   $vdLogger->Info("Getting $protocol information - $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($result->{exitCode} != 0 ) {
      if ($flag =~ m/no/i) {
         if (defined $result->{stderr}) {
            return SUCCESS;
         }
      } else {
         $vdLogger->Error("$tag Failed to get $protocol Information on ".
                       "$host for $vmnic");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   if (not defined $result->{stdout}) {
      if ($flag =~m/yes/i) {
         $vdLogger->Error("$tag $protocol info in ESX is not defined");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $vdLogger->Info("$tag The ESX host doesn't have $protocol info");
         return SUCCESS;
      }
   }

   $LLDPInfo = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                            RESULT => $result->{stdout}
                                            );

   # The LLDP info should be in Hash, if it is available.
   if (ref($LLDPInfo) !~ /HASH/i) {
      if ($result =~ m/yes/i) {
         $vdLogger->Error("$tag $protocol info is not correct");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   # get the port id of pswitch shown in lldp info.
   my $regex;
   if ($protocol =~ m/lldp/i) {
      $regex = 's*.*i([^"]+)';
   } else {
      $regex = 's*.*Ethernet([^"]+)';
   }

   # cdp has portId while lldp has portID
   my $info;
   if ($protocol =~ m/lldp/) {
      $info = $LLDPInfo->{portID};
   } else {
      $info = $LLDPInfo->{portId};
   }
   if ($info =~ m/$regex/i) {
      $port = $1;
   } else {
      if ($flag =~m/yes/i) {
         $vdLogger->Error("$tag LLDP info is incorrect.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   #
   # now check that port id in LLDP info should be same as
   # the switch port to which pnic is connected.
   #
   if ($port eq $vmnicObj->{switchPort}) {
      if ($flag =~ m/yes/i) {
         $vdLogger->Info("$tag port id in $protocol info for $vmnic is same as ".
                         "the actual port id of the pnic $vmnic");
         return SUCCESS;
       } else {
          $vdLogger->Error("$tag The $protocol info is not expected");
          VDSetLastError("ENOTDEF");
          return FAILURE;
       }
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag port id id in $protocol info for $vmnic is not same ".
                         "as the actual port id of the pnic $vmnic");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }  else {
         return SUCCESS;
      }
   }
}


########################################################################
#                                                                      #
# Method Name: GetPortIDByName                                         #
#                                                                      #
# Objective: To find port ID used by VM                                #
#                                                                      #
# Operation: Take the VM name from the user and return the port IDs of #
#            the vNICs that are connected to the vSwitch               #
#                                                                      #
# Input arguments:                                                     #
#      DisplayName: Name of the VM [Mandatory]                         #
#      All: If defined, then all portIds will be returned under this   #
#           name else first occurence of portID will be returned.      #
#           Accepts either "Y" or "N". Case insensitive. Default is "N"#
#           [Optional]                                                 #
#      vSwitch: Name of the switch from where portIDs are to be        #
#               retrieved. If not defined, default switch name from    #
#               test hash will be used. [Optional]                     #
#                                                                      #
# Output: An array of port IDs on success if "All" is "Y"              #
#         The first port ID on success if "All" is "N"                 #
#         FAILURE on failure                                           #
#                                                                      #
########################################################################

sub GetPortIDByName {
   my $self = shift;
   my $displayname = shift;
   my $all = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $displayname) {
      $vdLogger->Error("No displayname of VM provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("displayname" => $displayname,
                "all" => $all || undef,
                "vswitch" => $vswitch || undef);

   if ($self->{'switchType'} eq "vswitch") {
      $result = $self->{'switchObj'}->GetPortIDByName(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("This operation is applicable for vSS only");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#                                                                      #
# GetTeamUplink:                                                       #
#      To find uplink that is connected to a port. Method gets the port#
#      uplink on a particular vSwitch with a port ID that is specified #
#                                                                      #
# Input:                                                               #
#      PortId: Port ID where the information is required [Mandatory]   #
#      Switch:  Name of the switch from where port ID is connected.    #
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: Returns the uplink name if successful                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub GetTeamUplink {
   my $self = shift;
   my $portId = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for GetTeamUplink");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $switch = $vswitch || $self->{'name'};

   # Creating the command
   my $path = "/net/portsets/$switch/ports/$portId/teamUplink";
   my $command = "vsish -e get $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{'switchObj'}{host},
                                                  "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to list ports under switch $switch");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $res->{stdout}) {
      chomp($res->{stdout});
      return $res->{stdout};
   }
   $vdLogger->Error("Failed to retrieve uplink for port $portId under switch".
                    " $switch");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#                                                                      #
# GetSwitchUplinks:                                                    #
#      Method gets the Switch uplinks that are connected to it         #
#      from the VSI node: /net/portsets/<Switch>/uplinks/              #
#                                                                      #
# Input:                                                               #
#      Switch:  Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional - only for internal method     #
#               calls]                                                 #
#                                                                      #
# Results: Returns the uplink name(s) as an array if successful        #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub GetSwitchUplinks {
   my $self = shift;
   my $vswitch = shift;
   my $result;
   my (@uplink) = ();

   my $switch = $vswitch || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$switch/uplinks/";
   my $command = "vsish -pe ls $path";
   my $host = $self->{'switchObj'}{host};
   my $res = $self->{stafHelper}->STAFSyncProcess($host,
                                                  "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to list uplinks under switch $switch on ".
                       "$host with command:$command");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $res->{stdout}) {
      my $k = 0;
      my @tmp = split(/\n/,$res->{stdout});
      foreach my $i (@tmp) {
         chomp($i);
         chop($i);
         $uplink[$k] = $i;
         $vdLogger->Info("Uplink retrieved for switch $switch = $uplink[$k]");
         $k++;
      }
   }
   if (defined $uplink[0]) {
      return \@uplink;
   }
   $vdLogger->Error("Failed to retrieve uplink for switch $switch");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#                                                                      #
# GetPortClientStats:                                                  #
#       Method gets the ClientStats from the port mentioned            #
#       from the VSI node: /net/portsets/<vSwitch>/ports/              #
#                          <port#>/clientStats                         #
#                                                                      #
# Input:                                                               #
#      port   : Port number from where the clientStats are to be       #
#               retrieved [Mandatory]                                  #
#      vSwitch: Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: Returns the uplink name(s) as an array if successful        #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub GetPortClientStats {
   my $self = shift;
   my $portId = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for GetPortClientStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("portid" => $portId,
                "vswitch" => $vswitch || undef);

   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->{'switchObj'}->GetPortClientStats(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("GetPortClientStats is not supported for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#                                                                      #
# GetPortStatus:                                                       #
#       Method gets the status of the port depending on the user input #
#       from the VSI node: /net/portsets/<vSwitch>/ports/<port#>/status#
#                                                                      #
# Input:                                                               #
#      portid : Port number from where the port status is to be        #
#               retrieved [Mandatory]                                  #
#      param  : Param to be retrieved from port status. Currently      #
#               acceptable values are: [Mandadatory]                   #
#               "cfgName"                                              #
#               "dvPortId"                                             #
#               "clientName"                                           #
#               "clientType"                                           #
#               "clientSubType"                                        #
#               "worldLeader"                                          #
#               "flags"                                                #
#               "ptStatus"                                             #
#               "ethFRP"                                               #
#               "filterFeat"                                           #
#               "filterProp"                                           #
#      vSwitch: Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: Returns the param value if successful                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub GetPortStatus {
   my $self = shift;
   my $portId = shift;
   my $param = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $portId ||
       not defined $param) {
      $vdLogger->Error("Port ID / param not defined for GetPortStatus");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("portid" => $portId,
                "param" => $param,
                "vswitch" => $vswitch || undef);

   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->{'switchObj'}->GetPortStatus(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("GetPortStatus is not supported for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#                                                                      #
# EnableInputStats:                                                    #
#       Method to enable pktSizes sampling at uplink port level through#
#       VSI node: /net/portsets/<vswitch>/ports/<portId>/pktSizes/cmd  #
#                 start input                                          #
#                                                                      #
# Input:                                                               #
#      portid : Port number from where the input stats are to be       #
#               set [Mandatory]                                        #
#      vSwitch: Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: Returns the param value if successful                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub EnableInputStats {
   my $self = shift;
   my $portId = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for EnableInputStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("portid" => $portId,
                "vswitch" => $vswitch || undef);

   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->{'switchObj'}->EnableInputStats(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("EnableInputStats is not supported for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#                                                                      #
# GetPktSizeInputStats:                                                #
#       Method to get pktSize input stats from the VSI node:           #
#       /net/portsets/<vswitch>/ports/<portId>/pktSizes/inputStats     #
#                                                                      #
# Input:                                                               #
#      portid : Port number from where the pktSize inputstats are to be#
#               retrieved [Mandatory]                                  #
#      vSwitch: Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: Returns the result hash if successful                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub GetPktSizeInputStats {
   my $self = shift;
   my $portId = shift;
   my $vswitch = shift;
   my $result;

   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for GetPktSizeInputStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %input = ("portid" => $portId,
                "vswitch" => $vswitch || undef);

   if ($self->{switchType} =~ /vswitch/i) {
      $result = $self->{'switchObj'}->GetPktSizeInputStats(\%input);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $result;
      }
   } else {
      $vdLogger->Error("GetPktSizeInputStats is not supported for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#                                                                      #
# CheckQueAlloc:                                                       #
#       Method to check that a vmknic gets a queue allocated over a NIC#
#       supporting Hw LRO:                                             #
#       1. Get the port ID by name of the vmknic in the host           #
#       2. Check if LRO is supported for particular port               #
#       3. Ensure HwLRO is activated by enabling pktSizes sampling     #
#       4. Check that correct pktSizes are incrementing as per MTU     #
#                                                                      #
# Input:                                                               #
#      pgObj : Port group object of the port group newly created for   #
#              vmknic [Mandatory]                                      #
#      chkHwSwLro: Option to check Hw Sw LRO combination i.e. when     #
#                  Hw LRO will be enabled, Sw LRO should also be       #
#                  enabled and when Hw LRO is disabled, Sw LRO should  #
#                  be enabled. [Optional]                              #
#                                                                      #
# Results: SUCCESS is returned if vmknic gets a queue allocated over a #
#          NIC supporting Hw LRO                                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub CheckQueAlloc {
   my $self = shift;
   my $pgObj = shift;
   my $chkHwSwLro = shift || "N";
   my $vmkObj = shift;
   my $firstPktSize = undef;
   my $lastPktSize = undef;

   if (not defined $pgObj) {
      $vdLogger->Error("PG Object not defined for CheckQueAlloc");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{pgObj} = $pgObj;
   $self->{vmkObj} = $vmkObj;

   # Checking SwLRO
   if ($chkHwSwLro =~ m/y/i) {
      $vdLogger->Info("Getting Sw LRO status");
      my $swLRO = $self->{vmkObj}->GetLROStats();
      if ($swLRO eq FAILURE) {
         $vdLogger->Error("Unable to retrieve Sw LRO status");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($self->{vmkObj}->{LROStats}->{flags} == 1) {
         $vdLogger->Info("Sw LRO is supported");
      } else {
         $vdLogger->Error("Unable to retrieve vmknic port ID");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   my $vmkName = $self->{vmkObj}->{deviceId};

   $vdLogger->Info("Sleeping 150 seconds before starting test to let traffic ".
                   "start properly");
   sleep(150);

   # Getting the port ID of the vmknic as per vmkName after the sleep
   # because the port ID of the vmknic changes once the traffic workload
   # is called since static IPs are assigned to the vmknic in that
   # workload
   $vdLogger->Info("Getting the port ID of the vmknic as per vmk Name");
   my $vmkPortId = $self->GetPortIDByName($vmkName,
                                          "N",
                                          $self->{switchObj}{switch});
   if ($vmkPortId eq FAILURE) {
      $vdLogger->Error("Unable to retrieve vmknic port ID");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Check if port supports LRO
   $vdLogger->Info("Check if port supports LRO");
   my $supLRO = $self->GetPortStatus($vmkPortId,
                                     "filterFeat",
                                     $self->{switchObj}{switch});
   if ($supLRO & 1 != 1) {
      $vdLogger->Error("Port $vmkPortId doesn't support LRO");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Enabling input stats for pktSizes
   $vdLogger->Info("Enabling input stats for pktSizes");
   my $enableInput = $self->EnableInputStats($vmkPortId,
                                             $self->{switchObj}{switch});
   if ($enableInput eq FAILURE) {
      $vdLogger->Error("Unable to enable input stats for port $vmkPortId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Retrieve PktSize input stats
   $vdLogger->Info("Retrieve PktSize input stats");
   my $inputStats = $self->GetPktSizeInputStats($vmkPortId,
                                                $self->{switchObj}{switch});
   if ($inputStats eq FAILURE) {
      $vdLogger->Error("Unable to retrieve input stats for port $vmkPortId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Retrieving first packet size
   $vdLogger->Info("Retrieve first packet size");
   $firstPktSize = $inputStats->{histo}{count};
   if (not defined $firstPktSize) {
      $vdLogger->Error("Unable to retrieve first packet size count");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   sleep(3);

   # Retrieving last packet size
   $vdLogger->Info("Retrieve last packet size");
   $inputStats = $self->GetPktSizeInputStats($vmkPortId,
                                             $self->{switchObj}{switch});

   $lastPktSize = $inputStats->{histo}{count};
   if (not defined $lastPktSize) {
      $vdLogger->Error("Unable to retrieve last packet size count");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Comparing packet sizes
   if ($lastPktSize > $firstPktSize) {
      $vdLogger->Info("LRO queue is allocated for vmknic traffic for host ".
                      "$self->{hostOpsObj}{hostIP} vmknic $vmkName");
      return SUCCESS;
   }

   # In case test case is for Hw Sw LRO combination
   if ($chkHwSwLro =~ m/y/i) {
      $vdLogger->Info("Sw LRO is enabled irrespective of Hw LRO status");
      return SUCCESS;
   } else {
      $vdLogger->Error("LRO queue is not allocated for vmknic traffic in host ".
                       "$self->{hostOpsObj}{hostIP} vmknic $vmkName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# GetActiveVMNic --
#      Method to get active VMNic of the given virtual nic based on 3
#      different algorithms: iphash, srcmac and src virtual port.
#      An algorithm is picked based on the input parameters given.
#
# Input:
#      srcVnic : ip address or mac address or port id of a virtual
#                nic (Required)
#      dstVnic : destination's ip address (Optional, but Required to
#                compute active vmnic using ip hash algorithm)
#
#                If srcVnic is ip address and dstVnic is also given,
#                then ip hash algorithm will be used.
#                If srcVnic is mac address, then src mac algorithm is
#                used.
#                If srcVnic is a port id, then src virtual port
#                algorithm is used.
#      portgroup : specific portgroup name on the switch (Optional)
#      hostObj   : host object associated with active VMNic
#
# Results:
#      Active VMNic (scalar string) of the given the virtual nic,
#        if successful;
#      FAILURE, in case of any errors.
#
# Side effects:
#      None
#
########################################################################

sub GetActiveVMNic
{
   my $self       = shift;
   my $srcVnic    = shift;
   my $dstVnic    = shift;
   my $portgroup  = shift;
   my $hostOpsObj = shift;

   if (not defined $srcVnic) {
      $vdLogger->Error("srcVnic to find active vmnic is not given");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my ($srcMAC, $portID, $srcIP, $dstIP);

   #
   # Check the value of srcVnic to see which algorithm to choose
   # to compute active vmnic.
   #
   if ($srcVnic =~ /(([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2})/i) {
      $vdLogger->Debug("GetActiveVMNic: src mac address " .
                       "$srcVnic address is given");
      $srcMAC = $srcVnic;
   } elsif ($srcVnic =~ /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/i) {
      $srcIP = $srcVnic;
      $vdLogger->Debug("GetActiveVMNic: src ip address " .
                       "$srcVnic is given");
   } elsif ($srcVnic =~ /\d+/) {
      $vdLogger->Info("GetActiveVMNic: assuming src port id " .
                       "$srcVnic is given");
      $portID = $srcVnic;
   } else {
      $vdLogger->Error("Unknown input $srcVnic is given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }


   #
   # Get the list of uplinks on the given switch. This is available from
   # GetTeamingPolicies(), which returns a hash that has list of
   # 'ActiveAdapters'.
   #
   my $teamPolicy = $self->GetTeamingPolicies($portgroup, $hostOpsObj);
   if ($teamPolicy eq FAILURE) {
      $vdLogger->Error("Failed to get uplinks of $self->{switch}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $uplinks;
   $uplinks = $teamPolicy->{'ActiveAdapters'};
   if ($self->{switchType} ne "vswitch") {
      $uplinks = $teamPolicy->{'ActiveAdapters'};
      my @temp;
      foreach my $dvUplink (@$uplinks) {
         #
         # Find the phy uplink names (vmnicX) corresponding to the dvUplinks
         # seen on vdswitch.
         #
         my $vmnic = $hostOpsObj->GetActiveDVUplinkPort($self->{'switch'},
                                                                $dvUplink);

         $vdLogger->Info("vmnic name corresponding to $dvUplink: $vmnic");
         if ($vmnic eq FAILURE) {
            VDCleanErrorStack();
            next;
         }
         push (@temp, $vmnic);
      }
      $uplinks = \@temp;
   }

   if (not defined $uplinks) {
      $vdLogger->Error("Failed to get uplinks");
      return FAILURE;
   }

   my $numOfActiveNics = scalar(@{$uplinks});

   if ($numOfActiveNics == 0) {
      $vdLogger->Error("Number of active vmnics on $self->{switch} is zero");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("number of active vmnics on $self->{switchObj}{'switch'} :" .
                   $numOfActiveNics);

   my $activeNic;
   if (defined $srcMAC) {
      $srcMAC =~ s/^\s|\s$//; # remove any space
      $srcMAC =~ /:([0-9a-fA-F]{2})$/i; # check mac format
      my $lsb = $1;

      if (not defined $lsb) {
         $vdLogger->Error("Check the format of mac address $srcMAC");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      #
      # Algorithm:
      # Grab the LSB of the MAC address % number of Active NIC
      # TEAM_HASHBYTE_FROM_MACADDR(mac) ((mac)[5]) % numActive
      # NIC is selected based on the following: (LSB) % (Number of Active NICs
      # in the team)
      # Example: If we have 3 Active NICs in the team and source MAC of packet
      # is 00:50:56:4A:9B:A6 (LSB) mod (Number of Active NICs in the team) =
      #  A6(Hex) = 10100110 ( Binary ) = 166(Decimal)
      # 166 % 3 = 1 (2nd NIC)
      # 2nd NIC is chosen for this packet
      #

      $activeNic = (hex($lsb) % $numOfActiveNics);
   } elsif (defined $portID) {
      #
      # src virtual port algorithm:
      # Example for Port_ID 33554464:
      # (33554464 >> 1) = 0x1000010,
      # Last byte of 0x1000010 is 0x10
      # (0x10 MOD 3) +1  = 2
      # That means Port with ID 33554464 will use the 2nd active uplink (vmnic2).
      #

      my $rightShift = int($portID) >> 1;
      my $hex = unpack("H*", pack("N", $rightShift));
      $hex =~ /(\d\d$)/;
      $hex =~ /([0-9a-fA-F]{2})$/i;
      my $lastByte = $1;

      $activeNic = (hex($lastByte) % $numOfActiveNics);
   } else {
      my $srcIP = $srcVnic;
      my $dstIP = $dstVnic;
      if ((not defined $srcIP) || (not defined $dstIP)) {
         $vdLogger->Error("Both src and dst ip are needed");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      #
      # ip hash algorithm:
      # XOR the LSB of the two IP addresses (they're in NBO) % number of Active
      # NIC
      # TEAM_HASHBYTE_FROM_IP(ip1, ip2) (((ip1) ^ (ip2)) >> 24) % numActive
      # NIC is selected based on XOR operation of Least Significant Byte(LSB)
      # of the source and destination IP address of the packet.
      # Example: If we have 3 NICs in the team, a packet with source address
      # 10.17.214.108 and destination address 10.17.214.111, then NIC is chosen
      # as below:
      # Binary (108) = 1101100
      # Binary (111) = 1101111
      # XOR 108 and 111 = 0000011 = 3
      # 3 % 3 = 0
      # 1st NIC is chosen ( 0 = 1st NIC, 1 = 2nd NIC, 2 = 3rd NIC )
      #

      my @srcOctets = split(/\./,$srcIP);
      my @dstOctets = split(/\./,$dstIP);

      my $temp = int($srcOctets[3]) ^ int($dstOctets[3]);

      $activeNic = $temp % int($numOfActiveNics);
   }
   $vdLogger->Debug("active nic index/value computed:$activeNic");
   return @$uplinks[$activeNic];
}


########################################################################
#
# GetActiveVMNicUsingEsxTop --
#      Method to get the active uplink of a switch using esxtop/vsish.
#      EsxTop reads vsish nodes, just maintaining the name as esxtop.
#      The active uplink for the given vnic is obtained. If vnic
#      information is not given, then the value (active uplink) for
#      all virtual nics to this switch will be returned.
#      Additionally, if expected vmnic value is given, then the result
#      is checked against that.
#
# Input:
#      expectedVMNic: expected active uplink name (Optional)
#      vnic         : a specific virtual port id (Optional)
#
# Results:
#      Reference to an array of active uplinks, if successful;
#      FAILURE, in case of any errors.
#
# Side effects:
#      None
#
########################################################################

sub GetActiveVMNicUsingEsxTop
{
   my $self          = shift;
   my $expectedVMNic = shift;
   my $vnic          = shift;

   my @activeNicList;

   my $nicList;

   my $switchName;

   $switchName = $self->{switchObj}{'switch'};
   if ($self->{switchType} ne "vswitch" &&
       $switchName !~ /portset/i) {
      $switchName = $self->{hostOpsObj}->GetPortSetNamefromDVS($switchName);
      if ($switchName eq FAILURE) {
         $vdLogger->Error("Failed to get portset name of " .
                          $self->{switchObj}{'switch'});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   if (not defined $vnic) {
      #
      # If a specific virtual port id is not given, then get all virtual ports
      # (vnic) connected to this switch
      #
      my $result = $self->{hostOpsObj}->GetVnicPortIds($switchName);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get vnic port ids on $switchName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $nicList = $result; #list of all port ids
   } else {
      # Take just the given virtual port into the array
      push (@$nicList, $vnic);
   }

   foreach my $adapter (@{$nicList}) {
      #
      # GetActiveVMNicOfvNic() understands port id in absolute
      # format only.
      #
      $adapter = '/net/portsets/' . $switchName . '/ports/' .
                $adapter;

      #
      # Get the actual active uplink of the given adapters.
      #
      my $actualVMNic = $self->{hostOpsObj}->GetActiveVMNicOfvNic($adapter);
      if ($actualVMNic eq FAILURE) {
         $vdLogger->Error("Failed to get active vmnic of $adapter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      push (@activeNicList, $actualVMNic);
      #
      # Check active actual active uplink with expected value
      #
      if (defined $expectedVMNic) {
         if ($expectedVMNic ne $actualVMNic) {
            $vdLogger->Error("Active vmnic $actualVMNic and expected value " .
                             $expectedVMNic . " are different for $adapter");
            VDSetLastError("EMISMATCH");
            return FAILURE;
         }
         $vdLogger->Info("Verified active vmnic $actualVMNic and expected value " .
                         "$expectedVMNic are same for $adapter");
      }
   }
   return \@activeNicList;
}


########################################################################
#
# GetMACTable --
#      Method to retrieve the mac address table from the switch.
#      Applies to Phy switch only.
#
# Input:
#      vmnicObj: Reference to NetAdapter object (Optional)
#
# Results:
#      Reference to an array of lines from mac-address-table,
#        if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetMACTable
{
   my $self = shift;
   my $vmnicObj = shift;

   my $tag = "Switch : GetMACTable: ";
   if ($self->{switchType} !~/pswitch/) {
      #
      # Currently applies only to phy switch, esp Cisco switch.
      # TODO: Remove this comment once method extended to all switches.
      #
      $vdLogger->Error("$tag This is supported only for pswitch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   my $result = $self->{switchObj}->GetMACTable(SWITCH => $self->{switchObj},
                                                  VMNICOBJ => $vmnicObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get mac address table from $self->{name}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# GetPhySwitchPortSetting --
#      Method to retrieve the Port Settings from the physical switch.
#      Applies to Phy switch only.
#
# Input:
#      LogDir: Name of the directory where logs are to be copied.
#
# Results:
#      SUCCESS,  if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetPhySwitchPortSetting
{
   my $self	= shift;
   my $logDir   = shift;
   my $file     = $logDir."/"."Physical_Switch_Configuration";
   my $tag = "Switch : GetPhySwitchPortSetting: ";

   if (not defined $logDir) {
      $vdLogger->Error("Log directory is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->{switchType} !~/pswitch/) {
      #
      # Currently applies only to phy switch, esp Cisco switch.
      #
      $vdLogger->Warn("$tag This is supported only for pswitch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   my $result = $self->{switchObj}->{getphyswitchportsettings}(
                                                  SWITCH => $self->{switchObj},
				                  );
   if ($result eq FAILURE) {
      $vdLogger->Warn("Failed to get physical port settings for: ".
                      "$self->{switchObj}->{switchAddress} ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   open FILE, ">" ,$file;
   foreach my $data (@{$result}) {
      print FILE $data;
   }
   close (FILE);
}


######################################################################
#
# GetUplinkPortgroup--
#     Routine get the uplink portgroup name  from the vds
#     name
#
# Input:
#   Host : Name of the ESX host.
#
# Results:
#     On SUCCESS returns the name of the uplink portgroup.
#     On FAILURE returns the FAILURE.
#
# Side effects:
#     None
#
########################################################################

sub GetUplinkPortGroup
{
   my $self = shift;
   my $host = shift;
   my $switchObj = $self->{switchObj};
   my $result;

   if (not defined $host) {
      $vdLogger->Error("Name of the ESX host is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->{switchType} !~ m/vdswitch/i) {
      $vdLogger->Error("Uplink portgroup is defined only for the vdswitch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $result = $switchObj->GetUplinkPortGroup(HOST => $host);
   if ($result eq FAILURE) {
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      return $result;
   }
}


########################################################################
#
# ConfigureHealthcheck --
#      This method configure healthcheck for the vds. The user can
#      either enable or disable healthcheck for the vds. Users
#      can also specify the interval parameter.
#
# Input:
#      args     : Reference to below parameters
#      Operation: "Enable" if user wants to enable the check,
#                 "Disable" if user wants to disable the check.
#      interval:  Specifies the interval of each check time for the vds.
#      healthcheck_type    : vlanmtu or teaming
#
# Results:
#      "SUCCESS", if configuring healthcheck is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      <None>
#
########################################################################

sub ConfigureHealthcheck
{
   my $self = shift;
   my $args = shift;
   my $operation = $args->{operation};
   my $interval = $args->{interval};
   my $healthcheck_type = $args->{healthcheck_type};
   my $switchObj = $self->{switchObj};
   my $result;

   #
   # healthcheck is supported only for the vds.
   #
   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("Healthcheck is supported only for VDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $result = $switchObj->ConfigureHealthCheck(type => $healthcheck_type,
                                              operation  => $operation,
                                              interval  => $interval);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure $healthcheck_type healthcheck".
                       " to $operation for switch $self->{name}");
      VDSetLastError(VDGetLastError());
      return FAILURE;

   }
   return SUCCESS;
}


########################################################################
#
# ExportImportVDSDVPG --
#      This method exports/imports VDS and/or dvPortGroup configuration.
#
# Input:
#      operation : <exportvds/exportvdsdvpg/exportdvpg
#                  importvds/importvdsdvpg/importdvpg
#                  restorevds/restorevdsdvpg/restoredvpg
#                  importorigvds/importorigvdsdvpg/importorigdvpg>
#
#      dvpgName  : Name of the dvPort-group.
# Results:
#      "SUCCESS", if export operation is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      Creates a backup file/s having VDS and/or dvPortGroup configuration.
#
########################################################################

sub ExportImportVDSDVPG
{
   my $self = shift;
   my $operation = shift;
   my $dvpgName = shift;
   my $switchObj = $self->{switchObj};
   my $result;

   #
   # export configuration is supported only for VDS.
   #
   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("Export VDS is only supported for VDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $result = $switchObj->ExportImportEntity(backuprestore => $operation, dvpgName => $dvpgName);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to perform export/import VDS/DVPG" .
                       "operation for switch $self->{name}");
      VDSetLastError(VDGetLastError());
      return FAILURE;

   }
   return SUCCESS;
}


########################################################################
#
# ConfigureProtectedVM--
#      This method configures protected VM with a given DVFilter
#
# Input:
#      params     : All the parameters required to update the opaque data
#		    in order to configure a dvfilter for a given vnic
#
# Results:
#      "SUCCESS", if filter is updated with no failures
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureProtectedVM
{
   my $self = shift;
   my $params = shift;

   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("ConfigureProtectedVM is only applicable to VDS");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $params) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #The output for $params is too big so change info to Debug .
   $vdLogger->Debug("Switch::ConfigureProtectedVM: params: " . Dumper($params));
   $result = $switchObj->ConfigureProtectedVM($params);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update opaquedata for switch $self->{name}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigurePortRules--
#      This method configures protected VM with a given DVFilter
#
# Input:
#      params     : All the parameters required to update the opaque data
#                   in order to configure a dvfilter for a given vnic
#
# Results:
#      "SUCCESS", if filter is updated with no failures
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigurePortRules
{
   my $self = shift;
   my $params = shift;

   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("ConfigurePortRules is only applicable to VDS");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $params) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #The output for $params is too big so change info to Debug .
   $vdLogger->Debug("Switch::ConfigurePosrtRules: params: " . Dumper($params));
   $result = $switchObj->ConfigurePortRules($params);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update opaquedata for switch $self->{name}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


################################################################################
#
#  RemoveChannelGroup --
#  Remove channel-group on a particular port
#
#  Input:
#  Port : Port number
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub RemoveChannelGroup
{
   my $self = shift;
   my $port = shift;

   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} eq "pswitch") {
      $result = $switchObj->{removechannelgroup}( PORT => $port,
                                                  SWITCH => $switchObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove Channel group on switch");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Remove channel group is currently applicable only to ".
                       "physical switch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
#  SetVLAN --
#   Add / Remove VLAN from a switch DB
#
#  Input:
#   ACTION Add/remove the vlan id
#   SWITCH switch object reference
#   VLAN vlan id to be added to cisco switch database.
#
#  Results
#   If vland id gets set / removed from the switch DB, returns SUCCESS.
#   If failure, FAILURE is returned
#
#  Side effects:
#   vlan id gets added / removed from the switch database.
#
################################################################################

sub SetVLAN
{
   my $self = shift;
   my $action = shift;
   my $vlan = shift;

   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} eq "pswitch") {
      $result = $switchObj->{setvlan}( ACTION => $action,
                                       VLAN   => $vlan,
                                       SWITCH => $switchObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set VLAN properties on switch");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Set VLAN method is currently applicable only to ".
                       "physical switch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# EditMaxPorts
#      This method edits maximum number of ports for host.
#
# Input:
#      Host : IP of hostname of the target host.
#      MaxPorts : Parameter to specify/change max ports.
#
# Results:
#      "SUCCESS", if parameter setting succeeded.
#      "FAILURE", in case of any error while set the parameter.
#
# Side effects:
#      None
#
# Notes:
#      This method will not take effect until host reboots
#
########################################################################

sub EditMaxPorts
{
   my $self = shift;
   my $host = shift;
   my $maxports = shift;
   my $switchObj = $self->{switchObj};
   my $tag = "Switch : EditMaxPorts: ";
   my $result;

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("$tag This operation is only for vds");
      VDSetLastError("ENOTSUP");
   } else {
      $result = $switchObj->EditMAXProxyPorts(HOST => $host,
                                              MAXPORTS => $maxports);
   }

   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to edit max ports on host $host ".
                       " connected to $switchObj->{switch}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Edited maximum number of ports for host $host on ".
                   "$switchObj->{switch}, but you need to reboot host ".
                   "for this change");
   return SUCCESS;
}


########################################################################
#
# SetMonitoring -
#      This method would enable/disable the dvportgroup monitoring
#      for the dvportgroup
#
# Input:
#      dvportgroup object.
#
# Results:
#      "SUCCESS", if monitoring is set sucessfully for dvportgroup.
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub SetMonitoring
{
   my $self = shift;
   my $args = shift;
   my $dvPortgroup = $args->{dvportgroup};
   my $enable = $args->{status};
   my $tag = "Switch : SetMonitoring : ";
   my $result;

   # for vds.
   if ($self->{switchType} eq "vdswitch") {
      if (not defined $dvPortgroup) {
         $vdLogger->Error("dvportgroup not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $result = $dvPortgroup->SetMonitoring(ENABLE => $enable);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed set Monitoring status to $enable ".
                          "for dvportgroup ". $dvPortgroup->{pgName});
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag This is applicable only for VDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


################################################################################
#
#  RemovePortChannel --
#  Remove port-channel from a switch
#
#  Input:
#  PortChannel : Port-channel number
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub RemovePortChannel
{
   my $self = shift;
   my $portChannel = shift;

   if (not defined $portChannel) {
      $vdLogger->Error("Port-channel not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} eq "pswitch") {
      $result = $switchObj->RemovePortChannel( PORTCHANNEL => $portChannel,
                                                     SWITCH => $switchObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove port-channel from switch");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Remove port-channel is currently applicable only to ".
                       "physical switch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
#  GetEtherChannelSummary(%args)
#     Get information about ether channel
#
#  Input:
#     None
#
#  Results
#     Data - in case of success
#     FAILURE in case of error
#
#  Side effects:
#     None.
#
################################################################################

sub GetEtherChannelSummary
{
   my $self = shift;
   my $port = shift;

   if (not defined $port) {
      $vdLogger->Error("Port not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $switchObj = $self->{switchObj};
   my $result;

   if ($self->{switchType} eq "pswitch") {
      $result = $switchObj->{getetherchannelsummary}(switch => $switchObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get etherchannel summary");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Get EtherChannel Summary is currently applicable only to ".
                       "physical switch");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# SetLACP
#      this method sets lacp enable/disable and lacp mode for the
#      given vds.
#
# Input:
#       api - Which API to use, VIM/ESXCLI to configure LACP(optional)
#       operation - enable/disable (mandatory)
#       mode - passive/active (mandatory when operation is enable,
#                              optional otherwise)
#       lagID - lagID to create a LAG (optional)
#       uplinks - uplinks which can join the LAG(optional)
#
# Results:
#
#
########################################################################

sub SetLACP
{
   my $self = shift;
   my %refHash = @_;
   my $switchObj = $self->{switchObj};

   if ($self->{switchType} eq "vdswitch") {
    my $result = $switchObj->SetLACP(%refHash);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to setLACP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Setting LACP is currently applicable only to VDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureNIOCTraffic --
#     Wrapper method to configure NIOC
#
# Input:
#     None
#
# Results:
#     return value of ConfigureNIOCTraffic() in VDSwitch.pm
#
# Side effects:
#     None
#
########################################################################

sub ConfigureNIOCTraffic
{
   my $self = shift;
   return $self->{switchObj}->ConfigureNIOCTraffic(@_);
}


########################################################################
#
# ConfigureVDSUplinkPorts --
#     This method set vds uplink.
#
# Input:
#     vdsuplink   - the given vds uplink number to be set.
#
# Results:
#     "SUCCESS",if set vds uplink works fine
#     "FAILURE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVDSUplinkPorts
{
   my $self = shift;
   my %args = @_;
   my $vdsuplink = $args{numuplinkports};
   my $result = FAILURE;
   my $switchObj = $self->{switchObj};

   if ($self->{switchType} !~ /vdswitch/i) {
      $vdLogger->Error("This operation is only for vds");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $result = $switchObj->ConfigureVDSUplinkPorts(vdsuplink => $vdsuplink);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to set vds uplink");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# AddLinkAggregationGroup
#      This method creates LACP LAG on VDS
#
# Input:
#      Optional params
#      lag
#      lagname
#      lagmode
#      lagtimeout
#      lagloadbalancing
#      lagvlantype
#      lagvlantrunkrange
#      lagnetflow
#      ports
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub AddLinkAggregationGroup
{
   my $self = shift;
   my $arrayOfSpecs =  shift;
   my $result = FAILURE;
   my $tag = "Switch : ConfigureLinkAggregationGroup: ";
   my $switchObj = $self->{switchObj};

   # this is applicable only for vds.
   if ($self->{switchType} =~ /vdswitch/i) {

      $result = $switchObj->AddLinkAggregationGroup($arrayOfSpecs);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag Failed to configure LAG");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("$tag LACP Operation is successful ".
                      "for vds $switchObj->{switch}");
      return $result;
   } else {
      $vdLogger->Error("$tag This operation is not applicable ".
                      "for switch $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return FAILURE;
}

########################################################################
#
# DeleteLinkAggregationGroup
#      This method deletes LACPv2 LAG on VDS
#
# Input:
#      Below are all optional params that can be set while creating lag
#      lagObject (mandatory) - lag which needs to be deleted
#
# Results:
#      "SUCCESS", if lag is deleted
#      "FAILURE", in case of any error,
#
# Side effects:
#
########################################################################


sub DeleteLinkAggregationGroup
{
   my $self = shift;
   my $arrayOfLagObjects = shift ;

   my $result = FAILURE;
   my $switchObj = $self->{switchObj};
   # this is applicable only for vds.

   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->DeleteLinkAggregationGroup($arrayOfLagObjects);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure LAG");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("LACP Operation is successful ".
                      "for vds $switchObj->{switch}");
      return SUCCESS;
   } else {
      $vdLogger->Error("This operation is not applicable ".
                      "for switch $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return FAILURE;
}


########################################################################
#
# GetDVSPortIDForAnyNIC --
#     Method to get DVS port ID for
#     1) vmknic or
#     2) Virtual machine's vnic or
#     3) vmnic
#     For finding the vnic's port id we need to know the VM's name and
#     the ethX associated with the vnic. E.g.
#              Client: 2-rhel53-srv-32-local-18453.eth0
#              DVPortgroup ID: dvportgroup-1129
#              In Use: true
#              Port ID: 9
#
# Input:
#     <client> - Either a vmknic or vNic
#
# Results:
#     A valid port (integer), if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDVSPortIDForAnyNIC
{
   my $self = shift;
   my $hostObj = shift;
   my $client  = shift;

   my $result = FAILURE;
   my $switchObj = $self->{switchObj};
   # this is applicable only for vds.

   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->GetDVSPortIDForAnyNIC($hostObj, $client);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to DVSPortID for $client");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("This operation is not applicable ".
                      "for switch $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return FAILURE;
}


########################################################################
#
# GetInlineDVS --
#     Method to get InlineDVS
#
# Input:
#
# Results:
#     return GetInlineDVS, if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetInlineDVS
{
   my $self = shift;
   my $switchObj = $self->{switchObj};
   # for vds.
   if ($switchObj->{switchType} eq "vdswitch") {
      return $switchObj->GetInlineDVS();
   } else {
      $vdLogger->Error("This api is applicable only for VDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# EnableDisableVXLAN --
#     Method to get enable/disable VDL2/VXLAN on a VDS using vdl2.jar
#
# Input:
#
# Results:
#     return GetInlineDVS, if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub EnableDisableVXLAN
{
   my $self = shift;
   my $result = FAILURE;
   my $switchObj = $self->{switchObj};
   # this is applicable only for vds.

   if ($self->{switchType} =~ /vdswitch/i) {
      $result = $switchObj->EnableDisableVXLAN(@_);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to EnableDisableVXLAN on VDS");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("This operation is not applicable ".
                      "for switch $self->{switchType}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return FAILURE;
}


########################################################################
#
# ConfigureIpfix --
#      This method would pass the arguments to VDSwitch to configure
#      Ipfix.
#
# Input:
#      args, the hash passed in from the workload as following
#        ipfix         : add or remove the ipfix configuration
#        collector     : vnic object of the ipfix collector,
#        addressFamily : ipv6 or ipv4,if set to ipv6, use the ipv6 address
#                        of the collector,else use the ipv6 address
#        activetimeout : the time after which active flows are
#                        automatically exported to the ipfix collector,
#                        default is 60 seconds.
#        idletimeout   : the time after which idle flows are automatically
#                        exported to the ipfix collector, the default is
#                        15 seconds.
#        samplerate    : The Ipfix will sample a packet per samplerate
#
# Results:
#      "SUCCESS", if ipfix has been configured on the vds
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################


sub ConfigureIpfix
{
   my $self = shift;
   my %args = @_;
   my $result;
   my $switchObj = $self->{switchObj};

   $result = $switchObj->ConfigureIpfix(%args);
   if ($result eq FAILURE) {
      $vdLogger->Error("configure vds ipfix failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Successfully configured ipfix for ".
                   "$switchObj->{switch}");
   return SUCCESS;
}

#############################################################################
#
# CheckAutoscaleVSwitch:
#       Check for Autoscale switches
#
#
# Input:
#      autoscale:    true/false
#
# Results: SUCCESS if the vswitch is autoscale
#          FAILURE on failure
#
##############################################################################

sub CheckAutoscaleVSwitch
{

   my $self = shift;
   my $autoscale = shift;
   my $vswitch = $self->{name};    # switch name

   if (not defined $autoscale ) {
      $vdLogger->Error("autoscale is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Get maxPortsSystemWide
   my $command = "vsish -pe get /net/maxPortsSystemWide";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get maxPortsSystemWide");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $result->{stdout} =~ /(\d+)/;
   my $MaxPortsSystemWide = $1;
   # get numPorts
   $command = "esxcli network vswitch standard list -v ". $vswitch . "\| grep " .
                                       "\"Num Ports\" ";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get Num Ports of Host");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $result->{stdout} =~ /Num Ports:\s+(\d+)/;
   my $ports = $1;
   $vdLogger->Debug("ports = $ports maxport = $MaxPortsSystemWide");
   if ($autoscale eq "true") {
      if ($ports == $MaxPortsSystemWide) {
        $vdLogger->Debug("Autoscale vswitch verification passed");
        return SUCCESS;
      } else  {
        $vdLogger->Debug("Autoscale vswitch verification failed");
        return FAILURE;
      }
   } elsif ($autoscale eq "false") {
       if($ports != $MaxPortsSystemWide) {
        $vdLogger->Debug("Non Autoscale vswitch verification passed");
         return SUCCESS;
       } else {
        $vdLogger->Debug("Non Autoscale vswitch verification failed");
         return FAILURE;
       }
   } else {
        return FAILURE;
   }
}


################################################################################
#
# UpdateDVSMaxPorts:
#    edit  MaxPorts
#
# Input:
#    Hash with key host, Proxyports
#
# Results: SUCCESS if maxports has been updated
#          else FAILURE
#
################################################################################

sub UpdateDVSMaxPorts
{
   my $self = shift;
   my %args = @_;
   my $host = $args{host};
   my $maxports = $args{proxyports};

   $vdLogger->Debug("UpdateDVSMaxPort ". Dumper(%args));
   if (not defined $host) {
      $vdLogger->Error(" host IP $host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $switchObj = $self->{switchObj};

   $vdLogger->Debug("host: $host, maxports: $maxports");
   my $result = $self->EditMaxPorts($host, $maxports);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to edit max ports on host $host ".
                       " connected to $switchObj->{switch}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# UpdateNextServer --
#      Update NextServer with new VCVA IP address
#
# Input:
#      updatenextserver:  esx server name
#      vc              :  vc Object
#
# Results:
#      Returns "SUCCESS", if update success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub UpdateNextServer
{
   my $self      = shift;
   my %args      = @_;
   my $servername  = $args{updatenextserver};
   my $vcObj       = $args{vc};

   my $pswitchObj;

   $vdLogger->Debug("Enter UpdateNextServer");

   my $nextserver  =   $vcObj->{vcaddr};

   if ($self->{switchType} =~ /pswitch/i) {
      $pswitchObj = $self->{switchObj};
   } else {
      $vdLogger->Error("Failed to find pswitch object");
      $vdLogger->Error(VDGetLastError());
      return FAILURE;
   }

   my $result = $pswitchObj->{updateNextServer}(
      SWITCH =>$pswitchObj,
      SERVERNAME => $servername,
      NEXTSERVER => $nextserver);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update Nextserver");
      $vdLogger->Error(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureMulticastFilteringMode --
#     Wrapper method to configure multicast filtering mode
#
# Input:
#     mode -- legacyFiltering/snooping (required)
#
# Results:
#     return value of ConfigureMulticastFilteringMode() in VDSwitch.pm
#
# Side effects:
#     None
#
########################################################################

sub ConfigureMulticastFilteringMode
{
   my $self = shift;
   my $mode = shift;
   return $self->{switchObj}->ConfigureMulticastFilteringMode($mode);
}


########################################################################
#
# ConfigureNIOC
#      This method enable/disable NIOC feature in specified VDS.
#
# Input:
#      state: enable or disable NIOC
#      version: NIOC version(version2/version3)
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
#########################################################################

sub ConfigureNIOC
{
   my $self = shift;
   my $state = shift;
   my $version = shift;

   # nioc is supported for vds only.
   if ($self->{switchType} !~/vdswitch/i) {
      $vdLogger->Error("This operation is applicable only for vDS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   my $result;
   my $switchObj = $self->{switchObj};

   $result = $switchObj->ConfigureNIOC($state,$version);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure NIOC on Switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully $state"."d NIOC");
   return SUCCESS;
}


########################################################################
#
# SetSecurityPolicy
#     Method to enable/disable portgroup security policy change on the DVS
#
# Input:
#      securitypolicy : enable or disable(required)
#      virtualwire    : virtual wire object used to get id(required)
#      policytype     : ALLOW_PROMISCUOUS, MAC_CHANGE or FORGE_TRANSMITS
#                          (required)
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
#########################################################################

sub SetSecurityPolicy
{
   my $self = shift;
   my %args = @_;
   my $result;
   my $switchObj = $self->{switchObj};

   $result = $switchObj->SetSecurityPolicy(%args);
   if ($result eq FAILURE) {
      $vdLogger->Error("configure vds mac address change security policy failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Successfully configured security policy for ".
                   "$switchObj->{switch}");
   return SUCCESS;
}

########################################################################
#
# ConfigureLLDPIPv6Addr --
#     Method to configure IPv6 address advertised by LLDP.
#
# Input:
#     A hash with following keys:
#     lldpipv6addr - the IPv6 address advertised out(required)
#     sourcehost - the host sends out the LLDP information(required)
#
# Results:
#     SUCCESS, if configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureLLDPIPv6Addr
{
   my $self = shift;
   my %args = @_;
   my $result;
   my $switchObj = $self->{switchObj};

   $result = $switchObj->ConfigureLLDPIPv6Addr(%args);
   if ($result eq FAILURE) {
      $vdLogger->Error("configure lldp ipv6 address failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Successfully configured lldp ipv6 address for ".
                   "$switchObj->{switch}");
   return SUCCESS;
}


########################################################################
#
# RemoveHosts--
#     Interface to remove host from switch. After checking switch type
#     is vdswitch, it calls vdswitch object's RemoveHostsFromVDS method
#
# Input:
#     hostArrayRef : Reference to an array of host objects
#
# Results:
#     FAILURE, if self type is not 'vdswitch', or
#     result of RemoveHostsFromVDS of vdswitch.
#############################################################################

sub RemoveHosts
{
   my $self = shift;
   my $hostArrayRef = shift;

   if ($self->{switchType} ne "vdswitch") {
      $vdLogger->Error("Removing host operation can be supported by vdswitch only.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $self->RemoveHostsFromVDS($hostArrayRef);
}


#############################################################################
#
# GetName--
#     Method to get switch name.
#
# Input:
#     None
#
# Results:
#     switch's name
#
# Side effects:
#     None
#
########################################################################

sub GetName
{
   my $self = shift;

   return $self->{name};
}


#############################################################################
#
# CheckAdaptersStatus--
#     Method to check the vmnics status.
#
# Input:
#     vmnic - The target vmnic
#     status - The expect status, including active, standard, unused
#
# Results:
#     SUCCESS - The status of vmnic is as expect
#     FAILURE - In case of any error
#
# Side effects:
#     None
#
#############################################################################

sub CheckAdaptersStatus
{
   my $self = shift;
   my $vmnicList = shift;
   my $expStatus = shift;
   my $curStatus = undef;
   my $vSwitch;

   my $switchObj = $self->{switchObj};
   my $result;

   my $switchType = $self->{switchType};
   if ($switchType !~ /vswitch/i) {
      $vdLogger->Error("The switch type is not vswitch");
      $vdLogger->Debug("Switch type: " . Dumper($switchType));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ((not defined $vmnicList) || (scalar(@$vmnicList) == 0)) {
      $vdLogger->Error("The vmnicList is invalid, not defined or empty");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $result = $switchObj->CheckAdapterListStatus($vmnicList, $expStatus);
   if ($result eq FAILURE) {
      $vdLogger->Error("Fail to check the vmnics status");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# MirrorSession --
#     Interface to add/remove/edit mirror session. It calls vdswitch
#     object's corresponding method
#
# Input:
#     args : hash to necessary parameters to add/remove/edit mirror
#            session look 'VDSwitch.pm' for corresponding function
#            to know the parameters detail
#
# Results:
#     Result of corresponding method of vdswitch if its type is vds, or
#     FAILURE, if none of above type
#
# Side effects:
#     None
#
########################################################################

sub MirrorSession
{
   my $self = shift;
   my $args = shift;
   my $switchObj = $self->{switchObj};

   if ($self->{switchType} eq "vdswitch") {
      if (not defined $args->{operation}) {
         $vdLogger->Error("Operation type not specified!");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $opt = $args->{operation};
      if ($opt =~ /add/i) {
         return $switchObj->CreateMirrorSession($args);
      } elsif ($opt =~ /edit/i) {
         return $switchObj->EditMirrorSession($args);
      } elsif ($opt =~ /remove/i) {
         return $switchObj->RemoveMirrorSession($args);
      } else {
         $vdLogger->Error("Operation type $opt not supported!");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   $vdLogger->Error("Your switch type <$self->{switchType}> does not " .
      "support MirrorSession operation!");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}

1;
