##############################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::Testbed::Testbedv1;

##############################################################################
#  Testbed class creates testbed object taking command separate vmip, esxip,
#  optionally vmxpath.  Below is the testbed representation that is used by
#  this class
#  testbed {
#       SUT {
#	   vmx =>
#	   os =>
#	   ip =>
#	   host =>
#	   hostType =>
#	}
#	helper1 {
#	}
#	helpern {
#	}
#  }
#  Input:
#       list of comma separate strings: vmip/vmx,esxip,
#       [guestos,hostip,hosttype]
#
#  Results:
#       An instance/object of Testbed class
#
#  Side effects:
#       Creates STAF handle by calling STAFHelper, need to have STAFHelper.pm
#	in order to use this class
#
##############################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

# Inherit the parent class.
use base qw(VDNetLib::Testbed::Testbed);

use Data::Dumper;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT);
use VDNetLib::Common::Utilities;
use VDNetLib::VM::VMOperations;
use VDNetLib::Host::HostFactory;
use VDNetLib::VC::VCOperation;
use VDNetLib::Common::LogCollector;
use VDNetLib::Workloads::Utils;
use VDNetLib::Switch::Switch;
use VDNetLib::Switch::VSSwitch::PortGroup;
use Carp;

use constant GUESTIP_DEFAULT_TIMEOUT => 300;
use constant GUESTIP_SLEEPTIME => 5;
use constant GUEST_BOOTTIME => 60;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VMWARE_TOOLS_BASE_PATH => "/usr/lib/vmware/";
use constant VDNET_LOCAL_MOUNTPOINT => "vdtest";
use constant WIN32_BIN_PATH => "M:\\features\\Networking\\common\\binaries" .
                               "\\x86_32\\windows\\";

my @machineAttributes = qw(ip host vmx os hostType);
our $vdNetSrcServer;
our $vdNetSrcDir;
our $VDNET_VM_SERVER;
our $VDNET_VM_SHARE;


########################################################################
#
# new --
#       Constructor for Testbed object
#
# Input:
#       1. Reference to an array with each element of the array
#       containing string of the format:
#       <ip|vmx>:<hostip>[,cache=<cacheDir>][,sync=<0|1>]
#       [,prefixDir=<prefixDirectory>].
#       Refer to VDNetLib::Common::VDNetUsage.pm for more information on this
#       string.
#       The first element of the array should represent SUT and other
#       elements should represent helper machines.
#       2. Flag indicating whether to do setup or no. IF the flag is
#       defined setup will be skipped else setup will be performed.
#       3. <vdNetSrc> : IP address of the machine exporting
#       vdNet source code at /automation. If not specified, source
#       from scm-trees will be used.
#
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#       Builds testbed hash that has sut and helper machine details
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my ($class) = shift;
   my %args    = @_;
   my $session = $args{'session'};
   my $stafObj = $session->{'stafHelper'};

   if (not defined $session) {
      $vdLogger->Error("Session hash not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vdNetSrc          = $session->{'vdNetSrc'};
   my $vcaddr            = $session->{Parameters}{'vc'};

   # Update the global variable for vm repository server and share name
   $VDNET_VM_SERVER      = $session->{'vmServer'};
   $VDNET_VM_SHARE       = $session->{'vmShare'};
   # Setting the global variables to use the right vdNet source code
   $vdNetSrcServer = ($vdNetSrc !~ /scm-trees/i) ? $vdNetSrc :
                      VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_SERVER;

   $vdNetSrcDir = ($vdNetSrc !~ /scm-trees/i) ? "/automation" :
                        VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_DIR;

   # Update the vdNet share folder to be mounted
   $session->{vdNetShare} = $vdNetSrcDir;

   my $self = {};
   #
   # Store the current process id, this is needed for Event handler to send
   # signal from child processes to parent.
   #
   $self->{pid} = $$;

   # Check whether the vc address is valid
   if (defined $vcaddr) {
      my $ret = VDNetLib::Common::Utilities::IsValidAddress($vcaddr);
      if ( $ret eq "FAILURE") {
         $vdLogger->Error("Invalid VC address $vcaddr specified.".
                       " Please check -vc option.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $self->{vc}->{vcaddr} = $vcaddr;
   }
   $self->{'session'} = $session;

   bless $self, $class;

   if (not defined $stafObj) {
      # Creating new STAFHelper object.
      my $args;
      $args->{logObj} = $vdLogger;
      $args->{tcpport} = $session->{tcpport};
      my $temp = VDNetLib::Common::STAFHelper->new($args);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $stafObj = $temp;
   }
   $self->{stafHelper} = $stafObj;
   $self->{noOfMachines} = 0;
   $self->{resourceCache} = $session->{resourceCache}; # get this value from
                                                       # session
   #
   # Every element of resourceCache array is reference to hash with following
   # keys:
   # vmName          : name of the VM (the name specified at command line
   # vmx             : absolute vmx path
   # machineType     : type of the machine SUT/helper
   # startedPowerOn  : flag to indicate the initial state of the vm
   # datastore       : datastore on which VM files are present
   # host            : host on which VM is present
   # vmOpsObj        : reference to VM Operation object
   # available       : flag to indicate whether this machine is available or
   #                   not
   #

   # Initialize all the inventory object module mappings
   $self->{inventoryObjects} = $self->InitializeInventoryMapping();

   #
   # Currently there is no way to determine if the environment is hosted
   # (without restructuring testbed a lot) thus we rely on user to pass flag.
   # We can do getOS and find out but not sure if staf would be ready
   # on the host.
   # If hosted flag is defined then created childObj and return child obj i.e.
   # obj of HostedTestbed.pm to caller.
   #
   my $hostedFlag = $self->{session}->{hosted};
   if ((defined $hostedFlag) && ($hostedFlag == 1)) {
      my $childObj = $self->CreateHostedObj();
      if ($childObj eq FAILURE){
         $vdLogger->Error("Creating HostedTest Obj failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $childObj->{testbed} = ();
      return $childObj;
   }

   # Get the type of host for both SUT and helper
   $self->{version} = 1;
   $self->{testbed} = ();
   return $self;
}


########################################################################
#
# CheckSetup --
#       Checks Host, VM for setup required to run virtual device
#       automation
#
#       1. Checks if STAF is running on all the hosts in testbed, if not
#          return FAILURE as that is minimum setup requirement from the
#          user
#       2. If neither VM IP nor VMX file is provided then error out
#       3. If vmx file is provided and no IP is given, check if the VM
#          is powered on, if not power it on and wait for it to come up.
#       4. If STAF is not running on VM error out
#       5. If Tools are running and STAF not installed then install
#          perl/STAF, etc - this is not done yet
#       6. If Tools is not installed and STAF is running then install
#          tools if requested by the user
#       7. Setup the following:
#          if it is windows OS:
#             a) disable firewall
#             b) enable autologon
#             c) disable event tracker
#             d) install winpcap, if it is not installed
#          if it is linux OS:
#             a) TODO: if it is ubuntu, install vconfig
#             b) TODO: disable DHCP on test interfaces
#             c) TODO: iptables, ip6tables flush
#
#  Input:
#       target: SUT or helper<x> (Optional, default all machines/targets
#               will be considered)
#
#  Results:
#       Checks the setup and sets it up if necessary and possible
#
#  Side effects:
#       Lots of side effects on guest VM
#
########################################################################

sub CheckSetup
{
   my $self    = shift;
   my $tuple   = shift || undef;
   my $session = $self->{session};

   my $target = $self->GetMachineFromTuple($tuple);

   # remeber the setup is done on host as the VMs might have same hosts and
   # the setup might be repeated for each VM
   my %setup = ();

   #  1. Checks if STAF is running on all the hosts in testbed, if not
   #     return FAILURE as that is minimum setup requirement from the user
   foreach my $machine (keys %{$self->{testbed}}) {
      if ((defined $target) && ($target ne $machine)) {
         next; # if the given target does not match, then skip
      }
      if ( (not defined $self->{testbed}{$machine}{host}) &&
           (not defined $self->{testbed}{$machine}{ip}) ) {
         next;
      }
      my $message;
      if (defined $self->{testbed}{$machine}{ip}) {
         $message = "processing machine, $machine of testbed: ".
                       "$self->{testbed}{$machine}{host}, ".
                       "$self->{testbed}{$machine}{ip}";
      } else {
         $message = "processing machine, $machine of testbed: ".
                       "$self->{testbed}{$machine}{host}, ";
      }
      $vdLogger->Debug("$message");
      $vdLogger->Debug("Checking if STAF is running on host " .
            "$self->{testbed}{$machine}{host}");

      if ( $self->{stafHelper}->CheckSTAF($self->{testbed}{$machine}{host})
                    eq FAILURE ) {
         $vdLogger->Error("STAF is not running on $self->{testbed}{$machine}{host}");
         $vdLogger->Error("Rerun after having STAF running on " .
               "$self->{testbed}{$machine}{host}");
         return FAILURE;
      } else {
         # fill up the hostType here
         $vdLogger->Debug("STAF is running on host " .
            "$self->{testbed}{$machine}{host}");
         if ( not defined $self->{testbed}{$machine}{hostType} ) {
            if ( ($self->{testbed}{$machine}{hostType} =
                  $self->{stafHelper}->GetOS(
                          $self->{testbed}{$machine}{host})) =~
                          m/Unknown/i ) {
               $self->{"testbed"}{$machine}{hostType} = undef;
               $vdLogger->Error("unable to determine hostType for ".
                            "$self->{testbed}{$machine}{host}");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
         $vdLogger->Debug("host type is $self->{testbed}{$machine}{hostType}");
      }

      #
      # If neither VM IP nor VMX file is specified then the test would not use
      # any vm's. The following block for verifying setup can be skipped.
      #
      if (not defined $session->{"Parameters"}{$machine}{"vm"}) {
         $vdLogger->Debug("Not performing any setup verification on $machine ".
                          "since vm key is not defined under Parameters hash");
         next;
      }
      if ((defined $self->{testbed}{$machine}{ip}) ||
                       (defined $self->{testbed}{$machine}{vmx})) {
         my $vmip = VDNetLib::Common::Utilities::IsValidIP($self->{testbed}{$machine}{ip});
         if ( ($vmip eq FAILURE) &&
              ((not defined $self->{testbed}{$machine}{vmx}) ||
               ($self->{testbed}{$machine}{vmx} eq "")) ) {
         $vdLogger->Info("Neither VMX nor IP is provided for the guest on the host ".
               "$self->{testbed}{$machine}{host}");
         $vdLogger->Info("The Test would not do any operations on the VMs for" .
               "$self->{testbed}{$machine}{host}");
         }

         #  3. If vmx file is provided and no IP is given, check if the VM
         #     is powered on, if not, power it on
         if ( defined $self->{testbed}{$machine}{vmx} &&
           ($self->{testbed}{$machine}{vmx} ne "") &&
           ($vmip eq FAILURE) ) {
            # TODO: need to handle linked cloning of VMs once Giri's
            # API is available.  Validate the VMX file.
            # if ( $self->STAFHelper->IsVMAlive() ) {
            # power on the VM using hostType
            # go back check smb, staf & tools
            # }
            VDSetLastError("EFAIL");
            return FAILURE;
         }

         if ( (not defined $self->{testbed}{$machine}{vmx}) &&
              ($vmip eq SUCCESS) ) {
            $self->{testbed}{$machine}{vmx} = $self->GetVMX($machine);
            if ( $self->{testbed}{$machine}{vmx} eq FAILURE ) {
               VDSetLastError(VDGetLastError());
               $self->{testbed}{$machine}{vmx} = undef;
               return FAILURE;
            }
         }

         my $isSTAFonIP = $self->{stafHelper}->CheckSTAF
                             ($self->{testbed}{$machine}{ip});
         # TODO: need some work to make the machine entry work for both
         # VM and just a regular host
         if ($isSTAFonIP eq FAILURE) {
            $vdLogger->Error("STAF is not running on the VM:".
                  "$self->{testbed}{$machine}{vmx} ".
                  "$self->{testbed}{$machine}{ip}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         } else {
            # set os type here
            if (( $self->{testbed}{$machine}{os} =
               $self->{stafHelper}->GetOS($self->{testbed}{$machine}{ip}) )
                 eq FAILURE ) {
               $self->{"testbed"}{$machine}{os} = undef;
               $vdLogger->Error("Unable to figure out the OS of " . 
                                $self->{testbed}{$machine}{ip});
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }

         if ($self->CopySetupFilesToWinGuest($machine) eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Debug("Check if SMB share mounted on " .
               "$self->{testbed}{$machine}{os}");
         my $folder = ($self->{testbed}{$machine}{os} =~ /win/i) ?
                              "M:" : "/automation";
         # check SMB share mounted on the remote test/helper VM
         my $isSMBMount = $self->IsSMBMounted($self->{testbed}{$machine}{ip},
                                           $self->{testbed}{$machine}{os},
                                           $vdNetSrcServer,
                                           $vdNetSrcDir,
                                           $folder);

         if ($isSMBMount eq FAILURE) {
            $vdLogger->Error("Unable to check if SMB is mounted or not");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         if ($isSMBMount == VDNetLib::Common::GlobalConfig::FALSE) {
            # cleanup any mount points on $folder before mounting
            # $vdNetSrcDir share
            $vdLogger->Debug("Cleanup existing mount point on the remote machine");
            if ($self->DeleteMountPoint($self->{testbed}{$machine}{ip},
                                     $self->{testbed}{$machine}{os},
                                     $folder) eq FAILURE) {
            $vdLogger->Error("Cleaning up existing mount points failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Info("Mounting SMB share on $self->{testbed}{$machine}{ip}");
         if ($self->MountVDAuto($machine,
                                $self->{testbed}{$machine}{ip},
                                $self->{testbed}{$machine}{os},
                                $vdNetSrcServer,
                                $vdNetSrcDir,
                                $folder) eq FAILURE) {
               $vdLogger->Error("Unable to Mount SMB share $vdNetSrcServer on " .
                                "$self->{testbed}{$machine}{ip}");
               VDSetLastError("EMOUNT");
               return FAILURE;
            }
         }

         $self->SetMount($machine);
         # set PERLLIB variable on the VM
         # At this point, samba should be running locally
         # samba mount should be available on all the VMs
         # staf on host and vms should be working
         # print for debugging purposes
         if ($self->{testbed}{$machine}{os} =~ /win/i ) {
            my $ret = $self->WinVDNetSetup($machine);
            if ($ret eq FAILURE ) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            } elsif ($ret =~ /rebootrequired/) {
               $vdLogger->Info("Restarting the VM");
               if ( $self->RestartVM($machine) eq FAILURE ) {
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               #
               # copying setup.log file is to avoid rebooting the VM if it is already
               # setup, so it is best effort, if the file is not copied, we do not
               # check for error here.
               #
               `echo "Setup Completed" > /tmp/setup.log`;
               my $srcFile = "/tmp/setup.log";
               my $ip = $self->{testbed}{$machine}{ip};
               my $command = "COPY FILE $srcFile TODIRECTORY C:\\vmqa ".
                             "TOMACHINE $ip\@$STAF_DEFAULT_PORT";
               $self->{stafHelper}->runStafCmd('local', "FS", $command);
            }
         }
         # Disabling firewall on linux.
         if ( $self->{testbed}{$machine}{os} =~ /lin/i ) {
            if ($self->LinVDNetSetup($self->{testbed}{$machine}{ip},
                              $self->{testbed}{$machine}{os}) eq FAILURE ) {
               $vdLogger->Warn("Disabling Firewall failed on ".
                                "$self->{testbed}{$machine}{ip}");
            }
         }

         $vdLogger->Debug("vmx is $self->{testbed}{$machine}{vmx}")
         if $self->{testbed}{$machine}{vmx};
         $vdLogger->Debug("os is $self->{testbed}{$machine}{os}")
         if $self->{"testbed"}{$machine}{os};
         # make sure VM os, ip, vmx, and host IP and Type are filled for

         # all the machines in the testbed.
         foreach my $macEntry (@machineAttributes) {
            if (not defined $self->{testbed}{$machine}{$macEntry} ) {
               $vdLogger->Debug("$macEntry not found in $macEntry in testbed");
               VDSetLastError("EINVALID");
               return FAILURE;
            }
         }

      } # end of if (check for vmx and ip options).
   } # end of the foreach $machine.

}


########################################################################
#
# WinVDNetSetup --
#       Check windows VM setup and setup if necessary
#
# Input:
#       machine entry in test bed
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#       rebootrequired - in case the machine should be rebooted as
#       part of completion of setup.
#
# Side effects:
#       none
#
########################################################################

sub WinVDNetSetup
{
   my $self = shift;
   my $machine = shift;
   my $ip = shift || $self->{testbed}{$machine}{ip};
   my $os = shift || $self->{testbed}{$machine}{os};
   my $macInfo;
   my ($host, $vmx, $command, $cmdOut);
   my $restart = 0;

   if ($os !~ /win/i ) {
      # return SUCCESS if it the machine is not windows
      return SUCCESS;
   }

   $macInfo->{ip} = $ip;
   $macInfo->{os} = $os;
   # No need to send hostType to VDAutomationSetup new().
   # See new in VDAutomationSetup() for more info.

   # Make it dynamic loading module, it will save memory when the test
   # case is just linux based and VDAutomationSetup would not be
   # loaded in memory.
   my $module = "VDNetLib::Common::VDAutomationSetup";
   eval "require $module";
   if ($@) {
      $vdLogger->Error("Failed to load package $module $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Keep new (method) of child as light as possible for better performance.
   my $setup = $module->new($macInfo);
   if ($setup eq FAILURE) {
      $vdLogger->Error("Failed to create obj of package $module");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{setup} = $setup;

   # TODO: create a data structure where you have list of methods to call
   # and just iterate through it in this method

   # check if event tracker is disabled, if not disable
   my $eventTrackerStatus = $setup->IsEventTrackerDisabled();
   if ($eventTrackerStatus eq FAILURE) {
      $vdLogger->Error("Checking event tracker status failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($eventTrackerStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetEventTracker("disable") eq FAILURE) {
         $vdLogger->Error("Disabling event tracker status failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }

   # check if autologin is enabled, if not enable
   my $autoLogonStatus = $setup->IsAutoLogonEnabled();

   if ($autoLogonStatus eq FAILURE) {
      $vdLogger->Error("Checking auto logon status failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($autoLogonStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetAutoLogon("enable") eq FAILURE) {
         $vdLogger->Error("Enabling auto logon failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }

   # install winpcap
   if ($setup->InstallWinPcap() eq FAILURE) {
      $vdLogger->Error("Installing winpcap failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($setup->ConfigFullDump() eq FAILURE) {
      $vdLogger->Error("Configuring full dump failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # disable found new hardware wizard
   if ($setup->CopyDisableFoundNewHardwareWizard() eq FAILURE) {
      $vdLogger->Error("Copying files to disable found new HW wizard failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # disable driver signing off
   if ($setup->DisableDriverSigningWizard() eq FAILURE) {
      $vdLogger->Error("Disabling Driver sign-off failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my ($result, $data) = $self->{stafHelper}->runStafCmd(
                                           $ip,
                                           "FS",
                                           "GET FILE C:\\vmqa\\setup.log");
   if ($data =~ /does not exist/i) {
      $restart = 1;
   }

   # enable plain text passwd - tested and requires reboot
   my $plainTestPasswordStatus = $setup->IsPlaintextPasswordEnabled();

   if ($plainTestPasswordStatus eq FAILURE) {
      $vdLogger->Error("Checking plain text passwd status failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($plainTestPasswordStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetPlaintextPassword("enable") eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }

   if (!$restart) {
      return SUCCESS;
   } else {
      return "rebootrequired";
   }
}

########################################################################
#
# Init --
#       Initializes the testbed hash with all the necessary fields
#       Fill in the test bed details provided by the user in testbed
#       hash.  Call CheckSetup to check VMs, host setup.
#
# Input:
#       None
#
# Results:
#       Initializes pswitch, vmnic, switch, vmknic, vnic, vm, guest,
#       host of both SUT and helper machines.
#
# Side effects:
#       none
#
########################################################################

sub Init
{
   my ($self)       = shift;
   my $session      = $self->{'session'};
   #my $session      = shift;
   #$self->{session} = $session;
   my $skipSetup    = $session->{'skipSetup'};
   my $disableARP   = $session->{'disableARP'};
   my $useVIX       = $session->{'useVIX'};
   my $noTools       = $session->{'noTools'};

   my $machinesHash = $session->{'Parameters'};

   my $logCollector = VDNetLib::Common::LogCollector->new(testbed => $self,
                                                          logDir => $session->{logDir});
   $self->{logCollector} = $logCollector;

   #
   # Delete any machine information that is not required for a session.
   # This is important when running multiple tests in a session, where a
   # machine used in one test may not be needed in the next test case.
   #
   foreach my $machine (keys %{$self->{testbed}}) {
      if (not defined $machinesHash->{$machine}) {
         delete $self->{testbed}{$machine};
      }
   }
   foreach my $machine (keys %$machinesHash) {
      # Keep track of no. of machines in the testbed.
      if ($machine !~ /SUT|helper/i) {
         next;
      }
      $self->{noOfMachines} += 1;

      #
      # Update vmware tools, prefixdir, cache and sync values given at the
      # command line for each machine.
      #
      if (defined $machinesHash->{$machine}->{tools}) {
         $self->{testbed}{$machine}{tools}
                            = $machinesHash->{$machine}->{tools};
         $vdLogger->Info("$machine upgrade vmware-tools from ".
                          $self->{testbed}{$machine}{tools});
      }

      if (defined $machinesHash->{$machine}->{prefixdir}) {
         $self->{testbed}{$machine}{prefixDir}
                            = $machinesHash->{$machine}->{prefixdir};
         $vdLogger->Info("$machine use prefixdir :".
                          $self->{testbed}{$machine}{prefixDir});
      }
      if (defined $machinesHash->{$machine}->{cache}) {
         $self->{testbed}{$machine}{cache}
                            = $machinesHash->{$machine}->{cache};
         $vdLogger->Info("$machine using cache dir : ".
                          $self->{testbed}{$machine}{cache});
      }
      $self->{testbed}{$machine}{sync}
                           = $machinesHash->{$machine}->{sync};

      $self->{testbed}{$machine}{tools}
                           = $machinesHash->{$machine}->{tools};

      #
      # Make sure there are no stale information, this case applies when
      # running multiple tests in a session.
      #
      if (defined $self->{testbed}{$machine}{Adapters}) {
         delete $self->{testbed}{$machine}{Adapters};
      }
      if (defined $self->{testbed}{$machine}{switches}) {
         delete $self->{testbed}{$machine}{switches};
      }
      #
      # Re-create VMOpsObj for every test since not all the attributes
      # of the VM object created in previous test will be used in the
      # current test session. Example: using VC anchor PR682287
      if (defined $self->{testbed}{$machine}{vmOpsObj}) {
         delete $self->{testbed}{$machine}{vmOpsObj};
      }
      #
      # TODO: delete $self->{testbed}{$machine} to make sure
      # everything is reset for every test case.
      #

      #
      # Update the vm and host parameters from the session hash. The reason to
      # update this information from session hash instead of the command line
      # options is to, go by the requirements of test case and not by what is
      # provided at command line. For example, if a test case does not require
      # a vm, but the user provides vm information at command line,
      # then it should be ignored.
      #
      $self->{testbed}{$machine}{host} = $session->{'Parameters'}{$machine}{host};
      $self->{testbed}{$machine}{vm} = $session->{'Parameters'}{$machine}{vm};

      if (defined $self->{testbed}{$machine}{ip}) {
         $self->{testbed}{$machine}{vm} =  $self->{testbed}{$machine}{ip};
      }

      if (defined $self->{testbed}{$machine}{vm}) {
         my $vm = $self->{testbed}{$machine}{vm};
         #
         # If ip address is given, then update "ip" key, otherwise, update vmx
         # key.
         #
         if ($vm =~ /^([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)$/) {
            $self->{testbed}{$machine}{ip} = $vm;
         } else {
            $self->{testbed}{$machine}{vmx} = $vm;
         }
         $self->{testbed}{$machine}{vmID} =
            $session->{'Parameters'}{$machine}{vmID};
         $self->{testbed}{$machine}{datastoreType} =
            $session->{'Parameters'}{$machine}{datastoreType};
      }
   }
   # Create VC Operation object and store into testbed hash.
   if (defined $self->{vc}->{vcaddr}) {
      ($self->{vc}->{username}, $self->{vc}->{passwd}) =
                        VDNetLib::Common::Utilities::GetVCCredentials($self->{stafHelper},
                                                                      $self->{vc}->{vcaddr});
      if ((not defined $self->{vc}->{username}) || (not defined $self->{vc}->{passwd})) {
         $vdLogger->Error("Failed to get login credentials for VC. Please " .
                          "confirm that VC is up and credentials are set to one of " .
                          "the default username/password.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $vdLogger->Info("Found the VC Credentials: $self->{vc}->{username}/" .
                      $self->{vc}->{passwd});

      my $module = "VDNetLib::VC::VCOperation";
      eval "require $module";
      if ($@) {
         $vdLogger->Error("Failed to load package $module $@");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $vcOpsObj = $module->new($self->{vc}->{vcaddr},
                                  $self->{vc}->{username},
                                  $self->{vc}->{passwd});
      if ($vcOpsObj eq FAILURE) {
         $vdLogger->Error("Failed to create VCOperation object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{vc}->{vcOpsObj} = $vcOpsObj;
   }

   #
   # TODO - remove this foreach block after implementing the testbed
   # infrastrcuture end-to-end. Keep this for now, not to break any
   # existing test cases
   #
   foreach my $machine (keys %{$self->{testbed}}) {
      #
      # Add VC Info into each VM.
      if (defined $self->{vc}->{vcaddr}) {
         $self->{testbed}{$machine}{vcaddr} = $self->{vc}->{vcaddr};
         $self->{testbed}{$machine}{vcOpsObj} = $self->{vc}->{vcOpsObj};
      }
   }

   # Initializing host
   my @cache;
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"host"}) {
         foreach my $machineInCache (@cache) {
            if ($self->{testbed}{$machine}{host} eq
                  $self->{testbed}{$machineInCache}{host}) {
               $vdLogger->Info("Host of $machine is same as $machineInCache");
               $self->{testbed}{$machine}{hostObj} =
                  $self->{testbed}{$machineInCache}{hostObj};
               last;
               # Also break the outer loop if host is same.
            }
         }
      }
      if (not defined $self->{testbed}{$machine}{hostObj}) {
         if ($self->InitializeHost($machine) eq FAILURE) {
            VDSetLastError(VDGetLastError());
            if (defined $self->{testbed}{$machine}{hostObj}) {
               $self->{logCollector}->CollectLog("Host");
            }
            return FAILURE;
         }
      }
      if ($self->GetOSAndArch($machine, "host") eq FAILURE) {
         $vdLogger->Error("Failed to get os and arch type of $machine guest");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my $os = $self->{testbed}{$machine}{hostType};
      my $host = $self->{testbed}{$machine}{host};

      #
      # Not throwing error intentionally, since this is a best effort approach
      # to improve performance
      #
      $vdLogger->Info("Update hosts lookup table: " .
                      VDNetLib::Common::Utilities::UpdateLauncherHostEntry($host,
                                                                           $os,
                                                                           $self->{stafHelper}));
      push(@cache, $machine);
   }

   #
   # set the SRIOV flag for the machines if the "pci"
   # spec is given under parameters
   #
   # Initializing physical nics, if any, required for the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
         #
         # Create NetAdapter objects for all pnic/vmnic and store it
         # under the testbed hash.
         #
         if ($self->InitializePhyAdapters($machine) eq FAILURE) {
            $vdLogger->Error("Failed to initialize physical adapters");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # Initialize passthrough if needed for the given vmnic
         #
         if (defined $session->{"Parameters"}{$machine}{"passthrough"}) {
            if ($self->InitializePassthrough($machine) eq FAILURE) {
               $vdLogger->Error("Failed to initialize passthrough on $machine");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
   }
   # Initializing physical switches, if any, required for the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"pswitch"}) {
         #
         # Ensure that the physical switch is accessible
         # Create an object of Switch object with type as "pswitch"
         # and store it under testbed
         #
         my $address = $session->{"Parameters"}{$machine}{"pswitch"};
         my $transport = VDNetLib::Common::GlobalConfig::DEFAULT_SWITCH_TRANSPORT;
         my $type = VDNetLib::Common::GlobalConfig::DEFAULT_SWITCH_TYPE;
         # create a physical switch Object.
         $vdLogger->Info("Creating switch object for pswitch $address " .
                         "on $machine");
         my $pswitchObj = new VDNetLib::Switch::Switch(
                                            switchType => "pswitch",
                                            switchAddress => $address,
                                           transport => $transport,
                                            type => $type);
         if ($pswitchObj eq FAILURE) {
            $vdLogger->Error("Failed to create physical switch object for $machine");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         # update testbed.
         $self->{testbed}{$machine}{pswitch} = $pswitchObj;
      } else {
         #
         # 1. if not given the physical switch ip, use auto-detect CDP info.
         # 2. the value maybe is null if CDP error happened or there is no free
         #    vmnic on that machine.
         # 3. the vmnic index begins from "1" in hash, but not "0".
         # 4. if the free vmnics connected with different
         #    physical switches, assume use the first vmnic.
         #
         $self->{testbed}{$machine}{pswitch} =
                    $self->{testbed}{$machine}{Adapters}{vmnic}{1}{pswitchObj};
      }
      if ( !defined $self->{testbed}{$machine}{pswitch}) {
         $vdLogger->Warn("Physical switch info is missing on $machine,".
                         " may fail to config the physical switch!");
      }
   }


   #
   # Initializing virtual switches, if any, required for the test case
   # The switch initialization will not be done if the test needs to
   # passthrough any pnics directly to the vm.
   #
   # TODO: FIX: vnics can be added to a VM even if passthrough is enabled
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"switch"}) {
         #
         # Create Switch objects for all switches and store it
         # under the testbed hash
         #
         if ($self->InitializeVirtualSwitch($machine) eq FAILURE) {
            VDSetLastError(VDGetLastError());
            $self->{logCollector}->CollectLog("Switch");
            return FAILURE;
         }
      }
   }

   # Initializing vmkernel nics, if any, required for the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vmknic"}) {
         if ($self->InitializeVMKNic($machine) eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   # Initializing virtual machines, if any, required for the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vm"}) {
         # Update vmx for SUT/helper
         $vdLogger->Info("Initializing $machine VM");
         if ($self->InitializeVM($machine) eq FAILURE) {
            $vdLogger->Error("Failed to initialize VM");
            VDSetLastError(VDGetLastError());
            $self->{logCollector}->CollectLog("VM");
            $self->{logCollector}->CollectLog("Host");
            return FAILURE;
         }
         if (defined $self->{testbed}{$machine}{vmx}) {
            #
            # If the machine is from existing resource, then no need to update
            # resource cache, since it already knows the details. If not,
            # update the resource cache
            #
            if (!$session->{Parameters}{$machine}{existingResource}) {
               $vdLogger->Debug("$machine not defined in the cache, adding it");
               my $machineCache;
               $machineCache->{vmID} = $self->{testbed}{$machine}{vmID};
               $machineCache->{vmx} = $self->{testbed}{$machine}{vmx};
               $machineCache->{host} = $self->{testbed}{$machine}{host};
               $machineCache->{machineType} = ($machine =~ /sut/i) ? "SUT" :
                                                                   "helper";
               $machineCache->{lockFileName} =
                  $self->{testbed}{$machine}{lockFileName};
               $machineCache->{runtimeDir} =
                  $self->{testbed}{$machine}{runtimeDir};
               $machineCache->{startedPowerOn} =
                  $self->{testbed}{$machine}{startedPowerOn};

               $machineCache->{datastoreType} =
                  $self->{testbed}{$machine}{datastoreType};

               if (defined $self->{testbed}{$machine}{vmOpsObj}) {
                  $machineCache->{vmOpsObj} =
                     $self->{testbed}{$machine}{vmOpsObj};
               }
               if (not defined $self->{testbed}{$machine}{resourceCacheIndex}) {
                  $self->{testbed}{$machine}{resourceCacheIndex} =
                     scalar(@{$self->{resourceCache}});
               }
               push (@{$self->{resourceCache}}, $machineCache);
            } else { # existing resource
               $self->{testbed}{$machine}{resourceCacheIndex} =
                  $session->{Parameters}{$machine}{resourceCacheIndex};
            }
         }

         $vdLogger->Debug("ResourceCache" . Dumper($self->{resourceCache}));
         #
         # Initializing VirtualAdapters here
         #
         if (defined $session->{"Parameters"}{$machine}{"vnic"}) {
            if (not defined $session->{"Parameters"}{$machine}{"passthrough"}) {
               if ($self->InitializeVirtualAdapters($machine) eq FAILURE) {
                  $vdLogger->Error("Failed to initialize virtual adapters on " .
                                   $machine);
                   VDSetLastError(VDGetLastError());
                   return FAILURE;
               }
            } else {
               $vdLogger->Info("Not Initializing any Virtual Adapters ".
                               "for $machine Since Passthrough flag ".
                               "is specified in parameters");
            }
         }

         # Initializing pci, if any, required for the test case
         if (defined $session->{"Parameters"}{$machine}{"pci"}) {
            # TODO: This call should be replaced with a common
            # method configure PCI device for both SRIOV and FPT
            if ($self->ConfigurePCIDevices($machine) eq FAILURE) {
               $vdLogger->Error("Failed to configure PCI device for $machine");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }

         #
         # NOTE: DO NOT move power on call outside this loop. This will affect
         # the way run time directories are created in CreateVMInstance().
         # PR669189.
         #
         if ($self->PowerOnVM($machine) eq FAILURE) {
            $vdLogger->Error("Failed to power on $machine VM");
            $self->{logCollector}->CollectLog("VM");
            $self->{logCollector}->CollectLog("Host");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } # end of parameters check
   } # end of machines loop

   #
   # Initializing guest. One of the main step is to change the hostname of
   # windows VMs to avoid hostname conflict.
   #
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vm"}) {
         if ($self->InitializeGuest($machine) eq FAILURE) {
            $vdLogger->Error("Failed to initialize VM");
            VDSetLastError(VDGetLastError());
            $self->{logCollector}->CollectLog("VM");
            $self->{logCollector}->CollectLog("Host");
            return FAILURE;
         }
      }
   }
   #
   # Because tools upgrade happens in parallel we need to
   # wait for all tools upgrade processes to end before we do setup

   my $unMountToolsUpgrader = 0;
   foreach my $machine (keys %{$self->{testbed}}) {
      if ((defined $session->{"Parameters"}{$machine}{"vm"}) &&
          ($session->{'noTools'} == 0)){
         if (!$unMountToolsUpgrader) {
            if ($self->WaitForToolsUpgrade($machine) eq FAILURE) {
               $vdLogger->Error("WaitForToolsUpgrade() returned failure for $machine");
               $self->{logCollector}->CollectLog("VM");
               $self->{logCollector}->CollectLog("Host");
               #
               # if failure is returned here,
               # then cancel tools upgrade for this machine and
               # all the following machines in the loop
               #
               $unMountToolsUpgrader = 1;
            }
         }
         if ($unMountToolsUpgrader) {
            #
            # If tools upgrade hit timeout, it is highly possible that the process
            # is still running, we have to cancel the tools upgrade in order to
            # move forward, otherwise many VM operations, for example, change
            # portgroup, will be not be possible since the vmx is busy.
            #
            my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
            my $result = $vmOpsObj->VMOpsUnmountToolsInstaller();
            if ($result eq FAILURE) {
               $vdLogger->Error("Unmounting VMware tools installer also failed");
            }
         } # end of checking if $unMountToolsUpgrader is true
      } # end of tools upgrade check
   } # end of machines loop

   if ($unMountToolsUpgrader) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Perform vdNet automation setup on the given testbed if -s option is not
   # provided at vdNet.pl command-line.
   if (!$skipSetup) {
      #
      # Skip checking samba on controller machine if vdNet source to be used is
      # from scm-trees.
      #
      # The global variables $vdNetSrcServer and $vdNetSrcDir are updated in
      # Init() method which takes source code from scm-trees by default or
      # from the machine specified by -src command-line option at vdNet.pl
      #
      if ($vdNetSrcServer !~ /scm-trees/i) {
         # check SMB setup on the given $vdNetSrcServer
         $vdLogger->Debug("Checking if SAMBA is running locally");
         if ($self->IsSMBRunning() eq FAILURE &&
              $self->StartSMB eq FAILURE) {
            $vdLogger->Error("Either SMB is not installed or unable to run SMB");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Debug("SAMBA is running locally");
      }
      #
      # Now check setup on host and guest
      #
      $vdLogger->Info("Checking setup on SUT and helper machines");
      if ($self->CheckSetup() eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # Initialize virtual adapters in the guest, if required for the test case
   # Creation of VDNetLib::NetAdapter objects happens only here. They are
   # stored in testbed hash to allow workloads to make use of them.
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vnic"}) {
         if ($self->InitializeAdapters($machine) eq FAILURE) {
            $vdLogger->Error("Failed to initialize virtual adapters inside " .
                       "the guests");
            $self->{logCollector}->CollectLog("NetAdapter");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   #
   # Initialize PCI adapters within the guest
   #
   #
   if ($self->InitializePCIAdapters() eq FAILURE) {
      $vdLogger->Error("Failed to initialize PCI adapters");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# InitializePCIAdapters--
#     Method to initialize PCI adapters under tested based on the
#     requirements from test case session
#
# Input:
#     target: SUT or helper<x> (Optional, default is all
#             machines/targets initialized in a session
#
# Results:
#     SUCCESS, if the testbed hash is updated successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializePCIAdapters
{
   my $self    = shift;
   my $target  = shift;
   my $session = $self->{'session'};

   foreach my $machine (keys %{$self->{testbed}}) {
      if ((defined $target) && ($target ne $machine)) {
         next;
      }
      my $pciConfig = $session->{"Parameters"}{$machine}{"pci"};
      if (defined $pciConfig) {
         my $driverHash = {};

         foreach my $item (keys %$pciConfig) {
            my $driver = $pciConfig->{$item}{'driver'};
            if (not defined $driver) {
               $vdLogger->Error("Driver name is not defined");
               $vdLogger->Debug("PCI Config:" . Dumper($pciConfig));
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            if (defined $driverHash->{$driver}) {
               $driverHash->{$driver} = $driverHash->{$driver} + 1;
            } else {
               $driverHash->{$driver} = 1;
            }
         }

         my @requiredAdapters;
         foreach my $driver (keys %$driverHash) {
            my $temp = $driver . ":" . $driverHash->{$driver};
            push(@requiredAdapters, $temp);
         }
         #
         # Call the common method to initialize NetAdapter objects
         #
         if ($self->InitializeAdapters($machine, "pci",
                                       \@requiredAdapters) eq FAILURE) {
            $vdLogger->Error("Failed to initialize virtual adapters inside " .
                             "the guests");
            $self->{logCollector}->CollectLog("NetAdapter");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeHost --
#      Method to initialize physical host required for a session.
#      This method creates VDNetLib::Host::HostOperations object
#      and stores it in testbed hash. Then, all initialization required
#      on the given host is handled in this method.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the required physical hosts are initialized
#                 successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeHost
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $disableARP = $session->{"disableARP"};

   my $hostIP = $self->{testbed}{$machine}{host};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   if (not defined $hostObj) {
      # Updating HostOperations object for SUT/helper<x> in testbed
      $hostObj = VDNetLib::Host::HostFactory::CreateHostObject(hostip => $hostIP,
                                                               stafhelper => $self->{stafHelper});
      if($hostObj eq FAILURE) {
         $vdLogger->Error("Failed to create " .
                          "VDNetLib::Host::HostOperations object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $self->{testbed}{$machine}{hostObj} = $hostObj;
   }

   # Store all portgroup and switch information here
   $hostObj->UpdatePGHash();

   #
   # vdNet framework requires "vdtest" portgroup to be available before
   # running any test. So, creating portgroup "vdtest", if it does not
   # exist.
   #
   if (not defined $hostObj->{portgroups}{'vdtest'}) {
      my $vdtestSwitch = "vdtestSwitch";
      $vdLogger->Info("Creating portgroup vdtest on $hostIP");

      my $result = $hostObj->CreatevSwitch($vdtestSwitch);
      if ($result eq FAILURE) {
	 $vdLogger->Error("Failed to create VSS: $vdtestSwitch on Host: $hostIP");
	 VDSetLastError("EOPFAILED");
	 return FAILURE;
      }

      $result = $hostObj->CreatePortGroup("vdtest", $vdtestSwitch);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create portgroup vdtest on $hostIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #update the portgroup/switch information again
      $hostObj->UpdatePGHash();
   }

   # Setup host for vdNet
   if(!$session->{'skipSetup'}) {
      $vdLogger->Info("Configure host $hostIP for vdnet");
      if ("FAILURE" eq  $hostObj->VDNetESXSetup($session->{'vdNetSrc'},
                                                $session->{'vdNetShare'})) {
         $vdLogger->Error("VDNetSetup failed on host:$hostIP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      #
      # Mount sharedStorage on the host
      #
      my $sharedStorage = $self->{session}{sharedStorage};

      #
      # If the given value for sharedstorage has :, assume the value is
      # in the format server:/share. Then, mount the server on the host
      # and point the given share to /vmfs/volumes/vdnetSharedStorage.
      #
      my ($sharedStorageServer, $sharedStorageShare) =
         split(/:/,$sharedStorage);
      my $esxUtil = $self->{testbed}{$machine}{hostObj}{esxutil};

      $vdLogger->Info("Mount " . $sharedStorageServer .
                      " on $sharedStorageShare");
      $sharedStorage = $esxUtil->MountDatastore($hostIP,
                                                $sharedStorageServer,
                                                $sharedStorageShare,
                                                "vdnetSharedStorage",
                                                0);
      if ($sharedStorage eq FAILURE) {
         $vdLogger->Info("Failed to mount " . $sharedStorageServer .
                         " on $sharedStorageShare");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $sharedStorage = VMFS_BASE_PATH . "$sharedStorage"; # append with
                                                          # /vmfs/volumes
      $self->{testbed}{$machine}{sharedStorage} = $sharedStorage;
   }

   #
   # TODO - modify for hosted implementation
   #
   # Enabling arp inspection in vmkernel, which allows to find any VM's
   # IP address by reading its port information.
   # /net/portsets/<vSwitch>/ports/<port id>/ip.
   # This is done only if the variable $disableARP is not defined.
   #
   my $temp;
   my $operation;
   if (!$disableARP) {
      $temp->{'/config/Net/intOpts/GuestIPHack'} = 1;
      $operation = "Enable";
   } else {
      $temp->{'/config/Net/intOpts/GuestIPHack'} = 0;
      $operation = "Disable";
   }

   $vdLogger->Debug("$operation arp inspection on $hostIP");
   my $result = $hostObj->VMKConfig($operation, $temp);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to $operation arp inspection");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# InitializePhyAdapters --
#      Method to initialize physical nics required for a session.
#      This method finds available physical adapters and creates
#      VDNetLib::NetAdapter::NetAdapter objects.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the required physical adapters are initialized
#                 successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializePhyAdapters
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $hostIP  = $hostObj->{hostIP};

   my $esxUtilObj = $hostObj->{esxutil};
   $vdLogger->Info("Discovering free physical adapters on $machine");
   #
   # TODO - Fix GetFreePNics() to find adapters under Test network defined
   # vdnet testbed requirements.
   # The following block find available physical adapters which is not used
   # by any virtual switches. The number of physical adapters required is
   # defined by the 'vmnic' key under Parameters hash in the test case.
   #
   my @requiredAdapters = @{$session->{Parameters}{$machine}{"vmnic"}};
   my $index = 1; # initiate the adapters index to 1
   for (my $adapter = 0; $adapter < scalar(@requiredAdapters); $adapter++) {
      my ($driver, $adaptersCount, $speed, $passthrough);
      if (ref($requiredAdapters[$adapter]) eq "HASH") {
         $driver = $requiredAdapters[$adapter]->{'driver'};
         $adaptersCount = $requiredAdapters[$adapter]->{'count'};
         $speed = $requiredAdapters[$adapter]->{'speed'};
         $passthrough = $requiredAdapters[$adapter]->{'passthrough'};
      } else {
         ($driver, $adaptersCount, $speed) =
            split(/:/,$requiredAdapters[$adapter]);
      }
      #
      # vdNet supports "any" as a filter to select any type of driver for a phy
      # adapter.
      #
      $driver = ($driver =~ /any/i) ? undef : $driver;
      my @nicList = @{$esxUtilObj->GetFreePNics($hostIP, $driver, $speed)};
      if (scalar(@nicList) lt $adaptersCount) {
         $vdLogger->Error("Available physical adapters " .  scalar(@nicList) .
                          " is less than required:$adaptersCount");
         VDSetLastError("ELIMIT");
         return FAILURE;
      }
      #
      # Once the required phy adapters are found, create NetAdapter objects and
      # store them in testbed hash, so that workloads can refer to them using
      # an index (1,2,...,N) for "TestAdapter" key and "IntType" key (vmnic)
      # in workload hash.
      #
      for (my $item = 0; $item < $adaptersCount; $item++) {
         $vdLogger->Info("Creating NetAdapter object $index for " .
                         "$nicList[$item] on $machine");
         my $netObj = VDNetLib::NetAdapter::NetAdapter->new(controlIP => $hostIP,
                                                            interface => $nicList[$item],
                                                            intType   => "vmnic",
                                                            hostObj  => $hostObj,
                                                           );
         if ($netObj eq FAILURE) {
            $vdLogger->Error("Failed to create vmnic object for $nicList[$item]");
             VDSetLastError(VDGetLastError());
             return FAILURE;
         }
         $self->{testbed}{$machine}{Adapters}{vmnic}{$index} = $netObj;
         if (defined $passthrough) {
            $self->{testbed}{$machine}{Adapters}{vmnic}{$index}{passthrough} =
               $passthrough;
            $session->{"Parameters"}{$machine}{"passthrough"} =
               (defined $passthrough->{'type'}) ? $passthrough->{'type'} : "fpt";
         }
         $index++;
      }
   }

   return SUCCESS;
}


########################################################################
#
# InitializeVM --
#      Method to initialize VM required for a session. This method
#      updates the vmx path of SUT and helper VMs in testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the vmx path is found and updates successfully,
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub InitializeVM
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $vdNetSrc     = $session->{"vdNetSrc"};
   my $useVIX       = $session->{"useVIX"};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $hostIP  = $hostObj->{hostIP};
   my $switchRef = $self->{testbed}{$machine}{switches};
   my @switchArray;
   if (defined $switchRef) {
      @switchArray = @$switchRef;
   }
   my $useVC = undef;

   #
   # If vc is needed and the switch type is vds then
   # use vc as anchor for the vm related operations.
   #
   my $type = "vswitch";
   if (defined $switchRef) {
      $type = $switchArray[0]->{switchType};
   }

   if(defined $session->{Parameters}{vc} && $type =~ m/vdswitch/i) {
      $vdLogger->Info("Using VC anchor for VMOperations");
      $useVC = $self->{testbed}{$machine}{vcOpsObj};
   }

   if (defined $self->{testbed}{$machine}{ip}) {
      #
      # If IP address of the machine is given, then just find the vmx file
      # for the given VM.
      #
      # The previous test might have initialized to some value, which need to
      # be carried forever
      #
      if (not defined $self->{testbed}{$machine}{startedPowerOn}) {
         $self->{testbed}{$machine}{startedPowerOn} = 1;
      }
      $self->{testbed}{$machine}{changeName} = 0;
      if (not defined $self->{testbed}{$machine}{vmx}) {
            $self->{testbed}{$machine}{vmx} = $self->GetVMX($machine);
         if ($self->{testbed}{$machine}{vmx} eq FAILURE) {
            $vdLogger->Error("Failed to get vmx path for $machine");
            VDSetLastError(VDGetLastError());
            $self->{testbed}{$machine}{vmx} = undef;
            return FAILURE;
         }
      }

   } elsif (defined $self->{testbed}{$machine}{vmx}) {
      # VM's ip address if not given, either vmx path or VM name is given
      #
      # machine's runtimeDir defines from which VM directory vmx process
      # is started
      #
      $self->{testbed}{$machine}{runtimeDir} = undef;
      #
      # Use a flag to set/unset whether the windows guest's hostname should be
      # changed in order to mount scm-trees. If a windows VM is link cloned from
      # the VM repository then there will be hostname conflict if two or more
      # instances of same VM are used at the same time. This will prevent
      # mounting automation directory inside the guest
      #
      $self->{testbed}{$machine}{changeName} = VDNetLib::Common::GlobalConfig::FALSE;

      # Initially, SUT's runtimeDir will be undefined. The following block
      # tries to place helper's runtimeDir same as SUT's directory, that way
      # both SUT and helper VM files are present under same sub-directory
      #
      if ((defined $self->{testbed}{SUT}{runtimeDir}) &&
         ($self->{testbed}{$machine}{host} eq $self->{testbed}{SUT}{host})) {
         $vdLogger->Debug("Updating $machine prefixDir same as SUT's " .
                           "runtimeDir" . $self->{testbed}{SUT}{runtimeDir});
         my $temp = $self->{testbed}{SUT}{runtimeDir};
         $temp =~ s/\/SUT//g;
         $self->{testbed}{$machine}{runtimeDir} = $temp;
         $self->{testbed}{$machine}{prefixDir} = $self->{testbed}{SUT}{prefixDir};
      }

      #
      # If the user specifies, ip address for a machine (SUT/helper), it means
      # the VM is already powered ON, no need to create linked clone, or power
      # on the VM. If IP address is not specified, then vmName (absolute vmx path
      # or VM directory name) is expected. Using the vmName CreateVMInstance()
      # method returns the absolute vmx path.
      #
      #
      # if vmx or VM name is given, then vdNet powers on the VM. So, during
      # cleanup the VM has to be powered off (to put it back at the same
      # state before running the test).
      #
      $self->{testbed}{$machine}{startedPowerOn} = 0;
      if (FAILURE eq $self->CreateVMInstance($machine, $useVIX, $useVC)) {
         $vdLogger->Error("Failed to create instance of $machine");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }


      #
      # TODO - Move the following operation of updating vmx as a separate
      # module. The challenge part is handling the case where the ip address is
      # given at the command line. The list should be checked with existing vmx
      # file, if there is any different, then shutdown the vm, update the vmx,
      # power on, wait for staf etc.
      #
      my @list = ('msg.autoAnswer = "TRUE"',
                  'chipset.onlineStandby = "TRUE"',
                  'log.throttleBytesPerSec = "0"',
                  'log.guestNoLogAfterThreshold = "FALSE"',
                  'log.noLogAfterThreshold = "FALSE"',
                  'RemoteDisplay.vnc.enabled="TRUE"',
                  'RemoteDisplay.vnc.port="5909"', # TODO - keep this unique
                  'tools.skipSigCheck = "TRUE"',
                  'vix.commandSecurityOverride.' .
                  'VIX_COMMAND_CONNECT_DEVICE = "TRUE"',
                  'vix.commandSecurityOverride.' .
                  'VIX_COMMAND_IS_DEVICE_CONNECTED = "TRUE"');

      my $ret = VDNetLib::Common::Utilities::UpdateVMX($self->{testbed}{$machine}{host},
                                               \@list,
                                               $self->{testbed}{$machine}{vmx});
      if (($ret eq FAILURE) || (not defined $ret)) {
         $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() " .
                         "failed while update");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Neither vmx or ip address defined for the VM");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $ret = VDNetLib::Common::Utilities::CheckForPatternInVMX(
                                            $self->{testbed}{$machine}{host},
                                            $self->{testbed}{$machine}{vmx},
                                            "^displayName",
					    $self->{stafHelper},
                                            $self->{testbed}{$machine}{hostType});
   if (($ret eq FAILURE) || (not defined $ret)) {
      $vdLogger->Error("STAF error while retrieving display name of " .
                       "$self->{testbed}{$machine}{vmx} on " .
                       "$self->{testbed}{$machine}{host}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($ret eq "") {
      $vdLogger->Error("Display name is empty for " .
                       "$self->{testbed}{$machine}{vmx} on " .
                       "$self->{testbed}{$machine}{host}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $ret =~ s/\s*//g;
   $ret =~ s/\n//g;
   # On ESX its displayName and on WS its displayname.
   $ret =~ s/displayName=//ig;
   $ret =~ s/\"//g;
   $self->{testbed}{$machine}{vmDisplayName} = $ret;
   $vdLogger->Info("VM Display name is $ret");

   my $vmOpsObj;
   #
   # TO DO:
   # based on the component under test, create a table of test bed
   # components that needs to be created and index into the table
   # to figure out whether a given test bed component object needed
   # to be created or not
   #
   if (not defined $self->{testbed}{$machine}{vmOpsObj}) {
      $vmOpsObj = VDNetLib::VM::VMOperations->new($hostObj,
				$self->{testbed}{$machine}{vmx},
				$self->{testbed}{$machine}{vmDisplayName},
				$useVIX, $useVC);
      if (FAILURE eq $vmOpsObj) {
         $vdLogger->Error("Failed to create VMOperations object for $machine");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #
      # Updating VMOperations object for the given machine.
      #
      $self->{testbed}{$machine}{vmOpsObj} = $vmOpsObj;
   }

   #
   # Tools upgrade or vmotion does not require/need cd-rom, so removing it
   #
   my $result = $vmOpsObj->VMOpsDeviceAttachState("CD\/DVD drive");
   if (($result  eq FAILURE) || (not defined $result)) {
      $vdLogger->Error("Not able to get state of any CDROM on this VM");
   }
   if($result ne 0) {
      # If result is non-zero, it means CDROM is attached to this VM.
      my $cdromTask = "remove";
      $result = $vmOpsObj->VMOpsAddRemoveVirtualDevice("cdrom", $cdromTask);
      if($result eq FAILURE){
         $vdLogger->Error("Not able to $cdromTask virtual CDROM to this VM");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# PowerOnVM --
#      Method to power on VM. This method assumes VMOperations object
#      is already created before calling this method.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the vm is powered on successfully,
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub PowerOnVM
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};

   #
   # If ip address is not given, power on the VM or make sure it is
   # powered on using the vmx file
   #
   my $ip = $self->{testbed}{$machine}{ip};
   my $vmx = $self->{testbed}{$machine}{vmx};

   if ((defined $vmx) && (not defined $ip)) {
      $vdLogger->Info("Powering on $vmx");
      if ($vmOpsObj->VMOpsPowerOn() eq FAILURE) {
         $vdLogger->Error("Failed to power on $machine");
         $vmOpsObj->VMOpsUnRegisterVM(); # unregister in case of failure
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeGuest --
#      Method to initialize guest. This method takes care of windows
#      guests to avoid any host name conflicts. Then, this method
#      finds the control ip address of the guest.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the guest is initialized successfully,
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub InitializeGuest
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $ip = $self->{testbed}{$machine}{ip};
   my $vmx = $self->{testbed}{$machine}{vmx};
   my $result;
   #
   # Find mac address of control adapter in the vm.
   #
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $nicsInfo = $vmOpsObj->GetAdaptersInfo();
   if ($nicsInfo eq FAILURE) {
      $vdLogger->Error("Failed to get MAC address of control " .
                       "adapter in $machine");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $adapter (@$nicsInfo) {
      if ($adapter->{'portgroup'} =~ /VM Network/i) {
         $self->{testbed}{$machine}{controlMAC} = $adapter->{'mac address'};
      }
   }

   if (not defined $self->{testbed}{$machine}{controlMAC}) {
      $vdLogger->Error("Unable to find the control adapter's mac address " .
                       "in $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # If IP is not provided then find the IP address of the VM
   if (not defined $ip) {
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP(
                                          $self->{testbed}{$machine}{host},
                                          $self->{testbed}{$machine}{vmx},
                                          $self->{testbed}{$machine}{controlMAC}
                                          );
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get $machine ip address");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $self->{testbed}{$machine}{ip} = $ip;
      $vmOpsObj->{vmIP} = $self->{testbed}{$machine}{ip};
   }

   if ($self->{testbed}{$machine}{changeName} ==
				VDNetLib::Common::GlobalConfig::TRUE) {
      my $newCompName = VDNetLib::Common::Utilities::GetTimeStamp();
      $newCompName =~ s/.*-//g;
      #
      # New computer name will be in the format "Win-<hourminsec>".
      # hour, min, sec will be in 2 digits
      #
      $newCompName = "Win-" . $newCompName;
      my $newIP = VDNetLib::Common::Utilities::ChangeHostname(
                       host => $self->{testbed}{$machine}{host},
                       vmx  => $self->{testbed}{$machine}{vmx},
                       winIP => $ip,
                       compName => $newCompName,
                       machine => $machine,
                       macAddress => $self->{testbed}{$machine}{controlMAC},
                       stafHelper => $self->{stafHelper});
      if ($newIP eq FAILURE) {
         $vdLogger->Error("Failed to change hostname");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{testbed}{$machine}{ip} = $newIP;
      $vmOpsObj->{vmIP} = $self->{testbed}{$machine}{ip};
      $self->{testbed}{$machine}{changeName} = VDNetLib::Common::GlobalConfig::FALSE;
   }

   #
   # get the pnic device, if defined and set the device status to up.
   #
   if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
      # since first pNIC is used to link to the switch(vSS/vDS).
      my $vmnicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{'1'};
      if ($vmnicObj->{status} =~ m/down/i) {
         $result = $vmnicObj->SetDeviceUp();
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to enable the interface ".
                             "$vmnicObj->{vmnic}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   $vdLogger->Info("$machine IP address $self->{testbed}{$machine}{ip}");
   $vdLogger->Info("Waiting for STAF on $self->{testbed}{$machine}{ip}");
   $result = $self->{stafHelper}->WaitForSTAF($self->{testbed}{$machine}{ip});
   if ($result eq FAILURE) {
      $vdLogger->Error("STAF not running on $machine");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($self->GetOSAndArch($machine, "guest") eq FAILURE) {
      $vdLogger->Error("Failed to get os and arch type of $machine guest");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $hostIP = $self->{testbed}{$machine}{ip}; # guest IP

   # Adding OS/Arch atributes to VM Object
   $vmOpsObj->SetOS($self->{testbed}{$machine}{os});
   $vmOpsObj->SetArch($self->{testbed}{$machine}{arch});

   #
   # Not throwing error intentionally, since this is a best effort approach
   # to improve performance
   #
   $vdLogger->Info("Update hosts lookup table: " .
                   VDNetLib::Common::Utilities::UpdateLauncherHostEntry($hostIP,
                                                                        $vmOpsObj->{os},
                                                                        $self->{stafHelper}));

   if (!$session->{'noTools'}) {
      if (FAILURE eq $self->PerformToolsUpgrade($machine)) {
         $vdLogger->Error("Failed to upgrade vmware-tools on $machine");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
}


########################################################################
#
# GetOSAndArch --
#      This method fills the 'os' and 'arch' for the given host or
#      guest.
#
# Input:
#      machine: SUT or helper<x> (Required)
#      machineType: "host" or "guest" (Optional, default is host)
#
# Results:
#      "SUCCESS"", if 'os' and 'arch' details are filled in the testbed
#                  hash for the given machine successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetOSAndArch
{
   my $self = shift;
   my $machine = shift;
   my $machineType = shift || "host";

   my $ip;
   if ($machineType eq "host") {
      $ip = $self->{testbed}{$machine}{host};
   } else {
      $ip = $self->{testbed}{$machine}{ip};
   }
   # Get OS type
   if (($self->{testbed}{$machine}{os} =
       $self->{stafHelper}->GetOS($ip))
       eq FAILURE ) {
      $vdLogger->Error("Failed to get os information of $ip");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Update the VM's arch detail as well
   my $arch = $self->{stafHelper}->Arch($ip);
   if ($arch eq FAILURE) {
      $vdLogger->Error("Failed to get arch type of $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $arch =~ s/\n//g; # remove any new line character
   $self->{"testbed"}{$machine}{arch} = $arch;

   $vdLogger->Debug("arch type of $ip is " .
                    $self->{testbed}{$machine}{arch});

   if ($machineType eq "host") {
      if (($self->{testbed}{$machine}{hostType} =
           $self->{stafHelper}->GetOS(
                                      $self->{testbed}{$machine}{host})) =~
          m/Unknown|FAILURE/i ) {
         $self->{"testbed"}{$machine}{hostType} = undef;
         $vdLogger->Error("unable to determine hostType for ".
                          "$self->{testbed}{$machine}{host}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("host type is $self->{testbed}{$machine}{hostType}");

      $self->{testbed}{$machine}{hostObj}{hostType} =
                                          $self->{testbed}{$machine}{hostType};
      $self->{testbed}{$machine}{hostObj}{arch} =
                                              $self->{testbed}{$machine}{arch};
   }
   return SUCCESS;
}


########################################################################
#
# InitializeVirtualSwitch --
#      Method to initialize (creating and configure) virtual switch
#      required for a session.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the virtual switch is intialized successfully,
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub InitializeVirtualSwitch
{
   my $self	= shift;
   my $machine	= shift;
   my $session	= $self->{session};
   my $hostObj	= $self->{testbed}{$machine}{hostObj};
   my $hostIP	= $hostObj->{hostIP};
   my @hosts	= ();
   my $uplink	= undef;
   my $vmnicObj;

   #
   # find all the hosts (helper, SUT). This is needed for adding
   # those to VC if we need VC for the tests.
   #
   foreach my $machine (keys %{$self->{testbed}}) {
       push(@hosts, $self->{testbed}{$machine}{hostObj});
   }

   #
   # Get the list of virtual switches on the given host
   # Count the number of switches that are of the category
   # given in $session->{"Parameters"}{$machine}{"switch"}
   # Create new virtual switches if the count is less than required.
   # Then, create objects for all the switches and store
   # the reference to an array that has switch objects in the
   # testbed.
   #   $self->{testbed}{$machine}{switches} = \@switchArray;
   #
   my $requiredSwitches = {};
   my $switchRef = $session->{Parameters}{$machine}{"switch"};
   my @switchArray = ();
   my @pgArray = ();
   my $datacenter;
   my $folder;
   my $vcObj;

   # parameters needed for vc.
   if (defined $session->{Parameters}{vc}) {
      $datacenter = "datacenter"."-".$$;
      $folder = "folder"."-".$$;
      $vcObj = $self->{vc}->{vcOpsObj};
   }

   #
   # The format of switch key in Parameters hash is
   # vnic => [<switchType1>:<count>,...,<switchTypeN>:<count>]
   # Get each element of the array above and split them, find the
   # switch type and count required for each switch type.
   #
   foreach my $element (@{$switchRef}) {
      my ($type, $count) = split (/:/, $element);
      $requiredSwitches->{$type} = $count;
   }

   foreach my $item (keys %$requiredSwitches) {
      my $count = $requiredSwitches->{$item};

      my $type = $item;
      if ($type =~ /vss/i) {
         if ($self->{session}->{hosted} == 1) {
            # inside vdnet vss is referred as vmnet for hosted.
            $type = "vmnet";
         } else {
            # inside vdnet vss is referred as vswitch for esx.
            $type = "vswitch";
         }
      } elsif ($type =~ /vds/i) {
         $type = "vdswitch";  # inside vdnet code/workload, vds is referred as
                              # vdswitch
         if (not defined $session->{Parameters}{vc}) {
            # vc must be specified if test uses vdswitch.
            $vdLogger->Error("The VC Address must be specified ".
                             "for using dvs");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }

      for (my $i = 0; $i < $count; $i++) {
         #
         # if "vmnic" is defined under $session->{Parameters}{$machine},
         # uplink the first physical nic to the vSS or to the vDS.
         #
         if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
            #
            # at least one vmnic object should already be defined if
            # the Parameters in
            # test case hash has "vmnic".
            #
            if (not defined $self->{testbed}{$machine}{Adapters}{vmnic}{'1'}) {
               $vdLogger->Error("No vmnic objects defined for $machine");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            my $index = $i + 1;
            $vmnicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{$index};
            $uplink = $vmnicObj->{'interface'};
         }

         #
         # Limiting the processId to a value less than 2000 to avoid
         # false positives while comparing 'esxcfg-vswitch -l' output
	 # with vswitch hash in CreatevSwitch() method.
         #
	 my $switchName = ($type =~ /vswitch/i) ? "vss" : $type;
         $switchName = $self->GenerateSwitchName($switchName, $i);
         if ($switchName eq FAILURE) {
            $vdLogger->Error("Failed to genetate vswtich name");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("Adding Switch $switchName to $machine");
         # TODO implement a wrapper method CreateVirtualSwitch in
         # HostOperations.pm to handle both vss and vds.
         # Remember to cleanup these switches as part of cleanup.
         my $result;
         if ($type =~ /vdswitch/i) {
            # check if the specific vds version is needed.
            my $version;
            if (defined $session->{Parameters}{version}) {
               $version = $session->{Parameters}{version};
            } else {
               $version = $VDNetLib::Common::GlobalConfig::DEFAULTVDSVERSION;
            }
            # store the datacenter and folder name for cleanup part.
            $session->{Parameters}{datacenter} = $datacenter;
            $session->{Parameters}{folder} = $folder;
            if (defined $session->{Parameters}{vc}) {
               $result = $vcObj->SetupVC($folder,
                                         $datacenter,
                                         \@hosts,
                                         $switchName,
                                         $version);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Failed setup the VC for tests");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }

               # add the host to vds.
               $result = $vcObj->AddHostToVDS($datacenter,
                                              $hostIP,
                                              $switchName,
                                              $uplink
                                              );
               if($result eq FAILURE)  {
                  $vdLogger->Error("Failed add host $hostIP to VDS $switchName");
                  VDSetLastError("EOPFAILED");
                  return FAILURE;
               }
            }
         } else {
            $result = $hostObj->CreatevSwitch($switchName);
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to create virtual switch $switchName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("Creating Switch object for $switchName");
         my $switchObj =
            VDNetLib::Switch::Switch->new('switch' => $switchName,
                                          'switchType' => $type,
                                          'host' => $hostObj->{hostIP},
                                          'hostOpsObj' => $hostObj,
                                          'datacenter' => $datacenter,
                                          'vcObj' => $vcObj);
         if ($switchObj eq FAILURE) {
            $vdLogger->Error("Failed to create switch object for $switchName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $switchArray[$i] = $switchObj;

         #
         # uplink the first virtual switch to the the first physical nic.
         #
         if (defined $uplink) {
            if ($switchObj->{'switchType'} =~ /vswitch/i) {
               $vdLogger->Info("Uplinking $switchName to $uplink on $machine");
               $result = $switchObj->{switchObj}->AddvSwitchUplink($uplink);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Failed to uplink $switchName to " .
                                   "$uplink on $machine");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            } # end of checking cound condition
         }

         #
         # for each type of switch created above, create a
         # corresponding type of portgroup except vmnet(Workstation)
         #
         my $pgName;
         if ($type !~ /vmnet/i) {
            $pgName = ($type =~ /vswitch/i) ? "vss" : $type;
            $pgName = $self->GeneratePortgroupName($pgName, $i);
            $vdLogger->Info("Creating portgroup $pgName on $machine");
         }
         if ($type =~ /vdswitch/i) {
            #
            # create dvportgroups with ports, add default ports.
            # additional required ports can be added later in workload.
            #
            my $ports = VDNetLib::Common::GlobalConfig::DEFAULT_DV_PORTS;
            $result = $switchObj->CreateDVPortgroupWithPorts($pgName, $ports);
         } else {
            $result = $hostObj->CreatePortGroup($pgName, $switchName);
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to create portgroup $pgName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         #
         # Similar to virtual switches, create and store all the portgroup
         # objects in the test bed hash.
         #
         my $pgObj;
         if ($type =~ /vdswitch/i) {
            #
            # create the object for dvportgroup.
            #
            $vdLogger->Info("Creating DVPortgroup object for $pgName");
            $pgObj = new VDNetLib::Switch::VDSwitch::DVPortGroup(
                                                     DVPGName => $pgName,
                                                     switchObj => $switchObj->{switchObj},
                                                     stafHelper => $self->{stafHelper}
                                                     );
            if ($pgObj eq FAILURE) {
               $vdLogger->Error("Failed to create dv portgroup object");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }

         } elsif ($type =~ /vmnet/i) {
            #
            # VMNet is for hosted environment. Now there is no
            # concept of portgroup on hosted, but to keep testbed
            # as generic as possible we just point to the switchObj
            # so that in case testbed calls an operation on pg
            # then we can perform that operation on vswithch of hosted.
            #
            $pgObj = $switchObj;
         } else {
            $vdLogger->Info("Creating Portgroup object for $pgName,");
            $pgObj = VDNetLib::Switch::VSSwitch::PortGroup->new(
                           'hostip' => $hostIP,
                           'pgName' => $pgName,
                           'switchObj' => $switchObj,
                           'hostOpsObj' => $hostObj);
         }

         if ($pgObj eq FAILURE) {
            $vdLogger->Error("Failed to portgroup $pgName on $machine");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $pgArray[$i] = $pgObj;
      }
   }
   $self->{testbed}{$machine}{switches} = {}; # making sure there is no other
                                              # value stored in this key
   $self->{testbed}{$machine}{portgroups} = {};
   $self->{testbed}{$machine}{switches} = \@switchArray;
   $self->{testbed}{$machine}{portgroups} = \@pgArray;
   return SUCCESS;

}


########################################################################
#
# InitializeVMKNic --
#      Method to initialize vmknics required for a session. This method
#      checks if vmknic is required for a the given test case, creates
#      them, created NetAdapter objects for them and stores in testbed
#      hash.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the vmknics are initialized successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub InitializeVMKNic
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};

   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $hostIP  = $hostObj->{hostIP};
   my @switchArray = @{$self->{testbed}{$machine}{switches}};
   my $pgObj;
   my $result;

   #
   # vmknic is different from other testbed components in vdnet.
   # Users cannot pass any information about vmknic from command line.
   # If vmknic is part of a test case, then it should be mentioned
   # under Parameters hash in the test case using the key "vmknic".
   # The format of the value for vmknic key is:
   # vmknic => [switch1:<count>,switch2:<count>,...,switchN:<count>],
   #
   # Here switch 1,2,...,N refers to the virtual switches indicated
   # by "switch" key in the Parameters hash. For example,
   # switch => [vss:2,vds:3], in this case, 2 vswitch'es and 3 vdswitch'es
   # have to be initialized. So the total is 5 switches.
   #
   # The value of vmknic key informs the number of vmknics to be created
   # on each of these switches.
   #
   # Count the number of switches that are of the category
   # given in $session->{"Parameters"}{$machine}{"vmknic"}
   # Create new vmknics for the given count and portgroup.
   # Then, create objects for all the vmknic's and store
   # the reference to an array that has switch objects in the
   # testbed.
   #   $self->{testbed}{$machine}{Adapters}{vmknic}
   #
   my $requiredVMKNics = {};
   my $vmknicArray = $session->{Parameters}{$machine}{"vmknic"};
   my @pgArray = ();

   foreach my $element (@$vmknicArray) {
      #
      # find the switch index and count of vmknic to be created in each one of
      # them.
      #
      my ($switch, $count) = split (/:/, $element);
      $requiredVMKNics->{$switch} = $count;
   }

   my $index = 1;
   foreach my $item (keys %$requiredVMKNics) {
      my $count = $requiredVMKNics->{$item};
      my $switchIndex = undef;

      my $switch = $item;
      if ($switch =~ /Switch(\d)/i) { # the switch is refered by Switch<X> in
                                      # vmknic key
         $switchIndex = $1;
         $switchIndex = $switchIndex - 1; # since Switch objects are stored in
                                          # an array, decrement the index by 1
                                          # to access the right element from
                                          # the array.
                                          #
      } else {
         $vdLogger->Error("Unknown switch reference:$switch");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      my $switchObj = $switchArray[$switchIndex];
      if (not defined $switchObj) {
         $vdLogger->Error("Switch obj not defined for index $switchIndex");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      for (my $i =1; $i <= $count; $i++) {
         #
         # After finding the number of vmknics to be created on each switch,
         # create vmkernel portgroups before creating vmknic.
         # There is a one-one relationship between vmkernel portgroup  and
         # vmknic. Hence, a vmknic can be referred using it's device id or
         # portgroup name.
         #
         my $pgName = $self->GeneratePortgroupName("vmk", $i);
         $vdLogger->Info("Creating vmkernel portgroup $pgName under switch " .
                         $switchObj->{'name'} . " on $machine");
         if ($switchObj->{'switchType'} =~ /vdswitch/i) {
            my $ports = VDNetLib::Common::GlobalConfig::DEFAULT_DV_PORTS;
            $result = $switchObj->CreateDVPortgroupWithPorts($pgName, $ports);
         } else {
            $result = $hostObj->CreatePortGroup($pgName, $switchObj->{'name'});
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to create portgroup $pgName on $machine");
            VDSetLastError(VDGetLastError());
            return FAILURE;
        }


         if ($switchObj->{'switchType'} =~ /vdswitch/i) {
            $pgObj = new VDNetLib::Switch::VDSwitch::DVPortGroup(
                                                    DVPGName => $pgName,
                                                    switchObj => $switchObj->{switchObj},
                                                    stafHelper => $self->{stafHelper}
                                                    );
         } else {
            # create portgroup object and store it in testbed.
            $pgObj = VDNetLib::Switch::VSSwitch::PortGroup->new(
                               'hostip' => $hostIP,
                               'pgName' => $pgName,
                               'switch' => $switchObj,
                               'hostOpsObj' => $hostObj);
         }
         if( $pgObj eq FAILURE ) {
            $vdLogger->Error("Failed to create portgroup object for $pgName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         # update testbed.
         push(@{$self->{testbed}{$machine}{portgroups}}, $pgObj);

         # Create/Add vmknic to the portgroup created above
         if ($switchObj->{switchType} =~ /vdswitch/i) {
            $result = $switchObj->AddVMKNIC(host => $hostIP,
                                            dvportgroup => $pgName,
                                            ip => "dhcp");
         } else {
            $result = $hostObj->AddVmknic('pgName' => $pgName,
                                          'ip'     => "dhcp");
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to create vmknic in portgroup $pgName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Create NetAdapter object and store in the testbed hash.
         my $netObj = VDNetLib::NetAdapter::NetAdapter->new(controlIP => $hostIP,
                                                            pgObj  => $pgObj,
                                                            hostObj => $hostObj,
                                                            interface => $pgName,
                                                            intType   => "vmknic",
                                                            switchType => $switchObj->{switchType},
                                                            switch     => $switchObj->{switchObj}->{switch},
                                                           );
         if ($netObj eq FAILURE) {
            $vdLogger->Error("Failed to create vmknic object for $pgName");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $self->{testbed}{$machine}{Adapters}{vmknic}{$index} = $netObj;
         $index++;
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeVirtualAdapters --
#      Method to initialize virtual adapters required for the given
#      session.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the virtual adapters are created/discovered
#                 successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub InitializeVirtualAdapters
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $result;
   my $pgRef = $self->{testbed}{$machine}{portgroups};
   my @pgArray = @$pgRef;
   my $portgroup;

   #
   # If this method is called, then Parameters hash must have had a key "vnic"
   # in it. If vnic key is present, then 'switch' key must also be there.
   # Presence of "switch" means, at least 1 switch and 1 portgroup on it
   # have been initialized.
   # Therefore, use the first portgroup on the first switch to
   # initialize the virtual adapters. Change the portgroups of all test
   # adapters from "vdtest" to the first initialized portgroup.
   #
   # For hosted portgroup is same as vswitch name
   if ($self->{session}->{hosted}) {
      $portgroup = $pgArray[0]->{switchObj}->{switch};
      if ($portgroup !~ /vmnet/i) {
	 $vdLogger->Error("Hosted vSwitch name is not named like vmnet.");
	 return FAILURE;
      }
   }elsif (defined $pgArray[0]->{'pgName'}) {
      $portgroup = $pgArray[0]->{'pgName'};
   } else {
      $portgroup = $pgArray[0]->{'DVPGName'};
   }
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   if (not defined $vmOpsObj) {
      $vdLogger->Error("VM operations object required to initialize " .
                       "virtual adapters");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Gets the list of adapters from the given VM.
   # Count the adapters that match the given adapter type
   # $session->{"Parameters"}{$machine}{"vnic"}.  Create adapters
   # if the count is not matched. Then, after powen on, create objects of
   # VDNetLib::NetAdapter::NetAdapter class and store the objects
   # under:
   # $testbed->{testbed}{$machine}{Adapters}{$index}
   #  where $index is 1,2,...N and N is total number of adapters
   #
   my $adapters = $vmOpsObj->GetAdaptersInfo();
   if ($adapters eq FAILURE) {
      $vdLogger->Error("Failed to get adapters information on $machine");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $existingCount = 0;
   my $requiredCount = 0; # will accumalate the total number of adapters
                          # required
   my $mgmtCount = 0;
   my $existingAdapters; # keeps track of existing adapters.
                         # this is also a hash variable with key/values:
                         # <adapterType> => <count>
                         #
   my $requiredAdapters = {};
   my $vnicArray = $session->{Parameters}{$machine}{vnic};

   foreach my $element (@$vnicArray) {
      my ($type, $count) = split (/:/, $element);
      if (defined $requiredAdapters->{$type}) {
         $requiredAdapters->{$type} = $requiredAdapters->{$type} + $count;
      } else {
         $requiredAdapters->{$type} = $count;
      }
   }

   $vdLogger->Info("Virtual Adapters needed on $machine " .
                    Dumper($requiredAdapters));
   my @deleteList = ();
   my $adaptersList = " "; # using space intentionally to verify whole words
   foreach my $item (keys %$requiredAdapters) {
      $requiredCount = $requiredCount + $requiredAdapters->{$item};
      # Create a string of required adapters type. example:
      # " e1000 vmxnet3 e1000e "
      # using space intentionally to verify whole words
      $adaptersList = $adaptersList . $item . " ";
   }

   foreach my $item (@$adapters) {
      #
      # The adapter list returned by method GetAdaptersInfo() which uses staf
      # sdk, refers  to adapter type as "Virtual<adapterType>" i.e before every
      # adapter type "Virtual" is prefixed. It is removed here to keep adapter
      # type values consistent.
      #
      my $type = $item->{"adapter class"};
      if ($type =~ /Virtual/) {
         $type =~ s/Virtual//g;
      }
      $type = lc($type); # keep adapter type in lower case
      my $macAddress = $item->{"mac address"};
      if ($item->{portgroup} !~ /VM Network/) {
         $existingAdapters->{$type} = (defined $existingAdapters->{$type}) ?
                                       $existingAdapters->{$type} + 1 :
                                       1;
         $existingCount++;
         if ($adaptersList !~ /\s$type\s/i) { # checking for space before and
                                             # after $type ensures
                                             # verification of whole words.
                                             # Example:
                                             # if $adaptersList = " e1000e "
                                             # and $type = "e1000",
                                             # then this condition is true.
            $vdLogger->Debug("Required adapterList $adaptersList does not " .
                             "require adapter type $type");
            push(@deleteList, $item);
         } elsif ($adaptersList =~ /\s$type\s/i) {
            # if the adapter type matches with the adapter type required and ...
            if (int($requiredAdapters->{$type}) == 0) {
               # the count of existing adapters of given type is greater than
               # required count, then mark for deletion.
               $vdLogger->Info("Deleting additional adapter of type $type");
               push(@deleteList, $item);
               $existingAdapters->{$type} = $existingAdapters->{$type} - 1;
            } else {
               # if the count of existing adapters of given type is less than
               # or equal to the required count, then reduce the total count
               # of required adapters by 1, since the adapter type needed
               # already exists.
               #
               $requiredAdapters->{$type} = $requiredAdapters->{$type} - 1;
               $requiredCount--;
            }
         }
         # Change portgroup to unique portgroup name here for ESX based
         # test infrastructure.
         if (($self->{session}->{hosted} == 0) &&
             ($item->{portgroup} !~ /$portgroup/)) {
            $vdLogger->Debug("Changing portgroup of $macAddress to $portgroup " .
                            "on $machine");
            $result = $vmOpsObj->VMOpsChangePortgroup($macAddress, $portgroup);
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to change portgroup of $macAddress");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      } else {
         $mgmtCount++;
         if ($mgmtCount > 1) {
            #
            # if more than one control adapter exists (in portgroup "VM
            # Network"), then remove that as well. Otherwise, there might be a
            # problem while running wake on lan tests.
            #
            push(@deleteList, $item);
         }
      }
   }

   #
   # delete all the adapters marked for deletion.
   # This process ensures that there are not extra virtual adapters in a vm
   # than what is needed for a test case.
   #
   for (my $i = 0; $i < scalar(@deleteList); $i++) {
      $vdLogger->Debug("Deleting adapter: $deleteList[$i]->{'mac address'} " .
                     "on $machine");
      $result = $vmOpsObj->VMOpsHotRemovevNIC($deleteList[$i]->{'mac address'});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove adapter " .
                          $deleteList[$i]->{'mac address'});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   #
   # Add virtual adapters of the given driver type, if needed.
   #
   foreach my $item (keys %$requiredAdapters) {
      my $count = $requiredAdapters->{$item};
      my $type = $item;
      for (my $i=0; $i < $count; $i++) {
         $vdLogger->Info("Adding adapter $item to $machine");
         $result = $vmOpsObj->VMOpsHotAddvNIC($type, $portgroup);
	        if ($result eq FAILURE) {
           $vdLogger->Error("Failed to add adapter of type " .
                     "$type on $machine");
            VDSetLastError(VDGetLastError());
	           return FAILURE;
         }
      }
   }

   #
   # if only vmx is specified and pNic is needed then set
   # the status of test pNic to down.
   #
   if (defined $self->{testbed}{$machine}{vmx} &&
       not defined $self->{testbed}{$machine}{ip}) {
      if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
         # since first pNIC is used to link to the switch(vSS/vDS).
         my $vmnicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{'1'};
         if ($vmnicObj->{status} =~ m/up/i) {
            $result = $vmnicObj->SetDeviceDown();
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to disable the interface ".
                                "$vmnicObj->{vmnic}");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
   }

   return SUCCESS;
}


########################################################################
#
# InitializeAdapters --
#      Method to create NetAdapter objects for adapters, if any,
#      required for the given test case.
#      This method is used to initialize adapters on 1) guest for esx
#      2) for guest and host both on hosted platform.
#
# Input:
#      None.
#
# Results:
#      "SUCCESS", if NetAdapter objects of required driver types and
#      count values are created in the testbed hash  successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub InitializeAdapters
{
   my $self     = shift;
   my $machine  = shift;
   my $intType  = shift || "vnic";
   my $adaptersList = shift;

   #
   # This method is used to initialize adapters on a linux, windows, mac
   # etc. Now for esx these are guests.
   # But for Hosted platform these OSes are hosts. Now in vdnet we call
   # host adapter interfaces as vmknics.
   # This method works for both
   # - initializing guest adapters in esx
   # - initializing guest and host adapters in hosted platform
   #

   my $testbed  = $self->{testbed};
   my $session  = $self->{session};

   my @requiredAdapters;
   if (defined $adaptersList) {
      @requiredAdapters = @{$adaptersList};
   } else {
      @requiredAdapters = @{$session->{Parameters}{$machine}{$intType}};
   }

   my $index = 1; # initiate the adapters index to 1

   for (my $adapter = 0; $adapter < scalar(@requiredAdapters); $adapter++) {
      my ($driver, $adaptersCount) = split(/:/,$requiredAdapters[$adapter]);
      my $hash;
      if ($intType =~ /vmknic/i) {
         $vdLogger->Info("Discovering adapters on host: $machine " .
                         "with control ip: $testbed->{$machine}{host}");
         $hash->{controlIP} = $testbed->{$machine}{host};
         $driver = "all";
      } else {
         $vdLogger->Info("Discovering network adapters on VM: $machine " .
                         "with control ip: $testbed->{$machine}{ip}");
         $hash->{controlIP} = $testbed->{$machine}{ip};
      }
      #
      # Find the test/support driver/device name on SUT, helperX
      # respectively from the testcase hash. This information is stored
      # in the testcase hash by ProcessTDSID() at vdNet.pl script.
      #
      if (not defined $driver) {
         $vdLogger->Error("DriverName not found for $machine");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $adaptersCount = (defined $adaptersCount) ? $adaptersCount : 1;
      if ($intType =~ /vnic|pci/i) {
         $vdLogger->Info("$intType driver to find on $machine:$driver, " .
                         "count:$adaptersCount");
      }
      my @result = VDNetLib::NetAdapter::Vnic::Vnic::GetAllAdapters($hash,
                                                                    $driver,
                                                                    $adaptersCount
                                                                   );
      if ($result[0] eq "FAILURE") {
         $vdLogger->Error("Virtual adapter discovery failed " .
                         "on $hash->{controlIP}");
         $vdLogger->Debug("Discovered Adapters:\n" . Dumper(@result));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($intType =~ /vnic|pci/i) {
         $vdLogger->Info("$intType driver $driver found on $machine");
      }
      foreach my $objItem (@result) {
         $objItem->{intType} = $intType; # need to add this since old
                                         # NetAdapter i.e Vnic.pm does not
                                         # know about this attribute.
         $objItem->{vmOpsObj} = $self->{testbed}{$machine}{vmOpsObj};
         my $netObj = VDNetLib::NetAdapter::NetAdapter->new(%$objItem);
         if ($netObj eq "FAILURE") {
            $vdLogger->Error("Failed to initialize NetAdapter obj " .
                             "for $driver on $machine");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # Store the NetAdapter object for each of the discovered
         # test/support adapter in testbed hash. This information will
         # be used to all different workload modules
         # (NetAdapterWorkload, TrafficWorkload etc.)
         #
         if ($intType =~ /vmknic/i) {
            $testbed->{$machine}{Adapters}{vmknic}{$index} = $netObj;
         } elsif ($intType =~ /pci/i) {
            $testbed->{$machine}{'Adapters'}{'pci'}{$index} = $netObj;
         } else {
            $testbed->{$machine}{Adapters}{$index} = $netObj;
         }
         $index++;
      }
   } # end of required adapter loop for each machine

   return SUCCESS;
}


########################################################################
#
# InitializePassthrough --
#     Method to initialize passthrough on the host/adapters
#
# Input:
#     machine: SUT or helper<x> where x is integer, (Required)
#
# Results:
#     "SUCCESS", if passthrough is enabled successfully;
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializePassthrough
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $passthrough = $session->{"Parameters"}{$machine}{"passthrough"};
   my $vmnics = $self->{testbed}{$machine}{Adapters}{vmnic};

   if ($passthrough eq "sriov") {
      return $self->ConfigureSRIOV($machine);
   } else {
      # OLD way of enabling passthrough, will be deprecated
      return $self->InitializeFPT($machine);
   }
}


########################################################################
#
# ConfigureSRIOV --
#     Method to initialize SRIOV on the given machine (SUT/helper's)
#     host.
#
# Input:
#     machine: SUT/helper<x> where x is integer (Required)
#     action : "enable" or "disable" on adapters marked for
#              passthru (sriov) on the given machine
#              (Optional, default is "enable")
#
# Results:
#     SUCCESS, if SRIOV is initialized successfully on the given
#              machine;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureSRIOV
{
   my $self = shift;
   my $machine = shift;
   my $action = shift || "enable";
   my $session = $self->{session};
   my $passthrough = $session->{"Parameters"}{$machine}{"passthrough"};
   my $vmnics = $self->{testbed}{$machine}{Adapters}{vmnic};
   my $sriovHash;

   # template for passthrough hash
   # $sriovHash => {
      # '<driver1>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
      # '<driver2>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
      # .
      # .
      # '<driverN>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
   # }

   my $index = 0;

   #
   # Configuring SRIOV means loading sriov supported driver
   # which could enable adapters with different max_vfs values.
   # It is necessary to collect the list of adapters that can be
   # initialized by this driver.
   #

   #
   # 1. For each element in the passthrough array,
   #    get the vmnic and corresponsing maxVF.
   # 2. Groups adapters based on driver type.
   # 3. Collect all existing adapter of this driver type on the machine.
   # 4. Find the position mapping for max_vfs option. Any adapter that is not
   #    part of this session's testbed will have max_vf value as 0
   #
   $vdLogger->Info("Configuring pasthrough: sriov on $machine");
   foreach my $pnic (keys %$vmnics) {
      my $passthrough =
         $self->{testbed}{$machine}{Adapters}{vmnic}{$pnic}{passthrough};
      my $adapterHash = undef;
      my $nicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{$pnic};
      $adapterHash->{'adapter'} =  $nicObj;
      my $driver = $nicObj->{'driver'};
      if (defined $passthrough) {
         $adapterHash->{'maxvfs'} = ($action =~ /disable/i) ? "0" :
                                    $passthrough->{'maxvfs'};
      } else {
         $adapterHash->{'maxvfs'} = "0";
      }
      push (@{$sriovHash->{$driver}}, $adapterHash);
   }

   my $hostObj = $self->{testbed}{$machine}{hostObj};
   foreach my $driver (keys %$sriovHash) {
      if (FAILURE eq $hostObj->ConfigureSRIOV($sriovHash->{$driver}, $driver)) {
         $vdLogger->Error("Failed to configure SRIOV");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
}


########################################################################
#
# InitializeFPT --
#      Method to initialize passthrough.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the passthrough gets enabled and vm is assigned
#                 the pci device.
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub InitializeFPT
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $vmnics = $self->{testbed}{$machine}{Adapters}{vmnic};
   my @nics = ();
   my $index = 0;
   my $result;

   # get the list of nics required for FPT.
   if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
      foreach my $pnic(keys%$vmnics) {
         my $nicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{$pnic};
         $nics[$index] = $nicObj->{vmnic};
         $index++;
      }
   }
   #
   # Enable FPT
   #
   $result = $hostObj->EnableFPT(\@nics);
   if($result eq FAILURE) {
      $vdLogger->Error("Failed to enable FPT on host ".
                      "$hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigurePCIDevices --
#      Method to configure PCI device (SRIOV) on the given
#      VM.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the sriov gets enabled and vm is assigned
#                 the pci device.
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ConfigurePCIDevices
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $vmnics = $self->{testbed}{$machine}{Adapters}{vmnic};
   my $pciID;
   my $index = 1;
   my $result;

   my $pciConfig = $session->{Parameters}{$machine}{'pci'};
   my $masterPCIConfigHash = undef;
   foreach my $item (keys %$pciConfig) {
      my $list;
      if ($item =~ /\[(.*)\]/) {
         $list = $1;
      } else {
         $vdLogger->Error("Unknown key given for pci spec: $item");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      my $keyList = VDNetLib::Common::Utilities::GetKeyList($list);
      foreach my $index (@$keyList) {
         $masterPCIConfigHash->{$index} = $pciConfig->{$item};
      }

   }

   $result = $vmOpsObj->VMOpsRemoveSRIOVPCIPassthru();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to remove pci passthrough devices ".
                       "from the VM");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $index (keys %$masterPCIConfigHash) {
      my $passthruDevice = $masterPCIConfigHash->{$index}{'passthrudevice'};
      my $vfIndex = $masterPCIConfigHash->{$index}{'virtualfunction'};
      my $vfVLAN = $masterPCIConfigHash->{$index}{'vlan'};
      my $vfMAC = $masterPCIConfigHash->{$index}{'macaddress'};
      my $vmnicObj = VDNetLib::Workloads::Utils::GetAdapterObj($self,
                                                               $passthruDevice);
      $masterPCIConfigHash->{$index}{'driver'} = $vmnicObj->{'driver'};
      #
      # Every key other than 'vmnic' is ignored in case of FPT
      #
      $result = $vmOpsObj->VMOpsAddPCIPassthru(vmnic => $vmnicObj,
                                               vfIndex => $vfIndex,
                                               method => "vmx",
                                               pciIndex => $index-1,
                                               vfVLAN => $vfVLAN,
                                               vfMAC => $vfMAC);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to add VFs to VM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   delete $session->{Parameters}{$machine}{'pci'};
   $session->{Parameters}{$machine}{'pci'} = $masterPCIConfigHash;
   return SUCCESS;
}


########################################################################
#
# GetVMX --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the machine
#      in the testbed.
#	    1. Get the MAC address corresponding to the IP address of the
#	       machine.
#	    2. Get VMX files of all the VMs using vim-cmd.
#	    3. Grep the MAC found in step1 in each of the vmxFile
#	    4. If the MAC is found return the VMX
#	    5. If it is not found in any of the VMX files, return
#	       undef
#
# Input:
#      Machine name in the testbed
#
# Results:
#      VMX file name relative to its DataStore as mentioned above
#
# Side effects:
#      None
#
########################################################################

sub GetVMX
{
   my $self = shift;
   my $machine = shift;

   my $storage;
   my $vmxFile;
   my $vmx;
   my $mac;
   my $command;

   if ( not defined $self->{testbed}{$machine}{ip} &&
        not defined  $self->{testbed}{$machine}{hostType} &&
        $self->{testbed}{$machine}{hostType} !~ /esx|vmkernel/i ) {
      $vdLogger->Error("invalid machine details: ip, host " .
            " $self->{testbed}{$machine}{ip} $self->{testbed}{$machine}{hostType}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Get MAC address corresponding to the VM IP address
   # The below mechanism to get IP assume STAF working on the VM
   #
   $mac = VDNetLib::Common::Utilities::GetMACFromIP(
                                            $self->{testbed}{$machine}{ip},
                                            $self->{stafHelper});
   $vdLogger->Debug("GetVMX: MAC address returned by GetMACFromIP, $mac");
   if ((not defined $mac) || ($mac eq FAILURE)) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # replace '-' with ':' as it appears in the vmx file
   $mac =~ s/-/:/g;

   $command = "start shell command vim-cmd vmsvc/getallvms " .
                       "wait returnstdout";
   my ($result, $data) = $self->{stafHelper}->runStafCmd(
                                $self->{testbed}{$machine}{host},
                                "process", $command);

   if ( ($result ne SUCCESS) ||  (not defined $data) ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # sample output of vim-cmd vmsvc/getallvms
   # Vmid Name      File               Guest OS Version   Annotation
   # 112 sles11-64 [Storage1] sles11-32/sles11-32.vmx sles10Guest vmx-07
   my @vimcmd = split(/\n/,$data);
   if ( scalar(@vimcmd) > 1 ) {
      foreach my $vmline (@vimcmd) {
         $vmline =~ s/\s+/ /g;
         $vmline =~ s/\t|\n|\r//g;

         if ( $vmline =~ /.* (\[.*\]) (.*\.vmx) .*/ )  {
            $storage = $1;
            $vmx = $2;
            $vmxFile = "$storage "."$vmx";
            $vdLogger->Debug("vmxFile: $vmxFile");
            if ( defined $storage && defined $vmx ) {
               # if MAC address is found then we found vmx
               my $eth = VDNetLib::Common::Utilities::GetEthUnitNum(
                         $self->{testbed}{$machine}{host},
                         VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile), $mac);
               if ( $eth eq FAILURE ) {
                  # ignore the error as it is possible not to find the mac
                  # address in this vmxFile
                  VDCleanErrorStack();
                  next;
               } elsif  ($eth =~ /^ethernet/i) {
                  # storing the vmx path in absolute file format
                  $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
                  return $vmxFile;
               }
            }
         }
      }
   }
   # in case of the vms are powered on using /bin/vmx command then
   # vim-cmd will not list un-registered VMs hence use vsish to get it.
   $command = "start shell command vsish -e ls /vm " .
                    "wait returnstdout";
   ($result, $data) = $self->{stafHelper}->runStafCmd(
                             $self->{testbed}{$machine}{host},
                             "process", $command);
   if ( ($result ne SUCCESS) ||  (not defined $data) ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   @vimcmd = split(/\n/,$data);
   foreach my $vmline (@vimcmd) {
      $command = "start shell command vsish -e get /vm/$vmline" .
                             "vmmGroupInfo | grep \"vmx\" " .
                              "wait returnstdout";
      my ($result, $data) =
            $self->{stafHelper}->runStafCmd( $self->{testbed}{$machine}{host},
                                             "process", $command);
      if ( ($result ne SUCCESS) ||  (not defined $data) ) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ( $data =~ /\s*config file path:(.*)/ ) {
         $vmxFile = $1;
         chomp($vmxFile);
      } else {
         next;
      }

      if ( (defined $vmxFile) && ($vmxFile =~ /\.vmx/) ) {
         # if MAC address is found then we found vmx
         my $eth = VDNetLib::Common::Utilities::GetEthUnitNum(
                      $self->{testbed}{$machine}{host},
                      $vmxFile, $mac);
         if ( $eth eq FAILURE ) {
            # ignore the error as it is possible not to find the mac
            # address in this vmxFile
            VDCleanErrorStack();
            next;
         } elsif  ($eth =~ /^ethernet/i) {
            #
            # vsish reports the vmx file in canonical format, change
            # it to storage format as required by VMOperations module
            # The way it is done, is get the ls -l /vmfs/volumes output
            # match the symlink pointer of the storage with the canonical
            # directory in the path reported by vsish.
            #
            $command = "START SHELL COMMAND ls parms -l " . VMFS_BASE_PATH .
                       " WAIT RETURNSTDOUT STDERRTOSTDOUT";
            my ($result, $data) =
            $self->{stafHelper}->runStafCmd(
                                          $self->{testbed}{$machine}{host},
                                          "PROCESS", $command);
            if ( ($result ne SUCCESS) ||  (not defined $data) ) {
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            my @listOfFiles = split(/\n/,$data);
            foreach my $line (@listOfFiles) {
               # lrwxr-xr-x    1 root     root                 35 Aug  6 18:21
               # Storage-1 -> 495028af-13fdc8af-c0e7-00215a47b2ce
               if ( $line =~ /.*\d+\:\d+ (.*?) -> (.*)/ ) {
                  my $storage = $1;
                  my $datastore = $2;
                  if ( $vmxFile =~ /$datastore/ ) {
                     $vmxFile =~
                         s/\/vmfs\/volumes\/$datastore\//\[$storage\] /;
                  }
               }
            }
            # storing the vmx path in absolute file format
            $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
            return $vmxFile;
         }
      }
   }
   VDCleanErrorStack();
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


########################################################################
# GetPortGroupName --
#       Return the port group name corresponding to the given MAC
#       address in the given VMX file on the given HOST.
#       This method is only applicable to ESX
#	Call GetEthUnitNum to get the ethernet# for the given MAC
#	address
#	Grep for NetworkName corresponding to the ethernet# for
#	port group name
#
# Input:
#       HOST, VMXFILE, and MAC address
#
# Results:
#       Port Group name, if found else undef
#
# Side effects:
#       none
#
########################################################################

sub GetPortGroupName
{
   my $command;
   my $result;
   my $host;
   my $service;
   my $vmxFile;
   my ($ret,$data);
   my ($mac, $networkName, $file);

   my $self = shift;
   $host = shift;
   $vmxFile = shift;
   $mac = shift;

   if ( (not defined $self->{stafHelper}) ||
        (not defined $host) ||
        (not defined $vmxFile) ||
        (not defined $mac) ) {
      VDSetLastError("EINVALID");
      $vdLogger->Error("$host, $vmxFile, $mac, $self->{stafHelper}");
      return FAILURE;
   }
   $file = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile),
   # it assume the host is ESX
   # TODO: Add validation of the host
   my $eth = VDNetLib::Common::Utilities::GetEthUnitNum($host, $file, $mac);
   if ( $eth eq FAILURE ) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $pattern = $eth."\.networkName";
   $vdLogger->Debug("GetPortGroupName: pattern $pattern");
   my $wd = STAF::WrapData($file);

   $service = "process";

   $command = "start shell command egrep \'$pattern\' $wd wait returnstdout";
   ($ret, $data) = $self->{stafHelper}->runStafCmd($host, 'process', $command);
   $vdLogger->Debug("GetPortGroupName: $ret, $data");
   if ( $ret ne SUCCESS ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( $data  =~ /.*\s*=\s*(.*)/ ) {
      $networkName = $1;
      $networkName =~ s/\"//g;
      return $networkName;
   } else {
      $vdLogger->Error("Unable to get portgroup name: $data");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
# GetVswitchName --
#       Return the vSwitch name corresponding to the given port group
#	This is applicable only to ESX
#	Run esxcfg-vswitch command on the host and grep for portgroup
#
# Input:
#       HOST, portgroupname
#
# Results:
#       vSwitch name, if found else undef
#
# Side effects:
#       none
#
########################################################################

sub GetVswitchName
{
   my $command;
   my $result;
   my $host;
   my $service;
   my $vmxFile;
   my ($ret,$data);
   my $portGroupName;

   my $self = shift;
   $host = shift;
   $portGroupName = shift;

   if ( (not defined $self->{stafHelper}) &&
        (not defined $host) ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # it assume the host is ESX
   # TODO: Add validation of the host

   $service = "process";

   $command = "start shell command esxcfg-vswitch -l wait returnstdout";
   ($ret, $data) = $self->{stafHelper}->runStafCmd($host, 'process', $command);
   $vdLogger->Debug("GetVswitchName: $ret, $data ");
   return undef if ( $ret ne SUCCESS );

   my @list = split(/\n/,$data);
   my $vSwitch;
   my $pgFlag = 0;

   foreach my $l (@list) {
      if ( $l =~ /(^vSwitch\d+)/ ) {
         $vSwitch = $1;
         $pgFlag = 0;
         next;
      }
      if ( $l =~ /PortGroup Name/ ) {
         $pgFlag = 1;
         next;
      }
       if ( $pgFlag && $l =~ /^\s*(.*?)\s+\d* (.*?)\s+\d* (.*?)\s+\d*/) {
         my $p = $1;
         $p =~ s/^\s*//;
         $p =~ s/\s*$//;
         chomp($p);
         return  $vSwitch if ( ${p} eq ${portGroupName} );
      }
   }

   return undef;
}


#########################################################################
#
#  GetBuildInformation --
#      Gets Build Information
#
# Input:
#      Host Name or IP and Machine (SUT or HelperX)
#
# Results:
#      Returns "SUCCESS" and store "buildID, ESX Branch and buildType"
#      in testbed hash
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBuildInformation
{
   my $self = shift;
   my $host = shift;     # Host Name or IP
   my $hostInfo = shift;
   my ($cmd, $result);

   $cmd = "vmware -v";
   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $cmd failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stdout}){
      my ($test, $build) = split(/-/,$result->{stdout});
      chomp($build);
      $hostInfo->{build} = $build;

      # only first two digits of the version number is used, for example
      # for MN, it will be ESX50
      $hostInfo->{branch} = ($result->{stdout} =~ /.*(\d\.\d)\..*/) ? $1 : undef;
      if (defined $hostInfo->{branch}) {
         $hostInfo->{branch} =~ s/\.//g;
         $hostInfo->{branch} = 'ESX'. "$hostInfo->{branch}";
      }
   } else {
      $vdLogger->Error("Unable to get ESX branch information");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Debug("ESX Branch = $hostInfo->{branch}
                     Build = $hostInfo->{build}");
   $cmd = "vsish -e get /system/version";
   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $cmd);
   # Process the result
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*buildType\:(.*)\n.*/){
      my $buildType = $1;
      if ($buildType !~ /beta|obj|release/i) {
         $vdLogger->Warn("Unknown build Type $buildType");
      }
      $vdLogger->Debug("BuildType = $buildType");
      $hostInfo->{buildType} = $buildType;
   } else {
      $vdLogger->Debug("Can't find buildType");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
# GetTestbed --
#       Returns the testbed hash
#	return $self->{testbed} hash reference
#
# Input:
#       none
#
# Results:
#       reference to testbed hash
#
# Side effects:
#       none
#
########################################################################

sub GetTestbed
{
  my $self = shift;
  return \%{$self->{testbed}};
}

########################################################################
# GetNoOfMachines --
#       Returns the testbed hash
#	return $self->{noOfMachines} hash reference
#
# Input:
#       none
#
# Results:
#       reference to testbed hash
#
# Side effects:
#       none
#
########################################################################

sub GetNoOfMachines
{
  my $self = shift;
  return $self->{noOfMachines};
}


########################################################################
# GetOS --
#       Returns OS
#
# Algorithm:
#	return $self->{testbed}{$machine}{os} hash reference
#
# Input:
#      Machine (SUT or HelperX)
#
# Results:
#       returns testbed{$machine}{os)
#
# Side effects:
#       none
#
########################################################################

sub GetOS
{
   my $self = shift;
   my $machine =shift;    # machine SUT or HelperX
   my $os;
   $os = $self->{"testbed"}{$machine}{os};
   if ( $self->{"testbed"}{$machine}{os} =~ /win/i ) {
      $os = lc($os);
      $os =~ s/win/windows/;
   }
   return $os;
}


########################################################################
# GetHelper1OS --
#       Returns OS of helper1
#	return $self->{testbed}{helper1}{os} hash reference
#
# Input:
#       none
#
# Results:
#       returns testbed{helper1}{os}
#
# Side effects:
#       none
#
########################################################################

sub GetHelper1OS
{
   my $self = shift;
   my $os;
   $os = $self->{"testbed"}{helper1}{os};
   if ( $self->{"testbed"}{helper1}{os} =~ /win/i ) {
      $os = lc($os);
      $os =~ s/win/windows/;
   }
   return $os;
}


########################################################################
# GetSUTIP --
#       Returns the testbed{SUT}{ip}
#
# Algorithm:
#	return $self->{testbed}{SUT}{ip} hash reference
#
# Input:
#       none
#
# Results:
#       returns testbed{SUT}{ip}
#
# Side effects:
#       none
#
########################################################################

sub GetSUTIP
{
   my $self = shift;

   return $self->{"testbed"}{SUT}{ip};
}

########################################################################
# GetHelperIP --
#       Returns the testbed{helper#}{ip} given the helper name
#
# Algorithm:
#	return $self->{testbed}{helper#}{ip} hash reference
#
# Input:
#       none
#
# Results:
#       reference to testbed hash
#
# Side effects:
#       none
#
########################################################################

sub GetHelperIP
{
   my $self = shift;
   my $helperName = shift;

   return $self->{"testbed"}{$helperName}{ip} if defined $helperName;
   return $self->{"testbed"}{helper1}{ip};
}

########################################################################
# GetHostType --
#       Returns the testbed{machine}{hostType} of the current testbed
#
# Algorithm:
#	return $self->{testbed}{machine}{hostType} hash reference
#
# Input:
#       none
#
# Results:
#       returns testbed{machine}{hostType}
#
# Side effects:
#       none
#
########################################################################

sub GetHostType
{
   my $self = shift;
   my $machine = shift;

   return $self->{"testbed"}{$machine}{hostType};

}


########################################################################
# GetTestbedType --
#	To find out if it is INTER or INTRA testbed
#
# Algorithm:
#       If the two VMs are on same host then return INTRA else INTER
#	return $self->{testbed}{helper#}{ip} hash reference
#
# Input:
#       none
#
# Results:
#       return either INTER or INTRA
#
# Side effects:
#       none
#
########################################################################

sub GetTestbedType
{
   my $self = shift;

   if ( not defined $self->{testbed}{helper1} ) {
      return ("INTRA");
   }
   # this method is only applicable for two machine testbeds for now
   # Because in more than two machines you might have both inter and
   # intra setup
   my $noOfHelpers = grep (m/helper/i, keys %{$self->{"testbed"}});
   my $sutHost = $self->{testbed}{SUT}{host};

   if ( $self->{'testbed'}{SUT}{host} !~
         m/$self->{testbed}{helper1}{host}/i ) {
      return ("INTER");
   } else {
      return ("INTRA");
   }

}


########################################################################
# IsSMBRunning --
#	Checks if SMB is running on local machine
#
#  Input:
#       none
#
# Results:
#       Returns SUCCESS if SMB is running else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub IsSMBRunning
{
   my $self = shift;

   my $cmdOut = `service smb status 2>&1`;

   if ($cmdOut =~ /unrecognized service/i) {
      $cmdOut = `service smbd status 2>&1`;
      if ($cmdOut =~ /unrecognized service/i) {
         $vdLogger->Error("SMB is not installed:$cmdOut");
         # this is not a failure, it is one of the valid ouput
         # and hence VDSetError is not called
         return FAILURE;
      }
   }
   if ($cmdOut =~ /smbd is stopped/i ||
        $cmdOut =~ /smbd stop/i) {
      $vdLogger->Warn("SMB not running:$cmdOut");
      # this is not a failure, it is one of the valid ouput
      # and hence VDSetError is not called
      return FAILURE;
   }

   return SUCCESS
}

########################################################################
# StartSMB --
#	Start SMB on local machine, this is required when you reboot the
#	master controller machine and not configured to start smb as
#	part of your startup scripts.
#
#	NOTE:  This method will not install SAMBA on local machine.
#
# Input:
#       none
#
# Results:
#       Returns SUCCESS if SMB is running else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub StartSMB
{
   my $self = shift;

   my $serviceName = "smb";
   my $cmdOut = `service $serviceName status 2>&1`;

   if ($cmdOut =~ /unrecognized service/i) {
      $serviceName = "smbd";
      $cmdOut = `service $serviceName status 2>&1`;
      if ($cmdOut =~ /unrecognized service/i) {
         $vdLogger->Error("SMB is not installed on this machine $cmdOut");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   if ($cmdOut =~ /$serviceName is stopped/i ||
        $cmdOut =~ /$serviceName stop/i) {
      $cmdOut = `service $serviceName start`;
      sleep(30); # wait for 30 secs before checking the status
      $cmdOut = `service $serviceName status`;
      if ( $cmdOut !~ /.*$serviceName.*running.*/i ) {
         $vdLogger->Error("Starting $serviceName failed on local machine $cmdOut");
         return FAILURE;
      }
      # add passwd for the user root
      my $cmd = '/usr/bin/smbpasswd';
      $cmdOut = `(echo "ca\$hc0w"; echo "ca\$hc0w" ) | $cmd -s -a root`;
      if ( $cmdOut =~ /failed/i ) {
         $vdLogger->Error("smbpasswd -s -a root failed $cmdOut");
         VDSetLastError("ECMD");
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# DeleteMountPoint --
#	Deletes given mount point on the remote machine
#
# Input:
#       remote machines IP address
#       remote machine's OS type
#       folder that needs to be deleted
#
# Results:
#       Returns SUCCESS if SMB share /automation is mounted on the
#       given IP address else FAILURE
#
# Side effects:
#       For windows, if the M: driver is in not OK state then it will
#       delete the M:.  Similarly, for linux, it any thing else is
#       mounted on the /automatin directory, it will unmount it.
#
########################################################################

sub DeleteMountPoint
{
   my $self = shift;
   my $ip = shift; # where you want to mount
   my $os = shift; # os type of the remote machine
   my $folder = shift; # mount point name on the remote machine
   my ($command, $result, $data);
   my $me = ( caller(0) )[3];

   if ((not defined $ip) || (not defined $os) || (not defined $folder)) {
      $vdLogger->Error("DeleteMountPoint: One or more parms passed are undefined");
      VDSetLastError("ENINVALID");
      return FAILURE;
   }

   if ($os =~ /win/i) {
         $command = "start shell command net use /delete /y $folder wait " .
                    "returnstdout stderrtostdout";
   } elsif (($os =~ /linux|freebsd/i) || ($os =~ /esx/i)) {
         $command = "start shell command umount -lf $folder wait " .
                    "returnstdout stderrtostdout";
   } elsif ($os =~ /vmkernel|esxi/i) {
         # esxi doesn't take absolute path name of the folder where
         # it is mounted and hence remove the '/' again this works
         # only if the folder is at root level
         my $fol = $folder;
         $fol =~ s/\///;
         $command = "start shell command esxcfg-nas -d " .
                    "$fol wait returnstdout stderrtostdout";
   }

   $vdLogger->Debug("Deleting mount point $folder on $ip");
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "process",
                                                      $command);
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("Deleting mount point $folder failed: $data");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("$me: command $command\ndata $data");
   return SUCCESS;
}


########################################################################
#
# IsSMBMounted --
#	Checks if a given share on given server is mounted on the
#	remote machine
#
# Input:
#       Remote machine's IP address
#       Remote machine's OS type
#       Server IP address
#       Mount/Share name on server
#       folder name on remote machine where it has to be mounted
#
# Results:
#       Returns TRUE if share is mounted on a given folder on
#       remote machine else FALSE.  FAILURE for any other errors
#
# Side effects:
#       none
#
########################################################################

sub IsSMBMounted
{
   my $self = shift;
   my $ip = shift; # where you want to mount
   my $os = shift; # os type of the remote machine
   my $serverIP = shift; # mount server IP address
   # folder name on remote machine where it has to be mounted
   my $share = shift;
   my $folder = shift;

   my ($command, $result, $data);

   if (($os =~ /lin/i) ||($os =~ /esx/i) || ($os =~ /FreeBSD/i)) {
      # this should take care of both nfs and cifs mount
      $command = "mount | grep \"$serverIP:$share on $folder \"";
   } elsif ($os =~ /win/i) {
      $command = "net use $folder";
   } elsif ($os =~ /vmkernel|esxi/i) {
      $folder =~ s/^\///;
      $command = "esxcfg-nas -l | grep \"$folder is $share from\"";
   }

   $command = "START SHELL COMMAND " . STAF::WrapData($command) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip, "process", $command);
   $vdLogger->Debug("IsSMBMounted data: $data");
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("$command failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($os =~ /win/i) {
      # remove / in case if full path of the share is given
      $share =~ s/^\///;
      $share =~ s/\//\\/g;
      $share = quotemeta($share);
      if ((defined $data) &&
          ($data =~ /$serverIP\\$share/) &&
          ($data =~ /Status\s+OK/i) ) {
         $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
         return VDNetLib::Common::GlobalConfig::TRUE;
      } else {
         $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
         return VDNetLib::Common::GlobalConfig::FALSE;
      }
   }

   if ((defined $data) && ($data =~ /$serverIP/i)) {
      $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
#
# LinVDNetSetup --
#       Linux based VDNet Setup.
#       1) Stops iptables and ip6tables services if they are running.
#
# Input:
#       Remote machine's IP address
#       Remote machine's OS type
#
# Results:
#       SUCCESS - in case services are stopped.
#       FAILURE - in case of error.
#
# Side effects:
#       none
#
########################################################################

sub LinVDNetSetup
{
   my $self = shift;
   my $ip = shift; # machine on which firewall should be disabled.
   my $os = shift;
   my $service;
   my $action = "stop";
   my $result;

   # This method is only applicable on linux
   if ($os !~ /lin/i){
      VDSetLastError("EINVALID");
      $vdLogger->Error("This method is only applicable on Linux");
      return FAILURE;
   }
   # Stop the iptables service
   $service = "iptables";
   $result = VDNetLib::Common::Utilities::ConfigureLinuxService($ip,
                           $os, $service, $action, $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not disable iptables service on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Stop the ip6tables service
   $service = "ip6tables";
   $result = VDNetLib::Common::Utilities::ConfigureLinuxService($ip,
                           $os, $service, $action, $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not disable ip6tables service on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# MountVDAuto --
#	Mounts automation SMB share on SMBIP on the given IP address
#
# Input:
#       none
#
# Results:
#       Returns SUCCESS if SMB share is mounted successfully else
#       FAILURE
#
# Side effects:
#       none
#
########################################################################

sub MountVDAuto
{
   my $self = shift;
   my $machine = shift;
   my $ip = shift;
   my $os = shift;
   my $SMBIP = shift; # master controller IP address
   my $share = shift;
   my $folder = shift;
   my $me = ( caller(0) )[3];

   my $folderName = $share;

   my ($command, $result, $data);

   if (($os !~ /win/i) && ($os !~ /vmkernel/i)) {
      # create automation directory if it doesn't exist using STAF
      # FS service
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip, "fs",
                                            "create directory $folder");
      if ($result eq FAILURE) {
         $vdLogger->Error("creating automation directory on $ip failed");
         $vdLogger->Error("$data") if (defined $data);
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   if (($os =~ /lin|freebsd/i) || ($os =~ /esx/i)) {
      $command = "mount $SMBIP:$share $folder";
   } elsif ($os =~ /win/i) {
      $folderName =~ s/\//\\/g;
      if ($vdNetSrcServer =~ /scm-trees/i) {
         $command = "net use $folder \\\\$SMBIP" . $folderName . " " .
                    VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_PWD .
                    " /USER:vmwarem\\" .
                    VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_USR .
                    " /persistent:yes /Y";
      } else {
         $command = "net use $folder \\\\$SMBIP" . $folderName .
                    " /persistent:yes /Y";
      }
   } else {
      goto CheckMount;
   }

   $command = "START SHELL COMMAND " . STAF::WrapData($command) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "process",
                                                      $command);
   $vdLogger->Debug("command $command");
   $vdLogger->Debug("data $data");
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("$me: Mounting SMB share failed: $command $data");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ( defined $data && (($data =~ /System error 1326 has occurred/i) ||
                         ($data =~ /error/i)) ) {
      $vdLogger->Error("run smbpasswd -a on the smb share machine: $data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
CheckMount:
   if (VDNetLib::Common::GlobalConfig::FALSE ==
         $self->IsSMBMounted($ip, $os, $SMBIP, $share, $folder)) {
      VDSetLastError("EMOUNT");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


########################################################################
# SetMount --
#	Adds a start up script in windows startup directory to mount SMB
#	share from master controller
#
# Input:
#       none
#
# Results:
#       Returns SUCCESS if the mount.bat script is placed successfully
#       else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub SetMount
{
   my $self = shift;
   my $machine = shift;
   my ($host, $vmx, $command, $cmdOut, $ip);
   my ($result, $data);

   if ( $self->{testbed}{$machine}{os} =~ /lin/i ) {
      my $mountEntry = "$vdNetSrcServer\:$vdNetSrcDir /automation nfs ro ";
      # check if /etc/fstab has entry else add to it
      $command = "start shell command cat /etc/fstab wait " .
                 "returnstdout stderrtostdout";
      ($result, $data) = $self->{stafHelper}->runStafCmd(
                                             $self->{testbed}{$machine}{ip},
                                             "process", $command);
      if ($result eq FAILURE) {
         $vdLogger->Error("Couldn't get the /etc/fstab contents on ".
               "$self->{testbed}{$machine}{ip}");
         return FAILURE;
      }

      if (defined $data) {
         # check if vdNetSrcServer and automation is mounted on automation
         if ($data =~ /$vdNetSrcServer:$vdNetSrcDir \/automation/i ) {
            $vdLogger->Debug("/etc/fstab has entry: $data");
            return SUCCESS;
         } elsif ($data =~ /\s\/automation\s/) {
            $vdLogger->Debug("Editing /etc/fstab with $mountEntry");
            $mountEntry =~ s/\//\\\//g; # escape all slashes "/"
            $command = "perl -p -i -e " .
                       "\"s/.*\\\/automation.*/$mountEntry/g\" /etc/fstab";
         } else {
         # add an entry to /etc/fstab
         #
         $vdLogger->Debug("Adding $mountEntry in /etc/fstab");
         $command = "echo $mountEntry >> /etc/fstab";
         }
      }
      $command = "START SHELL COMMAND " . STAF::WrapData($command) .
                 " WAIT RETURNSTDOUT STDERRTOSTDOUT";

      $vdLogger->Debug("SetMount Command:$command");
      ($result, $data) = $self->{stafHelper}->runStafCmd(
                                             $self->{testbed}{$machine}{ip},
                                             "process", $command);

      $vdLogger->Debug("SetMount:$data");
      if ($result eq FAILURE || $data ne "") {
         $vdLogger->Error("Couldn't get the /etc/fstab contents on ".
               "$self->{testbed}{$machine}{ip}");
         return FAILURE;
      }
      return SUCCESS;
   }

   if ( $self->{testbed}{$machine}{os} !~ /win/i ) {
      # it is a noop for OSes other than windows after this point
      return SUCCESS;
   }

   $host = $self->{testbed}{$machine}{host};
   $vmx = $self->{testbed}{$machine}{vmx};
   $ip =  $self->{testbed}{$machine}{ip};

   # It is assumed the OS is windows at this point

   # modern windows has the following as startup directory
   my $startupDir = "C:\\ProgramData\\Microsoft\\Windows\\" .
                    "Start Menu\\Programs\\Startup\\";

   #
   # If the given startupDir does not exists on the given machine, then use
   # the alternate startupDir.
   #
   $command = "GET ENTRY $startupDir TYPE";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "FS",
                                                      $command);
   if ($result eq "FAILURE") {
      # pre-vista windows has the following as startup directory
      $startupDir = "C:\\Documents and Settings\\Administrator\\" .
                    "Start Menu\\Programs\\Startup\\";
      #
      # If the given startupDir does not exists on the given machine, then use
      # the alternate startupDir.
      #
      $command = "GET ENTRY $startupDir TYPE";
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                         "FS",
                                                         $command);
      if ($result eq "FAILURE") {
         # windows8 has the following as startup directory
         $startupDir = "C:\\Users\\Administrator\\AppData\\Roaming\\Microsoft\\Windows\\" .
                       "Start Menu\\Programs\\Startup\\";
       }
   }


   # I have no clue why it takes this may escape sequences but I figured
   # it hard way.
   my $tempDir = $vdNetSrcDir;
   $tempDir =~ s/\//\\/g; # convert / to \ for windows
   my $mntCmd;
   if ($vdNetSrcServer =~ /scm-trees/i) {
      $mntCmd = 'net use M: \\\\' . $vdNetSrcServer . $tempDir  . ' ' .
                VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_PWD .
                ' /USER:vmwarem\\vdtest /persistent:yes /Y';
   } else {
      $mntCmd = 'net use M: \\\\' . $vdNetSrcServer . $tempDir .
                ' /persistent:yes /Y';
   }
   my $srcFile = "/tmp/mount.bat";
   if(!open(MYFILE, ">$srcFile")) {
      $vdLogger->Error("Opening file $srcFile failed: $!");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   print MYFILE "$mntCmd\n";
   $vdLogger->Debug("Wrote ". $srcFile. " with command: $mntCmd on windows");
   close(MYFILE);
   $command = "COPY FILE $srcFile TODIRECTORY $startupDir TOMACHINE $ip\@$STAF_DEFAULT_PORT";
   ($result, $data) = $self->{stafHelper}->runStafCmd('local',
                                                      "FS",
                                                      $command);
   $vdLogger->Debug("command: $command");
   if ($result eq FAILURE) {
      $vdLogger->Error("command $command failed on $vmx, $ip");
      $vdLogger->Error("Error:$data") if (defined $data);
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
# IsToolsRunning --
#	Check if Tools are running.  This method is used when the OS
#	type of the VM is not yet discovered and assuming no STAF is
#	running at VM.
#
# Algorithm:
#       None
#
# Input:
#       host IP address
#       hostType (esx, linux or windows)
#       vmx vmx file of the VM
#
# Results:
#       Returns SUCCESS if Tools is running and update OS of the VM if
#       it is undefined in the testbed hash
#
# Side effects:
#       testbed{machine}{os} is updated with the os type
#
########################################################################

sub IsToolsRunning
{
   my $self = shift;
   my $machine = shift;

   my $host = $self->{testbed}{$machine}{host};
   my $hostType = $self->{testbed}{$machine}{hostType};
   my $vmx = $self->{testbed}{$machine}{vmx};

   my $guestUser;
   my $osCmd="";
   my ($cmdOut,$hostInfo);
   my ($ret,$command, $result, $data);

   if ( not defined $host || not defined $vmx ||
        not defined $hostType ) {
      $vdLogger->Error("Invalid parameters");
      VDSetLastError("EINVLAID");
      return FAILURE;
   }

   if ( $self->{testbed}{$machine}{hostType} !~ /esx/i ) {
      $hostInfo = "-T ws ";
   } else {
      $hostInfo = "-T esx -h https://$host/sdk" . ' -u root -p ca\\$hc0w ';
   }

   #
   # assume the OS as linux if it is not known at present
   # Following error is returned when tools not running on the VM
   # Error: The VMware Tools are not running in the virtual machine:
   # [Storage1] win2k3-r2-sp2-32/win2k3-r2-sp2-32.vmx
   #

   if (not defined $self->{testbed}{$machine}{os}) {
      $guestUser = "root";
      $self->{testbed}{$machine}{os} = "linux";
   }

   $command = "vmrun $hostInfo " .
              "-gu $guestUser -gp ca\\\$hc0w listProcessesInGuest \"$vmx\"";

   $vdLogger->Debug("command $command");

   ($ret, $cmdOut) = $self->VMRunCmdOnHostedOrESX($host, $hostInfo, $command);

   if ($ret eq FAILURE) {
      $vdLogger->Error("vmrun command listProcessesInGuest failed on $vmx " .
                       "$host");
      $vdLogger->Error("cmdOut $cmdOut");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   if ($cmdOut =~ /invalid user name/i) {
      $vdLogger->Debug("cmdOut $cmdOut");
      $guestUser = "Administrator";
      $command = "vmrun $hostInfo " .
                 "-gu $guestUser -gp ca\\\$hc0w " .
                 "listProcessesInGuest \"$vmx\"";
      ($ret, $cmdOut) = $self->VMRunCmdOnHostedOrESX($host,
                                                     $hostInfo,
                                                     $command);

      if ($ret eq FAILURE) {
         $vdLogger->Error("vmrun command listProcessesInGuest failed on " .
                          "$vmx $host");
         $vdLogger->Error("cmdOut $cmdOut ");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # we still need to discover the right OS flavor via STAF once
      # we confirm STAF is working.  Because STAF provided OS type might
      # have more information about the OS flavor like WindowsXP, 2003, etc
      $self->{testbed}{$machine}{os} = "windows";
   } elsif ($cmdOut !~ /invalid user name/i && $cmdOut =~ /error/i) {
      $vdLogger->Error("vmrun command listProcessesInGuest failed on $vmx " .
                       "$host");
      $vdLogger->Error("cmdOut $cmdOut");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ( $cmdOut =~ /Error: The VMware Tools are not running/ ) {
      $self->{testbed}{$machine}{os} = undef;
      $vdLogger->Error("vmrun cmd failed: $cmdOut, command: $command");
      return VDNetLib::Common::GlobalConfig::FALSE;
   } else {
      return VDNetLib::Common::GlobalConfig::TRUE;
   }

}


########################################################################
# DisableFirewall --
#       When the firewall is turned off on windows, it is not possible
#       to determine if STAF and Perl are installed.  A bat/sh script
#       is copied to guest and used the same to turn off the firewall.
#       Please note that this method require tools running on windows
#       VM.
#       This method has to be called after calling
#       CopySetupFilesToWinGuest to ensure install_vet_winguest.bat is
#       available on remote machine.
#
# Input:
#       machine entry in the testbed like sut or helper#
#
# Results:
#       Using C:\vmqa\install_vet_winguest.bat, turns off the firewall.
#
# Side effects:
#       none
#
########################################################################

sub DisableFirewall
{
   my $self = shift;
   my $machine = shift;
   my ($cmdOut, $command, $ret);
   my ($hostInfo, $guestUser);

   my $gc = new VDNetLib::Common::GlobalConfig;
   my $host = $self->{testbed}{$machine}{host};
   my $vmx = $self->{testbed}{$machine}{vmx};

   if ( $self->{testbed}{$machine}{os} !~ /win/i ) {
      $vdLogger->Debug("OS is $self->{testbed}{$machine}{os} - DisableFirewall is " .
            "only applicable for windows currently");
      return SUCCESS; # no need to do anything for linux.
   } else {
      $guestUser = "Administrator";
   }

   my $setupDir = $gc->GetSetupDir($self->{testbed}{$machine}{os});
   my $file = $setupDir . 'install_vet_winguest.bat';

   if ( $self->{testbed}{$machine}{hostType} !~ /esx/i ) {
      $hostInfo = "-T ws ";
   } else {
      $hostInfo = "-T esx -h https://$host/sdk" . ' -u root -p ca\\$hc0w ';
   }

   #
   # At this point, required file is copied to guest
   # For runProgramInGuest, you need to provide the output file, so
   # dummy file is always provided
   #
   $command = "vmrun $hostInfo " .
              "-gu $guestUser -gp ca\\\$hc0w runProgramInGuest \"$vmx\" " .
              "-activewindow cmd.exe \"/c $file foff " .
              "> $setupDir\\\\install.log\"";
   $vdLogger->Debug("command: $command");
   ($ret, $cmdOut) = $self->VMRunCmdOnHostedOrESX($host, $hostInfo, $command);

   if ($ret eq FAILURE) {
      $vdLogger->Error("vmrun command runProgramInGuest failed on\n\t$vmx " .
                        "$host");
      $vdLogger->Error("cmdOut $cmdOut ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($cmdOut =~ /Error:/i) {
      $vdLogger->Error("runProgramInGuest failed - unable to turn off firewall");
      $vdLogger->Error("command: $command\n\tcommand output: $cmdOut");
      VDSetLastError("ECMD");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# CopySetupFilesToWinGuest --
#       Copy files required to perform setup automation to C:\vmqa
#       directory on windows.
#
# Input:
#       machine entry in the testbed like SUT or helper#
#
# Results:
#       copies files to the guest - only supported for windows VM on
#       esx/hosted
#
# Side effects:
#       none
#
########################################################################

sub CopySetupFilesToWinGuest
{
   my $self = shift;
   my $machine = shift;

   my $host = $self->{testbed}{$machine}{host};
   my $vmx = $self->{testbed}{$machine}{vmx};
   my $hostType = $self->{testbed}{$machine}{hostType};
   my $os = $self->{testbed}{$machine}{os};
   my $ip = $self->{testbed}{$machine}{ip};

   my $gc = new VDNetLib::Common::GlobalConfig;

   my ($cmdOut, $command, $ret);
   my ($hostInfo, $guestUser);

   if ( $os !~ /win/i ) {
      $vdLogger->Debug("OS is $os - CopySetupFileToWinGuest is only applicable for" .
                      "windows VM");
      return SUCCESS; # no need to do anything for linux.
   }

   my $setupDir = $gc->GetSetupDir($os);
   $command = "create directory $setupDir";
   # Using FS service create C:\vmqa directory on windows VM
   # FS service returns success if the given directory already exists
   my ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                         "fs",
                                                         $command);
   if ($result ne SUCCESS) {
      $vdLogger->Error("Unable to create $setupDir on $ip");
      $vdLogger->Error("cmdOut $cmdOut ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $file (@{VDNetLib::Common::GlobalConfig::winSetupFiles}) {
      # This assumes all the files are in test code path
      # If that assumption changes then this for loop has to
      # be changed.
      my $srcDir = $gc->TestCasePath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      my $srcFile = $srcDir . "$file";
      my $dstFile = $setupDir . $file;

      $vdLogger->Info("Copying $srcFile to $dstFile");
      $command = "COPY FILE $srcFile TOFILE $dstFile TOMACHINE $ip\@$STAF_DEFAULT_PORT";

      ($result, $data) = $self->{stafHelper}->runStafCmd('local',
                                                         "fs",
                                                         $command);
      $vdLogger->Debug("command: $command");

      if ($result eq FAILURE) {
         $vdLogger->Error("command $command failed on\n\t$vmx, $ip");
         $vdLogger->Error("cmd output $data ");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } # end of the for loop to copy all setup files
   return SUCCESS;

}


########################################################################
# VMRunCmdOnHostedOrESX --
#       For VMs running on ESX, vmrun command can be executed from the
#       remote machine besides running from ESX host because of hostd
#       running on the ESX.  However, for VMs running in hosted
#       environment, the vmrun command has to be executed from host
#       machine.  So depending upon the host either we run vmrun from
#       the master controller if host is ESX or run it on the host
#       machine using STAF from the master controller.
#       The other way of solving this problem could be always use STAF
#       and run the vmrun command on the host.  However this require
#       installing vix on esxi/esx because unlike hosted vix is not
#       installed by default.
#       TODO: Gagan agreed to write a wrapper for vmrun command and put
#       it in VMOperations module, when that happens, we can deprecate
#       this method.
#
# Input:
#       hostInfo - string that has information on how to provide the
#                  host information to vmrun command
#       host     - host IP address
#       command  - vmrun command that needs to executed on the remote
#                  VM along with the vmx file.
#
# Results:
#       Returns FAILURE and empty string as output if the host type
#       is neither ESX nor windows or linux
#       Returns SUCCESS and vmrun commands ouptut it the command is
#       is executed successfully
#
# Side effects:
#       none
#
########################################################################

sub VMRunCmdOnHostedOrESX
{
   my $self = shift;
   my $host = shift;
   my $hostInfo = shift;
   my $command = shift;
   my ($result, $data);

   # for hosted product, we cannot run vmrun command from master controller
   # as there is no hostd running on hosted.  Therefore weneed to use STAF
   # to run the vmrun command on the machine.
   if ($hostInfo =~ /ws/i) {
      $command = "start shell command " . $command .
                 " wait returnstdout stderrtostdout";
      ($result, $data) = $self->{stafHelper}->runStafCmd($host,
                                                            "process",
                                                            $command);
      if ($result ne SUCCESS) {
         VDSetLastError(VDGetLastError());
         return (FAILURE, $data);
      }
      return ($result,$data);
   } elsif ($hostInfo =~ /esx/i) {
      $data = `$command`;
      return (SUCCESS, $data);
   } else {
      $vdLogger->Error("Unknown hosttype");
      VDSetLastError("EINVALID");
      return (FAILURE,"");
   }
}


########################################################################
# GetIPFromVMX --
#       To find the control IP of the VM corresponding to vmx without
#       using STAF.  It used VMRUN command
#
#       Run ipconfig/ifconfig using vmrun command on the given vmx using
#       runProgramInGuest and copy the output back to host.  Parse the
#       output and get the control IP address
#
# Input:
#       machine entry in testbed, like sut or helper#
#
# Results:
#       Returns IP address if found else FAILURE
#
# Side effects:
#       none
#       NOTE: not tested yet
#
########################################################################

sub GetIPFromVMX
{
   my $self = shift;
   my $machine = shift;

   my $host = $self->{testbed}{$machine}{host};
   my $vmx = $self->{testbed}{$machine}{vmx};

   my ($command, $cmdOut);

   my $outFile = "C:\\\\ipconfigout";
   my $user = "Administrator";

   $command = "vmrun -T esx -h https://$host/sdk -u root -p ca\\\$hc0w " .
              "-gu $user -gp ca\\\$hc0w runProgramInGuest \"$vmx\" " .
              "-activeWindow cmd.exe " .
              "\"/c c:\\\\windows\\\\system32\\\\ipconfig.exe /all " .
              "> c:\\\\$outFile\"";

   $vdLogger->Info("command: $command");
   $cmdOut = `$command`;
   $command = "vmrun -T esx -h https://$host/sdk -u root -p ca\\\$hc0w " .
                "-gu $user -gp ca\\\$hc0w CopyFileFromHGuestToHost\"$vmx\" " .
                "\"$outFile\" \"/tmp/$outFile\"";
   $vdLogger->Info("command: $command");
   $cmdOut = `$command`;
   if ( $cmdOut =~ /Error:/i ) {
      $vdLogger->Error("vmrun command failed: $cmdOut");
      return FAILURE;
   }
   my $ipout = `cat /tmp/$outFile`;
   my @cmdout = split("\n",$cmdOut);

   my $start = 0;
   my ($ipaddr, $phyaddr);
   my @tmparr;

   foreach my $line (@cmdout) {
      if ( $line =~ /\s*\t*Physical Address*/ ) {
         @tmparr = split(/:/,$line);
         $phyaddr = $tmparr[1];
         $phyaddr =~ s/^\s*//;
      } elsif ( $line =~ /^eth/ ) {
         $line =~ s/\s+/ /g;
         @tmparr = split(/ /,$line);
         $phyaddr = $tmparr[4];
         $phyaddr =~ s/^\s*//;
      }

      if ( $line =~ /.*inet addr\:(.*?) .*/ ) {
         $ipaddr = $1;
         $ipaddr =~ s/^\s*//;
         # we do not have to check for isValidIP here because the IP
         # that we are looking at is part of ipconfig/ifconfig output
         if ( $ipaddr =~ /^10\.\d+\.\d+\.\d+/ ) {
            $vdLogger->Info("ipaddress is $ipaddr");
            return $ipaddr;
         }
      }

      if ( $line =~ /\s*\t*IP|IPv4 Address*/ ) {
         @tmparr = split(/:/,$line);
         $ipaddr = $tmparr[1];
         next if not defined $ipaddr;
         $ipaddr =~ s/^\s+//;
         $ipaddr =~ s/\s+$//;
         if ( $ipaddr =~ /^10\.\d+\.\d+\.\d+/ ) {
            $vdLogger->Info("ipaddress is $ipaddr");
            return $ipaddr;
         }
      }
   }
   $vdLogger->Error("\nCouldn't find control IP for machine entry $machine in the " .
         "testbed hash");
   return FAILURE;
}

########################################################################
# RestartVM --
#	Restarts wndows VM using shutdown /r command
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       VM will be rebooted
#
########################################################################

sub RestartVM
{
   my $self = shift;
   my $machine = shift;

   my $cmd;
   if ($self->{testbed}{$machine}{os} =~ /win/i) {
      $cmd = 'shutdown /f /r /t 0';
   } elsif ($self->{testbed}{$machine}{os} =~ /linux/i) {
      $cmd = 'shutdown -r -y 0';
   }

   my $host = $self->{testbed}{$machine}{ip};
   my $command = "start shell command $cmd async";

   my ($ret, $data) = $self->{stafHelper}->runStafCmd($host,
                                                      'PROCESS',
                                                      $command);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Staf error executing shutdown command on $host\n$command $data");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # make sure the systems shutsdown
   sleep(VDNetLib::Common::GlobalConfig::TRANSIENT_TIME);
   # now wait for the STAF to come up
   $vdLogger->Info("Waiting for the the STAF to come up on $host");

   if ($self->{stafHelper}->WaitForSTAF($host) eq FAILURE) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# ResetVM --
#	Resets VM via VM run command and waits for STAF to come up
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       VM will be rebooted
#
########################################################################

sub ResetVM
{
   my $self = shift;
   my $machine = shift;
   my ($host, $vmx, $command, $cmdOut);
   my $guUser;

   if ( not defined $self->{testbed}{$machine}{vmx} ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $host = $self->{testbed}{$machine}{host};
   $vmx = $self->{testbed}{$machine}{vmx};

   if ( $self->{testbed}{$machine}{os} =~ /win/i ) {
      $guUser = "Administrator";
   } elsif ( $self->{testbed}{$machine}{os} =~ /lin/i ) {
      $guUser = "root";
      # for now, return SUCCESS here
      return SUCCESS;
   } else {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = "vmrun -T esx -h https://$host/sdk -u root -p ca\\\$hc0w " .
                "-gu $guUser -gp ca\\\$hc0w reset \"$vmx\" hard";
   $vdLogger->Debug("command: $command");
   $vdLogger->Info("Resetting VM for registry keys modifications to take effect");
   $cmdOut = `$command`;
   if ( (defined $cmdOut) && ($cmdOut =~ /Error:/i) ) {
      $vdLogger->Error("vmrun command failed: $cmdOut");
      VDSetLastError("ECMD");
      return FAILURE;
   }
   # make sure the systems shutsdown
   sleep(45);
   # now wait for the STAF to come up
   $vdLogger->Info("Waiting for the the STAF to come up on " .
         "$self->{testbed}{$machine}{ip}");
   if ( $self->{stafHelper}->WaitForSTAF($self->{testbed}{$machine}{ip})
              eq FAILURE ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS
}


########################################################################
# PrintTestbed --
#	Print the testbed hash
#
# Input:
#       none
#
# Results:
#       Prints testbed hash on to stdout using Dumper
#
# Side effects:
#       none
#
########################################################################

sub PrintTestbed
{
  my $self = shift;
  $vdLogger->Info(Dumper($self->{"testbed"}));
}


########################################################################
#
# CreateVMInstance --
#       Method to create a linked clone of a VM if the vmx provided is
#       not an absolute path.
#
# Input:
#       A valid testbed object;
#       useVIX: 0/1 to indicate delta disks should be created using VIX
#               APIs or not
#
# Results:
#       "SUCCESS" (Given testbed hash will have the vmx path
#       updated for both system under test and helper VMs);
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CreateVMInstance
{
   my $self = shift;
   my $machine = shift;
   my $useVIX  = shift || 0;
   my $useVC   = shift;
   my $defaultDir = "vdtest-$$"; # create a directory name with process id
   my $lockFileName;
   my $count = 0;
   my $result;
   my ($ret,$command, $data);

   if (not defined $machine) {
      $vdLogger->Error("Specify valid machine type:_sut or helper(x)");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # If the VMX given is not absolute path (for SUT and helper VMs), then the
   # following operations are performed specific to each option
   # 1. --CACHE:
   #        create linked clone VM within the runtime directory created,
   #        with the source VM as specified in CACHE option
   # 2. --CACHE and --SYNC:
   #        create a copy of VM within the runtime directory created and the
   #        source VM as specified in CACHE option
   # 3. --CACHE is NULL or undef:
   #        mount $VDNET_VM_SERVER, locate the vmx specified,
   #        create linked clone VM within the runtime directory created
   #

   #
   # Perform the operations mentioned above specific to commandline options
   # provided for the given VM type (_sut or helper)
   #

   my $vmx = $self->{testbed}{$machine}{vmx};
   my $runtimeDir = $defaultDir;
   my $prefixDir = $self->{testbed}{$machine}{prefixDir};
   my $sync = $self->{testbed}{$machine}{sync};
   my $cache = $self->{testbed}{$machine}{cache};
   my $srcDir;

   my $endIP = $self->{testbed}{$machine}{host};
   my $uniqueID = $$ . "-" . $endIP;
   # Creating a reference to vmx in testbed object as it needs to be updated
   my $testbedVMX = \$self->{testbed}{$machine}{vmx};
   #
   # If the given vmx is an absolute path then the user clearly know which
   # VM need to be used for testing, so return "SUCCESS" immediately
   #
   if (VDNetLib::Common::Utilities::IsPath($vmx)) {
      #TODO - when integrating new STAFHelper, check if vmx file exists
      $self->{testbed}{$machine}{vmx} = $vmx;
      return SUCCESS;
   } else {
      my $tempvmx = VDNetLib::Common::Utilities::IsVMName($endIP, $vmx,
                             $self->{testbed}{$machine}{hostObj}->{stafHelper});
      if ((defined $tempvmx) && $tempvmx eq FAILURE) {
         $vdLogger->Debug("IsVMName returned error: " .
                          "This could be a VM dir name in the user " .
                          "provided directory, which has to be cloned");
         VDCleanErrorStack();
      } else {
         # TODO: Does setting startedPowerOn, powersoff, unregister during
         # cleanup if so, set it 1 else check the VM state and set it to
         # 1
         # At this point, VMOpsObj is not created and hence cannot check
         # state via VMOps, so have to write a method in Utilities.pm
         $self->{testbed}{$machine}{startedPowerOn} = 1;
         $self->{testbed}{$machine}{vmx} = $tempvmx;
         return SUCCESS;
      }
   }

   # Since linked clone is created, set the flag changeName equal to
   # TRUE
   $self->{testbed}{$machine}{changeName} = VDNetLib::Common::GlobalConfig::TRUE;

   # Currently, this method will not work on hosted environment
   if ($self->{testbed}{$machine}{hostType} !~ /esx|vmkernel/i) {
      $vdLogger->Error("CreateVMInstance() not implemented for hosted environment");
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }


   #
   # If sync option is specified, a cache directory is absolutely needed,
   # throw error if no cache directory is specified with sync option
   #
   if (($sync) &&
      (not defined $cache)) {
      $vdLogger->Error("Sync option specified but cache directory missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   } elsif ((defined $cache) &&
           (!$sync)) {
      # This is case 1 mentioned about the top of this routine

      #
      # Check if the cache directory exists, fail if does not exist
      # Update $srcDir
      #
      $ret = $self->{stafHelper}->DirExists($endIP,
                                            $cache);
      if (!$ret) {
         $vdLogger->Error("Cache directory $cache does not exist on $machine");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $srcDir = $cache; # Update the source directory
      $srcDir = "$cache/$vmx"; # Concatenate cache directory and vm name
      $vdLogger->Debug("Source directory:$srcDir");
   } else {
      # find the source VM from $VDNET_VM_SERVER
      $vdLogger->Info("Mounting " . $VDNET_VM_SERVER . ":" . $VDNET_VM_SHARE .
                      " on $endIP");
      my $esxUtil = $self->{testbed}{$machine}{hostObj}{esxutil};

      my $vdnetMountPoint = VDNET_LOCAL_MOUNTPOINT;
      $vdnetMountPoint = $esxUtil->MountDatastore($endIP,
                                                  $VDNET_VM_SERVER,
                                                  $VDNET_VM_SHARE,
                                                  $vdnetMountPoint,
                                                  1);
      if ($vdnetMountPoint eq FAILURE) {
         $vdLogger->Info("Failed to mount " . $VDNET_VM_SERVER . " on $endIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Find the VM location
      my $dsPath = VMFS_BASE_PATH . "$vdnetMountPoint";

      #
      # $vdnetMountPoint might have spaces and ( ), so escaping them with \
      #
      $dsPath =~ s/ /\\ /;
      $dsPath =~ s/\(/\\(/;
      $dsPath =~ s/\)/\\)/;

      $command = "cd $dsPath; find . -name $vmx";

      $result = $self->{stafHelper}->STAFSyncProcess($endIP, $command);
      if ($result eq "FAILURE") {
         $vdLogger->Error("Failed to find the vmx path");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      my $path = $result->{stdout};
      $path =~ s/^\.//; # remove dot only in the beginning not everywhere
      $path =~ s/\n//g;
      if ($path eq "") {
         $vdLogger->Error("No VM $vmx exists under $dsPath on $endIP");
         $vdLogger->Debug("Error:" . Dumper($result));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $src = $dsPath . $path;
      # Finding the directory $vmx under $result on $machine
      $srcDir = $self->{stafHelper}->DirExists($endIP,
                                               $src);
      if (($srcDir eq FAILURE) ||
         (!$srcDir)) {
         $vdLogger->Error("Failed to get source VM path on $machine".
                          Dumper($result));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $srcDir = $src;
      $srcDir = VDNetLib::Common::Utilities::ReadLink($src, $endIP,
                                                      $self->{stafHelper});

      if ($srcDir eq FAILURE) {
         $vdLogger->Info("Failed to find symlink of $srcDir on $endIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Source VM directory:$srcDir");
      # Block to handle Case 2 mentioned at the top of the routine
      if ((defined  $cache) &&
         ($sync)) {
         #
         # Check if the cache directory exists, create if does not exist,
         # Mount $VDNET_VM_SERVER,
         # Copy VM from $VDNET_VM_SERVER to cache directory, update $srcDir to
         # cache
         #
         $vdLogger->Info("Checking if cache dir $cache exists, creating otherwise");
         $ret = $self->{stafHelper}->DirExists($endIP,
                                              $cache);
         if (!$ret) {
            $command = "CREATE DIRECTORY $cache FULLPATH" ;
            ($ret, $data) = $self->{stafHelper}->runStafCmd($endIP,
                                                            'FS',
                                                            $command);
            if ($data ne "") { # data expected is empty in case of success
               $vdLogger->Error("Staf error while synchronizing cache directory $cache " .
                     "on $machine");
               $vdLogger->Debug("Error: " . Dumper($data));
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
         # Copy vm dir from $VDNET_VM_SERVER to cache
         $vdLogger->Info("Copying source $srcDir to cache directory $cache on " .
               "$machine");
          ($ret, $data) = $self->{stafHelper}->CopyDirectory($endIP,
                                                            $srcDir,
                                                            $cache,
                                                            "");
         if ($data eq FAILURE) {
            $vdLogger->Error("Staf error while copying directory $srcDir on $machine," .
                   "error:$data");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $srcDir = $cache . "/" . $vmx; # TODO take care of the slash based
                                        # on os type
         $vdLogger->Info("Updating source directory to $srcDir");
      }
   }
      #
      # Creating runtime directory
      #
      # Try to create a directory with default dir name "vdtest".
      # If that directory exists, then try to delete it,
      # if delete operation fails (usually because vm is still powered on
      # and being used by someother session), then create new directory
      # vdtest.0.
      # Keep trying the operation mentioned about by incrementing the count
      # until a runtime directory is created.
      #
      my $dirNameDecided = 0;

      #
      # Check if sharedStorage is defined at the command line, if yes, then use
      # the sharedstorage to deploy linked clone VMs. This is only on
      # esx5x-stable branch, on main branch, sharedstorage will used only on
      # need basis i.e when a test case explicitly has a requirement to use
      # sharedstorage under Parameters hash.
      #
      my $datastoreType = $self->{testbed}{$machine}{datastoreType};
      my ($sharedStorageServer, $sharedStorageShare);
      if (defined $datastoreType && $datastoreType =~ /shared/i) {
         my $sharedStorage = $self->{testbed}{$machine}{sharedStorage}; # updated in main
         $prefixDir = $sharedStorage;
         $vdLogger->Info("Using shared storage $sharedStorage to " .
                         "deploy VM on $endIP");
      }
      if (not defined $prefixDir) {
         #
         # If not prefix directory is specified, this block finds a vmfs
         # partition which has the largest space on the given host
         #
         $vdLogger->Debug("Prefix directory to create runtime directory not provided");
         $vdLogger->Trace("Find a vmfs datastore with largest space available");
         $prefixDir = $self->{stafHelper}->GetCommonVmfsPartition($endIP);
         if (($prefixDir eq FAILURE) ||
            (not defined $prefixDir)) {
            $vdLogger->Error("Failed to get the datastore on $machine");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         # Append the datastore name with /vmfs/volumes
         $prefixDir = VMFS_BASE_PATH . "$prefixDir";
         $self->{testbed}{$machine}{prefixDir} = $prefixDir;
      }

      $prefixDir =~ s/\/$|\\$//; # Trailing slashes in the path are removed

      #
      # Deleting old files and directory
      #
      $vdLogger->Debug("Deleting old files and directory from ESX Host");
      # Need to pass the command like this '"' . $prefixDir . '/*"
      # in quotes otherwise the shell treats it as a special character
      my $commandForDel = 'perl ' . "/automation/scripts/cleanup.pl " .
                    '"' . $prefixDir . '/vdtest*"';
      $ret = $self->{stafHelper}->STAFAsyncProcess($endIP, $commandForDel);
      if ($ret->{rc}) {
         $vdLogger->Warn("Failed to delete the directories");
      }

      # Extract absolute path from hash entry
      # Call getfilesystemType method (host,absolutepath)
      my $filesystemType =
         VDNetLib::Common::Utilities::GetFileSystemType($endIP,
                                                        $prefixDir,
                                                        $self->{stafHelper});

      if (($filesystemType eq FAILURE) || (not defined $filesystemType)) {
         $vdLogger->Error("Failed to get the file system type on ".
                          "$machine for prefix directory $prefixDir");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } else {
         #Stored inside the Testbed key and not under the session->SUT
         $self->{testbed}{$machine}{$prefixDir}{filesystemType} = $filesystemType;
      }

      if (defined $self->{testbed}{$machine}{runtimeDir}) {
         $runtimeDir = $self->{testbed}{$machine}{runtimeDir};
         $dirNameDecided = 1;
      } else {
         $runtimeDir = $prefixDir . "/" . $runtimeDir;
         $dirNameDecided = 0;
         $vdLogger->Info("Finding run-time directory to deploy $machine VM, " .
                         "might take few secs...");
      }

      while (!$dirNameDecided) {
         if ($self->{testbed}{$machine}{$prefixDir}{filesystemType} =~ /vsan/i) {
            # Write your own DirExists as staf's will not work with vsan
            # hard coding for now. Filed bug # 875234 to fix it later.
            $ret = 0;
         } else {
            $ret = $self->{stafHelper}->DirExists($endIP,
                                                  $runtimeDir);
            if ($ret eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
         if ($ret == 1) { # directory exists, so deleting it
            $vdLogger->Debug("Runtime directory $runtimeDir exists");

            #
            # Now that the runtime directory exists, it is important to do some
            # check before deleting and re-using the directory name.
            # Check if any vmx process is running that uses vmx file from
            # the runtime directory. Execute "ps -c" command and grep for
            # vmx path that include runtime directort.
            #
            # First, get the absolute vmx path.
            # Example, absolute path of
            # /vmfs/volumes/datastore1/vdtest0 is
            # /vmfs/volumes/4c609bdc-46e83530-9a8e-001e4f439d6f/vdtest0
            #
            # The reason to find this path is that ps -c output reports
            # absolute path.
            #
            my $absPath = VDNetLib::Common::Utilities::GetActualVMFSPath($endIP,
                                                                  $runtimeDir);
            if ($absPath eq FAILURE) {
               $vdLogger->Error("Failed to get absolute value of $runtimeDir");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            #
            # Executing command one the end host to find the list of process
            # running.
            #
            $command = "start shell command ps -c | grep \"'$absPath\/'\" wait " .
                       "returnstdout stderrtostdout";
            ($ret, $data) = $self->{stafHelper}->runStafCmd($endIP,
                                                            'PROCESS',
                                                            $command);

            if ($ret eq FAILURE) {
               $vdLogger->Error("Failed to execute staf command to find " .
                                "info on $endIP");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            #
            # ps -c | grep $absPath will include many details including
            # one process for grep command. So, look for only the
            # /bin/vmx process
            #
            if ($data =~ /\/bin\/vmx\S* .* $absPath/) {
               $vdLogger->Debug("Files under $runtimeDir in use");
               $dirNameDecided = 0;
            } else {
               #
               # check if this process and $endIP has access to delete the
               # $runtimeDir.
               #
               $lockFileName = $runtimeDir . "/" .
                  VDNetLib::Common::GlobalConfig::DEFAULTLOCKFILE;
               my $access = VDNetLib::Common::Utilities::GetLockAccess(
                                                        $lockFileName,
                                                        $endIP,
                                                        $uniqueID,
                                                        $self->{stafHelper});
               if ((not defined $access) ||
                  (defined $access) &&
                  ($access == VDNetLib::Common::GlobalConfig::TRUE)) {
                  #
                  # If the current process and host/endIP has access to the
                  # lockfile, then delete the existing runtime directory to
                  # reuse it.
                  #

                  #
                  # if no files is in use under the runtime directory name
                  # decided, then delete it's contents and use the same dir
                  # name as runtimedir
                  #
                #  $vdLogger->Debug("Deleting $runtimeDir");
                #  $command = "DELETE ENTRY " . $runtimeDir .
                #             " CONFIRM RECURSE";
                #  ($ret, $data) = $self->{stafHelper}->runStafCmd($endIP,
                #                                                  'FS',
                #                                                  $command);
                #  if ($ret eq FAILURE) {
                #     $vdLogger->Warn("Unable to delete directory $runtimeDir " .
                #                     "on $machine");
                #        $dirNameDecided = 0;
                #  }
                  $dirNameDecided = 1;
               } else {
                  $vdLogger->Debug("Files under $runtimeDir locked");
                  $dirNameDecided = 0;
               }
            }
            if (!$dirNameDecided) {
               $runtimeDir = $prefixDir . "/" . $defaultDir . $count;
               $vdLogger->Debug("Trying to create runtime directory with new " .
                                "directory name $runtimeDir");
               $count++;
               next;
            }
         } else {
            # Decided the directory name to create
            $dirNameDecided = 1;
         }
      }
      $lockFileName = $runtimeDir . "/" .
                        VDNetLib::Common::GlobalConfig::DEFAULTLOCKFILE;
      my $vsanDir = $runtimeDir;
      my $currentCacheSize = scalar(@{$self->{resourceCache}});
      $runtimeDir = $runtimeDir . "/" . $machine . "-" . $currentCacheSize;
      $vdLogger->Info("Creating runtime directory $runtimeDir on $machine");
      #
      # Once the proper path for the runtime directory is identified,
      # create it on the given endpoint (sut/helper)
      #
      my $filesystemtype = $self->{testbed}{$machine}{$prefixDir}{filesystemType};
      $result=VDNetLib::Common::Utilities::CreateDirectory($endIP,
                                                           $runtimeDir,
                                                           $filesystemtype);

      if ($result eq 'SUCCESS') {
         $vdLogger->Info("Created $runtimeDir on $endIP");
      }

      $self->{testbed}{$machine}{runtimeDir} = $runtimeDir;
      $self->{testbed}{$machine}{lockFileName} = $lockFileName;
      #
      # Now that the runtime directory is decided, lock it to prevent other
      # processes or host from deleting it. This is important, check PR689869
      #
      $vdLogger->Info("Creating lockfile $lockFileName on $endIP");
      $ret = VDNetLib::Common::Utilities::CreateLockFile(
                                                      $lockFileName,
                                                      $endIP,
                                                      $uniqueID,
                                                      $self->{stafHelper});

      if ($ret eq FAILURE) {
         $vdLogger->Error("Unable to create lock file under $runtimeDir ".
                          "on $endIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      #
      # Copy linked clone from cache or $VDNET_VM_SERVER to runtime directory
      # created
      #
      $ret = $self->CreateDupDirectory($machine,
                                       $srcDir,
                                       $runtimeDir,
                                       "True");
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to copy $srcDir to $runtimeDir on $machine");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      #
      # Get the absolute path to the vmx which would finally be registered
      # and used for running the workloads
      #
      $command = "ls '$runtimeDir'/*.vmx";
      $command = "START SHELL COMMAND " .
                 STAF::WrapData($command) .
                 " WAIT RETURNSTDOUT STDERRTOSTDOUT";
      ($ret, $data) = $self->{stafHelper}->runStafCmd($endIP,
                                                      'PROCESS',
                                                      $command);

      if (($ret eq FAILURE) ||
         ($data eq "") ||
         ($data =~ /No such/i)) {
         $vdLogger->Error("Staf error while retreiving vmx path on $machine, " .
                          "error:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      chomp($data);
      $$testbedVMX = $data;

      if ((not defined $$testbedVMX) ||
         ($$testbedVMX eq "")) {
         $vdLogger->Error("$machine vmx path is invalid");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      #
      # escape spaces and () with \
      #
      if ($$testbedVMX !~ /\\/) { # if already escaped, ignore
                              # TODO: take care of this for hosted (windows)
                              #
         $$testbedVMX =~ s/ /\\ /;
         $$testbedVMX =~ s/\(/\\(/;
         $$testbedVMX  =~ s/\)/\\)/;
      }

      $vdLogger->Info("Updated vmx path as $$testbedVMX for $machine");

      # Add snapshot.redoNotWithParent = TRUE for linked clone to work
      my @list = ('snapshot.redoNotWithParent = "TRUE"');

      my $newName = $$testbedVMX;
      $newName =~ s/.*\///g;
      if ($newName =~ /(.*)\.vmx/i) {
         # if the VM name is not distinguished based on datastore type, then
         # the one created on local store might have same name as the one
         # created on shared storage
         # double check before changing this format
         #

         #
         # The display format is
         # <originalDisplayName>-<machineType>-<datastoreStype>-<processID>-
         # <currentCacheSize>
         #
         my $actualName = $1;
         $actualName = substr($actualName,0,8); # get the first 8 char of
                                                # actual display name
         $newName = "$actualName-" .
                    "$machine-$self->{testbed}{$machine}{datastoreType}-" .
                    "$$-$currentCacheSize";
      }

      $vdLogger->Debug("Renaming display name of $$testbedVMX to $newName");
      push(@list, "displayName = $newName");

      $ret = VDNetLib::Common::Utilities::UpdateVMX($self->{testbed}{$machine}{host},
                                            \@list,
                                            $self->{testbed}{$machine}{vmx});
      if (($ret eq FAILURE) || (not defined $ret)) {
         $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() " .
                         "failed while update");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }


      # Create delta disks
      $vdLogger->Debug("Creating delta disks");
      $ret = $self->CreateDeltaDisks($machine, $useVIX, $useVC);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to create delta disks on $machine");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

}


########################################################################
#
# CreateDupDirectory --
#       Method to create a duplicate VM directory.
#
# Input:
#       <machine>   - host ip on which this operation needs to be
#                     executed (required)
#       <sourceDir> - source direcory which needs to be duplicated
#                     (required)
#       <destDir>   - name of the duplicate directory (required)
#       <symlink>   - "True" or "False" (required)
#
# Results:
#       "SUCCESS", if duplicate directory is created;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CreateDupDirectory
{
   my $self = shift;
   my $machine = shift;
   my $sourceDir = shift;
   my $destDir = shift;
   my $symlink = shift;

   if ((not defined $machine) ||
      (not defined $sourceDir) ||
      (not defined $destDir) ||
      (not defined $symlink)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($command, $ret, $data);
   my @sourceFile = ("*.vmx", "*.vmsn", "*.vmsd");
   #my @sourceFile = ("*.vmx");
   my $endIP = $self->{testbed}{$machine}{host};

   if ($symlink =~ /True/i) {
      #
      # If symlink option is given, then copy .vmx files and symlink the vmdk
      # files
      #
      $ret = $self->{stafHelper}->CreateSymlinks($endIP,
                                                 "$sourceDir/*.vmdk",
                                                 $destDir);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to create vmdk symlinks on $machine");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

   } else {
      push(@sourceFile,"*.vmdk");
   }
   #
   # If symlink option is given, $sourceFile would be .vmx and that alone will
   # be copied since .vmdk files are already symlinked in the previous block.
   # If symlink is false, then the entire directory is copied
   #
   foreach my $file (@sourceFile) {
      my $extension = $file;
      $extension =~ s/\*\.//;
      #
      # TODO - replace with STAFFSListDirectory() when integrating
      # new STAFHelper.pm
      #
      $command = "START SHELL COMMAND \"ls $sourceDir/$file\" " .
                 "WAIT RETURNSTDOUT STDERRTOSTDOUT";
      my ($result, $dir) = $self->{stafHelper}->runStafCmd($endIP,
                                                           'PROCESS',
                                                           $command);
      #
      # The command above returns an array which has list of specified
      # file formats, if successful. Verify that the given format matches
      # with the result. If the given file format does not exist, then skip
      # to the next file format.
      #
      if ($result eq SUCCESS) {
         if ($dir eq "" || $dir =~ /No such/i) {
            # The given file does not exist, so skip copying
            next;
         }
      } else {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      ($ret, $data) = $self->{stafHelper}->CopyDirectory($endIP,
                                                         $sourceDir,
                                                         $destDir,
                                                         $file);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Staf error while copying directory $sourceDir" .
                          "on $machine, error:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# CreateDeltaDisks --
#       Method to create delta disks (to allow writing to vmdk locally)
#
# Input:
#       <machine> - reference to a machine's hash in testbed object,
#                   '_sut' or 'helper' (Required)
#       <useVIX>  - 0/1 to indicate whether to use VIX APIs or not
#
# Results:
#       "SUCCESS", if delta disks are created for the VM sepcified at
#                  the input;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CreateDeltaDisks
{
   my $self    = shift;
   my $machine = shift;
   my $useVIX  = shift;
   my $useVC   = shift;

   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $vmxName = $self->{testbed}{$machine}{vmx};

   # Create an VMOperations object
   my $vmOpsObj = VDNetLib::VM::VMOperations->new($hostObj,
						  $vmxName,
						  undef,
						  $useVIX, $useVC);
   if ($vmOpsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VMOperations object");
      return FAILURE;
   }
   # One way to create delta disk is to take snapshot of the VM
   if ( $vmOpsObj->VMOpsTakeSnapshot("delta") eq FAILURE ) {
      $vdLogger->Error(" VMOpsTakeSnapshot failed");
      #Unregister VM in case of error.
      $vmOpsObj->VMOpsUnRegisterVM();
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ChangeHostName --
#       Method to change hostname on windows/linux.
#
# Input:
#       <hostIP>   - endpoint ip address on which this operation
#                    needs to be executed (required)
#       <hostname> - new hostname, if not specified current hostname
#                    appended with mac address will used (Optional)
#
# Results:
#       new hostname, if the hostname is changed successfully;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub ChangeHostName
{
   my $self = shift;
   my $hostIP = shift;
   my $hostname = shift;
   my $result;

   if (not defined $hostIP) {
      $vdLogger->Error("Host IP is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Get the OS type of the given host/endpoint
   my $osType = $self->{stafHelper}->GetOS($hostIP);

   my ($command, $ret, $data);
   if ($osType =~ /win/i) {
      #
      # If $hostname is not provided at the input, assign a new hostname
      # automatically. It is done by appending mac address to the existing
      # hostname.
      # This case is required when the user wants to assign a unique hostname.
      #
      if (not defined $hostname) {
         $hostname = $self->GetHostName($hostIP);
         if ($hostname eq FAILURE) {
            $vdLogger->Error("Failed to get existing hostname:$hostname");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         #
         # compname.exe uses several macros to change hostname. One such macro
         # is ?m which will get the first mac address on the given machine
         #
         $hostname = "?m-" . $hostname;
      }

     $command = "START SHELL COMMAND " . WIN32_BIN_PATH .
                "compname.exe /c $hostname WAIT RETURNSTDOUT STDERRTOSTDOUT";
      ($ret, $data) = $self->{stafHelper}->runStafCmd($hostIP,
                                                      'PROCESS',
                                                      $command);
      if (($ret eq FAILURE) ||
         ($data !~ /successfully changed/i)) {
            $vdLogger->Error("Failed to change existing hostname:$data");
            VDSetLastError("EOPFAILED");
            return FAILURE;
      }
      #
      # Get the complete hostname (in case macro are used) and use that as the
      # return value of this method.
      #
      $hostname = $self->GetHostName($hostIP);
      if ($hostname eq FAILURE) {
         $vdLogger->Error("Failed to get existing hostname:$hostname");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Restart the machine (needed in case of windows)
      $command = "START SHELL COMMAND \"shutdown.exe /f /r /t 0\"";
      ($ret, $data) = $self->{stafHelper}->runStafCmd($hostIP,
                                                      'PROCESS',
                                                      $command);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to restart the guest $hostIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      return $hostname; # return the new hostname
   } else {
      $vdLogger->Error("Not Implemented on linux/esx");
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }
}


########################################################################
#
# GetHostName --
#       Method to get the hostname/computername of the given machine.
#
# Input:
#       <hostIP>   - endpoint ip address on which this operation
#                    needs to be executed (required)
#
# Results:
#       hostname, if the operation is successful;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetHostName
{
   my $self = shift;
   my $hostIP = shift;

   if (not defined $hostIP) {
      $vdLogger->Error("Host IP not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $osType = $self->{stafHelper}->GetOS($hostIP);

   my ($command, $ret, $hostname);
   if ($osType =~ /win/i) {
      #
      # On windows, the utility compname.exe is used to get the current
      # hostname on the given machine.
      #
      $command = "START SHELL COMMAND " .
                 "M:\\features\\Networking\\common\\binaries\\x86_32\\" .
                 "windows\\compname.exe /d WAIT RETURNSTDOUT " .
                 "STDERRTOSTDOUT";
      ($ret, $hostname) = $self->{stafHelper}->runStafCmd($hostIP,
                                                          'PROCESS',
                                                          $command);
      if (($ret eq FAILURE) ||
         ($hostname eq "")) {
         $vdLogger->Error("Failed to get existing hostname:$hostname");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Remove any trailing 'carriage return' or 'new line' characters
      $hostname =~ s/\r+$|\n+$//g;
      return $hostname;
   } else {
      # TODO - implement for linux/esx
      $vdLogger->Error("Method not implemented on given os:$osType");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# UpdateEthernetVMXOptions --
#      This method adds/updates any vmx entry related to virtual
#      network adapter (that starts with ethernetX.)
#
# Input:
#      $vmOpsObj: virtual machine object
#      mac    : mac address of the virtual network adapter whose vmx
#               configuration has to be added/modified
#      list   : reference to array that contains vmx configuration.
#               (Note: the vmx configuration is without ethernetX.
#                This method will find the ethernet unit number from
#                the given mac address and vmx file stored in testbed
#                object)
#
# Results:
#      SUCCESS, if the the given vmx options are add/modified without
#               error or if they already exist;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub UpdateEthernetVMXOptions {
   my $self    = shift;
   my $vmOpsObj = shift;
   my $mac     = shift; # mac address of the adapter
   my $list    = shift; # reference to an array of vmx options
   my $stafHelper = shift;

   if ((not defined $mac) || (not defined $vmOpsObj) || (not defined $list)) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmOpsObj->{vmx});
   my $hostObj = $vmOpsObj->{hostObj};
   if ((not defined $vmxFile) || ($vmxFile eq FAILURE)) {
      $vdLogger->Error("vmxFile is not defined for $hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Substitute any hyphen in the given mac address by semi-colon because
   # mac address is vmx file uses semi-colon.
   #
   $mac =~ s/-/:/g;

   #
   # GetEthUnitNum() method in Utilities gives the ethernet unit number, for
   # example, ethernet1, ethernet2 etc., that is being used in the vmx file to
   # represent a virtual network adapter.
   #
   my $ethernetX = VDNetLib::Common::Utilities::GetEthUnitNum($hostObj->{hostIP},
                                                              $vmxFile, $mac);

   if ($ethernetX eq FAILURE) {
      $vdLogger->Error("Failed to get ethernetX of $vmOpsObj->{controlIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$ethernetX corresponds to the mac address $mac on " .
                   $vmxFile);
   my $vmxPresent;
   my $updateNeeded = 0;
   foreach my $pattern (@{$list}) {
      #
      # Prepend the ethernet unit number with the given list of vmx
      # configuration entries
      #
      $pattern = $ethernetX . "." . $pattern;
      # Split the vmx configuration into <configOption> and <value>
      my ($option, $value) = split(/=/, $pattern);
      # Check if the given vmx configuration is already present
      $vmxPresent = VDNetLib::Common::Utilities::CheckForPatternInVMX($hostObj->{hostIP},
                                                                      $vmxFile,
                                                                      $pattern);
      #
      # Removing any quotes present on both the given vmx entry and existing vmx
      # entry.
      #
      $vmxPresent =~ s/"//g;
      $value =~ s/"//g;
      if (defined $vmxPresent && $vmxPresent !~ /$value/i) {
         #
         # Call Utilities's UpdateVMX() method even if there is one
         # configuration needs to be updated in the given list.
         #
         $updateNeeded = 1;
      }
   }

   if (!$updateNeeded) {
      $vdLogger->Info("vmx entries already present, update not required");
      return SUCCESS;
   }

   # power off the VM
   $vdLogger->Info("Bringing $vmOpsObj->{controlIP} down to update vmx file");
   if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
      $vdLogger->Error( "Powering off VM failed");
      $vdLogger->Error("Dump of VM object" . Dumper($vmOpsObj));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Adding vmx entry : " . join(',', @{$list}));
   my $ret = VDNetLib::Common::Utilities::UpdateVMX($hostObj->{hostIP},
                                                    $list,
                                                    $vmxFile);
   if (($ret eq FAILURE) || (not defined $ret)) {
      $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # power on the VM
   if ($vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Error( "Powering on VM failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   my $nicsInfo = $vmOpsObj->GetAdaptersInfo();
   if ($nicsInfo eq FAILURE) {
      $vdLogger->Error("Failed to get MAC address of control " .
                       "adapter in $vmOpsObj->{vmx}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $controlMAC;
   foreach my $adapter (@$nicsInfo) {
      if ($adapter->{'portgroup'} =~ /VM Network/i) {
         $controlMAC = $adapter->{'mac address'};
      }
   }


   #
   #  After power reset, the dhcp address of control adapter could change,
   #  so using  GetGuestControlIP() method to get the control ip address.
   #
   my $newIP = VDNetLib::Common::Utilities::GetGuestControlIP($hostObj->{hostIP},
                                                              $vmOpsObj->{vmx},
                                                              $controlMAC);
   if ($newIP eq FAILURE) {
      $vdLogger->Error("Failed to get $vmOpsObj->{vmx} ip address");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ($vmOpsObj->{controlIP} ne $newIP) {
      # Update control IP address if there is any change.
      $vmOpsObj->{controlIP} = $newIP;
   }

   $vdLogger->Info("Waiting for STAF on $vmOpsObj->{controlIP} to come up");
   $ret = $stafHelper->WaitForSTAF($vmOpsObj->{controlIP});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Info("STAF is not running on $vmOpsObj->{controlIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("STAF on $vmOpsObj->{controlIP} came up");
   return SUCCESS;
}


########################################################################
#
# TestbedCleanUp --
#      This routine cleans the testbed relation operation performed for
#      running the test case(s). For example, powering off the vm and
#      unregistering if it was created using linked clone.
#
# Input:
#      Reference to testbed hash
#
# Results:
#      Depends on various cleanup operations performed. The list of
#      operations can be extended in this routine.
#      1. If the user does not provide IP address for -sut or -helper
#      command line options, then vdNet assumes that these machines
#      are not powered on at the beginning. So, this cleanup routine
#      will power off and unregister those VMs since they were powered
#      on by vdNet script.
#
# Side effects:
#      Refer to the results section above.
#
########################################################################

sub TestbedCleanUp
{
   my $self = shift;

   my $result = SUCCESS;

   $vdLogger->Info("Doing clean up using testbed information");
    foreach my $machine (@{$self->{resourceCache}}) {
       if(defined $machine->{startedPowerOn} &&
          $machine->{startedPowerOn} == 0) {
         my $vmOpsObj = $machine->{vmOpsObj};
         if (defined $vmOpsObj) {
            #
            # Making sure esx host anchor is used and not the VC anchor since
            # VC is cleaned up at this point. PR688458
            #
            my $host = $vmOpsObj->{esxHost};
            my $stafVMAnchor =
               VDNetLib::Common::Utilities::GetSTAFAnchor($vmOpsObj->{stafHelper},
                                                          $host,
                                                          "VM");

            $machine->{vmOpsObj}{stafVMAnchor} = $stafVMAnchor;

            if ($stafVMAnchor eq FAILURE) {
               $vdLogger->Error("STAF VM anchor not defined for " .
                                "$vmOpsObj->{vmx} on $host");
               VDSetLastError(VDGetLastError());
               $result = FAILURE;
            }

            $vdLogger->Debug("Using $stafVMAnchor for cleanup of " .
                             $vmOpsObj->{vmx});

            $vmOpsObj->VMOpsPowerOff();

            if ($vmOpsObj->VMOpsUnRegisterVM()eq FAILURE) {
               $vdLogger->Error("Failed to unregister VM");
               VDSetLastError(VDGetLastError());
               $result = FAILURE;
               next; # if power off or unregistering VM fails, then
                     # don't delete the VM directory PR775235
            } # end of unregister

            #
            # As a good practice, remove the locks from the runtime directory,
            # so that the directory can be used for subsequent vdNet sessions.
            #
            my $lockFileName = $machine->{lockFileName};
            my $endIP = $machine->{host};
            my $uniqueID = $$ . "-" . $endIP;
            $vdLogger->Info("Removing lock $lockFileName with id $uniqueID on $endIP");
            my $ret = VDNetLib::Common::Utilities::RemoveLockFile(
                                                                  $lockFileName,
                                                                  $endIP,
                                                                  $uniqueID,
                                                                  $self->{stafHelper});

            if ($ret eq FAILURE) {
               $vdLogger->Error("Unable to remove lock file " .
                                "$lockFileName on $endIP");
               VDSetLastError(VDGetLastError());
            }
            my $runtimeDir = $machine->{runtimeDir};

            if ((defined $runtimeDir) && ($runtimeDir =~ /(sut|helper\d+)/i)) {
               #
               #  Delete the runtime directory (this block will be entered only
               #  in case if vdnet deploy's a VM. Linked clones are placed under
               #  a datastore with sub-dir "vdnet-<processID>".
               #  For example, this code block will delete
               #  /vmfs/volumes/datastore1/vdtest-1234/
               #
               $runtimeDir =~ s/\/(sut|helper\d+)\/?$//; # remove sut or helperx
               $vdLogger->Debug("Deleting $runtimeDir on $machine->{host}");
               my $options;
               $options->{recurse} = 1;
               $options->{ignoreerrors} = 1;
               my $ignoreRC = 48; # 48 indicates directory does not exist
               my $result = $self->{stafHelper}->STAFFSDeleteFileOrDir(
                                                               $machine->{host},
                                                               $runtimeDir,
                                                               $options,
                                                               $ignoreRC,
                                                               );
               if (not defined $result) {
                  $vdLogger->Warn("Failed to remove $runtimeDir " .
                                  "on $machine->{host}");
                  $vdLogger->Debug(Dumper($result));
               }
            } # end of deleting runtimeDir

         } # end of checking vmops obj
      } # end of checking whether "startedPowerOn" defined.
   } # end of machines loop
   $vdLogger->Info("Testbed cleanup result: $result");
   return ($result eq FAILURE) ? FAILURE : SUCCESS;
}


########################################################################
#
# SessionCleanUp --
#      This method cleans anything created during the initialization
#      part of testbed (Init() method) for the given test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the testbed components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub SessionCleanUp
{
   my $self	= shift;
   my $tcresult	= shift || "PASS";
   my $session	= $self->{session};
   my $result	= SUCCESS;
   $vdLogger->Info("Doing session cleanup");
   #
   # reset the noOfMachines to 0 first.
   # The noOfMachines are set during the testbed Init
   # based on the session parameters.
   #
   # set this before doing any cleanup so even if
   # cleanup fails we have correct parameters for
   # the next test.
   #
   $self->{noOfMachines} = 0;

   #
   # remove the vds version so that new test has the default vds
   # version based upon the version of ESX/VC being run.
   #
   $session->{Parameters}{version} = undef;

   # Cleaning virtual adapters, if any, used by the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vnic"}) {
         if ($self->CleanupVirtualAdapters($machine) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup virtual adapters on " .
                             $machine);
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      }
   }

   # Cleaning virtual machines, if any, used by the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vm"}) {
         if ($self->CleanupVMs($machine) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup virtual machine on " .
                             $machine);
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      }
   }

   #clean-up for SRIOV related stuff
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"pci"}) {
         if ($self->CleanupSRIOV($machine) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup SRIOV on " . $machine);
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      }
   }

   # Cleaning vmkernel nics, if any, used by the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vmknic"}) {
         if ($self->CleanupVMKNics($machine) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup virtual switches on " .
                             $machine);
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      }
   }

   #
   # get the pnic device, if defined and set the device status to up.
   # This is just extra check to make sure that if test has failed in
   # between the device status should be up.
   #
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
         # since first pNIC is used to link to the switch(vSS/vDS).
         my $vmnicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{'1'};
         if ((defined $vmnicObj) && $vmnicObj->{status} =~ m/down/i) {
            if ($vmnicObj->SetDeviceUp() eq FAILURE) {
               $vdLogger->Error("Failed to enable the interface ".
                                "$vmnicObj->{vmnic}");
               VDSetLastError(VDGetLastError());
               $result = FAILURE;
            }
         }
         my $passthrough = $session->{"Parameters"}{$machine}{"passthrough"};
         if (defined $passthrough) {
            if ($passthrough =~ /sriov/i) {
               if (FAILURE eq $self->ConfigureSRIOV($machine, "disable")) {
                  $vdLogger->Error("Failed to disable SRIOV on $machine");
                  VDSetLastError(VDGetLastError());
                  $result = FAILURE;
               }
            } else {
               my $hostObj = $self->{testbed}{$machine}{hostObj};
               if (FAILURE eq $hostObj->DisableFPT()) {
                  $vdLogger->Error("Failed to disable FPT on $machine");
                  VDSetLastError(VDGetLastError());
                  $result = FAILURE;
               }
            }
         }
      }
   }

   # Cleaning virtual switches, if any, used by the test case
   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"switch"}) {
         if ($self->CleanupVirtualSwitches($machine) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup virtual switches on " .
                             $machine);
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      }
   }

   # clean up on the vc side vds and datacenter.
   if (defined $session->{Parameters}{vc}
       && defined $session->{Parameters}{datacenter}) {
      my $vcObj = $self->{vc}->{vcOpsObj};
      my $datacenter = $session->{Parameters}{datacenter};
      my $folder = $session->{Parameters}{folder};
      if ($vcObj->CleanupVC($datacenter,$folder) eq FAILURE) {
         $vdLogger->Error("Failed to cleanup VC ".
                          "$self->{vc}->{vcaddr}");
         VDSetLastError("EOPFAILED");
         $result = FAILURE;
      }
   }

   return $result;
}


########################################################################
#
# CleanupVirtualAdapters --
#      This method cleans virtual adapters used in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS"  - TODO
#
# Side effects:
#      None
#
########################################################################

sub CleanupVirtualAdapters
{
   my $self = shift;
   my $machine = shift;
   if (not defined $self->{testbed}{$machine}{Adapters}) {
      $vdLogger->Info("No virtual adapter initialized to clean on $machine");
      return SUCCESS;
   }
   return SUCCESS;
}


########################################################################
#
# CleanupFPT --
#      This method cleans the FPT mode
#
# Input:
#      None
#
# Results:
#      "SUCCESS" if pci device gets removed and passthrough
#                status for pnic is disabled.
#      "FAILURE" otherwise.
#
# Side effects:
#      PCI device gets removed from the vm and passthrough status
#      for pnic gets disabled.
#
########################################################################

sub CleanupFPT
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $vmnics = $self->{testbed}{$machine}{Adapters}{vmnic};
   my @nics = ();
   my $index = 0;
   my $result;

   # get the list of nics required for FPT.
   if (defined $session->{"Parameters"}{$machine}{"vmnic"}) {
      foreach my $pnic(keys%$vmnics) {
         my $nicObj = $self->{testbed}{$machine}{Adapters}{vmnic}{$pnic};
         $nics[$index] = $nicObj->{vmnic};
         $index++;
      }
   }

   # remove pci passthrough device from the vm
   $result = $vmOpsObj->VMOpsRemovePCIPassthru(\@nics);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to remove pci passthrough devices ".
                       "from the VM");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Disable FPT
   $result = $hostObj->DisableFPT();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to disable Passthrough on host ".
                       "$hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# CleanupSRIOV --
#      This method cleans the SRIOV mode
#
# Input:
#      machine: SUT or helper<x> (Optional, default is "SUT")
#
# Results:
#      "SUCCESS" if SRIOV VF pci device gets removed and passthrough
#                status for pnic is disabled.
#      "FAILURE" otherwise.
#
# Side effects:
#      PCI device gets removed from the vm and passthrough status
#      for pnic gets disabled.
#
########################################################################

sub CleanupSRIOV
{
   my $self     = shift;
   my $machine  = shift || "SUT";
   my $session  = $self->{session};
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $pciID;
   my $result;

   if (not defined $vmOpsObj) {
      next;
   }

   if ($vmOpsObj->VMOpsPowerOff() eq FAILURE) {
      $vdLogger->Error("Powering off VM failed");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }
   $self->PowerOffVMEvent($machine);

   $result = $vmOpsObj->VMOpsRemoveSRIOVPCIPassthru();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to remove pci passthrough devices ".
                       "from the VM");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# CleanupVMs --
#      This method cleans virtual machines used in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if vnics are cleaned successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub CleanupVMs
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $result = SUCCESS;

   # TODO - clean VMs, may be take snapshot in case of failure?
   # Get the VMOperations object for the virtual machine
   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   if (not defined $vmOpsObj) {
      $vdLogger->Info("No virtual machine initialized as $machine " .
                      "to clean");
      return SUCCESS;
   }
   my $adapters = $vmOpsObj->GetAdaptersInfo();
   if ($adapters eq FAILURE) {
      $vdLogger->Error("Failed to get adapters information on $machine");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # In the virtual adapters initialization part, the portgroup of all test
   # adapters is changed from "vdtest" to a unique portgroup name for the
   # session. As part of cleanup, the portgroup of these test adapters are
   # changed back to "vdtest".
   #
   foreach my $item (@$adapters) {
      my $type = $item->{"adapter class"};
      my $macAddress = $item->{"mac address"};
      # Change portgroup to unique portgroup name here
      if (($self->{session}->{hosted} == 0) &&
          ($item->{portgroup} !~ /VM Network/i)) { # This check not needed?
         $vdLogger->Info("Changing portgroup of $macAddress to \"vdtest\" " .
                         "on $machine");
         # TODO - remove # when InitializeVirtualSwitch() method is completed
         # no hardcoding of vdtest?
         $result = $vmOpsObj->VMOpsChangePortgroup($macAddress, "vdtest");
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to change portgroup of $macAddress");
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
      } else {
            next;
      }
   }
   return ($result eq FAILURE) ? FAILURE : SUCCESS;
}


########################################################################
#
# CleanupVirtualSwitches --
#      This method cleans virtual switches used in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if virtual switches are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVirtualSwitches
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};

   if (not defined $self->{testbed}{$machine}{switches}) {
      $vdLogger->Info("No virtual switch initialized to clean on $machine");
      return SUCCESS;
   }

   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $switchArray = $self->{testbed}{$machine}{switches};
   my $pgArray = $self->{testbed}{$machine}{portgroups};
   my $result;

   #
   # In vdnet all the virtual switches used are created freshly instead of
   # using existing ones. As part of cleanup, all those switches will be deleted.
   #
   foreach my $obj (@$switchArray) {
      $vdLogger->Info("Deleting $obj->{'name'} on $machine");
      if ($obj->{'switchType'} =~ /vdswitch/i) {
         #
         # vds deletion is done while doing vc cleanup,
         # so just set success here.
         #
         $result = SUCCESS;
      } else {
         $result = $hostObj->DeletevSwitch($obj->{'name'});
      }
      if ($result eq FAILURE) {
            $vdLogger->Error("Failed to delete $obj->{'name'} on $machine");
            VDSetLastError(VDGetLastError());
            return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# CleanupVMKNics --
#      This method cleans vmknics created in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the vmknics are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVMKNics
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};

   if (not defined $self->{testbed}{$machine}{Adapters}{vmknic}) {
      $vdLogger->Info("No vmknics initialized to clean on $machine");
      return SUCCESS;
   }
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   my $vmknics = $self->{testbed}{$machine}{Adapters}{vmknic};
   my $portgroups = $self->{testbed}{$machine}{portgroups};
   my @pgArray = @$portgroups;
   my $switches = $self->{testbed}{$machine}{switches};
   my @switchArray = @$switches;
   my $pgObj;
   my $switchObj;
   my $result;

   #
   # Get the vmknic/NetAdapter objects from testbed hash
   # and delete all of them. The procedure to delete vmknic
   # attached is different since if we use the same method for
   # removing the vmknic attached to vds then vc would not
   # get the updated informatin causing failures in subsequnt
   # methods like remove vds etc. So we get switch Object from
   # the portgroup to which vmknic is attached and then delete it.
   #
   foreach my $nic (keys %$vmknics) {
      my $nicObj = $self->{testbed}{$machine}{Adapters}{vmknic}{$nic};
      # get the portgroup object to which vmknic attached.
      for(my $i=0; $i<scalar(@pgArray); $i++) {
         if ($nicObj->{pgName} eq $pgArray[$i]->{pgName}) {
            $pgObj = $pgArray[$i];
            last;
         }
      }
      if (not defined $pgObj) {
         $vdLogger->Error("Failed to get the portgroup for vmknic ".
                          "$nicObj->{deviceId}");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # the dvportgroup would have switchObj (or VDSwitch object).
      if (not defined $pgObj->{switchObj}) {
         # this means vmknic is part of legacy portgroup so remove it.
         $result = $hostObj->DeleteVmknic($nicObj->{'deviceId'});
      } else {
         # this means vmknic is connected to vds portgroup.
         for(my $i=0; $i<scalar(@switchArray);$i++) {
            if($switchArray[$i]->{name} eq $pgObj->{switchObj}->{switch}) {
               $switchObj = $switchArray[$i];
               last;
            }
         }
         $result = $switchObj->RemoveVMKNIC($hostObj->{hostIP},$nicObj->{deviceId});
      }

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to delete vmknic $nicObj->{'deviceId'}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetVCBuildInformation --
#       return VC Build Information
#
#
# Input:
#       none
#
# Results:
#       returns VC Build Information, if success
#       returns FAILURE, if failed.
#
# Side effects:
#       none
#
########################################################################

sub GetVCBuildInformation
{
   my $self = shift;
   my $build;

   my $vcObj = $self->{vc}{vcOpsObj};
   if(not defined $vcObj ) {
     $vdLogger->Error("VC obj not defined");
     VDSetLastError("ENOTFEF");
   }
   $build = $vcObj->GetVCBuild();
   if ($build eq FAILURE) {
       $vdLogger->Error("Failed to get vc build information");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   return $build;
}


########################################################################
#
# PerformToolsUpgrade --
#       Method to check the version of tools and upgrade tools based on
#       preference given by user. By default tools iso corresponding to
#       that of host build is used. Users can also provide their own ISO
#       Tools server is mounted, symlinks are created and Upgrade tools
#       command is fired in staf sdk to achieve this.
#
# Input:
#       $machine - SUT, helper1 etc
#
# Results:
#       returns SUCCESS if tools upgrade is launched successfully
#       returns FAILURE, if failed.
#
# Side effects:
#       Yes. Saw toolsVersionStatus = <unset> on some VMs. But not able
#       to reproduce it while testing. Upgrade can fail for multiple
#       reasons
#
########################################################################

sub PerformToolsUpgrade
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $skipSetup = $session->{'skipSetup'};
   my $ignoreToolsUpgrade = $session->{'noTools'};
   my $hostObj = $self->{testbed}{$machine}{hostObj};

   my ($toolsServer, $toolsShare, $pathToPXE, $command, $toolsPath,
       $toolsUpgraderPath);
   #
   # For this machine first check the tools version.
   #
   my $ToolsBuildCfg;
   if (defined $self->{ToolsBuildCfg}) {
      $ToolsBuildCfg = $self->{ToolsBuildCfg};
   } else {
      $ToolsBuildCfg = 0;
   }

   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   my $result = $vmOpsObj->VMOpsGetToolsStatus();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get VMware Tools Status");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # First precedence is given to notools flag passed by user. If flag is set
   # then we dont upgrade tools.
   # If user gives path to iso in <tools> option then
   # perform upgrade with it irrespective of current tools status/version.
   # If upgrade is with default build then no need to upgrade if GetToolsStatus
   # says 'guestToolsCurrent'.
   # If GetToolsStatus says 1 = 'ToolsNeedUpgrade' then of course
   # upgrade tools.

   my $toolsBuild = $self->{testbed}{$machine}{tools};
   if ($ignoreToolsUpgrade == 1) {
      $vdLogger->Trace("Not upgrading VMware Tools as IgnoreToolsUpgrade ".
                       "flag is ". $ignoreToolsUpgrade);
      return SUCCESS;
   } else {
      if (($result == 0) && (not defined $toolsBuild)) {
         # Tools is already uptodate as given by VMOpsGetToolsStatus()
         $self->{testbed}{$machine}{toolsUpgrade}->{uptodate} = 1;
         return SUCCESS;
      }
   }

   # If <tools> is specified under -sut or -helper options then
   # irrespective of skipsetup flag we do tools upgrade.
   # <tools> is usually specified to perform a custom *.iso tools upgrade
   # One can point to sandbox tools build which hash isoimages and
   # tools-updaters
   # If <tools> is not specified and skipsetup is false then
   # upgrade of tools will be done with default host build number.

   if (!$skipSetup || defined $toolsBuild) {
      if(defined $toolsBuild) {
         #
         # we will perform upgrade with the custom iso in <tools>
         # Extract the custom iso location given by user.
         my $buildInfo;
         if ($toolsBuild =~ /:/) {
            ($toolsServer,$toolsShare) = split(/:/,
                                          $self->{testbed}{$machine}{tools});
         } elsif ($toolsBuild =~ /\d+/) {
            $buildInfo =
               VDNetLib::Common::FindBuildInfo::GetBuildInfo($toolsBuild);
            if ($buildInfo eq FAILURE) {
               $vdLogger->Error("Failed to find build information of " .
                                $toolsBuild);
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            my $buildTree = $buildInfo->{'buildtree'};
            my @temp = split(/\//, $buildTree);
            $toolsServer = "build-" . $temp[2];
            $toolsShare = $buildTree;
            $toolsShare =~ s/$temp[1]\///;
            $toolsShare = $toolsShare . '/publish';
         }
         if ((not defined $toolsServer) || (not defined $toolsShare)) {
            $vdLogger->Error("ToolServer and/or ToolShare not defined");
            $vdLogger->Debug("BuildInfo:" . Dumper($buildInfo));
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      } else {
         my ($stdout, $build, $bin);
         $build = $hostObj->{build};
         if ($machine =~ /helper/i) {
            if($self->{testbed}{$machine}{host} ne
               $self->{testbed}{SUT}{host} || ($ToolsBuildCfg == 0)) {
               #
               # If helper's host is not equal as SUT's host then no need to
               # find build tree details of that host again.
               #
               $ToolsBuildCfg = 0;
            } else {
               # Setting the flag to 1 as we dont need to configure
               # tools build again. Its same as that of SUT's
               $ToolsBuildCfg = 1;
            }
         }
      }
   }

   #
   # Mounting the Tool Server on esx for iso images to be available on it.
   #
   my $esxHost = $self->{testbed}{$machine}{host};

   # Flag suggests that tools build need to be configured.
   # After configuring it will be set to 1 so that subsequent VMs
   # can use the same isoimages and tools-upgraders.
   #
   # There are 2 components needed for tools upgrade.
   # 1. iso images and
   # 2. tools-upgrader scripts
   #
   # Custom builds (sandbox) and official tools build does not have
   # tools-upgrader scripts. In that case or always, use the tools-upgrader
   # scripts from VMTREE.
   #
   # For isoimages, use either from VMTREE or user defined images depending
   # upon what is given at command line
   #
   if($ToolsBuildCfg == 0) {
      #
      # if users provided custom build for tools at command line, then mount
      # that server and share
      #
      if (defined $toolsBuild) {
         $vdLogger->Info("Mounting " . $toolsServer . ":" . $toolsShare .
                         " as vmware-tools on $self->{testbed}{$machine}{host}");
         $result = $hostObj->{esxutil}->MountDatastore($esxHost,
                                                       $toolsServer,
                                                       $toolsShare,
                                                       "vmware-tools");
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to mount");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $toolsPath = VMFS_BASE_PATH . "$result";
      }

      #
      # VMTREE is needed in any case, so getting that for the given host
      #
      my $vmtree = $hostObj->GetVMTree();
      if ($vmtree eq FAILURE) {
         $vdLogger->Error("Failed to get VMTREE on $esxHost:");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      #for most sandbox/official builds, we look here
      $toolsUpgraderPath = $vmtree . "/../publish/pxe";
      $result = $self->{stafHelper}->DirExists($esxHost,
                                               $toolsUpgraderPath);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      if (!$result) {
         #for developer builds, it might be here
         $toolsUpgraderPath = $vmtree . "/build/esx/" . $hostObj->{buildType} . "/pxe";
         $result = $self->{stafHelper}->DirExists($esxHost,
                                                  $toolsUpgraderPath);
         if ($result eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         if (!$result) {
            $vdLogger->Error("Failed to find PXE deliverables in VMTREE");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      $toolsUpgraderPath = VDNetLib::Common::Utilities::ReadLink(
                                                         $toolsUpgraderPath,
                                                         $esxHost,
                                                         $self->{stafHelper});

      if ($toolsUpgraderPath eq FAILURE) {
         $vdLogger->Info("Failed to find link to tools upgrader scripts");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      chomp($toolsUpgraderPath);

      #
      # As mentioned above, if user specified toolsPath, then that will be
      # used, otherwise, toolsPath (iso images) and tools upgrader scripts
      # path are same (VMTREE)
      #
      if (not defined $toolsPath) {
         $toolsPath = $toolsUpgraderPath;
      } else {
         #
         # Create symlinks so that Guest looks into this folder for picking up
         # tools iso images and tools-updater scripts.
         # First find the UUID of vmware-tools storage, then use this UUID for
         # creating symlinks
         #
         if ($toolsPath ne $toolsUpgraderPath) {
            $toolsPath = VDNetLib::Common::Utilities::ReadLink(
                                                         $toolsPath,
                                                         $esxHost,
                                                         $self->{stafHelper});

            if ($toolsPath eq FAILURE) {
               $vdLogger->Info("Failed to find UUID of vmware-tools storage");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            chomp($toolsPath);
         }
      }
      $vdLogger->Debug("Tools ISO and upgrader path $toolsPath," .
                       $toolsUpgraderPath);

      #
      # Now, the official or sandbox builds for tools does not have the iso
      # images in the filename format that is expected by tools upgrader.
      # For example, for linux, instead of linux.iso, they are available as
      # VMware-tools-linux-8.9.0-471958.iso
      #
      # Depending on the guest OS, the regex pattern of iso filename is
      # is generated and searched under the toolspath
      #
      my (@lines, $line, $isoFile, $upgraderDir, $esxRelease);
      $isoFile = "";
      my $guestOS = $self->{testbed}{$machine}{os};
      if ($guestOS =~ /lin/i) {
         $isoFile = "linux";
      } elsif ($guestOS =~ /^win/i) {
         $isoFile = "windows";
      } elsif ($guestOS =~ /darwin|mac/i) {
         $isoFile = "darwin";
      } elsif ($guestOS =~ /bsd/i) {
         $isoFile = "freebsd";
      } else {
         $vdLogger->Error("Unsupported guest type: $guestOS");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      #
      # Finding the folder on this storage which contains iso images and
      # upgrader scripts
      #
      # The iso file pattern is *<guestType>*.iso, which will return both
      # linux.iso and  VMware-tools-linux-X.X.X-XXXXXX.iso
      #
      $command = "find $toolsPath -iname \"*.iso\" -maxdepth 5";
      $result  = $self->{stafHelper}->STAFSyncProcess($esxHost, $command);
      if (($result->{rc} != 0)) {
         $vdLogger->Error("Failed to execute $command on $esxHost:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if($result->{stdout} !~ /\.iso/i) {
         $vdLogger->Warn("Wrong Symlink? build backedup to tape?");
         $vdLogger->Error("ISO files missing for tools upgrade. Command:".
                          "$command Host:$esxHost Result:". Dumper($result));
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      my ($sourceFile, $symlinkName, $dstDir);
      @lines = split('\n',$result->{stdout});
      foreach $line (@lines) {
         if ($line =~ /visor/i) {
            next;
         }
         if($line =~ /(.*)\/(.*)\.iso/i) {
            my $tempISOFile = $2;
            if ($tempISOFile eq "$isoFile") {
               #
               # If the iso images available in the current directory match the
               # expected iso image, say, linux.iso or windows.iso,
               # symlink the entire directory (this is current setting of
               # /usr/lib/vmware/isoimages/ which is a symlink to a directory
               # that contains all iso images for tools).
               #
               $sourceFile = $1;
               $symlinkName = 'isoimages';
               $dstDir = VMWARE_TOOLS_BASE_PATH;
               last;
            } elsif ($tempISOFile =~ /$isoFile.*/) {
               #
               # If the iso images file name are not in the format that tools
               # upgrader looks for that, then assume this is official or
               # sandbox tools build (not esx build) and symlink to the file
               # specifically. For example, VMware-tools-linux-8.9.0-XXXXX.iso
               # --> linux.iso
               #
               $sourceFile = $line;
               $symlinkName = $isoFile . '.iso';
               $dstDir = VMWARE_TOOLS_BASE_PATH . 'isoimages';
               last;
            } else {
               next;
            }
         }
      }

      # All iso should be located in single dir along with their
      # signature files(*.iso.sig)
      # Extracting the path where tools ISO images are residing.
      $command = "find $toolsUpgraderPath -o -iname \"*.sh\" -o -iname \"*.exe\"";
      $result  = $self->{stafHelper}->STAFSyncProcess($esxHost, $command);
      if (($result->{rc} != 0)) {
         $vdLogger->Error("Failed to execute $command on $esxHost:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if($result->{stdout} !~ /\.sh/i) {
         $vdLogger->Warn("Wrong Symlink? build backedup to tape?");
         $vdLogger->Error("Upgrader files missing for tools upgrade. Command:".
                          "$command Host:$esxHost Result:". Dumper($result));
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      # Extracting the path where upgrader scripts are residing.
      @lines = split('\n',$result->{stdout});
      foreach $line (@lines) {
         if ($line =~ /tools-upgraders$/i) {
            $upgraderDir = $line;
            last;
         }
      }

      if((not defined $sourceFile) || (not defined $upgraderDir)) {
         $vdLogger->Error("Failed to find VMware Tools files for upgrading. ".
                          "ISO:$isoFile Upgrader: $upgraderDir");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      #
      # Creating Symlink for isoimages
      #
      if ($sourceFile =~ /\.iso$/) {
         # Remove the old symlink before creating new one.
         $command = "rm -rf '$dstDir'; rm -rf '/productLocker'; " .
                    "mkdir -p '$dstDir'";
         $result = $self->{stafHelper}->STAFSyncProcess($esxHost, $command);
         if ($result->{rc} && $result->{exitCode}) {
            $vdLogger->Warn("Staf error while removing symlink on $esxHost:".
                            $result->{result});
         }
      }
      $isoFile =~ s/\n//g; # remove any new line character
      $vdLogger->Info("Using VMware Tools ISO image from:". $sourceFile);
      $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHost,
                                                        $sourceFile,
                                                        $dstDir,
                                                        $symlinkName,
                                                        $self->{stafHelper});
      if ($result eq FAILURE) {
          $vdLogger->Error("Failed to get guest information in ".
                           "PerformToolsUpgrade");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }

      #
      # In addition to updating files under /usr/lib/vmware,
      # /productLocker should also be pointing to the tools images
      # see PR893337
      #
      my @temp = split(/\//, $sourceFile);
      pop(@temp);
      $sourceFile = join("\/", @temp);
      $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHost,
                                                           $sourceFile,
                                                           "/",
                                                           "productLocker",
                                                           $self->{stafHelper});
      if ($result eq FAILURE) {
          $vdLogger->Error("Failed to update /productLocker file");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }

      #
      # In addition to iso images, create symlinks for .sig files.
      # Signature check is skipped for obj builds but required for other build
      # types
      #
      if ($sourceFile =~ /\.iso$/) {
         $sourceFile = $sourceFile . '.sig';
         $symlinkName = $isoFile . '.iso.sig';
         $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHost,
                                                           $sourceFile,
                                                           $dstDir,
                                                           $symlinkName,
                                                           $self->{stafHelper});
      }

      #
      # Creating Symlink for tools-upgraders scripts
      #
      $symlinkName = "tools-upgraders";
      $vdLogger->Trace("Using VMware Tools upgrader from:". $upgraderDir);
      $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHost,
                                                        $upgraderDir,
                                                        VMWARE_TOOLS_BASE_PATH,
                                                        $symlinkName,
                                                        $self->{stafHelper});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get guest information in ".
                          "PerformToolsUpgrade");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $self->{ToolsBuildCfg} = 1;
   }

   # VM staf service command UPGRADETOOLS is a blocking call. Thus what we do is
   # generate the staf cmd for upgrading tools and wrap it into another
   # async staf command and launch it.
   my $vmName = $vmOpsObj->{'vmName'};
   my $vmStafAnchor = $vmOpsObj->{'stafVMAnchor'};
   $command = "UPGRADETOOLS ANCHOR $vmStafAnchor VM $vmName WAITFORTOOLS";

   #
   # If the OS is linux and kernel is greater than 2.6.32-rc5 then it
   # will have inbox vmxnet3 driver. That is why we pass installeroptions
   # to clobber inboxed vmxnet3 driver and replace it with vmxnet3
   # from this vmware tools package.
   #
   if ($self->{testbed}{$machine}{os} =~ /linux/i) {
      $command = $command . " INSTALLEROPTIONS --clobber-kernel-modules=vmxnet3";
   }


   # Get the name of the file which will contain staf upgrade async launch
   # information.
   my $toolsStatus = $session->{logDir};
   if ($toolsStatus =~ /\/$/) {
      $toolsStatus = $toolsStatus . $machine;
   } else {
      $toolsStatus = $toolsStatus . "/" . $machine;
   }
   $toolsStatus = $toolsStatus . "-vmware-tools-upgrade-staf.log";
   $self->{testbed}{$machine}{toolsUpgrade}->{file} = $toolsStatus;

   # Launch the staf async process which is a wrapper for
   # STAF local vm UPGRADETOOLS ANCHOR.... command
   $command = "STAF local VM " . $command;
   open FILE, ">" ,$toolsStatus;
   print FILE "$command\n\n";
   close FILE;
   $vdLogger->Info("Upgrading VMware Tools on $machine.");
   $result = $self->{stafHelper}->STAFAsyncProcess("local",
                                                      $command,
                                                      $toolsStatus);
   if ($result->{rc} && $result->{exitCode}) {
      $vdLogger->Error("Unalbe to launch local command:".
                       $command);
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Store the handle and pid of the wrapper staf command.
   $self->{testbed}{$machine}{toolsUpgrade}->{handle} = $result->{handle};
   $result = $self->{stafHelper}->GetProcessInfo("local", $result->{handle});
   if ($result->{rc}) {
      if(defined $result->{endTimestamp}) {
         $vdLogger->Error("Unalbe to start Tools Upgrade on $machine");
      }
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{testbed}{$machine}{toolsUpgrade}->{pid} = $result->{pid};
   return SUCCESS;

}

########################################################################
#
# CheckMachineExistsInCache--
#      Method to check the given machine exists in the resourceCache
#      array.
#
# Input:
#      machineToCheck: reference to hash containing machine (vm)
#                      information. The keys of this hash much match the
#                      hash in resourceCache array. (Required)
#      machine       : SUT/helper<x> (Required)
#
# Results:
#      index to the matching maching in resourceCache array, if the
#      given machine exists in resourceCache;
#      undef, if the no matching machine found in resourceCache array
#
# Side effects:
#      None
#
########################################################################

sub CheckMachineExistsInCache {
   my $self           = shift;
   my $machineToCheck = shift;
   my $machine        = shift;
   my $refToResourceCache = $self->{resourceCache};
   if ((not defined $machineToCheck) || (not defined $machine)) {
      $vdLogger->Error("Details of machine to check in cache not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # things to check:
   # vm
   # vmx
   # host
   # sharedstorage
   # availability
   #
   my $existingMachine = undef; # initialize to undef
   my @resourceCacheArray = @{$refToResourceCache};
   my $index = 0;
   foreach my $machineCache (@resourceCacheArray) {
      my $matchFlag = 1;
      $matchFlag = ($machineCache->{available}) ? (1&&$matchFlag) : 0;
      if ($machineCache->{available}) {
         $matchFlag = ($machineCache->{healthStatus} eq "good") ?
                      (1&&$matchFlag) : 0;
      }
      $matchFlag = ($machineCache->{host} eq $machineToCheck->{host}) ?
                     (1&&$matchFlag) : 0;
      $matchFlag = ($machine =~ /$machineCache->{machineType}/) ?
                     (1&&$matchFlag) : 0;
      if (defined $machineToCheck->{vmID}) {
         $matchFlag = ($machineCache->{vmID} eq $machineToCheck->{vmID}) ?
                        (1&&$matchFlag) : 0;
         $matchFlag = ($machineCache->{datastoreType} eq
                         $machineToCheck->{datastoreType}) ? (1&&$matchFlag) : 0;
      }
      if (defined $machineToCheck->{vmx}) {
         $matchFlag = ($machineCache->{vmx} eq $machineToCheck->{vmx}) ?
                        (1&&$matchFlag) : 0;
      }

      if ($matchFlag) {
         $existingMachine = $index;
         last;
      }
      $index++;
   }
   return $existingMachine;
}


########################################################################
#
# CheckMachinesHealth--
#      Method to check the status of all components such as host, VMs,
#      phy switches etc. TODO: only handling host checkup for now, add
#      other components on need basis.
#
# Input:
#      None
#
# Results:
#      SUCCESS, if the status of all components are good;
#      FAILURE, in case of any error;
#      ABORT, in case of any catastrophic failure.
#
# Side effects:
#      None
#
########################################################################

sub CheckMachinesHealth {
   my $self	= shift;
   my $session	= $self->{session};
   my $result	= SUCCESS;

   if (defined $session->{Parameters}{vc}) {
      my $vc = $self->{vc}->{vcaddr};
      if (defined $vc) {
         $vdLogger->Info("Doing health checkup on VC $vc...");
         if (VDNetLib::Common::Utilities::Ping($vc)) {
            $vdLogger->Error("VC $vc is not accessible");
            $result = ABORT;
            return ABORT;
         }
      }
   }

   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"host"}) {
         $vdLogger->Info("Doing health checkup on $machine host...");
         my $hostIP = $self->{testbed}{$machine}{host};
         next if (not defined $hostIP);
         if (FAILURE eq $self->CheckMachineAccess($hostIP)) {
            $result = ABORT;
            return ABORT;
         }
      }
   }

   foreach my $machine (keys %{$self->{testbed}}) {
      if (defined $session->{"Parameters"}{$machine}{"vm"}) {
         $vdLogger->Info("Doing health checkup on $machine VM...");
         my $resourceCacheIndex = $self->{testbed}{$machine}{resourceCacheIndex};
         if (not defined $resourceCacheIndex) {
            $vdLogger->Warn("Something wrong, $machine should exist in " .
                            "resource cache at this point");
            next;
         }
         my $refToHash = @{$self->{resourceCache}}[$resourceCacheIndex];
         my $vmIP = $self->{testbed}{$machine}{ip};
         if (defined $refToHash->{healthStatus}) {
            $vdLogger->Info("$machine VM's health already verified");
         } else {
            $refToHash->{healthStatus} = "bad";  # updating the actual
                                                 # resourceCache,
               $refToHash->{available} = 0;
            if (defined $vmIP) {
               if (FAILURE ne $self->CheckMachineAccess($vmIP)) {
                  $refToHash->{healthStatus} = "good";
                  $refToHash->{available} = 1;
               }
            }

            if ("bad" eq $refToHash->{healthStatus}) {
               $vdLogger->Error("$machine VM with IP $vmIP is not accessible");
               $self->{logCollector}->CollectLog("VM");
               $self->{logCollector}->CollectLog("Host");
            }
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# CheckMachineAccess--
#      Check if the given machine is accessible.
#
# Input:
#      host : ip address of the machine
#
# Results:
#      SUCCESS, if the machine is accessible;
#      FAILURE, otherwise
#
# Side effects:
#      None
#
########################################################################

sub CheckMachineAccess
{
   my $self	= shift;
   my $host = shift;
   my $timeout = 60;

   if (not defined $host) {
      $vdLogger->Error("Host on which staf should wait not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $startTime = time();
   while ($timeout && $startTime + $timeout > time()) {
      if (VDNetLib::Common::Utilities::Ping($host)) {
         $vdLogger->Debug("$host not accessible, still trying...");
         sleep 5;
      } else {
         $vdLogger->Debug("$host is pingable");
         if ($self->{stafHelper}->CheckSTAF($host) eq FAILURE) {
            $vdLogger->Debug("STAF not running on $host");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
            return SUCCESS;
         }
      }
   }
   $vdLogger->Error("Machine $host not accessible");
   VDSetLastError("ENETDOWN");
   return FAILURE;
}


########################################################################
#
# WaitForToolsUpgrade --
#       Method to wait on tool's upgrade async process to finish on a
#       given machine
#
# Input:
#       $machine - SUT, helper1 etc
#
# Results:
#       returns SUCCESS if tools versions is uptodate
#       returns FAILURE, if failed.
#
# Side effects:
#       none.
#
########################################################################

sub WaitForToolsUpgrade
{
   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $skipSetup = $session->{'skipSetup'};
   my $ignoreToolsUpgrade = $session->{'noTools'};

   if ($skipSetup && not defined $self->{testbed}{$machine}{tools}) {
      $vdLogger->Info("Not waiting on Tools Upgrade as tools not defined and".
                       " skipsetup is set");
       return SUCCESS;
   }

   my $toolsUpgradeInfo = $self->{testbed}{$machine}{toolsUpgrade};
   if (not defined $toolsUpgradeInfo) {
      $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess info is missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   } elsif ($toolsUpgradeInfo->{uptodate}) {
      delete $self->{testbed}{$machine}{toolsUpgrade};
      # Tools was already uptodate. So no point waiting on it.
      return SUCCESS;
   }

   my $processLog = $toolsUpgradeInfo->{file};
   my $processHandle = $toolsUpgradeInfo->{handle};
   if ((not defined $processHandle) || (not defined $processLog)) {
      $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess handle ".
                       "or stdout File is missing" . Dumper($toolsUpgradeInfo));
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   # Get all the informatiion about that process. Wait and keep Reading till
   # the process gets endtimestamp
   my $result;
   $vdLogger->Info("Waiting for VMware Tools Upgrade to finish on $machine...");
   # On a Windows VM it should take a maximum of 30 min to upgrade
   # in a worst case scenario, thus keeping 30 min as default wait time.
   my $startTime = time();
   my $timeout = 30 * 60; # converting it to sec.
   do {
      sleep(1);
      $timeout--;
      `grep -ri Response $processLog`;
   } while($timeout > 0 && $? != 0);

   if ($timeout == 0) {
       $vdLogger->Error("Hit Timeout=30 min for VMware Tools STAF Async".
                        " call to finish. Log:". $processLog);
       $result = $self->{stafHelper}->GetProcessInfo("local", $processHandle);
       $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess Info:".
			                      Dumper($result));
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   #
   # Immediately after tools installation finishes, the VM's file-system
   # gets frozen for 3-4 seconds. Hence if any STAF command is issued to
   # the VM in that state it would return the failure. Below function is
   # to make sure we proceed after the vm resumes normally.
   #
   if ($self->{stafHelper}->WaitForSTAF(
		$self->{testbed}{$machine}{ip}) eq FAILURE) {
      $vdLogger->Error("STAF not running on $machine");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # We noticed that if immediately after VMOpsUpgradeTools() we
   # called VMOpsGetToolsStatus() it was returning tools
   # version as 0.0.0 because tools service was not stable yet.
   # Even waiting on staf didnt fix the purpose. So workaround is to
   # do 'vmware-toolbox-cmd --version' on it. It will return only after
   # tools service stabilizes.
   #
   if ($self->{testbed}{$machine}{os} =~ /linux/i) {
      # Because vmxnet3 is an inboxed driver, even after upgrading tools with --clobber
      # it will not load the vmxnet3 module on its own. Thus we do it explicitly.
      my $command = "vmware-toolbox-cmd --version; ".
		    "modprobe -r vmxnet3; modprobe vmxnet3";
      $result  = $self->{stafHelper}->STAFSyncProcess($self->{testbed}{$machine}{ip},
                                                         $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command on $self->{testbed}{$machine}{ip}:"
                          . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Trace("tools version returned by guest:" . $result->{stdout});
   }
   # TODO: Also get the Version on Windows using VMwareToolsCmd.exe --version

   #
   # Checking the status of VMware tools after upgrading.
   # It takes a some time for the tools status to reflect the correct value
   # after the tools upgrade. Giving few secs before bailing out.
   #

   my $vmOpsObj = $self->{testbed}{$machine}{vmOpsObj};
   $startTime = time();
   $timeout = GUEST_BOOTTIME;
   while ($timeout && $startTime + $timeout > time()) {
      VDCleanErrorStack();
      $result = $vmOpsObj->VMOpsGetToolsStatus();
      if ((!$result) && ($result ne FAILURE)) {
         # Cleanup the var and log file before exiting from the method
         `rm -rf $processLog`;
         delete $self->{testbed}{$machine}{toolsUpgrade};
         return SUCCESS;
      } else {
         sleep GUESTIP_SLEEPTIME;
      }
   }
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


###############################################################################
#
# GenerateSwitchName -
#       Generate a switch name which will be created for the current session
#       of the test run.
#
# Input:
#       $switchType - Type of switch(mandatory)
#       $count      - the switch number (mandatory)
#
# Results:
#       switch Name - on SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub GenerateSwitchName
{
   my $self = shift;
   my $switchType = shift;
   my $count = shift;
   my $session = $self->{session};
   my $testNumber = $session->{testCount} || "1";
   my $switchName = $switchType . "-" . $count . "-" .$testNumber. "-". $$ % 2000;
   return $switchName;
}


###############################################################################
#
# GeneratePortgroupName -
#       Generate a portgroup name which will be created for the current session
#       of the test run.
#
# Input:
#       $switchType - Type of switch(mandatory)
#       $count      - the switch number (mandatory)
#
# Results:
#       portgroup Name - on SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub GeneratePortgroupName
{
   my $self = shift;
   my $switchType = shift;
   my $count = shift;
   my $session = $self->{session};
   my $testNumber = $session->{testCount} || "1";
   my $pgName = $switchType . "-" . "pg" . "-" . $count . "-" .$testNumber. "-". $$ % 2000;
   return $pgName;
}


#############################################################################
# CreateHostedObj -
#       Creates hostedtestbed objects and bless it with parent attributes.
#
# Input:
#       childType - Type of Verification of which object is to be
#                   created (mandatory)
#
# Results:
#       child object - returns child obj handle
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CreateHostedObj
{
   my $self = shift;
   my $childModule = "VDNetLib::Common::HostedTestbed";
   eval "require $childModule";
   if ($@) {
      $vdLogger->Error("Failed to load package $childModule $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Keep new (method) of child as light as possible for better performance.
   my $childObj = $childModule->new($self);
   if ($childObj eq FAILURE) {
      $vdLogger->Error("Failed to create obj of package $childModule");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Copy the attributes of parent to child object.
   # Thus parents and child classes share these attributes now.
   #
   foreach my $key (keys %$self){
      if (not defined $childObj->{$key}) {
         $childObj->{$key} = $self->{$key}
      }
   }
   bless $childObj, $childModule;

   return $childObj;
}


########################################################################
#
# PowerOffVMEvent--
#     Event handler function for power off VM event.
#
# Input:
#     machine: SUT or helper<x> (Required)
#
# Results:
#     SUCCESS, if the callback functions as part of power off VM event
#              are executed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub PowerOffVMEvent
{
   my $self = shift;
   my $tuple = shift;

   my $machine = $self->GetMachineFromTuple($tuple);

   my $resourceCacheIndex = $self->{testbed}{$machine}{resourceCacheIndex};

   if (not defined $resourceCacheIndex) {
      $vdLogger->Error("Something wrong, $machine should exist in " .
                      "resource cache at this point");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $refToHash = @{$self->{resourceCache}}[$resourceCacheIndex];
   $refToHash->{healthStatus} = "good";
   $vdLogger->Debug("Status of the VM " . $refToHash->{healthStatus});
   return SUCCESS;
}


########################################################################
#
# GetComponentObject --
#       This method would fetch the required component object from the
#       given inventory and return it to the caller.
#
# Input:
#       $component - A 3 tuple string of type: SUT:host.1
#                    Format: <target>.<component>.<index>
#
# Results:
#       returns reference to the required component object (or Array of
#		objects, in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetComponentObject
{
   my $self	 = shift;
   my $component = shift;

   if (not defined $component) {
      $vdLogger->Error("Component/tuple not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } else {
      $vdLogger->Debug("Component/tuple: $component");
   }

   #
   # Now based on the first tuple value in the input
   # string the relevant GetComponentObject() method
   # will be invoked and the fetched object will  be
   # returned to the caller.
   #

   my $inventory   = undef;
   my $inputToComp = undef;

   my @componentArrary = split(/\./, $component);

   $inventory   = $componentArrary[1];

   #
   # $self->InitializeInventoryObjects() has alreday
   # been called once in new() method.
   #

   my $finalMethod = $self->{inventoryObjects}->{$inventory};
   if ((not defined $finalMethod) || (not defined $inventory)) {
      $vdLogger->Error("Either finalMethod $finalMethod or inventory " .
                       "$inventory is undefined for component $component");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Tuple used for getting $inventory object is $component");
   return $self->$finalMethod(@componentArrary);
}


########################################################################
#
# InitializeInventoryMapping --
#       This method would initialize all the inventory object module
#	mappings
#
# Input:
#	None
#
# Results:
#       returns reference to the inventoryObjects map hash
#
# Side effects:
#       None.
#
########################################################################

sub InitializeInventoryMapping
{
   my $self = shift;

   my %inventoryObjects = (

      #
      # This would would  contain mapping for all the inventory
      # objects to their relevant GetComponentObject() function.
      #
      'vc'		=>	'GetVCObject',
      'host'		=>	'GetHostObject',
      'vm'		=>	'GetVMObject',
      'vnic'		=>	'GetAdapterObject',
      'vmnic'		=>	'GetAdapterObject',
      'vmknic'		=>	'GetAdapterObject',
      'portgroups'	=>	'GetPortGroupsObject',
      'switch'		=>	'GetSwitchObject',
      'pswitch'		=>	'GetPSwitchObject',
      '1'		=>	'GetMachineObject',
   );

   return \%inventoryObjects;
}


########################################################################
#
# GetVCObject --
#       This method would fetch the required VC Component object
#       reference from testbed object, based on the values given
#       in the input string.
#
# Input:
#	None
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetVCObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};
   my $machine  = shift;
   my @myObj;

   @myObj = $testbed->{$machine}->{vcOpsObj};
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "VC component for machine $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetHostObject --
#       This method would fetch the required Host Component object
#       reference from testbed object, based  on  the values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine - sut/helper1, whose object reference is needed
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetHostObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine  = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   @myObj = $testbed->{$machine}{hostObj};
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetVMObject --
#       This method would fetch the required VM Component object
#       reference from testbed object, based on the values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine - sut/helper1, whose object reference is needed
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetVMObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine  = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   @myObj = $testbed->{$machine}{vmOpsObj};
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetAdapterObject --
#       This method would fetch required Netadapter Component object
#       reference from the testbed object, based on the values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine     - sut/helper1, whose object reference is needed
#	$adapterType - vnic/vmknic/vmnic, type of the adapter
#	$index	     - index of the adapter (starts with 0)
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetAdapterObject
{
   my $self	   = shift;
   my $testbed	   = $self->{testbed};

   my $machine	   = shift;
   my $adapterType = shift;
   my $index	   = shift;

   if ((not defined $machine) ||
       (not defined $adapterType) ||
       (not defined $index)) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;
   if ($adapterType =~ /vnic/i) {
      @myObj = $testbed->{$machine}{'Adapters'}{$index};
   } elsif ($adapterType =~ /vmknic/i) {
      @myObj = $testbed->{$machine}{'Adapters'}{'vmknic'}{$index};
   } elsif ($adapterType =~ /vmnic/i) {
      @myObj = $testbed->{$machine}{'Adapters'}{'vmnic'}{$index};
   } elsif ($adapterType =~ /pci/i) {
      @myObj = $testbed->{$machine}{'Adapters'}{'pci'}{$index};
   } else {
      $vdLogger->Error("Unknown adapter type $adapterType given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine.$adapterType.$index");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetPortGroupsObject --
#       This method would fetch the   required PortGroup Component
#       object reference from testbed object,based on values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine       - sut/helper1, whose object reference is needed
#	$componentType - Portgroups (Not required)
#	$index	       - index of the portgroup (starts with 0)
#			 (-1, if reference to entire portgroups object
#			  array needs to be returned.)
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetPortGroupsObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine	     = shift;
   my $componentType = shift;
   my $index	     = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   if ((defined $index) && ($index >= 0)) {
      #
      # e.g. sut.portgroups.2 (index starts at 0)
      # In this this case, reference to the specific porgroup
      # on the given machine will be returned as output.
      #
      @myObj = ${$testbed->{$machine}{portgroups}}[$index-1];
   } else {
      #
      # e.g. sut.portgroups.-1
      # In this this case, reference to the entire porgroups array
      # on the given machine will be returned as output.
      #
      @myObj = @{$testbed->{$machine}{portgroups}};
   }
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetMachineObject --
#       This method would fetch the required SUT/Helper1. object
#       reference from testbed object, based on the values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine       - sut/helper1, whose object reference is needed
#			 (This module  will be called if the parent
#			  GetComponentObject()  function is  called
#			  with 3 tuple string of type: "sut.1.1" or
#			  helper1.1.1)
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetMachineObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine  = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   @myObj = $testbed->{$machine};
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetSwitchObject --
#       This method would fetch the required Switch (vss/vds) object
#       reference from the testbed object, based on the values given
#       in the input string. The same will be returened to caller.
#
# Input:
#       $machine       - sut/helper1, whose object reference is needed
#	$ComponentType - switch (Not required)
#	$index	       - index of the switch (starts with 0)
#			 (-1, if reference to entire switch object
#			  array needs to be returned.)
#
#
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetSwitchObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine  = shift;
   my $componentType = shift;
   my $index	     = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   if ((defined $index) && ($index >= 0)) {
      #
      # e.g. sut.switch.1 (index starts at 0)
      # In this this case, reference to the specific switch
      # on the given machine will be returned as output.
      #
      @myObj = ${$testbed->{$machine}{switches}}[$index-1];
   } else {
      #
      # e.g. sut.switch.-1
      # In this this case, reference to the entire switches array
      # on the given machine will be returned as output.
      #
      @myObj = @{$testbed->{$machine}{switches}};
   }

   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetPSwitchObject --
#       This method would fetch the required PSwitch object
#       reference from testbed object, based on the  values
#       given in the input string.
#
# Input:
#       $machine - sut/helper1, whose object reference is needed
#
# Results:
#       returns required component object reference in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetPSwitchObject
{
   my $self     = shift;
   my $testbed  = $self->{testbed};

   my $machine  = shift;

   if (not defined $machine) {
      $vdLogger->Error("Component information is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @myObj;

   @myObj = $testbed->{$machine}{pswitch};
   if (not defined $myObj[0]) {
      $vdLogger->Error("Testbed does not have any reference to the given" .
                       "component: $machine");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return \@myObj;
}


########################################################################
#
# GetAllMachines --
#       Returns all the machine like SUT/Helper in the testbed hash
#
# Input:
#       none
#
# Results:
#       reference to all the machines in testbed hash
#
# Side effects:
#       none
#
########################################################################

sub GetAllMachines
{
   my $self = shift;
   return $self->{testbed};
}


###############################################################################
#
# GetAllTestAdapters -
#       Returns the tuple SUT:vnic:1.
#
# Input:
#
# Results:
#       SUCCESS - Return reference to test adapter array
#
# Side effects:
#       None
#
###############################################################################

sub GetAllTestAdapters
{
   my $self = shift;
   my @adapter;
   my $adapterTemp = "SUT:vnic:1";
   push (@adapter,$adapterTemp);
   return \@adapter;
}


###############################################################################
#
# GetAllSupportAdapters -
#       API returns tuples of vnic, vmknic and vmnic adapeter for both SUT and
#       Helper.
#
# Input:
#
# Results:
#       SUCCESS - Return reference to an array which has the list of adapters
#       FAILURE - In case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetAllSupportAdapters {
   my $self = shift;
   my $testbed = $self->{testbed};
   my $adapterTemp;
   my @adapter;
   foreach my $machine (keys %$testbed) {
      if (defined $testbed->{$machine}->{'Adapters'}) {
         # pick all the vNics.
         my $allAdapters = $testbed->{$machine}->{'Adapters'};
         foreach my $nicTypeORIndex (keys %$allAdapters) {
            # index of vNIC is always a digit
            if ($nicTypeORIndex =~ /\d+/) {
               # For constructing a string of nodes e.g.
               # helper1:vnic:1,helper2:vnic:1 ...
               $adapterTemp = $machine . ":vnic:" .$nicTypeORIndex;
               push (@adapter,$adapterTemp);
            } else {
               # pick all the vmknics/pci nics
               next if $nicTypeORIndex =~ /vmnic/i;
               my $allNonVNICs = $allAdapters->{$nicTypeORIndex};
               foreach my $nonVNICIndex (keys %$allNonVNICs) {
                  # For constructing a string of nodes e.g.
                  # helper1:pci:1,helper1:vmknic:1 ...
                  $adapterTemp = $machine .":". $nicTypeORIndex .
                             ":". $nonVNICIndex;
                  push (@adapter,$adapterTemp);
               }
            }
         }
      }
   }
   if (not defined \@adapter) {
      $vdLogger->Error("Unable to get adapter");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return \@adapter;
}


###############################################################################
#
# GetVMID -
#       API returns the run time attribute of SUT/Helper called vmID
#
# Input:
#      machine - SUT/helper for which vmID is requested
#
# Results:
#       SUCCESS - Return vmID if found
#       FAILURE - In case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVMID
{
   my $self    = shift;
   my $machine = shift;

   my $vmID = $self->{testbed}{$machine}{vmID};
   if (not defined $vmID) {
      $vdLogger->Error("Unable to get the vmID for $machine");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $vmID;
}


###############################################################################
#
# GetVMDisplayName -
#       API returns the run time attribute of SUT/Helper called VM Display
#
# Input:
#      machine - SUT/helper for which VM Display is requested
#
# Results:
#       SUCCESS - Return VM Display if found
#       FAILURE - In case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVMDisplayName
{
   my $self    = shift;
   my $machine = shift;

   my $vmDisplayName = $self->{testbed}{$machine}{'vmDisplayName'};
   if (not defined $vmDisplayName) {
      $vdLogger->Error("Unable to get the vmDisplayName for $machine");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $vmDisplayName;
}


###############################################################################
#
# GetMachineFromTuple -
#
# Input:
#       tuple - 3 values tuple or a string
#
# Results:
#       Returns SUT or Helper from SUT.vm.1
#
# Side effects:
#       None
#
###############################################################################

sub GetMachineFromTuple
{
   my $self    = shift;
   my $tuple   = shift || undef;

   if ((defined $tuple) && ($tuple =~ /\.+/)) {
      my @arr = split('\.', $tuple);
      return $arr[0];
   } else {
      return $tuple;
   }
}
1;
