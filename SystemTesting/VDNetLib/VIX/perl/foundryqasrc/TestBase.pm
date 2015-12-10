#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package perl::foundryqasrc::TestBase;
use strict;
use warnings;
no warnings 'redefine';

use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::ManagedHost;
use perl::foundryqasrc::ManagedVM;
use perl::foundryqasrc::ManagedGuest;
use perl::foundryqasrc::ManagedSharedFolder;
use perl::foundryqasrc::ManagedUtil;
use perl::foundryqasrc::ConnectAnchor;
use perl::foundryqasrc::Enumerations;
use perl::foundryqasrc::TestConstants;

use VMware::Vix::Simple;
use VMware::Vix::API::Constants;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PrintInfo
                 SetOutcome
                 PrintOutcome
                 NONE
                 PASS
                 FAIL
                 SETUPFAIL
                 CLEANUPFAIL
                 NOTSUPPORTED
                 );


use constant NONE => 0;
use constant PASS => 1;
use constant FAIL => 2;
use constant SETUPFAIL => 3;
use constant CLEANUPFAIL => 4;
use constant APIVERSION => -1;
use constant NOTSUPPORTED => 5;
use constant NOTIMPLEMENTED => 6;
use constant BLOCKEDBYBUG => 7;
use constant MASTERSETUPFAIL => 8;
use constant SERVICEPROVIDER => VIX_SERVICEPROVIDER_VMWARE_WORKSTATION;
use constant PORT => 902;
use constant HOSTNAME => "localhost";
use constant USERNAME => "root";
use constant PASSWORD => "ca\$hc0w";

my $minimumArgs = 5;

# Constructor
sub new() {
   my $class = shift;
   my $self = {};
   my $numOfArgs = @_;

   # Initialize based on the number of args passed
   if(1 <= @_) {
      $self->{testPrepConfig} = $_[0];
   } else {
      $self->{testPrepConfig} = 0;
   }
   if(2 == scalar @_) {
      $self->{initPowerState} = $_[1];
   } else {
      $self->{initPowerState} = undef;
   }

   # Initialize the rest with defaults
   $self->{apiVersion} = APIVERSION;
   $self->{hostType} = SERVICEPROVIDER;
   $self->{hostName} = HOSTNAME;
   $self->{port} = PORT;
   $self->{userName} = USERNAME;
   $self->{password} = PASSWORD;
   $self->{upgradeTools} = 0;
   $self->{registered_vms} = undef;
   $self->{connectAnchor} = undef;
   $self->{hostHandle} = undef;
   $self->{vmHandleArray} = ();
   $self->{host} = undef;
   $self->{vm} = undef;
   $self->{guest} = undef;
   $self->{sharedfolder} = undef;
   $self->{params} = {};
   $self->{outcome} = NONE;

   #printf "%s %s %s %s %s\n", $hostType, $hostName, $port, $userName, $password;
   return bless $self, $class;
}

sub PrintInfo($) {
   my $self = shift;
   printf "%s %s %s %s %s\n", $self->{hostType}, $self->{hostName}, $self->{port}, $self->{userName}, $self->{password};
   #printf "ProcessId - %d\n",getpid();
}

sub GetHostType($) {
   my $self = shift;
   return $self->{hostType};
}

sub GetHostName($) {
   my $self = shift;
   return $self->{hostName};
}

sub GetPort($) {
   my $self = shift;
   return $self->{port};
}

sub GetUserName($) {
   my $self = shift;
   return $self->{userName};
}

sub GetPassword($) {
   my $self = shift;
   return $self->{password};
}

sub GetConnectAnchor($) {
   my $self = shift;
   return $self->{connectAnchor};
}

sub GetManagedVM($) {
   my $self = shift;
   return $self->{vm};
}

sub GetManagedHost($) {
   my $self = shift;
   return $self->{host};
}

sub GetManagedGuest($) {
   my $self = shift;
   return $self->{guest};
}

sub GetSharedFolder($) {
   my $self = shift;
   return $self->{sharedfolder};
}

sub GetVMHandle($$) {
   my $self = shift;
   my $vmHandleNum = shift;
   if(not defined $vmHandleNum) {
      $vmHandleNum = 0;
   }
   if((defined $vmHandleNum) &&
      (defined $self->{vmHandleArray}) &&
      (0 <= $vmHandleNum) &&
      ($vmHandleNum < scalar @{$self->{vmHandleArray}})) {
      return $self->{vmHandleArray}[$vmHandleNum];
   }
   return 0;
}

sub GetVMHandleArray($$) {
   my $self = shift;
   return \$self->{vmHandleArray};
}

sub GetHostHandle($) {
   my $self = shift;
   return $self->{hostHandle};
}

sub GetHandleToUse($$) {
   my $self = shift;
   my $vmHandleNum = shift;
   my $handleToUse = undef;
   if(not defined $vmHandleNum) {
      $vmHandleNum = 0;
   }

   # If none of the options are set,
   # return the host handle
   if((($self->{testPrepConfig }) & (TP_HTU_HANDLE_VALID |
                                     TP_HTU_HANDLE_INVALID |
                                     TP_HTU_HANDLE_USE_HOST |
                                     TP_HTU_HANDLE_USE_VM)) == 0) {
      # Making a function call instead of using the member
      # variable as later the host handle might be stored
      # with the Connection Manager.
      $handleToUse = GetHostHandle($self);
   } elsif(TP_HTU_HANDLE_INVALID & $self->{testPrepConfig}) {
      $handleToUse = VIX_INVALID_HANDLE;
   } elsif(TP_HTU_HANDLE_USE_HOST & $self->{testPrepConfig}) {
      $handleToUse = GetHostHandle($self);
   } elsif(TP_HTU_HANDLE_USE_VM & $self->{testPrepConfig}) {
      $handleToUse = GetVMHandle($self, $vmHandleNum);
   }
   return $handleToUse;
}


sub GetVmxPath($$) {
   my $self = shift;
   my $vmxPathNum = shift;
   if(not defined $vmxPathNum) {
      $vmxPathNum = 0;
   }
   if((defined $vmxPathNum) &&
      (defined $self->{registered_vms}) &&
      (0 <= $vmxPathNum) &&
      ($vmxPathNum < scalar @{$self->{registered_vms}})) {
      return $self->{registered_vms}[$vmxPathNum];
   }
   return undef;
}

sub GetServiceProvider($$) {
   my $self = shift;
   my $serviceProviderStr = shift;
   # Defaults
   if(not defined $serviceProviderStr) {
      return VIX_SERVICEPROVIDER_VMWARE_WORKSTATION;
   }
   $serviceProviderStr = lc($serviceProviderStr);
   if("vi_server" eq $serviceProviderStr) {
      return VIX_SERVICEPROVIDER_VMWARE_VI_SERVER;
   }
   if("workstation" eq $serviceProviderStr) {
      return VIX_SERVICEPROVIDER_VMWARE_WORKSTATION;
   }
   if("esx" eq $serviceProviderStr) {
      return 5;
   }
   return undef;
}

#sub IsTestImplemented($) {
#   my $self = shift;
#   my $passed = 0;
#   # TestInfo "IsTestImplemented functionality not implemented for Perl tests";
#   $passed = 1;
#   return $passed;
#}

#sub IsTestBlockedByBug($) {
#   my $self = shift;
#   my $passed = 0;
   #TestInfo IsTestBlockedByBug functionality not implemented for Perl tests";
#   return $passed;
#}

#sub IsTestSupportedOnHost($) {
#   my $self = shift;
#   my $passed = 0;
   # TestInfo "IsTestSupportedOnHost functionality not implemented for Perl tests";
#   $passed = 1;
#   return $passed;
#}

#sub CheckVMRequirements($) {
#   my $self = shift;
#   my $passed = 0;
   # TestInfo "CheckVMRequirements functionality not implemented for Perl tests";
#   $passed = 1;
#   return $passed;
#}

#sub BackUpVM($) {
#   my $self = shift;
#   my $passed = 0;
   # TestInfo "BackUpVM functionality not implemented for Perl tests";
#   $passed = 1;
#   return $passed;
#}

sub IsTestSupportedOnProduct($) {
   my $self = shift;
   my $passed = 0;
   if(($self->{testPrepConfig} &
       (TP_TEST_SUPPORTED_ON_WS |
       TP_TEST_SUPPORTED_ON_SERVER |
       TP_TEST_SUPPORTED_ON_ESX)) == 0) {
      $passed = 1;
   } else {
      if((TP_TEST_SUPPORTED_ON_WS & $self->{testPrepConfig}) &&
         (VIX_SERVICEPROVIDER_VMWARE_WORKSTATION == $self->{hostType})){
         $passed = 1;
      } elsif((TP_TEST_SUPPORTED_ON_SERVER & $self->{testPrepConfig}) &&
              (VIX_SERVICEPROVIDER_VMWARE_VI_SERVER == $self->{hostType})) {
         $passed = 1;
      } elsif((TP_TEST_SUPPORTED_ON_ESX & $self->{testPrepConfig}) &&
              (10 == $self->{hostType})) {
         $passed = 1;
      }
      # Does not have VIX_SERVICEPROVIDER_VMWARE_ESX
      #} elsif((TP_TEST_SUPPORTED_ON_ESX & $self->{testPrepConfig}) &&
      #        (VIX_SERVICEPROVIDER_VMWARE_ESX == $self->{hostType})) {
      #   $passed = 1;
      #}
   }
   if(!$passed) {
      SetOutcome($self, NOTSUPPORTED);
   }
   return $passed;
}

sub ConnectHostInSetup($) {
   my $self = shift;
   my $passed = 0;
   ($passed, $self->{hostHandle}) = $self->{connectAnchor}->Connect($self->{userName},
                                                                    $self->{password},
                                                                    0);
   return $passed;

}


sub DisconnectHostInCleanup($) {
   my $self = shift;
   my $passed = $self->{connectAnchor}->Disconnect();
   return $passed;
}

sub ReleaseVMHandlesInCleanup($) {
   my $self = shift;
   if(defined $self->{vmHandleArray}) {
      for(my $vmHandleCount = 0;
          ($vmHandleCount < scalar @{$self->{vmHandleArray}});
          $vmHandleCount++) {
          ReleaseHandle($self->{vmHandleArray}[$vmHandleCount]);
      }
      for(my $vmHandleCount = 0;
          ($vmHandleCount < scalar @{$self->{vmHandleArray}});
          $vmHandleCount++) {
          $self->{vmHandleArray}[$vmHandleCount] = undef;
      }
   }
   $self->{vmHandleArray} = ();
}


sub RegisterOrUnRegisterVMsInSetup($) {
   my $self = shift;
   my $passed = 0;
   my $err = VIX_E_FAIL;
   my $vmxPath = undef;
   my $vmCount = 0;
   my $continueLooping = 1;
   my $vmHandle = VIX_INVALID_HANDLE;

   #################################################################
   # Check for the cases when we do not register the VM
   # as registering the VM is default
   #  1) The service provider is workstation
   #  2) The service provider is player(currently only a part of semi public)
   #  3) The api do not wish to register
   #  4) The api wishes to unregister in setup
   #################################################################

   if(VIX_SERVICEPROVIDER_VMWARE_WORKSTATION == $self->{hostType}) {
      return 1;
   }

   #if(VIX_SERVICEPROVIDER_VMWARE_PLAYER == $self->{hostType}) {
   #   return 1;
   #}

   # The test does not wish register api calls in the initialize
   # test setup e.g. Register test cases
   if(TP_REG_UNREG_DONTCARE & $self->{testPrepConfig}) {
      return 1;
   }

   # Check if set to unregister the vm on setup
   if(TP_UNREG_ON_SETUP & $self->{testPrepConfig}) {
      for($vmCount = 0;
          (defined $self->{registered_vms}) &&
          ($vmCount < scalar @{$self->{registered_vms}}) && $continueLooping;
          $vmCount++) {
         $vmxPath = $self->{registered_vms}[$vmCount];
         # Check if the VM is already registered
         if(IsVMRegistered($self->{hostHandle}, $vmxPath)) {
            if(not defined $self->{hostHandle}) {
               $continueLooping = 0;
            } else {
               # Open the VM
               ClearParam \%{$self->{param}};
               ($continueLooping, $err, $vmHandle) =
                  $self->{vm}->Open($self->{hostHandle},
                                    $vmxPath,
                                    \%{$self->{param}});
               # Power off the VM
               if($continueLooping) {
                  ClearParam \%{$self->{param}};
                  $continueLooping = $self->{vm}->SetVMState($vmHandle,
                                                            VIX_POWERSTATE_POWERED_OFF,
                                                            0,
                                                            \%{$self->{param}});
               }
               # Unregister the VM
               if($continueLooping) {
                  ClearParam \%{$self->{param}};
                  $continueLooping = $self->{host}->HostUnregisterVM($self->{hostHandle},
                                                                     $vmxPath,
                                                                     \%{$self->{param}});
               }
            }
         } else {
            $continueLooping = 1;
         }
         $passed = $continueLooping;
      }
   } else {
      # Check the VM is registered or not before registering 
     $vmxPath = $self->{registered_vms}[0];
     if(IsVMRegistered($self->{hostHandle}, $vmxPath   ) == 0) {#
      for(my $vmCount = 0;
             (defined $self->{registered_vms}) &&
             ($vmCount < scalar @{$self->{registered_vms}}) && $continueLooping;
             $vmCount++) {
         if(not defined $self->{hostHandle}) {
            $continueLooping = 0;
         } else {
            ClearParam \%{$self->{param}};
            $vmxPath = $self->{registered_vms}[$vmCount];
            $continueLooping = $self->{host}->HostRegisterVM($self->{hostHandle},
                                                            $vmxPath,
                                                            \%{$self->{param}});
        
         }
         $passed = $continueLooping;
      }
   }
   else
   {
   	$passed = 1;
   }
   }#
   return $passed;

}

sub InitializeTestSetup($) {
   my $self = shift;
   my $passed = 0;
   my $err = VIX_E_FAIL;
   my $vmxPath = undef;
   my $vmCount = 0;
   my $continueLooping = 1;
   my $vmHandle = VIX_INVALID_HANDLE;
   my $waitForTools = 0;
   my $powerOption = POWEROPTION;


   # Check if set not to connect
   if(TP_DONT_CONNECT & $self->{testPrepConfig}) {
      TestInfo "Set not to connect in the initialize test setup";
      return 1;
   }

   $passed = ConnectHostInSetup($self);

   if($passed) {
      # Initialize the variables
      $passed = RegisterOrUnRegisterVMsInSetup($self);
   }

   # Check if set to unregister in set up
   # Cannot perform any further operations
   if(TP_UNREG_ON_SETUP & $self->{testPrepConfig}) {
      return $passed;
   }

   # Check if set to not open the VM handle in set up
   if(TP_SHOULD_NOT_OPEN_VM & $self->{testPrepConfig}) {
      return $passed;
   } elsif($passed) {
      if(TP_WAIT_FOR_TOOLS & $self->{testPrepConfig}) {
         $waitForTools = 1;
      }
      for(my $vmCount = 0;
            (defined $self->{registered_vms}) &&
            ($vmCount < scalar @{$self->{registered_vms}}) && $continueLooping;
             $vmCount++) {
         if(not defined $self->{hostHandle}) {
            $continueLooping = 0;
         } else {
            ClearParam \%{$self->{param}};
            $vmxPath = $self->{registered_vms}[$vmCount];
            ($continueLooping, $err, $vmHandle) =
               $self->{vm}->Open($self->{hostHandle},
                                 $vmxPath,
                                 \%{$self->{param}});
         }
         if($continueLooping) {
            push(@{$self->{vmHandleArray}}, $vmHandle);
            #Check if set to set the initial power state
            if(defined $self->{initPowerState}) {
               if(TP_VM_POWERON_OPTION_LAUNCH_GUI & $self->{testPrepConfig}) {
                  $powerOption = VIX_VMPOWEROP_LAUNCH_GUI;
               }
               ClearParam \%{$self->{param}};
               $continueLooping = $self->{vm}->SetVMState($vmHandle,
                                                          $self->{initPowerState},
                                                          $waitForTools,
                                                          \%{$self->{param}},
                                                          $powerOption);
            }
         }

         #Check if set to login in guest
         if($continueLooping &&
            (TP_LOGIN_IN_GUEST & $self->{testPrepConfig})) {
            ClearParam \%{$self->{param}};
            $continueLooping = $self->{guest}->LoginInGuest($vmHandle,
                                                            GUESTADMIN,
                                                            GUESTADMINPASS,
                                                            0, \%{$self->{param}});

            # TODO: This is not the cleanest solution as it forces
            # each test to call the MasterTestSetup.
            # However, this should be an immediate solution
            if($self->{upgradeTools}) {
               ClearParam \%{$self->{param}};
               ($continueLooping, $err) =
                  $self->{guest}->InstallTools($vmHandle,
                                               FOUNDRYQA_VIX_REQUESTMSG_TOOLS_UPGRADE_ONLY,
                                               undef,
                                               \%{$self->{param}});
               if(!($continueLooping)) {
                  $self->{param}->{EXPECTED_ERROR} =
                     VIX_E_TOOLS_INSTALL_ALREADY_UP_TO_DATE;
                  $continueLooping =
                     CheckError($err, \%{$self->{param}});
                  if($continueLooping) {
                     TestWarning "Install tools failed as the tools are up to date";
                  }
               }
            }
         }
         $passed = $continueLooping;
      }
   }

   return $passed;
}

sub LogoutFromInputVMs($) {
   my $self = shift;
   my $passed = 1;
   my $err = VIX_E_FAIL;
   my $vmHandleCount = 0;
   my $powerState = undef;

   if(TP_LOGIN_IN_GUEST & $self->{testPrepConfig}) {
      for(my $vmHandleCount = 0;
             (defined $self->{vmHandleArray}) &&
             ($vmHandleCount < scalar @{$self->{vmHandleArray}});
             $vmHandleCount++) {
         # Check if the VM Handle is still valid
         if(VIX_HANDLETYPE_VM == GetHandleType($self->{vmHandleArray}[$vmHandleCount])) {
            ClearParam \%{$self->{param}};
            ($err, $powerState) =
               GetProperties($self->{vmHandleArray}[$vmHandleCount],
                             VIX_PROPERTY_VM_POWER_STATE);
            if(VIX_OK == $err) {
               if($powerState & VIX_POWERSTATE_POWERED_ON) {
                  ClearParam \%{$self->{param}};
                  $passed = $passed &&
                     $self->{guest}->LogoutFromGuest($self->{vmHandleArray}[$vmHandleCount],
                                                     \%{$self->{param}});
               }
            } else {
               $passed = $passed && 0;
            }
         }
      }
   }

   if(!$passed) {
      SetOutcome(CLEANUPFAIL);
   }

   return $passed;
}

sub PowerOffInputVMs($) {
   my $self = shift;
   my $passed = 1;
   my $err = VIX_E_FAIL;
   my $vmCount = 0;
   my $powerState = undef;
   if($self->{testPrepConfig} &
      (TP_SHOULD_POWEROFF_VM_ON_CLEANUP |
       TP_RESTORE_VMX_DIRECTORY |
       TP_RESTORE_VMX_FILE_ONLY |
       TP_UNREG_ON_CLEANUP)) {
      for(my $vmCount = 0;
             (defined $self->{registered_vms}) &&
             ($vmCount < scalar @{$self->{registered_vms}});
             $vmCount++) {
         # Check if the VM Handle is still valid
         if(VIX_HANDLETYPE_VM == GetHandleType($self->{vmHandleArray}[$vmCount])) {
            ClearParam \%{$self->{param}};
            $passed = $passed &&
               $self->{vm}->SetVMState($self->{vmHandleArray}[$vmCount],
                                       VIX_POWERSTATE_POWERED_OFF,
                                       0,
                                       \%{$self->{param}});
         }
      }
   }

   if(!$passed) {
      SetOutcome(CLEANUPFAIL);
   }
   return $passed;
}

sub UnregisterVmInCleanup($) {
   my $self = shift;
   my $passed = 1;
   my $vmCount = 0;
   my $vmxPath = undef;
   # Check if set to unregister the vm on setup
   if(TP_UNREG_ON_CLEANUP & $self->{testPrepConfig}) {
      for($vmCount = 0;
             (defined $self->{registered_vms}) &&
             ($vmCount < scalar @{$self->{registered_vms}});
          $vmCount++) {
         $vmxPath = $self->{registered_vms}[$vmCount];
         # Unregister the VM
         ClearParam \%{$self->{param}};
         $passed  = $passed &&
            $self->{host}->HostUnregisterVM($self->{hostHandle},
                                            $vmxPath,
                                            \%{$self->{param}});
      }
   }
   if(!$passed) {
      SetOutcome(CLEANUPFAIL);
   }
   return $passed;

}

#sub RestoreVM($) {
#   my $self = shift;
#   my $passed = 0;
   # TestInfo "RestoreVM functionality not implemented for Perl tests";
#   $passed = 1;
#   return $passed;
#}

sub MasterTestSetup($) {
   my $self = shift;
   my $passed = 0;
   TestInfo "MasterTestSetup Started...";
   # Check if the test has been implemented
   #if (!IsTestImplemented($self)) {
   #   TestInfo "The test has not been implemented";
   #   return 0;
   #}
   # Check if the test is blocked by bug
   #if (IsTestBlockedByBug($self)) {
   #   TestError "The test is blocked by bug# Needs implementation";
   #   return 0;
   #}
   # Check if the test is supported on the Host
   #if (!IsTestSupportedOnHost($self)) {
   #   TestInfo "The test is not supported on host";
   #   return 0;
   #}
   # Check if the test is supported on the Product
   if(!IsTestSupportedOnProduct($self)) {
      TestInfo "The test is not supported on product";
      return 0;
   }
   #if(!CheckVMRequirements($self)) {
   #   TestError "The test did not meet the specified VM requirements";
   #   return 0;
   #}
   #if(!BackUpVM($self)) {
   #   TestError "The test could not back up the VMs";
   #   return 0;
   #}

   $self->{connectAnchor} =
      perl::foundryqasrc::ConnectAnchor->new($self->{apiVersion},
                                             $self->{hostType},
                                             $self->{hostName},
                                             $self->{port});

   $self->{host}  =
      perl::foundryqasrc::ManagedHost->new($self->{connectAnchor});
   $self->{vm}  =
      perl::foundryqasrc::ManagedVM->new($self->{connectAnchor});
   $self->{guest}  =
      perl::foundryqasrc::ManagedGuest->new($self->{connectAnchor});
   $self->{sharedfolder}  =
      perl::foundryqasrc::ManagedSharedFolder->new($self->{connectAnchor});

   # Call initialize test set up
   $passed = InitializeTestSetup($self);

   TestInfo "MasterTestSetup Completed...";
   if(!$passed) {
      SetOutcome($self, MASTERSETUPFAIL);
   }
   return $passed;
}

sub MasterTestCleanup()
{
   my $passed = 0;
   my $self = shift;
   TestInfo "MasterTestCleanup Started...";
   if((NOTIMPLEMENTED != $self->{outcome}) &&
      (NOTSUPPORTED != $self->{outcome}) &&
      (BLOCKEDBYBUG != $self->{outcome})) {
      $passed = LogoutFromInputVMs($self);
      $passed = $passed && PowerOffInputVMs($self);
      $passed = $passed && UnregisterVmInCleanup($self);
      ReleaseVMHandlesInCleanup($self);
      if(!(TP_DONT_DISCONNECT_ON_CLEANUP & $self->{testPrepConfig})) {
         $passed = $passed && DisconnectHostInCleanup($self);
      }
      if(defined $self->{hostHandle}) {
         ReleaseHandle($self->{hostHandle});
      }
      $self->{hostHandle} = undef;
      #$passed = $passed && RestoreVM($self);
   } else {
      $passed = 1;
   }
   TestInfo "MasterTestCleanup Completed...";
   return $passed;
}

sub SetOutcome($) {
   my $self = shift;
   if ($self->{outcome} == NONE || $self->{outcome} == PASS) {
      $self->{outcome} = shift;
   }
   else {
      TestWarning "Test outcome already set! Outcome not modified.";
   }
   return undef;
}

sub PrintOutcome($) {
   my $self = shift;
   my $outcomestr;
   if ($self->{outcome} == PASS) {
      $outcomestr = "PASS";
   }
   elsif ($self->{outcome} == FAIL) {
      $outcomestr = "FAIL";
   }
   elsif ($self->{outcome} == SETUPFAIL) {
      $outcomestr = "SETUPFAIL";
   }
   elsif ($self->{outcome} == CLEANUPFAIL) {
      $outcomestr = "CLEANUPFAIL";
   }
   elsif ($self->{outcome} == NOTSUPPORTED) {
      $outcomestr = "NOTSUPPORTED";
   }
   elsif ($self->{outcome} == MASTERSETUPFAIL) {
      $outcomestr = "MASTERSETUPFAIL";
   }

   TestInfo "OUTCOME: ".$outcomestr;
   return undef;
}

# TODO:
# Ravi,
# This function is messed up.
# Shall we clean this real quick?
# Thanks
sub ParseCommandLine($) {
   my $self = shift;
   my $size = @ARGV;
   TestInfo "minimum args = ".$size;
   if ($size >= $minimumArgs) {
      $self->{apiVersion} = $ARGV[0];
      $self->{hostType} = GetServiceProvider($self, $ARGV[1]);
      $self->{hostName} = $ARGV[2];
      $self->{port} = $ARGV[3];
      $self->{userName} = $ARGV[4];
      $self->{password} = $ARGV[5];
      my $vmList = $ARGV[6];
      $self->{upgradeTools} = $ARGV[7];

      #printf "parse vmList = %s\n", $vmList;
      $self->{registered_vms} = [split(",", $vmList)];

      if ($self->{hostName} eq "NULL") {
         $self->{hostName} = 0;
      }
      if ($self->{userName} eq "NULL") {
         $self->{userName} = 0;
      }
      if ($self->{password} eq "NULL") {
         $self->{password} = 0;
      }
      if (lc($self->{upgradeTools}) eq "true") {
         $self->{upgradeTools} = 1;
      } else {
         $self->{upgradeTools} = 0;
      }
   }
   elsif ($size == 0) {
      $self->{hostName} = HOSTNAME;
      $self->{userName} = USERNAME;
      $self->{password} = PASSWORD;
      $self->{port} = PORT;
   }
   else {
      TestInfo "Usage: TestClass hostname port username password comma-separated-list-of-vms";
   }

   return undef;
}

1;