########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NetAdapter::Vtep::ESXVtep;

use strict;
use warnings;
use Hash::Util qw(hv_store);
use base 'VDNetLib::Root::Root';
use base 'VDNetLib::NetAdapter::Vmknic::Vmknic';
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              CallMethodWithKWArgs);

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
   my $pyclass = 'vmware.vsphere.esx.vtep.vtep_facade.VTEPFacade';
   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for VTEP");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{parentObj} = $args{parentObj};
   $self->{hostObj} = $args{parentObj};
   if (lc($self->{parentObj}) =~ m/hostoperations/) {
       $self->{_pyclass} = $pyclass;
       $self->{intType} = 'vmknic';
       $self->{netstackName} = 'vxlan';
   } else {
      $vdLogger->Error("Creating VTEP on $self->{parentObj} is not supported");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $self->{_pyIdName} = "name";
   $self->{controlIP} = $self->{parentObj}->{hostIP};
   $self->{hostName} = $self->{parentObj}->{hostIP};
   $self->{switchType} = 'vdswitch';
   $self->{id} = undef;
   $self->{deviceId} = undef;
   $self->{interface} = undef;
   $self->{switch} = undef;
   $self->{dvport} = undef;
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


################################################################################
#
# SetDeviceStatus -
#  Enables / disables a vtep and returns SUCCESS if the status has been changed properly
#
# Input -
#  'UP' or 'DOWN'.
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

   # Get adapter_info for all adapters.
   my $parentPerlObj = $self->{parentObj};
   my $parentPyObj = $parentPerlObj->GetInlinePyObject();
   if ($parentPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get parent inline python object");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vtepPyObj = $self->GetInlinePyObject($parentPyObj);
   if ($vtepPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline python object");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $adapterInfo = CallMethodWithKWArgs($vtepPyObj, 'get_adapter_info', {});
   if ($adapterInfo eq FAILURE) {
      $vdLogger->Error("Failed to get adapter info.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $adapterInfo = $adapterInfo->{table};
   # Find the switch and dvport for the adapter of interest.
   my $match;
   foreach my $element (@$adapterInfo) {
      my %table = map {lc $_ => $element->{$_}} keys %$element;
      if ((defined $table{name}) && ($table{name} eq $self->{id})) {
         $self->{switch} = $table{portset};
         $self->{dvport} = $table{'vds port'};
         $match = 1;
         last;
      }
   }

   if (not defined $match) {
      $vdLogger->Debug("Adapter info:\n $adapterInfo");
      $vdLogger->Error("Adapter info does not have record for $self->{id}.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $self->SUPER::SetDeviceStatus($action);
}

1;
