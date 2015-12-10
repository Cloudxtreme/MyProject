#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

# Integrating our code with foundary qa src will require putting the VMOperations class
# at the following location after installing VIX-PERL and VIX-PERL-SP and copying
# foundary qa src in perl library.
package VDNetLib::VM::HostedVMOperations;

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

# Should I be using this in a package?
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VIX";
# I am gonna use the following packages to write my code
# All packages belong to Foundary QA Src
use perl::foundryqasrc::TestBase;
use perl::foundryqasrc::TestConstants;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::Enumerations;
use perl::foundryqasrc::ManagedVM;
use perl::foundryqasrc::ManagedUtil;

# These packages belong with VIX-PERL API
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;
use VDNetLib::Common::GlobalConfig;
# package speicific vairables

# Inheriting from VMOperations package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::VM::VMOperations);

#-----------------------------------------------------------------------------
#  new (Constructor)
#
#  Algorithm:
#  Sets the variables specific to HostedVMOperations.
#
#  Input:
#       a hash with keys _host and _vmxPath
#
#  Output:
#       child Object of HostedVMOperations.
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub new
{
   my $proto    = shift;
   my $class    = ref($proto) || $proto;
   my $hash_ref = shift;

   $hash_ref->{'_justHostIP'}      = $hash_ref->{'_host'};
   $hash_ref->{'_absoluteVMXPath'} = $hash_ref->{'_vmxPath'};
   my $self = {

      # Right now I dont have any HostedVMOperation specific variables settings.

   };
   bless $self, $class;
   return $self;
}

# Methods specific to Hosted Operations
my %param;

#-----------------------------------------------------------------------------
#  InsterBackdoorLineESX
#
#  Algorithm:
#  Workstation VMs dont need any backdoor lines
#
#  Input:
#       None
#
#  Output:
#       SUCCESS
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------

sub InsterBackdoorLineESX
{
   TestInfo "Workstation VMs dont need any backdoor lines. ";
   return SUCCESS;
}

#TODO: Not yet implemented and tested so please ignore review.
#Functionality supported on WS only
# Foundary guys used wait for tools property before doing suspend.
sub VMOpsPause()
{
   my $class   = shift;
   my $passed  = 0;
   my $testobj = 0;
   ClearParam \%param;
   ( $passed, $testobj ) =
      $class->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VM Pause Started";

      # Need to figure out how to wait for tools to start.
      # TestInfo "Powered On and waited for tools succesfully";
      TestInfo "Calling a pause on the running VM";
      $passed =
    $testobj->GetManagedVM->PauseVM( $testobj->GetVMHandle(), 0,
    VIX_INVALID_HANDLE, \%param );

      if ($passed) {
    TestInfo "Paused the VM succesfully";
      } else {
    TestError "Could not pause the VM succesfully";
      }
      $class->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
   }
   return $passed;
}

#TODO: Not yet implemented and tested so please ignore review.
sub VMOpsUnpause()
{
   my $class   = shift;
   my $passed  = 0;
   my $testobj = 0;
   ClearParam \%param;
   ( $passed, $testobj ) =
      $class->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VM Unpause Started";
      ClearParam \%param;
      $passed = $testobj->GetManagedVM->UnPauseVM( $testobj->GetHandleToUse(),
    0, VIX_INVALID_HANDLE, \%param );

      if ($passed) {
    $testobj->SetOutcome(PASS);
    TestInfo "VM Unpause Passed";
      } else {
    $testobj->SetOutcome(FAIL);
    TestError "VM Unpause Failed";
      }
      $class->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
   }
   return $passed;
}

#-----------------------------------------------------------------------------
#  VMOpsHotAddvNIC
#
#  Algorithm:
#    Find the next available ethernet unit number by greping the vmx file
#    for ethernet[0-9].present = TRUE and then adding vNIC to next availabe unit number.
#    vmdbsh binary is given series of command to hot add vNIC.
#    Again verify hot add as well as read the vmx file for MAC address of vNIC
#    just added.
#
#  Input:
#      Adapter type: bridged, hostonly, nat (any 1 required)
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsHotAddvNIC
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   my $adapterType;
   my $command;
   my $errorString;
   my $service;
   my $ret;
   my $data;
   my @data_array;
   my $macAddress;
   my $presentNum;
   my $availableNum = 0;
   my $binary;

   # Validate staf handle
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined \n";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Validate input arguements to the function
   if ( 1 != @_ ) {
      TestError
    "Function called wihout type of Adapter(Bridged, NAT, HostOnly)\n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Validating if the argument is any of three values mentioned below
   $adapterType = shift;
   if (  $adapterType ne "bridged"
      && $adapterType ne "nat"
      && $adapterType ne "hostonly" ) {
      TestError "Supported adapters are :Bridged, NAT and HostOnly\n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Creating VIX handles before hot adding
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ( !$passed ) {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking if STAF is running on the host. Staf is used to send hot add command
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      print STDERR "STAF is not running on $self->{_justHostIP} \n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # grep for ethernetX.present = "TRUE" thus moving to next available unit
   # number for adding
   if ( $self->{_hostType} =~ /win/i ) {
      open FILE, "<", $self->{_absoluteVMXPath}
    or die("Could not read vmx file!");
      @data_array = grep( /^[' ']*ethernet[0-9].present = \"TRUE\"/, <FILE> );
      close(FILE);
   } else {
      $command =
      "start shell command \"grep -i \\\"^[' ']*ethernet[0-9]\\.present = "
    . "\\\\\\\"TRUE\\\\\\\"\\\" \\\"$self->{_absoluteVMXPath}\\\" | sort -u \"
      wait returnstdout stderrtostdout";
      $service = "process";
      ( $ret, $data ) =
    $self->{stafHandle}
    ->runStafCmd( $self->{_justHostIP}, $service, $command );
      if ( $ret eq FAILURE ) {
    TestError "Error with staf $command @data_array \n";
    VDSetLastError("ESTAF");
    return FAILURE;
      } else {
    @data_array = split( /\n/, $data );
      }
   }

   # Logic for moving on to next available ethernet unit number for adding
   foreach $data (@data_array) {
      if ( $data =~ /^\s*ethernet(\d*).*/ ) {
    $presentNum = $1;
    if ( $presentNum != $availableNum ) {
       last;
    } else {
       $availableNum++;
    }
      }
   }

   # Setting the vmdbsh binary path
   my $np = new VDNetLib::Common::GlobalConfig;
   my $binpath;
   if ( $self->{_hostType} =~ /win/i ) {
      $binpath = $np->binariespath(2);
      $binary  = "$binpath" . "x86_32/windows/vmdbsh";
   } else {
      $binpath = $np->binariespath(3);
      $binary  = "$binpath" . "x86_32/esx/vmdbsh";
   }

   # vmdbsh binary is same for 32/64 bit and hence it is hardcoded here
   my $wincmd = STAF::WrapData(
           "\"connect -v \\\"$self->{_absoluteVMXPath}\\\";mount /vm; "
    . "cd /vm/#_VMX/vmx/hotplug;begin;"
    . "newidx ##;set op deviceAdd;set op/deviceAdd/in/key ethernet$availableNum;"
    . "cd op/deviceAdd/in/options/;newidx #;set key ethernet$availableNum.connectionType;"
    . "set value $adapterType;cd ..;cd ../../../../../../;end;exit\"" );
   $command =
        "start shell command $binary -e "
      . $wincmd
      . " wait returnstdout stderrtostdout";
   $service = "process";
   ( $ret, $data ) =
      $self->{stafHandle}
      ->runStafCmd( $self->{_justHostIP}, $service, $command );

   # Let the hot plugging add the entries to vmx file. Thus sleeping to provide it sometime
   sleep(20);
   if ( $ret eq FAILURE ) {
      TestError "error with staf $command \n";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Read the MAC address of the vNIC just added.
   if ( $self->{_hostType} =~ /win/i ) {    # grepping the line in windows
      open FILE, "<", $self->{_absoluteVMXPath}
    or die("Could not read vmx file!");
      my @pattern =
    grep( /^[' ']*ethernet$availableNum.generatedAddress = /, <FILE> );
      $data = pop(@pattern);
      close(FILE);
   } else    # grepping the line in linux
   {
      $command =
      "start shell command \"grep -i \\\"^[' ']*ethernet$availableNum\\."
    . "generatedAddress =\\\" \\\"$self->{_absoluteVMXPath}\\\" \"
      wait returnstdout stderrtostdout";
      $service = "process";
      ( $ret, $data ) =
    $self->{stafHandle}
    ->runStafCmd( $self->{_justHostIP}, $service, $command );
      if ( $ret eq FAILURE ) {
    TestError "Error with staf $command \n";
    VDSetLastError("ESTAF");
    return FAILURE;
      }
   }

   # Logic to parse the macAddress and return it to the caller of function
   if ( $data =~ /^\s*ethernet$availableNum.generatedAddress = (.*?)\n/ ) {
      $macAddress = $1;
      $macAddress =~ s/(\")//g;
      chomp($macAddress);
   } else {
      TestError "error parsing MAC address $data\n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $self->TestCleanup($testobj);
   return SUCCESS, $macAddress;
}

#-----------------------------------------------------------------------------
#  VMOpsHotRemovevNIC
#
#  Algorithm:
#     Find ethernet unit number by grepping in vmx using MAC address, then use vmdhsh to hot remove vNIC.
#   Again verify by checking for ethernetX.present = False
#
#  Input:
#       MAC address of vNIC you want to hot remove (required)
#
#  Output:
#       1 if pass, 0 if fail
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsHotRemovevNIC
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   my $command;
   my $service;
   my $macAddress;
   my $ret;
   my $data;
   my $ethUnitNum;
   my ( $handle, $binary );

   # Validate if staf handle is present in the object
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined \n";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if macAddress of vNIC was passed.
   if ( 1 == @_ ) {
      $macAddress = shift;
      if ( not defined $macAddress ) {
    TestError "Inappropriate MAC address\n";
    VDSetLastError("EINVALID");
    return FAILURE;
      }
   } else {
      TestError "VM hot add vNIC called without MAC address input Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Creating VIX handle for operation on VM
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {

      # Checking if staf is running on the host. Staf is used to send hot remove command
      if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
    TestError "Staf not running on remote machine\n";
    VDSetLastError("ESTAF");
    return FAILURE;
      }

      #Finding the ethernet Unit number in vmx file using the macAddress of vNIC
      if ( $self->{_hostType} =~ /win/i ) {
    open FILE, "<", $self->{_absoluteVMXPath}
       or die("Could not read vmx file!");
    my @string = grep( /\"$macAddress\"/, <FILE> );
    $data = pop(@string);
    $data =~ /^ethernet(\d+).*/;
    $ethUnitNum = "ethernet" . "$1";
    close(FILE);
      } else {
    $ethUnitNum =
       VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP}, $self->{_absoluteVMXPath},
       $macAddress );
      }
      if ( not defined $ethUnitNum ) {
    TestError "Error returned from function GetEthUnitNum\n";
    VDSetLastError( VDGetLastError() );
    return FAILURE;
      }

      # Attaching the binary to the staf command according to the OS type.
      my $np = new VDNetLib::Common::GlobalConfig;
      my $binpath;
      if ( $self->{_hostType} =~ /win/i ) {
    $binpath = $np->binariespath(2);
    $binary  = "$binpath" . "x86_32/windows/vmdbsh";
      } else {
    $binpath = $np->binariespath(3);
    $binary  = "$binpath" . "x86_32/esx/vmdbsh";
      }

      # Preparing the series of command which will do hot remove
      my $wincmd = STAF::WrapData(
         "\"connect -v \\\"$self->{_absoluteVMXPath}\\\"; mount /vm; "
       . "cd /vm/#_VMX/vmx/hotplug; begin; newidx ## ;set op deviceRemove; "
       . "set op/deviceRemove/in/key $ethUnitNum; cd .. ;end; exit\"" );
      $command =
      "start shell command $binary -e "
    . $wincmd
    . " wait returnstdout stderrtostdout";

      $service = "process";
      ( $ret, $data ) =
    $self->{stafHandle}
    ->runStafCmd( $self->{_justHostIP}, $service, $command );
      if ( $ret eq FAILURE ) {
    TestError "error with staf $command\n";
    VDSetLastError("ESTAF");
    return FAILURE;
      }

      # Let the hot plugging module add entries to vmx file thus sleeping
      sleep(10);

      # After hotremove the ethernetX.present should say FALSE
      if ( $self->{_hostType} =~ /win/i ) {    # grepping the line in windows
    open FILE, "<", $self->{_absoluteVMXPath}
       or die("Could not read vmx file!");
    my @string = grep( /^$ethUnitNum.present/, <FILE> );
    $data = pop(@string);
    close(FILE);
      } else    # grepping the line in linux
      {

    $command = "start shell command \"grep -i \\\"^[' ']*$ethUnitNum\\."
       . "present = \\\" \\\"$self->{_absoluteVMXPath}\\\" | sort -u \"
      wait returnstdout stderrtostdout";
    $service = "process";
    ( $ret, $data ) =
       $self->{stafHandle}
       ->runStafCmd( $self->{_justHostIP}, $service, $command );
    if ( $ret eq FAILURE ) {
       TestError "error with staf $command \n";
       VDSetLastError("ESTAF");
       return FAILURE;
    }
      }

      # Logic to parse values of ethernetX.present and check if its false
      if ( $data =~ /^\s*ethernet\d+.present = (.*?)\n/ ) {
    my $status = $1;
    $status =~ s/(\")//g;
    chomp($status);
    if ( lc($status) eq "false" ) {
       $passed = 1;
    } else {
       $passed = 0;
       TestError("$ethUnitNum.present is not saying False\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
      } else {
    $passed = 0;
    TestError("error parsing status of $ethUnitNum\n");
    VDSetLastError("EFAIL");
    return FAILURE;
      }

      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#-----------------------------------------------------------------------------
#  VMOpsGetPowerState
#  Gets the Power State of the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed along with powerstate value
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsGetPowerState
{
   my $self       = shift;
   my $passed     = 0;
   my $testobj    = 0;
   my $powerstate = 0;
   ( $passed, $testobj ) = $self->TestSetup(TP_HTU_HANDLE_USE_VM);
   if ($passed) {
      TestInfo "VMOps Get Power state Started";
      $powerstate = $testobj->{param}->{ACTUAL_POWER_STATE};

      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS, $powerstate;
}

#-----------------------------------------------------------------------------
#  VMOpsIsVMRunning
#  Check if VM is running or not
#
#  Input:
#       none
#
#  Output:
#       1 if VM is running
#       0 if not running
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------

sub VMOpsIsVMRunning
{
   my $self = shift;
   my $powerState = $self->VMOpsGetPowerState();
   if ($powerState eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if($powerState & VIX_POWERSTATE_POWERED_ON) {
      return 1;
   } else {
      return 0;
   }
}

#-----------------------------------------------------------------------------
#   VMOpsConnectvNICCable
#
#  Algorithm:
#  Using VIX API.
#
#  Input:
#       1) MAC address of the vNIC you want to connect.
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       Yes. GOS should be up and running(Completely booted) or else the
#       behaviour will be inconsistent.
#
#-----------------------------------------------------------------------------
sub VMOpsConnectvNICCable()
{
   my $self   = shift;
   my $passed = 0;
   my $deviceName;
   my $macAddress;

   # Check if staf handle is created
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if staf is running on host
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ( lc( $self->{_productType} ) eq "esx" ) {

      # For cable disconnect to work VIX requires 2 lines in VMX file.
      $self->InsterBackdoorLineESX();
   }

   # Mapping from MAC address to ethernetX
   if ( 1 == @_ ) {
      $macAddress = shift;
      $deviceName =
    VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP}, $self->{_absoluteVMXPath},
    $macAddress );
   } else {
      TestError "VM Ops Connect vNIC called without NIC name . Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Connect vNIC Cable started";
      TestInfo "Calling a ConnectNamedDevice on $deviceName";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->ConnectNamedDeviceImpl( $testobj->GetHandleToUse(),
    $deviceName, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Connect vNIC Cable Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Connect vNIC Cable  Failed";
    VDSetLastError("ENETDOWN");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsDisconnectvNICCable
#
#  Algorithm:
#  Using VIX API.
#
#  Input:
#       1) MAC address of the vNIC you want to disconnect.
#       2) stafIP: IP address to check for STAF,
#                  If this parameter is specified, this method will
#                  wait for staf to be running inside the
#                  guest before disconnecting cable
#                  (Optional)
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       Yes. GOS should be up and running(Completely booted) or else the
#       behaviour will be inconsistent.
#
#-----------------------------------------------------------------------------
sub VMOpsDisconnectvNICCable()
{
   my $self   = shift;
   my $macAddress = shift;
   my $stafIP = shift;
   my $passed = 0;
   my $deviceName;

   # Check if staf handle is created
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if staf is running on host
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      TestError "STAF not running on $self->{_justHostIP} ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ( lc( $self->{_productType} ) eq "esx" ) {
      $self->InsterBackdoorLineESX();
   }

   if (defined $stafIP) {
      TestInfo "Waiting for STAF to be running inside the guest $stafIP";
      my $ret = $self->{stafHandle}->WaitForSTAF($stafIP);
      if ($ret ne SUCCESS) {
         TestError "STAF is not running on $stafIP";
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   if (defined $macAddress) {
      TestInfo "VMOpsDisconnectvNICCable: hostIP: " . $self->{_justHostIP} .
               " vmx path:" . $self->{_absoluteVMXPath} . " mac address: " .
               $macAddress;
      $deviceName =
       VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP}, $self->{_absoluteVMXPath},
                             $macAddress );
      if ($deviceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      TestError "VM Ops Connect vNIC called without NIC name . Exiting...";
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Disconnect vNIC Cable started";
      TestInfo "Calling a DisconnectNamedDevice on $deviceName";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->PowerOn( $testobj->GetHandleToUse(),
    VIX_VMPOWEROP_LAUNCH_GUI, 0, \%param );
      $passed =
    $testobj->GetManagedVM()
    ->DisconnectNamedDeviceImpl( $testobj->GetHandleToUse(),
    $deviceName, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Disconnect vNIC Cable Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Disconnect vNIC Cable  Failed";
    VDSetLastError("EOPFAILED");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#-----------------------------------------------------------------------------
#  VMOpsPowerOff
#  Powers off the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsPowerOff
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Power Off Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->PowerOff( $testobj->GetHandleToUse(), POWEROPTION, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Power Off Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Power Off Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $passed;
}

#-----------------------------------------------------------------------------
#  VMOpsPowerOn
#  Powers on the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsPowerOn
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Power On Started";

      #      my %param = undef;
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->PowerOn($testobj->GetHandleToUse(),
                                                  VIX_VMPOWEROP_LAUNCH_GUI,
                                                  0,
                                                  \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Power On Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Power On Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsResume
#  Powers on the VM which is a resume operation if the VM is suspended.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsResume
{
   my $self = shift;
   $self->VMOpsPowerOn;
}

#-----------------------------------------------------------------------------
#  VMOpsReset
#  Resets the VM.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsReset()
{
   my $self     = shift;
   my $passed   = 0;
   my $vmHandle = undef;
   my $testobj  = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Reset Started";
      $self->ClearGlobalParam();
      $vmHandle = $testobj->GetVMHandle();
      $passed =
    $testobj->GetManagedVM()->Reset( $testobj->GetHandleToUse(),
                                                 VIX_VMPOWEROP_NORMAL,
                                                 \%param );
      if ($passed) {
    TestInfo("VMOps Reset Passed");
    $testobj->SetOutcome("PASS");
      } else {
    TestError("VMOps Reset Failed");
    $testobj->SetOutcome("FAIL");
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsSuspend
#  Suspends the VM.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsSuspend
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Suspend Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->Suspend( $testobj->GetHandleToUse(), VIX_VMPOWEROP_NORMAL, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Suspend Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Suspend Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#-----------------------------------------------------------------------------
#  VMOpsTakeSnapshot
#  Just takes snapshot
#
#
#  Input:
#       SnapshotName   You should give a name while taking snapshot
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsTakeSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $snapshotName;
   if ( 1 <= @_ ) {
      $snapshotName = shift;
   } else {
      TestError
    "VM Ops Take Snapshot called without a snapshot name. Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Take Snapshot Started";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->CreateSnapshot(
    $testobj->GetHandleToUse(),
    $snapshotName, $snapshotName, DEFAULT_CREATE_SNAPSHOT_OPTION,
    VIX_INVALID_HANDLE, \%param
      );

      if ($passed) {
    $createSnapshotHandle = $param{ACTUAL_SNAPSHOT_HANDLE};
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Take Snapshot Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Take Snapshot Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsRevertSnapshot
#  Reverts to the given snapshot
#
#  Input:
#       SnapshotName: Name of the snapshot to revert. If not
#                     provided then current snapshot will be used.
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsRevertSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $snapshotName         = shift;
   my $passed               = 0;
   my $testobj              = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );

   if (defined $snapshotName) {
      ($passed,$createSnapshotHandle ) =
         $self->GetNamedSnapshot($snapshotName, $testobj);
   } else {
      #
      # if snapshot name is not given then get the current snapshot, if any
      # exists.
      #
      $self->ClearGlobalParam();
      ($passed) =
         $testobj->GetManagedVM()->GetCurrentSnapshot($testobj->GetHandleToUse(),
                                                      \%param);
      $createSnapshotHandle = $param{ACTUAL_CURRENTSNAPSHOT_HANDLE};
   }

   # If there exists no snapshot, then return SUCCESS
   if (!$createSnapshotHandle) {
      TestWarning "Snapshot handle undefined or no snapshot exists to revert";
      return SUCCESS;
   }

   if ($passed) {
      TestInfo "VMOps Revert Snapshot Started";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;

      #      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF;
      #      $param{EXPECTED_TOOL_STATE}  = VIX_TOOLSSTATE_UNKNOWN;
      $passed = $testobj->GetManagedVM()->RevertToSnapshot(
    $testobj->GetHandleToUse(),
    $createSnapshotHandle, DEFAULT_REVERT_SNAPSHOT_OPTION,
    VIX_INVALID_HANDLE, \%param
      );
      if ($passed) {

    # ReleaseHandle($createSnapshotHandle);
    # $createSnapshotHandle = VIX_INVALID_HANDLE;
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Revert Snapshot Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Revert Snapshot Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsDeleteSnapshot
#  Delete the snapshot with given name
#
#  Input:
#       SnapshotName: Name of the snapshot you want to delete. If not
#                     provided then current snapshot will be used.
#
#  Output:
#       SUCCESS if passed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsDeleteSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $snapshotName = shift;
   my $passed               = 0;
   my $testobj              = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_ON | VIX_POWERSTATE_POWERED_OFF );
   if (defined $snapshotName) {
      ($passed,$createSnapshotHandle ) =
         $self->GetNamedSnapshot( $snapshotName, $testobj );
   } else {
      #
      # if snapshot name is not given then get the current snapshot, if any
      # exists.
      #
      $self->ClearGlobalParam();
      ($passed) =
         $testobj->GetManagedVM()->GetCurrentSnapshot($testobj->GetHandleToUse(),
                                                      \%param);
      $createSnapshotHandle = $param{ACTUAL_CURRENTSNAPSHOT_HANDLE};
   }

   # If there exists no snapshot, then return SUCCESS
   if (!$createSnapshotHandle) {
      TestWarning "Snapshot handle undefined or no snapshot exists to delete";
      return SUCCESS;
   }

   if ($passed) {
      TestInfo "Test Started";
      $self->ClearGlobalParam();
      for (keys %param) {
        delete $hash{$_};
      }
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed =
    $testobj->GetManagedVM()->RemoveSnapshot( $testobj->GetHandleToUse(),
    $createSnapshotHandle, DEFAULT_REMOVE_SNAPSHOT_OPTION, \%param );
      if ($passed) {

    #         ReleaseHandle($createSnapshotHandle);
    #         $createSnapshotHandle = VIX_INVALID_HANDLE;
    $testobj->SetOutcome("PASS");
    TestInfo "Test Passed";
    $passed = 1;
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "Test Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsDeleteAllSnapshots
#  Deletes all the snapshots of the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsDeleteAllSnapshots()
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $vmHandle             = undef;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Delete All snapshots started";
      $vmHandle = $testobj->GetVMHandle();
      my $numSnapshotsRemoved = 0;
      TestInfo "Removing all existing snapshots in VMOps";
      while ($passed) {
    $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
    $passed =
       $testobj->GetManagedVM->GetNumRootSnapshots( $vmHandle, \%param );
    if ( $passed && $param{ACTUAL_NUMROOTSNAPSHOTS} > 0 ) {
       $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
       $passed =
          $testobj->GetManagedVM->GetRootSnapshot( $vmHandle, 0, \%param );
       if ($passed) {
          $createSnapshotHandle = $param{ACTUAL_ROOTSNAPSHOT_HANDLE};
          $self->ClearGlobalParam();
         $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
          $passed =
        $testobj->GetManagedVM->RemoveSnapshot( $vmHandle,
        $createSnapshotHandle, DEFAULT_REMOVE_SNAPSHOT_OPTION,
        \%param );
          if ($passed) {
        $numSnapshotsRemoved = $numSnapshotsRemoved + 1;
          } else {
        TestError "Removing of snapshot failed";
          }
       } else {
          TestError "Removing of snapshot failed";
       }
    } else {
       last;
    }
      }    # end of while
      TestInfo "Removed " . $numSnapshotsRemoved . " snapshots.";
   }
   if ($passed) {
      TestInfo "VMOps Delete All snapshots  Passed";
   } else {
      TestInfo("VMOps Delete All snapshots  Failed");
      $testobj->SetOutcome("SETUPFAIL");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsWaitForToolsInGuest
#  TODO: Yet to be fully coded and testing. Will work on it if we have requirement for it.
#  VMOpsInstallTools
#  From VIX API Documentation
#  If the guest operating system has the autorun feature enabled, the installer starts
#  automatically. Many guest operating systems require manual intervention to complete
#  the Tools installation. You can connect a console window to the virtual machine and
#  use the mouse or keyboard to complete the procedure as described in the documentation
#  for your VMware platform product.
#  I did replace the second parameter with VIX_VM_SUPPORT_TOOLS_INSTALL
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsInstallTools()
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Install Tools Started";
      $passed =
    $testobj->GetManagedGuest()
    ->InstallTools( $testobj->GetVMHandle(), VIX_VM_SUPPORT_TOOLS_INSTALL,
    undef, \%param );

      # I guess you can check if the tools are up to date using this
      # $param{EXPECTED_ERROR} = VIX_E_TOOLS_INSTALL_ALREADY_UP_TO_DATE;
      # TODO: ask kishore if he need such functionality
      if ($passed) {
    TestInfo "VMOps Install Tools Passed";
      } else {
    TestError "VMOps Install Tools Failed";
    $testobj->SetOutcome("SETUPFAIL");
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsWaitForToolsInGuest
#  TODO: Yet to be fully coded and testing. Will work on it if we have requirement for it.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsWaitForToolsInGuest
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Wait For Tools In Guest Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedGuest()
    ->WaitForToolsInGuest( $testobj->GetHandleToUse(),
    TIMEOUT_WAIT_FOR_TOOLS_IN_SEC, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Wait For Tools In Guest Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Wait For Tools In Guest Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}



#-----------------------------------------------------------------------------
#  GetNamedSnapshot
#  Gives the handle of snapshot with a specific name.
#
#  Input:
#       testObj        bunch of foundary qa handles anchored on host, vm, snaopshot, job
#       SnapshotName   Name of the snapshot you want to get handle of
#
#  Output:
#       SUCCESS if passed along with the handle to named snapshot.
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub GetNamedSnapshot($$)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $snapshotName;
   if ( 2 == @_ ) {
      $snapshotName = shift;
      $testobj      = shift;
   } else {
      TestError
"VM Ops Get Named Snapshot Called without name or testobj. Exiting....";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   TestInfo "VMOps Get Named Snapshot started ";
   $self->ClearGlobalParam();

   $passed =
      $testobj->GetManagedVM()
      ->GetNamedSnapshot( $testobj->GetHandleToUse(), $snapshotName, \%param );
   if ($passed) {
      $testobj->SetOutcome("PASS");
      $createSnapshotHandle = $param{ACTUAL_NAMEDSNAPSHOT_HANDLE};
      TestInfo "Test Passed";
   } else {
      $testobj->SetOutcome("FAIL");
      TestError "Test Failed";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $passed, $createSnapshotHandle;
}


########################################################################
# GetOptionsFromString --
#
# It just throw command at command promot so that foundary qa source code
# can pick it up.
# They dont have any function to invoke their module programmatically
#
# Input:
#       testObj bunch of foundary qa handles anchored on host, vm, snaopshot,
#       job
#
# Results:
#       none
#
# Side effects:
#       none
#
########################################################################

sub GetOptionsFromString
{
   my $self    = shift;
   my $testobj = shift;
   my $string = "$self->{_apiVersion} $self->{_productType} $self->{_host} " .
                "$self->{_port} $self->{_username} $self->{_password} " .
                "\"$self->{_vmxPath}\"";
   local @ARGV = Text::ParseWords::shellwords($string);
   $testobj->ParseCommandLine();
}


########################################################################
#  TestSetup
#  I will create my default handle as VM, as most of my operations are on VM
#  Other types of handles are host, job, Snapshot.
#  I hide the mechanism of managing handles from users of this API.
#
#  Algorithm:
#  It just throw command at command promot so that foundary qa source code can pick it up.
#  They dont have any function to invoke their module programmatically. They take arguments from command line only
#
#  Input:
#       1) Default handle to use (from VM, host, job, Snapshot.)
#       2) Initial Power State
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#
#  Side effects:
#       none
#
########################################################################

sub TestSetup
{
   my $self    = shift;
   my $testobj = undef;
   TestInfo "Calling new on TestBase";
   my $module = "perl::foundryqasrc::TestBase";
   eval "require $module";
   if ($@) {
      TestError "unable to load module $module:$@";
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }
   $testobj = $module->new(shift, shift);
   $self->GetOptionsFromString($testobj);
   my $passed = 0;
   TestInfo "Handle Creation Started";
   $passed = $testobj->MasterTestSetup();

   if ($passed) {
      TestInfo "Handle Creation Passed";
   } else {
      TestInfo("Handle Creation Failed");
      $testobj->SetOutcome("SETUPFAIL");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $passed, $testobj;
}

#-----------------------------------------------------------------------------
#  TestCleanup
#  Removes all the handles created by TestSetup
#
#
#  Input:
#       testObj     bunch of foundary qa handles anchored on host, vm, snaopshot, job
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub TestCleanup($)
{
   my $self    = shift;
   my $testobj = undef;
   my $passed  = 0;
   if ( 1 == @_ ) {
      $testobj = shift;
   } else {
      TestInfo "I need to know the testObj to clean it up";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   TestInfo "Handle Deletion Started";
   $passed = $testobj->MasterTestCleanup();
   if ($passed) {
      TestInfo "Handle Deletion Passed";
   } else {
      $testobj->SetOutcome("CLEANUPFAIL");
      TestInfo "Handle Deletion Failed";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $passed;
}

1;

