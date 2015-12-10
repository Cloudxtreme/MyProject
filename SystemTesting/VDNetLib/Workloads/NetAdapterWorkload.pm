########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::NetAdapterWorkload;

#
# This package/module is used to run workload that involves configuring
# a virtual network adapter. The configuration details are given in the
# workload hash and all the configurations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The NetAdapter object that this module uses extensively have to be
# registered in testbed object of vdNet. The workload hash can contain
# the following keys. The supported values are also given below for each
# key.
#
# Management keys:-
# ---------------
# Type = "NetAdapter" (this is mandatory and the value should be same)
#
# Network Configuration Keys:-
# --------------------------
# MTU = integer from 1500 to 9000
# IPv4 = "AUTO" or specific ip address in the format "X.X.X.X"
# VLAN = a valid integer from 0 to 4096 (0 means remove vlan)
# DeviceStatus = "UP" or "DOWN"
# IPV6ADDR = "DEFAULT" or specific IPV6 Address with prefix length 60"
# IPv6 = "ADD" or "DELETE"
# WoL = a string with either one of these values ARP/MAGIC/UNICAST/DISABLE
# SetWoL = a string with either one of these values ARP/MAGIC/UNICAST/DISABLE
# Wakeupguest = a string with either one of these values ARP/MAGIC/UNICAST
#
# For key "configure_offload"
# the offload_type  = TSOIPv4 ; the "Enable" = "True/False"
# the offload_type  = TCPTxChecksumIPv4 ;the "Enable" = "True/False"
# the offload_type  = TCPRxChecksumIPv4 ;the "Enable" = "True/False"
# the offload_type  = Ufo ;the "Enable" = "True/False"
# the offload_type  = Gso ;the "Enable" = "True/False"
# the offload_type  = SG ; the "Enable" = "True/False"

#
# UDPTxChecksumIPv4 = Enable/Disable
# UDPRxChecksumIPv4 = Enable/Disable
# TCPGiantIPv4 = Enable/Disable
# IPTxChecksum = Enable/Disable
# IPRxChecksum = Enable/Disable
# TSOIPv6 = Enable/Disable
# TCPTxChecksumIPv6 = Enable/Disable
# TCPRxChecksumIPv6 = Enable/Disable
# UDPTxChecksumIPv6 = Enable/Disable
# UDPRxChecksumIPv6 = Enable/Disable
# TCPGiantIPv6 = Enable/Disable
# InterruptModeration = Enable/Disable
# OffloadTCPOptions = Enable/Disable
# OffloadIPOptions = Enable/Disable
# RSS = Enable/Disable
# SmallRxBuffers = 64/128/256/512/768/1024/1536/2048/3072/4096/8192
# LargeRxBuffers = 64/128/256/512/768/1024/1536/2048/3072/4096/8192
# ring_type is Tx ;the value = 32/64/128/256/512/1024/2048/4096
# ring_type is rx1;the value = 32/64/128/256/512/1024/2048/4096
# ring_type is rx2;the value= 32/64/128/256/512/1024/2048/4096
# MACAddress = A valid MAC not starting with VMware's OUI
# LRO = Enable/Disable
# SetLROMxLgth = Numeric value e.g. "32767"
# SetTcpipStress = Stress option name
#    > TcpipStressValue = Numeric value e.g. "13" (Mandatory)
# route = "Add/Delete", by default
#    > Gateway = IPv4 gateway (optional in case of IPv6)
#    > IPv6Gateway = IPv6 gateway (optional in case of IPv4)
#    > Netmask = Netmask address (optional)
#    > Network = Network address (optional)
# VMotion = Enable/Disable
#
# All the network configuration keys above support 4 types of data format:
# 1. specific value, for example, MTU => "1500",
# 2. list of values, for example, MTU => "1500,9000",
# 3. range of values, for example, MTU => "1500-9000,50"
# 4. named parameters (wherever applicable), e.g. route => "Add",
#                                                 Gateway => "10.112.27.253",
#
use strict;
use warnings;
use Data::Dumper;
# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger PERSIST_DATA_REGEX);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::FeaturesMatrix qw(%vdFeatures);
use VDNetLib::Common::Iterator;
use VDNetLib::Common::Utilities;
use VDNetLib::Workloads::Utils;
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use File::Basename;

# constants
use constant STANDBY_TIMEOUT => 120;
use constant DEFAULT_SLEEP => 20;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::NetAdapterWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::Workloads::NetAdapterWorkload object,
#      if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new {
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   $self->{stafHelper} = $options{stafHelper};
   if (not defined $self->{stafHelper}) {
      my $args;
      $args->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($args);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }
   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'    => "testadapter",
      'componentIndex' => undef
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}

########################################################################
#
# StartWorkload --
#      This method will process the workload hash  of type 'NetAdapter'
#      and execute necessary operations on the specified Target and
#      Index, for n number of Iterations.
#
# Input:
#      None
#
# Results:
#     "PASS", if workload is executed successfully,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the NetAdapter workload being executed
#
########################################################################

sub StartWorkload {
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   # Collect the parameters
   my ($machine, $target, $adapter);
   my @adapters;

   # TODO - Read and validate the workload hash. For example, check if the
   # given configuration key is supported.

   # Create a copy of the workload hash and separate all the NetAdapter
   # related keys from the other (management/control) keys.
   # Reason. If these keys take any comma separated value then we don't
   # expect iterator module to generate combinations for them too.
   #
   # Pass the duplicate workload hash as parameter to create an Iterator
   # object.
   #

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);

   # Store the management keys in Local variables

   # Number of Iterations to run the test for
   my $iterations = $dupWorkload->{'iterations'};

   if (not defined $iterations) {
      $iterations = 1;
   }

   # Determine the target on which the NetAdapter workload should be run.
   # The target could be SUT or/AND helper<x>
   my $targets = $dupWorkload->{'target'};


   #
   # Find the interface type of the adapters to be used in the given
   # NetAdapter workload. If intType is not defined, then default to
   # vnic.
   # NOTE: In a NetAdapter workload hash, only one adapter type can be
   # tested at a time.
   # To test different adapter types (vmknic,vmnic,vnic), write different
   # workload hash.
   #
   my $interfaceType = $dupWorkload->{'inttype'};
   $interfaceType = (defined $interfaceType) ? $interfaceType : "vnic";

   #
   # Determine the adapter index on the given target to run this workload.
   # The target machines can have multiple test adapters as indicated by
   # <testCaseHash>->{PreConfig}{<target>}{AdaptersCount}.
   # The 'TestAdapter' key in the workload refers to the index of a particular
   # adapter from the set of adapters already registered in testbed.
   #
   my $testAdapters;
   if ($dupWorkload->{'testadapter'}) {
      $testAdapters = $dupWorkload->{'testadapter'};
   } else {
      #
      # default to the first adapter on the given target if 'TestAdapter' is
      # not defined.
      #
      $testAdapters = 1;
   }

   # If testAdapter is the format as ->\w.*->, then
   # read actual vdnet index from persist data
   if ($testAdapters =~ PERSIST_DATA_REGEX) {
      my $subvdnet_index;
      # if testAdapters is ->\w.*->.+\+.+, such as
      # my $str='nsxmanager.[1]->read_nexthop_gateway->gateway+.vnic.[1]';
      # it means we want testAdapters+str, for above str, the final result
      # may be 'nsxedge.[1].vnic.[1]'
      if ($testAdapters =~ m/(.*\-\>\w.*\-\>.+)\+(\..+)/) {
         $testAdapters = $1;
         $subvdnet_index = $2;
      }

      my $hash_ref = {};
      $hash_ref->{'adapterkey'} = $testAdapters;
      my $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                                 $hash_ref->{adapterkey},
                                                                 'adapterkey');
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get net adapter index from persist data");
         VDSetLastError("EOPFAILED");
         return "FAIL";
      } else {
         $testAdapters = $result;
         $vdLogger->Info("Retrieved actual testadapter from persistdata ".
                                                        "is $testAdapters");
      }
      if (defined $subvdnet_index) {
         $testAdapters = "$testAdapters$subvdnet_index";
         $vdLogger->Info("Final actual testadapter is $testAdapters");
      }
   }

   my $persistData;
   if ((exists $dupWorkload->{'persistdata'}) &&
      (defined $dupWorkload->{'persistdata'}) &&
      ($dupWorkload->{'persistdata'} =~ /yes/i)) {
      $persistData = "yes";
      delete $dupWorkload->{'persistdata'};
   } else {
      $persistData = "no";
   }

   #
   # In the workload hash, not all the keys represent the network configuration
   # to be made on the given adapter. There are keys that control how to run
   # the workload. These keys can be referred as management keys. The
   # management keys are removed from the duplicate hash
   my @mgmtKeys = ('testadapter', 'type', 'iterations', 'timeout', 'target',
                   'verification', 'onevent', 'onstate', 'expectedresult',
                   'maxtimeout', 'passthrough', 'inttype', 'sleepbetweencombos',
                   'sleepbetweenworkloads', 'runworkload');

   my $mgmtHash = {};
   foreach my $key (@mgmtKeys) {
     $mgmtHash->{$key} = $dupWorkload->{$key};
     delete $dupWorkload->{$key};
   }

   $self->{testkeysHash} = $dupWorkload;
   $self->{mgmtkeysHash} = $mgmtHash;

   #if sleepbetweenworkloads is specified
   if (defined $mgmtHash->{sleepbetweenworkloads}) {
      $vdLogger->Info("Sleep between workloads is defined: " .
                     $mgmtHash->{sleepbetweenworkloads});
      sleep($mgmtHash->{sleepbetweenworkloads});
   }

   # Run for the given number of iterations
   $vdLogger->Info("Number of Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");
      # Create an iterator object and find all possible combination of workloads
      # to be run. NetAdapterWorkload handles specific, list and range of values
      # for a given network configuration key. The iterator module takes care of
      # identifying these different data types and generates combination if more
      # than one network configuration key uses list or range data types.
      # For example, if MTU = 1500, 9000 and TSOIPv4 = Enable, Disable. Then, the
      # iterator will return 4 different hashes with
      # 1. MTU = 1500; TSO = Enable
      # 2. MTU = 9000; TSO = Enable
      # 3. MTU = 1500; TSO = Disable
      # 4. MTU = 9000; TSO = Disable
      #
      my $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload,
                                                        flag => "ignoreSingleton");
      if ($iteratorObj eq FAILURE) {
         $vdLogger->Error("Failed to create iterator object");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }

      my $configCount = 1;
      # NextCombination() method gives the first combination of keys
      my %adapterConfig = $iteratorObj->NextCombination();
      my $adapterConfigHash = \%adapterConfig;

      $self->{initDefault} = 0;
      while (%adapterConfig) {
         $vdLogger->Info("Working on configuration set $configCount");
         $vdLogger->Info(Dumper($adapterConfigHash));
         if ($self->{testbed}{version} == 1) {
            my $refArray = $self->GetAdapterList('targets' => $targets,
                                                 'intType' => $interfaceType,
                                                 'testAdapter' => $testAdapters);
            push @adapters, @$refArray;
         } else {
            @adapters = split($self->COMPONENT_DELIMITER, $testAdapters);
            my @newArray = ();
            foreach my $adapter (@adapters) {
               my $refArray = $self->{testbed}->GetAllComponentTuples($adapter);
               if ($refArray eq FAILURE) {
                  $vdLogger->Error("Failed to get component tuples for $adapter");
                  VDSetLastError(VDGetLastError());
                  return "FAIL";
               }
               push @newArray, @$refArray;
            }
            @adapters = ();
            push @adapters, @newArray;
         }
         # Filter out unnecessary spaces
         foreach my $adapterTuple (@adapters) {
            $adapterTuple =~ s/^\s+//;
            $self->{target} = $adapterTuple;
            $self->SetComponentIndex($adapterTuple);
            $vdLogger->Info("Running NetAdapter workload on $adapterTuple");
            my $ref = $self->{testbed}->GetComponentObject($adapterTuple);
            $self->{'testAdapter'} = $adapterTuple;
            $adapter = $ref->[0];
            my $adapterFeatureHash; # this hash stores keys like driverName,
            # testbedInfo (information related to adapter) and vdFeatureInfo
            # (reference to virtual devices feature matric hash)

            #
            # Store the NetAdapter object corresponding to 'TestAdapter' key
            # and also based  on intType key.
            # The NetAdapter object should be already registered in the testbed
            # before running any workload.
            #

            if (not defined $adapter) {
               $vdLogger->Error("Specified NetAdapter index $adapterTuple is not" .
                                "registered in the testbed hash for " .
                                "machine $target");
               VDSetLastError("ENOTDEF");
               return "FAIL";
            }

            # Store it as class attribute
            $self->{adapter} = $adapter;
            $self->{'adapterFeatureHash'} =
               $self->CreateAdapterFeatureHash($adapter, $adapterConfigHash);

            #
            # Configure the given adapter using the combination of test key
            # hash.
            #
            my $result = $self->ProcessTestKeys($adapterConfigHash,
                                                $persistData);
            if ($result eq FAILURE) {
               $vdLogger->Error("NetAdapterWorkload failed while processing " .
                                "test keys");
               VDSetLastError(VDGetLastError());
               return "FAIL";
            }
            if ($result eq "SKIP") {
               $vdLogger->Info("Skipping the NetAdapter workload");
               return "SKIP";
            }
         } # end of machines loop

         # Call another workload for verification, if specified.
         if (defined $mgmtHash->{'runworkload'}) {
            # Check for supported verification types else assume workload
            my $runworkload = $mgmtHash->{'runworkload'};
            $vdLogger->Info("Running $mgmtHash->{'runworkload'} workload " .
                            "for verification");
            if ($self->RunChildWorkload($runworkload) eq FAILURE) {
               $vdLogger->Error("Failed to execute runworkload for verification: " .
                                Dumper($runworkload));
               VDSetLastError(VDGetLastError());
               return "FAIL";
            }
         }
         #
         # Consecutive NextCombination() calls iterates through the list of all
         # available combination of hashes
         #
         %adapterConfig = $iteratorObj->NextCombination();
         $self->{initDefault} = 1; # set this to 1 to skip default setting next
                                   # time
         $configCount++;
      } # end of combinations loop
   } # end of iterations loop
   return "PASS";
}


########################################################################
#
# ProcessTestKeys --
#      This method will process the workload hash  of type 'NetAdapter'
#      and execute necessary operations (executes NetAdapter related
#      methods).
#
# Input:
#      TestKeyHash: Reference to test keys Hash
#
# Results:
#     "SUCCESS", if workload is executed successfully,
#     "FAILURE", in case of any error;
#
# Side effects:
#     Depends on the NetAdapter workload being executed
#
########################################################################

sub ProcessTestKeys
{
   my $self = shift;
   my $testKeysCombo = shift;
   my $persistData       = shift;
   my %temp = %{$testKeysCombo};
   my $adapterConfigHash = \%temp; #making a local copy here
   my $mgmtHash = $self->{mgmtkeysHash};
   my $target = $self->{target};
   my $adapter = $self->{adapter};
   my $testbed = $self->{testbed};
   my $result;
   my $stafHelper = $testbed->{stafHelper};

   if (not defined $adapter) {
      $vdLogger->Error("NetAdapter object not defined");
      VDSetLastError("ENOTDEF");
      return "FAILURE";
   }

   my $adapterFeatureHash = $self->{'adapterFeatureHash'};
   my $driverName = $adapterFeatureHash->{driverName};
   my $testbedInfo = $adapterFeatureHash->{testbedInfo};
   my $vdFeatureInfo = $adapterFeatureHash->{vdFeatureMatrix};
   #
   # Check if Passthrough verification is required by reading the key
   # 'Passthrough' in workload hash. If yes, then get the
   # VDNetLib::Host::HostOperations object for the given target SUT/helper<x>
   # and retrieve the adapter's VSI port number. This port information is
   # needed for GetvNicUPTStatus() method which is used to verify adapter's UPT
   # status.
   #
   if (defined $mgmtHash->{'passthrough'} &&
      $mgmtHash->{'passthrough'} =~ /upt/i) {
      $vdLogger->Info("Passthrough verification enabled");
      my $hostObj;
      my $vmOpsObj;
      if (($adapter->{intType} eq 'vnic') || ($adapter->{intType} eq 'pci')) {
         $vmOpsObj = $adapter->{vmOpsObj};
         $hostObj = $vmOpsObj->{hostObj};
      } elsif (($adapter->{intType} eq 'vmnic') ||
               ($adapter->{intType} eq 'vmknic')) {
         $hostObj = $adapter->{hostObj};
      }

      if (not defined $hostObj) {
         $vdLogger->Error("HostOperations object not defined for $target");
         VDSetLastError("ENOTDEF");
         return "FAILURE";
      }
      my $vsiPort = $hostObj->GetvNicVSIPort($adapter->{'macAddress'});
      if ($vsiPort eq FAILURE) {
         $vdLogger->Error("Failed to get vsi port for " .
                          $adapter->{'macAddress'});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Store the VSI port number is NetAdapter hash for now.
      # TODO - any other better variable to store?
      #
      $adapter->{vsiPort} = $vsiPort;
   }

   #
   # Initialize the given adapter to default value. The initialization
   # remove any vlan configured, sets mtu to 1500 and assigns ip address.
   # These actions are performed only if the user did not specify any value for
   # these configurations in the workload hash.
   #
   if (defined $adapter->{'intType'} and $adapter->{'intType'} eq "vnic") {
      if (!$self->{initDefault}) {
         $vdLogger->Info("Setting default configuration on adapter");
         $result = $self->InitDefaultNIC();
         if ($result eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return "FAILURE";
         }
      }

      #
      # There are some special operations like wol which needs some
      # special configuration before actually configuring them on the given
      # driver. These features need to be first checked if they are supported
      # on the given driver and testbed.
      #
      my @specialKeys = ('wol', 'setwol', 'intrmode');

      my $featureSupport;
      foreach my $config (@specialKeys) {
         if (defined $adapterConfigHash->{$config}) {
	    if ($config =~ /setwol/i) {
	       $config = 'wol';	# Just to check if WOL feature is supported
	    }

            $featureSupport = $self->IsFeatureSupported($driverName, $config,
                                                        $testbedInfo,
                                                        $vdFeatureInfo);
            if ($featureSupport eq FAILURE) {
               $vdLogger->Error("Failed to check if feature is supported " .
                                "not");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            if(!$featureSupport) {
               $vdLogger->Warn("Feature $config not supported on $driverName");
               return "SKIP";
            }
         }
      } # end of special keys loop
   } # end of vnic condition

   #
   # WoL is special, it requires vmx configuration, ConfigureWoL()
   # method takes care of add vmx entries related to WoL for the given
   # adapter
   #
   if (defined $adapterConfigHash->{'wol'}) {
      $result = $self->ConfigureWoL($adapter,
                                    $adapterConfigHash->{'wol'},
                                    $testbed->{stafHelper});
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }

   #
   # WoL is special, it requires vmx configuration, ConfigureWoL()
   # method takes care of add vmx entries related to WoL for the given
   # adapter
   #
   if (defined $adapterConfigHash->{'setwol'}) {
      $result = $self->ConfigureWoL($adapter,
                                    $adapterConfigHash->{'setwol'},
                                    $testbed->{stafHelper});
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }

   #
   # Configure all other given properties on the network adapter,
   # expect IntrMode.
   if (not defined $adapterConfigHash->{'intrmode'}) {
      $vdLogger->Debug("Running NetAdapter workload on $target in ".
                       "ProcessTestKeys()");
      my $sleepBetweenCombos = $mgmtHash->{'sleepbetweencombos'};
      if (defined $sleepBetweenCombos) {
         $vdLogger->Info("Sleep between combination of value " .
               "$sleepBetweenCombos is given. Sleeping ...");
         sleep($sleepBetweenCombos);
      }
      $result = $self->ConfigureComponent('configHash'       => $adapterConfigHash,
                                          'passthrough'      => $mgmtHash->{'passthrough'},
                                          'testObject' => $adapter,
                                          'persistData' => $persistData);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure netadapter component");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }

      if ($result eq "SKIP") {
         return "SKIP";
      }
   }

   # If WoL key is defined, by now WoL would have already been set using
   # SetWoL(). Now verify WoL, by putting the VM to standby and send
   # magic pkt/ARP/ping based on what the adapter is currently configured
   # with and make sure the VM wakes up.
   if (defined $adapterConfigHash->{'wol'}) {
      my $ref = $self->GetNetAdapterObject(inputType => "support",
                       supportAdapter => $testKeysCombo->{supportadapter});
      my $supportAdapterObj = $ref->[0];
      $result = $self->VerifyWoL($adapter,
                                 $adapterConfigHash->{'wol'},
                                 $supportAdapterObj);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }

   # If the IntrMode is defined, then change the interrupt mode
   # for the adapter and verify it.
   if (defined $adapterConfigHash->{'intrmode'}) {
      $result = $self->InterruptProcessing($adapter,
                                           $adapterConfigHash->{'intrmode'},
                                           $testbed->{stafHelper});
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }

   return SUCCESS;
}


########################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of NetAdapterWorkload
#      if needed. This method should be defined as it is a required
#      interface for VDNetLib::Workloads::Workloads.
#
# Input:
#     None
#
# Results:
#     To be added
#
# Side effects:
#     None
#
########################################################################

sub CleanUpWorkload {
   my $self = shift;
   # TODO - there is no cleanup required as of now. Implement any
   # cleanup operation here if required in future.
   return "PASS";
}


########################################################################
#
# ConfigureComponent --
#      This method configures most of the features (example: MTU,
#      TSOIPv4, Tx/RxRingSize etc.) on the virtual network adapter.
#
# Input:
#      adapter: NetAdapter object on which configurations has to be made
#      adaperConfigHash: A part of workload hash with network
#                        configuration keys, the managements key have
#                        to be removed from workload hash before
#                        calling this method.
#      passthrough: "UPT", if passthrough verification is needed
#                    (Optional)
#
# Result:
#      "SUCCESS", if all the network configurations are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureComponent {
   my $self              = shift;

   my %args        = @_;
   my $adapterConfigHash = $args{configHash};
   my $adapter           = $args{testObject};
   my $passthrough       = $args{passthrough} || undef;
   my $persistData       = $args{persistData};
   my $tuple             = $args{tuple};

   my $adapterFeatureHash = $self->{adapterFeatureHash};

   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $adapterConfigHash,
                                                 'testObject' => $adapter,
                                                 'persistData' => $persistData,
                                                 'tuple'      => $tuple);

   if (defined $result) {
      if ($result eq "FAILURE") {
         return "FAILURE";
      } elsif ($result eq "SKIP") {
         return "SKIP";
      } elsif ($result eq "SUCCESS") {
         return "SUCCESS";
      }
   }

    if ((not defined $adapter) || (not defined $adapterConfigHash)) {
      $vdLogger->Error("Target, adapter and/or config hash not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $macAddr = $adapter->{'macAddress'};
   if (not defined $macAddr) {
      $vdLogger->Error("MAC address undefined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $adapter->{originalMAC}) {
      $adapter->{originalMAC} = $adapter->{macAddress};
   }

   # Create a duplicate copy of the Adapter Config hash so that the duplicate
   # contains the param keys and method keys of the test cases
   my %temp = %{$adapterConfigHash};
   my $dupConfigHash = \%temp;

   my $ipv6addr = $dupConfigHash->{'ipv6addr'};
   if (not defined $ipv6addr) {
      $ipv6addr = "AUTO";
   }



   # $result = undef is a temporary return value being
   # used currently until we port all the keys to the
   # new modular design. This condition says that the
   # Parent Workload's ConfigureComponent was not able
   # to configure the key because the key was not part
   # of the KEYSDATABASE, so the NetAdapterWorkload's
   # ConfigureComponent will try to confgure the key.


   # Deleting all the named param keys from the Adapter config hash
   my @allParamKeys = ('gateway', 'ipv6gateway', 'netmask',
                       'network', 'rxqid', 'rxfilterid', 'portid',
                       'numactq', 'transtype', 'txrxqueueid',
                       'poolid', 'poolparam', 'txqparam', 'verifyvalue',
                       'txqueueid', 'ipv6addr', 'priorityvlanaction',
                       'supportadapter');

   foreach my $key (@allParamKeys) {
      if (defined $adapterConfigHash->{$key}) {
         delete $adapterConfigHash->{$key};
      }
   }

   #
   # Store the method names in NetAdapter class for every network feature in
   # virtual network devices in the following hash. If a method is common
   # for multiple features, then store the additional parameters that need
   # to be passed as well. For example, SetOffload() method is common for
   # TSOIPv4, TSOIPv6 and many other features. SetOffload() takes feature name
   # as first parameter, such information are stored as 'param' in the
   # following hash.
   #
   # Also, store the UPT end status after each configuration and transition state,
   # if any, that needs to be verified while doing the given network
   # configuration.
   #
   my %configNames = (
      'mtu'                => {
         'method'          => 'SetMTU',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => 'NO_VF',
         },
      },
      'ipv4'               => {
         'method'          => 'SetIPv4',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'ipv6'           => {
         'method'          => 'SetIPv6',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'devicestatus'       => {
         'method'          => 'SetDeviceStatus',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
         },
      },
      'vmotion'            => {
         'method'          => 'SetVMotion',
         'param'           => '',
      },
      'nicstats'           => {
         'method'          => 'GetNICStats',
         'param'           => '',
      },
      'offload16offset'    => {
         'method'          => 'Offload16Offset',
         'param'           => '',
      },
      'offload8offset'     => {
         'method'          => 'Offload8Offset',
         'param'           => '',
      },
      'nethighdma'         => {
         'method'          => 'NetHighDMA',
         'param'           => '',
      },
      'netsgspanpgs'       => {
         'method'          => 'NetSGSpanPages',
         'param'           => '',
      },
      'netsg'              => {
         'method'          => 'ActivateNETSG',
         'param'           => '',
      },
      'ipchecksum'         => {
         'method'          => 'SetOffload',
         'param'           => 'IPCheckSum',
      },
      'vlanrx'             => {
         'method'          => 'HwVlanRx',
         'param'           => '',
      },
      'vlantx'             => {
         'method'          => 'HwVlanTx',
         'param'           => '',
      },
      'tso6exthdrs'        => {
         'method'          => 'IPV6TSO6ExtHdrs',
         'param'           => '',
      },
      'ipv6extchecksum'    => {
         'method'          => 'IPV6CSumExtHdrs',
         'param'           => '',
      },
      'ipv6checksum'       => {
         'method'          => 'IPV6CSum',
         'param'           => '',
      },
      'nicwol'             => {
         'method'          => 'WOL',
         'param'           => '',
      },
      'wakeupguest'        => {
         'method'          => 'WakeupGuest',
         'param'           => '',
      },
      'txqinfo'            => {
         'method'          => 'TxQueueInfo',
         'param'           => '',
      },
      'rxqinfo'            => {
         'method'          => 'RxQueueInfo',
         'param'           => '',
      },
      'rxfilterinfo'       => {
         'method'          => 'RxFilterInfo',
         'param'           => '',
      },
      'getrxq'             => {
         'method'          => 'GetRxQueues',
         'param'           => '',
      },
      'gettxnumq'          => {
         'method'          => 'GetTxNumOfQueues',
         'param'           => '',
      },
      'gettxqid'           => {
         'method'          => 'GetTxQueueId',
         'param'           => '',
      },
      'getrxqfilter'       => {
         'method'          => 'GetRxQueueFilters',
         'param'           => '',
      },
      'qpktcnt'         => {
         'method'          => 'GetQueuePktCount',
         'param'           => '',
      },
      'rxpoolinfo'         => {
         'method'          => 'GetRxPoolInfo',
         'param'           => '',
      },
      'rxpoolq'            => {
         'method'          => 'GetRxPoolQueues',
         'param'           => '',
      },
      'rxpools'            => {
         'method'          => 'GetRxPools',
         'param'           => '',
      },
      'txqstats'           => {
         'method'          => 'GetTxQueueStats',
         'param'           => '',
      },
      'setpktsched'        => {
         'method'          => 'SetPktSchedAlgo',
         'param'           => '',
      },
      'tsosupported'       => {
         'method'          => 'TSOSupported',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
         },
      },
      'wol'                => {
         'method'          => 'SetWoL',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => '1',
         },
      },
      'setwol'                => {
         'method'          => 'SetWoL',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => '1',
         },
      },
      'udptxchecksumipv4'  => {
         'method'          => 'SetOffload',
         'param'           => 'UDPTxChecksumIPv4',
      },
      'udprxchecksumipv4'  => {
         'method'          => 'SetOffload',
         'param'           => 'UDPRxChecksumIPv4',
      },
      'tcpgiantipv4'       => {
         'method'          => 'SetOffload',
         'param'           => 'TCPGiantIPv4',
      },
      'iptxchecksum'       => {
         'method'          => 'SetOffload',
         'param'           => 'IPTxChecksum',
      },
      'iprxchecksum'       => {
         'method'          => 'SetOffload',
         'param'           => 'IPRxChecksum',
      },
      'tsoipv6'            => {
         'method'          => 'SetOffload',
         'param'           => 'TSOIPv6',
      },
      'tcptxchecksumipv6'  => {
         'method'          => 'SetOffload',
         'param'           => ' TCPTxChecksumIPv6',
      },
      'tcprxchecksumipv6'  => {
         'method'          => 'SetOffload',
         'param'           => 'TCPRxChecksumIPv6',
      },
      'udptxchecksumipv6'  => {
         'method'          => 'SetOffload',
         'param'           => 'UDPTxChecksumIPv6',
      },
      'udprxchecksumipv6'  => {
            'method'       => 'SetOffload',
            'param'        => 'UDPRxChecksumIPv6',
      },
      'tcpgiantipv6'       => {
         'method'          => 'SetOffload',
         'param'           => 'TCPGiantIPv6',
      },
      'sg'       => {
         'method'          => 'SetOffload',
         'param'           => 'SG',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => '',
         },
      },
      'interruptmoderation'=> {
         'method'          => 'SetInterruptModeration',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => '',
         },
      },
      'offloadtcpoptions'  => {
         'method'          => 'SetOffloadTCPOptions',
         'param'           => '',
      },
      'offloadipoptions'   => {
         'method'          => 'SetOffloadIPOptions',
         'param'           => '',
      },
      'priorityvlan'        => {
         'method'          => 'SetPriorityVLAN',
         'param'           => '',
      },
      'smallrxbuffers'      => {
         'method'          => 'SetRxBuffers',
         'param'           => 'Small',
      },
      'largerxbuffers'     => {
         'method'          => 'SetRxBuffers',
         'param'           => 'Large',
      },
      'macaddress'         => {
         'method'          => 'SetMACAddress',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => 'VNIC_DISABLED',
         },
      },
   );

   #
   # Collect all testbed details here.
   #
   my ($driverName, $testbedInfo, $vdFeatureInfo);
   if (not defined $adapterFeatureHash) {
      $adapterFeatureHash =  $self->CreateAdapterFeatureHash($adapter,
                                                             $adapterConfigHash);
      $vdLogger->Debug("Feature hash" . Dumper($adapterFeatureHash));
   }
   $driverName = $adapter->{driver};
   $testbedInfo = $adapterFeatureHash->{testbedInfo};
   $vdFeatureInfo = $adapterFeatureHash->{vdFeatureMatrix};
   $driverName = $adapterFeatureHash->{driverName};

   #
   # Now, the keys in the given network configuration hash are processed one by
   # one.
   #

   foreach my $config (keys %{$adapterConfigHash}) {
      #
      # Check if the feature is supported or not. If not supported, just
      # proceed to the next feature/configuration.
      #

      #
      # Adding vmnic to the check
      # NOTE: Currently in vmnic, only method "qpktcnt" needs an
      # exception
      #
      my $featureSupport;

      if (($config !~ /wakeupguest/i) &&
          ($adapter->{'intType'} eq "vnic" ||
          ($adapter->{'intType'} eq "vmnic" &&
           $config eq "qpktcnt"))) {
	   my $featureName = $config;
	   if ($featureName =~ /setwol/i) {
	      $featureName  = 'wol'; # Just to check if WOL feature is supported
	   }

           $featureSupport = $self->IsFeatureSupported($driverName, $featureName,
                                                       $testbedInfo,
                                                       $vdFeatureInfo);
           if ($featureSupport eq FAILURE) {
              VDSetLastError(VDGetLastError());
              return FAILURE;
           }
           if(!$featureSupport) {
               $vdLogger->Warn("Feature $featureName not supported on $driverName");
               return "SKIP";
           }
   }
      # Find the NetAdapter method name for each feature.
      my $method = $configNames{$config}{'method'};
      if (not defined $method) {
            $vdLogger->Error("Method name not found for $config operation");
            VDSetLastError("ENOTDEF");
            return FAILURE;
      }
      my @value = ();

      # Store the default parameters for each method here.
      if ($configNames{$config}{'param'}) {
         push(@value, $configNames{$config}{'param'});
      }

      my $ip = undef;
      if ($config eq "ipv4") {
         if ($adapterConfigHash->{$config} =~ /auto/i) {
            #
            # "AUTO" is the special value for IPV4, which indicates that this
            # package should assign an ip address automatically.
            # GetAvailableTestIP() utility function gives an available class C
            # ip address to use.
            #
            $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($adapter->{controlIP});
            if ($ip eq FAILURE) {
               $vdLogger->Error("Failed to get free IP address");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
         } else {
            # If user specified a specific ip address, then use that.
            $ip = $adapterConfigHash->{$config};
         }
         # Using the default netmask
         push(@value, $ip, VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK);
      } else {
         # Pass the user provided value for each feature/configuration
         push(@value, $adapterConfigHash->{$config});
      }
      if ($config eq "wakeupguest") {
         my $ref = $self->GetNetAdapterObject(inputType => "support",
                          supportAdapter => $dupConfigHash->{supportadapter});
         my $supportAdaperObj = $ref->[0];
         push(@value, $adapter);
         push(@value, $self->{testbed}->{stafHelper});
         push(@value, $supportAdaperObj);
      }

      if ($config eq "ipv6") {
         my ($ip, $prefix);
         if ($ipv6addr =~ /default/i) {
            #
            # "DEFAULT" is the special value for IPV6, which indicates that this
            # package should assign an ipv6 address automatically.
            # GetAvailableTestIP() utility function gives an ipv6 address
            # to use based on the MAC Address.
            #
            $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($adapter->{controlIP},
                                                                  $macAddr,"ipv6");
            if ($ip eq FAILURE) {
               $vdLogger->Error("Failed to get IPV6 address");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
         } else {
            # If user specified a specific ipv6 address, then use that.
            $ip = $dupConfigHash->{'ipv6addr'};
         }
         if ($ip =~ /(.*)\/(.*)/) {
            $ip = $1;
            $prefix = $2;
         }
         # Using the default IP and prefix Length
         push(@value, $ip, $prefix);
      }

      if ($config =~ /verify/i) {
         push(@value, $dupConfigHash->{'verifyvalue'});
         $vdLogger->Info("Verifying $adapterConfigHash->{$config}" .
                         " on adapter " . $macAddr .
                         " with parameters " . join(',',@value));
      } else {
         $vdLogger->Info("Configuring $config on adapter " . $macAddr .
                         " with parameters " . join(',',@value));
      }

      if ($config eq "mtu") {
	 if (($adapter->{'intType'} =~ /vnic/i) &&
	     ($testbedInfo->{'guestos'} =~ /win/i) &&
	     int($adapterConfigHash->{$config}) < 1500) {
	       $vdLogger->Warn("The given MTU size: ".
			       "$adapterConfigHash->{$config} ,".
			       " is not supported on Windows. ".
			       "Hence skipping this testcase...");
	       return "SKIP";
	 }
      }

      #
      # After figuring out the method name and parameters to pass in order
      # configure a feature on the given adapter, call the appropriate
      # NetAdapter method.
      #
      my $result = undef;

      #
      # NOTE:
      # Setting a standard that in case a method accepts more than one argument
      # for e.g. "stress option" and its "value", the user will pass named
      # parameters as given in the method required rather than accepting params
      # using "shift". There will be methods that will take in more than 4
      # params and using "shift" won't be a wise option then.
      # The $config values listed below are the methods in NetAdapter that
      # accept 1 or more named arguments
      #
      if ($config =~ /settcpipstress/ ||
          $config =~ /gettxqid/ ||
          $config =~ /priorityvlan/ ||
          $config =~ /qpktcnt/ ||
          $config =~ /rxpoolinfo/ ||
          $config =~ /txqstats/ ||
          $config =~ /verifyfeature/ ||
          $config =~ /rxfilterinfo/) {
         $result = $adapter->$method($dupConfigHash);
      } else {
         $result = $adapter->$method(@value);
      }
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure $config on $macAddr");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      #
      # If Passthrough verification flag is passed, then call the appropriate
      # method (GetvNicUPTStatus() for UPT) to verify the status
      #
      if (defined $passthrough &&
         $passthrough =~ /upt/i) {
         $vdLogger->Info("Passthrough verification for $config");
         my $vmOpsObj;
         my $hostObj;
         if (($adapter->{intType} eq 'vnic') || ($adapter->{intType} eq 'pci')) {
            $vmOpsObj = $adapter->{vmOpsObj};
            $hostObj = $vmOpsObj->{hostObj};
         } elsif (($adapter->{intType} eq 'vmnic') ||
                 ($adapter->{intType} eq 'vmknic')) {
           $hostObj = $adapter->{hostObj};
         }

         #
         # The status of a a given vNIC is verified using GetvNicUPTStatus().
         # It takes few seconds to reflect the changes in VSI Node after any
         # opeartion on the vNIC. So, sleep is defined here to give some time
         # vNIC to report the correct status.
         #
         sleep(15);
         my $uptStatus= $hostObj->GetvNicUPTStatus($macAddr,
                                                   $adapter->{vsiPort});
         if ($uptStatus eq FAILURE) {
            $vdLogger->Error("Failed to get UPT status");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Info("UPT status of $macAddr : $uptStatus");
         my $expectedStatus = $configNames{$config}{'upt'}{'status'};

         if ($config eq "devicestatus") {
             if ($adapterConfigHash->{$config} =~ /down/i) {
                #
                # devicestatus with param DOWN is a special case where the
                # pass status is VNIC_DISABLED and not OK
                #
                $expectedStatus = "VNIC_DISABLED";
             }
          }

         if (defined $expectedStatus) {
            if ($uptStatus !~ $expectedStatus) {
               $vdLogger->Error("Expected UPT status $expectedStatus is " .
                                "different from returned status $uptStatus");
               VDSetLastError("EMISMATCH");
               return FAILURE;
            }
         }
         #
         # TODO - verify passthru transition once hostd provides passthrough
         # history for all the adapters.
         #
      }

   }
   return SUCCESS;
}


########################################################################
#
# ConfigureVLAN --
#      This method configures vlan on the given network adapter.
#
# Input:
#      target:  SUT or helper<x>
#      adapter: NetAdapter object corresponding to the network adapter
#      vlanID : a valid vlan id from 1 - 4096. If 0 is passed, then
#      any vlan configured on the given adapter is removed.
#
# Results:
#      - NetAdapter object for the child/vlan interface created;
#      - 0, if vlan is removed successfully;
#      - "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ConfigureVLAN {
   my $self    = shift;
   my $adapter = shift;
   my $vlanID  = shift;
   my $ipv4    = shift;
   my $vlanInterface = 0;

   if ((not defined $adapter) || (not defined $vlanID)) {
      $vdLogger->Error("Valid NetAdapter object and/or vlan id not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # If the given vlan id is zero, then remove any vlan configuration on the
   # given adapter.
   #

   my $addID = undef; # default to vlan being requested
   my $removeID = undef;
   my $configuredVLANId = $adapter->GetVLANId();

   if ($vlanID eq "0") {
      if ($configuredVLANId eq "0") {
         # if both wanted and existing vlan id is 0, return 0
         return 0;
      } else {
         # wanted vlan is 0, someother vlan already exists, then remove that
         $removeID = $configuredVLANId;
         $addID = undef;
      }
   } else { # wanted vlan is non-zero
      if ($configuredVLANId eq "0") {
         # existing vlan id is 0, then add
         $addID = $vlanID;
      } elsif ($configuredVLANId ne $vlanID) {
         # wanted and existing vlan ids are different, then
         # remove existing vlan and add wanted vlan
         $addID = $vlanID;
         $removeID = $configuredVLANId;
      } else {
         # if both existing and wanted vlan id is same,
         # calling SetVLAN will do nothing,
         $vdLogger->Info("VLAN id wanted $vlanID and existing value " .
                         "$configuredVLANId are same");
         $addID = $vlanID;
         $removeID = undef;
      }
   }

   if (defined $removeID) {
      $vdLogger->Info("Removing VLAN $removeID on adapter ".
                      $adapter->{'macAddress'} .
                      " on $adapter->{controlIP}");
      my $result = $adapter->RemoveVLAN();
      if ($result eq "FAILURE") {
         VDSetLastError(VDGetLastError());
         $vdLogger->Info("Removing VLAN ID failed");
         return FAILURE;
      }
   }

   if (defined $addID) {

      my $ip = $ipv4;
      my $netmask = VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK;

      #
      # SetVLAN() method in NetAdapter requires ip address and netmask to be used
      # for the child/vlan interface, so finding any available class C ip address
      #
      if (not defined $ip) {
         $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($adapter->{controlIP});
         if ($ip eq FAILURE) {
            $vdLogger->Error("Failed to get free IP address");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }

      #
      #
      # Now, call SetVLAN() method in NetAdapter to configure vlan on the given
      # interface.
      #
      $vdLogger->Info("Configuring VLAN $vlanID on adapter ".
                      $adapter->{'macAddress'} . " with ip " . $ip .
                      " on $adapter->{controlIP}");
      $vlanInterface = $adapter->SetVLAN($vlanID, $ip, $netmask);

      if ($vlanInterface eq FAILURE) {
         $vdLogger->Error("Failed to configure VLAN adapter at " .
                          $adapter->{controlIP});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   #
   # Skip updating parent about vlan configuration if the guest os is windows.
   # There is no child node created for vlan and less confusion in windows.
   #
   my $os = $adapter->{vmOpsObj}{os};
   if ((defined $os) && ($os =~ /win/i) ) {
      $vdLogger->Info("Not updating parent about vlan " .
                      "since the guest is windows");
      return 0;
   }

   my %paramsHash = (
      machine         => $adapter,
      addVLANID       => $addID,
      removeVLANID    => $removeID,
      parentInterface => $adapter->{'interface'},
      vlanNetObj      => $vlanInterface,
      intType         => $adapter->{'intType'},
   );
   return \%paramsHash;
}


########################################################################
# ConfigureWoL --
#      This method updates the vmx option corresponding to the given
#      adapter to configure WoL.
#      WoL feature requires adding/updating vmx entry
#      "ethernetX.wakeOnPcktRcv" as well as configuring the network
#      adapter. This method takes care of just of the first step.
#      ConfigureComponent() will handle the second step.
#
# Input:
#      adapter: NetAdapter object corresponding to the adapter on which
#               WoL has to be configured
#      value  : Enable or Disable
#      stafHelper : staf helper object used from the testbed
#
# Results:
#      SUCCESS, if the WoL related vmx option is updated successfully;
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub ConfigureWoL
{
   my $self = shift;
   my $adapter = shift;
   my $value   = shift;
   my $stafHelper = shift;

   my $ipConfigured = $adapter->GetIPv4();

   if (not defined $adapter || not defined $value) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   #Finding the vmx value based on the given WoL configuration option
   #
   $value = ($value =~ /disable/i) ? "FALSE" : "TRUE";

   my $mac = $adapter->{'macAddress'};
   if (not defined $mac || $mac eq FAILURE) {
      $vdLogger->Error("MAC address undefined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Setting WoL option to $value in vmx file");
   my @list = ("wakeOnPcktRcv = $value");
   my $vmOpsObj = $adapter->{vmOpsObj};
   my $hostObj  = $vmOpsObj->{hostObj};
   my $result = $self->{testbed}->UpdateEthernetVMXOptions($vmOpsObj,
                                                     $mac,
                                                     \@list);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure WoL in vmx file");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Now check if chipset.onlineStandby is set to TRUE
   my $standbyStatus;
   my $pattern = "^chipset.onlineStandby";

   my $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmOpsObj->{vmx});
   if ( (not defined $vmxFile) || ($vmxFile eq FAILURE) ) {
      $vdLogger->Error("vmxFile is not defined for $hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }

   $standbyStatus = VDNetLib::Common::Utilities::CheckForPatternInVMX($hostObj->{hostIP},
                                                                 $vmxFile,
                                                                 $pattern);
   if ((not defined $standbyStatus) || ($standbyStatus !~ /true/i)) {
      # power off the VM
      $vdLogger->Info("Bringing $vmOpsObj->{vmIP} down to update vmx file");
      if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
         $vdLogger->Error( "Powering off VM failed");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      sleep(30);
      $vdLogger->Info("Adding vmx entry chipset.onlineStandby=True");
      my @list = ('chipset.onlineStandby = "TRUE"');
      $result = VDNetLib::Common::Utilities::UpdateVMX($hostObj->{hostIP},
                                                  \@list,
                                                  $vmxFile);
      if ( ($result eq FAILURE) || (not defined $result) ) {
         $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() " .
                             "failed while updating VMX");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      # power on the VM
      if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
         $vdLogger->Error( "Powering on VM failed ");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      $vdLogger->Info("Waiting for STAF on $vmOpsObj->{vmIP} to come up");
      $result = $stafHelper->WaitForSTAF($vmOpsObj->{vmIP});
      if ( $result ne SUCCESS ) {
         $vdLogger->Info("STAF is not running on $vmOpsObj->{vmIP}");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      $vdLogger->Info("STAF on $vmOpsObj->{vmIP} came up");
   }

   #
   # When the guest goes through a power reset, the ip address configured
   # may not be available. Therefore, checking if a valid ipv4 address is
   # available. If not, configure the same address that was configured before
   # the power reset.
   #
   # TODO: WoL test involves 3 steps: configuring wol, putting the guest to
   # sleep and lastly wake up using unicast/arp/magic packet. Currently, all
   # the three steps are done together. As reported in PR711790, step 1, 2 and
   # 3 should be separate keys. Once PR711790 is fixed, the following block
   # can be removed.
   #
   my $ipv4 = $adapter->GetIPv4();
   my $netmask = VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK;
   if (($ipv4 eq FAILURE) || ($ipv4 eq "NULL")) {
      VDCleanErrorStack();
      $result = $adapter->SetIPv4($ipConfigured, $netmask);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure $ipConfigured on " .
                          $adapter->{controlIP});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # We have to disable vmkernel sending IGMP queuries to vNICs, otherwise
   # as soon as we put the VM to standby, these IGMP requests will wake up
   # the VM.
   #
   my %tempHash = (
      '/config/Net/intOpts/IGMPQueries' => 0,
   );
   $result = $hostObj->VMKConfig("disable", \%tempHash);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to disable IGMPQueries vsish node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# VerifyWoL --
#	This method verifies the WoL feature by putting the VM to
#	standby, sending magic pkt/ARP/ping to wake up the VM and
#	then verifies if the VM really woke up.
#
# Input:
#      adapter: NetAdapter object corresponding to the adapter on which
#               WoL has to be verified
#      value  : WoL parameter
#
#
# Results:
#      SUCCESS, if the WoL works as expected
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub VerifyWoL
{
   my $self = shift;
   my $adapter = shift;
   my $value   = shift;
   my $supportAdapter = shift;
   my $stafHelper = $self->{testbed}->{stafHelper};
   my $stafResult;
   my $cmd;
   my $pingCmd;
   my $dir;
   my $result;

   if (not defined $adapter) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $vmOpsObj = $adapter->{vmOpsObj};
   my $helperVMObj = $supportAdapter->{vmOpsObj};

   if (not defined $helperVMObj) {
      $vdLogger->Error("No Helper machine available to verify WoL");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $os =  $helperVMObj->{os};
   my $helperIP =  $helperVMObj->{vmIP};

   if ((not defined $os || not defined $helperIP) && ($value !~ /MAGIC/)) {
      $vdLogger->Error("One or more parameters are missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Get the test adapter's IP address
   my $testIP    = $adapter->GetIPv4();
   my $supportIP = $supportAdapter->GetIPv4();

   if (($testIP eq FAILURE) || ($supportIP eq FAILURE)) {
      $vdLogger->Error("Failed to get test and/or helper ip address");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $testMAC = $adapter->{'macAddress'};
   # form the pind cmd
   if ( $os =~ /lin/i ) {
      $pingCmd = "ping -c 5";
   } else {
      $pingCmd = "ping";
      # Windows needs mac address with '-' as delimiter
      $testMAC =~ s/:/-/g;
   }

   # Check if the test adapter on SUT and helper can communicate,
   # otherwise after putting the VM to standby we won't be able to
   # wake up the VM for UNICAST/ARP case. Also for MAGIC case, ARP
   # entry for test vNIC has to exist in helper VM to be able to
   # send magic pkts.
   $cmd = $pingCmd . " $testIP";
   $stafResult = $stafHelper->STAFSyncProcess($helperIP, $cmd);
   if (($STAF::kOk != $stafResult->{rc}) || ($stafResult->{exitCode})) {
         $vdLogger->Error("Failed to ping test adapter on SUT from helper");
         VDSetLastError("ESTAF");
         return FAILURE;
   }
   my $ndisVersion = $adapter->GetNDISVersion();
   my $interfaceName = $adapter->GetInterfaceName();

   # Add static ARP entry on helper VM which is required to wake
   # the VM
   if ($value =~ /MAGIC/i) {
      # Add the ARP entry to make sure magic pkts reach test adapter
      if ( $os =~ /lin/i ) {
         $cmd = "arp -s $testIP $testMAC";
      } else {
         # Using netsh command for newer Guests as arp has some known
         # issues with these newer Guests
         if ($ndisVersion =~ /6.\d/) {
            $cmd = "netsh interface ipv4 add neighbors \"$interfaceName\" $testIP $testMAC";
         } else {
            # For windows, we have to pass the interface IP where we want to add
            # this ARP entry otherwise it will add it to the first interface table
            # in ARP cache which might be control interface.
            $cmd = "arp -s $testIP $testMAC $supportIP";
         }
      }
      $stafResult = $stafHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to add the ARP entry");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # Put the VM to standby
   $result = $vmOpsObj->VMOpsStandby($vmOpsObj->{'vmIP'});
   if ($result eq FAILURE) {
      $vdLogger->Error("Putting the VM to standby failed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Check if WoL is disabled on control adapter, if it's not then it might
   # wake up the VM because of traffic on public network.
   my $ip = $adapter->{controlIP};
   my $loss = "0";
   # Maximum time to wait to check if the VM woke up
   my $timeout = STANDBY_TIMEOUT;
   while ($loss < "100" && $timeout > 0) {
      sleep(DEFAULT_SLEEP);
      $cmd = `ping -c 5 $ip`;
      if ($cmd =~ /(\d+)\%.*loss/i) {
         $loss = $1;
      }
      $timeout = $timeout - 20;
   }

   if ($timeout == 0) {
      $vdLogger->Error("Either WoL is enabled on control adapter or it's buggy".
		      ", if it's enabled please disable it and rerun the test");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($value =~ /ARP/i) {
      # Goto to helper machine, delete the arp entry for source machine
      $cmd = "arp -d $testIP";
      $stafResult = $stafHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to delete SUT ARP entry from helper VM");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
    }

    # Send MAGIC/ARP/UNICAST pkt to wake up the guest
    if ($value =~ /MAGIC/i) {
      $vdLogger->Info("Sending magic pkt");
      my $args = $testIP . "," . $adapter->{'macAddress'};
      $result = VDNetLib::Common::LocalAgent::ExecuteRemoteMethod($helperIP,
                                                       "SendMagicPkt", $args);
      if ($result eq FAILURE) {
        $vdLogger->Error("Failed to send MAGIC pkt");
        VDSetLastError(VDGetLastError());
        return FAILURE;
      }
    } elsif (($value =~ /UNICAST/i) || ($value =~ /ARP/)) {
      $vdLogger->Info("Waking up the guest using ping packet");
      $cmd = "$pingCmd $testIP";
      $stafResult = $stafHelper->STAFSyncProcess($helperIP, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to ping the SUT from helper");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unsupported WoL flag");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Verify if the VM woke up
   $loss = "10";
   $timeout = STANDBY_TIMEOUT;
   while ($loss != "0" && $timeout > 0) {
      sleep(DEFAULT_SLEEP);
      $cmd = `ping -c 5 $ip`;
      if ($cmd =~ /(\d+)\%.*loss/i) {
         $timeout = $timeout - 20;
         $loss = $1;
      } else {
         $loss = $1;
         last;
      }
   }

   if ($loss != 0) {
      $vdLogger->Error("VM didn't wake up");
      $vdLogger->Error("Restarting SUT since it might have got " .
			 "stuck in sleep state");
      my $options;
      $options->{waitForTools} = 1;
      my $result = $vmOpsObj->VMOpsReset($options);
      if ($result eq FAILURE) {
         $vdLogger->Error("Reset VM failed");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# InitDefaultNIC --
#      This method sets the default configuration on the given adapter
#      if the user did not specify any value for these (ipv4, mtu, vlan)
#      keys.
#
# Input:
#      adapter: NetAdapter object on which configuration has to be done
#      adaperConfigHash: A part of the workload hash with just the
#                        network configuration keys
#
# Results:
#      SUCCESS, if the default configuration is done;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub InitDefaultNIC {
   my $self              = shift;
   my $adapter           = $self->{adapter};
   my $adapterConfigHash = $self->{testkeysHash};

   # TODO remove the following code since it's not necessary
   return SUCCESS;

    if ((not defined $adapter) || (not defined $adapterConfigHash)) {
      $vdLogger->Error("Target, NetAdapter object and/or adapter " .
                        "configuration hash not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $dupConfig;
   my $result;

   # Enable the device before use
   $result = $adapter->GetDeviceStatus();
   if ($result =~ /DOWN/i) {
      $result = $adapter->SetDeviceStatus("UP");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to enable device $adapter->{macAddress}" .
                          "on adapter $self->{'testAdapter'}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # set IPv4 = AUTO, if user did not specify a value in the workload hash
   if (not defined $adapterConfigHash->{'ipv4'}) {
      $result = $adapter->GetIPv4();
      if (($result eq "NULL") || ($result =~ m/^169/)) {
         $dupConfig->{'ipv4'} = "AUTO";
      }
   }

   # set MTU = 1500, if user did not specify a value in the workload hash
   if (not defined $adapterConfigHash->{'mtu'}) {
      $result = $adapter->GetMTU();
      if ($result gt "1500") {
         $dupConfig->{'mtu'} = "1500";
      }
   }


   # Configure the above features
   if (defined $dupConfig) {
      $result = $self->ConfigureNIC($dupConfig);
      if ($result eq FAILURE) {
         $vdLogger->Error("Default ConfigureNIC() failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # TODO: Move InitDefaultNic() to Workloads.pm where virtual
   # adapters are initialized. Calling InitDefault() for every workload hash
   # will overwrite the configuration done in previous workload hash.
   # This problem is not yet seen in existing test cases. But, need to be moved
   # for next release of vdNet (this message is written on 3/15/11)
   #
   # Remove if any vlan configuration on the adapter if the user did not
   # specify any value for VLAN key in the workload hash.
   #
   if ($adapter->{'intType'} eq "vnic") {
      if (not defined $adapterConfigHash->{'vlan'}) {
        $dupConfig->{'vlan'} = 0;

         $result = $self->ConfigureVLAN($adapter, $dupConfig->{'vlan'});
         if ($result eq FAILURE) {
            $vdLogger->Error("Configuring VLAN failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# IsFeatureSupported --
#      This method finds whether the given configuration/feature is
#      supported on the given driver under test.
#
# Input:
#      driverName : name of the driver (vmxnet3,vmxnet2,e1000,e1000e
#                                       vlance).
#      featureName: name of the network adapter feature like mtu,rss etc
#      testbedInfo: reference to a hash that has all the testbed details
#                   The keys in this hash should match the testbed
#                   configuration keys in VDNetLib::Common::FeaturesMatrix.
#      vdFeatureInfo: reference to the hash %vdFeatures in
#                     VDNetLib::Common::FeaturesMatrix
#
# Results:
#      1 - if the feature is supported on the given testbed;
#      0 - if the feature is not supported on the given testbed;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub IsFeatureSupported
{
   my $self = shift;
   my $driverName = shift;
   my $featureName = shift;
   my $testbedInfo = shift;
   my $vdFeatureInfo = shift;

   if (not defined $driverName || not defined $featureName ||
       not defined $testbedInfo || not defined $vdFeatureInfo) {
      $vdLogger->Error("One or more parameters missing $driverName," .
                       "$featureName, $testbedInfo, $vdFeatureInfo");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $testbed = $self->{'testbed'};

   #
   # Get the sub-hash i.e hash within VDNetLib::Common::FeaturesMatrix::vdFeatures
   # corresponding to the given featureName.
   #
   my $feature = $vdFeatureInfo->{$featureName};
   if (not defined $feature) {
      $vdLogger->Error("Feature $featureName not defined or unknown");
      VDSetLastError("ENOTDEF");
      return 0;
   }

   #
   # Get the hash within the feature hash corresponding to the driver/device
   # under test.
   #
   my $deviceFeature = $feature->{$driverName};

   if (not defined $deviceFeature) {
      $vdLogger->Skip("$driverName does not support $featureName," .
                      " skipping $featureName configuration");
      return 0;
   }

   # Go through each testbed configuration key and find whether the
   # value of the corresponding key in the given testbed matches.
   #
   my @orderOfValidation = ('platform', 'guestos', 'ndisversion',
                            'kernelversion');

   foreach my $item (@orderOfValidation) {
      #
      # If a particular testbed config key is not defined in the features
      # matrix, then it is assumed that it can be ignored.
      # The same assumption applies when current testbed info has a value
      # "NA".
      #
      if ((not defined $deviceFeature->{$item}) ||
          (defined $testbedInfo->{$item} && $testbedInfo->{$item} eq "NA")) {
         next;
      }

      if (not defined $testbedInfo->{$item}) {
	      $vdLogger->Info("$item is not defined on given " .
                         "testbed matrix, " .
                         "skipping $featureName configuration");
         return 0;
      }

      if ((defined $testbedInfo->{$item})&& ($item =~ /kernelversion/i) ){
	      # Now check if the kernelversion is supported
	      if ($deviceFeature->{$item} =~ /all/i) {
                 return 1;
	      } else {
                 my @supportkernelversions = split /,/, $deviceFeature->{$item};
                 my @kernelversion = split /\./, $testbedInfo->{$item};
                 my $kernelmajor = $kernelversion[0];
                 my $kernelminor = $kernelversion[1];
                 my $kernelfinal = $kernelversion[2];
                 my $isSupported = 0;
                 foreach my $supportkernelversion (@supportkernelversions) {
                    my @kernelnum = split /\./,$supportkernelversion;
                    if ((defined $kernelnum[0] && $kernelnum[0] == $kernelmajor) &&
                        (defined $kernelnum[1] && $kernelnum[1] == $kernelminor)) {
                       if ((not defined $kernelnum[2]) || ($kernelfinal >= $kernelnum[2])) {
                          $isSupported = 1;
                          last;
                       }
                    }
                 }
                 if ($isSupported == 0) {
                    $vdLogger->Info($testbedInfo->{$item} . " is not supported value " .
	                            "for $item, so skipping $featureName configuration " .
	                            "on $driverName device");
                 }
                 return $isSupported;
              }
          # Now check if the driverversion is supported
	      if (defined $deviceFeature->{driverversion}) {
		      # Driver version will be defined like 1.0.X.0, get X now
              # to compare
                  my @ddevInfo = split('\.', $deviceFeature->{driverversion});
	          my @dtbInfo = split('\.', $testbedInfo->{driverversion});
	          if ((defined $ddevInfo[2]) && ($dtbInfo[2] >= $ddevInfo[2])) {
		          return 1;
		      } else {
			      $vdLogger->Info($testbedInfo->{driverversion} .
                                  " is not supported driverversion " .
                                  "for $featureName, so skipping the" .
                                  " configuration");
                  return 0;
              }
           }
     }
   }
   return 1;
}

#######################################################################
#  InterruptProcessing --
#       This can be used as entry point for all tests involving
#       interrupt mode operations.
#       Following tasks are planned:
#       1. If OS is windows, edit appropriate registry entries
#       2. Get Mac of adapter and eth name of the adapter
#       3. Power off the VM
#       4. Edit the vmx file for required configuration
#       5. poweron the vm
#       6. Get vsi PortNumber for mac address and verify the
#          vsish status for mask information.
#       7. For linux verify the type of interrupt. for windows
#          there is no proper verification method, so verify
#          vmware.log.
#
#      The Automode and Active Mode has following interrupt codes
#      ===================================================
#               AutoMode      ActiveMode
#      ===================================================
#      INTX        1                5
#      MSI         2                6
#      MSI-x       3                7
#      ===================================================
#
# Input:
#
#       adapter - adapter object based on the tuple
#       modeValue - based on the interrupt mode value
#       stafHelper - stafHelper object used from the testbed hash
#
# Results:
#      PASS in case of no erorrs
#      FAIL in case of any errors
#
# Side effetcs:
#       none
#######################################################################

sub InterruptProcessing
{
   my $self = shift;
   my $adapter = shift;
   my $modeValue   = shift;
   my $stafHelper = shift;

   if (not defined $adapter || not defined $modeValue) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($modeValue !~ /AUTO-INTX|AUTO-MSI|AUTO-MSIX/ and
       $modeValue !~ /ACTIVE-INTX|ACTIVE-MSI|ACTIVE-MSIX/) {
      $vdLogger->Error("Invalid Interrupt mode supplied ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $srcMac = $adapter->{'macAddress'};
   if (not defined $srcMac) {
      $vdLogger->Error("Unable to get src MAC address");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $vmOpsObj = $adapter->{vmOpsObj};
   my $hostObj = $vmOpsObj->{hostObj};
   if (not defined $vmOpsObj || not defined $hostObj) {
      $vdLogger->Error("Unable to get vm/host operations object");
      VDSetLastError("EINVALID");
      return FAILURE;
   }


   my $ret = "PASS";
   my ($command, $data, $debug, $data1);
   my @suffixlist = ("vmx","log");
   my $modeString;

   if (defined $modeValue) {
       # This Section Covers the interrupt mode configuration
       # and Initial verification

       # Create object of VDNetLib::GlobalConfig
       my $gc = VDNetLib::Common::GlobalConfig->new();

       # Collect test parameters
       my $srcControlIP = $adapter->{controlIP};
       my $srcTestIP = $adapter->GetIPv4();
       my $srcHostIP = $hostObj->{hostIP};
       my $sutOS = $vmOpsObj->{os};

       my $vmxfile = VDNetLib::Common::Utilities::GetAbsFileofVMX(
							$vmOpsObj->{'vmx'});
       if ($vmxfile eq "FAILURE") {
          $vdLogger->Error("Failed to get VMX filename");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       my $ethUnit = VDNetLib::Common::Utilities::GetEthUnitNum($srcHostIP,
                                                           $vmxfile,
                                                           $srcMac);
       if ($ethUnit eq "FAILURE") {
          $vdLogger->Error("Failed to get ethernet unit number");
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Collect the directory name from vmxfile name
       my ($name,$path,$suffix) = fileparse($vmxfile,@suffixlist);
       my $vmwarelog = "$path"."vmware.log";

       if ($sutOS =~ /lin/i) {
	   my ($minorVersion, $majorVersion) =
                VDNetLib::Common::Utilities::GetKernelVersion(
						$srcControlIP,
						$stafHelper);
           $modeString = $gc->GetInterruptString($modeValue, $minorVersion, $majorVersion);
           $ethUnit = $adapter->{interface};
       } else {
           $modeString = $gc->GetInterruptString($modeValue);
       }
       $ethUnit =~ /(\d+)$/;
       my $modeNum = $1;
       $modeString = "$modeString"."$modeNum" if defined $modeNum;
       # Get the corresponding INTR mode number
       $modeValue = $gc->GetInterruptMode($modeValue);

       if ($ret eq "SUCCESS") {
          $vdLogger->Info("Interrupt mode already set to specified value");
          return SUCCESS;
       }
       # Set the registry keys if Source adapter os is
       # windows. We can either modify the inf file or
       # do away with registry key settings. But after
       # setting the registry key make sure to power
       # cycle the vm for the keys to take effect.
       if ($sutOS =~ /win/) {
          # query to see if the keys DisableAutoMask, DisableMSI
          # and DisableMSI-x are available, if not add them
          ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "query");
          if ($ret eq "FAILURE") {
              $vdLogger->Error("Failed to obtain the registry key information");
              VDSetLastError("EFAIL");
              return FAILURE;
          }

          if (not defined $data) {
             $data = "";
          }
          # Check if DisabelAutoMask registry key exists, if not
          # create/add it
          if ($data !~  /DisableAutoMask/) {
             # Add the registry key - DisableAutoMask
             ($ret, $data1) = ConfigureIntKey($stafHelper, $srcControlIP, "add",
                                              "DisableAutoMask");
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableAutoMask");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # Check if DisabelMSI registry key exists, if not
          # create/add it
          if ($data !~  /DisableMSI/) {
             # Add the registry key - DisableMSI
             ($ret, $data1) = ConfigureIntKey($stafHelper, $srcControlIP, "add",
                                              "DisableMSI");
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableMSI");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # Check if DisabelMSI-x registry key exists, if not
          # create/add it
          if ($data !~  /DisableMSI-x/) {
             # Add the registry key - DisableMSI-x
             ($ret, $data1) = ConfigureIntKey($stafHelper, $srcControlIP, "add",
                                              "DisableMSI-x");
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableMSI-x");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # modeValue less than 4 indicates auto mode and greater than
          # 4 indicates active mode
          if ($modeValue < 4) {
             # DisableAutoMask to be set to 0
             ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "set",
                                             "DisableAutoMask");
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to unset the registry key " .
					"DisableAutoMask");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          } else {
             # DisableAutoMask to be set to 1
             ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "unset",
                                             "DisableAutoMask");
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key " .
					"DisableAutoMask");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # Check for error in previous command.
          if ($ret eq "FAILURE") {
             $vdLogger->Error("Failed to configure the registry key " .
				"DisableAutoMask");
             VDSetLastError("EFAIL");
             return FAILURE;
          }

          # If interrupt mode to be set is INTX, set disable MSI
          # and MSI-x registry keys
          if ($modeValue == 1 or $modeValue == 5) {
              # Unet - DisableMSI
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "unset",
                                              "DisableMSI");
              if ($ret eq "FAILURE") {
                  $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI");
                  VDSetLastError("EFAIL");
                  return FAILURE;
              }

              # Unset - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "unset",
                                              "DisableMSI-x");
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }
          } elsif ($modeValue == 2 or $modeValue == 6) {
              # If interrupt mode to be set is MSI, set enable MSI
              # and disable MSI-x registry keys

              # set the registry key - DisableMSI
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "set",
                                              "DisableMSI");
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }

              # Unset - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "unset",
                                              "DisableMSI-x");
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }
          } elsif ($modeValue == 3 or $modeValue == 7) {
              # If interrupt mode to be set is MSIx, set disable MSI
              # and enable MSI-x registry keys

              # set the registry key - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "set",
                                              "DisableMSI-x");
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }

              # Unset - DisableMSI
              ($ret, $data) = ConfigureIntKey($stafHelper, $srcControlIP, "unset",
                                              "DisableMSI");
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key " .
					"DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }
          }
       }

       # Create an object of VMOps and power off the VM
       $vdLogger->Info("Powering off the VM for INTR mode changes " .
                       "to take effect");
       if ( $vmOpsObj->VMOpsShutdownUsingCLI() eq FAILURE ) {
          $vdLogger->Error("VM poweroff returned failed");
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       sleep(15);

       # build a command for deleting an vmx entry
       # The EditFile method defined in VDNetLib::Utilities module
       # takes in few arguments such as task to either add
       # an entry into file, delete an entry from file or
       # modify an entry from file. Also provides task for
       # querying the entry from file. In the following we
       # are deleting an entry named ethernetx.intrMode = "Y"
       # from vmx file for the given mac address. X indicates
       # ethUnit number and Y indicates the interrupt mode.
       my ($line, $arg);
       $line = "$ethUnit"."\."."intrMode"." = ";
       $arg = "$vmxfile"."\*"."'delete'"."\*"."$line";
       $vdLogger->Info("Editing a VMX file for reseting interrupt".
                           " mode if set earlier");

       $ret = VDNetLib::Common::Utilities::ExecuteMethod($srcHostIP,
                                                         "EditFile",
                                                         "'$arg'");
       # Build command for an vmx entry
       $line = "$ethUnit"."\."."intrMode"." = \\\"$modeValue\\\"";
       $arg = "$vmxfile"."\*"."'insert'"."\*"."$line";
       $vdLogger->Info("Editing a VMX file for interrupt mode");
       my @list = ("intrMode = $modeValue");
       my $vmOpsObj = $adapter->{vmOpsObj};
       $ret = $self->{testbed}->UpdateEthernetVMXOptions($vmOpsObj,
                                                         $srcMac,
                                                         \@list,
                                                         $stafHelper);
       if ($ret eq FAILURE) {
          $vdLogger->Error("Failed to add vmx entry");
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }

       # Power on the VM
       $vdLogger->Info("Powering on the VM");
       if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
          $vdLogger->Error("VM poweron returned failed");
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # Check for staf to come up
       $vdLogger->Info("Waiting for STAF on $srcControlIP to come up");
       $ret = $stafHelper->WaitForSTAF($srcControlIP);
       if ($ret eq FAILURE) {
           $vdLogger->Error("STAF is not running on $srcControlIP");
           VDSetLastError("EINVALID");
           return FAILURE;
       }
       $vdLogger->Info("STAF on $srcControlIP came up");

       sleep(200);

       # Create an object of hostoperations module to obtain the
       # vsi node number for mac address to verify automode value
       # to verify that interrupt mode is set correctly
       my $vsiNode = $hostObj->GetvNicVSIPort($srcMac);
       if ( $vsiNode eq FAILURE ) {
          $vdLogger->Error("Fetching VSI node from MAC failed");
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       # Following commands will get the vsi node status for interrupt
       # mode being in auto mode or active mode.The output looks like:
       # intr stats of a vmxnet3 vNIC {
       #    autoMask:1
       #    intr stats:stats of the individual intr {
       #       actions posted:23
       #       actions posted with hint:0
       #       actions avoided:2
       #    }
       # }
       #
       # Here autoMask: 1 indicates that auto mode of interrupt is set
       # Here autoMask: 0 indicates that active mode of interrupt is set
       $command = "vsish -e get $vsiNode/vmxnet3/intrSummary";
       $ret = $stafHelper->STAFSyncProcess($srcHostIP,
                                                      $command);
       $data = $ret->{stdout};
       # check for success or failure of the command
       if ($ret eq "FAILURE" or $data eq "") {
           $vdLogger->Error("Failed to obtain the interrupt mode summary");
           VDSetLastError("EFAIL");
           return FAILURE;
       }
       # First level verification for correct interrupt mode
       $data =~ /autoMask:(\d+)/;
       my $mask = $1;
       # Check for Auto Masking interrupt mode
       if ($modeValue < 4 and $mask eq "1") {
           $vdLogger->Info("Interrupt Mode auto mask is set correctly");
       } elsif ($modeValue > 4 and $mask eq "0") {
           # Check for Active Masking interrupt mode
           $vdLogger->Info("Interrupt Mode active mask is set correctly");
       } else {
           $vdLogger->Error("Failed to set correct Interrupt Mode mask");
           VDSetLastError("EFAIL");
           return FAILURE;
       }
       # Verify the INTR mode
       if ($sutOS =~ /lin/i) {
          $ret = GetCurrentIntrMode($sutOS, $srcControlIP, $stafHelper,
                                    $modeString, $vmwarelog);
       } else {
          $ret = GetCurrentIntrMode($sutOS, $srcHostIP, $stafHelper,
                                    $ethUnit, $vmwarelog, $modeValue);
       }
       if ($ret eq "FAILURE") {
          $vdLogger->Error("Failed to verify interrupt mode info");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
       $vdLogger->Info("Interrupt mode verified successfully");
       return SUCCESS;
   } else {
      $vdLogger->Error("No Interrupt mode passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
#  GetCurrentIntrMode --
#       This method can be used to get the current interrupt mode
#
# Input:
#       sutOS:            SUT OS (required)
#       srcIP:            SUT control IP Address (for Linux) or
#			  Host IP (for Windows)
#       testbed:          Testbed object
#       modeStrORethUnit: Ethernet unit number (for Windows)
#			  or modeString (for Linux)
#       vmwarelog:        vmware.log path
#
# Results:
#      SUCCESS
#      FAILURE in case of any failures
#
# Side effetcs:
#       Modifies the registry setting on windows vm
#
########################################################################

sub GetCurrentIntrMode
{
   my $sutOS= shift;
   my $srcIP = shift;
   my $stafHelper = shift;
   # If the sutOS is Linux, then the following value should be modeString
   # otherwise for Windows it should be ethUnit
   my $modeStrORethUnit = shift;
   my $vmwarelog = shift;
   my $modeValue = shift;

   my ($command, $ret, $data, $line);
   # Verify the results for linux OS
   if ($sutOS =~ /lin/i) {
      if (not defined $modeStrORethUnit) {
         $vdLogger->Error("modeString parameter missing");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      # Following commands will get the vsi node status for interrupt
      # mode being in auto mode or active mode.
      $command = "cat /proc/interrupts";
      $ret = $stafHelper->STAFSyncProcess($srcIP,
                                          $command);
      if ($ret eq "FAILURE") {
         $vdLogger->Error("Failed to obtain interrupt mode info");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $data = $ret->{stdout};
      if ($data =~ /$modeStrORethUnit/) {
         $vdLogger->Info("Interrupt Mode verified and is set correctly");
         return SUCCESS;
      } else {
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } else {
      # Verify the results for windows OS
      if (not defined $modeStrORethUnit || not defined $vmwarelog) {
         $vdLogger->Error("One or more parameters missing");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # As there is no exact check in windows for interrupt mode
      # added a check to confirm the interrupt mode setting through
      # vmware.log content. (This check can be adopted to linux vm).
      $line = "$modeStrORethUnit"."\.intrMode"." = "."$modeValue";
      $command = "grep 'intrMode' $vmwarelog";
      $ret = $stafHelper->STAFSyncProcess($srcIP,
                                          $command);
      $data = $ret->{stdout};
      $data =~ s/\"//g;
      if ($data =~ /$line/) {
	      $vdLogger->Info("Interrupt Mode verified and is set correctly");
	      return SUCCESS;
      }else{
	      VDSetLastError("EFAIL");
	      return FAILURE;
      }
   }
}


########################################################################
#  ConfigureIntKey --
#       This method can be used for configuring interrupt mode key for
#       windows.(DisableAutoMask, DisableMSI and DisableMSI-x are the
#       keys.)
#
# Input:
#       Testbed hash
#       IP Address
#       Task (one of set/enable, unset/disable,delete/remove and add)
#       Key name
#
# Results:
#      SUCCESS
#      FAILURE in case of any failures
#
# Side effetcs:
#       Modifies the registry setting on windows vm
#
########################################################################

sub ConfigureIntKey
{
   my $stafHelper = shift;
   my $ip = shift;
   my $task = shift;
   my $key = shift;

   my ($command, $res);

   # Check for non empty inputs.
   if (($task eq "") or ($ip eq "")) {
      $vdLogger->Error("Invalid parameter supplied to ConfigureIntKey ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Check if task is simple query. For query the key
   # is not required. If task is other than query then
   # check if key is one among DisableAutoMask or DisableMSI
   # or DisableMSI-x
   if ($task !~ /query/) {
      if ($key !~ /DisableAutoMask|DisableMSI|DisableMSI-x/i) {
         $vdLogger->Error("Invalid Key name supplied");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   if (($task =~ /unset/i) || ($task =~ /add/i)) {
      # Edit the registry key - set to 0 (Setting 0 would cause the
      # Disable keys to enable them)
      $command = "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet".
                 "\\Services\\vmxnet3ndis6\\Parameters ".
                 "/v $key /t REG_DWORD /d 0x00000001 /f";
   } elsif ($task =~ /set/i) {
      # Edit the registry key - set to 1 (Setting 1 would cause the
      # Disable keys to be in Disabled State)
      $command = "reg add HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet".
                 "\\Services\\vmxnet3ndis6\\Parameters ".
                 "/v $key /t REG_DWORD /d 0x00000000 /f";
   } elsif (($task =~ /delete/i) || ($task =~ /remove/i)) {
      # Remove the registry key
      $command = "reg delete HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet".
                 "\\Services\\vmxnet3ndis6\\Parameters ".
                 "/v $key /f";
   } elsif ($task =~ /query/i) {
      # query the registry keys - DisableAutoMask/DisableMSI/DisableMSI-x
      $command = "reg query HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet".
                 "\\Services\\vmxnet3ndis6\\Parameters";
   } else {
      $vdLogger->Error("Invalid task mentioned");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Construct the command
   $res = $stafHelper->STAFSyncProcess($ip, $command);
   if ($res eq "FAILURE") {
      $vdLogger->Error("Failed to configure the registry key DisableAutoMask");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return (SUCCESS, $res->{stdout});
}


########################################################################
#
#  GetNetAdapterObject --
#       This method can be used for getting the desired net adapter obj
#
# Input:
#       testAdapter - a tuple or a number (mandatory)
#       target      - SUT/helper (v1) (optional)
#       interfaceType - can be either vmnic/vmknic/pci
#       supportAdapter - can be a tuple or number (optional)
#
# Results:
#      SUCCESS - return the reference to array containg the net
#                adapter obj
#      FAILURE in case of any failures
#
# Side effetcs:
#       None
#
########################################################################

sub GetNetAdapterObject
{
   my $self             = shift;
   my %args             = @_;
   my $testAdapter      = $args{testAdapter};
   my $target           = $args{target};
   my $interfaceType    = $args{interfaceType};
   my $type             = $args{inputType};
   my $supportAdapter   = $args{supportAdapter};

   my $tuple;

   if ((defined $type) && ($type eq "support")) {
      return $self->GetSupportAdapterObject($supportAdapter);
   }

   if (($self->{testbed}{version} == 1) && ($testAdapter =~ /^\d+$/)) {
      if ($interfaceType =~ /vmknic/i) {
         $tuple = "$target.vmknic.$testAdapter";
      } elsif ($interfaceType =~ /vmnic/i) {
         $tuple = "$target.vmnic.$testAdapter";
      } elsif ($interfaceType =~ /pci/i) {
         $tuple = "$target.pci.$testAdapter";
      } else {
         $tuple = "$target.vnic.$testAdapter";
      }
   } else {
      $tuple = $testAdapter;
   }

   $tuple =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
#  GetSupportAdapterObject --
#       This method can be used for getting the desired support
#       adapter obj
#
# Input:
#       supportAdapter - a tuple. if supportAdapter is undef, it means
#                        that support adapter was not defined in
#                        confighash, so set tuple to default tuple
#                        "helper1.vnic.1"
#
# Results:
#      SUCCESS - return the reference to array containg the support net
#                adapter obj
#      FAILURE in case of any failures
#
# Side effetcs:
#       None
#
########################################################################

sub GetSupportAdapterObject
{
   my $self         = shift;
   my $supportAdapter  = shift;
   my $tuple;

   if (($self->{testbed}{version} == 1) && (not defined $supportAdapter)) {
      $tuple = "helper1.vnic.1";
   } else {
      $tuple = "$supportAdapter";
   }

   $tuple =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
#  MTUPreProcess --
#       This method pushes mtu parameters into an array in proper oder
#       and returns the reference to array. The assumption here is that the
#       key will "not" have either add/delete as value.
#
# Input:
#       runtimeParamsHash - reference to the hash containing values which
#                           will be used as arguments.
#       argumentOrder     - reference to array of params defined under action
#                           key.
#
# Results:
#      SUCCESS - return reference to array if array is filled with values
#      FAILURE - incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub MTUPreProcess
{
   my $self              = shift;
   my $adapter           = shift;
   my $keyName           = shift;
   my $keyValue          = shift;
   my $runtimeParamsHash = shift;
   my $argumentOrder     = shift;

   my $vmOpsObj   = $adapter->{vmOpsObj};
   my $os         = $vmOpsObj->{os};
   if (($adapter->{'intType'} =~ /vnic/i) &&
       ($os =~ /win/i) && int($keyValue) < 1500) {
      $vdLogger->Warn("The given MTU size:" . "$keyValue," .
                      " is not supported on Windows. ".
                      "Hence skipping this testcase...");
      return "SKIP";
   }
   return $self->PreProcessShiftTypeAPI($adapter,
                                        $keyName,
                                        $keyValue,
                                        $runtimeParamsHash,
                                        $argumentOrder);
}


########################################################################
#
#  MTUPostProcess --
#       This method is used for event handling, when we want to update
#       the testbed infrastructure.
#
# Input:
#
# Results:
#
# Side effetcs:
#       None
#
########################################################################

sub MTUPostProcess
{
   return SUCCESS;
}


########################################################################
#
#  ResolveIPv6AddrKey --
#       This method returns IPv6 address
#
# Input:
#       ipv6Addr - value can be either 'default' or 'address'
#       adapter  - net adapter object
#
# Results:
#      SUCCESS - return the IPv6 address.
#      FAILURE - incase of failure.
# Side effetcs:
#       None
#
########################################################################

sub ResolveIPv6AddrKey
{
   my $self     = shift;
   my $ipv6Addr = shift;
   my $adapter  = shift;

   my $macAddr  = $adapter->{'macAddress'};
   my $ip;

   if ($ipv6Addr =~ /default/i) {
      #
      # "DEFAULT" is the special value for IPV6, which indicates that this
      # package should assign an ipv6 address automatically.
      # GetAvailableTestIP() utility function gives an ipv6 address
      # to use based on the MAC Address.
      #
      $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($adapter->{controlIP},
                                                            $macAddr,"ipv6");
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get IPV6 address");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      # If user specified a specific ipv6 address, then use that.
      $ip = $ipv6Addr;
   }

   return $ip;
}


########################################################################
#
#  IPv6PostProcess --
#       This method is used for event handling, when we want to update
#       the testbed infrastructure.
#
# Input:
#
# Results:
#
# Side effetcs:
#       None
#
########################################################################

sub IPv6PostProcess
{
   return SUCCESS; #Event handler
}


########################################################################
#
#  TemplatePostProcess --
#      Call SetComponentObject() and update the datasructure based on the input
#
# Input:
#      updateValue - Value that needs to be updated in the Testbed
#
# Results:
#      SUCCESS - if updating the Testbed datastructure was successful.
#      FAILURE - incase of any failure
#
# Side effetcs:
#      None
#
########################################################################

sub TemplatePostProcess
{

}


########################################################################
#
#  TemplateParam1Method --
#      Call SetComponentObject() and update the datasructure based on the input
#
# Input:
#      input - either a tuple or a value that needs to sent as an argument
#
# Results:
#      SUCCESS - return the final value based on the input
#      FAILURE - incase of any failure
#
# Side effetcs:
#      None
#
########################################################################

sub TemplateParam1Method
{

}


########################################################################
#
#  CreateAdapterFeatureHash --
#      The purpose of the api is to construct adapterFeatureHash which
#      consists of driverName, vdFeatureMatrix and testbedInfo.
#
# Input:
#      adapter - network adapter object for which adapterFeatureHash needs
#                to be constructed.
#
# Results:
#      SUCCESS - return the refernece to adapterFeatureHash
#      FAILURE - incase of any failure
#
# Side effetcs:
#      None
#
########################################################################

sub CreateAdapterFeatureHash
{
   my $self = shift;
   my $adapter = shift;
   my $adapterConfigHash = shift;

   my $adapterFeatureHash;
   # Adding vmnic to the check
   if (defined $adapter->{'intType'} and ($adapter->{'intType'} eq "vnic" ||
      $adapter->{'intType'} eq "vmnic")) {
      #
      # Get information to fill $adapterFeatureHash
      # In case interface is "vmnic", pass the testbedInfo as simply
      # "vmnic" since there are no values to be matched with inside
      # FeaturesMatrix
      #
      my $testbedInfo;
      if ((defined $adapter->{vmOpsObj}->{'vmType'}) &&
          ($adapter->{vmOpsObj}->{'vmType'} eq 'appliance')) {
         $testbedInfo = "appliance";
      } elsif ($adapter->{'intType'} eq "vnic") {
         # PR 1142157, we stop to change $adapter->{interface} to parent interface
         # if it is vlan interface. Test case owner should use correct
         # net adapter and use vlan interface if needed in workloads.

         # Check PR1431970. When the vm entered powered off or suspend status,
         # access to the vm is closed. So, we skip to get 'CollectTestbedDetails'.
         my $vmOpsObj = $adapter->{vmOpsObj};
         my $result = $vmOpsObj->VMOpsGetPowerState();
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to get VM $vmOpsObj->{vmx} power state");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # We need to get the testbed details for wakeupguest workload
         # because of two reasons. First of all the guest is  supposed
         # to be in standby mode when wakeupguest workload is made  to
         # execute and hence CollectTestbedDetails() would be resulting
         # in failures.  Second one is that this testbedinfo is  being
         # used only fy IsFeatureSupported function. Before getting to
         # run this wakeupguest, user would have already run "standby"
         # workload and  if that  feature is  not supported anyways we
         # will not reach at next workload, i.e: wakeupguest
         #

         if (($result->{result} =~ /poweredOff/i ) ||
            ( $result->{result} =~ /suspended/i ) ||
            (defined $adapterConfigHash->{'wakeupguest'})) {
            $testbedInfo = "vnic";
         } else {
            $testbedInfo = $self->{testbed}->CollectTestbedDetails($adapter);
         }
      } else {
         $testbedInfo = "vmnic";
      }
      if ($testbedInfo eq FAILURE) {
         $vdLogger->Error("Failed to get testbed info");
         VDSetLastError(VDGetLastError());
         return "FAIL";
         }
      $adapterFeatureHash->{testbedInfo} = $testbedInfo;

      #
      # Get the drivername being under test
      # If inttpye is vmnic, then driver name is already stored in
      # adapter object as "driver"
      #
      my $driverName = $adapter->{driver};

      if ((not defined $driverName) || ($driverName eq FAILURE)) {
         $vdLogger->Error("Failed to get driver name");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
      $adapterFeatureHash->{driverName} = $driverName;

      # Now, get the feature matrix for all virtual adapter features
      my $vdFeatureInfo = \%VDNetLib::Common::FeaturesMatrix::vdFeatures;
      if (not defined $vdFeatureInfo) {
         $vdLogger->Error("Failed to get vd features hash");
         VDSetLastError("ENOTDEF");
         return "FAIL";
      }
      $adapterFeatureHash->{vdFeatureMatrix} = $vdFeatureInfo;
   }
   return $adapterFeatureHash;
}


########################################################################
#
#  GetAdapterList --
#       This method is used in case of ver1 and retunr list of adapters
#
# Input:
#
# Results:
#      SUCCESS - returns the KEYSDATABASE hash.
#      FAILURE - incase of any failure.
#
# Side effetcs:
#       None
#
########################################################################

sub GetAdapterList
{
   my $self = shift;
   my %args         = @_;
   my $targets       = $args{targets} || "SUT";
   my $intType      = $args{intType} || "vnic";
   my $testAdapter  = $args{testAdapter} || "1";

   my @machines;
   my @returnArrayTuples;
   my $tuple;
   if (($testAdapter =~ /\.+/) || (($testAdapter =~ /\:+/))) {
      # $testAdapter is already in tuple format,
      # split testadapter and return the reference
      # array of tuples
      $testAdapter =~ s/\:/\./g;
      @returnArrayTuples = split(',', $testAdapter);
      return \@returnArrayTuples;
   }

   # The input taken is SUT,helper<x>,helper<y>. Split it by a Comma
   # and convert the data into an array for easy processing.
   if (defined $targets) {
      @machines = split(',',$targets);
   }

   # Filter out unnecessary spaces
   foreach my $machine (@machines) {
      $machine =~ s/^\s+//;
      $machine =~ s/\s+$//;
      # In case the target value is given as helper[1-N]
      my $machinePrefix = undef;
      my $newMachine = undef;
      my $min = 0;
      my $max = 0;
      if ($machine =~ /(.*)\[(.*)\]/) {
         $machinePrefix = $1;
         my $range = $2;
         if ((not defined $machinePrefix) || (not defined $range)) {
            $vdLogger->Error("Invalid machine name provided : $machine");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         ($min, $max) = split(/-/, $range);
         $max = (defined $max) ? $max : $min;
      }
      for (my $seq = $min; $seq <= $max; $seq++) {
         if (defined $machinePrefix) {
            $tuple = "$machinePrefix.$intType.$seq";
         } else {
            $tuple = "$machine.$intType.$testAdapter";
         }
         push @returnArrayTuples, $tuple
      }
   }
   return \@returnArrayTuples;
}


########################################################################
#
# ResolveIPv4AddrKey --
#     Method to process 'ipv4address' key.
#
# Input:
#     ipv4addr: auto/dhcp/ip in format <xxx>.<xxx>.<xxx>.<xxx>
#     adapter : reference to netadapter object
#     index   : name of the paramater key
#     componentIndex   - number, from below example the vnic index
#                        in array is 4.
#     component        - key that represents the sub-component
#                        creation, e.g. workload:
#                         Typte: VM
#                         TestVM: vm.[1]
#                         vnic:
#                            '[4]':
#                              driver: e1000
#
#                          In this case key is 'vnic'
#
# Results:
#     ip address, if successful;
#     FAILURE, in case error;
#
# Side effects:
#     None
#
########################################################################

sub ResolveIPv4AddrKey
{
   my $self     = shift;
   my $ipv4Addr = shift;
   my $adapter  = shift;
   my $index    = shift;
   my $componentIndexInArray = shift;
   my $component = shift;

   my $macAddr  = $adapter->{'macAddress'};
   my $ip;
   if ($ipv4Addr =~ /x=/) {
      # Looking for equation like
      # 'ipv4address' = 'x=vm_index*1.16.16.1'
      return $self->GenerateIPUsingEquation(
                                    $ipv4Addr,
                                    $adapter,
                                    $index,
                                    $componentIndexInArray,
                                    $component);
   }
   if ($ipv4Addr =~ /auto/i) {
      #
      # "auto" is the special value for IPv4, which indicates that this
      # package should assign an ipv4 address automatically.
      # GetAvailableTestIP() utility function gives an ipv4 address
      # to use based on the MAC Address.
      #
      # Note: this option will not work when adapter is being created since
      # it's mac address is unknown
      #
      $ip = VDNetLib::Common::Utilities::GetAvailableTestIP($adapter->{controlIP},
                                                            $macAddr, "ipv4");
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get IPV4 address");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      # If user specified a specific ipv4 address, then use that.
      $ip = $ipv4Addr;
   }

   return $ip;
}


########################################################################
#
# PreProcessReconfigureAdapter --
#     Method to preprocess parameters required to edit virtual
#     adapter configuration
#
# Input:
#     testObject  : reference to test adapter object
#     keyName     : key name for which this pre-process method is called
#     keyValue    : value of 'keyName'
#     paramValue  : list of parameters used to edit virtual adapter
#
# Results:
#     reference to an array which contains arguments needed to
#     edit virtual adapter
#
# Side effects:
#     None
#
########################################################################

sub PreProcessReconfigureAdapter
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue, $paramValue) = @_;
   my @arguments;
   my $specHash = {
      'portgroup'          => $paramValue->{'portgroup'},
      'driver'             => $paramValue->{'driver'},
      'connected'          => $paramValue->{'connected'},
      'startconnected'     => $paramValue->{'startconnected'},
      'allowguestcontrol'  => $paramValue->{'allowguestcontrol'},
      'shareslevel'        => $paramValue->{'shareslevel'},
      'shares'             => $paramValue->{'shares'},
      'reservation'        => $paramValue->{'reservation'},
      'limit'              => $paramValue->{'limit'},
      'ip'                 => $paramValue->{'ipv4address'},
      'netmask'            => $paramValue->{'netmask'},
      'vlanid'             => $paramValue->{'vlanid'},
      'macaddress'         => $paramValue->{'macaddress'},
      'binding'            => $paramValue->{'binding'},
      'service_bindings'   => $paramValue->{'service_bindings'},
      'network'            => $paramValue->{'network'}
   };
   push(@arguments, $specHash);
   return \@arguments;
}


########################################################################
#
# PreProcessNIOCVerification --
#     Method to compose the arguments for VerifyEntitlement()
#     in NetAdapter class
#
# Input:
#     testObject  : reference to test adapter object
#     keyName     : key name for which this pre-process method is called
#     keyValue    : value of 'keyName'
#     paramValue  : list of parameters used to edit virtual adapter
#
# Results:
#     reference to an array which contains arguments needed to
#     edit virtual adapter
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNIOCVerification
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue) = @_;
   my @arguments;

   if (ref($keyValue) ne "ARRAY") {
      $vdLogger->Error("Invalid value format");
   }
   my $netObjs;
   my @nodeList;
   foreach my $node (@$keyValue) {
      if ($node !~ /\./) {
         push(@nodeList, $node);
      } else {
         $netObjs = $self->GetComponentObjects($node);
         push(@nodeList, @$netObjs);
      }
   }
   push(@arguments, \@nodeList);
   return \@arguments;
}


########################################################################
#
# IPv4PreProcess --
#     Method to process "ipv4" property in testspec
#     and return the appropriate ipv4 address
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#     IP of host will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub IPv4PreProcess
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   if ($keyValue =~ /x=/) {
      # Looking for equation like
      # 'ipv4' = 'x=vm_index*1.16.16.1'
      $paramValue->{ipv4} = $self->GenerateIPUsingEquation(
                                            $keyValue,
                                            $testObject);
   }

   if ($keyValue =~ /auto/i) {
      #
      # "AUTO" is the special value for IPV4, which indicates that this
      # package should assign an ip address automatically.
      # GetAvailableTestIP() utility function gives an available class C
      # ip address to use.
      #
      $keyValue = VDNetLib::Common::Utilities::GetAvailableTestIP($testObject->{controlIP});
      if ($keyValue eq FAILURE) {
         $vdLogger->Error("Failed to get free IP address");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $paramValue->{ipv4} = $keyValue;
   }

   my @array ;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      }
   }

   # If user does not give the netmask value, use the default one.
   if (not defined $paramValue->{netmask}) {
      push(@array, VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK);
   }

   return \@array;
}


########################################################################
#
# PostProcessSetMACAddr --
#     Post process method for updating testbed hash with newly set MAC
#     address
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
# Results:
#     SUCCESS, if new object is updated successfully
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessSetMACAddr
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;

   # Retrieving the object of the existing vnic
   my $tuple = $self->{componentIndex};
   # Taking the backup of the old object
   $testObject->{originalMAC} =  $testObject->{macAddress};

   # Updating the testbed with the new vnic MAC address
   $testObject->{macAddress} = $keyValue;
   my $result = $self->{testbed}->SetComponentObject($tuple,
                                                     $testObject);
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to set the component Obj for newly ".
                       "set MAC Address");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# PostProcessReconfigureAdapter --
#     Post process method for updating adapter object
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
# Results:
#     SUCCESS, if new object is updated successfully
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessReconfigureAdapter
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   if ($testObject->{intType} =~ "vmknic") {
      $testObject->{pgObj} = $paramValues->{portgroup};
      my $result = $self->{testbed}->SetComponentObject($self->{componentIndex},
                                                        $testObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to set the component Obj for ".
                          "$self->{componentIndex}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   if ($testObject->{intType} =~ "vnic") {
      if (index($self->GetComponentIndex(),"vnic.[0]") != -1) {
         my $ip = $testObject->{vmOpsObj}->InitializeManagementAdapter($testObject);
         if ($ip eq FAILURE){
            $vdLogger->Error("Unable to get the new generated vm IP");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         } elsif (not $ip eq $testObject->{controlIP}) {
            return $self->{testbed}->UpdateControlIP($testObject->{vmOpsObj},
                                                  $ip);
         }
      }
   }

   return SUCCESS;
}

########################################################################
#
# PreProcessSetMACAddr --
#     Pre - process method for updating testbed hash with newly set MAC
#     address with key "setmacaddr"
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
# Results:
#     Array of params for method "SetMACAddr"
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################
sub PreProcessSetMACAddr
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   # Checking value of MAC Address passed
   if ($keyValue =~ /reset/i) {
      $paramValue->{setmacaddr} = $testObject->{originalMAC};
   }
   delete $testObject->{originalMAC};

   my @array;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      }
   }
   return \@array;
}

########################################################################
#
# PreProcessSetMACAddrAsHash --
#     Pre - process method for updating testbed hash with newly set MAC
#     address with key "set_mac_address"
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
# Results:
#     Array of params for method "set_mac_address"
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################
sub PreProcessSetMACAddrAsHash
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   # Checking value of MAC Address passed
   if ($keyValue =~ /reset/i) {
      $paramValue->{setmacaddr} = $testObject->{originalMAC};
   }
   delete $testObject->{originalMAC};
   if (@$paramList != 1) {
       $vdLogger->Error("set_mac_address method excepts exactly 1 new mac " .
                        "address, " . scalar(@$paramList) . "provided");
       return FAILURE;
   }
   my %returnHash;
   $returnHash{new_mac} = $paramValue->{@$paramList[0]};
   my @array;
   push(@array, \%returnHash);
   return \@array;
}

########################################################################
#
# PostProcessConfigureVLAN --
#     Method to post-process key "vlan";
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessConfigureVLAN
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;

   my $addVLANID       = $runtimeResult->{addVLANID};
   my $removeVLANID    = $runtimeResult->{removeVLANID};
   my $vlanNetObj      = $runtimeResult->{vlanNetObj};
   my $intType         = $runtimeResult->{intType} || "vnic";

   if ((not defined $addVLANID) && (not defined $removeVLANID)) {
      $vdLogger->Debug("Do nothing as addVLANID and removeVLANID not defined");
      return SUCCESS;
   }

   # Retrieving the object of the existing vnic
   my $tuple = $self->{componentIndex};
   my $result = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $result) {
      $vdLogger->Error("Invalid ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $adapterRef = $result->[0];

   if (defined $removeVLANID) {
      $vdLogger->Debug("Removing child object from testbed spec");
      # Object stored in $tuple must be a vlan interface object;
      if (defined $adapterRef->{'parentObj'}) {
         $result = $self->{testbed}->SetComponentObject($tuple, "delete");
         if ($result eq FAILURE) {
            $vdLogger->Error("Unable to delete vlan $tuple from zookeeper");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }

         $adapterRef->{'parentObj'}{'objID'} =  $adapterRef->{'objID'};
         $result = $self->{testbed}->SetComponentObject($tuple,
                                     $adapterRef->{'parentObj'});
         if ($result eq FAILURE) {
            $vdLogger->Error("Unable to SetComponentObject for $tuple");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $adapterRef->{'parentObj'} = undef;
      } else {
         $vdLogger->Error("parentObj in vlan interface object not defined " .
                          "in tuple $tuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   if (defined $addVLANID) {
      if (not defined $vlanNetObj) {
         $vdLogger->Error("vlanNetObj not provided to proceed");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      delete $adapterRef->{'objID'};
      $vlanNetObj->{'parentObj'} = $adapterRef;
      $result = $self->{testbed}->SetComponentObject($tuple,
                                                     $vlanNetObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to SetComponentObject for $tuple");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# PreProcessARPCache --
#     Pre - process method for updating testbed hash with vmknic object
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
# Results:
#     Vmknic object, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessARPCache
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   # Retrieving the object of the vmknic
   my $result = $self->{testbed}->GetComponentObject($keyValue);
   if (not defined $result) {
      $vdLogger->Error("Invalid ref for tuple $keyValue");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $paramValue->{$keyName} = $result->[0];

   my @array;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      }
   }
   return \@array;
}

########################################################################
#
# PreProcessPnic --
#     Pre - process method for updating testbed hash with vmnic object
#
# Input:
#     testObject  : Testbed object being used here
#     keyName     : Name of the key being worked upon here
#     keyValue    : Value of the key being worked upon here
#     paramValues : Values of the params in the test hash
#     paramList   : List / order of the params being passed
#
#
# Results:
#     vmnic, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessPnic
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;
   my $nicplacement = $keyValue;
   my $returnValue;
   if($nicplacement =~ m/vmnic/i) {
      # Retrieving the object of the vmnic
      my $result = $self->{testbed}->GetComponentObject($nicplacement);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $nicplacement ");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $returnValue= $result->[0]->{'vmnic'};
    } else {
         $returnValue = $nicplacement;
    }
    my @array;
    push(@array, $returnValue);
    return \@array;
}

1;
