########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::VMWorkload;

#
# This package/module is used to run workload that involves executing
# VM operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VM::VMOperation object that this module
# uses extensively have to be registered in testbed object of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
#
# Management keys:-
# ---------------
# *Type        => "VM" (this is mandatory and the value should be same)
# Target       => SUT or helper1 or helper2 or helper<x>
# Verification => function pointer or another workload hash name
# Iterations   => # number of iterations
# Passthrough  => UPT would require to do additional verification to check
#                 for transitions between passthrough <-> emulation mode
# TestAdapter  => Indicates the index of the test adapter to be used.
#
# VM Operation Keys:-
# --------------------------
# *Operation   => reset, shutdown, reboot, hibernate,
#                 suspend,  removepcipassthruvm
#                 changeportgroup, killvm, killallpbyname, createsnap,
#                 reversnap, rmsnap
# SnapshotName => "<Name of the snapshot to create/revert/delete>"
#                 If one of the operations is createsnap or rmsnap or
#                 revertsnap, this value will be used. If not specified,
#                 a unique name will be computed automatically for createsnap
#                 and current snapshot on the VM will be used for revertsnap
#                 and rmsnap
#
use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger PERSIST_DATA_REGEX);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE SKIP VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Workloads::Utils;
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::NetAdapter::Vmnic::Vmnic;
use Storable 'dclone';
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass);

########################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::VMWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::Workloads::VMWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'    => "testvm",
      'componentIndex' => undef,
      };

   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


########################################################################
#
# StartWorkload --
#      This method will process the workload hash of type 'VM'
#      and execute necessary operations on the specified target and
#      Index for n number of Iterations.
#
# Input:
#      None
#
# Results:
#     "PASS", if workload is executed successfully,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the VM workload being executed
#
########################################################################

sub StartWorkload
{
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   #
   # if the target is "SUT,helper[4-5]", $targetindex for them are 0,1,2
   # This is for some scalability cases which involve mappings of test vm
   # and other paramters (like portgroup).
   #
   my $targetindex = 0;

   # Copy 'Operation' key from the workload hash and copy it in a duplicate
   # hash and pass the duplicate hash as parameter to create an Iterator
   # object.
   #
   # To each combination of the workload hash returned from Iterator,
   # execute the VM operation.
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
   my $testVM = $dupWorkload->{'testvm'};
   my $target = $dupWorkload->{'target'};
   my @tempArry;

   if ((not defined $testVM) && ($self->{testbed}{version} == 1)) {
      $target = (defined $target) ? $target : "SUT";
      my @arr = split(/,/, $target);
      @tempArry = map {"$arr[$_]".":vm:1"} 0..$#arr;
      $testVM = join (',', @tempArry);
   }

   # If testvm is the format as ->\w.*->, then
   # read actual vdnet index from persist data
   if ($testVM =~ PERSIST_DATA_REGEX) {
      my $hash_ref = {};
      $hash_ref->{'vmkey'} = $testVM;
      my $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                                 $hash_ref,
                                                                 'vmkey');
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get vm index from persist data");
         VDSetLastError("EOPFAILED");
         return "FAIL";
      } else {
         $testVM = $result;
         $vdLogger->Info("Retrieved actual testvm from persistdata is $testVM");
      }
   }

   my $sleepBetweenWorkloads = $dupWorkload->{'sleepbetweenworkloads'};

   my $verificationStyle;
   if ((exists $dupWorkload->{'verificationstyle'}) &&
      (defined $dupWorkload->{'verificationstyle'})) {
      $verificationStyle = $dupWorkload->{'verificationstyle'};
      delete $dupWorkload->{'verificationstyle'};
   } else {
      $verificationStyle = "default";
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

   my $noofretries = 1;
   if (defined $dupWorkload->{'noofretries'}) {
      $noofretries = $dupWorkload->{'noofretries'};
      delete $dupWorkload->{'noofretries'};
      $vdLogger->Info("Number of retries value $noofretries is given.");
   }
   #
   # In the workload hash, not all the keys represent the network configuration
   # to be made on the given adapter. There are keys that control how to run
   # the workload. These keys can be referred as management keys. The
   # management keys are removed from the duplicate hash
   my @mgmtKeys = ('type', 'iterations', 'target', 'testvm',
                   'passthrough','sleepbetweenworkloads');

   foreach my $key (@mgmtKeys) {
     delete $dupWorkload->{$key};
   }

   $vdLogger->Info("Number of Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");
      my @arrayVM = split($self->COMPONENT_DELIMITER, $testVM);
      my @newArray = ();
      foreach my $vmTuple (@arrayVM) {
         my $refArray = $self->{testbed}->GetAllComponentTuples($vmTuple);
         if ($refArray eq FAILURE) {
            $vdLogger->Error("Failed to get component tuples for $vmTuple");
               VDSetLastError(VDGetLastError());
            return "FAIL";
         }
         push @newArray, @$refArray;
      }
      foreach my $vm (@newArray) {
         $vm =~ s/\:/\./g;
         $vm =~ s/^\s+//;
         $self->SetComponentIndex($vm);
         # Because ProcessTestKeys() deletes keys from the workload hash
         # during processing we need to send a cloned copy of workload for
         # each iteration so that behavior is consistent
         my $clonedWorkload = dclone $dupWorkload;
         my $retryCount = 0;
         my $result = FAILURE;
         while ($retryCount < $noofretries) {
            if (defined $sleepBetweenWorkloads) {
                $vdLogger->Info("Sleep between workloads of value " .
                                "$sleepBetweenWorkloads is given. Sleeping ...");
                sleep($sleepBetweenWorkloads);
            }
            $result = $self->ProcessTestKeys($clonedWorkload, $vm,
                                             $verificationStyle, $persistData);
            $retryCount++;
            if ((defined $result) && (($result eq SUCCESS) or ($result eq SKIP))) {
               $vdLogger->Info("VMWorkload success execute the hash " .
                               "with retry $retryCount times");
               last;
            }

            $vdLogger->Info("VMWorkload failed execute the hash " .
                            "with retry $retryCount times");
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("Start Workload failed");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
      }# end of arrayVM loop
   } # end of iteration loop
   return "PASS";
}

########################################################################
#
# ProcessTestKeys --
#      This method will process the workload hash  of type 'VM'
#      and execute necessary operations (executes VM related
#      methods).
#
# Input:
#      dupWorkload :Reference to test keys Hash
#      vmObj: VMOperations object of the SUT/helper VM
#      target      :Target (SUT/helper<x>) on which the configuration is
#                   to be done
#      testAdapters:List of testadapters to run the operation on.
#
# Results:
#      "SUCCESS", if all the network configurations are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#     Depends on the NetAdapter workload being executed
#
########################################################################

sub ProcessTestKeys
{
   my $self = shift;
   my $dupWorkload = shift;
   my $testVM = shift;
   my $verificationStyle = shift;
   my $persistData = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   # If the key 'snapshotname' has "", then mark it as undef
   if (defined $dupWorkload->{'snapshotname'} &&
      $dupWorkload->{'snapshotname'} eq "") {
      $dupWorkload->{'snapshotname'} = undef;
   }

   my $runworkload;
   if (defined $dupWorkload->{'runworkload'}) {
      $runworkload = $dupWorkload->{'runworkload'};
      delete $dupWorkload->{'runworkload'};
   }

   #
   # Create an iterator object and find all possible combination of workloads
   # to be run. VMWorkload handles specific, and list type of values
   # for 'Operation' key. The iterator module takes care of
   # identifying these different data types and generates combination if more
   # than one VM Operation is provided.
   #
   my $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);

   my $configCount = 1;
   # NextCombination() method gives the first combination of keys
   my %vmOps = $iteratorObj->NextCombination();
   my $vmOpsHash = \%vmOps;
   while (%vmOps) {
      $vdLogger->Info("Working on configuration set $configCount");
      $vdLogger->Info(Dumper($vmOpsHash));
      $vdLogger->Info("Running VM workload on ".
                      "vm $testVM");
      my $sleepBetweenCombos = $dupWorkload->{'sleepbetweencombos'};
      if (defined $sleepBetweenCombos) {
         $vdLogger->Info("Sleep between combination of value " .
               "$sleepBetweenCombos is given. Sleeping ...");
         sleep($sleepBetweenCombos);
      }
      my $result = $self->ConfigureComponent(configHash => $vmOpsHash,
                                             tuple      => $testVM,
                                             verificationStyle => $verificationStyle,
                                             persistData => $persistData);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
        return FAILURE;
      }

      # Run workload for verification if runworkload in dupWorkload;
      if (defined $runworkload) {
         $vdLogger->Info("Processing runworkload hash for workload " .
                          "verification.");
         if ($self->RunChildWorkload($runworkload) eq FAILURE) {
            $vdLogger->Error("Failed to execute runworkload for verification: " .
                             Dumper($runworkload));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #
      %vmOps = $iteratorObj->NextCombination();
      $configCount++;
   }
   return SUCCESS;
}



########################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of VMWorkload
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

sub CleanUpWorkload
{
   my $self = shift;
   # TODO - there is no cleanup required as of now. Implement any
   # cleanup operation here if required in future.
   return "PASS";
}


########################################################################
#
# ConfigureComponent --
#      This method executes VM operations on the given target machine
#      (example: suspend, resume etc).
#
# Input:
#      vmObj: VMOperations object of the SUT/helper VM
#      vmOpsHash/config: A part of workload hash with vm 'operation' keys
#                        which is returned by Iterator after processing
#                        different data types.
#
# Result:
#      "SUCCESS", if all the network configurations are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureComponent
{
   my $self        = shift;
   my %args        = @_;
   my $vmOpsHash   = $args{configHash};
   my $testVM      = $args{tuple};
   my $vmObj       = $args{testObject};
   my $verificationStyle = $args{verificationStyle};
   my $persistData = $args{persistData};

   if (not defined $vmObj) {
      my $ref = $self->GetVMObjects($testVM);
      $vmObj = $ref->[0];
      if ((not defined $vmObj) || (not defined $vmOpsHash)) {
         $vdLogger->Error("VM Operation object and/or config hash not provided");
         $vdLogger->Error("vm object: $vmObj  hash: $vmOpsHash");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $vmOpsHash,
                                                 'tuple' => $testVM,
                                                 'testObject' => $vmObj,
                                                  verificationStyle => $verificationStyle,
						                         'persistData' => $persistData);

   # 1322076: As 'operation' has been defined as parameter key in
   # ParentWorkload, for legacy v1 key 'operation', we should process it
   # instead of return here.
   # For any legacy key, the SUPER::ConfigureComponent() return undef so we need
   # to figure out if the legacy code needs to be triggered or not.
   # Here we check if the result is undefined OR operation is defined, we assume
   # that keysDB part didnt get triggered and now the legacy code must be
   # triggered.

   if ((defined $result) && ($result =~ /FAILURE|SKIP|SUCCESS/) &&
        (not defined ($vmOpsHash->{'operation'}))) {
      return $result;
   }

   #
   # $result = undef is a temporary return value being
   # used currently until we port all the keys to the
   # new modular design. This condition says that the
   # Parent Workload's ConfigureComponent was not able
   # to configure the key because the key was not part
   # of the KEYSDATABASE, so the NetAdapterWorkload's
   # ConfigureComponent will try to confgure the key.
   #

   my $vmx = $vmObj->{vmx};
   if ($vmx eq FAILURE) {
      $vdLogger->Error("Failed to get vmx");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $operation  = $vmOpsHash->{'operation'};
   if (not defined $operation) {
      $vdLogger->Error("No VM Operation specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Find/Replace portgroupname with testpg key
   #
   my $testpg;
   my $target;
   if (defined $vmOpsHash->{portgroupname}) {
      $testpg = $vmOpsHash->{portgroupname};
      if (not defined $target) {
         $target = "SUT";
      }
   } elsif (defined $vmOpsHash->{testpg}) {
      $testpg = $vmOpsHash->{testpg};
   }
   my $pgName;
   if (defined $testpg) {
      my $portgroupRef = $self->GetPortGroupNames($testpg, $target);
      $pgName = $portgroupRef->[0];
      if (not defined $pgName) {
         $vdLogger->Error("No pgname found for $testpg");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   #
   # Some of the supported VM operations like CONNECTVIRTUALNIC,
   # DISCONNECTVIRTUALNIC, require virtual network adapter information.
   # User can provide this adapter information using the 'TestAdapter' key in
   # the workload hash.
   #
   my $testadapter = $vmOpsHash->{'testadapter'};
   if ($self->{testbed}{version} == 1) {
      if (defined $testadapter) {
         if (defined $testVM) {
            my @arr = split('\.',$testVM);
            $testadapter = "$arr[0].vnic.$testadapter";
         } else {
            $testadapter = "SUT.vnic.$testadapter";
         }
      } elsif (not defined $testadapter) {
         $testadapter = "SUT.vnic.1";
      }
   }
   #
   # Find the mac address of virtual network adapter if the requested
   # VM operation involves network adapter in the vm.
   #
   my $mac;
   my $netObj;
   if (defined $testadapter) {
      my @arr = split('\.', $testVM);
      my $adapterRef = $self->GetNetAdapterObject(testAdapter => $testadapter,
                                                  target      => $arr[0],
                                                  intType     => $vmOpsHash->{'inttype'});
      $netObj = $adapterRef->[0];
      $mac = $netObj->{'macAddress'};
      if ($mac eq FAILURE) {
         $vdLogger->Error("Failed to get mac address of" .
                          "$vmOpsHash->{'testadapter'}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   #
   # If Passthrough key is defined, then get the VDNetLib::Host::HostOperations
   # object for the given target SUT/helper<x> and retrieve the adapter's VSI
   # port number. This port information is needed for GetvNicUPTStatus() method
   # which is used to verify adapter's UPT status.
   #
   my $hostObj;
   my $vsiPort;

   $hostObj = $vmObj->{'hostObj'};
   if (not defined $hostObj) {
      $vdLogger->Error("HostOperations object not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # Store the method names in VDNetLib::VM::VMOperations class for
   # every vm operation supported.
   #
   # Also, store the UPT end status after each operation and transition state,
   # if any, that needs to be verified while doing the VM operation.
   #



   my %operationNames = (
      'validatemac'  => {
         'method'           => 'VMOpsValidateMAC',
         'param'            => {
            allocschema  => $vmOpsHash->{'allocschema'},
            parameters   => $vmOpsHash->{'macvalues'},
            vmobj        => $vmObj,
         },
      },
      'createsnap'         => {
         'method'          => 'VMOpsTakeSnapshot',
         'param'           => $vmOpsHash->{'snapshotname'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => 'VM_OP',
         },
      },
      'revertsnap'         => {
         'method'          => 'VMOpsRevertSnapshot',
         'param'           => {
            SnapShotName  => $vmOpsHash->{'snapshotname'},
            ControlIP     => $vmObj->{controlIP},
      },
      'upt'             => {
            # vsi node will be lost
            'transition'   => undef,
         },
      },
      'rmsnap'             => {
         'method'          => 'VMOpsDeleteSnapshot',
         'param'           => $vmOpsHash->{'snapshotname'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'reset'              => {
         'method'          => 'VMOpsReset',
         'param'           => {
            waitForTools  => 0,
             waitForSTAF   => 0,
      },
      'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'shutdown'           => {
         'method'          => 'VMOpsShutdown',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'killallpbyname'           => {
         'method'          => 'KillAllPByName',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'reboot'           => {
         'method'          => 'VMOpsRebootUsingSDK',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'hibernate'          => {
         'method'          => 'VMOpsHibernate',
         'upt'             => {
            'status'       => 'VNIC_FEATURES',
            'transition'   => undef,
         },
      },
      'standby'            => {
         'method'          => 'VMOpsStandby',
         'upt'             => {
            'status'       => 'VNIC_FEATURES',
            'transition'   => undef,
         },
      },
      'sendkeystrokes'            => {
         'method'          => 'SendKeystrokes',
      },
      'killvm'             => {
         'method'          => 'VMOpsKill',
         'upt'             => {
            'status'       => '',
            'transition'   => undef,
         },
      },
      'changeportgroup'    => {
         'method'          => 'VMOpsChangePortgroup',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'removepcipassthruvm'=> {
         'method'          => 'VMOpsRemovePCIPassthru',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'removecdrom'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "cdrom,remove",
      },
      'addcdrom'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "cdrom,add",
      },
      'removefloppy'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "floppy,remove",
      },
      'addfloppy'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "floppy,add",
      },
      'removeserialport'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "serialport,remove",
      },
      'addserialport'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "serialport,add",
      },
     'removeparallelport'   => {
        'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "parallelport,remove",
      },
      'addparallelport'   => {
         'method'          => 'VMOpsAddRemoveVirtualDevice',
         'param'           => "parallelport,add",
      },
     'configurevmotion'   => {
        'method'          => 'VMOpsConfigureVMotion',
        'param'           => '',
      },
      'verifyvnicstate'    => {
         'method'          => 'GetLinkState',
         'param'           => $vmOpsHash->{'state'},
      },
     'configurenetdumpserver'  => {
        'method'            => 'VMOpsConfigureNetdumpServer',
        'param'             => {
            NetdumpConfig    => $vmOpsHash->{'netdumpparam'},
            NetdumpValue     => $vmOpsHash->{'netdumpvalue'},
         },
      },
      'logpathpermissions'  => {
         'method'            => 'VMOpsSetReadWrite',
         'param'             => {
          logdirectory    => $vmOpsHash->{'netdumpparam'},
          directoryproperties => $vmOpsHash->{'netdumpvalue'},
         },
      },
      'configureservice'  => {
        'method'            => 'VMOpsConfigureService',
        'param'             => {
          ServiceName      => $vmOpsHash->{'servicename'},
           ServiceAction    => $vmOpsHash->{'serviceaction'},
         },
      },
      'checknetdumpstatus'   => {
         'method'            => 'VMOpsCheckNetdumpStatus',
         'param'             => {
            NetdumpClientIP  =>
               $vmOpsHash->{'netdumpclientip'},
            NetdumpClientAdapter =>
               $vmOpsHash->{'clientadapter'},
         },
      },
      'netdumperservice'  => {
         'method'           => 'VMOpsNetdumperService',
         'param'            => $vmOpsHash->{'action'},
      },
      'verifynetdumperconfig'   => {
         'method'            => 'VMOpsVerifyNetdumpConfig',
         'param'             => {
            NetdumpConfig    => $vmOpsHash->{'netdumpparam'},
            NetdumpValue     => $vmOpsHash->{'netdumpvalue'},
         },
      },
      'installnetdumpserver'	=> {
         'method'            => 'VMOpsInstallNetdumpServer',
         'param'             => {
            NetdumpInstall   => $vmOpsHash->{'netdumpinstall'},
         },
      },
      'cleanupnetdumperlogs'   => {
         'method'            => 'VMOpsCleanNetdumperLogs',
      },
      'waitforvdnet'   => {
         'method'            => 'WaitForVDNet',
      },
      'vnicconnectiontype' => {
         'method'	     => 'VMOpsSetvNICConnectionType',
         'param'	     => {
            ConnectionType   => $vmOpsHash->{'ConnectionType'},
            MACAddress       => $mac,
            VMNet            => $vmOpsHash->{'VMNet'},
         },
      },
      'configurelinuxservice'  => {
         'method'            => 'VMOpsConfigureLinuxService',
         'param'             => {
            ServiceName      => $vmOpsHash->{'servicename'},
            ServiceAction    => $vmOpsHash->{'serviceaction'},
         },
      },
      'memoryovercommit'           => {
         'method'          => 'VMOpsMemoryOverCommit',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
   );

   #
   # Now, the keys in the given VMWorkload hash are processed one by
   # one.
   #
   # Find the VMOperation method name for each operation.
   #
   $operation = lc($operation);
   my $method = $operationNames{$operation}{'method'};
   if (not defined $method) {
      $vdLogger->Error("Method name not found for $operation operation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if($operation eq "verifyvnicstate") {
      return ($self->VerifyvNicStateInVM($netObj, $method,
      $operationNames{$operation}{'param'}));
   }

   if ($operation eq "checknetdumpstatus") {
      my $clienttestadapter = $operationNames{$operation}
      {'param'}{'NetdumpClientAdapter'};
      my $clientip = $operationNames{$operation}{'param'}{'NetdumpClientIP'};
      my @vals = split (/:/, $clienttestadapter);

      if ($clientip =~ m/auto/i) {
         my $refToArray = $self->{testbed}->GetComponentObject($clienttestadapter);
         my $netobj = $refToArray->[0];
         $operationNames{$operation}{'param'}{'NetdumpClientIP'} = $netobj->GetIPv4();
      } else {
        $vdLogger->Error("Incorrect vmknic adapter provided".
                         "to the workload");
        VDSetLastError(VDGetLastError());
        return FAILURE;
      }
   }

   #
   # If no snapshot name is given for 'creatsnap' operation, then generate a
   # unique snapshot name.
   #
   if ($operation eq "createsnap" &&
       not defined $vmOpsHash->{'snapshotname'}) {
      $operationNames{$operation}{'param'} = "vdnet-" . $$ .
      VDNetLib::Common::Utilities::GetTimeStamp();
   }

   my @value = ();

   if ($operation =~ /changeportgroup/i) {
      $vdLogger->Info("Using portgroup $pgName for this workload");
   }

   if ($operation eq "changeportgroup") {
      push(@value, $mac);
      push(@value, $pgName);
      push(@value, $vmOpsHash->{'anchor'}) if defined ($vmOpsHash->{'anchor'});
      push(@value, $vmOpsHash->{'testadapter'});
      push(@value, $vmOpsHash->{'portgrouptovnicmapping'})
      if defined ($vmOpsHash->{'portgrouptovnicmapping'});
   }

   if ($operation eq "killallpbyname") {
      push(@value, $vmOpsHash->{'processname'});
   }

   #
   # For the following operations we set the flag to wait on vdnet
   # share to be available before moving on to other operations
   # unless a user has already set the flag to 0
   #
   my @vmOps = ("revertsnap", "addcdrom", "removecdrom", "reset");
   foreach my $item (@vmOps) {
      if ($operation eq $item) {
         if (not defined $vmOpsHash->{'waitforvdnet'}) {
            $vmOpsHash->{'waitforvdnet'} = 1;
         }
         last;
      }
   }

   if ($operation eq "reboot") {
      # Pushing default value of 0 to method because it expects arguments in "shift"
      # and the first argument is "waitforreboot" and the success condition for this
      # argument is when user defines "waitforreboot" and the value is "1". Don't want
      # to change existing functionality.
      if (defined $vmOpsHash->{'waitforreboot'}) {
         push(@value, $vmOpsHash->{'waitforreboot'});
      } else {
         push(@value, "0");
      }
   }

   # Store the default parameters for each method here.
   if ($operationNames{$operation}{'param'}) {
      if (ref($operationNames{$operation}{'param'}) eq "ARRAY") {
         @value = @{$operationNames{$operation}{'param'}};
      } elsif($operationNames{$operation}{'param'} =~ /\,/) {
         @value = split(',',$operationNames{$operation}{'param'});
      } else {
         push(@value, $operationNames{$operation}{'param'});
      }
   }


   $vdLogger->Info("Executing $operation operation on $vmx" .
                   " with parameters " . join(',',@value));

   #
   # After figuring out the method name and parameters to execute a VM
   # operation, call the appropriate method.
   #
   $result = "FAILURE";
   $result = $vmObj->$method(@value);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to execute $operation on $vmx");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   #
   # If Passthrough verification flag is passed, then call the appropriate
   # method (GetvNicUPTStatus() for UPT) to verify the status
   #

   my $passthrough     = $netObj->{'virtualfunction'}; #P0
   if (defined $passthrough &&
      $passthrough =~ /upt/i) {
      if ($vmObj->VMOpsIsVMRunning()) {

         if ($netObj->GetLinkState() eq "Connected") {
            $vdLogger->Info("Passthrough verification for $operation");
            $vsiPort = $hostObj->GetvNicVSIPort($mac);
            if ($vsiPort eq FAILURE) {
               $vdLogger->Error("Failed to get vsi port for " .
                                $mac);
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            my $uptStatus= $hostObj->GetvNicUPTStatus($mac,
                                                      $vsiPort);
            if ($uptStatus eq FAILURE) {
               $vdLogger->Error("Failed to get UPT status");
               VDSetLastError(VDGetLastError());
            }

            $vdLogger->Info("UPT status of $mac : $uptStatus");
            my $expectedStatus = $operationNames{$operation}{'upt'}{'status'};
            if (defined $expectedStatus) {
               if ($uptStatus !~ $expectedStatus) {
                  $vdLogger->Error("Expected UPT status $expectedStatus is " .
                                   "different from returned status $uptStatus");
                  VDSetLastError("EMISMATCH");
                  return FAILURE;
               }
               #
               # TODO - verify passthru transition once hostd provides passthrough
               # history for all the adapters.
               #
            }
         }
      }
   }

   my $waitForVDNet = $vmOpsHash->{'waitforvdnet'};

   $waitForVDNet = (defined $waitForVDNet) ? $waitForVDNet : 0;
   if (int($waitForVDNet) != 0) {
      $vdLogger->Info("Waiting for vdnet source to be ready on $vmObj->{'vmx'}");
      # For windows vm, when VDNet does revertsnap ,vm asks for a new ip from the DHCPServer
      # So we add the sleep to make sure they can get new ip.
      if ($operation eq "revertsnap"){
          $vdLogger->Info(" For windows vm, when VDNet does revertsnap ,sleep 120s" .
                          " to make sure that VM can get the new ip.");
          sleep (120);
      }
      my $ipOld = $self->{'vmIP'};
      $result = $vmObj->WaitForVDNet();
      if ($result eq FAILURE) {
          $vdLogger->Error("Wait for vdnet returned failure");
           VDSetLastError(VDGetLastError());
           return FAILURE;
         }
      if ($ipOld ne $self->{'vmIP'}) {
          my $ret =  $self->{testbed}->SetComponentObject($testVM, $vmObj);
          if ($ret eq FAILURE) {
              $vdLogger->Error("Failed to update the testbed hash.");
              VDSetLastError(VDGetLastError());
              return FAILURE;
          }
      }
      $vdLogger->Info("vdnet source ready on $vmObj->{'vmx'}");
      }

   if ((int($waitForVDNet) != 0) || ($operation eq "waitforvdnet")) {
      if (FAILURE eq $self->{testbed}->CheckSetup($testVM)) {
         $vdLogger->Error("Failed to check setup");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   if (int($waitForVDNet) != 0 ) {
      my @paramArray;
      push(@paramArray, $testVM);
      if (defined $vmOpsHash->{'inttype'}) {
         if (FAILURE eq $self->{testbed}->SetEvent("PCIUpdate",
                                                   \@paramArray)) {
            $vdLogger->Error("Failed to update parent about PCI changes");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   #
   # check if 'setevent' key is defined the given VM operation, if yes call
   # SetEvent() with appropriate event name and parameters.
   #
   if (defined $operationNames{$operation}{setevent}) {
      my $eventName;
      my @paramArray;

      # Get the VM power state
      my $result = $vmObj->VMOpsGetPowerState();
      if ($result->{rc} != $STAF::kOk) {
         $vdLogger->Error("Unable to get VM power state");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # TODO: Need to call GetAllAdapters() before returning here to update
      # testbed hash with the newly added adapter.
      # If the VM is in the powered off state we don't have to send any events
      if ($result->{result} =~ /poweredoff/i) {
         return SUCCESS;
      }

      # Calling SetEvent() to update the parent process
      if (FAILURE eq $self->{testbed}->SetEvent($eventName,
                                                \@paramArray)) {
         $vdLogger->Error("Failed to update parent about " .
                          "event $eventName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# VerifyvNicStateInVM --
#      This method will verify whether the given vNic
#      is in the given expected "state".
#
# Input:
#      adapter: vNic object
#      method : Name of the final method to be executed
#      state  : expected state to be verified
#
# Results:
#     "PASS"   : if the given vNic is in the given expected state,
#     "FAILURE": Otherwisein case of any error;
#
# Side effects:
#     None
#
########################################################################

sub VerifyvNicStateInVM
{
   my $self	= shift;
   my $adapter	= shift;
   my $method	= shift;
   my $expstate	= shift;

   my $curstate  = undef;

   if (not defined $expstate) {
	 $vdLogger->Error("Required parameter not supplied for operation: " .
			  "VerifyvNicState. e.g. \"state\"");
	 VDSetLastError("ENOTDEF");
	 return FAILURE;
   }

   $curstate = $adapter->$method();
   if ($curstate eq FAILURE) {
      $vdLogger->Error("Failed to retrieve vNic's current state.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $expstate = lc($expstate);
   $curstate = lc($curstate);

   if ($expstate =~ m/connected|up/i) {
	 $expstate = "connected";
   } elsif ($expstate =~ m/disconnected|down/i) {
	 $expstate = "disconnected";
   } else {
	 $vdLogger->Error("Incorrect value specified for state key. " .
			  "Supported values are: connected/disconnected");
	 VDSetLastError("EINVALID");
	 return FAILURE;
   }

   if ($curstate ne $expstate) {
	 $vdLogger->Error("The current vNic state: $curstate, does not match " .
			  " with the expected state: $expstate.");
         VDSetLastError(VDGetLastError());
	 return FAILURE;
   }
   $vdLogger->Info("The current & expected vNic state is: $curstate");
   return SUCCESS;
}


########################################################################
#
# PreProcessCreateVnic --
#     Pre-process method to create vnic on a VM
#
# Input:
#     testObject: reference to VDNetLib::VM::VMOperations object
#     keyName   : vnic
#     keyValue  : refer to format under 'vnic' key in keys database
#
# Results:
#     reference to an array, which contains arguments needed to
#     create vnic
#
# Side effects:
#     None
#
########################################################################

sub PreProcessCreateVnic
{
   my $self   = shift;
   my $testObject = shift;
   my $keyName    = shift;
   my $keyValue   = shift;

   my @specArray;
   my @arguments;
   my $type = ($keyName =~ /pcipassthru/i) ? "pcipassthru" : "ethernet";
   $keyValue = VDNetLib::Common::Utilities::ExpandTuplesInSpec($keyValue);
   foreach my $index (sort (keys %$keyValue)) {
      $vdLogger->Debug("Processing for key $keyName and index $index");
      my $refNewConfigSpec = $self->CallLinkedWorkloadToTransformSpec(
                                                   $keyValue->{$index},
                                                   undef,
                                                   $keyName);
      if ($refNewConfigSpec eq FAILURE) {
         $vdLogger->Error("Failed to process vdnet config spec");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      #
      # for backward compatibility reasons, device is created
      # with connection state set to true
      #
      if (not defined $refNewConfigSpec->{'connected'}) {
         $refNewConfigSpec->{'connected'} = 1;
         $refNewConfigSpec->{'startconnected'} = 1;
         $refNewConfigSpec->{'allowguestcontrol'} = 1;
      }
      my $specHash = {
         'portgroup'          => $refNewConfigSpec->{'portgroup'},
         'driver'             => $refNewConfigSpec->{'driver'},
         'connected'          => $refNewConfigSpec->{'connected'},
         'startconnected'     => $refNewConfigSpec->{'startconnected'},
         'allowguestcontrol'  => $refNewConfigSpec->{'allowguestcontrol'},
         'shareslevel'        => $refNewConfigSpec->{'shareslevel'},
         'shares'             => $refNewConfigSpec->{'shares'},
         'reservation'        => $refNewConfigSpec->{'reservation'},
         'limit'              => $refNewConfigSpec->{'limit'},
         'vmnic'              => $refNewConfigSpec->{'vmnic'},
         'macaddress'         => $refNewConfigSpec->{'macaddress'},
         'virtualfunction'    => $refNewConfigSpec->{'virtualfunction'},
         'network'            => $refNewConfigSpec->{'network'},
      };
      if (defined $refNewConfigSpec->{'discover'}) {
          $specHash->{'discover'} = $refNewConfigSpec->{'discover'};
      }
      push(@specArray, $specHash);
   }
   push (@arguments, \@specArray, $type);
   return \@arguments;
}


########################################################################
#
# PreProcessChangeVMState --
#     Method to process "vmstate" property
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

sub PreProcessChangeVMState
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @arguments = ();
   my $args = {};
   if ($keyValue =~ /poweron/i) {
      $args->{'waitForTools'}  = $paramValues->{waitfortools};
      $args->{'waitForSTAF'}   = $paramValues->{waitforstaf};
      $args->{'waitForVDNet'}  = $paramValues->{waitforvdnet};
   } elsif ($keyValue =~ /resume/i) {
      $args->{'waitForTools'} = 'false';
      $args->{'waitForSTAF'}  = 'false';
      $args->{'controlIP'}    = $testObject->{controlIP}
   } elsif ($keyValue =~ /reboot/i) {
      $args->{'waitForTools'}  = $paramValues->{waitfortools};
      $args->{'waitForSTAF'}   = $paramValues->{waitforstaf};
      $args->{'waitForVDNet'}  = $paramValues->{waitforvdnet};
   }

   push(@arguments, $keyValue);
   push(@arguments, $args);
   return \@arguments;
}


########################################################################
#
# PreProcessDcCluster --
#     Method to process "DC/Cluster" property
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

sub PreProcessDcCluster
{
   my $self      = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   my $result = $self->{testbed}->GetComponentObject($keyValue);
   if (not defined $result) {
      $vdLogger->Error("Failed to get DC or Cluster object from Testbed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   push(@array, $result->[0]);
   return \@array;
}


########################################################################
#
# PreProcessDeleteVnic --
#     Method to process "deletevnic" property
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

sub PreProcessDeleteVnic
{
   my $self	 = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @objArray	 = ();
   my @arguments = ();
   my $type = ($keyName =~ /deletepcipassthru/i) ? "pcipassthru" :
              "ethernet";
   my $refArraryVnicObjects = $self->ConstructArrayOfObjects($testObject,
							     $keyName,
							     $keyValue);

   if ($refArraryVnicObjects eq FAILURE) {
      return FAILURE;
   }
   $refArraryVnicObjects = $refArraryVnicObjects->[0];
   push (@arguments, $refArraryVnicObjects, $type);

   return \@arguments;
}


########################################################################
#
# StoreVnicObjects --
#     Method to store vnic objects and initialize the vnic objects
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     SUCCESS, if the vnic object is stored and initiliazed
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub StoreVnicObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $ret) = @_;
   my $keyvalueobj = $keyValue->{1};
   my $param = $paramValues->{'vnic'};
   while(my($k,$v)=each(%$keyvalueobj)){$vdLogger->Info("keyValue:::$k--->$v");}
   while(my($k,$v)=each(%$param)){$vdLogger->Info("paramValues+++$k--->$v");}
   foreach my $r (@$ret) {
      $vdLogger->Info("The retcontent is: $r");
      while(my($k,$v)=each(%$r)){$vdLogger->Info("r+++$k--->$v");}
   }
   my $result = "FAILURE";
   $vdLogger->Info("The args: $testObject, $keyName, $keyValue, $paramValues, $ret");
   $result = $testObject->VMOpsGetPowerState();
   if ($result eq "FAILURE") {
      $vdLogger->Error("VMOpsGetPowerState() on $testObject returned FAILURE");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Warn("VM not powered on skipping vnic initialization");
      goto STORE;
   }
   if ((defined $testObject->{'vmType'}) &&
       ($testObject->{'vmType'} eq 'appliance')) {
      $vdLogger->Info("Skipping vnic initialization for an appliance VM");
      goto STORE;
   }

   sleep 5;
   $result = $testObject->InitializeVnicInterface($ret);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to run part 2 InitializeVnicInterface");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($ret eq "FAILURE") {
      $vdLogger->Info("ret is $ret");
   } else {
   #   while(my($k,$v)=each(%$ret)){$vdLogger->Info("ret:::$k--->$v");}                                                                                                                                                                       
   }

STORE:
   $result = $self->StoreSubComponentObjects($testObject,
                                                $keyName,
                                                $keyValue,
                                                $paramValues,
                                                $ret);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to run part 1 StoreSubComponentObjects");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return "SUCCESS";
}

########################################################################
#
# PostProcessChangeVMState --
#     Method to postprocess "vmstate" property
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

sub PostProcessChangeVMState
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   if ($keyValue =~ /poweroff|suspend|crash/i) {
      $vdLogger->Debug("Not running post process for key $keyValue");
      return SUCCESS;
   }

   my $controlIP    = $testObject->{'vmIP'};
   my $vmOperation  = $paramValues->{'vmstate'};
   my $waitForVDNet = $paramValues->{'waitforvdnet'};
   my $waitForTools = $paramValues->{'waitfortools'};
   my $waitForSTAF  = $paramValues->{'waitforstaf'};

   if ($keyValue =~ /poweroff|suspend|crash/i) {
      $vdLogger->Debug("Not running post process for key $keyValue");
      return SUCCESS;
   }

   if (($vmOperation =~ /poweron/i) || ($vmOperation =~ /reboot/i)) {
      if ($waitForVDNet =~ /true/i) {
         $vdLogger->Info("Option waitforvdnet is enabled");
         my $Result = VDNetLib::VM::VMOperations::WaitForVDNet($testObject);
         if ($Result eq 'FAILURE') {
            $vdLogger->Info("Unable to configure waitforvdnet.");
            return FAILURE;
         }
      }

      if ($waitForTools =~ /true/i) {
         $vdLogger->Info("Option waitfortools is enabled");
         my $Result = VDNetLib::VM::VMOperations::WaitForToolsUpgrade($testObject);
         if ($Result eq 'FAILURE') {
            $vdLogger->Info("Unable to configure waitfortools.");
            return FAILURE;
         }
      }

      if (($waitForSTAF =~ /true/i) && defined $controlIP) {
         # This branch is for resumed VM which already had IP address.
         return $self->{stafHelper}->WaitForSTAF($controlIP);
      } elsif ($waitForSTAF =~ /true/i) {
         return $self->{stafHelper}->WaitForSTAF($testObject->{'vmIP'});
      }
   }

   my $inventoryIndex = $self->{componentIndex};

   #
   # Below we need to check if VM IP changes after poweron and
   # inform zookeeper necessarily
   #
   my $vmObj  = $testObject;
   my $vm_type = (split(/[.]/, $inventoryIndex))[0];
   $vdLogger->Debug("PostProcessChangeVMState got" .
             "inventoryindex = $inventoryIndex, vm_type = $vm_type");
   #
   # when using testbed save/reuse option the vm ip may be changed
   # during power ops so unset it and let setup vm pick the
   # right ip address.
   #
   my $managementPortgroup;
   my $managementAdapterIndex = "$inventoryIndex.vnic.[0]";
   my $result = $self->{testbed}->CheckIfComponentExists($managementAdapterIndex, 'Debug');
   if (FAILURE eq $result) {
      $vdLogger->Debug("$managementAdapterIndex doesn't exist in zookeeper. Skip it.");
   } else {
      $managementPortgroup = $self->GetManagementPortgroup($managementAdapterIndex);
      if ($managementPortgroup eq FAILURE ) {
          $vdLogger->Error("Failed to get the management portgroup" .
                           " of vm $inventoryIndex");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }
   $vmObj->{vmIP} = undef;
   my %vdNetMountElements ;
   $vdNetMountElements{vdNetSrc} = $self->{testbed}->{vdNetSrc};
   $vdNetMountElements{vdNetShare} = $self->{testbed}->{vdNetShare};
   $result = $vmObj->SetupVM(\%vdNetMountElements, $managementPortgroup);
   if ($result  eq FAILURE ) {
       $vdLogger->Error( "Failed to setup the vm, post poweron...");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }

   $result = $self->{testbed}->SetComponentObject($inventoryIndex, $vmObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash for $inventoryIndex.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ((defined $vmObj->{'vmType'}) and ($vmObj->{'vmType'} =~ m/appliance/i)) {
      $vdLogger->Info("VM Type is appliance..skipping vnic initialization");
      return SUCCESS;
   }

   # Get the inventoryIndex 1 from vm.[1].x.[1e
   $inventoryIndex =~ s/\D//g;
   my @arrayOfVMCompomnent = ("vnic", "pcipassthru", "vif");
   foreach my $component (@arrayOfVMCompomnent) {
      my $vnicObjects =
         $self->{testbed}->GetComponentObject("$vm_type.[$inventoryIndex].$component.[-1]");
      my $OldVmIP = $vmObj->{vmIP};
      if ((scalar(@$vnicObjects)) &&
         ($vmObj->InitializeVnicInterface($vnicObjects, $managementPortgroup) eq FAILURE)) {
         $vdLogger->Error("Failed to initialize $component interfaces");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # This fixing for PR 1304957
      my $NewVmIP = $vmObj->{vmIP};
      if ($OldVmIP ne $NewVmIP) {
         $vdLogger->Info("VM IP changed after init VNic,sotre new VM IP in VM object");
         my $tuple = "$vm_type.[$inventoryIndex]";
         $self->{testbed}->SetComponentObject($tuple, $vmObj);
      }

      my $vnicTuples =
        $self->{testbed}->GetAllComponentTuples("$vm_type.[$inventoryIndex].$component.[-1]");
      my $count = 0;
      foreach my $tuple (@$vnicTuples) {
         my $vmOpsObj = $vnicObjects->[$count]->{vmOpsObj};
         $vnicObjects->[$count]->{controlIP} = $vmOpsObj->{vmIP};
         if (not defined $vnicObjects->[$count]->{controlIP}) {
            $vdLogger->Error("Control IP for $tuple not defined");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $self->{testbed}->SetComponentObject($tuple, $vnicObjects->[$count]);
         $count++;
      }
   }

   return SUCCESS;
}


#######################################################################
#
# GetManagementPortgroup --
#      This method will get the management portgroup for specified vm
#
# Input:
#      vmIndex: vm index
#
# Results:
#     managementPortgroup: name of the managementPortgroup in vm,
#     "FAILURE": Otherwisein case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetManagementPortgroup
{
   my $self = shift;
   my $managementAdapterIndex = shift;
   my $managementPortgroup;

   if (not defined $managementAdapterIndex) {
      $vdLogger->Error("Required parameter not supplied for operation: " .
                       "GetManagementPortgroup. e.g. \"managementAdapterIndex\"");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $controlObj =
      $self->{testbed}->GetComponentObject($managementAdapterIndex);
   if ($controlObj eq FAILURE) {
      $vdLogger->Error("Failed to get $managementAdapterIndex.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (defined $controlObj) {
      $managementPortgroup = $controlObj->[0]->GetPortgroupName();
      if ($managementPortgroup eq FAILURE) {
         $vdLogger->Error("Failed to get management portgroup name.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("The portgroup of management adapter is "
                       . Dumper($managementPortgroup));
   }
   return $managementPortgroup;
}


########################################################################
#
# PreProcessReconfigureVM --
#     Method to preprocess vm reconfiguration
#
# Input:
#     Same as Pre-Process template
#
# Results:
#     Same as Pre-process template
#
# Side effects:
#     None
#
########################################################################

sub PreProcessReconfigureVM
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue, $paramValue) = @_;
   my @arguments;
   my $specHash = {
      'instanceuuid'          => $paramValue->{'instanceuuid'},
   };
   push(@arguments, $specHash);
   return \@arguments;
}



########################################################################
#
# PostProcessUpdateVMHostObject
#     Method to postprocess "findin" property
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

sub PostProcessUpdateVMHostObject
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $dstobjID = undef;

   #
   # Update the current VM object to have new destination host Obj
   # Case 1. User intentionally does vMotion to different host
   # Case 2. In case of disaster stuck in HA and FT environment
   # The VM gets powered on a different host in this scenario thus we need to update it
   #
   $vdLogger->Debug("testObject".Dumper($testObject));
   $vdLogger->Debug("paramValues".Dumper($paramValues));
   my $vmObj = $testObject;
   my $host  = $vmObj->GetHostIP();
   if (defined $paramValues->{dsthost}) {
      my $dstHostObj = $paramValues->{dsthost}->[0];
      $dstobjID = $dstHostObj->{objID};
      $vdLogger->Debug("host: " . Dumper($dstHostObj));
      my $vmxPath = $dstHostObj->ReturnVMXPathIfVMExists($vmObj->{vmName});
      $vdLogger->Debug("vmxPath: " . Dumper($vmxPath));
      if ($vmxPath ne "FAILURE") {
         $host = $dstHostObj->{hostIP};
         $vdLogger->Debug("host: " . Dumper($host));
      }
   }

   if ($host eq FAILURE) {
      $vdLogger->Error("Failed to get host IP for $self->{componentIndex}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Host IP for $self->{componentIndex} is $host");

   if(($vmObj->{esxHost} =~ /$host/)  || ($vmObj->{_host} =~ /$host/)) {
      $vdLogger->Info("Host for $self->{componentIndex} did not change");
      return SUCCESS;
   } else {
      $vdLogger->Info("$self->{componentIndex} got relocated to $host");
   }

   my $newhostObj;
   my $allTupleString = "host.[-1]";
   if ((defined $dstobjID) && ($dstobjID =~ /esx/i)) {
      $allTupleString = "esx.[-1]";
   }
   my $allHostTuples = $self->{testbed}->GetAllComponentTuples($allTupleString);
   foreach my $tuple (@$allHostTuples) {
      my $ref = $self->{testbed}->GetComponentObject($tuple);
      my $hostObject = $ref->[0];
      if ($hostObject->{hostIP} =~ /$host/) {
         $newhostObj = $hostObject;
         last;
      }
   }

   #
   # If vcObj which is usually the case of vmotion,
   # then update the host IP as VC IP, otherwise
   # cleanup or any operation would use host ip instead of
   # VC, which is wrong.
   #
   if (defined $newhostObj->{vcObj}) {
      $vmObj->{host}     = $newhostObj->{vcObj}{vcaddr};
   } else {
      $vmObj->{host}     = $newhostObj->{hostIP};
   }
   $vmObj->{esxHost}  = $newhostObj->{hostIP};
   $vmObj->{_host}    = $newhostObj->{hostIP};
   $vmObj->{hostObj}  = $newhostObj;
   $vmObj->{_hostObj} = $newhostObj;

   my $result = $self->{testbed}->SetComponentObject($self->{componentIndex}, $vmObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to set the $self->{componentIndex} Object.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# PostProcessFindVM
#     Method to postprocess "findin or vmotion" property
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

sub PostProcessFindVM
{
   my $self = shift;
   my $result = $self->PostProcessUpdateVMHostObject(@_);
   if ($result eq FAILURE) {
      $vdLogger->Error("PostProcessUpdateVMHostObject returned failure");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # In case of disaster if
   # HA is enabled VM gets poweredon on a different host
   # in that case IP can change thus call PostProcessChangeVMState()
   # which handles that
   $result = $self->PostProcessChangeVMState(@_);
   if ($result eq FAILURE) {
      $vdLogger->Error("PostProcessUpdateVMHostObject returned failure");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
# PreProcessFaultToleranceVM --
#     Method to preprocess vm fault tolerance
#
# Input:
#     Same as Pre-Process template
#
# Results:
#     Same as Pre-process template
#
# Side effects:
#     None
#
########################################################################

sub PreProcessFaultToleranceVM
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue, $paramValue) = @_;
   my @arguments;
   my $specHash = {
      'faulttolerance'        => $paramValue->{'faulttolerance'},
      'secondaryhost'         => $paramValue->{'secondaryhost'},
   };
   push(@arguments, $specHash);
   return \@arguments;
}


########################################################################
#
# PostProcessControllerPassword
#     Method to postprocess "controllerpassword" property
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

sub PostProcessControllerPassword
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   $vdLogger->Info("Updating new controller password to zookeeper");
   my $allControllerTuples = $self->{testbed}->GetAllComponentTuples("vsm.[-1].vxlancontroller.[-1]");
   foreach my $tuple (@$allControllerTuples) {
      my $ref = $self->{testbed}->GetComponentObject($tuple);
      my $controllerObject = $ref->[0];
      $controllerObject->{password} = $keyValue;

      my $result = $self->{testbed}->SetComponentObject($tuple, $controllerObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to set the $self->{componentIndex} Object.");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   return SUCCESS;
}


#######################################################################
#
# GetComponentAttribute--
#     Wrapper method to call ether AutogenerateName() or
#     GetComponentAttribute() from ParentWorkload
#
# Input:
#     attributeValue : Values of the params in the test hash
#     testObj        : Testbed object being used here
#     attributeKey   : Name of the key being worked upon here
#
#        Example:
#           external_id: 'esx.[1]->id'
#              attributeValue is 'esx.[1]->id'
#              attributeKey is 'id'
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

sub GetComponentAttribute
{
   my $self           = shift;
   my $attributeValue = shift;
   my $testObj        = shift;
   my $attributeKey   = shift;
   my $componentIndexInArray = shift;

   my $result = undef;
   my $key = lc($attributeKey);
   if (($attributeValue =~ /autogenerate/i) &&
      ($key eq 'name')) {
      $vdLogger->Debug("Calling AutogenerateName from ParentWorkload");
      $result = $self->SUPER::AutogenerateName($attributeValue,
                                        $testObj,
                                        $attributeKey,
                                        $componentIndexInArray);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to run Autogenerate for $attributeKey");
         VDSetLastError("EOPFAIL");
         return FAILURE;
      }
   } else {
      $vdLogger->Debug("Calling GetComponentAttribute from ParentWorkload");
      $result = $self->SUPER::GetComponentAttribute($attributeValue,
                                                    $testObj,
                                                    $attributeKey);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to run Autogenerate for $attributeKey");
         VDSetLastError("EOPFAIL");
         return FAILURE;
      }
   }
   $vdLogger->Debug("Returned value is $result");
   return $result;
}


#######################################################################
#
# PostProcessWaitForVDNet --
#     Method to postprocess "snapshot" operations
#
# Input:
#     vmObj      : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     SUCCESS, if all operations are executed successfully
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessWaitForVDNet
{
   my $self = shift;
   my ($vmObj, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $objID = $vmObj->{objID};
   my $tag = "PostProcessWaitForVDNet";

   my $waitForVDNet = $paramValues->{waitforvdnet};
   if ($keyValue =~ m/revert/i) {
      $waitForVDNet = 'true';
   }
   $waitForVDNet = (defined $waitForVDNet) ? $waitForVDNet : 'false';

   if ($waitForVDNet =~ m/true/i) {
      my $ipOld = $self->{'vmIP'};
      $vdLogger->Info("$tag : Waiting on $vmObj->{'vmx'}");
      if (FAILURE eq $vmObj->WaitForVDNet()) {
         $vdLogger->Error("Wait for vdnet returned failure");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Info("$tag : Now check if control IP address changes ... ");
      if ($ipOld ne $self->{'vmIP'}) {
          if (FAILURE eq $self->{testbed}->SetComponentObject($objID, $vmObj)) {
              $vdLogger->Error("Failed to update the testbed hash.");
              VDSetLastError(VDGetLastError());
              return FAILURE;
          }
      }
      $vdLogger->Info("$tag : Success! Vdnet source ready on $vmObj->{'vmx'}");
   }

   return SUCCESS;
}
1;
