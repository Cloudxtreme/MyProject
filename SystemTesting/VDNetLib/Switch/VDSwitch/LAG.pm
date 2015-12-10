#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::VDSwitch::LAG;

#
# This package is responsible for handling all the interaction with
# VMware VDS's Link Aggregation Group
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::Utilities;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS
                                   VDSetLastError VDGetLastError);

use constant DEFAULT_LACPVERSION => "multiplelag";
use constant DEFAULT_LAG_PORTS   => 6;
use constant DEFAULT_LAG_MODE    => "passive";
use constant DEFAULT_LAG_LB      => "srcDestIpTcpUdpPortVlan";
use constant DEFAULT_LAG_TIMEOUT => "long";

#######################################################################
#
# new --
#      Constructor for LAG class
#
# Input:
#      A named parameter list, in other words a hash with following keys:
#      'switchObj': Object of the switch(vDS) (Required)
#      'stafHelper': object of VDNetLib::STAFHelper (Required)
#      Below are all optional params that can be set while creating lag
#      lagname
#      lagmode
#      lagtimeout
#      lagloadbalancing
#      lagvlantype
#      lagvlantrunkrange
#      lagnetflow
#      lagports
#
# Results:
#      An object of Lag class, if successful
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
#######################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;

   if ((not defined $args{switchObj}) || (not defined $args{stafHelper}) ) {
      $vdLogger->Error("Either switchobject or stafhelper is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $self;
   $self->{switchObj} = $args{switchObj};
   $self->{stafHelper} = $args{stafHelper};
   $self->{lagname} = undef;
   $self->{lagmode} = undef;
   $self->{lagtimeout} = undef;
   $self->{lagloadbalancing} = undef;
   $self->{lagports} = undef;

   bless($self, $class);
   $self->SetDefaultParams(%args);
   return $self;
}


#######################################################################
#
# GetLagName--
#      To get lag name from this object
#
# Input:
#
# Results:
#      name: name of this lag
#
# Side effects:
#      None
#
#######################################################################

sub GetLagName
{
   my $self = shift;
   return $self->{lagname};
}


#######################################################################
#
# SetLagId --
#      To set lag id on the inline java lag obj
#
# Input:
#      id: ID of this lag
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagId
{
   my $self = shift;
   my $lagId = shift;
   $self->{lagId} = $lagId;

}

#######################################################################
#
# SetLagTimeout--
#      To set long or shot LACP Protocol timeout for this
#      lag on a member host
#
# Input:
#      timeout: long or short(mandatory)
#      refObjHosts:  reference of host object on which to set timeout
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagTimeout
{
   my $self = shift;
   my $lagTimeout = shift;
   my $refObjHosts = shift;
   my $vdsName = $self->{switchObj}->{switch};
   my $timeout;

   if ((not defined $lagTimeout) || (not defined $refObjHosts)) {
      $vdLogger->Error("SetLagTimeout failed. Missing timeout value or host");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($lagTimeout =~ /short/i) {
      $timeout = " -t 1 ";
   } elsif ($lagTimeout =~ /long/i) {
      $timeout = " -t 0 ";
   } else {
      $vdLogger->Error("SetLagTimeout failed. Wrong timeout value. Only ".
                       "short|long is accepted");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $host (@$refObjHosts) {
      my $hostIP = $host->{hostIP};
      #
      # No VIM API support
      # E.g esxcli network vswitch dvs vmware
      # lacp timeout set -l 1 -t 1 -s dvs-1
      #
      my $command = "esxcli network vswitch dvs vmware lacp timeout set ";
      $command = $command . " $timeout " .
                 " -l $self->{lagId} " .
                 " -s $vdsName ";
      $vdLogger->Debug("Setting lag timeout with $command on $hostIP");
      my $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to set timeout $lagTimeout for ".
                          "$self->{lagname}, $vdsName on $hostIP ".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $vdLogger->Info("Successfully set timeout $lagTimeout for ".
                          "$self->{lagname}, $vdsName on $hostIP");
   }
   return SUCCESS;
}


#######################################################################
#
# SetDefaultParams--
#      To set default parameters of this lag object and apply them on
#      inline java lag object.
#
# Input:
#      params of this class
#
# Results:
#      An object of Lag class, if successful
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
#######################################################################

sub SetDefaultParams
{
   my $self = shift;
   my %args = @_;
   # Set the lacpversion passed by user. Else set default
   $self->{lacpversion} = $args{lacpversion} || DEFAULT_LACPVERSION;

   #
   # Enable/Disable for version1,
   # Always Enable for version2
   #
   if ($self->{lacpversion} =~ /multiplelag/i) {
      $self->{lagstate} = "enable";

      if (not defined $args{lagname}) {
         # Make unique lag names even when they were created within 1s.
         my $index = int (rand(10000));
         $self->{lagname} =
                VDNetLib::Common::Utilities::GenerateNameWithRandomId("lag", $index);
      } else {
         $self->{lagname} = $args{lagname};
      }

      $self->{lagports}    = $args{lagports} || DEFAULT_LAG_PORTS;
      $self->{lagloadbalancing}  = $args{lagloadbalancing} || DEFAULT_LAG_LB;

      $self->{lagvlantype}       = undef;
      $self->{lagvlantrunkrange} = undef;
   } else {
      $self->{lagstate} = $args{lagoperation};
      $self->{lagname} = "default_uplink_pg_lag";
      $self->{lagId} = 0;
   }

   $self->{lagmode} = $args{lagmode} || DEFAULT_LAG_MODE;
   $self->{lagtimeout} = $args{lagtimeout} || DEFAULT_LAG_TIMEOUT;
   return SUCCESS;
}

#######################################################################
#
# EditParams --
#      To edit parameters of this vdnet lag obj and apply them on inline
#      java lag object.
#
# Input:
#      params of this class
#
# Results:
#      An object of Lag class, if successful
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
#######################################################################

sub EditParams
{
   my $self = shift;
   my %args = @_;

   $self->{lagstate} = $args{lagoperation} if defined $args{lagoperation};
   $self->{lagname}  = $args{lagname} if defined $args{lagname};
   $self->{lagtimeout}  = $args{lagtimeout} if defined $args{lagtimeout};
   $self->{lagmode}     = $args{lagmode} if defined $args{lagmode};
   $self->{lagports}    = $args{lagports} if defined $args{lagports};
   $self->{lagloadbalancing}  = $args{lagloadbalancing}
                                          if defined $args{lagloadbalancing};

   $self->{lagvlantype}       = undef; #TODO: Fix these two
   $self->{lagvlantrunkrange} = undef;
   return SUCCESS;
}



########################################################################
#
# EditLinkAggregationGroup
#      This method edits LACPv2 LAG on VDS
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

sub EditLinkAggregationGroup
{
   my $self = shift;
   my %options = @_;

   if ($self->{lacpversion} =~ /multiplelag/i) {
      my $ret = $self->EditParams(%options);
      if (not defined $ret || (defined $ret && $ret =~ /(FAILURE|FALSE)/i)) {
         $vdLogger->Error("EditParams failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      my $inlineDVSObj = $self->{switchObj}->GetInlineDVS();
      $ret = $inlineDVSObj->ConfigureInlineLAG($self, "edit");
      if (!$ret || (defined $ret && $ret =~ /(FAILURE|FALSE)/i)) {
         $vdLogger->Error("Edit InlineLinkAggregationGroup failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      $vdLogger->Info("Successfully edited lag:$self->{lagname} on".
                      " VDS:$self->{switchObj}->{switch}");
   }
   return SUCCESS;
}


########################################################################
#
# ConfigUplinkToLag --
#     Method to config uplinks to a link aggregation group
#
# Input:
#     operation:        operation (add/remove)
#     refArrayObjVmnic: vdnet vmnic objects
#
# Results:
#     "SUCCESS",if config uplink works fine
#     "FAILURE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigUplinkToLag
{
   my $self = shift;
   my $operation = shift;
   my $refArrayObjVmnic = shift;

   if (not defined $operation) {
      $vdLogger->Error("operation is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $refArrayObjVmnic) {
      $vdLogger->Error("refArrayObjVmnic is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $operationRef = {
      'add'    => 'AddUplinkToLag',
      'remove' => 'RemoveUplinkFromLag',
   };
   my $method  = $operationRef->{$operation};
   $vdLogger->Debug("$operation uplinks on lag: $self->{lagname}");

   my @arrMapping;
   my %involvedHost = ();

   foreach my $vmnicObj (@$refArrayObjVmnic) {
      my @arr;
      my $hashRef;
      my $hostObj = $vmnicObj->{hostObj};
      my $hostIP = $hostObj->{hostIP};
      my $inlineHostObject = $hostObj->GetInlineHostObject();

      if (defined $involvedHost{$hostIP}) {
         next;
      }
      $involvedHost{$hostIP} = 1;

      foreach my $vmnicObject (@$refArrayObjVmnic) {
         my $ip = $vmnicObject->{hostObj}->{hostIP};
         if ($ip eq $hostIP) {
            my $vmnicName = $vmnicObject->{vmnic};
            $vdLogger->Debug("$operation host $hostIP $vmnicName on lag");
            push (@arr, $vmnicName);
         }
      }
      $hashRef = { 'inlineHostObj' => $inlineHostObject,
                   'vmnicNames'=> \@arr
                 };
      push(@arrMapping, $hashRef);
   }

   my $ret = $self->$method(\@arrMapping);
   if ((not defined $ret) || ($ret == 0)) {
      $vdLogger->Error("$operation uplink failed");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Successfully $operation uplink to lags");
   return SUCCESS;
}


########################################################################
#
# CheckUplinkState --
#     Method to check uplink state in a link aggregation group
#
# Input:
#     expectedState:    Expected uplink state
#                       (Bundled|Independent|Stand-alone|Hot-standby)
#     refArrayObjVmnic: vdnet vmnic objects
#
# Results:
#     "SUCCESS",if the uplink state is the same as expected
#     "FAILURE",in case of any error or the state is not as expected
#
# Side effects:
#     None
#
########################################################################

sub CheckUplinkState
{
   my $self = shift;
   my $expectedState = shift;
   my $refArrayObjVmnic = shift;
   my $lagid = $self->{lagId};

   if (not defined $expectedState) {
      $vdLogger->Error("expectedState is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $refArrayObjVmnic) {
      $vdLogger->Error("refArrayObjVmnic is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $vmnicObj (@$refArrayObjVmnic) {
      my $hostObj = $vmnicObj->{hostObj};
      my $hostIP = $hostObj->{hostIP};
      my $vmnicName = $vmnicObj->{vmnic};

      # command to get lag status info
      my $command = "esxcli network vswitch dvs vmware lacp status get";
      my $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command to get lag status info failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Debug("Lag info of host $hostIP: $result->{stdout}");

      if ($result->{stdout} =~ m/\s$lagid\s.*?$vmnicName.*?\s+\sState:\s+(.*?)\s+/is) {
         if ($1 =~ m/$expectedState/i) {
            $vdLogger->Info("Lag state: $vmnicName on $hostIP is $expectedState");
         } else {
            $vdLogger->Error("Lag state: $vmnicName on $hostIP is $1, rather ".
                             "than $expectedState");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("No lag info for $vmnicName of $hostIP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# CheckVob --
#     Method to check vob messages for link aggregation group up/down
#
# Input:
#     expectedState: Expected lag state (up|down)
#     refObjHost:    vdnet host object
#
# Results:
#     "SUCCESS",if the lag state is the same as expected
#     "FAILURE",in case of any error or the state is not as expected
#
# Side effects:
#     None
#
########################################################################

sub CheckVob
{
   my $self = shift;
   my $expectedState = shift;
   my $refObjHost = shift;
   my $hostIP = $refObjHost->{hostIP};
   my $lagname = $self->{lagname};
   my $string;

   if (not defined $expectedState) {
      $vdLogger->Error("expectedState is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif ($expectedState !~ m/up|down/i) {
      $vdLogger->Error("$expectedState is invalid, only up|down is supported");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($expectedState =~ m/up/i) {
      $string = "Link aggregation group $lagname on VDS DvsPortset-[0-9] is up";
   } else {
      $string = "Link aggregation group $lagname on VDS DvsPortset-[0-9] is down";
   }

   my $command = "grep -i '$string' /var/log/vobd.log";
   my $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to get lag vob message failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq "") {
      $vdLogger->Error("No vob message found for $lagname $expectedState");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      $vdLogger->Debug("Vob message is $result->{stdout}");
   }
   return SUCCESS;
}

1;
