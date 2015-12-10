#######################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Switch::PSwitch::PSwitch;
use strict;
use warnings;

use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT
                                      $sessionSTAFPort);

#
# module to handle all the cisco physical switch related methods.
#
#


################################################################################
#  CheckDiscoveryInfo(%args)
#   Get Info about neighbors using LLDP or CDP.
#
#  Input:
#   SWITCH switch object reference.
#   A hash containing info about the pnic which is connected to this switch.
#   VMNICOBJ A hash containing information about the pnic.
#   PROTOCOL Specifying which protocol to be used.
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   none.
#
#  note
#  The method has two modes.
#  1) Persistent Mode: An active session has already been initialized and is
#                      associated with the VMKSWITCH.
#
#  2) Non Persistent Mode: A session object is already created and a connection
#                         to the remote switch already exists.
###############################################################################

sub CheckDiscoveryInfo
{
   my (%args) = @_;
   my $tag = "PSWITCH : CheckDiscoveryInfo :";
   my $switchRef = $args{SWITCH};
   my $vmnicObj = $args{VMNICOBJ};
   my $protocol = $args{PROTOCOL} || "lldp";
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};
   my $currmode = undef;
   my $cmd;
   my $interfaceType;
   my $port;
   my @output = ();

   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vmnicObj) {
      $vdLogger->Error("$tag Information about pnic is not passed ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $port = $vmnicObj->{switchPort};
   $interfaceType = $switchRef->{portMap}->{$port};

   # login to switch to get the info lldp info.
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
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Info("$tag Connection to $switch established".
                                 " Successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
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
               $vdLogger->Info("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }

      # run the command to get the dp info
      if ($protocol =~ m/lldp/i) {
         $cmd = "show lldp entry *";
      } else {
         $cmd = "show cdp entry *";
      }

      @output = $sessionObj->cmd("$cmd");
      $vdLogger->Info("$tag $cmd on switch $switch");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
         $vdLogger->Info("$tag Session to $switch closed.");
      }
   };

   #
   # check if any error occured in the above eval block,
   # there are caught here and reported back.
   #
   if ($@) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag Failure while checking LLDP info on switch ".
                       "$switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # now verify that information is correct.
   $vdLogger->Info("$tag Displaying the $protocol output from switch $switch..");
   foreach my $info(@output) {
      $vdLogger->Debug("$info");
   }
   $vdLogger->Debug("$tag $protocol output from $switch ends");

   # verify the pnic name,
   my $regex;
   if ($protocol =~ m/lldp/i) {
      $regex = "Chassis id: " . $vmnicObj->{vmnic};
   } else {
      $regex = "Interface: ".$interfaceType.$port.",";
   }
   $vdLogger->Debug("Regex used to check CDP: $regex");

   foreach my $line (@output) {
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      if($line =~ /$regex/i) {
         $vdLogger->Info("The $protocol info is correct for portId in ".
                         "switch $switch");
         return SUCCESS;
      }
   }
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


################################################################################
#
# GetPhySwitchPortSettings --
#   Get settings for the given Physical Switch Port.
#
#  Input:
#   SWITCH : switch object reference.
#   PORT   : Physical Switch Port ID.
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   none.
#
###############################################################################

sub GetPhySwitchPortSettings
{
   my $tag	 = "PSWITCH : GetPhySwitchPortSettings :";
   my (%args)	 = @_;
   my $switchRef = $args{SWITCH};
   my $sessionObj= $switchRef->{sessionObj};
   my $switch	 = $switchRef->{switchName};
   my $login	 = $switchRef->{login};
   my $password	 = $switchRef->{password};
   my $trpt	 = $switchRef->{transport};
   my $currmode	 = undef;
   my $cmd;
   my @output	 = ();

   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Warn("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # login to switch to get the port Settings info.
   eval {
      #
      # If no active session exists then create a new session
      # and connect to the switch.
      #
      if(($switchRef->{conPersist} =~ m/^N$/i)
         and (not defined $sessionObj)){
         $sessionObj = Net::Appliance::Session->new(Host => $switch,
                                                    Transport => $trpt);
         $vdLogger->Debug("$tag Session Object created Successfully");
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Debug("$tag Connection to $switch established".
                                 " Successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
         } elsif($currmode =~ m/privileged/) {
            $sessionObj->in_privileged_mode(1);
         } elsif($currmode =~ m/none/) {
            $vdLogger->Warn("$tag Connection to $switch could not be established");
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
               $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }

      $cmd = "show running-config full";

      @output = $sessionObj->cmd("$cmd");
      $vdLogger->Debug("$tag Running Command : $cmd on switch : $switch");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
         $vdLogger->Debug("$tag Session to $switch closed.");
      }
   };

   #
   # check if any error occured in the above eval block,
   # there are caught here and reported back.
   #
   if ($@) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Warn("$tag Failure while getting port settings nfo on switch ".
                       "$switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (@output) {
      return \@output;
   } else {
      return FAILURE;
   }
}


################################################################################
#  SetInfiniteTimeout(%args)
#   Set Infinite Timeout for the session
#
#  Input
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   none.
#
#
################################################################################

sub SetInfiniteTimeout
{
   my (%args) = @_;
   my $tag = "PSWITCH : SetInfinteTimeout :";
   my $switchRef = $args{SWITCH};
   if (! defined $switchRef) {
      $vdLogger->Error("$tag Switch object reference not found");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $sessionObj = $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};
   my $currmode = "none";
   eval {
      #
      # If no active session exists then create a new session
      # and connect to the switch. By default if the connection is via SSH then
      # the login mode is priveleged mode. If the connection is via Telnet then
      # the default login mode is EXEC mode.
      #
      if(($switchRef->{conPersist} =~ m/^N$/i)
         and (not defined $sessionObj)){
         $sessionObj = Net::Appliance::Session->new(Host => $switch,
                                                    Transport => $trpt);
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Debug("$tag Session Object created successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if($currmode =~ m/none/){
            die "Invalid Mode";
         }
         if($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($switchRef->{password});
            $vdLogger->Debug("$tag Entered Privileged Mode");
         }else {
            $vdLogger->Debug("$tag Already in Privileged Mode");
            $sessionObj->in_privileged_mode(1);
         }
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if($currmode !~ m/privileged/i) {
            $vdLogger->Error("Not in Privileged Mode");
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
               $vdLogger->Debug("$tag Already in Privileged Mode");
            }
         }
      }
      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
      if($currmode =~ m/none/i) {
          $vdLogger->Error("Invalid mode");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }
      $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
      if($currmode =~ m/privileged/i) {
         $sessionObj->begin_configure();
      }else {
         $sessionObj->in_configure_mode(1);
      }
      $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
      if($currmode !~ m/configure/i) {
         $vdLogger->Error("Not in Privileged Mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("$tag Entered Configured Mode");
      #
      # Entering Interface Mode.
      #
      my $cmd ;
      # PR 1211139
      if($switchRef->{modelNumber} =~ m/Nexus/i) {
         $cmd = "line vty";
      } else {
         $cmd = "line vty 0 15";
      }
      $sessionObj->cmd($cmd);
      $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
      if($currmode !~ m/line/i) {
         $vdLogger->Error("Not in Virtual terminal line Mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("$tag Entered Virtual Terminal Mode");
      $vdLogger->Debug("$tag Set Infinite Virtual Terminal Timeout");
      if($switchRef->{modelNumber} =~ m/Nexus/i) {
         $cmd = "exec-timeout 0";
      } else {
         $cmd = "exec-timeout 0 0";
      }
      $sessionObj->cmd($cmd);

      #PR 1211139 NEXUS switch should exit from config-line mode
      if($switchRef->{modelNumber} =~ m/Nexus/i) {
         $sessionObj->cmd("exit");
      }
      $sessionObj->end_configure();
      $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
      if($currmode !~ m/privileged/i) {
         $vdLogger->Error("$tag Not in Privileged Mode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
      }
   };
   if ( $@ ) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $vdLogger->Error("$tag $@");
      $vdLogger->Error("$tag Setting Infinite Timeout Failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("$tag Infinite Timeout set successfully");
   return SUCCESS;
}


################################################################################
#  SetMTUSize
#  Set the MTU size for the cisco switch.
#
#  Input:
#   SWITCH switch object reference
#   PORT port number where MTU has to be set.
#   MTU  size of the MTU
#
#  Results
#   If mtu is set on the switch port SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:
#   MTU gets set on the switch port.
#
################################################################################

sub SetMTUSize
{

   # TO BE DONE.

}


################################################################################
#  SetVLAN
#  Add / remove a specific vlan id from the Cisco switch database.
#
#  Input:
#   ACTION Add/remove the vlan id
#   SWITCH switch object reference
#   VLAN vlan id to be added to cisco switch database.
#
#  Results
#   If vland id gets set / removed from the switch DB, returns SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:
#   vlan id gets added / removed from the switch database.
#
################################################################################

sub SetVLAN
{
   my (%args) = @_;
   my $action = $args{ACTION};
   my $switchRef = $args{SWITCH};
   my $vlan = $args{VLAN};
   my $tag = "PSWITCH : SetVLAN :";

   # Parsing the vlan param for values passed
   $vlan =~ s/\_/\,/g;
   $vlan =~ s/to/\-/g;

   # Checking validity of the values passed
   my @contents = split (/,/,$vlan);
   foreach my $value (@contents) {
      if ($value !~ m/(\d+)-(\d+)/) {
         if ($value !~ m/(\d+)/) {
            $vdLogger->Error("Error in entering VLAN values in test hash");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }

   if (($action !~ /add/i) &&
       ($action !~ /remove/i)) {
      $vdLogger->Error("Error in entering action values in test hash");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @commands;
   #
   # Enter mode to configure VLAN
   #
   if ($action =~ /add/i) {
      @commands = ("vlan $vlan");
      $vdLogger->Info("$tag adding vlan".
                      " $vlan to the DB");
   } else {
      @commands = ("no vlan $vlan");
      $vdLogger->Info("$tag removing vlan".
                      " $vlan from the DB");
   }
   my $result = $switchRef->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                    CMD => \@commands,
                                    TAG => $tag);
   if ($result == SUCCESS ) {
      $vdLogger->Info("$tag setting VLAN properties on phsyical switch successful" );
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag setting VLAN properties on physical switch ".
                       "failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#  SetPortTrunkMode
#  set a specific port in trunk mode.
#
#  Input:
#   SWITCH      switch object reference
#   VlanRange   parameters to specify a list of comma separate vlan id's.
#               if nothing is specied then it allows all the vlan id's
#               for that specific port.
#   NativeVlan  parameters to specify native vlan for a specific port.
#               default is 1
#   PORT        switch port where trunk vlan has to be set.
#
#  Results
#   on success returns SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:
#   the port is set into vlan trunking mode.
#

sub SetPortTrunkMode
{

   my (%args)    = @_;
   my $tag       = "PSWITCH : SetPortTrunkMode :";
   my $switchRef = $args{SWITCH};
   my $port      = $args{PORT};
   my $nativevlan    = $args{NATIVEVLAN};
   my $vlanrange     = $args{VLANRANGE};
   my $mtu           = $args{mtu};
   my $sessionObj    = $switchRef->{sessionObj};
   my $switch        = $switchRef->{switchName};
   my $login         = $switchRef->{login};
   my $password      = $switchRef->{password};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $trpt          = $switchRef->{transport};
   my $model         = $switchRef->{modelNumber};
   my $currmode      = undef;

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
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
         $vdLogger->Debug("$tag Session Object created Successfully");
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Info("$tag Connection to $switch established".
                                 " Successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
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
               $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }
      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if(not $sessionObj->in_configure_mode()) {
         $sessionObj->begin_configure();
         $vdLogger->Debug("$tag Entered the Global Configuration Mode");
      }
      #
      # clear all the pre-set
      #
      $sessionObj->cmd("default interface $interfaceType $port");
      #
      # Enter the Interface Configuration Mode.
      #
      $sessionObj->cmd("interface $interfaceType $port");
      $vdLogger->Info("$tag Configuring Interface $interfaceType $port");

      $mtu = (defined $mtu) ? $mtu : "9000";
      #
      # set trunk mode
      #
      if ($model =~ /4948|3750/){
         $sessionObj->cmd("switchport trunk encapsulation dot1q");
      }
      $sessionObj->cmd("switchport mode trunk");
      $sessionObj->cmd("no shutdown");
      if (defined $nativevlan){
         $vdLogger->Info("$tag set native vlan to $nativevlan");
         $sessionObj->cmd("switchport trunk native vlan $nativevlan");
      }
      if (defined $vlanrange){
         $vdLogger->Info("$tag set vlan range to $vlanrange");
         $sessionObj->cmd("switchport trunk allowed vlan $vlanrange");
      }
      $vdLogger->Info("$tag set port $port to trunk mode");
      if($model =~ /4948/){
         $vdLogger->Info("$tag set mtu to $mtu");
         $sessionObj->cmd("mtu $mtu");
      }
      #
      # Exit Global Configuration Mode.
      #
      $sessionObj->end_configure();
      $vdLogger->Info("$tag Exited Configure Mode");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
         $vdLogger->Info("$tag Session to $switch closed.");
      }
   };

   #
   # check if any error occured in the above eval block,
   # there are caught here and reported back.
   #
   if ($@) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag Can't set port $port to trunk mode on switch $switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag set port $port to trunk mode on switch $switch.");
   return SUCCESS;

}


################################################################################
#  SetPortAccessMode
#   set the port to with a access vlan.
#
#  parameters:
#   SWITCH      switch object reference
#   PORT        switch port to get the vlan mode for.
#   VLANID      vlan id
#
#  return
#   on success returns SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:
#   the port is set into access mode.
#

sub SetPortAccessMode
{

   my (%args)    = @_;
   my $tag       = "PSWITCH : SetPortAccessMode :";
   my $switchRef = $args{SWITCH};
   my $port      = $args{PORT};
   my $vlanid    = $args{VLANID};
   my $sessionObj    = $switchRef->{sessionObj};
   my $switch        = $switchRef->{switchName};
   my $login         = $switchRef->{login};
   my $password      = $switchRef->{password};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $trpt          = $switchRef->{transport};
   my $model         = $switchRef->{modelNumber};
   my $currmode      = undef;

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
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
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Info("$tag Connection to $switch established".
                                 " Successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
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
               $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }
      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if(not $sessionObj->in_configure_mode()) {
         $sessionObj->begin_configure();
         $vdLogger->Debug("$tag Entered the Global Configuration Mode");
      }
      #
      # clear all the pre-set commands
      #
      $sessionObj->cmd("default interface $interfaceType $port");
      #
      # Enter the Interface Configuration Mode.
      #
      $sessionObj->cmd("interface $interfaceType $port");
      $vdLogger->Info("$tag Configuring Interface $interfaceType $port");
      #
      # Disable the port by shutting down the interface.
      #
      $sessionObj->cmd("switchport mode access");
      $sessionObj->cmd("switchport access vlan $vlanid");
      $sessionObj->cmd("no shutdown");
      $vdLogger->Info("$tag set port $port to access mode,access vlan $vlanid");
      #
      # Exit Global Configuration Mode.
      #
      $sessionObj->end_configure();
      $vdLogger->Info("$tag Exited Configure Mode");
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
         $vdLogger->Info("$tag Session to $switch closed.");
      }
   };

   #
   # check if any error occured in the above eval block,
   # there are caught here and reported back.
   #
   if ($@) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag Can't set port $port to access mode on switch $switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag set port $port to access mode on switch $switch.");
   return SUCCESS;
}



########################################################################
#
# GetMACTable --
#      Method to retrieve the mac-address-table information.
#
# Input:
#      Reference to switch hash with following keys:
#      SWITCH - reference to switch hash (Required)
#      VMNICOBJ - reference to VMNic NetAdapter object (Optional)
#
# Results:
#      Reference to an array having every line of mac address table;
#      FAILURE in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetMACTable
{
   my (%args) = @_;
   my $tag = "PSWITCH : GetMACTable :";
   my $switchRef = $args{SWITCH};
   my $vmnicObj = $args{VMNICOBJ};
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};
   my $currmode = undef;
   my @output = ();

   #
   # TODO: remove the following block establishing connection if it can be
   # moved to new()
   #
   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
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
         $sessionObj->connect(Name => $login,
                              Password => $password);
         $vdLogger->Info("$tag Connection to $switch established".
                                 " Successfully");
         $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
         if ($currmode =~ m/exec/i) {
            $sessionObj->begin_privileged($password);
            $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
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
               $vdLogger->Debug("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }

      my $retry = 0;
      my $vmnicPort;
      #
      # When a virtual nic changes port from A to B (even with Notify Switches
      # set to yes), it takes sometime for the mac address to appear on Port B.
      # So, retrying thrice to ensure enough time is given for the change.
      #
      while ($retry < 3) {
         my $command = "show mac-address-table";

         # run the command to get the mac info
         #
         # If vmnicObj is defined, the switchPort information can be obtained.
         # This can be used as a filter for the list of entries in the mac
         # address table. If full mac list is needed, then vmnicObj should not
         # be defined.
         #
         if (defined $vmnicObj) {
            if (not defined $vmnicPort) {
               $vmnicPort = $vmnicObj->{switchPort};
               my $intType = $switchRef->{portMap}->{$vmnicPort};
               $vmnicPort = "$intType" . "$vmnicPort";
               $vdLogger->Info("$tag Port id to be used:$vmnicPort");
            }
            # search for the specific port id in mac address table
            $command = $command . " in $vmnicPort";
         }

         $vdLogger->Info("$tag $command on switch $switch");
         @output = $sessionObj->cmd($command);

         $vmnicPort = (defined $vmnicPort) ? $vmnicPort : "";
         my $found = 0;
         foreach my $line (@output) {
            if ($line =~ /STATIC|DYNAMIC/i) {
               #
               # At least one line in the output should
               # have the valid entry.
               #
               $found = 1;
               last;
            }
         }

         if (!$found) {
            $vdLogger->Info("$tag Port $vmnicPort not found, retrying in 20 secs");
            sleep(20);
         } else {
	    last;
	 }
         $retry++; # reduce the count left for retry.
      }
      if($switchRef->{conPersist} =~ m/^N$/i) {
         $switchRef->{sessionObj} = undef;
         $sessionObj->close();
         $vdLogger->Info("$tag Session to $switch closed.");
      }
   };

   #
   # check if any error occured in the above eval block,
   # there are caught here and reported back.
   #
   if ($@) {
      if(defined $sessionObj) {
         $sessionObj->close();
      }
      $switchRef->ReportError($@);
      $vdLogger->Error("$tag Failure to get mac address table info on switch ".
                       "$switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return \@output;
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
   my %args = @_;
   my $switchRef = $args{switch};
   my $tag = "PSWITCH:GetEtherChannelSummary:";
   my $cmd = "show etherchannel summary";
   my @commands = ($cmd);
   my ($data, $result) = $switchRef->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                              CMD => \@commands,
                                              TAG => $tag,
                                              MODE => "privileged");
   if ($result eq SUCCESS) {
      my $dataArray =  $data->{$cmd};
      return $dataArray;
   } else {
      $vdLogger->Error("$tag failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  ClearLogs
#     clear the pswitch log buffer
#
#  Input:
#     None
#
#  Results
#     SUCCESS - in case of success
#     FAILURE in case of error
#
#  Side effects:
#     None.
#
################################################################################

sub ClearLogs
{
   my (%args) = @_;
   my $switchRef = $args{SWITCH};
   my $tag = "PSWITCH : ClearLogs :";
   my $cmd = "clear logging";
   my @commands = ($cmd, "\n");
   my $result = $switchRef->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag,
                                 MODE => "privileged"
                                 );
   if ($result eq SUCCESS ) {
      $vdLogger->Debug("$tag successful");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}



################################################################################
#
#  GetLogs
#     Get logs from the pswitch
#
#  Input:
#     None
#
#  Results
#     Data - in case of success
#     FAILURE in case of error or if logging is disalbed on the pswitch
#
#  Side effects:
#     None.
#
################################################################################

sub GetLogs
{
   my (%args) = @_;
   my $switchRef = $args{SWITCH};
   my $tag = "PSWITCH : GetLogs :";
   my $cmd = "show logging";
   my @commands = ($cmd);
   my ($data, $result)  = $switchRef->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                              CMD => \@commands,
                                              TAG => $tag,
                                              MODE => "privileged");
   if ($result eq SUCCESS) {
      my $dataArray =  $data->{$cmd};
      if ($dataArray->[0] =~ /Syslog logging: disabled/i) {
         $vdLogger->Error("logging is disabled on pswitch");
         $vdLogger->Trace(Dumper($data));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vdLogger->Debug("$tag successful");
      return join "", @$dataArray;
   } else {
      $vdLogger->Error("$tag failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

###############################################################################
#
#  UpdateNextServer
#     Set NextServer in "ip dhcp pool" at Cisco switch
#
#  Input:
#   SWITCH      Switch object reference
#   SERVERNAME  Stateless ESX Server name
#   NEXTSERVER  Next Sever IP address (vcva IP)
#
#  Results
#   on success returns SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:None
#
###############################################################################

sub UpdateNextServer
{
   my (%args) = @_;
   my $tag           = "PSWITCH : UpdateNextServer :";
   my $switchRef     = $args{SWITCH};
   my $servername    = $args{SERVERNAME};
   my $nextserver    = $args{NEXTSERVER};
   my $model         = $switchRef->{modelNumber};
   my $switch        = $switchRef->{switchName};
   my $result;
   # the switch reference must be specified.
   if (!defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   #
   # Check for unsupported Cisco Switch
   #
   if ($model =~ /2970|3550/){
      $vdLogger->Error("$tag is not supported in model $model");
      return FAILURE;
   }

   if (not defined $servername) {
      $vdLogger->Error("$tag  $servername not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (not defined $nextserver) {
      $vdLogger->Error("$tag  $nextserver not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @commands = (
                   "ip dhcp pool $servername
                    bootfile https://$nextserver:6501/vmw/rbd/tramp
                    next-server $nextserver
                    ip dhcp pool $servername-
                    next-server $nextserver
                   "
   );

   $result =  $switchRef->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);

   # PR 988101 - Command expected to fail, but sucessfully update on switch

   $result = VerifyNextServer(SWITCH => $switchRef,
                              SERVERNAME => $servername,
                              NEXTSERVER => $nextserver);

   if ($result eq FAILURE) {
      $vdLogger->ERROR("$tag update $nextserver $servername  on switch" .
                 " $switch fail");
      return FAILURE;
   } else {
      $vdLogger->Debug("$tag update $nextserver $servername  on switch" .
                " $switch succeed");
      return SUCCESS;
   }
}

###############################################################################
#
#  VerifyNextServer
#     Verify NextServer in "ip dhcp pool" at Cisco switch
#
#  Input:
#   SWITCH      Switch object reference
#   SERVERNAME  Stateless ESX Server name
#   NEXTSERVER  Next Sever IP address (vcva IP)
#
#  Results
#   on success returns SUCCESS.
#   If failure, FAILURE is returned.
#
#  Side effects:None
#
###############################################################################

sub VerifyNextServer
{
   my (%args) = @_;
   my $tag           = "PSWITCH : VerifyNextServer :";
   my $switchRef     = $args{SWITCH};
   my $servername    = $args{SERVERNAME};
   my $nextserver    = $args{NEXTSERVER};
   my $model         = $switchRef->{modelNumber};
   my $switch        = $switchRef->{switchName};

   # the switch reference and port number must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   #
   # Check for unsupported Cisco Switch
   #
   if ($model =~ /2970|3550/){
      $vdLogger->Error("$tag is not supported in model $model");
      return FAILURE;
   }

   if (! defined $servername) {
      $vdLogger->Error("$tag  $servername not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (! defined $nextserver) {
      $vdLogger->Error("$tag  $nextserver not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $cmd = "show running-config";
   my @commands = ($cmd);
   my ($data, $result)  =  $switchRef->ExecuteCMDOnPSwitch(
                                              SWITCH => $switchRef,
                                              CMD => \@commands,
                                              TAG => $tag,
                                              MODE => "privileged");
   if ($result eq SUCCESS) {
     #
     # Verify Switch update
     #
     my $dataArray_ref = $data->{$cmd};
     my $count = 0;
     my $srv0 = 0;
     my $srv1 = 0;
     #
     # Loop through Anonymous Array return by "show running-config"
     #
     foreach my $line (@$dataArray_ref) {
        if($line =~ /ip dhcp pool $servername-/) {
          $srv0++;
          $count++;
          $vdLogger->Debug("Found:$line");
          next;
        }
        if(($line =~ /next-server $nextserver/i) && ($srv0 != 0)  ){
           $count++;
           $srv0 = 0;
           $vdLogger->Debug("Found:$line");
           next;
        } elsif ( ($line =~ /next-server $nextserver/i) && ($srv1 !=0) ) {
           $count++;
           $srv1=0;
           $vdLogger->Debug("Found:$line");
           next;
        }
        if($line =~ /ip dhcp pool $servername/i) {
           $count++;
           $srv1++;
           $vdLogger->Debug("Found:$line");
           next;
        }
        if( ($line =~ /$nextserver:6501/i) && ($srv1 != 0) ) {
           $count++;
           $vdLogger->Debug("Found:$line");
           next;
        } elsif ( ($line =~ /$nextserver:6501/i) && ($srv1 == 0) ) {
          next;
        }
        if ($count == 5){
           last;
        }
      }
      if ($count != 5) {
         $vdLogger->ERROR("$tag verify $nextserver $servername  on switch" .
                       " $switch fail");
         return FAILURE;
      }else {
         $vdLogger->Debug("$tag verify $nextserver $servername  on switch" .
                      " $switch succeed");
         return SUCCESS;
      }
   } else {
      $vdLogger->Error("$tag failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

1;
