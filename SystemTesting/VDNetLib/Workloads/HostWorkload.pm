########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::HostWorkload;

#
# This package/module is used to run workload that involves executing
# Host operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Host::HostOperations object that this module
# uses extensively have to be registered in testbed object of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type      => "Host" (this is mandatory and the value should be same)
# Target    => SUT or helper1 or helper2 or helper<x>
#
# Host Operation Keys:-
# --------------------------
# UPT           => "Enable/Disable",
# vswitch       => "add/delete",
# Portgroup     => "add/delete",
# vswitchName   => "<vswitch name>",   # if not defined a vswitchname will be
                                       # automatically created
# PortGroupName => "<portgroup name>", # if not defined a portgroupname will be
                                       # automatically created
# UplinkName    => "vmnic<x>"          # name of the phy nic to which vswitch
                                       # should be uplinked (optional)
                                       #
# testesx       => "testesx-command"   #  estesx command to execute
# lro            => "Enable/Disable"   # Enable/Disable lro

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE SKIP VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::TestData::StressTestData;
use VDNetLib::Workloads::Utils;
use Storable 'dclone';
use Inline::Python qw(py_eval py_call_function);
use VDNetLib::TestData::TestConstants;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::HostWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::HostWorkload object, if successful;
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

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'    => "testhost",
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
#      This method will process the workload hash of type 'Host'
#      and execute necessary operations (executes host related
#      methods mostly from VDNetLib::Host::HostOperations.pm).
#
# Input:
#      None
#
# Results:
#     "PASS", if workload is executed successfully,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the Host workload being executed
#
########################################################################

sub StartWorkload {
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);
   %temp =  %$dupWorkload;

   # TODO - Read and validate the workload hash. For example, check if the
   # given configuration key is supported.

   if ($dupWorkload->{'type'} !~ /host/i) {
      $vdLogger->Error("This is not a host workload:" . $dupWorkload->{'type'});
      VDSetLastError("EINVALID");
      return "FAIL";
   }

   # Determine the target on which the VM workload should be run.
   # The target could be SUT or helper<x> based on ver 1.
   my $testHost;
   if ($self->{testbed}{version} == 1) {
      $testHost = $dupWorkload->{'target'};
      if (not defined $testHost) {
         $testHost = "SUT";
      }
      $testHost = $self->GetListOfTuples($testHost, "host");
   } else {
      $testHost = $dupWorkload->{'testhost'};
      if (not defined $testHost) {
          $vdLogger->Error("TestHost Key is not defined for the Host " .
                           "workload" . Dumper($dupWorkload));
          VDSetLastError("ENODEF");
          return FAILURE;
      }
   }

   # Number of Iterations to run the test for
   my $iterations = $dupWorkload->{'iterations'};

   if (not defined $iterations) {
      $iterations = 1;
   }

   my $verification = $dupWorkload->{'verification'};
   if (exists $dupWorkload->{'verification'}) {
      $self->{verification} = $dupWorkload->{verification};
   }

   my $sleepBetweenWorkloads = $dupWorkload->{'sleepbetweenworkloads'};
   my $runWorkload = $dupWorkload->{'runworkload'};

   if (defined $dupWorkload->{pgname}) {
      $dupWorkload->{testpg} = $dupWorkload->{pgname};
   } elsif (defined $dupWorkload->{testpg}){
      $dupWorkload->{testpg} = $dupWorkload->{testpg};
   } elsif (defined $dupWorkload->{portgroupname}) {
      $dupWorkload->{testpg} = $dupWorkload->{portgroupname};
   }

   if (defined $dupWorkload->{vswitchname}) {
      $dupWorkload->{testswitch} = $dupWorkload->{vswitchname};
   } elsif (defined $dupWorkload->{swindex}){
      $dupWorkload->{testswitch} = $dupWorkload->{swindex};
   }elsif (defined $dupWorkload->{swname}){
      $dupWorkload->{testswitch} = $dupWorkload->{swname};
   } elsif (defined $dupWorkload->{vswname}){
      $dupWorkload->{testswitch} = $dupWorkload->{vswname};
   } elsif (defined $dupWorkload->{testswitch}){
      $dupWorkload->{testswitch} = $dupWorkload->{testswitch};
   }

   my $noofretries = 1;
   if (defined $dupWorkload->{'noofretries'}) {
      $noofretries = $dupWorkload->{'noofretries'};
      delete $dupWorkload->{'noofretries'};
      $vdLogger->Info("Number of retries value $noofretries is given.");
   }

   my $verificationStyle;
   if (defined $dupWorkload->{'verificationstyle'}) {
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

   #
   # In the dupWorkload hash, not all the keys represent the host operations
   # to be executed on the given target. There are keys that control how to run
   # the workload. These keys can be referred as management keys. The
   # management keys are removed from the duplicate hash.
   #
   my @mgmtKeys = ('type', 'iterations', 'target', 'pgname', 'portgroupname',
                   'verification', 'expectedresult','sleepbetweenworkloads', 'vswitchname',
                   'swindex', 'swname', 'vswname', 'testhost', 'runworkload', 'noofretries');

   foreach my $key (@mgmtKeys) {
      delete $dupWorkload->{$key};
   }

   my $configCount = 1;
   my $iteratorObj;
   my %combo;
   my $comboHash;

    # Run for the given number of iterations
   $vdLogger->Info("Number of Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");

   #
   # Create an VDNetLib::Common::Iterator object by passing the dupWorkload hash
   # as the parameter. All different combinations for the keys with specific,
   # list and range (eg. '1-20,2') of values will be generated. By calling
   # NextCombination() method, one combination at a time will be retrieved and
   # it wil be passed to ExecuteHostOps() method in the current package which
   # will execute host operations indicated by the keys in the hash.
   #
   $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);

   #
   # NextCombination() method gives one set of keys from the list of available
   # combinations.
   #
   %combo = $iteratorObj->NextCombination();
   $comboHash = \%combo;
   my $ret = "FAIL";
   # Run the following until a valid combination is present
   while (%combo) {
      my @arrayHost = split($self->COMPONENT_DELIMITER, $testHost);
      my @newArray = ();
      foreach my $hostTuple (@arrayHost) {
         my $refArray = $self->{testbed}->GetAllComponentTuples($hostTuple);
         if ($refArray eq FAILURE) {
            $vdLogger->Error("Failed to get component tuples for $hostTuple");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
         push @newArray, @$refArray;
      }
      foreach my $testHost (@newArray) {
         $vdLogger->Info("Running Host workload on $testHost");
         $self->SetComponentIndex($testHost);
         my $hostObjRef = $self->GetHostObjects($testHost);
         my $hostObj = $hostObjRef->[0];
         if (not defined $hostObj) {
            $vdLogger->Error("HostOperations object for $testHost" .
                             "not registered in the testbed");
            VDSetLastError("ENOTDEF");
            return "FAIL";
         }
         if ($self->{verification}) {
            $vdLogger->Info("Start Verification");
            my $veriResult = $self->InitVerification($self);
            if ($veriResult eq FAILURE) {
              $vdLogger->Error("Failed to call Verification");
              VDSetLastError(VDGetLastError());
              return FAILURE;
           }
         }

         $vdLogger->Info("Working on configuration set $configCount" . Dumper($comboHash));
         my $dupComboHash = dclone $comboHash;
         my $retryCount = 0;
         my $result = FAILURE;
         while ($retryCount < $noofretries) {
            if (defined $sleepBetweenWorkloads) {
                $vdLogger->Info("Sleep between workloads of value " .
                            "$sleepBetweenWorkloads is given. Sleeping ...");
                sleep($sleepBetweenWorkloads);
            }
            $result = $self->ConfigureComponent('testObject' => $hostObj,
                                                'configHash' => $dupComboHash,
                                                'tuple'   => $testHost,
                                                'verificationStyle' => $verificationStyle,
                                                'persistData' => $persistData);
            $retryCount++;
            if ((defined $result) && (($result eq SUCCESS) or ($result eq SKIP))) {
               $vdLogger->Info("HostWorkload success execute the hash " .
                               "with retry $retryCount times");
               last;
            }

            $vdLogger->Info("HostWorkload failed execute the hash " .
                            "with retry $retryCount times");
         }

         if (($result eq FAILURE) || ($result eq "FAIL")) {
            $vdLogger->Error("HostWorkload failed execute the hash" .
                              Dumper($comboHash));
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }

         # Return SKIP (Unsupported) if result is SKIP.
         if ($result eq "SKIP") {
            return "SKIP";
         }

         #
         # Another workload can be run as verification for every combination.
         #
         # Call final verification and call GetResult which will do a diff
         # of final - initial state.
         #
         if ($self->{verification}) {
            $vdLogger->Info("Stop Verification");
            my $veriResult = $self->FinishVerification($self);
            if ($veriResult eq FAILURE) {
              $vdLogger->Error("Failed to finish Verification");
              VDSetLastError(VDGetLastError());
              return FAILURE;
            }
         }

         # Run workload if runworkload in dupWorkload;
         if (defined $runWorkload) {
            $vdLogger->Info("Processing runworkload hash for workload" .
                          "verification.");
            if ($self->RunChildWorkload($runWorkload) eq FAILURE) {
               $vdLogger->Error("Failed to execute runworkload for verification: " .
                             Dumper($runWorkload));
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #
      %combo = $iteratorObj->NextCombination();
      $configCount++;
      }#end of iterator combo loop
   }#end of iteration loop

   return "PASS";
}


########################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of HostWorkload,
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
# ExecuteHostOps --
#      This method executes host operations on the given target machine
#      (example: enable/disable UPT, create/delete vswitch and portgroup etc).
#
# Input:
#      target : SUT or helper<x>
#      hostObj: VDNetLib::Host::HostOperations object of the given target
#      hostOpsHash: A part of workload hash with host 'operation' keys.
#                   Refer to this package description for all supported
#                   host operation keys and values.
#
# Result:
#      "SUCCESS", if all the host operation/configurations
#                 are successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigureComponent
{
   my $self         = shift;
   my %args        = @_;
   my $testHost    = $args{tuple};
   my $hostObj     = $args{testObject};
   my $hostOpsHash = $args{configHash};
   my $verificationStyle = $args{verificationStyle};
   my $persistData = $args{persistData};
   my $testbed     = $self->{testbed};

   if ((not defined $hostObj) || (not defined $hostOpsHash)) {
      $vdLogger->Error("Target, HostOperation object and/or config hash " .
                       "not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $hostOpsHash,
                                                 'testObject' => $hostObj,
                                                 'tuple' => $testHost,
                                                 'verificationStyle' => $verificationStyle,
                                                 'persistData' => $persistData);

   if (defined $result) {
      if ($result eq "FAILURE") {
         return "FAILURE";
      } elsif ($result eq "SKIP") {
         return "SKIP";
      } elsif ($result eq "SUCCESS") {
         return "SUCCESS";
      }
   }

   # $result = undef is a temporary return value being
   # used currently until we port all the keys to the
   # new modular design. This condition says that the
   # Parent Workload's ConfigureComponent was not able
   # to configure the key because the key was not part
   # of the KEYSDATABASE, so the HostWorkload's
   # ConfigureComponent will try to confgure the key.

   if (not defined $hostOpsHash->{'testswitch'}) {
      $hostOpsHash->{'testswitch'} = "vswitch-" . $$;
   }

   if (not defined $hostOpsHash->{testpg}) {
      $hostOpsHash->{testpg} = "pg-" . $$;
   }

   my $netObj;
   my $mac;
   if ((defined $hostOpsHash->{'testadapter'}) &&
       (not $hostOpsHash->{'monitorvmnicstat'}) &&
       (not $hostOpsHash->{'monitorvstvlanpkt'})) {
      my $adapterRef = $self->GetNetAdapterObject(testAdapter => $hostOpsHash->{'testadapter'},
                                                  target      => $testHost,
                                                  intType     => $hostOpsHash->{'inttype'});
      if ($adapterRef eq FAILURE) {
         $vdLogger->Error("Unable to find obj for testadapter " .
                          "$hostOpsHash->{'testadapter'} under $testHost");
         VDSetLastError("EINVALID");
         return FAILURE;
      } else {
         $netObj = $adapterRef->[0];
         $mac = $netObj->{'macAddress'};
      }
   }


   my $pgObj;
   if (($hostOpsHash->{testpg} =~ /^\d+$/) || ($hostOpsHash->{testpg} =~ /(:|\.)/)) {
      my @args = ($hostOpsHash->{testpg}, $testHost);
      my $refToArr = $self->GetPortGroupObjects(@args);
      $pgObj = $refToArr->[0];
      $hostOpsHash->{testpg} = $pgObj->{pgName};
   }

   if (($hostOpsHash->{testswitch} =~ /^\d+$/) || ($hostOpsHash->{testswitch} =~ /(:|\.)/)) {
      my $refToArr = $self->GetSwitchNames($hostOpsHash->{testswitch});
      $hostOpsHash->{testswitch} = $refToArr->[0];
   }

   my $supportNetObj;
   if (defined $hostOpsHash->{'supportadapter'}) {
      my $ref = $self->GetNetAdapterObject(testAdapter => $hostOpsHash->{'supportadapter'},
                                    target      => $testHost,
                                    intType     => $hostOpsHash->{'inttype'});
      if ($ref eq FAILURE) {
         $vdLogger->Error("Unable to find obj for support adapter " .
                          "$hostOpsHash->{'supportadapter'} under $testHost");
         VDSetLastError("EINVALID");
         return FAILURE;
      } else {
         $supportNetObj = $ref->[0];
      }
   }

   #
   # List all the supported operations in HostWorkload. One of the main input
   # to this method is hostOpsHash which can have keys like
   # upt,vswitch,portgroup, etc. There will be other keys (such as vswitchname,
   # portgroupname etc.) that are used as parameters for
   # host operations. Process one key at a time from hostOpsHash and if the key
   # is not defined in the list supported operations, then skip that key.
   #
   my %supportedOperations = (
      'netdump'             => 1,
      'upt'                 => 1,
      'vnicupt'             => 1,
      'vswitch'             => 1,
      'vmknic'              => 1,
      'ableipv6'            => 1,
      'portgroup'           => 1,
      'testesx'             => 1,
      'firewall'            => 1,
      'reboot'              => 1,
      'hibernate'           => 1,
      'hoghostcpu'          => 1,
      'stophogcpuprocess'   => 1,
      'verifyvmklog'        => 1,
      'fpt'                 => 1,
      'chf'                 => 1,
      'analyzetxrxq'        => 1,
      'checkipv6host'       => 1,
      'vmkmodule'           => 1,
      'killvmprocess'       => 1,
      'startvmnetdhcp'      => 1,
      'changeserviceorder'  => 1,
      'enableportforwarding'=> 1,
      'setteamcheckparam'   => 1,
      'setdvsuplinkportstatus' => 1,
      'vdl2'                => 1,
      'monitorportstat'     => 1,
      'monitorvmnicstat'    => 1,
      'monitorvstvlanpkt'   => 1,
      'monitordvfilterstat' => 1,
   );

   foreach my $operation (keys %{$hostOpsHash}) {
      my $method = undef;
      my @params = ();

      if (not defined $supportedOperations{$operation}) {
         next;
      }

      my $tuple;

      my $vmnicObj;
      if (($operation eq 'monitorvmnicstat') ||
          ($operation eq 'monitorvstvlanpkt')) {
         my $ref = $self->GetNetAdapterObject(
         testAdapter => $hostOpsHash->{vmnicadapter});
         $vmnicObj = $ref->[0];
      }

      # Netdump Code Starts Here
      if ($operation eq "netdump") {
         if ($hostOpsHash->{netdump} =~ /set/i) {
            $method = 'SetNetdump';
            my $nic;
            if (not defined $hostOpsHash->{'testadapter'}) {
               $nic = $hostOpsHash->{'name'};
            } else {
               my $vmknic_index = $hostOpsHash->{'testadapter'};
               $nic = $netObj->{'deviceId'};
            }
            my $svrip = $hostOpsHash->{'netdumpsvrip'};
            if ($svrip =~ m/auto/i) {
               $svrip = $supportNetObj->GetIPv4();
            }
            $vdLogger->Debug("Hostworkloads.pm: $hostOpsHash->{'testadapter'}, " .
                             "$nic, $svrip");
            push(@params, $nic);
            push(@params, $svrip);
            push(@params, $hostOpsHash->{'netdumpsvrport'});
         }
         if ($hostOpsHash->{netdump} =~ /deletenetdumpvmk/i) {
            $method = 'DeleteNetdumpVMK';
            my $vmknic_index = $hostOpsHash->{'testadapter'};
            my $vmknic = $netObj->{'deviceId'};
            push(@params, $vmknic);
         }
         if ($hostOpsHash->{netdump} =~ /configure/i) {
            $method = 'ConfigureNetdump';
            push(@params, $hostOpsHash->{'netdumpstatus'});
         }
         if ($hostOpsHash->{netdump} =~ /panicandreboot/i) {
            $method = 'NetdumpPanicAndReboot';
            push(@params, $hostOpsHash->{'paniclevel'});
            push(@params, $hostOpsHash->{'panictype'});
         }
         if ($hostOpsHash->{netdump} =~ /verifynetdumpclient/i) {
            $method = 'VerifyNetdumpClient';
            my $nic = $netObj->{'deviceId'};
            my $svrip = $hostOpsHash->{'netdumpsvrip'};
            if ($svrip =~ m/auto/i) {
               $svrip = $supportNetObj->GetIPv4();
            }
            push(@params, $nic);
            push(@params, $svrip);
            push(@params, $hostOpsHash->{'netdumpsvrport'});
            push(@params, $hostOpsHash->{'netdumpstatus'});
	 }
         if ($hostOpsHash->{netdump} =~ /netdumpesxclicheck/i) {
            $method = 'NetdumpCheckCommand';
	 }
         if ($hostOpsHash->{netdump} =~ /backuphost/i) {
            $method = 'BackupHostConfigurations';
	 }
      } # Netdump code Ends Here

      # Define the method and parameters to pass for each operation
      if($operation eq "enableportforwarding") {
         $method = 'VMOpsEnablePortForwarding';
         push(@params, $hostOpsHash->{'trafficType'}, $hostOpsHash->{'hostPort'},
              $hostOpsHash->{'vmIp'}, $hostOpsHash->{'vmPort'});
      }
      if($operation eq "changeserviceorder") {
         $method = 'ChangeNetworkServiceOrder';
         push(@params, $hostOpsHash->{'networkservicename'});
      }
      if($operation eq "killvmprocess") {
         $method = 'KillVMProcess';
         push(@params, $hostOpsHash->{'processname'});
      }
      if($operation eq "startvmnetdhcp") {
         $method = 'StartDHCPProcess';
         push(@params, $hostOpsHash->{'vmnetname'});
      }
      if ($operation eq "upt") {
         $method = 'SetHostUPT';
         push(@params, $hostOpsHash->{'upt'});
      }

      if ($operation eq "vnicupt") {
         $method = 'SetvNicUPTStatus';
         push(@params, $hostOpsHash->{'vnicupt'});
         if ((not defined $mac) || $mac eq FAILURE) {
            $vdLogger->Error("MAC address not defined for adapter " .
                             $hostOpsHash->{'testadapter'}{interface} .
                             "on " . $hostOpsHash->{'testadapter'}{controlIP});
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         push(@params, $mac);
      }

      if ($operation eq "portgroup") {
         if ($hostOpsHash->{'portgroup'} =~ /add/i) {
            $method = 'CreatePortGroup';
         } else {
            $method = 'DeletePortGroup';
         }
         # Creating/deleting a portgroup requires vswitch name
         push (@params, $hostOpsHash->{'testpg'});
         push(@params, $hostOpsHash->{'testswitch'});
      }

      if ($operation eq "vmkmodule") {
         $method = 'VMKModule';
         # VMKModule needs operation value (load/unload) and
         # modulename and moduleparams if the module supports any
         push (@params, $hostOpsHash->{'vmkmodule'});
         push(@params, $hostOpsHash->{'modulename'});
      }

      if ($operation eq "vswitch") {
         my $switch = $hostOpsHash->{'testswitch'};
         if (defined $switch) {
            my $switchRef = $self->GetSwitchNames($switch, $testHost);
            $hostOpsHash->{'testswitch'} = $switchRef->[0];
         }
         if ($hostOpsHash->{'vswitch'} =~ /add/i) {
            $method = 'CreatevSwitch';
         } else {
            $method = 'DeletevSwitch';
         }
         push(@params, $hostOpsHash->{'testswitch'});
      }
      if ($operation eq "vmknic") {
         if (defined $hostOpsHash->{testpg}) {
            my @args = ($hostOpsHash->{testpg}, $testHost);
            my $refToArr = $self->GetPortGroupNames(@args);
            $hostOpsHash->{testpg} = $refToArr->[0];
         }
         if ($hostOpsHash->{vmknic} =~ /add/i) {
            $method = 'AddVmknic';
            my %hash = (
              'pgName'    => $hostOpsHash->{testpg},
              'ip'        => $hostOpsHash->{ip},
              'netstack'  => $hostOpsHash->{netstack} || 'defaultTcpipStack',
            );
            push(@params, %hash);
         } else {
            $method = 'DeleteVmknic';
            my $device = undef;
            my $result = $hostObj->ListVmknics();
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to list the vmknics");
               VDSetLastError("EOPFAILED")
            }
            if (ref($result) eq "ARRAY") {
               foreach my $item (@$result) {
                  if ($item->{'portgroup'} eq $hostOpsHash->{testpg}) {
                     $device = $item->{'device'};
                  }
               }
            }
            if (not defined $device) {
               $vdLogger->Error("vmknic interface to delete is undefined " .
                                "for $hostOpsHash->{testpg}");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            push(@params, $device); # pass device as parameter
         }
      }

      if ($operation eq "ableipv6") {
         $method = 'AbleIPv6';
         push(@params, $hostOpsHash->{'ableipv6'});
      }

      if ($operation eq "checkipv6host") {
         $method = 'CheckIPv6Host';
      }

      if ($operation eq "testesx") {
         $method = 'TestEsxCommand';
         push(@params, $hostOpsHash->{'testesx'});
      }

      if ($operation eq "fpt") {
         if ($hostOpsHash->{'fpt'} =~ /Enable/i) {
             if ($hostOpsHash->{'uplinkname'} eq "") {
                 $vdLogger->Error("Please enter the NIC to enable passthru ".
                                  " mode on host:$self->{hostIP}");
                 VDSetLastError("EFAIL");
                 return FAILURE;
               }
              my $pnic=$hostOpsHash->{'uplinkname'};
              my @pnicArray=split(',', $pnic);
              $method = 'EnableFPT';

              push(@params, \@pnicArray);
         } else {
            $method = 'DisableFPT';
         }
      }

      if ($operation eq "firewall") {
         if ($hostOpsHash->{'firewall'} =~ /list/i) {
            $method = 'FirewallRulesList';
            push(@params, $hostOpsHash->{'servicename'});
         }
		  if ($hostOpsHash->{'firewall'} =~ /ListAllowedIPInvalidValue/i) {
            $method = 'ListAllowedIPInvalidValue';
            push(@params, $hostOpsHash->{'servicename'});
         }

         if ($hostOpsHash->{'firewall'} =~ /invalidsetdisabled/i) {
            $method = 'FirewallinvalidSetDisabledRule';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
         if ($hostOpsHash->{'firewall'} =~ /setenabled/i) {
            $method = 'FirewallSetEnabledRule';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
         if ($hostOpsHash->{'firewall'} =~ /setallowedall/i) {
            $method = 'FirewallSetAllowedAll';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
         if ($hostOpsHash->{'firewall'} =~ /setstatus/i) {
            $method = 'FirewallSetStatus';
            push(@params, $hostOpsHash->{'status'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/CheckIPExist/i) {
            $method = 'FirewallCheckIPExist';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'ip'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/CheckRule/i) {
            $method = 'FirewallCheckRule';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/IPSet/i) {
            $method = 'FirewallIPSet';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
            push(@params, $hostOpsHash->{'ip'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/CheckDupService/i) {
            $method = 'FirewallCheckDupService';
            push(@params, $hostOpsHash->{'servicename'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/CheckDaemonStatus/i) {
            $method = 'FirewallCheckDaemonStatus';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'status'});
         }
		 if ($hostOpsHash->{'firewall'} =~ m/checkconflictrule/i) {
            $method = 'FirewallCheckConflictRule';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'allowedip'});
         }
        if ($hostOpsHash->{'firewall'} =~ /checkallowedall/i) {
            $method = 'FirewallCheckAllowedAll';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/InvalidIPSet/i) {
            $method = 'FirewallInvalidIPSet';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
            push(@params, $hostOpsHash->{'ip'});
            push(@params, $hostOpsHash->{'check'});
         }
         if ($hostOpsHash->{'firewall'} =~ m/InvalidSrvName/i) {
            $method = 'FirewallInvalidSrvName';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
            push(@params, $hostOpsHash->{'ip'});
         }
        if ($hostOpsHash->{'firewall'} =~ m/InvalidService/i) {
            $method = 'FirewallInvalidService';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'flag'});
         }
        if ($hostOpsHash->{'firewall'} =~ m/ConfigureService/i) {
            $method = 'FirewallConfigureService';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'direction'});
            push(@params, $hostOpsHash->{'l4protocol'});
            push(@params, $hostOpsHash->{'porttype'});
            push(@params, $hostOpsHash->{'portnumber'});
            push(@params, $hostOpsHash->{'flag'});
         }
       if ($hostOpsHash->{'firewall'} =~ m/InvalidXMLTagConfig/i) {
            $method = 'FirewallInvalidXMLTagConfig';
            push(@params, $hostOpsHash->{'servicename'});
            push(@params, $hostOpsHash->{'direction'});
            push(@params, $hostOpsHash->{'l4protocol'});
            push(@params, $hostOpsHash->{'porttype'});
            push(@params, $hostOpsHash->{'portnumber'});
            push(@params, $hostOpsHash->{'flag'});
         }
      }
       if ($operation eq "reboot") {
	   $method = 'Reboot';
      }

      if ($operation eq "hibernate") {
         $method = 'Hibernate';
         push(@params, $hostOpsHash->{'hibernate'});
      }

      if ($operation eq "hoghostcpu") {
         $method = 'HogHostCPU';
         push(@params, $hostOpsHash->{'hoghostcpu'});
      }

      if ($operation eq "stophogcpuprocess") {
         $method = 'StopHogCPUProcess';
         push(@params, $hostOpsHash->{'stophogcpuprocess'});
      }

      if ($operation eq "verifyvmklog") {
         $method = 'VerifyVMKLog';
         push(@params, $hostOpsHash->{'verifyvmklog'});
      }
      if ($operation eq "setdvsuplinkportstatus") {
         $method = "SetDVSUplinkPortStatus";
         my $dvsName;
         if (defined $hostOpsHash->{switch}) {
            my $adapterRef = $self->GetSwitchNames($hostOpsHash->{switch},
                                                   $testHost);
            $dvsName  = $adapterRef->[0];
         }
         my $adapterRef = $self->GetNetAdapterObject(testAdapter => $hostOpsHash->{vmnicadapter},
                                                     target      => $testHost,
                                                     intType     => 'vmnic');
         my $vmnicObj = $adapterRef->[0];
         push (@params, $vmnicObj->{interface});
         push (@params, $hostOpsHash->{setdvsuplinkportstatus});
         push (@params, $dvsName);
      }
      if ($operation eq "setteamcheckparam") {
         $method = 'SetTeamcheckParam';
         push(@params, $hostOpsHash);#P0 api doesnot exist (might have been depricated)
      }
      if ($operation eq "setmoduleloglevel") {
         $method = 'SetModuleLogLevel';
         push(@params, $hostOpsHash);#P0 api doesnot exist (might have been depricated)
      }
      if ($operation eq "analyzetxrxq") {
         # In case key "vSwName" is not mentioned in the test case hash
         # default value from testbed hash will be taken
         if (not defined $hostOpsHash->{testswitch}) {
            my $switchRef = $self->GetSwitchNames("0", $testHost);
            $hostOpsHash->{testswitch} = $switchRef->[0];
         }
         # Expecting NICs to be mentioned in test case hash as:
         # AnalyzeTxRxQ => "<NICnum1>:<NICnum2>", (if 2 NICs are to be used, else "<NICnum1>")
         my @nics = split(':',$hostOpsHash->{'analyzetxrxq'});
         my $vmnicObj1;
         my $vmnicObj2;
         if (defined $nics[0]) {
            my $ref = $self->GetNetAdapterObject(testAdapter => $nics[0],
                                                 target      => $testHost,
                                                 intType     => "vmnic");
            $vmnicObj1 = $ref->[0];
            $hostOpsHash->{vmnic}->{$nics[0]}->{name} = $vmnicObj1->{interface};
            $hostOpsHash->{nic1} = $nics[0];
         } else {
            $vdLogger->Error("NICs haven't been mentioned along with key ".
                             "\"AnalyzeTxRxQ\" as \"<NICnumber1>:<NICnumber2>\"");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         if (defined $nics[1]) {
            my $ref = $self->GetNetAdapterObject(testAdapter => $nics[1],
                                                 target      => $testHost,
                                                 intType     => "vmnic");
            $vmnicObj2 = $ref->[0];
            $hostOpsHash->{vmnic}->{$nics[1]}->{name} = $vmnicObj2->{interface};
            $hostOpsHash->{nic2} = $nics[1];
         }
         my $opsHash = {
            'teampolicy'          => $hostOpsHash->{'teampolicy'},
            'vswname'             => $hostOpsHash->{testswitch},
            'nic1'                => $nics[0],
            'nic2'                => $nics[1],
            'sleepbetweencombos'  => $hostOpsHash->{'sleepbetweencombos'},
            'vmnic'              => {
                                    $nics[0] => {
                                       'name'  => $vmnicObj1->{interface},
                                    },
                                    $nics[1] => {
                                       'name'  => $vmnicObj2->{interface},
                                    },
                                 },
            };
         $method = 'AnalyzeTxRxQ';
         push(@params, $opsHash);
      }

      #
      # CHF feature
      #
      if ($operation eq "chf") {
         if ($hostOpsHash->{'chf'} =~ /checkNetFence/i) {
            $method = 'CheckNetFence';
            push(@params, $hostOpsHash->{'vdsname'});
            push(@params, $hostOpsHash->{'fenceid'});
         }
         if ($hostOpsHash->{'chf'} =~ /CheckCHFEsxcli/i) {
            $method = 'CheckCHFEsxcli';
            push(@params, $hostOpsHash->{'vdsname'});
            push(@params, $hostOpsHash->{'fenceid'});
         }
      }

      #
      # VDL2 feature
      #
      if ($operation eq "vdl2") {
         $method = 'CheckAndInstallVDL2';
      }

      # Define the method and parameters to pass for MonitorNetworkPortStat
      if($operation eq "monitorportstat") {
         $method = 'MonitorNetworkPortStat';
         push(@params, $hostOpsHash->{'testswitch'});
      } # end of monitorportstat operation

      # Define the method and parameters to pass for MonitorVMNICPacketStat
      if($operation eq "monitorvmnicstat") {
         $method = 'MonitorVMNICPacketStat';
         push(@params, $vmnicObj->{interface});
      } # end of monitorvmnicstat operation

      # Define the method and parameters to pass for monitorvstvlanpkt
      if($operation eq "monitorvstvlanpkt") {
         $method = 'MonitorPerVLANPacketStat';
         $vdLogger->Debug("Vmnic object" . Dumper($vmnicObj));
         push(@params, $vmnicObj->{interface}, $hostOpsHash->{'monitorvstvlanpkt'});
      } # end of monitorvstvlanpkt operation

      # Define the method and parameters to pass for MonitorNetworkPortStat
      if($operation eq "monitordvfilterstat") {
         $method = 'MonitorDVFilterPortStat';
         push(@params, $hostOpsHash->{'testswitch'});
      } # end of monitordvfilterportstat operation

     if (not defined $method) {
         $vdLogger->Error("Method name not found for $operation operation");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $vdLogger->Info("Executing $method operation on $testHost host" .
                      " with parameters " . join(',', @params));
      #
      # After figuring out the method name and parameters to execute a host
      # operation, call the appropriate method.
      #
      my $result = $hostObj->$method(@params);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to execute $operation on $testHost host");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      if ($result eq "SKIP") {
         $vdLogger->Warn("Requested operation is not supported".
			  " with current configuration.");
         VDSetLastError("ENOTSUP");
	 return "SKIP";
      }

      if ($method eq 'GetFilterName') {
         if ($result eq VDNetLib::Common::GlobalConfig::FALSE) {
            $vdLogger->Debug("GetFilterName returned FALSE");
            return "FAIL";
         } else {
            # if the result is not FALSE then the API could've returned
            # some value other than 1.  If it needs to strictly return
            # TRUE only then HostOperations::GetDVFilterName cannot be
            # workload, instead write wrapper around and call it as
            # IsFilterExist, which in turn call GetDVFilterName
            return "PASS";
         }
      }

      # The UPT part are not used anymore,delete the stress's part for UPT.

      #
      # Set any events here
      #
      my $event;
      if ($operation eq "vswitch") {
         if ($hostOpsHash->{'vswitch'} =~ /add/i) {
            my @tempArray;
            push(@tempArray, $testHost, $hostOpsHash->{'testswitch'}, "vswitch");
            if (FAILURE eq $self->{testbed}->SetEvent("AddSwitch",
                                                      \@tempArray)) {
               $vdLogger->Error("Failed to update parent about " .
                                "event \"AddSwitch\"");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            } # end of SetEvent()
         } # end of checking for "add" operation
      } # end of check for vswitch operation

      if ($operation eq "vmknic") {
         if ($hostOpsHash->{'vmknic'} =~ /add/i) {
            my @tempArray;
            $vdLogger->Debug("Pg name == $hostOpsHash->{testpg} and Host Object = " . Dumper($hostObj) .Dumper($pgObj));
            # Create NetAdapter object and store in the testbed hash.
            my $netObj = VDNetLib::NetAdapter::NetAdapter->new(controlIP  => $hostObj->{hostIP},
                                                               pgObj      => $pgObj,
                                                               interface  => $hostOpsHash->{testpg},
                                                               hostObj    => $hostObj,
                                                               intType    => "vmknic",
                                                               switchType => "vswitch",
                                                               switch     => undef);
            if ($netObj eq FAILURE) {
               $vdLogger->Error("Failed to create vmknic object for $hostOpsHash->{testpg}");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            $tuple = undef;
            if ($testHost !~ /\:+/) {
               $tuple = "$testHost.SUT.1";
            }
            if (FAILURE eq $self->{testbed}->SetEvent("VMNicEvent",
                                                      \@tempArray)) {
               $vdLogger->Error("Failed to update parent about " .
                                "event \"VMKNic\"");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            } # end of SetEvent()
         } # end of add operation
      } # end of check for vmknic operation
   } # end of processing all test keys
   return SUCCESS;
}


########################################################################
#
# PreProcessVerifyRSSFunctionalityKey --
#     Method to process "verifyrssfunctionality" property in testspec
#     and return host vmnic
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

sub PreProcessVerifyRSSFunctionalityKey
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   #
   # Storing NIC information as NIC object references in an array
   #
   my @vmnicArray = ();
   my $refVmnicArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($keyValue);
   my $lc = 0;
   foreach my $pnic (@$refVmnicArray) {
      my $ref = $self->{testbed}->GetComponentObject($pnic);
      if ($ref eq FAILURE) {
         $vdLogger->Error("Vmnic information has not been passed in the ".
                          "required tuple format supported for vdNetv2: ".
                          "host.[#].vmnic.[#]");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vmnicArray[$lc] = $ref->[0];
      $lc++;
   }

   $paramValues->{$keyName} = \@vmnicArray;

   my @array;
   foreach my $param (@$paramList) {
      if (defined $paramValues->{$param}) {
         push(@array, $paramValues->{$param});
      }
   }
   return \@array;
}


########################################################################
#
# PreProcessVmknicMAC --
#     Method to process "vmkinfo" property in testspec and return vmknic
#     MACs
#
# Input:
#     vmkinfo: tuple representing vmknic adapter
#
# Results:
#     MACs of vmknic will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVmknicMAC
{
   my $self = shift;
   my $vmknicPgTuple = shift;
   my @args;

   #
   # Expecting NICs to be mentioned in test case hash as:
   # vmkinfo => "<vmkMAC1>;;<vmkMAC2>", (if more than 1 vmknic is used)
   # or as vdNetv2 supported tuples:
   # vmkinfo => "host.[#].vmknic.[#]".
   # Storing vmknic information as vmknic MAC addresses in an array
   #
   # First, checking whether vmknic info has been passed as MAC addresses
   #
   my $lc = 0;
   my @vmknicArray = ();
   my @vmknics = split(';;',$vmknicPgTuple);
   foreach my $vnic (@vmknics) {
      if ($vnic =~ /.{2}\:.{2}\:.{2}\:.{2}\:.{2}\:.{2}/) {
         $vmknicArray[$lc] = $vnic;
         $lc++;
      }
   }
   if ($lc > 0) {
      # If lc > 0, the vmknic information has already been stored as MACs
      return \@vmknicArray;
   }

   # Next, checking whether the vmknic information is stored as vdNetv2 tuples
   my $refVmknicArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($vmknicPgTuple);
   foreach my $vnic (@$refVmknicArray) {
      # Tracking down the MAC address of this vmknic
      my $ref = $self->{testbed}->GetComponentObject($vnic);
      if ($ref eq FAILURE) {
         $vdLogger->Error("Vmknic information has not been passed in either the ".
                          "required tuple format supported for vdNetv2: ".
                          "host.[#].vmknic.[#] OR the MAC addresses of the vmknic, ".
                          "separated by 2 semi-colons \";;\"");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vmknicArray[$lc] = $ref->[0]->{macAddress};
      $lc++;
   }
   return \@vmknicArray;
}


########################################################################
#
# PreProcessLoadUnloadDriverKey
#     Method to return driver value for the load / unload driver methods
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Array of method values along with driver info, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessLoadUnloadDriverKey
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   # Tracking down the driver of the vmnic
   my $ref = $self->{testbed}->GetComponentObject($keyValue);
   if ($ref eq FAILURE) {
      $vdLogger->Error("Driver info of the vmnic has been passed as \"".
                       "$keyValue\", which is not in the ".
                       "required tuple format supported for vdNetv2: ".
                       "host.[#].vmnic.[#]");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $keyValue = $ref->[0]->{driver};

   my @array;
   push(@array, $keyValue);
   if (defined $paramValues->{moduleparam}) {
      push(@array, $paramValues->{moduleparam});
   }
   return \@array;
}


########################################################################
#
# PreProcessModuleParam --
#     Method to process "moduleParam" in testspec and return comma
#     separated values
#
# Input:
#     moduleParam: Exact params to be passed while loading a driver
#
# esults:
#     Same string will be returned as entered with ";;" replaced by ","
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessModuleParam
{
   my $self = shift;
   my $moduleParam = shift;

   $moduleParam =~ s/::/,/g;

   return $moduleParam;
}


########################################################################
#
# PreProcessDVFilterConfigSpec--
#     Method to process dvfilter config spec parameters
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method DVFilterCTL.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessDVFilterConfigSpec
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arguments = ();
   my $dvfilterctl = $paramValues->{$paramList->[0]};
   my $dvfilterConfigSpec = $paramValues->{$paramList->[1]};
   my $vmObj = $paramValues->{$paramList->[2]};
   my $vmIP = $paramValues->{$paramList->[3]};
   if (not defined $dvfilterConfigSpec) {
      $vdLogger->Error("Parameters not provided to PreProcessDVFilterConfigSpec");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my %args = (
      'dvfilterctl'    => $dvfilterctl,
      'vm'             => $vmObj,
      'vmip'           => $vmIP,
      'inbound'        => $dvfilterConfigSpec->{inbound},
      'outbound'       => $dvfilterConfigSpec->{outbound},
      'tcp'            => $dvfilterConfigSpec->{tcp},
      'udp'            => $dvfilterConfigSpec->{udp},
      'icmp'           => $dvfilterConfigSpec->{icmp},
      'delay'          => $dvfilterConfigSpec->{delay},
      'copy'           => $dvfilterConfigSpec->{copy},
      'dnaptport'      => $dvfilterConfigSpec->{dnaptport},
      'fakeprocessing' => $dvfilterConfigSpec->{fakeprocessing},
   );
   push(@arguments, %args);
   return \@arguments;
}


########################################################################
#
# PreProcessIPSecSecurityAssociation--
#     Method to process ipsec SA parameters
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method AddIPSecSecurityAssociation.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessIPSecSecurityAssociation
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arguments = ();
   my $operation = $paramValues->{$paramList->[0]};
   my $ipsecConfigSpec = $paramValues->{$paramList->[1]};
   if (not defined $ipsecConfigSpec) {
      $vdLogger->Error("Parameters not provided to PreProcessIPSecSecurityAssociation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my %args = (
      'operation'           => $operation,
      'encryptionAlgorithm' => $ipsecConfigSpec->{encryption},
      'encryptionKey'       => $ipsecConfigSpec->{encryptionkey},
      'integrityAlgorithm'  => $ipsecConfigSpec->{integrity},
      'integrityKey'        => $ipsecConfigSpec->{integritykey},
      'destination'         => $ipsecConfigSpec->{destination},
      'mode'                => $ipsecConfigSpec->{mode},
      'name'                => $ipsecConfigSpec->{name},
      'source'              => $ipsecConfigSpec->{source},
      'spi'                 => $ipsecConfigSpec->{spi},
   );
   push(@arguments, %args);
   return \@arguments;
}


########################################################################
#
# PreProcessIPSecSecurityPolicy --
#     Method to process paramters to add ipsec SP.
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#    Reference to an array which contains arguments for
#     method AddIPSecSecurityPolicy.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessIPSecSecurityPolicy
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arguments = ();
   my $operation = $paramValues->{$paramList->[0]};
   my $ipsecConfigSpec = $paramValues->{$paramList->[1]};
   if (not defined $ipsecConfigSpec) {
      $vdLogger->Error("Parameters not provided to PreProcessIPSecSecurityAssociation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my %args = (
      'operation'           => $operation,
      'SAName'              => $ipsecConfigSpec->{saname},
      'SPName'              => $ipsecConfigSpec->{spname},
      'action'              => $ipsecConfigSpec->{action},
      'destinationPort'     => $ipsecConfigSpec->{destinationport},
      'sourcePort'          => $ipsecConfigSpec->{sourceport},
      'direction'           => $ipsecConfigSpec->{direction},
      'destinationAddress'  => $ipsecConfigSpec->{destinationAddress},
      'mode'                => $ipsecConfigSpec->{mode},
      'sourceAddress'       => $ipsecConfigSpec->{sourceAddress},
      'protocol'            => $ipsecConfigSpec->{protocol},
   );
   push(@arguments, %args);
   return \@arguments;

}


########################################################################
#
# PreProcessLRO --
#     Method to process "lro" property in testspec
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

sub PreProcessLRO
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my $vnicObj = $paramValues->{adapter};
   if ((not defined $vnicObj) || ($vnicObj->{intType} ne 'vnic')) {
      $vdLogger->Error("apdater parameter is not provided with appropriate value.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $paramValues->{adapter} = $vnicObj->{driver};

   my @array;
   foreach my $param (@$paramList) {
      if (defined $paramValues->{$param}) {
         push(@array, $paramValues->{$param});
      }
   }
   return \@array;
}


########################################################################
#
# PreProcessEsxcliVmPortlistVerify --
#     Method to process "esxclivmportlistverify" property in testspec
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

sub PreProcessEsxcliVmPortlistVerify
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my $vmObj = $self->GetOneObjectFromOneTuple($keyValue);

   if ($vmObj eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Core API expects the VM Display name to be passed as an argument
   $paramValues->{$keyName} = $vmObj->{displayName};

   my @array;
   foreach my $param (@$paramList) {
      if (defined $paramValues->{$param}) {
         push(@array, $paramValues->{$param});
      }
   }
   return \@array;
}


########################################################################
#
# PreProcessSriov --
#     Method to process "sriov" property in testspec
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

sub PreProcessSriov
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   if (not defined $paramValues->{vmnicadapter}) {
      $vdLogger->Error("vmnicadapter key is mandatory, but not provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $adaptersHash = undef;
   my @sriovAdapters;
   my $driver;

   if (ref($paramValues->{vmnicadapter}->[0])  !~ /HASH/) {
      foreach my $vmnicObj (@{$paramValues->{vmnicadapter}}) {
	 my $adapterHash = undef;

	 my $maxVFs = (defined $paramValues->{maxvfs}) ?
			$paramValues->{maxvfs} : "max";

	 $adapterHash->{'adapter'}{interface} = $vmnicObj->{interface};
	 $adapterHash->{'adapter'}{driver}    = $vmnicObj->{driver};

	 if ($keyValue =~ /Enable/i) {
	    $adapterHash->{'maxvfs'} = $maxVFs;
	 } else {
	    $adapterHash->{'maxvfs'} = "0";
	 }

	 push(@sriovAdapters, $adapterHash);
      }

      $adaptersHash = \@sriovAdapters;
   } else {
      $adaptersHash = $paramValues->{vmnicadapter};
   }

   my @array;
   push(@array, $adaptersHash);

   return \@array;
}


########################################################################
#
# PreProcessVmnicadapter --
#     Method to process "vmnicadapter" in testspec and return data in
#     required format
#
# Input:
#     vmnics: ;; separated list of vmnic tuples
#
# Results:
#     Required SRIOV Hash, in case of SUCCESS
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVmnicadapter
{
   my $self   = shift;
   my $vmnics = shift;

   if (not defined $vmnics) {
      $vdLogger->Error("vmnicadapter key is mandatory, but not provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $sriovHash = $vmnics;

   if (ref($sriovHash) !~ /ARRAY/) {
      $sriovHash = $self->GetMultipleComponentObjects($vmnics);
   }

   return $sriovHash;
}


########################################################################
#
# PreProcessUpgradeBuild --
#     Method to process "upgradebuild" in testspec and return data in
#     required format
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
#
# Results:
#     Required profile Hash, in case of SUCCESS
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessUpgradeBuild
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arrayBuild ;

   if ($paramValues->{build} =~ m/Auto/i) {
       #TODO:getting Input from yaml file
       my $build ; # "132678,132678"
       @arrayBuild = split(",",$build);
       $paramValues->{'build'} = \@arrayBuild;
    } else {
       @arrayBuild = $paramValues->{'build'};
       $paramValues->{'build'} = \@arrayBuild;
    }

    my @arguments;
    my $specHash = {
       'profile' => $paramValues->{"profile"},
       'signaturecheck' => $paramValues->{'signaturecheck'},
       'build'   => $paramValues->{'build'},
    };
    push (@arguments,$specHash);
    return \@arguments;
}


########################################################################
#
# PreProcessEditProfile --
#     Method to process "editprofile" in testspec and return data in
#     required format
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
#
# Results:
#     Required edit profile Hash, in case of SUCCESS
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessEditProfile
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arrayBuild ;
   my @arguments;
   my $specHash;

   $specHash = {
      'hostprofilefile' => $paramValues->{editprofile},
      'path' =>  $paramValues->{profilepath},
      'policy' => $paramValues->{policyid},
      'policyOption' => $paramValues->{policyoption},
   };
   if ( (defined $paramValues->{name}) && (defined $paramValues->{value}) ) {
      my $value =  $paramValues->{name} . "=" . $paramValues->{value};
      $specHash->{'params'} = $value;
   }
   if ( defined $paramValues->{adapter} ) {
      $specHash->{'adapter'} = $paramValues->{adapter};
   }
   push (@arguments,$specHash);
   return \@arguments;
}


########################################################################
#
# PreProcessVerifyControllerInfoOnHost--
#     Method to process user spec data parameters
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method VerifyControllerInfoOnHost.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyControllerInfoOnHost
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   my $userData;
   foreach my $parameter (@$paramList) {
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            foreach my $key (keys %$entry) {
               if ($key eq "server") {
                  my $controllerObj = $entry->{$key};
                  my $controllerIP = $controllerObj->get_ip();
                  $entry->{$key} = $controllerIP;
               }
            }
         }
         $vdLogger->Debug("Data after processing user input " . Dumper($userProcessedData));
         $userData = $userProcessedData;
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}


########################################################################
#
# ProcessVIBFiles --
#     Method to process array of build numbers/keywords
#
# Input:
#     value: reference to an array of build numbers or
#            keywords in format <product>:<branch>:<type>:<optional>
#     hostObj: reference to the test host object
#
# Results:
#     reference to array with resolved values for all keywords
#
# Side effects:
#     None
#
########################################################################

sub ProcessVIBFiles
{
   my $self    = shift;
   my $value   = shift;
   my $hostObj = shift;

   my $result = [];
   for (my $index=0; $index < scalar(@$value); $index++) {
      if ($value->[$index] !~ /:/) {
         next;
      }
      my ($product, $branch, $type, $optional) = split(":", $value->[$index]);
      if ($branch =~ /default/i) {
         $branch = VDNetLib::TestData::TestConstants::NVS_DEFAULT_BRANCH;
      }
      #
      # Optional field for NSX-VSwitch can be vmkernel-main or
      # prod2013-stage. This is temporary until build team merges it
      #
      if (($type =~ /default/i) || ($optional =~ /default/i)) {
         my $build;
         ($build, $optional, $type) = VDNetLib::Common::Utilities::GetBuildInfo(
                                       $hostObj->{hostIP},
                                       $hostObj->{stafHelper});
         $optional = ($optional =~ /esx55/i) ? "prod2013-stage" : "vmkernel-main";
      }

      eval {
         py_eval("import build_utilities");
         $result->[$index] = py_call_function("build_utilities",
                                   "get_build",
                                   $product,
                                   $branch,
                                   lc($type),
                                   $optional);
      };
      if ($@) {
         $vdLogger->Error("Failed to execute GetBuild routine:$@");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      if (not defined $result->[$index]) {
         $vdLogger->Error("Error finding build for " .
                          "$product:$branch:$type:$optional");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
   }
   return $result;
}

########################################################################
#
# PreProcessLLDPIPv6Address--
#     Method to process user spec data parameters for LLDP IPv6 address
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method GetLLDPIPv6Info.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessLLDPIPv6Address
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   my $userData;

   foreach my $parameter (@$paramList) {
      if ($parameter eq $keyName) {
         my $userProcessedData =
            $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            foreach my $key (keys %$entry) {
               if ($key eq "ipv6") {
                  my $ipv6Address = $entry->{$key};
                  my $fullIPv6Address =
                  VDNetLib::Common::Utilities::FullLengthIPv6Address(
                                             $ipv6Address);
                  $entry->{$key} = $fullIPv6Address;
               }
            }
         }
         $vdLogger->Debug("Data after processing user input "
                           .Dumper(\$userProcessedData));
         $userData = $userProcessedData;
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}

########################################################################
#
# PreProcessFirewallStatus --
#     Method to process "firewall_status" in testspec and return data in
#     required format
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
#
# Results:
#     Required firewall_status Hash, in case of SUCCESS
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessFirewallStatus
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arrayBuild ;
   my @arguments;
   my $specHash;

   if ((defined $paramValues->{execution_type}) &&
       (defined $paramValues->{firewall_status})) {
      $specHash->{'execution_type'} = $paramValues->{execution_type};
      $specHash->{'firewall_status'} = $paramValues->{firewall_status};
   } else {
      $vdLogger->Error("execution_type or firewall_status missing");
      return FAILURE;
   }
   push (@arguments,$specHash);
   return \@arguments;
}

########################################################################
#
# PreProcessFaultToleranceStateVM --
#     Method to preprocess vm fault tolerance state
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

sub PreProcessFaultToleranceOperation
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue, $paramValue) = @_;
   my @arguments;
   my $specHash = {
      'faulttoleranceoption' => $paramValue->{'faulttoleranceoperation'}->{'faulttoleranceoption'},
      'faulttolerancevm'  => $self->GetMultipleComponentObjects($paramValue->{'faulttoleranceoperation'}->{'faulttolerancevm'}),
   };
   push(@arguments, $specHash);
   return \@arguments;
}

1;
