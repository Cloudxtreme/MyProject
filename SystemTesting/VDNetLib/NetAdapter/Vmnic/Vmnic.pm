################################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
################################################################################
package VDNetLib::NetAdapter::Vmnic::Vmnic;

# File description:
# This module contains all the methods that should be used for any functions
# pertaining to vmnic on the ESXi server

# Used to enforce coding standards
use strict;
use warnings;
use FindBin;
# Inheriting from VDNetLib::NetAdapter::NetAdapter package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::NetAdapter::NetAdapter);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Host::HostOperations;
use VDNetLib::Switch::Switch;
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);

our $binVmnic = "/sbin/esxcfg-nics";
our $binEsxcli = "/sbin/esxcli";
our $binEthtool = "/sbin/ethtool";


################################################################################
#
# new --
#      Creates an object instance of vmnic object.
#
# Input:
#      controlIP   : ip address of the host
#      interface   : Name of vmnic (Mandatory)
#      hostOpsObj  : Host operations object (Mandatory)
#      pgName      : PG Name to which pNIC is attached (Optional)
#      vSwitch     : vSwitch name to which pNIC is attached (Optional)
#
# Results:
#      Reference to newly created Vmnic instance is returned.
#      If the object is not created, then "FAILURE" is returned
#
# Side effects:
#      None
#
################################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;

   $self->{vSwitch}    = $args{vSwitch} || undef;
   $self->{pgName}     = $args{pgName} || undef;
   $self->{interface}  = $args{interface};
   $self->{hostObj}    = $args{hostObj};
   # parentObj is needed for inline python.
   $self->{parentObj}  = $args{hostObj};
   $self->{controlIP}  = $args{controlIP};
   $self->{vmnic}      = $self->{interface}; # vmnic is same as interface
   $self->{hostName}   = $self->{controlIP}; # hostName is same as controlIP
   if ((not defined $self->{vmnic}) ||
       (not defined $self->{hostName}) ||
       (not defined $self->{hostObj})) {
      $vdLogger->Error("vmnic and/or hostObj not passed for creating vmnic object");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # information related to the physical switch
   $self->{switchPort} = undef;
   $self->{switchPortVLAN} = undef;
   $self->{switchAddress} = undef;

   #
   # status of the device, since we create vmnicObj
   # only when device is up and available, so
   # set the status to up.
   #
   $self->{status} = "up";

   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = "vmware.vsphere.esx.vmnic.vmnic_facade." .
                       "VmnicFacade";
   bless ($self,$class);

  if ($self->GetVmnicProperties() eq FAILURE) {
     $vdLogger->Error("failed to get $self->{vmnic} properties");
     VDSetLastError(VDGetLastError());
     return FAILURE;
  }
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
                                              $self->{interface});
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


################################################################################
# GetVmnicProperties --
#      Method to get properties of vmnic
#
# Input:
#      None.
#
# Results:
#      SUCCESS if successful
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetVmnicProperties
{
   my $self = shift;

   # Creating the command
   my $awk = "awk '{print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9}'";
   my $command = "$binEsxcli network nic list | grep $self->{vmnic} | $awk";

   $vdLogger->Debug("Running method: GetVmnicProperties");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @tmp = split /\s+/,$result->{stdout};
   if ((defined $self->{hostObj}->{version}) &&
       ($self->{hostObj}->{version} =~ /^6/)){
      #Remove the admin field for prod2015
      splice @tmp, 3, 1;
   }
   $self->{PCI_ID} = $tmp[1];
   $self->{driver} = $tmp[2];
   $self->{link} = $tmp[3];
   $self->{speed} = $tmp[4];
   $self->{duplex} = $tmp[5];
   $self->{macAddress} = $tmp[6];
   $self->{MTU} = $tmp[7];

   return SUCCESS;
}


################################################################################
# TSOSupported --
#      Method to check if TSO is supported by the vmnic
#
# Input:
#      tsosupport - The expect tso support status(true/false)
#
# Results:
#      SUCCESS is returned if TSO is supported.
#      FAILURE is returned in case of any error
#
# Side effects:
#      None
################################################################################

sub TSOSupported
{
   my $self = shift;
   my $tsosupport = shift;

   if (not defined $tsosupport) {
      $vdLogger->Error("The value of key check_tso_support is undefined, should be true or false");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ($tsosupport !~ /true|false/i) {
         $vdLogger->Error("The value of key check_tso_support is invalid, should be true or false");
         VDSetLastError("EOPFAILED");
         return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e get /net/pNics/$self->{vmnic}/properties";

   $vdLogger->Debug("Running method: TSOSupported");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Match the output string with the pattern VMNET_CAP_TSO
   if ($result->{stdout} =~ m/VMNET_CAP_TSO/) {
      $vdLogger->Debug("TSO is supported by vmnic $self->{vmnic}");
      if ($tsosupport =~ /true/i) {
         return SUCCESS;
      } else {
         $vdLogger->Error("TSO status of $self->{vmnic} is not as expected");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      if ($tsosupport =~ /false/i) {
         return SUCCESS;
      } else {
         $vdLogger->Error("TSO is NOT supported by vmnic $self->{vmnic}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
}


################################################################################
# SetOffload -
#        Enables/disables a offload operation provided as input
#        on the esx vmnic.
#
# Input:
#       param has two part:
#        <offloadFunction>
#        Now support the following offload functions:
#        TSOIPv4, IPCheckSum
#        <action>
#        'true', to enable the specified offload operation
#        'false', to disable the specified offload operation
#
# Results:
#        'SUCCESS', if the action on the specified offload operation
#           is successful on the adapter
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
################################################################################
sub SetOffload
{
   my $self = shift;
   my $param = shift;

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

   # $action 1 for enable; 0 for disable
   if ($action =~ /true/i){
      $action = '1';
   } elsif ($action =~ /false/i){
      $action = '0';
   } else {
       $vdLogger->Error("In the key of configure_offload ," .
          "the parameter 'enable' need to be 'true' or 'false'");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my  %supportedFeatures = (
      'tsoipv4' => 'TSOIPv4',
      'ipchecksum' => 'IPCheckSum',
   );
   if (not exists $supportedFeatures{$offloadFunction}) {
      $vdLogger->Error("Given offload $offloadFunction is not supported");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   my $method = $supportedFeatures{$offloadFunction};
   $vdLogger->Debug("Call $method to set $offloadFunction $action on the $self->{vmnic}.");

   return $self->$method($action);
}


################################################################################
# TSOIPv4 --
#      Method to set Hardware / Software TSO on vmnic
#
# Input:
#      "1" for enable   vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/CAP_TSO 1
#      "0" for disable  vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/CAP_TSO 0
#
# Results:
#      SUCCESS is returned if value is set.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub TSOIPv4
{
   my $self = shift;
   my $action = shift;
   if (not defined $action ||
       ($action != "0" && $action != "1")) {
      $vdLogger->Error("Action to set hw / sw TSO not defined. Should be ".
                       "either 1 or 0");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_TSO $action";

   $vdLogger->Debug("Running method: TSOIPv4");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if TSO has been set correctly
   if ($self->GetTSOType() == $action) {
      $vdLogger->Debug("TSO has been set correctly for vmnic $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("TSO has NOT been set for vmnic $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetTSOType --
#      Method to get TSO type of the vmnic
#
# Input:
#      None.
#
# Results:
#      TSO type is returned.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetTSOType
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_TSO";

   $vdLogger->Debug("Running method: GetTSOType");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# GetDriverName --
#      Method to get driver name of vmnic
#
# Input:
#      None.
#
# Results:
#      Name of driver is returned.
#
# Side effects:
#      None
################################################################################

sub GetDriverName
{
   my $self = shift;
   $vdLogger->Debug("Running method: GetDriverName");
   return $self->{driver};
}


################################################################################
# GetMTU --
#      Method to get MTU size that is set for vmnic
#
# Input:
#      None.
#
# Results:
#      MTU size of driver is returned.
#
# Side effects:
#      None
################################################################################

sub GetMTU
{
   my $self = shift;
   $vdLogger->Debug("Running method: GetMTU");
   return $self->{MTU};
}


################################################################################
# GetPktSchedAlgo --
#      Method to retrieve the packet scheduled algorithm for the given
#      vmnic
#
# Input:
#      "vmnic#" - the name of the vmnic from where the algorithm is to
#                 be retrieve. [Optional - only to be used to internal
#                 method calls]
#
# Results:
#      Algorithm name is returned.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetPktSchedAlgo
{
   my $self = shift;
   my $nic = shift;

   my $vmnic = $nic || $self->{'vmnic'};

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$vmnic/sched/info";

   $vdLogger->Debug("Running method: GetPktSchedAlgo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # Parse output
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if (($result->{stdout}{name} !~ /SFQ/i) &&
      ($result->{stdout}{name} !~ /mclk/i) &&
      ($result->{stdout}{name} !~ /FIFO/i)) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse vsish output of Pkt sched info");
      return FAILURE;
   }
   if ($result->{stdout}{name} =~ /FIFO/i) {
      $result->{stdout}{name} = 0;
   } else {
      $result->{stdout}{name} = 1;
   }

   $vdLogger->Debug("Packet sched algo for $vmnic: ".
                   "$result->{stdout}{name}");
   return $result->{stdout}{name};
}


################################################################################
# SetPktSchedAlgo --
#      Method to set the packet scheduled algorithm for the given vmnic
#
# Input:
#      "1" for SFQ
#      "0" for FIFO
#
# Results:
#      SUCCESS is returned in case the algorithm is set successfuly.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub SetPktSchedAlgo
{
   my $self = shift;
   my $action = shift;

   if (not defined $action ||
      ($action != 1 && $action != 0)) {
      $vdLogger->Error("Action not passed as 0 or 1 for setting packet".
                       " scheduled algorithm");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{'vmnic'}/sched/".
                 "allowResPoolsSched $action";

   $vdLogger->Debug("Running method: SetPktSchedAlgo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if packet sched algo has been set correctly
   if ($self->GetPktSchedAlgo() == $action) {
      $vdLogger->Debug("Packet sched algo set successfully for $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("Packet sched algo NOT set for $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# Offload16Offset --
#      Method to enable / disable CAP_OFFLOAD_16OFFSET on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub Offload16Offset
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Vmnic not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_OFFLOAD_16OFFSET $action";

   $vdLogger->Debug("Running method: Offload16Offset");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_OFFLOAD_16OFFSET has been set correctly
   if ($self->Get16Offset() == $action) {
      $vdLogger->Debug("Offload16Offset set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("Offload16Offset NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# Get16Offset --
#      Method to retrieve CAP_OFFLOAD_16OFFSET value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub Get16Offset
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_OFFLOAD_16OFFSET";

   $vdLogger->Debug("Running method: Get16Offset");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# Offload8Offset --
#      Method to enable / disable CAP_OFFLOAD_8OFFSET on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub Offload8Offset
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Vmnic not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_OFFLOAD_8OFFSET $action";

   $vdLogger->Debug("Running method: Offload8Offset");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_OFFLOAD_8OFFSET has been set correctly
   if ($self->Get8Offset() == $action) {
      $vdLogger->Debug("Offload8Offset set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("Offload8Offset NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# Get8Offset --
#      Method to retrieve CAP_OFFLOAD_8OFFSET value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub Get8Offset
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_OFFLOAD_8OFFSET";

   $vdLogger->Debug("Running method: Get8Offset");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# NetHighDMA --
#      Method to enable / disable CAP_NET_HIGH_DMA on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub NetHighDMA
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Vmnic not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_NET_HIGH_DMA $action";

   $vdLogger->Debug("Running method: NetHighDMA");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_NET_HIGH_DMA has been set correctly
   if ($self->GetNetHighDMA() == $action) {
      $vdLogger->Debug("NetHighDMA set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("NetHighDMA NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetNetHighDMA --
#      Method to retrieve CAP_NET_HIGH_DMA value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetNetHighDMA
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_NET_HIGH_DMA";

   $vdLogger->Debug("Running method: GetNetHighDMA");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# NetSGSpanPages --
#      Method to enable / disable CAP_NET_SG_SPAN_PAGES on vmnic.
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if Enabled / Disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub NetSGSpanPages
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_NET_SG_SPAN_PAGES $action";

   $vdLogger->Debug("Running method: NetSGSpanPages");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if CAP_NET_SG_SPAN_PAGES has been set correctly
   if ($self->GetNetSGSpanPages() == $action) {
      $vdLogger->Debug("CAP_NET_SG_SPAN_PAGES set correctly on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_NET_SG_SPAN_PAGES NOT set on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetNetSGSpanPages --
#      Method to retrieve CAP_NET_SG_SPAN_PAGES value on vmnic.
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetNetSGSpanPages
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_NET_SG_SPAN_PAGES";

   $vdLogger->Debug("Running method: GetSGSpanPages");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# ActivateNETSG --
#      Method to activate Hw / Sw CAP_NET_SG on vmnic.
#
# Input:
#      "1" for Hardware
#      "0" for Software
#
# Results:
#      SUCCESS if enabled.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub ActivateNETSG
{
   my $self = shift;
   my $action = shift;

   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_NET_SG $action";

   $vdLogger->Debug("Running method: ActivateNETSG");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if CAP_NET_SG value has been set correctly
   if ($self->GetNET_SG() == $action) {
      $vdLogger->Debug("CAP_NET_SG set correctly on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_NET_SG NOT set on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetNET_SG --
#      Method to retrieve CAP_NET_SG value on vmnic.
#
# Input:
#      None.
#
# Results:
#      Value if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetNET_SG
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_NET_SG";

   $vdLogger->Debug("Running method: GetNET_SG");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# IPCheckSum --
#      Method to enable / disable CAP_IP_CSUM on vmnic
#
# Input:
#      "1" for enable
#      "0" for disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub IPCheckSum
{
   my $self = shift;
   my $action = shift;

   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_IP_CSUM $action";

   $vdLogger->Debug("Running method: IPCheckSum");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_IP_CSUM has been set correctly
   if ($self->GetIPCheckSum() == $action) {
      $vdLogger->Debug("IPCheckSum set correctly on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("IPCheckSum NOT set on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#
# GetIPCheckSum --
#      Method to retrieve CAP_IP_CSUM value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetIPCheckSum
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_IP_CSUM";

   $vdLogger->Debug("Running method: GetIPCheckSum");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# HwVlanRx --
#      Method to enable / disable CAP_VLAN_RX on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub HwVlanRx
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking if CAP_VLAN_RX is already equal to the required value
   if ($self->GetVlanRx() == $action) {
      $vdLogger->Debug("VlanRX already set to $action on $self->{vmnic}");
      return SUCCESS;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_VLAN_RX $action";

   $vdLogger->Debug("Running method: HwVlanRx");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if CAP_VLAN_RX has been set correctly
   if ($self->GetVlanRx() == $action) {
      $vdLogger->Debug("VlanRX set correctly on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("VlanRX NOT set on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#
# GetVlanRx --
#      Method to retrieve CAP_VLAN_RX value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetVlanRx
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_VLAN_RX";

   $vdLogger->Debug("Running method: GetVlanRx");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# HwVlanTx --
#      Method to enable / disable CAP_VLAN_TX on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub HwVlanTx
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking if VLAN_TX is already set to the required value
   if ($self->GetVlanTx() == $action) {
      $vdLogger->Debug("VlanTX already set to $action on $self->{vmnic}");
      return SUCCESS;
   }

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{'vmnic'}/hwCapabilities/".
                 "CAP_VLAN_TX $action";

   $vdLogger->Debug("Running method: HwVlanTx");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if VLAN_TX has been set correctly
   if ($self->GetVlanTx() == $action) {
      $vdLogger->Debug("VlanTX set correctly on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("VlanTX NOT set on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetVlanTx --
#      Method to retrieve CAP_VLAN_TX value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetVlanTx
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_VLAN_TX";

   $vdLogger->Debug("Running method: GetVlanTx");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# CheckWOLSupport --
#      Method to check if WOL is supported by vmnic
#
# Input:
#      None.
#
# Results:
#      SUCCESS if supported.
#      0 if not supported.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub CheckWOLSupport
{
   my $self = shift;

   # Creating the command
   my $command = "$binEthtool $self->{vmnic}";

   $vdLogger->Debug("Running method: CheckWOLSupport");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking output
   if ($result->{stdout} =~ /Supports Wake-on: g/) {
      $vdLogger->Debug("WOL is supported on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Debug("WOL is not supported on $self->{vmnic}");
      return 0;
   }
}


################################################################################
# WOL --
#      Method to enable / disable WOL on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub WOL
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking if WOL is supported by vmnic
   if ($self->CheckWOLSupport() ne SUCCESS) {
      $vdLogger->Error("Vmnic $self->{vmnic} does not support WOL");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing user input as per command requirements
   if ($action == "1") {
      $action = "g";
   } elsif ($action == "0") {
      $action = "d";
   } else {
      $vdLogger->Error("Action for enabling / disabling not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "$binEthtool -s $self->{vmnic} wol $action";

   $vdLogger->Debug("Running method: WOL");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if WOL has been enabled
   if ($self->GetWOLStatus() eq SUCCESS) {
      if ($action eq "g") {
         $vdLogger->Debug("WOL enabled successfuly");
         return SUCCESS;
      }
   } elsif ($self->GetWOLStatus() == "0") {
      if ($action eq "d") {
         $vdLogger->Debug("WOL disabled successfully");
         return 0;
      }
   }
   $vdLogger->Error("Unable to set WOL on $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetWOLStatus --
#      Method to retrieve WOL status on vmnic
#
# Input:
#      None.
#
# Results:
#      SUCCESS if enabled.
#      0 if disabled.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetWOLStatus
{
   my $self = shift;

   # Creating command
   my $command = "$binEthtool $self->{vmnic}";

   $vdLogger->Debug("Running method: GetWOLStatus");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stdout} =~ /Supports Wake-on.+Wake-on: g/s) {
      $vdLogger->Debug("WOL is enabled on $self->{vmnic}");
      return SUCCESS;
   } elsif ($result->{stdout} =~ /Supports Wake-on.+Wake-on: d/s) {
      $vdLogger->Debug("WOL is disabled on $self->{vmnic}");
      return 0;
   }
   $vdLogger->Error("Unable to retrieve WOL status for $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}

########################################################################
#
# GetNICStats --
#      Method to retrieve particular NIC stats of a vmnic from
#      /net/pNics/<pNIC>/stats
#
# Input:
#      None.
#
# Results:
#      Result hash reference, if successful
#      Sample output hash:
#      device {
#         -- General Statistics:
#         Rx Packets:308907037
#         Tx Packets:1435
#         Rx Bytes:138902985
#         Tx Bytes:160002
#         Rx Errors:0
#         Tx Errors:0
#         Rx Dropped:0
#         Tx Dropped:0
#         Multicast:12856624
#         Collisions:0
#         Rx Length Errors:0
#         Rx Over Errors:0
#         Rx CRC Errors:0
#         Rx Frame Errors:0
#         Rx Fifo Errors:0
#         Rx Missed Errors:15948
#         Tx Aborted Errors:0
#         Tx Carrier Errors:0
#         Tx Fifo Errors:0
#         Tx Heartbeat Errors:0
#         Tx Window Errors:0
#         Module Interface Rx packets:308891153
#         Module Interface Tx packets:1435
#         Module Interface Rx dropped:0
#         Module Interface Tx dropped:0
#         -- Driver Specific Statistics:
#         rx_bytes : 236362104265
#         rx_error_bytes : 0
#         tx_bytes : 160002
#         tx_error_bytes : 0
#         rx_ucast_packets : 286612085
#         rx_mcast_packets : 12856624
#         rx_bcast_packets : 9438328
#         tx_ucast_packets : 19
#         tx_mcast_packets : 433
#         tx_bcast_packets : 983
#         tx_mac_errors : 0
#         tx_carrier_errors : 0
#         rx_crc_errors : 0
#         rx_align_errors : 0
#         tx_single_collisions : 0
#         tx_multi_collisions : 0
#         tx_deferred : 0
#         tx_excess_collisions : 0
#         tx_late_collisions : 0
#         tx_total_collisions : 0
#         rx_fragments : 0
#         rx_jabbers : 0
#         rx_undersize_packets : 0
#         rx_oversize_packets : 0
#         rx_64_byte_packets : 8433542
#         rx_65_to_127_byte_packets : 110241892
#         rx_128_to_255_byte_packets : 800522
#         rx_256_to_511_byte_packets : 2106856
#         rx_512_to_1023_byte_packets : 80607217
#         rx_1024_to_1522_byte_packets : 106717008
#         rx_1523_to_9022_byte_packets : 0
#         tx_64_byte_packets : 909
#         tx_65_to_127_byte_packets : 263
#         tx_128_to_255_byte_packets : 103
#         tx_256_to_511_byte_packets : 160
#         tx_512_to_1023_byte_packets : 0
#         tx_1024_to_1522_byte_packets : 0
#         tx_1523_to_9022_byte_packets : 0
#         rx_xon_frames : 0
#         rx_xoff_frames : 0
#         tx_xon_frames : 0
#         tx_xoff_frames : 0
#         rx_mac_ctrl_frames : 0
#         rx_filtered_packets : 0
#         rx_ftq_discards : 0
#         rx_discards : 0
#         rx_fw_discards : 15948
#
#         FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetNICStats
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -e get /net/pNics/$self->{vmnic}/stats";

   $vdLogger->Debug("Running method: GetNICStats");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output to convert it to a hash
   my @temp = split(/\n/,$result->{stdout});

   my $stats = undef;
   foreach my $line (@temp) {
      if ($line !~ /:/) {
         next;
      }
      my ($key, $value) = split(/:/,$line);
      # remove any spaces before and after stats name and value
      $key =~ s/^\s+|\s+$//g;
      $value =~ s/^\s+|\s+$//g;
      if (defined $key && (($key eq "") || ($key !~ /\w+|\d+/))) {
         # If the value of key is empty or not equal to a word or number,
         # ignore it
         next;
      }
      if (defined $value && (($value eq "") || ($value !~ /\w+|\d+/))) {
         next;
      }
      $stats->{$key} = $value;
   }
   if (defined $stats) {
      $vdLogger->Debug("Stats collected for $self->{vmnic} " .
                       Dumper($stats));
      return $stats;
   } else {
      $vdLogger->Error("Unable to parse vsish output of NIC stats");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# TxQueueInfo --
#      Method to retrieve number of active Tx queues / Default Queue ID
#
# Input:
#      "numQueues" for Number of active Tx Queues
#      "defaultQid" for Default Queue ID
#      "vmnic#" for specifying any particular vmnic [Optional - only for
#                                                    internal method calls]
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub TxQueueInfo
{
   my $self = shift;
   my $action = shift;
   my $nic = shift;
   if (not defined $action) {
      $vdLogger->Error("Parameter to be retrieved not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmnic = $nic || $self->{vmnic};
   # Creating the command
   my $command = "vsish -pe get /net/pNics/$vmnic/txqueues/info";

   $vdLogger->Debug("Running method: TxQueueInfo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of TxQueueInfo");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (defined $result->{stdout}->{$action}) {
      $vdLogger->Debug("$action for $vmnic: ".
                      "$result->{stdout}->{$action}");
      return $result->{stdout}->{$action};
   } else {
      $vdLogger->Error("Unable to retrieve $action for $vmnic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# RxQueueInfo --
#      Method to retrieve number of active Rx filters / supported filters /
#      supported queues
#
# Input:
#      "maxQueues" for # of supported queues
#      "numFilters" for # of supported filters
#      "numActiveFilters" for # of active filters
#      "vmnic#" for vmnic name. If not mentioned, default vmnic name from parent
#               hash will be used. [Optional - ot be used by internal method
#               call only]
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub RxQueueInfo
{
   my $self = shift;
   my $action = shift;
   my $nic = shift;
   if (not defined $action) {
      $vdLogger->Error("Parameter to be retrieved not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmnic = $nic || $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$vmnic/rxqueues/info";

   $vdLogger->Debug("Running method: RxQueueInfo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of RxQueueInfo");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (defined $result->{stdout}->{$action}) {
      $vdLogger->Debug("$action for $vmnic: ".
                      "$result->{stdout}->{$action}");
      return $result->{stdout}->{$action};
   } else {
      $vdLogger->Error("Unable to retrieve $action for $vmnic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# RxFilterInfo --
#      Method to retrieve filter info as per inputs shown below
#
# Input:
#      RxQID: Rx queue ID where filter is present
#      RxFilterID: Rx filter ID
#      vmnic: Vmnic#, in case user wants to retrieve value for another vmnic. If
#             defined, default vmnic name will be used from parent hash.
#             [Optional - to be used only for internal method calls]
#
# Results:
#      Hash of values if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub RxFilterInfo
{
   my $self = shift;
   my $args = shift;
   if (not defined $args->{rxqid} ||
       not defined $args->{rxfilterid}) {
      $vdLogger->Error("RXQID / RXFILTERID not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $rxqid = $args->{rxqid};
   my $rxfilterid = $args->{rxfilterid};
   my $vmnic = $args->{vmnic} || $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$vmnic/rxqueues/queues/".
                 "$rxqid/filters/$rxfilterid/filter";

   $vdLogger->Debug("Running method: RxFilterInfo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of RxFilterInfo");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# GetRxQueues --
#      Method to retrieve list of Rx queues of vmnic in NetQ and return them
#      as an array reference to be worked upon later
#
# Input:
#      vmnic - vmnic name. If not defined, default vmnic name from parent hash
#              will be accepted. [Optional - to be used only for internal
#              method calls]
#
# Results:
#      Value (as a reference to an array) if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRxQueues
{
   my $self = shift;
   my $nic = shift;

   my $vmnic = $nic || $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe ls /net/pNics/$vmnic/rxqueues/queues/";

   $vdLogger->Debug("Running method: GetRxQueues");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output
   if (defined $result->{stdout}) {
      my @tmp = split(/\n/,$result->{stdout});
      $vdLogger->Debug("Rx queues for vmnic $vmnic: @tmp");
      return \@tmp;
   }

   $vdLogger->Error("Unable to retrieve Rx queues for $vmnic");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetTxNumOfQueues --
#      Method to find the # of Tx queues actually being used in vmnic in NetQ
#
# Input:
#      "vmnic#" - vmnic name for which value is to be retrieved. [Optional -
#                 only for internal method calls]
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################


sub GetTxNumOfQueues
{
   my $self = shift;
   my $nic = shift;

   my $vmnic = $nic || $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe ls /net/pNics/$vmnic/txqueues/queues/";

   $vdLogger->Debug("Running method: GetTxNumOfQueues");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output
   if (defined $result->{stdout}) {
      my @tmp = split(/\n/,$result->{stdout});
      my $num = scalar @tmp;
      $vdLogger->Debug("Number of Tx queues for vmnic $vmnic: $num");
      return $num;
   }

   $vdLogger->Error("Unable to retrieve number of Tx queues for ".
                    "$vmnic");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetTxQueueId --
#      Method to calculate the Tx queue ID from the Port ID and the # of active
#      Tx queues of vmnic in NetQ based on the formula:
#      ((((PortId) >> 1) ^ (((PortId) & 1)
#      << (hashXorBitShift))) % (NumActQ))
#
# Input:
#      PortId   : Port ID of which Tx queue ID is to be calculated (Mandatory)
#      NumActQ  : Number of active queues (Mandatory)
#
# Results:
#      Value if successful.
#      Undef is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetTxQueueId
{
   my $self = shift;
   my $args = shift;

   my $portid = $args->{portid};
   my $numactq = $args->{numactq};

   $vdLogger->Debug("Running method: GetTxQueueId");

   if (not defined $portid ||
       not defined $numactq) {
      $vdLogger->Error("PortId / NumActQ not passed for ".
                       "GetTxQueueId of vmnic");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $hashxorbitshift = undef;
   #
   # Checking validity of number of Tx queues passed and setting
   # hashXorBitShift value
   #
   if (($numactq > 3) && ($numactq < 8)) {
      $hashxorbitshift = 1;
   } elsif (($numactq > 7) && ($numactq < 16)) {
      $hashxorbitshift = 2;
   } elsif (($numactq > 15) || ($numactq < 2)) {
      $vdLogger->Error("Invalid value for NumActQ passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # Function to calculate Tx Queue ID
   #
   my $result = ((($portid >> 1) ^ (($portid & 1)
                << $hashxorbitshift)) % $numactq);

   if (defined $result) {
      $vdLogger->Debug("$self->{vmnic} Tx Queue ID: $result");
      return $result;
   }
   $vdLogger->Error("Unable to calculate Tx Queue ID for $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetRxQueueFilters --
#      Method to find list of Rx queue filters of vmnic in NetQ
#
# Input:
#      QueueId  : Rx queue Id (Mandatory)
#      vmnic    : vmnic#, in case user wants to retrieve for another vmnic. If
#                 not defined, default vmnic name will be used from the parent
#                 hash. [Optional - to be used only for internal method calls]
#
# Results:
#      Value (as an array) if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRxQueueFilters
{
   my $self = shift;
   my $queueid = shift;
   my $nic = shift;

   if (not defined $queueid) {
      $vdLogger->Error("QueueId not passed for ".
                       "GetRxQueueFilters of vmnic $self->{vmnic}");
      VDSetLastError("ENOTDEF");
      return undef;
   }
   my $vmnic = $nic || $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe ls /net/pNics/$vmnic/rxqueues/queues/".
                 "$queueid/filters";

   $vdLogger->Debug("Running method: GetRxQueueFilters");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output
   if (defined $result->{stdout}) {
      my @tmp = split(/\n/,$result->{stdout});
      $vdLogger->Debug("Rx queue filters for vmnic $vmnic: @tmp");
      return \@tmp;
   }

   $vdLogger->Error("Unable to retrieve Rx queue filters for queue $queueid in".
                    " $vmnic");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetQueuePktCount --
#      Method to find the packet count per Tx / Rx queue in NetQ
#
# Input:
#      Type     : Tx / Rx (Mandatory)
#      TxRxQueueId  : queue Id (Mandatory)
#      Vmnic    : Vmnic ID [Optional - only for internal method calls]
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetQueuePktCount
{
   my $self = shift;
   my $args = shift;

   my $queueid = $args->{txrxqueueid};
   my $type = $args->{transtype};
   my $vmnic = $args->{vmnic} || $self->{vmnic};

   if (not defined $queueid ||
       not defined $type) {
      $vdLogger->Error("QueueId / type not passed for ".
                       "GetQueuePktCount of vmnic $vmnic");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = undef;
   # Creating the command
   if ($self->{driver} =~ /ixgbe/i) {
      if ($type =~ /Rx/i) {
         $command = "$binEthtool -S $vmnic | grep rx_queue_$queueid".
                    "_packets | awk '^{print \$2}'";
      } elsif ($type =~ /Tx/i) {
         $command = "$binEthtool -S $vmnic | grep tx_queue_$queueid".
                    "_packets | awk '^{print \$2}'";
      } else {
         $vdLogger->Error("Type Tx / Rx not correctly specified");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Driver $self->{driver} is not supported for retrieval".
                       " of value from ethtool for vmnic $vmnic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("Running method: GetQueuePktCount");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output
   if (defined $result->{stdout}) {
      $vdLogger->Debug("$type queue packet count for Queue $queueid vmnic ".
                      "$vmnic: $result->{stdout}");
      return $result->{stdout};
   }

   $vdLogger->Error("Unable to retrieve $type queue packet count for queue ".
                    "$queueid in $vmnic");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# SetNicSpeedDup --
#      Method to set speed of NIC and appropriate duplex mode
#
# Input:
#      Speed    : Speed to be set (Optional)
#      DupMode  : Duplex mode to be set (Optional)
#      Auto     : Speed and Duplex mode in Auto negotiation (Optional)
#
# Results:
#      SUCCESS if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub SetNicSpeedDup
{
   my $self = shift;
   my $args = shift;

   my $speed  = $args->{speed} || undef;
   my $duplex = $args->{duplex} || undef;
   my $auto   = $args->{autoconfigure} || undef;

   my $command = undef;

   # Creating command
   if (defined $speed xor
       defined $duplex) {
      $vdLogger->Error("Speed and Duplex if defined, should be passed".
                       " together");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif (defined $speed and defined $duplex) {
      $command = "$binEsxcli network nic set -S $speed -D $duplex".
                 " -n $self->{vmnic}";
   }
   if (defined $auto && $auto =~ /true/i) {
      $command = "$binEsxcli network nic set -a -n $self->{vmnic}";
   }

   $vdLogger->Debug("Running method: SetNicSpeedDup");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("$command failed with:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parsing the output
   if (defined $result->{stderr}) {
      if ($result->{stderr} =~ m/Error/i ||
          $result->{stderr} =~ m/Invalid/i ||
          $result->{stderr} =~ m/Missing/i) {
         $vdLogger->Error("Unable to set SpeedDup:" . Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Checking if vmnic has been set
      $vdLogger->Debug("Checking if $self->{vmnic} has been set");
      for (my $i = 0; $i < 10; $i++) {
         if ($self->GetVmnicProperties() ne FAILURE &&
             $self->{link} =~ /Up/i) {
            if (defined $auto) {
               $vdLogger->Debug("Auto negotiation for $self->{vmnic} ".
                               "successful");
               return SUCCESS;
            }
            $self->{speed} =~ /(\d+).*/;
            if ($speed =~ /$1/i &&
                $duplex =~ /$self->{duplex}/i) {
               $vdLogger->Debug("Speed set to $speed, duplex mode set to ".
                               "$duplex for $self->{vmnic} ");
               return SUCCESS;
            }
         }
         sleep(1);
      }
   }
   $vdLogger->Error("Unable to set speed and duplex for $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetRxPoolInfo --
#      Method to retrieve the Rx Pool info as per user input in NetQ
#
# Input:
#      PoolId    : Pool Id from which information is to be retrieved (Mandatory)
#      PoolParam : Argument to be checked, accepts any ONE of values:
#                  "attr", "features", "nQueues", "maxQueues", "ratio",
#                  "active"
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRxPoolInfo
{
   my $self = shift;
   my $args = shift;

   my $poolid = $args->{poolid};
   my $poolparam = $args->{poolparam};

   if (not defined $poolid ||
       not defined $poolparam) {
      $vdLogger->Error("PoolId / PoolParam not passed for ".
                       "GetRxPoolInfo of vmnic");
      VDSetLastError("ENOTDEF");
      return undef;
   }

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/rxqueues/pools/".
                 "$poolid/info";

   $vdLogger->Debug("Running method: GetRxPoolInfo");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parse output
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse vsish output of Rx Pool info");
      return FAILURE;
   }

   if (defined $result->{stdout}->{$poolparam}) {
      $vdLogger->Debug("Rx queue pool $poolid info for vmnic $self->{vmnic}:".
                      " $result->{stdout}->{$poolparam}");
      return $result->{stdout}->{$poolparam};
   }
   $vdLogger->Error("Unable to retrieve Rx queue pool info for pool $poolid in".
                    " $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetRxPoolQueues --
#      Method to retrieve the Rx queues per pool in NetQ
#
# Input:
#      None.
#
# Results:
#      Value (as an array) if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRxPoolQueues
{
   my $self = shift;
   my $poolid = shift;

   if (not defined $poolid) {
      $vdLogger->Error("PoolId not passed for GetRxPoolQueues of vmnic");
      VDSetLastError("ENOTDEF");
      return undef;
   }

   # Creating the command
   my $command = "vsish -pe ls /net/pNics/$self->{vmnic}/rxqueues/pools/".
                 "$poolid/queues";

   $vdLogger->Debug("Running method: GetRxPoolQueues");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking the output
   if (defined $result->{stdout}) {
      my @tmp = split (/\n/,$result->{stdout});
      $vdLogger->Debug("Queues per pool ID $poolid of $self->{vmnic}: @tmp");
      return \@tmp;
   }
   $vdLogger->Error("Unable to retrieve Rx queue pool queues for pool ".
                    "$poolid in $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetRxPools --
#      Method to retrieve the pools per vmnic in NetQ
#
# Input:
#      None.
#
# Results:
#      Value (as an array) if successful.
#      Undef is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRxPools
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe ls /net/pNics/$self->{vmnic}/rxqueues/pools/";

   $vdLogger->Debug("Running method: GetRxPools");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking the output
   if (defined $result->{stdout}) {
      my @tmp = split (/\n/,$result->{stdout});
      $vdLogger->Debug("Pools in $self->{vmnic}: @tmp");
      return \@tmp;
   }
   $vdLogger->Error("Unable to retrieve Rx pools in $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetTxQueueStats --
#      Method to retrieve the Tx queue stats per vmnic in NetQ
#
# Input:
#      QueueId  : Queue ID from where information is to be retrieved (Mandatory)
#      TxQParam : Only one of the values can be passed at a time:
#                 "pktsTransmitted,txErrors,txBusy,queueStops,queuesStarts"
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetTxQueueStats
{
   my $self = shift;
   my $args = shift;

   my $queueid = $args->{txqueueid};
   my $txqparam = $args->{txqparam};

   if (not defined $queueid ||
       not defined $txqparam) {
      $vdLogger->Error("QueueID / TxQParam not passed for ".
                       "GetTxQueueStats of vmnic");
      VDSetLastError("ENOTDEF");
      return undef;
   }

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/txqueues/queues/".
                 "$queueid/stats";

   $vdLogger->Debug("Running method: GetTxQueueStats");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Parse output
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse vsish output of Rx queuesStats");
      return FAILURE;
   }

   if (defined $result->{stdout}->{$txqparam}) {
      $vdLogger->Debug("Tx queue stat $txqparam queue $queueid for vmnic ".
                      "$self->{vmnic}: $result->{stdout}->{$txqparam}");
      return $result->{stdout}->{$txqparam};
   }
   $vdLogger->Error("Unable to retrieve Tx queue stats for param $txqparam".
                    " queue $queueid in $self->{vmnic}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


################################################################################
# GetPhysicalSwitchInfo --
#      Method to retrieve the physical switch information to which this pnic
#      is connected, It currently uses CDP(Cisco Discovery protocol).
#
# Input:
#   None
#
# Results:
#      SUCCESS if physical switch information is received.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      none
#
################################################################################

sub GetPhysicalSwitchInfo
{
   my $self = shift;
   my $vmnic = $self->{vmnic};
   my $result;
   my $reg;
   my $cdpInfo;
   my $command;

   # command to retrive the port id of the switch.
   $command = "vim-cmd hostsvc/net/query_networkhint --pnic-names=$vmnic";
   # Submit STAF command
   $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess($self->{hostName},
                                                             $command);

   $vdLogger->Debug("Discovery info result for $vmnic : ");
   $vdLogger->Debug(Dumper($result));

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      $cdpInfo = $result->{stdout};
   } else {
      return FAILURE;
   }

   #
   # the output for switchport info is
   #
   # connectedSwitchPort = (vim.host.PhysicalNic.CdpInfo) {
   #      dynamicType = <unset>,
   #      cdpVersion = 2,
   #      timeout = 0,
   #      ttl = 129,
   #      samples = 75216,
   #      devId = "vmk-colo-057",
   #      address = "10.112.24.57",
   #      portId = "GigabitEthernet0/15",
   #      deviceCapability = (vim.host.PhysicalNic.CdpDeviceCapability) {
   #         dynamicType = <unset>,
   #         router = false,
   #         transparentBridge = false,
   #         sourceRouteBridge = false,
   #         networkSwitch = true,
   #         host = false,
   #         igmpEnabled = true,
   #         repeater = false,
   #      },
   #      softwareVersion = "Cisco IOS Software, C2960 Softw",
   #      hardwarePlatform = "cisco WS-C2960G-24TC-L",
   #      ipPrefix = "0.0.0.0",
   #      ipPrefixLen = 0,
   #      vlan = 243,
   #      fullDuplex = true,
   #      mtu = 0,
   #      systemName = "",
   #      systemOID = "",
   #      mgmtAddr = "10.112.24.57",
   #      location = "",
   #   },
   #

   # first get the switchport.
   $reg = 'portId\s*=\s*.*Ethernet([^"]+)';

   #
   # we are just intrested in the port id not the
   # interface type.
   #
   if ($cdpInfo =~ /$reg/i) {
      $self->{switchPort} = $1;
      $self->{switchPort} =~ s/\"//g;
      $vdLogger->Info("Port id of $self->{vmnic} on phy switch is " .
                      $self->{switchPort});
   } else {
      $vdLogger->Debug("Failed to get switch port for $vmnic using CDP");
      VDSetLastError("ENOTDEF");

      #
      # Try if lldp data is available before claiming
      # that discovery info is not available.
      #
      $reg = 'portId\s*=s*.*i([^"]+)';
      if ($cdpInfo =~ /$reg/i) {
         $self->{switchPort} = $1;
         $self->{switchPort} =~ s/\"//g;
      } else {
         $vdLogger->Debug("No Discovery Info available for pNIC $self->{vmnic}");
         return FAILURE;
      }
   }

   if (not defined $self->{switchPort}) {
      $vdLogger->Warn("Port if of $self->{vmnic} missing, " .
                      "will affect cases using that information");
   }

   #
   # Check for the switch Address.
   #
   $reg = 'devId\s*=\s*"([^"]+)"';
   if ($cdpInfo =~ /$reg/i) {
      my $switchName = $1;
      #
      # ignore anything within braces, for example
      # prme-vmkqa-5596b.eng.vmware.com(FOX1524GAHB)
      #
      $switchName =~ s/\(.*\)$//;
      my $mgmtip = VDNetLib::Common::Utilities::GetIPfromHostname($switchName);
      if ($mgmtip eq FAILURE) {
         $vdLogger->Error("Failed to get physical switch mgmt IP address");
         return FAILURE;
      }
      $self->{switchAddress} = $mgmtip;
   } else {
      $vdLogger->Debug("Failed to get physical switch address for $vmnic");
      return FAILURE;
   }

   #
   # check for the vlan to which this pnic belongs at the switchport side.
   #
   $reg = 'vlan\s*=\s*([0-9]+)';
   if ($cdpInfo =~ /$reg/i) {
      $self->{switchPortVLAN} = $1;
   } else {
      $vdLogger->Debug("Failed to get vlan to which switch port for ".
                      "$vmnic belongs");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetDeviceStatus --
#      Method to set the pnic device status to the specified one(up/down).
#
# Input:
#      Status : Status of the device to be set.(up/down)
#
# Results:
#      SUCCESS if device status gets set correctly.
#      FAILURE if setting device status fails.
#
# Side effects:
#      status of the pNIC device is set to either up or down.
#
################################################################################

sub SetDeviceStatus
{
   my $self = shift;
   my $status = shift;
   my $execution_type = shift;
   my $specHash;

   if (not defined $status) {
      $vdLogger->Error("device status to be set not specified");
      return FAILURE;
   }
   $specHash->{"status"} = $status;
   $specHash->{"execution_type"} = $execution_type;

   #
   #  xxx (hchilkot):
   #  calling pylib method to set device status.
   #  We don't need this method, but without this wrapper
   #  method setting device status for vnic fails, since
   #  we don't have vnic status setting in pylib and they
   #  are dependent on RemoteAgent
   #
   return $self->set_device_status($specHash);
}


################################################################################
# SetDeviceDown --
#      Method to set the pnic device status to down.
#
# Input:
#      None.
#
# Results:
#      SUCCESS if device status gets set correctly.
#      FAILURE if setting device status fails.
#
# Side effects:
#      status of the pNIC device is set to down.
#
################################################################################

sub SetDeviceDown
{
   my $self = shift;
   my $result;

   $result = $self->SetDeviceStatus("down");
   if ($result eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # set the status of device.
   $self->{status} = "down";
   return SUCCESS;
}


################################################################################
# SetDeviceUp --
#      Method to set the pnic device status to up
#
# Input:
#      None.
#
# Results:
#      SUCCESS if device status gets set correctly.
#      FAILURE if setting device status fails.
#
# Side effects:
#      status of the pNIC device is set to up.
#
################################################################################

sub SetDeviceUp
{
   my $self = shift;
   my $result;

   $result = $self->SetDeviceStatus("up");
   if ($result eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{status} = "up";
   return SUCCESS;
}


################################################################################
#
# CheckNetworkHint --
#      Method to check if the network hint on given vmnic
#      contains the given vlan values.
#
# Input:
#      Either a single vlan id or a colon (:) separated list of vlan
#      id's to verify (to verify multiple vlan id's in single shot)
#
# Results:
#      SUCCESS, if the network hint contains the given vlan id's.
#      FAILURE, in case of any failure.
#
# Side effects:
#      None
#
################################################################################

sub CheckNetworkHint()
{
   my $self	= shift;
   my $vlanids	= shift || undef;
   my @myvlanids;
   my $mynetworkhint;

   if (not defined $vlanids or $vlanids eq "") {
      $vdLogger->Error("list of vlan id's to check is not provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e get /net/pNics/$self->{vmnic}/properties";

   $vdLogger->Debug("Running method: Network Hint");
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*Network Hint\:(.*)\n.*/) {
      $mynetworkhint = $1;
   } else {
      $vdLogger->Error("Unable to get network hint on $self->{vmnic}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   @myvlanids = split(/:/, $vlanids);
   foreach my $myvlan (@myvlanids) {
      next if ($mynetworkhint =~ /$myvlan/);
      $vdLogger->Error("Current Network hint does not include the".
		       " given vlan id: $myvlan");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# IPV6TSO6ExtHdrs --
#      Method to enable / disable CAP_TSO6_EXT_HDRS on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub IPV6TSO6ExtHdrs
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("action not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->GetIPV6TSO6ExtHdrs() == $action) {
      $vdLogger->Debug("CAP_TSO6_EXT_HDRS was set already on $self->{vmnic}");
      return SUCCESS;
   }
   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_TSO6_EXT_HDRS $action";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                             ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_TSO6_EXT_HDRS has been set correctly
   if ($self->GetIPV6TSO6ExtHdrs() == $action) {
      $vdLogger->Debug("CAP_TSO6_EXT_HDRS set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_TSO6_EXT_HDRS NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#
# GetIPV6TSO6ExtHdrs --
#      Method to retrieve CAP_TSO6_EXT_HDRS value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetIPV6TSO6ExtHdrs
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_TSO6_EXT_HDRS";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
# TSOIPv6 --
#      Method to enable / disable CAP_TSO6 on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub TSOIPv6
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("action not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->GetTSOIPV6() == $action) {
      $vdLogger->Debug("CAP_TSO6 was set already on $self->{vmnic}");
      return SUCCESS;
   }
   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_TSO6 $action";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                             ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_TSO6 has been set correctly
   if ($self->GetTSOIPV6() == $action) {
      $vdLogger->Debug("CAP_TSO6 set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_TSO6 NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
# GetTSOIPV6 --
#      Method to retrieve CAP_TSO6 value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetTSOIPV6
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_TSO6";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# IPV6CSumExtHdrs --
#      Method to enable / disable CAP_IP6_CSUM_EXT_HDRS on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub IPV6CSumExtHdrs
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("action not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->GetIPV6CSumExtHdrs() == $action) {
      $vdLogger->Debug("CAP_IP6_CSUM_EXT_HDRS was".
                       " set already on $self->{vmnic}");
      return SUCCESS;
   }
   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_IP6_CSUM_EXT_HDRS $action";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                             ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if CAP_IP6_CSUM_EXT_HDRS has been set correctly
   if ($self->GetIPV6CSumExtHdrs() == $action) {
      $vdLogger->Debug("CAP_IP6_CSUM_EXT_HDRS set".
                       " successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_IP6_CSUM_EXT_HDRS NOT set".
                        " successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#
# GetIPV6CSumExtHdrs --
#      Method to retrieve CAP_IP6_CSUM_EXT_HDRS value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetIPV6CSumExtHdrs
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_IP6_CSUM_EXT_HDRS";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# IPV6CSum --
#      Method to enable / disable CAP_IP6_CSUM on vmnic
#
# Input:
#      "1" if enable
#      "0" if disable
#
# Results:
#      SUCCESS if enabled / disabled
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub IPV6CSum
{
   my $self = shift;
   my $action = shift;
   if (not defined $action) {
      $vdLogger->Error("action not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->GetIPV6CSum() == $action) {
      $vdLogger->Debug("CAP_IP6_CSUM was set already on $self->{vmnic}");
      return SUCCESS;
   }
   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_IP6_CSUM $action";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                             ($self->{hostName}, $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # Check if CAP_IP6_CSUM has been set correctly
   if ($self->GetIPV6CSum() == $action) {
      $vdLogger->Debug("CAP_IP6_CSUM set successfully on $self->{vmnic}");
      return SUCCESS;
   } else {
      $vdLogger->Error("CAP_IP6_CSUM NOT set successfully on $self->{vmnic}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#
# GetIPV6CSum --
#      Method to retrieve CAP_IP6_CSUM value on vmnic
#
# Input:
#      None.
#
# Results:
#      Value if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetIPV6CSum
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/hwCapabilities/".
                 "CAP_IP6_CSUM";
   $vdLogger->Debug("Running command: $command");
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $result->{stdout};
}


################################################################################
#
# SetMTU --
#      Method to set the MTU in a vmnic through vsish
#
# Input:
#      Size - MTU Size to be set
#
# Results:
#      SUCCESS, if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub SetMTU
{
   my $self = shift;
   my $size = shift;

   # Creating the command
   my $command = "vsish -e set /net/pNics/$self->{vmnic}/mtu $size";
   $vdLogger->Debug("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking whether the value has been set
   $command = "vsish -pe get /net/pNics/$self->{vmnic}/mtu";

   # Submit STAF command
   $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Converting array to a hash
   $result = VDNetLib::Common::Utilities::ProcessVSISHOutput
                          (RESULT => $result->{stdout});
   if ($result eq FAILURE) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($size =~ $result->{mtu}) {
      return SUCCESS;
   } else {
      return FAILURE;
   }

   return $result->{stdout};
}

########################################################################
#
# GetPCIInfo--
#     Method to get PCI information about the adapter instance/object
#
# Input:
#     bdfInHex : bdf number for the PCI device
#
# Results:
#     Reference to array of hash which has the following keys:
#     'bdf'    : BDF (Bus, Device, Function) number
#     'class'  : class of the PCI device
#     'name'   : interface name of PCI device on the host
#     'vendorDevId': vendor and device ID
#     return FAILURE in case of error
#
# Side effects:
#
########################################################################

sub GetPCIInfo
{
   my $self = shift;
   my $bdfInHex = shift;
   my $command;
   my $result = undef;

   my $pciList = $self->{hostObj}->GetPCIDevices();
   if ($pciList eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (defined $bdfInHex) {
      $vdLogger->Debug("Try to find PCI information for bdf $bdfInHex");
      foreach my $device (@{$pciList}){
         if ((defined $device->{bdf}) && ($device->{bdf} =~ /$bdfInHex$/)) {
            $result = $device;
            $vdLogger->Debug("Find the PCI information for $bdfInHex".Dumper($result));
            last;
         }
      }
   } else {
      foreach my $device (@{$pciList}) {
         if ((defined $device->{name}) && ($device->{name} eq $self->{interface})) {
            $result = $device;
            $vdLogger->Debug("Find the PCI information for $self->{interface}".Dumper($result));
            last;
         }
      }
   }
   if ($result) {
      return $result;
   } else {
      $vdLogger->Error("Failed to find PCI information");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}

################################################################################
# GetRSSInfo --
#      Method to retrieve specific RSS queue information based on the parameter
#      passed.
#
# Input:
#      Param  - The node from which information is to be obtained [MANDATORY]
#      Queue# - The queue number on which RSS is supported [MANDATORY]
#
# Results:
#      Value (as a string) if successful.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
################################################################################

sub GetRSSInfo
{
   my $self = shift;
   my $param = shift;
   my $queue = shift;

   my $vmnic = $self->{vmnic};

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$vmnic/rxqueues/queues/$queue/rss/".
                 "$param";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);

   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("Command \"$command\" to retrieve Rx queues for $vmnic".
                       " failed");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      return $result->{stdout};
   }

   $vdLogger->Error("Unable to retrieve Rx queues for $vmnic");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# VerifyOffload -
#        Verifies if the current value for the offload operation is set
#        to the expected Enable/disable value provided as input
#
# Input:
#        A hash function containing the keys:
#        feature_type: What to verify
#        value  : The value that is to be expected
#
#        Any one of the following offload functions:
#        NICStatus, (more functions to be filled here)
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
   my $self             = shift;  # Required
   my $confighash       = shift;  # Required

   %$confighash = (map { lc $_ => lc $confighash->{$_}} keys %$confighash);

   my $offloadFunction  = $confighash->{'feature_type'};  # Required
   my $expValue         = $confighash->{'value'};    # Required
   my $curValue         = undef;

   my %supportedFeatures = (
      'nicstatus' => 'NICStatus',
   );

   $offloadFunction = $supportedFeatures{$offloadFunction};

   if ((not defined $self->{'interface'}) ||
       (not defined $offloadFunction) ||
       (not defined $expValue)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($offloadFunction =~ /nicstatus/i) {
      $curValue = $self->GetNICStatus();
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


################################################################################
#
# GetNICStatus --
#      Method to get link status of a vmnic
#
# Input:
#      None.
#
# Results:
#      "Enabled" or "Disabled" is returned.
#      FAILURE is returned in case of any error.
#
# Side effects:
#      None
#
################################################################################

sub GetNICStatus
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/pNics/$self->{vmnic}/linkStatus";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                ($self->{hostName}, $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("Unable to retrieve link status of NIC");
      return FAILURE;
   }

   # Parse output
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse vsish output of NIC status");
      return FAILURE;
   }

   if ($result->{stdout}->{status} =~ /1/i) {
      $result->{stdout}->{status} = "Enable";
      return $result->{stdout}->{status};
   } elsif ($result->{stdout}->{status} == 0) {
      $result->{stdout}->{status} = "Disable";
      return $result->{stdout}->{status};
   }
   $vdLogger->Error("Unable to retrieve NIC status for vmnic $self->{'vmnic'}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# VerifyEntitlement --
#     Method to verify entitlement for the given port.
#     ports can be vnic port id or infrastructure nodes like ft/nfs/
#     iscsi
#
# Input:
#     ports     : reference to array of ports placed on this vmnic
#                 adapter
#     iterations: number of iterations to verify entitlement
#     interval  : sleep time between each interval
#
# Results:
#
# Side effects:
#
########################################################################

sub VerifyEntitlement
{
   my $self       = shift;
   my $ports      = shift;
   my $iterations = shift;
   my $interval   = shift;

   my $args = $self->{'interface'};
   my $status = ExecuteRemoteMethod($self->{'controlIP'},
                                    "GetPortEntitlementStatus",
                                    $args);
   if ($status eq FAILURE) {
      $vdLogger->Error("Failed to get entitlement information");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $port (keys %$status) {
      shift(@{$status->{$port}{'status'}}); # ignore the first iteration
                                            # since it does not have previos
                                            # data to compare against
   }
   my $result = "SUCCESS";
   foreach my $port (@$ports) {
      if (ref($port)) {
         $port = $port->GetPortID();
         $vdLogger->Info("port id is $port");
      }
      if (grep(/NOT OK/, @{$status->{$port}{'status'}})) {
         $vdLogger->Error("Entitlement not met for $port");
         $result = FAILURE;
      }
   }
   return $result;
}


########################################################################
#
# GetUplinkTunnelIP --
#  Method to get uplink ip address
#
# Input:
#     None
#
# Results:
#     ipv4 address configured on the uplink;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetUplinkTunnelIP
{
   my $self  = shift;
   my $uplinks = $self->GetUplinkInfo();

   my $uplinkInfo;
   foreach my $item (@$uplinks) {
      if ($item->{name} eq $self->{interface}) {
         $uplinkInfo = $item;
         last;
      }
   }

   #
   # code to get ip address or any information about vmknic is
   # implemented in VDNetLib::NetAdapter::NetAdapter
   #
   my $vmknicObj = VDNetLib::NetAdapter::NetAdapter->new(
                                 controlIP   => $self->{hostObj}{hostIP},
                                 pgName      => "nvp",
                                 hostObj     =>  $self->{hostObj},
                                 deviceId    => $uplinkInfo->{'vmk intf'},
                                 intType     => "vmknic");
   if ($vmknicObj eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $ip = $vmknicObj->GetIPv4();
   if ($ip eq FAILURE) {
      $vdLogger->Error("Failed to get ip address of vmknic " .
                       "associated with $self->{interface}");
      $vdLogger->Debug(Dumper($uplinkInfo));
      return FAILURE;
   }
   return $ip;
}


########################################################################
#
# GetUplinkInfo --
#     Method to get information about all uplinks configured on the
#     give switch
#
# Input:
#     None
#
# Results:
#     Reference to array of hash which each hash contains attributes
#     of an uplink;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetUplinkInfo
{
   my $self = shift;
   my $hostIP = $self->{hostObj}{hostIP};
   my $command = "nsxcli uplink/show";
   my $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                     $command);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get NVS uplink info on $hostIP");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $data = $result->{stdout};
   my @uplinkArray = split("[=]{2,30}\n", $data);
   my @ovsUplinks;
   foreach my $uplink (@uplinkArray) {
      my $uplinkInfo;
      my @temp = split("\n", $uplink);
      $uplinkInfo->{name} = $temp[0];
      $uplinkInfo->{name} =~ s/:$// if defined ($uplinkInfo->{name});
      for (my $line = 1; $line < scalar(@temp); $line++) {
         if (($temp[$line] =~ /[-]{1,10}/) ||
            ($temp[$line] =~ /^\.\.\./)) {
            next;
         }
         my ($key, $value) = split(":", $temp[$line]);
         $key =~ s/\s+$//;
         $value =~ s/^\s+// if (defined $value);
         $key = lc($key);
         $uplinkInfo->{$key} = $value;
      }
      if ((defined $uplinkInfo->{'connection'}) &&
         ($uplinkInfo->{'connection'} =~ /nvs/i)) {
         push(@ovsUplinks, $uplinkInfo);
      }
   }
   return \@ovsUplinks;
}


########################################################################
#
# GetVmnicHardwareCapability --
#     Method to get vmnic hardware capability value, like CAP_ENCAP
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       value => undef
#                     }
#                  ],
#     capabilityType:  vmnic hardware capability type, like CAP_ENCAP
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVmnicHardwareCapability
{
   my $self           = shift;
   my $serverForm     = shift;
   my $capType        = shift;
   my @serverData;

   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $vmnic   = $self->{vmnic};
   my $command = "vsish -pe get /net/pNics/$vmnic/hwCapabilities/" . uc($capType);
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostObj}->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $resultHash->{reason} = "Failed to execute command $command on " .
                              $self->{hostObj}->{hostIP};
      return $resultHash;
   }
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   push @serverData, {'value'  => chomp($result->{stdout})};
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;
   return $resultHash;
}

########################################################################
#
# Getuplink --
#     Method to get uplink name of the host vmnic,
#
# Input:
#     <none>
#
# Results:
#     uplink name of the host pnic, say, uplink2
#
# Side effects:
#     None
#
########################################################################

sub Getuplink
{
   my $self = shift;

   my $nic = $self->{'vmnic'};
   my $hostObj = $self->{hostObj};

   my $dvslist = $hostObj->GetDVSListInfo();
   my @lineArray = split('\n', $dvslist);
   my $found = 0;
   my $switchName = undef;

   foreach my $line (@lineArray) {
      if ( $line =~ m/^\s+Name: (.+)$/i ) {
         $switchName = $1;
      } elsif ( $line =~ m/^\s+Client: $nic$/i ) {
         $found = 1;
         last;
      }
   }

   if ((not $found) || (not defined $switchName)) {
      $vdLogger->Error("Cannot find switch for vmnic : $nic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("Running GetDVUplinkNameOfVMNic for $switchName and $nic");
   my $dvUplink =  $hostObj->GetDVUplinkNameOfVMNic($switchName,
                                                    $nic);
   if ($dvUplink eq FAILURE) {
      $vdLogger->Error("Failed to get uplink name for $nic on $switchName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $dvUplink;
}

1;
