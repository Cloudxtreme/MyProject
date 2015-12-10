#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::Port::Cisco;

#
# This package is responsible for handling all the interaction with
# VMware vNetwork Ports.
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Switch::Port);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::Switch::Port::Cisco
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'portid'    : speed of the port 1G/10G
#      'switchObj' : pswitch object.
#      'vmnicObj'  : vmnic object (peer port on host)
#      'stafHelper': Reference to the staf helper object.
#
# Results:
#      An object of VDNetLib::Switch::Port::Cisco, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
########################################################################

sub new
{
   my $class      = shift;
   my %args       = @_;
   my $self;
   my $portid     = $args{portid};
   my $switchObj  = $args{switchObj};
   my $vmnicObj   = $args{vmnicObj};
   my $stafHelper = $args{stafHelper};
   my $result;

   # check parameters.
   if (not defined $vmnicObj) {
      $vdLogger->Error("Vmnic objects is not is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{switchObj}  = $switchObj;
   $self->{stafHelper} = $stafHelper;
   $self->{portid}     = $portid;
   # Attributes that will be set during runtime
   $self->{'switchPort'} = undef;
   $self->{'hostObj'}    = undef;
   $self->{'vmnic'}      = undef;

   bless($self, $class);
}


################################################################################
#
#  GetPortRunningConfiguration(%args)
#  Get port running-config on Cisco Switch
#
#  Input:
#   switch   switch object reference
#   port     port number for which running-config is to be got
#
#  Results
#   If successful, array ref of running-config of port is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub GetPortRunningConfiguration
{
   my $self = shift;


   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};
   my $interfaceType = $switchRef->{portMap}->{$port};

   # the switch reference and port number must be specified.
   if ((! defined $switchRef) ||
       (! defined $port)) {
      $vdLogger->Error("PSwitch reference / port not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $tag = "PSWITCH: GetPortRunningConfiguration";
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   $interfaceType = $switchRef->{portMap}->{$port};
   my $trpt = $switchRef->{transport};
   my @tempArray = ();

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
         my $currmode = $switchRef->GetCurrentMode(SESSION => $sessionObj);
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
      # Execute command on switch.
      #
      my $cmd = "show running-config interface $interfaceType $port";
      #my @result = $sessionObj->cmd("$cmd");
      my @result = $sessionObj->cmd("$cmd");
      #my @result = $result1;
      my $i = 0;
      my $tempCount;

      for (my $count = 0; $count < (scalar @result); $count++) {
         $tempCount = $count;
         if ($result[$tempCount] =~ /interface/i) {
            $tempCount++; # starting to store from the next line
            for (my $temp = "0"; $temp < (scalar @result); $temp++) {
               if (not defined $result[$temp]) {
                  next;
               }
               if ($result[$temp] !~ /end/i) {
                  chomp($result[$temp]);
                  $tempArray[$i] = $result[$temp];
                  $i++;
               } else {
                  $count = scalar @result; # Max'ing the count to quit the loop
               }
            }
         }
      }

      if (scalar @tempArray == 0) {
         $vdLogger->Warn("$tag The port $port is of default configuration");
      }

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
      $vdLogger->Error("$tag Unable to retrieve running-config of port $port on".
                       " switch $switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag Retrieval of running-config of switch port $port successful" );
   return \@tempArray;
}



sub SetPortStatus
{
   my $self = shift;
   my $status = shift;
   if ($status =~ /enable/i) {
      return $self->EnablePort();
   } else {
      return $self->DisablePort();
   }
}


################################################################################
#  DisablePort(%args)
#  Disable a port(shutdown) on a specified Cisco Switch..
#
#  Input:
#   PORT Port Number (Example. 0/20 or 1/0/10)
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the port on the physical switch gets disabled.
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

sub DisablePort
{
   my $self = shift;


   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};

   my $tag = "PSWITCH : PortDisable :";
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $trpt = $switchRef->{transport};
   my $currmode = undef;

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
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

      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if(not $sessionObj->in_configure_mode()) {
         $sessionObj->begin_configure();
         $vdLogger->Info("$tag Entered the Global Configuration Mode");
      }

      #
      # Enter the Interface Configuration Mode.
      #
      $sessionObj->cmd("interface $interfaceType $port");
      $vdLogger->Info("$tag Configuring Interface ".
                       $interfaceType." ".$port);

      #
      # Disable the port by shutting down the interface.
      #
      $sessionObj->cmd("shutdown");
      $vdLogger->Info("$tag Disabled $interfaceType $port");

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
      #$switchRef->ReportError($@);
      $vdLogger->Error("$tag Can't disable port $port on switch $switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag Disabled port $port on switch $switch.");
   return SUCCESS;
}


################################################################################
#  ConfigureRSPAN -
#   Wrapper api for configuring rspan
#
#  Input:
#   rspan - operation type, create rspan on source/destination or remove rspan;
#   rspanSession - rspan session number
#   rspanValue - rspan vlan value
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the port on the physical switch gets disabled.
#
#
################################################################################

sub ConfigureRSPAN
{
   my $self = shift;
   my $rspan = shift;
   my $rspanSession = shift;
   my $rspanValue = shift;


   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};

   if ($rspan =~ m/source/i) {
      return $self->CreateRSPANSource($rspanSession, $port, $rspanValue);
   } elsif ($rspan =~ m/destination/i) {
      return $self->CreateRSPANDestination($rspanSession, $port, $rspanValue);
   } elsif ($rspan =~ m/remove/i) {
      return $self->RemoveRSPAN($rspanSession, $port, $rspanValue);
   }
}


################################################################################
#
#  CreateRSPANSource(%args)
#  Configure RSPAN source session on a specified Cisco Switch.
#
#  Input:
#   PORT Port Number (Example. 0/20 or 1/0/10)
#   SWITCH switch object reference
#   monitorsession RSPAN session number
#   rspanvlan Remote SPAN VLAN
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub CreateRSPANSource
{
   my $self = shift;
   my $monitorsession = shift;
   my $port = shift;
   my $rspanvlan = shift;

   my $tag = "PSWITCH : CreateRSPANSource :";
   my $switchRef = $self->{switchObj};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $result;
   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @commands = ("no monitor session $monitorsession",
                   "monitor session $monitorsession source interface $interfaceType $port",
                   "monitor session $monitorsession destination remote vlan $rspanvlan",
   );
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("$tag configure RSAPN source on port $port on switch $switchRef success");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag configure RSAPN source on port $port on switch ".
                       "$switchRef failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

}


################################################################################
#
#  CreateRSPANDestination(%args)
#  Configure RSPAN destination session on a specified Cisco Switch.
#
#  Input:
#   PORT Port Number (Example. 0/20 or 1/0/10)
#   SWITCH switch object reference
#   monitorsession RSPAN session number
#   rspanvlan Remote SPAN VLAN
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub CreateRSPANDestination
{
   my $self = shift;
   my $monitorsession = shift;
   my $port = shift;
   my $rspanvlan = shift;

   my $tag = "PSWITCH : CreateRSPANSource :";
   my $switchRef = $self->{switchObj};

   my $interfaceType = $switchRef->{portMap}->{$port};
   my $result;

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @commands = ("no monitor session $monitorsession",
                   "monitor session $monitorsession source remote vlan $rspanvlan",
                   "monitor session $monitorsession destination interface $interfaceType $port",
   );
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("$tag configure RSAPN destination on port $port on switch $switchRef success" );
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag configure RSAPN destination on port $port on switch ".
                       "$switchRef failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

}


################################################################################
#
#  RemoveRSPAN(%args)
#  Remove RSPAN session on a specified Cisco Switch.
#
#  Input:
#   monitorsession RSPAN session number
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

sub RemoveRSPAN
{
   my $self = shift;
   my $monitorsession = shift;
   my $port = shift;
   my $rspanvlan = shift;

   my $tag = "PSWITCH : CreateRSPANSource :";
   my $switchRef = $self->{switchObj};

   my @commands = ("no monitor session $monitorsession");
   my $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("$tag remove RSPAN session on switch $switchRef success" );
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag remove RSPAN session on on switch $switchRef failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#  EnablePort(%args)
#  Enable a port(no shutdown) on a specified Cisco Switch..
#
#  Input:
#   PORT Port Number (Example. 0/20 or 1/0/10)
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the port on the physical switch gets disabled.
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

sub EnablePort
{
   my $self = shift;

   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};

   my $tag = "PSWITCH : PortEnable :";
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $trpt = $switchRef->{transport};

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (! defined $port) {
      $vdLogger->Error("$tag port on the physcial switch not defined");
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
         $vdLogger->Info("$tag Session Object created Successfully");
         $sessionObj->connect(Name => $login,
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
      #
      # Enter the Interface Configuration Mode.
      #
      $sessionObj->cmd("interface $interfaceType $port");
      $vdLogger->Info("$tag Configuring Interface".
                      " $interfaceType $port");
      #
      # Enable the port.
      #
      $sessionObj->cmd("no shut");
      $vdLogger->Info("$tag Enabling $interfaceType $port");
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
      $vdLogger->Error("$tag Enable port $port on switch ".
                       "$switch failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag Enabled port $port on switch $switch" );
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
   my $self = shift;

   my $switchRef = $self->{switchObj};

   my $tag = "PSWITCH : GetMACTable :";
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
         if (not defined $vmnicPort) {
            $vmnicPort = $self->{switchPort};
            my $intType = $switchRef->{portMap}->{$vmnicPort};
            $vmnicPort = "$intType" . "$vmnicPort";
            $vdLogger->Info("$tag Port id to be used:$vmnicPort");
         }
         # search for the specific port id in mac address table
         $command = $command . " in $vmnicPort";

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
#  SetupNativeTrunkVLAN(%args)
#  Sets up a switch port with a native VLAN and a trunk mode
#  NOTE: Currently this method is being used to setup the Healthcheck testbed
#        prior to running the entire TDS on Cisco Switch
#
#  Input:
#   switch  switch object reference
#   port    port number on which setup is to be made
#   native  Native VLAN to be set - to be sent along with the test tag
#           "SetupHealthcheckTestbed" in test hash
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub SetupNativeTrunkVLAN
{
   my $self = shift;
   my $native = shift;


   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};
   my $interfaceType = $switchRef->{portMap}->{$port};
   my $resultHash;

   my $tag = "PSWITCH: SetupNativeTrunkVLAN";

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # First, setting the interface configuration to default config
   my $result = $self->SetDefaultInterfaceConfig(switch => $switchRef,
                                                 port   => $port);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Unable to set default config to port $port");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Setting up the native trunk vlan scenario on the given port
   my @commands;

   # In case switch is 4948, trunk encapsulation is required
   $vdLogger->Debug("Switch model: $switchRef->{modelNumber}");
   if ($switchRef->{modelNumber} =~ /4948/) {
      @commands = ("interface $interfaceType $port",
                   "switchport trunk encapsulation dot1q",
                   "switchport trunk native vlan $native",
                   "switchport mode trunk");
   } else {
      @commands = ("interface $interfaceType $port",
                   "switchport trunk native vlan $native",
                   "switchport mode trunk");
   }

   $vdLogger->Info("$tag Setting up native trunk VLAN on $port");

   ($resultHash, $result) = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                                          CMD => \@commands,
                                                          TAG => $tag);
   if ($result eq "SUCCESS" ) {
      $vdLogger->Info("$tag native trunk vlan setup on port $port successful" );
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag native trunk vlan setup on port $port ".
                       "failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  SetDefaultInterfaceConfig(%args)
#  Sets the configuration of an interface back to its default values on a Cisco
#  switch
#
#  Input:
#   switch  switch object reference
#   port    port number on which setup is to be made
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub SetDefaultInterfaceConfig
{
   my $self = shift;
   my (%args) = @_;
   my $switchRef = $args{switch};
   my $port = $args{port};
   my $tag = $args{TAG} || "PSWITCH: SetDefaultInterfaceConfig";
   my $interfaceType = $switchRef->{portMap}->{$port};

   # the switch reference and port number must be specified.
   if (! defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @commands;
   @commands = ("default interface $interfaceType $port");
   $vdLogger->Info("$tag Setting default settings for $interfaceType $port");

   my ($resultHash, $result) = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                           CMD => \@commands,
                                           TAG => $tag);
   if ($result eq "SUCCESS" ) {
      $vdLogger->Info("$tag configure default configuration on port $port ".
                      "successful");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag configure default configuration on port ".
                       "$port failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  SetMTU
#  Sets the MTU of a port to a specified value on a Cisco switch
#
#  Input:
#   mtu     MTU value
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub SetMTU
{
   my $self = shift;
   my $mtu = shift;

   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};
   my $interfaceType = $switchRef->{portMap}->{$port};

   if (! defined $mtu) {
      $vdLogger->Error("MTU value not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @commands;
   @commands = ("interface $interfaceType $port", "mtu $mtu");
   $vdLogger->Info("Setting mtu $mtu for $interfaceType $port");

   my ($resultHash, $result) = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                           CMD => \@commands);
   if ($result eq "SUCCESS" ) {
      $vdLogger->Info("Configure mtu $mtu on port $port succeeded");
      return SUCCESS;
   } else {
      $vdLogger->Error("Configure mtu $mtu on port $port failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  ConfigureChannelGroup
#  Configure channel-group on a switch port
#
#  Input:
#   group  channel-group number
#   mode   channel-group mode
#   nativevlan channel-group native vlan (optional)
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub ConfigureChannelGroup
{
   my $self = shift;
   my $group = shift;
   my $mode = shift;
   my $nativevlan = shift;

   $mode = lc($mode);

   my $switchRef = $self->{switchObj};
   my $port = $self->{'switchPort'};
   my $interfaceType = $switchRef->{portMap}->{$port};

   if (! defined $port) {
      $vdLogger->Error("Port on the physcial switch not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @commands;
   if ($group =~ m/no/i) {
      # we should reset the interface to pick up the new settings at once
      @commands = ("interface $interfaceType $port",
                   "no channel-group", "sh", "no sh");
      $vdLogger->Info("Removing channel-group from $interfaceType $port");
   } else {
      #
      # If you try to add a port to channel-group/port-channel and if it does
      # not exists Pswitch creates it for you but the created port-channel will
      # not have mtu set to 9000. We have mtu set to 9000 on all ports thus
      # it will be incompatible. Pswitch will say "EC-5-CANNOT_BUNDLE2: Gi1/8
      # is not compatible with Po63 and will be suspended (MTU of Gi1/8 is 9000,
      # Po63 is 1500)"
      # Thus we create the portchannel manually
      # Set "spanning-tree portfast trunk" is to disable STP on the ports, so
      # that the traffic can be restored quickly when there is frequent vmnic
      # add/remove operations.
      #
      @commands = ("interface port-channel $group",
                   "switchport",
                   "no shutdown", #to support cisco 6503
                   "switchport mode trunk", #to support cisco 6503
                   "spanning-tree portfast trunk");

      if (defined $nativevlan) {
         if ($switchRef->{modelNumber} =~ /4948/) {
            push (@commands, "switchport trunk encapsulation dot1q");
         }
         push (@commands, "switchport trunk native vlan $nativevlan");
      }

      unless ($switchRef->{modelNumber} =~ /3[0-9]{3}/) {
         push (@commands, "mtu 9000");
      }

      my $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                              CMD => \@commands);
      if ($result eq "SUCCESS") {
         $vdLogger->Info("Creating Channelgroup $group successful");
      } else {
         $vdLogger->Error("Creating Channelgroup $group failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Now we can go ahead and add the port to the portchannel
      @commands = ("interface $interfaceType $port",
                   "channel-group $group mode $mode");
      $vdLogger->Info("Assigning channel-group $group to $interfaceType $port");
   }
   my $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                           CMD => \@commands);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("Configure Channelgroup on port $port successfully" );
      return SUCCESS;
   } else {
      $vdLogger->Error("Configure Channelgroup on port $port failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  SetPortRunningConfiguration
#  Set port running-config on Cisco Switch
#
#  Input:
#   switch   switch object reference
#   port     port number for which running-config is to be set
#   config   running-config of the switchport that is to be set
#
#  Results
#   If successful, SUCCESS is returned if successfully set
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub SetPortRunningConfiguration
{
   my $self = shift;

   my $switchRef = $self->{switchObj};

   my $port = $self->{'switchPort'};
   my @config = $self->{switchObj}{portMap}{runConfig}{$port};
   my $interfaceType = $switchRef->{portMap}->{$port};

   if ((! defined $switchRef) ||
       (! defined $port)) {
      $vdLogger->Error("PSwitch reference / port not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $tag = "PSWITCH: SetPortRunningConfiguration";
   my @tempArray = ();

   my @commands;
   @commands = ("interface $interfaceType $port");
   foreach my $line (@config) {
      @tempArray = @$line; # element of @config is ref to array
   }
   my $count;
   my $lowerlimit;
   foreach my $line (@tempArray) {
      if ($line =~ /$port/) {
         push (@commands, $line);
         last;
      }
      $count++;
   }
   $lowerlimit = $count + 1;
   for (my $index = $lowerlimit; $index < @tempArray; $index++) {
      push @commands, $tempArray[$index];
   }


   # First, setting the interface configuration to default config
   my $result = $self->SetDefaultInterfaceConfig(switch => $switchRef,
                                                 port   => $port);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Unable to set default config to port $port");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("$tag Setting running-config for $interfaceType $port");

   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                        CMD => \@commands,
                                        TAG => $tag);

   if ($result eq FAILURE ) {
      $vdLogger->Error("$tag configure running-configuration on port ".
                       "$port failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
#  CheckLLDPOnESX
#  Check LLDP on ESX
#
#  Input:
#   flag      yes/no
#   protocol  lldp
#
#  Results
#   If successful, SUCCESS is returned if successfully set
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub CheckLLDPOnESX
{
   my $self     = shift;
   my $flag     = shift || "yes";
   my $protocol = "lldp";
   return $self->CheckProtocol($flag, $protocol);
}


################################################################################
#
#  CheckCDPOnESX
#  Check cdp on ESX
#
#  Input:
#   flag      yes/no
#   protocol  cdp
#
#  Results
#   If successful, SUCCESS is returned if successfully set
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub CheckCDPOnESX
{
   my $self     = shift;
   my $flag     = shift || "yes";
   my $protocol = "cdp";
   return $self->CheckProtocol($flag, $protocol);
}


#######################################################################
#
# CheckProtocol:
#     This method would verify the status of lldp in ESX server.
#     It makes sure that LLDP info passed by the physical switch is
#     correct.
#
# Input:
#     flag     : Indicates what is expected, possible values are-
#                "yes" which means the lldp info should be present.
#                "no" means the lldp info should not be present.
#     protocol : lldp/cdp
#
# Results:
#      "SUCCESS", if lldp info is correct.
#      "FAILURE", in case lldp info in esx is not correct.
#
# Side effects:
#      None.
#
# Note:
#
# Sample output for LLDP .
#  ~ # vsish -pe get /vmkModules/cdp/pNics/vmnic2/lldpSummary
# {
#   "status" : 1,
#   "timeout" : 0,
#   "samples" : 82125,
#   "chassisID" : "00:21:1b:53:90:8f",
#   "portID" : "Gi0/15",
#   "ttl" : 98,
#   "optTLVNum" : 6,
#   "optTLVLen" : 190,
#   "optTLVBuf" : "
#                  ",
# }
# ~ #
#
#
########################################################################

sub CheckProtocol
{
   my $self = shift;
   my $flag = shift || "yes";
   my $protocol = shift;


   my $vmnic = $self->{vmnic};
   my $host = $self->{hostObj}->{hostIP};
   my $tag = "Switch : ";
   my $status;
   my $DPInfo;
   my $LLDPInfo;
   my $port;
   my $cmd;
   my $result;

   if ($flag !~ m/yes|no/i) {
      $vdLogger->Error("$tag $flag is invalid value, valid ones are ".
                       "'yes' and 'no' ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($protocol !~ m/lldp|cdp/i) {
      $vdLogger->Error("$tag $protocol is invalid value for discovery protocol ".
                       "valid values are 'cdp' and 'lldp'");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # First check that Discovery Protocol status on esx
   # should be LLDP which is "1".
   #
   $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/DPStatus";
   $vdLogger->Info("Getting LLDP information - $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($result->{rc} != 0 && $result->{exitCode} != 0) {
      $vdLogger->Error("$tag Failed to get Discovery protocol info on ".
                       "$host for $vmnic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $DPInfo =  VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                            RESULT => $result->{stdout}
                                            );
   $vdLogger->Debug("DPStatus: " . Dumper($DPInfo));

   if ($DPInfo eq "") {
      if ($flag =~ m/no/i) {
         $vdLogger->Info("$tag information not available as expected");
         return SUCCESS;
      } else {
         $vdLogger->Error("$tag The information is not available for ".
                         "$vmnic via $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   # protocol status should be 1 for lldp and 0 for CDP.
   if ($protocol =~ m/cdp/i) {
      $status = 0;
   } else {
      $status = 1;
   }
   if ($DPInfo->{protocol} eq "$status") {
      $vdLogger->Info("$tag Discovery Protocol is $protocol");
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag Discovery protocol is not $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   # the info status should be 1.
   if ($DPInfo->{infoAvailable} eq "1") {
      if ($flag =~ m/yes/i) {
         $vdLogger->Info("$tag The information is available for $vmnic ".
                         "via $protocol");
      }
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag The information is not available for ".
                         "$vmnic via $protocol");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   # command to check discovery protocol info;
   if ($protocol =~ m/lldp/i) {
      $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/lldpSummary";
   } else {
      $cmd = "vsish -pe get /vmkModules/cdp/pNics/$vmnic/cdpSummary";
   }

   $vdLogger->Info("Getting $protocol information - $cmd");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($result->{exitCode} != 0 ) {
      if ($flag =~ m/no/i) {
         if (defined $result->{stderr}) {
            return SUCCESS;
         }
      } else {
         $vdLogger->Error("$tag Failed to get $protocol Information on ".
                       "$host for $vmnic");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   if (not defined $result->{stdout}) {
      if ($flag =~m/yes/i) {
         $vdLogger->Error("$tag $protocol info in ESX is not defined");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $vdLogger->Info("$tag The ESX host doesn't have $protocol info");
         return SUCCESS;
      }
   }

   $LLDPInfo = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                            RESULT => $result->{stdout}
                                            );

   # The LLDP info should be in Hash, if it is available.
   if (ref($LLDPInfo) !~ /HASH/i) {
      if ($result =~ m/yes/i) {
         $vdLogger->Error("$tag $protocol info is not correct");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }
   $vdLogger->Debug("LLDP info on the host:".Dumper(\$LLDPInfo));
   $vdLogger->Debug("Switch port is $self->{switchPort}");
   # get the port id of pswitch shown in lldp info.
   my $regex;
   if ($protocol =~ m/lldp/i) {
      $regex = 's*.*i([^"]+)';
   } else {
      $regex = 's*.*Ethernet([^"]+)';
   }

   # cdp has portId while lldp has portID
   my $info;
   if ($protocol =~ m/lldp/) {
      $info = $LLDPInfo->{portID};
      $vdLogger->Debug("portID get from LLDP is $info");
   } else {
      $info = $LLDPInfo->{portId};
   }
   if ($info =~ m/$regex/i) {
      $port = $1;
   } elsif ($info =~ m/Te(.*)/i) {
      $port = $1;
      $vdLogger->Debug("Switch port information get from LLDP is $port");
   }  else {
      if ($flag =~m/yes/i) {
         $vdLogger->Error("$tag LLDP info is incorrect.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return SUCCESS;
      }
   }

   #
   # now check that port id in LLDP info should be same as
   # the switch port to which pnic is connected.
   #
   if ($port eq $self->{switchPort}) {
      if ($flag =~ m/yes/i) {
         $vdLogger->Info("$tag port id in $protocol info for $vmnic is same as ".
                         "the actual port id of the pnic $vmnic");
         return SUCCESS;
       } else {
          $vdLogger->Error("$tag The $protocol info is not expected");
          VDSetLastError("ENOTDEF");
          return FAILURE;
       }
   } else {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag port id id in $protocol info for $vmnic is not same ".
                         "as the actual port id of the pnic $vmnic");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }  else {
         return SUCCESS;
      }
   }
}


#######################################################################
#
# CheckCDPOnSwitch:
#     This method would verify the info of discovery protocol
#     (cdp or lldp ) inside the physical switch.It makes sure that
#     discovery protocol info passed by the ESX is
#     correct in physical switch.
#
# Input:
#     flag     : Indicates what is expected, possible values are
#                "yes" which means the discovery info should be present.
#                "no" means the discovery info should not be present.
#     vmnicObj : NetAdapter object for the pnic.
#
# Results:
#      "SUCCESS", if dp info is correct.
#      "FAILURE", in case dp info in switch is not correct.
#
# Side effects:
#      None.
#
# Note:
# Sample output for LLDP
#
#  vmk-colo-057#show lldp entry *
#
# Capability codes:
#    (R) Router, (B) Bridge, (T) Telephone, (C) DOCSIS Cable Device
#    (W) WLAN Access Point, (P) Repeater, (S) Station, (O) Other
#
# Chassis id: vmk-colo-049.eng.vmware.com
# Port id: vmnic2
# Port Description: port 0 on vdswitch dvSwitch (etherswitch)
# System Name: vmk-colo-049.eng.vmware.com
#
# System Description:
# VMware ESX BETAbuild-309830
#
# Time remaining: 176 seconds
# System Capabilities: B
# Enabled Capabilities: B
# Management Addresses - not advertised
# Auto Negotiation - not supported
# Physical media capabilities - not advertised
# Media Attachment Unit type - not advertised
# ---------------------------------------------
#
#
# Total entries displayed: 1
#
########################################################################

sub CheckCDPOnSwitch
{
   my $self = shift;
   my $flag = shift || "yes";

   my $protocol = "cdp";

   my $tag = "Switch : CheckLLDPOnSwitch : ";
   my $result;

   $result = $self->CheckDiscoveryInfo(SWITCH => $self->{switchObj},
                                       PROTOCOL => $protocol);

   if ($result eq FAILURE) {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag Failed to validate the $protocol Info");
         VDSetLastError("EINVALID");
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      if ($flag =~ m/yes/i) {
         return SUCCESS;
      } else {
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
}


#######################################################################
#
# CheckLLDPOnSwitch:
#     This method would verify the info of discovery protocol
#     (cdp or lldp ) inside the physical switch.It makes sure that
#     discovery protocol info passed by the ESX is
#     correct in physical switch.
#
# Input:
#     flag     : Indicates what is expected, possible values are
#                "yes" which means the discovery info should be present.
#                "no" means the discovery info should not be present.
#     vmnicObj : NetAdapter object for the pnic.
#
# Results:
#      "SUCCESS", if dp info is correct.
#      "FAILURE", in case dp info in switch is not correct.
#
# Side effects:
#      None.
#
# Note:
# Sample output for LLDP
#
#  vmk-colo-057#show lldp entry *
#
# Capability codes:
#    (R) Router, (B) Bridge, (T) Telephone, (C) DOCSIS Cable Device
#    (W) WLAN Access Point, (P) Repeater, (S) Station, (O) Other
#
# Chassis id: vmk-colo-049.eng.vmware.com
# Port id: vmnic2
# Port Description: port 0 on vdswitch dvSwitch (etherswitch)
# System Name: vmk-colo-049.eng.vmware.com
#
# System Description:
# VMware ESX BETAbuild-309830
#
# Time remaining: 176 seconds
# System Capabilities: B
# Enabled Capabilities: B
# Management Addresses - not advertised
# Auto Negotiation - not supported
# Physical media capabilities - not advertised
# Media Attachment Unit type - not advertised
# ---------------------------------------------
#
#
# Total entries displayed: 1
#
########################################################################

sub CheckLLDPOnSwitch
{
   my $self = shift;
   my $flag = shift || "yes";

   my $protocol = "lldp";

   my $tag = "Switch : CheckLLDPOnSwitch : ";
   my $result;

   $result = $self->CheckDiscoveryInfo(PROTOCOL => $protocol);


   if ($result eq FAILURE) {
      if ($flag =~ m/yes/i) {
         $vdLogger->Error("$tag Failed to validate the $protocol Info");
         VDSetLastError("EINVALID");
         return FAILURE;
      } else {
         return SUCCESS;
      }
   } else {
      if ($flag =~ m/yes/i) {
         return SUCCESS;
      } else {
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
}

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
   my $self = shift;

   my $switchRef = $self->{switchObj};

   my (%args) = @_;
   my $tag = "PSWITCH : CheckDiscoveryInfo :";
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

   if ($protocol !~ m/lldp|cdp/i) {
      $vdLogger->Error("$tag $protocol is invalid value for discovery protocol ".
                       "valid values are 'cdp' and 'lldp'");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $port = $self->{switchPort};
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
      $regex = "Chassis id: " . $self->{vmnic};
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


###############################################################################
#  SetLLDPTransmitInterface
#  Sets the LLDP TX Interface State for the physical switchport.
#
#  Input:
#   SWITCH : switch object reference
#   port   : port id of the switch where lldp TX state to be set.
#   mode   : defines whether to enable the state or to disable.
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldp TX interface state is set (enabled or disabled).
#
#  Note
#   None
#
#############################################################################

sub SetLLDPTransmitInterface
{
   my $self = shift;
   my $mode = shift || "Enable";


   my $switch = $self->{switchObj};
   my $port = $self->{'switchPort'};

   my $cmd;
   my $result;
   my $tag = "PSwitch : SetLLDPTXInterfaceState : ";

   if (not defined $port) {
      $vdLogger->Error("$tag SwitchPort not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $switch) {
      $vdLogger->Error("$tag Reference to switch not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # build the command to set lldp interface state based on the mode.
   if ($mode =~ m/Disable/i) {
       $cmd = "no lldp transmit";
   } else {
       $cmd = "lldp transmit";
   }

   # Set the RX interface state.
   $result = $self->SetLLDPInterfaceState(PORT => $port,
                                   SWITCH => $switch,
                                   COMMAND => $cmd
                                   );
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to $mode LLDP receive for $port");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


###############################################################################
#  SetLLDPReceiveInterface
#  Sets the LLDP RX Interface State for the physical switchport.
#
#  Input:
#   SWITCH : switch object reference
#   port   : port id of the switch where lldp rx state to be set.
#   mode   : defines whether to enable the state or to disable.
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldp interface state is set (enabled or disabled).
#
#  Note
#   None
#############################################################################

sub SetLLDPReceiveInterface
{
   my $self = shift;
   my $mode = shift || "Enable";


   my $switch = $self->{switchObj};
   my $port = $self->{'switchPort'};

   my $cmd;
   my $result;
   my $tag = "PSwitch : SetLLDPRXInterfaceState : ";

   if (not defined $port) {
      $vdLogger->Error("$tag SwitchPort not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $switch) {
      $vdLogger->Error("$tag Reference to switch not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # build the command to set lldp interface state based on the mode.
   if ($mode =~ m/Disable/i) {
       $cmd = "no lldp receive";
   } else {
       $cmd = "lldp receive";
   }

   # Set the RX interface state.
   $result = $self->SetLLDPInterfaceState(PORT => $port,
                                   SWITCH => $switch,
                                   COMMAND => $cmd
                                   );
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to $mode LLDP receive for $port");
      VDSetLastError(GetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


###############################################################################
#  SetLLDPInterfaceState
#  Sets the LLDP Interface State for the physical switch.
#
#  Input:
#   SWITCH switch object reference
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   the lldp interface state is enabled.
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

sub SetLLDPInterfaceState
{
   my $self = shift;
   my (%args) = @_;
   my $port = $args{PORT};
   my $command = $args{COMMAND};
   my $tag = "PSwitch : SetLLDPInterfaceState : ";
   my $switchRef = $args{SWITCH};
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $trpt = $switchRef->{transport};
   my $interfaceType = $switchRef->{portMap}->{$port};

   # the switch reference must be specified.
   if (not defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $command) {
      $vdLogger->Error("$tag Status of LLDP to be set not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $port) {
      $vdLogger->Error("$tag port not defined");
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
               $vdLogger->Info("$tag Entered Privileged EXEC Mode");
               $sessionObj->begin_privileged($password);
            }
         }
      }

      #
      # If already in configure mode then ignore, else move to configure mode.
      #
      if(not $sessionObj->in_configure_mode()) {
         $sessionObj->begin_configure();
         $vdLogger->Info("$tag Entered the Global Configuration Mode");
      }

      #
      # Enter the Interface Configuration Mode.
      #
      $sessionObj->cmd("interface $interfaceType $port");
      $vdLogger->Info("$tag Configuring Interface ".
                       $interfaceType." ".$port);

      #
      # Disable the port by shutting down the interface.
      #
      $sessionObj->cmd("$command");
      $vdLogger->Info("$tag $command on $interfaceType $port");

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
      $vdLogger->Error("$tag Can't set LLDP for $port on switch $switch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$tag Set LLDP for $port on switch $switch.");
   return SUCCESS;
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
   my $self = shift;
   my (%args) = @_;
   my $switchRef = $self->{switchObj}; #$args{SWITCH};
   my $tag = $args{TAG} || "ExecuteCMDOnPSwitch";
   my $commands = $args{CMD};
   my $mode = $args{MODE} || undef;
   my $sessionObj= $switchRef->{sessionObj};
   my $switch = $switchRef->{switchName};
   my $login = $switchRef->{login};
   my $password = $switchRef->{password};
   my $port = $args{PORT};
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
         $sessionObj->connect(Name => $login,
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


################################################################################
#
#  EnablePIM
#  Enable IP PIM for given vlan on physical switch
#
#  Input:
#   enablepim   given vlan id
#   mode        sparse-dense-mode
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub EnablePIM
{
   my $self = shift;
   my %args    = @_;
   my $vlan = $args{enablepim};
   my $mode = $args{mode};

   my $tag = "PSWITCH : EnablePIM :";
   my $switchRef = $self->{switchObj};
   my $result;
   my @commands;

   if (!defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #This command to check physical switch support PIM or not
   @commands = ("show ip pim interface");
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 MODE => "privileged",
                                 TAG => $tag);
   if ($result eq "FAILURE") {
      $vdLogger->Error("$tag $switchRef->{switchName} doesn't " .
                      "support PIM");
      return FAILURE;
   }

   #Check vlan id between 1 and 4094
   my ($lower, $upper) = (1, 4094);
   my $is_between = (sort {$a <=> $b} $lower, $upper, $vlan)[1] == $vlan;
   if ($is_between eq "") {
     $vdLogger->Error("$tag vlan id $vlan not between $lower and $upper");
     return FAILURE;
   }
   @commands = ("interface vlan $vlan",
                "ip pim $mode");
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("$tag enable ip pim for vlan $vlan on " .
                      "switch $switchRef->{switchName} success");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag enable ip pim for vlan $vlan on switch ".
                       "$switchRef->{switchName} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
#  DisablePIM
#  Disable IP PIM for given vlan on physical switch
#
#  Input:
#   disablepim   given vlan id
#   mode        sparse-dense-mode
#
#  Results
#   If successful, SUCCESS is returned
#   If failure, FAILURE is returned
#
#  Side effects:
#   None.
#
################################################################################

sub DisablePIM
{
   my $self = shift;
   my %args    = @_;
   my $vlan = $args{disablepim};
   my $mode = $args{mode};

   my $tag = "PSWITCH : DisablePIM :";
   my $switchRef = $self->{switchObj};
   my $result;
   my @commands;

   if (!defined $switchRef) {
      $vdLogger->Error("$tag PSwitch reference not defined");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #This command to check physical switch support PIM or not
   @commands = ("show ip pim interface");
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 MODE => "privileged",
                                 TAG => $tag);
   if ($result eq "FAILURE") {
      $vdLogger->Error("$tag $switchRef->{switchName} doesn't " .
                      "support PIM");
      return FAILURE;
   }

   #Check vlan id between 1 and 4094
   my ($lower, $upper) = (1, 4094);
   my $is_between = (sort {$a <=> $b} $lower, $upper, $vlan)[1] == $vlan;
   if ($is_between eq "") {
     $vdLogger->Error("$tag vlan id $vlan not between $lower and $upper");
     return FAILURE;
   }
   @commands = ("interface vlan $vlan",
                "no ip pim $mode");
   $result = $self->ExecuteCMDOnPSwitch(SWITCH => $switchRef,
                                 CMD => \@commands,
                                 TAG => $tag);
   if ($result eq "SUCCESS") {
      $vdLogger->Info("$tag disable ip pim for vlan $vlan on " .
                      "switch $switchRef->{switchName} success");
      return SUCCESS;
   } else {
      $vdLogger->Error("$tag disable ip pim for vlan $vlan on switch ".
                       "$switchRef->{switchName} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

1;
