########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::VDNetv2;

#
# This package inherits VDNetLib::TestSession::TestSession Class.
# It stores attributes and implements method to run vdnet tests
# version 2.
#
#
use strict;
use warnings;

use base 'VDNetLib::TestSession::TestSession';

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use Storable 'dclone';
use YAML::XS qw(LoadFile);
use VDNetLib::Common::Utilities;
use VDNetLib::Testbed::Testbedv2;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);

use constant INVENTORYCOMPONENTS => {
   'vc'   => ['folder', 'datacenter', 'cluster', 'vds', 'dvportgroup'],
   'host' => ['vmnic', 'vmknic', 'portgroup', 'vss', 'netstack', 'ovs',
              'nvpnetwork', 'pswitchport', 'disk'],
   'vm'   => ['cpu', 'memory', 'disk', 'vnic', 'pci'],
   'vsm'  => ['datacenter', 'cluster', 'networkscope', 'vwire'],
   'pswitch' => [],
   'powerclivm' => [],
   'testinventory' => [],
   'authserver'  => [],
   'nsxmanager' => [],
   'nsxcontroller' => [],
   'nsxedge' => [],
   'logserver' => [],
};
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;
use constant TRUE => VDNetLib::Common::GlobalConfig::TRUE;

########################################################################
#
# new --
#     Constructor to create an instance of
#     VDNetLib::TestSession::TestSessionv2
#
# Input:
#     Named hash parameters with following keys:
#     testcaseHash  : reference to vdnet test case hash (version 2)
#     userInputHash : reference to hash containing all user input
#                     TODO: check if all input is really required
#
# Results:
#     An object of VDNetLib::TestSession::TestSessionv2, if successful;
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self = VDNetLib::TestSession::TestSession->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSession::TestSession" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $self->{'version'} = "2.0";

   $self->{testbedSpec}    = undef; # stores reference to testbed spec
   $self->{userConfigSpec} = undef; # stores reference to user spec

   $self->{testCaseNumber} = $options{'testCaseNumber'};
   $self->{zookeeperObj}   = $options{'zookeeperObj'};
   $self->{testLevel}      = $options{'userInputHash'}{'testLevel'};
   $self->{yamlWins}       = $options{'userInputHash'}{'yamlWins'};
   $self->{zkSessionNode}  = undef;
   my $cacheTestbed = $options{'userInputHash'}{'cachetestbed'};
   bless $self, $class;

   #
   # Initialize the test session which involves create the
   # final testbed spec based on user input and testcase hash
   #
   my $result = $self->Initialize($cacheTestbed);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to initialize test session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self;
}


########################################################################
#
# Initialize --
#     Method to initialize test session which involves:
#     - Creating testbed spec for the given test
#     - testbed spec is passed as input to create an instance
#       of Testbedv2
#
# Input:
#     cacheTestbed: boolean (1/0) to indicate if cachetestbed
#                   feature is enabled
#
# Results:
#     SUCCESS, if test session is initialized successfully;
#              attributes userConfigSpec, testcaseHash,
#              testbed will be updated too.
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub Initialize
{
   my $self     = shift;
   my $cacheTestbed = shift;
   $self->SUPER::Initialize();

   #
   # Based on the user input create a final userConfigSpec.
   # Refer to ProcessUserInput() for more details
   #
   $self->{userConfigSpec} = $self->ProcessUserInput();

   #
   # Now, given the final userConfigSpec and testbed spec
   # which is presented as requirement in test case hash,
   # construct final testbed spec which is a merge of
   # both userconfigspec and testbed spec in test case hash.
   #
   my $result = $self->CreateTestbedSpec();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create testbed spec");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Testbed Spec after initialization:" .
                    Dumper($self->{testbedSpec}));

   $cacheTestbed = (defined $cacheTestbed) ? $cacheTestbed : 0;

   my $rootIndex = undef;
   if ($cacheTestbed) {
      # Compute 32-bit checksum from the testbedspec and use that as root node
      $rootIndex = VDNetLib::Common::Utilities::GetChecksumForHash($self->{testbedSpec});
      if ($rootIndex eq FAILURE) {
         $vdLogger->Error("Failed to get checksum value for hash");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   if (not defined $rootIndex) {
      $rootIndex = VDNetLib::Common::GlobalConfig::ZOOKEEPER_TEST_SESSION_NODE;
   } else {
      $rootIndex = VDNetLib::Common::GlobalConfig::ZOOKEEPER_TEST_SESSION_NODE . '/' . $rootIndex;
   }
   $self->SetTestSessionNode($rootIndex);
   my $zkObj = $self->{zookeeperObj};
   if (FAILURE eq $self->AddZooKeeperTestSessionNode()) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   #
   # Next, create an instance of Testbedv2 using the testbedSpec created
   # in previous step
   #
   my $testbed = VDNetLib::Testbed::Testbedv2->new(
                                 'testbedSpec'     => $self->{testbedSpec},
                                 'stafHelper'      => $self->{'stafHelper'},
                                 'skipSetup'       => $self->{'skipSetup'},
                                 'noTools'         => $self->{'noTools'},
                                 'vdNetSrc'        => $self->{'vdNetSrc'},
                                 'vdNetShare'      => $self->{'vdNetShare'},
                                 'sharedStorage'   => $self->{'sharedStorage'},
                                 'vmServer'        => $self->{'vmServer'},
                                 'vmShare'         => $self->{'vmShare'},
                                 'version'         => $self->{'version'},
                                 'version'         => $self->{'version'},
                                 'testCaseNumber'  => $self->{'testCaseNumber'},
                                 'zookeeperObj'    => $self->{'zookeeperObj'},
                                 'zkSessionNode'   => $self->{'zkSessionNode'},
                                 'logDir'          => $self->{'logDir'},
                                 'maxWorkers'      => $self->{'maxWorkers'},
                                 'maxWorkerTimeout'=> $self->{'maxWorkerTimeout'},
                                 );
   if ($testbed eq FAILURE) {
      $vdLogger->Error("Creation of testbed object failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{testbed} = $testbed; # update testbed attribute
   return SUCCESS;
}


########################################################################
#
# TestbedSetup --
#     Method to perform testbed setup based on the testbed spec
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed is created successfully;
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
      if (($self->{'collectLogs'} == TRUE) &&
          ($self->{testbed}->CollectAllLogs() eq FAILURE)) {
            $vdLogger->Error("Failed to collect logs for debugging");
      }
      $vdLogger->Error("Init in Testbed failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RunTest --
#     Method to run test using the given testcase hash and testbed
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed is created successfully;
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
# Cleanup --
#     Method to do test session cleanup
#
# Input:
#     lastTest: boolean flag to indicate if given test is last test in
#               overall session
#
# Results:
#     SUCCESS, if testbed is created successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     All virtual components created in testbed created will be
#     destroyed
#
########################################################################

sub Cleanup
{
   my $self = shift;
   my $lastTest = shift; # TODO: resource cache fix
   my $testbed = $self->{testbed};
   my $testResult = $self->{result};
   my $result = SUCCESS;

   if ($testbed->SessionCleanUp($testResult) eq FAILURE) {
      $vdLogger->Error("Test session cleanup failed");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   if ($lastTest &&
       ((not defined $self->{'noCleanup'}) ||
        ((defined $self->{'noCleanup'}) && ($self->{'noCleanup'} eq 0)))) {
      if ($testbed->TestbedCleanUp($testResult) eq FAILURE) {
         $result = FAILURE;
         $vdLogger->Error("Testbed cleanup failed");
      }
   }

   my $storedZkpid = $self->{'zookeeperObj'}->{'pid'};
   if (!VDNetLib::Common::Utilities::CheckIfPIDIsRunning($storedZkpid)) {
      $vdLogger->Error("zookeeper process $storedZkpid terminated, " .
                       "test session cleanup failed.");
      $result = `ps -ef`;
      $vdLogger->Debug("current process list: $result");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->DeleteZooKeeperTestSessionNode()) {
      $result = FAILURE;
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Test session cleanup failed");
      VDSetLastError(VDGetLastError());
   }
   return $result;
}


########################################################################
#
# ProcessUserInput --
#     Method to create userConfigSpec based on the user input
#     parameters
#
# Input:
#     None
#
# Results:
#     userConfigSpec: reference to user config spec (hash),
#     if successful;
#
# Side effects:
#     None
#
########################################################################

sub ProcessUserInput
{
   #
   # Based on the user input create a final userConfigSpec
   # which has exact details about the inventory items,
   # ip address etc. This step is required because
   # we support multiple input options for vdnet such
   # as --sut, --helper, --vms, --hosts and soon -c which
   # is json config.
   #
   my $self = shift;
   my $userConfigSpec = undef;
   my $userTestbedSpec = $self->{userTestbedSpec};
   my $userInputHash = $self->{userInputHash};
   if (not defined $userInputHash) {
      $vdLogger->Warn("User Input Hash not provided, start using" .
                      "--config option");
   } else {
      $vdLogger->Debug("User Input Hash" . Dumper($userInputHash));
      $userConfigSpec = $userInputHash->{testbed};
   }
   my $vmList = $self->{vmlist};
   if (defined $vmList) {
      # split the comma separated list of vms
      my @temp = split(/,/, $vmList);
      foreach my $item (@temp) {
         my ($vmType, $value) = split(/=/, $item);
         # remove any spaces before and after the string
         $vmType =~ s/^\s+|\s+$//;
         $value =~ s/^\s+|\s+$//;
         if ($vmType =~ /pri/i) {
            #
            # TODO: for now, considering one VM type for all
            # VM specs in the test.
            # This can be fixed once json config is implemented
            #
            $userConfigSpec->{'vm'}{'[-1]'}{template} = $value;
         }
      }
   }
   my $hostList = $self->{hostlist};
   if (defined $hostList) {
      my @temp = split(/,/, $hostList);
      for (my $i = 0; $i < scalar(@temp); $i++) {
         my $ip = $temp[$i];
         $ip =~ s/^\s+|\s+$//;
         my $index = $i+1;
         $userConfigSpec->{'host'}{"\[$index\]"}{ip} = $ip;
      }
   }
   #
   # TODO: for now, considering only one VC.
   # This can be fixed once json config is implemented
   #
   my $vc = $self->{vc};
   if (defined $vc) {
      $userConfigSpec->{'vc'}{'[1]'}{ip} = $vc;
   }

   $vdLogger->Debug("UserConfig Spec" . Dumper($userConfigSpec));
   return $userConfigSpec;
}


########################################################################
#
# CloneGlobalSpec --
#     This method makes copy of all specs referred by '-1' as index/key
#     -1 is used to indicate spec for all inventory/component.
#     This method makes X number of copies of this spec, where X is
#     equal to the number of indexes for corresponding
#     inventory/components in test spec
#
# Input:
#     userspec: spec which has references to -1 as index/key
#     testspec: testbed spec from test case hash
#
# Results:
#     The given userspec is updated. Reference to -1 will be copied
#     to actual index/keys and reference to -1 hash will be deleted
#
# Side effects:
#     None
#
########################################################################

sub CloneGlobalSpec
{
   my $self = shift;
   my $userSpec = shift;
   my $testSpec = shift;

   my $specComponents = INVENTORYCOMPONENTS;
   # Get the list of inventory items
   foreach my $inventory (keys %$testSpec) {
      my $inventoryIndexes = $testSpec->{$inventory};
      #
      # Each inventory will have multiple indexes or
      # if index is -1, then make copies of this spec
      #
      foreach my $index (keys %$inventoryIndexes) {
         if (not defined $userSpec->{$inventory}{$index}) {
            if (defined $userSpec->{$inventory}{'-1'}) {
               $userSpec->{$inventory}{$index} = $userSpec->{$inventory}{'-1'};
            }
         }
         my $componentList = $testSpec->{$inventory}{$index};
         foreach my $component (keys %$componentList) {
            # check if the key is part of supported component list
            if (!grep(/$component/, @{$specComponents->{$inventory}})) {
               $vdLogger->Trace("$component is not a component");
               next;
            }
            if (not defined $userSpec->{$inventory}{$index}{$component}) {
               next;
            }
            my $componentIndexes = $testSpec->{$inventory}{$index}{$component};
            #
            # Each component will have multiple indexes or
            # if index is -1, then make copies of this spec
            #
            foreach my $componentIndex (keys %$componentIndexes) {
               my $componentSpec =
                  $userSpec->{$inventory}{$index}{$component}{$componentIndex};
               if (not defined $componentSpec) {
                  if (defined $userSpec->{$inventory}{$index}{$component}{'-1'}) {
                     $userSpec->{$inventory}{$index}{$component}{$componentIndex} =
                        $userSpec->{$inventory}{$index}{$component}{'-1'};
                  }
               }
            }
            delete $userSpec->{$inventory}{$index}{$component}{'-1'};
         }
      }
      delete $userSpec->{$inventory}{'-1'};
   }
   return SUCCESS;
}


########################################################################
#
# CreateTestbedSpec --
#     Method to create testbed spec based on testcase requirements
#     and user config spec
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
   my $self = shift;

   if (exists $self->{testcaseHash}{testbedSpecFile}) {
      if (-e $self->{testcaseHash}{testbedSpecFile}) {
         my $testbedSpec = $self->{testcaseHash}{TestbedSpec};
         my $testbedFile = $self->{testcaseHash}{testbedSpecFile};
         $vdLogger->Debug("Importing testbed spec $testbedSpec from file: $testbedFile");
         if (exists LoadFile($testbedFile)->{$testbedSpec}) {
            $self->{testcaseHash}{TestbedSpec} = LoadFile($testbedFile)->{$testbedSpec};
         } else {
            $vdLogger->Error("TestbedSpec $testbedSpec not found in file: $testbedFile");
         }
      }
   }

   if (not defined $self->{testcaseHash}{TestbedSpec}) {
      $vdLogger->Error("TestbedSpec key not defined in yaml");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # First resolve/expand index notations in [] format
   #
   my $userConfigSpec = VDNetLib::Common::Utilities::ProcessSpec(
                          $self->{userConfigSpec});
   my $testConfigSpec = VDNetLib::Common::Utilities::ProcessSpec(
                          $self->{testcaseHash}{TestbedSpec});

   #
   # When testbedSpec from TestData/TestbedSpecs is used in test cases,
   # the value is passed as reference. This in turn would affect the
   # integrity of the spec since test cases modify the value of
   # testbedSpec. In order to protect testbedSpec from each test case,
   # a deep copy is made using dclone
   #
   $self->{testbedSpec} = dclone $testConfigSpec;
   $self->{userConfigSpec} = dclone $userConfigSpec;
   $self->CloneGlobalSpec($self->{userConfigSpec},
                         $self->{testbedSpec});
   #
   # Get the testbedSpec from test case hash
   # for each inventory item, check if corresponding entry from userInput
   # is available. For example, if the test case spec requires 10 hosts,
   # ensure there are user input for 10 hosts.
   # For inventory items, ip address is a must.
   # if login credentials are given then use it.
   # If any other keys in the spec in defined as a <variable> and if there
   # exits a corresponding entry user config hash, then replace the test case
   # spec with the user input value. If user input entry is NOT a variable
   # in test case spec, then return SKIP.
   #

   my $updatedSpec = $self->MergeSpec($self->{userConfigSpec},
                            $self->{testbedSpec});
   foreach my $inventory (keys %$testConfigSpec) {
      #
      # If there is no entry for given inventory, then throw error
      # We need at least ip address of the inventory
      #
      if (not defined $userConfigSpec->{$inventory}) {
         $vdLogger->Error("$inventory details missing in the user input");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      } else {
         my $testInventorySpec = $testConfigSpec->{$inventory};
         foreach my $item (keys %$testInventorySpec) {
            if ($item eq "-1") {
               $vdLogger->Debug("Special case: user input for $inventory " .
                                "index is $item");
               return SUCCESS;
            }
            #
            # Check if '[-1]' => {} exists for
            # $self->{userConfigSpec}{$inventory}
            #
            my $indexAll = "[-1]";
            if (exists $self->{userConfigSpec}{$inventory}{$indexAll}) {
               return SUCCESS;
            }
            if (not defined $self->{userConfigSpec}{$inventory}{$item}) {
               $vdLogger->Error("User input for $inventory index " .
                                "$item missing");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         }
      }
   }
   #
   # if user provided a testbed spec to override then merge
   # the test spec with user provided values
   #
   if (defined $self->{userTestbedSpec}) {
      $self->OverrideTestbedSpec();
   }
   return SUCCESS;
}


########################################################################
#
# OverrideTestbedSpec --
#     Method to override testspec with user provided testbed spec
#
# Input:
#     None
#
# Results:
#     Contents of 'testbedSpec' will be updated
#
# Side effects:
#     None
#
########################################################################

sub OverrideTestbedSpec
{
   my $self = shift;

   #
   # First resolve/expand index notations in [] format
   #
   my $userTestbedSpec = VDNetLib::Common::Utilities::ProcessSpec(
                            $self->{userTestbedSpec});
   $self->{userTestbedSpec} = $userTestbedSpec;
   $self->CloneGlobalSpec($self->{userTestbedSpec},
                         $self->{testbedSpec});
   $self->MergeSpec(
                     $self->{userTestbedSpec},
                     $self->{testbedSpec},
                   );
   return SUCCESS;
}


########################################################################
#
# MergeSpec --
#     Method to merge user config spec and testcase spec
#
# Input:
#     userSpec: reference to hash containing user configuration
#     testSpec: reference to hash containing test case spec
#               (These specs have to be simple structure i.e
#               should not be nested hash)
#
# Results:
#     SUCCESS, if specs are merged;
#
# Side effects:
#     None
#
########################################################################

sub MergeSpec
{
   my $self             = shift;
   my $customSpec       = shift;
   my $specTobeUpdated  = shift;

   foreach my $item (keys %$customSpec) {
      if (ref($customSpec->{$item}) eq "HASH") {
         #
         # First check if the item is a hash, if yes, then,
         # merge only if the hash exists in the actual testbed spec
         # from the test case. This will ensure components that
         # are required by test case are updated and not any additional
         # components from custom spec. For example, if the user has
         # entries for 2 hosts, but the testcase requires only one host,
         # then merge only one host.
         #
         if ((defined $specTobeUpdated->{$item}) ||
            ($self->{yamlWins})) {
            # recursive call to process all component specs
            $specTobeUpdated->{$item} = $self->MergeSpec($customSpec->{$item},
                                                      $specTobeUpdated->{$item}
                                                      );
         } else {
            next;
         }
      } elsif (not defined $specTobeUpdated->{$item}) {
         $specTobeUpdated->{$item} = $customSpec->{$item};
      } else {
         # update the spec, make sure this is updating the actual
         # spec and not the pointer
         my %orig = %$specTobeUpdated;
         $orig{$item} = $customSpec->{$item};
         $specTobeUpdated = \%orig;
         $vdLogger->Debug("Overriding $item with $customSpec->{$item}");
      }
   }
   return $specTobeUpdated;
}


########################################################################
#
# AddZooKeeperTestSessionNode --
#     Method to add root node for this test session
#
# Input:
#     None
#
# Results:
#     SUCCESS, if node for test session is added successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddZooKeeperTestSessionNode
{
   my $self = shift;
   my $node = $self->{zkSessionNode};
   my $zkHandle = $self->{'zookeeperObj'}->CreateZkHandle();

   if (not defined $zkHandle) {
      $vdLogger->Error("ZooKeeper handle is empty");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $result = $self->{'zookeeperObj'}->CheckIfNodeExists($node, $zkHandle);
   if ($result eq FAILURE) {
      $result = $self->{'zookeeperObj'}->AddNode("/testbed", "", undef, $zkHandle);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to add zookeeper node /testbed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $result = $self->{'zookeeperObj'}->AddNode($node, "", undef, $zkHandle);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to add zookeeper node $node");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to add zookeeper test session node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{zookeeperObj}->CloseSession($zkHandle);
   return SUCCESS;
}


########################################################################
#
# DeleteZooKeeperTestSessionNode --
#     Method to delete root node for this test session
#
# Input:
#     None
#
# Results:
#     SUCCESS, if node for test session is deleted successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DeleteZooKeeperTestSessionNode
{
   my $self = shift;

   my $node = $self->{zkSessionNode};
   my $zkHandle = $self->{'zookeeperObj'}->CreateZkHandle();
    if (not defined $zkHandle) {
       $vdLogger->Error("ZooKeeper handle is empty");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }
   my $result = $self->{'zookeeperObj'}->DeleteNode($node, $zkHandle);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to delete zookeeper test session node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{zookeeperObj}->CloseSession($zkHandle);
   return SUCCESS;
}


########################################################################
#
# CheckupAndRecovery --
#     Check up and recovery for all the inventories after each test
#
# Input:
#     None
#
# Results:
#     SUCCESS, if check health and recovery  successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub CheckupAndRecovery
{
   my $self = shift;
   my $testbed = $self->{testbed};
   my $checkupResult = FAILURE;
   my $result = SUCCESS;

   if (not defined $testbed) {
      # not defined, do nothing
      $vdLogger->Warn("Testbed not defined");
      return SUCCESS;
   }

   eval {
      $checkupResult = $testbed->HealthCheckupAndRecovery(1500);
      if ($checkupResult eq FAILURE) {
         $vdLogger->Warn("Health check failed");
         $result = FAILURE;
      }
   };
   if ($@) {
      $vdLogger->Error("Failed to do health check up and recovery with " .
                       "return value $checkupResult " . $@);
      $result = FAILURE;
   }

   return $result;
}


########################################################################
#
# SetTestSessionNode --
#     Method to set attribute zkSessionNode
#
# Input:
#     value to be stored in zkSessionNode
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub SetTestSessionNode
{
   my $self = shift;
   $self->{zkSessionNode} = shift;
}


########################################################################
#
# GetTestSessionNode --
#     Method to return current test session node
#
# Input:
#     None
#
# Results:
#     value of zkSessionNode attribute
#
# Side effects:
#     None
#
########################################################################

sub GetTestSessionNode
{
   my $self = shift;
   return $self->{zkSessionNode};
}
1;
