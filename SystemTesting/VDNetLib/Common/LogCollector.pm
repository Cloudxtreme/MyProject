##############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
##############################################################################
package VDNetLib::Common::LogCollector;

##############################################################################
#
#  This module is responsible for handling the collection of different logs,
#  stats etc. to help users in debugging the test failure. Different failures
#  require different kind of log's. For example to diagnose a guest
#  networking failures the networking information on the host is not enough
#  it requires the guest log's, adapter stats etc.
#
#  The main workload has a log handler associated with it, when a workload
#  fails it calls the collectLogs method passing the type of workload which
#  failed. For each workload type (for e.g. host, switch etc.) there is a
#  list of items which should be collected upon failure. This list tells
#  which method should be called and how it should be called. All the logs
#  are placed in the testcaselog directory, so for e.g. VM  related logs
#  would be under Vm_<IP> and esx host related logs would be in Host_<IP>.
#
#  This makes simple to add the new logs in future, one has to just
#  add the required method in any of the relevant libraries and
#  then add that info in the relevant workload array.
#
##############################################################################

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger TRUE FALSE);
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDNetUsage;
use VDNetLib::Common::VDAutomationSetup;
use VDNetLib::VM::VMOperations;
use VDNetLib::Host::HostOperations;
use VDNetLib::VC::VCOperation;
use VDNetLib::Switch::Switch;
use VDNetLib::Switch::VSSwitch::PortGroup;
use Carp;

use constant LOGFUNCTIONMAP => {
      'net-vdl2' => {
         object => "host",
         method => "GetNetVDL2Config",
      },
      'net-vdr' => {
         object => "host",
         method => "GetNetVDRConfig",
      },
      'netConfig' => {
         object => "host",
         method => "GetNetworkConfig",
      },
      'vmkernelLog' => {
         object => "host",
         method => "GetVMKernelLog",
      },
      'guestLog' => {
         object => "vm",
         method => "GetGuestLogs",
      },
      'adapterStats' => {
         object => "netadapter",
         method => "GetAdapterStats",
      },
      'registerDump' => {
         object => "netadapter",
         method => "GetAdapterRegisterDump",
      },
      'VMNetConfig' => {
         object => "netadapter",
         method => "GetNetworkConfig",
      },
      'routeConfig' => {
         object => "netadapter",
         method => "GetRouteConfig",
      },
      'sysLogs' => {
         object => "host",
         method => "GetSysLogs",
      },
      'vmwareLog' => {
         object => "vm",
         method => "GetVMwareLogs",
      },
      'hostdLog' => {
         object => "host",
         method => "GetHostAgentLog",
      },
      'nsxmanagerLog' => {
         object => "nsxmanager",
         method => "GetNSXManagerLog",
      },
      'nsxcontrollerLog' => {
         object => "nsxcontroller",
         method => "GetNSXControllerLog",
      },
      'vpxaLog' => {
         object => "host",
         method => "GetVPXAgentLog",
      },
      'vsfwdlog' => {
         object => "host",
         method => "GetVSFWDLog",
      },
      'netcpaLog' => {
         object => "host",
         method => "GetNetCPALog",
      },
      'VSINetCache' => {
         object => "host",
         method => "GetNetVSICacheFile",
      },
      'pswitchConfig' => {
         object => "switch",
         method => "GetPhySwitchPortSetting",
      },
      'kvmLog' => {
         object => "kvm",
         method => "GetKVMLog",
      },
};

my $vsfwdLog      = LOGFUNCTIONMAP->{'vsfwdlog'};
my $netcpaLog     = LOGFUNCTIONMAP->{'netcpaLog'};
my $net_vdl2      = LOGFUNCTIONMAP->{'net-vdl2'};
my $net_vdr       = LOGFUNCTIONMAP->{'net-vdr'};
my $netConfig     = LOGFUNCTIONMAP->{'netConfig'};
my $vmkernelLog   = LOGFUNCTIONMAP->{'vmkernelLog'};
my $guestLog      = LOGFUNCTIONMAP->{'guestLog'};
my $adapterStats  = LOGFUNCTIONMAP->{'adapterStats'};
my $registerDump  = LOGFUNCTIONMAP->{'registerDump'};
my $VMNetConfig   = LOGFUNCTIONMAP->{'VMNetConfig'};
my $routeConfig   = LOGFUNCTIONMAP->{'routeConfig'};
my $vmwareLog     = LOGFUNCTIONMAP->{'vmwareLog'};
my $hostdLog      = LOGFUNCTIONMAP->{'hostdLog'};
my $vpxaLog       = LOGFUNCTIONMAP->{'vpxaLog'};
my $VSINetCache   = LOGFUNCTIONMAP->{'VSINetCache'};
my $pswitchConfig = LOGFUNCTIONMAP->{'pswitchConfig'};
my $refLogFunctionMap = LOGFUNCTIONMAP;
my $sysLogs = LOGFUNCTIONMAP->{'sysLogs'};
my $nsxmanagerLog      = LOGFUNCTIONMAP->{'nsxmanagerLog'};
my $nsxcontrollerLog      = LOGFUNCTIONMAP->{'nsxcontrollerLog'};
my $kvmLog      = LOGFUNCTIONMAP->{'kvmLog'};

#
# List of items (log's, network configuration to be collected
# for each type of workload failures. There might be cases
# where for two different type workload failures we need similar
# kind of log's and other configuration information.
#

# Things to collect for failure in switch workload.
my @switch = ( $netConfig, $vmkernelLog, $VSINetCache, $pswitchConfig);

# if the failure in traffic workload collect following items.
my @traffic = (
   $guestLog,    $registerDump, $adapterStats,
   $vmkernelLog, $vmwareLog, $VSINetCache, $pswitchConfig,
   $net_vdl2, $net_vdr, $netcpaLog, $vsfwdLog,
);

# if the failure is host workload.
my @host = ( $netConfig, $vmkernelLog, $VSINetCache, $hostdLog, $net_vdl2,
             $net_vdr, $netcpaLog, $vsfwdLog, $sysLogs );
# TODO(llai): Add ovs debug bundle and db output logs
my @kvm = ( $kvmLog );

# if the failure is in vc.
# Many properties of VC like netiorm have debugging
# information in VSINetCache thus collect that as well during
# VC operation failure.
my @vc = ( $hostdLog, $vpxaLog, $VSINetCache );

# If there is any failure in NSXManager, techsupport bundle log
# will be downloaded using REST API
my @nsxmanager = ( $nsxmanagerLog );
my @nsxcontroller = ( $nsxcontrollerLog );

# if the failure is in netadapter workload.
my @netadapter = (
   $guestLog,    $vmwareLog,   $registerDump, $adapterStats,
   $VMNetConfig, $VSINetCache, $routeConfig
);

# if the failure is vm workload.
my @vm = ( $vmwareLog, $guestLog, $vmkernelLog, $VSINetCache, $hostdLog, $sysLogs );
my @kvm_vm = ( $guestLog, $sysLogs );

my @all = ( $netConfig, $vmkernelLog, $VSINetCache, $guestLog,
            $registerDump, $adapterStats, $vmwareLog, $pswitchConfig,
            $hostdLog, $vpxaLog, $VMNetConfig, $routeConfig, $sysLogs,
            $net_vdl2, $net_vdr, $netcpaLog, $vsfwdLog,
            $nsxmanagerLog, $nsxcontrollerLog, $kvmLog );

my $workLoadSubMap = {
   'switch'     => \@switch,
   'vc'         => \@vc,
   'host'       => \@host,
   'esx'        => \@host,
   'nsxmanager' => \@nsxmanager,
   'nsxcontroller' => \@nsxcontroller,
   'netadapter' => \@netadapter,
   'vm'         => \@vm,
   'traffic'    => \@traffic,
   'kvm'        => \@kvm,
   'all'        => \@all,
};

my $customLog = {
   vmware   => 'vm.[-1]',
   vmkernel => 'host.[-1]',
   hostd    => 'host.[-1]',
};


########################################################################
#
# new --
#       Constructor for LogCollector module
#
# Input:
#   testbed : hash containing the infromation about the testbed.
#   logDir  : Name of the directory where log's are to be copied.
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;

   if ((not defined $args{testbed}) ||
       (not defined $args{logDir})) {
      $vdLogger->Error("Testbed object/Log directory not provided while" .
                       " initializing LogCollector");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self = {
      'testbed' => $args{testbed},
      'logDir'  => $args{logDir},
   };

   bless( $self, $class );
   return $self;
}


########################################################################
#
# CollectLog --
#      Method to collect the logs based on the type of failures
#
# Input:
#      Workload,  The type of logs we should collect for given tuple;
#                  One of switch/vc/host/netadapter/vm/traffic;
#      tuple,    The tuple of a object which need log collection;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub CollectLog
{
   my $self              = shift;
   my $workloadType      = shift;
   my $objTuple          = shift;
   my $testbed           = $self->{'testbed'};

   if (not defined $workloadType) {
      $vdLogger->Debug("Object tuple/Log ype not provided for log collecting");
      return FAILURE;
   }

   my ($logTypeKey, $refLogTypeArr);
   foreach my $workloadKey ( keys %{$workLoadSubMap} ) {
      if ( $workloadType =~ /$workloadKey/i ) {
         $refLogTypeArr = $workLoadSubMap->{$workloadKey};
         $logTypeKey = $workloadType;
      }
   }

   if ( not defined $refLogTypeArr ) {
      $vdLogger->Error( "Not found corresponding method for workload type" .
                        " $workloadType" );
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $tupleArray = [];
   if (defined $objTuple) {
      push @$tupleArray, $objTuple;
   } else {
      if ( $logTypeKey =~ /host/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]"];
      } elsif ( $logTypeKey =~ /switch/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]","pswitch.[-1]"];
      } elsif ( $logTypeKey =~ /netadapter/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]", "vm.[-1]",
                        "vm.[-1].vnic.[-1]"];
      } elsif ( $logTypeKey =~ /traffic/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]", "vm.[-1]",
                        "vm.[-1].vnic.[-1]", "pswitch.[-1]"];
      } elsif ( $logTypeKey =~ /vc/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]"];
      } elsif ( $logTypeKey =~ /vm/i ) {
         $tupleArray = ["vm.[-1]", "esx.[-1]", "host.[-1]"];
      } elsif ( $logTypeKey =~ /nsxmanager/i ) {
         $tupleArray = ["nsxmanager.[-1]"];
      } elsif ( $logTypeKey =~ /nsxcontroller/i ) {
         $tupleArray = ["nsxcontroller.[-1]"];
      } elsif ( $logTypeKey =~ /kvm/i ) {
         $tupleArray = ["kvm.[-1]"];
      } elsif ( $logTypeKey =~ /all/i ) {
         $tupleArray = ["host.[-1]", "esx.[-1]", "vm.[-1]",
                        "vm.[-1].vnic.[-1]", "pswitch.[-1]", "nsxmanager.[-1]",
                        "nsxcontroller.[-1]", "kvm.[-1]"];
      }
   }

   my $result;
   my $finalResult = SUCCESS;
   $vdLogger->Info("Starting log collection for tuple @$tupleArray");
   foreach $objTuple (@$tupleArray) {
      $vdLogger->Debug("Log collection for tuple $objTuple");
      foreach my $logType (@$refLogTypeArr) {
         my $logObj = $logType->{object};
         my $method = $logType->{method};
         if ( $logObj =~ /host|esx/i && $objTuple =~ /host|esx/i) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetHostLog($method, $objTuple);
         } elsif ( $logObj =~ /netadapter/i && $objTuple =~ /vnic/i) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetNetAdapterLog($method, $objTuple);
         } elsif ( $logObj =~ /^vm/i && $objTuple =~ /^vm/i
                   && $objTuple !~ /vnic/i) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetVmLog($method, $objTuple);
         } elsif ( $logObj =~ /switch/i && $objTuple  =~ /pswitch/i ) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetSwitchLog($method, $objTuple);
         } elsif ( $logObj =~ /vc/i && $objTuple =~ /vc/i ) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetVcLog($method, $objTuple);
         } elsif ( $logObj =~ /nsxmanager/i && $objTuple =~ /nsxmanager/i ) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetNSXManagerLog($method, $objTuple);
         } elsif ( $logObj =~ /nsxcontroller/i && $objTuple =~ /nsxcontroller/i ) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetComponentLog($method, $objTuple);
         } elsif ( $logObj =~ /^kvm/i && $objTuple =~ /^kvm/i ) {
            $vdLogger->Trace("Log collection method is $method, ".
                             "logobj is $logObj, objTuple is $objTuple");
            $result = $self->GetComponentLog($method, $objTuple);
         } else {
            $vdLogger->Trace("Log collection skipped, ".
                              "logobj is $logObj, objTuple is $objTuple");
            next;
         }
         if ((defined $result) && ($result eq FAILURE)) {
            $finalResult = FAILURE;
            $vdLogger->Error("Failed to collect logs $method for $objTuple");
         }
      }
   }
   return $finalResult;
}


########################################################################
#
# CollectCustomLog --
#      Method to collect logs based on the keys defined in $customLog;
#
# Input:
#      None, CollectCustomLog collects logs based on hash $customLog;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub CollectCustomLog
{
   my $self = shift;
   my $result;
   my $finalResult = SUCCESS;

   foreach my $logKey (keys %{$customLog}) {
      my $objTuple = $customLog->{$logKey};

      my $method = undef;
      my $logObj = undef;
      $vdLogger->Debug("Collecting custom logs for $logKey, $objTuple");

      foreach my $logTypeName (keys %$refLogFunctionMap) {
         if ($logTypeName =~ /$logKey/i) {
            $logObj = LOGFUNCTIONMAP->{$logTypeName}{"object"};
            $method = LOGFUNCTIONMAP->{$logTypeName}{"method"};
         }
      }

      if (not defined $logObj || not defined $method) {
         $vdLogger->Debug("Can't find corresponding object/method for " .
                          "$logKey, $logObj");
         next;
      }

      if ( $logObj =~ /host|esx/i && $objTuple =~ /host|esx/i) {
         $result = $self->GetHostLog($method, $objTuple);
      } elsif ( $logObj =~ /netadapter/i && $objTuple =~ /vnic/i) {
         $result = $self->GetNetAdapterLog($method, $objTuple);
      } elsif ( $logObj =~ /vm/i && $objTuple =~ /vm/i
                && $objTuple !~ /vnic/i) {
         $result = $self->GetVmLog($method, $objTuple);
      } elsif ( $logObj =~ /switch/i && $objTuple  =~ /pswitch/i ) {
         $result = $self->GetSwitchLog($method, $objTuple);
      } elsif ( $logObj =~ /vc/i && $objTuple =~ /vc/i ) {
         $result = $self->GetVcLog($method, $objTuple);
      } else {
         $vdLogger->Warn("CustomLog collection not implemented for $objTuple");
      }

      if ((defined $result) && ($result eq FAILURE)) {
         $vdLogger->Error("Failed to collect logs for object $objTuple");
         $finalResult = FAILURE;
      }
   }

   return $finalResult;
}


########################################################################
#
# GetSwitchLog--
#      Method which will run the required method in switch library to
#      get the logs related to switch (mainly physical switch realated).
#
# Input:
#    Method : Name of the method in switch library to be run.
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetSwitchLog
{
   my $self    = shift;
   my $method  = shift;
   my $tuple   = shift;
   my $testbed = $self->{testbed};
   my $logDir  = $self->{logDir};

   my $arrayofPswitchTuples = $testbed->GetAllComponentTuples($tuple);
   my $finalResult = SUCCESS;
   foreach my $pswitchTuple (@$arrayofPswitchTuples) {
      my $pswitchArr = $testbed->GetComponentObject($pswitchTuple);
      if ($pswitchArr eq FAILURE) {
         $vdLogger->Error("Failed to find object for tuple $pswitchTuple");
         next;
      }
      my $pswitchObj = @$pswitchArr[0];
      if ( not defined $pswitchObj ) {
         $vdLogger->Debug("Host object/pswitch object of host not defined");
         next;
      }

      my $hostObj = $pswitchObj->{"hostObj"};
      # Check Host IP Connectivity
      my $hostip = $hostObj->{hostIP};
      if (VDNetLib::Common::Utilities::Ping($hostip)) {
         $vdLogger->Error("Host $hostip not accessible");
         $finalResult = FAILURE;
      }

      #
      # create directory named host_$hostip, so that all log
      # are in separate directories
      #
      my $hostDir = $logDir . "/" . "host_$hostip";
      $hostObj->{stafHelper}->STAFFSCreateDir( $hostDir, "local" );
      if ( $pswitchObj->$method($hostDir) eq FAILURE ) {
         $vdLogger->Error("Failure while running $method() for" .
                          " PSwitch of $hostip");
         $finalResult = FAILURE;
      }
   }

   return $finalResult;
}


########################################################################
#
# GetHostLog --
#      Method to collect log for host objects.
#
# Input:
#    method,  Method name need to be called for host log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetHostLog
{
   my $self    = shift;
   my $method  = shift;
   my $tuple   = shift;

   my $logDir      = $self->{logDir};
   my $testbed     = $self->{testbed};
   my $result = SUCCESS;

   my $arrayofHostTuples = $testbed->GetAllComponentTuples($tuple);
   if ($arrayofHostTuples eq FAILURE) {
      $vdLogger->Error("Failed to get component tuples for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $hostTuple (@$arrayofHostTuples) {
      my $hostArr = $testbed->GetComponentObject($hostTuple);
      if ($hostArr eq FAILURE) {
         $vdLogger->Error("Failed to find object for tuple $hostTuple");
         next;
      }
      my $hostObj = @$hostArr[0];
      if ((not defined $hostObj) || (not defined $hostObj->{hostIP})) {
         $vdLogger->Debug("hostObj or hostObj->{hostIP} not defined");
         next;
      }

      # Check Host IP Connectivity
      my $hostip = $hostObj->{hostIP};
      if (VDNetLib::Common::Utilities::Ping($hostip)) {
         $vdLogger->Error("Host $hostip not accessible");
         $result = FAILURE;
         next;
      }

      #
      # create directory named host_$hostip, so that all logs
      # are in separate directories
      #
      my $hostDir = $logDir . "/" . "host_$hostip";
      $hostObj->{stafHelper}->STAFFSCreateDir( $hostDir, "local" );
      if ( $hostObj->$method($hostDir) eq FAILURE ) {
         $vdLogger->Error("Failure while running $method() for host $hostip");
         $result = FAILURE;
         next;
      }
   }

   return $result;
}


########################################################################
#
# GetVmLog --
#      Method to collect log for VM objects.
#
# Input:
#    method,  Method name need to be called for VM log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetVmLog
{
   my $self   = shift;
   my $method = shift;
   my $tuple  = shift;

   my $logDir    = $self->{logDir};
   my $testbed   = $self->{testbed};
   my $result = SUCCESS;

   my $arrayofVmTuples = $testbed->GetAllComponentTuples($tuple);
   foreach my $vmTuple (@$arrayofVmTuples) {
      my $vmArr = $testbed->GetComponentObject($vmTuple);
      if ($vmArr eq FAILURE) {
         $vdLogger->Error("Failed to find object for tuple $vmTuple");
         next;
      }
      my $vmObj = @$vmArr[0];
      if (defined $vmObj->{type} && $vmObj->{type} =~ m/kvm/i) {
            my @found_method = grep {$_->{method} eq $method} @kvm_vm;
            if (not scalar(@found_method)) {
                $vdLogger->Debug("Not calling $method for KVM VMs ..");
                next;
            }
      }
      # PR 1150859 : If vm not pingable, or vm failed to get control IP,
      # or VM failed to poweron, we should be able to collect vmware.log
      # for troubleshooting in all of these situations
      if ((not defined $vmObj) || ((not defined $vmObj->{vmIP}) &&
           ($method !~ /GetVMwareLogs/i))) {
         $vdLogger->Debug("vmObj or vmObj->{vmIP} not defined");
         next;
      }

      # Check VM IP Connectivity
      my $vmip = $vmObj->{vmIP};
      if ((defined $vmip) && VDNetLib::Common::Utilities::Ping($vmip)) {
         $vdLogger->Info("VM $vmip not accessible");
         if ($method !~ /GetVMwareLogs/i) {
            next;
         }
      }

      #
      # create directory named vm_$vmip, so that all log
      # are in separate directories
      #
      my $vmName = (defined $vmip) ? $vmip : $vmObj->{vmName};
      my $vmDir = $logDir . "/" . "vm_$vmName";
      $vmObj->{stafHelper}->STAFFSCreateDir( $vmDir, "local" );
      if ($vmObj->$method($vmDir) eq FAILURE) {
         $vdLogger->Error("Failure while running $method() for VM $vmName");
         $result = FAILURE;
      }
   }

   return $result;
}


########################################################################
#
# GetVcLog --
#      Method to collect log for VC objects.
#
# Input:
#    method,  Method name need to be called for VC log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetVcLog
{
   my $self   = shift;
   my $method = shift;
   my $tuple  = shift;

   my $logDir    = $self->{logDir};
   my $testbed   = $self->{testbed};
   my $result = SUCCESS;

   my $arrayofVcTuples = $testbed->GetAllComponentTuples($tuple);
   foreach my $vcTuple (@$arrayofVcTuples) {
      my $vcArr = $testbed->GetComponentObject($vcTuple);
      if ($vcArr eq FAILURE) {
         $vdLogger->Error("Failed to find object for tuple $vcTuple");
         next;
      }
      my $vcObj = @$vcArr[0];
      if ((not defined $vcObj) || (not defined $vcObj->{vcaddr})) {
         $vdLogger->Debug("vcObj or vcObj->{vcaddr} not defined");
         next;
      }

      # Check VC IP Connectivity
      my $vcip = $vcObj->{vcaddr};
      if (VDNetLib::Common::Utilities::Ping($vcip)) {
         $vdLogger->Error("VC $vcip not accessible");
         $result = FAILURE;
         next;
      }

      #
      # create a directory named vc_$vcip, so that all log
      # are in separate directories
      #
      my $hostDir = $logDir . "/" . "vc_$vcip";
      $vcObj->{stafHelper}->STAFFSCreateDir( $hostDir, "local" );
      if ( $vcObj->$method($hostDir) eq FAILURE ) {
         $vdLogger->Error("Failure while running $method() for VC $vcip");
         $result = FAILURE;
         next;
      }
   }

   return $result;
}

########################################################################
#
# GetNSXManagerLog --
#      Method to collect log for NSXManager objects.
#
# Input:
#    method,  Method name need to be called for NSXManager log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetNSXManagerLog
{
   my $self   = shift;
   my $method = shift;
   my $tuple  = shift;

   if (not defined $method ||
       not defined $tuple) {
      $vdLogger->Error("method/tuple missing in GetNSXManagerLog");
      return FAILURE;
   }
   my $logDir    = $self->{logDir};
   my $testbed   = $self->{testbed};
   my $result    = SUCCESS;

   my $arrayofNSXManagerTuples = $testbed->GetAllComponentTuples($tuple);
   foreach my $nsxTuple (@$arrayofNSXManagerTuples) {
      my $nsxArr = $testbed->GetComponentObject($nsxTuple);
      if ( $nsxArr eq FAILURE ) {
         $vdLogger->Error("Failed to find object for tuple $nsxTuple");
         next;
      }
      my $nsxObj = @$nsxArr[0];
      if ((not defined $nsxObj) || (not defined $nsxObj->{ip})) {
         $vdLogger->Info("nsxObj or nsxObj->{ip} not defined");
         next;
      }

      # Check NSX IP Connectivity
      my $nsxip = $nsxObj->{ip};

      if (VDNetLib::Common::Utilities::Ping($nsxip)) {
         $vdLogger->Error("NSXManager $nsxip not accessible");
         $result = FAILURE;
         next;
      }

      #
      # create a directory named nsx_$nsxip, so that all log
      # are in separate directories
      #

      my $hostDir = $logDir . "/" . "nsxmanager_$nsxip/";
      $nsxObj->{stafHelper}->STAFFSCreateDir( $hostDir, "local" );
      if ( $nsxObj->$method($hostDir) eq FAILURE ) {
         $vdLogger->Error("Failure while running $method() for NSXManager $nsxip");
         $result = FAILURE;
         next;
      }
   }

   return $result;
}


########################################################################
#
# GetComponentLog --
#      Method to collect log for component objects.
#
# Input:
#    method,  Method name need to be called for component log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetComponentLog
{
   my $self   = shift;
   my $method = shift;
   my $tuple  = shift;

   if ((not defined $method) || (not defined $tuple)) {
      $vdLogger->Error("method/tuple missing in GetComponentLog");
      return FAILURE;
   }
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @tupleNameArray = split('\.',$tuple);
   my $componentName = $tupleNameArray[0];

   my $logDir    = $self->{logDir};
   my $testbed   = $self->{testbed};
   my $finalResult = SUCCESS;

   my $arrayofTuples = $testbed->GetAllComponentTuples($tuple);
   foreach my $tuple (@$arrayofTuples) {
      my $objArr = $testbed->GetComponentObject($tuple);
      if ( $objArr eq FAILURE ) {
         $vdLogger->Error("Failed to find object for tuple $tuple");
         $finalResult = FAILURE;
         next;
      }
      my $componentObj = @$objArr[0];
      if ((not defined $componentObj)) {
         $vdLogger->Info("Component object not defined");
         next;
      }
      my $componentIP = undef;
      if (exists $componentObj->{ip}) {
         $componentIP = $componentObj->{ip};
      } elsif (exists $componentObj->{hostIP}) {
         $componentIP = $componentObj->{hostIP};
      }
      if (not defined $componentIP) {
         $vdLogger->Info("Component IP not defined");
         next;
      }

      # Check IP Connectivity
      if (VDNetLib::Common::Utilities::Ping($componentIP)) {
         $vdLogger->Error("IP $componentIP for $tuple not accessible");
         $finalResult = FAILURE;
         next;
      }
      #
      # create a directory named component_$componentIP, so that all log
      # are in separate directories
      #

      my $hostDir = $logDir . "/$componentName" . "_$componentIP/";
      $componentObj->{stafHelper}->STAFFSCreateDir( $hostDir, "local" );
      if ($componentObj->$method($hostDir, $localIP) eq FAILURE) {
         $vdLogger->Error("Failure while running $method() for " .
                          "$componentName $componentIP");
         $finalResult = FAILURE;
         next;
      }
   }

   if ($finalResult eq FAILURE) {
      VDSetLastError("EFAIL");
   }
   return $finalResult;
}


########################################################################
#
# GetNetAdapterLog --
#      Method to collect log for given net adapter object.
#
# Input:
#    method,  Method name need to be called for net adapter log collecting;
#    tuple,   Tuple representation of objects;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetNetAdapterLog
{
   my $self   = shift;
   my $method = shift;
   my $tuple  = shift;

   my $logDir            = $self->{logDir};
   my $testbed           = $self->{testbed};
   my $result            = SUCCESS;

   my $arrayofVnicTuples = $testbed->GetAllComponentTuples($tuple);
   foreach my $netAdapterTuple (@$arrayofVnicTuples) {
      my $netAdapterArr = $testbed->GetComponentObject($netAdapterTuple);
      if ($netAdapterArr eq FAILURE ) {
         $vdLogger->Error("Failed to find object for tuple $netAdapterTuple");
         next;
      }
      my $netAdapterObj = @$netAdapterArr[0];

      # Check net adapter IP Connectivity
      my $netAdapterip = $netAdapterObj->{controlIP};
      if (not defined $netAdapterip) {
         $vdLogger->Error("VM adapter IP not defined for $netAdapterTuple");
         next;
      }
      if (VDNetLib::Common::Utilities::Ping($netAdapterip)) {
         $vdLogger->Error("VM adapter IP $netAdapterip not accessible");
         $result = FAILURE;
         next;
      }

      my $vmDir = $logDir . "/" . "vm_$netAdapterip";
      my $vmOpsObj = $netAdapterObj->{vmOpsObj};
      $vmOpsObj->{stafHelper}->STAFFSCreateDir($vmDir,"local");
      if ( $netAdapterObj->$method($vmDir) eq FAILURE ) {
         $vdLogger->Error( "Failure while running $method() for VM adapter"
              . " IP $netAdapterip" );
         $result = FAILURE;
         next;
      }
   }

   return $result;
}


########################################################################
#
# AddCustomLogs --
#      Method to inject new key to the list of keys.
#
# Input:
#    logKeyName,  Key name need to inject. Now below keys are supported:
#                 net/vmkernel/guest/adapter/eeprom/register/vmnet/
#                 route/vmware/hostd/vpxa/vsinet/pswitch
#    tuple,       general tuple string;
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub AddCustomLogs
{
   my $self   = shift;
   my $logKeyName = shift;
   my $tuple  = shift;

   if (not defined $logKeyName ||
       not defined $tuple) {
      $vdLogger->Error("logKeyName/tuple missing in AddCustomLogs");
      return FAILURE;
   }

   $customLog->{$logKeyName} = $tuple;
   return SUCCESS;
}


########################################################################
#
# RemoveCustomLogs --
#      Method to remove a key from log
#
# Input:
#    logKeyName,  Method name need to be called for net adapter log collecting;
#
# Results:
#       SUCCESS always
#
# Side effects:
#       None
#
########################################################################

sub RemoveCustomLogs
{
   my $self       = shift;
   my $logKeyName = shift;

   if (exists($customLog->{$logKeyName})) {
      delete $customLog->{$logKeyName};
   }
   return SUCCESS;
}


########################################################################
#
# CreateLogArchive --
#      Method to create log archive, will upload to CAT for problem
#      troubleshooting;
#
# Input:
#    None
#
# Results:
#       SUCCESS on a successful archive creation otherwise FAILURE
#
# Side effects:
#       None
#
########################################################################

sub CreateLogArchive
{
   my $self   = shift;
   my $logDir            = $self->{logDir};

   #
   # Here we run tar utility to create a log archive;
   #
   $logDir =~ /(\d+_.*)/;
   my $archiveName = $1 . ".tar.gz";
   `tar -zcf $logDir/$archiveName * --exclude=testcase.log  --exclude=vdNetInlineJava.log`;
   if ($? != 0) {
      $vdLogger->Error("Error occured while creating log archive.");
      return FAILURE;
   };

   return SUCCESS;
}

1;
