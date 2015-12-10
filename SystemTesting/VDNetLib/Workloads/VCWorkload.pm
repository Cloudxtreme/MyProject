##############################################################################
#
# Copyright (C) 2010 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::VCWorkload;
# This package is used to run VC workload that involves
#
#    -- Add/Remove datacenter
#    -- Add/Remove Folder
#    -- Add/Remove hosts into datacenter
#    -- Add/Remove VDS
#    -- Add/Remove upliks from VDS
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VC::VCOperation object will be created in new function
# In this way, all the VC workloads can be run parallelly with no
# reentrant issue.
#
###############################################################################

package VDNetLib::Workloads::VCWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::VC::VCOperation;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::VCWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::VCWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

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
      'targetkey'    => "testvc",
      'componentIndex' => undef,
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


###############################################################################
#
# StartWorkload --
#      This method will process the workload hash of type 'VC'
#      and execute necessary operations (executes host related
#      methods mostly from VDNetLib::VC::VCOperation.pm).
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
###############################################################################

sub StartWorkload {
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};
   my $vc = undef;
   my @params = ();
   my $method;
   my @vdsnames = ();

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);

   if ($dupWorkload->{'type'} !~ /vc/i) {
      $vdLogger->Error("This is not a vc workload:" . $dupWorkload->{'type'});
      VDSetLastError("EINVALID");
      return "FAIL";
   }

   my $iterations = $dupWorkload->{'iterations'};
   if (not defined $iterations) {
      $iterations = 1;
   }
   # Determine the target on which the VC operation should be launched.
   my $opt = $dupWorkload->{'opt'};
   if ((not defined $opt) && ($self->{testbed}{version} == 1)) {
      $vdLogger->Error("This is no operation command");
      VDSetLastError("EINVALID");
      return "FAIL";
   }

   # Get the function name and parameters
   my $sleepBetweenCombos = $dupWorkload->{'sleepbetweencombos'};

   my $testVC = $dupWorkload->{'testvc'};

   if ((not defined $testVC) && ($self->{testbed}{version} == 1)) {
      my $target;
      if ((defined $target) && ($target ne "ARRAY")) {
         $target = $dupWorkload->{hosts};
      } else {
         $target = "SUT";
      }
      $testVC = $self->GetListOfTuples($target, "vc");
   }

   my @mgmtKeys = ('type', 'iterations', 'target', 'testvc','expectedresult');
   foreach my $key (@mgmtKeys) {
      delete $dupWorkload->{$key};
   }

   $vdLogger->Info("Number of Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");
      my @arrayVC = split($self->COMPONENT_DELIMITER, $testVC);
      my @newArray = ();
      foreach my $vcTuple (@arrayVC) {
         my $refArray = $self->{testbed}->GetAllComponentTuples($vcTuple);
         if ($refArray eq FAILURE) {
            $vdLogger->Error("Failed to get component tuples for $vcTuple");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
         push @newArray, @$refArray;
      }
      foreach my $vc (@newArray) {
         $vc =~ s/\:/\./g;
         $self->SetComponentIndex($vc);
         my $result = $self->ConfigureComponent(configHash => $dupWorkload,
                                                tuple      => $vc);
         if ($result eq FAILURE) {
            $vdLogger->Error("Start Workload failed");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
      } #end of @arrayVC loop
   } #end of iterations loop
   return "PASS";
}


###############################################################################
#
# ConfigureComponent --
#      This method is to perform any cleanup of HostWorkload,
#      if needed. This method should be defined as it is a required
#      interface for VDNetLib::Workloads.
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
###############################################################################

sub ConfigureComponent
{
   my $self = shift;
   my %args        = @_;
   my $dupWorkload = $args{configHash};
   my $testVC      = $args{tuple};
   my $vcObject    = $args{testObject};

   if (not defined $vcObject) {
      my $ref = $self->GetVCObjects($testVC);
      $vcObject = $ref->[0];
      if ((not defined $vcObject) || (not defined $dupWorkload)) {
         $vdLogger->Error("VC Operation object and/or config hash not provided");
         $vdLogger->Error("vc object:$vcObject  hash: $dupWorkload");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   my $testbed = $self->{testbed};
   my $iteratorObj = VDNetLib::Common::Iterator->new(workloadHash => $dupWorkload);


   my $configCount = 1;
   # NextCombination() method gives the first combination of keys
   my %vcOps = $iteratorObj->NextCombination();
   my $vcOpsHash = \%vcOps;
   while (%vcOps) {
      $vdLogger->Info("Working on configuration set $configCount");
      $vdLogger->Info(Dumper($vcOpsHash));
      $vdLogger->Info("Running VC workload on vc $testVC");

      # For ver2 we will call the ConfigureComponent from parent class first.
      my $result = $self->SUPER::ConfigureComponent('configHash' => $dupWorkload,
                                                    'testObject' => $vcObject);

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
      # of the KEYSDATABASE, so the VCWorkload's
      # ConfigureComponent will try to confgure the key.

      $result = undef;
      $result = $self->Dispatch($vcObject, $dupWorkload, $testVC);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
        return FAILURE;
      }
      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #
      %vcOps = $iteratorObj->NextCombination();
      $configCount++;
   }
   return SUCCESS;
}


###############################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of HostWorkload,
#      if needed. This method should be defined as it is a required
#      interface for VDNetLib::Workloads.
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
###############################################################################

sub CleanUpWorkload {
   my $self = shift;
   # TODO - there is no cleanup required as of now. Implement any
   # cleanup operation here if required in future.
   return "PASS";
}


###############################################################################
#
# dispatch --
#      This method will return calling function name and parameters according
#      "OPT" value.
#
# Input:
#      OPT      -- operation name can be one of following options.
#       * connect    -  connect with VC server, create anchor in STAF service
#       * adddc      -  create a new datacenter.
#       * removedc   -  remove a given datacenter.
#       * addfolder  -  create a new directory.
#       * removefolder - remove a given folder.
#       * createvds   - create a new VDS.
#       * checkpools  - check the system static pools in an ESX host (NetIORMv2)
#      workload -- duplicate workload
#
# Results:
#     (function name, parameters array)
#
# Side effects:
#     None
#
###############################################################################

sub Dispatch {
   my $self        = shift;
   my $vcObj       = shift;
   my $dupWorkload = shift;
   my $testVC      = shift;
   my $testbed     = $self->{testbed};
   my $opt         = $dupWorkload->{'opt'};


   #Find DC Name
   my $dcname;
   if (defined $dupWorkload->{dcname}) {
      $dcname = $dupWorkload->{dcname};
   } else {
      $dcname = $vcObj->{'datacenter'} || undef;
   }

   if (defined $dupWorkload->{datacenter}) {
      my $dcObject = $self->GetOneObjectFromOneTuple($dupWorkload->{datacenter});
      $dcname  = $dcObject->{'datacentername'};
   }

   # Initialize common variables in the begining
   my $foldername = $dupWorkload->{'foldername'} || undef;

   # Find VM Object if defined
   my $testVM;
   if (defined $dupWorkload->{testvm}) {
      $testVM = $dupWorkload->{testvm};
   } elsif ((defined $dupWorkload->{hosts}) &&
            ($dupWorkload->{hosts} ne "ARRAY")) {
      $testVM = $dupWorkload->{hosts};
   } elsif (defined $dupWorkload->{host}){
      $testVM = $dupWorkload->{host};
   } elsif (defined $dupWorkload->{vm}){
      $testVM = $dupWorkload->{vm};
   } else {
      $testVM = "SUT";
   }
   my $target = $testVM;
   my ($vmObj,$refVMObj);
   if ((defined $testVM) && ($self->{testbed}{version} == 1)) {
      $testVM = $self->GetListOfTuples($testVM, "vm");
   }

   # Find VDS Name
   my $testSwitch;
   my $vdsname;
   if (defined $dupWorkload->{'vdsname'}) {
      if ($dupWorkload->{'vdsname'} =~ /^\d+$/) {
         $testSwitch = $dupWorkload->{'vdsname'};
      } else {
         $vdsname = $dupWorkload->{'vdsname'};
      }
   } elsif (defined $dupWorkload->{'vds'}) {
      $testSwitch = $dupWorkload->{'vds'};
   } elsif (defined $dupWorkload->{vdsindex}){
      $testSwitch = $dupWorkload->{vdsindex};
   } elsif (defined $dupWorkload->{'testswitch'}) {
      $testSwitch = $dupWorkload->{'testswitch'}
   } else {
      $testSwitch = undef;
   }


   if ($dupWorkload->{opt} =~ /VXLANTSAMCheck/i) {
      $vdLogger->Debug("We dont find switch object if opt is VXLANTSAMCheck");
   } elsif (defined $testSwitch) {
      my $refSwitch = $self->GetSwitchNames($testSwitch, $target);
      $vdsname = join (',', @$refSwitch);
   }

   # Find Host Object reference for the given tuple/machine

   my $testHost = $dupWorkload->{'testhost'};
   if ($self->{testbed}{version} == 1) {
      if (not defined $testHost) {
         $testHost = $target;
      } elsif ((defined $dupWorkload->{hosts}) &&
            ($dupWorkload->{hosts} ne "ARRAY")) {
         $testHost = $self->GetListOfTuples($dupWorkload->{hosts}, "host");
      } elsif ((defined $dupWorkload->{hosts}) &&
            ($dupWorkload->{hosts} eq "ARRAY")) {
         $testHost = undef;
         my @hostArray;
         foreach my $host (@$dupWorkload->{hosts}) {
            push (@hostArray, $self->GetListOfTuples($host, "host"));
         }
         $testHost = join (',', @hostArray);
      }
   }

   my $refHostObj;
   my $hostObj;
   my $hostIP;
   if (defined $testHost) {
      my @testHostArray = split(/,/, $testHost);
      my @arrayHostObj;
      foreach my $hostTuple (@testHostArray) {
         my $ref = $self->GetHostObjects($hostTuple);
         push (@arrayHostObj, $ref->[0]);
      }
      $refHostObj = \@arrayHostObj;
      $hostObj = $refHostObj->[0];
      $hostIP = $hostObj->{hostIP};
   }

   my $refDestHostObj;
   my $destHostObj;
   if ((defined $dupWorkload->{opt}) &&
      ($dupWorkload->{opt} eq "createprofile")) {
      my $testDstHost = $dupWorkload->{dsthost};
      $refDestHostObj = $self->GetHostObjects($testDstHost);
      $destHostObj = $refDestHostObj->[0];
   }

   # Find portgroup name
   my $testPG;
   my $pgname;
   if (defined $dupWorkload->{pgname}) {
      if ($dupWorkload->{pgname} =~ /^\d+$/) {
         $testPG = $dupWorkload->{pgname};
      } else {
         $pgname = $dupWorkload->{pgname};
      }
   } elsif ($dupWorkload->{dvportgroupname}) {
      if ($dupWorkload->{dvportgroupname} =~ /^\d+$/) {
         $testPG = $dupWorkload->{dvportgroupname};
      } else {
         $pgname = $dupWorkload->{dvportgroupname};
      }
   } elsif (defined $dupWorkload->{portgroup}){
      $testPG = $dupWorkload->{portgroup};
   } elsif (defined $dupWorkload->{testpg}){
      $testPG = $dupWorkload->{testpg};
   } elsif (defined $dupWorkload->{portgroupname}) {
      $testPG = $dupWorkload->{portgroupname};
   } else {
      $testPG = undef
   }

   if (defined $testPG) {
      my $refPGNames = $self->GetPortGroupNames($testPG,$target);
      $pgname = $refPGNames->[0];
   }

   my $nrpname = $dupWorkload->{'nrpname'} || undef;
   my @params;
   my %paramhash;
   my $method;


   # Dispatch each "OPT" to cooperated VCoperation function.
   # Connect to VC
   if ( $opt eq "connect") { #TODOver2 handle event
      $method = 'ConnectVC';
      push(@params, $testbed);
   }
   # Add new dc in VC
   if ( $opt eq "adddc" ) {
      $method = 'CreateDCWithHosts';
      push(@params, $dcname);
      push(@params, $refHostObj);
   }
   # Remove dc from VC
   if ( $opt eq "removedc" ) {
      $method = 'RemoveDC';
      push(@params, $dcname);
   }
   # Add new folder in VC
   if ( $opt eq "addfolder" ) {
      $method = 'AddFolder';
      push(@params, $foldername );
   }
   # Delete specified folder in VC
   if ( $opt eq "removefolder" ) {
      $method = 'RemoveFolder';
      push(@params, $foldername );
   }
   # Add new VDS in VC
   if ( $opt eq "createvds" ) {
      $method = 'CreateVDS';
      push(@params, $dcname);
      push(@params, $vdsname);
      my $refFreePnic = $self->GetUplinkObjects($dupWorkload->{'uplink'});
      push(@params, $refFreePnic);
      push(@params, $refHostObj);
   }
   if ( $opt eq "checkpools" ) {
      $method = 'CheckPools';
       push(@params, $hostIP);
       if (defined $dupWorkload->{'nrpname'}) {
          push(@params, $dupWorkload->{'nrpname'});
       }
       if (defined $dupWorkload->{'exist'}) {
          push(@params, $dupWorkload->{'exist'});
       }
   }
   if ( $opt eq "addnrp" ) {
      $method = 'AddNRP';
      push(@params, $vdsname);
      push(@params, $nrpname);
      push(@params, $dupWorkload->{'nrplimit'});
      push(@params, $dupWorkload->{'nrp8021ptag'});
      push(@params, $dupWorkload->{'nrpshare'});
      push(@params, $dupWorkload->{'nrpnumber'});
   }
   if ( $opt eq "updatenrp" ) {
      $method = 'UpdateNRP';
      push(@params, $vdsname);
      push(@params, $nrpname);
      push(@params, $dupWorkload->{'nrplimit'});
      push(@params, $dupWorkload->{'nrp8021ptag'});
      push(@params, $dupWorkload->{'nrpshare'});
   }
   if ( $opt eq "deletenrp" ) {
      $method = 'DelNRP';
      push(@params, $vdsname);
      push(@params, $nrpname);
   }
   if ( $opt eq "delsystemnrp" ) {
      $method = 'DelSystemNRP';
      push(@params, $vdsname);
   }
   if ( $opt eq "resetnetiormcounter" ) {
      $method = 'ResetNetIORMCounter';
      push(@params, $vdsname);
      push(@params, $hostIP);
      push(@params, $dupWorkload->{'check'});
   }
   if ( $opt eq "addhosttovds" ) {
      $method = 'AddHostToVDS';
      $dcname = $dupWorkload->{'dcname'};
      $vdsname = $dupWorkload->{'vdsname'};
      if (!defined $vdsname){
         $vdsname = $self->GetVDSNameByIndex($testbed,
                                             $dupWorkload->{'vdsindex'});
      }
      push(@params, $dcname);
      my $host = $dupWorkload->{'hosts'};
      push(@params, $hostIP);
      push(@params, $vdsname);
   }
   if ( $opt eq "netiormverify" ) {
      $method = 'NetIORMVerify';
      push(@params, $vdsname);
      push(@params, $hostIP);
      push(@params, $dupWorkload->{'sharecheck'});
      push(@params, $dupWorkload->{'limitcheck'});
      push(@params, $dupWorkload->{'limitduration'});
      push(@params, $dupWorkload->{'optout'});
      push(@params, $dupWorkload->{'lbt'});
      push(@params, $dupWorkload->{'rotateonfail'});
      push(@params, $dupWorkload->{'precedence'});
      push(@params, $dupWorkload->{'map8021p'});
   }
   if ( $opt eq "adduplink" ) {
      $method = 'AddUplink';
      my $uplink = $dupWorkload->{'uplink'}; #Uplink number is count
      if ((defined $dupWorkload->{'vdsname'}) && ($dupWorkload->{'vdsname'} =~ /^\d+/)) {
         if ($self->{testbed}{version} == 1) {
            my ($target, $nic) = split(/::/,$uplink);
            my $ref =$self->GetSwitchNames($dupWorkload->{'vdsname'}, $target);
            $vdsname = $ref->[0];
         }
      }
      my $refFreePnic = $self->GetUplinkObjects($dupWorkload->{'uplink'});
      push(@params, $vdsname);
      push(@params, $refFreePnic);
   }
   if ( $opt eq "removeuplink" ) {
      $method = 'RemoveUplink';
      my $uplink = $dupWorkload->{'uplink'}; #Uplink number is index
      my $host = $dupWorkload->{'host'};
      my $tupleRemoveUplink;
      if ((defined $dupWorkload->{'vdsname'}) && ($dupWorkload->{'vdsname'} =~ /^\d+/)) {
         if ($self->{testbed}{version} == 1) {
            my ($target, $nic) = split(/::/,$uplink);
            my $ref =$self->GetSwitchNames($dupWorkload->{'vdsname'}, $target);
            $vdsname = $ref->[0];
         }
      }
      if ($self->{testbed}{version} == 1) {
         my ($target, $nic) = split(/::/,$dupWorkload->{'uplink'});
         $tupleRemoveUplink = "$target:vmnic:$nic";
      } else {
         $tupleRemoveUplink = $dupWorkload->{'uplink'};
      }
      my $args;
      my @uplinkArry;
      my $refRemovePnic = $self->GetNetAdapterObject('testAdapter' => $tupleRemoveUplink);
      my $netObj = $refRemovePnic->[0];
      my $removeUplink = $netObj->{interface};
      $vdLogger->Info("Removing the uplink $removeUplink");
      push(@params, $vdsname);
      push(@params, $hostIP);
      push(@params, $removeUplink);
    }
   if ( $opt eq "optout" ) {
      $method = 'OptOut';
      push(@params, $vdsname);
      push(@params, $hostIP);
      push(@params, $dupWorkload->{'value'});
   }

   # create CHF Instance for vds on VC
   if ( $opt eq "createChfInstance" ) {
      $method = 'CreateChfInstance';
      push(@params, $vdsname);
   }
   # Remove CHF Instance for vds on VC
   if ( $opt eq "removeChfInstance" ) {
      $method = 'RemoveChfInstance';
      push(@params, $vdsname);
   }
   # Add CHF ID for vds in VC
   if ( $opt eq "addFenceId" ) {
      $method = 'AddFenceId';
      my $fenceid = $dupWorkload->{'fenceid'};
      push(@params, $vdsname);
      push(@params, $pgname);
      push(@params, $fenceid);
   }
   # Delete CHF ID for vds in VC
   if ( $opt eq "deleteFenceId" ) {
      $method = 'DeleteFenceId';
      push(@params, $vdsname);
      push(@params, $pgname);
   }
   # Change CHF ID for vds in VC
   if ( $opt eq "changeFenceId" ) {
      $method = 'ChangeFenceId';
      my $changetimes = $dupWorkload->{'changetimes'};
      push(@params, $vdsname);
      push(@params, $pgname);
      push(@params, $changetimes);
   }
   # Enable broadcast containment for vds in VC
   if ( $opt eq "enableBC" ) {
      $method = 'EnableBC';;
      push(@params, $vdsname);
      push(@params, $pgname);
   }
   # Disable broadcast containment for vds in VC
   if ( $opt eq "disableBC" ) {
      $method = 'DisableBC';
      push(@params, $vdsname);
      push(@params, $pgname);
   }
   # VXLAN TSAM test case
   if ( $opt eq "VXLANTSAMCheck" ) { #TODOver2-sit with stanley
      if (! exists $dupWorkload->{'method'}) {
         $vdLogger->Error("Must provide Method input.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $method = $dupWorkload->{'method'};
      if (! exists $dupWorkload->{'testswitch'}) {
         $vdLogger->Error("Must provide testswitch input.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      # testswitch must have 2 parameters, such as: 1,2
      my @vdsIndexs = split(';;',$dupWorkload->{'testswitch'});
      my $vdsIndexsNo = scalar(@vdsIndexs);
      if ($vdsIndexsNo != 2) {
         $vdLogger->Error("testswitch must provide 2 parameters");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my ($vdsIndex1, $vdsIndex2) = @vdsIndexs;
      my $refSwitch1 = $self->GetSwitchNames($vdsIndex1);
      my $vdsName1 = $refSwitch1->[0];
      my $refSwitch2 = $self->GetSwitchNames($vdsIndex2);
      my $vdsName2 = $refSwitch2->[0];
      if (! exists $dupWorkload->{'testhost'}) {
         $vdLogger->Error("Must provide hosts list input.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my @hosts = split(';;',$dupWorkload->{'testhost'});
      my $hostsNo = scalar(@hosts);
      if ($hostsNo != 2) {
         $vdLogger->Error("hosts must provide 2 parameters");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my ($hostName1, $hostName2) = @hosts;
      my $ref1 = $self->GetHostObjects($hostName1);
      my $hostObj1 = $ref1->[0];
      my $hostIp1 = $hostObj->{hostIP};

      my $ref2 = $self->GetHostObjects($hostName2);
      my $hostObj2 = $ref2->[0];
      my $hostIp2 = $hostObj2->{hostIP};

      if (! exists $dupWorkload->{'vlan'}) {
         $vdLogger->Error("Must provide vlan id input.");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $vlanId = $dupWorkload->{'vlan'};
      my $mtu = $dupWorkload->{'mtu'};
      my %paramhash;
      $paramhash{vdsName1} = $vdsName1;
      $paramhash{vdsName2} = $vdsName2;
      $paramhash{hostIp1}  = $hostIp1;
      $paramhash{hostIp2}  = $hostIp2;
      if (exists $dupWorkload->{'vlan'}) {
         $paramhash{vlanId} = $dupWorkload->{'vlan'};
      }
      if (exists $dupWorkload->{'mtusize'}) {
         $paramhash{mtuSize} = $dupWorkload->{'mtusize'};
      }
      # multicast domain check need muticast ip and expectResponseNo
      if (exists $dupWorkload->{'mcastip'}) {
         $paramhash{multicastIp} = $dupWorkload->{'mcastip'};
      }
      if (exists $dupWorkload->{'expectedstring'}) {
         $paramhash{expectedstring} = $dupWorkload->{'expectedstring'};
      }
      push(@params, \%paramhash);
   }
   if ( $opt eq "createprofile" ) {
      $method = 'CreateProfile';
      my $srchost;
      my $refhost;
      my $srcprofile;
      my $serializedprofile;
      push(@params, $hostObj);
      my $targetProfile=$dupWorkload->{'targetprofile'};
      push(@params, $targetProfile);
      push(@params, $destHostObj);
      if (defined $dupWorkload->{'srcprofile'}) {
         $srcprofile = $dupWorkload->{'srcprofile'};
         push(@params, $srcprofile);
      }
      if (defined $dupWorkload->{'serializedprofile'}) {
         push(@params, "nouse");
         $serializedprofile = $dupWorkload->{'serializedprofile'};
         push(@params, $serializedprofile);
      }
   }
   if ( $opt eq "checkcompliance" ) {
      $method = 'CheckCompliance';
      my $profile=$dupWorkload->{'targetprofile'};
      push(@params, $hostObj);
      push(@params, $profile);
   }
   if ( $opt eq "associateprofile" ) {
      $method = 'AssociateProfile';
      my $profile=$dupWorkload->{'targetprofile'};
      push(@params, $hostObj);
      push(@params, $profile);
   }
   if ( $opt eq "applyprofile" ) {
      $method = 'ApplyProfile';
      my $profile=$dupWorkload->{'targetprofile'};
      push(@params, $hostObj);
      push(@params, $profile);
   }
   if ( $opt eq "destroyprofile" ) {
      $method = 'DestroyProfile';
      my $profile=$dupWorkload->{'targetprofile'};
      push(@params, $profile);
   }
   if ( $opt eq "editpolicyopt" ) {
      $method             = 'EditPolicyOpt';
      my $applyprofile    = $dupWorkload->{'applyprofile'};
      my $profile         = $dupWorkload->{'targetprofile'};
      my $profiledevice   = $dupWorkload->{'profiledevice'};
      my $profilecategory = $dupWorkload->{'profilecategory'};
      my $policyid        = $dupWorkload->{'policyid'};
      my $policyoption    = $dupWorkload->{'policyoption'};
      my $policyparams    = $dupWorkload->{'policyparams'};
      my $subcategory     = $dupWorkload->{'subcategory'};
      push(@params, $applyprofile);
      push(@params, $profile);
      push(@params, $profiledevice);
      push(@params, $profilecategory);
      push(@params, $policyid);
      push(@params, $policyoption);
      push(@params, $policyparams);
      push(@params, $subcategory);
   }
   if ( $opt eq "exportprofile" ) {
      $method = 'exportprofile';
      my $host = $dupWorkload->{'host'};
      my $profile=$dupWorkload->{'targetprofile'};
      push(@params, $host);
      push(@params, $profile);
    }
   if ( $opt eq "getprofileinfo" ) {
      $method = 'GetProfileInfo';
      my $profile=$dupWorkload->{'targetprofile'};
      my $subprofile=$dupWorkload->{'subprofile'};
      push(@params, $profile);
      push(@params, $subprofile);
   }
   if ( $opt eq "getnetworkpolicyinfo" ) {
      $method = 'GetNetworkPolicyInfo';
      my $profile=$dupWorkload->{'targetprofile'};
      my $networkcategory=$dupWorkload->{'networkcategory'};
      push(@params, $profile);
      push(@params, $networkcategory);
      if (defined $dupWorkload->{'subcategory'}) {
         my $subcategory=$dupWorkload->{'subcategory'};
         push(@params, $subcategory);
      }
      if (defined $dupWorkload->{'networkpolicy'}) {
         my $networkpolicy=$dupWorkload->{'networkpolicy'};
         push(@params, $networkpolicy);
      }
      if (defined $dupWorkload->{'networkdevicename'}) {
         my $networkdevicename=$dupWorkload->{'networkdevicename'};
         push(@params, $networkdevicename);
      }
   }
   if ( $opt eq "setvdsuplink" ) {
      $method = 'SetVDSUplink';
      push(@params, $hostObj);
      push(@params, $vdsname);
      push(@params, $dupWorkload->{'portmode'});
      push(@params, $dupWorkload->{'vlanid'});
      push(@params, $dupWorkload->{'nativevlan'});
      push(@params, $dupWorkload->{'vlanrange'});
      push(@params, $dupWorkload->{'count'});
   }
   if ( $opt eq "removevds" ) {
      $method = 'RemoveVDS';
      push(@params, $vdsname);
   }
   if ( $opt eq "addvmk" ) {
      $method = 'AddVMKNIC';
      push(@params, $hostIP);
      push(@params, $vdsname);
      push(@params, $dcname);
      push(@params, $pgname);
      push(@params, $dupWorkload->{'ipadd'});
      if (defined $dupWorkload->{'prefixlen'}) {
         push(@params, $dupWorkload->{'prefixlen'});
      }
   }
   if ( $opt eq "removevmk" ) {
      $method = 'RemoveVMKNIC';
      push(@params, $hostIP);
      push(@params, $dupWorkload->{'ipadd'});
      push(@params, $dupWorkload->{'ipv6add'});
   }
   if ( $opt eq "setlinnet" ) {
      $method = 'SetLinNet';
      push(@params, $hostIP);
      push(@params, $dupWorkload->{'level'});
   }
   if ( $opt eq "migratevmknictovds" ) {
      $method = 'MigrateManamgementNetToVDS';
      push(@params, $hostIP);
      push(@params, $vdsname);
      push(@params, $dupWorkload->{dcname});
      push(@params, $dupWorkload->{'dvpgname'});
      push(@params, $dupWorkload->{'pgname'});
   }
   if ($opt eq "enablevdl2") {
      $method = 'EnableVDL2';
      push(@params, $vdsname);
   }
   if ($opt eq "disablevdl2") {
      $method = 'DisableVDL2';
      push(@params, $vdsname);
   }
   if ($opt eq "disablevdl2") {
      $method = 'DisableVDL2';
      push(@params, $vdsname);
   }
   if ($opt eq "createvdl2vmknic") {
      $method = 'CreateVDL2VMKNIC';
      push(@params, $vdsname);
      push(@params, $dupWorkload->{'vlanid'});
   }
   if ($opt eq "changevmknic") {
      $method = 'ChangeVDL2VMKNIC';
      $paramhash{vdsname} = $vdsname;
      $paramhash{host} = $hostIP;
      $paramhash{vlanid} = $dupWorkload->{'vlanid'};
      $paramhash{ipaddr} = $dupWorkload->{'ipaddr'};
      $paramhash{netmask} = $dupWorkload->{'netmask'};
      $paramhash{setdhcp} = $dupWorkload->{'setdhcp'};
      push(@params, \%paramhash);
   }
   if ($opt eq "removevdl2vmknic") {
      $method = 'RemoveVDL2VMKNIC';
      push(@params, $vdsname);
      push(@params, $dupWorkload->{'vlanid'});
   }
   if ($opt eq "attachvdl2") {
      $method = 'AttachVDL2';
      push(@params, $vdsname);
      push(@params, $pgname);
      push(@params, $dupWorkload->{'vdl2id'});
      push(@params, $dupWorkload->{'mcastip'});
   }
   if ($opt eq "detachvdl2") {
      $method = 'DetachVDL2';
      push(@params, $vdsname);
      push(@params, $pgname);
   }
   if ($opt eq "attachvdl2id") {
      $method = 'AttachVDL2ID';
      push(@params, $vdsname);
      push(@params, $pgname);
      push(@params, $dupWorkload->{'vdl2id'});
   }
   if ($opt eq "attachvdl2mcip") {
      $method = 'AttachVDL2MCIP';
      push(@params, $vdsname);
      push(@params, $pgname);
      push(@params, $dupWorkload->{'mcastip'});
   }
   if ($opt eq "setvdl2udpport") {
      $method = 'SetVDL2UDPPort';
      $paramhash{vdsname} = $vdsname;
      $paramhash{host} = $hostIP;
      $paramhash{udpport} = $dupWorkload->{'udpport'};
      push(@params, \%paramhash);
   }
   if ($opt eq "checkvdl2esxcli" or $opt eq "checknetvdl2") { #TODOver2 wierd keys
      my $host;
      my $testadapter;
      my $peermac;
      my $expectedstring;

      my $peerhost;
      if (defined $dupWorkload->{'peerhost'}) {
         my $peerHostTuple = $dupWorkload->{'peerhost'};
         my $refToArray = $self->{testbed}->GetComponentObject($peerHostTuple);
         if ($refToArray eq FAILURE) {
            $vdLogger->Error("Failed to get the host object for $peerHostTuple");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         $peerhost = $refToArray->[0];
      }

      my $testhost;
      if (defined $dupWorkload->{'testhost'}) {
         my $testHostTuple = $dupWorkload->{'testhost'};
         my $testRefToArray = $self->{testbed}->GetComponentObject($testHostTuple);
         if ($testRefToArray eq FAILURE) {
            $vdLogger->Error("Failed to get the host object for $testRefToArray");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         $testhost = $testRefToArray->[0];
      }

      $testadapter = $dupWorkload->{'testadapter'};
      if (defined $dupWorkload->{'peerhost'}){
         if (defined $testadapter){
            my $adapterRef = $self->GetNetAdapterObject(testAdapter => $testadapter);
            my $netObj = $adapterRef->[0];
            $peermac = $netObj->{'macAddress'};
            if ($peermac eq FAILURE) {
               $vdLogger->Error("Failed to get mac address of $testadapter");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }


      if ($opt eq "checkvdl2esxcli") {
         $method = 'CheckVDL2EsxCLI';
         $paramhash{esxclicmd} = $dupWorkload->{'esxclicmd'};
      } else {
         $method = 'CheckNetVDL2';
         $paramhash{netvdl2cmd} = $dupWorkload->{'netvdl2cmd'};
      }

      $paramhash{vdsname} = $vdsname;
      $paramhash{host} = $testhost->{hostIP};
      $paramhash{vdl2id} = $dupWorkload->{'vdl2id'};
      $paramhash{vlanid} = $dupWorkload->{'vlanid'};
      $paramhash{mcastip} = $dupWorkload->{'mcastip'};
      $paramhash{networknum} = $dupWorkload->{'networknum'};
      $paramhash{vmknicnum} = $dupWorkload->{'vmknicnum'};
      $paramhash{peernum} = $dupWorkload->{'peernum'};
      $paramhash{peermac} = $peermac;
      $paramhash{peerhost} = $peerhost->{hostIP};
      $paramhash{expectedstring} = $dupWorkload->{'expectedstring'};
      $paramhash{expectedresult} = $dupWorkload->{'expectedresult'};
      push(@params, \%paramhash);
      $vdLogger->Debug("@params :" . Dumper(@params));
   }
   if ($opt eq "setmac") {
      $method = 'SetVpxdMACScheme';
      push(@params, $dupWorkload->{'allocschema'});
      push(@params, $dupWorkload->{'macvalues'});
   }
   if ($opt eq "rollbackenable") {
      $method = 'EnableRollback';
   }
   if ($opt eq "setvdl2statslevel") {
      $method = 'SetVDL2StatsLevel';
      $paramhash{host} = $hostIP;
      $paramhash{statslevel} = $dupWorkload->{'statslevel'};
      $paramhash{cmdtype} = $dupWorkload->{'cmdtype'};
      push(@params, \%paramhash);
      $vdLogger->Debug("@params :" . Dumper(@params));
   }

   # Executing the operation
   $vdLogger->Info("Executing $method operation on $vcObj->{vcaddr}" .
                      " with parameters " . join(',', @params));
   my $result = $vcObj->$method(@params);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to execute $opt on $vcObj->{vcaddr}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }


   # Event handler related stuff.
   if ($opt eq "createvds") {
      my $target;
      my $tuple;
      if ($self->{testbed}{version} == 1) {
         if (defined $dupWorkload->{target}) {
            $tuple = "$dupWorkload->{target}:vc:1";
         } else {
            $tuple = "SUT:vc:1";
         }
      } else {
         $tuple = $dupWorkload->{testvc};
      }

      my @tempArray;
      $tuple =~ s/\:/\./g;
      push(@tempArray, $tuple, $dupWorkload->{vdsname}, "vdswitch", $dcname);
      my $result = $self->{testbed}->SetEvent("AddSwitch", \@tempArray);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update parent about " .
                          "event \"AddSwitch\"");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
}


########################################################################
#
# PreProcessVnicAdapter --
#     Method to process "vnic" property in testspec
#
# Input:
#     vnicadapter: tuple representing vnic adapter
#
# Results:
#     reference to objects corresponding to given vnic objects
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVnicAdapter
{
   my $self = shift;
   my $vnicadapter = shift;
   my @args;

   my $refVnicAdapterArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($vnicadapter);
   foreach my $vnicAdapterTuple (@$refVnicAdapterArray) {
      my $result = $self->{testbed}->GetComponentObject($vnicAdapterTuple);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $vnicAdapterTuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


########################################################################
#
# PreProcessSwitch --
#     Method to process "switch" property in testspec
#
# Input:
#     switch: tuple representing switch
#
# Results:
#     reference to objects corresponding to given switch objects
#
# Side effects:
#     None
#
########################################################################

sub PreProcessSwitch
{
   my $self = shift;
   my $switch = shift;
   my @args;

   my $refSwitchrArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($switch);
   foreach my $switchTuple (@$refSwitchrArray) {
      my $result = $self->{testbed}->GetComponentObject($switchTuple);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $switchTuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


1;
