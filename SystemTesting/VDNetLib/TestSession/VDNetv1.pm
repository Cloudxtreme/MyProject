########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::VDNetv1;

#
# This package inherits VDNetLib::TestSession::TestSession Class.
# It stores attributes and implements method to run vdnet tests
# version 1.
#
#
use strict;
use warnings;

use base 'VDNetLib::TestSession::TestSession';

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::Utilities;
use VDNetLib::Testbed::Testbedv1;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);

# TODO: remoove this global variable after resource cache for testbed v2
# is implemented
our @resourceCache = ();

########################################################################
#
# new--
#     Constructor to create an object of
#     VDNetLib::TestSession::TestSessionv1
#
# Input:
#     testcaseHash  : Reference to vdnet test case hash (version 1)
#     userConfigHash: Reference to userConfigHash which has following
#                     keys;
#                     hostlist: comma separated list of host IPs
#                     vmlist  : TBD
#                     pswitch : phy switch ip address
#                     vdnetOptions : TBD
#                     sut     : TBD
#                     helper  : TBD
#
#
# Results:
#     An object of VDNetLib::TestSession::TestSessionv1, if successful;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $testcaseHash     = $options{'testcaseHash'};
   my $userConfigHash   = $options{'userConfigHash'};
   my $self = VDNetLib::TestSession::TestSession->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSession::TestSession" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{'version'} = "1.0";
   $self->{'Parameters'} = undef;
   $self->{'Parameters'}{'vc'} = $self->{'vc'};
   $self->{resourceCache} = \@resourceCache;
   bless $self, $class;
   if ($self->Initialize() eq FAILURE) {
      $vdLogger->Error("Failed to initialize test session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self;
}


########################################################################
#
# Initialize--
#     Method to initialize test session which includes creating
#     testbed spec based on test case hash and userconfig hash
#
# Input:
#     None
#
# Results:
#     SUCCESS, if the test session is initialized successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub Initialize
{
   my $self = shift;

   if (FAILURE eq $self->SUPER::Initialize()) {
      $vdLogger->Error("Failed to initialize using parent method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Initialize Testbedv1.pm (testbed needs to be initialized first
   # since CreateTestbedSpec() is dependent on testbed obj. Testbedv1
   # acts as both resource cache and also stores test objects per
   # test. This needs to be de-coupled
   #
   #
   my $testbed = VDNetLib::Testbed::Testbedv1->new('session' => $self);
   if ($testbed eq FAILURE) {
      $vdLogger->Error("Creation of testbed object failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{testbed} = $testbed;

   $self->SetWorkloadsManagerObj();

   if (FAILURE eq $self->CreateTestbedSpec($self->{testcaseHash},
                                           $self->{testbed})) {
      $vdLogger->Error("Failed to create testbed spec");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->ProcessTestCaseHash($self->{testcaseHash})) {
      $vdLogger->Error("Failed to create testbed spec");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# TestbedSetup--
#     Method to do testbed initialization
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed is setup successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub TestbedSetup
{
   my $self = shift;
   #
   # Init Testbed here corresponding to the test case
   #
   if ($self->{testbed}->Init() eq FAILURE) {
      $vdLogger->Error("Init in Testbed failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RunTest--
#     Method to run the test
#
# Input:
#     None
#
# Results:
#     SUCCESS, if the test case executed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub RunTest
{
   my $self = shift;
   $self->SUPER::RunTest();
}


########################################################################
#
# Cleanup--
#     Method to do test session cleanup
#
# Input:
#     lastTest: boolean flag to indicate if this is a last test in
#               a session (Optional)
#
# Results:
#     SUCCESS, if the test session is cleaned up successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Cleanup
{
   my $self     = shift;
   my $lastTest = shift; # TODO: resource cache fix
   my $testbed  = $self->{testbed};
   my $testResult = $self->{result};
   if ($testbed->SessionCleanUp($testResult) eq FAILURE) {
      $vdLogger->Error("Test session cleanup failed");
      VDSetLastError(VDGetLastError());
      #return FAILURE;
   }
   my $result = $testbed->CheckMachinesHealth();
   if ($result ne "SUCCESS") {
      $vdLogger->Error("Check machines health returned failure ");
      # ABORT?
   }

   #
   # If lastTest is TRUE, then call cleanup entire testbed.
   # TBD: whether to move this to Session.pm
   #
   if ($lastTest &&
       ((not defined $self->{'noCleanup'}) ||
        ($self->{'noCleanup'} eq 0))) {
      if ($testbed->TestbedCleanUp($testResult) eq FAILURE) {
         $vdLogger->Error("Test session cleanup failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# ProcessUserConfigHash--
#     Method to convert session hash into a format that is required
#     by this package
#
# Input:
#     None
#
# Results:
#     SUCCESS, if session hash is converted successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ProcessUserConfigHash
{
   my $self = shift;
   #TODO: implement this when TestSessionv2.pm is implemented
}


########################################################################
#
# CreateTestbedSpec--
#     Method to create testbed spec based on userconfig hash and
#     testcase hash. This method is responsible for filling
#     the details such as host ip, vm template, vnic/vmnic drivers etc
#     from userconfig hash into the testcase hash.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed spec is created successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateTestbedSpec
{
   my $self          = shift;

   my $tcRef      = $self->{testcaseHash};
   my $tb         = $self->{testbed};
   my $hostlist   = $self->{hostlist};
   my $vmlist     = $self->{vmlist};
   my $pswitch    = $self->{pswitch};
   my $vdnetOptions  = $self->{vdnetOptions};
   my $sut           = $self->{sut};
   my @helper        = @{$self->{helper}};

   #
   # There are multiple hashes initiated and updated as part of a vdnet session.
   # "userConfigHash" is the main hash which contains all the information provided
   # by the user regarding the testbed. userConfigHash is composed primarily based
   # on the command line options of vdnet. User might also point to a pre-defined
   # test configuration template using --testconfig command line option. Overall,
   # userConfigHash will have information about the testbed to use. The contents
   # of this hash will not be updated once written.
   #
   # Another important hash is "machineHash". userConfigHash contains testbed
   # information which might be very generic. Especially, when running multiple
   # tests together. By generic, it means that user can given host list and vms to
   # use, but it is required to compose the testbed parameters specific to a test
   # case. For example, one example might require 3 VMs with 2 VMs on host1 and 1
   # VM on host2. Another test case might require just 1 VM on host1 and 2 VMs on
   # host2. In these cases, the framework will compose the actual testbed params
   # and store in machineHash for each test case.
   #
   # Next one is "resourceCache" array whose elements are hash references to
   # different machine details (especially VMs). With machineHash composed for
   # every test from the generic userConfigHash, we shouldn't be re-creating VMs
   # for every test case. This increased time and becomes innefficient. Therefore,
   # after every test case, all the machines used are stored in resourceCache
   # array such that the next test case can look up into the resourceCache and
   # re-use some of the existing that match the given requirements criteria of a
   # test case.
   #

   my %userConfigMachines = ();
   my $userConfigHash = \%userConfigMachines; # reference to userConfigMachines
   my %macHash = ();
   my $machineHash = \%macHash; # reference to macHash
   $self->{machineHash} = $machineHash;

   #
   # If user provides --sut and --helper details at command then they will take
   # the precedence over --hostlist and --vmlist parameters. This is to make sure:
   # - vdnet is backward compatiable
   # - to allow users to given exact testbed details which cannot be covered by
   #   the algorithm to automatically compose machineHash from userConfigHash.
   #
   # So, if $sut is defined, then assume user has provided exact testbed details.
   # Note that the testbed details composed in this case will be applied to ALL
   # the test cases in a vdnet session. If the given testbed details (using --sut
   # and --helper) params does not meet every test case requirements, then it is
   # user error. This is opposite to given testbed details using --hostlist
   # --vmlist parameters, where testbed details will be composed from the given
   # list of resources.
   #
   if (defined $sut) {
      if (FAILURE eq FillMachineEntries($userConfigHash, "SUT", $sut)) {
         $vdLogger->Error("Processing machine entry failed " . VDGetLastError());
         $vdLogger->Error("$VDNetLib::Common::VDNetUsage::usage");
         return FAILURE;
      }

      my $entry = 0;
      for (my $i = 0; $helper[$i]; $i = $i + 1) {
         my $machine = $i + 1;
         $entry = $helper[$i];
         $machine = "helper" . $machine;
         if (FAILURE eq FillMachineEntries($userConfigHash, $machine, $entry)) {
            $vdLogger->Error("Processing machine entry failed " . VDGetLastError());
            $vdLogger->Error("$VDNetLib::Common::VDNetUsage::usage");
            return FAILURE;
         }
      }
   }

   #
   # Get the list of hosts (generic set that applies to all test cases) to be used
   # for the given vdnet session.
   #
   if (defined $hostlist) {
      $hostlist =~ s/\s|\n//g;
      my @hosts = split(/,/, $hostlist);
      foreach my $host (@hosts) {
         $userConfigHash->{hosts}{$host}{ip} = $host;
      }
   }


   #
   # Get the VM specifications i.e. generic SUT and helper VMs that applies to all
   # test cases in the given vdnet session.
   #
   if (defined $vmlist) {
      $vmlist =~ s/\s|\n//g;
      my @vms = split(/,/, $vmlist);
      foreach my $entry (@vms) {
         #
         # The format for --vmlist is "sut=<>,helper=<>"
         #
         my ($machine, $vm) = split(/=/, $entry);
         $machine =~ s/sut/SUT/i;
         $userConfigHash->{vms}{$machine}{name} = $vm;
      }
   }

   if (defined $pswitch) {
      $userConfigHash->{pswitch}{ip} = $pswitch;
   }

   # TODO - validate list of supported options

   if (defined $vdnetOptions) {
      if ($vdnetOptions =~ /disablearp/i) {
         $vdLogger->Info("Disable arp option given");
         $self->{"disableARP"} = 1;
      }
      if ($vdnetOptions =~ /usevix/i) {
         $vdLogger->Info("Use VIX API option given");
         $self->{"useVIX"} = 1;
      }
      if ($vdnetOptions =~ /notools/i) {
         $vdLogger->Info("Ignore VMware Tools upgrade option given");
         $self->{"noTools"} = 1;
      }
      if ($vdnetOptions =~ /dontupgstafsdk/i) {
         $vdLogger->Info("Don't upgrade to latest STAF SDK");
         $self->{"dontUpgSTAFSDK"} = 1;
      }
   }

   my $testHost;
   if (defined $userConfigHash->{SUT}{host}){
      $testHost = $userConfigHash->{SUT}{host};
   } elsif (defined $userConfigHash->{SUT}{ip}) {
      $testHost = $userConfigHash->{SUT}{ip};
   } else {
      my $userConfigHosts = $userConfigHash->{hosts};
      my $host = ((keys %{$userConfigHosts})[0]);
      if (defined $userConfigHash->{hosts}{$host}{ip}) {
         $testHost = $userConfigHosts->{$host}->{ip};
      }
   }
   my $testMachineHash;
   #
   # To begin with, assign userConfigHash to machineHash.
   # But only the definition of specific host value in SUT will decide
   # whether to use the same machineHash for all test cases or compose
   # machineHash for every test case.
   #
   $machineHash = $userConfigHash;

   $vdLogger->Debug("UserConfigHash:" . Dumper($userConfigHash));

   #
   # If the user did not provide specific values for --sut and --helper options
   # but specified the hostlist, then compose the testbed parameters for the
   # test case based on the rules defined in the test case hash.
   #
   if (not defined $machineHash->{SUT}{host}) {
      $machineHash = {};
      if (FAILURE eq FillMachinesBasedOnRules($machineHash, $tcRef,
                                              $userConfigHash)) {
         $vdLogger->Error("Failed to fill machineHash based on rules");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # Make sure that the user testbed parameters match the "Parameters"
   # key in the test case hash. If it does not match, abort.
   #
   my $validation = $self->ValidateMachineParams($tcRef, $machineHash,
                                                 $userConfigHash);
   if ($validation eq SKIP) {
      $vdLogger->Warn("One of the custom configuration parameter can't ".
		      "be applied for this testcase. Hence skipping...");
      return FAILURE;
   }

   if ($validation eq FAILURE) {
      $vdLogger->Error("Command line validation returned error");
      $vdLogger->Error(VDGetLastError());
      $vdLogger->Abort("Test aborted");
      return FAILURE;
   }

   $vdLogger->Debug("machineHash after validation" . Dumper($machineHash));
   $vdLogger->Debug("Session information " . Dumper($self));

   #
   # Next step is to see the composed machineHash has machines that are already
   # part of resourceCache array. If a machine exists in resourceCache that
   # matches all the requirements of the current test case, then re-use
   # the same machine. Please note that the resourceCache array will
   # be empty for the first test.
   #
   my $testcaseMachinesReq =  $tcRef->{Parameters};
   foreach my $machine (keys %{$testcaseMachinesReq}) {
      if ($machine !~ /sut|helper/i) {
         next;
      }
      if (not defined $self->{'Parameters'}{$machine}{vmID}) {
         $self->{'Parameters'}{$machine}{vmID} =
            $self->{'Parameters'}{$machine}{vm};
      }

      my $existingMachine = $tb->CheckMachineExistsInCache(
                                            $self->{'Parameters'}{$machine},
                                            $machine);
      if (not defined $existingMachine) {
         $self->{Parameters}{$machine}{existingResource} = 0;
      } elsif ($existingMachine ne FAILURE) { # exists
         $vdLogger->Debug("Resource cache has entry that matches $machine");
         $self->{Parameters}{$machine}{existingResource} = 1;
         $self->{Parameters}{$machine}{resourceCacheIndex} = $existingMachine;
         if (defined $self->{Parameters}{$machine}{vm}) {
            # update VM information only if test case parameters asks for it
            $self->{Parameters}{$machine}{vm}   =
               @{$tb->{resourceCache}}[$existingMachine]->{vmx};
            $self->{Parameters}{$machine}{vmID} =
               @{$tb->{resourceCache}}[$existingMachine]->{vmID};
         }
         my $refToHash = @{$tb->{resourceCache}}[$existingMachine];
         $refToHash->{available} = 0; # updating the actual resourceCache,
                                         # not any variable in local scope
         $refToHash->{healthStatus} = undef; # reset healthStatus
      } else {
         $vdLogger->Error("Failed to check if machine exist in resource cache");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # Double-check if the latest sessionHash meets the rules of the test case.
   # TODO: this block can be removed since machineHash/sessionHash is composed
   # based on the rules.
   #
   $vdLogger->Debug("Updated Session information " . Dumper($self));
   my $ruleList = $tcRef->{Parameters}{Rules};
   if (defined $ruleList) {
      my $result = $self->CheckRules($ruleList);
      if ($result eq FAILURE) {
         $vdLogger->Error("Error verifying rules");
         return FAILURE;
      }
   }
}


########################################################################
#
# FillMachinesBasedOnRules--
#      Routine to fill machineHash using the userConfigHash based on the
#      rules defined in the test case hash. This routine is important to
#      compose the machineHash for each test case when user did not
#      provide specific testbed details for vdnet session.
#      (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#      machineHash    : machineHash which needs to be filled based on
#                       rules (Required)
#      testcaseHash   : testcase hash which has the rules (required)
#      userConfigHash : userConfigHash which has generic testbed
#                       parameters for the entire vdnet session
#
# Results:
#      SUCCESS, if the machineHash is filled based on test rules;
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub FillMachinesBasedOnRules
{
   my $machineHash = shift;
   my $testcaseHash = shift;
   my $userConfigHash = shift;
   my $ruleList = $testcaseHash->{Parameters}{Rules};

   my $rulesArrayRef;

   #
   # Get the rules array from the given test case hash.
   #
   if (defined $ruleList) {
      $rulesArrayRef = GetRulesArray($ruleList);
   }

   #
   # If NO rules defined, then take the default values from the
   # userConfigHash. One of the default assumption is that if 2 hosts are
   # defined, then both the hosts will be used for that test case.
   #
   if ((not defined $rulesArrayRef) || (!@{$rulesArrayRef})) {
      $vdLogger->Debug("Rules array is empty");
      my $requiredMachinesList = $testcaseHash->{Parameters};
      foreach my $machine (keys %$requiredMachinesList) {
         if ($machine !~ /sut|helper/i) {
            next;
         }
         if (not defined $machineHash->{$machine}{host}) {
            my $host =  FillEntryFromUserConfig($machine, "host", $userConfigHash);
            $machineHash->{$machine}{host} = $host;
         }
      }
      return SUCCESS; # return here itself since no rules are defined
   }

   my $userConfigHosts;

   #
   # If rules are defined, then the following procedure is followed:
   # - take the first rule
   # - take the LHS of the first rule
   # - check the component (vm/host/pswitch) on LHS of the rule is defined,
   #   if not defined, pick a default value
   # - now proceed to the RHS component of the rule
   # - from all possible value of RHS component, pick the first value that
   #   satisfies the condition with LHS component.
   # - move on to the next rule and the repeat the steps above.
   #

   foreach my $rulesHash (@{$rulesArrayRef}) {
      # The following block fills the LHS component of the rule
      my $leftMachine = $rulesHash->{leftMachine};
      my $rightMachine = $rulesHash->{rightMachine};
      my $leftComponent = $rulesHash->{leftComponent};
      my $rightComponent = $rulesHash->{rightComponent};

      if (not defined $machineHash->{$leftMachine}{$leftComponent}) {
         if ($rulesHash->{leftComponent} =~ /host/i) {
            #my $leftMachine = $rulesHash->{leftMachine};
            $userConfigHosts = $userConfigHash->{hosts};
            my $selectedHost = ((keys %{$userConfigHosts})[0]);
            $machineHash->{$leftMachine}{host} =
               $userConfigHash->{hosts}{$selectedHost}{ip};

            if (not defined $machineHash->{$leftMachine}{host}) {
               $vdLogger->Error("$leftMachine host not defined based on " .
                                "the rules");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         } else {
            $vdLogger->Error("Unknown component $rulesHash->{leftComponent} " .
                             "in rules");
         }
      }
      # now fill the right side component
      if (not defined $machineHash->{$rightMachine}{$rightComponent}) {
         if ($rulesHash->{rightComponent} =~ /host/i) {
            # By now left component should be defined
            $userConfigHosts = $userConfigHash->{hosts};
            foreach my $host (keys %{$userConfigHosts}) {
               if ($rulesHash->{condition} eq "eq") {
                  if ($userConfigHosts->{$host}{ip} eq
                      $machineHash->{$leftMachine}{host}) {
                     $machineHash->{$rightMachine}{host} =
                        $userConfigHosts->{$host}{ip};
                     last;
                  }
               } else {
                  if ($userConfigHosts->{$host}{ip} ne
                      $machineHash->{$leftMachine}{host}) {
                     $machineHash->{$rightMachine}{host} =
                        $userConfigHosts->{$host}{ip};
                     last;
                  }
               }
            } # end of for loop to cover "host" component
            # TODO - extend other components when they are introduced in rules
            if (not defined $machineHash->{$rightMachine}{host}) {
               $vdLogger->Error("$rightMachine host not defined based " .
                                "on the rules");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         } # end of the condition to check "host" component
      } # end of RHS of the rule
   } # end of all rules
   return SUCCESS;
}


########################################################################
#
# FillMachineEntries --
#      This method fills the machine details (SUT/helper<x>) from the
#      given command line options in a hash with each key being name
#      of the machine (SUT/helper<x>) recognized by testbed .
#      (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#      machineHash: reference to hash to store machine details (Required)
#      machine - SUT or helper<x> where x is an integer (Required)
#      entries - string with comma separated values in the format given
#                below: (all these values are optional)
#                prefixDir=<prefixDir>,
#                cache=<cacheDir>,
#                sync=<0|1>,
#                vm=<ip address or vmx path or vm name>,
#                host=<host ip address>,
#                vnic=<e1000|e1000e|vmxnet2|vmxnet3|vlance|ixgbe|bnx2>,
#                switch=<vss|vds>,
#                vmnic=<ixgbe|bnx2>,
#                For more details on machine entries,
#               refer to VDNetLib::Common::VDNetUsage.
#
# Results:
#      "SUCCESS" - if valid values are given and machine details filled
#                  successfully;
#      "FAILURE" - in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FillMachineEntries
{
   my $machineHash   = shift;
   my $machine = shift;
   my $entries = shift;

   my $supportedKeys = VDNetLib::Common::GlobalConfig::MACHINE_ENTRIES;
   # split the string with de-limiter as comma (,)
   my @temp = split(/,/,$entries);

   foreach my $item (@temp) {
      # remove any space before after ,
      $item =~ s/\s$|^\s//;
      if ($item =~ /=/) {
         # split the string with de-limiter as =
         my ($key, $value) = split(/=/,$item);
         $key = lc($key);

         if ($supportedKeys !~ / $key /) {
            $vdLogger->Error("Unknown entry \"$key\" passed in command line " .
                             "for $machine");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         $machineHash->{$machine}{$key} = $value;
      } elsif ($item =~ /:/ && $item !~ /=/) { #todo- check digit
         # The else condition above is for backward compatibility to handle
         # command line option given in the format <vm>:<host>
         #
         my ($vm, $host) = split(/:/,$item);
         $machineHash->{$machine}{'vm'} = $vm;
         $machineHash->{$machine}{'host'} = $host;
      } else {
         $machineHash->{$machine}{'host'} = $item;
      }
   }

   my $vm = $machineHash->{$machine}{'vm'};
   if (defined $vm) {
      if ("SUCCESS" eq VDNetLib::Common::Utilities::IsValidIP($vm)) {
         # If the value given "vm" is ip address, then update the ip address
         $machineHash->{$machine}{ip} = $vm;
         $machineHash->{$machine}{vmx} = undef;
      } else {
         $machineHash->{$machine}{vmx} = $vm;
         $machineHash->{$machine}{ip} = undef;
         VDCleanErrorStack(); # IsValidIP() above sets error, clear that.
      }
   }

   if (not defined  $machineHash->{$machine}{host}) {
      $vdLogger->Error("host name is not defined for $machine");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Make sure the value for each component like vnic, vmnic, switch
   # is under supported list of values
   #
   foreach $machine (keys %$machineHash) {
      my $machineEntries = $machineHash->{$machine};
      foreach my $entry (keys %$machineEntries) {
         if ($entry !~ /vnic/i && $entry !~ m/^switch$/i) {
            next;
         }
        my $temp = 'VDNetLib::Common::GlobalConfig::supported' . $entry;
        my $supportList = eval($temp);
        my $value = $machineHash->{$machine}{$entry};

        # TODO - implement the feature to accept direct values for vmnic,switch,vnic
        # For example, accept eth0, eth1, etc. for vnic. This will prevent
        # discovering adapters based on a particular type and save some
        # run-time.
        #
        if ($supportList !~ / $value /i) {
           $vdLogger->Error("Unknown type $value given for $entry");
           VDSetLastError("EINVALID");
           return FAILURE;
        }
      }
   }
   return $machineHash;
}


########################################################################
#
# ValidateMachineParams --
#      This routine validates the given command line options, retrieves
#      the session Parameters (value of Parameters key from test
#      case hash), updates the session Parameters value with the
#      command line options (if needed).
#      (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#      testcaseHash: reference to test case hash (Required)
#      machineHash: reference to the hash containing details about
#                   SUT and helper command line parameters (Required)
#
# Results:
#      "SUCCESS", if the command line parameters are validated against
#                 session's Parameters and meets requirements;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ValidateMachineParams
{
   my $self         = shift;
   my $testcaseHash = shift;
   my $machineHash  = shift;
   my $userConfigHash = shift;
   if (not defined  $testcaseHash->{'Parameters'}) {
      $vdLogger->Error("Parameters key not defined in test case hash");
      return SUCCESS;
   }

   # if a test requires specific vds version.
   if (defined $testcaseHash->{Parameters}{vdsversion}) {
      my $version = $testcaseHash->{Parameters}{vdsversion};
      if ($version !~ m/4.0|4.1.0|5.0.0|5.1.0/i) {
         $vdLogger->Error("Invalid vds version $version specified");
         return FAILURE;
      }
      $self->{Parameters}{version} = $version;
   }

   #
   # Decide the testbed components needed based on the command line options
   # given.
   #
   # First, clear the session if it has unwanted machine details for a test
   # case
   #
   foreach my $machine (keys %$machineHash) {
      if (not defined $testcaseHash->{Parameters}{$machine}) {
         delete $self->{Parameters}{$machine};
      }
   }

   my $machinesList = $testcaseHash->{Parameters};

   #
   # The following block checks if the given hosts are different. In that case,
   # to ensure connectivity between them vmnic/pnic is mandatory, so adding
   # that to the test case hash Parameters.
   #
   my $needVMNic = 0;
   foreach my $machine (keys %$machinesList) {
      if ((defined $machineHash->{$machine}) &&
         $machineHash->{$machine}{host} ne $machineHash->{SUT}{host}) {
         $needVMNic = 1;
      }
   }
   #
   # foreach block to go through each machine (SUT,helper1, helper2,...,
   # helper<x>)
   #
   foreach my $item (keys %$machinesList) {
      my $machine = ($item =~ /SUT|helper/) ? $item : undef;
      if (not defined $machine) {
         # this is not either SUT or helper related key, so skip it
         next;
      }

      if (not defined $machineHash->{$machine}) {
         $vdLogger->Error("$machine related parameter expected at command line");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      #
      # cache, prefixdir, sync command line options are generic to all test
      # cases in session, Updating the given the command line option in
      # $session hash
      #
      if (defined $machineHash->{$machine}{tools}) {
            $self->{'Parameters'}{$machine}{tools} =
               $machineHash->{$machine}{tools};
      }

      if (defined $machineHash->{$machine}{cache}) {
            $self->{'Parameters'}{$machine}{cache} =
               $machineHash->{$machine}{cache};
      }

      if (defined $machineHash->{$machine}{prefixdir}) {
            $self->{'Parameters'}{$machine}{prefixdir} =
               $machineHash->{$machine}{prefixdir};
      }

      if (defined $machineHash->{$machine}{sync}) {
            $self->{'Parameters'}{$machine}{sync} =
               $machineHash->{$machine}{sync};
      }

      if ($needVMNic) {
         # add vmnic as part of test case parameter is needVMNic is not 0.
         if (not defined $testcaseHash->{Parameters}{$machine}{'vmnic'}) {
            $testcaseHash->{Parameters}{$machine}{'vmnic'} = ["any:1"];
         }
      }

      if (defined $testcaseHash->{Parameters}->{$machine}->{'vmknic'}) {
         if (not defined $testcaseHash->{Parameters}->{$machine}->{'switch'}) {
            # using the default switch type as "vss"
            $testcaseHash->{Parameters}{$machine}{'switch'} = ["vss:1"];
         }
      }
      #
      # It is not necessary to enter all testbed components in test case hash's
      # "Parameters" field. For instance, if vnic details are provided, then it
      # is obvious that VM is required in the test bed. Such dependencies are
      # handled in the following block.
      #
      # vnic is dependent on switch, vm, host; host is mandatory anyways
      #
      if (defined $testcaseHash->{Parameters}->{$machine}->{'vnic'}) {
         if (not defined $testcaseHash->{Parameters}->{$machine}->{'switch'}) {
            # using the default switch type as "vss"
            $testcaseHash->{Parameters}{$machine}{'switch'} = ["vss:1"];
         }
         if (not defined $testcaseHash->{Parameters}->{$machine}->{'vm'}) {
            $testcaseHash->{Parameters}->{$machine}->{'vm'} = 1;
         }
      }
      my $datastoreType =
         $testcaseHash->{Parameters}{$machine}{'datastoreType'};
      $testcaseHash->{Parameters}{$machine}{'datastoreType'} =
         (defined $datastoreType) ? $datastoreType : "local";

      # vm, vmnic and switch are dependent on host
      if (defined $testcaseHash->{Parameters}->{$machine}->{'vm'} ||
          defined $testcaseHash->{Parameters}->{$machine}->{'switch'} ||
          defined $testcaseHash->{Parameters}->{$machine}->{'vmnic'}) {
         if (not defined $testcaseHash->{Parameters}->{$machine}->{'host'}) {
            $testcaseHash->{Parameters}->{$machine}->{'host'} = 1;
         }
      }

      my $tcMachineEntries = $testcaseHash->{Parameters}->{$machine};
      #
      # Now take each test bed component (vnic, switch, vm, host) of SUT/helper
      #
      foreach my $entry (keys %$tcMachineEntries) {
         if (defined $testcaseHash->{Parameters}->{$machine}{$entry}) {
            #
            # Check if the corresponding entry is available in command line
            # parameters.
            #
            if (not defined $machineHash->{$machine}{$entry}) {
               #
               # If a testbed component is not defined and
               # if it is vm, host or physical switch, then throw error
               # since they are mandatory for the given session.
               #
               if ($entry eq "vm" || $entry =~ /host/i || $entry =~ /pswitch/i ) {
                  my $value = FillEntryFromUserConfig($machine, $entry,
                                                      $userConfigHash);
                  if (not defined $value and $entry !~ /pswitch/i) {
                     $vdLogger->Error("$entry info expected for $machine " .
                                      "at command line");
                     VDSetLastError("ENOTDEF");
                     return FAILURE;
                  } else {
                     $machineHash->{$machine}{$entry} = $value;
                     $self->{'Parameters'}{$machine}{$entry} = $value;
                  }
               } else {
                  # If the testbed component is other than vm, host, then
                  # update the session's Parameter with the value in the test
                  # case hash's default value for the testbed component.
                  #
                  $self->{'Parameters'}{$machine}{$entry} =
                     $testcaseHash->{Parameters}->{$machine}{$entry};
               }
            } else {
               #
               # If the testbed component in testcase hash is provided
               # at command line options, and if the component is vm, host
               # or physical switch then use the value given at command line.
               #
               if ($entry eq "vm" || $entry =~ /host/i || $entry =~ /pswitch/i) {
                  $self->{'Parameters'}{$machine}{$entry} =
                     $machineHash->{$machine}{$entry};
               } else {
                  #
                  # If the component is other than vm/host and "Override"
                  # key is set to be 1 (default) in the test case hash,
                  # then update the session's value for the testbed component
                  # with value provided at command line.
                  #
                  if (defined $testcaseHash->{"Parameters"}{Override} &&
                      !$testcaseHash->{"Parameters"}{Override}) {

		     if ($entry !~ /vnic/i) {
                        $self->{'Parameters'}{$machine}{$entry} =
				$testcaseHash->{Parameters}->{$machine}{$entry};
			$vdLogger->Warn("Override option is disabled");
			next;
		      } else {
			 my @testComponent = @{$testcaseHash->{Parameters}->{$machine}{$entry}};
			 my $newType = lc($machineHash->{$machine}{$entry});

			 $testComponent[0] =~ /(.*):.*/;
			 if ($newType eq $1) {
			    #
			    # Though the override option is disabled,  the
			    # user has specified the same vnic type as the
			    # one present in the testcase hash.   Hence no
			    # action is required. Simply moving on to next
			    # key.
			    #
			    $self->{'Parameters'}{$machine}{$entry} =
				$testcaseHash->{Parameters}->{$machine}{$entry};
			    next;
			 } else {
			    $vdLogger->Warn("Override option is disabled. " .
					    "Hence can't override the existing vnic type: \"$1\" " .
					    "with \"$newType\". Skipping this testcase...");
			    return SKIP;
			 }
		     }
                  }
                  my $temp = $machineHash->{$machine}{$entry};
                  my $arrRef = $testcaseHash->{Parameters}->{$machine}{$entry};
                  my @testComponent = @$arrRef;
                  if ($entry =~ /vmnic/i) {
                     if (ref($testComponent[0]) eq "HASH") {
                        $testComponent[0]->{'driver'} = $temp;
                     }
                  } else {
                     $testComponent[0] =~ s/.*:/$temp:/;
                  }
                  $vdLogger->Info("Updating the component $entry as " .
                                  $temp . " for $machine");
                  $testcaseHash->{Parameters}->{$machine}{$entry} = \@testComponent;
                  $self->{'Parameters'}{$machine}{$entry} =
                     $testcaseHash->{Parameters}->{$machine}{$entry};
               }
            }
         }
      }
      #
      # if a switch type required for the test case is vds, then
      # vc is needed.
      #
      if (defined $self->{Parameters}{$machine}{'switch'}) {
         my @switchArray = @{$self->{Parameters}{$machine}{'switch'}};
         foreach my $item (@switchArray) {
            if ($item =~ /vds/) {
               if (not defined $self->{Parameters}{vc}) {
                  $vdLogger->Error("VC required for using switch type vds");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
         }
      }
   }
   #
   # Read the "Rules" key under Parameters hash to check for the given
   # input by the user and ensure it matches the testbed requirements of
   # a test case.
   #
   my $ruleList = $testcaseHash->{Parameters}{Rules};
   if (defined $ruleList) {
      my $result = $self->CheckRules($ruleList);
      if ($result eq FAILURE) {
         $vdLogger->Error("Error verifying rules");
         VDSetLastError(VDGetLastError());
      }
   }
   return SUCCESS;
}


########################################################################
#
# CheckRules--
#      Routine to check if the given sessionHash meets the
#      given rules.
#      (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#     ruleList: comma separated rules (Required)
#               rules are defined in test case hash
#
# Results:
#     SUCCESS, if the session hash satisfies the rules defined;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub CheckRules {
   my $self     = shift;
   my $ruleList = shift;

   if (not defined $ruleList) {
      $vdLogger->Error("Rules not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   #
   # Rules is a comma separated list.
   # Currently, supported operators are == and !=
   # The rules should only make use of testbed components in the
   # terms understood by vdnet. For example, machines should be
   # represented as SUT or helper<x> where x is an integer.
   # host, vm, vnic, vmnic, vmknic, pswitch are other supported
   # data in a rule.
   #
   my @rulesArray = split(/,/,$ruleList);
   foreach my $rule (@rulesArray) {
      $rule =~ s/^\s|\s$//;
      my ($left, $right) = split(/==|\!=/,$rule);
      # Get the left and right hand side of a rule
      $left =~ s/^\s|\s$//;
      $right =~ s/^\s|\s$//;
      if ((not defined $left) && (not defined $right)) {
         $vdLogger->Error("Unknown rule $rule provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      #
      # Get the testbed components part of the rules defintion on
      # both left and right side.
      #
      my ($leftMachine, $rightMachine, $leftComponent, $rightComponent);
      if ($left =~ /(\w+)\.(\w+)/){
         $leftMachine = $1;
         $leftComponent = $2;
      }
      if ($right =~ /(\w+)\.(\w+)/){
         $rightMachine = $1;
         $rightComponent = $2;
      }

      #
      # Check the corresponding parameters in the session hash
      # and see if the rules match
      #
      if ($rule =~ /==/) {
         if ($self->{Parameters}{$leftMachine}{$leftComponent} ne
             $self->{Parameters}{$rightMachine}{$rightComponent}) {
            $vdLogger->Error("Machine $leftMachine $leftComponent should " .
                             "be equal to Machine $rightMachine " .
                             $rightComponent);
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      } elsif ($rule =~ /!=/) {
         if ($self->{Parameters}{$leftMachine}{$leftComponent} eq
             $self->{Parameters}{$rightMachine}{$rightComponent}) {
            $vdLogger->Error("Machine $leftMachine $leftComponent should " .
                             "NOT be equal to Machine $rightMachine " .
                             $rightComponent);
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Unknown expression given in $rule");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } # end of for loop
   return SUCCESS;
}


########################################################################
#
# GetRulesArray--
#     Routine to convert the given comma separated list of rules into
#     an array of hash, where each hash is one rule.
#     (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#     ruleList: comma separated list of rules (Required)
#               Example: SUT.host == helper1.host,
#                        helper1.host != helper2.host
#
# Results:
#     Reference to an array where each element is reference to a hash.
#     The hash has the following keys:
#     leftMachine   : SUT/helper<x>
#     rightMachine  : SUT/helper<x>
#     leftComponent : vm/host/prefixdir
#     rightComponent: vm/host/prefixdir
#     condition     : == or !=
#
#     FAILURE, in case of any error.
#
# Side effects:
#     None
#
########################################################################

sub GetRulesArray {
   my $ruleList = shift;
   my @rules;
      #
      # Rules can be a comma separated list.
      #
      # Currently, supported operators are == and !=
      # The rules should only make use of testbed components in the
      # terms understood by vdnet. For example, machines should be
      # represented as SUT or helper<x> where x is an integer.
      # host, vm, vnic, vmnic, vmknic, pswitch are other supported
      # data in a rule.
      #
      my @rulesArray = split(/,/,$ruleList);
      foreach my $rule (@rulesArray) {
         my $rulesHash = {
            'leftMachine' => undef,
            'leftComponent' => undef,
            'rightMachine' => undef,
            'rightComponent' => undef,
            'condition'     => undef,
         };

         $rule =~ s/^\s|\s$//;
         my ($left, $right) = split(/==|\!=/,$rule);
         # Get the left and right hand side of a rule
         $left =~ s/^\s|\s$//;
         $right =~ s/^\s|\s$//;
         if ((not defined $left) && (not defined $right)) {
            $vdLogger->Error("Unknown rule $rule provided");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         #
         # Get the testbed components part of the rules defintion on
         # both left and right side.
         #
         if ($left =~ /(\w+)\.(\w+)/){
            $rulesHash->{leftMachine} = $1;
            $rulesHash->{leftComponent} = $2;
         }
         if ($right =~ /(\w+)\.(\w+)/) {
            $rulesHash->{rightMachine} = $1;
            $rulesHash->{rightComponent} = $2;
         }

         #
         # Check the corresponding parameters in the session hash
         # and see if the rules match
         #
         if ($rule =~ /==/) {
            $rulesHash->{condition} = "eq";
         } elsif ($rule =~ /!=/) {
            $rulesHash->{condition} = "ne";
         } else {
            $vdLogger->Error("Unknown expression given in $rule");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         push(@rules, $rulesHash);
      }
      return \@rules;
}


########################################################################
#
# FillEntryFromUserConfig--
#      Routine to get value for the given entry using the userConfigHash.
#      The entry could be "vm" or "host" or "pswitch". This routine is
#      mainly used when user did not give specific sut/helper details
#      for the vdnet session.
#     (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#      machine : SUT/helper<x> (Required)
#      entry   : vm/host/pswitch (Required)
#      userConfigHash: userConfigHash which has common values for host,
#                      vm and pswitch (Required)
#
# Results:
#      A scalar string value from the userConfigHash corresponding to
#      the given entry and machine;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FillEntryFromUserConfig
{
   my $machine        = shift;
   my $entry          = shift;
   my $userConfigHash = shift;

   if ((not defined $machine) || (not defined $entry) ||
       (not defined $userConfigHash)) {
      $vdLogger->Error("machine and/or entry and/or userConfigHash " .
                       "not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $selectedValue;
   if ($entry eq "vm") {
      my $userConfigVMs = $userConfigHash->{vms};
      if ($machine =~ /SUT/i) {
         $selectedValue = $userConfigVMs->{SUT}{name};
      } elsif ($machine =~ /helper/i) {
         $selectedValue = $userConfigVMs->{helper}{name};
      }
   } elsif ($entry eq "host") {
      my $userConfigHosts = $userConfigHash->{hosts};
      my $selectedHost;
      #
      # if the given machine is helper, if 2 hosts are defined, then the second
      # host will be used for helper.
      #
      $selectedHost = ((keys %{$userConfigHosts})[0]);
      if ($machine =~ /helper/i) {
         if (defined ((keys %{$userConfigHosts})[1])) {
            $selectedHost = ((keys %{$userConfigHosts})[1]);
         } else {
            $selectedHost = ((keys %{$userConfigHosts})[0]);
         }
      }
      $selectedValue = $userConfigHash->{hosts}{$selectedHost}{ip};
   } elsif ($entry eq "pswitch") {
      $selectedValue = $userConfigHash->{pswitch}{ip};
      # pswitch is not a mandatary condition
      if (not defined $selectedValue){
         return undef;
      }
   } else {
      $vdLogger->Error("Unknown entry $entry given for " .
                       "FillEntryFromUserConfig method");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $selectedValue) {
      $vdLogger->Error("Entry $entry for $machine is not defined " .
                       "in user config hash");
      $vdLogger->Error(Dumper($userConfigHash));
      return FAILURE;
   }
   return $selectedValue;
}


########################################################################
#
# ProcessTestCaseHash--
#     Routine to process test case hash. For example, resolve any
#     key/values
#     (THIS METHOD IS INTERNAL TO THIS PACKAGE)
#
# Input:
#     Reference to test case hash
#
# Results:
#     SUCCESS, if the test case hash is processed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ProcessTestCaseHash
{
   my $self  = shift;
   my $tcRef = shift;

   my $parametersHash = $tcRef->{'Parameters'};

   foreach my $machine (keys %$parametersHash) {
      if ($machine !~ /sut|helper/i) {
         next;
      }
      if ($machine =~ /(.*)\[(.*)\]/) {
         my $machinePrefix = $1;
         my $range = $2;

         if ((not defined $machinePrefix) || (not defined $range)) {
            $vdLogger->Error("Invalid machine name provided : $machine");
            VDSetLastError("EINVALID");
            return FAILURE;
         }

         my ($min, $max) = split(/-/, $range);

         # set max value same as min if max is not defined
         $max = (defined $max) ? $max : $min;

         for (my $index = $min; $index <= $max; $index++) {
            my $newMachine = $machinePrefix . $index;
            $tcRef->{Parameters}{$newMachine} =
                  $tcRef->{Parameters}{$machine};
         }
         # delete the original key which has beed resolved
         delete $tcRef->{Parameters}{$machine};
      }
   }
   $vdLogger->Debug("Updated test case hash: " . Dumper($tcRef->{Parameters}));
   return SUCCESS;
}
1;
