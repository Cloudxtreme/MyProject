package perl::foundryqasrc::ManagedHost;
use strict;
use warnings;
use perl::foundryqasrc::ManagedUtil;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::TestConstants;

use VMware::Vix::API::Constants;
use VMware::Vix::Simple;

use base qw(Exporter perl::foundryqasrc::ManagedBase);
our @EXPORT = qw(ConnectHost
                 DisconnectHost
                 HostFindRunningVMs
                 HostFindItems
                 HostRegisterVM
                 HostUnregisterVM);

sub new() {
   my $self = shift;
   my $obj = $self->SUPER::new(shift);
   return $obj;
};

# serviceProvider, hostName, hostPort, userName, password, options, propertyListHandle, param
sub ConnectHost($$$$$$$$$) {
   TestInfo "Issuing HostConnect...";
   my $self = shift;
   my $passed = 0;
   my $err = VIX_OK;
   my $hostHandle = VIX_INVALID_HANDLE;

   ($err, $hostHandle) = HostConnect(shift, shift, shift, shift, shift, shift, shift, shift);

   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_HOST_HANDLE} = $hostHandle;

   $passed = CheckError($err, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_HOST_HANDLE}) {
         $passed = ($rparam->{EXPECTED_HOST_HANDLE} == $rparam->{ACTUAL_HOST_HANDLE});
      }
      else {
         $passed = ($rparam->{ACTUAL_HOST_HANDLE} != VIX_INVALID_HANDLE);
      }
   }

   return $passed;
};

# hostHandle
sub DisconnectHost($) {
   my $self = shift;
   HostDisconnect(shift);
};

# hostHandle, timeout, param
sub HostFindRunningVMs($$$) {
   TestInfo "Issuing FindRunningVMs...";
   my $self = shift;
   my $err = VIX_OK;
   my $passed = 0;

   my @actualVMsFound = FindRunningVMs(shift, shift);
   TestInfo "Actual VMs found: @actualVMsFound";
   $err = shift @actualVMsFound;

   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   $passed = CheckError($err, $rparam);

   if ($passed && exists $rparam->{EXPECTED_VMS_FOUND}) {
      my $expectedVMsFound = $rparam->{EXPECTED_VMS_FOUND};
      my $notexpectedVMsFound = $rparam->{NOT_EXPECTED_VMS_FOUND};

      TestInfo "Expected VMs: @$expectedVMsFound\nNot Expected VMs: @$notexpectedVMsFound\nActually found VMS: @actualVMsFound";
      if ($passed) {
         for (my $expcnt = 0; $expcnt < @$expectedVMsFound && $passed; $expcnt++) {
            $passed = 0;
            for (my $actcnt = 0; $actcnt < @actualVMsFound; $actcnt++) {
               $passed = $passed || ($expectedVMsFound->[$expcnt] eq $actualVMsFound[$actcnt]);
            }
            if (!$passed) {
               #TODO:Gagan: Commenting it to suppress warning "Using an array as a reference is deprecated". Revisit
               #TestError "Expected VM @$expectedVMsFound->[$expcnt] is not in actual VMs found @actualVMsFound";
               
            }
         }
      }
      if ($passed) {
         for (my $expcnt = 0; $expcnt < @$notexpectedVMsFound && $passed; $expcnt++) {
            for (my $actcnt = 0; $actcnt < @actualVMsFound; $actcnt++) {
               $passed = $passed && !(($notexpectedVMsFound->[$expcnt]) eq ($actualVMsFound[$actcnt]));
            }
            if (!$passed) {
               #TODO:Gagan: Commenting it to suppress warning "Using an array as a reference is deprecated". Revisit
               #TestError "VM @$notexpectedVMsFound->[$expcnt] is not Expected but is in actual VMs found @actualVMsFound";
            }
         }
      }
   }

   return $passed;
};

# hostHandle, searchType, timeout, param
sub HostFindItems($$$$) {
   TestInfo "Issuing FindItems...";
   my $self = shift;
   my $err = VIX_OK;
   my $passed = 0;

   my @actualVMsFound = FindItems(shift, shift, shift);
   TestInfo "Actual VMs found: @actualVMsFound";
   $err = shift @actualVMsFound;

   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   $passed = CheckError($err, $rparam);

   if ($passed && exists $rparam->{EXPECTED_VMS_FOUND}) {
      my $expectedVMsFound = $rparam->{EXPECTED_VMS_FOUND};
      my $notexpectedVMsFound = $rparam->{NOT_EXPECTED_VMS_FOUND};

      
      TestInfo "Expected VMs: @$expectedVMsFound\nNot Expected VMs: @$notexpectedVMsFound\nActually found VMS: @actualVMsFound";
      if ($passed) {
         for (my $expcnt = 0; $expcnt < @$expectedVMsFound && $passed; $expcnt++) {
            $passed = 0;
            for (my $actcnt = 0; $actcnt < @actualVMsFound; $actcnt++) {
               $passed = $passed || ($expectedVMsFound->[$expcnt] eq $actualVMsFound[$actcnt]);
            }
            if (!$passed) {
               #TODO:Gagan: Commenting it to suppress warning "Using an array as a reference is deprecated". Revisit
               #TestError "Expected VM @$expectedVMsFound->[$expcnt] is not in actual VMs found @actualVMsFound";
            }
         }
      }
      if ($passed) {
         for (my $expcnt = 0; $expcnt < @$notexpectedVMsFound && $passed; $expcnt++) {
            for (my $actcnt = 0; $actcnt < @actualVMsFound; $actcnt++) {
               $passed = $passed && !(($notexpectedVMsFound->[$expcnt]) eq ($actualVMsFound[$actcnt]));
            }
            if (!$passed) {
      		   #TODO:Gagan: Commenting it to suppress warning "Using an array as a reference is deprecated". Revisit
               #TestError "VM @$notexpectedVMsFound->[$expcnt] is not Expected but is in actual VMs found @actualVMsFound";
            }
         }
      }
   }

   return $passed;
};

# hostHandle, vmxPath, param
sub HostRegisterVM($$$) {
   my $self = shift;
   my $hostHandle = shift;
   my $vmxPath = shift;
   my $rparam = shift;
   my $err = VIX_OK;
   my $passed = 0;
   TestInfo "Issuing HostRegisterVM for $vmxPath";

   $err = RegisterVM($hostHandle, $vmxPath);
   $rparam->{ACTUAL_ERROR} = $err;
   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "HostRegisterVM successful";
   } else {
      TestWarning "HostRegisterVM unsuccessful";
   }
   return $passed;
}

# hostHandle, vmxPath, param
sub HostUnregisterVM($$$) {
   TestInfo "Issuing HostUnregisterVM...";
   my $self = shift;
   my $hostHandle = shift;
   my $vmxPath = shift;
   my $rparam = shift;
   my $err = VIX_OK;
   my $passed = 0;

   $err = UnregisterVM($hostHandle, $vmxPath);
   $rparam->{ACTUAL_ERROR} = $err;
   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "HostUnregisterVM successful";
   } else {
      TestWarning "HostUnregisterVM unsuccessful";
   }

   return $passed;
}

1;