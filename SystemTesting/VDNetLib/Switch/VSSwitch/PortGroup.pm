########################################################################
#  Copyright (C) 2010 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::VSSwitch::PortGroup;

#
# This package, PortGroupConfig, allows to retrieve all port group
# related attributes and execute operations on portgroups in a ESX machine.
#
# NOTE
# This package is currently as it is copied from VDNetLib::PortgroupConfig.
# All new additions to the portgroup should go here moving forward, the
# older package will continue to work as it in the interim.
#
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use base 'VDNetLib::Root::Root';
use Getopt::Long;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::InlineJava::Portgroup::Portgroup;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              ConvertToPythonBool
                                              CallMethodWithKWArgs) ;
use constant TRUE => 1;
use constant FALSE => 0;
my $debug = 0;
our $ESXCLI = "esxcli network vswitch standard portgroup";

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::PortGroupConfig.
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'pgName': name of the portgroup (Required)
#      'hostIP': IP address of the host on which the given portgroup
#                is present (Required)
#      'switch': name of the switch to which the given portgroup belongs
#                (Required)
#      'stafHelper': Reference to an object of VDNetLib::Common::STAFHelper
#                    (Optional)
#      'hostOpsObj': Reference to an object of VDNetLib::Host::HostOperations
#                    (Optional)
#
# Results:
#      An object of VDNetLib::PortGroupConfig, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
#######################################################################

sub new {

    my $class      = shift;
    my %args       = @_;
    my $self;
    $self->{'hostIP'}  = $args{'hostip'};
    $self->{'pgName'} = $args{'pgName'};
    $self->{'pgType'} = $args{'pgType'};
    $self->{'switchObj'} = $args{'switchObj'};
    $self->{'stafHelper'} = $args{'stafHelper'};
    $self->{'hostOpsObj'} = $args{'hostOpsObj'};
    $self->{parentObj} = $self->{'switchObj'}->{'switchObj'};
    $self->{_pyIdName} = "name";
    $self->{'name'} = $self->{'pgName'};
    $self->{_pyclass} = "vmware.vsphere.esx.vsswitch.portgroup.portgroup_facade".
                        ".PortgroupFacade";
    my $hostIP        = $args{'hostip'};

    my $switchObj = $self->{'switchObj'};
    $self->{'switch'} = $switchObj->{'name'};

    if (not defined $self->{'pgName'} ||
        not defined $self->{'switch'} ||
        not defined $hostIP) {
       $vdLogger->Error("HostIP, portgroup name and/or its switch not provided");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }

    bless($self);

    #
    # Create a VDNetLib::Common::STAFHelper object with default parameters if it not
    # provided in the input parameters.
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

    # Find the type of the host i.e whether it is hosted or esx or vmkernel
    $self->{hostType} = VDNetLib::Common::Utilities::GetHostType($hostIP);
    if (not defined $self->{hostType} ||
       ($self->{hostType} !~ /esx/i && $self->{hostType} !~ /vmkernel/i)) {
       $vdLogger->Error("Unknown host type or type not supported");
       VDSetLastError("EOSNOTSUP");
       return FAILURE;
    }

    if (not defined  $self->{hostOpsObj}) {
       $vdLogger->Error("hostOpsObj not passed in new() of PortGroup class");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

    return $self;
}


#######################################################################
#
# GetPGProperties --
#      Method to get the properties like VLAN ID, switch name of
#      portgroup object.
#
# Input:
#      None
#
# Results:
#      Reference to a hash with following key/values:
#      'switch' : name of portgroup object's switch
#      'vlan'   : vlan id configured on the portgroup object
#      'name'   : name of the portgroup
#
# Side effects:
#      None
#
#######################################################################

sub GetPGProperties
{
    my $self = shift;

    my $pgPyObj = $self->GetInlinePyObject();
    my $result = CallMethodWithKWArgs($pgPyObj, 'read', {});
    if( $result eq FAILURE){
        $vdLogger->Error("Could not retrieve properties of $self->{pgName} ".
                         "on host $self->{hostIP}");
        VDSetLastError(VDGetLastError());
        return FAILURE;
    }
    $vdLogger->Info("Retrieved portgroup properties for $self->{pgName} ".
                    "on host $self->{hostIP}");
    $vdLogger->Debug("Portgroup $result->{name} --> switch: $result->{switch},".
                    " vlanId: $result->{vlan}");
    return $result;
}


########################################################################
#
# GetPortGroupPromiscuous --
#      Method to get the Status of Promiscuous mode of a given PortGroup
#      Obtains promiscuous mode information of the given PortGroup.
#
# Input:
#       None
#
# Results:
#      FALSE (unset) - Promiscuous mode is unset/disable
#      TRUE (set)   - Promiscuous mode is set/enable
#      FAILURE   - In case of any failure
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupPromiscuous
{
    my $self   = shift;
    my $PortGroup = $self->{'pgName'};
    my $res;
    my $size;

    #
    # Build the command to get the Promiscuous mode status of the
    # portgroup.
    #

    my $command = "$ESXCLI policy security get -p=$PortGroup";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                        "$command");
    #
    # Check if the command is successful in obtaining the promiscuous
    # mode status of the Portgroup.
    #

    if (($res->{rc}) == 0 &&
        $res->{exitCode} == 0 &&
        (defined $res->{stdout}) &&
        $res->{stdout} =~ m/\s{3}Allow Promiscuous: true/i) {
       $vdLogger->Debug("the promiscusous mode for " .
                        "portgroup $PortGroup is enabled");
       return TRUE;
    } elsif (($res->{rc}) == 0 &&
             $res->{exitCode} == 0 &&
             (defined $res->{stdout}) &&
             $res->{stdout} =~ m/\s{3}Allow Promiscuous: false/i) {
       $vdLogger->Debug("The Promiscuous mode on $PortGroup is " .
                        "disabled");
       return FALSE;
    } else {
       my $errorString = VDSetLastError(VDGetLastError);
       $vdLogger->Error("Failed to get Promiscuous mode for " .
                        "portgroup \n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# GetPortGroupMacAddressChange --
#      Method to get the Status of Mac Address change flag of the given
#      PortGroup.
#      Obtains the Mac Address change flag information for the given
#      PortGroup using the command: "esxcli network vswitch standard
#      portgroup policy security get".
#
# Input:
#      None
#
# Results:
#      FALSE (unset) - Mac Address change is rejected
#      TRUE (set)   - Mac Address change is accepted
#
# Side effects:
#       None
#
########################################################################

sub GetPortGroupMacAddressChange
{
    my $self    = shift;
    my $PortGroup = $self->{'pgName'};
    my $res;
    my $size;

    #
    # Build the command to get the Mac Address change flag status of
    # the given portgroup.
    #

    my $command = "$ESXCLI policy security get -p=$PortGroup";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
    #
    # Check if the command is successful in obtiaining the Mac Address
    # change flag status of the given PortGroup.
    #

    if (($res->{rc}) == 0 &&
        $res->{exitCode} == 0 &&
        (defined $res->{stdout}) &&
        $res->{stdout} =~ m/\s{3}Allow MAC Address Change: true/i) {
       $vdLogger->Debug("The Mac Address Change for " .
                        "portgroup $PortGroup is accepted");
       return TRUE;
    } elsif (($res->{rc}) == 0 &&
        $res->{exitCode} == 0 &&
        (defined $res->{stdout}) &&
        $res->{stdout} =~ m/\s{3}Allow MAC Address Change: false/i) {
       $vdLogger->Debug("The Mac Address Change for $PortGroup is " .
                        "rejected");
       return FALSE;
    } else {
       my $errorString = VDSetLastError(VDGetLastError);
       $vdLogger->Debug($errorString);
       $vdLogger->Error("Failed to get the Mac Address Change " .
                        " flag status for $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# SetPortGroupMacAddressChange --
#      Method to set the Status of Mac Address change flag accepted for
#      the given PortGroup.
#      Enables the Mac Address Change for the specified PortGroup using
#      the esxcli
#
# Input:
#      None
#
# Results:
#      SUCCESS for successful operation
#      FAILURE for failure
#
# Side effects:
#      None
#
########################################################################

sub SetPortGroupMacAddressChange
{
    my $self = shift;
    my $res;
    my $command;

    my $PortGroup = $self->{'pgName'};

    #
    # Get the current status of the Mac Address Change flag on the
    # given portgroup.
    #

    $res = $self->GetPortGroupMacAddressChange();

    if ($res eq "FAILURE") {
       # Failed to get the current Mac Address Change flag status
       $vdLogger->Error("Failed to set the Mac Address Change flag " .
                        "on $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    } elsif ($res == 1) {
       # Given PortGroup is already accepting the Mac Address Change.
       $vdLogger->Debug("Mac Address Change on $PortGroup is " .
                        "already set");
       return SUCCESS;
    } else {

       #
       # If the Mac Address Change flag is not set i.e. set to rejected.
       # Then build the command to set the Mac Address Change flag as
       # accept on portgroup.
       #

       $command = "$ESXCLI policy security set ".
                  " --allow-mac-change=true -p=$PortGroup";

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}
                                                  {hostIP},"$command");

       # Check for the success or failure of above command.
       if (($res->{rc}) != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to set the Mac Address Change flag " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       #
       # Cross verify if Mac Address Change flag on portgroup has been
       # set properly.
       #

       $res = $self->GetPortGroupMacAddressChange();

       if ($res eq "FAILURE") {
          # Failed to get the Mac Address Change flag status.
          $vdLogger->Error("Failed to set the Mac Address Change flag " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       } elsif ($res == 1) {
          # Mac Address Change has been enabled.
          $vdLogger->Debug("Successfully enabled the Mac Address Change " .
                           "on $PortGroup");
          return SUCCESS;
       } else {
          # Mac Address Change has not been set.
          $vdLogger->Error("Failed to set the Mac Address Change flag " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}


########################################################################
#
# GetPortGroupForgedTransmit --
#      Method to get the Status of Forged Transmit flag of the given
#      PortGroup.
#      Obtains the Forged Transmit flag information for the given
#      PortGroup using the command:" esxcli network vswitch standard
#      portgroup policy security get"
#
# Input:
#     None
#
# Results:
#      FALSE (unset) - Forged Transmit is rejected
#      TRUE (set)   - Forged Transmit is accepted
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupForgedTransmit
{
    my $self    = shift;
    my $PortGroup = $self->{'pgName'};
    my $res;
    my $size;

    #
    # Build the command to get the Forged Transmit flag status of the
    # given PortGroup.
    #

    my $command = "$ESXCLI policy security get -p=$PortGroup";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}
                                               {hostIP},"$command");

    #
    # Check if the command is successful in obtaining the Forged
    # Transmit flag status of the given PortGroup.
    #

    if (($res->{rc}) == 0 &&
        $res->{exitCode} == 0 &&
        (defined $res->{stdout}) &&
        $res->{stdout} =~ m/\s{3}Allow Forged Transmits: true/i) {
       $vdLogger->Debug("The Forged Transmit for " .
                        "portgroup: $PortGroup is accepted");
       return TRUE;
    } elsif (($res->{rc}) == 0 &&
             $res->{exitCode} == 0 &&
             (defined $res->{stdout}) &&
             $res->{stdout} =~ m/\s{3}Allow Forged Transmits: false/i) {
       $vdLogger->Debug("The Forged Transmit for " .
                        "portgroup: $PortGroup is rejected");
       return FALSE;
    } else {
       my $errorString = VDSetLastError(VDGetLastError);
       $vdLogger->Debug($errorString);
       $vdLogger->Error("Failed to get the Forged Transmit " .
                        "flag status for $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# SetPortGroupForgedTransmit --
#      Method to set the Forged Transmit flag status to accepted for the
#      given PortGroup.
#      Enables the Forged Transmit for the specified PortGroup using the
#      esxcli.
#
# Input:
#      None
#
# Results:
#      SUCCESS for successful operation
#      FAILURE for failure
#
# Side effects:
#       None
#
########################################################################

sub SetPortGroupForgedTransmit
{
    my $self = shift;
    my $res;
    my $command;
    my $PortGroup = $self->{'pgName'};

    #
    # Get the current status of the Forged Transmit flag on the given
    # portgroup.
    #

    $res = $self->GetPortGroupForgedTransmit();

    if ($res eq "FAILURE") {
       # Failed to get the current Forged Transmit flag status
       $vdLogger->Error("Failed to set the Forged Transmit flag " .
                        "on $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    } elsif ($res == 1) {
       # Given PortGroup is already accepting the Forged Transmit.
       $vdLogger->Debug("Forged Transmit on $PortGroup is " .
                        "already set");
       return SUCCESS;
    } else {

       #
       # If the Forged Transmit flag is not set i.e. set to rejected.
       # Then build the command to set the Forged Transmit flag as accept
       # on portgroup.
       #

       $command = "$ESXCLI policy security set " .
                  "--allow-forged-transmits=true -p=$PortGroup";

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}
                                                  {hostIP},"$command");

       # Check for the success or failure of above command.
       if (($res->{rc}) != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to set the Forged Transmit flag " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       #
       # Cross verify if Forged Transmit flag on portgroup has been set
       # properly.
       #

       $res = $self->GetPortGroupForgedTransmit();

       if ($res eq "FAILURE") {
          # Failed to get the Forged Transmit flag status
          $vdLogger->Error("Failed to set the Forged Transmit flag " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       } elsif ($res == 1) {
          # Forged Transmit has been enabled
          $vdLogger->Debug("Successfully enabled the Forged Transmit on " .
                           "$PortGroup");
          return SUCCESS;
       } else {
          # Forged Transmit has not been set
          $vdLogger->Error("Failed to enable the Forged Transmit " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
         }
    }
}


########################################################################
#
# GetPortgroupBeaconProbing --
#      Method to get the Status of Beacon Probing flag of the given
#      PortGroup.
#      Obtains the Beacon Probing flag information for the given vSwitch
#      using the command:"esxcli".
#
# Input:
#      None
#
# Results:
#      FALSE(unset) if beacon probing is disabled
#      TRUE(set)   if beacon probing is enabled
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupBeaconProbing
{
    my $self    = shift;
    my $res;
    my $size;
    my $PortGroup = $self->{'pgName'};

    #
    # Build the command to get the Beacon Probing flag status of the
    # given Portgroup.
    #

    my $command = "$ESXCLI policy failover get -p=$PortGroup";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}
                                               {hostIP},"$command");

    #
    # Check if the command is successful in obtaining the Beacon Probing
    # flag status of the given PortGroup.
    #

    if (($res->{rc}) == 0 &&
        $res->{exitCode} == 0 &&
        (defined $res->{stdout}) &&
        $res->{stdout} =~ m/\s{3}Network Failure Detection: link/i) {
       $vdLogger->Debug(" Failure based on NIC link state is detected");
       return TRUE;
    } elsif (($res->{rc}) == 0 &&
             $res->{exitCode} == 0 &&
             (defined $res->{stdout}) &&
       $res->{stdout} =~ m/\s{3}Network Failure Detection: beacon/i)  {
       $vdLogger->Debug("Failure based on active beaconing to the vswitch " .
                        "state is detected");
       return FALSE;
    } else {
       my $errorString = VDSetLastError(VDGetLastError);
       $vdLogger->Debug($errorString);
       $vdLogger->Error("Failed to get the Beacon Probing " .
                        " flag status for $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# SetPortGroupBeaconProbing
#      Method to enable the Beacon Probing flag for the given PortGroup.
#      Enables the Beacon Probing for the specified PortGroup using the
#      esxcli.
#
# Input:
#      None
#
# Results:
#      SUCCESS for successful operation
#      FAILURE for failure
#
# Side effects:
#      None
#
########################################################################

sub SetPortGroupBeaconProbing
{
    my $self = shift;
    my $res;
    my $command;
    my $PortGroup = $self->{'pgName'};

    #
    # Get the current status of the Beacon Probing flag on the given
    # portgroup.
    #

    $res = $self->GetPortGroupBeaconProbing();

    if ($res eq "FAILURE") {
       # Failed to get the current Beacon Probing flag status
       $vdLogger->Error("Failed to enable the Beacon Probing " .
                        "on $PortGroup\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    } elsif ($res == 1) {
       # Given PortGroup is already having the Beacon Probing, enabled.
       $vdLogger->Debug("Beacon Probing on $PortGroup is " .
                        "already enabled");
       return SUCCESS;
    } else {

       #
       # If the Beacon Probing is not enabled then build the command to
       # enable it on the given PortGroup.
       #

       $command =  "$ESXCLI policy failover set ".
                  " --failure-detection=beacon  -p=$PortGroup";

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}
                                                  {hostIP},"$command");

       # Check for the success or failure of above command.
       if (($res->{rc}) != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to enable the Beacon Probing " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       #
       # Cross verify if Beacon Probing on the given PortGroup has been
       # enabled properly.
       #

       $res = $self->GetPortGroupBeaconProbing();

       if ($res eq "FAILURE") {
          # Failed to get the Beacon Probing flag status
          $vdLogger->Error("Failed to enable Beacon Probing " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       } elsif ($res == 1) {
          # Beacon Probing has been enabled
          $vdLogger->Debug("Successfully enabled the Beacon Probing on " .
                           "$PortGroup");
          return SUCCESS;
       } else {
          # Beacon Probing has not been enabled
          $vdLogger->Error("Failed to enable the Beacon Probing " .
                           "on $PortGroup\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}

########################################################################
#
# GetPortGroupStats --
#      Method to obtain stats of data traffic of PortGroup.
#      Use the esxcli command option to get stats.
#
# Input:
#      None
#
# Results:
#      Result hash on success
#      FALSE on failure
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupStats
{
    my $self = shift;
    my $res;
    my $command;
    my %result;
    my $PortGroup = $self->{'pgName'};

    # Build the command to get the Stats of a PortGroup.
    $command = "$ESXCLI policy failover set -l=portid -p=$PortGroup";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if (($res->{rc}) == 0 && $res->{exitCode} == 0) {
       my @temp = split(/\n/, $res->{stdout});

       # build a hash of values to return
       foreach my $el (@temp) {
          $el =~ s/^\s+//;
          $el =~ s/\s+$//;
          if (not $el =~ m/{/ || $el eq "}") {
             my @rets = split(/:/, $el);
             $result{$rets[0]} = $rets[1];
             print " Successfull to provide the statistics of the portgroup";
             return TRUE;
          }
       }
       return \%result;
    } else {
       $vdLogger->Error("Failed to obtain the PortGroup stats\n");
       VDSetLastError("EFAIL");
       return FALSE;
    }
}


########################################################################
#
# GetPortGroupNicTeamingPolicy --
#      Method to obtain the NIC Teaming Policies for the given PortGroup
#      Use the esxcli command to get the NIC Teaming Policies for the
#      given PortGroup.
#
# Input:
#      None
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
#  -----------------------|-------------------------------
#                         |
# Side effects:
#      None
#
########################################################################

sub GetPortGroupNicTeamingPolicy
{
    my $self = shift;
    my $res;
    my $command;
    my %result;
    my @tmp;

    my $PortGroup = $self->{'pgName'};

    #
    # Build the command to get the NIC Teaming Policies for the given
    # PortGroup.
    #

    $command = "$ESXCLI policy failover  get -p=$PortGroup";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
    if (($res->{rc}) == 0 && $res->{exitCode} == 0) {
       my @temp = split(/\n/, $res->{stdout});

       #
       # Build a hash of values to return
       # The command above will output the parameters related to all the
       # policies (Security, Traffic Shaping and Failover).
       # But we are interested only in "Failover Policy" related information.
       # Hence will parse the same.
       #

       foreach my $el (@temp) {
          $el =~ s/^\s+//;
          $el =~ s/\s+$//;
          @tmp = split(/:/, $el);
          $tmp[1] =~ s/^\s|\s$// if (defined $tmp[1]);
          $result{$tmp[0]} = $tmp[1];
       }

       if (defined $result{"Active Adapters"}) {
          @tmp = split(/\,\s*/, $result{"Active Adapters"});
          $result{"ActiveAdapters"} = \@tmp;
          delete $result{"Active Adapters"};
       }
       return \%result;
    } else {
       $vdLogger->Error("Failed to obtain the NIC Teaming Policy " .
                        "for PortGroup: $PortGroup\n");
       VDSetLastError("EFAIL");
       return FALSE;
    }
}


########################################################################
#
# SetPortGroupNicTeamingPolicy --
#      Method to set the NIC Teaming Policies for the given PortGroup.
#      Use the esxcli command to set the NIC Teaming Policies for the
#      given PortGroup.
#
# Input:
#      reference to an input (properties)hash containing the key-value
#      pairs of the NIC Teaming Properties to be set.
#      Format for the same is given below.
#
# Results:
#      SUCCESS on success
#      FAILURE on failure
#
# Format for the input hash:
# --------------------------
#       The input hash will have the following
#       format for the key-value pairs:-
#
#  KEY                    |  VALUE(s) (Description)
#  -----------------------|------------------------------
#                         |
#  ActiveAdapters         |  A string containing list of
#                         |  virtual nics (separated by
#                         |  commas) to be added as the
#                         |  uplink
#                         |(e.g. {vmnic1,vmnic2,vmnic3})
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
#                         |
# Side effects:
#      None
#
########################################################################

sub SetPortGroupNicTeamingPolicy
{
    my $self       = shift;
    my $properties = shift;
    my $options    = "";
    my $res;
    my $command;
    my %result;
    my @tmp;

    my $PortGroup = $self->{'pgName'};

    foreach my $myKey (keys %{$properties}) {
       if ($myKey =~ m/ActiveAdapters/i && defined $properties->{$myKey}) {
          $properties->{$myKey} =~ s/\s+//;
          @tmp = split(/\,/, $properties->{$myKey});
          foreach my $myAdapter (@tmp) {
             next if ($self->AddvSwitchUplink($myAdapter) eq "SUCCESS");
             $vdLogger->Error("Failed to set the NIC Teaming Policy " .
                              "for PortGroup: $PortGroup\n");
             VDSetLastError("EFAIL");
             return FAILURE;
          }
       } elsif ($myKey =~ m/Failback/i && defined $properties->{$myKey}) {
          if ($properties->{$myKey} =~ m/yes/i ||
              $properties->{$myKey} =~ m/true/i) {
             $options = "$options -b true";
          } elsif ($properties->{$myKey} =~ m/no/i ||
                   $properties->{$myKey} =~ m/false/i) {
             $options = "$options -b false";
          } else {
             $vdLogger->Debug("Incorrect value specified for NotifySwitch " .
                              "option.Possible values are: true/false");
          }
       } elsif ($myKey =~ m/LoadBalancing/i && defined $properties->{$myKey}) {
          if ($properties->{$myKey}  =~ m/portid/ ||
              $properties->{$myKey} =~ m/iphash/  ||
              $properties->{$myKey} =~ m/mac/  ||
              $properties->{$myKey} =~ m/explicit/) {
             $options = "$options -l $properties->{$myKey}";
          } else {
             $vdLogger->Debug("Incorrect value specified for LoadBalancing " .
                              "option.Possible values are: " .
                              "portid/iphash/mac/explicit");
          }
      } elsif ($myKey =~ m/NetworkFailureDetection/i &&
               defined $properties->{$myKey}) {
         if ($properties->{$myKey} =~ m/link/i) {
            $options = "$options -f link";
         } elsif ($properties->{$myKey} =~ m/beacon/i) {
            $options = "$options -f beacon";
         } else {
            $vdLogger->Debug("Incorrect value specified for " .
                             "NetworkFailureDetection option.Possible " .
                             "values are:link/beacon");
         }
      } elsif ($myKey =~ m/NotifySwitch/i && defined $properties->{$myKey}) {
         if ($properties->{$myKey} =~ m/yes/i ||
             $properties->{$myKey} =~ m/true/i) {
            $options = "$options -n true";
         } elsif ($properties->{$myKey} =~ m/no/i ||
                  $properties->{$myKey} =~ m/false/i) {
            $options = "$options -n false";
         } else {
            $vdLogger->Debug("Incorrect value specified for NotifyPortGroup " .
                             "option.Possible values are: true/false");
         }
      } elsif ($myKey =~ m/standbynics/i && defined $properties->{$myKey}) {
         $properties->{$myKey} =~ s/\s//g;
         $options = "$options -s $properties->{$myKey}";
      }
      if (not defined $properties) {
         $vdLogger->Error("properties hash not provided");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
    }

    # Build the command to set the NIC Teaming Policies for the given PortGroup.

    $command = "$ESXCLI policy failover set -f=link -p=$PortGroup";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       $vdLogger->Info("Successful in setting the NIC Teaming Policy " .
                       "for PortGroup: $PortGroup\n");
       return SUCCESS;
    } else {
       $vdLogger->Error("Failed to set the NIC Teaming Policy " .
                        "for PortGroup: $PortGroup");

       $vdLogger->Debug(Dumper($res));
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# SetPortGroupFailoverOrder --
#      Method to set the failover order for the given PortGroup.
#      Use the esxcli command to set the failover order for the given
#      PortGroup.
#
# Input:
#      Comma separated list of vmnics (failover order)
#
# Results:
#      SUCCESS on success
#      FAILURE on failure
#
# Side effects:
#      None
#
########################################################################

sub SetPortGroupFailoverOrder
{
    my $self      = shift;
    my $vmnicList = shift;
    my $res       = undef;
    my $command   = undef;
    my $PortGroup = $self->{'pgName'};

    # Build the command to set the failover order for the given PortGroup.

    $command = "$ESXCLI policy failover set --active-uplinks=$vmnicList " .
               "-p=$PortGroup";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if (($res->{rc}) == 0 && $res->{exitCode} == 0) {
       $vdLogger->Info("Failover order has been set, " .
                       "successfully for PortGroup: $PortGroup\n");
       return SUCCESS;
    } else {
       $vdLogger->Error("Failed to set the given failover order " .
                        "for PortGroup: $PortGroup\n");
       $vdLogger->Error(Dumper($res));
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#
# SetPortGroupShaping --
#      Method to enable the traffic shaping policies for the given
#      PortGroup.
#      Use the esxcli command to enable the traffic shaping policies for
#      given PortGroup.
#
# Input:
#      Reference to an "options" hash with the values for following keys
#      avg-bandwidth  (in bits/secs)
#      peak-bandwidth (in bits/secs)
#      burst-size     (in bytes)
#
# Results:
#      SUCCESS on success
#      FAILURE on failure
#
# Side effects:
#      None
#
########################################################################

sub SetPortGroupShaping
{
    my $self = shift;
    my $options = shift;

    my $avgBandwidth  = $options->{'avgbandwidth'};
    my $peakBandwidth = $options->{'peakbandwidth'};
    my $burstSize     = $options->{'burstsize'};
    my $host          = $self->{hostOpsObj}{hostIP};
    my $PortGroup = $self->{'pgName'};

    # All 4 shaping parameters are mandatory.

     my $pgPyObj = $self->GetInlinePyObject();
     my $result = CallMethodWithKWArgs($pgPyObj, 'edit_traffic_shaping',
                             {'avg_bandwidth' => $avgBandwidth,
                              'burst_size' => $burstSize,
                              'enabled' => ConvertToPythonBool(undef, 1),
                              'peak_bandwidth' => $peakBandwidth});

    if ($result eq FAILURE){
         $vdLogger->Error("Failed to set the Traffic Shaping " .
                         "Policies for PortGroup: $PortGroup\n");
         VDSetLastError(VDGetLastError());
         return FAILURE;
    }

    $vdLogger->Info("Set traffic shaping successfully.");
    return SUCCESS;
}


#######################################################################
#
# SetVLAN --
#      Method to configure the given VLAN ID on the portgroup object.
#
# Input:
#      vlanid: a valid VLAN ID to be configured on the portgroup
#              object (Required)
#
# Results:
#      "SUCCESS", if the given the VLAN ID is configured successfully;
#      "FAILURE", in case of any error.
#
#######################################################################

sub SetVLAN
{
    my $self = shift;
    my %args = @_;
    my $vlanType = $args{'vlantype'} || 'access';
    my $vlanid = $args{'vlan'};
    my $pgName = $self->{pgName};
    my $host = $self->{hostIP};
    my $result;
    my $command;

    if ((not defined $vlanid) and ($vlanType =~ /access/i)) {
       $vdLogger->Error("VLAN ID not provided");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    } elsif ($vlanType =~ /trunk/i) {
       $vdLogger->Error("Can not set vlan with type $vlanType with range $vlanid ".
                        "on portgroup $pgName");
       $vdLogger->Error("By now, VSS does not support set a vlan trunk range ".
                        "for a portgroup.\n Please set vlan as access with ".
                        "VLAN ID 4095 for trunk request on VSS");
       VDSetLastError("EINVALID");
       return FAILURE;
    }

    $result = $self->{stafHelper}->STAFSyncProcess($host,"uname -a");
    if ($result->{rc} && $result->{exitCode}) {
       VDSetLastError("ESTAF");
       return FAILURE;
    } elsif ($result->{stdout} =~ / [5|6]\.(\d+)\.(\d+) /) {
       # Execute esxcli command to set the vlan on esx 5.0
       $command = "$ESXCLI set --vlan-id $vlanid ".
                  "--portgroup-name $pgName";
    } else {
       # Execute esxcfg-vswitch command to set the vlan on esx 4.1 and 4.0
       my $vswitch = $self->{switch};
       $command = "esxcfg-vswitch -p $pgName -v $vlanid  $vswitch";
    }

    $vdLogger->Debug("Executing command $command on host $host");
    $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                  $command);
    if ($result->{rc} != 0 && $result->{exitCode} != 0) {
       $vdLogger->Error("Failed to set vlan id for portgroup".
                        "$pgName");
       VDSetLastError("ESTAF");
       return FAILURE;
    }

    #
    # TO DO
    # Add some form of verification which is error free.
    # At the moment UpdateHash method is not up to the mark,
    # Not sure why it is written this way.
    #
    return SUCCESS;
}


###########################################################
# Method Name: UpdateHash                                 #
#                                                         #
# Objective: To update the object hash with portgroup     #
#            parameters                                   #
#                                                         #
# Operation: Updates the object hash using esxcfg-vswitch #
#            -l command. Uses reg-exp and string ops to   #
#            update the hash. Also updates vmnames and    #
#            port group names                             #
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: None                                            #
#                                                         #
# Export Status: Not Exported                             #
###########################################################
sub UpdateHash {
    my $self = shift;
    my $pgName = "$self->{pgName}";

    # This method obtains all the information regarding the
    # portgroup only.
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
          VDSetLastError("EINVALID");
          return FAILURE;
       }

        # This method was in Old HostOperations.pm module.
        # run UpdateHash method from HostOperations module
        # and collect the vswitch info
        #my $res = $self->{hostOpsObj}->UpdateHash();
        #if (defined $res and $res eq "FAILURE") {
        #    print "Failed to update the hash for $pgName\n";
        #    VDSetLastError(VDGetLastError());
        #    return FAILURE;
        #}

        $self->{$pgName}{name}    = $self->{hostOpsObj}->{$pgName}{name};
        $self->{$pgName}{vswitch} = $self->{hostOpsObj}->{$pgName}{vswitch};
        $self->{$pgName}{vlanid}  = $self->{hostOpsObj}->{$pgName}{vlanid};
        $self->{$pgName}{uplink}  = $self->{hostOpsObj}->{$pgName}{uplink};
        $self->{$pgName}{usedports} = $self->{hostOpsObj}->{$pgName}{usedport};
    } else {
       # returning error for non-esx variant systems
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: GetVswitchforPgroup                        #
#                                                         #
# Objective: To get the vSwitch corresponding to the      #
#            port-group                                   #
#                                                         #
# Operation: Gets the vSwitch for a portgroup form the    #
#            object hash. Calls the UpdateHash method for #
#            getting latest info. However we can get the  #
#            vSwitch info without calling UpdateHash also #
#            but the validity of the data can not be      #
#            Gauranteed.                                  #
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: vSwitch name corresponding to port-group        #
#                                                         #
# Export Status: Not Exported                             #
###########################################################
sub GetVswitchforPgroup {
    my $self = shift;

    # This method is supported on ESX variants only
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       my $pgName = "$self->{pgName}";

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $ret = $self->CheckPgroupExists("$pgName");
       if ($ret eq "FAILURE" ||
           $ret == 0) {
          print STDERR "Invalid Port group Name supplied\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # Update the object hash to get the
       # latest parameters. Here vswitch info is
       # obtained for the port group for UpdateHash
       $self->UpdateHash();

       # return the vswitch for the given
       # portgroup name
       if (defined $self->{$pgName}{vswitch}) {
          return $self->{$pgName}{vswitch};
       } else {
          print STDERR "Failed to obtain the vswitch for given portgroup\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}



###########################################################
# Method Name: PortGroupAddUplink                         #
#                                                         #
# Objective: To add an uplink to port group               #
#                                                         #
# Operation: Adds the uplink given by adapter type to the #
#            Specified port group.Uses esxcfg-vswitch     #
#            command with options such as portgroup name  #
#            and adapter name.                            #
#                                                         #
# input arguments: uplink adapter name                    #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddUplink {
    my $self          = shift;
    my $uplinkAdapter = shift;
    my ($res, $data);

    # This method is supported on ESX variants only
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {
       my $pgName = "'$self->{pgName}'";

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $ret = $self->CheckPgroupExists("$pgName");
       if ($ret eq "FAILURE" ||
           $ret == 0) {
          print STDERR "Invalid Port group Name supplied\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # Get the vswitch for the given port group
       my $vswitch = $self->GetVswitchforPgroup($pgName);

       # Check for errors
       if ($vswitch eq "FAILURE") {
          print STDERR "Failed to get vSwitch for port group\n";
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }

       # build the command for adding an uplink to the given portgroup
       my $command = "esxcfg-vswitch $vswitch -p $pgName -L $uplinkAdapter";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupAddUplink\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Result is (add uplink) $data\n" if $debug;

       # check for failure or success of the command
       if ($res eq "SUCCESS") {
          print "Successfully added the uplink to $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/ Uplink already exists: /i) {
          print STDERR "Failed to add uplink, Uplink".
                       " already exists for $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupGetUplinkAndVLAN                  #
#                                                         #
# Objective: To get an uplink of this port group          #
#                                                         #
# Operation: Gets the uplink given by adapter type to the #
#            Specified port group.Uses esxcfg-vswitch     #
#            command with options such as portgroup name  #
#            and adapter name.                            #
#                                                         #
# input arguments: vswitch (optional)                     #
#                                                         #
# Output: has containing uplink & vlan name for           #
#         successful operation                            #
#         FAILURE for failure                             #
#                                                         #
# Export Status: Exported                                 #
###########################################################

sub PortGroupGetUplinkAndVLAN {
    my $self          = shift;
    my $vswitch       = shift || $self->{switch};
    my ($res, $data);

    # This method is supported on ESX variants only
    if ($self->{hostType} !~ /(ESX|vmkernel)/i) {
       # returning error for non-esx variant systems
       VDSetLastError("EINVALID");
       return FAILURE;
    }

    my $pgName = $self->{pgName};

    # Check if portgroup is a valid entry.This step is important
    # to catch error, such as say portgroup object exists, but the
    # port group does not exist.Ex: Some one manually deleting the
    # portgroup while tests are running.
    my $ret = $self->CheckPgroupExists("'$self->{pgName}'");
    if ($ret eq "FAILURE" ||
        $ret == 0) {
       VDSetLastError("EINVALID");
       return FAILURE;
    }

   # Get the vswitch for the given port group

   if(not defined $vswitch) {
      $vswitch = $self->GetVswitchforPgroup("'$self->{pgName}'");
   }


   # Check for errors
   if ((not defined $vswitch) || ($vswitch eq "FAILURE")) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # build the command for retriving an uplink of the given portgroup
   my $command = "esxcfg-vswitch -l";
   $command = "start shell command $command wait".
              " returnstderr returnstdout";
   ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                   "Process",
                                                   "$command");

   if ($res eq "FAILURE") {
      $vdLogger->Error("Failed to execute $command on $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Array declaration to store port group information
   my @tempArray;
   my @newArray; # holds the information without newlines and spaces
   my $flag = 0;
   # Convert the output of esxcfg-vswitch -l into an array
   @tempArray = split(/(\n+)/, $data);

   # Filter out un-necessary spaces

   foreach my $el (@tempArray) {
      if ($el =~ m/\S+/i) {
         $el =~ s/^\s+//;
         $el =~ s/\s+$//;
         push(@newArray, $el);
      }
   }

   # Following lines will filterout the required contents
   # from esxcfg-vswitch -l output
   my $size = @newArray;

   #
   # For each line in the output of the esxcfg-vswitch -l command
   # Collect the switch name, uplink adapter,number of ports to that
   # switch, use portd, configured ports etc.
   #
   for (my $i = 0; $i < $size; $i++) {
      if (defined $newArray[$i] && $newArray[$i] =~ m/Switch Name|Dvs Name/i) {
         if($newArray[$i+1] !~ $vswitch) {
            next;
         }
         if ($newArray[$i+2] =~ /PortGroup Name/i) {
            my $count = $i+3;
            my $usedports;
            my $vlanid;
            my $uplink;
            while (defined $newArray[$count] &&
                  $newArray[$count] !~ m/Switch Name|Dvs Name/i) {
               if($newArray[$count] !~ /$pgName/) {
                  $count = $count+1;
                  next
               }
               $newArray[$count] =~ s/\s{2,}/:/g;
               ($pgName, $vlanid, $usedports, $uplink) =
                  split(/:/,$newArray[$count]);
               my $hash;
               $hash->{pgname} = $pgName;
               $hash->{vlanid} = $vlanid;
               $hash->{uplink} = $uplink;
               return $hash;
            }
         }
      }
   }

   # check for failure or success of the command
   if ($res eq "SUCCESS") {
      return SUCCESS;
   } elsif ($data =~ m/ Uplink already exists: /i) {
      print STDERR "Failed to add uplink, Uplink".
                   " already exists for $pgName\n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

}

###########################################################
# Method Name: PortGroupAddVMKNic                         #
#                                                         #
# Objective: To add an vmknic to port group               #
#                                                         #
# Operation: Adds a vmknic to the port group mentioned    #
#            uses the esxcfg-vmknic command to do the task#
#            If IP address is given as a second argument  #
#            then expects the third argument as subnetmask#
#            and if ipaddress is given as "DHCP", then    #
#            assigns IP addresss to vmknic dynamically    #
#                                                         #
# input arguments: IP address to be assigned to vmknic or #
#                  DHCP                                   #
#                  subnetmask if IPaddress is != DHCP     #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#         2 for invalid args                              #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddVMKNic {
    my $self       = shift;
    my $ipaddress  = shift;
    my $subnetmask = shift;
    my $pgName     = "'$self->{pgName}'";

    my $command;
    my ($res,$data);

    # This method works on ESX variants only
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $status = $self->CheckPgroupExists("$pgName");

       my $ret = $self->CheckPgroupExists("$pgName");
       if ($ret eq "FAILURE" ||
           $ret == 0) {
          print STDERR "Invalid Port group Name supplied\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # Check if IP address is defined and is a valid one
       if (defined $ipaddress and $ipaddress =~ m/[0-9]+/) {
          my $ret = VDNetLib::Common::Utilities::IsValidIP($ipaddress);
          if ($ret eq "FAILURE") {
             print STDERR "Invalid IP passed as argument\n";
             VDSetLastError("EINVALID");
             return FAILURE;
          }

           # Check if subnetmask is defined and is a valid one
           if (defined $subnetmask) {
              # check for ipv4 subnetmask
              if ($subnetmask =~ m/[0-9.]+/) {
                 $ret = VDNetLib::Common::Utilities::IsValidIP($subnetmask);
                 if ($ret eq "FAILURE") {
                    print STDERR "Invalid subnet mask passed as argument\n";
                    VDSetLastError("EINVALID");
                    return FAILURE;
                 }
              } elsif ($subnetmask !~ /\d+/) {
                 # check if subnetmask is of prepix length format
                 print STDERR "Invalid subnet mask passed as argument\n";
                 VDSetLastError("EINVALID");
                 return FAILURE;
              }

              # build the command
              $command = "-i $ipaddress -n $subnetmask";
           } else {
              print STDERR "INVALID Subnet mask passed\n";
              VDSetLastError("EINVALID");
              return FAILURE;
           }
       } elsif ($ipaddress =~ m/DHCP/i) {
          # check if ipaddress option is a DHCP
          $command = "-i DHCP";
       } else {
          print STDERR "INVALID ARGS\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }


       #Build a command for adding a vmknic to the portgroup
       $command = "esxcfg-vmknic -a $command $pgName";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       # Check for failure while adding vmknic to portgroup
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in PortGroupAddVMKNic\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Command: $command *\n Result: $res *\n Data: $data\n" if $debug;

       # return Success on successful completion of the previous
       # command or else throw an error
       if ($data =~ m/Generated New MAC address/ or $data eq "") {
          print "Successfully added the vmknic to $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/A vmkernel nic for the connection
                         point already exists /i) {
          print STDERR "Failed to add vmknic, already exists on $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       } else {
          print STDERR "Unknown error\n";
          VDSetLastError("EUNKNOWN");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupDeleteVMKNic                      #
#                                                         #
# Objective: To Delete a vmknic to port group             #
#                                                         #
# Operation: Deletes a vmknic from port group mentioned   #
#            uses the esxcfg-vmknic command to do the task#
#            Only accepts port group name to delete vmknic#
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupDeleteVMKNic {
    my $self   = shift;
    my $pgName = "'$self->{pgName}'";
    my ($res,$data);
    my $command;

    # This method works only on ESX variants
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $ret = $self->CheckPgroupExists("$pgName");
       if ($ret eq "FAILURE" ||
           $ret == 0) {
          print STDERR "Invalid Port group Name supplied\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # build a command for deleting a vmknic from the portgroup
       $command = "esxcfg-vmknic -d -p $pgName";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       # Check for failure and success of the previous command
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupDeleteVMKNic\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Command : $command *\n Result: $res *\n Data: $data*\n" if $debug;

       # Check if vmknic is successfully deleted
       if ($res eq "SUCCESS") {
          print "Successfully deleted the vmknic from $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/Error performing operation: There is no VMkernel/i) {
          print STDERR "Failed to delete vmknic, No vmknic connection point".
                       "exists for $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       } else {
          print STDERR "Unknown error\n";
          VDSetLastError("EUNKNOWN");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupAddvNIC                           #
#                                                         #
# Objective: To add a vnic from a VM to the port group    #
#                                                         #
# Operation: This method uses the changevirtualnic command#
#            from staf vm service. This method adds a vnic#
#            to the port group, but makes sure that user  #
#            supplied info is correct, before going ahead #
#                                                         #
# Algorithm: 1. GetVMNames                                #
#            2. Get Nics of VMs                           #
#            3. Check if IP of the NIC supplied as arg    #
#               Matches with the vm's nics.If yes collect #
#               the vm name                               #
#            4. use vmstaf service add virtual nic using  #
#               the vmname and the portgroup name supplied#
#                                                         #
# input arguments: Nic name or IP address                 #
#                                                         #
# Output: None                                            #
#         Failure failure                                 #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddvNIC {
    my $self      = shift;
    my $Nic_or_ip = shift;
    my $pgName    = "$self->{pgName}";
    my $vmNames;
    my $macaddr;
    my $adapter;
    my $command;
    my @datalines;
    my $vm;
    my @vmids;
    my ($res,$data);

    # This method is supported on ESX variants only
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       # check if the arguments passed are valid
       if ($Nic_or_ip ne "") {

          # Check if portgroup is a valid entry.This step is important
          # to catch error, such as say portgroup object exists, but the
          # port group does not exist.Ex: Some one manually deleting the
          # portgroup while tests are running.
          if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
              $self->CheckPgroupExists("$pgName") == 0) {
             print STDERR "Invalid Port group Name supplied\n";
             VDSetLastError("EINVALID");
             return FAILURE;
          }

          # Get All the VM names in the string format
          $res = $self->{hostOpsObj}->UpdateVMHash();
          # Check for failure of UpdateVMHash of HostOperations
          if ($res eq "FAILURE") {
             print STDERR "Failure to update HostOperations".
                          " hash in PortGroupAddvNIC\n";
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }

          $vmNames = $self->{hostOpsObj}->{VMNames};
          @vmids   = split(/ /,$self->{hostOpsObj}->{VMIDS});
          if ($vmNames eq "FAILURE") {
             print STDERR "Failure to obtain VM names in PortGroupAddvNIC\n";
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }

          # Check if the passed in parameter is a ip or
          # vnic name Ex:Nic_or_ip can have an ip address
          # or a label. The label looks like "Netwrok Adapter 3"
          if ($Nic_or_ip =~ m/[0-9.]+/) {
             # $Nic_or_ip passed is an IP address
             my @vms = split(/ /,$vmNames);
             @vms = grep /\S/, @vms;#remove empty elements
             $vm = "";

             @vmids = grep /\S/, @vmids;#remove empty elements

             # Check if the IP belongs to the VM from the contents
             # of the host operations object hash
             foreach my $vmnm (@vms) {
                $command = "GETGUESTINFO anchor $self->{agent} vm $vmnm";
                ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                               "vm",
                                                               "$command");
                if (defined $data and $data =~ /$Nic_or_ip/) {
                   $data =~ m/NIC (\d+) IP Address: $Nic_or_ip/g;
                   my $label = $1;
                   $data =~ m/NIC $label MAC Address: (.*)/g;
                   $macaddr = $1;
                   $vm = $vmnm;
                   last;
                }
             }

             if ($vm eq "" or $macaddr eq "") {
                print STDERR "Failed to obtain vmname or mac address in ".
                             "PortGroupAddvNIC as $Nic_or_ip is not".
                             " connected to any VM\n";
                VDSetLastError("EFAIL");
                return FAILURE;
             }


             # This command will provide vmnic info for the given
             # VM. The output of the following command will look like
             # as given below:
             #
             # VM NETWORK 1
             # ADAPTER CLASS: VirtualE1000
             # PortGroup: VM Network
             # NETWORK: VM Network
             # MACADDRESS: 00:0c:29:2a:33:8f
             # Label: Network adapter 1
             #
             # VM NETWORK 2
             # ADAPTER CLASS: VirtualE1000
             # PortGroup: data
             # NETWORK: data
             # MACADDRESS: 00:0c:29:2a:33:99
             # Label: Network adapter 2
             #
             # VM NETWORK 3
             # ADAPTER CLASS: VirtualVmxnet2
             # PortGroup: data
             # NETWORK: data
             # MACADDRESS: 00:0c:29:2a:33:a3
             # Label: Network adapter 3
             #
             # VM NETWORK 4
             # ADAPTER CLASS: VirtualVmxnet3
             # PortGroup: data
             # NETWORK: data
             # MACADDRESS: 00:0c:29:2a:33:ad
             # Label: Network adapter 4
             #
             # And we need the label here to add a vnic to the portgroup
             #
             $command = "vmnicinfo anchor $self->{hostOpsObj}{hostIP} vm $vm";
             ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                            "vm",
                                                            "$command");


                # Check for Success or failure of the previous
                # command
                if ($res ne "FAILURE") {
                   my @lines = split(/\n/, $data);
                   my $length = @lines;
                   # if the previous command is successful, get the
                   # label for the adapter
                   for (my $i=0; $i < $length; $i++) {
                      if ($lines[$i] =~ m/$macaddr/) {
                         if ($lines[$i+1] =~ m/Label: (.*)/) {
                            $Nic_or_ip = $1;
                         }
                      }
                   }
                } else {
                   print STDERR "Failed to obtain the guestinfo".
                                " in PortGroupAddvNIC\n";
                   VDSetLastError("EFAIL");
                   return FAILURE;
                }
            } else {
               # Check if the Network adapter label is provided
               # instead of IP. If not throw and invalid input error
               if (not $Nic_or_ip =~ m/Network adapter [0-9]+/) {
                  print STDERR "INVALID Network label supplied".
                               "Ex: Network adapter 3";
                  VDSetLastError("EINVALID");
                  return FAILURE;
               }
            }

            # Build the command for adding the vnic to a portgroup using the
            # network label obtained from the previous step. The Network label
            # is stored in $Nic_or_ip variable
            $command = "changevirtualnic anchor $self->{agent} vm $vm".
                       " virtualnic_name";
            $command = "$command". " \"$Nic_or_ip\" pgname \"$pgName\"";
            ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                            "vm",
                                                            "$command");

            # Check for Success or failure of the previous command in
            # adding an vnic to the portgroup
            if ($res ne "FAILURE") {
               print "Successfully added vnic to portgroup\n";
               return SUCCESS;
            } elsif ($res eq "FAILURE" and $data eq "0") {
               print "Successfully added vnic to portgroup\n";
               return SUCCESS;
            } else {
               print STDERR "Failed to add vnic to port group\n";
               VDSetLastError("EFAIL");
               return FAILURE;
            }
       } else {
          print STDERR "Invalid args....returning\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupDeleteUplink                      #
#                                                         #
# Objective: To delete an uplink to port group            #
#                                                         #
# Operation: Deletes the uplink given by adapter type from#
#            Specified port group.Uses esxcfg-vswitch     #
#            command with options such as portgroup name  #
#            and adapter name.                            #
#                                                         #
# input arguments: Uplink Adapter Name                    #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupDeleteUplink {
    my $self          = shift;
    my $uplinkAdapter = shift;
    my $pgName     = "'$self->{pgName}'";
    my $command;
    my ($res, $data);

    # This method works on ESX variants
    if ($self->{hostType} =~ /(ESX|vmkernel)/i) {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $ret = $self->CheckPgroupExists("$pgName");
       if ($ret eq "FAILURE" ||
           $ret == 0) {
          print STDERR "Invalid Port group Name supplied\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       my $vswitch = $self->GetVswitchforPgroup($pgName);

       if ($vswitch eq "FAILURE") {
          print STDERR "Failed to get vSwitch for port group\n";
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }

       # Build the command for deleting the Uplink from port group
       $command = "esxcfg-vswitch $vswitch -p $pgName -U $uplinkAdapter";
       $command = "start shell command $command wait returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");


       # Check for failures
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupDeleteUplink\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Check for successful unlinking of uplink adapter
       # to the portgroup
       if ($data eq "") {
          print "Successfully deleted the uplink from $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/Removing from config file only/i) {
          print STDERR "Failed to delete uplink from $pgName and $vswitch\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###############################################################################
#
# SetPromiscousMode --
#      Method which enables or disables the promiscous mode for the porgroup.
#
# Input:
#     operation : specifies whether to enable or disable the promiscous mode.
#
# Results:
#      Returns SUCCESS if promiscous mode is set successfully,
#      Rerurns FAILURE is setting promiscous mode fails.
#
# Side effects:
#      promiscous mode gets enabled for the portgroup.
#
###############################################################################

sub SetPromiscousMode
{
    my $self = shift;
    my $operation = shift || "Enable";
    my $pgName = $self->{pgName};
    my $hostObj = $self->{hostOpsObj};
    my $host = $hostObj->{hostIP};
    my $command;
    my $result;
    my $enable;

    if ($operation =~ m/Enable/i) {
       $enable = 1;
    } else {
       $enable = 0;
    }

    # build the command to set the promiscuous mode of portgroup
    $command = "$ESXCLI policy security set --allow-promiscuous ".
               " $enable -p $pgName";
    $result = $self->{stafHelper}->STAFSyncProcess($host,$command);

    if (($result->{rc} != 0 ) || ($result->{exitCode})) {
       $vdLogger->Error("Failure to set promiscous mode $command on $host");
       $vdLogger->Error(Dumper($result));
       VDSetLastError("EFAIL");
       return FAILURE;
    }
    return SUCCESS;
}


###########################################################
# Method Name: CheckPgroupExists                          #
#                                                         #
# Objective: To Check if a given portgroup exists         #
#                                                         #
# Operation: uses esxcfg-vswitch command to checl if a    #
#            given portGroup exists                       #
#                                                         #
# input arguments: Port Group Name                        #
#                                                         #
# Output: 1 if portgroup exists                           #
#         0 if portgroup does not exist                   #
#         Failure on failure                              #
###########################################################

sub CheckPgroupExists {
    my $self   = shift;
    my $pgName = shift;
    my $command;
    my ($res,$data);

    if (defined $pgName) {
       # Build the command to check if portGroup Exists
       # The esxcfg-vswitch -C <pgroup-name> returns 1
       # if portgroup exists or 0 if it does not exists
       $command = "esxcfg-vswitch -C '$pgName'";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";

       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                      "Process",
                                                      "$command");
        # Check for the status of the previous operation
        if ($res eq "FAILURE") {
           print STDERR "Failure to execute $command on".
                        " $self->{hostOpsObj}{hostIP}\n";
           VDSetLastError("EFAIL");
        } else {
           print STDOUT "Portgroup existsance status is $data\n", if $debug;
           return $data;
        }
    } else {
       print STDERR "Please pass Portgroup name to this method\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


########################################################################
#
# GetInlinePortgroupObject --
#     Method to get an object of
#     VDNetLib::InlineJava::Portgroup::Portgroup with attributes
#     corresponding to this portgroup
#
# Input:
#     None
#
# Results:
#     return value of new() from
#     VDNetLib::InlineJava::Portgroup::Portgroup
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePortgroupObject
{
    my $self = shift;
    return VDNetLib::InlineJava::Portgroup::Portgroup->new(
                                                'name' => $self->{'pgName'});
}
1;
