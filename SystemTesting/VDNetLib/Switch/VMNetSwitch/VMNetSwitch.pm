########################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Switch::VMNetSwitch::VMNetSwitch;


use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );

our $vmnetCfgCLI = "/automation/bin/x86_32/esx/vmnetCfgCLI";

# All the functionality which is there in "Virtual Network Editor" of WS
# and some of the same functionality of Fusion(as VNE is not there on fusion)
# will be placed in this module. It will deal the VMNet0 to VMNet8 which
# the vSwitch on Hosted products.

########################################################################
#
# new --
#      This method is the entry point to this package.
#
# Input:
#      A named parameter hash with following keys:
#      ********** Inputs are not sure at this time *****************
#      'switch' : Name/identifier of the switch (Required)
#      'switchType' : "vmnetswitch" (Required)
#      'host'       : IP address of the host or switch itself which is
#                      required to access and configure the switch.
#
# Results:
#      Obj of VMNetSwitch class.
#      FAILURE - in case of error.
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self;

   $self->{'host'}       = $args{'host'};
   $self->{'switch'}     = $args{'switch'};
   $self->{'stafHelper'} = $args{'stafHelper'};
   $self->{'hostOpsObj'} = $args{'hostOpsObj'};

   if (not defined $self->{'host'}) {
      $vdLogger->Error("host name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{'switch'}) {
      $vdLogger->Error("switch name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   bless($self);

   #
   # Create a VDNetLib::Common::STAFHelper object with default options
   # if reference to this object is not provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   return $self;
}


########################################################################
#
# AddvSwitchUplink
#     This method used to add uplink to vswitch vmnet
#     Method: use movebridge to change mapping of vmnet and host adapter
#               vmnetCfgCLI movebridge eth1 NULL vmnet0
# Input:
#      pNIC : physical adapter name
#
# Output:
#      SUCCESS for sucessful operation
#      FAILURE if something wrong
#
########################################################################

sub AddvSwitchUplink
{
   my $self = shift;
   my $pNIC = shift;
   my $res;
   my $command;
   my $vSwitch = $self->{'switch'};

   $command = "$vmnetCfgCLI movebridge $pNIC NULL $vSwitch";
   $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to execute $command on $self->{host}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $self->{hostOpsObj}->HostNetRefresh();

   $command = "$vmnetCfgCLI getbridge $vSwitch";
   $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to execute $command on $self->{host}");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ($res->{stderr} ne ''  ||
                $res->{stdout} !~ /$vSwitch is bridged to $pNIC/) {
      $vdLogger->Error("$vSwitch is not able to bridged to $pNIC\n".
                        Dumper($res));
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
# Note:
#
########################################################################

sub RemoveVMKNIC
{
   #TODO: Implement this method for hosted. It will remove the host
   # adapter from the vmnetX switch.
   return SUCCESS;
}

1;
