########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NetAdapter::Vtep::KVMVtep;

use strict;
use warnings;
use Hash::Util qw(hv_store);
use base 'VDNetLib::Root::Root';
use base 'VDNetLib::NetAdapter::NetAdapter';
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);

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
   my $pyclass = 'vmware.kvm.vtep.vtep_facade.VTEPFacade';
   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for VTEP");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{parentObj} = $args{parentObj};
   $self->{hostObj} = $args{parentObj};
   if (lc($self->{parentObj}) =~ m/kvmoperations/) {
      $self->{_pyclass} = $pyclass;
   } else {
      $vdLogger->Error("Creating VTEP on $self->{parentObj} is not supported");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $self->{_pyIdName} = "name";
   $self->{controlIP} = $self->{parentObj}->{hostIP};
   $self->{hostName} = $self->{parentObj}->{hostIP};
   $self->{id} = undef;
   $self->{deviceId} = undef;
   hv_store(%$self, 'deviceId', $self->{'id'});
   hv_store(%$self, 'interface', $self->{'id'});
   bless $self;
   return $self;
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


################################################################################
#
# SetMTU -
#  Set MTU for a specified vtep. Returns SUCCESS if it is successful.
#
# Input -
#  value - Value of the MTU size to be set
#
# Results -
#  Returns SUCCESS if successful
#  Returns FAILURE if MTU is not set / specified vtep is not found
#
# Side effects -
#  None
#
################################################################################

sub SetMTU
{
   my $self = shift;
   my $value = shift;

   if (not defined $value) {
      $vdLogger->Error("Value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $result = $self->set_adapter_mtu({'mtu'=> $value});
   return $result;

}


################################################################################
#
# GetMTU -
#  Get MTU for a specified vtep.
#
# Input -
#    None
#
# Results -
#  Returns MTU if successful get mtu
#  Returns FAILURE if MTU is get
#
# Side effects -
#  None
#
################################################################################

sub GetMTU
{
   my $self = shift;
   my $result =  $self->get_adapter_mtu({});
   return $result;
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
       $vdLogger->Error("IP address not provided");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $args = $self->{'id'} . "," . $ipaddr . "," . $netmask;
   $args = $args . "," . $gateway if (defined $gateway);
   $vdLogger->Info("Setting IPv4 in $self->{'controlIP'} on $args");
   return ExecuteRemoteMethod($self->{'controlIP'}, "SetIPv4", $args);
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
   my $self = shift;
   $self->{'macAddress'} = ExecuteRemoteMethod($self->{'controlIP'},
                                               "GetMACAddress",
                                               $self->{id});
   return $self->{'macAddress'};
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
   return ExecuteRemoteMethod($self->{'controlIP'}, "GetNetworkAddr",
                              $self->{id});
}


################################################################################
#
# SetDeviceStatus -
#  Enables / disables a vtep and returns SUCCESS if the status has been
#  changed properly.
#
# Input -
#  action: 'UP' or 'DOWN'.
#
# Results -
#  Returns SUCCESS if vtep is enabled / disabled
#  Returns FAILURE if vtep is not enabled / disabled
#
# Side effects -
#  None
#
################################################################################

sub SetDeviceStatus
{
   my $self = shift;
   my $action = shift;
   my $args = $self->{id};
   $args = $args . "," . $action;
   return ExecuteRemoteMethod($self->{'controlIP'}, "SetDeviceStatus", $args);
}

1;
