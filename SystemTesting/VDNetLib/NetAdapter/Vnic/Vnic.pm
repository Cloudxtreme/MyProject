#!/usr/bin/perl
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::NetAdapter::Vnic::Vnic;
# The NetAdapter Class defines an network adapter on a machine, be it
# on a host or a virtual machine. The NetAdapter object created could be
# an adapter in the local machine or in a remote machine based on the
# controlIP value passed when creating the object.
# All the methods called on a NetAdapter object will be executed
# locally/remotely using the actual method implemented in netDiscover package.
# This class implementation is somewhat similar to RPC. Therefore, any method
# defined in NetAdapter class should actually be implemented in NetDiscover.pm
# remoteAgent.pl is a helper program on the remote/end machine
# which executes the equivalent method defined in netDiscover.pm
#
#    |-----------|      |   |--------------|
#    | NetAdapter|      |   |  netDiscover |    SetMTU()
#    |-----------|      |   |--------------|    GetMTU()
#         | SetMTU()    |         /\               :
#         | GetMTU()    |        /||\              :
#         |    :        |         ||
#    |-----------|      |   |----------------|
#    | localAgent|==========|  remoteAgent   |
#    |-----------|      |   |----------------|
#                       |
#                       |
#                       |
#                       |
#                       |
#                       |
#    Controller         |    Test machine
#
#
#
# This class defines following attributes and methods
# Attributes:
#       controlIP - control ip address to be used for a adapter
#       name      - name of the adapter/interface
#       interface - unique way to identify an adapter
#                   eth0, eth1, ... in case of linux
#                   deviceID/GUID in case of windows
#       nicType   - attribute that identifies whether
#                   the adapter belongs to test subnet
#                   or control subnet
# Methods:
#       new() - constructor which creates an instance of this class
#       GetAllAdapters() - returns all adapters in the end machine
#       GetAdapterName() - returns adapter's name
#       GetMTU() - returns MTU size of the adapter
#       SetMTU() - sets the user specified MTU size
#       GetVLANId() - returns vlan ID of the adapter
#       SetVLAN() - configures vlan on the given adapter
#       RemoveVLAN() - deletes the vlan configuration on the given adapter
#       GetIPv4() - returns the IPv4 address
#       SetIPv4() - sets the given IP address to an adapter
########################################################################

my $version = "1.0";

use strict;
use warnings;
use Data::Dumper;
use PLSTAF;
# Inheriting from VDNetLib::NetAdapter::NetAdapter package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::NetAdapter::NetAdapter);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError
                                   VDGetLastError VDCleanErrorStack );
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use constant STANDBY_TIMEOUT => 120;
use constant DEFAULT_SLEEP => 20;
use constant DISCOVER_ADAPTERS_TIMEOUT => "300";
use VDNetLib::NetAdapter::Vnic::VlanInterface;
use VDNetLib::NetAdapter::Vnic::IpInterface;
use base 'VDNetLib::Root::Root';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use constant OSTYPE => VDNetLib::Common::GlobalConfig::GetOSType();
use constant OS_LINUX => 1;
use constant OS_WINDOWS => 2;
use File::Basename;

########################################################################
#
# new -
#       This is the constructor module for NetAdapterClass
#
# Input:
#       IP address of a control adapter (required)
#       Interface (ethx in linux, GUID in windows) (Required)
#
# Results:
#       An instance/object of NetAdapter class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   # TODO
   # Currently vmControlIP, interface (ethx in linux, GUID in windows uniquely
   # defines a NetAdapter object. This constructor has to be modified to get a
   # pre-defined hash as Input which will specify driver/adapter name
   # (vmxnet2/vlance/vmxnet3/e1000) and also other configuration details like
   # IPv4, TSO, VLAN etc. Given that input, the constructor is expected to
   # return a NetAdapter object with specific adapter type with all other
   # configuration changes made as specified in the hash or set to default
   # values.
   my $class = shift;
   my %args = @_;
   my $self = {
      controlIP => undef,
      name => undef,
      interface => undef,
      macAddress => undef,
      nicType => undef,
      ndisVersion => undef,
      name => undef,
      vmOpsObj => undef,
      pgObj => undef,
      deviceLabel => undef,
      @_,
   };
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = "vmware.vsphere.vm.vnic.vnic_facade." .
                       "VnicFacade";

   #
   # Key parentObj below is used to store parent vnic object after vlan
   # interface creation;
   #
   $self->{'parentObj'} = $self->{vmOpsObj};
   if (not defined $args{parentObj}) {
      $vdLogger->Warn("Parent object not provided for Vnic");
   }
   bless $self, $class;
   #
   # encapsulate device ID in windows with ^, since STAF throws error when
   # the curly braces in the device id are used
   #   if ((defined $self->{'interface'}) && ($self->{'interface'} =~ "{")) {
   #      $self->{'interface'} = "^" . $self->{'interface'} . "^";
   #   }
   # The step above was required only when the command was not wrapped using
   # STAF::WrapData() method. Now that vdnet uses new STAFHelper.pm which
   # always wrap data, the step above is no more required.
   #

   if (not defined $self->{'vmOpsObj'}) {
      $vdLogger->Error("Failed to get VM object, Can't create NetAdapter object");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $self->{'intType'} = (not defined $self->{'intType'}) ? "vnic" :
                        $self->{'intType'};

   my $vmObj = $self->{'vmOpsObj'};
   return $self;
}


########################################################################
#
# SetInterface -
#       set the interface attribute of vnic
#
# Input:
#       interface - interface string
#
# Results:
#     "SUCCESS", set the interface attribute of vnic
#     "FAILURE", in case of error
#
# Side effects:
#     none
#
########################################################################

sub SetInterface
{
   my $self          = shift;
   my $interface     = shift;
   if (not defined $interface) {
      $vdLogger->Error("Interface not defined");
      VDSetLastError("EINVALID");
         return FAILURE;
      }
   $self->{'interface'} = $interface;
   return SUCCESS;
   }


########################################################################
#
# SetControlIP -
#       set the interface attribute of vnic
#
# Input:
#       controlIP - ip address
#
# Results:
#     "SUCCESS", set the interface attribute of vnic
#     "FAILURE", in case of error
#
# Side effects:
#     none
#
########################################################################

sub SetControlIP
{
   my $self          = shift;
   my $controlIP     = shift;
   if (not defined $controlIP) {
      $vdLogger->Error("The controlIP not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
      }
   $self->{'controlIP'} = $controlIP;
   return SUCCESS;
}


########################################################################
#
# SetMACAddress --
#     Method to set mac address
#
# Input:
#     macAddress: mac address of the vnic
#
# Results:
#     "SUCCESS", set the interface attribute of vnic
#     "FAILURE", in case of error
#
# Side effects:
#     None
#
########################################################################

sub SetMACAddress
{
   my $self          = shift;
   my $macAddress     = shift;
   if (not defined $macAddress) {
      $vdLogger->Error("mac address not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{'macAddress'} = $macAddress;
   return SUCCESS;
}


sub GetAllAdapters
{
   my $self          = shift;
   my $filter        = shift || "all";
   my $adaptersCount = shift;
   my $args;
   my $timeout       = DISCOVER_ADAPTERS_TIMEOUT;

   if (not defined $self->{'controlIP'}) {
      $vdLogger->Error("Insufficient arguments");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (defined $filter) {
      $args = $self->{'controlIP'} . "," . $filter;
   } else {
      $args = $self->{'controlIP'};
   }

   if (defined $adaptersCount) {
      $args = $args . "," .  $adaptersCount;
   }
   if ((defined $self->{'vmOpsObj'}) && (defined $self->{'vmOpsObj'}{'os'}) &&
       ($self->{'vmOpsObj'}{'os'} =~ /win/i)) {
      $timeout = $timeout * 2;
   }
   my $return = ExecuteRemoteMethod($self->{'controlIP'},
                                            "GetAdapters",
                                            $args,
                                            $timeout);
   return ($return ne FAILURE) ? @{$return} : FAILURE;
}


########################################################################
#
# GetAllAdapters -
#       Function that returns an array of adapters in the machine referred by
#       Control IP. If device filter is specified, then only one adapter of
#       type requested is returned. The return value is a blessed
#
# Input:
#       - IP address of a control adapter (required)
#       - Device filter (all/vlance/e1000/e1000e/vmxnet2/vmxnet3 or
#                        a specific mac address) (required)
#       - adaptersCount: number of adapters to discover (optional)
#
# Results:
#       An array of objects of NetAdapter class, if no filter is given or
#         an instance/object of NetAdapter class of type = device filter,
#         if device filter is passed
#       "FAILURE", in case of error
#
# Side effects:
#       Disables all data adapters (except control adapters) if device filter
#       is passed
#
########################################################################

sub GetAllNestedEsxAdapters
{
   my $self          = shift;
   my $filter        = shift || "all";
   my $adaptersCount = shift;
   my $args;
   my $timeout       = DISCOVER_ADAPTERS_TIMEOUT;

   if (not defined $self->{'controlIP'}) {
      $vdLogger->Error("Insufficient arguments");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (defined $filter) {
      $args = $self->{'controlIP'} . "," . $filter;
   } else {
      $args = $self->{'controlIP'};
   }

   if (defined $adaptersCount) {
      $args = $args . "," .  $adaptersCount;
   }
   if ((defined $self->{'vmOpsObj'}) && (defined $self->{'vmOpsObj'}{'os'}) &&
       ($self->{'vmOpsObj'}{'os'} =~ /win/i)) {
      $timeout = $timeout * 2;
   }
   $vdLogger->Info("The vmobj is =============== $self->{vmOpsObj}");
   $vdLogger->Info("The args::::::::::::::::::::::: $self->{'controlIP'}, $args, $timeout");
   my $vmobj = $self->{'vmOpsObj'};
  # while(my($k,$v)=each$vmobj){print "$k--->$v\n";}
   #my $return = ExecuteRemoteMethod($self->{'controlIP'},
   #                                         "GetAdapters",
   #                                         $args,
   #                                         $timeout);
   my $cmd = "esxcli network nic list";
   my $cmd_vmk = "esxcli network ip interface ipv4 get";
   my $return = $self->{'vmOpsObj'}->{'stafHelper'}->STAFSyncProcess("10.115.174.217", $cmd);
   my $return_vmk = $self->{'vmOpsObj'}->{'stafHelper'}->STAFSyncProcess("10.115.174.217", $cmd_vmk);
#   if ($return eq FAILURE) {
#      $return = $self->{'vmOpsObj'}->{'stafHelper'}->STAFSyncProcess("10.115.174.217", $cmd);
#   }
   #$vdLogger->Info("The result is 1111111111 $return");
 #  while(my($k,$v)=each(%$return)){print"return $k--->$v\n";}
   my @stdout_info = split(/\r?\n/, $return->{'stdout'});
   my @vmk_stdout = split(/\r?\n/, $return_vmk->{'stdout'});
   my @nic_info_array;
   my $info_array;
   my $vmk_info_array;
#   foreach $info_array (@stdout_info){
   my $index;
   for ($index = 0;$index < scalar(@vmk_stdout); $index++) {
#      if ($index eq 2) {
#         $info_array = $stdout_info[$index];
#      } else {
#         $info_array = $stdout_info[scalar(@stdout_info)-1];
#      }
      $info_array = $stdout_info[$index];
      $vmk_info_array = $vmk_stdout[$index];
      if($info_array =~ /vmnic/i) {
         my @nic_info = split(/\s+/,$info_array);
         my @vmk_info =  split(/\s+/,$vmk_info_array);
         my $interface = $nic_info[0];
         my $deviceName = $nic_info[0];
         my $ipv4 = $vmk_info[1];
         my $macAddress = $nic_info[7];
         my $adminState = 'UP';
         my $hwid = 'NULL';
        
           my  %resultHash =
             ( interface  => $interface, name => $deviceName,
              macAddress => $macAddress,  ipv4 => $ipv4,
              adminstate => $adminState, hwid => 'NULL',
              nicType => 'NULL', controlIP => $self->{'controlIP'},
           );
         #$nic_info_hash->{macAddress} = $nic_info[7];
         #$nic_info_hash->{interface}  = $nic_info[0];
   #      %nic_info_hash = ('macAddress' => $nic_info[7], 'interface' => $nic_info[0]);
    #     while(my($k,$v)=each%nic_info_hash){print"$k--->$v\n";}
         push(@nic_info_array, \%resultHash);
       #  $nic_info_hash->{controlIP}  = $nic_info[
      }
   }
   return @nic_info_array;
#   return ($return ne FAILURE) ? @{$return} : FAILURE;
}


########################################################################
#
# GetAdapterStats -
#       Function that returns the stats (ethtool -S <interface>) of the
#       specific adapter.
#
# Input:
#       - IP address of a control adapter (required)
#       - Name of the adapter.
#
# Results:
#   Dumps the adapter stats on success.
#   on failure FAILURE is returned.
#
########################################################################

sub GetAdapterStats
{
   my $self          = shift;
   my $logDir        = shift;
   my $adapter       = $self->{interface};
   my $file          = $logDir."/".$adapter."_"."stats";

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $logDir) {
      $vdLogger->Error("Log directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $return = ExecuteRemoteMethod($self->{controlIP},
                                    "GetAdapterStats",
                                    $adapter
                                    );

   if ($return ne FAILURE) {
      open(FILE, ">", $file);
      print FILE "Stats for $adapter\n\n";
      print FILE $return;
      close (FILE);
   } else {
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetAdapterEEPROMDump -
#       Function that returns the EEPROM dump of the specific adapter.
#
# Input:
#       - IP address of a control adapter (required)
#       - Name of the adapter.
#
# Results:
#   Returns SUCCESS if we are able to get the eeprom data.
#   Returns FAILURE if we fail to get the eeprom data.
#
########################################################################

sub GetAdapterEEPROMDump
{
   my $self          = shift;
   my $logDir        = shift;
   my $adapter       = $self->{interface};
   my $file          = $logDir."/"."eepromDump"."_".$adapter;

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $logDir) {
      $vdLogger->Error("Log directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $return = ExecuteRemoteMethod($self->{controlIP},
                                    "GetAdapterEEPROMDump",
                                    $adapter);

   if ($return ne FAILURE) {
      open(FILE, ">", $file);
      print FILE "EEPROM Dump for $adapter\n\n";
      print FILE $return;
      close (FILE);
   } else {
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetAdapterRegisterDump -
#       Function that returns the Register dump of the specific adapter.
#
# Input:
#       - IP address of a control adapter (required)
#       - Name of the adapter.
#       - Log directory.
#
# Results:
#   Returns SUCCESS if register dump is retreived correctly.
#   Returns FAILURE if we fail to get the register dump.
#
########################################################################

sub GetAdapterRegisterDump
{
   my $self          = shift;
   my $logDir        = shift;
   my $adapter       = $self->{interface};
   my $file          = $logDir."/"."registerDump"."_".$adapter;

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specified");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $logDir) {
      $vdLogger->Error("Log directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $return = ExecuteRemoteMethod($self->{controlIP},
                                    "GetRegisterDump",
                                    $adapter
                                    );

   if ($return ne FAILURE) {
      open(FILE, ">", $file);
      print FILE "Register Dump for $adapter\n\n";
      print FILE $return;
      close (FILE);
   } else {
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetNetworkConfig -
#       Function that returns the Network config of the vm (equivalent
#       of ifconfig -a, route -n)
#
# Input:
#       logDir - where the network config file is to be be created
#
# Results:
#       FAILURE - in case of error
#       SUCCESS - if route information is obtained
#
########################################################################

sub GetNetworkConfig
{
   my $self    = shift;
   my $logDir  = shift;
   my $file;
   if(-d $logDir) {
      $file = $logDir."/"."Network_Config";
   } else {
      $file = $logDir;
   }


   if (not defined $self->{controlIP}) {
      $vdLogger->Error("Control IP address of the vm not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $logDir) {
      $vdLogger->Error("logging directory not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $return = ExecuteRemoteMethod($self->{controlIP},
                                    "GetNetworkConfig");
   if ($return ne FAILURE) {
      open(FILE, ">", $file);
      print FILE "Network Configuration\n\n";
      print FILE $return;
      close (FILE);
   }

   return SUCCESS;
}


########################################################################
#
# GetRouteConfig -
#       Function that returns the route config of the vm (equivalent
#       of route print and route -n)
#
# Input:
#       logDir - where the route config file is to be be created
#
# Results:
#       FAILURE - in case of error
#       SUCCESS - if route information is obtained
#
########################################################################

sub GetRouteConfig
{
   my $self    = shift;
   my $logDir  = shift;
   my $file;
   if(-d $logDir) {
      $file = $logDir."/"."Route_Config";
   } else {
      $file = $logDir;
   }


   if (not defined $self->{controlIP}) {
      $vdLogger->Error("Control IP address of the vm not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $logDir) {
      $vdLogger->Error("logging directory not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # get route config
   my $return = ExecuteRemoteMethod($self->{controlIP},
                                    "GetRouteConfig");
   if ($return ne FAILURE) {
      open(FILE, ">", $file);
      print FILE "Route Table\n\n";
      print FILE $return;
      close (FILE);
   } else {
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetDriverName -
#       This method returns driver name (vlance/vmxnet2/vmxnet3/e1000) of the
#       given adapter
#
# Input:
#       None
#
# Results:
#       Adapter/Driver name is returned
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetDriverName
{
   my $self = shift;
   my $args = $self->{'interface'};
   if (not defined $args) {
      $vdLogger->Error("Interface undefined for GetDriverName.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $self->{driver} = ExecuteRemoteMethod($self->{'controlIP'},
                                         "GetDriverName",
                                         $args);
   if (not defined $self->{driver}) {
      $vdLogger->Error("Failed to get driver name for $args.");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   }
   $self->{name} = $self->{driver};
   return $self->{driver};
}


########################################################################
#
# GetDriverVersion -
#       This method returns the driver version of the given adapter
#
# Input:
#       None
#
# Results:
#       Adapter/Driver version is returned
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetDriverVersion
{
   my $self = shift;
   my $args = $self->{'interface'};
   return ExecuteRemoteMethod($self->{'controlIP'},
                              "GetDriverVersion",
                              $args);
}


########################################################################
#
# GetMTU -
#       This method returns Maximum frame size (MTU) currently allowed by
#       the adapter
#
# Input:
#       None
#
# Results:
#       MTU size (in bytes) is returned
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetMTU
{
   my $self = shift;
   my $args = $self->{'interface'};
   return ExecuteRemoteMethod($self->{'controlIP'}, "GetMTU", $args);
}


########################################################################
#
# SetMTU -
#       This method sets the Maximum frame size (MTU) of the adapter
#
# Input:
#       MTU size in bytes
#
# Results:
#       "SUCCESS", if the given MTU size is set
#       "FAILURE", in case of error
#
# Side effects:
#       Setting MTU requires resetting adapters, therefore IP details if
#       configured using DHCP might be changed
#
########################################################################

sub SetMTU
{
   my $self = shift;
   my $mtuSize = shift;

   if (not defined $mtuSize) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   # Check if the MTU size is within 0-16111
   # The end value is 16111 because e1000 supports max of 16110
   # on Linux
   if ($mtuSize =~ /^(\d\d?\d?\d?\d?)$/) {
      if (($1 < 0) || ($1 > 16111)) {
         $vdLogger->Error("MTU size out of range");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid MTU size:$mtuSize");
         VDSetLastError("EINVALID");
         return FAILURE;
   }

   my $args = $self->{'interface'} . "," . $mtuSize;
   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "SetMTU",
                                          $args);
}


########################################################################
#
# GetIPv4 -
#       This method returns the IPv4 address configured for the
#       adapter/interface
#
# Input:
#       None
#
# Results:
#       IPv4 address, if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetIPv4
{
   my $self = shift;
   my $args = $self->{'interface'};
   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "GetIPv4",
                                          $args);
}

########################################################################
#
# SetIPv4 -
#       This method configures given IPv4 address, netmask, to the given
#       adapter/interface
#
# Input:
#       IPv4 Address - in the format xx.xx.xx.xx (required)
#       Netmask - in the format xx.xx.xx.xx (required)
#
# Results:
#       "SUCCESS", if the given IPv4 address, netmask is set
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetIPv4
{
   my $self = shift;
   my $ipaddr = shift;
   my $netmask = shift;
   my $gateway = shift;

   if (not defined $ipaddr) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   # check the validity of ip address
   unless ($ipaddr =~ m/dhcp|remove/i) {
      if ((CheckIPValidity($ipaddr) eq FAILURE) ||
         (CheckIPValidity($netmask) eq FAILURE) ||
         ((defined $gateway) && (CheckIPValidity($gateway) eq FAILURE))) {
         $vdLogger->Error("Invalid address");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   if (defined $self->{id}) {
      $self->{interface} = $self->{id};
   }
   my $args = $self->{'interface'} . "," . $ipaddr . "," . $netmask;
   $args = $args . "," . $gateway if (defined $gateway);
   $vdLogger->Info("Setting IPv4 in $self->{'controlIP'} on $args");
   return ExecuteRemoteMethod($self->{'controlIP'}, "SetIPv4", $args);
}


########################################################################
#
# AddIPv4 -
#       This method configures given sub IPv4 address, netmask, to the given
#       adapter/interface
#
# Input:
#       IPv4 Address - in the format xx.xx.xx.xx (required)
#       Netmask      - in the format xx.xx.xx.xx (required)
#       SubIpIndex   - integer (required)
#       Gateway      - in the format xx.xx.xx.xx (optional)
#
# Results:
#       "SUCCESS", if the given sub IPv4 address, netmask is set
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub AddIPv4
{
   my $self       = shift;
   my $ipaddr     = shift;
   my $netmask    = shift;
   my $subipindex = shift;
   my $gateway    = shift;

   if ((not defined $ipaddr) || (not defined $subipindex)) {
       $vdLogger->Error("Insufficient parameters passed: the ipadd or " .
                        "subipindex is not defined");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if (lc($self->{vmOpsObj}->{os}) ne "linux") {
      $vdLogger->Error("Add sub ip address to existing ip interface currently " .
                       "only support linux system");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # check the validity of ip address
   unless ($ipaddr =~ m/dhcp/i) {
      if ((CheckIPValidity($ipaddr) eq FAILURE) ||
         (CheckIPValidity($netmask) eq FAILURE) ||
         ((defined $gateway) && (CheckIPValidity($gateway) eq FAILURE))) {
         $vdLogger->Error("Invalid address");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $args = $self->{'interface'} . ":$subipindex" . "," . $ipaddr . "," . $netmask;
   $args = $args . "," . $gateway if (defined $gateway);
   $vdLogger->Info("Setting IPv4 in $self->{'controlIP'} on $args");

   my $result = ExecuteRemoteMethod($self->{'controlIP'}, "SetIPv4", $args);
   if ($result eq 'FAILURE') {
      $vdLogger->Error("Failed to add sub ip on the vm.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# GetVLANId -
#       This method returns the VLAN id of the given  adapter/interface
#
# Input:
#       None
#
# Results:
#       VLAN ID, if success
#       "0", if vlan is not supported or configured
#
# Side effects:
#       None
#
########################################################################

sub GetVLANId
{
   my $self = shift;
   my $args = $self->{'interface'};
   my $result = ExecuteRemoteMethod($self->{'controlIP'}, "GetVLANId", $args);

   if ($result eq FAILURE) {
      $vdLogger->Debug("GetVLANId warning: " . VDGetLastError());
      VDCleanErrorStack();
      return "0";
   } else {
      $self->{vlanid} = $result;
      return $result;
   }
}


########################################################################
#
# SetVLAN -
#       In windows, this method configures VLAN on the given interface.
#       In case of linux, a new VLAN interface with the base device as the given
#       interface/adapter
#
# Input:
#       VLAN ID - 1 to 4095 (required)
#       IPv4 Address - in the format xx.xx.xx.xx (required)
#       Netmask - in the format xx.xx.xx.xx (required)
#
# Results:
#       A new NetAdapter object, if success
#       "FAILURE", in case of any error
#
# Side effects:
#       In linux, the base devices' IP address will changed to 0.0.0.1 to
#       prevent it from being used for testing
#
########################################################################

sub SetVLAN
{
   my $self = shift;
   my $vlanId = shift;
   my $ipaddr = shift;
   my $netmask = shift;
   my $gateway = shift; # not used currently

   if ((not defined $ipaddr) ||
       (not defined $netmask) ||
       (not defined $vlanId)) {
       $vdLogger->Error("Invalid paramters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   #
   # check the validity of ip address
   if ((CheckIPValidity($ipaddr) eq FAILURE) ||
      (CheckIPValidity($netmask) eq FAILURE) ||
      ((defined $gateway) && (CheckIPValidity($gateway) eq FAILURE))) {
      $vdLogger->Error("Invalid address");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Check if the vlan id is within range 0-4095
   if ($vlanId =~ /^(\d\d?\d?\d?)$/) {
      if (($1 < 0) || ($1 > 4095)) {
         $vdLogger->Error("VLAN Id out of range");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid VLAN Id");
         VDSetLastError("EINVALID");
         return FAILURE;
   }
   my $args = $self->{'interface'} . "," . $vlanId . "," . $ipaddr . "," .
              $netmask;
   my $newInterface = ExecuteRemoteMethod($self->{'controlIP'},
                                          "SetVLAN",
                                          $args);

   if ($newInterface eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $self->{vlanid} = $vlanId;
   #
   # Create VDNetLib:NetAdapter::NetAdapter object of the child vlan node
   # and return it.
   #
   if ($newInterface =~ /{/ && $newInterface !~ /\^{/) {
      $newInterface = "^" . $newInterface . "^";
   }
   $args = $newInterface;

   my $mac = ExecuteRemoteMethod($self->{'controlIP'},
                                 "GetMACAddress",
                                 $args);
   if ($mac eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Copy the current obj attributes to new obj, then override mac and
   # new interface name.
   # Even child vlan's driver is same as parent
   my %newSelf = %$self;
   my $vlaninterface = \%newSelf;
   #$newSelf = %$self;
   $vlaninterface->{interface} = $newInterface;
   $vlaninterface->{macAddress} = $mac;
   $vlaninterface->{thisIsVLAN} = "****************************************";
   bless $vlaninterface;
   return $vlaninterface;
}


########################################################################
#
# RemoveVLAN -
#       In windows, this method removes VLAN configured on the given
#       interface.
#       In case of linux, a new VLAN interface that has the base device
#       as the given interface/adapter will be removed
#
# Input:
#       None
#
# Results:
#       "SUCCESS", if remove operations is success
#       "FAILURE", in case of any error
#
# Side effects:
#       In linux, the base devices' IP address will refreshed using DHCP
#
########################################################################

sub RemoveVLAN
{
   my $self = shift;
   my $args = $self->{'interface'};

   my $result = ExecuteRemoteMethod($self->{'controlIP'},
                                    "RemoveVLAN",
                                    $args);
   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } else {
      $self->{vlanid} = "0";
      return $result;
   }
}


########################################################################
#
# GetDeviceStatus -
#        Gives the status (UP or DOWN) of the network adapter
#
# Input:
#       None
#
# Results:
#       "UP", if the network adapter is enabled
#       "DOWN", if the network adapter is disabled
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetDeviceStatus
{
   my $self = shift;
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "GetDeviceStatus",
                                          $args);
}


########################################################################
#
# SetDeviceStatus --
#       This module changes the adapter's status 'enabled or disabled' based on
#       the input 'UP' or 'DOWN'
#
#
# Input:
#       <action> ('UP' to enable, 'DOWN' to disable the device)
#
# Results:
#       "SUCCESS", if the action requested is successful
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub SetDeviceStatus
{
   my $self = shift;
   my $action = shift;

   if ((not defined $self->{'interface'}) ||
       (not defined $action)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $action;
   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "SetDeviceStatus",
                                          $args);
}


########################################################################
#
# GetNDISVersion -
#        Gives the Ndis version of the mini-port driver being used by the
#        network adapter
#
# Input:
#        None
#
# Results:
#        Returns Ndis version (5.x, 6.x etc) if success
#        "FAILURE", in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetNDISVersion
{
   my $self = shift;
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'},
                                      "GetNDISVersion",
                                      $args);
}


########################################################################
#
# GetOffload -
#        Gives the status (enabled or diabled) of offload operation provided
#        as input. On windows, IPV6 offload functions can be retrieved only if
#        IPv6 protocol is installed.
#
# Input:
#        Any one of the following offload functions:
#        TSOIPv4, TCPTxChecksumIPv4, TCPRxChecksumIPv4,
#        UDPTxChecksumIPv4, UDPRxChecksumIPv4, TCPGiantIPv4, IPTxChecksum,
#        IPRxChecksum, TSOIPv6, TCPTxChecksumIPv6, TCPRxChecksumIPv6,
#        UDPTxChecksumIPv6, UDPRxChecksumIPv6, TCPGiantIPv6
#
# Results:
#        'Enabled', if the offload operation is enabled on the adapter
#        'Disabled', if the offload operation is disabled on the adapter
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetOffload
{
   my $self = shift;
   my $offloadFunction = shift;  # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $offloadFunction)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   $offloadFunction  = lc($offloadFunction);
   my $args = $self->{'interface'};
   $args = $args . "," . $offloadFunction;

   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "GetOffload",
                                          $args);
}


########################################################################
#
# SetOffload -
#        Enables/disables a offload operation provided as input
#        on the network adapter. On windows, IPv6 offload functions can be
#        performed only if IPv6 protocol is installed.
#
# Input:
#        <offloadFunction>
#        Any one of the following offload functions:
#        TSOIPv4, TCPTxChecksumIPv4, TCPRxChecksumIPv4,
#        UDPTxChecksumIPv4, UDPRxChecksumIPv4, TCPGiantIPv4, IPTxChecksum,
#        IPRxChecksum, TSOIPv6, TCPTxChecksumIPv6, TCPRxChecksumIPv6,
#        UDPTxChecksumIPv6, UDPRxChecksumIPv6, TCPGiantIPv6
#        <action>
#        'Enable', to enable the specified offload operation
#        'Disable', to disable the specified offload operation
#
# Results:
#        'SUCCESS', if the action on the specified offload operation
#           is successful on the adapter
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub SetOffload
{
   my $self = shift;             # Required
   my $param = shift;

   if (not defined $self->{'interface'}){
       $vdLogger->Error("The parameter of 'interface'" .
          " was not defined.");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if ((not defined $param) ||
       (not exists  $param->{offload_type}) ||
       (not exists  $param->{enable})){
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $offloadFunction  = lc($param->{offload_type});
   my $action = $param->{enable};
   if ((not defined $offloadFunction) ||
       (not defined  $action )) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if ($action =~ /true/i){
      $action = 'enable';
   } elsif ($action =~ /false/i){
      $action = 'disable';
   } else {
       $vdLogger->Error("In the key of configure_offload ," .
          "the parameter 'enable' need to be 'true' or 'false'");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   # Setting SG is not supported on Windows, so return appropriate
   # value for this case. Retuning SKIP (UNSUPPORTED) for Disable
   # request. But returning SUCCESS for Enable request for VD Test
   # cases requirements where same test case is run on both Linux
   # and Windows.
   if ((OSTYPE == OS_WINDOWS) && ($offloadFunction =~ /sg/i)) {
      if ($action =~ /Enable/i) {
         return SUCCESS;
      } else {
         $vdLogger->Warn("SG is not support on Windows," .
            "so we skip the operation of $action ");
         return "SKIP";
      }
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $offloadFunction . "," . $action;
   $vdLogger->Info("Execute SetOffload $args on remote vm.");

   return ExecuteRemoteMethod($self->{'controlIP'},
                                          "SetOffload",
                                          $args);
}


########################################################################
#
# VerifyOffload -
#        Verifies if the current value for the offload operation is set
#	 to the expected Enable/disable value provided as input
#
# Input:
#        <offloadFunction>
#        Any one of the following offload functions:
#        TSOIPv4, TCPTxChecksumIPv4, TCPRxChecksumIPv4, Gso,
#        UDPTxChecksumIPv4, UDPRxChecksumIPv4, TCPGiantIPv4, IPTxChecksum,
#        IPRxChecksum, TSOIPv6, TCPTxChecksumIPv6, TCPRxChecksumIPv6,
#        UDPTxChecksumIPv6, UDPRxChecksumIPv6, TCPGiantIPv6
#        <expValue>
#        'Enable', to check if the current value is set to enable
#        'Disable', to check if the current value is set to disable
#
# Results:
#        'SUCCESS', if the current value set is same as expected one
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub VerifyOffload
{
   my $self		= shift;  # Required
   my $confighash	= shift;  # Required

   %$confighash = (map { lc $_ => lc $confighash->{$_}} keys %$confighash);

   my $offloadFunction	= $confighash->{'feature_type'};  # Required
   my $expValue		= $confighash->{'value'};    # Required
   my $curValue		= undef;

   my %supportedFeatures = (
      'tsoipv4' => 'TSOIPv4',
      'tcptxchecksumipv4' => 'TCPTxChecksumIPv4',
      'tcprxchecksumipv4' => 'TCPRxChecksumIPv4',
      'ufo' => 'Ufo',
      'gso' => 'Gso',
      'sg'  => 'SG',
      'lro' => 'LRO',
      'udptxchecksumipv4'=> 'UDPTxChecksumIPv4',
      'udprxchecksumipv4'=> 'UDPRxChecksumIPv4',
      'tcpgiantipv4'	 => 'TCPGiantIPv4',
      'ipchecksum'	 => 'IPCheckSum',
      'iptxchecksum'	 => 'IPTxChecksum',
      'iprxchecksum'	 => 'IPRxChecksum',
      'tsoipv6'		 => 'TSOIPv6',
      'tcptxchecksumipv6'=> 'TCPTxChecksumIPv6',
      'tcprxchecksumipv6'=> 'TCPRxChecksumIPv6',
      'udptxchecksumipv6'=> 'UDPTxChecksumIPv6',
      'udprxchecksumipv6'=> 'UDPRxChecksumIPv6',
      'tcpgiantipv6'	 => 'TCPGiantIPv6',
      'wol'		 => 'wol',
      'mtu'		 => 'mtu',
      'rss'		 => 'rss',
      'maxtxqueues'	 => 'maxtxqueues',
      'maxrxqueues'	 => 'maxrxqueues',
      'txringsize'	 => 'txringsize',
      'rx1ringsize'	 =>  'rx1ringsize',
      'rx2ringsize'	 => 'rx2ringsize',
      'vlan'	         => 'VLAN',
      'priority'	 => 'Priority',
   );

   $offloadFunction = $supportedFeatures{$offloadFunction};
   if (not defined $offloadFunction) {
      $vdLogger->Error("Incorrect parameter passed: $offloadFunction");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ((not defined $self->{'interface'}) ||
       (not defined $offloadFunction) ||
       (not defined $expValue)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if ($offloadFunction =~ /wol/i) {
      $curValue = $self->GetWol();
      $curValue = $$curValue; # GetWol returns reference to a string, hence de-reference.
   } elsif ($offloadFunction =~ /mtu/i) {
      $curValue = $self->GetMTU();

      #
      # MTU values on windows drivers depend on the enum values. For example,
      # to MTU size 1500 on e1000, the value to write in the registry is 1514.
      #

      if ((int($curValue) >= (int($expValue) - 14)) &&
	  (int($curValue) <= (int($expValue) + 14))) {
	     $curValue = $expValue;
      }
   } elsif ($offloadFunction =~ /rss/i) {
      $curValue = $self->GetRSS();
   } elsif ($offloadFunction =~ /maxtxqueues/i) {
      $curValue = $self->GetMaxTxRxQueues("Tx");
   } elsif ($offloadFunction =~ /maxrxqueues/i) {
      $curValue = $self->GetMaxTxRxQueues("Rx");
   } elsif ($offloadFunction =~ /txringsize/i) {
      $curValue = $self->GetRingSize("Tx");
   } elsif ($offloadFunction =~ /rx1ringsize/i) {
      $curValue = $self->GetRingSize("Rx1");
      my $isJumboEnabled = $self->GetMTU();

      if (int($isJumboEnabled) > 1500) {
         $isJumboEnabled = 1;
      } else {
         $isJumboEnabled = 0;
      }

      #
      # When jumboframes are configured (lets say MTU 9000) 3 bufs/recv
      # descriptors are required per frame. Minimum size of ring is  32
      # freames, which will need (32 x 3) = 96 bufs. Hence all the ring
      # sizes programmed from  ethtool are aligned to 96 bufs  (i.e. 32
      # frames and not to 32.
      #

      if($isJumboEnabled) {
         if ($curValue >= ($expValue - 96) &&
	     $curValue <= ($expValue + 96)) {
		$curValue = $expValue;
         }
      }
   } elsif ($offloadFunction =~ /rx2ringsize/i) {
      $curValue = $self->GetRingSize("Rx2");
   } elsif (($offloadFunction =~ /vlan/i) ||
            ($offloadFunction =~ /priority/i)) {
      $curValue = $self->GetPriorityVLAN($offloadFunction);
   } else {
      $curValue = $self->GetOffload($offloadFunction);
   }

   if ($curValue eq FAILURE) {
      $vdLogger->Error("Failed to get the current value for : $offloadFunction");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($curValue !~ /$expValue/i) {
      $vdLogger->Error("Value mismatch for $offloadFunction. Current Value: " .
		    "$curValue. Expected Value: $expValue\n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("$offloadFunction value is set to expected value: $expValue");
   return SUCCESS;
}


########################################################################
#
# GetMACAddress -
#       Returns the mac address (hardware address) of the given
#       adapter/interface
#
# Input:
#       None
#
# Results:
#       Mac address of the given the adapter/interface
#       'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetMACAddress
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};
   $self->{'macAddress'} = ExecuteRemoteMethod($self->{'controlIP'},
                                          "GetMACAddress",
                                          $args);
   return $self->{'macAddress'};
}

########################################################################
#
# GetInterfaceName -
#        Gives the interface name (example, "Local Area Connection #") for a
#        network adapter on windows. In linux, there is no such name for an
#        adapter
#
# Input:
#        None
#
# Results:
#        <InterfaceName>, if success
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetInterfaceName
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetInterfaceName", $args);
}


########################################################################
#
# CheckIPValidity --
#        Checks whether the given address has valid IP format and each octet is
#        within the range. This is just a utility function currently placed in
#        this package. This sub-routine is not part of the methods that can be
#        used on a NetAdapter object
#
# Input:
#        Address in IP format (xxx.xxx.xxx.xxx)
#
# Results:
#        "SUCCESS", if the given address has correct format and range
#        "FAILURE", if the given address has invalid format or range
#
# Side effects:
#        None
#
########################################################################

sub CheckIPValidity
{
   my $address = shift;

   if (not defined $address) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($address =~ /^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/) {
      if ($1 > 255 || $2 > 255 || $3 > 255 || $3 > 255 || $4 > 255) {
         $vdLogger->Error("Address out of range: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid address: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# GetLinkState --
#     Gives the current link state of the adapter
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     'Connected', if the link is active
#     'Disconnected', if the link is not active
#     'FAILURE', in case of any errror
#
# Side effects:
#     None
#
########################################################################

sub GetLinkState
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetLinkState", $args);
}


########################################################################
#
# GetIPv6Local --
#     Gives the IPv6 link-local address for the given interface
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     Array of IPv6 link-local address, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Local
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetIPv6Local", $args);
}


########################################################################
#
# GetIPv6Global --
#     Gives the IPv6 global address for the given interface
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     Array of IPv6 global address, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Global
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   my $ret = ExecuteRemoteMethod($self->{'controlIP'}, "GetIPv6Global", $args);
   # Sample $ret = ['2001:bd6::c:2957:103:75/64'];

   # Check for undefined/FAILURE/non-array/empty-array return.
   if (not defined $ret) {
      $vdLogger->Error("Remote method GetIPv6Global returned undef.");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   } elsif ($ret eq FAILURE) {
      $vdLogger->Error("Remote method GetIPv6Global returned FAILURE.");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   } elsif (ref($ret) ne "ARRAY") {
      $vdLogger->Error("Expects remote method GetIPv6Global to return ARRAY.");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   } elsif (scalar(@$ret) == 0) {
      # Got empty array. IPv6 global address not configured.
      $vdLogger->Warn("Remote method GetIPv6Global returned empty array.");
      return $ret;
   }
   # Found IP. Strip the netmask to return only IP.
   my @tempIP = split(/\//, $ret->[0]);
   $ret->[0] =  $tempIP[0];
   # Sample $ret = ['2001:bd6::c:2957:103:75'];
   return $ret;
}


########################################################################
#
# GetSingleIPv6Global --
#     Gives the IPv6 global address for the given interface.
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     String for IPv6 global address, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetSingleIPv6Global
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};
   my $ret = $self->GetIPv6Global($args);
   if ((defined $ret) && ($ret eq FAILURE)) {
      $vdLogger->Error("Failed to get global IPv6 for $args.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $ret->[0];
}


########################################################################
#
# SetIPv6 --
#       This function configures the IP address of the given interface
#
#
# Input:
#       <A valid NetAdapter object>
#       <operation>    - add or delete (Required)
#       <ipaddr>       - IPv6 address to set (Required)
#       <prefixLength> - Prefix length of IPv6 address(Optional)
#
# Results:
#       "SUCCESS", if success
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub SetIPv6
{
   my $self = shift; # Required
   my $operation = shift;  # Required
   my $ipaddr = shift; # Required
   my $prefixLength = shift || 64;
   my $gateway = shift; # Not used currently

   if ((not defined $self->{'interface'}) ||
       (not defined $operation) ||
       (not defined $ipaddr)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if ($ipaddr =~ /(.*)\/(.*)/) {
      $ipaddr = $1;
      $prefixLength = $2;
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $operation . "," . $ipaddr . "," . $prefixLength;
   $vdLogger->Info("Setting IPv6 in $self->{'controlIP'} on $args");

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetIPv6", $args);
}


########################################################################
#
# GetWoL --
#     Gives the wake-on LAN configuration on the given interface.
#     The return value is string which can be any combination of the
#     following:
#     ARP - wake on arp
#     UNICAST - wake on unicast packet
#     MAGIC - wake on magic packet
#
#     *** or ***
#     DISABLE - wake-on lan feature is disabled or not supported
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     A string with any combination of the above, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetWoL
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetWoL", $args);
}


########################################################################
#
# SetWoL --
#     Sets the wake-on LAN configuration on the given interface.
#     The wake-on method is string which can be any combination of the
#     following:
#     ARP - wake on arp
#     UNICAST - wake on unicast packet
#     MAGIC - wake on magic packet
#
#     *** OR ***
#     DISABLE - disable wake-on lan feature
#
# Input:
#     <A valid NetAdapter object>
#     <wakeUpMethods>
#        String with methods mentioned above, for example,
#        SetWoL(eth0,'MAGIC ARP'), SetWoL(eth0,'DISABLE')
#
# Results:
#     'SUCCESS', if the given wake-method is configured or wol is disabled
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetWoL
{
   my $self = shift; # Required
   my $wakeUpMethods = shift;  # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $wakeUpMethods)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $wakeUpMethods;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetWoL", $args);
}


########################################################################
#
# GetInterruptModeration --
#     Method to get the status of InterruptModeration.
#     Currently this method is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetInterruptModeration
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetInterruptModeration", $args);
}


########################################################################
#
# SetInterruptModeration --
#     Method to change the status (enable/disable) InterruptModeration.
#     Currently this method is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetInterruptModeration
{
   my $self = shift;    # Required
   my $operation = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $operation)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $operation;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetInterruptModeration", $args);
}


########################################################################
#
# GetOffloadTCPOptions --
#     Method to get the status of Offload TCP options on the given interface.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetOffloadTCPOptions
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetOffloadTCPOptions", $args);
}


########################################################################
#
# SetOffloadTCPOptions --
#     Method to change the status (enable/disable) of Offload TCP options
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetOffloadTCPOptions
{
   my $self = shift;    # Required
   my $operation = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $operation)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $operation;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetOffloadTCPOptions", $args);
}


########################################################################
#
# GetOffloadIPOptions --
#     Method to get the status of Offload IP options on the given interface.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetOffloadIPOptions
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetOffloadIPOptions", $args);
}


########################################################################
#
# SetOffloadIPOptions --
#     Method to change the status (enable/disable) of Offload IP options
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetOffloadIPOptions
{
   my $self = shift;    # Required
   my $operation = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $operation)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $operation;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetOffloadIPOptions", $args);
}


########################################################################
#
# GetRSS --
#     Method to get the status of RSS on the given interface.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRSS
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetRSS", $args);
}


########################################################################
#
# SetRSS --
#     Method to change the status (enable/disable) of RSS.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetRSS
{
   my $self = shift;    # Required
   my $operation = shift;    # Required
   my $driverName = $self->{'name'};

   if ((not defined $self->{'interface'}) ||
       (not defined $operation)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $operation . "," . $driverName;
   $vdLogger->Debug("On the $self->{'controlIP'} SetRss $args");

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetRSS", $args);
}

########################################################################
#
# GetMaxTxRxQueues --
#     Method to get the status of number of Tx or Rx queues.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <type> ("Tx" or "Rx")
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetMaxTxRxQueues
{
   my $self = shift;    # Required
   my $type = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $type)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $type;

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetMaxTxRxQueues", $args);
}


########################################################################
#
# SetMaxTxRxQueues --
#     Method to change the number of Tx/Rx queues.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <type> ("Tx" or "Rx")
#     <value> (One of these values: 1, 2, 4 or 8)
#
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetMaxTxRxQueues
{
   my $self  = shift;    # Required
   my $param = shift;    # Required
   my $type  = $param->{direction};    # Required
   my $value = $param->{value};   # Required

   my $rxqSupport =  shift;   # Optional
   my $driverName = $self->{'name'};
   my $adapter = $self->{'interface'};

   if ((not defined $self->{'interface'}) ||
       (not defined $type) ||
       (not defined $value)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   # Move the juegement form NetAdapeterWorkload.pm
   # The max queues of Rx/Tx are not supported ,
   # when the IntrMode are not 3/7
   if ((OSTYPE == OS_LINUX) && ($driverName =~ /vmxnet3/i)) {
      my $vmOpsObj = $self->{vmOpsObj};
      my $hostObj = $vmOpsObj->{hostObj};
      my $srcHostIP = $hostObj->{hostIP};
      my $vmxfile = VDNetLib::Common::Utilities::GetAbsFileofVMX(
                                                        $vmOpsObj->{'vmx'});
      if ($vmxfile eq "FAILURE") {
         $vdLogger->Error("Failed to get VMX filename");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      my $macAddr = $self->{'macAddress'};
      my $ethUnit = VDNetLib::Common::Utilities::GetEthUnitNum(
                                                        $srcHostIP,
                                                        $vmxfile,
                                                        $macAddr);
      if ($ethUnit eq "FAILURE") {
         $vdLogger->Error("Failed to get ethernet unit number");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Collect the directory name from vmxfile name
      my @suffixlist = ("vmx","log");
      my ($name,$path,$suffix) = fileparse($vmxfile,@suffixlist);
      my $vmwarelog = "$path"."vmware.log";

      my $currentIntrMode = undef;
      $currentIntrMode =
         VDNetLib::Common::Utilities::GetInterruptModeFromVmwareLog(
                                                           $srcHostIP,
                                                           $ethUnit,
                                                           $vmwarelog,
                                                           $self->{'stafHelper'});

      if ((defined $currentIntrMode) &&
         ($currentIntrMode !~ /FAILURE/i) &&
         $currentIntrMode != 3 &&
         $currentIntrMode != 7) {
         $vdLogger->Error("Multi Rx queue is not supported in currently".
                            " set interrupt mode. Hence disabling it...");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Multi queue is only supported for linux and vmxnet3.");
      return FAILURE;
   }

   my @arr = split /,/,$value;
   foreach my $key(@arr){
      my $args;

      if ((defined $rxqSupport) && $rxqSupport == 0) {
         $args ="$self->{'interface'}," . "$type," . "$key," .
            "$driverName," . "$rxqSupport";
      } else {
         $args = "$self->{'interface'}," . "$type," . "$key," .
            "$driverName";
      }

      my $returnVal = ExecuteRemoteMethod($self->{'controlIP'}, "SetMaxTxRxQueues", $args);
      $vdLogger->Debug("Return value for SetMaxTxRxQueues is: ".
         Dumper($returnVal));
      if ($returnVal eq FAILURE) {
         VDSetLastError(VDGetLastError());
         $vdLogger->Error("Failed to set the queues of Tx/Rx on adapter.");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetRxBuffers --
#     Method to get the size of small or large Rx buffers.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <type> ("small" or "large")
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRxBuffers
{
   my $self = shift;    # Required
   my $type = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $type)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $type;

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetRxBuffers", $args);
}


########################################################################
#
# SetRxBuffers --
#     Method to change the size of small or large Rx buffers.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <type> ("small" or "large")
#     <value> (One of these values: 64, 128, 256, 512, 768, 1024, 1536, 2048,
#                                   3072, 4096, 8192)
#
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#
########################################################################

sub SetRxBuffers
{
   my $self = shift;    # Required
   my $type = shift;    # Required
   my $value = shift;   # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $type) ||
       (not defined $value)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $type . "," . $value;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetRxBuffers", $args);
}


########################################################################
#
# GetRingSize --
#     Method to get ring size (Tx/Rx1/Rx2) of the given adapter
#
# Input:
#     <valid NetAdapter object>
#     <type> (Tx, or Rx1, or Rx2. Rx2 is not supported on linux)
#
# Results:
#     Ring size of the given interface, in case of no error
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRingSize
{
   my $self = shift;    # Required
   my $type = shift;    # Required

   if ((not defined $self->{'interface'}) ||
       (not defined $type)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $type;

   return ExecuteRemoteMethod($self->{'controlIP'}, "GetRingSize", $args);
}


########################################################################
#
# SetRingSize --
#     Method to set ring size (Tx/Rx1/Rx2) on the given adapter
#
# Input:
#     <valid NetAdapter object>
#     <param>: ($param->{ring_type} should be :Tx, or Rx1, or Rx2.
#                                    Rx2 is not supported on linux)
#              ($param->{value} on Linux, any value less than maximum
#                               supported, usually 4096;
#                               on Windows, one of these values:
#                               32, 64, 128, 256, 512, 1024, 2048, 4096;)
#
# Results:
#     "SUCCESS", if the given ring size is set without any error
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetRingSize
{
   my $self = shift;    # Required
   my $param = shift;    # Required

   if (not defined $self->{'interface'}){
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if ((not defined $param) ||
       (not exists  $param->{ring_type}) ||
       (not exists $param->{value})) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $type  = $param->{ring_type};    # Required
   my $value = $param->{value};   # Required
   if ((not defined $type) ||
       (not defined $value)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my @arr = split /,/,$value;
   foreach my $key(@arr){
      my $args;
      $args = $self->{'interface'} . "," . $type . "," . $key;

      my $returnVal = ExecuteRemoteMethod($self->{'controlIP'}, "SetRingSize", $args);
      $vdLogger->Debug("Return value for SetRingSize is: ".
         Dumper($returnVal));
      if ($returnVal eq FAILURE) {
         VDSetLastError(VDGetLastError());
         $vdLogger->Error("Failed to set the ring size of Tx/Rx1/Rx2 on adapter.");
         return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# IntrModParams --
#     Reload the driver with the given intr mod_params
#
# Input:
#     <valid NetAdapter object>
#     <module_params> (Module parameters to use while loading the driver)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub IntrModParams
{
   my $self = shift;    # Required
   my $moduleParams = shift; # optional
   my $driverName = $self->{'name'};

   my $args = $self->{'interface'};
   $args = $args . "," . $driverName . "," . $moduleParams;
   $vdLogger->Info(" On $self->{'controlIP'} set IntrModParams $args");

   return ExecuteRemoteMethod($self->{'controlIP'}, "IntrModParams", $args);
}

########################################################################
#
# DriverLoad --
#     Routine to load the driver
#
# Input:
#     <valid NetAdapter object>
#     <module_params> (Module parameters to use while loading the driver)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DriverLoad
{
   my $self = shift;    # Required
   my $moduleParams = shift; # optional
   my $driverName = $self->{'name'};

   my $args = $driverName . "," . $moduleParams;
   return ExecuteRemoteMethod($self->{'controlIP'}, "DriverLoad", $args);
}

########################################################################
#
# DriverUnload --
#     Routine to unload the driver
#
# Input:
#     <valid NetAdapter object>
#
# Results:
#     "SUCCESS", if the unload is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DriverUnload
{
   my $self = shift;    # Required
   my $driverName = $self->{'name'};

   return ExecuteRemoteMethod($self->{'controlIP'}, "DriverUnload",
			      $driverName);
}

########################################################################
#
# DriverReload --
#     Routine to reload the driver
#
# Input:
#     <valid NetAdapter object>
#     <module_params> (Module parameters to use while loading the driver)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DriverReload
{
   my $self = shift;    # Required
   my $moduleParams = shift; # optional
   my $driverName = $self->{'name'};

   if ($moduleParams =~ /true/i){
      $moduleParams = 'null';
   } else {
      $vdLogger->Error("Invalid parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $args = $self->{'interface'};
   $args = $args . "," . $driverName . "," . $moduleParams;
   $vdLogger->Info("Re-loading driver $self->{name} on $self->{controlIP} " .
      " with args $args");
   # The current design of NetAdapter doesn't allow loading of the driver
   # when there is no corresponding ethX interface in the guest (during unload
   # the interface gets destroyed but the device still exists). When we
   # initially add the device if the guest has tools, it will install the
   # driver otherwise we have to install the tools first. Once we have tools,
   # if we want to unload and load the driver, during unload the ethX interface
   # gets destroyed so if we want to load the driver then, NetAdapter won't be
   # able to discover the correponding MAC address and it will fail. So, call
   # this method instead, if you want to reload the driver with the given
   # module_params.

   #
   # Unload the driver first
   # TODO - Unloading driver is done as part of loading driver itself until
   # PR722104 is fixed.
   # ExecuteRemoteMethod($self->{'controlIP'}, "DriverUnload", $driverName);
   #

   # Load the driver again with the passed module_params
   return ExecuteRemoteMethod($self->{'controlIP'}, "DriverLoad", $args);
}

########################################################################
#
# SetMACAddr --
#     Routine to set the MAC address
#
# Input:
#     <valid NetAdapter object>
#     <mac> (User passed MAC address)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetMACAddr
{
   my $self = shift; # Required
   my $mac = shift;  # Required

   if (not defined $mac) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $args = $self->{'interface'} . "," . $mac;
   my $ret = ExecuteRemoteMethod($self->{'controlIP'}, "SetMACAddr", $args);

   if ($ret eq SUCCESS) {
      $self->{'macAddress'} = $mac;
   }
   return $ret;
}

########################################################################
#
# GetNetworkAddr -
#       This method returns the Other address configured for the
#       adapter/interface like Subnet Mask, Broadcast address along with
#       IPv4 address
#
# Input:
#       None
#
# Results:
#       Hash of IPv4 address, Subnet Mask and Bcast address if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetNetworkAddr
{
   my $self = shift;
   my $args = $self->{'interface'};
   return ExecuteRemoteMethod($self->{'controlIP'},
                              "GetNetworkAddr",
                              $args);
}

########################################################################
#
# SetLROStatus-
#       This method enables or disables lro on device
#
# Input:
#       action - enable/disable
#
# Results:
#       SUCCESS, in case lro is enabled/disabled
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetLROStatus
{
   my $self = shift;
   my $action = shift;
   my $driverName = $self->{'name'};
   my $args = $self->{'interface'} . "," . $driverName . "," . $action;
   return ExecuteRemoteMethod($self->{'controlIP'},
                              "SetLRO",
                              $args);
}


########################################################################
#
# WakeupGuest --
#     Wakes up the guest sending a MAGIC/ARP/UNICAST packet
#     The packet to be sent is a string which can be any combination of the
#     following:
#     ARP - wake on arp
#     UNICAST - wake on unicast packet
#     MAGIC - wake on magic packet
#
# Input:
#     WakeupGuest: ARP / MAGIC / UNICAST
#     WOLTarget: "SUT" or "helper1/2/3..." as applicable
#
# Results:
#     'SUCCESS', if the guest is woken up
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub WakeupGuest
{
   my $self = shift;
   my $value = shift;
   my $targetHash = shift; # Hash to store the target adapter information
   my $STAFHelper = shift;
   my $supportAdapter = shift;

   my $cmd;
   my $pingCmd;
   my $stafResult;
   my $result;

   if ((not defined $targetHash) ||
       (not defined $value) ||
       (not defined $supportAdapter) ||
       (not defined $STAFHelper)) {
      $vdLogger->Error("Parameters not passed to WakeupGuest");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $helperVMObj = $supportAdapter->{vmOpsObj};
   my $os =  $helperVMObj->{os};
   my $helperIP =  $helperVMObj->{vmIP};

   my $testMAC = $targetHash->{macAddress};

   # Get the test adapter's IP address
   my $testIP    = $targetHash->GetIPv4();
   my $controlIP = $targetHash->{controlIP};
   my $supportIP = $supportAdapter->GetIPv4();

   if (($testIP eq FAILURE) || ($supportIP eq FAILURE)) {
      $vdLogger->Error("Failed to get test and/or helper ip address");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # form the pind cmd
   if ( $os =~ /lin/i ) {
      $pingCmd = "ping -c 5";
   } else {
      $pingCmd = "ping";
      # Windows needs mac address with '-' as delimiter
      $testMAC =~ s/:/-/g;
   }

   # Add static ARP entry on helper VM which is required to wake
   # the VM
   if ($value =~ /MAGIC/i) {
      # Add the ARP entry to make sure magic pkts reach test adapter
      if ( $os =~ /lin/i ) {
         $cmd = "arp -s $testIP $testMAC";
      } else {
	 my $ndisVersion = $targetHash->{'ndisVersion'};
	 my $interfaceName = $targetHash->{'interface'};

         # Using netsh command for newer Guests as arp has some known
         # issues with these newer Guests
         if ($ndisVersion =~ /6.\d/) {
            $cmd = "netsh interface ipv4 add neighbors \"$interfaceName\" $testIP $testMAC";
         } else {
            # For windows, we have to pass the interface IP where we want to add
            # this ARP entry otherwise it will add it to the first interface table
            # in ARP cache which might be control interface.
            $cmd = "arp -s $testIP $testMAC $supportIP";
         }
      }
      $vdLogger->Debug("Executing the command: $cmd on host: $helperIP");
      $stafResult = $STAFHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to add the ARP entry");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   if ($value =~ /ARP/i) {
      # Goto to helper machine, delete the arp entry for source machine
      $cmd = "arp -d $testIP";
      $stafResult = $STAFHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to delete SUT ARP entry from helper VM");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
    }

    # Send MAGIC/ARP/UNICAST pkt to wake up the guest
    if ($value =~ /MAGIC/i) {
      $vdLogger->Info("Sending magic pkt");
      my $args = $testIP . "," . $targetHash->{macAddress};
      $result = VDNetLib::Common::LocalAgent::ExecuteRemoteMethod($helperIP,
                                                       "SendMagicPkt", $args);
      if ($result eq FAILURE) {
        $vdLogger->Error("Failed to send MAGIC pkt");
        VDSetLastError(VDGetLastError());
        return FAILURE;
      }
    } elsif (($value =~ /UNICAST/i) || ($value =~ /ARP/)) {
      $vdLogger->Info("Waking up the guest using ping packet");
      $cmd = "$pingCmd $testIP";
      $stafResult = $STAFHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to ping the SUT from helper");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unsupported Wakeupguest flag");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Verify if the VM woke up
   my $loss = "10";
   my $timeout = STANDBY_TIMEOUT;
   while ($loss != "0" && $timeout > 0) {
      sleep(DEFAULT_SLEEP);
      $cmd = `ping -c 5 $controlIP`;
      if ($cmd =~ /(\d+)\%.*loss/i) {
         $timeout = $timeout - 20;
         $loss = $1;
      } else {
         $loss = $1;
         last;
      }
   }

   if ($loss != 0) {
      $vdLogger->Error("VM didn't wake up after sending $value packet type");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetPriorityVLAN --
#     Method to change the status (enable/disable) of PriorityVLAN.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <parameter> ("Priority" or "VLAN")
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetPriorityVLAN
{
   my $self = shift;
   my $arg = shift;
   my $parameter = $arg->{priorityvlan};
   my $operation = $arg->{priorityvlanaction};
   my $driverName = $self->{'name'};

   if ((not defined $self->{'interface'}) ||
       (not defined $parameter) ||
       (not defined $operation)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'interface'};
   $args = $args . "," . $parameter . "," . $operation . "," . $driverName;

   return ExecuteRemoteMethod($self->{'controlIP'}, "SetPriorityVLAN", $args);
}


########################################################################
#
# GetPriorityVLAN --
#     Method to get the status (enable/disable) of PriorityVLAN.
#     Currently this feature is supported only on windows
#
# Input:
#     <valid NetAdapter object>
#     <feature> ("Priority" or "VLAN")
#
# Results:
#     "SUCCESS", if the check is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPriorityVLAN
{
   my $self = shift;
   my $feature = shift;
   my $driverName = $self->{'name'};

   my $args = $self->{'interface'};
   $args = $args . "," . $feature . "," . $driverName;

   # Retrieving PriorityVLAN value
   return ExecuteRemoteMethod($self->{'controlIP'}, "GetPriorityVLAN", $args);
}


########################################################################
#
# GetPortID --
#     Get port id of this adapter registered on the given switch
#
# Input:
#     None
#
# Results:
#     port id of the adapter, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetPortID
{
   #deprecate GetvNicVSIPort in HostOperations
   my $self = shift;
   my $vmOpsObj = $self->{'vmOpsObj'};
   my $hostObj  = $vmOpsObj->{'hostObj'};
   my $worldId = $vmOpsObj->GetWorldID();
   if ($worldId eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $portsHash = $vmOpsObj->GetNetworkPortsInfo();
   my $macAddress = lc($self->{'macAddress'});
   if (defined $portsHash->{$macAddress}) {
      return $portsHash->{$macAddress}{'Port ID'};
   } else {
      $vdLogger->Error("Failed to find port id of $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetPortgroupName --
#     Get portgroup name of this adapter
#
# Input:
#     None
#
# Results:
#     portgroup name of the adapter, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetPortgroupName
{
   my $self = shift;
   if ((defined $self->{'pgObj'}) && (defined $self->{'pgObj'}->{'pgName'})) {
      return $self->{'pgObj'}->{'pgName'};
   } else {
      $vdLogger->Error("pgObj or pgName isn't defined.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetPortSetName --
#     Method to get portset name corresponding to the backing
#     network of this adapter
#
# Input:
#     None
#
# Results:
#     a string that indicates portset name, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetPortSetName
{
   my $self = shift;
   my $vmOpsObj = $self->{'vmOpsObj'};
   my $hostObj  = $vmOpsObj->{'hostObj'};
   my $worldId = $vmOpsObj->GetWorldID();
   if ($worldId eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $portsHash = $vmOpsObj->GetNetworkPortsInfo();
   if ($portsHash eq FAILURE) {
      $vdLogger->Error("Failed to get port info");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $macAddress = lc($self->{'macAddress'});
   if (not defined $portsHash->{$macAddress}) {
      $vdLogger->Error("Failed to find port id of $macAddress");
      $vdLogger->Debug("portsHash: " . Dumper($portsHash));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $switchName = $portsHash->{$macAddress}{'vSwitch'};
   my $portsetName;
   if ($portsHash->{$macAddress}{'DVPort ID'} ne "") {
      $portsetName = $hostObj->GetPortSetNamefromDVS($switchName);
      if ($portsetName eq FAILURE) {
         $vdLogger->Error("Failed to get portset name for $macAddress");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $portsetName = $switchName; # standard switch
   }
   return $portsetName;
}


########################################################################
#
# GetNIOCInfo --
#     Get NIOC placement information of this adapter
#
# Input:
#     portID : port id of this adapter (optional)
#
# Results:
#     Reference to a hash containing placement details, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetNIOCInfo
{
   my $self    = shift;
   my $portID  = shift;
   my $vmOpsObj = $self->{'vmOpsObj'};
   my $hostObj  = $vmOpsObj->{'hostObj'};

   my $macAddress = $self->{'macAddress'};
   my $portsetName = $self->GetPortSetName();
   if ($portsetName eq FAILURE) {
      $vdLogger->Error("Failed to find portset name of $macAddress");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (not defined $portID) {
      $portID = $self->GetPortID();
   }
   if ($portID eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $command = 'vsish -pe get /net/portsets/' .  $portsetName . '/ports/' .
                 $portID . '/niocVnicInfo';
   $vdLogger->Debug("Executing command:$command");
   my $result = $vmOpsObj->{stafHelper}->STAFSyncProcess($hostObj->{'hostIP'},
                                                     $command);
      $vdLogger->Debug("niocInfo:" . Dumper($result));
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $niocInfo = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $result->{stdout});
   if ($niocInfo eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $niocInfo;
}


########################################################################
#
# GetNetSchedulerInfo --
#     Method to get details of this adapter from the network
#     scheduler
#
# Input:
#     niocInfo : reference to niocInfo hash (obtained using
#                GetNIOCInfo() method) (Optional)
#
# Results:
#     Reference to hash containing adapter stats and placement
#     details, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetNetSchedulerInfo
{
   my $self     = shift;
   my $niocInfo = shift;
   my $vmOpsObj = $self->{'vmOpsObj'};
   my $hostObj  = $vmOpsObj->{'hostObj'};

   my $macAddress = $self->{'macAddress'};
   $niocInfo = (defined $niocInfo) ? $niocInfo : $self->GetNIOCInfo();
   my $portID = $self->GetPortID();
   if ($portID eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $command = 'vsish -pe get ' .
                 '/vmkModules/netsched/hclk/devs/' .
                 $niocInfo->{'uplinkDev'} .
                 '/qleaves/netsched.pools.vm.'.
                 $portID .
                 '/info';
   $vdLogger->Debug("GetNetSchedulerInfo command:$command");
   my $result = $vmOpsObj->{stafHelper}->STAFSyncProcess($hostObj->{'hostIP'},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $netschedInfo = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $result->{stdout});
   if ($netschedInfo eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $netschedInfo;
}


########################################################################
#
# VerifyNIOCPlacement --
#     Method to verify NIOC placement of this adapter
#
# Input:
#     expectedResult: 0/1/vmnic1....etc
#
# Results:
#     SUCCESS, if NIOC placement is verified correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub VerifyNIOCPlacement
{
   my $self = shift;
   my $expectedResult = shift;

   my $vmOpsObj = $self->{'vmOpsObj'};

   my $hostObj  = $vmOpsObj->{'hostObj'};

   my $macAddress = $self->{'macAddress'};
   my $niocInfo = $self->GetNIOCInfo();
   if ($niocInfo eq FAILURE) {
      $vdLogger->Error("Failed to get NIOC Info");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if($expectedResult =~ m/vmnic/i) {
      if ($expectedResult !~ m/$niocInfo->{'uplinkDev'}/i) {
         $vdLogger->Error("$self->{objID} is not placed on $expectedResult");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $expectedResult = 1;
   }

   my $portID = $self->GetPortID();
   if ($portID eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $nicPlaced;
   if ($niocInfo->{'uplinkDev'} =~ /unavailable/i) {
      $nicPlaced = 0;
      goto DECIDE;
   } else {
      $nicPlaced = 1;
   }

   my $netschedInfo = $self->GetNetSchedulerInfo();

   if ($netschedInfo eq FAILURE) {
      $vdLogger->Error("Failed to get scheduler information");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($netschedInfo->{'ppoolId'} eq $niocInfo->{'ppoolId'}) {
      $nicPlaced = 1;
   } else {
      $nicPlaced = 0;
   }

DECIDE:
   if ($nicPlaced != int($expectedResult)) {
      $vdLogger->Error("Mismatch between expected $expectedResult and " .
                       "actual placement $nicPlaced");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# Reconfigure --
#     Method to edit the virtual adapter settings on the VM
#
# Input:
#     Reference to hash containing following keys:
#               driver              : <vmxnet3/e1000>
#               portgroup           : reference to portgroup (vdnet
#                                     core object)
#               connected           : boolean
#               startConnected      : boolean
#               allowGuestControl   : boolean
#               reservation         : integer value in Mbps
#               limit               : integer value in Mbps
#               shareslevel         : normal/low/high/custom
#               shares              : integer between 0-100
#
# Results:
#     SUCCESS, if the adapter is reconfigured correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Reconfigure
{
   my $self       = shift;
   my $editParams = shift;
   my $inlineVirtualAdapter = $self->GetInlineVirtualAdapter();
   my $originalSpec = $inlineVirtualAdapter->GetEthernetCardSpecFromLabel();
   my $vnicSpec;
   push(@$vnicSpec, $editParams);
   my $vmObj = $self->{'vmOpsObj'};
   my $parameters = $vmObj->ProcessVirtualAdapterSpec($vnicSpec);
   my $deltaSpec = $inlineVirtualAdapter->ConfigureEthernetCardSpec(
                                                            "edit",
                                                            $parameters->[0],
                                                            $originalSpec);
   if (!$deltaSpec) {
      $vdLogger->Error("Failed to edit adapter");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $virtualDeviceConfigSpec = []; # new
   $virtualDeviceConfigSpec->[0] = $deltaSpec;
   my $inlineVMObj = $vmObj->GetInlineVMObject();
   if (!$inlineVMObj->ReconfigureVirtualAdapters($virtualDeviceConfigSpec)) {
      $vdLogger->Error("Failed to edit virtual adapter configuration");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetInlineVirtualAdapter --
#     Method to get inline java object to manage to this adapter
#
# Input:
#     None
#
# Results:
#     reference to an object of VDNetLib::InlineJava::VM::VirtualAdapter
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVirtualAdapter
{
   my $self = shift;

   my $vmObj = $self->{'vmOpsObj'};
   use VDNetLib::InlineJava::VM::VirtualAdapter;
   return VDNetLib::InlineJava::VM::VirtualAdapter->new(
                                        'vmObj' => $vmObj->GetInlineVMObject(),
                                        'deviceLabel' => $self->{'deviceLabel'});
}


########################################################################
#
# ConfigureRoute -
#       This method configures given IPv4 address, netmask, to the given
#       adapter/interface
#
# Input:
#       Route - route operation to configure like add/delete (required)
#       Network or Destination- in the format xx.xx.xx.xx (required)
#       Netmask - in the format xx.xx.xx.xx (required)
#       Gateway - gateway to be configured with route (optional)
#
# Results:
#       "SUCCESS", if the given IPv4 address, netmask is set
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ConfigureRoute
{
   my $self = shift;
   my %args = @_;
   my $routeOperation = $args{route};
   my $netmask = $args{netmask};
   my $network = $args{network};
   my $destination = $args{destination};
   my $gateway = $args{gateway} || undef;

   # TODO: destination is used as workaround for BUG #1365413
   $network = $network || $destination;

   if (not defined $gateway) {
      $vdLogger->Error("Mandatory key gateway missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ((not defined $routeOperation) ||
       (defined $routeOperation) && ($routeOperation !~ /(add|delete)/i)) {
      $vdLogger->Error("Either route operation not defined or ".
                       "Unknown route operation");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Sample route cmd
   # route add -net 192.169.1.0 netmask 255.255.255.0 gw 192.168.1.1 dev eth2
   # route -A inet6 del 2000::/3 gw 2001:0db8:0:f101::1
   #
   my $args = $routeOperation . "," . $network . "," . $netmask . "," .
              $gateway . "," .  $self->{'interface'};
   $vdLogger->Info("Configuring Route on $self->{'controlIP'} to $args");
   return ExecuteRemoteMethod($self->{'controlIP'}, "ConfigureRoute", $args);
}


########################################################################
#
# ConfigureVLAN --
#      This method configures vlan on the given network adapter.
#
# Input:
#      vlanID : a valid vlan id from 1 - 4096. If 0 is passed, then
#      any vlan configured on the given adapter is removed.
#
#      ipv4   : a valid ip for vnic vlan interface(optional).
# Results:
#      - NetAdapter object for the child/vlan interface created;
#      - Do nothing, the configured vlan id and the vlan id are same;
#      - "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ConfigureVLAN
{
   my $self    = shift;
   my $vlanID  = shift;
   my $ipv4    = shift;
   my $vlanInterface = 0;

   if (not defined $vlanID) {
      $vdLogger->Error("Valid NetAdapter object and/or vlan id not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # If the given vlan id is zero, then remove any vlan configuration on the
   # given adapter.
   #

   my $addID = undef; # default to vlan being requested
   my $removeID = undef;
   my $configuredVLANId = $self->GetVLANId();

   if ($vlanID eq "0") {
      if ($configuredVLANId eq "0") {
         # if both wanted and existing vlan id is 0, do nothing
         $vdLogger->Info("VLAN id wanted $vlanID and existing value " .
                         "$configuredVLANId are same");
         $addID = undef;
         $removeID = undef;
      } else {
         # wanted vlan is 0, someother vlan already exists, then remove that
         $removeID = $configuredVLANId;
         $addID = undef;
      }
   } else { # wanted vlan is non-zero
      if ($configuredVLANId eq "0") {
         # existing vlan id is 0, then add
         $addID = $vlanID;
      } elsif ($configuredVLANId ne $vlanID) {
         # wanted and existing vlan ids are different, then
         # remove existing vlan and add wanted vlan
         $addID = $vlanID;
         $removeID = $configuredVLANId;
      } else {
         # if both existing and wanted vlan id is same,
         # calling SetVLAN will do nothing,
         $vdLogger->Info("VLAN id wanted $vlanID and existing value " .
                         "$configuredVLANId are same");
         $addID    = undef;
         $removeID = undef;
      }
   }

   if (defined $removeID) {
      $vdLogger->Info("Removing VLAN $removeID on adapter ".
                      $self->{'macAddress'} .
                      " on $self->{controlIP}");
      my $result = $self->RemoveVLAN();
      if ($result eq "FAILURE") {
         VDSetLastError(VDGetLastError());
         $vdLogger->Info("Removing VLAN ID failed");
         return FAILURE;
      }
   }

   if (defined $addID) {
      my $ip = $ipv4;
      my $netmask = VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK;

      #
      # SetVLAN() method in NetAdapter requires ip address and netmask to be used
      # for the child/vlan interface, so finding any available class C ip address
      #
      if (not defined $ip) {
         $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($self->{controlIP});
         if ($ip eq FAILURE) {
            $vdLogger->Error("Failed to get free IP address");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }

      #
      #
      # Now, call SetVLAN() method in NetAdapter to configure vlan on the given
      # interface.
      #
      $vdLogger->Info("Configuring VLAN $vlanID on adapter ".
                      $self->{'macAddress'} . " with ip " . $ip .
                      " on $self->{controlIP}");
      $vlanInterface = $self->SetVLAN($vlanID, $ip, $netmask);

      if ($vlanInterface eq FAILURE) {
         $vdLogger->Error("Failed to configure VLAN adapter at " .
                          $self->{controlIP});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   #
   # Skip updating parent about vlan configuration if the guest os is windows.
   # There is no child node created for vlan and less confusion in windows.
   #
   my $os = $self->{vmOpsObj}{os};
   if ((defined $os) && ($os =~ /win/i) ) {
      $vdLogger->Info("Not updating parent about vlan " .
                      "since the guest is windows");
      return 0;
   }

   my %paramsHash = (
      addVLANID       => $addID,
      removeVLANID    => $removeID,
      vlanNetObj      => $vlanInterface,
      intType         => $self->{'intType'},
   );
   return \%paramsHash;
}


########################################################################
#
# CreateVLANInterface
#      To create vlan interface on a given vnic
#
# Input:
#      arrayOfSpecs  : array of spec for vlaninterface
#      associatedvlan: name of the vlan using which the interface will be
#                      created.
#
# Results:
#      Returns array of vlan interface objects
#      Returns "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub CreateVLANInterface
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfVlanIntObjects;
   my $iteration = 0;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Vlan interface spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $iteration++;
      my %options       = %$element;
      my $vlan          = $options{vlanid};
      my $vlanInterface = undef;
      my $vswitch;
      my $result = $self->ConfigureVLAN($vlan, $options{ip});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to associate vlan with interface " .
                          "$vlanInterface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $os = $self->{vmOpsObj}{os};
      if ((defined $os) && ($os =~ /win/i) ) {
         $vlanInterface = $self->{interface};
         } else {
         $vlanInterface = $self->{interface} . '.' . $vlan;
      }

      my $vlanInterfaceObj =
         VDNetLib::NetAdapter::Vnic::VlanInterface->new(
            'vnicObj'       => $self,
            'vlanInterface' => $vlanInterface,
            'stafHelper' => $self->{stafHelper});

      if ($vlanInterfaceObj eq FAILURE) {
         $vdLogger->Error("Failed to create object for vlan interface " .
                          "$vlanInterface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfVlanIntObjects, $vlanInterfaceObj;
   }
   return \@arrayOfVlanIntObjects;
}


########################################################################
#
# DeleteVLANInterface --
#      This method deletes the given VlanInterface
#
# Input:
#      arrayOfVlanInterfaceObjects: array of spec for VlanInterface
#
# Results:
#      Returns "SUCCESS" if the given VlanInterface is deleted successfully
#      Returns "FAILURE" in case of any errror.
#
# Side effects:
#      None
#
########################################################################

sub DeleteVLANInterface
{
   my $self = shift;
   my $arrayOfVlanInterfaceObjects = shift;

   foreach my $vlanInterface (@$arrayOfVlanInterfaceObjects) {
      my $result = $self->ConfigureVLAN("0", $self->{controlIP});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to associate vlan with interface " .
                          "$vlanInterface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Delete VlanInterface $vlanInterface->{interface} passed");
   }
   return SUCCESS;
}


########################################################################
#
# CreateIPInterface
#      Create sub ip interfaces only on linux vm
#
# Input:
#      arrayOfSpecs  : array of spec for ipinterface
#      associatedip  : name of the Ips using which the interface will be
#                      created.
#
# Results:
#      Returns array of ip interface objects
#      Returns "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub CreateIPInterface
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfIpIntObjects;
   my $iteration = 0;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Ip interface spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $iteration++;
      my %options       = %$element;
      my $ipAddress     = $options{ipv4address};
      my $netmask       = $options{netmask};
      my $subipindex    = $options{subipindex};
      my $ipInterface   = $self->{interface} . ':' . $subipindex;
      my $vswitch;
      my $result = $self->AddIPv4($ipAddress, $netmask, $subipindex);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to associate vlan with interface " .
                          "$ipInterface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $ipInterfaceObj =
         VDNetLib::NetAdapter::Vnic::IpInterface->new(
            'vnicObj'     => $self,
            'ipInterface' => $ipInterface,
            'stafHelper'  => $self->{stafHelper});

      if ($ipInterfaceObj eq FAILURE) {
         $vdLogger->Error("Failed to create object for ip interface " .
                          "$ipInterface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfIpIntObjects, $ipInterfaceObj;
   }
   return \@arrayOfIpIntObjects;
}


########################################################################
#
# GetUUID --
#     Method to get UUID of Vnic
#
# Input:
#     None
#
# Results:
#     UUID, if successful;
#     FAILURE, in case of errors;
#
# Side effects:
#     None
#
########################################################################

sub GetUUID
{
   my $self = shift;
   my $inlineObj = $self->GetInlineVirtualAdapter();
   if ($inlineObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline object for Vnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $inlineObj->GetUUID();
}


########################################################################
#
# GetVnicUUID --
#     Method to get UUID of Vnic and append it with .002 as VC accepts it
#     in this format.
#
#
# Input:
#    before: fe80::250:56ff:fe96:32ce-2
#
# Results:
#     Converted UUID, if successful;
#     after: fe80::250:56ff:fe96:32ce.002
#     FAILURE, in case of errors;
#
# Side effects:
#     None
#
#########################################################################

sub GetVnicUUID
{
   my $self = shift;
   my $moid = FAILURE;
   $moid = $self->GetUUID();
   if ($moid eq FAILURE) {
      $vdLogger->Error("Failed to get adapter id for Vnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $moid =~s/(-)(\d)$/\.00$2/;
   return $moid;
}


#########################################################################
#
# GetVsishIpLearningEntriesFromHost --
#     Method to get vm vsish entries from host, it will be used for
#            verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       ip  => undef,
#                       mac => undef
#                     }
#                  ],
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#      None.
#
#########################################################################

sub GetVsishIpLearningEntriesFromHost
{
   my $self         = shift;
   my $serverForm   = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my @serverData;
   my $vmAdapterVSIPort;
   my $vmAdapterPortID;
   my $vmiPath;
   my $vmi;

   $vmAdapterVSIPort = $self->{vmOpsObj}->{hostObj}->GetvNicVSIPort(
                                                         $self->{macAddress});
   if (not defined $vmAdapterVSIPort) {
      $resultHash->{reason} = "Fetch VM net adapter VSI port info failed";
      return $resultHash;
   }

   $vdLogger->Debug("vm vnic mac address is " . $self->{macAddress} .
                    "vm vnic ip address is " . $self->GetIPv4() .
                    "vm VSI port index is " . $vmAdapterVSIPort);
   #
   #vmAdapterVSIPort should be like "/net/portsets/DvsPortset-0/ports/16777218"
   #
   if ($vmAdapterVSIPort =~ /\/net\/portsets\/DvsPortset-.*\/ports\/(.*)/i) {
      $vmAdapterPortID = $1;
   }
   if (not defined $vmAdapterPortID) {
      $resultHash->{reason} = "Fetch VM net adapter port ID failed";
      return $resultHash;
   }

   $vmiPath = "\/vmkModules\/dvfilter-switch-security\/security\/" .
              $vmAdapterPortID . "\/vmi\/";
   my $output = $self->{vmOpsObj}->{hostObj}->GetVMIIndexInfo($vmiPath);
   $vdLogger->Debug("vmi index info: " . Dumper($output));
   my @vmiIndex = ();
   if (($output ne "") && ($output ne FAILURE)) {
      @vmiIndex = split ("\n", $output);
   }

   foreach my $index (@vmiIndex) {
      $vmiPath = "\/vmkModules\/dvfilter-switch-security\/security\/" .
                 $vmAdapterPortID .
                 "\/vmi\/" . $index;
      $vdLogger->Info("checking vmi info : " . $vmiPath);
      my $result = $self->{vmOpsObj}->{hostObj}->GetVMISummary($vmiPath);
      if ((not defined $result) or ($result eq FAILURE)) {
         $vdLogger->Warn("Failed to get vim summary info about $vmiPath");
         next;
      }
      $vmi = $result;
      push @serverData, {'ip'  => $vmi->{"IP Address"},
                         'mac' => uc($vmi->{"Etherenet MAC"})};
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


#########################################################################
#
# GetMcastStatsFromServer --
#     Method to access mcast stats vsish entries from host, it will be used
#               for verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#             [
#                {
#                    'mcastprotocol => undef,
#                    'mcastversion  => undef,
#                    'mcastmode     => undef,
#                    'groupaddr     => undef,
#                    'sourceaddrs   => [],
#                },
#             ]
#    mcastProtocol : multicast protocol, IGMP/MLD
#    mcastAddr     : IPv4 or IPv6 multicast address
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#      None.
#
#########################################################################

sub GetMcastStatsFromServer
{
   my $self          = shift;
   my $serverForm    = shift;
   my $mcastProtocol = uc(shift);
   my $mcastAddr     = shift;
   my $resultHash    = {
     'status'   => "FAILURE",
     'response' => undef,
     'error'    => undef,
     'reason'   => undef,
   };
   my $mcastFilterPath;
   my @serverData;

   my $portSetName = $self->GetPortSetName();
   if ($portSetName eq FAILURE) {
      $resultHash->{reason} = "Failed to find portset name";
      return $resultHash;
   }
   my $vmAdapterPortID = $self->GetPortID();
   if ($vmAdapterPortID eq FAILURE) {
      $resultHash->{reason} = "Failed to find vm port id";
      return $resultHash;
   }

   $mcastFilterPath = "\/vmkModules\/etherswitch\/McastFilter\/Portsets\/" .
                               $portSetName. "\/ports\/$vmAdapterPortID\/" .
                                                      $mcastProtocol . "\/";
   my $output = $self->{vmOpsObj}->{hostObj}->GetVMIIndexInfo($mcastFilterPath);
   if ($output eq FAILURE) {
      $resultHash->{reason} = "Couldn't find group address entries from " .
                                            "vsi node " . $mcastFilterPath;
      return $resultHash;
   }

   # An expected output looks like below, a string includes one or more
   # lines ending with '/' and '\n',
   # $output = 'ff390000:00000000:00000000:00020001/
   #            ff020000:00000000:00000000:000000fb/
   #            ff020000:00000000:00000001:ffa11fd9/';
   my @mcast_addrs = ();
   my $matched_addr = undef;
   @mcast_addrs = split ("\n", $output);
   foreach my $mcast_addr (@mcast_addrs) {
       $mcast_addr =~ s/\///g;
       if ($mcastAddr eq $mcast_addr) {
           $vdLogger->Debug("Found matched group address: $mcastAddr");
           $matched_addr = $mcast_addr;
           last;
       }
   }
   if (not defined $matched_addr) {
      push @serverData, { 'groupaddr' => '', };
      $resultHash->{status}   = "SUCCESS";
      $resultHash->{response} = \@serverData;
      return $resultHash;
   }

   $mcastFilterPath = $mcastFilterPath . $matched_addr . "\/stats";
   my $result = $self->{vmOpsObj}->{hostObj}->GetVMISummary($mcastFilterPath);
   if ((not defined $result) or ($result eq FAILURE)) {
      $resultHash->{reason} = "Failed to get mcast filter stats for " .
                                                    "$mcastFilterPath";
      return $resultHash;
   }
   # An expected result is a hash and looks like below,
   # $result = {
   #       'updated for seconds' => '17',
   #       'mode' => 'Source IP filter mode: 2 -> exclude',
   #       'source IPv6 filters' => '20020000:00000000:00000000:00010001, .. ,',
   #       'MLD version' => '2'
   # };
   my $mcastFilterStats = $result;
   my $modeKey = "mode";
   my $versionKey = $mcastProtocol . " version";
   my $sourceKey;
   if ($mcastProtocol eq "MLD") {
      $sourceKey = "source IPv6 filters";
   } else {
      $sourceKey = "source IPv4 filters";
   }
   my $modeValue = $mcastFilterStats->{$modeKey};
   my $versionValue = $mcastFilterStats->{$versionKey};
   my $sourceValue = $mcastFilterStats->{$sourceKey};
   if ($modeValue !~ /^Source IP filter mode: \d -> ([A-Za-z]+)$/) {
      $resultHash->{reason} = "Couldn't recognize mode format $modeValue";
      return $resultHash;
   } else {
      $modeValue = lc($1);
   }
   $sourceValue =~ s/\s//g;
   my @source_val_array = split(",", $sourceValue);
   if ($#source_val_array == -1) {
      $source_val_array[0] = 'empty';
   }

   push @serverData, {
                       'mcastprotocol'  => $mcastProtocol,
                       'groupaddr'      => $mcastAddr,
                       'mcastmode'      => $modeValue,
                       'mcastversion'   => $versionValue,
                       'sourceaddrs'    => \@source_val_array,
                     };

   $vdLogger->Info("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;

   return $resultHash;
}

#########################################################################
#
# GetNetworkFeatures --
#     Method to access the network feature summary for the given the vnic
#
# Input:
#   None
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#      None.
#
#########################################################################

sub GetNetworkFeatures
{
   my $self       = shift;
   my $resultHash = {
     'status'   => "FAILURE",
     'response' => undef,
     'error'    => undef,
     'reason'   => undef,
   };
   my @serverData;
   my $data;
   my $portId;
   my $vmAdapterVSIPort = $self->{vmOpsObj}->{hostObj}->GetvNicVSIPort(
                                                         $self->{macAddress});
   if (not defined $vmAdapterVSIPort) {
      $resultHash->{reason} = "Fetch VM net adapter VSI port info failed";
      return $resultHash;
   }

   #
   #vmAdapterVSIPort should be like "/net/portsets/DvsPortset-0/ports/16777218"
   #
   if ($vmAdapterVSIPort =~ /\/net\/portsets\/DvsPortset-.*\/ports\/(.*)/i) {
      $portId = $1;
   }
   my $command = "net-swsec --show-conf -p $portId";
   my $result = $self->{vmOpsObj}->{stafHelper}->STAFSyncProcess(
              $self->{vmOpsObj}->{hostObj}->{'hostIP'}, $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      $resultHash->{reason} = "Failed to get features summary for " .
                                             "port $portId";
      return $resultHash;
   }
   my @output = split(/\n/, $result->{stdout});
   foreach my $line (@output) {
      $line =~ s/^\s+|\s+$//g;
      my ($key, $value) = split(/:/, $line);
      $key =~ s/^\s+|\s+$//g;
      $value =~ s/^\s+|\s+$//g;
      $data->{$key} = $value;
   }

   push @serverData, $data;
   $vdLogger->Info("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;

   return $resultHash;
}


#########################################################################
#
# GetMcastFilterModeFromServer --
#     Method to access mcast mode vsish entries from host, it will be used
#               for verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#             [
#                {
#                    'mcastfiltermode => undef,
#                },
#             ]
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#      None.
#
#########################################################################

sub GetMcastFilterModeFromServer
{
   my $self       = shift;
   my $serverForm = shift;
   my $resultHash = {
     'status'   => "FAILURE",
     'response' => undef,
     'error'    => undef,
     'reason'   => undef,
   };
   my $mcastFilterModePath;
   my @serverData;

   my $portSetName = $self->GetPortSetName();
   if ($portSetName eq FAILURE) {
      $resultHash->{reason} = "Failed to find portset name";
      return $resultHash;
   }
   $mcastFilterModePath = "\/vmkModules\/etherswitch\/McastFilter\/Portsets\/" .
                                                           "$portSetName\/mode";
   my $command = "vsish -pe get $mcastFilterModePath";
   my $result = $self->{vmOpsObj}->{stafHelper}->STAFSyncProcess(
              $self->{vmOpsObj}->{hostObj}->{'hostIP'}, $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      $resultHash->{reason} = "Failed to get mcast filter mode from " .
                                                "$mcastFilterModePath";
      return $resultHash;
   }
   my $mcastFilterMode = $result->{stdout};
   # The expected result is a string include '"' and '\n',
   # $VAR1 = '"Snooping"
   # ';
   $mcastFilterMode =~ s/"|\R//g;
   push @serverData, { 'mcastfiltermode'  => lc($mcastFilterMode), };

   $vdLogger->Info("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;

   return $resultHash;
}


#########################################################################
#
# Read --
#     Method to get runtime attributes of the vnic.
#
# Input:
#     None
#
# Results:
#     Return mac address attribute of object
#
# Side effects:
#      None.
#
#########################################################################

sub Read
{
   my $self       = shift;
   my $vmOpsObj = $self->{'vmOpsObj'};
   my $hostObj  = $vmOpsObj->{'hostObj'};

   my $portsHash = $vmOpsObj->GetNetworkPortsInfo();
   my $macAddress = lc($self->{'macAddress'});
   my $payload;
   if (exists $portsHash->{$macAddress}) {
      $payload = $portsHash->{$macAddress};
   } else {
      $vdLogger->Error("Failed to find port id of $macAddress" .
                        Dumper($portsHash));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $mapperHash = {
      'Port ID'         => 'portid',
      'vSwitch'         => 'vswitch',
      'Portgroup'       => 'portgroup',
      'DVPort ID'       => 'dvportid',
      'MAC Address'     => 'macaddress',
      'IP Address'      => 'ipaddress',
      'Team Uplink'     => 'teamuplink',
      'Uplink Port ID'  => 'uplinkportid',
      'Active Filters'  => 'activefilters',
   };
   my $serverData;
   foreach my $key (keys %$payload) {
      if (exists $mapperHash->{$key}) {
         $serverData->{$mapperHash->{$key}} = $payload->{$key};
      }
   }
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverData,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
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
   my $mac = $self->{macAddress};
   my $ip = $self->GetIPv4();
   my $inlinePyObj;
   eval {
      # FIXME(salmanm): Workaround till all the esx related methods have been
      # moved to the python layer.
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass}, $parentObj,
                                              $ip, $mac, $self->{interface});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (defined $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   if (defined $self->{interface}) {
      $inlinePyObj->{interface} = $self->{interface};
   }
   return $inlinePyObj;
}

######################################################################
#
# Getdvport --
#     Methd to get dvport number of the vnic interface.
#
# Input:
#     None
#
# Results:
#     dvport number which connect specified vnic of vm
#     When you launch command 'esxcfg-vswitch -l' on host,
#     you get, say dvport 9, connect to vm.1.vnic.1. Then '9'
#     will return as result.
#
# Side effects:
#     None
#
#######################################################################

sub Getdvport
{
   my $self = shift;
   if (not defined $self->{'vmOpsObj'}) {
      $vdLogger->Error("VM object not defined!");
      return FAILURE;
   }
   my $vmOpsObj = $self->{'vmOpsObj'};

   if (not defined $vmOpsObj->{'hostObj'}) {
      $vdLogger->Error("Host object not defined!");
      return FAILURE;
   }
   my $hostObj  = $vmOpsObj->{'hostObj'};

   if (not defined $self->{macAddress}) {
      $vdLogger->Error("This vnic has no mac address!");
      return FAILURE;
   }

   my $result = $hostObj->GetvNicDVSPortID($self->{macAddress});
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get dvport number of the vnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $result;
}

1;
