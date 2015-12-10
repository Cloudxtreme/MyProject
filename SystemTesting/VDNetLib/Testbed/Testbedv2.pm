#############################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::Testbed::Testbedv2;

##############################################################################
#  Testbedv2 class creates testbed object taking testbedSpec and few other
#  runtime options.
#
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

use List::Util qw( min max );
use Scalar::Util qw(blessed);
use Storable;
use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT $sshSession);
use VDNetLib::Zookeeper::ZKLock;
use VDNetLib::Root::Root;
use VDNetLib::Common::Utilities;
use VDNetLib::VM::VMOperations;
use VDNetLib::Host::HostFactory;
use VDNetLib::Host::Netstack;
use VDNetLib::VC::VCOperation;
use VDNetLib::VC::Datacenter;
use VDNetLib::VC::Cluster;
use VDNetLib::Switch::Switch;
use VDNetLib::Switch::VSSwitch::PortGroup;
use VDNetLib::Common::LogCollector;
use VDNetLib::Common::ZooKeeper;
use VDNetLib::TestData::TestConstants;
use VDNetLib::Testbed::Utilities;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use VDNetLib::Common::Tasks;
use VDNetLib::Common::Operator;
use Carp;
use constant TRUE  => 1;
use constant FALSE => 0;
use constant GUESTIP_DEFAULT_TIMEOUT => 300;
use constant GUESTIP_SLEEPTIME => 5;
use constant GUEST_BOOTTIME => 60;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VDNET_LOCAL_MOUNTPOINT => "vdtest";
use constant VDNET_SHARED_MOUNTPOINT => "vdnetSharedStorage";
use constant ROUNDROBIN => "roundrobin";
use Inline::Python qw(eval_python
                     py_bind_class
		     py_eval
                     py_study_package
		     py_call_function
		     py_call_method
                     py_is_tuple);
py_eval('import pickle');


########################################################################
#
# new --
#       Constructor for Testbed object
#
# Input:
#	testbedSpec : Entire testbedSpec Hash
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
   my ($class) = shift;
   my %args    = @_;

   my $self = {};
   $self->{testbedSpec}	  =  $args{testbedSpec};
   $self->{stafHelper}	  =  $args{stafHelper};
   $self->{skipSetup}	  =  $args{skipSetup};
   $self->{noTools}	  =  $args{noTools};
   $self->{vdNetSrc}	  =  $args{vdNetSrc};
   $self->{vdNetShare}	  =  $args{vdNetShare};
   $self->{sharedStorage} =  $args{sharedStorage};
   $self->{vmServer}	  =  $args{vmServer};
   $self->{vmShare}	  =  $args{vmShare};
   $self->{version}       =  $args{version};
   $self->{testCaseNumber}=  $args{testCaseNumber};
   $self->{zookeeperObj}  =  $args{zookeeperObj};
   $self->{zkSessionNode} =  $args{zkSessionNode} ||
      VDNetLib::Common::GlobalConfig::ZOOKEEPER_TEST_SESSION_NODE;
   $self->{logDir}        =  $args{logDir};
   $self->{'maxWorkers'}      =  $args{'maxWorkers'};
   $self->{'maxWorkerTimeout'} = (defined $args{'maxWorkerTimeout'}) ?
       $args{'maxWorkerTimeout'} : VDNetLib::TestData::TestConstants::MAX_TIMEOUT;
   $self->{zkHandle}      = undef;

   #
   # Store the current process id, this is needed for Event handler to send
   # signal from child processes to parent.
   #
   $self->{pid} = $$;
   $self->{areLogsCollected} = FALSE;

   bless $self, $class;
   my $masterControlIP;
   # fill in the master controlIP here
   if (($masterControlIP =  VDNetLib::Common::Utilities::GetLocalIP()) eq FAILURE) {
      $vdLogger->Error("Unable to Get master controller IP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("master controller IP is: $masterControlIP\n");

   $self->{noOfMachines}  = 0;
   $self->{resourceCache} = [];
   $self->{testbed}	  = ();

   if ($self->InitializeWorkloads() eq FAILURE) {
      $vdLogger->Error("Failed to initialize Workload Anchors.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $logCollector = VDNetLib::Common::LogCollector->new(testbed => $self,
                                                          logDir  => $self->{logDir});
   if ($logCollector eq FAILURE) {
      $vdLogger->Error("Failed to create object of VDNetLib::Common::LogCollector");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{logCollector}  =  $logCollector;

   #
   # Perform vdNet automation setup on the given testbed if,
   # if -s option is not provided at vdNet.pl command-line.
   #
   if (not defined $self->{'skipSetup'}) {
      #
      # Skip checking samba on controller machine if vdNet source to be used is
      # from scm-trees.
      #
      if ($self->{vdNetSrc} !~ /scm-trees/i) {
	 # check SMB setup on the given vdNetSrc Server
	 $vdLogger->Debug("Checking if SAMBA is running locally");
	 if ($self->IsSMBRunning eq FAILURE && $self->StartSMB eq FAILURE) {
	    $vdLogger->Warn("Either SMB is not installed or unable to run SMB");
	 }
	 $vdLogger->Debug("SAMBA is running locally");
      }
   }

   return $self;
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
# Side effects:
#       none
#
########################################################################

sub Init
{
   my $self	    = shift;
   my $testbedSpec  = shift || $self->{'testbedSpec'};
   $self->{'testbedSpec'} = $testbedSpec; # should testbedSpec be class
                                          # attribute?
   my $result;
   my $nestedObj = undef;
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # create root object and store it it zookeeper.
   my $rootObj = VDNetLib::Root::Root->new();
   $result = $self->SetComponentObject("root.[1]",
                                       $rootObj);

   # TODO: Remove this block once 'host' in testbed specs are completed
   # converted to esx
   if (defined  $testbedSpec->{host}) {
      $vdLogger->Info("The args of init: @_");                                                                                                                                                                                               
      foreach my $item (@_) {                                                                                                                                                                                                                
         $vdLogger->Info("The each items : $item");                                                                                                                                                                                          
      }
      my $functionRef = sub {$self->InitializeHostPhysicalComponents(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "host");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize Host.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (not ($result eq SUCCESS)) {
         $nestedObj = $result;
         $vdLogger->Info("NestedObj is $nestedObj");
      }
      $vdLogger->Info("Host initialization for physical components ".
		      "is complete.\n\n");
      $vdLogger->Info("The result of InitializeHostPhysicalComponents is $result");
   }
   # add support to take 'esx' as key to represent ESX hypervisor
   if (defined  $testbedSpec->{esx}) {
      my $functionRef = sub {$self->InitializeHostPhysicalComponents(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "esx");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize ESX");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("ESX initialization for physical components ".
		      "is complete.\n\n");
   }
   # KVM Initialization
   if (defined  $testbedSpec->{kvm}) {
      my $kvm = "VDNetLib::Host::KVMOperations";
      eval "require $kvm";
      if ($@) {
         $vdLogger->Error("Loading KVMOperations.pm, failed" . Dumper($@));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $functionRef = sub {$self->InitializeKVM(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "kvm");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize KVM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("KVM initialization is complete.\n\n");
   }

   if (defined  $testbedSpec->{pswitch}) {
      $result =  $self->InitializePswitch($testbedSpec->{pswitch});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize Pswitch.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Pswitch initialization is complete.\n\n");
   }

   if (defined  $testbedSpec->{vc}) {
      my $functionRef = sub {$self->InitializeVC(@_)};
      $result =  $self->InitializeUsingThreads($functionRef, "vc");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize VC.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("VC initialization is complete.\n\n");
   }

   #
   # Initializing inventory objects in a generic way
   # using InitializeInventory. InitializeInventory()
   # would create objects for all inventory items
   # before configuring them.
   # TODO (gjayavelu/prabudh): All inventory items
   # could be initialized using InitializeInventory().
   # For now, initializing nsxmanager and nsxcontroller using
   # this approach.
   #
   our $inventoryMap = [
      {
         'inventory' => 'nsxcontroller',
         'module' => 'VDNetLib::NSXController::NSXController',
         'workload' => "Controller",
      },
      {
         'inventory' => 'nsxedge',
         'module' => 'VDNetLib::NSXEdge::Edge',
         'workload' => "Gateway",
      },
      {
         'inventory' => 'nsx_uidriver',
         'module' => 'VDNetLib::NSXManager::NSXUIDriver',
         'workload' => "UIDriver",
      },
      {
         'inventory' => 'nsxmanager',
         'module' => 'VDNetLib::NSXManager::NSXManager',
         'workload' => "NSX",
      },
      {
         'inventory' => 'torgateway',
         'module' => 'VDNetLib::TORGateway::TORGateway',
         'workload' => "Gateway",
      },
   ];
   foreach my $item (@$inventoryMap) {
      my $inventory = $item->{inventory};
      if (not exists $testbedSpec->{$inventory}) {
         next;
      }
      my $module = $item->{module};
      my $workloadName = $item->{workload};
      my $inventorySpec = $testbedSpec->{$inventory};
      foreach my $inventoryIndex (keys %$inventorySpec) {
         $result = $self->InitializeInventory(
            $inventorySpec->{$inventoryIndex},
            $inventoryIndex,
            $inventory,
            $module,
            $workloadName);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to initialize inventory $inventory: ".
                             $inventoryIndex);
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   # Initialize VSM before initializing the virtual components of the
   # host. That way any components created by HostPrep, say nsx-vswitch,
   # vtep vmknic can be initialized correctly. Otherwise, any reference
   # to the components will throw error.
   #
   if (defined  $testbedSpec->{vsm}) {
      my $vsmModule = "VDNetLib::VSM::VSMOperations";
      eval "require $vsmModule";
      if ($@) {
         $vdLogger->Error("Loading VSM.pm, failed" . Dumper($@));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $functionRef = sub {$self->InitializeVSM(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "vsm");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialie VSM.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $functionRef = sub {$self->ConfigureVSM(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "vsm");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialie VSM.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("VSM initialization is complete.\n\n");
   }


   # Neutron Initialization
   if (defined  $testbedSpec->{neutron}) {
      my $neutronModule = "VDNetLib::Neutron::NeutronOperations";
      eval "require $neutronModule";
      if ($@) {
         $vdLogger->Error("Loading NeutronOperations.pm, failed" . Dumper($@));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $neutronSpec = $testbedSpec->{neutron};
      foreach my $inventoryIndex (keys %$neutronSpec) {
         $result =  $self->InitializeNeutron($inventoryIndex,
                                  $neutronSpec->{$inventoryIndex});
         if ($result eq FAILURE) {
	          $vdLogger->Error("Failed to initialie Neutron node.");
	          VDSetLastError(VDGetLastError());
	          return FAILURE;
         }
         $vdLogger->Info("Neutron node initialization is complete.\n\n");
      }
   }

   if (defined  $testbedSpec->{host}) {
      $vdLogger->Info("The args of init: @_");
      foreach my $item (@_) {
         $vdLogger->Info("The each items : $item");
      }
      my $functionRef = sub {$self->InitializeHostVirtualComponents(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "host");
      $vdLogger->Info("The result of InitializeUsingThreadsInitializeUsingThreads is $result");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize Host.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (not ($result eq SUCCESS)) {
         $nestedObj = $result;
         $vdLogger->Info("NestedvirutalObj is $nestedObj");
      }
      $vdLogger->Info("Host initialization for virtual components ".
		                "is complete.\n\n");
   }

   if (defined  $testbedSpec->{esx}) {
      my $functionRef = sub {$self->InitializeHostVirtualComponents(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "esx");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize ESX.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("ESX initialization for virtual components ".
		                "is complete.\n\n");
   }
   if (defined  $testbedSpec->{kvm}) {
      my $functionRef = sub {$self->ConfigureKVM(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "kvm");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize KVM.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("KVM initialization for virtual components ".
		                "is complete.\n\n");
   }
   # Initialize Authentication Server
   if (defined  $testbedSpec->{authserver}) {
      my $authserverModule = "VDNetLib::AuthServer::AuthServer";
      eval "require $authserverModule";
      if ($@) {
         $vdLogger->Error("Loading AuthServer.pm, failed" . Dumper($@));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $authserverSpec = $testbedSpec->{authserver};
      foreach my $inventoryIndex (keys %$authserverSpec) {
         $result =  $self->InitializeAuthServer($inventoryIndex, $authserverSpec->{$inventoryIndex});
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to initialie AuthServer.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("AuthServer initialization is complete.\n\n");
      }
   }
   # Initialize Logging Server
   if (defined  $testbedSpec->{logserver}) {
      my $logServerModule = "VDNetLib::LogServer::LogServer";
      eval "require $logServerModule";
      if ($@) {
         $vdLogger->Error("Loading LogServer.pm, failed" . Dumper($@));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $logServerSpec = $testbedSpec->{logserver};

      foreach my $inventoryIndex (keys %$logServerSpec) {
         $result =  $self->InitializeInventory($logServerSpec->{$inventoryIndex}
                                                , $inventoryIndex,
                                               "LogServer", $logServerModule);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to initialie Logging Server.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("Log Server initialization is complete.\n\n");
      }
   }
   #
   # Configure the inventory items here based on inventoryMap
   #
   foreach my $item (@$inventoryMap) {
      my $inventory = $item->{inventory};
      if (not exists $testbedSpec->{$inventory}) {
         next;
      }
      my $inventorySpec = $testbedSpec->{$inventory};
      my $workload = $item->{workload};
      foreach my $inventoryIndex (keys %$inventorySpec) {
         $result =  $self->ConfigureInventory(
            inventoryName => $inventory,
            inventoryIndex => $inventoryIndex,
            configSpec => $inventorySpec->{$inventoryIndex},
            workload => $workload);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to configure $inventory\.$inventoryIndex");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("$inventory configuration is complete.\n\n");
      }
   }

   #
   # Configure all types of vm
   #
   my @arrayOfVMTypes = ("vm","powerclivm","dhcpserver", "linuxrouter");
   $vdLogger->Info("Initializing vms needed for the testcase...");
   foreach my $prefix (@arrayOfVMTypes) {
      $vdLogger->Debug("Initializing $prefix needed for the testcase...");
      $result = $self->InitializeAllTypesOfVM($testbedSpec, $prefix);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize VM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
 #  my $hostObject = $self->GetComponentObject("host.[2]");
   
 #  my $freep =  $hostObject->{esxutil}->GetFreePNicsDetails("10.115.174.217");
 #  my $ret = $self->InitNestedVmnic($hostObject, '1',$freep);
 #  if ($result eq FAILURE) {
 #        $vdLogger->Error("Failed to initialize nested vmnic1111111111111111111");
 #        VDSetLastError(VDGetLastError());
 #        return FAILURE;
 #     }
#    $vdLogger->Info("Sucess to initiliae neste vmnic");
   #
   # Now check setup on host and guest
   #
   $vdLogger->Info("Checking setup on hosts and vms...");
#   if ($self->CheckSetup() eq FAILURE) {
#      VDSetLastError(VDGetLastError());
#      return FAILURE;
#   }

   if (defined  $testbedSpec->{testinventory}) {
      my $functionRef = sub {$self->InitializeTestInventory(@_)};
      $result = $self->InitializeUsingThreads($functionRef, "testinventory");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize TestInventory.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("TestInventory initialization is complete.\n\n");
      $self->GetWorkloadObject("TestComponent");

   }
   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return SUCCESS;
}

sub InitNestedVmnic {
   my $self        = shift;
   my $hostObj = shift;
   my $componentIndex = shift;
   my $freepnics = shift;
   my $inventoryIndex = '2';
   my $hostIndexName = 'host';

            my $vmnicObj = $self->InitializeVmnicAdapter($hostObj,
                                                      $componentIndex,
                                                      $freepnics,
                                                      $componentIndex);
         if ($vmnicObj eq FAILURE) {
            $vdLogger->Error("Failed to create vmnic: $componentIndex,".
                             " for Host: $inventoryIndex");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("The arggggg: $hostIndexName, $inventoryIndex, $componentIndex");
         my $result = $self->SetComponentObject(
                                             "$hostIndexName.[$inventoryIndex].vmnic.[$componentIndex]",
                                             $vmnicObj);
   return $vmnicObj;
}

########################################################################
#
# InitializeAllTypesOfVM --
#       This module initializes all types of VM
#       in vdNet.
#
# Input:
#       vmSpec:  vm Specification
#       prefix:  Type of VM
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub InitializeAllTypesOfVM
{
   my $self        = shift;
   my $vmSpec = shift;
   my $prefix      = shift;
   my $nestObj = shift;
   if (defined  $vmSpec->{$prefix}) {
      $vdLogger->Debug("Initializing $prefix needed for the testcase...");
      my $functionRef = sub {$self->DeployVM(@_)};
      my $result = $self->InitializeUsingThreads($functionRef, $prefix);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to deploy VM $prefix.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $functionRef = sub {$self->InitializeVM(@_)};
      $result = $self->InitializeUsingThreads($functionRef, $prefix);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize VM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("VM initialization is complete.\n\n");
   }
}


########################################################################
#
# InitializeWorkloads --
#       This module initializes the anchor for each of the workloads
#	in vdNet.
#
# Input:
#	None
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub InitializeWorkloads
{
   my $self = shift;

   my @workloads = (
      #'Host',
      #'NetAdapter',
      'Switch',
      'PortGroup',
      'Port',
      'Netstack',
      'VM',
      'LocalVDR',
      'Datacenter',
      'Cluster',
      'NSX',
      'TransportZone',
      'Tor',
   );

   foreach my $type (@workloads) {
      # Append "Workload" to the type of workload
      $type	       = $type . "Workload";
      my $workloadType = "VDNetLib::Workloads::" . $type;

      #
      # Load the workload module that can understand and process the
      # workload hash.
      #
      eval "require $workloadType";

      if ($@) {
	 $vdLogger->Error("unable to load module $workloadType:$@");
	 VDSetLastError("EOPFAILED");
	 return FAILURE;
      }
      my $dummyWorkload = {};
      my $workloadObj =  $workloadType->new(workload   => $dummyWorkload,
					    testbed    => $self,
					    stafHelper => $self->{stafHelper});
      if ($workloadObj eq FAILURE) {
	 $vdLogger->Error("Failed to create $workloadType object");
	 $vdLogger->Debug(VDGetLastError());
	 return FAILURE;
      }

      $self->{$type} = $workloadObj;
   }

   return SUCCESS;
}


########################################################################
#
# GetWorkloadObject --
#       This function creates an workload object and return it
#
# Input:
#       workloadType: The workload type, like "Host", "NetAdapter"
#
# Results:
#       Workload object if no errors encoutered else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub GetWorkloadObject
{
   my $self = shift;
   my $workloadType = shift;

   # Append "Workload" to the type of workload
   $workloadType = "VDNetLib::Workloads::" . $workloadType . "Workload";

  eval "require $workloadType";

   if ($@) {
      $vdLogger->Error("unable to load module $workloadType:$@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $dummyWorkload = {};
   my $workloadObj =  $workloadType->new(workload   => $dummyWorkload,
	                                 testbed    => $self,
				         stafHelper => $self->{stafHelper});
   if ($workloadObj eq FAILURE) {
      $vdLogger->Error("Failed to create $workloadType object");
      $vdLogger->Debug(VDGetLastError());
      return FAILURE;
   }

   return $workloadObj;
}


########################################################################
#
# InitializeVC --
#      Method to initialize VC required for a session. All the
#      initialization required on given VC is handled in this method.
#
# Input:
#      vcSpec : VC Spec (Required)
#
# Results:
#      "SUCCESS", if the required vc's are initialized
#                 successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeVC
{
   my $self = shift;
   my $vcSpec = shift;
   my $inventoryIndex = shift;
   my $vcIndexName = shift;
   my $result = undef;

   $vdLogger->Info("Initializing VC needed for the testcase...");


   if (not defined $vcSpec->{ip}) {
      $vdLogger->Error("No IP address is given for vc: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $username = $vcSpec->{username};
   my $passwd   = $vcSpec->{password};

   if ((not defined $username) || (not defined $passwd)) {
      ($username, $passwd) =
       VDNetLib::Common::Utilities::GetVCCredentials(
             $self->{stafHelper},
             $vcSpec->{ip});
   }

   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error(
       "Failed to get login credentials for VC: $inventoryIndex".
       " Please confirm that VC is up and credentials ".
       "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("Found the VC: $inventoryIndex Credentials: ".
              " $username/$passwd");

   my $vcOpsObj = VDNetLib::VC::VCOperation->new(
             $vcSpec->{ip},
             $username, $passwd);
   if ($vcOpsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VCOperations object for ".
                  "VC: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # inventory object will always be stored as x.[x] (e.g. vc.[1])
   $result = $self->SetComponentObject("vc.[$inventoryIndex]",
                                      $vcOpsObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Initialize the datacenters.
   my $datacenterHash = $vcSpec->{datacenter};
   if (defined $datacenterHash) {
      $vdLogger->Info("Initializing datacenters needed for the testcase...");
      foreach my $componentIndex (keys %$datacenterHash) {
         my $dcObj = $self->InitializeDC($vcOpsObj,
                            $datacenterHash->{$componentIndex},
                            $componentIndex,
                            $inventoryIndex);
         if ($dcObj eq FAILURE) {
            $vdLogger->Error("Failed to create datacenter: $componentIndex,".
            " for VC: $inventoryIndex");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $result = $self->SetComponentObject(
                          "vc.[$inventoryIndex].datacenter.[$componentIndex]",
                          $dcObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to update the testbed hash.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Info("Successfully created the datacenter:".
                        "vc.[$inventoryIndex].datacenter.[$componentIndex]");
      }
   }

   # Initialize the VDS.
   my $vdsHash = $vcSpec->{vds};
   if (defined $vdsHash) {
      $vdLogger->Info("Initializing VDS needed for the testcase...");
      foreach my $componentIndex (keys %$vdsHash) {
         my $vdsObj = $self->InitializeVDS($vcOpsObj,
                             $vdsHash->{$componentIndex},
                             $componentIndex);
         if ($vdsObj eq FAILURE) {
            $vdLogger->Error("Failed to create VDS: $componentIndex,".
                             " for VC: $inventoryIndex");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $result = $self->SetComponentObject(
                          "vc.[$inventoryIndex].vds.[$componentIndex]",
                          $vdsObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to update the testbed hash.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Info("Successfully created the VDS: " .
                        "vc.[$inventoryIndex].vds.[$componentIndex]");
      }
   }

   # Initialize the DVPortgroup.
   my $dvpgHash = $vcSpec->{dvportgroup};
   if (defined $dvpgHash) {
      $vdLogger->Info("Initializing DVPortgroup needed for the testcase...");
      my $vcWorkloadObj = $self->GetWorkloadObject("VC");

      # In order to create dvportgroup/s, the dvportgroup key must be
      # processed by configureComponent.  So we must ammend the dvpgHash
      # by setting dvpg spec equal to dvportgroup key
      my $dvpgHash = {'dvportgroup' => $dvpgHash};

      my $tuple = "vc.[$inventoryIndex]";
      $vcWorkloadObj->SetComponentIndex($tuple);

      $result = $vcWorkloadObj->ConfigureComponent(
                                            'configHash' => $dvpgHash,
                                            'tuple'      => $tuple,
                                            'testObject' => $vcOpsObj);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure DVPortgroup components".
                          " with :". Dumper($dvpgHash));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Info("Successfully created the DVPortgroup/s");
   }
   $vdLogger->Info("Successfully completed the initialization of VC".
                   ": $vcSpec->{ip}\n\n");
   return SUCCESS;
}


########################################################################
#
# InitializeAllPswitches --
#      Method to initialize all the required physical switch based on
#      vmnics
#
# Input:
#      pswitchSpec : pswitch Spec (Required)
#
# Results:
#      "SUCCESS", if the required pswitches are initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeAllPswitches
{
   my $self        = shift;
   my $pswitchSpec = shift;
   my $result      = undef;

   # Get all the vmnics
   my $arrayVmnicTuples = $self->ResolveTuple("host.[-1].vmnic.[-1]");
   my $refHash;
   foreach my $vmnicTuple (@$arrayVmnicTuples) {
      my $result = $self->GetComponentObject($vmnicTuple);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get object for tuple: $vmnicTuple.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $vmnicObj = $result->[0];
      if (defined $vmnicObj->{switchAddress}) {
         # Store the mgmtIP of pswitches for corressponding $vmnicTuple
         $refHash->{$vmnicObj->{switchAddress}} = $vmnicObj->{pswitchObj};
      }
   }

   # Store the pswitch object in Zookeeper
   my $count = "1";
   foreach my $eachMgmtIP (keys %$refHash) {
      $result = $self->SetComponentObject("pswitch.[$count]",
                                          $refHash->{$eachMgmtIP});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash for");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Successfully added the pswitch pswitch.[$count] with mgmtIP: " .
                      "$eachMgmtIP\n");
      $count++;
   }
   return SUCCESS;
}


########################################################################
#
# InitializePswitchFromSpec --
#      Method to initialize  physical switch based from the spec
#
# Input:
#      pswitchSpec : pswitch Spec (Required)
#
# Results:
#      "SUCCESS", if the required pswitches are initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializePswitchFromSpec
{
   my $self        = shift;
   my $pswitchSpec = shift;
   my $result      = undef;

   foreach my $inventoryIndex (keys %$pswitchSpec) {
      my $mgmtIP = $pswitchSpec->{$inventoryIndex}{ip};
      if (not defined $mgmtIP) {
         $vdLogger->Error("No IP address is given for pswitch: $inventoryIndex");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      my $pswitchObj = VDNetLib::Switch::Switch->new(
            switchType    => "pswitch",
            switchAddress => $mgmtIP,
            password => $pswitchSpec->{$inventoryIndex}{password},
            username => $pswitchSpec->{$inventoryIndex}{username}
                                                    );
      if ($pswitchObj eq FAILURE) {
         $vdLogger->Error("Failed to create pswitch object: $mgmtIP");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $result = $self->SetComponentObject("pswitch.[$inventoryIndex]",
                                          $pswitchObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Successfully added the pswitch with mgmtIP: $mgmtIP\n");
   }

   return SUCCESS;

}


########################################################################
#
# InitializePswitch --
#      Method to initialize the required physical switch.
#      This method reuses the the pswitch object stored in vmnics
#      and stores it in form of pswitch.[index].
#
# Input:
#      pswitchSpec : pswitch Spec (Required)
#
# Results:
#      "SUCCESS", if the required pswitches are initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializePswitch
{
   my $self        = shift;
   my $pswitchSpec = shift;
   my $result      = undef;

   # Special index '-1'
   if (/-1/ ~~ %$pswitchSpec) {
      $vdLogger->Info("Initializing pswitches based on vmnics...");
      return $self->InitializeAllPswitches($pswitchSpec);
   } else {
      # For normal index values
      $vdLogger->Info("Initializing pswitches based on the spec...");
      return $self->InitializePswitchFromSpec($pswitchSpec);
   }
}


########################################################################
#
# InitializeHostPhysicalComponents --
#      Method to initialize the required physical components in host.
#      (e.g. VMNics, sriov, passthrough, FPT etc.)
#      This method creates  "VDNetLib::Host::HostOperations"  object
#      and stores it in   testbed hash.  Then all the initialization
#      required on the given host is handled in this method.
#
# Input:
#      hostSpec : Host Spec (Required)
#      inventoryIndex: inventory index for this host
#
# Results:
#      "SUCCESS", if the required physical components of hosts are
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeHostPhysicalComponents
{
   my $self           = shift;
   my $hostSpec       = shift;
   my $inventoryIndex = shift;
   my $hostIndexName  = shift;
   my $result   = undef;

   $self->{noOfMachines} = keys %$hostSpec;
   my $hostIP = $hostSpec->{ip};
   if (not defined $hostIP) {
      $vdLogger->Error("No IP address is given for host: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Info("Initializing physical components of $hostIP");

   my $hostObj = VDNetLib::Host::HostFactory::CreateHostObject(
                                 hostip => $hostIP,
                                 hosttype => "esx",
                                 password => $hostSpec->{password},
                                 stafhelper => $self->{stafHelper},
                                 vdnetsrc => $self->{'vdNetSrc'},
                                 vdnetshare => $self->{'vdNetShare'},
                                 vmserver => $self->{vmServer},
                                 vmshare => $self->{vmShare},
                                 sharedstorage => $self->{sharedStorage});
   if($hostObj eq FAILURE) {
      $vdLogger->Error("Failed to create HostOperations object for ".
                       "Host: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # inventory object will always be stored as <inventory>.<index>
   # (e.g. host.[1])
   $result = $self->SetComponentObject("$hostIndexName.[$inventoryIndex]",
                                       $hostObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Initializing VMNICs
   my $vmnicHash = $hostSpec->{vmnic};
   if (defined $vmnicHash) {
      $vdLogger->Info("Initializing vmnics needed on $hostIP");
      # Get all the free Vmnics details for this host
      my $freepnics  = $hostObj->{esxutil}->GetFreePNicsDetails($hostIP);
      if ($freepnics eq FAILURE) {
         $vdLogger->Error("Failed to get the list of free PNics on $hostIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my @fptNicList = ();
      my $sriovHash  = undef;

      foreach my $componentIndex (keys %$vmnicHash) {
         $vdLogger->Info("The args are: $hostObj, $vmnicHash->{$componentIndex}, $freepnics, $componentIndex");
         my $hashh = $vmnicHash->{$componentIndex};
         while(my($k,$v)=each(%$hashh)){$vdLogger->Info("hassss:$k--->$v");}
         foreach my $vmn (@$freepnics) {
            foreach my $v (@$vmn) {
              $vdLogger->Info("Free pnics are : $v");
            }
        }
         my $vmnicObj = $self->InitializeVmnicAdapter($hostObj,
                                                      $vmnicHash->{$componentIndex},
                                                      $freepnics,
                                                      $componentIndex);
         if ($vmnicObj eq FAILURE) {
            $vdLogger->Error("Failed to create vmnic: $componentIndex,".
                             " for Host: $inventoryIndex");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("The arggggg: $hostIndexName, $inventoryIndex, $componentIndex");
         $result = $self->SetComponentObject(
                                             "$hostIndexName.[$inventoryIndex].vmnic.[$componentIndex]",
                                             $vmnicObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to update the testbed hash.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $vdLogger->Info("Successfully created the vmnic: ".
                         "$hostIndexName.$inventoryIndex.vmnic.$componentIndex");

         # Check if passthrough is needed for the given vmnic
         if (defined $vmnicHash->{$componentIndex}{passthrough}) {
	    my $passthroughHash = $vmnicHash->{$componentIndex}{passthrough};
            my $adapterHash = undef;
            my $driver      = $vmnicObj->{'driver'};

            my $passthroughType  = $passthroughHash->{type};

            if ((defined $passthroughType) &&
                $passthroughType eq "sriov") {
               $adapterHash->{'adapter'}{interface} = $vmnicObj->{interface};
               $adapterHash->{'adapter'}{driver} = $vmnicObj->{driver};
               $adapterHash->{'maxvfs'}  = $passthroughHash->{'maxvfs'}||"max";

               push(@{$sriovHash->{$driver}}, $adapterHash);
            } elsif ((defined $passthroughType) &&
                $passthroughType eq "fpt") {
                push(@fptNicList, $vmnicObj->{vmnic});
            } else {
               $vdLogger->Error("The Passthrough type should be either fpt or sriov");
               VDSetLastError(VDGetLastError());
            }
         }
      }

      # Initialize passthrough if needed
      if ((defined $sriovHash) || $#fptNicList >= 0) {
         if ($self->InitializePassthrough($hostObj, $sriovHash,
                                          \@fptNicList) eq FAILURE) {
            $vdLogger->Error("Failed to initialize passthrough on $hostIP");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      if (defined $sriovHash) {
	 #
	 # Storing this readymade hash into hostObj persistently. Later, it will
	 # be used during CleanupHost() to disable the SRIOV on required drivers.
	 #
	 $hostObj->{sriovHash} = $sriovHash;
	 $result = $self->SetComponentObject("$hostIndexName.[$inventoryIndex]",
					     $hostObj);
	 if ($result eq FAILURE) {
	    $vdLogger->Error("Failed to update the testbed hash.");
	    VDSetLastError(VDGetLastError());
	    return FAILURE;
	 }
      }
   }
   delete $hostSpec->{vmnic};
   delete $hostSpec->{installtype};
   delete $hostSpec->{driver};

   $vdLogger->Info("Successfully completed the initialization for physical ".
                   "components of host: $hostIP\n\n");

   $vdLogger->Info("The host inventory index is $inventoryIndex");
  # if ($inventoryIndex eq 2) {
  #    $vdLogger->Info("Returnning hostobj $hostObj");
  #    return $hostObj;
  # }
   return SUCCESS;
}


########################################################################
#
# InitializeHostVirtualComponents --
#      Method to initialize the required virtual components in host.
#      (e.g. VMKNic, VSS, Portgroup etc)
#
# Input:
#      hostSpec : Host Spec (Required)
#
# Results:
#      "SUCCESS", if the required virtual components of hosts are
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeHostVirtualComponents
{
   my $self           = shift;
   my $hostSpec       = shift;
   my $inventoryIndex = shift;
   my $hostIndexName  = shift;
   my $result   = undef;
   my $tuple    = "$hostIndexName.[$inventoryIndex]";

   $vdLogger->Info("Initializing virtual components of host $inventoryIndex");

   $result = $self->GetComponentObject($tuple);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to access host: $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $hostObj = pop(@$result);
   if (not defined $hostObj) {
      $vdLogger->Error("Failed to access host: $tuple");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   delete $hostSpec->{vmnic};
   delete $hostSpec->{driver};
   if (($hostObj->{"buildType"} !~ /^release$/i) and
       (not defined $hostSpec->{configure_service_state})) {
      $vdLogger->Debug("Adding keys to disable memscrubd service");
      $hostSpec->{configure_service_state} = {
           'execution_type' => 'cli',
           'service_name' => 'memscrubd',
           'state' => 'stop',
           'strict' => FALSE,
      };
   }

   my $hostWorkloadObj = $self->GetWorkloadObject("Host");
   $hostWorkloadObj->SetComponentIndex($tuple);

   my $hashSize = keys %$hostSpec;
   if ($hashSize > 0) {
      $result = $hostWorkloadObj->ConfigureComponent('configHash' => $hostSpec,
                                                     'testObject' => $hostObj,
                                                     'tuple' => $tuple);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure Host Virtual components".
			  " with :". Dumper($hostSpec));
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# DeployVM --
#      Method to initialize virtual machines required for test session.
#      All the initialization required on the given host is handled in
#      this method.
#
# Input:
#      vmSpec : VM Spec (Required)
#
# Results:
#      "SUCCESS", if the required VM's are initialized successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub DeployVM
{
   my $self           = shift;
   my $vmSpecRef      = shift;
   my $inventoryIndex = shift;
   my $component      = shift || "vm";
   my $nested_esx_obj = shift;
   my $result         = undef;

   my $vmSpec       = dclone($vmSpecRef);
   my $discoverControlAdapter = FALSE;
   # if defined vnic.[0], need to store the control adapter.
   if ((defined $vmSpec->{vnic}) and (defined $vmSpec->{vnic}->{0})) {
      $vdLogger->Debug("vnic.[0] found in vm spec. Storing control adapter.");
      $discoverControlAdapter = TRUE;
   }
   my $hostIndex    = $vmSpec->{host};
   if (not defined $hostIndex) {
       $vdLogger->Error("host key is mandatory but missing.".
                       " Hence configuration of VM failed for ". Dumper($vmSpec));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $result = $self->GetComponentObject($hostIndex);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to initialize VM.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $hostObj = pop(@$result);
   if (not defined $hostObj) {
      $vdLogger->Error("Failed to access host $hostIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Info("The hostindex is $hostIndex");
   my ($vmObj, $initialState, $vmIP) = $hostObj->CreateVM(\$vmSpec, $inventoryIndex, $component);
   if ($vmObj eq FAILURE) {
      $vdLogger->Error("Failed to create VMOperations object for ".
                       "VM: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $nestedObj;
   if ($inventoryIndex eq '1') {
      $nestedObj = $self->GetComponentObject("host.[2]");
      $vmObj->{'nestedesx'} = pop(@$nestedObj);
      $vdLogger->Info("VM has initialize the nested host obj");
   }
   # runtimeDir is updated in CreateVM->...->GetVMRuntimeDir, so need to set host
   # object
   $result = $self->SetComponentObject($hostIndex, $hostObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update $hostIndex after creating vm.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $vmWorkloadObj = $self->{VMWorkload};
   my $tuple = "$component.[$inventoryIndex]";

   # inventory object will always be stored as x.[x] (e.g. vm.[1])
   $vdLogger->Info("Before SetComponentObject");
   $result = $self->SetComponentObject($tuple, $vmObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Before SetComponentIndex");
   $vdLogger->Debug("Updating the componentIndex = $tuple of VMWorkload");
   $vmWorkloadObj->SetComponentIndex($tuple);
   my $vmState = undef;

   # If vmstate is not given by user. By default we it is "poweron"
   if (not defined $vmSpec->{'vmstate'}) {
      $vmState = "poweron";
   } elsif ($vmSpec->{'vmstate'} =~  /poweron/i) {
      $vmState = $vmSpec->{'vmstate'};
      delete $vmSpec->{'vmstate'};
   }

   if ((not defined $vmIP) && $vmObj->{initialState} ne "off") {
      # Get the current state of the VM and update the flag accordingly
      $result = $vmObj->VMOpsGetPowerState();
   }

   if ($discoverControlAdapter eq TRUE) {
      $result = $self->CleanupVNics($vmObj, $discoverControlAdapter);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to delete the default management adapter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   $vdLogger->Info("Before ConfigureComponent");
   my $vnicspec = $vmSpec->{'vnic'}->{1};
   while(my($k,$v)=each(%$vnicspec)){$vdLogger->Info("vmspecf:$k--->$v");}
   #while(my($k,$v)=each(%$vmObj)){$vdLogger->Info("vmobj:$k--->$v");}
   my $hashSize = keys %$vmSpec;
   if ($hashSize > 0) {
      $result = $vmWorkloadObj->ConfigureComponent(configHash => $vmSpec,
                                                   testObject => $vmObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure VM components".
                          " with :". Dumper($vmSpec));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # Poweron the VM here, if vmstate was set to "poweron"
   if (defined $vmState) {
      my $configHash;
      $configHash->{vmstate} = $vmState;
      $result = $vmWorkloadObj->ConfigureComponent(configHash => $configHash,
                                                   testObject => $vmObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure VM components".
                          " with :". Dumper($configHash));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }


   # inventory object will always be stored as x.[x] (e.g. vm.[1])
      $result = $self->SetComponentObject("$component.[$inventoryIndex]",
                                       $vmObj);
   #while(my($k,$v)=each(%$vmObj)){$vdLogger->Info("vmobj1:$k--->$v");}
   $vdLogger->Info("component obj is $component.[$inventoryIndex]");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# UpdateControlIP --
#     Method to update vm and all vnics' control ip
#
# Input:
#     vmObj         : reference to vm object
#     controlIP     : the new control ip
#
# Results:
#     SUCCESS, if updating correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpdateControlIP
{
   my $self      = shift;
   my $vmObj     = shift;
   my $controlIP = shift;
   my $result    = FAILURE;

   # Updating ip in vmObj
   my $tuple = $vmObj->{objID};
   $vdLogger->Info("IP of $tuple control adapter is: $controlIP");
   $vmObj->{vmIP} = $controlIP;
   $result = $self->SetComponentObject($tuple,
                                       $vmObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to set the component Obj for ".
                       "$tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully update vmIP for $tuple");
   #Updating control ip in vnics object
   $tuple = "$tuple.vnic.[-1]";
   my $tuples = $self->GetAllComponentTuples($tuple);
   if ($tuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach $tuple (@$tuples) {
      my $vnicObject = $self->GetComponentObject($tuple)->[0];
      $vnicObject->{vmOpsObj} = $vmObj;
      $vnicObject->{parentObj} = $vmObj;
      $vnicObject->{controlIP} = $vmObj->{vmIP};
      $result = $self->SetComponentObject($tuple, $vnicObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to set the component Obj for ".
                          "$tuple");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Successfully update controlIP for $tuple");
   }
   return $result;
}


########################################################################
#
# InitializeVM --
#     Method to get VM's ip address and configure it with tools
#     and other setup required for vdnet
#
# Input:
#     vmSpec         : reference to hash containing VM specification
#     inventoryIndex : index to represent the given VM
#
# Results:
#     SUCCESS, if the VM is configure correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializeVM
{
   my $self     = shift;
   my $vmSpec   = shift;
   my $inventoryIndex = shift;
   my $component = shift || "vm";
   my $result   = undef;
   my $vmIndex;

   $vmIndex = "$component.[$inventoryIndex]";
   $vdLogger->Info("Initializing VM $vmIndex");

   $result = $self->GetComponentObject($vmIndex);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $vmObj = $result->[0];

   $vdLogger->Info("Successfully completed the initialization of VM".
                   ": $vmIndex\n\n");

   #
   # Upgrade VM tools for all VMs if necessary;
   # If the vm is in powered off state, then also
   # tools upgrade will not happen.
   #
   if ((!$self->{'noTools'}) && (defined $vmObj->{vmIP})) {
      my $vmWorkloadObj = $self->{VMWorkload};

      # Upgrade VM tools for all VM objects;
      my $toolsBuild->{tools}   = $vmSpec->{tools};
      if ((defined $toolsBuild->{tools}) &&
          ($toolsBuild->{tools} =~ /notools/i) ) {
         next;
      }

      if ((not defined $toolsBuild->{tools}) ||
          ($toolsBuild->{tools} !~ /ob|sb-\d+/i)) {
         $vdLogger->Debug("tools not defined, using default for VMTools" .
                          " upgrade");
         $toolsBuild->{tools} = "default";
      }
      $result = $vmWorkloadObj->ConfigureComponent(configHash => $toolsBuild,
                                                   testObject => $vmObj,
                                                   tuple => $vmIndex);
      if (FAILURE eq $result) {
         $vdLogger->Error("Failed to upgrade vmware-tools on VM:" .
                          " $vmObj->{vmIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# CheckSetup --
#       Checks Host, VM for setup required to run vdNet
#
#       1. Checks if STAF is running on all the hosts in testbed, if not
#          return FAILURE as that is minimum setup requirement from the
#          user
#       2. If neither VM IP nor VMX file is provided then error out
#       3. If vmx file is provided and no IP is given, check if the VM
#          is powered on, if not power it on and wait for it to come up.
#       4. If STAF is not running on VM error out
#       4. Setup the following:
#          if it is windows OS:
#             a) disable firewall
#             b) enable autologon
#             c) disable event tracker
#             d) install winpcap, if it is not installed
#
#  Input:
#	None
#
#  Results:
#       Checks the setup and sets it up if necessary and possible
#
#  Side effects:
#       Required mountpoints gets created on Guest VMs
#
########################################################################

sub CheckSetup
{
   my $self    = shift;
   my $result;

   my $componentArray = $self->GetComponentObject("vm.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get VM objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @arrayOfVMTypes = ("vm","powerclivm","dhcpserver", "torgateway", "linuxrouter");
   my @arrayAllTypesOfVM;
   foreach my $prefix (@arrayOfVMTypes) {
      $componentArray = $self->GetComponentObject("$prefix.[-1]");
      if ($componentArray eq FAILURE) {
         $vdLogger->Error("Failed to get VM objects from Testbed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push (@arrayAllTypesOfVM, @$componentArray);
   }


   foreach my $vmObj (@arrayAllTypesOfVM) {
      my $vmIP = $vmObj->{vmIP};
      if (not defined $vmIP) {
         $vdLogger->Warn("IP address of one of the VMs is not available.".
                         " Please check if the vm was expected to be in".
                         " poweroff state, initially.");
                         next;
      }

      $vdLogger->Debug("Checking if STAF is running on VM $vmIP");
      if ($self->{stafHelper}->CheckSTAF($vmIP) eq FAILURE) {
         $vdLogger->Warn("STAF is not running on VM $vmIP.".
                         " Please check if the vm was expected to be in".
                         " poweroff state, initially.");
                         next;
      }
      $vdLogger->Debug("STAF is running on vm $vmIP.");
      # Check VM setup for vdnet
      my %vdNetMountElements ;
      $vdNetMountElements{vdNetSrc} = $self->{vdNetSrc};
      $vdNetMountElements{vdNetShare} = $self->{vdNetShare};
      $result = $vmObj->CheckVMSetup(\%vdNetMountElements);
      if ($result eq FAILURE) {
         $vdLogger->Error("Some setup in VM $vmIP is not in line with vdNet request.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# GetRandomInstance --
#   Returns an object randomly chosen from all the available objects of given
#   type.
#
#   Inputs:
#       zkNode: Zookeeper node from which all the component instances will be
#       derived.
#
#   Outputs:
#       Index of the randomly selected component enclosed in an array
#       reference. FAILURE in case of errors.
#
########################################################################

sub GetRandomInstance {
    my $self = shift;
    my $zkNode = shift;
    my $childNodes = $self->GetAllComponentInstances($zkNode);
    if ($childNodes eq FAILURE) {
       $vdLogger->Error("Failed to get nodes for $zkNode");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }
    my $randomIndex = VDNetLib::Common::Utilities::RandomNumberInRange(
        0, scalar(@$childNodes) - 1);
    my @randomComponent = ($childNodes->[$randomIndex]);
    return \@randomComponent;
}

########################################################################
#
# GetRRQueueHead --
#   Returns an object chosen from all the available objects of given
#   type such that the given object is supposed to be the next one if we
#   were following round robin component access.
#
#   Inputs:
#       componentType: Type of the component whose next element in RR
#       queue is required. (e.g. nsxmanager)
#       listOfComponentIndices: List of component indices on which the
#           round robin algo needs to be applied. If none is provided,
#           then the method assumes that we will be goind around all
#           the deployed components. (e.g. (1,2,3) or (5,12,10) etc.)
#
#   Outputs:
#       Index of the least recently used instance as an array ref.
#       reference.
#       FAILURE in case of errors.
#
########################################################################

sub GetRRQueueHead
{
    my $self = shift;
    my $componentType = shift;
    my $listOfComponentIndices = shift;
    # Sanitize the arguments.
    if (not defined $componentType || $componentType eq "") {
        $vdLogger->Error("Need component type to retrieve the round-robin " .
                         "list");
        VDSetLastError('ENODEF');
        return FAILURE;
    }
    if (FAILURE eq $self->UpdateZooKeeperHandle()) {
       $vdLogger->Error("Failed to update zookeeper handle");
       return FAILURE;
    }
    if (defined $listOfComponentIndices and
        ref($listOfComponentIndices) ne 'ARRAY') {
        $vdLogger->Error("list of indicies must be provided in array " .
                         "format, got:\n" . Dumper($listOfComponentIndices));
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    $self->{zookeeperObj}{zkHandle} = $self->{zkHandle};
    # If list of component indices is not passed in then we inspect the already
    # created zookeeper children node of the component type passed in and use
    # the defined indices for round robin circular queue.
    if (not defined $listOfComponentIndices) {
        $listOfComponentIndices = [];
        my $zkNode = "$self->{zkSessionNode}/$componentType";
        my $templistOfComponentIndices = $self->GetAllComponentInstances(
           $zkNode);
        my $roundRobinRegex = qr/${\(ROUNDROBIN)}/;
        # Remove any nodes that match 'roundrobin'.
        @$listOfComponentIndices = grep {
            $_ !~ $roundRobinRegex} @$templistOfComponentIndices;
    }
    if (not scalar(@$listOfComponentIndices)) {
        $vdLogger->Error("No $componentType object found in zookeeper");
        return FAILURE;
    }
    my $indicesString = join("-", @$listOfComponentIndices);
    # Acquire the lock so that no other parallel process manipulates the data
    # that we are about to update.
    my $rrWriteLock = VDNetLib::Zookeeper::ZKLock->new(
        'name' => "$componentType$indicesString",
        'zkObj' => $self->{zookeeperObj});
    if ($rrWriteLock eq FAILURE) {
        $vdLogger->Error("Failed to create the lock object for $componentType");
        return FAILURE;
    }
    my $acquireResult = $rrWriteLock->Acquire();
    if ($acquireResult eq FAILURE) {
        $vdLogger->Error("Failed to acquire lock on " .
                         "$componentType$indicesString");
        $rrWriteLock->Release();
        return FAILURE;
    }
    my $rrMaintenanceRet = ();
    # Do a circular shift on the round robin queue and save it in the
    # zookeeper.
    eval {
        $rrMaintenanceRet = $self->UpdateRRListOfComponent(
            $componentType, $indicesString, $listOfComponentIndices);
    };
    if ($@) {
        $vdLogger->Error("Failed to update RR list for " .
                         "$componentType/$indicesString:\n" . Dumper($@));
        $rrWriteLock->Release();
        return FAILURE;
    }
    if ($rrMaintenanceRet eq FAILURE) {
        $vdLogger->Error("Failed to update RR list for " .
                         "$componentType/$indicesString");
        $rrWriteLock->Release();
        return FAILURE;
    }
    $rrWriteLock->Release();
    my @retArr = (@{$rrMaintenanceRet}[0]);
    return \@retArr;
}


########################################################################
#
#  XXX (salmanm): Caller should ensure that he acquires the lock before
#    calling this method.
#
#  UpdateRRListOfComponent --
#       Maintains a round robin list of a given component type such that
#       the elements are shifted by one so that the next time user makes
#       a call, he is able to chose a different component.
#
# Input:
#       $componentType: Type of the component e.g. nsxmanager.
#       $indicesString: '-' separated list of component indicies. (e.g. 5-10-12)
#       $componentIndices: Array ref containing the list of indices of
#           components. (e.g. (1,2,3) or (5,12,10) etc.)
#
# Results:
#       Round-robin component list - in case circular shift was
#           successful.
#       FAILURE - in case circular shift fails.
#
# Side effetcs:
#       If the data structure for keeping track of RR queue for the
#       passed in component type is not there in zookeeper already, then
#       it is populated by this method call.
#
########################################################################

sub UpdateRRListOfComponent
{
    my $self = shift;
    my $componentType = shift;
    my $indicesString = shift;
    my $componentIndices = shift;
    if (not defined $componentType) {
        $vdLogger->Error("Component type not passed in, can not maintain " .
                         "RR list");
        VDSetLastError('ENODEF');
        return FAILURE;
    }
    if (not defined $indicesString) {
        $vdLogger->Error("Indicies string not passed in, can not maintain " .
                         "RR list");
        VDSetLastError('ENODEF');
        return FAILURE;
    }
    if (not defined $componentIndices || ref($componentIndices) ne 'ARRAY') {
        $vdLogger->Error("Either component indices not passed in, or it is " .
                         "not in array format, got:\n" .
                         Dumper($componentIndices));
        VDSetLastError('ENODEF');
        return FAILURE;
    }
    my $rrComponentList = $self->GetOrderedRRComponents(
        $componentType, $indicesString, 'Warn');
    if ($rrComponentList eq FAILURE) {
        # If data retrieval fails from zookeeper.
        my $zkNode = "$self->{zkSessionNode}/$componentType/" . ROUNDROBIN .
                     "$indicesString";
        $vdLogger->Error("Failed to get info of node: $zkNode");
        return FAILURE;
    } elsif ($rrComponentList == VDNetLib::Common::ZooKeeper::ZNONODE) {
        # If the RR strucuture does not exist then create it.
       $vdLogger->Debug("Initializing RR list for component: " .
                        "$componentType/$indicesString ...");
       my $completePath = $self->{zkSessionNode} . "/$componentType/" .
                          ROUNDROBIN . "/$indicesString";
       # XXX(salmanm): Ideally we should have used ephemeral nodes here so
       # that we get the same sequence of round-robin components on the test
       # rerun but seems like the epehemeral nodes are being deleted once a
       # a workload ends and so attempting to use epehemeral node here will
       # result in retrieveing the same component index in every workload.
       my $newNode = $self->AddRecursiveZooKeeperPath(
            $completePath, $self->{zookeeperObj});
       if (FAILURE eq $newNode) {
          $vdLogger->Error("Failed to add ZK node: $completePath");
          return FAILURE;
       }
       my $setRet = $self->SetOrderedRRComponents(
           $componentType, {'list' => $componentIndices}, $indicesString);
       if (FAILURE eq $setRet) {
           $vdLogger->Error("Failed to set value of ZK node: $completePath");
           return FAILURE;
       }
       $rrComponentList = $componentIndices;
    } else {
      # If the structure exists then shift it.
      $rrComponentList = $rrComponentList->{'list'};
      $vdLogger->Debug("Existing RR list for component $componentType " .
                       "is:\n" . Dumper($rrComponentList));
      # Do a circular shift such that the first element is moved to last
      # and the second element is moved to the front of the queue.
      my $firstElem = shift(@$rrComponentList);
      push(@$rrComponentList, $firstElem);
      my $ret = $self->SetOrderedRRComponents(
          $componentType, {'list' => $rrComponentList}, $indicesString);
      if ($ret ne SUCCESS) {
         $vdLogger->Error("Failed to update the RR list of $componentType");
         return FAILURE;
      }
    }
    return $rrComponentList;
}

########################################################################
#
# GetOrderedRRComponents--
#       This method would fetch the component objects in order such that
#       the list of components returned will be such that the first
#       element will be the one that has not been used for the longest
#       and the last element is the one that has been used most
#       recently.
#
# Input:
#       $componentType - Component type (e.g. nsxmanager)
#       $nodePath - Path under component type. (e.g. 5-10-12)
#       $logLevel - Specifies the log level at which the errors should
#           be logged at. (e.g. 'Error')
#
# Results:
#       ARRAY ref in case of success. (e.g. (2) or (3) etc.)
#       FAILURE otherwise.
#
# Side effects:
#       None.
#
########################################################################

sub GetOrderedRRComponents
{
   my $self = shift;
   my $componentType = shift;
   my $nodePath = shift;
   my $logLevel = shift || 'Error';
   if (not defined $componentType) {
       $vdLogger->Error("Component type not provided !");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   if (not defined $nodePath) {
       $vdLogger->Error("Node path not provided !");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $completeZkPath = "$self->{zkSessionNode}/$componentType/" . ROUNDROBIN .
                        "/$nodePath";
   return $self->GetDataFromZooKeeperPath($completeZkPath, $logLevel);
}


########################################################################
#
# SetOrderedRRComponents--
#       This method save the component objects list to the zookeeper
#       path from where RR ordered list of objects can be retrieved.
#
# Input:
#       $componentType - Component type (e.g. nsxmanager)
#       $value - Value to be stored as RR data structure. (e.g. (2,5))
#       $rrPath - Node name relative to
#           /testbed/<componentType>/roundrobin/
#
# Results:
#       Refer to the return type of SetComponentDataInZooKeeper
#       method.
#
# Side effects:
#       None.
#
########################################################################

sub SetOrderedRRComponents
{
   my $self = shift;
   my $componentType = shift;
   my $value = shift;
   my $rrPath = shift;
   if (not defined $componentType) {
        $vdLogger->Error("Component type is not defined");
        VDSetLastError("ENODEF");
        return FAILURE;
   }
   if (not defined $value) {
        $vdLogger->Error("Value is not defined");
        VDSetLastError("ENODEF");
        return FAILURE;
   }
   if (not defined $rrPath) {
        $vdLogger->Error("Round robin node path is not defined");
        VDSetLastError("ENODEF");
        return FAILURE;
   }
   my $completePath = $self->{zkSessionNode} . "/$componentType/" .
                      ROUNDROBIN . "/$rrPath";
   return $self->SetDataInZooKeeperPath($completePath, $value);
}


########################################################################
#
# ResolveTuple --
#     Method to resolve the tuple and covert to an intermediate format
#     that ProcessTuple() can understand. This specifically handles
#     '[-1]' representation in tuple which indicates all components.
#     It will be converted [<min>-<max>] based on actual number of
#     components stored on testbed.
#     Note: This method does not take index values as range like
#     host.[1-5]. To handle range, call ProcessTuple() before
#     calling this method.
#
# Input:
#     tuple: tuple in the format
#     <inventory>.[<inventoryIndex>].<component>.[<componentIndex]
#        Example- host.[-1].vmknic.[-1] or vc.[1].vds.[-1].lag.[-1];
#     prefix: a portion of the tuple which is already resolved
#             (Optional)
#
# Results:
#     If successful, reference to an array of tuple (resolved)
#     in the same format mentioned above;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ResolveTuple
{
   my $self	  = shift;
   my $tuple  = shift;
   my $prefix = shift;
   $tuple =~ s/\.x\.\[x\]$//g; # remove trailing x.[x]
   my @temp = split(/\./, $tuple);

   # Ensure that the given tuple/index is in right format
   if (scalar(@temp) % 2) {
      $vdLogger->Error("Invalid format for vdnet index $tuple, " .
                       "should be of format <inventory>.[x].<component>.[x]");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # If prefix is not defined, then use the inventory name
   # as prefix
   #
   if (not defined $prefix) {
      $prefix = $temp[0];
   }

   my $newArrayOfTuples = [];
   my $regex = quotemeta($prefix . '.');
   #
   # Split the prefix and remaining part of tuple
   #
   my ($dummy, $tail) = split($regex, $tuple);
   @temp = split(/\./, $tail);
   my $tempNode = $self->{zkSessionNode} . '/' .
                  $prefix; #prefix root node
   $tempNode =~ s/\./\//g; # replace . with /
   $tempNode =~ s/\[|\]//g; # remove [ and ]

   my $childNodes;
   #
   # If index is -1, then find all component instances, otherwise
   # the index is assumed to be resolved already
   #
   my $roundRobinRegex = qr/${\(ROUNDROBIN)}=/;  # Matches with "roundrobin="
   my $roundRobinRegexStrict = qr/${\(ROUNDROBIN)}/i;
   if ($temp[0] eq '[-1]' or $temp[0] eq 'all') {
      #
      # Get all the child nodes for the prefixed component
      #
      $childNodes = $self->GetAllComponentInstances($tempNode);
      if ($childNodes eq "FAILURE") {
         $vdLogger->Error("Failed to get nodes for $tempNode");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      @$childNodes = grep {$_ !~ $roundRobinRegexStrict} @$childNodes;
   } elsif ($temp[0] =~ /random/i) {
      $childNodes = $self->GetRandomInstance($tempNode);
      if ($childNodes eq FAILURE) {
          return FAILURE;
      }
      $vdLogger->Info("Chose $prefix\." . $childNodes->[0] . " randomly ...");
   } elsif ($temp[0] =~ $roundRobinRegexStrict) {
     if ($temp[0] eq ROUNDROBIN or $temp[0] eq "[" . ROUNDROBIN . "]") {
        # Roundrobin on all deployed nodes.
        $childNodes = $self->GetRRQueueHead($prefix);
     } elsif ($temp[0] =~ $roundRobinRegex) {
        my $index = $temp[0];
        my @indices = split($roundRobinRegex, $index);
        my $expandedIndices = VDNetLib::Common::Utilities::ExpandIndices($indices[1]);
        $childNodes = $self->GetRRQueueHead($prefix, $expandedIndices);
     } else {
        $vdLogger->Error("Invalid " . ROUNDROBIN . " index spec: $temp[0]");
        return FAILURE;
     }
     if ($childNodes eq FAILURE) {
         $vdLogger->Error("Failed to get " . ROUNDROBIN . " node index for: $prefix");
         VDSetLastError("EOPFAIL");
         return FAILURE;
     }
     $vdLogger->Info("Chose $prefix\." . $childNodes->[0] . " in a round-" .
                     "robin fashion ...");
   } else {
      my $componentIndex = $temp[0];
      $componentIndex =~ s/\[|\]//g; # remove [ or ]
      push(@$childNodes, $componentIndex);
   }

   my @list = grep(/\d+/,@$childNodes );
   if (!@list) {
      $vdLogger->Debug("No child nodes for $tempNode found " .
                       "after filtering");
   }
   for (my $i = 0; $i < scalar(@list) ; $i++) {
      my $newPrefix = $prefix . '.' . '[' . $list[$i] . ']';
      my $newArray = [];
      #
      # Now that a portion of the tuple is resolved, compose
      # the new tuple with the resolved portion + remaining
      # unresolved portion and call this method recursively
      # until all unresolved portions are processed.
      #
      if (defined $temp[1]) {
         $newPrefix = $newPrefix . '.' . $temp[1];
         my $newTuple = $newPrefix . '.' . join('.', @temp[2..$#temp]);
         $newArray = $self->ResolveTuple($newTuple, $newPrefix);
         if ($newArray eq FAILURE or not scalar($newArray)) {
            $vdLogger->Error("Failed to resolve tuple recursively");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         push(@$newArray, $newPrefix);
      }
      if (@$newArray) {
         push(@$newArrayOfTuples, @$newArray);
      }
   }
   return $newArrayOfTuples;
}


########################################################################
#
# GetAllComponentTuples --
#     Method to get expanded list of tuples based on what
#     is configured on testbed
#
# Input:
#     componentDetails: tuple in format
#                      <inventory>.[<index>].component.[<index>]
#
# Results:
#     Reference to an array which contains tuples
#
# Side effects:
#     None
#
########################################################################

sub GetAllComponentTuples
{
   my $self = shift;
   my $componentDetails = shift;
   my $tuplesArray =  VDNetLib::Common::Utilities::ProcessTuple($componentDetails);
   my $tuplesArray1;
   my @finalTuplesList;

   #
   # Resolve -1 in all the tuples
   #
   foreach my $tuple (@$tuplesArray) {
      my $resolvedTupleArray = $self->ResolveTuple($tuple);
      if ($resolvedTupleArray eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      @finalTuplesList = (@finalTuplesList, @$resolvedTupleArray);
   }
   return \@finalTuplesList;
}


########################################################################
#
# GetComponentObject --
#       This method would fetch the required component object from the
#       given inventory and return it to the caller.
#
# Input:
#       $componentDetails - A 4 tuple string of type: vc.[1].vds.[2]
#	Format: <inventory>.[<index/range>].<component>.[<index/range>]
#
# Results:
#       returns reference to the required component object (or Array of
#       objects), in case of success
#       returns FAILURE, if failed.
#
# Side effects:
#       None.
#
########################################################################

sub GetComponentObject
{
   my $self = shift;
   my $componentDetails = shift;
   my $ret = $self->GetComponentDataFromZooKeeper($componentDetails, 'obj');
   if ($ret eq FAILURE) {
       return FAILURE;
   }
   if ($ret == VDNetLib::Common::ZooKeeper::ZNONODE) {
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   return $ret;
}

########################################################################
#
# GetDataFromZooKeeperPath --
#       This method would fetch the required component object from the
#       given zookeeper path.
#
# Input:
#       $node: ZooKeeper node/path from which the data needs to be
#           retrieved from.
#       $logLevel: Determines the log level at which the error conditions
#           should be recorded. Defaults to 'Error' by default.
#
# Results:
#       returns reference to the required component object (or Array of
#       objects), in case of success
#       returns FAILURE, if failed.
#       returns VDNetLib::Common::ZooKeeper::ZNONODE if the desired node
#       does not exist in the zookeeper.
#
# Side effects:
#       None.
#
########################################################################

sub GetDataFromZooKeeperPath
{
   my $self = shift;
   my $node = shift;
   my $logLevel = shift || 'Error';
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->$logLevel("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $zkObj = $self->{zookeeperObj};
   if (FAILURE eq $zkObj->CheckIfNodeExists($node, $self->{zkHandle})) {
        $vdLogger->$logLevel("ZooKeeper node $node does not exist");
        if ($logLevel eq 'Error') {
            VDSetLastError("EINVALID");
        }
        return VDNetLib::Common::ZooKeeper::ZNONODE;
   }
   my $value = $zkObj->GetNodeValue($node, $self->{zkHandle});
   if ($value eq FAILURE) {
      $vdLogger->$logLevel("Failed to get zookeeper node for $node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   chomp($value);
   my $temp;
   if ($value =~ /__builtin__/) {
      # Its a python object.
      eval {
         $temp = py_call_function("pickle", "loads", $value);
      };
      if ($@) {
         $vdLogger->Error("Error while pickling:\n" . Dumper($@));
         $vdLogger->Error("Failed to pickle\n:" . Dumper($value));
         VDSetLastError("ERUNTIME");
         return FAILURE;
      }
      print $temp->{balance} if defined $temp->{balance1};
   } else {
      # Its a perl object
      $temp  = eval($value);
      if ($@) {
         $vdLogger->Error("Value of zookeeper :\n" . Dumper($value));
         $vdLogger->$logLevel("Failed to eval value of $node: $@");
         $vdLogger->Trace("Corrupted Value: $value");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   if (defined $temp and $temp =~ /VDNetLib.*=HASH/) { # process only vdnet core objects

      my ($className, $varType) = split(/=/,$temp);
      eval "require $className";
      if ($@) {
         $vdLogger->$logLevel("Failed to load $className: $@");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      foreach my $item (keys %$temp) {
         if ((defined $temp->{$item}) && ($temp->{$item} =~ /VDNetLib.*=HASH/)) {
            if (defined $temp->{$item}{objID}) {
               my $objArray = $self->GetComponentObject($temp->{$item}{objID});
               if ($objArray eq FAILURE) {
                  $vdLogger->$logLevel("Failed to get object of " .
                                       $temp->{$item}{objID});
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               #
               # replace the content of original object with
               # the content retrieved from zookeeper
               #
               $temp->{$item} = $objArray->[0];
            }
            if (defined $temp->{$item}{stafHelper}) {
                 #
               # sometime the core object contains attribute which is another
               # core object but that does not have objID example: switch
               # obj contains an attribute 'switchObj'.
               # this block handles such scenarios as well
                 #
               delete $temp->{$item}{stafHelper};
               $temp->{$item}{stafHelper} = $self->{stafHelper};
            }
         }
      }
   }
   #
   # ensure the updated stafhelper object is used.
   # This is important while running tests in 'workloadsOnly' mode
   #
   $temp->{stafHelper} = $self->{stafHelper};
   return $temp;

}

########################################################################
#
# CheckIfComponentExists --
#       This method would check if the component exists in zookeeper.
#
# Input:
#       $node: ZooKeeper node/path from which the data needs to be
#           retrieved from.
#       $logLevel: Determines the log level at which the error conditions
#           should be recorded. Defaults to 'Error' by default.
#
# Results:
#       returns reference to the required component object (or Array of
#       objects), in case of success
#       returns FAILURE, if failed.
#       returns VDNetLib::Common::ZooKeeper::ZNONODE if the desired node
#       does not exist in the zookeeper.
#
# Side effects:
#       None.
#
########################################################################

sub CheckIfComponentExists
{
   my $self = shift;
   my $tuple = shift;
   my $logLevel = shift || 'Error';
   my $node = $self->GetNodeFromTuple($tuple);

   my $zkObj = $self->{zookeeperObj};
   my $root = $self->{zkSessionNode};
   my $element = $root . '/' . $node;
   $vdLogger->Debug("Zookeeper path for tuple is: $node");

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->$logLevel("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (FAILURE eq $zkObj->CheckIfNodeExists($element, $self->{zkHandle})) {
      $vdLogger->$logLevel("ZooKeeper node $node does not exist");
      if ($logLevel eq 'Error') {
          VDSetLastError("EINVALID");
      }
      return FAILURE;
   }
   return SUCCESS;

}

########################################################################
#
# GetComponentDataFromZooKeeper--
#       This method would fetch the required component object from the
#       given inventory and return it to the caller.
#
# Input:
#       $componentDetails - A 4 tuple string of type:
#       <inventory>.[<index/range>].<component>.[<index/range>]
#       $path: Path relative to the component that contains the data.
#       $logLevel: Determines the log level at which the error conditions
#           should be recorded. Defaults to 'Error' by default.
#
# Results:
#       returns reference to the required component object (or Array of
#       objects), in case of success
#       returns FAILURE, if failed.
#       returns -1 if the desired node does not exist in the zookeeper.
#
# Side effects:
#       None.
#
########################################################################

sub GetComponentDataFromZooKeeper
{

   my $self = shift;
   my $componentDetails = shift;
   my $path  = shift;
   my $logLevel = shift || 'Error';
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->$logLevel("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @finalTuplesList;
   my @objectsArray;
   if ($componentDetails !~ /\./) {
      $vdLogger->$logLevel("Unknown format given for component " .
                           Dumper($componentDetails));
      VDSetLastError("EINVALID");
      return FAILURE;

   }
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->$logLevel("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $refArray = $self->GetAllComponentTuples($componentDetails);
   if ($refArray eq FAILURE) {
      $vdLogger->$logLevel("Failed to get all indexes for $componentDetails");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   @finalTuplesList = @{$refArray};
   #
   # All component objects are stored in $self->{testbed} with unique
   # tuple id as key. Any addition/changes to a component is 'written'
   # first to zookeeper using SetComponentObject(). In order to identify
   # the component, we inject {objID} as attribute to all objects.
   # While retrieving the ojects from the serialized
   # version of the object using eval(), a new memory address is given.
   # But, that address is not used, rather the address/reference to
   # original object (stored in $self->{testbed} is retrieved using
   # GetComponentObject().
   # In order to avoid of duplicate of objects and inconsistency
   # among these object, only one object per component is stored
   # in the entire vdnet session.
   #
   foreach my $tuple (@finalTuplesList) {
      $tuple = $self->GetNodeFromTuple($tuple);
      $tuple = $self->{zkSessionNode} . '/' . $tuple;

      my $node = $tuple . '/' . $path;
      my $temp = $self->GetDataFromZooKeeperPath($node, $logLevel);
      if ($temp eq FAILURE) {
         $vdLogger->$logLevel("Failed to get zookeeper data for $tuple");
         return FAILURE;
      } elsif ( $temp == VDNetLib::Common::ZooKeeper::ZNONODE) {
         $vdLogger->$logLevel("zookeeper node for $tuple does not exist");
         return VDNetLib::Common::ZooKeeper::ZNONODE;
      }
      push(@objectsArray, $temp);
   }
   return \@objectsArray;
}


########################################################################
#
# GetAllComponentInstances --
#     Method to get all child nodes (all instances of a given
#     component)
#
# Input:
#     node: zookeeper node in absolue path format.
#           example: /testbed/host/1/vmknic
#
# Results:
#     reference to array which contains component indexes, if success;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetAllComponentInstances
{
   my $self = shift;
   my $node = shift;
   my $zkObj = $self->{zookeeperObj};
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   }
   my $refToArrayOfNodes = $zkObj->GetChildren($node, $self->{zkHandle});
   if ($refToArrayOfNodes eq FAILURE) {
      $vdLogger->Error("Failed to get child nodes");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $refToArrayOfNodes;
}


########################################################################
#
# BackupInventoryToFile --
#     Method to backup zookeeper inventory of a particular tuple to a
#     file
#
# Input:
#     tupleToBackup     : zookeeper tuple.
#                         example: neutron.[1]
#     backupFile        : backup file to store zookeeper inventory
#
# Results:
#     SUCCESS:  If backup was successful
#     FAILURE:  It backup failed
#
# Side effects:
#     None
#
########################################################################

sub BackupInventoryToFile
{
   my $self = shift;
   my $tupleToBackup = shift;
   my $backupFile = shift;

   my $node = $self->GetNodeFromTuple($tupleToBackup);

   # Getting zookeeper child nodes for given tuple
   my $zkObj = $self->{zookeeperObj};
   my $root = $self->{zkSessionNode};
   my $element = $root . '/' . $node;

   return $zkObj->BackupInventoryToFile($element, $backupFile);
}


########################################################################
#
# GetNodeFromTuple --
#     Method to convert a tuple to node format
#
# Input:
#     tuple             : zookeeper tuple.
#                         example: neutron.[1]
#
# Results:
#     the node equivalent of the input tuple
#     example: /testbed/testsession/neutron/1
#
# Side effects:
#     None
#
########################################################################

sub GetNodeFromTuple
{
   my $self = shift;
   my $tuple = shift;

   my $node = $tuple;
   $node =~ s/\.x.*//g;
   $node =~ s/\[|\]//g;
   $node =~ s/\./\//g;

   return $node;
}


########################################################################
#
# RestoreInventoryFromFile --
#     Method to restore zookeeper inventory of a particular tuple from a
#     file
#
# Input:
#     tupleToRestore    : zookeeper tuple.
#                         example: neutron.[1]
#     restoreFile       : restore file that contains zookeeper inventory
#
# Results:
#     SUCCESS:  If restore was successful
#     FAILURE:  It restore failed
#
# Side effects:
#     None
#
########################################################################

sub RestoreInventoryFromFile
{
   my $self = shift;
   my $tupleToRestore = shift;
   my $restoreFile = shift;

   my $node = $self->GetNodeFromTuple($tupleToRestore);

   # Getting zookeeper child nodes for given tuple
   my $zkObj = $self->{zookeeperObj};
   my $root = $self->{zkSessionNode};
   my $element = $root . '/' . $node;

   return $zkObj->RestoreInventoryFromFile($element, $restoreFile);
}


########################################################################
#
# AddNewNodeToPeers --
#     Method to add an object to all the peers of a node
#
# Input:
#     tuple         : vdnet tuple of inventory item on whose peers we need to
#                     add the new Node
#                     example: neutron.[1]
#     newObject     : object to be added to all the peers
#     tupleToAvoid  : tuple that corresponds to the new node.
#                     This is passed so that we dont add the
#                     new node to itself
#     keyName       : key name of tuples to be added
#     key           : index of peer tuple to be added to the existing peers
#                     in the cluster
#
# Results:
#     SUCCESS, if success;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddNewNodeToPeers
{
   my $self = shift;
   my $tuple = shift;
   my $newObject = shift;
   my $tupleToAvoid = shift;
   my $keyName = shift;
   my $key = shift;
   my $peerId = $newObject->{'id'};

   my $tuples = $tuple;
   $tuples =~ s/(\d+)/-1/g;

   # $objects is the list all neutron nodes in the inventory
   my $allNodeTuples = $self->GetAllComponentTuples($tuples);
   if ($allNodeTuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $tuples");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $peertuples = $tuple . '.' . $keyName . '.[-1]';
   my $allPeerTuples = $self->GetAllComponentTuples($peertuples);
   if ($allPeerTuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $peertuples");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $peerTuple (@$allPeerTuples) {
      my $result = $self->GetComponentObject($peerTuple);
      my $peerobject = $result->[0];
      foreach my $nodeTuple (@$allNodeTuples) {
         my $result =  $self->GetComponentObject($nodeTuple);
         my $object =  $result->[0];
         #
         # Check if node belongs to the cluster
         # If yes add new peer node to it
         #
         if ($object->{'id'} eq $peerobject->{'id'}) {
            $vdLogger->Debug("Node $nodeTuple is part of cluster, process to append peer $key");
            my $targetTuple = $nodeTuple;
            if ($object->{'id'} ne $peerId) {
               my $result = $self->AddPeer($targetTuple, $newObject, $keyName, $key);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Failed to update the testbed hash.");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            }
         }
      }
   }

   return SUCCESS;
}


########################################################################
#
# AddPeersToNewNode --
#     Method to add an peer objects of all existing nodes to a new node in the
#     cluster
#
# Input:
#     node          : vdnet tuple corresponding to the inventory item.
#                     example: neutron.[1]
#     newObject     : Object to be added to all the peers.
#     peerNode      : tuple that corresponds to the new node.
#                     This is passed so that we dont add the
#                     new node to itself as a peer
#     keyName       : key name of tuples to be added
#
# Results:
#     SUCCESS, if success;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddPeersToNewNode
{
   my $self      = shift;
   my $node      = shift;
   my $newObject = shift;
   my $peerNode  = shift;
   my $keyName   = shift;

   my $peerId  = $newObject->{'id'};
   my $tuple = $node;
   my $peertuplelist = $tuple.'.'.$keyName.'.[-1]';
   my $peertuples = $self->GetAllComponentTuples($peertuplelist);
   if ($peertuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $peertuplelist");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $newNodePeerTuples = $peerNode . '.' . $keyName . '.[-1]';
   my $newNodePeerObjects =  $self->GetComponentObject($newNodePeerTuples);

   foreach my $peertuple (@$peertuples) {
      my $result = $self->GetComponentObject($peertuple);
      my $peerobject = @$result[0];
      foreach my $newNodePeerObject (@$newNodePeerObjects) {
         my $alreadyHasPeer = 0;
         #
         # Check if peer of node already exists in
         # the new node
         # If yes, then skip adding that
         #
         if ($peerobject->{'id'} eq $newNodePeerObject->{'id'}) {
            $alreadyHasPeer = 1;
         }
         if (($alreadyHasPeer == 0) && ($peerId ne $peerobject->{'id'})) {

            my $index = $peertuple;
            $index =~ s/.*\[//g;
            $index =~ s/\]//g;

            $vdLogger->Debug("Peer node for $peerNode not found, process to append peer $index");
            my $result = $self->AddPeer($peerNode, $peerobject, $keyName, $index);
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to update the testbed hash.");
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
# AddPeer --
#     Method to add an object as a peer to another node
#     cluster
#
# Input:
#     node          : vdnet tuple corresponding to an inventory type object
#                     example: neutron.[1]
#     peerObj       : new object to be added to node
#     keyName       : key name of tuples to be added
#     key           : index of the new tuple that is to be created
#
# Results:
#     SUCCESS, if success;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddPeer
{
   my $self = shift;
   my $node = shift;
   my $peerObj = shift;
   my $keyName = shift;
   my $key = shift;

   my $newPeerNode = $node . '.' . $keyName . '.[' . $key . ']';
   my $result = $self->GetComponentObject($node);
   $peerObj->{parentObj} = @$result[0];
   $vdLogger->Debug("Modified parent of peer to point to " . $node);

   $vdLogger->Debug("Adding peer $newPeerNode on $node");
   $result = $self->SetComponentObject($newPeerNode, $peerObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetNodeTuplesFromPeers --
#     Method to get node tuples from peer tuples
#
# Input:
#     peerTuple     : vdnet tuple for peer type node
#                     example: neutron.[1].neutronpeer.[1]
#     node          : vdnet tuple for inventory type node
#                     example: neutron.[1]
#     newTuple      : vdnet tuple for component object
#                     example: neutron.[1].logicalswitch.[1]
#
# Results:
#     reference to array which contains component tuples, if success;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetNodeTuplesFromPeers
{
   my $self = shift;
   my $peerTuple = shift;
   my $node = shift;
   my $newTuple = shift;

   my $peerObjects = $self->GetComponentObject($peerTuple);
   my $nodeTuples = $self->GetAllComponentTuples($node);
   if ($nodeTuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @tupleArray = ();

   foreach my $peerObject (@$peerObjects) {
      foreach my $nodeTuple (@$nodeTuples) {
         my $result = $self->GetComponentObject($nodeTuple);
         my $nodeObject = @$result[0];
         # Appending all inventory type tuples whose id matches that of
         # peer type tuples
         if ($nodeObject->{'id'} eq $peerObject->{'id'}) {
            # Appending subcomponent tuple to the newly obtained inventory
            # type tuple
            my $temp = $newTuple;

            # This particular regex removes everything till the first .
            $temp =~ s/^[^.]*.//;
            # This particular regex removes everthing till the next . and
            # replaces it with a .
            # This along with the previous regex removes the inventory tuple
            # e.g. neutron.[1] with a . from neutron.[1].logicalswitch.[1], so
            # we are left with .logicalswitch[1] in $temp and it can be
            # to neutron.[2] to get neutron.[2].logicalswitch.[1]
            $temp =~ s/^[^.]*././;
            my $targetTuple = $nodeTuple . $temp;
            push(@tupleArray, $targetTuple);
         }
      }
   }
   return \@tupleArray;
}


########################################################################
#
# RemovePeerComponents --
#     Method to remove all subcomponents from a peer node
#
# Input:
#     tuple     : vdnet tuple for inventory type node
#                     example: neutron.[1]
#     peerTuple : vdnet tuple for peer type node
#                     example: neutron.[1].neutronpeer.[1]
#
# Results:
#     SUCCESS, if success;
#
# Side effects:
#     None
#
########################################################################

sub RemovePeerComponents
{
   my $self = shift;
   my $tuple = shift;
   my $peerTuple = shift;

   $tuple =~ s/(\d+)/-1/;
   # Getting the inventory type tuple for the peer tuple
   my $results = $self->GetNodeTuplesFromPeers($peerTuple, $tuple, "");
   if ($results eq FAILURE) {
      $vdLogger->Error("Failed to get object for peer tuple: $peerTuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $targetTuple = @$results[0];

   $vdLogger->Debug("Removing components for $peerTuple");

   my $result = $self->GetComponentObject($peerTuple);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get object for peer tuple: $peerTuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (@$result[0]->can('GetIsGlobal')) {
      my $isGlobal = @$result[0]->GetIsGlobal();
      if ($isGlobal ne VDNetLib::Common::GlobalConfig::TRUE) {
         $vdLogger->Debug("skipping removal of object as it is not a global " .
           "object (GetIsGlobal() returned False) for peer tuple: $peerTuple");
         return SUCCESS;
      }
   } else {
      $vdLogger->Debug("skipping removal of object as it is not a global " .
               "object (GetIsGlobal() missing) for peer tuple: $peerTuple");
      return SUCCESS;
   }

   my $peerName = undef;

   if (@$result[0]->can('GetKeepChildren')) {
      my $isGlobal = @$result[0]->GetKeepChildren();
      if ($isGlobal eq VDNetLib::Common::GlobalConfig::TRUE) {
         $vdLogger->Debug("skipping removal of children of $peerTuple");
         $result = $self->GetComponentObject($targetTuple);
         $peerName = @$result[0]->GetPeerName();
         $vdLogger->Debug("Removing only $peerName");
      }
   } else {
      $vdLogger->Debug("Removing children of $peerTuple");
   }

   $vdLogger->Debug("Removing global children of " . $targetTuple);
   # Removing all subcomponents from the peer tuple
   my $arrayToDelete = $self->GetChildren($targetTuple, $peerName);
   foreach my $obj (@$arrayToDelete) {
      if ($obj->can('GetKeepChildren')) {
          $vdLogger->Debug("child is a peer type object");
      }
      $vdLogger->Debug("Removing replicated component object $targetTuple from peer node");
      $vdLogger->Debug("Removing replicated component object $obj from peer node");
      my $result = $self->SetComponentObject($obj, "delete");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   }

   return SUCCESS;
}


########################################################################
#
# GetChildren --
#     Method to get child tuples from a tuple
#
# Input:
#     tuple     : vdnet tuple
#                     example: neutron.[1]
#     filterNode: if this is set then only children that match it are returned
#                     example: nsxslave
#
# Results:
#     Array of Tuples, if success;
#     Failure, if failure;
#
# Side effects:
#     None
#
########################################################################

sub GetChildren
{
   my $self = shift;
   my $tuple = shift;
   my $filterNode = shift;

   my $node = $self->GetNodeFromTuple($tuple);

   # Getting zookeeper child nodes for given tuple
   my $zkObj = $self->{zookeeperObj};
   my $root = $self->{zkSessionNode};
   my $element = $root . '/' . $node;

   my $refToArrayOfNodes = $zkObj->GetChildren($element, $self->{zkHandle});
   if ($refToArrayOfNodes eq FAILURE) {
      $vdLogger->Error("Failed to get child nodes");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @arrayOfTuples = ();

   # Converting zookeeper nodes to tuples
   if (!(@$refToArrayOfNodes)) {
      return SUCCESS;
   }
   foreach my $obj (@$refToArrayOfNodes) {
      if ((defined $obj) && ($obj ne 'obj')) {
         my $tuple = $node . '/' . $obj;

         $tuple =~ s/(\d+)/\.\[$1\]\./g;
         $tuple =~ s/\///g;
         $tuple = $tuple . '.[-1]';
         if ($filterNode eq undef || $filterNode eq $obj) {
            push (@arrayOfTuples, $tuple);
         }
      }
   }
   return \@arrayOfTuples;
}


########################################################################
#
# RemovePeer --
#     Method to remove all peer type nodes corresponding to a particular
#     inventory type node from a cluster
#
# Input:
#     tuple     : vdnet tuple for inventory type node
#                     example: neutron.[1]
#     peerTuple : vdnet tuple for peer type node
#                     example: neutron.[1].neutronpeer.[1]
#     keyName   : keyName of peer type object
#                     example neutronpeer
#
# Results:
#     SUCCESS, if success;
#
# Side effects:
#     None
#
########################################################################

sub RemovePeer
{
   my $self = shift;
   my $tuple = shift;
   my $peerTuple = shift;
   my $keyName = shift;

   my $tuplePeers = $tuple . '.' . $keyName . '.[-1]';
   my $tuplePeerTuples = $self->GetAllComponentTuples($tuplePeers);
   if ($tuplePeerTuples eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $tuplePeers");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $result = $self->GetComponentObject($peerTuple);
   my $peerTupleObject = @$result[0];

   foreach my $tuplePeer (@$tuplePeerTuples) {
      my $result = $self->GetComponentObject($tuplePeer);
      my $tuplePeerObject = @$result[0];
      # Removing the peer tuples for the node that is being removed from the
      # cluster
      if ($tuplePeerObject->{'id'} eq $peerTupleObject->{'id'}) {
         $vdLogger->Debug("Removing peer tuple $tuplePeer for node that is being removed from cluster");
         my $result = $self->SetComponentObject($tuplePeer, "delete");
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to update the testbed hash.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


###############################################################################
#
# RecursiveReplicateComponents -
#       Replicates zookeeper hierarchy from source to destination
#
# Input:
#       $node     - vdnet tuple corresponding to the source from where we want
#                   subcomponents replicated.
#                   example: neutron.[1]
#       $target   - vdnet tuple corresponding to the destination where we want
#                   subcomponents replicated to.
#                   example: neutron.[2]
#       $keyName -  name of peer type tuple
#                   example: neutronpeer
#
# Results:
#       SUCCESS, if everything goes fine.
#	FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub RecursiveReplicateComponents
{
   my $self = shift;
   my $node = shift;
   my $target = shift;
   my $keyName = shift;
   my @skipList;

   if (defined $keyName) {
      push @skipList, $keyName;
      push @skipList, "obj";
      #process tuple
      $node = $self->GetNodeFromTuple($node);
   }

   my $zkObj = $self->{zookeeperObj};
   my $root = $self->{zkSessionNode};
   my $element = $root . '/' . $node;
   my $refToArrayOfNodes = $zkObj->GetChildren($element, $self->{zkHandle});
   if ($refToArrayOfNodes eq FAILURE) {
      $vdLogger->Error("Failed to get child nodes");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Removing items we don't want replicated
   my $index = 0;

   if (!(@$refToArrayOfNodes )) {
      return SUCCESS;
   }

   foreach my $obj (@$refToArrayOfNodes) {
      foreach my $skipItem (@skipList) {
        if ($skipItem eq $obj) {
            delete @$refToArrayOfNodes[$index];
        }
      }
      $index++;
   }

   # Replicate the shallowest obj item found in node to target
   $index = 0;

   if (!(@$refToArrayOfNodes )) {
      return SUCCESS;
   }

   foreach my $obj (@$refToArrayOfNodes) {
      if ((defined $obj) && ($obj eq 'obj')) {
         my $oldObj = $node . '/' . $obj;

         my $value = $zkObj->GetNodeValue($root . '/' . $oldObj, $self->{zkHandle});

         chomp($value);
         my $temp  = eval($value);
         if ($temp->can('GetIsGlobal')) {
            my $isGlobal = $temp->GetIsGlobal();
            $vdLogger->Debug("Checking to see if node $temp should be replicated");
            if ($isGlobal ne VDNetLib::Common::GlobalConfig::TRUE) {
                $vdLogger->Debug("Skipping the replication of non global object" .
                                " (GetIsGlobal() returns False)");
                next;
            }
         } else {
            $vdLogger->Debug("Skipping the replication of non global object" .
                            " (GetIsGlobal() missing)");
            next;
         }
         $vdLogger->Debug("Replicating component object for tuple $target from node $node");
         $self->SetComponentObject($target, $temp);
         delete @$refToArrayOfNodes[$index];
      }
      $index++;
   }

   # Recursing through remaining items in array

   if (!(@$refToArrayOfNodes )) {
      return SUCCESS;
   }
   foreach my $obj (@$refToArrayOfNodes) {
      if (defined $obj) {
         my $newObj = $target . '/' . $obj;
         my $oldObj = $node . '/' . $obj;
         $self->RecursiveReplicateComponents($oldObj, $newObj);
      }
   }

   return SUCCESS;
}

###############################################################################
#
# InitializeDC --
#      This method would create the required folder and datacenter on the
#      given VC.
#
# Input:
#      vcObj		- VC Object
#      dcHash		- Datacenter testbed spec hash
#      componentIndex	- Component Index
#
# Results:
#    dcObj (Datacenter class object), if creation of datacenter is successfull.
#    FAILURE, in case of any failure.
#
# Side effects:
#      None.
#
###############################################################################

sub InitializeDC
{
   my $self	          = shift;
   my $vcObj	      = shift;
   my $dcHash	      = shift;
   my $componentIndex = shift;
   my $inventoryIndex = shift;

   my $folder	  = undef;
   my $datacenter = undef;

   # check the values.
   if(not defined $vcObj) {
      $vdLogger->Error("VC Object not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $folder = $dcHash->{foldername};

   if ((not defined $dcHash->{name}) || $dcHash->{name} =~ /auto/i) {
      $datacenter = VDNetLib::Common::Utilities::GenerateName("datacenter",
                                                              $componentIndex);
      $folder     = (defined $folder) ? $folder :
		    VDNetLib::Common::Utilities::GenerateName("folder",
                                                              $componentIndex);
   } else {
      $datacenter = $dcHash->{name};
      $folder     = (defined $folder) ? $folder :
		    "folder"."-".$dcHash->{name};
   }

   my $hostFolder = "/"."$folder"."/"."$datacenter";
   my $result;

   # check if datacenter already exists, if yes return success.
   $result = $vcObj->DCExists($hostFolder);
   if ($result eq SUCCESS) {
      $vdLogger->Debug("The datacenter already exists");
   } else {
      #create a folder.
      $result = $vcObj->AddFolder($folder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create the folder");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # create a datacenter.
      $hostFolder = "/".$folder."/".$datacenter;
      $result = $vcObj->CreateDC($hostFolder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create datacenter");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   my $dcObj = VDNetLib::VC::Datacenter->new(vcObj       => $vcObj,
                                             datacenter  => $datacenter,
                                             folder      => $folder,
                                             stafHelper  => $self->{stafHelper});
   if ($dcObj eq FAILURE) {
         $vdLogger->Error("Failed to create Datacenter object for ".
                          "datacenter: $datacenter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }
   # Add hosts to DC, if required
   my @hostObjArray = ();
   my @hostTupleArray = ();
   my $hostList;
   my $hostIndexName;
   if (defined $dcHash->{esx}) {
      $hostList = $dcHash->{esx};
      $hostIndexName = "esx";
   } else {
      $hostList = $dcHash->{host};
      $hostIndexName = "host";
   }
   if (defined $hostList) {
      my $refHost = VDNetLib::Common::Utilities::ProcessMultipleTuples($hostList);
      foreach my $hostIndexes (@$refHost) {
         my @tmpArray = VDNetLib::Common::Utilities::GetTupleInfo($hostIndexes);
         if ($tmpArray[0] eq FAILURE) {
            $vdLogger->Error("Failed to get host information for ".
                             "datacenter: $datacenter");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $hostIndexes = $tmpArray[1];
         foreach my $hostIndex (@$hostIndexes) {
            $result = $self->GetComponentObject("$hostIndexName.[$hostIndex]");
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to get Host object for host tuple: ".
                                "$hostIndexName.[$hostIndex]");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            my $hostObj = pop(@$result);
            if (not defined $hostObj) {
               $vdLogger->Error("Failed to access host: ".
                                "$hostIndexName.[$hostIndex]");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            push(@hostObjArray, $hostObj);
            push(@hostTupleArray, "$hostIndexName.[$hostIndex]");
         }
      }
      $result = $dcObj->AddHostsToDC(\@hostObjArray, $hostFolder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to add required hosts to datacenter: ".
                          "$dcObj->{datacentername}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      foreach my $hostTuple (@hostTupleArray) {
         $result = $self->SetComponentObject($hostTuple, shift(@hostObjArray));
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to set Host object for host tuple: ".
                             "$hostTuple");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   delete $dcHash->{host};
   delete $dcHash->{foldername};
   delete $dcHash->{name};

   my $dcWorkloadObj = $self->{DatacenterWorkload};
   my $tuple = "vc.[$inventoryIndex].datacenter.[$componentIndex]";
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
		    "DatacenterWorkload");
   $dcWorkloadObj->SetComponentIndex($tuple);

   my $hashSize = keys %$dcHash;
   if ($hashSize > 0) {
      $result = $dcWorkloadObj->ConfigureComponent(configHash => $dcHash,
                                                   testObject => $dcObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure Datacenter " .
			  " component with :". Dumper($dcHash));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return $dcObj;
}


###############################################################################
#
# InitializeVDS --
#      This method would create the required VDS on the given VC
#      and datacenter.
#
# Input:
#      vcObj		- VC Object
#      vdsHashref	- VDS testbed spec hash reference
#      componentIndex	- Component Index
#
# Results:
#    vdsObj (VDS class object), if creation of VDS is successfull.
#    FAILURE, in case of any failure.
#
# Side effects:
#      None.
#
###############################################################################

sub InitializeVDS
{
   my $self	      = shift;
   my $vcObj	      = shift;
   my $vdsHashref     = shift;
   my $componentIndex = shift;
   my $result;

   # create local copy of the input vdsHash
   my %tmpHash = %$vdsHashref;
   my $vdsHash = \%tmpHash;

   my $version	  = $vdsHash->{version};
   my $datacenter = $vdsHash->{datacenter};
   my $vdsName	  = $vdsHash->{name};

   my $vcIndex;
   my $dcIndex;

   if (not defined $datacenter) {
      $vdLogger->Error("datacenter key is mandatory but missing.".
                       " Hence creation of VDS failed.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @tmpArray = VDNetLib::Common::Utilities::GetTupleInfo($datacenter);
   if ($tmpArray[0] eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vcIndex  = ${$tmpArray[1]}[0];
   $dcIndex  = ${$tmpArray[3]}[0];

   $result = $self->GetComponentObject("vc.[$vcIndex].datacenter.[$dcIndex]");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to initialize VDS.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $dcObj = pop(@$result);
   if (not defined $dcObj) {
      $vdLogger->Error("Failed to access datacenter: ".
		       "vc.[$vcIndex].datacenter.[$dcIndex]");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $datacenter = $dcObj->{datacentername};
   if (not defined $datacenter) {
      $vdLogger->Error("Failed to access datacenter: ".
		       "vc.[$vcIndex].datacenter.[$dcIndex]");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vdsName) {
      $vdsName = "vds";
      $vdsName = VDNetLib::Common::Utilities::GenerateNameWithRandomId($vdsName,
							   $componentIndex);
   }

   $vdLogger->Info("Adding Switch $vdsName to datacenter: $datacenter");

   # create a VDS.
   $result = $vcObj->CreateVDSOnVC($datacenter, $vdsName, $version);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create VDS: $vdsName");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $vdsObj = VDNetLib::Switch::Switch->new(
				'switch'     => $vdsName,
				'switchType' => "vdswitch",
				'datacenter' => $datacenter,
				'vcObj'      => $vcObj,
				'stafHelper' => $self->{stafHelper});
   if ($vdsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VDSwitch object for: ".
                       Dumper($vdsHash));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   delete $vdsHash->{version};
   delete $vdsHash->{datacenter};
   delete $vdsHash->{name};

   $result = $self->InitializeUplinkPortGroup($vdsHash,
                                              $vdsObj,
                                              $componentIndex,
                                              $vcIndex);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create uplink portgroup for VDSwitch");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $switchWorkloadObj = $self->{SwitchWorkload};
   my $tuple = "vc.[$vcIndex].vds.[$componentIndex]";
   $vdLogger->Debug("Updating the componentIndex = $tuple of SwitchWorkload");
   $switchWorkloadObj->SetComponentIndex($tuple);

   my $hashSize = keys %$vdsHash;
   if ($hashSize > 0) {
      $result = $switchWorkloadObj->ConfigureComponent('configHash' => $vdsHash,
                                                       'testObject' => $vdsObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure VDS component".
			  " with :". Dumper($vdsHash));
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }

   return $vdsObj;
}


###############################################################################
#
# InitializeUplinkPortGroup --
#      This method would create the required uplink port group
#      for vds.
#
# Input:

#      vdsHash         - VDS testbed spec hash reference
#      vcObj           - VC Object
#      componentIndex  - Component Index of vds
#      vcIndex         - Inventory index of vc
#
# Results:
#    vdsObj (VDS class object), if creation of VDS is successfull.
#    FAILURE, in case of any failure.
#
# Side effects:
#      None.
#
###############################################################################

sub InitializeUplinkPortGroup
{
   my $self           = shift;
   my $vdsHash        = shift;
   my $vdsObj         = shift;
   my $componentIndex = shift;
   my $vcIndex        = shift;
   my $result;

   # Check if hosts are defined
   if (not defined $vdsHash->{host}) {
      $vdLogger->Info("VDS not associated with a host,".
                      " skipping uplink portgourp initialization");
      return SUCCESS;
   }

   # Get the host tuple from config hash
   my ($host, $remainingHosts) = split(';;',$vdsHash->{host});
   $result = $self->GetAllComponentTuples($host);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $hostTuple = pop(@$result);
   my $switchName = $vdsObj->{switch} || $vdsObj->{name};

   $vdLogger->Info("Initializing uplink portgroup for $switchName");
   $result = $self->GetComponentObject($hostTuple);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get Host object to initialize UplinkPortGroup $hostTuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $hostObj = pop(@$result);
   my $hostIP = $hostObj->{hostIP};
   my $uplinkPort = $vdsObj->GetUplinkPortGroup($hostIP);
   if ($uplinkPort eq FAILURE) {
      $vdLogger->Error("Failed to get the uplink portgroup for $vdsObj->{switch}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $uplinkPGObj = new VDNetLib::Switch::VDSwitch::DVPortGroup(
                                              DVPGName   => $uplinkPort,
                                              switchObj  => $vdsObj->{switchObj},
                                              stafHelper => $self->{stafHelper});
   if ($uplinkPGObj eq FAILURE) {
      $vdLogger->Error("Failed to create Uplink object for $uplinkPort");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $uplinkTuple = "vc.[$vcIndex].vds.[$componentIndex].uplinkportgroup.[1]";
   $result = $self->SetComponentObject($uplinkTuple, $uplinkPGObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to set uplink portgroup object for host tuple: ".
                       "$uplinkTuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully created the uplink portgroup $uplinkTuple");
   return SUCCESS;
}

############################################################################### #
# ReplacePortsWithDVPortHash --
#      This method replaces the ports key in dvportgroup with
#      dvport key and places a hash for that key.
#
# Input:
#      $dvpgHash  - dvpg hash
#
# Results:
#      return dvpgHash, where ports is replaced dvport key
#
# Side effects:
#      None.
#
###############################################################################

sub ReplacePortsWithDVPortHash
{
   my $self = shift;
   my $dvpgHash = shift;

   my $ports = $dvpgHash->{ports};
   my $dvportHash = {};
   if (not exists $dvpgHash->{dvport}) {
      if (not defined $ports) {
         $ports = VDNetLib::Common::GlobalConfig::DEFAULT_DV_PORTS;
         my $index = "'" . "[1-$ports]" . "'";
         $dvportHash->{$index} = {};
      } else {
         if ($ports eq "1") {
            $dvportHash->{'[1]'} = {};
         } else {
             my $index = "'" . "[1-$ports]" . "'";
             $dvportHash->{$index} = {};
         }
      }
   }
   if (%$dvportHash) {
      delete $dvpgHash->{ports};
      $dvportHash = VDNetLib::Common::Utilities::ExpandTuplesInSpec($dvportHash);
      $dvpgHash->{'dvport'} = $dvportHash;
   }

   return $dvpgHash;
}


###############################################################################
#
# SetRuntimeStatsValue -
#       Sets runtime values under the folder
#       component index/runtime/workloadName
#          e.g. /testbed/vm/1/vnic/1/runtime/<workloadname>/<instance>
#
# Input:
#       vdnetIndex         - vdnet index e.g. host.[1]
#       workloadName       - name fo the workload under which the most
#                            recent stats will be stored.
#       attributeGroupName - attribute Group Name 'key' for which
#                            default value needs to be accessed.
#       attributeValue     - value that will stored under the path
#
# Results:
#       SUCCESS, if everything goes fine.
#	FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub SetRuntimeStatsValue
{
   my $self               = shift;
   my $vdnetIndex         = shift;
   my $workloadName       = shift;
   my $attributeGroupName = shift;
   my $attributeValue     = shift;

   if (not defined $attributeGroupName) {
      $vdLogger->Error("attribute Group Name 'key' for which" .
                       " default value needs to be accessed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $zkObj = $self->{zookeeperObj};

   my $node = $self->{zkSessionNode};
   my $defaultNode = $node;
   my $tuple = $vdnetIndex;
   $tuple = VDNetLib::Testbed::Utilities::ConvertVdnetIndexToPath($tuple);

   # Creating defaultTuple which will help in
   # setting the default value at this location
   my $defaultTuple = $tuple . '/runtime/' . $attributeGroupName . '/' .
                      'default';
   if ((not defined $workloadName) || ($workloadName eq '')) {
      $workloadName = "ChildWorkload";
      $vdLogger->Debug("This is a child workload");
   }
   $tuple = $tuple . '/runtime/' . $attributeGroupName . '/' .
            lc($workloadName) . '/';

   # Check how many children are present
   # calculate the total # of elements and
   # add 1 to it. That will be the index
   my $masterNode = $node . '/' . $tuple;
   my $refToArrayOfNodes = $zkObj->GetChildren($masterNode, $self->{zkHandle});
   my $index = @$refToArrayOfNodes + 1;
   $tuple = $tuple . $index;
   $vdLogger->Debug("Adding workload node = $tuple under root = $node");
   $node = $self->AddRecursiveZooKeeperPath("$node/$tuple", $zkObj);
   if ('FAILURE' eq $node) {
      $vdLogger->Error("Failed to add zookeeper node for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Serializing Data
   $vdLogger->Debug("Serializing data");
   my $serializedData =
     VDNetLib::Testbed::Utilities::SerializePerlDataStructure($attributeValue);

   # Set value for workload/iteration
   $vdLogger->Debug("Put serialized data to node: $node");
   if (FAILURE eq $zkObj->SetNodeValue($node, $serializedData, $self->{zkHandle})) {
      $vdLogger->Error("Failed to set zookeeper node for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Set value for key/default
   my $result = $self->SetRuntimeDefaultValue($index,
                                              $defaultTuple,
                                              $workloadName);
   if (FAILURE eq $result) {
      $vdLogger->Error("Failed to set runtime default value for $defaultTuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Updated zookeeper node for $tuple");
   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return SUCCESS;
}


###############################################################################
#
# SetRuntimeDefaultValue -
#       Set value located under <componentName>/1/runtime/<key>/default
#       to point at last created runtime workload + iteration.
#
#         E.g. host/1/runtime/<key>/default will always have a value
#              equal to querydapater/4, which means 'QueryAdapater' is
#              the workload name and 4 is the iteration or instance of
#              attributes collected from the server call.
#
# Input:
#        index        - the iteration/instance of the workload
#        defaultTuple - The path under which the default value will
#                       be stored. e.g. host/1/runtime/<key>/default
#        workloadName - Name of the workload whose most recent value
#                       will be stored
#
# Results:
#       SUCCESS, if successful in setting the default value
#	     FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub SetRuntimeDefaultValue
{
   my $self         = shift;
   my $index        = shift;
   my $defaultTuple = shift;
   my $workloadName = shift;

   my $defaultNode = $self->{zkSessionNode};
   my $zkObj = $self->{zookeeperObj};

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $checkNode = $defaultNode . '/' . $defaultTuple;
   my $result;
   $vdLogger->Debug("Check if node = $checkNode exists");
   $result = $zkObj->CheckIfNodeExists($checkNode, $self->{zkHandle});
   if (FAILURE eq $result) {
      $vdLogger->Debug("Adding default node = $checkNode");
      $defaultNode = $self->AddRecursiveZooKeeperPath(
        "$defaultNode/$defaultTuple", $zkObj);
      if (FAILURE eq $defaultNode) {
         $vdLogger->Error("Failed to add multiple nodes for $defaultNode");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Debug("Default node already exists = $checkNode");
      $defaultNode = $checkNode;
   }
   my $defaultValue = $workloadName . '/' . $index;
   $vdLogger->Debug("Put value = $defaultValue in default node = $defaultNode");
   $result = $zkObj->SetNodeValue($defaultNode,
                                  $defaultValue,
                                  $self->{zkHandle});
   if (FAILURE eq $result) {
      $vdLogger->Error("Failed to set zookeeper node for $defaultNode");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return $result;
}


###############################################################################
#
# AddRecursiveZooKeeperPath -
#       Adds recursive path to ZooKeeper.
#
# Input:
#       location   - location in directory structure.
#       zkObj      - zookeeper object
#       flags      - flags to create the recursive path. If
#           ZOO_EPHEMERAL is provided then only the leaf node in the
#           entire path will be created as EPHEMERAL.
#
# Results:
#       node, slash separated path in zookeeper directory format
#	     FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub AddRecursiveZooKeeperPath
{
   my $self      = shift;
   my $location  = shift;
   my $zkObj     = shift;
   my $flags     = shift || 0;
   my $ephemeralFlag = VDNetLib::Common::ZooKeeper::ZOO_EPHEMERAL;
   my $ephemeralFlagCombo = (VDNetLib::Common::ZooKeeper::ZOO_EPHEMERAL |
                             VDNetLib::Common::ZooKeeper::ZOO_SEQUENCE);
   if (not defined $location) {
      $vdLogger->Error("ZK path to be added is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my @temp = split('/', $location);
   @temp = grep {$_ ne ''} @temp;
   $temp[0] = "/$temp[0]";
   for (my $ind = 0; $ind < @temp - 1; $ind++) {
      my @allSeenIndices = 0 .. $ind;
      my $parentNode = join('/', @temp[@allSeenIndices]);
      my $failed = 0;
      if (FAILURE eq $zkObj->CheckIfNodeExists($parentNode, $self->{zkHandle})) {
         $vdLogger->Trace("Adding node $parentNode");
         my $result = $zkObj->AddNode($parentNode, undef, undef,
                                      $self->{zkHandle}, $flags);
         if ($result eq 'FAILURE') {
            $vdLogger->Error("Failed to add zookeeper node: $parentNode");
            VDSetLastError(VDGetLastError());
            $failed = 1;
         }
      }
      my $childIndex = $ind + 1;
      my $childNode = $parentNode . "/" . lc($temp[$childIndex]);
      if (FAILURE eq $zkObj->CheckIfNodeExists($childNode, $self->{zkHandle})) {
         $vdLogger->Trace("Adding node $childNode");
         my $result = undef;
         if (($flags == $ephemeralFlag) || ($flags == $ephemeralFlagCombo)) {
            if ($childIndex == scalar(@temp) - 1) {
                # Only apply flags to the leaf if ephemeral flag is passed,
                # otherwise ZK would throw ZNOCHILDRENFOREPHEMERALS.
                $result = $zkObj->AddNode($childNode, undef, undef,
                   $self->{zkHandle}, $flags);
            } else {
                $result = $zkObj->AddNode($childNode, undef, undef,
                   $self->{zkHandle});
            }
         } else {
             $result = $zkObj->AddNode($childNode, undef, undef,
                $self->{zkHandle}, $flags);
         }
         if ($result eq 'FAILURE') {
            $vdLogger->Error("Failed to add zookeeper node: $childNode");
            VDSetLastError(VDGetLastError());
            $failed = 1;
         }
      }
      if ($failed) {
         $vdLogger->Error("Failed to add zookeeper node: $location");
         return FAILURE;
      }
   }
   return $location;
}


###############################################################################
#
# GetRuntimeStatsValue -
#       Gets runtime stats from a given location.
#
# Input:
#       vdnetIndex         - vdnet index e.g. host.[1]
#       workloadName       - name fo the workload under which the most
#                            recent stats will be stored.
#       workloadIndex      - iteration of the workload
#       attributeGroupName - attribute Group Name 'key' for which
#                            for example 'read' is a type of attributeGroupName
#
# Results:
#       value, extracted form the given path
#	     FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub GetRuntimeStatsValue
{
   my $self               = shift;
   my $vdnetIndex         = shift;
   my $workloadName       = shift;
   my $workloadIndex      = shift;
   my $attributeGroupName = shift;

   if (not defined $attributeGroupName) {
      $vdLogger->Error("attribute Group Name 'key' for which" .
                       " default value needs to be accessed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $key;
   my $zkObj = $self->{zookeeperObj};
   my $result;
   my $node = $self->{zkSessionNode};
   my $tuple = $vdnetIndex;
   $tuple = VDNetLib::Testbed::Utilities::ConvertVdnetIndexToPath($tuple);
   $node = $node . '/' . $tuple . '/runtime/' . $attributeGroupName . '/' .
           lc($workloadName) . '/' . $workloadIndex;

   $vdLogger->Debug("Check if $node exist");
   if (FAILURE eq $zkObj->CheckIfNodeExists($node, $self->{zkHandle})) {
      $vdLogger->Error("ZooKeeper node $node does not exist");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Get value from $node");
   my $value = $zkObj->GetNodeValue($node, $self->{zkHandle});
   if ($value eq FAILURE) {
      $vdLogger->Error("Failed to get zookeeper node for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   chomp($value);
   $value = eval($value);
   $vdLogger->Debug("Value from node = $node is " . Dumper($value));
   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return $value;
}


###############################################################################
#
# GetRuntimeDefaultNode -
#       Get value located under host/1/runtime/<key>/default
#       Method is used when we want to access the most recent
#       runtime stats
#
# Input:
#       vdnetIndex         - vdnet index e.g. host.[1]
#       attributeGroupName - attribute Group Name 'key' for which
#                            default value needs to be accessed.
#
# Results:
#       value, extracted form the given path
#	     FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub GetRuntimeDefaultNode
{
   my $self            = shift;
   my $vdnetIndex      = shift;
   my $attributeGroupName = shift;

   if (not defined $attributeGroupName) {
      $vdLogger->Error("attribute Group Name 'key' for which" .
                       " default value needs to be accessed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $node = $self->{zkSessionNode};
   my $zkObj = $self->{zookeeperObj};
   my $tuple = VDNetLib::Testbed::Utilities::ConvertVdnetIndexToPath($vdnetIndex);
   $node = $node . '/' . $tuple . '/runtime/' . $attributeGroupName .
           '/default';
   $vdLogger->Debug("Get default value from $node");
   my $value = $zkObj->GetNodeValue($node, $self->{zkHandle});
   if ($value eq FAILURE) {
      $vdLogger->Error("Failed to get zookeeper node for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return $value;
}


###############################################################################
#
# SetComponentObject -
#       Sets the given values  in the required given place, in the
#       tesbed hash. Location of testbed hash is given in the form
#	of 4 values tuples.
#
# Input:
#       $key   - tuple, representing the component id
#              <inventory>.[<index/range>].<component>.[<index/range>]
#       $value - value to be stored (mandatory)
#
# Results:
#       SUCCESS, if everything goes fine.
#	FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub SetComponentObject
{
   my $self  = shift;
   my $key   = shift;
   my $value = shift;
   return $self->SetComponentDataInZooKeeper($key, $value, 'obj');
}


###############################################################################
#
# SetDataInZooKeeperPath --
#       Stores the given values in the given path.
#
# Input:
#       $path  - Specifies the path relative to testbed/$componentType path under
#           which the provided value would be stored.
#       $value - value to be stored (mandatory)
#       $parentPath - Parent path which will be taken as reference for the
#           path/value being added to Zookeeper. If none is specified then the
#           default zookeeper node is used.
#
# Results:
#       SUCCESS, if everything goes fine.
#       FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub SetDataInZooKeeperPath
{
   my $self  = shift;
   my $path = shift;
   my $value = shift;
   if (not defined $path) {
      $vdLogger->Error("Path to set value in ZK is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Add zookeeper nodes;
   my $zkObj = $self->{zookeeperObj};
   my $nodeExists = $zkObj->CheckIfNodeExists($path, $self->{zkHandle});
   my $node = $path;
   if (FAILURE eq $nodeExists) {
      $node = $self->AddRecursiveZooKeeperPath($path, $zkObj);
   }
   if (FAILURE eq $node) {
      $vdLogger->Error("Failed to add zookeeper node $path");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $serializedData;
   if (ref($value) =~ /InlinePython/i) {
      $serializedData = VDNetLib::Testbed::Utilities::SerializePythonObj($value);
   } else {
      $serializedData = VDNetLib::Testbed::Utilities::SerializePerlObj($value);
   }
   if (FAILURE eq $zkObj->SetNodeValue($node, $serializedData, $self->{zkHandle})) {
      $vdLogger->Error("Failed to set value for zookeeper node $path");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Updated zookeeper node $path");
   return SUCCESS;
}

###############################################################################
#
# SetComponentDataInZooKeeper --
#       Stores the given values in the required given place, in the
#       tesbed hash.
#
# Input:
#       $key   - tuple, representing the component id
#              <inventory>.[<index/range>].<component>.[<index/range>]
#       $value - value to be stored (mandatory)
#       $path  - Specifies the path relative to object path under which the
#           provided value would be stored/deleted.
#
# Results:
#       SUCCESS, if everything goes fine.
#       FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub SetComponentDataInZooKeeper
{
   my $self  = shift;
   my $key   = shift;
   my $value = shift;
   my $path = shift;

   my $zkObj = $self->{zookeeperObj};

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($value =~ /delete/i) {
      return $self->DeleteComponentObject($key);
   }

   #PR: 1124004 check after processing 'delete'
   if ((not defined $value) ||
       ((ref($value) ne 'HASH') && (not defined blessed($value)))) {
      $vdLogger->Error("The given value is neither a hash reference nor " .
                       "a blessed object type:\n" . Dumper($value));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $tuplesArray =  VDNetLib::Common::Utilities::ProcessTuple($key);
   foreach my $tuple (@$tuplesArray) {
      if ((defined $value) && ($value !~ /delete/i)) {
         $value->{objID} = $tuple; # magic! Inject unique objID which is
                                   # necessary to identify the original
                                   # location of component stored in
                                   # $self->{testbed}
      }
      $tuple = $self->GetNodeFromTuple($tuple);

      my $result;
      my $node = $self->{zkSessionNode};
      my $testbedNode = $node . '/' . $tuple;
      my $completePath =  "$testbedNode/$path";

      # Add zookeeper nodes;
      my $setRet = $self->SetDataInZooKeeperPath($completePath, $value);
      if (FAILURE eq $setRet) {
         $vdLogger->Error("Failed to add zookeeper node for $tuple");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("Updated zookeeper node for $tuple");
      $testbedNode =~ s/\//-/g;
      $self->{testbed}{$testbedNode} = $value;
   }
   return SUCCESS;
}

###############################################################################
#
# DeleteComponentObject -
#       Deletes values based on the input tuples.
#
# Input:
#       $key   - Tuple. Based on this tuple, object associated with Tuple
#                is deleted
#
# Results:
#       SUCCESS, if everything goes fine.
#       FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub DeleteComponentObject
{
   my $self  = shift;
   my $key   = shift;

   my $zkObj = $self->{zookeeperObj};
   $vdLogger->Debug("Deleting node $key and its children");
   my $allInstances = $self->GetAllComponentTuples($key);
   if ($allInstances eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $key");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $tuple (@$allInstances) {
      $tuple = $self->GetNodeFromTuple($tuple);
      my $node = $self->{zkSessionNode} . '/' . $tuple;
      $vdLogger->Debug("Deleting node $node");
      my $result = $zkObj->DeleteNode($node, $self->{zkHandle});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to delete node $node");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $node =~ s/\//-/g;
      delete $self->{testbed}{$node};
   }
   return SUCCESS;

}


###############################################################################
#
# ConfigureHost -
#       This method configures the given host to be used by vdNet.
#
# Input:
#       $hostObj - Host Object (mandatory)
#
# Results:
#       SUCCESS, in case of SUCCESS.
#	FAILURE, Otherwise.
#
# Side effects:
#       None
#
###############################################################################

sub ConfigureHost
{
   my $self	= shift;
   my $hostObj	= shift;
   my $hostIP	= $hostObj->{hostIP};

   if ($hostObj->CheckIfHostSetupRequired($self->{pid}) ==
       VDNetLib::Common::GlobalConfig::FALSE) {
      $vdLogger->Info("Host $hostIP already configured by VDNet");
      return SUCCESS;
   }
   $vdLogger->Info("Configuring host $hostIP for vdnet...");
   if ("FAILURE" eq  $hostObj->VDNetESXSetup($self->{'vdNetSrc'},
                                             $self->{'vdNetShare'})) {
      $vdLogger->Error("VDNetSetup failed on host:$hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Mount sharedStorage on the host
   my $sharedStorage = $self->{sharedStorage};

   #
   # If the given value for sharedstorage has :, assume the value is
   # in the format server:/share. Then, mount the server on the host
   # and point the given share to /vmfs/volumes/vdnetSharedStorage.
   #
   my ($sharedStorageServer, $sharedStorageShare) =
      split(/:/,$sharedStorage);

   $vdLogger->Debug("Mounting shared storage: " .
                    "$sharedStorageServer:$sharedStorageShare on $hostIP");
   my $esxUtil = $hostObj->{esxutil};

   $vdLogger->Debug("Mounting $self->{vmServer}:$self->{vmShare} on $hostIP");
   my $vdnetMountPoint = $hostObj->{esxutil}->MountDatastore(
                                                     $hostIP,
                                                     $self->{vmServer},
                                                     $self->{vmShare},
                                                     VDNET_LOCAL_MOUNTPOINT,
                                                     1);
    if ($vdnetMountPoint eq FAILURE) {
      $vdLogger->Info("Failed to mount $self->{vmServer}:$self->{vmShare} ".
                      "on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $prefixDir = $self->{stafHelper}->GetCommonVmfsPartition($hostIP);
   if (($prefixDir eq FAILURE) || (not defined $prefixDir)) {
      $vdLogger->Error("Failed to get the datastore on $hostIP");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("Mounting " . $sharedStorageServer .
                   " on $sharedStorageShare");
   $sharedStorage = $esxUtil->MountDatastore($hostIP,
                                             $sharedStorageServer,
                                             $sharedStorageShare,
                                             VDNET_SHARED_MOUNTPOINT,
                                             0);
   if ($sharedStorage eq FAILURE) {
      $vdLogger->Error("Failed to mount " . $sharedStorageServer .
                      " on $sharedStorageShare");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   # call being made to delete old files from
   # esx host under /vmfs/volumes/<somedatastore>/vdtest*
   $prefixDir = VMFS_BASE_PATH . "$prefixDir";
   $prefixDir =~ s/\/$|\\$//; # Trailing slashes in the path are removed
   my $path = '"' . $prefixDir . '/vdtest*"';
   VDNetLib::Common::Utilities::CleanupOldFiles(path       => $path,
                                                stafhelper => $hostObj->{stafHelper},
                                                systemip   => $hostObj->{hostIP});


   return SUCCESS;
}


########################################################################
#
# InitializeVmnicAdapter --
#      Method to initialize Vmnics nics required for a test session.
#      This method creates VDNetLib::NetAdapter::NetAdapter object.
#
# Input:
#      hostObj            - Host Object
#      vmnicHashref       - Vmnic testbed spec hash reference
#      freePnics          - Parameter specifying whether given pnic
#                           is in use or not i.e. not connected to any
#                           switch (vss, vds, nsxswitch.
#      componentIndex     - component index for the pnic. The index
#                           should be integer (0-20)
#
# Results:
#      vmnicObj, if the required Vmnic adapter is initialized
#                 successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeVmnicAdapter
{
   my $self	      = shift;
   my $hostObj	      = shift;
   my $vmnicHashref   = shift;
   my $freePnics      = shift;
   my $componentIndex = shift;
   my $vmnicObj	      = undef;
   my $result;

   # create local copy of the input vmnicHash
   my %tmpHash = %$vmnicHashref;
   my $vmnicHash = \%tmpHash;

   my $session   = $self->{session};
   my $hostIP    = $hostObj->{hostIP};

   my $driver = $vmnicHash->{driver};
   my $speed  = $vmnicHash->{speed};
   my $interface = $vmnicHash->{interface};
   if ((not defined $driver) || ($driver =~ /any/i)) {
      $driver = undef;
   }

   #
   # if index specified is 0 (VDNetLib::Common::GlobalConfig::VDNET_RESERVE_INDEX)
   # do not check whether nic is free since this pnic will be connected to management
   # network and will be in use.
   #
   if ($componentIndex ne VDNetLib::Common::GlobalConfig::VDNET_RESERVE_INDEX) {
      if ((not defined $freePnics) || scalar(@$freePnics) == 0) {
         $vdLogger->Error("No more Vmnic adapters are present on: $hostIP . ".
		       "Failed to get required adapter: ". Dumper($vmnicHash));
         VDSetLastError("ELIMIT");
         return FAILURE;
      }
   }
   if (defined $speed) {
      if ($speed =~ /(.*)G$|(.*)Gbps$/i) {
         $speed = $1 * 1000;
      } elsif ($speed =~ /(.*)M$|(.*)Mbps$/i) {
         $speed = $1;
      }
      $vdLogger->Debug("Looking for vmnics with speed $speed" .
                       "Mbps on $hostIP");
   }

   if (defined $interface) {
      $vdLogger->Info("Interface $interface already defined by user");
      goto FOUND;
   }
   foreach my $index (0..$#$freePnics) {
      my $node = $freePnics->[$index];
      if (not defined $node) {
         next;
      }
      if (defined $driver && $driver =~ /\w+/ ){
         # 2nd element in node is driver
         if ($node->[1] ne $driver) {
            next;
         }
      }
      if (defined $speed) {
         # 3rd element in node is speed
         if ($node->[2] ne $speed) {
            next;
         }
      }

      # remove the current node from the freePnics list.
      delete $freePnics->[$index];
      $interface = $node->[0];
      last;
   }
   if (not defined $interface) {
      $vdLogger->Error("Couldn't find a vmnic matching given attributes");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
FOUND:
   $vdLogger->Info("Creating NetAdapter object for: $interface on $hostIP");
   $vmnicObj = VDNetLib::NetAdapter::NetAdapter->new(controlIP => $hostIP,
                                                     interface => $interface,
                                                     intType   => "vmnic",
                                                     hostObj   => $hostObj);
   if ($vmnicObj eq FAILURE) {
      $vdLogger->Error("Failed to create vmnic object for $interface");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   delete $vmnicHash->{interface};
   delete $vmnicHash->{driver};
   delete $vmnicHash->{speed};
   delete $vmnicHash->{passthrough};

   my $netWorkloadObj = $self->GetWorkloadObject("NetAdapter");
   my $hashSize = keys %$vmnicHash;
   if ($hashSize > 0) {
      $result = $netWorkloadObj->ConfigureComponent('configHash' => $vmnicHash,
                                                    'testObject' => $vmnicObj,
                                                    'tuple'      => $componentIndex);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure Vmnic component".
                          " with :". Dumper($vmnicHash));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return $vmnicObj;
}


########################################################################
#
# InitializePassthrough --
#     Method to initialize passthrough on the host/adapters
#
# Input:
#      hostObj          - Host Object
#      sriovHash	- SRIOV Hash in the following format:
#
#       $sriovHash => {
#	   '<driver1>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	   '<driver2>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	   .
#	   .
#	   '<driverN>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	}
#
#	fptNicList	- Array of Pnic Names where FPT needs to be
#			  enabled, it at all.
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
   my $self	  = shift;
   my $hostObj	  = shift;
   my $sriovHash  = shift;
   my $fptNicList = shift;
   my $result;


   if (defined $sriovHash) {
      if ($self->ConfigureSRIOV($hostObj, $sriovHash) eq FAILURE) {
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }

   if ($#$fptNicList >= 0) {
      if ($self->InitializeFPT($hostObj, $fptNicList) eq FAILURE) {
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureSRIOV --
#     Method to initialize SRIOV on the given machine (SUT/helper's)
#     host.
#
# Input:
#      hostObj		- Host Object
#      sriovHash	- SRIOV Hash in the following format:
#
#       $sriovHash => {
#	   '<driver1>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	   '<driver2>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	   .
#	   .
#	   '<driverN>' => [<'adapter' => <vmnicX>, 'maxvfs' => <X>,..],
#	}
#
#      action		- "enable" or "disable" on adapters marked for
#			  passthru (sriov) on the given machine
#			  (Optional, default is "enable")
#
# Results:
#     SUCCESS, if SRIOV is initialized successfully.
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureSRIOV
{
   my $self		= shift;
   my $hostObj		= shift;
   my $sriovHash	= shift;
   my $action		= shift || "enable";
   my $result;

   $vdLogger->Info("Configuring pasthrough: sriov on $hostObj->{hostIP}");

   foreach my $driver (keys %$sriovHash) {
      if ($action =~ /disable/i) {
	 foreach my $adapterHash (@{$sriovHash->{$driver}}) {
	    $adapterHash->{'maxvfs'} = "0";
	 }
      }

      my $hostWorkloadObj = $self->GetWorkloadObject("Host");
      my $configHash = undef;

      $configHash->{sriov}  = $action;
      $configHash->{vmnicadapter} = $sriovHash->{$driver};

      $result = $hostWorkloadObj->ConfigureComponent('configHash' => $configHash,
						     'testObject' => $hostObj);
      if ((defined $result) && ($result eq FAILURE)) {
	 $vdLogger->Error("Failed to configure SRIOV on $hostObj->{hostIP} ".
			  "with :". Dumper($configHash));
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeFPT --
#      Method to initialize passthrough.
#
# Input:
#	hostcObj	- Host Object
#	fptNicList	- Array of Pnic Names where FPT needs to be
#			  enabled, it at all.
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
   my $self	  = shift;
   my $hostObj	  = shift;
   my $fptNicList = shift;
   my $result;

   #
   # Enable FPT
   #
   $result = $hostObj->EnableFPT($fptNicList);
   if($result eq FAILURE) {
      $vdLogger->Error("Failed to enable FPT on host $hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $hostObj->{fptNicList} = $fptNicList;
   $result = $self->SetComponentObject($hostObj->{objID}, $hostObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# InitializeAdapterObject --
#      Method to create NetAdapter objects for adapters, if any,
#      required for the given test case. This method also takes
#      care of pre-initializing the required configuration on
#      the given vnic, if requrired. (By calling configureComponent())
#
# Input:
#      vmObj       - VM Object
#      vnicHashref - VNic testbed spec hash reference
#      adapters    - Reference to an array of existing VNics on VM
#
# Results:
#      vnicObj, if the required NetAdapter object is created
#      successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub InitializeAdapterObject
{
   my $self	         = shift;
   my $vmObj	      = shift;
   my $vnicHashref   = shift;
   my $adapters	   = shift;
   my $componentIndex = shift;
   my $vnicObj = FAILURE;
   my $result;

   # create local copy of the input vnicHash
   my %tmpHash  = %$vnicHashref;
   my $vnicHash = \%tmpHash;
   my $vnicType	= $vnicHash->{driver};

   foreach my $index (0..$#$adapters) {
      my $objItem = $adapters->[$index];
      if (not defined $objItem) {
	      next;
      }

      if ($objItem->{name} =~ /$vnicType/i) {
         $objItem->{intType}  = "vnic";
         $objItem->{vmOpsObj} = $vmObj;

         while(my($k,$v)=each(%$objItem)){$vdLogger->Info("objitem of vnic:$k--->$v");}
         $vnicObj = VDNetLib::NetAdapter::NetAdapter->new(%$objItem);
         if ($vnicObj eq "FAILURE") {
            $vdLogger->Error("Failed to initialize NetAdapter obj " .
                             "for $vnicType on VM: $vmObj->{vmIP}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
	      delete $adapters->[$index];
	      last;
      }
   } # end of foreach loop

   delete $vnicHash->{portgroup};
   delete $vnicHash->{driver};

   my $netadapterWorkloadObj = $self->GetWorkloadObject("NetAdapter");
   my $hashSize = keys %$vnicHash;
   if ($hashSize > 0) {
      while(my($k,$v)=each(%$vnicHash)){$vdLogger->Info("vnicHash: $k--->$v");}
      my $result = $netadapterWorkloadObj->ConfigureComponent(
                                      configHash => $vnicHash,
                                      testObject => $vnicObj
                                      );
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure adapter component".
                          " with :". Dumper($vnicObj));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return $vnicObj;
}


########################################################################
#
# IsSMBRunning --
#       Checks if SMB is running on local machine
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
         $vdLogger->Debug("SMB is not installed:$cmdOut");
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
#       Start SMB on local machine, this is required when you reboot the
#       master controller machine and not configured to start smb as
#       part of your startup scripts.
#
#       NOTE:  This method will not install SAMBA on local machine.
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
         $vdLogger->Debug("SMB is not installed on this machine $cmdOut");
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
   my $self	   = shift;
   my $finalResult = SUCCESS;
   my $result;

   $vdLogger->Info("Doing session cleanup...");

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $result = $self->CleanupVM();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the VM.");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }

   $result = $self->CleanupVSMManager();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the NSX Manager for VSM product");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }
   $result = $self->CleanupNSXManager();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the NSX Manager for Transformer product");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }
   my $hostIndexName = "host";
   if (defined $self->{'testbedSpec'}{'esx'}) {
      $hostIndexName = "esx";
   }
   $result = $self->CleanupHost($hostIndexName);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the Host.");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }

   $result = $self->CleanupVC();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the VC.");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }

   # cleanup all ssh handles
   foreach my $host (keys %$sshSession) {
      undef $sshSession->{$host};
      delete $sshSession->{$host};
   }

   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return $finalResult;
}


########################################################################
#
# CleanupHost --
#      This method cleans everything created on host during
#      InitializeHost() method, for the given test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if the Host components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupHost
{
   my $self     = shift;
   my $hostIndexName = shift;
   my $result   = SUCCESS;

   $vdLogger->Info("Doing Host Components cleanup...");

   #
   # reset the noOfMachines to 0 first.
   # The noOfMachines are set during the testbed Init
   # based on the test session parameters.
   #
   # set this before doing any cleanup so even if
   # cleanup fails we have correct parameters for
   # the next test.
   #
   $self->{noOfMachines} = 0;

   # cleanup any VDR instances
   if ($self->CleanupVDRInstances($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup VDR instances.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   # Cleanup the Vm Kernel Nics
   if ($self->CleanupVMKNics($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup VMKNics.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   if ($self->CleanupNVPNetworks($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup netstack instances.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }
   # cleanup any netstack instances
   if ($self->CleanupNetstackInstances($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup netstack instances.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   # Cleanup the Virtual Switches
   if ($self->CleanupVSwitches($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup Virtual Switches.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   # Cleanup the Vmnics
   if ($self->CleanupVMNics($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup Vmnics.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   # Cleanup the Passthrough
   if ($self->CleanupPassthrough($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup Vmnics Passthrough.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   # Cleanup the STAFAnchors
   if ($self->CleanupSTAFAnchors($hostIndexName) eq FAILURE) {
      $vdLogger->Error("Failed to cleanup STAF Anchors.");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   return $result;
}

########################################################################
#
# CleanupVSwitches --
#      This method cleans virtual switches used in a test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if virtual switches are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVSwitches
{
   my $self	= shift;
   my $hostIndexName = shift;
   my $errFound	= 0;
   my $result;

   $vdLogger->Info("Doing VSS cleanup");
   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].vss.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get VSS objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No virtual switch initialized to clean from ".
		      "last test case.");
      return SUCCESS;
   }

   #
   # In vdnet all the virtual switches used are created freshly instead of
   # using existing ones. In cleanup, all those switches will be deleted.
   #
   foreach my $vssObj (@$componentArray) {
      if (defined $vssObj) {
	 my $hostObj = $vssObj->{hostOpsObj};
	 if ($vssObj->{'name'} =~ "vSwitch0") {
	    next;
	 }
	 $result = $hostObj->DeletevSwitch($vssObj->{'name'});
	 if ($result eq FAILURE) {
	    $vdLogger->Error("Failed to delete $vssObj->{'name'} ".
			     "on $hostObj->{hostIP}");
	    VDSetLastError(VDGetLastError());
	    $errFound++;
	    next;
	 }
	 $vdLogger->Info("Successfully deleted the VSS: $vssObj->{'name'} ".
			 "on $hostObj->{hostIP}");
      }
   }

   if ($errFound) {
#       return FAILURE;
       return SUCCESS;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# CleanupVMKNics --
#      This method cleans vmknics created in a test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
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
   my $self	= shift;
   my $hostIndexName = shift;
   my $errFound	= 0;
   my $result;
   my @arrayOfVmknicObjects;

   $vdLogger->Info("Doing VMKNic cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].vmknic.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get VMKNic objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No VMKNics initialized to clean from ".
		      "last test case.");
      return SUCCESS;
   }

   foreach my $vmknicObj (@$componentArray) {
      if ((defined $vmknicObj) && ($vmknicObj->{deviceId} ne "vmk0")) {
	 my $hostObj   = $vmknicObj->{hostObj};
         push(@arrayOfVmknicObjects, $vmknicObj);
	 $result = $hostObj->DeleteVmknic(\@arrayOfVmknicObjects);
	 if ($result eq FAILURE) {
	    $vdLogger->Error("Failed to delete vmknic $vmknicObj->{deviceId}");
	    VDSetLastError(VDGetLastError());
	    $errFound++;
	    next;
	 }
      }
      @arrayOfVmknicObjects = ();
   }

   if ($errFound) {
       return FAILURE;
   } else {
       $vdLogger->Info("Successfully deleted the VMKNics");
       return SUCCESS;
   }
}


########################################################################
#
# CleanupNetstackInstances --
#      This method cleans netstack instances created in a test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if the netstack instances are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupNetstackInstances
{
   my $self	= shift;
   my $hostIndexName = shift;
   my $errFound	= 0;
   my $result;
   my @arrayOfNetstackObjects;

   $vdLogger->Info("Doing Netstack cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].netstack.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get Netstack objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No Netstack instances initialized.");
      return SUCCESS;
   }

   foreach my $netstackObj (@$componentArray) {
      if (defined $netstackObj) {
         my $hostObj   = $netstackObj->{hostObj};
         my $netstackName = $netstackObj->{netstackName};
         #
         # don't remove the default instance, since
         # we don't create and tyring to delete would
         # would always return FAIL.
         #
         my $defaultStack = VDNetLib::Common::GlobalConfig::DEFAULT_STACK_NAME;
         if ($netstackName =~ m/$defaultStack/i) {
            next;
         }
         push(@arrayOfNetstackObjects, $netstackObj);
         my $result = $hostObj->RemoveTCPIPInstance(\@arrayOfNetstackObjects);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to delete netstack instance $netstackName");
            VDSetLastError(VDGetLastError());
	    $errFound++;
	    next;
         }
         $vdLogger->Info("Successfully deleted the netstack: $netstackName ".
			 "on $hostObj->{hostIP}");
         @arrayOfNetstackObjects = ();
      }
   }

   if ($errFound) {
       return FAILURE;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# CleanupNVPNetworks --
#     Method to clean all NVP networks on the testbed
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#     SUCCESS, if all NVP networks are cleaned up;
#     FAILURE, in case of any error;
#
# Side effects:
#     None of the NVP network objects will be accessible;
#
########################################################################

sub CleanupNVPNetworks
{
   my $self = shift;
   my $hostIndexName = shift;

   $vdLogger->Info("Doing NVP network cleanup");
   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].nvpnetwork.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get NVP network from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No NVP network instances initialized.");
      return SUCCESS;
   }


	my $errFound = 0;
   foreach my $nvpNetworkObj (@$componentArray) {
      my $hostObj   = $nvpNetworkObj->{hostOpsObj};
      # TODO: cleanup should happen per host for better runtime,
      # right now, all nvp networks are cleaned one by one even if multiple
      # networks belong to same host
      if ($hostObj->RemoveNVPNetwork([$nvpNetworkObj]) eq FAILURE) {
         $vdLogger->Error("Failed to remove NVP network " .
                          $nvpNetworkObj->{'network'});
	      $errFound++;
      }
   }
   if ($errFound) {
       return FAILURE;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# CleanupVMNics --
#      This method cleans vmnics used in a test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if vmnics are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVMNics
{
   my $self = shift;
   my $hostIndexName = shift;
   my $result;

   $vdLogger->Info("Doing VMNic cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].vmnic.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get vmnic objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No vmnics initialized to clean from ".
                      "last test case.");
      return SUCCESS;
   }

   foreach my $vmnicObj (@$componentArray) {
      if (defined $vmnicObj) {
	 if ($vmnicObj->{status} =~ m/down/i) {
	    if ($vmnicObj->SetDeviceUp() eq FAILURE) {
	       $vdLogger->Error("Failed to enable the interface ".
				"$vmnicObj->{vmnic}");
	       VDSetLastError(VDGetLastError());
	       $result = FAILURE;
	    }
	 }
      }
   }

   return SUCCESS;
}


########################################################################
#
# CleanupPassthrough --
#      This method clears the passthrough on Vmnics if enabled by test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if the passthrough is reset successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupPassthrough
{
   my $self	= shift;
   my $hostIndexName = shift;
   my $errFound	= 0;
   my $result;

   $vdLogger->Info("Doing Passthrough cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get host objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No hosts initialized to clean from ".
                      "last test case.");
      return SUCCESS;
   }

   foreach my $hostObj (@$componentArray) {
      if (defined $hostObj->{sriovHash}) {
	 if (FAILURE eq $self->ConfigureSRIOV($hostObj,
					      $hostObj->{sriovHash},
					      "disable")) {
	    $vdLogger->Error("Failed to disable SRIOV on $hostObj->{hostIP}");
	    VDSetLastError(VDGetLastError());
	    $errFound++;
	 }
	 $hostObj->{sriovHash} = undef;
      }

      if (defined $hostObj->{fptNicList}) {
	 if (FAILURE eq $hostObj->DisableFPT()) {
	    $vdLogger->Error("Failed to disable FPT on $hostObj->{hostIP}");
	    VDSetLastError(VDGetLastError());
	    $errFound++;
	 }
	 $hostObj->{fptNicList} = undef;
      }
   }

   if ($errFound) {
       return FAILURE;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# CleanupSTAFAnchors --
#      This method cleans up the staf anchors in each of the host
#      object.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if STAF Anchors are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupSTAFAnchors
{
   my $self = shift;
   my $hostIndexName = shift;
   my $result;

   $vdLogger->Info("Doing Host STAF Anchors cleanup");

   my $allInstances = $self->GetAllComponentTuples("$hostIndexName.[-1]");
   if ($allInstances eq FAILURE) {
      $vdLogger->Error("Failed to get all indexes for $hostIndexName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $tuple (@$allInstances) {
      my $tempArray = $self->GetComponentObject($tuple);
      if ($tempArray eq FAILURE) {
         $vdLogger->Error("Failed to get host objects from Testbed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $hostObj = $tempArray->[0];
      $hostObj->UpdateVCObj();

      #
      # Without any argument undef will be sent and default host
      # anchor will get updated in the currentVMAnchor
      #
      $hostObj->UpdateCurrentVMAnchor();
      $tempArray = $self->SetComponentObject($tuple, $hostObj);
      if ($tempArray eq FAILURE) {
         $vdLogger->Error("Failed to get host objects from Testbed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   }
   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get host objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      return SUCCESS;
   }

   foreach my $hostObj (@$componentArray) {
      # Without any argument undef will be updated in the vcObj
      $hostObj->UpdateVCObj();

      #
      # Without any argument undef will be sent and default host
      # anchor will get updated in the currentVMAnchor
      #
      $hostObj->UpdateCurrentVMAnchor();
   }

   return SUCCESS;
}

########################################################################
#
# CleanupVSMManager--
#      This method cleans everything created on VSM Manager during
#      InitializeVSM() method, for the given test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the VSM components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
#########################################################################

sub CleanupVSMManager
{
   my $self = shift;
   my $error = 0;
   my $result;

   my $componentArray = $self->GetComponentObject("vsm.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get VSM manager objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No VSM managers initialized to cleanup");
      return SUCCESS;
   }

   # Delete the Edge Service Gateway
   my $vsmConfigHash = {
      deletegateway => "vsm.[-1].gateway.[-1]",
   };
   $result = $self->CleanupVSM($vsmConfigHash);
   if(not defined $result or $result eq FAILURE) {
      $vdLogger->Error("Failure during gateway cleanup");
      VDSetLastError("EFAIL");
      $error++;
   }

   $vdLogger->Info("Edge Service Gateway deleted successfully");

   # Make clean vxlan controller before clean virtualwires in case of meeting error during
   # clean up virtualwires, thus will make cleanup vxlan controllers not executed, and
   # such resources will be left on the controller host for ever.
   $vsmConfigHash = {
      deletevxlancontroller => "vsm.[-1].vxlancontroller.[-1]",
   };
   $result = $self->CleanupVSM($vsmConfigHash);
   if($result eq FAILURE) {
      $vdLogger->Error("Failure during vxlan controller cleanup");
      VDSetLastError("EFAIL");
      $error++;
   }

   # clean edge as virtual wire deletion will fail if there is LIF
   # pointing to it
   $vsmConfigHash = {
      deletevse => "vsm.[-1].vse.[-1]",
   };
   $result = $self->CleanupVSM($vsmConfigHash);
   if($result eq FAILURE) {
      $vdLogger->Error("Failure during vdn cluster cleanup");
      VDSetLastError("EFAIL");
      $error++;
   }

   # clean virtual wire.
   my $scopeConfigHash = {
      # Waiting for all vNIC refs to be removed PR 1126978
      'sleepbetweenworkloads' => "60",
      deletevirtualwire => "vsm.[-1].networkscope.[-1].virtualwire.[-1]",
   };
   my $allScopeTuples = $self->GetAllComponentTuples("vsm.[-1].networkscope.[-1]");
   foreach my $tuple (@$allScopeTuples) {
      my $ref = $self->GetComponentObject($tuple);
      my $scopeObject = $ref->[0];
      my $transportZoneWorkloadObj = $self->{TransportZoneWorkload};
      $transportZoneWorkloadObj->SetComponentIndex($tuple);
      $result = $transportZoneWorkloadObj->ConfigureComponent(configHash => $scopeConfigHash,
                                                              testObject => $scopeObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failure during Virtual wire cleanup");
         VDSetLastError("EFAIL");
         $error++;
      }
   }

   # clean vsm components
   my $totalvdnclustertuples = $self->GetAllComponentTuples("vsm.[-1].vdncluster.[-1]");
   $vsmConfigHash = {
      deletenetworkscope => "vsm.[-1].networkscope.[-1]",
      deletemulticastiprange => "vsm.[-1].multicastiprange.[-1]",
      deletesegmentidrange => "vsm.[-1].segmentidrange.[-1]",
      deleteippool => "vsm.[-1].ippool.[-1]",
      deletevdncluster => "vsm.[-1].vdncluster.[-1]",
   };
   $result = $self->CleanupVSM($vsmConfigHash);
   if($result eq FAILURE) {
      $vdLogger->Error("Failure during vdn cluster cleanup");
      VDSetLastError("EFAIL");
      $error++;
   }

   # clean vsm application service, application group and application group members
   $vsmConfigHash = {
      deleteapplicationservicegroupmember => "vsm.[-1].applicationservicegroup.[-1].applicationservicegroupmember.[-1]",
      deleteapplicationservicegroup => "vsm.[-1].applicationservicegroup.[-1]",
      deleteapplicationservice => "vsm.[-1].applicationservice.[-1]",
   };
   $result = $self->CleanupVSM($vsmConfigHash);

   if(not defined $result or $result eq FAILURE) {
      $vdLogger->Error("Failure during deletion of vsm application service,group, servicemembers components  gateway cleanup");
      VDSetLastError("EFAIL");
      $error++;
   }
   $vdLogger->Info("Application Components  deleted successfully");

   ############### Keep this code for TrinityFebUpdateRelease ##############
   ############### This product PR tracks it 1114374 ##############

   # unconfigure vxlan
   #   my $clusterConfigHash = {
   #      vxlan => "unconfigure",
   #   };
   #   my $allClusterTuples = $self->GetAllComponentTuples("vsm.[-1].vdncluster.[-1]");
   #   foreach my $tuple (@$allClusterTuples) {
   #      my $ref = $self->GetComponentObject($tuple);
   #      my $clusterObject = $ref->[0];
   #      my $clusterWorkloadObj = $self->{ClusterWorkload};
   #      $clusterWorkloadObj->SetComponentIndex($tuple);
   #      $result = $clusterWorkloadObj->ConfigureComponent(configHash => $clusterConfigHash,
   #                                                        testObject => $clusterObject);
   #      if($result eq FAILURE) {
   #         $vdLogger->Error("Failure during vdn cluster cleanup");
   #         VDSetLastError("EFAIL");
   #         $error++;
   #      }
   #   }
   if (scalar(@$totalvdnclustertuples) > 0) {
      my $allHostTuples = $self->CheckForHosts();
      $vdLogger->Info("Rebooting hosts as part of VSM cleanup");
      foreach my $tuple (@$allHostTuples) {
         my $hostConfigHash = {
            reboot => "yes",
         };
         ## To DO: We need a better solution to identify controller host
         if ($tuple =~ /host.\[1\]/i || $tuple =~ /esx.\[1\]/i ) {
            $vdLogger->Debug("Skipping rebooting of controller host");
            next;
         }
         my $ref = $self->GetComponentObject($tuple);
         my $hostObject = $ref->[0];
         my $hostWorkloadObj = $self->GetWorkloadObject("Host");
         $hostWorkloadObj->SetComponentIndex($tuple);
         $result = $hostWorkloadObj->ConfigureComponent(configHash => $hostConfigHash,
                                                        testObject => $hostObject,
                                                        tuple      => $tuple);
         if($result eq FAILURE) {
            $vdLogger->Error("Failure during host reboot");
            VDSetLastError("EFAIL");
            $error++;
         }
      }
   }

   if (!$error) {
      $vdLogger->Info("Cleanup VSM Manager Successfull");
      return SUCCESS;
   } else {
      $vdLogger->Error("Failure during one or more VSM component cleanup");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}

########################################################################
#
# CheckForHosts --
#      This method returns the ref to array of all host/esx in testbed
#
# Input:
#       None
# Results:
#      return ref to array of all hosts in testbed
#
# Side effects:
#      None
#
#########################################################################

sub CheckForHosts
{
  my $self = shift;
  my $AllHostTuples = $self->GetAllComponentTuples("host.[-1]");
  if (scalar(@$AllHostTuples) == 0) {
    return ($self->GetAllComponentTuples("esx.[-1]"));
  } else {
    return $AllHostTuples;
  }
}



########################################################################
#
# CleanupVSM --
#      This method cleans the components on VSM
#
# Input:
#      vsmConfigHash - containing the subcompoents to be cleanedup on VSM
#
# Results:
#      "SUCCESS", if the VSM subcomponents are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
#########################################################################

sub CleanupVSM
{
   my $self          = shift;
   my $vsmConfigHash = shift;
   my $error = 0;
   my $result;

   # clean vsm components
   my $allVSMTuples = $self->GetAllComponentTuples("vsm.[-1]");
   foreach my $tuple (@$allVSMTuples) {
      my $ref = $self->GetComponentObject($tuple);
      my $vsmObject = $ref->[0];
      my $nsxWorkloadObj = $self->{NSXWorkload};
      $nsxWorkloadObj->SetComponentIndex($tuple);
      $result = $nsxWorkloadObj->ConfigureComponent(configHash => $vsmConfigHash,
                                                    testObject =>  $vsmObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failure during VSM Cleanup");
         VDSetLastError("EFAIL");
         $error++;
      }
   }

   if (!$error) {
      $vdLogger->Info("Cleanup NSX Manager for VSM product Successfull");
      return SUCCESS;
   } else {
      $vdLogger->Error("Failure during one or more nsx component cleanup");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# CleanupVC --
#      This method cleans everything created on VC during
#      InitializeVC() method, for the given test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the VC components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVC
{
   my $self     = shift;
   my $result   = SUCCESS;

   $vdLogger->Info("Doing VC Components cleanup...");

   # Cleanup the Datacenter
   if ($self->CleanupDatacenter() eq FAILURE) {
      $vdLogger->Error("Failed to cleanup datacenter");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   }

   return $result;
}


########################################################################
#
# CleanupDatacenter --
#      This method cleans everything created on VC during
#      InitializeDC() method, for the given test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the Datacenter components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupDatacenter
{
   my $self	= shift;
   my $errFound	= 0;
   my $result;

   $vdLogger->Info("Doing Datacenter cleanup");

   my $componentArray = $self->GetComponentObject("vc.[-1].datacenter.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get datacenter objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No datacenters initialized to clean from ".
                      "last test case.");
      return SUCCESS;
   }

   foreach my $datacenterObj (@$componentArray) {
      if (defined $datacenterObj) {
         my $vcObj = $datacenterObj->{vcObj};
         if ($vcObj->CleanupVC($datacenterObj->{datacentername},
                               $datacenterObj->{foldername}) eq FAILURE) {
            $vdLogger->Error("Failed to cleanup VC: $vcObj->{vcaddr}");
            VDSetLastError("EOPFAILED");
	    $errFound++;
         }
      }
   }

   if ($errFound) {
       return FAILURE;
   }

   #
   # If VC successfully cleanup, we need to update all stafVMAnchors in VM
   # objects for successive VM operations;
   #
   my $vmTupleArray = $self->GetAllComponentTuples("vm.[-1].x.[x]");
   foreach my $vmTuple (@$vmTupleArray) {
      $result = $self->GetComponentObject($vmTuple);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to GetComponentObject for tuple $vmTuple");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $vmObj = $result->[0];
      $vmObj->UpdateSTAFAnchor($vmObj->{'hostObj'}{'stafHostAnchor'});
      $result = $self->SetComponentObject($vmTuple, $vmObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to SetComponentObject for tuple $vmTuple");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# CleanupVM --
#      This method cleans everything created on VM during
#      InitializeVM() method, for the given test case.
#
# Input:
#      tuple(optional): If one wants to delete only specific VM. This
#      is required when deleting VMs from Workload
#
# Results:
#      "SUCCESS", if the VM components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVM
{
   my $self	= shift;
   my $tuple    = shift || undef;
   my $errFound	= 0;
   my $result;

   my @arrayOfVMTypes;
   my @arrayAllTypesOfVM;
   if (not defined $tuple) {
      @arrayOfVMTypes = ("vm","powerclivm","dhcpserver","torgateway", "linuxrouter");
      foreach my $prefix (@arrayOfVMTypes) {
         $vdLogger->Info("Doing VM Components cleanup for $prefix.[-1] ...");
         my $componentArray = $self->GetComponentObject("$prefix.[-1]");
         if ($componentArray eq FAILURE) {
            $vdLogger->Error("Failed to get $prefix objects from Testbed.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         push (@arrayAllTypesOfVM, @$componentArray);
      }
   } else {
      $vdLogger->Info("Doing VM Components cleanup for $tuple ...");
      my $componentArray = $self->GetComponentObject($tuple);
      if ($componentArray eq FAILURE) {
         $vdLogger->Error("Failed to get $tuple objects from Testbed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push (@arrayAllTypesOfVM, @$componentArray);
   }

   if (scalar(@arrayAllTypesOfVM) == 0) {
      $vdLogger->Info("No vms initialized to clean from ".
                      "last test case.");
      return SUCCESS;
   }

   foreach my $vmObj (@arrayAllTypesOfVM) {
      $result = $self->CleanupVNics($vmObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to clean VNics/VIFs on VM: $vmObj->{vmIP}");
         VDSetLastError(VDGetLastError());
         $errFound++;
      }
   }

   if ($errFound) {
       return FAILURE;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# CleanupVNics --
#      This method takes care of cleaning Vnics created on VM during
#      InitializeVM() method, for the given test case.
#
# Input:
#      vmObj  - VM Object
#
# Results:
#      "SUCCESS", if the VNics are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVNics
{
   my $selfi = shift;
   my $vmObj = shift;
   my $includeControlAdapter = shift;
   my $sriovFlag = 0;
   my $result;

   # XXX(gaggarwal/salmanm): Remove these if else and move the VM cleanup parts
   # to respective hypervisor classes.
   if ($vmObj->{hostObj} =~ m/.*kvmoperations/i) {
      return $vmObj->RemoveVirtualAdapters();
   }
   my $hostObj  = $vmObj->{hostObj};
   my $adapters = $vmObj->GetAdaptersInfo();
   if ($adapters eq FAILURE) {
      $vdLogger->Error("Failed to get adapters information ".
                       "on $vmObj->{vmIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Check if PCI Passthru devices exist on this VM. If yes then VM needs
   # to be powered off, before "RemoveVirtualAdapters" function can be
   # called.
   #
   foreach my $item (@$adapters) {
      my $label = (defined $item->{label}) ? $item->{label} : undef;

      if ((defined $label) && ($label =~ /SR-IOV|PCI/i)) {
	 $sriovFlag = 1;
	 last;
      }
   }

   if ($sriovFlag) {
      $result = $vmObj->VMOpsPowerOff();

      if ($result eq FAILURE) {
         $vdLogger->Warn("Failed to poweroff VM");
      }
   }

   # delete all existing test adapters
   $vmObj->RemoveVirtualAdapters(undef, undef, $includeControlAdapter);

   if ($sriovFlag) {
      my $options;
      $options->{waitForSTAF} = 1;
      $result = $vmObj->VMOpsPowerOn($options);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to poweron VM");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# CleanupVDRInstances --
#      This method cleans netstack instances created in a test case.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if the netstack instances are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVDRInstances
{
   my $self	= shift;
   my $hostIndexName = shift;
   my $errFound	= 0;
   my $result;

   $vdLogger->Info("Doing VDR cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1].vdr.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get VDR objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No VDR instances initialized.");
      return SUCCESS;
   }

   foreach my $vdrObj (@$componentArray) {
      if (defined $vdrObj) {
         my $hostObj   = $vdrObj->{hostObj};
         my $vdrName = $vdrObj->{'name'};
         my $result = $hostObj->RemoveLocalVDR($vdrObj);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to delete vdr instance $vdrName");
            VDSetLastError(VDGetLastError());
	    $errFound++;
	    next;
         }
         $vdLogger->Info("Successfully deleted the vdr: ".  "$vdrName");
      }
   }

   if ($errFound) {
       return FAILURE;
   } else {
       return SUCCESS;
   }
}


########################################################################
#
# TestbedCleanUp --
#      This routine cleans the testbed related operations performed for
#      running the test case(s). For example, powering off the vm and
#      unregistering if it was created using linked clone. Also it takes
#      care of deleting the cloned vm directories on host.
#
# Input:
#      None
#
# Results:
#      SUCCESS, if everything goes fine, else FAILURE.
#
# Side effects:
#      None
#
########################################################################

sub TestbedCleanUp
{
   my $self        = shift;
   my $finalResult = SUCCESS;
   my $result;

   if (FAILURE eq $self->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Doing Final Testbed Cleanup...");

   $result = $self->CleanupTestbedVMs();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the VM.");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }

   my $hostIndexName = "host";
   if (defined $self->{'testbedSpec'}{'esx'}) {
      $hostIndexName = "esx";
   }
   $result = $self->CleanupTestbedHosts($hostIndexName);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to cleanup the Host.");
      VDSetLastError(VDGetLastError());
      $finalResult = FAILURE;
   }

   $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   return $finalResult;
}


########################################################################
#
# CleanupTestbedVMs --
#      This method takes care of powering off the vm's if they were
#      dynamically created using templates.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if required vm's are powered-off/un-regiested successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupTestbedVMs
{
   my $self   = shift;
   my $tuple  = shift || "vm.[-1]";
   my $result = SUCCESS;

   $vdLogger->Info("Powering Off and unregistering VM $tuple");
   my $componentArray = $self->GetComponentObject($tuple);
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get vm objects for $tuple from Testbed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      return SUCCESS;
   }
   # use this until PR1010811 is fixed
   foreach my $vmObj (@$componentArray) {
      $vmObj->VMOpsPowerOff();
      $vmObj->VMOpsUnRegisterVM();
   }
   # Removing from zookeeper
   $self->SetComponentObject($tuple, "delete");

   return SUCCESS;
}


########################################################################
#
# CleanupTestbedHosts --
#      This method takes care of deleting the VM directory from each
#      host, if those vm's were dynamically created using templates.
#
# Input:
#      hostIndexName: 'esx' or 'host' (backward compatibility)
#
# Results:
#      "SUCCESS", if required runtime vm directory is cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupTestbedHosts
{
   my $self   = shift;
   my $hostIndexName = shift || "host";
   my $result = SUCCESS;

   $vdLogger->Info("Doing Host Testbed Cleanup");

   my $componentArray = $self->GetComponentObject("$hostIndexName.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get host objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (scalar(@$componentArray) == 0) {
      return SUCCESS;
   }

   foreach my $hostObj (@$componentArray) {
      my $pid =  getpgrp($$) % 2000; # same as GenerateName() from Utilities.pm
      $hostObj->DestroyVMs($pid);
      my $runtimeDir = $hostObj->{runtimeDir};
      my $hostIP     = $hostObj->{hostIP};
      if (defined $runtimeDir) {
	 # $runtimeDir will only be defined for linked cloned vm's.
	 $vdLogger->Debug("Deleting $runtimeDir on $hostIP");

	 # 48 indicates directory does not exist
	 my $ignoreRC		  = 48;
	 my $options;
	 $options->{recurse}	  = 1;
	 $options->{ignoreerrors} = 1;

	 $result = $self->{stafHelper}->STAFFSDeleteFileOrDir($hostIP,
							      $runtimeDir,
							      $options,
							      $ignoreRC);
	 if (not defined $result) {
	    $vdLogger->Warn("Failed to remove $runtimeDir on $hostIP");
	    $vdLogger->Debug(Dumper($result));
	 }
      }
   }
   $vdLogger->Info("Host Testbed cleanup result: SUCCESS");

   return SUCCESS;
}


########################################################################
#
# UpdateZooKeeperHandle --
#     Method to update class attribute 'zkHandle'
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub UpdateZooKeeperHandle
{
   my $self = shift;

   my $zkHandle;
   if (not defined $self->{'zkHandle'}) {
      $zkHandle = $self->{'zookeeperObj'}->CreateZkHandle();
      if (not defined $zkHandle) {
         $vdLogger->Error("ZooKeeper handle is empty");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $self->{'zkHandle'} = $zkHandle;
   } else {
      $zkHandle = $self->{zookeeperObj}->RefreshHandle($self->{zkHandle});
      if ((defined $zkHandle) && ($zkHandle ne FAILURE)) {
         $self->{'zkHandle'} = $zkHandle;
      } else {
         $vdLogger->Error("ZooKeeper handle cannot be refreshed or empty");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   return SUCCESS;;
}

###############################################################################
#
# GetAllTestAdapters -
#       Returns the tuple vm.[1].vnic.[1].
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
   my $adapterTemp = "vm.[1].vnic.[1]";
   push (@adapter, $adapterTemp);
   return \@adapter;
}


###############################################################################
#
# GetAllSupportAdapters -
#       API returns tuples of vnic adapeter for all vm
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

sub GetAllSupportAdapters
{
   my $self = shift;
   return $self->GetAllComponentTuples("vm.[-1].vnic.[-1]");
}
1;


########################################################################
#
# InitializeUsingThreads --
#     A generic method for all initialization using threads.
#
# Input:
#     functionRef: reference to a Perl function/sub-routine;
#     component  : <vc/host/vm/vsm>
#     timeout    : max timeout to initialize one of the given component
#
# Results:
#     SUCCESS, if the given component is initialized successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializeUsingThreads
{
   my $self          = shift;
   my $functionRef   = shift;
   my $component     = shift;
   my $testbedSpec   = $self->{'testbedSpec'};
   @_ = ();


   if ($ENV{VDNET_USE_THREADS}) {
      # Close the handle in parent process before creating new thread
      $self->{zookeeperObj}->CloseSession($self->{zkHandle});
   }

   my $tasksObj = VDNetLib::Common::Tasks->new(
       'maxWorkers' => $self->{'maxWorkers'},
       'maxWorkerTimeout' => $self->{maxWorkerTimeout}
   );
   my $result = FAILURE;
   my $queuedTasks = 0;
   my @result_array = ();
   my $returning = undef;
   foreach my $inventoryIndex (keys %{$testbedSpec->{$component}}) {
      my @args = ($testbedSpec->{$component}{$inventoryIndex},
                 $inventoryIndex, $component);
      my $decorator = sub { $self->TestbedDecoratorForThreads(@_)};
      my @decoratorArgs = ($functionRef, \@args);
      if (!$ENV{VDNET_USE_THREADS}) {
         $vdLogger->Info("Executing job in synchronuous mode");
         $result = &{$functionRef}(@args);
         $vdLogger->Info("The result of thread $result");
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to execute task in synchronuous mode");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         if (not ($result eq SUCCESS)) {
            #push(@result_array, $result);
            $vdLogger->Info("The result is $result"); 
            $returning = $result;
           # foreach my $tmp (@result_array) {
           #    $vdLogger->Info("The array is $tmp");
           # }
         } 
            
         
      } else {
         $tasksObj->QueueTask(functionRef  => $decorator,
                              functionArgs => \@decoratorArgs,
                              outputFile   => undef,
                              taskId       => "$component\.$inventoryIndex");
         $queuedTasks++;
      }
   }
   if ($ENV{VDNET_USE_THREADS}) {
      my $completedThreads = $tasksObj->RunScheduler();
      $vdLogger->Debug("Total queuedTasks $queuedTasks");
      if ($completedThreads eq FAILURE) {
         $vdLogger->Error("Failed to run scheduler to initialize $component");
         VDSetLastError(VDGetLastError());
         $result = FAILURE;
      } elsif ($completedThreads != $queuedTasks) {
         $vdLogger->Error("For $component, number of queued tasks $queuedTasks" .
                          " is not equal to completed tasks $completedThreads");
         #
         # PR 1199274
         # dump memory info for debugging,
         # sometimes thread creation fails
         # due to not enough memory
         #
         VDNetLib::Common::Utilities::CollectMemoryInfo();
         VDSetLastError(VDGetLastError());
        # $result = FAILURE;
         $result = SUCCESS;
         $vdLogger->Debug("StackTrace:\n" .
                           VDNetLib::Common::Utilities::StackTrace());
      } else {
         $result = SUCCESS;
      }
      #
      # create a new handle for the parent process since the control is back from
      # thread to parent process
      #
      if (FAILURE eq $self->UpdateZooKeeperHandle()) {
         $vdLogger->Error("Failed to update zookeeper handle");
         VDSetLastError(VDGetLastError());
         $result = FAILURE;
      }
   }
   if ($result eq SUCCESS) {
      $vdLogger->Info("The return is $returning");
      return $returning;
   }
   return $result;
}


########################################################################
#
# TestbedDecoratorForThreads --
#     This method transforms (similar to decorators in Python)
#     the given function. The usage is specifically for threads
#     which requires zookeeper and inline JVM connections to be
#     re-established.
#
# Input:
#     functionRef : reference to a function to be executed
#     args        : reference to an array of arguments
#
# Results:
#     return value of the given function
#
# Side effects:
#     None
#
########################################################################

sub TestbedDecoratorForThreads
{
   my $self        = shift;
   my $functionRef = shift;
   my $args        = shift;
   my $result = FAILURE;
   @_ = ();
   my $zkh;
   if ($ENV{VDNET_USE_THREADS}) {
      STDOUT->autoflush(1);
      if (FAILURE eq $self->UpdateZooKeeperHandle()) {
         $vdLogger->Error("Failed to update zookeeper handle");
         VDSetLastError(VDGetLastError());
      }
      VDNetLib::InlineJava::VDNetInterface->ReconnectJVM();
   }
   eval {
      $result = &$functionRef(@$args);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while calling thread callback " .
                       "function with return value $result " . $@);
   }
   #
   # error check should be done by caller, since this is generic code
   # and the return value can be different depending on the method
   # being called.
   #
   if ($ENV{VDNET_USE_THREADS}) {
      $self->{zookeeperObj}->CloseSession($self->{zkHandle});
      if ($result eq FAILURE) {
         $vdLogger->Debug("Stack from thread:" . VDGetLastError());
         VDCleanErrorStack();
      }
   }
   return $result;
}


########################################################################
#
# InitializeVSM --
#      Method to initialize the required VSM components.
#
# Input:
#      inventoryIndex : VSM inventory index (Required)
#      vsmSpec : VSM Spec (Required)
#
# Results:
#      "SUCCESS", if the required VSM are
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeVSM
{
   my $self = shift;
   my $vsmSpec = shift;
   my $inventoryIndex = shift;
   my $result = undef;

   $vdLogger->Info("Initializing VSM $inventoryIndex needed ".
		   "for the testcase...");

   my $vsmIP = $vsmSpec->{ip};
   if (not defined $vsmIP) {
      $vdLogger->Error("No IP address is given for vsm: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $vsmSpec->{username} || VDNetLib::Common::GlobalConfig::DEFAULT_VSM_USERNAME;
   my $passwd   = $vsmSpec->{password} || VDNetLib::Common::GlobalConfig::DEFAULT_VSM_PASSWORD;
   my $rootPasswd   = $vsmSpec->{root_password} || VDNetLib::Common::GlobalConfig::DEFAULT_VSM_ROOT_PASSWORD;
   my $upgradeBuild = $vsmSpec->{upgrade_build} || "";
   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error(
		     "Failed to get login credentials for VSM: $inventoryIndex".
		     " Please confirm that VSM is up and credentials ".
		     "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("Found the VSM: $inventoryIndex Credentials: ".
		                 " $username/$passwd");
   my $vsmObj = VDNetLib::VSM::VSMOperations->new(ip => $vsmIP,
                                                  username => $username,
                                                  cert_thumbprint => $vsmSpec->{cert_thumbprint},
                                                  password => $passwd,
                                                  root_password => $rootPasswd,
                                                  upgrade_build => $upgradeBuild);

   if($vsmObj eq FAILURE) {
      $vdLogger->Error("Failed to create VSMOperations object for ".
                       "VSM: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # inventory object will always be stored as x.[x] (e.g. vsm.[x])
   $result = $self->SetComponentObject("vsm.[$inventoryIndex]",
                                       $vsmObj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureVSM--
#      Method to Configure VSM components.
#
# Input:
#      inventoryIndex : VSM inventory index (Required)
#      vsmSpec : VSM Spec (Required)
#
# Results:
#      "SUCCESS", if the required VSM are configured successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub ConfigureVSM
{
   my $self = shift;
   my $vsmSpec = shift;
   my $inventoryIndex = shift;
   my $result = undef;

   my $vsmHash = $vsmSpec;
   delete $vsmHash->{ip};
   delete $vsmHash->{username};
   delete $vsmHash->{password};
   delete $vsmHash->{cert_thumbprint};
   delete $vsmHash->{root_password};

   my $hashSize = keys %$vsmHash;
   if ($hashSize > 0) {
      my $nsxWorkloadObj = $self->{NSXWorkload};
      my $tuple = "vsm.[$inventoryIndex]";
      $vdLogger->Debug("Updating the componentIndex = $tuple of " .
                       "NSXWorkload");
      $nsxWorkloadObj->SetComponentIndex($tuple);

      $result = $self->GetComponentObject("vsm.[$inventoryIndex]");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $vsmObj = $result->[0];
      $result = $nsxWorkloadObj->ConfigureComponent('configHash' => $vsmHash,
                                                    'testObject' => $vsmObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure VSM inventory".
                          " with :". Dumper($vsmHash));
	       VDSetLastError(VDGetLastError());
	       return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeInventory --
#      Method to initialize the required Inventory components.
#
# Input:
#      spec : Inventory specification (Required)
#      inventoryIndex : Inventory index (Required)
#      inventoryName : Inventory name that we specify (Required)
#      module : Module name for the Inventory (Required)
#      workload : Workload name for the Inventory (Required)
#
#
# Results:
#      "SUCCESS", if the required Inventory are
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeInventory
{
   my $self           = shift;
   my $spec           = shift;
   my $inventoryIndex = shift;
   my $inventoryName  = shift;
   my $module         = shift;
   my $workloadName   = shift;

   my $result         = undef;
   $vdLogger->Info("Initializing $inventoryName\.$inventoryIndex needed ".
		   "for the testcase...");

   my $ip = $spec->{ip};
   if ((not defined $ip) && ($inventoryName !~ /testinventory/i)) {
      $vdLogger->Error("No IP address is given for $inventoryName: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $spec->{username};
   my $passwd   = $spec->{password};
   my $cmd_username = $spec->{cmd_username};
   my $cmd_password = $spec->{cmd_password};
   my $root_password = $spec->{root_password};
   my $build   = $spec->{build};
   foreach my $key (%$spec) {
      # Check if -> operator is present
      if  ((defined $spec->{$key}) &&
          ($spec->{$key} =~ /\-\>/)) {
          # Get the workload object to call GetComponenetAttribute
          my $workloadObj = $self->GetWorkloadObject($workloadName);
          my $value = $workloadObj->GetComponentAttribute($spec->{$key},
                                                          undef,
                                                          $key);
          if ($value eq FAILURE) {
              $vdLogger->Error("Failed to fetch value for".
                               "$spec->{$key} for key:$key");
              VDSetLastError(VDGetLastError());
              return FAILURE;
          }
          $vdLogger->Debug("Value for key:$key is $value");
          $spec->{$key} = $value;
      }
   }
   my $ui_ip   = $spec->{ui_ip};
   if (((not defined $username) || (not defined $passwd)) &&
      ($inventoryName !~ /testinventory/i)) {
      $vdLogger->Error(
		     "Failed to get login credentials for $inventoryName: $inventoryIndex".
		     " Please confirm that $inventoryName is up and credentials ".
		     "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ((defined $username) && (not defined $passwd)) {
      $vdLogger->Debug("Found the $inventoryName: $inventoryIndex Credentials:".
		       " $username/$passwd");
   }
   eval "require $module";
   if ($@) {
      $vdLogger->Error("Loading $module failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $obj = $module->new(ip => $ip,
                             username => $username,
                             password => $passwd,
                             cmd_username => $cmd_username,
                             cmd_password => $cmd_password,
                             root_password => $root_password,
                             build => $build,
                             ui_ip => $ui_ip);

   if($obj eq FAILURE) {
      $vdLogger->Error("Failed to create $module object for ".
                       "$inventoryName: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $installType = $spec->{installtype};
   if ((defined $installType) && ($installType eq "nested")) {
      my $nestedHostTuple = $spec->{esx};
      if ((defined $nestedHostTuple)) {
          my $hostObjs = $self->GetComponentObject($nestedHostTuple);
          my $hostObj = $hostObjs->[0];
          my $vmInstance = $spec->{'vmInstance'};
          delete $spec->{'vmInstance'};
          my $vmType = "appliance";
          my $vmObj = $obj->InitNSXApplianceVM($hostObj, $ip, $vmInstance, $vmType);
          $obj = $vmObj;
      } else {
           $vdLogger->Error("Specified installtype as nested, but not specify
               the nested host");
           VDSetLastError("ENOTDEF");
           return FAILURE;
      }
   }

   $inventoryName = lc $inventoryName;
   # inventory object will always be stored as x.[x] (e.g. inventoryobject.[x])
   $result = $self->SetComponentObject("$inventoryName.[$inventoryIndex]",
                                       $obj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $hash = $spec;
   delete $hash->{ip};
   delete $hash->{username};
   delete $hash->{password};
   delete $hash->{cmd_username};
   delete $hash->{cmd_password};
   delete $hash->{root_password};
   delete $hash->{build};
   delete $hash->{installtype};
   delete $hash->{network};
   delete $hash->{ovfurl};
   delete $hash->{esx};
   delete $hash->{kvm};
   return SUCCESS;
}


########################################################################
#
# ConfigureInventory --
#     Method to configure inventory items
#
# Input:
#     named hash with following keys:
#     inventoryName : Name of the inventory
#     inventoryIndex: Current index of the inventory being processed
#     configSpec    : reference to hash containing the configuration
#                     details
#     workloadName  : Name of the Workload module handling the given
#                     inventory item
#
# Results:
#     SUCCESS, if the configuration is done correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureInventory
{
   my $self = shift;
   my %args = @_;
   my $inventoryName = $args{inventoryName};
   my $inventoryIndex = $args{inventoryIndex};
   my $configSpec   = $args{configSpec};
   my $workloadName = $args{workload};


   if (not defined $workloadName) {
      $workloadName = $inventoryName;
   }
   my $tuple = "$inventoryName.[$inventoryIndex]";
   my $inventoryObj = $self->GetComponentObject($tuple);
   if ($inventoryObj eq FAILURE) {
      $vdLogger->Error("Failed to get object for tuple: $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $workloadObj = $self->GetWorkloadObject($workloadName);
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
		    $workloadName . "Workload");
   $workloadObj->SetComponentIndex($tuple);
   my $hashSize = keys %$configSpec;

   if ($hashSize > 0) {
      my $result = $workloadObj->ConfigureComponent(
         'configHash' => $configSpec,
         'testObject' => $inventoryObj->[0]);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure $inventoryName inventory".
                          " with :". Dumper($configSpec));
	       VDSetLastError(VDGetLastError());
	       return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# InitializeTestInventory --
#      Method to initialize the required TestInventory components.
#
# Input:
#      inventorySpec : Inventory specification (Required)
#      inventoryIndex : Inventory index (Required)
#
# Results:
#      "SUCCESS", if the required Inventory are
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeTestInventory
{
   my $self = shift;
   my $inventorySpec = shift;
   my $inventoryIndex = shift;
   my $result = undef;

   $result =  $self->InitializeInventory(
                                         $inventorySpec,
                                         $inventoryIndex,
                                         "testinventory",
                                         "VDNetLib::Infrastructure::TestInventory");
   $result =  $self->ConfigureInventory(
              inventoryName => "testinventory",
              inventoryIndex => $inventoryIndex,
              configSpec => $inventorySpec,
              workload => "TestInventory");
   return $result;
}


########################################################################
#
# InitializeNVPController --
#      Method to initialize the required NVP components.
#
# Input:
#      inventoryIndex : NVP Controller inventory index (Required)
#      nvpControllerSpec : NVP Controller Spec (Required)
#
# Results:
#      "SUCCESS", if the required NVP Controller is
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeNVPController
{
   my $self = shift;
   my $inventoryIndex = shift;
   my $nvpControllerSpec = shift;
   my $result = undef;

   $vdLogger->Info("Initializing NVP Controller needed ".
		   "for the testcase...");

   my $nvpControllerIP = $nvpControllerSpec->{ip};
   if (not defined $nvpControllerIP) {
      $vdLogger->Error("No IP address is given for nvp controller: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $nvpControllerSpec->{username};
   my $passwd   = $nvpControllerSpec->{password};

   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error(
		     "Failed to get login credentials for NVP Controller: $inventoryIndex".
		     " Please confirm that nvp controller is up and credentials ".
		     "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("Found the NVP Controller: $inventoryIndex Credentials: ".
		                 " $username/$passwd");
   my $nvpControllerObj = VDNetLib::NVPController::NVPControllerOperations->new
                                                  (ip => $nvpControllerIP,
                                                  username => $username,
                                                  password => $passwd,
                                                  cert_thumbprint => $nvpControllerSpec->{cert_thumbprint});
   if($nvpControllerObj eq FAILURE) {
      $vdLogger->Error("Failed to create NVPControllerOperations object for ".
                       "NVP Controller: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Setup NVP controller once. Autoload will trigger for this call
   eval{
      $nvpControllerObj->init_nvp_controller($nvpControllerIP);
   };
   if($@){
      $vdLogger->Error("Exception thrown while initializing nvp controller " .
                       $nvpControllerIP." with the following error : ".$@);
      VDSetLastError("EINLINE");
      return FAILURE;
   }


   # inventory object will always be stored as x.[x] (e.g. vsm.[x])
   $result = $self->SetComponentObject("nvpcontroller.[$inventoryIndex]",
                                       $nvpControllerObj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $nvpControllerHash = $nvpControllerSpec;
   delete $nvpControllerHash->{ip};
   delete $nvpControllerHash->{username};
   delete $nvpControllerHash->{password};
   delete $nvpControllerHash->{cert_thumbprint};

   my $nvpControllerWorkloadObj = $self->{NSXWorkload};
   my $tuple = "nvpcontroller.[$inventoryIndex]";
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
		    "NVPControllerWorkload");
   $nvpControllerWorkloadObj->SetComponentIndex($tuple);
   my $hashSize = keys %$nvpControllerHash;
   if ($hashSize > 0) {
      $result = $nvpControllerWorkloadObj->ConfigureComponent('configHash' => $nvpControllerHash,
                                                    'testObject' => $nvpControllerObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure NVP Controller inventory".
                          " with :". Dumper($nvpControllerHash));
	       VDSetLastError(VDGetLastError());
	       return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# InitializeKVM--
#      Method to initialize the required KVM components.
#
# Input:
#      kvmSpec : KVM Spec (Required)
#      inventoryIndex : KVM inventory index (Required)
#
# Results:
#      "SUCCESS", if the required KVM  is initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeKVM
{
   my $self           = shift;
   my $kvmSpec        = shift;
   my $inventoryIndex = shift;
   my $result         = undef;

   $vdLogger->Info("Initializing KVM." . $inventoryIndex .
                   " needed for the testcase...");

   my $kvmIP = $kvmSpec->{ip};
   if (not defined $kvmIP) {
      $vdLogger->Error("No IP address is given for KVM: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $kvmSpec->{username};
   my $passwd   = $kvmSpec->{password};

   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error("Failed to get login credentials for KVM: $inventoryIndex".
         " Please confirm that KVM is up and credentials ".
         "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("User given KVM: $inventoryIndex Credentials: ".
		                 " $username/$passwd");
   my $kvmObj = VDNetLib::Host::HostFactory::CreateHostObject(
                                 hostip => $kvmIP,
                                 hosttype => "kvm",
                                 username  => $username,
                                 password => $passwd,
                                 stafhelper => $self->{stafHelper},
                                 vdnetsrc => $self->{'vdNetSrc'},
                                 vdnetshare => $self->{'vdNetShare'},
                                 vmserver => $self->{vmServer},
                                 vmshare => $self->{vmShare},
                                 sharedstorage => $self->{sharedStorage});
   if($kvmObj eq FAILURE) {
      $vdLogger->Error("Failed to create KVMOperations object for ".
                       "KVM: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Autoload not working for some reason thus calling setup_kvm in new() of kvm
   eval{
      #$kvmObj->setup_kvm($kvmIP);
   };
   if($@){
      $vdLogger->Error("Exception thrown while initializing KVM " .
                       $kvmIP." with the following error : ".$@);
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   # inventory object will always be stored as x.[x] (e.g. vsm.[x])
   $result = $self->SetComponentObject("kvm.$inventoryIndex",
                                       $kvmObj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# ConfigureKVM--
#      Method to configure the required KVM components.
#
# Input:
#      kvmSpec : KVM Spec (Required)
#      inventoryIndex : KVM inventory index (Required)
#
# Results:
#      "SUCCESS", if the required KVM  is initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub ConfigureKVM
{
   my $self           = shift;
   my $kvmSpec        = shift;
   my $inventoryIndex = shift;
   my $hostIndexName  = shift;
   my $result         = undef;
   my $tuple = "$hostIndexName.[$inventoryIndex]";
   my $kvmHash = $kvmSpec;
   delete $kvmHash->{ip};
   delete $kvmHash->{username};
   delete $kvmHash->{password};
   my $compObjs = $self->GetComponentObject($tuple);
   my $kvmObj = $compObjs->[0];
   my $kvmWorkloadObj = $self->GetWorkloadObject("Host");
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
		    "HostWorkload");
   $kvmWorkloadObj->SetComponentIndex($tuple);
   my $hashSize = keys %$kvmHash;
   if ($hashSize > 0) {
      $result = $kvmWorkloadObj->ConfigureComponent('configHash' => $kvmHash,
                                                    'testObject' => $kvmObj,
                                                    'testHost' => $tuple);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure KVM inventory".
                          " with :". Dumper($kvmHash));
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# InitializeNeutron
#      Method to initialize the required Neutron components.
#
# Input:
#      inventoryIndex : Neutron node inventory index (Required)
#      NeutronSpec : Neutron node Spec (Required)
#
# Results:
#      "SUCCESS", if the required Neutron node is
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeNeutron
{
   my $self = shift;
   my $inventoryIndex = shift;
   my $neutronSpec = shift;
   my $result = undef;

   $vdLogger->Info("Initializing Neutron Node needed ".
		   "for the testcase...");

   my $neutronIP = $neutronSpec->{ip};
   if (not defined $neutronIP) {
      $vdLogger->Error("No IP address is given for neutron node: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $neutronSpec->{username};
   my $passwd   = $neutronSpec->{password};

   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error(
		     "Failed to get login credentials for Neutron Node: $inventoryIndex".
		     " Please confirm that neutron node is up and credentials ".
		     "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("Found the Neutron node: $inventoryIndex Credentials: ".
		                 " $username/$passwd");

   my $neutronObj = VDNetLib::Neutron::NeutronOperations->new
                                                  (ip => $neutronIP,
                                                  cert_thumbprint => $neutronSpec->{cert_thumbprint},
                                                  username => $username,
                                                  password => $passwd);

   if($neutronObj eq FAILURE) {
      $vdLogger->Error("Failed to create NeutronOperations object for ".
                       "Neutron Node: $inventoryIndex");
      $vdLogger->Error("Neutron Spec = " . Dumper($neutronSpec));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # inventory object will always be stored as x.[x] (e.g. vsm.[x])
   $result = $self->SetComponentObject("neutron.[$inventoryIndex]",
                                       $neutronObj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $neutronHash = $neutronSpec;
   delete $neutronHash->{ip};
   delete $neutronHash->{username};
   delete $neutronHash->{password};
   delete $neutronHash->{cert_thumbprint};

   my $neutronWorkloadObj = $self->{NSXWorkload};
   my $tuple = "neutron.[$inventoryIndex]";
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
		    "NeutronWorkload");
   $neutronWorkloadObj->SetComponentIndex($tuple);
   my $hashSize = keys %$neutronHash;
   if ($hashSize > 0) {
      $result = $neutronWorkloadObj->ConfigureComponent('configHash' => $neutronHash,
                                                    'testObject' => $neutronObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure Neutron inventory".
                          " with :". Dumper($neutronHash));
	       VDSetLastError(VDGetLastError());
	       return FAILURE;
      }
   }
   return SUCCESS;
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
   $vdLogger->Info("Bringing $vmOpsObj->{vmIP} down to update vmx file");
   if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
      $vdLogger->Error( "Powering off VM failed");
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
   my $newIP = VDNetLib::Common::Utilities::GetGuestControlIP($vmOpsObj,
                                                              $controlMAC);
   if ($newIP eq FAILURE) {
      $vdLogger->Error("Failed to get $vmOpsObj->{vmx} ip address");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ($vmOpsObj->{vmIP} ne $newIP) {
      # Update control IP address if there is any change.
      $vmOpsObj->{vmIP} = $newIP;
   }

   $vdLogger->Info("Waiting for STAF on $vmOpsObj->{vmIP} to come up");
   $ret = $self->{stafHelper}->WaitForSTAF($vmOpsObj->{vmIP});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Info("STAF is not running on $vmOpsObj->{vmIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# CheckupAndRecoveryOnInventory --
#     This method is thread callback function for health check up and recovery
#
# Input:
#      inventorySpec : Inventory Spec (Optional)
#      inventoryIndex: Inventory index
#      inventoryName: Inventory Name
#
# Results:
#     SUCCESS, if check health and recovery  successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CheckupAndRecoveryOnInventory
{
   my $self = shift;
   my $nventorySpec = shift;
   my $inventoryIndex = shift;
   my $inventoryName = shift;
   my $result = FAILURE;

   my $component = $inventoryName . ".[" . $inventoryIndex . "]";

   $result = $self->GetComponentObject($component);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get component object $component");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $componentObj = $result->[0];
   if (not defined $componentObj->can("HealthCheckupAndRecovery")) {
       $vdLogger->Info("There is no health check functions for $component");
       return SUCCESS;
   }
   $result = $componentObj->HealthCheckupAndRecovery();
   if (($result eq FAILURE) || ($result eq VDNetLib::Common::GlobalConfig::FALSE)) {
      $vdLogger->Error("Health check return failure for inventory $component");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# HealthCheckupAndRecovery
#     Check up and recovery for all the inventories using threads.
#
# Input:
#     timeout    : max timeout for each inventory
#
# Results:
#     SUCCESS, if check health and recovery  successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub HealthCheckupAndRecovery
{
   my $self          = shift;
   my $result;
   my $testbedSpec = $self->{'testbedSpec'};
   my @componentArray = qw (host esx vm kvm nsxmanager);

   if (not defined $testbedSpec) {
      $vdLogger->Warn("Testbed spec is not defined");
      return SUCCESS;
   }
   my $functionRef = sub {$self->CheckupAndRecoveryOnInventory(@_)};
   foreach my $oneComponent (keys %$testbedSpec) {
      if (!(grep(/^$oneComponent$/, @componentArray))) {
         next;
      }
      $result = $self->InitializeUsingThreads($functionRef, $oneComponent);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to do health check and recovery on $oneComponent.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Health check and recovery is complete on $oneComponent");
   }
   return SUCCESS;
}

########################################################################
#
# InitializeAuthServer --
#      Method to initialize the required AuthServer components.
#
# Input:
#      inventoryIndex : AuthServer inventory index (Required)
#      authserverSpec : AuthServer Spec (Required)
#
# Results:
#      "SUCCESS", if the required AuthServer
#                 initialized successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeAuthServer
{
   my $self = shift;
   my $inventoryIndex = shift;
   my $authserverSpec = shift;
   my $result = undef;

   $vdLogger->Info("Initializing AuthServer needed ".
           "for the testcase...");

   my $authserverIP = $authserverSpec->{ip};
   if (not defined $authserverIP) {
      $vdLogger->Error("No IP address is given for authserver: $inventoryIndex");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $username = $authserverSpec->{user} || VDNetLib::Common::GlobalConfig::DEFAULT_AUTHSERVER_USERNAME;
   my $passwd   = $authserverSpec->{password} || VDNetLib::Common::GlobalConfig::DEFAULT_AUTHSERVER_PASSWORD;

   if ((not defined $username) || (not defined $passwd)) {
      $vdLogger->Error(
             "Failed to get login credentials for AuthServer: $inventoryIndex".
             " Please confirm that AuthServer is up and credentials ".
             "are set to one of the default username/password.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("Found the AuthServer: $inventoryIndex Credentials: ".
                         " $username/$passwd");

   my $authserverObj = VDNetLib::AuthServer::AuthServer->new(ip => $authserverIP,
                                                  username => $username,
                                                  password => $passwd);

   if($authserverObj eq FAILURE) {
      $vdLogger->Error("Failed to create AuthServerOperations object for ".
                       "AuthServer: $inventoryIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # inventory object will always be stored as x.[x] (e.g. authserver.[x])
   $result = $self->SetComponentObject("authserver.[$inventoryIndex]",
                                       $authserverObj);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $authserverHash = $authserverSpec;
   delete $authserverHash->{ip};
   delete $authserverHash->{username};
   delete $authserverHash->{password};

   my $authserverWorkloadObj = $self->GetWorkloadObject("AuthServer");

   my $tuple = "authserver.[$inventoryIndex]";
   $vdLogger->Debug("Updating the componentIndex = $tuple of " .
            "AuthServerWorkload");
   $authserverWorkloadObj->SetComponentIndex($tuple);
   my $hashSize = keys %$authserverHash;
   if ($hashSize > 0) {
      $result = $authserverWorkloadObj->ConfigureComponent('configHash' => $authserverHash,
                                                    'testObject' => $authserverObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure AuthServer inventory".
                          " with :". Dumper($authserverHash));
           VDSetLastError(VDGetLastError());
           return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# CleanupNSXManager--
#      This method cleans everything configured on NSX Manager
#      for the given test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the NSX components are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
#########################################################################

sub CleanupNSXManager
{
   my $self = shift;
   my $error = 0;
   my $result;

   my $componentArray = $self->GetComponentObject("nsxmanager.[-1]");
   if ($componentArray eq FAILURE) {
      $vdLogger->Error("Failed to get nsx manager objects from Testbed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (scalar(@$componentArray) == 0) {
      $vdLogger->Info("No NSX managers initialized to cleanup");
      return SUCCESS;
   }
   #Since the logicalports have been cleaned up when removing the vnic,
   #skip the cleanup of logicalports here
   my @componentList = ('logicalport', 'logicalrouterport', 'logicalrouter',
                        'logicalswitch', 'transportnode', 'fabrichost',
                        'uplinkprofile', 'transportzone');
   my $nsxConfigHash = {
      deletelistofcomponents => \@componentList,
   };
   $result = $self->CleanupInventory('inventoryTuple' => 'nsxmanager.[-1]',
                                     'configSpec'     => $nsxConfigHash,
                                     'workloadName'   => 'NSX',
                                     'componentList'  => \@componentList);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure during one or more nsx Transformer component cleanup");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info("Cleanup NSX Manager for Transformer Successfull");
   return SUCCESS;
}

########################################################################
#
# CleanupInventory --
#      This method cleans the subcomponents on inventory
#
# Input:
#      named hash with following keys:
#      inventoryTuple : tuple of the inventory
#      configSpec : ref to hash containing the subcomponents to
#                   be cleaned up from the inventory
#      workloadName : the workload name for the test component
#
# Results:
#      "SUCCESS", if the subcomponents are cleaned successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
#########################################################################

sub CleanupInventory
{
   my $self           = shift;
   my %args           = @_;
   my $inventoryTuple = $args{inventoryTuple};
   my $configSpec     = $args{configSpec};
   my $workloadName   = $args{workloadName};
   my $componentList   = $args{componentList};
   my $error = 0;
   my $result;

   # clean subcomponents
   my $allInventoryTuples = $self->GetAllComponentTuples($inventoryTuple);
   foreach my $tuple (@$allInventoryTuples) {
      $vdLogger->Info("Cleaning up for tuple: $tuple");
      my $childIndexes = $self->GetChildren($tuple);
      if ($childIndexes eq FAILURE) {
         $vdLogger->Error("Failed to get child nodes of $tuple");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $empty = VDNetLib::Common::GlobalConfig::TRUE;
      # check if there is at least one sub-component available to clean
      foreach my $subComponent (@$childIndexes) {
         # check if the sub-component is in the list to clean
         my @arr = split('\.' ,$subComponent);
         $vdLogger->Debug("The current subcomponent is $arr[2]");
         if (grep /$arr[2]/, @$componentList) {
            $vdLogger->Debug("The current subcomponent is
                              in the removing list");
            if (scalar (@{$self->GetAllComponentTuples($subComponent)})) {
               $empty = VDNetLib::Common::GlobalConfig::FALSE;
               last;
            }
         }
      }
      if ($empty) {
         $vdLogger->Info("No components available to cleanup for $tuple");
         next;
      }

      my $ref = $self->GetComponentObject($tuple);
      my $inventoryObj = $ref->[0];
      if ($inventoryObj eq FAILURE) {
         $vdLogger->Error("Failed to get object for tuple: $tuple");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $workloadObj = $self->GetWorkloadObject($workloadName);
      $workloadObj->SetComponentIndex($tuple);
      $result = $workloadObj->ConfigureComponent(configHash => $configSpec,
                                                 testObject => $inventoryObj,
                                                 tuple      => $tuple);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failure during $tuple Cleanup");
         VDSetLastError("EFAIL");
         $error++;
      }
   }

   if (!$error) {
      $vdLogger->Info("Cleanup $inventoryTuple Successfull");
      return SUCCESS;
   } else {
      $vdLogger->Error("Failure during one or more $inventoryTuple cleanup");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# CollectAllLogs --
#     Method to do log collection
#
# Input:
#     ignoreFlag: true or false. If true, always collect log without
#         checking the flag 'areLogsCollected' (optional) by default it is false
#     logDir: log directory user wants logs to be saved into (optional)
#
# Results:
#     SUCCESS: If log collection succeeds
#     FAILURE: If error happens
#
# Side effects:
#     None
#
########################################################################

sub CollectAllLogs
{
   my $self = shift;
   my $ignoreFlag = shift || FALSE;
   my $logDir = shift;
   # $self->{logCollector}->{logDir} is current log directory,
   # in case caller wants to save all logs into another directory, it can pass
   # new log dir as second parameter. This new log dir will be used in
   # function $self->{logCollector}->CollectLog().
   # After it, we restore $self->{logCollector}->{logDir} to previous value
   my $oldDir = $self->{logCollector}->{logDir};

   my $result = FAILURE;

   if (($self->{areLogsCollected} == TRUE) && ($ignoreFlag == FALSE)) {
      $vdLogger->Debug("Log collection is already done");
      return SUCCESS;
   }
   eval {
      if (defined $logDir) {
         $self->{logCollector}->{logDir} = $logDir;
      }
      $result = $self->{logCollector}->CollectLog("all");
      $self->{logCollector}->{logDir} = $oldDir;
   };
   if ($@) {
      $self->{logCollector}->{logDir} = $oldDir;
      $vdLogger->Error("Exception thrown while collecting log " . Dumper($@));
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   if ($result eq FAILURE) {
      $vdLogger->ERROR("Failed to collect logs");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   $self->SetLogCollectionFlag(TRUE);
   return SUCCESS;
}


########################################################################
#
# SetLogCollectionFlag --
#     Method to set $self->{areLogsCollected}
#
# Input:
#     areLogsCollected: TRUE or FALSE to indicate log collected or not
#
# Results:
#     SUCCESS: If areLogsCollected set
#     FAILURE: If error happens
#
# Side effects:
#     None
#
########################################################################

sub SetLogCollectionFlag
{
   my $self = shift;
   my $areLogsCollected = shift;
   my $operatorObj = VDNetLib::Common::Operator->new();

   if ($operatorObj->Boolean(undef, $areLogsCollected) eq FAILURE) {
      $vdLogger->ERROR("areLogsCollected should be set to TRUE or FALSE");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $self->{areLogsCollected} = $areLogsCollected;
   return SUCCESS;
}

1;
