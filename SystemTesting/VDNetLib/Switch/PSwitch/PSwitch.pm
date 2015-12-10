#######################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::PSwitch::PSwitch;

#
# This package is responsible for handling all the interaction with
# Physical switch devices. The methods in this file are generic and
# not specific to any particular physical switch. Adding a new type
# of physical switch would be easier to integrate. All the switch
# specific stuff is in their respective file.
#
# It can  handle  most of the commonly used physical switch like Cisco,
# Extreme, Netgear, Force10, Foundry, UCS to name a few. It is capable
# of finding the type of physical switch as well since different switches
# have different ways to configure the same thing.
#
# The physical switching device should have at least SSH or Telnet enabled
# before using this package.
#
# For communicating with the physical switch device it uses the
# Net::Appliance::Session CPAN module so that module must be installed
# before using this package.
#


use strict;
use warnings;

use FindBin;
use Data::Dumper;
use Net::Telnet;
use UNIVERSAL::require;
use Net::Appliance::Session;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );

my $supportedSwitches = "CISCO|EXTREME|FORCE10|FOUNDRY|UCSMANAGER";
my %discoveryCmds = (
   EXTREME => "show switch",
   CISCO   => "show version",
);

###############################################################################
#
# new -
#       This package is a entry point for all the physical switch.
#
# Input:
#       Hash containing parameters related to the physical switch.
#
# Results:
#       SUCCESS - A pointer to child instance/object of Verification
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################
sub new
{
    my $class      = shift;
    my %args       = @_;
    my $self;

    # verify the aruguments.
    if (! defined $args{NAME}) {
       $vdLogger->Error("IP address or switch name not defined");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }
    # add a check to make sure the switch ip or switchname is in proper format.

    $self->{username}      = $args{username} || undef;
    $self->{login}         = $args{username} || undef;
    $self->{password}      = $args{password} || undef;
    $self->{switchName}    = $args{NAME};
    $self->{switchType}    = $args{TYPE};
    $self->{prompt}        = $args{PROMPT}  || '[\$%#>] $';  # Default Prompt
    $self->{transport}     = $args{TRANSPORT} || "Telnet";
    $self->{conPersist}    = $args{CONPERSIST} || "N";
    $self->{discover}      = 1;     # By default perform discovery of switch type
    $self->{make}          = undef;
    $self->{series}        = undef; # Series:  e.g SUMMIT, CATALYST etc.
    $self->{modelNumber}   = undef; # Which model no. it is for a particular
                                   # series e.g 3750, 450i etc.
    $self->{interfaceType} = undef; # Gigabit or Fast ethernet
    $self->{sessionObj}    = undef;
    $self->{portMap}       = undef; # Hash with Port No/Interface Type mapping

   #
   # Generic actions on the physical switches.
   #
   $self->{enablePort}        = undef;
   $self->{disablePort}       = undef;
   $self->{getMTUSize}        = undef;
   $self->{setMTUSize}        = undef;
   $self->{reboot}            = undef;
   $self->{addVLAN}           = undef;
   $self->{setPortTrunkMode}  = undef;
   $self->{setPortAccessMode} = undef;
   $self->{enableLLDPGlobalState} = undef;
   $self->{disableLLDPGlobalState} = undef;
   $self->{setLLDPReceiveInterfaceState} = undef;
   $self->{setLLDPTransmitInterfaceState} = undef;
   $self->{getCDPGlobalState} = undef;
   $self->{getCDPInterfaceState} = undef;
   $self->{configurePVLAN}    = undef;
   $self->{removeVLAN}        = undef;
   $self->{disableCDP}        = undef;
   $self->{enableCDP}         = undef;
   $self->{disableCDPOnPort}  = undef;
   $self->{enableCDPOnPort}   = undef;
   $self->{setDefaultInterface} = undef;
   $self->{configure8021QTrunkPort} = undef;
   $self->{configureEtherchannel} = undef;
   $self->{removeEtherchannel} = undef;
   $self->{enableSTP} = undef;
   $self->{disableSTP} = undef;
   $self->{getPortState} = undef;
   $self->{updateNextServer} = undef;
   $self->{verifyNextServer} = undef;

   # Add more actions here.

   #
   # Check if $self->{switchType} is set and contains atleast the
   # switch type we support, if specified correctly then we don't have to
   # figure out which switch it is and hence we set $self->discover to 0
   # otherwise let $self->discover be 1 and dynamically figure out which
   # physical switch it is.
   #
   if(defined $self->{switchType}){
      if($self->{switchType} !~ m/$supportedSwitches/i){
         $vdLogger->Error("the device type $self->{'switchType'} is not a supported switch");
         VDSetLastError("ENODEV")
      } else {
         $self->{discover} = 0;
      }
   }

   if ((not defined $self->{username}) || (not defined $self->{password})) {
      ($self->{username}, $self->{password}) =
                   VDNetLib::Common::Utilities::GetPswitchCredentials($self->{switchName});
      if ((not defined $self->{username}) || (not defined $self->{password})) {
         $vdLogger->Error("Failed to get login credentials for Switch: $self->{switchName}. " .
                          "Please confirm that Switch is up and credentials are set to one of " .
                          "the default username/password.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $self->{login} = $self->{username};
   }
   $vdLogger->Debug("Found the Switch Credentials: $self->{username}/$self->{password}");

   bless($self,$class);

   #
   # extreme switch functions.
   #
   # $self->{"EXTREME"} = {
      # enablePort  => \&Extreme_Summit_Port_Enable,
      # disablePort => \&Extreme_Summit_Port_Disable
   # };

   # Cisco Switch functions.
   $self->{"CISCO"} = {
      setPortTrunkMode  => \&SetPortTrunkMode,
      setPortAccessMode => \&SetPortAccessMode,
      enableLLDPGlobalState => \&EnableLLDPGlobalState,
      disableLLDPGlobalState => \&DisableLLDPGlobalState,
      checkDPInfo                 => \&CheckDiscoveryInfo,
      setInfiniteTimeout=> \&SetInfiniteTimeout,
      getmactable       => \&GetMACTable,
      getphyswitchportsettings   => \&GetPhySwitchPortSettings,
      removeportchannel       => \&RemovePortChannel,
      setvlan       => \&SetVLAN,
      getetherchannelsummary       => \&GetEtherChannelSummary,
      clearlogs => \&ClearLogs,
      getlogs => \&GetLogs,
      updateNextServer => \&UpdateNextServer,
      verifyNextServer => \&VerifyNextServer,
   };

   my %CISCO    = %{ $self->{"CISCO"} };
   my %EXTREME  = (); #%{ $self->{"EXTREME"} };
   my %FORCE10  = (); #%{ $self->{"FORCE10"} };
   my %FOUNDRY  = (); #%{ $self->{"FOUNDRY"} };
   my %UCSMANAGER  = (); #%{ $self->{"UCSMANAGER"} };

   # discover switch type if not specified explicitly.
   if($self->{discover} == 1){
      if($self->discoverSwitchType() ne SUCCESS){
         $vdLogger->Error("Discovery for $self->{switchName} :".
                         " discoverSwitchType failed");
         VDSetLastError("ENODEV");
         return FAILURE;
      }
   } else {
      # check switch type specified by the user.
      if($self->{switchType} =~ m/([A-Z])+_([A-Za-z0-9])+_.+/) {
         my @tmp = split(/_/,$self->{switchType});
         $self->{make} = $tmp[0];
         $self->{series} = $tmp[1];
         $self->{modelNumber} = $tmp[2];
      } else {
         #
         # do nothing, since this will anyway would be
         # take care while doing switch specific initialization.
         #
     }
   }

   # use the library based on the physical switch type.
   if($self->{switchType} =~ m/EXTREME/i){
      my $module = 'VDNetLib::Switch::PSwitch::Extreme';
      $module->require or die $@;
      while ( my ( $k, $v ) = each %EXTREME ) {
         $self->{$k} = $v;
      }
      $self->ExtremeInit();
   } elsif($self->{switchType} =~ m/CISCO/i){
      my $module = 'Net::Appliance::Session';
      $module->require or die $@;
      $module = 'VDNetLib::Switch::PSwitch::Cisco';
      $module->require or die $@;
      while ( my ( $k, $v ) = each %CISCO ) {
         $self->{$k} = $v;
      }
      my $reslt = $self->CiscoInit();
      if (FAILURE eq $reslt) {
         $vdLogger->Error("Failed to initialize cisco switch");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif($self->{switchType} =~ m/FORCE10/i){
      my $module = 'Net::Appliance::Session';
      $module->require or die $@;
      $module = 'VDNetLib::Switch::PSwitch::Force10';
      $module->require or die $@;
      my $result = undef;
      while ( my ( $k, $v ) = each %FORCE10 ) {
         $self->{$k} = $v;
      }
      $result = $self->ForceTenInit();
      if($result eq FAILURE) {
         return FAILURE;
      }
   } elsif($self->{switchType} =~ m/FOUNDRY/i){
      my $module = 'Net::Appliance::Session';
      $module->require or die $@;
      $module = 'VDNetLib::Switch::PSwitch::Foundry';
      $module->require or die $@;
      my $result = undef;
      while ( my ( $k, $v ) = each %FOUNDRY ) {
         $self->{$k} = $v;
      }
      $result = $self->FoundryInit();
      if($result eq FAILURE) {
         $vdLogger->Error("VMKSWITCH : new : Foundry Switch ".
                                    "Initialization Failed.");
         return FAILURE;
      }
   }elsif($self->{switchType} =~ m/UCSMANAGER/i){
      my $module = 'Net::Appliance::Session';
      $module->require or die $@;
      $module = 'VDNetLib::Switch::PSwitch::UCS';
      $module->require or die $@;
      my $result = undef;
      while ( my ( $k, $v ) = each %UCSMANAGER) {
         $self->{$k} = $v;
      }
      $result = $self->UCSInit();
      if($result eq FAILURE) {
         return FAILURE;
      }
   }
   return $self;
}


################################################################################
#
#  EnableLLDPGlobalState
#    Enables the LLDP Global State for the physical switch.
#
#  Input:
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldpglobal state gets enabled.
#
###############################################################################

sub EnableLLDPGlobalState
{
   my $self = shift;
   my %args = @_;
   my $cmd = "lldp run";
   my $result;

   # enable CDP global state.
   $result = SetLLDPGlobalState(CMD => $cmd,
                                SWITCH => $args{SWITCH});
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to enable LLDP Global State");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
#  DisableLLDPGlobalState
#    Disables the LLDP Global State for the physical switch.
#
#  Input:
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldpglobal state gets disabled.
#
###############################################################################

sub DisableLLDPGlobalState
{
   my %args = @_;
   my $cmd = "no lldp run";
   my $result;

   # enable CDP global state.
   $result = SetLLDPGlobalState(CMD => $cmd,
                                SWITCH => $args{SWITCH});
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to disable LLDP Global State");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
#  SetLLDPGlobalState
#     Sets the LLDP Global State for the physical switch.
#
#  Input:
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldpglobal state gets enabled.
#
#  note
#  The method has two modes.
#  1) Persistent Mode: An active session has already been initialized and is
#                      associated with the VMKSWITCH.
#
#  2) Non Persistent Mode: A session object is already created and a connection
#                         to the remote switch already exists.
#
################################################################################

sub SetLLDPGlobalState
{
   my (%args) = @_;
   my $cmd = $args{CMD};
   my $tag = "PSwitch : SetLLDPGlobalState : ";
   my $switchRef = $args{SWITCH};
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $username = $switchRef->{username};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};

   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $cmd) {
      $vdLogger->Error("$tag Status of LLDP to be set is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   eval {
      #
      # If no active session exists then create a new session
      # and connect to the switch.
      #
      if(($switchRef->{conPersist} =~ m/^N$/i)
         and (not defined $sessionObj)){
         $sessionObj = Net::Appliance::Session->new(Host => $switch,
                                                    Transport => $trpt);
         $vdLogger->Info("$tag Session Object created Successfully");
         $sessionObj->connect(Name => $username,
                              Password => $password);
         $vdLogger->Info("$tag Connection to $switch established".
                         " Successfully");
         my $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Info("$tag Entered Privileged EXEC Mode");
         } elsif($currmode =~ m/privileged/) {
            $sessionObj->in_privileged_mode(1);
         } elsif($currmode =~ m/none/) {
            $vdLogger->Error("$tag Connection to $switch established".
                                    " Successfully");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      #
      # If an active session is present check the current mode and traverse to
      # the privileged mode.
      #
      else {
         if (not $sessionObj->in_configure_mode()){
            if(not $sessionObj->in_privileged_mode()) {
               $vdLogger->Info("$tag Entered Privileged Mode");
               $sessionObj->begin_privileged($password);
            }else {
               $sessionObj->in_privileged_mode(1);
            }
         }else {
            end_configure();
         }
      }
      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if(not $sessionObj->in_configure_mode()) {
         $sessionObj->begin_configure();
         $vdLogger->Info("$tag Entered Configured Mode");
      }

      # run command to enable lldp global state.
      $sessionObj->cmd("$cmd");
      $vdLogger->Info("$tag enabling LLDP global state on $switch cmd = $cmd");

      #
      # Exit Global Configuration Mode.
      #
      $sessionObj->end_configure();
      $vdLogger->Info(MSG =>"$tag Exiting Configure Mode");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
      }
   };

   #
   # If any errors occur in any of switch configuration statements in the above
   # eval block they are caught below the corresponding error is Reported.
   #
   if ( $@ ) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag Enabling LLDP global state on switch ".
                       "$switch failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
    }
    $vdLogger->Info("$tag Enabled LLDP global state on switch $switch" );
    return SUCCESS;
}


################################################################################
#
# discoverSwitchType()
#    This method discovers the physical switch type. The info will include
#    the make, model and series of the physical switch.
#
#  Input
#    None
#
#  Results
#    On success, SUCCESS is returned
#    On Failure, FAILURE is returned
#
###############################################################################

sub discoverSwitchType
{
   my $self = shift;
   my $session;
   my $switchName = $self->{switchName};
   my $transport = $self->{transport};
   my $currmode;
   my $password = $self->{password};
   my $status = FAILURE;
   my @output = ();

   #
   # since different switch type might have different commands so try with
   # all possible commands.
   #
   my @discoveryCmd = values(%discoveryCmds);

   # Go through commands for supported switches
   foreach my $cmd (@discoveryCmd) {
      eval {
         $vdLogger->Info("Finding switch make, ".
                         "series and model using command \"$cmd\"");

         $session = Net::Appliance::Session->new(Host => $switchName,
                                                 Transport => $transport);
         $session->connect(Name => $self->{username},
                           Password => $password);
         $currmode = $self->GetCurrentMode(SESSION => $session);
         if ($currmode =~ m/exec/i) {
            $session->begin_privileged($password);
            $vdLogger->Debug("Entered Privileged EXEC Mode");
         } elsif($currmode =~ m/privileged/) {
            $session->in_privileged_mode(1);
         } elsif($currmode =~ m/none/) {
            $vdLogger->Error("Connection to $switchName Failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         @output = $session->cmd("$cmd\r");
      };

      #
      # check if any error occured in the above eval block,
      # there are caught here and reported back.
      #
      if ($@) {
         if(defined $session) {
            $session->close();
         }
      }
      #
      # In each line of the returned output, search for the make, model
      # and series of the specific switch.
      #
      foreach my $out (@output) {
         if ($out =~ m/\d+\s*Gigabit.*/i) {
            $self->{interfaceType} = "GigabitEthernet";
         } elsif (($out =~ m/\d+\s*FastEthernet.*/i) ||
                  ($out =~ m/O2.*10GE\/Modular Supervisor/i)) {
            $self->{interfaceType} = "FastEthernet";
         } elsif (($out =~ m/(\w+)\sIOS Software/i) ||
                  ($out =~ m/(\w+)\sNexus Operating System/i)) {
            $self->{switchType} = $1;
         }
         if (($out =~ m/WS\-(\w+)[\-|\s]/i) ||
             ($out =~ m/cisco\s+(.*)\s+Chassis/i)) {
            $self->{modelNumber} = $1;
         }
      }
      if ((defined $self->{switchType}) && (defined $self->{modelNumber})) {
         # found the swith model
         $status = SUCCESS;
        last;
      } else {
         #
         # Reset the output array
         #
         @output = ();
      }
   }

   if ($status eq SUCCESS) {
      $vdLogger->Info("Physical switch type: $self->{switchType}, ".
                      "model : $self->{modelNumber}");
      return SUCCESS;
   } else {
       $vdLogger->Error("discoverSwitchType : " .
          "unable to figure out switch type");
       return FAILURE;
   }
}


################################################################################
#
# CiscoInit()
#    This method will get the cisco switch configuration details using
#    telnet or ssh.
#
#  Input
#    None
#
#  Results
#    On success, SUCCESS is returned
#    On Failure, FAILURE is returned
#
###############################################################################

sub CiscoInit
{
   my $self = shift;
   my $tag = "PSWITCH : CiscoInit : ";
   my $switch = $self->{switchName};
   my $username = $self->{username};
   my $password = $self->{password};
   my $sessionObj = undef;
   my @output;
   my $cmd;
   my %portMap;
   my $trpt = $self->{transport};
   my $currmode = "none";

   eval {
      #
      # Create a new session
      # and connect to the switch.
      #
      $sessionObj = Net::Appliance::Session->new(Host => $switch,
                                                 timeout => 300,
                                                 Transport => $trpt);
      $vdLogger->Debug("$tag Session Object Created");
      #
      # Connecting to the switch
      #
      $sessionObj->connect(Name => $username,
                           Password => $password,
                           SHKC => 0
                           );
      $vdLogger->Info("$tag Connection to $switch established".
                              " Successfully");
      #
      # Getting the Current Mode of the switch.
      #
      $currmode = $self->GetCurrentMode(SESSION => $sessionObj);
      if ($currmode =~ m/exec/i) {
         $sessionObj->begin_privileged($password);
         $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
      } elsif($currmode =~ m/privileged/) {
         $vdLogger->Debug("$tag Already in Privileged Mode");
         $sessionObj->in_privileged_mode(1);
      } elsif($currmode =~ m/none/) {
         $vdLogger->Error("$tag Entered Invalid Mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      #
      # Display the version information with "show version" command
      # and get the interface type (gigabit Ethernet/fast Ethernet).
      #
      @output = $sessionObj->cmd("show version");
      foreach my $out (@output) {
         if ($out =~ m/\d+\s*Gigabit.*/i) {
            $self->{interfaceType} = "GigabitEthernet";
         } elsif ($out =~ m/\d+\s*FastEthernet.*/i) {
            $self->{interfaceType} = "FastEthernet";
         } elsif ($out =~ m/WS\-(\w+)[\-|\s]/i or
                  $out =~ m/cisco\s+(.*)\s+Chassis/i) {
            $self->{modelNumber} = $1;
         } else {
            next;
         }
      }
      $vdLogger->Debug("Physical switch model : $self->{modelNumber}");
      $vdLogger->Debug("Physical interface type : " . $self->{interfaceType} ?
                       $self->{interfaceType} : "not defined");
      #
      # Listing the Interfaces
      #
      if($self->{modelNumber} =~ /Nexus/i) {
         $sessionObj->cmd("terminal len 0");
         $cmd = "show interface";
         @output = $sessionObj->cmd('string' => $cmd, 'timeout' => 300);
      }else{
         $cmd = "show interfaces";
         @output = $sessionObj->cmd($cmd);
      }

      #
      # Find the interface type with the command "show interface(s)"
      # Sample output for the command show interface is as follows
      # '
      # vfc4 is up
      # Bound interface is Ethernet1/4
      # Hardware is Virtual Fibre Channel
      # ......
      # vfc5 is down
      # Bound interface is Ethernet1/5
      # Hardware is Virtual Fibre Channel
      # ......
      #'
      #
      foreach my $line (@output) {
         if ($line =~ m/^vfc([\d+\/]+)/) {
            my $tmp = $1;
            $portMap{$tmp} = "vfc";
         } elsif ($line =~ m/^fc([\d+\/]+)/) {
            my $tmp = $1;
            $portMap{$tmp} = "fc";
         }  elsif ($line =~ m/^GigabitEthernet(\d+\/\d+\/\d+)/) {
            my $tmp = $1;
            $portMap{$tmp} = "GigabitEthernet";
         } elsif ($line =~ m/^GigabitEthernet(\d+\/\d+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "GigabitEthernet";
         } elsif ($line =~ m/^FastEthernet(\d+\/\d+\/\d+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "FastEthernet";
         } elsif ($line =~ m/^FastEthernet(\d+\/\d+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "FastEthernet";
         } elsif ($line =~ m/^TenGigabitEthernet(\d+\/\d+\/\d+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "TenGigabitEthernet";
         } elsif ($line =~ m/^TenGigabitEthernet(\d+\/\d+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "TenGigabitEthernet";
         } elsif ($line =~ m/^Ethernet([\d+\/]+)/i) {
            my $tmp = $1;
            $portMap{$tmp} = "Ethernet";
         } else {
            next;
         }
      }

      # initialize the portmap.
      $self->{portMap} = \%portMap;
      if($self->{conPersist} =~ m/^N$/i) {
         $sessionObj->close();
         $self->{sessionObj}= undef;
      }else {
         $self->{sessionObj}= $sessionObj;
      }
      $self->{setInfiniteTimeout}(SWITCH => $self);
   };

   #
   # If any errors occur in any of switch configuration statements in the above
   # eval block. They are caught below and the corresponding error is Reported.
   #
   if ($@) {
      $self->ReportError($@);
      $vdLogger->Error("$tag $@");
      $vdLogger->Error("$tag Cisco Switch Initialization failed");
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      return FAILURE;
   }
   $vdLogger->Debug("$tag Cisco Switch Initialization success");
   $vdLogger->Debug("$tag Switch:$self->{switchName}");
   $vdLogger->Debug("$tag Login:$self->{username}");
   return SUCCESS;
}


###############################################################################
#
# ReportError()
#    This method will report the error messages based on the failures from
#    Net::Appliance::Session module.
#
#  Input
#    None
#
#  Results
#    On success, SUCCESS is returned
#    On Failure, FAILURE is returned
#
###############################################################################

sub ReportError {
   my $self = shift;
   #
   # standard subroutine used to extract failure info when
   # interactive session fails
   #
   my $err         = shift;
   my $device_name = $self->{switchName};

   if (! defined $err) {
      $vdLogger->Error("Error message not define");
      #
      return FAILURE;
   }
   my $report; # holder for report message to return to caller

   if ( UNIVERSAL::isa($err, 'Net::Appliance::Session::Exception') ) {
      #
      # fault description from Net::Appliance::Session
      #
      $report  =  "We had an error during our Telnet/SSH session to device  " .
                  ": $device_name \n";
      $report .= $err->message . " \n";

      #
      # message from Net::Telnet
      #
      $report .= "Net::Telnet message : " . $err->errmsg . "\n";

      #
      # last line of output from your appliance
      #
      $report .=  "Last line of output from device : " . $err->lastline . "\n\n";

   } elsif (UNIVERSAL::isa($err, 'Net::Appliance::Session::Error') ) {
      #
      # fault description from Net::Appliance::Session
      #
      $report  = "We had an issue during program execution to device : " .
                 "$device_name \n";
      $report .=  $err->message . " \n";
   } else {
      #
      # we had some other error that wasn't a deliberately created exception
      #
      $report  = "We had an issue when accessing the device : $device_name \n";
      $report .= "The reported error was : $err \n";
   }
   $vdLogger->Error($report);
   return SUCCESS;
}


###############################################################################
#
#  GetCurrentMode()
#    This methode will get the current operational mode of the switch. This is
#    needed to check where we are, currently either in exec mode, enable mode,
#    config mode etc. etc.
#
#  Input
#    None
#
#  Results
#    If the current mode is determined then returns the mode name
#    if not then returns the "none"
#
#  note
#  This command enters an empty string and retrives the last_prompt parameter
#  of the hash net_telnet of the session Object.
#
###############################################################################

sub GetCurrentMode
{
   my ($self,%args)=@_;
   my $sessionObj = $args{SESSION} || $self->{sessionObj};
   my $mode = "none";
   my $tag = "PSWITCH : GetCurrentMode: ";

   if (! defined $sessionObj) {
      $vdLogger->Error("$tag session object not defined");
      return FAILURE;
   }

   #
   # Enter an Empty Command.
   #
   eval {
      my $match = $sessionObj->cmd("");
      my $s = *$sessionObj->{net_telnet};
      my $configprmpt = '\(config[^)]*\)# ?$';
      my $ifaceprmpt = '\(config\-if\)\s*#$';
      my $vlanprmpt = '\(config\-vlan\)\s*#$';
      my $lineprmpt = '\(config\-line\)\s*# ?$';
      my $localmgmtprmpt = '\(local\-mgmt\)\s*#\s*$';
      if($s->{last_prompt} =~ m/$vlanprmpt/i) {
         $mode = "vlan";
      }elsif($s->{last_prompt} =~ m/$localmgmtprmpt/i) {
         $mode = "localmgmt";
      }elsif($s->{last_prompt} =~ m/$lineprmpt/i) {
         $mode = "line";
      }elsif($s->{last_prompt} =~ m/$ifaceprmpt/i) {
         $mode = "interface";
      }elsif($s->{last_prompt} =~ m/$configprmpt/i) {
         $mode = "configure";
      }elsif($s->{last_prompt} =~ m/# ?$/i) {
         $mode = "privileged";
      }elsif($s->{last_prompt} =~ m/> ?$/i) {
         $mode = "exec";
      }
   };

   #
   # If any errors occur in Session::cmd statement in the above
   # eval block they are caught below and the corresponding error is Reported.
   #
   if ( $@ ) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $vdLogger->Error("$tag $@");
      $vdLogger->Error("$tag Failed to retrieve current Mode");
      return "none";
   }
   return $mode;
}


#######################################################################
#
# GetPortMap --
#      This method is used to return port map
#
# Input:
#       none
#
# Result:
#      port map value is returned stored in the pswitch
#
# Side effects:
#      None
#
########################################################################

sub GetPortMap
{
   my $self = shift;
   return $self->{portMap};
}


################################################################################
#
#  RemovePortChannel(%args)
#  Remove port-channel from a physical switch
#
#  Input:
#   PORTCHANNEL  port-channel number
#   SWITCH switch object reference
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
   my ($self, %args) = @_;
   my $portChannel = $args{PORTCHANNEL};
   my $switchRef = $args{SWITCH};
   my $tag = "PSWITCH : RemovePortChannel :";

   if (! defined $portChannel) {
      $vdLogger->Error("$tag port-channel on the physical switch not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @commands = ("no interface port-channel $portChannel");

   my $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS" ) {
      $vdLogger->Info("$tag remove Channelgroup $portChannel successful");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag remove Channelgroup $portChannel ".
                       "failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

################################################################################
#
#  ExecuteCMDOnPSwitch(%args)
#  Execute command on a specified Cisco Switch.
#
#  Input:
#   SWITCH switch object reference
#   CMD    reference to an array
#   TAG    call functional info
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub ExecuteCMDOnPSwitch
{
   my ($self, %args) = @_;
   my $switchRef = $args{SWITCH};
   my $tag = $args{TAG} || "ExecuteCMDOnPSwitch";
   my $commands = $args{CMD};
   my $mode = $args{MODE} || undef;
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $username = $switchRef->{username};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};
   my $resultHash;

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
  eval {
      #
      # If no active session exists then create a new session
      # and connect to the switch.
      #
      if(($switchRef->{conPersist} =~ m/^N$/i)
         and (not defined $sessionObj)){
         $sessionObj = Net::Appliance::Session->new(Host => $switch,
                                                    Transport => $trpt);
         $vdLogger->Trace("$tag Session Object created Successfully");
         $sessionObj->connect(Name => $username,
                              Password => $password);
         $vdLogger->Trace("$tag Connection to $switch established".
                         " Successfully");
         my $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Trace("$tag Entered Privileged EXEC Mode");
         } elsif($currmode =~ m/privileged/) {
            $sessionObj->in_privileged_mode(1);
         } elsif($currmode =~ m/none/) {
            $vdLogger->Error("$tag Connection to $switch established".
                                    " Successfully");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      #
      # If an active session is present check the current mode and traverse to
      # the privileged mode.
      #
      else {
         if (not $sessionObj->in_configure_mode()){
            if(not $sessionObj->in_privileged_mode()) {
               $vdLogger->Debug("$tag Entered Privileged Mode");
               $sessionObj->begin_privileged($password);
            }else {
               $sessionObj->in_privileged_mode(1);
            }
         }else {
            end_configure();
         }
      }
      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if ((defined $mode) && ($mode =~ /privileged/i)) {
         # Do not enter into configure mode
      } else {
         if(not $sessionObj->in_configure_mode()) {
            $sessionObj->begin_configure();
            $vdLogger->Trace("$tag Entered Configured Mode");
         }
      }
      #
      # Execute command on switch.
      #

      foreach my $cmd (@$commands) {
         $vdLogger->Debug("CMD:$cmd");
         # This method returns result if the result is stored in
         # array. perl wantarray will be 1
         my @resultArry = $sessionObj->cmd("$cmd");
         $resultHash->{"$cmd"} = \@resultArry;
      }

      #
      # Exit Global Configuration Mode.
      #
      $sessionObj->end_configure();
      $vdLogger->Trace(MSG =>"$tag Exiting Configure Mode");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
      }
   };

   #
   # If any errors occur in any of switch configuration statements in the above
   # eval block they are caught below the corresponding error is Reported.
   #
   if ( $@ ) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag command on switch $switch failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $resultHash, SUCCESS;
}

1;

