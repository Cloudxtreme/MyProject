##########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
##########################################################################

package VDNetLib::Common::VDAutomationSetup;

##########################################################################
#
# This perl package has all methods used for doing network automation
# setup.
#
# It can't be used to install VET/STAF on hosts (Windows/Linux), it can
# only be used to install software like winpcap on the guests, which in
# turn use STAF on the remote host/VM.
#
# The prerequisite for using this is, the remote VM/Host should have
# STAF running.
#
# This uses RemoteAgent package, which internally uses STAF to talk to
# remote hosts/VMs. So STAF/VET is a pre-requisite on hosts
# (Windows/Linux) for using this package.
#
# For ESX, it uses vmrun command with -H (host) option to talk to remote
# ESX host. vmrun internally uses hostd deamon on remote ESX host for
# communication. So users don't have to install VET/STAF on ESX hosts.
#
# There should be a automation directory on remote hosts containing
# VDAutomationSetup, RemoteAgent.pm, RemoteAgent.pl and .sh/.bat scripts
# Since RemoteAgent from local machine invokes the RemoteAgent methods
# in remote host. On VMs, we copy all the required files before
# the installation of VET/STAF so subsequent invocation of STAF on
# guests for doing other setup required for running network automation
# tests uses the locally copied files.
#
# In the comments wherever it refers to VET/STAF installation, it means
# VET/STAF/VIX/Java/VMstaf installation.
#
##########################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use Getopt::Long;
use File::Copy;

# VMware packages
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::RemoteAgent_Storage;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

# Built-in packages
BEGIN {
   eval "use POSIX qw(sys_utsname_h)";
   eval "use Win32::TieRegistry";
}

# Global variables
# It is assumed startup directory is same for all windows flavors
# TODO: C:\\User\Administrator for vista and win7 - review comment by
# Gagan
my @ListOfMachines = ();
my $Registry = $Win32::TieRegistry::Registry;

##########################################################################
# new --
#
# Input:
#	vmip - IP of the VM
#	os - os type of VM
#	vmx - vmx file corresponding to VM
#	host - host IP address
#	hostType - esx, linux, or windows
#
# Results:
#
#       Returns blessed reference to this class
#
# Side effects:
#       none
#
##########################################################################

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $mac = shift;

   my %param = ();
   my @args;
   my $self    = {};
   my $remote;
   my %pkgArgs;
   my %macInfo = ();

   #
   # if %macInfo is directly assigned %{$mac} and if $mac is undefined
   # the code exits at the line.  If defined check is required.
   #
   if (not defined $mac) {
      $vdLogger->Error("Invalid params:\n" . Dumper($mac));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # NOTE: if $mac is not defined, the code exists here, tried to
   # capture the error via eval, but even eval is unable to catch it
   #
   %macInfo = %$mac;

   # Saving the testbed info for later use
   push(@ListOfMachines, $mac);

   #
   # We only need RemoteAgent object for installing VET/STAF/VIX/Perl
   # /Java/VMstaf on VMs in Windows and Linux Guests and doing setup
   # stuff on VMs.
   # RemoteAgent internally uses STAF to talk to remote host or VMs.
   # For VMs in ESX host we can use vmrun -T esx -H https://host/sdk
   # to run commands from master controller and install VET/STAF
   # in the guests.  For installing VET/STAF on master controller
   # too we don't need to instantiate RemoteAgent object as this is
   # like local installation.
   #
   if (defined $mac->{ip}) {
      $remote = 'VDNetLib::Common::RemoteAgent_Storage';
      my $remoteIp = $mac->{ip};
      my $osType;
      if ( defined $mac->{hostType} ) {
         if ($mac->{hostType} =~ /linux|esx|vmkernel/i) {
            $osType = VDNetLib::Common::GlobalConfig::OS_LINUX;
         } elsif ( $mac->{hostType} =~ /win/i ) {
            $osType = VDNetLib::Common::GlobalConfig::OS_WINDOWS;
         } else {
            $vdLogger->Error("Unsupported os");
            VDSetLastError("EOSNOTSUP");
            return FAILURE;
         }
      } else {
         if ( $mac->{os} =~ /linux/i ) {
            $osType = VDNetLib::Common::GlobalConfig::OS_LINUX;
         } elsif ( $mac->{os} =~ /win/i ) {
            $osType = VDNetLib::Common::GlobalConfig::OS_WINDOWS;
         } else {
            $vdLogger->Error("Unsupported os");
            VDSetLastError("EOSNOTSUP");
            return FAILURE;
         }
      }
      $mac->{ip} = undef;
      %pkgArgs = %$mac;
      @args = (remoteIp=>$remoteIp,pkgArgs=>[\%pkgArgs]);
      $self = new VDNetLib::Common::RemoteAgent_Storage(@args);
      $self = $remote->new(@args);
      if (ref($self) ne "VDNetLib::Common::RemoteAgent_Storage") {
          $vdLogger->Error("Instantiation of RemoteAgent failed");
          VDSetLastError("EINVALID");
          return FAILURE;
      }
   } else {
      $self->{isSetupDone} = 0;
      $remote = $class;
   }
   # Copy each key in testbed info to $self to we can use directly
   foreach my $key ( keys %macInfo ) {
      $self->{$key} = $macInfo{$key} if not $self->{$key};
   }
   bless $self, $remote;
   return $self;
}


########################################################################
# SetPlaintextPassword --
#       This methods enables/disables plaintext password registry key in
#       windows guests
#
# Input:
#       Operation (enable or disable)
#
# Results:
#	SUCCESS if operation performed without error else FAILURE
#
# Side effects:
#	changes the registry key
#
########################################################################

sub SetPlaintextPassword
{
   my $self = shift;
   my $operation = shift;

   if ( not defined $operation ) {
      $vdLogger->Error("Undefined operation passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ( !(($operation =~ /enable/i) ||
          ($operation =~ /disable/i)) ) {
      $vdLogger->Error("$operation not supported\nSupported operations: " .
                   "enable/disable");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $value;
   my $member = "enableplaintextpassword";


   my $key = "LMachine\\SYSTEM\\CurrentControlSet\\Services\\".
             "lanmanworkstation\\parameters\\";

   my $plaintextKey = $Win32::TieRegistry::Registry->{$key};

   if (not defined $plaintextKey) {
      $vdLogger->Error("SetPlaintextPassword: Can't find the Windows " .
                   "Registry key: $^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $value = ( $operation =~ /enable/i ) ? 1 : 0;

   $plaintextKey->{"$member"} = [pack("L", $value), "REG_DWORD"];

   if ( ($plaintextKey->{"$member"} eq "0x00000001") &&
        ($value == 1) ) {
      $vdLogger->Info("Enabled plaintext password registry key successfully");
      return SUCCESS;
   } elsif ( ($plaintextKey->{"$member"} eq "0x00000000") &&
             ($value == 0) ) {
      $vdLogger->Info("Disabled plaintext registry key successfully");
      return SUCCESS;
   }
   $vdLogger->Error("Failed to updated registry key to $operation plaintext password");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
# IsPlaintextPasswordEnabled --
#       This methods checks if plaintext password is enabled
#
# Input:
#       none
#
# Results:
#	SUCCESS if enabled, else FAILURE
#
# Side effects:
#	None
#
########################################################################

sub IsPlaintextPasswordEnabled
{
   my $key = "LMachine\\SYSTEM\\CurrentControlSet\\Services\\".
                  "lanmanworkstation\\parameters\\";

   my $plaintextKey = $Win32::TieRegistry::Registry->{$key};

   if (not defined $plaintextKey) {
      $vdLogger->Error("IsPlaintextPasswordEnabled: Can't find the Windows " .
                   "Registry key: $^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $member = "enableplaintextpassword";
   my $value = $plaintextKey->{"$member"};

   if ($value eq "0x00000001") {
      $vdLogger->Info("Plaintext passwd is enabled");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Info("Plaintext passwd is disabled");
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
# SetAutoLogon --
#	Enables/Disables autologon in windows guests
#
# Input:
#       none
#
# Results:
#	SUCCESS for success and FAILURE if there is a failure
#
# Side effects:
#	changes the registry key
#
########################################################################

sub SetAutoLogon
{
   my $self = shift;
   my $operation = shift;

   if (not defined $operation) {
      $vdLogger->Error("Undefined operation passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ( !(($operation =~ /enable/i) ||
          ($operation =~ /disable/i)) ) {
      $vdLogger->Error("$operation not supported\nSupported operations: " .
                   "enable/disable");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $value = ( $operation =~ /enable/i ) ? "1" : "0";

   my $regKey = "LMachine\\SOFTWARE\\Microsoft\\Windows " .
                "NT\\CurrentVersion\\Winlogon\\";

   my $winlogonKey = $Registry->{"$regKey"};

   if (not defined $winlogonKey) {
      $vdLogger->Error("SetAutoLogon: Can't find the Windows Registry key: $^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $autoLogon = "AutoAdminLogon";
   $winlogonKey->{"$autoLogon"}=[$value, "REG_SZ"];

   $vdLogger->Info("value of autologn key is $winlogonKey->{$autoLogon}");

   if ($value eq "0") {
      if ( $winlogonKey->{"$autoLogon"} == $value ) {
         $vdLogger->Info("Updated autologon reg keys to $operation");
         return SUCCESS;
      } else {
         $vdLogger->Error("Updating autologon reg keys to $operation failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   my $user = "DefaultUserName";
   my $userValue = VDNetLib::Common::GlobalConfig::DEFAULT_WINDOWS_USER;
   my $passwdValue = VDNetLib::Common::GlobalConfig::DEFAULT_WINDOWS_PASSWORD;
   my $forceAutoLogon = "ForceAutoLogon";

   $winlogonKey->{"$user"}=[$userValue, "REG_SZ"];
   # strip of escape chars
   $passwdValue =~ s/\\//g;
   $winlogonKey->SetValue( "DefaultPassword", $passwdValue );

   $vdLogger->Debug("user: $winlogonKey->{$user}, " . 
                    "uservalue: $winlogonKey->{$userValue} " .
                    "forceAutoLogon: $winlogonKey->{$forceAutoLogon} " .
                    "autoLogon: $winlogonKey->{$autoLogon}");

   if ( ($winlogonKey->{"DefaultPassword"} eq $passwdValue) and
        ($winlogonKey->{"$user"} eq $userValue) and
        ($winlogonKey->{"$autoLogon"} == $value) ) {
      $vdLogger->Info("Enabled autologon successfully");
      return SUCCESS;
   } else {
      $vdLogger->Error("Enabling autologon failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# IsAutoLogonEnabled --
#	Checks if autologon is enabled
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE if its not enabled
#
# Side effects:
#	None
#
########################################################################

sub IsAutoLogonEnabled
{
   my $regKey = "LMachine\\SOFTWARE\\Microsoft\\Windows " .
                "NT\\CurrentVersion\\Winlogon\\";
   my $winlogonKey = $Registry->{"$regKey"};

   if (not defined $winlogonKey) {
      $vdLogger->Error("IsAutoLogonEnabled: Can't find the Windows Registry key: $^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $userValue = $winlogonKey->{"DefaultUserName"};
   my $passwdValue = $winlogonKey->{"DefaultPassword"};
   my $autoLogon = $winlogonKey->{"AutoAdminLogon"};

   $vdLogger->Info("uservalue: $userValue password: $passwdValue " .
         "autoLogon: $autoLogon");

   my $defaultpasswd = VDNetLib::Common::GlobalConfig::DEFAULT_WINDOWS_PASSWORD;
   $defaultpasswd =~ s/\\//g;
   if ( ($userValue eq VDNetLib::Common::GlobalConfig::DEFAULT_WINDOWS_USER) and
	($passwdValue eq $defaultpasswd) and
	($autoLogon eq "1" ) ) {
      $vdLogger->Info("Autologon is enabled");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Info("Autologon is not enabled: $autoLogon");
      # no need to set any error, because FAILURE is the output of the function
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
# SetEventTracker --
#	Enables/Disables event tracker in win2k3 and win2k8 guests
#
# Input:
#       Operation - disable/enable
#
# Results:
#	SUCCESS if the operation is performed successfully else FAILURE
#
# Side effects:
#	changes the registry key
#
########################################################################

sub SetEventTracker
{
   my $self = shift;
   my $operation = shift;

   if (not defined $operation) {
      $vdLogger->Error("SetEventTracker: Undefined operation passed as parameter");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ( !(($operation =~ /enable/i) ||
          ($operation =~ /disable/i)) ) {
      $vdLogger->Error("$operation not supported\nSupported operations: " .
                   "enable/disable");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $value = ( $operation =~ /enable/i ) ? 1 : 0;

   my $regKey = "LMachine\\SOFTWARE\\Microsoft\\Windows\\" .
                "CurrentVersion\\Reliability\\";
   my $key1 = $Registry->{$regKey};

   if (not defined $key1) {
      my $regAddCmd = 'reg add "LMachine\\SOFTWARE\\Microsoft\\' .
                      'Windows\\CurrentVersion\\Reliability\\" ' .
                      '/v ShutdownReasonUI /t REG_DWORD /d 0x0 /f';
      `$regAddCmd`;
      $key1 = $Registry->{$regKey};
   }

   if (not defined $key1) {
      $vdLogger->Error("SetEventTracker: Can't find the Windows Registry key1: ".
            "$^E");
      VDSetLastError("ECMD");
      return FAILURE;
   }

   $regKey = "LMachine\\SOFTWARE\\Policies\\Microsoft\\Windows " .
             "NT\\Reliability\\";
   my $key2 = $Registry->{$regKey};

   if (not defined $key2) {
      my $regAddCmd = 'reg add "LMachine\\SOFTWARE\\Policies\\Microsoft\\' .
                      'Windows NT\\Reliability\\" ' .
                      '/v ShutdownReasonUI /t REG_DWORD /d 0x0 /f';
      `$regAddCmd`;
      $key2 = $Registry->{$regKey};
   }

   if (not defined $key2) {
      $vdLogger->Error("SetEventTracker: Can't find the Windows Registry key2: $^E");
      VDSetLastError("ECMD");
      return FAILURE;
   }

   my $shutdownReasonUI = "ShutdownReasonUI";
   my $shutdownReason = "ShutdownReasonOn";

   $key1->{"$shutdownReasonUI"} = [pack("L", $value), "REG_DWORD"];
   $key2->{"$shutdownReasonUI"} = [pack("L", $value), "REG_DWORD"];
   $key2->{"$shutdownReason"}   = [pack("L", $value), "REG_DWORD"];

   $vdLogger->Debug("$key1->{$shutdownReasonUI} $key2->{$shutdownReasonUI} " .
                    "$key2->{$shutdownReason}");

   if ( ($key1->{"$shutdownReasonUI"} =~ /$value$/) and
        ($key2->{"$shutdownReasonUI"} =~ /$value$/) and
        ($key2->{"$shutdownReason"} =~ /$value$/) ) {
      $vdLogger->Info("Updated reg keys successfully to $operation EventTracker");
      return SUCCESS;
   } else {
      $vdLogger->Error("Updating reg keys to $operation EventTracker failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# IsEventTrackerDisabled --
#	Checks if event tracker is disabled in win2k3 and win2k8 guests
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE if its not disabled
#
# Side effects:
#	None
#
########################################################################

sub IsEventTrackerDisabled
{
   my $regKey = "LMachine\\SOFTWARE\\Microsoft\\Windows\\" .
                "CurrentVersion\\Reliability\\";

   my $key1 = $Registry->{$regKey};
      $vdLogger->Info("$regKey key2: $key1");

   if (not defined $key1) {
      $vdLogger->Error("IsEventTrackerDisabled: Can't find the Windows " .
            "Registry key1: $^E");
      VDSetLastError("ECMD");
      return FAILURE;
   }

   $regKey = "LMachine\\SOFTWARE\\Policies\\Microsoft\\Windows" .
             " NT\\Reliability\\";

   my $key2 = $Registry->{$regKey};

   if (not defined $key2) {
      $vdLogger->Error("IsEventTrackerDisabled: Can't find the Windows Registry key2: ".
            "$^E");
      `reg add "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\Reliability" /v ShutdownReasonUI /t REG_DWORD /d 0x0 /f`;
   }

   $regKey = "LMachine\\SOFTWARE\\Policies\\Microsoft\\Windows" .
             " NT\\Reliability\\";

   $key2 = $Registry->{$regKey};

   if (not defined $key2) {
      $vdLogger->Error("IsEventTrackerDisabled: Can't find the Windows Registry key2: ".
            "$^E");
      VDSetLastError("ECMD");
      return FAILURE;
   }

   my $shutdownReasonUIv1 = $key1->{"ShutdownReasonUI"};
   my $shutdownReasonUIv2 = $key2->{"ShutdownReasonUI"};
   my $shutdownReason = $key2->{"ShutdownReasonOn"};

   $vdLogger->Info("IsEventTrackerDisabled: ReasonUIv1: $shutdownReasonUIv1 " .
                  "ReasonUIv2: $shutdownReasonUIv2 shutdownReason: $shutdownReason");

   if ( ( $shutdownReasonUIv1 eq "0x00000000" ) and
        ( $shutdownReasonUIv2 eq "0x00000000" ) and
        ( $shutdownReason eq "0x00000000" )) {
      $vdLogger->Info("EventTracker is disabled");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Info("EventTracker is not disabled");
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
# ConfigFullDump --
#	Configures windows guest to dump full memory when it crashes
#
# Input:
#       none
#
# Results:
#	SUCCESS for success and FAILURE if there is a failure
#
# Side effects:
#	changes System Properties -> Advanced -> Startup and Recovery ->
#	Settings -> write debug info to "complete memory dump"
#
########################################################################

sub ConfigFullDump
{
   # This will set "write debug info -> complete memory dump"
   my $cmd_op = `wmic recoveros set DebugInfoType = 1`;
   my $where = index($cmd_op, "successful");
   if ($where > 0) {
      $vdLogger->Info("Succesfully configured for full memory dump");
      return SUCCESS;
   } else {
      $vdLogger->Error("Configuring full dump failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# ConfigDefaultMemoryDump --
#	Configures windows guest to dump only kernel memory when it
#	crashes
#
# Input:
#       none
#
# Results:
#	SUCCESS for success and FAILURE if there is a failure
#
# Side effects:
#	changes System Properties -> Advanced -> Startup and Recovery
#	-> Settings -> write debug info to "kernel memory dump"
#
########################################################################

sub ConfigDefaultMemoryDump
{
   # This will set "write debug info -> kernel memory dump"
   my $cmd_op = `wmic recoveros set DebugInfoType = 2`;
   my $where = index($cmd_op, "successful");
   if ($where > 0) {
      $vdLogger->Info("Succesfully configured for kermel memory dump");
      return SUCCESS;
   } else {
      $vdLogger->Error("Configuring to kernel memory dump failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# IsFullMemoryDumpConfigured --
#	Checks if full memory dump is configured
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE otherwise
#
# Side effects:
#	None
#
########################################################################

sub IsFullMemoryDumpConfigured
{
   my $cmd_op = `wmic recoveros get DebugInfoType`;
   my $where = index($cmd_op, "1");
   if ($where > 0) {
      $vdLogger->Info("OS is configured for full memory dump");
      return SUCCESS;
   } else {
      $vdLogger->Error("OS is not configured for full memory dump");
      return FAILURE;
   }
}


########################################################################
# SetHibernation --
#	Enables/Disables hibernation on windows guests
#
# Input:
#       Operation - enable or disable
#
# Results:
#	SUCCESS for success FAILURE for failure
#
# Side effects:
#	Changes guest OS power options
#
########################################################################

sub SetHibernation
{
   my $self = shift;
   my $operation = shift;

   if ( not defined $operation ) {
      $vdLogger->Error("Undefined operation passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ( $operation !~ /enable/i ||
        $operation !~ /disable/i ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $value = ( $operation =~ /enable/i ) ? "on" : "off";
   system("powercfg /hibernate $value");
   return SUCCESS;
}


########################################################################
# CheckAdminAccount --
#	Checks if there is an user called 'Administrator' with admin
#	privileges on windows guests
#
# Input:
#       none
#
# Results:
#	SUCCESS if Admin Account is configured else FAILURE
#
# Side effects:
#	None
#
########################################################################

sub CheckAdminAccount
{
   my $cmd_op = `net user VDNetLib::Common::GlobalConfig::DEFAULT_WINDOWS_USER`;
   my $where = index($cmd_op, "Administrators");

   if ($where > 0) {
      $vdLogger->Info("Administrator user is available and has admin privileges");
      return SUCCESS;
   } else {
      $vdLogger->Error("No Administrator user");
      return FAILURE;
   }
}


########################################################################
# CopyDisableFoundNewHardwareWizard --
#	Adds a vbs script to the windows startup directory so after
#	reboot when you add a new device it doesn't show
#	FoundNewHardware wizard.
#	The vbs script has the code to force the default behavior when
#	FoundNewHardware wizard comes up so the user doesn't have to
#	provide any input.
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, failure otherwise
#
# Side effects:
#	Adds a file to windows startup directory
#
########################################################################

sub CopyDisableFoundNewHardwareWizard
{
   my $self = shift;
   my $binPath;
   my $startupDir;
   my $gc = new VDNetLib::Common::GlobalConfig;

   if ( $self->{os} =~ /win/i ) {
      $binPath = $gc->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $binPath = $binPath . "x86_32\\windows\\";
   } else {
      # this is only applicable to windows
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   my $file = "hw_wizard\.vbs";
   my $srcFile = $binPath . $file;

   # check if the startup dir exists because it is different on different
   # windows flavors
   if (-d VDNetLib::Common::GlobalConfig::STARTUP_DIR) {
      $vdLogger->Info("dir exists ");
   }

   $startupDir = (-d VDNetLib::Common::GlobalConfig::STARTUP_DIR) ? 
                  VDNetLib::Common::GlobalConfig::STARTUP_DIR :
                  VDNetLib::Common::GlobalConfig::WIN7_STARTUP_DIR;
   my $dstFile = $startupDir . $file;

   # copy the hw_wizard.vbs file every time this method is called
   # that way if any changes were made to it and updated in the perforce
   # it will be copied to the VM
   if (-e $dstFile) {
      $vdLogger->Info("Deleting $dstFile");
      my $out = `del /F \"$dstFile\"`;
      if (defined $out && $out ne "") {
         $vdLogger->Info("del command returned $out");
      }
   }

   if ( !copy($srcFile, $dstFile) ) {
      $vdLogger->Error("Couldn't disable FoundNewHardwareWizard\n$srcFile $dstFile");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ( -e $dstFile) {
      $vdLogger->Info("Disabled FoundNewHardwareWizard");
      return SUCCESS;
   } else {
      $vdLogger->Error("Unable to disable FoundNewHardwareWizard");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# EnableFoundNewHardwareWizard --
#	Removes the vbs script from the windows startup directory so
#	after reboot when you add a new device it will show
#	FoundNewHardware wizard.
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE for failure
#
# Side effects:
#	Removes a file from windows startup directory
#
########################################################################

sub EnableFoundNewHardwareWizard
{
   my $file = "hw_wizard\.vbs";
   my $src_path = VDNetLib::Common::GlobalConfig::STARTUP_DIR . $file;
   unlink($src_path);
   if (! -e $src_path) {
      $vdLogger->Info("FoundNewHardwareWizard enabled successfully");
      return SUCCESS;
   } else {
      $vdLogger->Error("Couldn't enable FoundNewHardwareWizard");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# DisableDriverSigningWizard --
#	Adds an exe to the windows startup directory so after reboot
#	when you install an unsigned driver it doesn't show
#	DriverSigning wizard.
#	The exe has the code to force the default behavior when
#	DriverSigning wizard comes up so the user doesn't have to
#	provide any input.
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE otherwise
#
# Side effects:
#	Adds a file to windows startup directory
#
########################################################################

sub DisableDriverSigningWizard
{
   my $self = shift;
   my $binPath;
   my $gc = new VDNetLib::Common::GlobalConfig;
   if ( $self->{os} =~ /win/i ) {
      $binPath = $gc->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $binPath = $binPath . "x86_32\\\\windows\\\\";
   } else {
      # this is only applicable to windows
      return SUCCESS;
   }
   my $file = "DriverSigning-Off\.exe";

   my $src_path = $binPath . $file;

   my $startupDir = (-d VDNetLib::Common::GlobalConfig::STARTUP_DIR) ? 
                     VDNetLib::Common::GlobalConfig::STARTUP_DIR :
                     VDNetLib::Common::GlobalConfig::WIN7_STARTUP_DIR;

   my $dst_path = $startupDir . $file;

   $vdLogger->Info("src, dst are: $src_path $dst_path");

   if (-e $dst_path) {
      $vdLogger->Info("Deleting $dst_path");
      my $out = `del /F \"$dst_path\"`;
      if (defined $out && $out ne "") {
         $vdLogger->Info("del command returned $out");
      }
   }

   if ( !copy($src_path, $dst_path) ) {
      $vdLogger->Error("Couldn't disable DriverSigningWizard");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # TODO: check the return code of the below command
   system($dst_path);
   $vdLogger->Info("Disabled DriverSigningWizard successfully");
   return SUCCESS;
}


########################################################################
# EnableDriverSigningWizard --
#	Removes an exe from the windows startup directory so after
#	reboot when you install an unsigned driver it will show
#	DriverSigning wizard
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE for failure
#
# Side effects:
#	Removes a file from windows startup directory
#
########################################################################

sub EnableDriverSigningWizard
{
   my $self = shift;
   my $file = "DriverSigning-On\.exe";
   my $binPath;
   my $gc = new VDNetLib::Common::GlobalConfig;

   if ( $self->{os} =~ /win/i ) {
      $binPath = $gc->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $binPath = $binPath . "x86_32\\\\windows\\\\";
   } else {
      # this is only applicable to windows
      return SUCCESS;
   }

   my $filePath = VDNetLib::Common::GlobalConfig::STARTUP_DIR;
   my $srcFile = $binPath . $file;

   if ( ! -e $srcFile ) {
      $vdLogger->Error("$srcFile doesn't exist");
      return FAILURE;
   }

   # execute DriverSigning-On.exe file.  There is no way to check if
   # the executable passed or failed, assume it is success
   my $out = `$srcFile`;
   my $startupFile = $filePath . $file;

   if ( -e $startupFile ) {
      unlink($startupFile);
      if (! -e $startupFile) {
         $vdLogger->Info("DriverSigningWizard enabled successfully");
         return SUCCESS;
      } else {
         $vdLogger->Error("Couldn't enable DriverSigningWizard");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
# CheckStartupScripts --
#       Checks if a given file exists in startup directory on windows
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE otherwise
#
# Side effects:
#	None
#
########################################################################

sub CheckStartupScripts
{
   my $self = shift;
   my $file = shift;

   if ( $self->{os} !~ /win/i || not defined $file ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $dstFilePath = VDNetLib::Common::GlobalConfig::STARTUP_DIR . $file;

   if ( -e $dstFilePath ) {
      $vdLogger->Info("$file exists in " . VDNetLib::Common::GlobalConfig::STARTUP_DIR);
      return SUCCESS;
   } else {
      $vdLogger->Error("$file are not in " . VDNetLib::Common::GlobalConfig::STARTUP_DIR);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# IsDriverSigningTurnedOff --
#	Checks if driver signing is disabled
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE if not disabled
#
# Side effects:
#	None
#
########################################################################

sub IsDriverSigningTurnedOff
{
   my $value =
      `reg query "HKLM\\Software\\Microsoft\\Driver Signing" /v Policy`;
   my $i1 = index($value, "REG_BINARY");
   my $i2 = index($value, "00");

   if ( ($i1 > 0) and ($i2 > 0) ) {
      $vdLogger->Info("Driver signing is turned off");
      return SUCCESS;
   } else {
      $vdLogger->Info("Driver signing is turned on");
      return FAILURE;
   }
}


########################################################################
# CheckWinPcap --
#	Checks if WinPcap is installed
#
# Input:
#       none
#
# Results:
#	SUCCESS for success, FAILURE otherwise
#
# Side effects:
#	None
#
########################################################################

sub CheckWinPcap
{
   my $exe_file = "rpcapd\.exe";
   my $winpcap_dir_64 = "C:\\Program Files (x86)\\WinPcap\\";
   my $winpcap_dir = "C:\\Program Files\\WinPcap\\";

   my $winpcap_exe_path = $winpcap_dir . $exe_file;
   my $winpcap64_exe_path = $winpcap_dir_64 . $exe_file;

   if (-e $winpcap_exe_path || -e $winpcap64_exe_path) {
      $vdLogger->Info("WinPcap is already installed");
      return SUCCESS;
   } else {
      $vdLogger->Error("WinPcap is not installed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
# InstallWinPcap --
#	Installs WinPcap if it is not already installed
#
# Input:
#       none
#
# Results:
#       SUCCESS if WinPcap is installed successfully else FAILURE
#
# Side effects:
#	none
#
########################################################################

sub InstallWinPcap
{
   my $self = shift;
   my $binPath;
   if ( $self->CheckWinPcap eq SUCCESS ) {
      return SUCCESS;
   }
   my $gc = new VDNetLib::Common::GlobalConfig;
   if ( $self->{os} =~ /win/i ) {
      $binPath = $gc->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $binPath = $binPath . "x86_32\\\\windows\\\\";
   } else {
      # this is only applicable to windows
      return SUCCESS;
   }

   my $exe_file = $binPath . "winpcap_install_autoit.exe";
   $vdLogger->Info("Starting installation of winpcap using autoit");
   my $out = `$exe_file`;
   # if winpcap installation fails due to wrong window then it will just
   # hang we need to find that out only by having timeout to the STAF
   # command
   $vdLogger->Info("WinPcap installed successfully");
   return SUCCESS;
}


########################################################################
# InstallVconfigOnUbubtu --
#	Install vconfig utility on Ubuntu
#
# Input:
#       arch guest os architecture
#
# Results:
#	SUCCESS for success and FAILURE for failure
#
# Side effects:
#	Installs vconfig
#
########################################################################

sub InstallVconfigOnUbubtu
{
   # TODO: This method has not tested
   my $self = shift;
   my $arch = shift;
   my $cmd_op = `vconfig`;
   my $ftpURLx86 = 'http://ftp.debian.org/debian/pool/main/v/vlan/'.
                'vlan_1.9-3_i386.deb';
   my $ftpURLx64 = 'http://ftp.debian.org/debian/pool/main/v/vlan/' .
                   'vlan_1.9-3_ia64.deb';

   my $where = index($cmd_op, "VLAN");
   if ($where > 0) {
      $vdLogger->Info("vconfig utility already present on the system");
      return SUCCESS;
   }

   chdir "/tmp";
   if ( $arch == 32 ) {
      system("wget $ftpURLx86");
      system("dpkg -i vlan_1.9-3_i386.deb");
   } elsif ( $arch == 64 ) {
      system("wget $ftpURLx64");
      system("dpkg -i vlan_1.9-3_ia64.deb");
   } else {
      $vdLogger->Error("Unsupported architecture");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $where = index($cmd_op, "VLAN");
   if ($where > 0) {
      $vdLogger->Info("vconfig utility installed successfully");
      return SUCCESS;
   } else {
      $vdLogger->Error("Installation of vconfig failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


1;
