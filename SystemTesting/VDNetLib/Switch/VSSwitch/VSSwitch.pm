########################################################################
#  Copyright (C) 2011 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::Switch::VSSwitch::VSSwitch;

#
## This package is responsible for all the interaction with VMware
## vNetwork Standard Switch or vSwitch.
#
use FindBin;
use strict;
use warnings;

use Data::Dumper;

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use base 'VDNetLib::Root::Root';
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              ConvertToPythonBool
                                              CallMethodWithKWArgs) ;

our $ESXCFG_VSWITCH="esxcfg-vswitch";
our $ESXCLI_VSWITCH="esxcli network vswitch standard";
our $VSI = "vsish";

########################################################################
#
# new --
#      This is the entry point to VDNetLib::VSwitchConfig package.
#      This method created an object of this class.
#
# Input:
#      A named parameter hash with the following keys:
#      'hostIP' : IP address of the host on which vSwitch is present
#                 (Required)
#      'switch' : Name of the vSwitch (Required)
#      'stafHelper' : VDNetLib::Common::STAFHelper object (optional)
#      'hostOpsObj' : VDNetLib::Host::HostOperations object (optional)
#
# Results:
#      An object of VDNetLib::VSwitchConfig, if successful;
#      "FAILURE", in case of any error.
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
   $self->{'switchType'} = "vswitch";
   $self->{parentObj} = $self->{'hostOpsObj'};
   $self->{'name'} = $self->{'switch'};
   $self->{_pyIdName} = "name";
   $self->{_pyclass} = "vmware.vsphere.esx.vsswitch.vsswitch_facade.VSSwitchFacade";

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

   if (not defined  $self->{hostOpsObj}) {
      $vdLogger->Error("hostOpsObj not passed in new() of VSSwitch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $self;
}


########################################################################
#
# GetvSwitchProps --
#      This method returns all the properties of a vSwitch in a hash.
#
# Input:
#      None
#
# Results:
#      Reference to a hash with the following keys:
#      'switch', 'numports', 'usedports', 'confports', 'mtu', 'uplink',
#        if successful;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetvSwitchProps {
    my $self = shift;

    my $vssPyObj = $self->GetInlinePyObject();
    my $result = CallMethodWithKWArgs($vssPyObj, 'read', {});
    if ($result eq FAILURE){
       $vdLogger->Error("Could not retrieve properties of $self->{switch}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   #uplink attribute is an array reference and needs to be
   #iterated over to retrieve the uplinks from the hash
   return $result;
}


########################################################################
#
# SetvSwitchMTU --
#      This method configures MTU on the vSwitch object.
#
# Input:
#      mtu: MTU size to be set on the vSwitch
#
# Results:
#      "SUCCESS", if MTU is configured successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub SetvSwitchMTU {
   my $self = shift;
   my $mtu = shift;
   my $vSwitch = $self->{'switch'};
   my $host = $self->{host};
   my $command;
   my $result;
   my $actualMTU;

   if (not defined $mtu) {
      $vdLogger->Error("MTU size not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # esxcfg command to set the mtu.
   $command = "$ESXCFG_VSWITCH -m $mtu $vSwitch";

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                  $command);
    if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Verify whether the given MTU is set correctly.
   #
   $actualMTU = $self->GetvSwitchMTU();
   if ($actualMTU eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($actualMTU->{"mtu"} !~ $mtu) {
      $vdLogger->Error("vSwitch MTU mismatch actual:$actualMTU->{'mtu'} " .
                       "requested:$mtu");
      VDSetLastError("EMISTMATCH");
      return FAILURE;
   }
   $vdLogger->Info("Configured MTU $mtu for vswitch $vSwitch");
   return SUCCESS;
}


########################################################################
#
# GetvSwitchMTU --
#      This method gets the mtu value of the vswitch.
#
# Input:
#      none
#
# Results:
#      MTU value of the vswitch.
#      "FAILURE", in case of any error
#
# Side effects:
#      None
########################################################################

sub GetvSwitchMTU
{
   my $self = shift;
   my $vSwitch = $self->{switch};
   my $host = $self->{host};
   my $cmd = "$VSI -pe get /net/portsets/$vSwitch/mtu";
   my $mtu;
   my $result;

   if (not defined $vSwitch) {
      $vdLogger->Error("GetvSwitchMTU : vswitch name not defined");
      VDSetLastError("EONOTDEF");
      return FAILURE;
   }

   # command to get the mtu value for the vswitch.
   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                  $cmd);
    if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      $mtu = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                    RESULT => $result->{stdout});
      return $mtu;
   } else {
     $vdLogger->Error("GetvSwitchMTU : Failed to retrieve mtu value".
                      "for vswitch $vSwitch");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
}


########################################################################
#								       #
# EnableCDP --							       #
#      This method enables the CDP on the vSwitch object.	       #
#								       #
# Input:							       #
#      MODE: the mode of cdp to which this should be set. It could     #
#            be either listen, advertise, both or down.		       #
#								       #
# Results:							       #
#      "SUCCESS", if CDP mode is set successfully;		       #
#      "FAILURE", in case of any error				       #
#								       #
# Side effects:							       #
#      cdp status for the vSS get changed.			       #
#								       #
########################################################################

sub EnableCDP
{
   my $self = shift;
   my %args = @_;
   my $mode = $args{MODE};
   my $host = $self->{host};
   my $command = undef;
   my $result = undef;
   my $status = undef;

   # if mode is not defined then by default put cdp mode of switch
   # to listen.
   #
   if (not defined $mode) {
      $mode = "listen";
   }
   $command = "$ESXCFG_VSWITCH ".
                 "-B $mode $self->{switch}";
   $result = $self->{stafHelper}->STAFSyncProcess($host,$command);

    if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to enable cdp for switch ".
                      "$self->{switch} due to staf error");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # check the CDP value.
   $status = $self->GetCDPStatus();
   if (defined $status && $status =~ /$mode/i) {
      $vdLogger->Info("Successfully set the cdp status".
                     " for vswitch $self->{switch}");
   } else {
      $vdLogger->Error("Failed set cdp status to $mode".
                      " for vswitch $self->{switch}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#								       #
# GetCDPStatus --						       #
#      This method gets the cdp status for the vswitch.		       #
#								       #
# Input:							       #
#      None.							       #
#								       #
# Results:							       #
#      cdp status, if cdp status is retrieved successfully.	       #
#      "FAILURE", in case of any error				       #
#								       #
# Side effects:							       #
#      none.							       #
#								       #
########################################################################

sub GetCDPStatus
{
   my $self = shift;
   my %args = @_;
   my $mode = $args{MODE};
   my $host = $self->{host};
   my $command = undef;
   my $result = undef;
   my $status = undef;

   $command = "$ESXCFG_VSWITCH -b $self->{switch}";
   $result = $self->{stafHelper}->STAFSyncProcess($host,$command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      $status = $result->{stdout};
   } else {
      $vdLogger->Error("Failed to retrieve the cdp status".
                      " for the vswitch $self->{switch}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $status;
}


########################################################################
#								       #
# Method Name: GetvSwitchProm					       #
#								       #
# Objective: To get the Status of Promiscuous mode of a		       #
#            given vSwitch					       #
#								       #
# Operation: Obtains promiscuous mode info of the given		       #
#            vSwitch using the command esxcfg-info -nF xml	       #
#            command						       #
#								       #
# input arguments: None						       #
#								       #
# Output: 0 (unset) - Promiscuous mode is unset			       #
#         1 (set)   - Promiscuous mode is set			       #
#	  FAILURE   - In case of any failure			       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub GetvSwitchProm {
    my $self    = shift;
    my $vSwitch = $self->{'switch'};
    my $res;
    my $size;

    # Build the command to get the Promiscuous mode status
    # of the vswitch

    my $command = "vim-cmd /hostsvc/net/vswitch_info".
                  " $vSwitch|grep -i allowpromiscuous";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Check if the command is successful in
    # obtaining the promiscuous mode status of the
    # vSwitch

    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
	defined $res->{stdout} &&
	$res->{stdout} =~ m/true/i) {
        $vdLogger->Debug("the promiscusous mode for".
                         "switch $vSwitch is enabled");
        return 1;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/false/i) {
        $vdLogger->Debug("The Promiscuous mode on $vSwitch is disabled");
        return 0;

    } else {
        my $errorString = VDGetLastError();
        $vdLogger->Debug($errorString);
        $vdLogger->Error("Failed to get Promiscuous mode of $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: SetvSwitchProm					       #
#								       #
# Objective: To set the promiscuous mode of a given vSwitch	       #
#								       #
# Operation: Enables the promiscuous mode of a specified	       #
#            vswitch using the vim-cmd				       #
#								       #
# input arguments:                                                     #
#         state: enable or disable                                     #
#								       #
# Output: 0 for successful operation				       #
#         1 for failure						       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub SetvSwitchProm {
    my $self = shift;
    my $state = shift;
    my $expectedRes;
    my $res;
    my $command;

    if (not defined $state) {
       $vdLogger->Error("Promiscuous state not specified on vSwitch!");
       return FAILURE;
    } elsif ( $state =~ /enable/i ) {
       $expectedRes = 1;
    } elsif ( $state =~ /disable/i ) {
       $expectedRes = 0;
    } else {
       $vdLogger->Error("Unsupported promiscuous state <$state> on vSwitch!");
       return FAILURE;
    }

    my $vSwitch = $self->{'switch'};

    # Get the current status of the Promiscuous mode
    # on the given switch

    $res = $self->GetvSwitchProm();

    if ($res eq "FAILURE") {
       # Failed to get the current promiscuous mode status
       $vdLogger->Error("Failed to get promiscuous mode on $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    } elsif ($res == $expectedRes) {
       # Given vSwitch is having its promiscuous mode, set.
       $vdLogger->Debug( "Promiscuous mode on $vSwitch is already in $state state");
       return SUCCESS;

    } else {

       # If the promiscuous mode is not set
       # build the command to set the promiscuous
       # mode on vswitch

       $command = "vim-cmd /hostsvc/net/vswitch_setpolicy";
       if ( $state =~ /enable/i ) {
          $command .= " --securepolicy-promisc=true $vSwitch";
       } else {
          $command .= " --securepolicy-promisc=false $vSwitch";
       }

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       # Check for the success or failure of above command
       if ($res->{rc} != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to set promiscuous mode".
                           " on vSwitch: $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Cross verify if promiscuous mode on vswitch
       # has been set properly

       $res = $self->GetvSwitchProm();

       if ($res eq "FAILURE") {
          # Failed to get the promiscuous mode status
          $vdLogger->Error("Failed to set promiscuous mode on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;

       } elsif ($res == $expectedRes) {
          # Promiscuous mode has been set
          $vdLogger->Debug("Successfully $state the promiscuous mode on $vSwitch");
          return SUCCESS;

       } else {
          # Promiscuous mode has not been set
          $vdLogger->Error("failed to $state the promiscuous".
                           "mode on $vSwitch");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchMacChange				       #
#								       #
# Objective: To get the Status of Mac Address change flag	       #
#            of the given vSwitch				       #
#								       #
# Operation: Obtains the Mac Address change flag info		       #
#            for the given vSwitch using the command:		       #
#	     "vim-cmd /hostsvc/net/vswitch_info"		       #
#								       #
# input arguments: None						       #
#								       #
# Output: 0 (unset) - Mac Address change is rejected		       #
#         1 (set)   - Mac Address change is accepted		       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub GetvSwitchMacChange {
    my $self    = shift;
    my $vSwitch = $self->{'switch'};
    my $res;
    my $size;

    # Build the command to get the Mac Address change flag status
    # of the given vSwitch

    my $command = "vim-cmd /hostsvc/net/vswitch_info $vSwitch|grep -i \"macChanges\"";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Check if the command is successful in
    # obtaining the Mac Address change flag
    # status of the given vSwitch

    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/true/i) {
        $vdLogger->Debug("The Mac Address Change for ".
                         "switch: $vSwitch is accepted");
        return 1;

    } elsif ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/false/i) {
        $vdLogger->Debug("The Mac Address Change for ".
			 "switch: $vSwitch is disabled");
        return 0;

    } else {
        my $errorString = VDGetLastError();
        $vdLogger->Debug($errorString);
        $vdLogger->Error("Failed to get the Mac Address Change ".
			 " flag status for $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: SetvSwitchMacChange				       #
#								       #
# Objective: To set the Status of Mac Address Change Policy	       #
#								       #
# Operation: Enable/Disable the Mac Address Change for the	       #
#            specified vSwitch using the vim-cmd		       #
#								       #
# input arguments:                                                     #
#         state: enable or disable                                     #
#								       #
# Output: SUCCESS for successful operation			       #
#         FAILURE for failure					       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub SetvSwitchMacChange {
    my $self = shift;
    my $state = shift;
    my $expectedRes;
    my $res;
    my $command;

    if (not defined $state) {
       $vdLogger->Error("MAC address change state not specified on vSwitch!");
       return FAILURE;
    } elsif ($state =~ /enable/i) {
       $expectedRes = 1;
    } elsif ($state =~ /disable/i) {
       $expectedRes = 0;
    } else {
       $vdLogger->Error("Unsupported mac change state <$state> on vSwitch!");
       return FAILURE;
    }
    my $vSwitch = $self->{'switch'};

    # Get the current status of the Mac Address Change flag
    # on the given switch

    $res = $self->GetvSwitchMacChange();

    if ($res eq "FAILURE") {
       # Failed to get the current Mac Address Change flag status
       $vdLogger->Error("Failed to get the Mac Address Change flag ".
			"on $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    } elsif ($res == $expectedRes) {
       # Given vSwitch is already in expected state on Mac Address Change.
       $vdLogger->Debug("Mac Address Change on $vSwitch is ".
			"already set to $state");
       return SUCCESS;

    } else {

       # Build the command to set the Mac Address Change flag
       # on vswitch as specified

       $command = "vim-cmd /hostsvc/net/vswitch_setpolicy";
       if ( $state =~ /enable/i ) {
          $command .= " --securepolicy-macchange=true $vSwitch";
       } else {
          $command .= " --securepolicy-macchange=false $vSwitch";
       }

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       # Check for the success or failure of above command
       if ($res->{rc} != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to set the Mac Address Change flag ".
	                   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Cross verify if Mac Address Change flag on vswitch
       # has been set properly

       $res = $self->GetvSwitchMacChange();

       if ($res eq "FAILURE") {
          # Failed to get the Mac Address Change flag status
          $vdLogger->Error("Failed to get the Mac Address Change flag ".
		           "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;

       } elsif ($res == $expectedRes) {
          # Mac Address Change has been set
          $vdLogger->Debug("Successfully $state the Mac Address Change on $vSwitch");
          return SUCCESS;

       } else {
          # Mac Address Change has not been set
          $vdLogger->Error("Failed to $state the Mac Address Change ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchForgedXmit				       #
#								       #
# Objective: To get the Status of Forged Transmit flag		       #
#            of the given vSwitch				       #
#								       #
# Operation: Obtains the Forged Transmit flag info		       #
#            for the given vSwitch using the command:		       #
#	     "vim-cmd /hostsvc/net/vswitch_info"		       #
#								       #
# input arguments: None						       #
#								       #
# Output: 0 (unset) - Forged Transmit is rejected		       #
#         1 (set)   - Forged Transmit is accepted		       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub GetvSwitchForgedXmit {
    my $self    = shift;
    my $vSwitch = $self->{'switch'};
    my $res;
    my $size;

    # Build the command to get the Forged Transmit flag status
    # of the given vSwitch

    my $command = "vim-cmd /hostsvc/net/vswitch_info".
                  " $vSwitch|grep -i forgedTransmits";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Check if the command is successful in
    # obtaining the Forged Transmit flag
    # status of the given vSwitch

    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/true/i) {
        $vdLogger->Debug("The Forged Transmit for ".
                         "switch: $vSwitch is accepted");
        return 1;

    } elsif ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/false/i) {
        $vdLogger->Debug("The Forged Transmit for ".
		         "switch: $vSwitch is rejected");
        return 0;

    } else {
        my $errorString = VDGetLastError();
        $vdLogger->Debug($errorString);
        $vdLogger->Error("Failed to get the Forged Transmit ".
			 " flag status for $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: SetvSwitchForgedXmit				       #
#								       #
# Objective: To set the Forged Transmit flag status to		       #
#	     accepted for the given vSwitch			       #
#								       #
# Operation: Enable/Disable the Forged Transmit for the		       #
#            specified vSwitch using the vim-cmd		       #
#								       #
# input arguments:              				       #
#         state: enable or disable                                     #
#								       #
# Output: SUCCESS for successful operation			       #
#         FAILURE for failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub SetvSwitchForgedXmit {
    my $self = shift;
    my $state = shift;
    my $expectedRes;
    my $res;
    my $command;

    if (not defined $state) {
       $vdLogger->Error("Forged transmit state not specified on vSwitch!");
       return FAILURE;
    } elsif ($state =~ /enable/i) {
       $expectedRes = 1;
    } elsif ($state =~ /disable/i) {
       $expectedRes = 0;
    } else {
       $vdLogger->Error("Unsupported forged transmit state <$state> on vSwitch!");
       return FAILURE;
    }

    my $vSwitch = $self->{'switch'};

    # Get the current status of the Forged Transmit flag
    # on the given switch

    $res = $self->GetvSwitchForgedXmit();

    if ($res eq "FAILURE") {
       # Failed to get the current Forged Transmit flag status
       $vdLogger->Error("Failed to get the Forged Transmit flag ".
			"on $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    } elsif ($res == $expectedRes) {
       # Given vSwitch is already in expected state on Forged Transmit.
       $vdLogger->Debug("Forged Transmit on $vSwitch is ".
                        "already set to $state");
       return SUCCESS;

    } else {

       # Build the command to set the Forged Transmit flag
       # on vswitch as specified

       $command = "vim-cmd /hostsvc/net/vswitch_setpolicy";
       if ( $state =~ /enable/i ) {
          $command .= " --securepolicy-forgedxmit=true $vSwitch";
       } else {
          $command .= " --securepolicy-forgedxmit=false $vSwitch";
       }

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       # Check for the success or failure of above command
       if ($res->{rc} != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to set the Forged Transmit flag ".
		           "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Cross verify if Forged Transmit flag on vswitch
       # has been set properly

       $res = $self->GetvSwitchForgedXmit();

       if ($res eq "FAILURE") {
          # Failed to get the Forged Transmit flag status
          $vdLogger->Error("Failed to get the Forged Transmit flag ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;

       } elsif ($res == $expectedRes) {
          # Forged Transmit has been set
          $vdLogger->Debug("Successfully $state the Forged Transmit on $vSwitch");
          return SUCCESS;

       } else {
          # Forged Transmit has not been set
          $vdLogger->Error("Failed to $state the Forged Transmit ".
		           "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
         }
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchBeacon					       #
#								       #
# Objective: To get the Status of Beacon Probing flag		       #
#            of the given vSwitch				       #
#								       #
# Operation: Obtains the Beacon Probing flag info		       #
#            for the given vSwitch using the command:		       #
#	     "vim-cmd /hostsvc/net/vswitch_info"		       #
#								       #
# input arguments: None						       #
#								       #
# Output: 0 (unset) - Beacon Probing is disabled		       #
#         1 (set)   - Beacon Probing is enabled			       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub GetvSwitchBeacon {
    my $self    = shift;
    my $vSwitch = $self->{'switch'};
    my $res;
    my $size;

    # Build the command to get the Beacon Probing flag status
    # of the given vSwitch

    my $command = "vim-cmd /hostsvc/net/vswitch_info".
                  " $vSwitch|grep -i checkBeacon";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Check if the command is successful in
    # obtaining the Beacon Probing flag
    # status of the given vSwitch

    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/true/i) {
        $vdLogger->Debug("Beacon Probing for ".
                         "switch: $vSwitch is enabled");
        return 1;

    } elsif ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
        defined $res->{stdout} &&
        $res->{stdout} =~ m/false/i) {
        $vdLogger->Debug("Beacon Probing for ".
			 "switch: $vSwitch is disabled");
        return 0;

   } else {
        my $errorString = VDGetLastError();
        $vdLogger->Debug($errorString);
        $vdLogger->Error("Failed to get the Beacon Probing ".
			 " flag status for $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: SetvSwitchBeacon					       #
#								       #
# Objective: To enable the Beacon Probing flag for the		       #
#	     given vSwitch					       #
#								       #
# Operation: Enables the Beacon Probing for the			       #
#            specified vSwitch using the vim-cmd		       #
#								       #
# input arguments: None						       #
#								       #
# Output: SUCCESS for successful operation			       #
#         FAILURE for failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub SetvSwitchBeacon {
    my $self = shift;
    my $res;
    my $command;

    my $vSwitch = $self->{'switch'};

    # Get the current status of the Beacon Probing flag
    # on the given switch

    $res = $self->GetvSwitchMacChange();

    if ($res eq "FAILURE") {
       # Failed to get the current Beacon Probing flag status
       $vdLogger->Error("Failed to enable the Beacon Probing ".
			"on $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    } elsif ($res == 1) {
       # Given vSwitch is already having the Beacon Probing, enabled.
       $vdLogger->Debug("Beacon Probing on $vSwitch is ".
			"already enabled");
       return SUCCESS;

    } else {
       # If the Beacon Probing is not enabled then
       # build the command to enable it on the given
       # vSwitch

       $command = "vim-cmd /hostsvc/net/vswitch_setpolicy".
                  " --failurecriteria-check-beacon=true $vSwitch";

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       # Check for the success or failure of above command
       if ($res->{rc} != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to enable the Beacon Probing ".
		           "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Cross verify if Beacon Probing on the given vSwitch
       # has been enabled properly

       $res = $self->GetvSwitchBeacon();

       if ($res eq "FAILURE") {
          # Failed to get the Beacon Probing flag status
          $vdLogger->Error("Failed to enable Beacon Probing ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;

       } elsif ($res == 1) {
          # Beacon Probing has been enabled
          $vdLogger->Debug("Successfully enabled the Beacon Probing on $vSwitch");
          return SUCCESS;

       } else {
          # Beacon Probing has not been enabled
          $vdLogger->Error("Failed to enable the Beacon Probing ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}


########################################################################
#								       #
# Method Name: ResetvSwitchBeacon				       #
#								       #
# Objective: To disable the Beacon Probing flag for the		       #
#	     given vSwitch					       #
#								       #
# Operation: Disables the Beacon Probing for the		       #
#            specified vSwitch using the vim-cmd		       #
#								       #
# input arguments: None						       #
#								       #
# Output: SUCCESS for successful operation			       #
#         FAILURE for failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub ResetvSwitchBeacon {
    my $self = shift;
    my $res;
    my $command;

    my $vSwitch = $self->{'switch'};

    # Get the current status of the Beacon Probing flag
    # on the given switch

    $res = $self->GetvSwitchBeacon();

    if ($res eq "FAILURE") {
       # Failed to get the current Beacon Probing flag status
       $vdLogger->Error("Failed to disable the Beacon Probing ".
			"on $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    } elsif ($res == 0) {
       # Given vSwitch is already having the Beacon Probing, disabled.
       $vdLogger->Debug("Beacon Probing on $vSwitch is ".
			"already disabled");
       return SUCCESS;

    } else {

       # If the Beacon Probing is not disabled then
       # build the command to disable it on the given
       # vSwitch

       $command = "vim-cmd /hostsvc/net/vswitch_setpolicy".
                  " --failurecriteria-check-beacon=false $vSwitch";

       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       # Check for the success or failure of above command
       if ($res->{rc} != 0 || $res->{exitCode} != 0) {
          $vdLogger->Error("Failed to disable the Beacon Probing ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Cross verify if Beacon Probing on vswitch
       # has been disabled properly

       $res = $self->GetvSwitchBeacon();

       if ($res eq "FAILURE") {
          # Failed to get the Beacon Probing flag status
          $vdLogger->Error("Failed to disable Beacon Probing ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;

       } elsif ($res == 0) {
          # Beacon Probing has been disabled
          $vdLogger->Debug("Successfully disabled the Beacon Probing on $vSwitch");
          return SUCCESS;

       } else {
          # Beacon Probing has not been disabled
          $vdLogger->Error("Failed to disable Beacon Probing ".
			   "on $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    }
}


########################################################################
#                                                                      #
# Method Name: AddvSwitchUplink                                        #
#                                                                      #
# Objective: To add a pnic to vSwitch with a given name                #
#                                                                      #
# Operation: Using the "network vswitch standard uplink add            #
#            -u pnicname -v vswitch_name" command.                     #
#            Add call method "SetvSSFailoverOrder" to active           #
#            the pnic/vmnic just added.                                #
#                                                                      #
# input arguments: vmnic Name                                          #
#                                                                      #
# Output: SUCCESS for successful operation                             #
#         FAILURE for failure                                          #
#                                                                      #
# Export Status: Exported                                              #
#                                                                      #
########################################################################

sub AddvSwitchUplink {
    my $self = shift;
    my $pNIC = shift;
    my $res;
    my $command;
    my $failoverPolicy;
    my @activeAdapters = ();
    my @standbyAdapters = ();

    my $vSwitch = $self->{'switch'};

    # build the command to add an uplink to vSwitch
    $command = "esxcli network vswitch standard uplink add -u $pNIC -v $vSwitch";

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Check for the status of the command
    if ($res->{rc} == 0) {
        if ($res->{exitCode} == 0) {
            $vdLogger->Info( "Successfully added the pnic: $pNIC, "
                  . "to vSwitch: $vSwitch\n" );

            # Get active adapters and standby adapters
            $failoverPolicy = $self->GetvSwitchNicTeamingPolicy();
            if (FAILURE eq $failoverPolicy) {
                $vdLogger->Error("Failed to get vSwitch $vSwitch nic teaming policy.\n");
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }
            if (defined @{$$failoverPolicy{"ActiveAdapters"}}) {
                @activeAdapters = @{$$failoverPolicy{"ActiveAdapters"}};
            }
            if (defined @{$$failoverPolicy{"StandbyAdapters"}}) {
                @standbyAdapters = @{$$failoverPolicy{"StandbyAdapters"}};
            }
            # Remove the adapter just added from standby adpaters list
            if (@standbyAdapters) {
                @standbyAdapters = grep { $_ ne $pNIC } @standbyAdapters;
                $vdLogger->Debug("Remove the adapter just added: $pNIC from standby adpaters list\n");
            }
            # then add it to active adpaters list
            push(@activeAdapters, $pNIC);
            $vdLogger->Debug("Add the adapter just added: $pNIC to active adpaters list\n");

            # Call SetvSSFailoverOrder to put the adapter in active state
            if (@standbyAdapters) {
                $res = $self->SetvSSFailoverOrder( \@activeAdapters, \@standbyAdapters );
            } else {
                $res = $self->SetvSSFailoverOrder(\@activeAdapters);
            }
            if (FAILURE eq $res) {
                $vdLogger->Error("Failed to put adapter: $pNIC in active status");
                VDSetLastError("EFAIL");
                return FAILURE;
            }
            return SUCCESS;
        } elsif (defined $res->{stdout} &&
            $res->{stdout} =~ m/Uplink already exists/i )
        {
            $vdLogger->Info("pNic: $pNIC already exists on $vSwitch\n");
            return SUCCESS;
        }
    } else {
        $vdLogger->Error( "Failed to add pnic: $pNIC, to "
               . "vSwitch $vSwitch" . Dumper($res) );
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: UnlinkvSwitchUplink				       #
#								       #
# Objective: To delete a pnic from vSwitch with a given name	       #
#								       #
# Operation: To delete a pnic/vmnic from vSwitch with the given name   #
#            using the esxcfg-vswitch -U pnicname vswitch_name	       #
#            command.						       #
#								       #
# input arguments: vmnic Name					       #
#								       #
# Output: SUCCESS for successful operation			       #
#         FAILURE for failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub UnlinkvSwitchPNIC {
    my $self = shift;
    my $pNIC = shift;
    my $anchor = shift;
    my $host = $self->{hostOpsObj}{hostIP};
    my $res;
    my $command;
    my $failoverPolicy;
    my @activeAdapters = ();
    my @standbyAdapters = ();

    my $vSwitch = $self->{'switch'};

    if (not defined $anchor) {
    # build the command for unlinking the uplink
    # adapter from the vSwitch

    # Get active adapters and standby adapters
    $failoverPolicy = $self->GetvSwitchNicTeamingPolicy();
    if (FAILURE eq $failoverPolicy) {
        $vdLogger->Error("Failed to get vSwitch $vSwitch nic teaming policy.\n");
        VDSetLastError(VDGetLastError());
        return FAILURE;
    }
    if (defined @{$$failoverPolicy{"ActiveAdapters"}}) {
        @activeAdapters = @{$$failoverPolicy{"ActiveAdapters"}};
    }
    if (defined @{$$failoverPolicy{"StandbyAdapters"}}) {
        @standbyAdapters = @{$$failoverPolicy{"StandbyAdapters"}};
    }
    #Judge whether the adapter is active. If active, set standby; else ignore.
    foreach my $tmpNIC (@activeAdapters) {
       if ($pNIC eq $tmpNIC) {
           # Add it to standby adpaters list
           push(@standbyAdapters, $pNIC);
           $vdLogger->Debug("Add the adapter: $pNIC to standby adpaters list\n");

           # Call SetvSSFailoverOrder to put the adapter in standby state
           if (@standbyAdapters) {
               $res = $self->SetvSSFailoverOrder(undef, \@standbyAdapters);
           }
           if (FAILURE eq $res) {
               $vdLogger->Error("Failed to put adapter: $pNIC in standby status");
               VDSetLastError("EFAIL");
               return FAILURE;
           }
        }
     }

    $command = "esxcli network vswitch standard uplink remove -u $pNIC -v $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
	defined $res->{stdout} &&
	$res->{stdout} eq "") {
        $vdLogger->Info("Successfully deleted the pNic: $pNIC, ".
			"from vSwitch: $vSwitch\n");
        return SUCCESS;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/No such uplink/i) {
        $vdLogger->Info("pNic: $pNIC, was already not linked to $vSwitch\n");
        return SUCCESS;

    } else {
        $vdLogger->Error("Failed to delete pnic: $pNIC, ".
			 "from vSwitch: $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    $self->{hostOpsObj}->HostNetRefresh();
    } else {
        # Not been tested since a testcase is needed that hits the
        # conditional paths in this method
        my $vssPyObj = $self->GetInlinePyObject();
        my $result = CallMethodWithKWArgs($vssPyObj, 'remove_uplink',
                                           {'uplink' => $pNIC});
        if ($result eq FAILURE){
            $vdLogger->Error("Could not remove $pNIC from $self->{switch}".
                              " on host: $self->{hostOpsObj}{hostIP}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
        }
    }
   $vdLogger->Info("Removed $pNIC successfully.");
   return SUCCESS;
}


########################################################################
#								       #
# Method Name: GetvSwitchInfo					       #
#								       #
# Objective: To collect information about a vSwitch		       #
#								       #
# Operation: This method uses the esxcfg-vswitch cmd to do	       #
#            do the task. If no additional parameters are	       #
#            given this method returns all the information	       #
#            about the vSwitch.					       #
#								       #
# input arguments: vSwitch name					       #
#                  parameter (whose info is required)		       #
#                  (The second parameter is single parameter	       #
#                   or list of parameters)			       #
#								       #
# Output: vSwitch details/info					       #
#								       #
# Export Status: Not Exported					       #
#								       #
########################################################################

sub GetvSwitchInfo {
    my $self = shift;
    my (@params) = @_;

    my $vSwitch = $self->{'switch'};

    # An array of possible elements available to get info of
    my @info = qw(mtu prom usedports numports configuredports uplink);

    # Update the contents of object hash
    $self->UpdateHash();

    my $el;
    my %lHash;
    my $size = @params;

    # If no parameters are mentioned send all the info
    if ($size == 0) {
        foreach $el (@info) {
            $lHash{$el} = $self->{$vSwitch}{$el};
        }
    } else {
        # send the info for those parameters
        # which are passed in command line
        foreach $el (@params) {
            if (grep(/$el/,@info)) {
                $lHash{$el} = $self->{$vSwitch}{$el};
            } else {
                $vdLogger->Error("$el is not an valid parameter\n");
                $vdLogger->Error("Please choose one of ", "@info", " \n");
                VDSetLastError("EINVALID");
                return FAILURE;
            }
        }
    }
    return \%lHash;
}


########################################################################
#								       #
# Method Name: AddPortGroupTovSwitch				       #
#								       #
# Objective: To add a port group to vSwitch			       #
#								       #
# Operation: Use the esxcfg-vSwitch command to add the		       #
#            port group to vSwitch using -A switch		       #
#								       #
# input arguments: Name of the Port Group			       #
#								       #
# Output: SUCCESS on success					       #
#         FAILURE on failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub AddPortGroupTovSwitch {
    my $self   = shift;
    my $pgname = shift;
    my $res;

    my $vSwitch = $self->{'switch'};

    # build a command to add a portgroup to vSwitch
    my $command = "esxcfg-vswitch -A $pgname $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

   #
   # Any changes made to network configuration on a esx host using esxcfg-*
   # command does not update/refresh the configuration end to end.
   # So, it is necessary to update the networking configuration manually.
   # For example, adding a portgroup using esxcfg-vswitch command does not
   # get reflected under available network names in any VM.
   #
   $self->HostNetRefresh();

   # Sleep 10 seconds to waiting for new portgroup info sync with VC,fix PR883524
   sleep(10);
   $vdLogger->Debug("Sleep 10 seconds to waiting for refreshing network configuration with VC");

    # Verify if the command is success/failure
    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
	defined $res->{stdout} &&
	$res->{stdout} eq "") {
       $vdLogger->Info("Successfully added a portgroup to vSwitch\n");
       return SUCCESS;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/Already exists/i) {
        $vdLogger->Error("Failed to add portgroup.".
			 " Another portgroup with name $pgname already exists.\n");
        VDSetLastError("EINVALID");
        return FAILURE;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/No such virtual switch/i) {
        $vdLogger->Error("Invalid vSwitch. If you are passing space seperated".
			 " portgroup name,use with in double quotes\n");
        VDSetLastError("EINVALID");
        return FAILURE;

    } else {
        $vdLogger->Error("Failed to add port group to vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: DeletePortGroupFromvSwitch			       #
#								       #
# Objective: To delete a port group from vSwitch		       #
#								       #
# Operation: Use the esxcfg-vSwitch command to delete the	       #
#            port group from vSwitch using -D switch		       #
#								       #
# input arguments: Name of the Port Group			       #
#								       #
# Output: SUCCESS on success					       #
#         FAILURE on failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub DeletePortGroupFromvSwitch {
    my $self   = shift;
    my $pgname = shift;
    my $res;

    my $vSwitch = $self->{'switch'};

    # build a command to delete a portgroup from vSwitch
    my $command = "esxcfg-vswitch -D $pgname $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    # Verify if the command is successful/failure
    if ($res->{rc} == 0 &&
	$res->{exitCode} == 0 &&
	defined $res->{stdout} &&
	$res->{stdout} eq "") {
       $vdLogger->Info("Successfully deleted a portgroup from vSwitch\n");
       return SUCCESS;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/Not found/i) {
        vdLogger->Error("Failed to delete port group.".
			" There is no portgroup: $pgname found.\n");
        VDSetLastError("EINVALID");
        return FAILURE;

    } elsif ($res->{rc} == 0 &&
	     $res->{exitCode} == 0 &&
	     defined $res->{stdout} &&
	     $res->{stdout} =~ m/No such virtual switch/i) {
        vdLogger->Error("If you are passing space seperated".
			" portgroup/vswitch name,use them within double quotes\n");
        VDSetLastError("EINVALID");
        return FAILURE;

    } else {
        $vdLogger->Error("Failed to delete port group from vSwitch\n");
	VDSetLastError("EFAIL");
        return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchUplinkStatus				       #
#								       #
# Objective: To check status of uplink in vSwitch		       #
#								       #
# Operation: Use the UpdateHash to get the vmnics of a		       #
#            vSwitch and check if status of vmnic is up		       #
#            or down using esxcfg-nics command			       #
#            If multiple vmnics are connected to vSwitch	       #
#            return a string with name of the vmnic and		       #
#            status back to back.				       #
#								       #
# input arguments: None						       #
#								       #
# Output: result string on success				       #
#         FAILURE on failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub GetvSwitchUplinkStatus {
    my $self = shift;
    my $res;
    my $ret;
    my $uplink;
    my @vmnics;
    my $command;

    my $vSwitch = $self->{'switch'};

    # Update the contents of object hash
    $self->UpdateHash();

    $uplink = $self->{$vSwitch}{uplink};

    if ($uplink ne "NULL") {
        if ($uplink =~ m/[a-z0-9]+ [a-z0-9]+/i) {
            @vmnics = split(/\s/, $uplink);
        } else {
            $vmnics[0] = $uplink;
        }
    } else {
        vdLogger->Error("There is no uplink on the vSwitch $vSwitch\n");
        VDSetLastError("EFAIL");
        return FAILURE;
    }

    $command = "esxcfg-nics -l";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");
    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       foreach my $el (@vmnics) {
          if ($res->{stdout} =~ m/$el(.*)\n/) {
              my @rets = split(/ +/, $1);
              $ret = $ret."$el-$rets[3] ";
          }
       }

       if ($ret eq "" && $vmnics[0] =~ /nouplink/) {
          $vdLogger->Error("No uplinks found on this vSwitch \n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       return $ret;
    } else {
       $vdLogger->Error("Failed to obtain the vmnics status\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchStats					       #
#								       #
# Objective: To obtain stats of data traffic of vSwitch		       #
#								       #
# Operation: Use the vsish command option to get stats		       #
#								       #
# input arguments: None						       #
#								       #
# Output: Result hash on success				       #
#         FAILURE on failure					       #
#								       #
# Export Status: Exported					       #
#								       #
########################################################################

sub GetvSwitchStats {
    my $self = shift;
    my $res;
    my $command;
    my %result;

    my $vSwitch = $self->{'switch'};

    # Build the command to get the Stats of a vSwitch
    $command = "vsish -e get /net/portsets/$vSwitch/stats";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       my @temp = split(/\n/, $res->{stdout});

       # build a hash of values to return
       foreach my $el (@temp) {
          $el =~ s/^\s+//;
          $el =~ s/\s+$//;
          if (not $el =~ m/{/ || $el eq "}") {
              my @rets = split(/:/, $el);
              $result{$rets[0]} = $rets[1];
          }
       }
       return \%result;
    } else {
       $vdLogger->Error("Failed to obtain the vSwitch stats\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: GetvSwitchNicTeamingPolicy			       #
#								       #
# Objective: To obtain the NIC Teaming Policies for the		       #
#	     given vSwitch					       #
#								       #
# Operation: Use the esxcli command to get the NIC		       #
#            Teaming Policies for the given vSwitch		       #
#								       #
# input arguments: None						       #
# Output: Reference to the Result hash on success		       #
#         FAILURE on failure					       #
#								       #
# Format of the Result hash:					       #
# --------------------------					       #
#	The result hash will have the following			       #
#       format for the key-value pairs:-			       #
#								       #
#  KEY                    |  VALUE(s) (Description)		       #
#  -----------------------|------------------------------	       #
#                         |					       #
#  ActiveAdapters         |  Reference to an array of		       #
#			  |  virtual nics			       #
#                         |(e.g. {vmnic1, vmnic2, vmnic3})	       #
#                         |					       #
#  StandbyAdapters        |  Reference to an array of		       #
#			  |  virtual nics			       #
#                         |(e.g. {vmnic1, vmnic2, vmnic3})	       #
#                         |					       #
#  Failback               |  'true' or 'false'			       #
#                         |					       #
#  LoadBalancing          |  'portid' or 'iphash'		       #
#                         |  'mac' or 'explicit'		       #
#                         |					       #
#  NetworkFailureDetection|  'link' or 'beacon'			       #
#                         |					       #
#  NotifySwitches	  |  'true' or 'false'			       #
#  -----------------------|-------------------------------	       #
#                         |					       #
# Export Status: Exported					       #
#								       #
########################################################################

sub GetvSwitchNicTeamingPolicy {
    my $self = shift;
    my $res;
    my $command;
    my %result;
    my @tmp;
    my @activeAdapters;
    my @standbyAdapters;

    my $vSwitch = $self->{'switch'};

    # Build the command to get the NIC Teaming Policies for
    # for the given vSwitch

    $command = "$ESXCLI_VSWITCH policy failover get -v $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       my @resLines = split(/\n/, $res->{stdout});

       # build a hash of values to return
       # The command above will output the parameters related to all
       # the policies (Security, Traffic Shaping and Failover).
       # But we are interested only in "Failover Policy" related
       # information. Hence will parse the same.

       foreach my $line (@resLines) {
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            @tmp = split(/:/, $line);
            $tmp[1] =~ s/^\s|\s$// if (defined $tmp[1]);
            $result{$tmp[0]} = $tmp[1];
       }

       if (defined $result{"Active Adapters"}) {
	    @activeAdapters = split(/\,\s*/, $result{"Active Adapters"});
	    $result{"ActiveAdapters"} = \@activeAdapters;
        delete $result{"Active Adapters"};
       }

       if (defined $result{"Standby Adapters"}) {
	    @standbyAdapters = split(/\,\s*/, $result{"Standby Adapters"});
	    $result{"StandbyAdapters"} = \@standbyAdapters;
        delete $result{"Standby Adapters"};
       }

       return \%result;

    } else {
       $vdLogger->Error("Failed to obtain the NIC Teaming Policy ".
			"for vSwitch: $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: SetvSwitchNicTeamingPolicy			       #
#								       #
# Objective: To set the NIC Teaming Policies for the		       #
#	     given vSwitch					       #
#								       #
# Operation: Use the esxcli command to set the NIC		       #
#            Teaming Policies for the given vSwitch		       #
#								       #
# input arguments: reference to an input (properties)		       #
#		   hash containing the key-value pairs of	       #
#                  the NIC Teaming Properties to be set.	       #
#		   Format for the same is given below.		       #
#								       #
# Output: SUCCESS on success					       #
#         FAILURE on failure					       #
#								       #
# Format for the input hash:					       #
# --------------------------					       #
#	The input hash will have the following			       #
#       format for the key-value pairs:-			       #
#								       #
#  KEY                    |  VALUE(s) (Description)		       #
#  -----------------------|------------------------------	       #
#                         |					       #
#  ActiveAdapters         |  A string containing list of	       #
#			  |  virtual nics (separated by		       #
#			  |  commas) to be added as the		       #
#			  |  uplink				       #
#                         |(e.g. {vmnic1,vmnic2,vmnic3})	       #
#                         |					       #
#  Failback               |  'true' or 'false'			       #
#                         |					       #
#  LoadBalancing          |  'portid' or 'iphash'		       #
#                         |  'mac' or 'explicit'		       #
#                         |					       #
#  NetworkFailureDetection|  'link' or 'beacon'			       #
#                         |					       #
#  NotifySwitches	  |  'true' or 'false'			       #
#  -----------------------|------------------------------	       #
#                         |					       #
# Export Status: Exported					       #
#								       #
########################################################################

sub SetvSwitchNicTeamingPolicy {
    my $self       = shift;
    my $properties = shift;
    my $options	   = "";
    my $res;
    my $command;
    my %result;
    my @tmp;

    if (not defined $properties) {
       $vdLogger->Error("properties hash not provided");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }

    my $vSwitch = $self->{'switch'};

    foreach my $myKey (keys %{$properties}) {
       if ($myKey =~ m/ActiveAdapters/i && defined $properties->{$myKey}) {
	  $properties->{$myKey} =~ s/\s+//;
	  @tmp = split(/\,/, $properties->{$myKey});
	  foreach my $myAdapter (@tmp) {
	     next if ($self->AddvSwitchUplink($myAdapter) eq "SUCCESS");
             $vdLogger->Error("Failed to set the NIC Teaming Policy ".
                              "for vSwitch: $vSwitch\n");
             VDSetLastError("EFAIL");
             return FAILURE;
	  }

    } elsif ($myKey =~ m/Failback/i  && defined $properties->{$myKey}) {
	  if ($properties->{$myKey} =~ m/yes/i ||
	      $properties->{$myKey} =~ m/true/i) {
	     $options = "$options -b true";
	  } elsif ($properties->{$myKey} =~ m/no/i ||
                   $properties->{$myKey} =~ m/false/i) {
	     $options = "$options -b false";
	  } else {
	     $vdLogger->Debug("Incorrect value specified for NotifySwitches option. ".
			      "Possible values are: true/false");
	  }

       } elsif ($myKey =~ m/LoadBalancing/i && defined $properties->{$myKey}) {
	  if ($properties->{$myKey}  =~ m/portid/ ||
	      $properties->{$myKey} =~ m/iphash/  ||
	      $properties->{$myKey} =~ m/mac/  ||
	      $properties->{$myKey} =~ m/explicit/) {

	     $options = "$options -l $properties->{$myKey}";
	  } else {
	     $vdLogger->Debug("Incorrect value specified for LoadBalancing option. ".
			      "Possible values are: portid/iphash/mac/explicit");
	  }

       } elsif ($myKey =~ m/NetworkFailureDetection/i && defined $properties->{$myKey}) {
	  if ($properties->{$myKey} =~ m/link/i) {
	     $options = "$options -f link";
	  } elsif ($properties->{$myKey} =~ m/beacon/i) {
	     $options = "$options -f beacon";
	  } else {
	     $vdLogger->Debug("Incorrect value specified for NetworkFailureDetection option. ".
			      "Possible values are: link/beacon");
	  }

	   } elsif ($myKey =~ m/NotifySwitches/i && defined $properties->{$myKey}) {
	      if ($properties->{$myKey} =~ m/yes/i ||
	          $properties->{$myKey} =~ m/true/i) {
   	      $options = "$options -n true";
	     } elsif ($properties->{$myKey} =~ m/no/i ||
                $properties->{$myKey} =~ m/false/i) {
	         $options = "$options -n false";
   	  } else {
	         $vdLogger->Debug("Incorrect value specified for NotifySwitches option. ".
		   	       "Possible values are: true/false");
	   }
	   } elsif ($myKey =~ m/standbynics/i && defined $properties->{$myKey}) {
	      $properties->{$myKey} =~ s/\s//g;
   	   $options = "$options -s $properties->{$myKey}";
	   }
   }

    # Build the command to set the NIC Teaming Policies for
    # for the given vSwitch

    $command = "$ESXCLI_VSWITCH policy failover set $options -v $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       $vdLogger->Info("Successful in setting the NIC Teaming Policy ".
                       "for vSwitch: $vSwitch\n");
       return SUCCESS;
    } else {
       $vdLogger->Error("Failed to set the NIC Teaming Policy ".
			"for vSwitch: $vSwitch");
       $vdLogger->Debug(Dumper($res));
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#                                                                      #
# Method Name: SetvSSFailoverOrder                                     #
#                                                                      #
# Objective: To set the failover order for the			       #
#            given vSwitch					       #
#                                                                      #
# Operation: Use the esxcli command to set the			       #
#            failover order for the given vSwitch		       #
#                                                                      #
# input arguments:                                                     #
#  ActiveAdapters         |  Reference to an array of		       #
#                         |  virtual nics in failover order.           #
#                         |(e.g. {vmnic1, vmnic2, vmnic3})	       #
#                         |					       #
#  StandbyAdapters        |  Reference to an array of		       #
#                         |  virtual nics in failover order.(optional) #
#                         |(e.g. {vmnic1, vmnic2, vmnic3})	       #
#                                                                      #
# Output: SUCCESS on success                                           #
#         FAILURE on failure                                           #
#                                                                      #
########################################################################

sub SetvSSFailoverOrder {
    my $self = shift;
    my $activeAdapters = shift;
    my $standbyAdapters = shift;
    my $res = undef;
    my $command  = undef;
    my $vSwitch = $self->{'switch'};

    # Build the command to set the failover order
    # for the given vSwitch
    $command = "$ESXCLI_VSWITCH policy failover set";
    if (defined $standbyAdapters && @$standbyAdapters && $activeAdapters && @$activeAdapters) {
       $command .= " -a ".join( "," , @$activeAdapters ).
                   " -s ".join( "," , @$standbyAdapters ).
                   " -v $vSwitch";
    } elsif (defined $activeAdapters && @$activeAdapters) {
       $command .= " -a ".join( "," , @$activeAdapters ).
                   " -v $vSwitch";
    } else {
       $command .= " -s ".join( "," , @$standbyAdapters ).
                   " -v $vSwitch";
    }
    $vdLogger->Debug("The failover command used is: $command\n");

    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       $vdLogger->Info("Failover order has been set, ".
                       "successfully for vSwitch: $vSwitch\n");
       return SUCCESS;
    } else {
       $vdLogger->Error("Failed to set the given failover order ".
                        "for vSwitch: $vSwitch\n");
       $vdLogger->Error(Dumper($res));
       VDSetLastError("EFAIL");
       return FAILURE;
    }
}


########################################################################
#								       #
# Method Name: ResetvSwitchShaping				       #
#								       #
# Objective: To disable the traffic shaping Policies		       #
#	     for the given vSwitch				       #
#								       #
# Operation: Use the esxcli command to disable the		       #
#            Traffic shaping Policies for given vSwitch		       #
#								       #
# input arguments: None						       #
#								       #
# Output: SUCCESS on success					       #
#         FAILURE on failure					       #
#								       #
########################################################################

sub ResetvSwitchShaping {
    my $self = shift;
    my $res;
    my $command;

    my $vSwitch = $self->{'switch'};

    # Build the command to reset the Traffic Shaping Policies
    # for the given vSwitch

    $command = "$ESXCLI_VSWITCH policy shaping set -e false -v $vSwitch";
    $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                "$command");

    if ($res->{rc} == 0 && $res->{exitCode} == 0) {
       $vdLogger->Info("Traffic Shaping Policies have been disabled, ".
                       "successfully for vSwitch: $vSwitch\n");
       return SUCCESS;
    } else {
       $vdLogger->Error("Failed to disable the Traffic Shaping ".
			"Policies for vSwitch: $vSwitch\n");
       VDSetLastError("EFAIL");
       return FAILURE;

    }
}


########################################################################
#								       #
# Method Name: SetvSwitchShaping				       #
#								       #
# Objective: To enable the traffic shaping Policies		       #
#	     for the given vSwitch				       #
#								       #
# Operation: Use the esxcli command to enable the		       #
#            Traffic shaping Policies for given vSwitch		       #
#								       #
# input arguments: Reference to an "options" hash with		       #
#		   the values for following keys:		       #
#								       #
#		   avg-bandwidth  (in bits/secs)		       #
#		   peak-bandwidth (in bits/secs)		       #
#		   burst-size	  (in bytes)			       #
#								       #
# Output: SUCCESS on success					       #
#         FAILURE on failure					       #
#								       #
########################################################################

sub SetvSwitchShaping {
    my $self = shift;
    my $res;
    my $command;
    my $options = shift;
    my $anchor  = shift;

    my $avgBandwidth  = $options->{'avgbandwidth'};
    my $peakBandwidth = $options->{'peakbandwidth'};
    my $burstSize     = $options->{'burstsize'};

    my $host          = $self->{hostOpsObj}{hostIP};

    if (not defined $avgBandwidth) {
       $avgBandwidth = $options->{'avg-bandwidth'} ||
                       $options->{'avg'}           ||
                       undef;
    }

    if (not defined $peakBandwidth) {
       $peakBandwidth = $options->{'peak-bandwidth'} ||
                   	   $options->{'peak'}           ||
                 	      undef;
    }

    if (not defined $burstSize) {
       $burstSize = $options->{'burst-size'} ||
                    $options->{'burst'}  ||
                 	  undef;
    }

    if ((not defined $avgBandwidth)  ||
         (not defined $peakBandwidth) ||
      	(not defined $burstSize)) {
      $vdLogger->Error("Missing parameter(s). It is mandatory ".
			   "to specify values for all the options ".
			   "(avg-bandwidth/peak-bandwidth/burst-size)");
          VDSetLastError("ENOTDEF");
          return FAILURE;
    }

    my $vSwitch = $self->{'switch'};

    # Build the command to set the given Traffic Shaping Policies
    # for the given vSwitch

   if (not defined $anchor) {
       $command = "$ESXCLI_VSWITCH policy shaping set -e true -b $avgBandwidth ".
		  "-k $peakBandwidth -t $burstSize -v $vSwitch";
       $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                                   "$command");

       if ($res->{rc} == 0 && $res->{exitCode} == 0) {
          $vdLogger->Info("Traffic Shaping Policies have been set, ".
                          "successfully for vSwitch: $vSwitch\n");
          return SUCCESS;
       } else {
          $vdLogger->Error("Failed to set the Traffic Shaping ".
			   "Policies for vSwitch: $vSwitch\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
   } else {
       $vdLogger->Info("Begin to set traffic shaping for $vSwitch");
       $command = " EDITTRAFFICSHAPING ANCHOR $anchor HOST $host ".
          " SWNAME $vSwitch ENABLE Y PEAKBANDWIDTH $peakBandwidth BURSTSIZE $burstSize AVGBANDWIDTH $avgBandwidth";
       $vdLogger->Debug("Run command : $command");
       $res = $self->{stafHelper}->STAFSubmitHostCommand("local", $command);
       if ($res->{rc} != 0) {
          $vdLogger->Error("Failure to set traffic shaping ".Dumper($res));
          VDSetLastError("ESTAF");
          return FAILURE;
       }
       $vdLogger->Info("Set traffic shaping successfully.");
       return SUCCESS;
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
   my $args = shift;
   my (@portId) = ();

   my $displayName = $args->{'displayname'};
   my $all = $args->{'all'} || "N";
   if ($all !~ m/^[YN]$/i) {
      $vdLogger->Error("Incorrect value entered for \"all\" parameter");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vSwitch = $args->{'vswitch'} || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$vSwitch/ports/";
   my $command = "vsish -pe ls $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to list ports under switch $vSwitch");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $portList = $res->{stdout};

   # Parsing the output for PortIDs
   if (defined $portList) {
      my $k = 0;
      my @tmp = split(/\n/,$portList);
      foreach my $i (@tmp) {
         chomp($i);
         $command = "vsish -pe get $path"."$i"."status";
         $res = $self->{stafHelper}->STAFSyncProcess(
                                     $self->{hostOpsObj}{hostIP},
                                     "$command");
         if ($res->{rc} != 0) {
            $vdLogger->Error("Failed to retrieve status of portID $i under ".
                             "switch $vSwitch");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         # Converting the output to a hash
         $res->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $res->{stdout});
         if ($res->{stdout} eq FAILURE) {
            $vdLogger->Error("Unable to parse vsish output of PortID status");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         if ($res->{stdout}->{clientName} =~ m/$displayName/i) {
            $portId[$k] = $i;
            chop($portId[$k]);
            $vdLogger->Info("PortID retrieved for displayName $displayName".
                            " switch $vSwitch = $portId[$k]");
            if ($all =~ m/^N$/i) {
               return $portId[$k];
            }
            $k++;
         }
      }
   }
   if ((scalar @portId) > 0) {
      return \@portId;
   }
   $vdLogger->Error("Failed to retrieve portID under switch $vSwitch for ".
                    "displayName $displayName");
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
   my $args = shift;

   my $portId = $args->{'portid'};
   if (not defined $portId ) {
      $vdLogger->Error("Port ID not defined for GetPortClientStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vSwitch = $args->{'vswitch'} || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$vSwitch/ports/$portId/clientStats";
   my $command = "vsish -pe get $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to get clientStats under switch $vSwitch port".
                       " $portId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $res->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $res->{stdout});
   if ($res->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of NIC stats");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (defined $res->{stdout}) {
      return $res->{stdout};
   }
   $vdLogger->Error("Failed to retrieve clientStats for switch $vSwitch".
                    " port $portId");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#                                                                      #
# GetNumberOfActiveVmnics --                                           #
#      This method gets the number of active pNics for the given       #
#      vswitch.							       #
#                                                                      #
# Input:                                                               #
#      None.                                                           #
#                                                                      #
# Results:                                                             #
#      Returns number of active pNics connected to the given vSwitch.  #
#      "FAILURE", in case of any error                                 #
#                                                                      #
# Side effects:                                                        #
#      none.                                                           #
#                                                                      #
########################################################################

sub GetNumberOfActiveVmnics
{
   my $self    = shift;
   my $command = undef;
   my $result  = undef;

   $command = "$ESXCFG_VSWITCH -x $self->{switch}";
   $result  = $self->{stafHelper}->STAFSyncProcess($self->{host}, $command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (not defined $result->{stdout}) {
      $vdLogger->Error("Failed to retrieve the number of active pNics".
                      " for the vswitch: $self->{switch}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $result->{stdout};
}

########################################################################
#
# HostNetRefresh --
#      Method to refresh networking configuration in a esx host.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the network configuration is refreshed successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub HostNetRefresh
{
   my $self = shift;

   my $command = "vim-cmd hostsvc/net/refresh";

   $vdLogger->Debug("Refreshing network configuration on $self->{host}");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{host},
                                                  $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
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
   my $args = shift;

   my $portId = $args->{'portid'};
   my $param = $args->{'param'};
   if (not defined $portId ||
       not defined $param) {
      $vdLogger->Error("Port ID / Param not defined for GetPortStatus");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vSwitch = $args->{'vswitch'} || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$vSwitch/ports/$portId/status";
   my $command = "vsish -pe get $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to get status under switch $vSwitch port".
                       " $portId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $res->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $res->{stdout});
   if ($res->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of port status");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (defined $res->{stdout}->{$param}) {
      $vdLogger->Info("Value for param $param: $res->{stdout}->{$param}");
      return $res->{stdout}->{$param};
   }
   $vdLogger->Error("Failed to retrieve status for switch $vSwitch".
                    " port $portId param $param");
   VDSetLastError("EFAIL");
   return FAILURE;
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
#               enabled [Mandatory]                                    #
#      vSwitch: Name of the switch from where uplink is to be retrieved#
#               If not defined, default switch name from test hash     #
#               will be used. [Optional]                               #
#                                                                      #
# Results: SUCCESS if successful                                       #
#          FAILURE on failure                                          #
#                                                                      #
########################################################################

sub EnableInputStats {
   my $self = shift;
   my $args = shift;

   my $portId = $args->{'portid'};
   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for EnableInputStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vSwitch = $args->{'vswitch'} || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$vSwitch/ports/$portId/pktSizes/cmd start input";
   my $command = "vsish -pe set $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to enable pktSizes sampling for port".
                       " $portId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
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
   my $args = shift;

   my $portId = $args->{'portid'};
   if (not defined $portId) {
      $vdLogger->Error("Port ID not defined for GetPktSizeInputStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vSwitch = $args->{'vswitch'} || $self->{'switch'};

   # Creating the command
   my $path = "/net/portsets/$vSwitch/ports/$portId/pktSizes/inputStats";
   my $command = "vsish -pe get $path";
   my $res = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP},
                                               "$command");

   if ($res->{rc} != 0) {
      $vdLogger->Error("Failed to get pktSize input stats under switch ".
                       "$vSwitch port $portId");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $res->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $res->{stdout});
   if ($res->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output of pktSize input stats");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $res->{stdout};
}


#############################################################################
#
# CheckAdapterListStatus--
#     Method to check the vmnics status.
#
# Input:
#     vmnicList - The target vmnics
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

sub CheckAdapterListStatus
{
   my $self = shift;
   my $vmnicList = shift;
   my $expStatus = shift;
   my $curStatus = undef;
   my $vSwitch;

   my $switchObj = $self->{switchObj};
   my $result;
   my @uplinks;

   if ((not defined $vmnicList) || (scalar(@$vmnicList) == 0)) {
      $vdLogger->Error("The vmnicList is invalid, not defined or empty");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $vmnicObj (@$vmnicList) {
      $vdLogger->Debug("vmnic : " . Dumper($vmnicObj->{'vmnic'}));
      push(@uplinks, $vmnicObj->{'vmnic'});
   }
   $vSwitch = $self->{switch};
   $vdLogger->Debug("vSwitch name: $vSwitch");

   foreach my $vmnic (@uplinks) {
      $result = $self->CheckAdapterStatus($vSwitch, $vmnic, $expStatus);
      if ($result eq FAILURE) {
         $vdLogger->Error("Fail to check the vmnic $vmnic status");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


#############################################################################
#
# CheckAdapterStatus--
#     Method to check the vmnic status.
#
# Input:
#     vswitch: The name of vswitch
#     vmnic - The name of vmnic
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

sub CheckAdapterStatus
{
   my $self = shift;
   my $vSwitch = shift;
   my $vmnic = shift;
   my $expStatus = shift;
   my $curStatus = undef;
   my $command = "esxcli network vswitch standard policy failover get -v $vSwitch";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostOpsObj}{hostIP}, $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("Unable to retrieve the status of NIC");
      return FAILURE;
   }

   # Parse output
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse esxcli output of NIC status");
      return FAILURE;
   }

   if ($result->{stdout} =~ /Active Adapters: $vmnic/i) {
      $vdLogger->Info("The $vmnic status: active");
      $curStatus = 'active';
   } elsif ($result->{stdout} =~ /Standby Adapters: $vmnic/i) {
      $vdLogger->Info("The $vmnic status: standby");
      $curStatus = 'standby';
   } elsif ($result->{stdout} =~ /Unused Adapters: $vmnic/i) {
      $vdLogger->Info("The $vmnic status: unused");
      $curStatus = 'unused';
   } else {
      $vdLogger->Error("The $vmnic status is invalid, should be active, standby or unused");
      return FAILURE;
   }

   if ($curStatus !~ /$expStatus/i) {
      $vdLogger->Error("Value mismatch for $expStatus Current Value: " .
                    "$curStatus. Expected Value: $expStatus\n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info("The adapter status is as expect");
   return SUCCESS;
}


###############################################################################
#
# RemoveVMKNIC --
#      This method will remove a vmknic with specified vmk id.
#
# Input:
#      Host                 -   ESX host, like SUT or helper2
#      vmkid                -   VMK NIC ID like vmk0, vmk1, etc.
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#
###############################################################################

sub RemoveVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $host = $args{'HOST'};
   my $vmknicid = $args{'DEVICEID'};
   my $anchor  = $args{'ANCHOR'};

   my $cmd;
   my $result;

   if (not defined $host) {
      $vdLogger->Error("host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vmknicid) {
      $vdLogger->Error("vmk NIC not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Begin to remove vmknic - $vmknicid");
   $cmd = " RMVMKNIC ANCHOR $anchor HOST $host ".
          " DEVICEID $vmknicid";
   $vdLogger->Debug("Run command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand("local", $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failure to remove $vmknicid".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Remove vmknic successfully.");
   return SUCCESS;
}

1;
