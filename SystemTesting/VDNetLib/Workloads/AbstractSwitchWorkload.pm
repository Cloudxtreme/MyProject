########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::AbstractSwitchWorkload;

#
# This package/module is used to run workload that involves executing
# switch and portgroup operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Switch::VSSwitch::Portgroup and VDNetLib::Switch::Switch objects
# that this module uses extensively have to be registered in testbed object
# of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type        => "Switch" (this is mandatory and the value should be same)
# Target      => SUT or helper1 or helper2 or helper<x>
# SwitchType  => "Type of the switch" # vswitch/vds/extreme/netgear
# datacenter  => "Name of the datacenter, this is needed for the vds case"
# switchAddress => "Name or the ip address of the switch, this is needed for
#                  "pswitch and/or vds".
# TestAdapter => "1/2/3/.." # index to a netadapter in testbed
# IntType     => The Type of interface, vmknic or vnic. If not defined it is
#                assumed to be vnic.
#
# TestPG      => "<name of a portgroup in testbed>"
# TestSwitch  => "<name of a switch in testbed>"
# Version     => "version of the switch"
#
# If 'TestAdapter' is specified, then its portgroup and associated switch
# will be used. If 'TestPG' is given, then this portgroup and its associated
# switch will be used. If 'TestSwitch' is given, then operations will be
# executed only on this switch. The order of precedence is
# TestAdapter, TestPG, TestSwitch
#
#
# Test Keys:-
# --------------------------
# VLAN     => "<valid vlan id to be configured on portgroup>"
# Promisc  => "Enable/Disable",
# MTU      => <1-9000>
# cdp      => <listen, advertise, both>
# lldp     => <listen, advertise, both>
# portstatus => <enable,disable>
# createdvportgroup => <dvportgroup>
# addporttodvpg => <dvportgroup>
# removedvportgroup => <dvportgroup>
# confignetflow => <collector ip >
# setlldptransmitport - Enable,Disable.
# setlldpreceive - Enable,Disable.
# checklldponesx - yes,no
# checklldponswitch - yes,no
#
#

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Switch::Switch;
use VDNetLib::Workloads::Utils;
use VDNetLib::Workloads::FilterWorkload;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::AbstractSwitchWorkload class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::AbstractSwitchWorkload object, if successful;
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

   if ((not defined $options{testbed}) || (not defined $options{workload})) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
   };

   my $testbed = $options{testbed};
   if (defined $testbed->{logCollector}) {
      $self->{localLogsDir} = $testbed->{logCollector}->{logDir} . "/switchworkload-".
                              VDNetLib::Common::Utilities::GetTimeStamp() .
                              "/";
   } else {
      my $myLogDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
      $myLogDir = $myLogDir . "switchworkload-";
      $myLogDir = $myLogDir . VDNetLib::Common::Utilities::GetTimeStamp();
      $myLogDir = $myLogDir . "/";
      $self->{localLogsDir} = $myLogDir;
   }
   $vdLogger->Debug("Logs for this switch workload: $self->{localLogsDir}");

   bless ($self, $class);
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


########################################################################
#
# StartWorkload --
#      This method will process the workload hash of type 'Switch'
#      and execute necessary operations (executes Switch and portgroup
#      related methods mostly from VDNetLib::Switch::VSSwitch::PortGroup
#      and VDNetLib::Switch:Switch).
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

sub StartWorkload
{
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};
   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   if ($self->{testbed}{version} != 1) {
      return $self->SUPER::StartWorkload();
   }

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);

   # TODO - Read and validate the workload hash. For example, check if the
   # given configuration key is supported.

   # Determine the target on which the VM workload should be run.
   # The target could be SUT or helper<x>
   my $target = $dupWorkload->{'target'};

   if ((not defined $target) ||
      (($self->{testbed}{version} == 1) && (lc($target) eq "vc"))) {
      $target = "SUT";
   }
   my $testAdapter = $dupWorkload->{'testadapter'};
   my $testPG = $dupWorkload->{'testpg'};
   my $testSwitch = $dupWorkload->{'testswitch'};
   my $type = $dupWorkload->{'switchtype'};
   my $datacenter = $dupWorkload->{'datacenter'};
   my $switchAddress = $dupWorkload->{'switchAddress'};
   my $intType = $dupWorkload->{'inttype'};
   my $verification = $dupWorkload->{'verification'};
   my $runWorkload = $dupWorkload->{'runworkload'};
   my $sleepBetweenCombos = $dupWorkload->{'sleepbetweencombos'};
   my $iterations = $dupWorkload->{'iterations'};

   $iterations = (defined $iterations) ? $iterations : 1;
   for (my $count = 0; $count < $iterations; $count++) {
      my @tempTargets = split($self->COMPONENT_DELIMITER, $target);
      foreach my $targetMachine (@tempTargets) {
         $targetMachine =~ s/^\s|\s$//g;
         #
         # In the dupWorkload hash, not all the keys represent the host
         # operations to be executed on the given target. There are keys that
         # control how to run the workload. These keys can be referred as
         # management keys. The management keys are removed from the duplicate
         # hash.
         #
         my @mgmtKeys = ('switchtype','type', 'iterations', 'target',
                         'version', 'expectedresult', 'datacenter', 'switchaddress',
                         'sleepbetweencombos', 'verification', 'runworkload');
         foreach my $key (@mgmtKeys) {
            delete $dupWorkload->{$key};
         }

         my $iteratorObj =
            VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);
         #
         # NextCombination() method gives one set of keys from the list of available
         # combinations.
         #
         my %combo = $iteratorObj->NextCombination();

         while (%combo) {
            my $comboHash = \%combo;
            my $result = $self->ExecuteSwitchOps('target' => $targetMachine,
                                                 'testadapter'  => $testAdapter,
                                                 'inttype' => $intType,
                                                 'testpg' => $testPG,
                                                 'testswitch' => $testSwitch,
                                                 'type' => $type,
                                                 'datacenter' => $datacenter,
                                                 'switchAddress' => $switchAddress,
                                                 'confighash' => $dupWorkload,
                                                 'verification' => $verification,
                                                 'sleepbetweencombos' => $sleepBetweenCombos,
                                                 'comboHash' => $comboHash,
                                                 'runworkload' => $runWorkload,);
            if ($result =~ /FAIL/i) {
               VDSetLastError(VDGetLastError());
               return "FAIL";
            }
            %combo = $iteratorObj->NextCombination();
         }
      }
   }
   #
   # In case of PASS we delete all the logs before returning. This
   # will delete all nested dirs and verfication
   # logs inside session dirs
   #
   if ((-d $self->{localLogsDir})) {
      my $ret = `rm -rf $self->{localLogsDir}`;
      if ($ret ne "") {
      $vdLogger->Error("rm -rf $self->{localLogsDir} failed with $ret");
      $vdLogger->Error("Will eat up storage space.");
      }
   }

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
# ExecuteSwitchOps --
#      This method retrieves the correct switch and portgroup object
#      to be used from the given workload hash information. Generates
#      various combinations using iterator module and calls
#      ConfigurePGAndSwitch() to execute switch and portgroup
#      operations.
#
# Input:
#      A named parameter hash with the following keys:
#      'target'    : SUT or helper<x>;
#      'datacenter': Name of the datacenter
#      'switchAddress': Address of the switch.
#      'verification' : Type of verification needed
#      'sleepbetweencombos' : Delay between the test combinations
#      'comboHash' : The hash which contains combinations of test
#                    adapters, testswitches, testpg
#      'configHash': reference to hash containing test keys
#                    (operations) to be executed on the switch/portgroup
#
# Results:
#      None
#
# Side effects:
#      None
#
########################################################################

sub ExecuteSwitchOps
{
   my $self    = shift;
   my %options = @_;
   my $target = $options{'target'};
   my $datacenter = $options{'datacenter'};
   my $switchAddress = $options{'switchAddress'};
   my $configHash = $options{'confighash'};
   my $verification = $options{'verification'};
   my $runWorkload = $options{'runworkload'};
   my $sleepBetweenCombos = $options{'sleepbetweencombos'};
   my $comboHash = $options{'comboHash'};
   my $testAdapter = $comboHash->{'testadapter'};
   my $intType = $comboHash->{'inttype'};
   my $portgroup = $comboHash->{'testpg'};
   my $switch = $comboHash->{'testswitch'};
   my $type = $options{'type'} || "vswitch";
   my $testbed = $self->{testbed};

   my $pgObj;
   my $pgName;
   my $switchObj;
   my $vcObj;
   my @switchArray = ();
   my @pgArray = ();
   my $vmnicObj = undef;
   my $tuple;

   $self->{verification} = $verification if defined $verification;
   if (defined $testAdapter) {
      my $ref =  $self->GetNetAdapterObject(target => $target,
                                            intType => $intType,
                                            testAdapter => $testAdapter);
      my $netObj = $ref->[0];
      if ($netObj->{intType} eq 'vnic') {
         my $mac = $netObj->{macAddress};
         my $vmOpsObj = $netObj->{vmOpsObj};
         my $hostObj = $vmOpsObj->{hostObj};
         my $vmx = $vmOpsObj->{vmx};
         $pgName = $hostObj->GetPGNameFromMAC($vmx, $mac);
         my $ref = $self->GetPortGroupObjects($testAdapter, $target, -1);
         foreach my $pg (@$ref) {
            if ($pg->{'pgName'} eq $pgName) {
               $pgObj = $pg;
               last;
            }
         }
         if (defined $pgObj) {
            $switchObj = $pgObj->{switchObj};
         } else {
            $vdLogger->Error("Unable to find pgObj through $pgName");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      } elsif ($netObj->{intType} eq 'vmnic') {
         $switchObj = $netObj->{pswitchObj};
         # make sure switchPort is defined for the vmnic, This might
         # not be defined due to some stale data caused by running
         # other tests so check this again since in most of the cases
         # when vmnicadapter key is present in workload hash then it's
         # likely that test require the pswitch info for the tests.
         #
         if (not defined $netObj->{switchPort}) {
            my $result = $netObj->GetPhysicalSwitchInfo();
            if ($result eq FAILURE) {
               # for now just warn.
               $vdLogger->Warn("Failed to get physical" .
                               "switch info for $vmnicObj->{vmnic}");
            }
         }
      }
   } elsif (defined $switch) {
      my $args;
      if ($type =~ /pswitch/i) {
         $args = "$target.$type.$switch";
      } else {
         $args = $switch;
      }
      my $ref = $self->GetSwitchObjects($args,$target);
      $switchObj = $ref->[0];
   } elsif (defined $portgroup) {
      my $ref = $self->GetPortGroupObjects($portgroup, $target);
      $pgObj = $ref->[0];
      $switchObj = $pgObj->{switchObj};
   } else {
      $vdLogger->Error("No test switch given");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($switchObj eq 'FAILURE' ) {
      $vdLogger->Error("Unable to get switch object");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Dump of Switch Obj" . Dumper($switchObj));
   if (defined $pgObj) {
      $vdLogger->Debug("Dump of PG Obj" . Dumper($pgObj));
   }
   my $configCount = 1;
   my $iteratorObj;

   #
   # Create an VDNetLib::Common::Iterator object by passing the dupWorkload
   # hash as the parameter. All different combinations for the keys with
   # specific, list and range (eg. '1-20,2') of values will be generated.
   # By calling NextCombination() method, one combination at a time will be
   # retrieved and it wil be passed to ExecuteHostOps() method in the current
   # package which will execute host operations indicated by the keys in the
   # hash.
   #

   my $name;
   if ((defined $switchObj->{switchType}) &&
       ($switchObj->{switchType} eq "pswitch")) {
      $name = $switchObj->{switchAddress};
   } else {
      $name = $switchObj->{switchObj}{name};
   }
   if (defined $name) {
      $vdLogger->Info("Running switch workload for $name on $target");
   }
   # Run the following until a valid combination is present

   $vdLogger->Info("Working on configuration set: " . Dumper($comboHash));
   if (defined $sleepBetweenCombos) {
      $vdLogger->Info("Sleep between combination of value " .
                      "$sleepBetweenCombos is given");
      sleep($sleepBetweenCombos);
   }
   my $result = $self->ConfigureComponent(configHash => $comboHash,
                                          switchObj  => $switchObj,
                                          pgObj      => $pgObj,
                                          tuple      => $target );
   if ($result eq FAILURE) {
      $vdLogger->Error("SwitchWorkload failed execute the hash" .
                        Dumper($comboHash));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Call another workload for verification, if specified.
   if ($runWorkload) {
      # Run another workload as part of verification
      $vdLogger->Info("Running $runWorkload workload " .
                      "for verification");
      if (FAILURE eq $self->{testbed}->SetEvent("RunWorkload",
                                                $runWorkload)) {
      $vdLogger->Error("Failed to verify given switch workload " .
                       "using workload $runWorkload");
      VDSetLastError(VDGetLastError());
      return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureComponent --
#      This method executes portgroup, switch operations on the given
#      switch and portgroup objects.
#      (example: configure VLAN, MTU, promiscuous mode etc).
#
# Input:
#      'switchObj' : switch object for either vss/vds/pswitch (mandatory)
#      'pgObj'     : port group object for either standard/dv (optional)
#      'configHash': Reference to hash with following keys:
#                     'vlan' - <1-4095>
#                     'mtu'  - <1- 9000>
#
# Result:
#      "SUCCESS", if all the switch/portgroup operation/configurations
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
   my %args         = @_;
   my $configHash   = $args{configHash};
   my $testObject   = $args{testObject};
   my $tuple             = $args{tuple};
   my $skipPostProcess   = $args{skipPostProcess};
   my $verificationStyle = $args{verificationStyle};
   my $persistData       = $args{persistData};
   my $testbed	     = $self->{testbed};
   my $vmnicObj     = undef;
   my $vmnic        = undef;
   my $target       = undef;

   if (exists $self->{workload}{Target}) {
      $target = $self->{workload}{Target};
   }

   # list of all supported operations in switch workload.
   my %supportedOperations = (
      'mtu'       => 1,
      'vlan'   => 1,
      'cdp'   => 1,
      'checkcdponesx' => 1,
      'checkcdponswitch' => 1,
      'createdvportgroup' => 1,
      'lldp'    => 1,
      'portstatus' => 1,
      'removedvportgroup' => 1,
      'addporttodvportgroup' => 1,
      'enablenetiorm' => 1,
      'disablenetiorm' => 1,
      'confignetflow' => 1,
      'setmonitoring' => 1,
      'setbeacon' => 1,
      'configureuplinks' => 1,
      'configureportgroup' => 1,
      'getproperties' => 1,
      'getteamingpolicies' => 1,
      'setnicteaming' => 1,
      'setfailoverorder' => 1,
      'settrafficshaping' => 1,
      'editmaxports' => 1,
      'blockport' => 1,
      'unblockport' => 1,
      'accessvlan' => 1,
      'trunkrange' => 1,
      'enableinshaping' => 1,
      'disableinshaping' => 1,
      'enableoutshaping' => 1,
      'setpvlantype' => 1,
      'setlldptransmitport' => 1,
      'setlldpreceiveport' => 1,
      'checklldponesx' => 1,
      'checklldponswitch' => 1,
      'quealloc' => 1,
      'verifyactivevmnic' => 1,
      'verifyvnicswitchport' => 1,
      'vmknic'               => 1,
      'rspan'                => 1,
      'configurehealthcheck' => 1,
      'configurechannelgroup' => 1,
      'removeportchannel' => 1,
      'setportrunningconfiguration' => 1,
      'getportrunningconfiguration' => 1,
      'setupnativetrunkvlan' => 1,
      'removechannelgroup' => 1,
      'backuprestore' => 1,
      'lacp' => 1,
   );


   #
   # Execute each switch/portgroup operation in the given configHash
   # one by one.
   #
   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $configHash,
                                                 'testObject' => $testObject,
                                                 'tuple' => $tuple,
                                                 'skipPostProcess'   => $skipPostProcess,
                                                 'verificationStyle' => $verificationStyle,
                                                 'persistData'       => $persistData);

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
   # of the KEYSDATABASE, so the NetAdapterWorkload's
   # ConfigureComponent will try to confgure the key.


   foreach my $config (keys %{$configHash}) {
      my $componentObj = $args{testObject};
      my $vcObj = $componentObj->{vcObj};
      my @args;

      if (defined $configHash->{vmnicadapter}) {
         my $ref = $self->GetVmnicObjects($configHash->{vmnicadapter});
         $vmnicObj = $ref->[0];
         $vmnic     = $vmnicObj->{vmnic};
      }

      my $method = undef;
      my @value = ();

      if (not defined $supportedOperations{$config}) {
         $vdLogger->Debug("The given $config operation is not supported" .
                          " or it could be a test parameter");
         next;
      }
      if ($config eq "mtu") {
         $method = "SetMTU";
         push(@value, $configHash->{mtu});
      }
      if ($config eq "vlan") {
         if ((defined $componentObj->{switchType}) &&
             ($componentObj->{switchType} =~ /pswitch/i)) {
            $method = "SetVLAN";
            push(@value, $configHash->{vlan});
            push(@value, $configHash->{action});
         } else {
            $method = "SetPortGroupVLANID";
            push(@value, $configHash->{vlan});
         }
      }
      if ($config eq "cdp") {
         $method = "EnableCDP";
         push(@value, $configHash->{cdp});
      }
      if ($config eq "createdvportgroup") {
         $method = "CreateDVPortgroup";
         push(@value, $configHash->{createdvportgroup});
         push(@value, $configHash->{nrp});
         push(@value, $configHash->{binding});
         push(@value, $configHash->{ports});
      }
      if ($config eq "removedvportgroup") {
         $method = "RemoveDVPortgroup";
         if (defined $configHash->{removedvportgroup}) {
            my @args = ("$configHash->{removedvportgroup}" , "$target");
            my $refToArr = $self->GetPortGroupNames(@args);
            $configHash->{removedvportgroup} = $refToArr->[0];
         }
         push(@value, $configHash->{removedvportgroup});
      }
      if ($config eq "addporttodvportgroup") {
         $method = "AddPortToDVPG";
         push(@value, $configHash->{addporttodvportgroup});
         push(@value, $configHash->{ports});
      }
      if ($config eq "setbeacon") {
	 if ($configHash->{setbeacon} =~ /Enable/i) {
	    $method = "SetBeacon";
	 } else {
	    $method = "ResetBeacon";
	 }
      }
      if ($config eq "configureuplinks") {
         $vcObj = $componentObj->{vcObj};
         my $anchor = $vcObj->{'hostAnchor'};

         if ($configHash->{configureuplinks} =~ /Add/i) {
            $method = "AddUplinks";
         } else {
            $method = "RemoveUplinks";
         }
         my @arrVmnicObj;
         push (@arrVmnicObj, $vmnicObj);
         push(@value, \@arrVmnicObj);
         push(@value, $anchor);
      }
      if ($config eq "configureportgroup") {
	 if ($configHash->{configureportgroup} =~ /Add/i) {
	    $method = "AddPortGroup";
	 } else {
	    $method = "DeletePortGroup";
	 }
         push(@value, $configHash->{pgname});
         push(@value, $configHash->{pgnumber});
      }
      if ($config eq "getproperties") {
         $method = "GetProperties";
      }
      if ($config eq "setnicteaming") {
         $method = "SetvSSTeaming";

	 # This vmnic value is dynamically determined by the
	 # infrastructure and used here to add one of the free
	 # pnic/vmnic as the active adapter. This vmnic value
	 # is passed from ExecuteSwitchOps() function.

         push(@value, $vmnic);
         push(@value, $configHash->{failback});
         push(@value, $configHash->{lbpolicy});
         push(@value, $configHash->{failuredetection});
         push(@value, $configHash->{notifyswitch});
      }
      if ($config eq "getteamingpolicies") {
         $method = "GetTeamingPolicies";
      }
      if ($config eq "quealloc") {
         $method = "CheckQueAlloc";
         my $refPGObj = $self->{testbed}->GetComponentObject($configHash->{testpg});
         if (not defined $refPGObj) {
            $vdLogger->Error("Invalid ref for tuple $configHash->{testpg}");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         my $pgObj = $refPGObj->[0];
         push(@value, $pgObj);
         push(@value, $configHash->{chkhwswlro});
         my $refVMKNICObj = $self->{testbed}->GetComponentObject($configHash->{testadapter});
         if (not defined $refVMKNICObj) {
            $vdLogger->Error("Invalid ref for tuple $configHash->{testvmknic}");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         my $vmknicObj = $refVMKNICObj->[0];
         push(@value, $vmknicObj);
      }
      if($config eq "setfailoverorder") {
         $method = "SetFailoverOrder";

	 my $vmnicList = $self->GetVmnicList(CONFIGVALUE => $configHash->{setfailoverorder},
                                             TARGET     => $target,
                                             SWITCH   => $componentObj
                                            );
	 if (($vmnicList eq "") || ($vmnicList eq FAILURE)) {
	    $vdLogger->Error("Failed to get the pnic list to be used for failover order");
	    VDSetLastError("ENOTDEF");
	    return FAILURE;
	 }

         push(@value, $vmnicList);
      }
      if ($config eq "settrafficshaping") {
         $vcObj = $componentObj->{vcObj};
         my $anchor = $vcObj->{'hostAnchor'};
	 if ($configHash->{settrafficshaping} =~ /Enable/i) {
	    $method = "SetvSSShaping";
	 } else {
	    $method = "ResetvSSShaping";
	 }

	 if ((defined $configHash->{executiontype}) &&
	 ($configHash->{executiontype} =~ /api/i)) {
	    $anchor = $componentObj->{hostOpsObj}{'stafVMAnchor'};
	 }
         push(@value, $configHash->{avgbandwidth});
         push(@value, $configHash->{peakbandwidth});
         push(@value, $configHash->{burstsize});
         push(@value, $anchor);
      }
      if ($config eq "editmaxports") {
         $method = "EditMaxPorts";
         my $hostObj = $componentObj->{hostOpsObj};
         my $hostIP = $hostObj->{hostIP};
         push(@value, $hostIP);
         push(@value, $configHash->{editmaxports});
      }
      if($config eq "blockport") {
         $method = "BlockPort";
         my ($dvport,$portgroup);
         if ($configHash->{blockport} =~ m/^\d+$/) {
            $dvport = $configHash->{blockport};
         } else {
            $dvport = $self->GetDVPortId($configHash->{blockport});
         }
         my $portgroupRef = $self->GetPortGroupNames($configHash->{portgroup});
         if ((not defined $dvport) || (not defined $portgroupRef->[0])) {
            $vdLogger->Error("Either dvport=$dvport or pgref=$portgroupRef->[0] not defined");
            return FAILURE;
         }
         push(@value, $dvport);
         push(@value, $portgroupRef->[0]);
      }
      if ($config eq "unblockport") {
         $method = "UnBlockPort";
         my ($dvport,$portgroup);
         if ($configHash->{unblockport} =~ m/^\d+$/) {
            $dvport = $configHash->{unblockport};
         } else {
            $dvport = $self->GetDVPortId($configHash->{unblockport});
         }
         my $portgroupRef = $self->GetPortGroupNames($configHash->{portgroup});
         push(@value, $dvport);
         push(@value, $portgroupRef->[0]);
      }
      if ($config eq "enablenetiorm") {
         $method = "EnableNetIORM";
         push(@value, $configHash->{enablenetiorm});
      }
      if ($config eq "disablenetiorm") {
         $method = "DisableNetIORM";
         push(@value, $configHash->{disablenetiorm});
      }
      if ($config eq "removeportchannel") {
         $method = "RemovePortChannel";
         push(@value, $configHash->{removeportchannel});
      }
      if ($config eq "removechannelgroup") {#Depricated
         $method = "RemoveChannelGroup";
         my $ref	 = $self->GetVmnicObjects($configHash->{"vmnicadapter"});
         my $vmnicObj = $ref->[0];
         my $switchport = $vmnicObj->{'switchPort'};
         push(@value, $switchport);
      }
      if ($config eq "accessvlan") {
         $method = "SetAccessVLAN";
         my $portgroupRef = $self->GetPortGroupNames($configHash->{portgroup});
         push(@value, $configHash->{accessvlan});
         push(@value, $portgroupRef->[0]);
         push(@value, $vmnicObj->{switchPort});
      }
      if ($config eq "trunkrange") {
         $method = "SetVLANTrunking";
         my $refHostObj = $self->GetHostObjects($configHash->{host});
         my $hostObjFromConfigHash = $refHostObj->[0];
         $componentObj->{hostOpsObj} = $hostObjFromConfigHash;
         my $hostObj = $componentObj->{hostOpsObj};
         my $host = $hostObj->{hostIP};
         my $pgName;
         my $portgroupRef;
         #
         # If the portgroup key contains the value as "Uplink" then
         # in this case the trunk range has to be set on the uplink
         # portgroup instead of the normal dvportgroup. The uplink
         # portgroup is unique for all the vds and in case of vmware
         # vds type there is only one uplink dvportgroup. The uplink
         # dvportgroup only supports setting the trunk vlan range.
         #
         if ((defined $configHash->{portgroup}) &&
             ($configHash->{portgroup} =~ m/Uplink/i)) {
            my $uplinkPort = $componentObj->GetUplinkPortGroup($host);
            if ($uplinkPort eq FAILURE) {
               $vdLogger->Error("Failed to get the uplink portgroup for $componentObj->{switch}");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            $pgName = $uplinkPort;
         } elsif (defined $configHash->{portgroup}) {
             $portgroupRef = $self->GetPortGroupNames($configHash->{portgroup});
             $pgName = $portgroupRef->[0];
         }
         push(@value, $configHash->{trunkrange});
         push(@value, $pgName);
         push(@value, $vmnicObj->{switchPort});
         push(@value, $configHash->{nativevlan});
         push(@value, $configHash->{vlanrange});
      }
      if ($config eq "enableinshaping") {
         $method = "EnableInTrafficShaping";
         my $pgName;
         my @args = ($configHash->{enableinshaping});
         my $portgroupRef = $self->GetPortGroupNames(@args);
         push(@value, $portgroupRef->[0]);
         push(@value, $configHash->{avgbandwidth});
         push(@value, $configHash->{peakbandwidth});
         push(@value, $configHash->{burstsize});
      }
      if ($config eq "disableinshaping") {
         $method = "DisableInTrafficShaping";
         my $pgName;
         my @args = ($configHash->{disableinshaping});
         my $portgroupRef = $self->GetPortGroupNames(@args);
         push(@value, $portgroupRef->[0]);
      }
      if ($config eq "enableoutshaping") {
         $method = "EnableOutTrafficShaping";
         my @args = ($configHash->{enableoutshaping});
         my $portgroupRef = $self->GetPortGroupNames(@args);
         push(@value, $portgroupRef->[0]);
         push(@value, $configHash->{avgbandwidth});
         push(@value, $configHash->{peakbandwidth});
         push(@value, $configHash->{burstsize});
      }
      if ($config eq "setpvlantype") {
         $method = "SetPVLANType";
         push(@value, $configHash->{setpvlantype});
         push(@value, $configHash->{pvlan});
      }
      if ($config eq "confignetflow") {
         my $collector;
         my $vdsIP;
         my $port;
         $method = "ConfigureNetFlow";
         if ($configHash->{confignetflow} eq "local") {
            $collector = VDNetLib::Common::Utilities::GetLocalIP();
         } else {
            $collector = $configHash->{confignetflow};
         }
         $vdsIP = VDNetLib::Common::GlobalConfig::VDNET_VDS_IP_ADDRESS;
         $port = VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT;
         push(@value, $collector);
         push(@value, $vdsIP);
         push(@value, $configHash->{internal});
         push(@value, $configHash->{idletimeout});
         push(@value, $port);
         push(@value, $configHash->{activetimeout});
         push(@value, $configHash->{sampling});
      }
      if ($config eq "setmonitoring") {
         my $pgName;
         $method = "SetMonitoring";
         my @args = ("$configHash->{dvportgroup}");
         my $portgroupRef = $self->GetPortGroupNames(@args);
         push(@value, $portgroupRef->[0]);
         push(@value, $configHash->{enable});
      }

      if ($config eq "verifyactivevmnic") {
         $method = "GetActiveVMNicUsingEsxTop";
         my $ref	 = $self->GetVmnicObjects($configHash->{"verifyactivevmnic"});
         my $vmnicObj = $ref->[0];
         my $expValue = $vmnicObj->{'vmnic'};
         # Need to check with Giri
         $componentObj->{hostOpsObj} = $vmnicObj->{hostObj};
         push(@value, $expValue);
      }
      if ($config eq "vmknic") {
          my $hostObj = $componentObj->{hostOpsObj};
          my $host = $hostObj->{hostIP};
         if($configHash->{vmknic} =~ m/add/i) {
            $method = "AddVMKNIC";
            $configHash->{host} = $host;
            push(@value, %$configHash);
            #push(@value, $configHash->{dvportgroup});
            #push(@value, $configHash->{ip});
            #push(@value, $configHash->{netmask});
            #push(@value, $configHash->{prefix});
            #push(@value, $configHash->{route});
            #push(@value, $configHash->{mtu});
         } elsif($configHash->{vmknic} =~ /remove/i) {
            $method = "RemoveVMKNIC";
            my $deviceID;
            my $anchor;
	    if (not defined $configHash->{dvportgroup}) {
          # Assume vmkNIC is present on VSS
          $vcObj = $componentObj->{vcObj};
          $anchor = $vcObj->{'hostAnchor'};
          my $hostObj = $componentObj->{hostOpsObj};
	       $deviceID = $hostObj->GetManagementInterfaceName();
                 if ($deviceID eq FAILURE) {
                    $vdLogger->Error("Failed to get the managment interface");
                    VDSetLastError("EINVALID");
                    return FAILURE;
                 }

            } else {
               # get the dvportgroup
               my $dvPortGroup;
               my @args = ("$configHash->{dvportgroup}" , "$target");
               my $portgroupRef = $self->GetPortGroupNames(@args);
               $dvPortGroup = $portgroupRef->[0];

               #
               # get the device id of the vmknic interface
               # connected to dvportgroup.
               #
               my $ref;
               my $args;
               if ($self->{testbed}{version} == 1) {
                  $args = "$target.vmknics.-1";
               } else {
                  $args = "$configHash->{dvportgroup}";
               }
              $ref =  $self->{testbed}->GetComponentObject($args);
              if (not defined $ref) {
                 $vdLogger->Error("Invalid ref $ref for tuple $args");
                 VDSetLastError("EINVALID");
                 return FAILURE;
              }
              my @arrayObjects = @$ref;
              foreach my $obj (@arrayObjects) {
                  if ($obj->{pgName} eq $dvPortGroup) {
                     $deviceID = $obj->{deviceId};
                     last;
                 }
              }
            }
            push(@value, $host);
            push(@value, $deviceID);
            push(@value, '');
            push(@value, $anchor);
         }
      }
      if ($config eq "configurehealthcheck") {
         if ($configHash->{configurehealthcheck} =~ /vlanmtu/i) {
            $method = "ConfigureVLANMTUCheck";
         } elsif($configHash->{configurehealthcheck} =~ /teaming/i)  {
            $method = "ConfigureTeamingCheck";
         }
         push(@value, $configHash->{operation});
         push(@value, $configHash->{healthcheckinterval});
      }
      if ($config eq "backuprestore") {
         $method = "ExportImportVDSDVPG";
         push(@value, $configHash->{backuprestore});
      }
      if ((not defined $componentObj) || (not defined $method)) {
         $vdLogger->Error("Object/Method name not found for operation $config");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      #
      # Call Verification to collect initial info. Execute the operation
      # then call verification to collect final info.
      #
      if ($self->{verification}) {
         my $veriResult = $self->InitVerification($self);
         if ($veriResult eq FAILURE) {
           $vdLogger->Error("Failed to call Verification");
           VDSetLastError(VDGetLastError());
           return FAILURE;
        }
      }
      #
      # Execute the switch/portgroup method by using the right object
      #
      $vdLogger->Debug("Running operation $config");
      my $result = $componentObj->$method(@value);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure $config");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      #
      # Call final verification and call GetResult which will do a diff
      # of final - initial state.
      #
      if ($self->{verification}) {
         my $veriResult = $self->FinishVerification($self);
         if ($veriResult eq FAILURE) {
           $vdLogger->Error("Failed to finish Verification");
           VDSetLastError(VDGetLastError());
           return FAILURE;
        }
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetVmnicList --
#      This method is used to prepare the comma separated ordered
#      list of vmnics to be used for setfailover operation.
#
# Input:
#      configHash   : Reference to hash with following keys:
#                     'setfailoverorder' - <1+2+3>
#      Target	    : SUT or helper1 or helper2 or helper<x>
#
# Result:
#      Returns the comma separated ordered list of vmnics based on
#      the given setfailoverorder key value.
#
# Side effects:
#      None
#
########################################################################
sub GetVmnicList
{
   my $self       = shift;
   my %args       = @_;
   my $configValue = $args{CONFIGVALUE};
   my $target	    = $args{TARGET};
   my $switchObj	  = $args{SWITCH};
   my $testbed	  = $self->{testbed};

   my $vmnicList = "";

   if (defined $configValue) {
      my @vmnics    = split(/\;;/, $configValue);
      foreach my $vmnicindex (@vmnics) {
         $vmnicindex =~ s/\s+//;
         my $refToArray = $self->GetVmnicObjects($vmnicindex);
         if ($refToArray eq FAILURE) {
            $vdLogger->Error("Failed to get the ref for adapter objects");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         my $vmnicObj = $refToArray->[0];
         # Ask Giri
         $switchObj->{hostOpsObj} = $vmnicObj->{hostObj};
         $vdLogger->Debug("Dump of vmnic obj" . Dumper($vmnicObj));
         if (not defined $vmnicObj) {
            $vdLogger->Warn("Incorrect Vmnicadapter index provided: $vmnicindex. ".
                            "Hence ignoring the same and continuing...");
            next;
         }
         if ($vmnicList eq "") {
            $vmnicList = $vmnicObj->{'vmnic'};
         } else {
            my $vmnicListTemp = $vmnicObj->{'vmnic'};
            $vmnicList = $vmnicList. "," . $vmnicListTemp;
         }
      }
   }
   #
   # In case of vdswitch, dvUplink port names corresponding to the vmnics need
   # to be obtained. This block goes through the list of vmnics computed above
   # and finds the corresponding dvUplink names.
   #
   if ($switchObj->{switchType} ne "vswitch") {
      my @nicList = split(/,/,$vmnicList);
      $vmnicList = ""; #reset the main list
      foreach my $nic (@nicList) {
         my $dvUplink = $switchObj->{hostOpsObj}->GetDVUplinkNameOfVMNic(
                           $switchObj->{switchObj}{'switch'},
                           $nic);
         if ($dvUplink eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         if ($vmnicList eq "") {
            $vmnicList = $dvUplink;
         } else { # create the dvuplink names as comma separated list
            $vmnicList = $vmnicList . "," . $dvUplink;
         }
      }
   }
   return $vmnicList;
}


#######################################################################
#
# PreProcessBlockUnblockPort --
#      Method to process BlockPort/UnblockPort property in
#      testspec and return portid and portgroup to which
#      the specified nic is connected.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
# Result:
#      Returns the dvportId and portgroup if succeed,
#      Returns FAILURE if fail;
#
# Side effects:
#      None
#
########################################################################

sub PreProcessBlockUnBlockPort
{
   my $self              = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $port = $self->GetDVPortId($keyValue);
   $vdLogger->Debug("Port with id $port will be blocked/unblocked");
   my @array;
   push @array, $port;
   push(@array, $paramValues->{portgroup});
   return \@array;
}

#######################################################################
#
# GetDVPortId --
#      This method is used to get dvport ID to which the specified nic
#      is connected.
#
# Input:
#      Interface   : Name of the machine and vnic and index whose
#                    dvPortId is to be found the fromat is
#                    <machine>:<nic>:<index>,multiple interface split
#                    by ";".
#
# Result:
#      Returns the dvportId to which the specified vnic is connected,
#      split by "," if has more than one vnic
#      On failure returns the FAILURE;
#
# Side effects:
#      None
#
########################################################################

sub GetDVPortId
{
   my $self = shift;
   my $interface = shift;
   my $mac;
   my $hostObj;
   my $result;
   my $dvportids;
   my @adapters = split( /;/,$interface);
   my $refToArray1;
   my $refToArray2;
   foreach my $adapter (@adapters) {
      my $tuple = $adapter;
      $tuple =~ s/\:/\./g;
      $refToArray1 = $self->{testbed}->GetComponentObject($tuple);
      if ($refToArray1 eq FAILURE) {
         $vdLogger->Error("Failed to get the ref for adapter objects");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      my $netAdapterObj = $refToArray1->[0];
      $mac = $netAdapterObj->{macAddress};

      my $hostObj;
      if (ref($netAdapterObj) =~ /vmknic/i){
         $hostObj = $netAdapterObj->{hostObj};
      } else {
         $hostObj = $netAdapterObj->{vmOpsObj}{hostObj};
      }

      $result = $hostObj->GetvNicDVSPortID($mac);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get the dvportID");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $dvportids=$dvportids."$result,";
   }
   $dvportids=~s/\,$//;
   return $dvportids;
}


#######################################################################
#
# GetERSPANIP --
#      This method is used to get IP address to which the specified nic
#      is connected.
#
# Input:
#      Interface   : Name of the machine and vnic and index whose
#                    dvPortId is to be found the fromat is
#                    <machine>:<nic>:<index>,multiple interface split
#                    by ";".
#
# Result:
#      Returns the IP addresss to which the specified  vnics is connected.
#      Multiple IP address split by ",".
#      On failure returns the FAILURE;
#
# Side effects:
#      None
#
########################################################################

sub GetERSPANIP
{
   my $self = shift;
   my $interface = shift;
   my $testbed = $self->{testbed};
   my $ip;
   my $hostObj;
   my $result;
   my $iplist;
   my @adapters = split( /;/,$interface);
   foreach my $adapter (@adapters) {
      my $tuple = $adapter;
      $tuple =~ s/\:/\./g;
      my $refToArray = $self->{testbed}->GetComponentObject($tuple);
      if ($refToArray eq FAILURE) {
         $vdLogger->Error("Failed to get the ref for adapter objects");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      my $vnicObj = $refToArray->[0];
      $ip = $vnicObj->GetIPv4();
      $iplist=$iplist."$ip,";
   }
   $iplist=~s/\,$//;
   $vdLogger->Debug("ERSPAN IP List:$iplist");
   return $iplist;
}


#######################################################################
#
# GetDVSUplinkAliasOfVMNic --
#      This method is used to get VDS uplinks alias to which the
#      specified nic is connected.
#
# Input:
#      switchObj   : switch object
#      vmnics      : inpout in tuple format
#
# Result:
#      Returns the VDS uplink alias to which the specified nic is connected,
#      Multiple uplinks alias split by ",".
#      On failure returns the FAILURE;
#
# Side effects:
#      None
#
########################################################################

sub GetDVSUplinkAliasOfVMNic {
   my $self = shift;
   my $switchObj = shift;
   my $vmnics = shift;
   my $testbed = $self->{testbed};
   my $result;
   my $uplinks;
   my @adapters = split( /;/,$vmnics);
   foreach my $vmnic (@adapters) {
      my $tuple = $vmnic;
      $tuple =~ s/\:/\./g;
      my $refToArray = $self->{testbed}->GetComponentObject($tuple);
      if ($refToArray eq FAILURE) {
         $vdLogger->Error("Failed to get the ref for adapter objects");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      my $vmnicObj = $refToArray->[0];
      my $nic = $vmnicObj->{'vmnic'};
      my $hostObj = $vmnicObj->{hostObj};
      my $switchName = $switchObj->{'switch'} || $switchObj->{'name'};
      $vdLogger->Debug("Running GetDVUplinkNameOfVMNic for $switchName and $nic");
      my $dvUplink =  $hostObj->GetDVUplinkNameOfVMNic($switchName,
                                                       $nic);

      if ($dvUplink eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $uplinks=$uplinks."$dvUplink,";
   }
   $uplinks=~s/\,$//;
   return $uplinks;
}


#######################################################################
#
# GetAllPortGroupObjects --
#      This method is used to return all portgroup object from the
#      Testbed datastructure under the vm
#
# Input:
#      component   : number (ver1) and tuple (ver2) (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Based on the $index, port group object is returned
#
# Side effects:
#      None
#
########################################################################
sub GetAllPortGroupObjects
{
   my $self = shift;
   my $component = shift;
   my $target = shift;
   my $args;

   if ($self->{testbed}{version} == 1) {
      $args = "$target.portgroups.-1";
   } else {
      my @array = split ('.', $component);
      $args = "$array[0] . $array[1] . 'portgroups' . '-1'";
   }
   my $ref = $self->{testbed}->GetComponentObject($args);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $args");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


#######################################################################
#
# GetVmnicObjects --
#      This method is used to return vmnic adapter object from the
#      Testbed datastructure
#
# Input:
#      component   : number (ver1) and tuple (ver2)  (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Based on the $index, vmnic adapter object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetVmnicObjects
{
   my $self = shift;
   my $component = shift;
   my $target = shift;
   my $ref;
   my $args;

   $component =~ s/\:/\./g;
   if (($self->{testbed}{version} == 1) && ($component =~ /^\d+$/)) {
      $args = "$target.vmnic.$component";
   } else {
      $args = "$component";
   }
   $ref = $self->{testbed}->GetComponentObject($args);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $args");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
# PreProcessVmknicId --
#     Method to process "vmknicpg" property in testspec and return vmknic
#     obj
#
# Input:
#     vmknicpg: tuple representing vmknic adapter
#
# Results:
#     Obj of vmknic will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVmknicId
{
   my $self = shift;
   my $vmknicPgTuple = shift;
   my @args;

   my $refVmknicArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($vmknicPgTuple);
   foreach my $vmknicTuple (@$refVmknicArray) {
      my $result = $self->{testbed}->GetComponentObject($vmknicTuple);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $vmknicTuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


########################################################################
#
# PreProcessVssName --
#     Method to process "vss" property in testspec and return vss Obj
#
# Input:
#     vss: tuple representing vss adapter
#
# Results:
#     Obj of vss will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVssName
{
   my $self = shift;
   my $vssTuple = shift;
   my @args;

   my $refVssArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($vssTuple);
   foreach my $vss (@$refVssArray) {
      my $result = $self->{testbed}->GetComponentObject($vss);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $vss");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


########################################################################
#
# PreProcessAdapters --
#     Method to process vmnics of configfailoverorder, convert them to
#     the vmnic name.
#
# Input:
#       testObject - An object, whose core api will be executed.
#       keyName    - Name of the action key.
#       keyValue   - Value assigned to action key in config hash.
#       paramValue - Reference to hash where keys are the contents of
#                    'params' and values are the values that are assigned
#                    to these keys in config hash.
#       paramList  - List of the params being passed.
#
# Results:
#     Return reference of an array carried with vmnic names.
#     Return FAILURE if the array is empty.
#
# Side effects:
#     None
#########################################################################

sub PreProcessAdapters
{
   my $self   = shift;
   my $vmnicList;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;
   if (defined $paramValue->{'setfailoverorder'}) {
      $vmnicList = $self->GetVmnicList(CONFIGVALUE => $paramValue->{'setfailoverorder'},
                                          TARGET      => $self->{workload}{Target},
                                          SWITCH      => $testObject
                                         );
      if (($vmnicList eq "") || ($vmnicList eq FAILURE)) {
         $vdLogger->Error("Failed to get the standby nic list");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   my @arguments;
   push(@arguments, $vmnicList);
   return \@arguments;
}


########################################################################
#
# PreProcessMigrateManagementNetKey --
#     Method to process "migratemgmtnettovss/vds" property in testspec
#     and return host name
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

sub PreProcessMigrateManagementNetKey
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   # Getting obj of host
   my $result = $self->{testbed}->GetComponentObject($keyValue);
   if (not defined $result) {
      $vdLogger->Error("Invalid ref for tuple $keyValue");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $paramValue->{$keyName} = $result->[0];

   my @array ;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      } elsif (defined $keyValue) {
         push(@array, $keyValue);
      }
   }
   return \@array;
}


########################################################################
#
# PostProcessMigrateManagementNetKey --
#     Post process method for migrating vmknic to newly created PG which
#     updates testbed with the new PG object
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

sub PostProcessMigrateManagementNetKey
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;

   # Updating the testbed with the new PG obj
   my $result = $self->{testbed}->SetComponentObject($self->{workload}->{vmknictuple},
                                                     $runtimeResult);
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to set the component Obj for newly ".
                       "created PG");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


1;
