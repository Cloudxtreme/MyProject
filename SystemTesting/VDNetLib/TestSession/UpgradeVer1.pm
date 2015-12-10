########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::UpgradeVer1;

#
# This package upgrades TDS from ver1 to ver2
#
#
use strict;
use warnings;
use Tie::IxHash;

use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use List::Util qw(first);
use List::MoreUtils qw(uniq);
use VDNetLib::Common::Utilities;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);

# TODO: remoove this global variable after resource cache for testbed v2
# is implemented
our @resourceCache = ();


#TestbedSpec Look up table that wil be used for referencing
use constant TestbedSpecLookUpTable => {
   TestbedSpec => "",
   'configurevc'   => "ConfigureVC",
   'configurehost' => "ConfigureHost",
   'configurevm'   => "ConfigureVM",
   'vmnic'         => "ConfigureVmnic",
   'vnic'          => "ConfigureVnic",
   'datastoreType' => "ConfigureDatastoreType",
   'pci'           => "ConfigurePCI",
   'switch'        => "ConfigureSwitch",
   'sutswitcharray'=> undef,
   'sutvmkniccount'=> "",
   'sutvmniccount' => "",
   'pgarray'       => "",
   'vmarray'       => undef,
   'vmknic'        => "ConfigureVmknic",
   'inventorykeys' => ["configurevc", "configurehost", "configurevm"],
   'passthrough'   => "ConfigurePassthrough",
   'hostkeys'      => ["switch","vmnic","vmknic"],
   'vckeys'        => ["switch"],
   'vmkeys'        => ["vnic","pci","datastoreType"],
   'host1vssCount' => "0",
   'host2vssCount' => "0",
   'host1pgCount'  => "0",
   'host2pgCount'  => "0",
   'toporder'      => ["Component", "Category", "TestName", "Summary", "ExpectedResult", "Tags"],
   'NoRULES' => {
      'VirtualNetDevices' => "1",
      'JFDiffSwitch' => "1",
   },
   'VDL2' => ["PartialDeploy","Unicast","VST","Multicast","Broadcast","DuplicatedAddress","DVShaper",
              "IPv6","JumboFrame","PortMirror","PortBinding","ChangeMulticastIP","ChangeVDL2ID",
              "ChangeVmknicIP","UDPPortConfiguration"],
   'SupportAdapterIsVM2' => ["NetQueuev3TxRxVerify","NetQueuev3FORollingBeacon",
                             "NetQueuev3FOExplicitBeacon","NetQueuev3FORolling",
                             "NetQueuev3FOExplicit","NetQueuev3LBMAC",
                             "NetQueuev3LBIP","NetQueuev3LBSrcID","NetQueuev3ChangeMTU",
                             "NetQueuev3vNICLink",],
   'NoRULES2' => [
                  #"JFDiffSwitch",
                  ],
   #'4002' => "VDNetLib::Common::GlobalConfig::VDNET_VLAN_B",
   #'4001' => "VDNetLib::Common::GlobalConfig::VDNET_VLAN_A",
   'listofkeys' => ["configurevc", 'configurehost', 'configurevm', 'vmnic', 'vnic',
                   'datastoreType', 'pci', 'switch', 'sutswitcharray', 'sutvmkniccount',
                   'sutvmniccount', 'pgarray', 'vmarray', 'vmknic', 'inventorykeys',
                   'passthrough', 'hostkeys', 'vckeys', 'vmkeys', 'host1vssCount',
                   'host2vssCount', 'host1pgCount', 'host2pgCount', 'toporder',
                   'NoRULES', 'VDL2', 'SupportAdapterIsVM2', 'NoRULES2','4002',
                   '4001', 'listofkeys'],
};

#Workload Look up table that wil be used for referencing
use constant WorkloadLookUpTableBkp => {};
use constant WorkloadLookUpTable => {
   'NetAdapter' => {
      'workload'    => {
         'Type'        => "NetAdapter",
         'testadapter' => undef,
      },
      'mgmtkeys'       => "type,target,inttype,testadapter,portgroupname," .
                          "operation,ipv4,anchor,vmotion,sleepbetweencombos",
      'depricatedkeys' => ["vmotion"],
      'vmotion'        => "PrepareNetAdapterVmotion",
      'ProcessTestKey' => "PrepareNetAdapter",
   },
   'PortGroup' => {
      'workload'    => {
         'Type'        => "PortGroup",
         'testportgroup' => undef,
      },
      'mgmtkeys'       => "type,target,accessvlan,testswitch,trunkrange,host," .
                          "pvlan,setpvlantype,portgroup,switchtype",
      'ProcessTestKey' => "",
   },
   'Port' => {
      'workload'    => {
         'Type'        => "Port",
         'testport' => undef,
      },
      'mgmtkeys'       => "type,target,pswitch,testswitch,adapterindex,testswitch," .
                          "switchtype,inttype,testadapter,verifyvnicswitchport,pswitch",
      'ProcessTestKey' => "",
   },
   'DVFilter' => {
      'workload'    => {
         'Type'        => "DVFilter",
         'testdvfilter' => undef,
      },
      'mgmtkeys'       => "type,target,pswitch,testswitch,adapterindex,testswitch," .
                          "switchtype,inttype,testadapter,supportadapter," .
                          "slowpathtarget,helpertarget",
      'ProcessTestKey' => "PrepareDVFilter",
   },
   'Command' => {
      'workload'    => {
         'Type'        => "Command",
         'testhost'    => undef,
      },
      'mgmtkeys'       => "type,target,hosttype",
      'ProcessTestKey' => "PrepareCommand",
   },
   'Suite' => {
      'workload'    => {
         'Type'        => "Command",
         'testadapter'    => undef,
      },
      'mgmtkeys'       => "type,target,testadapter,supportadapter",
      'ProcessTestKey' => "PrepareSuite",
   },
   'Switch' => {
      'workload'    => {
         'Type'        => "Switch",
         'testswitch' => undef,
      },
      'mgmtkeys'       => "type,target,testswitch,switchtype,testadapter," .
                          "inttype,testpg,createdvportgroup,pswitch," .
                          "binding,createdvportgroup,blockport,unblockport," .
                          "portgroup,vmnicadapter,verifyactivevmnic,setfailoverorder," .
                          "confignicteaming,verifyvnicswitchport,standbynics," .
                          "opt,uplink,configureuplinks,testvc,vdsname,pgname," .
                          "erspanip,srcrxport,srctxport,dstport,dstuplink,accessvlan," .
                          "dvportgroup,migratemgmtnettovss,vss,migratemgmtnettovds,configureportgroup," .
                          "setpvlantype,vmknic,datacenter,configureprotectedvm," .
                          "enableoutshaping,enableinshaping,disableinshaping,sleepbetweencombos," .
                          "disableoutshaping,testinttype,removedvportgroup,configureportrules",
      'depricatedkeys' => ["createdvportgroup", "addporttodvportgroup","blockport","unblockport",
                           "verifyactivevmnic","confignicteaming", "verifyvnicswitchport",
                           "accessvlan","setfailoverorder", "trunkrange", "configureuplinks",
                           "erspanip","srcrxport","srctxport","dstport", "dstuplink",
                           "migratemgmtnettovss", "migratemgmtnettovds", "configureportgroup",
                           "setpvlantype","pswitch","vmknic", "vlan","checkcdponswitch",
                           "lldp","setlldptransmitport", "removedvportgroup","checkcdponesx",
                           "lacp", "backuprestore", "configureportrules", "portstatus","quealloc"],
      'createdvportgroup'    => "MoveDVPGToVCWorkload",
      'addporttodvportgroup' => "PrepareAddPortToDVPG",
      'blockport'            => "PrepareBlockPort",
      'unblockport'          => "PrepareUnBlockPort",
      "verifyactivevmnic"    => "PrepareVerifyActiveVmnic",
      "confignicteaming"     => "PrepareNicTeaming",
      "verifyvnicswitchport" => "PrepareVerifyVnicSwitchport",
      "accessvlan"           => "PrepareAccessVlan",
      "pswitch"              => "PreparePort",
      "setpvlantype"         => "PrepareSetpvlantype",
      "setfailoverorder"     => "PrepareSetFailOverOrder",
      "trunkrange"           => "PrepareTrunkRange",
      "configureuplinks"     => "PrepareConfigureUplinks",
      "erspanip"             => "PrepareErspanip",
      "srcrxport"            => "PrepareSrcrxport",
      "srctxport"            => "PrepareSrctxport",
      "dstport"              => "PrepareDstport",
      "dstuplink"            => "PrepareDstuplink",
      "vmknic"               => "AddVmknicToHost",
      "vlan"                 => "PrepareVlan",
      #"checkcdponswitch"    => "PrepareCheckcdponswitch",
      "checkcdponswitch"     => "PreparePort",
      "checkcdponesx"        => "PreparePort",
      "portstatus"           => "PreparePort",
      #"checklldponesx"       => "PreparePort",
      "migratemgmtnettovss"  => "PrepareMigratemgmtnettovss",
      "migratemgmtnettovds"  => "PrepareMigratemgmtnettovds",
      "configureportgroup"   => "PrepareTestHost",
      "lldp"                 => "PrepareLLDP",
      "setlldptransmitport"  => "PreparePort",
      "removedvportgroup"    => "Prepareremovedvportgroup",
      "lacp"                 => "PrepareLacpmode",
      "backuprestore"        => "PrepareBackuprestore",
      "configureportrules"   => "PrepareConfigureportrules",
      "quealloc"             => "PrepareQuealloc",
      'ProcessTestKey'       => "PrepareSwitchOrPortGroup",
   },
   'VC' => {
      'workload'    => {
         'Type'        => "VC",
         'testvc'      => 'vc.[1].x.[x]',
      },
      'mgmtkeys'  => "type,target,testswitch,switchtype,createdvportgroup," .
                     "dsthost,testhost,vm,binding,hosts,vdsname,uplink," .
                     "testhost,version,opt,dcname,sleepbetweencombos,vdsindex," .
                     "host,referencehost,targetprofile,pgname,peerhost,referenceHost",
      'depricatedkeys' => ["uplink","removehostfromvds"],
      'uplink'         => "PrepareUplink",
      'removehostfromvds' => "Removehostfromvds",
      'ProcessTestKey' => "PrepareTestVC",
      'opt' => "adddc",
      'adddc' => '',
   },
   'VM' => {
      'workload'    => {
         'Type'        => "VM",
         'testvm'      => undef,
      },
      'mgmtkeys'  => "type,target,testadapter,sleepbetweencombos,portgroupname," .
                     "operation,iterations,clientadapter,passthroughadapter",
      'ProcessTestKey' => "PrepareTestVM",
   },
   'Host' => {
      'workload'    => {
         'Type'        => "Host",
         'testhost'      => undef,
      },
      'mgmtkeys'  => "type,target,testadapter,vmnic,switch,vmnicadapter,vswitch," .
                     "portgroupname,vswitchname,portgroup,vmknic,portgroup,pgname," .
                     "ip,configureportgroup,switchtype,supportadapter,uplinkname," .
                     "analyzetxrxq,swindex,nicindex,checklocalmtumatch,esxclivmportlistverify",
      'depricatedkeys' => ["setdvsuplinkportstatus","vswitch","portgroup","vmknic",
                          "analyzetxrxq", "configureportgroup", "swindex", "nicindex",
                          "checklocalmtumatch","checkteamchkmatch","monitorportstat",
                          "monitorvmnicstat","monitorvstvlanpkt","monitordvfilterstat",
                          "addremdvfiltertovm", "lro", "esxclivmportlistverify"],
      'setdvsuplinkportstatus' => "PrepareSetDvsUplinkPortstatus",
      'vswitch' => "AddPGToHost",# "AddVSSToHost",
      'portgroup' => "AddPGToHost",
      'vmknic'    => "AddVmknicToHost",
      "configureportgroup"   => "AddPGToHost",
      "analyzetxrxq"   => "PrepareAnalyzetxrxq",
      "swindex" => "PrepareSwIndex",
      "nicindex" => "PrepareNicIndex",
      "checklocalmtumatch" => "PrepareChecklocalmtumatch",
      "checkteamchkmatch" => "PrepareCheckteamchkmatch",
      "monitorportstat" => "PrepareMontorHost",
      "monitorvmnicstat" => "PrepareMontorHost",
      "monitorvstvlanpkt" => "PrepareMontorHost",
      "monitordvfilterstat" => "PrepareMontorHost",
      "addremdvfiltertovm"    => "PrepareAddremdvfiltertovm",
      "esxclivmportlistverify" => "PrepareEsxclivmportlistverify",
      "lro" => "PrepareLRO",
      'ProcessTestKey' => "PrepareTestHost",
   },
   'Traffic' => {
      'workload'    => {
         'Type'        => "Traffic",
         'testadapter'      => undef,
         'supportadapter'      => undef,
      },
      'mgmtkeys'  => "type,testadapter,supportadapter,verificationadapter," .
                     "testinttype,supportinttype",
      'ProcessTestKey' => "PrepareTrafficAdapters",
   },
   'RemoveOldMgmtKeys'     => "RemoveOldMgmtKeys",
   'MergeRemainingKeys'    => "MergeRemainingKeys",
   'lowercase' => "CovertKeysToLowerCase",
   'TrafficAdaptersNotPresentCount' => '0',
   'workloadType' => {
      'VM'         => 'TestVM',
      'NetAdapter' => 'TestAdapter',
      'Switch'     => 'TestSwitch',
      'VC'         => 'TestVC',
      'Host'       => 'TestHost',
      'PortGroup'  => 'TestPortGroup',
      'Port'       => 'TestPort',
      'Command'    => 'command',
      'DVFilter'   => 'TestDVFilter',
      #'Traffic'    => 'TestAdapter',
      'Suite'      => 'TestAdapter',
   }
};

use constant vdNetConstantTable => {
   "16" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_A',
   "17" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_B',
   "18" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_C',
   "19" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_D',
   "20" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_E',
   "21" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_F',
   "22" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_G',
   "23" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_H',
   "4001" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_A',
   "4002" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_B',
   "3000" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_C',
   "3001" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_D',
   "3002" => 'VDNetLib::Common::GlobalConfig::VDNET_VLAN_E',
};


sub new
{
   my $class = shift;
   my $testcaseHash = shift;

   my $logDir = shift;
   my $tdsID =  shift;

   my $self = {
      'testcaseHash' => $testcaseHash,
      'logDir'       => $logDir,
      'tdsIDs'       => $tdsID
   };
   bless ($self, $class);
   return $self;
}


sub UpgradeTDS
{
   my $self = shift;
   my $testcaseArray = shift;
   my $SessionObject = shift;

   my ($tdsName, $destTdsFile, $destTdsHandle);
   my ($testcaseList, $result);
   ($tdsName, $destTdsFile) = $self->GetNewTDSName();
   open($destTdsHandle, ">", $destTdsFile) or die "cannot open > $destTdsFile: $!";

   # Write the TDS header to new TDS file;
   print $destTdsHandle $self->createHeaderBody($tdsName);

   my $testName = undef;
   my $testbedSpec = undef;
   my $testCount = 0;
   foreach my $testcase (@$testcaseArray) {
      if (defined $testcase->{Version} && $testcase->{Version} == 2) {
         $vdLogger->Debug("Skipping upgrade of $testcase->{TestName}");
         next;
      }
      tie my %dupTestcaseHash, 'Tie::IxHash';
      %dupTestcaseHash = %$testcase;
      $testCount = $testCount + 1;
      $vdLogger->Info("Upgrading TDS parameters for case $testCount: $testcase->{TestName}");
      my @tdsID = @{$self->{tdsIDs}};
      my $folderPath = pop @tdsID;
      my @findTDSFolder = split ('\.',$folderPath);
      my $TdsFolder = $findTDSFolder[0];

      $testName = $testcase->{testID};
      $testName =~ s/::/./g; # remove :: from the test case name
      my $logDir = $self->{'logDir'} . "/" . $testCount . "_$testName";

      my $testcaseHash = $self->StartUpgrade($testcase, $TdsFolder,$SessionObject);
      #my $testcaseHash = $self->UpgradeVer1($testcase);
      if ($testcaseHash eq FAILURE) {
         $vdLogger->Error("Failed to create test session object for $testcase");
         $result = FAILURE;
         next;
      }

      #Dumper converted to testbedspec to $destTdsHandle here;
      my $dumper = new Data::Dumper([$testcaseHash]);
      $dumper->Indent(1);
      #$dumper->Sortkeys(1);
      $testbedSpec = $dumper->Dump();
      $testbedSpec =~ s/^/\t\t/mg;
      $testbedSpec =~ s/\$VAR1\ =/\'$testcase->{TestName}\'\ =>/g;
      $testbedSpec =~ s/\}\;/\}\,/g;
      print $destTdsHandle $testbedSpec . "\n\n";
      $testbedSpec = undef;
   }

   # Append new method for newly created TDS;
   print $destTdsHandle $self->createNewBody($tdsName);
   close $destTdsFile;

   if (defined $result and $result eq FAILURE ) {
      $vdLogger->Info("Got errors during TDS upgrade. ");
      $vdLogger->Debug(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("New TDS file successfully generated in $destTdsFile");
   return SUCCESS;
}




########################################################################
#
# UpgradeVer1--
#     Routine to upgrade the parameter and workload to ver2
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub StartUpgrade
{
   my $self              = shift;
   $self->{testcaseHash} = shift;
   my $TdsFolder         = shift;
   my $SessionObject = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my @arrayOfTopOrder = @{$TestbedSpecLookUpTable->{toporder}};
   tie my %testcaseHashTemp , 'Tie::IxHash';
   tie my %selfDup , 'Tie::IxHash';

   # Fill Initial Entries
   foreach my $entry (@arrayOfTopOrder) {
      $testcaseHashTemp{$entry} = $self->{testcaseHash}{$entry};
   }

   $testcaseHashTemp{Version} = "2";

   my %knownEntries = map { $_ => 1 } @arrayOfTopOrder;
   foreach my $entry (keys %{$self->{testcaseHash}}) {
      if (($entry =~ /Parameters/i) ||
          ($entry =~ /WORKLOADS/i) ||
          (exists($knownEntries{$entry}))) {
          next;
      }
      $testcaseHashTemp{$entry} = $self->{testcaseHash}{$entry};
   }
   #Tie
   $testcaseHashTemp{TestbedSpec} = $self->UpgradeParameter($TdsFolder);
   #tie my %dupWorkload, 'Tie::IxHash';
   #%dupWorkload = %{$self->UpgradeWorkload()};

   #my $vcexists;
   #if (exists $self->{testcaseHash}{Parameters}{vc}) {
   #   $vcexists = "1";
   #}
   #my $hostexists;
   #if (exists $self->{testcaseHash}{Parameters}{SUT}{host}) {
   #   $hostexists = "1";
   #}

   delete $self->{testcaseHash}{Parameters};

   #$self->{testcaseHash}{TestbedSpec} = %{$testcaseHashTemp{TestbedSpec}};
   #$self->{testcaseHash}{TestbedSpec} = $self->UpgradeParameter();
   #$self->{testcaseHash}{WORKLOADS} = $self->UpgradeWorkload();
   $self->{testcaseHash}{Version} = "2";
   #TIE
   my $newTestbedspec;
   ($testcaseHashTemp{WORKLOADS},$newTestbedspec) = $self->UpgradeWorkload($testcaseHashTemp{TestbedSpec});

   #print Dumper(%testcaseHashTemp);
   #$self->{testcaseHash} = %testcaseHashTemp;
   #$testcaseHashTemp{Version} = "2";
   # Delete Rules
   delete $testcaseHashTemp{Rules};


   $testcaseHashTemp{TestbedSpec} = $self->CorrectPswitchPort($testcaseHashTemp{TestbedSpec});
   #$testcaseHashTemp{TestbedSpec} = $self->CorrectVC($testcaseHashTemp{TestbedSpec},$vcexists);
   #$testcaseHashTemp{TestbedSpec} = $self->CorrectHost1($testcaseHashTemp{TestbedSpec},$hostexists);
   $TestbedSpecLookUpTable->{'host1pswitchportCount'} = undef;
   $TestbedSpecLookUpTable->{'host2pswitchportCount'} = undef;
   #return $self->{testcaseHash};
   print "===TesbedSpecHash===" . Dumper(\%testcaseHashTemp);
   $TestbedSpecLookUpTable->{host1pswitchportCount} = undef;
   $TestbedSpecLookUpTable->{host2pswitchportCount} = undef;
   $self->{testcaseHash} = \%testcaseHashTemp;
   my %listofkeys = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'listofkeys'}};
   foreach my $key (keys %$TestbedSpecLookUpTable) {
      if (exists($listofkeys{$key})) {
         #skip
      } else {
       delete $TestbedSpecLookUpTable->{$key};
      }
   }
   #print "===2===" . Dumper($self->{testcaseHash});
   #print "===3===" . Dumper($SessionObject);
   return \%testcaseHashTemp;
}


sub CorrectVC
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectVC");
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #print "====1===" . Dumper($dupTestbedSpec);
   if (($TestbedSpecLookUpTable->{vccount} eq "YES") &&
      (not exists $dupTestbedSpec->{'vc'})) {
       #$self->{testcaseHash}{TestbedSpec}{vc}{'[1]'} = {};
       $dupTestbedSpec->{'vc'}{'[1]'} = {};
       $TestbedSpecLookUpTable->{vccount} = "NO";
   }
   return $dupTestbedSpec;
}


sub CorrectHost1
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   #my $hostexists =  shift;
   $vdLogger->Debug("Inside CorrectHost1");
   #print Dumper($dupTestbedSpec);
   #print "===2==1=1=1=1=1=";
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $dupTestbedSpec->{'host'}{'[1]'} = {};
   return $dupTestbedSpec;
}

########################################################################
#
# UpgradeParameter--
#     Routine to upgrade the parameter section to testbedspec
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub UpgradeParameter
{
   my $self         = shift;
   my $TdsFolder = shift;
   my $parameter = $self->{testcaseHash}{Parameters};
   my $result = FAILURE;
   $vdLogger->Debug("Start Conversion for parameter section\n");
   tie my %dupTestbedSpec, 'Tie::IxHash';
   my $newWorkloadList;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #$TestbedSpecLookUpTable->{'host1pswitchportCount'} = undef;
   #$TestbedSpecLookUpTable->{'host2pswitchportCount'} = undef;
   # Fill Rules structure in TestbedLookUpTable
   $self->AddMachinesToHostsBasedOnRules($TdsFolder);
   $vdLogger->Debug("Dump of TestbedLookUpTable" . Dumper($TestbedSpecLookUpTable));
   #Upgrade Host, VC and VM
   my $newtestbedspec = ();
   my $inventorykeys = $TestbedSpecLookUpTable->{inventorykeys};
   foreach my $key (@$inventorykeys) {
      $result = undef;
      $vdLogger->Debug("Upgrading parameter for $key");
      my $method = $TestbedSpecLookUpTable->{$key};
      $result = $self->$method();

      if (not defined $result) {
         $vdLogger->Debug("Skip setup for $key");
         next;
      }

      if ((defined $result) && ($result eq FAILURE)) {
         $vdLogger->Error("Failed to upgrade parameter for $key");
         VDSetLastError("EOPFAILED");
         return $result;
      } elsif ($result eq SKIP) {
         $vdLogger->Debug("Skipping the upgrade of $key");
         next;
      }
      #TIE
      my $dupKey = $key;
      $dupKey =~ s/configure//g;
      $vdLogger->Debug("Adding spec to $dupKey" . Dumper($result));
      $dupTestbedSpec{$dupKey} = $result;
   }



   # Configure Host 1 vmnic=1 even if vmnic is not part of Paramters
   if ((exists $self->{testcaseHash}{TestbedSpec}{vc}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic}) ||
       ((exists $self->{testcaseHash}{TestbedSpec}{vm}) &&
        (exists $self->{testcaseHash}{TestbedSpec}{vm}{'[1]'}) &&
        ($self->{testcaseHash}{TestbedSpec}{vm}{'[1]'}{host} =~ /1/i) &&
        (not exists $self->{testcaseHash}{TestbedSpec}{host}))) {
      %dupTestbedSpec = %{$self->MandatoryConfigureHost1(\%dupTestbedSpec)};
   }

   # Configure Host 1 vmnic=1 even if vmnic is not part of Paramters
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vss}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vss}{'[1]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vss}{'[1]'}{vmnicadapter}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic})) {
      %dupTestbedSpec = %{$self->AddVmknicToHost1InCaseMissed(\%dupTestbedSpec)};
   }

   # Configure Host 1 vmnic=1 even if vmnic is not part of Paramters
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss}{'[1]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss}{'[1]'}{vmnicadapter}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic})) {
      %dupTestbedSpec = %{$self->AddVmknicToHost2InCaseMissed(\%dupTestbedSpec)};
   }

   # Configure Host 2 vmnic=1 even if vmnic is not part of Paramters
   #print "===1===" . Dumper ($self->{testcaseHash}{TestbedSpec});
   if (((exists $self->{testcaseHash}{TestbedSpec}{vc}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic})) ||
       ((defined $TestbedSpecLookUpTable->{'host2'}) &&
        (@{$TestbedSpecLookUpTable->{'host2'}}) &&
        (!(exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'})))) {
      %dupTestbedSpec = %{$self->MandatoryConfigureHost2(\%dupTestbedSpec)};
   }

   # Configure Host for pg and vss if vss is not part of Paramters
   #print "===1===" . Dumper (\%dupTestbedSpec);
   if ((exists $self->{testcaseHash}{TestbedSpec}{vm}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host})) {
      %dupTestbedSpec = %{$self->MandatoryConfigureHostForPGAndVSS(\%dupTestbedSpec)};
   }

   # Configure Host for pg and vss if vss/pg is not part of host but part of VM
   #print "===1===" . Dumper (\%dupTestbedSpec);
   if ((exists $self->{testcaseHash}{TestbedSpec}{vm}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{portgroup})) {
      %dupTestbedSpec = %{$self->MandatoryConfigureHost1ForPGAndVSS(\%dupTestbedSpec)};
   }


   # To cure the pg and host mismatch in vm
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{vm})) {
      #my @arrayOfKeys = keys %{$self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic}};
      $vdLogger->Debug("Checking if pg and host mismatch in vm");
      foreach my $vmIndex (sort (keys %{$self->{testcaseHash}{TestbedSpec}{vm}})) {
         my $hostTuple = $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{host};
         my $pgTuple;
         my $vnicIndex;
         if (exists $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic}{'[1]'}) {
            $pgTuple = $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic}{'[1]'}{portgroup};
         } else {
            my @vnicKeys = keys %{$self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic}};
            $vnicIndex = pop @vnicKeys;
            if (not defined $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic}{$vnicIndex}){
               delete $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic};
               next;
            } else {
               $pgTuple = $self->{testcaseHash}{TestbedSpec}{vm}{$vmIndex}{vnic}{$vnicIndex}{portgroup};
            }
         }
         my @arrayHostTuple = split '\.', $hostTuple;
         my @arraypgTuple = split '\.', $pgTuple;
         if (($arraypgTuple[0] eq $arrayHostTuple[0]) &&
             ($arraypgTuple[1] ne $arrayHostTuple[1])) {
            $vdLogger->Debug("Pg and host mismatch in vm");
            my $newPGTuple = "$arraypgTuple[0].$arrayHostTuple[1].$arraypgTuple[2].$arraypgTuple[3]";
            if ($vnicIndex) {
               $dupTestbedSpec{vm}{$vmIndex}{vnic}{$vnicIndex}{portgroup} = $newPGTuple;
            } else {
               $dupTestbedSpec{vm}{$vmIndex}{vnic}{'[1]'}{portgroup} = $newPGTuple;
            }
            if (!(exists $dupTestbedSpec{host}{'[2]'}{portgroup})) {
               %dupTestbedSpec = %{$self->MandatoryConfigureHost2PCI(\%dupTestbedSpec)};
            }
            if (!(exists $dupTestbedSpec{host}{'[1]'}{portgroup})) {
               %dupTestbedSpec = %{$self->MandatoryConfigureHost1(\%dupTestbedSpec)};
            }
            #%dupTestbedSpec = %{$self->CorrectPGHost2Miusmatch(\%dupTestbedSpec)};
         }
      }
   }


   # Correct VDS Host2 association incase both vss and vds associated with
   # vmnics under host 2
   if ((exists $self->{testcaseHash}{TestbedSpec}{vc}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{vc}{'[1]'}{vds}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss})) {
      my @vssKeys = keys %{$self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss}};
      foreach my $eachVSSIndex (@vssKeys) {
         if (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vss}{$eachVSSIndex}{vmnicadapter}) {
            %dupTestbedSpec = %{$self->CorrectVSSVDSHost2(\%dupTestbedSpec)};
            last;
         }
      }
   }

   # Configure Host for pg and vss if vss is not part of Paramters
   if ((!%{$self->{testcaseHash}{TestbedSpec}}) &&
       (exists $parameter->{SUT}) &&
       (exists $parameter->{SUT}{host}) &&
       (defined $parameter->{SUT}{host})) {
      %dupTestbedSpec = %{$self->AddHostIfOnlyHostKeyPresentInSUT(\%dupTestbedSpec)};
   }

   # To cure the occurence of [1] and [1-2] in vmnics of host2
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic})) {
      my @arrayOfKeys = keys %{$self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vmnic}};
      $vdLogger->Debug("Checking if fix is needed under Host2 for multiple vmnics");
      my $len = @arrayOfKeys;

      if ($len > 1) {
         $vdLogger->Debug("Multiple vmnic entries found under Host2, fixing it");
         %dupTestbedSpec = %{$self->CorrectVmnicOnHost2(\%dupTestbedSpec)};
      }
   }

   # To remove vc keys from host and put in vc inventory
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vc})) {
      $vdLogger->Debug("To remove vc keys from host 1 and put in vc inventory");
      %dupTestbedSpec = %{$self->CorrectVCVmknicHost1Association(\%dupTestbedSpec)};
   }

   # To remove vc keys from host and put in vc inventory
   if ((exists $self->{testcaseHash}{TestbedSpec}{host}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{host}{'[2]'}{vc})) {
      $vdLogger->Debug("To remove vc keys from host 2 and put in vc inventory");
      %dupTestbedSpec = %{$self->CorrectVCVmknicHost2Association(\%dupTestbedSpec)};
   }

   #Add pswitch inventory if defined
   if ((exists $self->{testcaseHash}{Parameters}{SUT}{pswitch}) &&
       (defined $self->{testcaseHash}{Parameters}{SUT}{pswitch})) {
      $dupTestbedSpec{'pswitch'}{'[-1]'} = {};
      $self->{testcaseHash}{TestbedSpec} = \%dupTestbedSpec;
   }

   # Add host if only host is defined in Paramter
   if ((exists $self->{testcaseHash}{Parameters}{SUT}{host}) &&
       (not exists $self->{testcaseHash}{TestbedSpec}{host})) {
        print "==1===" . Dumper(\%dupTestbedSpec);
      %dupTestbedSpec =  %{$self->CorrectHost1(%dupTestbedSpec)};
      $self->{testcaseHash}{TestbedSpec} = \%dupTestbedSpec;
   }

   # Add vc if only host is defined in Paramter or connectvc or checkpools is
   # used as a key in VC
#   if ((exists $self->{testcaseHash}{Parameters}{vc}) &&
#      (not exists $self->{testcaseHash}{TestbedSpec}{vc}) ||
#      ($TestbedSpecLookUpTable->{vccount} eq "YES")) {
#      #%dupTestbedSpec =  %{$self->CorrectVC(%dupTestbedSpec)};
#      #$self->{testcaseHash}{TestbedSpec} = \%dupTestbedSpec;
#   }

   #delete $TestbedSpecLookUpTable->{'host1'};
   #delete $TestbedSpecLookUpTable->{'host2'};
   #print "=====" . Dumper(%dupTestbedSpec);
   return \%dupTestbedSpec;
}


sub CorrectVCVmknicHost1Association
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectVCVmknicHost1Association");

   my $vcspec = $dupTestbedSpec->{'host'}{'[1]'}{'vc'};
   $dupTestbedSpec = $self->MergeSpec($vcspec, $dupTestbedSpec);
   $self->{testcaseHash}{TestbedSpec}{'vc'} = $self->MergeSpec($vcspec, $self->{testcaseHash}{TestbedSpec}{'vc'} );

   delete $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{'vc'};
   delete $dupTestbedSpec->{'host'}{'[1]'}{'vc'};
   delete $dupTestbedSpec->{'[1]'};
   delete $self->{testcaseHash}{TestbedSpec}{'[1]'};
   return $dupTestbedSpec;
}


sub CorrectVCVmknicHost2Association
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectVCVmknicHost1Association");

   my $vcspec = $dupTestbedSpec->{'host'}{'[2]'}{'vc'};
   $dupTestbedSpec = $self->MergeSpec($vcspec, $dupTestbedSpec);
   $self->{testcaseHash}{TestbedSpec}{'vc'} = $self->MergeSpec($vcspec, $self->{testcaseHash}{TestbedSpec}{'vc'} );

   delete $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{'vc'};
   delete $dupTestbedSpec->{'host'}{'[2]'}{'vc'};
   delete $dupTestbedSpec->{'[1]'};
   delete $self->{testcaseHash}{TestbedSpec}{'[1]'};
   return $dupTestbedSpec;
}



########################################################################
#
# ConfigureVC--
#     Routine to upgrade the vc section of teatbedspec
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVC
{
   my $self = shift;
   my $parameters             = $self->{testcaseHash}{Parameters};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   if ((not defined $parameters) || (not defined $TestbedSpecLookUpTable)) {
      $vdLogger->Error("Failed to upgrade paramter for vc");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $vckeys = $TestbedSpecLookUpTable->{vckeys};

   my $inventoryCount = "1";
   my $vckey = "" . "[$inventoryCount]" . "";
   my $vcSpecInitial = {};
   my $vcSpecReturn = {};
   tie %$vcSpecInitial, 'Tie::IxHash';
   tie %$vcSpecReturn, 'Tie::IxHash';
   $vdLogger->Debug("Configure VC Start");
   foreach my $parameterKey (keys %$parameters) {
      if (($parameterKey =~ m/vc/i) || ($parameterKey =~ m/Rules/i)|| ($parameterKey =~ m/Override/i)  ) {
         next;
      }

      # skip "vdsversion" but before that save the vdsversion for future use
      if ($parameterKey =~ m/version/i) {
         $TestbedSpecLookUpTable->{'version'} = $parameters->{$parameterKey};
         next;
      }

      foreach my $key (@$vckeys) {
         my $value = $parameters->{$parameterKey}{$key};
         foreach my $element (@$value) {
            my ($type, $range) = split(':', $element);
            $vdLogger->Debug("key=$key, type = $type and quantity = $range");
            $range = $self->ConvertToRange($range);
            if ($type =~ m/vss/i) {
               next;
            }
            my $method = $TestbedSpecLookUpTable->{$key};
            my $temp = $self->$method($inventoryCount, $type, $range, $parameterKey);
            $vcSpecInitial = {%$temp, %$vcSpecInitial};
         }
      }
      if (%$vcSpecInitial) {
         $vcSpecReturn->{'vc'}{$vckey} = $vcSpecInitial;
         $vcSpecReturn->{'vc'}{$vckey}{'datacenter'}{$vckey}{'host'} = "host.[1].x.[x]";
         if (defined $TestbedSpecLookUpTable->{'host2'}) {
            $vcSpecReturn->{'vc'}{$vckey}{'datacenter'}{$vckey}{'host'} = "host.[1-2].x.[x]";
         }
         $TestbedSpecLookUpTable->{'dcCount'} = "1";
      }
      #print "\n";
   }
   $self->{testcaseHash}{TestbedSpec} = $vcSpecReturn;
   #TIE
   $vdLogger->Debug("Configure VC End");
   #print "VC==" . Dumper($vcSpecReturn);
   return $vcSpecReturn->{vc};
}


########################################################################
#
# ConfigureVM--
#     Routine to upgrade the vm section of teatbedspec
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVM
{
   my $self                   = shift;
   my $parameters             = $self->{testcaseHash}{Parameters};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   tie my %dupVM, 'Tie::IxHash';

   my @unsortedVMArray;
   my $vmkeys = $TestbedSpecLookUpTable->{vmkeys};
   my $vmSpecReturn;
   $vdLogger->Debug("Configure VM Start");
   $TestbedSpecLookUpTable->{sutVnicCount} = "0";

   my $inventoryCount = "1";
   foreach my $parameterKey (keys %$parameters) {
      my $vmSpecInitial = {};
      if (($parameterKey =~ m/vc/i) || ($parameterKey =~ m/Rules/i) ||
          ($parameterKey =~ m/Override/i) || ($parameterKey =~ m/vdsversion/i)) {
         next;
      }
      foreach my $key (@$vmkeys) {
         $vdLogger->Debug("machine=$parameterKey, key = $key");
         my $value = $parameters->{$parameterKey}{$key};
         my $method = $TestbedSpecLookUpTable->{$key};
         if ((defined $value) &&
             (ref($value) ne "ARRAY") &&
             ($key =~ /datastoreType/i)) {
            my $tempSpec = "$value:1";
            my @tempArray;
            push @tempArray, $tempSpec;
            $value = \@tempArray;
         }
         if (ref($value) eq "HASH") {
            my $temp = $self->ConfigurePCIHASH($value,$parameterKey);
            $vmSpecInitial = {%$temp, %$vmSpecInitial};
            if ($parameterKey =~ /SUT/i) {
               push @{$TestbedSpecLookUpTable->{vmarray}}, $parameterKey;
            } else {
               push @unsortedVMArray, $parameterKey;
            }
         } else {
            my $count = "1";
            foreach my $element (@$value) {
               #print "===1===$count\n";
               my ($type, $range) = split(':', $element);
               $vdLogger->Debug("key=$key, type = $type and quantity = $range");
               $range = $self->ConvertToRange($range);
               if ($type =~ m/vds/i) {
                  next;
               }
               if ($count > "1") {
                  $range = "[$count]";
               }
               my $temp = $self->$method($inventoryCount,$type,$range,$parameterKey);

               # Need to check if this breaks
               if ($count > "1") {
                  $vmSpecInitial->{vnic} = {%{$temp->{vnic}}, %{$vmSpecInitial->{vnic}}};
               } else {
                  $vmSpecInitial = {%$temp, %{$vmSpecInitial}};
               }
               if ($parameterKey =~ /SUT/i) {
                  push @{$TestbedSpecLookUpTable->{vmarray}}, $parameterKey;
               } else {
                  push @unsortedVMArray, $parameterKey;
               }
               $count++;
            }
         }
      }
      $vmSpecReturn->{$parameterKey} = $vmSpecInitial;
   }
   if (defined $TestbedSpecLookUpTable->{vmarray}) {
      my %hashToRemoveDuplicateEntries1;
      @hashToRemoveDuplicateEntries1{@{$TestbedSpecLookUpTable->{vmarray}}} = ();
      @{$TestbedSpecLookUpTable->{vmarray}} = keys %hashToRemoveDuplicateEntries1;
   }

   if (@unsortedVMArray) {
      my %hashToRemoveDuplicateEntries2;
      @hashToRemoveDuplicateEntries2{@unsortedVMArray} = ();
      @unsortedVMArray = keys %hashToRemoveDuplicateEntries2;
   }


   if ((not defined $TestbedSpecLookUpTable->{vmarray}) &&
      !(@unsortedVMArray)) {
      $vdLogger->Debug("Skipping the configuration of vm spec");
      return "SKIP";
   }

   my @sortedHelperArray = sort @unsortedVMArray;
   if (defined $TestbedSpecLookUpTable->{vmarray}) {
      @{$TestbedSpecLookUpTable->{vmarray}} = (@{$TestbedSpecLookUpTable->{vmarray}}, @sortedHelperArray);
   } else {
      @{$TestbedSpecLookUpTable->{vmarray}} = @sortedHelperArray;
   }

   #Add SUT initially to TestbedSpec as vm 1
   #print "vmspecreturn" . Dumper($vmSpecReturn);
   if (keys %{$vmSpecReturn->{SUT}}) {
      $self->{testcaseHash}{TestbedSpec}{'vm'}{'[1]'} = $vmSpecReturn->{SUT};
      $self->{testcaseHash}{TestbedSpec}{'vm'}{'[1]'}{'host'} = "host.[1].x.[x]";
      #TIE
      $dupVM{'vm'}{'[1]'} = $vmSpecReturn->{SUT};
      $dupVM{'vm'}{'[1]'}{'host'} =  "host.[1].x.[x]";
      delete $vmSpecReturn->{SUT};
   } else {
      # decreasing the count. This means vm 1 is under helper1 and
      # not under SUT
      $inventoryCount--;
   }


   #Add all helpers except SUT to TestbedSpec under vm 2 to N
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my %host2Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host2'}};
   foreach my $machine (sort keys %$vmSpecReturn){
      if ((not defined $vmSpecReturn->{$machine}{'vnic'}) &&
         (not defined $vmSpecReturn->{$machine}{'pcipassthru'})) {
         # vnic not provided, no need to create vm
         next;
      }
      $inventoryCount++;
      my $newIndex = undef;
      foreach my $newTarget (keys %$parameters) {
         if ($newTarget =~ /\[/) {
            $newTarget =~  s/helper//;
            $newIndex = $newTarget;
         }
      }
      #print $self->{testcaseHash}{Parameters}{helper}
      # Check if $newIndex = [1-6] where it starts with 1
      # In that case the new Index should be changed to
      # [2-7].
      my $vmkey;
      if (defined $newIndex) {
         my $tempIndex = $newIndex;
         $newIndex =~ s/\[|\]//g;
         my ($lower, $upper) = split ('-', $newIndex);
         if ($lower eq "1") {
            $lower = $lower + "1";
            $upper = $upper + "1";
            $newIndex = "[" . $lower . "-" . $upper . "]";
         }
      }
      if (defined $newIndex) {
         $vmkey = $newIndex;
      } else {
         $vmkey = "" . "[$inventoryCount]" . "";
      }
      my $tuple;
      if (exists($host1Machines{$machine})) {
         $self->{testcaseHash}{TestbedSpec}{'vm'}{$vmkey} = $vmSpecReturn->{$machine};
         #TIE
         $dupVM{'vm'}{$vmkey} = $vmSpecReturn->{$machine};
         $tuple = "host.[1].x.[x]";
      } elsif (exists($host2Machines{$machine})) {
         $self->{testcaseHash}{TestbedSpec}{'vm'}{$vmkey} = $vmSpecReturn->{$machine};
         #TIE
         $dupVM{'vm'}{$vmkey} = $vmSpecReturn->{$machine};
         $tuple = "host.[2].x.[x]";
      } else {
         next;
      }
      $self->{testcaseHash}{TestbedSpec}{'vm'}{$vmkey}{'host'} = $tuple;
      #TIE
      $dupVM{'vm'}{$vmkey}{'host'} = $tuple;
   }
   
   #print "====1====" .Dumper($TestbedSpecLookUpTable);
   foreach my $vm (keys %dupVM) {
    foreach my $vmIndex (keys %{$dupVM{$vm}}) {
       if (exists $dupVM{$vm}{$vmIndex}{'pcipassthru'}) {
          $dupVM{$vm}{$vmIndex}{'vmstate'} = "poweroff"; #poweroff
          $dupVM{$vm}{$vmIndex}{'reservememory'} = "max";
       } else {
          #$dupVM{$vm}{$vmIndex}{'vmstate'} = "poweron";
          #$dupVM{$vm}{$vmIndex}{'reservememory'} = "max";
       }
    }
   }

   return $dupVM{vm};
}


########################################################################
#
# ConfigureHost--
#     Routine to upgrade the host section of teatbedspec
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub ConfigureHost
{
   my $self                   = shift;
   my $parameters             = $self->{testcaseHash}{Parameters};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   tie my %dupHost, 'Tie::IxHash';

   my $hostkeys = $TestbedSpecLookUpTable->{hostkeys};
   my $hostSpecReturn = {};
   tie %$hostSpecReturn, 'Tie::IxHash';

   $vdLogger->Debug("Configure Host Start");

   my $inventoryCount = "1";
   foreach my $parameterKey (keys %$parameters) {
      my $hostSpecInitial = {};
      tie %$hostSpecInitial, 'Tie::IxHash';

      if (($parameterKey =~ m/vc/i) || ($parameterKey =~ m/Rules/i) ||
          ($parameterKey =~ m/Override/i) || ($parameterKey =~ m/vdsversion/i)) {
         next;
      }
      #$hostkey = "" . "[$inventoryCount]" . "";
      foreach my $key (@$hostkeys) {
         $vdLogger->Debug("machine=$parameterKey, key = $key");
         my $value = $parameters->{$parameterKey}{$key};
         my $method = $TestbedSpecLookUpTable->{$key};
         if ((not defined $value) && ($key =~ /vmnic/i)) {
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            if (!(exists($host1Machines{$parameterKey}))) {
               #$value = ['any:1']; <---TODO
            }
         }
         my $count = 1;
         foreach my $element (@$value) {
            my $type = undef;
            my $range = undef;
            if (ref($element) eq "HASH") {
               my $temp = $self->$method($inventoryCount,$type,$range,$parameterKey,$element,$count);
               if (defined $temp) {
                  my $hostSpecInitial = $self->MergeSpec($temp, $hostSpecInitial);
                  #$hostSpecInitial = {%$temp, %$hostSpecInitial};
               }
               $count++;
            } else {
               ($type, $range) = split(':', $element);
               $vdLogger->Debug("key=$key, type = $type and quantity = $range count=$count");
               $range = $self->ConvertToRange($range);
               if ($type =~ m/vds/i) {
                  next;
               }
               my $temp = $self->$method($inventoryCount,$type,$range,$parameterKey,$element,$count);
               if (defined $temp) {
                  my $hostSpecInitial = $self->MergeSpec($temp, $hostSpecInitial);
                  #$hostSpecInitial = {%$temp, %$hostSpecInitial};
               }
               $count++;
            }

         }
      }
      $hostSpecReturn->{$parameterKey} = $hostSpecInitial;
   }

   if ((!keys %{$hostSpecReturn->{SUT}}) &&
       (!keys %{$hostSpecReturn->{helper1}})) {
      $vdLogger->Debug("Skipping the configuration of host spec");
      return "SKIP";
   }


   my $mergedHash = ();
   tie my %mergeHashTemp , 'Tie::IxHash';
   # Merging and Adding spec to Host 1 under TestbedSpec
   foreach my $machine (@{$TestbedSpecLookUpTable->{'host1'}}) {
      my $falseHash = ();
      if (!($mergedHash)) {
         $mergedHash = $hostSpecReturn->{$machine};
      }
      $mergedHash = $self->MergeSpec($hostSpecReturn->{$machine}, $mergedHash);
   }

   %mergeHashTemp = %$mergedHash;
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'} = $mergedHash;
   #TIE
   $dupHost{'host'}{'[1]'} = $mergedHash;
   # Merging and Adding spec to Host 2 under TestbedSpec
   # re-initialising the hash to null
   $mergedHash = ();
   if (defined $TestbedSpecLookUpTable->{'host2'}) {
      foreach my $machine (@{$TestbedSpecLookUpTable->{'host2'}}) {
         my $falseHash = ();
         if (!($mergedHash)) {
            $mergedHash = $hostSpecReturn->{$machine};
         }
         $mergedHash = $self->MergeSpec($hostSpecReturn->{$machine}, $mergedHash);
      }
      
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'} = $mergedHash;
      #TIE
      $dupHost{'host'}{'[2]'} = $mergedHash;
   }
   return $dupHost{host};
}

sub CorrectVSSVDSHost2
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectVSSVDSHost2");



   my $parameters             = $self->{testcaseHash}{Parameters};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #print "===1===" . Dumper($TestbedSpecLookUpTable); 
   my $host2helperArray = $TestbedSpecLookUpTable->{host2};

   my $firstSwitch;
   my $vssSwitch;
   my $helper;
   foreach my $element (@$host2helperArray) {
      my $host2vssArray = $parameters->{$element}{switch};
      $firstSwitch = $host2vssArray->[0];
      if ($firstSwitch =~ /vss/i) {
         $helper = $element;
         $vssSwitch = $firstSwitch;
      }
   }
   
   #print "===1=$helper==$vssSwitch" . Dumper($TestbedSpecLookUpTable); 
   if ((defined $helper) && ($vssSwitch =~ /vss/i)) {
      #correcting the host2 association with vds
      $self->{testcaseHash}{TestbedSpec}{'vc'}{'[1]'}{"vds"}{'[1]'}{'vmnicadapter'} = "host.[1].vmnic.[1]";
      $self->{testcaseHash}{TestbedSpec}{'vc'}{'[1]'}{"vds"}{'[1]'}{'host'} = "host.[1].x.[x]";
      $dupTestbedSpec->{'vc'}{'[1]'}{"vds"}{'[1]'}{'vmnicadapter'} = "host.[1].vmnic.[1]";
      $dupTestbedSpec->{'vc'}{'[1]'}{"vds"}{'[1]'}{'host'} = "host.[1].x.[x]";
   } else {
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{vss}{'[1]'} = {};
      $dupTestbedSpec->{'host'}{'[2]'}{vss}{'[1]'} = {};
   }

   # Also correct portgroup association for vm

   # Get all vms in the array [SUT, hlper1...]
   # New Addition
   if (not defined $TestbedSpecLookUpTable->{vmarray}) {
      return $dupTestbedSpec;
   }
   my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
   # Get all machines under host2
   my %host2Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host2'}};

   foreach my $machine (keys %host2Machines) {
      my $index = first { $nums[$_] eq $machine } 0..$#nums;
      my $inventoryIndex = $index + "1";
      if (exists $dupTestbedSpec->{'vm'}{"[$inventoryIndex]"}) {
         my $pg = $dupTestbedSpec->{'vm'}{"[$inventoryIndex]"}{'vnic'}{'[1]'}{'portgroup'};
         if ($pg eq "vc.[1].dvportgroup.[1]") {
            # Hard coding it, need to be careful
            $dupTestbedSpec->{'vm'}{"[$inventoryIndex]"}{'vnic'}{'[1]'}{'portgroup'} = "host.[2].portgroup.[1]";
         }
      }
   }
   return $dupTestbedSpec;
}


sub CorrectVmnicOnHost2
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectVmnicOnHost2");
   my @arrayOfKeys = keys %{$dupTestbedSpec->{'host'}{'[2]'}{"vmnic"}};
   my ($firstkey, $secondkey, $range);
   $firstkey = $arrayOfKeys[0];
   $secondkey = $arrayOfKeys[1];

  if (($firstkey !~ /\-/) && ($firstkey !~ /\-/))  {
     # no need to split, there is no 1 and 1-2
     return $dupTestbedSpec;
  } else {
     $secondkey =~ s/\[|\]//g;
     $firstkey =~ s/\[|\]//g;
  }

   my @rangeOfVmnicHost2 = split ('\-', $secondkey);
   my @range2OfVmnicHost2 = split ('\-', $firstkey);
   my @newArrayToSort;
   $newArrayToSort[0] = $rangeOfVmnicHost2[0] || 1;
   $newArrayToSort[1] = $rangeOfVmnicHost2[1] || 1;
   $newArrayToSort[2] = $range2OfVmnicHost2[0] || 1;
   $newArrayToSort[3] = $range2OfVmnicHost2[1] || 1;
   @newArrayToSort = sort(@newArrayToSort);
   my $lowest = $newArrayToSort[0];
   my $highest = $newArrayToSort[3];
   if ($lowest == $highest) {
      $range = "[$lowest]";
   } else {
      $range = "[$lowest-$highest]";
   }

   delete $dupTestbedSpec->{'host'}{'[2]'}{"vmnic"};
   $dupTestbedSpec->{'host'}{'[2]'}{"vmnic"}{"$range"}{'driver'} = 'any';
   return $dupTestbedSpec;
}

sub CorrectPGHost2Miusmatch
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectPGHost2Miusmatch");
}


sub CorrectPswitchPort
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside CorrectPswitchPort");
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   

   
   #print "===12===" . Dumper($TestbedSpecLookUpTable);
   if (defined $TestbedSpecLookUpTable->{host1pswitchportCount}) {
    
      my $host1count = $TestbedSpecLookUpTable->{host1pswitchportCount};
      #print "===13===$host1count";
      while ($host1count > 0) {
       #print "===4===$host1count";
         if (defined $TestbedSpecLookUpTable->{"host.[1].pswitchport.[$host1count]"}) {
            my $vmnicTuple = $TestbedSpecLookUpTable->{"host.[1].pswitchport.[$host1count]"};
            $dupTestbedSpec->{'host'}{'[1]'}{"pswitchport"}{"[$host1count]"}{'vmnic'} = $vmnicTuple;
            #$host1count--;
         }
         $dupTestbedSpec->{'pswitch'}{'[-1]'} = {};
         $host1count--;
      }
   }
   if (defined $TestbedSpecLookUpTable->{host2pswitchportCount}) {
      my $host2count = $TestbedSpecLookUpTable->{host2pswitchportCount};
      #print "===23===$host2count";
      while ($host2count > 0) {
         if (defined $TestbedSpecLookUpTable->{"host.[2].pswitchport.[$host2count]"}) {
            my $vmnicTuple = $TestbedSpecLookUpTable->{"host.[2].pswitchport.[$host2count]"};
            $dupTestbedSpec->{'host'}{'[2]'}{"pswitchport"}{"[$host2count]"}{'vmnic'} = $vmnicTuple;
            #$host2count--;
         }
         $dupTestbedSpec->{'pswitch'}{'[-1]'} = {};
         $host2count--;
      }
   }
   # Trying initialize and resolve LLDP
   #$TestbedSpecLookUpTable->{'host1pswitchportCount'} = undef;
   #$TestbedSpecLookUpTable->{'host2pswitchportCount'} = undef;
   return $dupTestbedSpec;
}


sub AddVmknicToHost1InCaseMissed
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside AddVmknicToHostInCaseMissed");
   $dupTestbedSpec->{'host'}{'[1]'}{"vmnic"}{'[1]'}{"driver"} ="any";
   return $dupTestbedSpec;
}


sub AddVmknicToHost2InCaseMissed
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside AddVmknicToHostInCaseMissed");
   $dupTestbedSpec->{'host'}{'[2]'}{"vmnic"}{'[1]'}{"driver"} ="any";
   return $dupTestbedSpec;
}


sub MandatoryConfigureHost1
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside MandatoryConfigureHost1");
   #return $self->MandatoryConfigureHostForPGAndVSS($dupTestbedSpec);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my ($switchArray,$vssCount);
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"vmnic"}{'[1]'}{"driver"} ="any";
   #Tie
   $dupTestbedSpec->{'host'}{'[1]'}{"vmnic"}{'[1]'}{"driver"} ="any";

   #print "====111====" . Dumper($TestbedSpecLookUpTable);
   if ((exists $dupTestbedSpec->{'vm'}) &&
       (exists $dupTestbedSpec->{'vm'}{'[1]'}{'vnic'}) &&
       (defined $TestbedSpecLookUpTable->{'vnicPGType'}) &&
       ($TestbedSpecLookUpTable->{'vnicPGType'} eq "portgroup")) {
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"vss"}{'[1]'} = {};
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

      #Tie
      $dupTestbedSpec->{'host'}{'[1]'}{"vss"}{'[1]'} = {};
      $dupTestbedSpec->{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

      push @{$TestbedSpecLookUpTable->{sutswitcharray}}, "host.[1].vss.[1]";
      $TestbedSpecLookUpTable->{'host1pgCount'} = "1";
      $TestbedSpecLookUpTable->{'host1vssCount'} = "1";
   }
   #print "====111====" . Dumper($dupTestbedSpec);
   return $dupTestbedSpec;
}


sub AddHostIfOnlyHostKeyPresentInSUT
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Info("Inside MandatoryConfigureHost1");
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'} ={};
   #Tie
   $dupTestbedSpec->{'host'}{'[1]'} ={};
   return $dupTestbedSpec;
}


sub MandatoryConfigureHost2
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside MandatoryConfigureHost2");
   my ($switchArray,$vssCount);
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"vmnic"}{'[1]'}{"driver"} ="any";
   #Tie
   $dupTestbedSpec->{'host'}{'[2]'}{"vmnic"}{'[1]'}{"driver"} ="any";
   #print "===1===" . Dumper($self->{testcaseHash}{TestbedSpec});
   return $dupTestbedSpec;
}


sub MandatoryConfigureHost2PCI
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   $vdLogger->Debug("Inside MandatoryConfigureHost2PCI");
   #return $self->MandatoryConfigureHostForPGAndVSS($dupTestbedSpec);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"vss"}{'[1]'} = {};
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"portgroup"}{'[1]'}{'vss'} = "host.[2].vss.[1]";
   #Tie
   $dupTestbedSpec->{'host'}{'[2]'}{"vss"}{'[1]'} = {};
   $dupTestbedSpec->{'host'}{'[2]'}{"portgroup"}{'[1]'}{'vss'} = "host.[2].vss.[1]";

   push @{$TestbedSpecLookUpTable->{host2switcharray}}, "host.[2].vss.[1]";
   $TestbedSpecLookUpTable->{'host2pgCount'} = "1";
   $TestbedSpecLookUpTable->{'host2vssCount'} = "1";

   #print "====111====" . Dumper($dupTestbedSpec);
   return $dupTestbedSpec;
}



sub FillVmnicCountForUplinkUsage
{
   my $self = shift;
   $vdLogger->Debug("Inside FillVmnicCountForUplinkUsage");
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $host1Range = $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"vmnic"};
   $host1Range =~ s/\[|\]//g;
   my $listofVmnicsHost1 = $self->ConvertRangeToCommaSeparatedValues($host1Range);
   my @arrayOfVmnicsHost1 = split('\,', $listofVmnicsHost1);
   $TestbedSpecLookUpTable->{'host1vmnicCount'} = pop @arrayOfVmnicsHost1;
   if ((exists $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}) &&
       (exists $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{'vmnic'})) {
      my $host2Range = $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"vmnic"};
      $host2Range =~ s/\[|\]//g;
      my $listofVmnicsHost2 = $self->ConvertRangeToCommaSeparatedValues($host2Range);
      my @arrayOfVmnicsHost2 = split('\,', $listofVmnicsHost2);
      $TestbedSpecLookUpTable->{'host2vmnicCount'} = pop @arrayOfVmnicsHost2;
   }
}


sub MandatoryConfigureHostForPGAndVSS
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   $vdLogger->Debug("Inside MandatoryConfigureHostForPGAndVSS");
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"vss"}{'[1]'} = {};
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

   #Tie
   $dupTestbedSpec->{'host'}{'[1]'}{"vss"}{'[1]'} = {};
   $dupTestbedSpec->{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

   push @{$TestbedSpecLookUpTable->{sutswitcharray}}, "host.[1].vss.[1]";
   $TestbedSpecLookUpTable->{'host1pgCount'} = "1";
   $TestbedSpecLookUpTable->{'host1vssCount'} = "1";

   if (defined $TestbedSpecLookUpTable->{'host2'}) {
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"vss"}{'[1]'} = {};
      $self->{testcaseHash}{TestbedSpec}{'host'}{'[2]'}{"portgroup"}{'[1]'} = "host.[2].vss.[1]";
      #Tie
      $dupTestbedSpec->{'host'}{'[2]'}{"vss"}{'[1]'} = {};
      $dupTestbedSpec->{'host'}{'[2]'}{"portgroup"}{'[1]'}{'vss'} = "host.[2].vss.[1]";
      $TestbedSpecLookUpTable->{'host1vssCount'} = "1";
      $TestbedSpecLookUpTable->{'host2pgCount'} = "1";
   }
   return $dupTestbedSpec;
}


sub MandatoryConfigureHost1ForPGAndVSS
{
   my $self = shift;
   my $dupTestbedSpec = shift;
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   $vdLogger->Debug("Inside MandatoryConfigureHostForPGAndVSS");
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"vss"}{'[1]'} = {};
   $self->{testcaseHash}{TestbedSpec}{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

   #Tie
   $dupTestbedSpec->{'host'}{'[1]'}{"vss"}{'[1]'} = {};
   $dupTestbedSpec->{'host'}{'[1]'}{"portgroup"}{'[1]'}{'vss'} = "host.[1].vss.[1]";

   push @{$TestbedSpecLookUpTable->{sutswitcharray}}, "host.[1].vss.[1]";
   $TestbedSpecLookUpTable->{'host1pgCount'} = "1";
   $TestbedSpecLookUpTable->{'host1vssCount'} = "1";
   return $dupTestbedSpec;
}


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
         if (defined $specTobeUpdated->{$item}) {
         # recursive call to process all component specs
         $specTobeUpdated->{$item} = $self->MergeSpec($customSpec->{$item},
                                                      $specTobeUpdated->{$item}
                                                      );
         } else {
            $specTobeUpdated->{$item} = $customSpec->{$item};
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
         if ($specTobeUpdated->{$item} =~ /\<|\>/) {
            $vdLogger->Debug("Overriding $item with $customSpec->{$item}");
         } else {
            # TBD: whether to throw error/skip if something can't be overridden
            #$vdLogger->Warn("Cannot override $item since it is not a variable");
         }
      }
   }
   return $specTobeUpdated;
}


sub ConfigureSwitch
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;
   my $hostSpec;

   my $parameters             = $self->{testcaseHash}{Parameters};
   my $vdsuplink;
   if (exists $parameters->{$sutHelper}{vdsuplink}) {
      $vdsuplink = $parameters->{$sutHelper}{vdsuplink};
   }

   if ((not defined $inventoryCount) ||
       (not defined $type) ||
       (not defined $range)) {
      $vdLogger->Error("Either type=$type, inventoryCount=$inventoryCount or" .
                       "range=$range not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($type =~ m/vss/i) {
      $hostSpec = $self->ConfigureVSSwitch($inventoryCount,$type,$range,$sutHelper);
   } elsif ($type =~ m/vds/i) {
      $hostSpec = $self->ConfigureVDSwitch($inventoryCount,$type,$range,$sutHelper,$vdsuplink);
   }
   return $hostSpec;
}


sub ConfigureVSSwitch
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my ($hostSpec, $tuple);
   $vdLogger->Debug("Inside ConfigureVSSwitch");
   #$hostSpec->{$type}{"[1]"}{"vmnicadapter"} = "host.[$inventoryCount].vmnic.[1]";
   $hostSpec->{$type}{"[1]"}{"configureuplinks"} = "add";

   my $dupRange = $range;
   $dupRange =~ s/\[//g;
   $dupRange =~ s/\]//g;
   my @arr = split('-',$dupRange);
   my $numOfSwitch = @arr;
   if ($numOfSwitch > 1) {
      if ($arr[1] eq "2") {
         $dupRange = "" . "[$arr[1]]" . "";
      } else {
         $dupRange = "" . "[2-$arr[1]]" . "";
      }
      $hostSpec->{$type}{$dupRange} = {};
   }

   # Check if sutswitcharray is already filled for SUT
   # and if SUT==helper dont overwirte
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my ($switchArray,$vssCount);
   if (exists($host1Machines{$sutHelper})) {
      $switchArray = "sutswitcharray";
      $vssCount = "host1vssCount";
      $hostSpec->{$type}{"[1]"}{"vmnicadapter"} = "host.[1].vmnic.[1]";
      $tuple = "host.[1].$type.$range";
   } else {
      $switchArray = "host2switcharray";
      $vssCount = "host2vssCount";
      $hostSpec->{$type}{"[1]"}{"vmnicadapter"} = "host.[2].vmnic.[1]";
      $tuple = "host.[2].$type.$range";
   }

   my $refArray = VDNetLib::Common::Utilities::ProcessTuple($tuple);
   if (defined $TestbedSpecLookUpTable->{$switchArray}) {
      my %switcharray = map { $_ => 1 } @{$TestbedSpecLookUpTable->{$switchArray}};
      foreach my $element (@$refArray) {
         if (!(exists($switcharray{$element}))) {
            $TestbedSpecLookUpTable->{$switchArray} = $refArray;
         }
      }
   } else {
      $TestbedSpecLookUpTable->{$switchArray} = $refArray
   }
   $TestbedSpecLookUpTable->{$vssCount} = @{$TestbedSpecLookUpTable->{$switchArray}};
   $hostSpec = $self->ConfigurePortGroup($hostSpec,$sutHelper);
   return $hostSpec;
}


sub ConfigurePortGroup
{
   my $self           = shift;
   my $hostSpec       = shift;
   my $sutHelper      = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $vdLogger->Debug("Inside ConfigurePortGroup");
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my ($switchArray, $hostpgCount, $tuple, $pgArray, $host1host2pgCount);
   if (exists($host1Machines{$sutHelper})) {
      $switchArray = "sutswitcharray";
      $hostpgCount = "host1pgCount";
   } else {
      $switchArray = "host2switcharray";
      $hostpgCount = "host2pgCount";
   }


   my $arrayRefForAllVSS = $TestbedSpecLookUpTable->{$switchArray};
   my $pgCount = 1;

   foreach my $vssTuple (@$arrayRefForAllVSS) {
      my $index = "" . "[$pgCount]" . "";
      $hostSpec->{'portgroup'}{$index}{'vss'} = $vssTuple;
      $TestbedSpecLookUpTable->{'$hostpgCount'} = $pgCount;
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$sutHelper})) {
         $pgArray = "host1pgarray";
         $host1host2pgCount = "host1pgCount";
         $tuple = "host.[1].portgroup.[$pgCount]";
      } else {
         $pgArray = "host2pgarray";
         $host1host2pgCount = "host2pgCount";
         $tuple = "host.[2].portgroup.[$pgCount]";
      }

      my $refArray = VDNetLib::Common::Utilities::ProcessTuple($tuple);
      if (defined $TestbedSpecLookUpTable->{$pgArray}) {
         my %pgarray = map { $_ => 1 } @{$TestbedSpecLookUpTable->{$pgArray}};
         foreach my $element (@$refArray) {
            if (!(exists($pgarray{$element}))) {
               #$TestbedSpecLookUpTable->{$pgArray} = $refArray;
               push @{$TestbedSpecLookUpTable->{$pgArray}} , $tuple;
            }
         }
      } else {
         $TestbedSpecLookUpTable->{$pgArray} = $refArray
      }
      $TestbedSpecLookUpTable->{$host1host2pgCount} = $pgCount;
      $pgCount++;
   }

   return $hostSpec;
}


sub ConfigureVmknic
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $hostSpec;
   my $hostvmknicCount;
   my $hostVmknicTuple;
   my $num = $type;
   $num =~ s/\D//g;
   my $index = $num-1;
   my $rangeVmknic = $range;
   $rangeVmknic =~ s/\[|\]//g;
   my ($minVmknic, $maxVmknic) = split ('-', $rangeVmknic);
   if (not defined $maxVmknic) {
      #that means both are 1
      $maxVmknic = "1";
   }
   $vdLogger->Debug("Inside ConfigureVmknic type=$type range=$range num=$num");
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my ($pgArray, $hostpgCount, $switchArray, $hostIndex);
   if (exists($host1Machines{$sutHelper})) {
      $pgArray = "host1pgarray";
      $hostvmknicCount = "host1vmknicCount";
      $hostVmknicTuple = "host1vmknicTuple";
      $switchArray = "sutswitcharray";
      $hostpgCount = "host1pgCount";
      $hostIndex = "[1]";
   } else {
      $pgArray = "host2pgarray";
      $hostVmknicTuple = "host2vmknicTuple";
      $hostvmknicCount = "host2vmknicCount";
      $switchArray = "host2switcharray";
      $hostpgCount = "host2pgCount";
      $hostIndex = "[2]";
   }
   #$range = "[$range]";
   #print "===1====" . Dumper($TestbedSpecLookUpTable);
   for (my $vmknicIndex = "1"; $vmknicIndex <= $maxVmknic; $vmknicIndex++) {
      my $switchType = $TestbedSpecLookUpTable->{sutswitcharray};
      my $vmknicIndexBrackets = '[' . $vmknicIndex . ']';
      if ($switchType->[0] =~ /vss/i) {
         my $refToPGArray = $TestbedSpecLookUpTable->{$pgArray};
         #if (defined $refToPGArray->[$index]) {
         my $hostpgCountNumber = $TestbedSpecLookUpTable->{$hostpgCount};
         $hostpgCountNumber = $hostpgCountNumber + "1";
         my $pgNewTuple = "host.$hostIndex.portgroup.[$hostpgCountNumber]";
         $hostSpec->{"vmknic"}{$vmknicIndexBrackets}{"portgroup"} = $pgNewTuple;
         push @{$TestbedSpecLookUpTable->{$pgArray}}, $pgNewTuple;
         $TestbedSpecLookUpTable->{$hostpgCount} = $hostpgCountNumber;
         # Added the vmknic tuple to testbedspec
         $TestbedSpecLookUpTable->{$hostVmknicTuple}{$hostpgCountNumber} = "host.$hostIndex.vmknic.$vmknicIndexBrackets";
         $hostpgCountNumber = '[' . $hostpgCountNumber . ']';
         $type =~ s/\D//g;
         $type = $type - "1";
         my @vssArray = @{$TestbedSpecLookUpTable->{$switchArray}};
         $hostSpec->{portgroup}{$hostpgCountNumber}{'vss'} = $vssArray[$type];
      } else {
        $pgArray = "vcdvpgarray";
        my $refToPGArray = $TestbedSpecLookUpTable->{$pgArray};
        my $vcDvpgCount = @$refToPGArray;
        $vcDvpgCount = $vcDvpgCount + "1";
        if (defined $refToPGArray->[$index]) {
           my $pgNewTuple = "vc.[1].dvportgroup.[$vcDvpgCount]";
           $hostSpec->{"vmknic"}{$vmknicIndexBrackets}{"portgroup"} = $pgNewTuple;
           push @{$TestbedSpecLookUpTable->{$pgArray}}, $pgNewTuple;
           $vcDvpgCount = '[' . "$vcDvpgCount" . ']';
           $type =~ s/\D//g;
           $type = $type - "1";
           my @vssArray = @{$TestbedSpecLookUpTable->{sutswitcharray}};
           $hostSpec->{vc}{'[1]'}{dvportgroup}{$vcDvpgCount}{'vds'} = $vssArray[$type];
        }
        
      }
   }
   $range =~ s/\[|\]//g;
   my $listofVmknics = $self->ConvertRangeToCommaSeparatedValues($range);
   my @arrayOfVmknics = split('\,', $listofVmknics);
   $TestbedSpecLookUpTable->{$hostvmknicCount} = pop @arrayOfVmknics;
   #print "===1==vmknic==" . Dumper($hostSpec);
   #print "===2===$listofVmknics";
   return $hostSpec;
}


sub ConfigureVmnic
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;
   my $element      = shift;
   my $count      = shift;

   my $hostSpec;
   my $hostvmnicCount;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #$range = "[$range]";
   if (ref($element) eq "HASH") {
      $vdLogger->Debug("Inside ConfigureVmnic for machine:$sutHelper");
      my $range = "[" . $count . "]";
      #print "===1===" . Dumper($element);
      my $upperRange=$count;
      if ((exists $element->{count}) && 
         ($element->{count} > $count)) {
         my $range2 = "[" . $element->{count} . "]";
         $hostSpec->{"vmnic"}{$range2} = $element;
      }

      $hostSpec->{"vmnic"}{$range} = $element;
      if (defined $hostvmnicCount) {
         $TestbedSpecLookUpTable->{$hostvmnicCount} = $element->{count};
      }
      #$TestbedSpecLookUpTable->{$hostvmnicCount} = $element->{count};
      delete $element->{count};
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      my ($switchArray, $hostpgCount);
      if (exists($host1Machines{$sutHelper})) {
         $hostvmnicCount = "host1vmnicCount";
      } else {
         $hostvmnicCount = "host2vmnicCount";
      }
      #$TestbedSpecLookUpTable->{$hostvmnicCount} = $upperRange;
      return $hostSpec;
   } else {
      my $lowerRange;
      my $num = $type =~ /(\d+)/;
      $vdLogger->Debug("Inside ConfigureVmnic $type $range $num for machine:$sutHelper");
      $hostSpec->{"vmnic"}{$range}{"driver"} ="$type";
      $range =~ s/\[|\]//g;
      my $listofVmnics = $self->ConvertRangeToCommaSeparatedValues($range);
      my @arrayOfVmnics = split('\,', $listofVmnics);
   
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      my ($switchArray, $hostpgCount);
      if (exists($host1Machines{$sutHelper})) {
         $hostvmnicCount = "host1vmnicCount";
      } else {
         $hostvmnicCount = "host2vmnicCount";
      }
      $TestbedSpecLookUpTable->{$hostvmnicCount} = pop @arrayOfVmnics;
      return $hostSpec;
   }
}



sub ConfigureVDSwitch
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;
   my $vdsUplink      = shift || undef;

   my $vdl2VDS2Special = "0";
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if ($self->{testcaseHash}{testID} =~ m/vdl2/i) {
      my @nums = @{$TestbedSpecLookUpTable->{VDL2}};
      my $index = undef;
      my $testname = $self->{testcaseHash}{TestName};
      $index = first { $nums[$_] =~ m/$testname/i } 0..$#nums;
      #print "===1===$testname";
      if ((defined $index) && ($testname ne "Configuration")) {
         $vdl2VDS2Special = 1;
      }
   }
   my $vcSpec         = {};
   tie %$vcSpec, 'Tie::IxHash';
   tie my %vcSpecDup, 'Tie::IxHash';
   tie my %vcSpecDup1, 'Tie::IxHash';
   tie my %vcSpecDup2, 'Tie::IxHash';
   $vdLogger->Debug("Inside ConfigureVDSwitch");

   # Add host and uplink
   my $tupleAddVmnicAdapter = "host.[$inventoryCount].vmnic.[1]";
   my $tupleAddhost = "host.[$inventoryCount].x.[x]";
   if ((defined $TestbedSpecLookUpTable->{'host2'})) { #&&
      #(not defined $TestbedSpecLookUpTable->{'host2vssCount'})) {
      $tupleAddVmnicAdapter = "host.[1-2].vmnic.[1]";
      $tupleAddhost = "host.[1-2].x.[x]";
      # Vmnic 1 under host 2 has been used
      $TestbedSpecLookUpTable->{'host2vmnicCountUsed'} = 1;
   }
   $vcSpec->{$type}{'[1]'}{"vmnicadapter"} = $tupleAddVmnicAdapter;
   # Reducing the count of vmnic adapter

   $vcSpec->{$type}{'[1]'}{"host"} = $tupleAddhost;
   # Vmnic 1 under host 1 has been used
   $TestbedSpecLookUpTable->{'host1vmnicCountUsed'} = 1;

   # Add simple keys
   $vcSpec->{$type}{'[1]'}{"configurehosts"} = "add";
   $vcSpec->{$type}{'[1]'}{"datacenter"} = "vc.[1].datacenter.[1]";
   $vcSpec->{$type}{'[1]'}{"datacenter"} = "vc.[1].datacenter.[1]";
   $TestbedSpecLookUpTable->{'host1vdsCount'} = 1;
   if (defined $vdsUplink) {
      $vcSpec->{$type}{'[1]'}{"numuplinkports"} = $vdsUplink;
   }
   if ( defined $TestbedSpecLookUpTable->{'version'}) {
      $vcSpec->{$type}{'[1]'}{"version"} =
                                $TestbedSpecLookUpTable->{'version'};
   }
   #TIE
   $vcSpecDup{$type}{'[1]'} = $vcSpec->{$type}{'[1]'};

   my $dupRange = $range;
   $dupRange =~ s/\[//g;
   $dupRange =~ s/\]//g;
   my @arr = split('-',$dupRange);
   my $numOfSwitch = @arr;
   if ($numOfSwitch > 1) {
      if ($arr[1] eq "2") {
         $dupRange = "" . "[$arr[1]]" . "";
         $TestbedSpecLookUpTable->{'host1vdsCount'} = 2;
      } else {
         $dupRange = "" . "[2-$arr[1]]" . "";
         $TestbedSpecLookUpTable->{'host1vdsCount'} = $arr[1];
      }
      $vcSpec->{$type}{$dupRange}{"datacenter"} = "vc.[1].datacenter.[1]";
      $vcSpec->{$type}{$dupRange}{"host"} = $tupleAddhost;
      $vcSpec->{$type}{$dupRange}{"configurehosts"} = "add";
      if (defined $vdsUplink) {
         $vcSpec->{$type}{$dupRange}{"numuplinkports"} = $vdsUplink;
      }
      if ( defined $TestbedSpecLookUpTable->{'version'}) {
         $vcSpec->{$type}{$dupRange}{"version"} =
                                   $TestbedSpecLookUpTable->{'version'};
      }
      #TIE
      $vcSpecDup{$type}{$dupRange} = $vcSpec->{$type}{$dupRange};
   }
   #$range = "[$range]";#-----check
   my $tuple = "vc.[$inventoryCount].$type.$range";

   my $refArray = VDNetLib::Common::Utilities::ProcessTuple($tuple);
   #print "adding vds $tuple" . Dumper($refArray);
   # Check if sutswitcharray is already filled for SUT
   # and if SUT==helper dont overwirte
   # Still need to handle case where
   # SUT and helper are not equal
   if (defined $TestbedSpecLookUpTable->{sutswitcharray}) {
      my %switcharray = map { $_ => 1 } @{$TestbedSpecLookUpTable->{sutswitcharray}};
      foreach my $element (@$refArray) {
         if (!(exists($switcharray{$element}))) {
            $TestbedSpecLookUpTable->{sutswitcharray} = $refArray;
         }
      }
   } else {
      $TestbedSpecLookUpTable->{sutswitcharray} = $refArray
   }
   $TestbedSpecLookUpTable->{'vcVdsCount'} = @{$TestbedSpecLookUpTable->{sutswitcharray}};
   $vcSpec = $self->ConfigureDVPortGroup($vcSpec);


   if ($vdl2VDS2Special eq "1") {
      $vcSpec->{$type}{'[2]'}{vmnicadapter} = 'host.[1-2].vmnic.[2]',
   }

   #return \%vcSpecDup;
   return $vcSpec;
}

sub ConfigureDVPortGroup
{
   my $self           = shift;
   my $vcSpec         = {};
   tie %$vcSpec, 'Tie::IxHash';
   $vcSpec         = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $vdLogger->Debug("Inside ConfigureDVPortGroup");
   my $arrayRefForAllVDS = $TestbedSpecLookUpTable->{sutswitcharray};
   my $dvpgCount = 1;
   foreach my $vdsTuple (@$arrayRefForAllVDS) {
      my $index = "" . "[$dvpgCount]" . "";
      #print "create vds for $vdsTuple";
      $vcSpec->{'dvportgroup'}{$index}{'vds'} = $vdsTuple;
      $TestbedSpecLookUpTable->{'dvpgpgCount'} = $dvpgCount;
      my ($pgArray, $tuple);
      $pgArray = "vcdvpgarray";
      $tuple = "vc.[1].dvportgroup.[$dvpgCount]";

      my $refArray = VDNetLib::Common::Utilities::ProcessTuple($tuple);
      if (defined $TestbedSpecLookUpTable->{$pgArray}) {
         my %pgarray = map { $_ => 1 } @{$TestbedSpecLookUpTable->{$pgArray}};
         foreach my $element (@$refArray) {
            if (!(exists($pgarray{$element}))) {
               push @{$TestbedSpecLookUpTable->{$pgArray}} , $tuple;
            }
         }
      } else {
         $TestbedSpecLookUpTable->{$pgArray} = $refArray
      }
      $dvpgCount++;
   }
   return $vcSpec;
}




sub ConfigureVnic
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;
   my $vmSpec;
   my $num = $type =~ /(\d+)/;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
   my $pgTuple;
   if ((defined $refToSwitchArray->[0]) &&
       ($refToSwitchArray->[0] =~ m/vds/i)) {
      $TestbedSpecLookUpTable->{'vnicPGType'} = "dvpg";
      $pgTuple = "vc.[1].dvportgroup.[1]";
   } else {
      $TestbedSpecLookUpTable->{'vnicPGType'} = "portgroup";
      $pgTuple = "host.[1].portgroup.[1]";
   }
   $vdLogger->Debug("Inside ConfigureVnic $type $range $num");
   #$range = "[$range]";
   $vmSpec->{"vnic"}{$range}{"driver"} = "$type";
   $vmSpec->{"vnic"}{$range}{"portgroup"} = "$pgTuple";
   if ($sutHelper =~ /SUT/i) {
      $TestbedSpecLookUpTable->{sutVnicCount} = $TestbedSpecLookUpTable->{sutVnicCount} + 1;
   }
   #$vmSpec->{"vnic"}{$range}{"ipv4address"} = "auto";
   #print "===2===" .Dumper($vmSpec);
   return $vmSpec;
}


sub ConfigureDatastoreType
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $sutHelper      = shift;

   my $vmSpec;
   $vdLogger->Debug("Inside ConfigureDatastoreType $type $range");
   if (defined $type) {
      $vmSpec->{datastoreType} = $type;
   }

   return $vmSpec;
}


sub  ConfigurePCI
{
   my $self           = shift;
   my $inventoryCount = shift;
   my $type           = shift;
   my $range          = shift;
   my $vmSpec;
   my $num = $type =~ /(\d+)/;
   $vdLogger->Debug("Inside ConfigurePCI $type $range $num");
   #$range = "[$range]";
   $vmSpec->{"pci"}{$range}{"driver"} ="$type";
   return $vmSpec;
}

sub  ConfigurePCIHASH
{
   my $self  = shift;
   my $hash  = shift;
   my $sutHelper = shift;
   my $count = "1";

   my $pciIndex = '[' . $count . ']';
   my $vmSpec;
   $vdLogger->Debug("Inside ConfigurePCIHASH: $sutHelper");
   #$range = "[$range]";
   #$vmSpec->{vnic} = $hash;

   $hash = VDNetLib::Common::Utilities::ExpandTuplesInSpec($hash);
   foreach my $key (keys %$hash) {
      $count = $key;
      my $pciIndex = '[' . $count . ']';
      my @arrayOfVMnics;
      if (defined $hash->{$key}{passthrudevice}) {
         my $oldWorkload->{testadapter} = $hash->{$key}{passthrudevice};
         my $dummyneworkload = $self->HelperTestAdapter($oldWorkload);
         push @arrayOfVMnics, $dummyneworkload->{testadapter};
      }
      $vmSpec->{"pcipassthru"}{$pciIndex}{"vmnic"} = join ",",@arrayOfVMnics;
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
      my $pgTuple;
      if ((defined $refToSwitchArray->[0]) &&
          ($refToSwitchArray->[0] =~ m/vds/i)) {
         #$TestbedSpecLookUpTable->{'vnicPGType'} = "dvpg";
         $pgTuple = "vc.[1].dvportgroup.[1]";
      } else {
         #$TestbedSpecLookUpTable->{'vnicPGType'} = "portgroup";
         $pgTuple = "host.[1].portgroup.[1]";
      }
      #$vdLogger->Debug("Inside ConfigureVnic $type $range $num");
      #$range = "[$range]";
      if ($hash->{$key}{driver}) {
         $vmSpec->{"pcipassthru"}{$pciIndex}{"driver"} = $hash->{$key}{driver};
      } else {
         # special case for sriov
         #print "===1===" . Dumper($self->{testcaseHash}{TestbedSpec});
         if (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic}{'[1]'}{passthrough}) {
            $vmSpec->{"pcipassthru"}{$pciIndex}{"driver"} = $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic}{'[1]'}{passthrough}{type};
         } elsif (exists $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic}{'[1]'}{driver}) {
            $vmSpec->{"pcipassthru"}{$pciIndex}{"driver"} = $self->{testcaseHash}{TestbedSpec}{host}{'[1]'}{vmnic}{'[1]'}{driver};
         }

      }
      $vmSpec->{"pcipassthru"}{$pciIndex}{"portgroup"} = "$pgTuple";
   }
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $key = $sutHelper."PCICount";
   $TestbedSpecLookUpTable->{$key} = $count;
   #print "===1===ConfigurePCIhash" . Dumper($vmSpec);
   return $vmSpec;
}


sub GetTestbedSpecLookUpTable
{
   return TestbedSpecLookUpTable;
}

sub GetWorkloadLookUpTable
{
   return WorkloadLookUpTable;
}

sub GetvdNetConstantTable
{
   return vdNetConstantTable;
}

sub UpgradeWorkload
{
   my $self = shift;
   my $TestbedSpec = shift;
   my $newWorkloadList;
   my $workload = $self->{testcaseHash}{WORKLOADS};
   my $arryOfSequence = $self->{testcaseHash}{WORKLOADS}{Sequence};
   my $arrayOfExitSequence = $self->{testcaseHash}{WORKLOADS}{ExitSequence};
   my @masterArrayWorkloadList;
   tie my %dupWorkload, 'Tie::IxHash';

   #Add Sequence
   $dupWorkload{Sequence} = $self->{testcaseHash}{WORKLOADS}{Sequence};

   #Add Exit Sequence
   if (defined $self->{testcaseHash}{WORKLOADS}{ExitSequence}) {
      $dupWorkload{ExitSequence} = $self->{testcaseHash}{WORKLOADS}{ExitSequence};
   }
   #Add Duration
   if (defined $self->{testcaseHash}{WORKLOADS}{Duration}) {
      $dupWorkload{Duration} = $self->{testcaseHash}{WORKLOADS}{Duration};
   }
   #Add Iterations
   if (defined $self->{testcaseHash}{WORKLOADS}{Iterations}) {
      $dupWorkload{Iterations} = $self->{testcaseHash}{WORKLOADS}{Iterations};
   }

   #Construct Master list
   if (defined $arryOfSequence) {
      my $workArray = $arryOfSequence;
      foreach my $set (@{$workArray}) {
         foreach my $eachElementofSet (@$set) {
            if (!(@masterArrayWorkloadList)) {
               push @masterArrayWorkloadList, $eachElementofSet;
               next;
            }
            my %UniqueWorkloads = map { $_ => 1 } @masterArrayWorkloadList;
            if (!(exists($UniqueWorkloads{$eachElementofSet}))) {
               push @masterArrayWorkloadList, $eachElementofSet;
               next;
            }
         }
      }
   } else {
      return undef;
   }
   if (defined $arrayOfExitSequence) {
      my $workArray = $arrayOfExitSequence;
      foreach my $set (@{$workArray}) {
         foreach my $eachElementofSet (@$set) {
            if (!(@masterArrayWorkloadList)) {
               push @masterArrayWorkloadList, $eachElementofSet;
               next;
            }
            my %UniqueWorkloads = map { $_ => 1 } @masterArrayWorkloadList;
            if (!(exists($UniqueWorkloads{$eachElementofSet}))) {
               push @masterArrayWorkloadList, $eachElementofSet;
               next;
            }
         }
      }
   }
   #print Dumper(@masterArrayWorkloadList);
   my $newWorkloadVeri = ();
   tie %$newWorkloadVeri, 'Tie::IxHash';
   # Just for upgrading the verification
   foreach my $workload (keys %{$self->{testcaseHash}{WORKLOADS}}) {
      if (($workload =~ /Sequence/i) ||
          ($workload =~ /Duration/i) ||
          ($workload =~ /Iterations/i) ||
          ($workload =~ /IgnoreFailure/i) ||
          ($workload =~ /IgnoreFail/i) || 
          ($workload =~ /SkipSequence/i)) {
         next;
      }

      if ((exists $self->{testcaseHash}{WORKLOADS}{$workload}{RunWorkload})) {
          my $thatworkload = $self->{testcaseHash}{WORKLOADS}{$workload}{RunWorkload};
          push @masterArrayWorkloadList, $thatworkload;
      }
      # Delete duplicate entries
      my %seen=();
      @masterArrayWorkloadList = grep { ! $seen{$_} ++ } @masterArrayWorkloadList;

      if (not defined $self->{testcaseHash}{WORKLOADS}{$workload}{Type}) {
         my $tempSleepbeforefinal;
         if (exists $self->{testcaseHash}{WORKLOADS}{$workload}{sleepbeforefinal}) {
            $tempSleepbeforefinal = $self->{testcaseHash}{WORKLOADS}{$workload}{sleepbeforefinal};
            delete $self->{testcaseHash}{WORKLOADS}{$workload}{sleepbeforefinal};
         }
         $self->{testcaseHash}{WORKLOADS}{$workload} = $self->PrepareVerification($self->{testcaseHash}{WORKLOADS}{$workload});
         $newWorkloadVeri->{$workload} = $self->{testcaseHash}{WORKLOADS}{$workload};
         if (defined $tempSleepbeforefinal) {
            $newWorkloadVeri->{$workload}{sleepbeforefinal} = $tempSleepbeforefinal;
            $self->{testcaseHash}{WORKLOADS}{$workload}{sleepbeforefinal} = $tempSleepbeforefinal;
         }
      } else {
         next;
      }

   }


   foreach my $refWorkload (@masterArrayWorkloadList) {
      my $newWorkload = ();
      tie %$newWorkload, 'Tie::IxHash';
      tie my %newWorkloadTie, 'Tie::IxHash';
      my $oldWorkload = ();
      my $workloadType = undef;
      my $method = undef;
      if (($refWorkload =~ /Sequence/i) ||
          ($refWorkload =~ /Duration/i) ||
          ($refWorkload =~ /Iterations/i)) {
         next;
      }

      my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
      $vdLogger->Debug("Upgrading workload $refWorkload");
      $method = $WorkloadLookUpTable->{lowercase};
      $oldWorkload = $self->$method($workload->{$refWorkload});
      $vdLogger->Debug("Converted old workload keys to lower case");

      #Adding the New Mgmt Keys
      if (not defined $workload->{$refWorkload}{type}) {
         $self->{testcaseHash}{WORKLOADS}{$refWorkload} = $self->PrepareVerification($workload->{$refWorkload}, $newWorkload);
         next;
      }
      $workloadType = $workload->{$refWorkload}{type};
      $vdLogger->Debug("Workload Type is $workloadType");
      $vdLogger->Debug("Got new workload structure");
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

      #Creating new test<> mgmtkey
      my ($mgmtKey, $mgmttype);
      $method = $WorkloadLookUpTable->{$workloadType}->{ProcessTestKey};
      if (defined $method) {
         $newWorkload = $self->$method($oldWorkload, $newWorkload,$TestbedSpec);
         #print "===1===" . Dumper($TestbedSpecLookUpTable);
         if (not defined $TestbedSpecLookUpTable->{MAGICINSERTION}) {
            my @keysOfWorkload = keys %$newWorkload;
            $mgmttype = $newWorkload->{Type} || $newWorkload->{type};
            $newWorkloadTie{Type} = $newWorkload->{Type};
            $mgmtKey = $WorkloadLookUpTable->{workloadType}{$mgmttype};
            if (defined $mgmtKey) {
               my $dupmgmtKey = lc($mgmtKey);
               $newWorkloadTie{$mgmtKey} = $newWorkload->{$dupmgmtKey};
            }
         }
      }
      #print "Might break after this" . Dumper($newWorkload);

      # Lets not discuss this part
      # MAGIC INSETION
      $vdLogger->Debug("Check if insertion is needed");
      if ($TestbedSpecLookUpTable->{MAGICINSERTION}) {
         $vdLogger->Debug("Start the insertion of workload process");
         my @newArrayOfWorkloads;
         foreach my $key (keys %$newWorkload) {
            my @keysOfWorkload = keys %{$newWorkload->{$key}};
            $mgmttype = $newWorkload->{$key}{Type};
            tie my %newWorkloadTie, 'Tie::IxHash';
            $newWorkloadTie{Type} = $newWorkload->{$key}{Type};
            $mgmtKey = $WorkloadLookUpTable->{workloadType}{$mgmttype};
            if (defined $mgmtKey) {
               my $dupmgmtKey = lc($mgmtKey);
               $newWorkloadTie{$mgmtKey} = $newWorkload->{$key}{$dupmgmtKey};
            }
            #print "STAGE1\n";
            $vdLogger->Debug("Created the new test <type> mgmt key");
            #Remove old mgmt keys from old workload
            $method = $WorkloadLookUpTable->{RemoveOldMgmtKeys};
            if ((defined $oldWorkload->{type}) && ($newWorkload->{$key}{'Type'} ne $oldWorkload->{type})) {
               $workload->{$refWorkload}{type} = $newWorkload->{$key}{'Type'};
            }
            #print "keyhash" . Dumper($newWorkload->{$key});
            $oldWorkload = $self->$method($WorkloadLookUpTable, $newWorkload->{$key});
            $vdLogger->Debug("Removed old mgmt keys from old workload");
            #print "STAGE2\n";
            #Merge Remaining keys from old workload
            $method = $WorkloadLookUpTable->{MergeRemainingKeys};
            $newWorkload->{$key} = $self->$method($oldWorkload,$newWorkload->{$key});
            $vdLogger->Debug("Merged new keys & remaining keys from old workload");
            # Entries to workload
            $self->{testcaseHash}{WORKLOADS}{$refWorkload} = $newWorkload;
            #print "STAGE3\n";
            foreach my $oldkey (keys %{$newWorkload->{$key}}) {
               if (($oldkey =~ /$mgmttype/i) ||
                   ((defined $mgmtKey) && ($oldkey =~ /$mgmtKey/i))) {
                  if ($oldkey ne "notifyswitch") {
                  next;
                  }
               }
               $newWorkloadTie{$oldkey} = $newWorkload->{$key}{$oldkey};
            }
            my $tempValue = $refWorkload;
            $refWorkload = $refWorkload . "_$key";
            #print "WILL be stored" . Dumper(\%newWorkloadTie);
            $dupWorkload{$refWorkload} = \%newWorkloadTie;
            push @newArrayOfWorkloads, $refWorkload;
            $refWorkload = $tempValue;
         }
         $vdLogger->Debug("Completed the insertion of workload process");
         $TestbedSpecLookUpTable->{MAGICINSERTION} = undef;
         $dupWorkload{Sequence} = $self->InsertNewWorkloadsSequence($dupWorkload{Sequence}, 
                                                                     \@newArrayOfWorkloads,
                                                                     $refWorkload);
         $dupWorkload{ExitSequence} = $self->InsertNewWorkloadsSequence($dupWorkload{ExitSequence}, 
                                                                     \@newArrayOfWorkloads,
                                                                     $refWorkload);
         next;
      }

      $vdLogger->Debug("Created the new test <type> mgmt key");
      #Remove old mgmt keys from old workload
      $method = $WorkloadLookUpTable->{RemoveOldMgmtKeys};
      if ((defined $newWorkload->{'Type'}) &&
          (defined $oldWorkload->{type}) &&
          ($newWorkload->{'Type'} ne $oldWorkload->{type})) {
         $workload->{$refWorkload}{type} = $newWorkload->{'Type'};
      }
      $oldWorkload = $self->$method($WorkloadLookUpTable, $workload->{$refWorkload});
      $vdLogger->Debug("Removed old mgmt keys from old workload");


      #Merge Remaining keys from old workload
      $method = $WorkloadLookUpTable->{MergeRemainingKeys};
      $newWorkload = $self->$method($oldWorkload,$newWorkload);
      $vdLogger->Debug("Merged new keys & remaining keys from old workload");
      # Entries to workload
      $self->{testcaseHash}{WORKLOADS}{$refWorkload} = $newWorkload;
   #print "===1===" .Dumper($newWorkload);
      foreach my $oldkey (keys %$newWorkload) {
         #print "==1==$oldkey===$mgmttype===$mgmtKey\n";
         if (((defined $mgmttype) && ($oldkey =~ /$mgmttype/i)) ||
             ((defined $mgmtKey) && ($oldkey =~ /$mgmtKey/i))) {
            if (($oldkey ne "notifyswitch") && ($oldkey ne "portstatus") &&
                 ($oldkey ne "checkcdponswitch") && ($oldkey ne "setlldpreceiveport") &&
                 ($oldkey ne "setlldptransmitport") &&
                 ($oldkey ne "getportrunningconfiguration") &&
                 ($oldkey ne "setportrunningconfiguration") &&
                 ($oldkey ne "verifyvnicswitchport") &&
                 ($oldkey ne "dvfilterhostsetup") &&
                 ($oldkey ne "vmotion") &&
                 ($oldkey ne "addporttodvportgroup") &&
                 ($oldkey ne "vmstate")) {
               next;
            }
         }
         # Check if VLAN reslated stuff is tere in the $TestbedSpecLookUpTable
#         if ((exists $TestbedSpecLookUpTable->{$newWorkload->{$oldkey}}) &&
#            ($oldkey =~ /vlan/i)) {
#            $newWorkload->{$oldkey} = $TestbedSpecLookUpTable->{$newWorkload->{$oldkey}};
#         }
         $newWorkloadTie{$oldkey} = $newWorkload->{$oldkey};
      }

      $dupWorkload{$refWorkload} = \%newWorkloadTie;
      #print "====2====" . Dumper($dupWorkload{$refWorkload});
   }

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $self->Cleanup();
   %dupWorkload = (%dupWorkload,%$newWorkloadVeri);
   #print "====1====" . Dumper($self->{testcaseHash}{TestbedSpec});
   #print "====2====" . Dumper(\%dupWorkload);
   return \%dupWorkload;
}


sub InsertNewWorkloadsSequence
{
   my $self = shift;
   my $arryOfSequence = shift;
   my $newArray = shift;
   my $toBeReplaced = shift;
   my @BrandNewArraySequence;
   my @BrandNewArraySequence2;

   my @replacingArray = [[$newArray->[0]],[$newArray->[1]]];

   #print "Old Sequence" . Dumper($arryOfSequence);
   #print "New Array" . Dumper(@replacingArray);
   #print "To be replaced...$toBeReplaced\n";
   foreach my $set (@{$arryOfSequence}) {
      foreach my $eachElementofSet (@$set) {
         if ($eachElementofSet eq $toBeReplaced) {
            push @BrandNewArraySequence, $replacingArray[0][0];
            push @BrandNewArraySequence, $replacingArray[0][1];
         } else {
            push @BrandNewArraySequence, $set;
         }
      }
   }
   #print "New Sequence" . Dumper(@BrandNewArraySequence);
   return \@BrandNewArraySequence;
}


sub Cleanup
{
   my $self = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $TestbedSpecLookUpTable->{'host1pgCount'}  = undef;
   $TestbedSpecLookUpTable->{'host2pgCount'}  = undef;
   $TestbedSpecLookUpTable->{'host1pgarray'}  = undef;
   $TestbedSpecLookUpTable->{'host2pgarray'}  = undef;
   $TestbedSpecLookUpTable->{'vcdvpgarray'}  = undef;
   $TestbedSpecLookUpTable->{'host1vssCount'} = undef;
   $TestbedSpecLookUpTable->{'host2vssCount'} = undef;
   $TestbedSpecLookUpTable->{'vcVdsCount'}    = undef;
   $TestbedSpecLookUpTable->{sutswitcharray}  = undef;
   $TestbedSpecLookUpTable->{'version'}    = undef;
   $TestbedSpecLookUpTable->{'dvpgpgCount'}   = undef;
   $TestbedSpecLookUpTable->{'host1vmnicCount'} = undef;
   $TestbedSpecLookUpTable->{'host2vmnicCount'} = undef;
   $TestbedSpecLookUpTable->{'host1vmnicCountUsed'} = undef;
   $TestbedSpecLookUpTable->{'host2vmnicCountUsed'} = undef;
   $TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'} = undef;
   $TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'} = undef;
   $TestbedSpecLookUpTable->{host1vmknicTuple} = undef;
   $TestbedSpecLookUpTable->{host2vmknicTuple} = undef;
   $TestbedSpecLookUpTable->{'dcCount'}         = undef;
   $TestbedSpecLookUpTable->{'sutswitcharray'} = undef;
   $TestbedSpecLookUpTable->{'host2switcharray'} = undef;
   $TestbedSpecLookUpTable->{"host2vmknicCount"} = undef;
   $TestbedSpecLookUpTable->{"host1vmknicCount"} = undef;
   #$TestbedSpecLookUpTable->{'host1pswitchportCount'} = undef;
   #$TestbedSpecLookUpTable->{'host2pswitchportCount'} = undef;
   delete $TestbedSpecLookUpTable->{'host1'};
   delete $TestbedSpecLookUpTable->{'host2'};
   $TestbedSpecLookUpTable->{sutVnicCount} = undef;
   delete $TestbedSpecLookUpTable->{vmarray};
   $TestbedSpecLookUpTable->{'vnicPGType'} = undef;
   $TestbedSpecLookUpTable->{MAGICINSERTION} = undef;
   #$TestbedSpecLookUpTable->{vccount} = "0";
   $TestbedSpecLookUpTable->{vccount} = "NO";
   #$TestbedSpecLookUpTable->{host1pswitchportCount} = undef;
   #$TestbedSpecLookUpTable->{host2pswitchportCount} = undef;
}


sub CovertKeysToLowerCase
{
   my $self = shift;
   my $refWorkload = shift;
   # Convert keys in the hash $workload to lower case before any processing
   %$refWorkload = (map { lc $_ => $refWorkload->{$_}} keys %$refWorkload);
   return $refWorkload;
}


sub PrepareSwitchOrPortGroup
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $testpg = $oldWorkload->{'testpg'};
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   if ($target =~ /vc/i) {
      $oldWorkload->{'target'} = "SUT";
      $target = "SUT";
   }

   # Process Testadapter if given
   if (($oldWorkload->{'testadapter'}) || ($oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload,$newWorkload);
   }

   # Handle Switches
   if ($testswitch =~ /^\d+$/ ) {
      # $oldWorkload->{testswitch} is number or hyphen or comma separated
      my $refToArray =$self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
      if (@$refToArray) {
         $newWorkload->{testswitch} = join ",", @$refToArray;
      }
   } else {
     # $oldWorkload->{testswitch} is name
     # this case will fail
      $newWorkload->{testswitch} = $TestbedSpecLookUpTable->{switchname}{tuple};
      if (not defined $newWorkload->{testswitch}) {
         $newWorkload->{testswitch} = $TestbedSpecLookUpTable->{$testswitch};
      }
   }

   # Handle Port Group
   if (defined $testpg) {
      my $refToArray = $self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      $newWorkload->{testpg} = join ",", @$refToArray;
   }

   # Handle Enableoutshaping
   if (defined $oldWorkload->{enableoutshaping}) {
      $newWorkload->{enableoutshaping} = $TestbedSpecLookUpTable->{$oldWorkload->{enableoutshaping}};
   }
   
   # Handle Enableinshaping
   if (defined $oldWorkload->{enableinshaping}) {
      $newWorkload->{enableinshaping} = $TestbedSpecLookUpTable->{$oldWorkload->{enableinshaping}};
   }

   # Handle Disableoutshaping
   if (defined $oldWorkload->{disableoutshaping}) {
      $newWorkload->{disableoutshaping} = $TestbedSpecLookUpTable->{$oldWorkload->{disableoutshaping}};
   }
   
   # Handle Disableinshaping
   if (defined $oldWorkload->{disableinshaping}) {
      $newWorkload->{disableinshaping} = $TestbedSpecLookUpTable->{$oldWorkload->{disableinshaping}};
   }

   if ((defined $oldWorkload->{'dvportgroup'}) &&
       (exists $oldWorkload->{setmonitoring})) {
      my $refToArray =$self->GetPGTupleBasedonNumber($oldWorkload->{'dvportgroup'}, $switchtype, $target);
      $newWorkload->{dvportgroup} = join ",", @$refToArray;
      delete $newWorkload->{testpg};
   } elsif (defined $oldWorkload->{dvportgroup}) {
      $newWorkload->{dvportgroup} = $oldWorkload->{dvportgroup};
   }

   # Handle Vmnic Adapter
   if (defined $oldWorkload->{vmnicadapter}) {
      $newWorkload->{vmnicadapter} = $self->GetVmnicTupleBasedonNumber($oldWorkload);
   }

   # Handle ConfigureProtectedVM
   if (defined $oldWorkload->{configureprotectedvm}) {
      my $tuple = $oldWorkload->{configureprotectedvm};
      $tuple =~ s/qw//;
      $tuple =~ s/\(|\)//g;
      my $oldTempWorkloadVM->{testadapter} = $tuple;
      my $newTempWorkloadVM = $self->HelperTestAdapter($oldTempWorkloadVM);
      $newWorkload->{configureprotectedvm} = $newTempWorkloadVM->{testadapter};
   }

   # Handle ConfigurePortRules
   if (defined $oldWorkload->{configureportrules}) {
      my $tuple = $oldWorkload->{configureportrules};
      $tuple =~ s/qw//;
      $tuple =~ s/\(|\)//g;
      my $oldTempWorkloadVM->{testadapter} = $tuple;
      my $newTempWorkloadVM = $self->HelperTestAdapter($oldTempWorkloadVM);
      $newWorkload->{configureportrules} = $newTempWorkloadVM->{testadapter};
   }

   # Handle Vmnic Adapter if AdapterIndex and switchType is pswitch
#   if ((defined $oldWorkload->{adapterindex}) && ($switchtype eq "pswitch")) {
    if ($switchtype eq "pswitch") {
      $oldWorkload->{pswitch} = "pswitch";
      #my $tempOldWorkload = $oldWorkload;
      #$tempOldWorkload->{vmnicadapter} = $oldWorkload->{adapterindex};
      #$newWorkload->{vmnicadapter} = $self->GetVmnicTupleBasedonNumber($tempOldWorkload);
   }

   $newWorkload->{Type} = "Switch";
   # Handle depricated Keys
   my %depricatedKeys = map { $_ => 1 } @{$WorkloadLookUpTable->{Switch}{depricatedkeys}};
   foreach my $oldkey (keys %$oldWorkload) {
      if (exists($depricatedKeys{$oldkey})) {
         my $method = $WorkloadLookUpTable->{Switch}{$oldkey};
         $newWorkload = $self->$method($oldWorkload,$newWorkload,$switchtype);
      }
   }

   # Special case for Port Mirror
   if ((exists $oldWorkload->{rspan}) && ($oldWorkload->{rspan} =~ m/remove/i)) {
      $newWorkload->{Type} = "Port";
      $newWorkload->{testport} = "host.[-1].pswitchport.[-1]";
      delete $newWorkload->{testswitch};
   }
   delete $oldWorkload->{host};
   return $newWorkload;
}


sub PrepareSwitchOrPortGroupLight
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $testpg = $oldWorkload->{'testpg'};
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # Process Testadapter if given
   if (($oldWorkload->{'testadapter'}) || ($oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload,$newWorkload);
   }

   # Handle Switches
   if ($testswitch =~ /^\d+$/ ) {
      # $oldWorkload->{testswitch} is number or hyphen or comma separated
      my $refToArray =$self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
      $newWorkload->{testswitch} = join ",", @$refToArray;
   } else {
     # $oldWorkload->{testswitch} is name
     # this case will fail
      $newWorkload->{testswitch} = $TestbedSpecLookUpTable->{switchname}{tuple};
   }

   # Handle Port Group
   if (defined $testpg) {
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      $newWorkload->{testpg} = join ",", @$refToArray;
   }
   if ((defined $oldWorkload->{'dvportgroup'}) &&
       (exists $oldWorkload->{setmonitoring})) {
      my $refToArray =$self->GetPGTupleBasedonNumber($oldWorkload->{'dvportgroup'}, $switchtype, $target);
      $newWorkload->{dvportgroup} = join ",", @$refToArray;
      delete $newWorkload->{testpg};
   } elsif (defined $oldWorkload->{dvportgroup}) {
      $newWorkload->{dvportgroup} = $oldWorkload->{dvportgroup};
   }

   # Handle Vmnic Adapter
   if (defined $oldWorkload->{vmnicadapter}) {
      $newWorkload->{vmnicadapter} = $self->GetVmnicTupleBasedonNumber($oldWorkload);
   }
   return $newWorkload;
}


sub PrepareCheckcdponswitch
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   delete $newWorkload->{testport};
   #$newWorkload->{Type} = "Switch";
   #$newWorkload->{testswitch} = "pwitch.[-1].x.[x]";
   $newWorkload->{Type} = "Port";
   $newWorkload->{testport} = "pwitch.[-1].x.[x]";
   $newWorkload->{checkcdponswitch} = $oldWorkload->{checkcdponswitch};

   # Vmnic adapter
   my $oldWorkloadForSupport = $oldWorkload;
   $oldWorkloadForSupport->{inttype} = "vmnic";
#   $oldWorkloadForSupport->{testadapter} = $oldWorkload->{vmnicadapter};
   my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
     #print "===new==" . Dumper($newWorkloadForSupport) . Dumper( $oldWorkloadForSupport);
   
   #$newWorkload->{vmnicadapter} = $newWorkloadForSupport->{testadapter};

   return $newWorkload;
}


sub PrepareAnalyzetxrxq
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my @arrayOfVmnics = split ":" , $oldWorkload->{'analyzetxrxq'};

   # Create vmnic
   my @finalArrayOfVmnic;
   foreach my $vmnic (@arrayOfVmnics) {
      my $oldWorkloadForSupport = $oldWorkload;
      $oldWorkloadForSupport->{testadapter} = "$target:vmnic:$vmnic";
      my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
      push @finalArrayOfVmnic, $newWorkloadForSupport->{testadapter};
   }
   $newWorkload->{'analyzetxrxq'} = join ':', @finalArrayOfVmnic;
   #print "===1===". Dumper($newWorkload);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #print "===1==" . Dumper($TestbedSpecLookUpTable);
   if ($target =~ /sut/i) {
      my @array = @{$TestbedSpecLookUpTable->{sutswitcharray}};
      $newWorkload->{testswitch} = $array[0];
   } else {
      my @array = @{$TestbedSpecLookUpTable->{host2switcharray}};
      $newWorkload->{testswitch} = $array[0];
   }
   return $newWorkload;
}


sub PrepareSuite
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   if (($oldWorkload->{'testadapter'}) || ($oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload, $newWorkload);
   }
   if (defined $oldWorkload->{'supportadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldTempWorkload->{testadapter} = $oldWorkload->{'supportadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldWorkload,$newWorkload);
      $newWorkload->{'supportadapter'} = $newTempWorkload->{testadapter};
   }
   $newWorkload->{Type} = "Suite";
   return $newWorkload;
}


sub PrepareLLDP
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   
   if ((defined $switchtype) && ($switchtype eq "pswitch")) {
      $newWorkload->{testswitch} = "pswitch.[-1].x.[x]";
      return $newWorkload;
   }

   return $newWorkload;
}


sub PreparePort
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   if (defined $oldWorkload->{'lldp'}) {
      return $newWorkload;
   }

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{vmnicadapter}) {
      $key = "vmnicadapter";
   } elsif ($oldWorkload->{adapterindex}) {
      $key = "adapterindex";
   }

#   if (exists $oldWorkload->{sleepbetweencombos}) {
#      $newWorkload->{sleepbetweencombos} = $oldWorkload->{sleepbetweencombos};
#   }

   my $count;
   my $host1host2pswitchPortCount;
   $oldWorkloadForSupport = $oldWorkload;
   $oldWorkloadForSupport->{inttype} = "vmnic";
   if (defined $key) {
      $oldWorkload->{$key} =~ s/\;/\,/g;
   }
   if (defined $key) {
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{$key};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   my $vmnic = $newWorkloadForSupport->{testadapter};
   my @arrayofVmnic = split('\,',$vmnic);

   # Delete Duplicate enrtries;
   my %hashToRemoveDuplicateEntries1;
   @hashToRemoveDuplicateEntries1{@arrayofVmnic} = ();
   @arrayofVmnic = keys %hashToRemoveDuplicateEntries1;
#print "===1===" .Dumper($TestbedSpecLookUpTable);
   my $justQuesry = "0";
   foreach my $eachvmnic (@arrayofVmnic) {
      if (exists $TestbedSpecLookUpTable->{$eachvmnic}) {
        # Use this for querying and nothing else
         $justQuesry = "1";
         #last;
      }
      my $tuple;
      if (exists($host1Machines{$target})) {
         if (not defined $TestbedSpecLookUpTable->{host1pswitchportCount}) {
            $count = 1;
         } else {
            $count = $TestbedSpecLookUpTable->{host1pswitchportCount};
            if ($TestbedSpecLookUpTable->{"host.[1].pswitchport.[$count]"} eq $eachvmnic) {
               # skip all the circus fixing for host1 only
            } else {
               if ($justQuesry eq "0") {
                  $count = $count + 1;
               }
            }
         }
         if ($justQuesry eq "0") {
             $tuple = "host.[1].pswitchport.[$count]";
         } else {
             # Entry already exists
             $tuple = $TestbedSpecLookUpTable->{$eachvmnic};
         }
         $host1host2pswitchPortCount = "host1pswitchportCount";
      } else {
         if (not defined $TestbedSpecLookUpTable->{host2pswitchportCount}) {
            $count = 1;
         } else {
            $count = $TestbedSpecLookUpTable->{host2pswitchportCount} + 1;
         }
         #$tuple = "host.[2].pswitchport.[$count]";
         if ($justQuesry eq "0") {
             $tuple = "host.[2].pswitchport.[$count]";
         } else {
             # Entry already exists
             $tuple = $TestbedSpecLookUpTable->{$eachvmnic};
         }
         $host1host2pswitchPortCount = "host2pswitchportCount";
      }

      my $rememberTuple;
      foreach my $TBkey (keys %$TestbedSpecLookUpTable) {
         if ((defined $TestbedSpecLookUpTable->{$TBkey}) &&
             (ref($TestbedSpecLookUpTable->{$TBkey}) ne "HASH") &&
             (ref($TestbedSpecLookUpTable->{$TBkey}) ne "ARRAY") &&
             ($TestbedSpecLookUpTable->{$TBkey} eq $eachvmnic)) {
            $rememberTuple = $TBkey;
            push @{$TestbedSpecLookUpTable->{deleteElements}}, $tuple;
            #last;
         }
      }
      #Cleanup/delete entries
      # Added this to resolve Will Issue for VSSTds.pm
      my $deleteElements = $TestbedSpecLookUpTable->{deleteElements};
      foreach my $deleteKey (@$deleteElements) {
         delete $TestbedSpecLookUpTable->{$deleteKey};
      }
      if (defined $tuple) {
         $TestbedSpecLookUpTable->{$tuple} = $eachvmnic;
         #print "seeting tuple=$tuple for $eachvmnic\n";
         # For LLDP if vmnic has pswitchport entry dont worry
         #$TestbedSpecLookUpTable->{$eachvmnic} = $tuple;
      }
      if (defined $newWorkload->{testport}) {
         $newWorkload->{testport} = $newWorkload->{testport} . "," . $tuple;
      } else {
         $newWorkload->{testport} = $tuple;
      }

      # Doing this for LLDP
      if (not exists $TestbedSpecLookUpTable->{$tuple}) {
          if ($justQuesry eq "0") {
             $TestbedSpecLookUpTable->{$tuple} = $eachvmnic;
          }
      }
      # Using this for reverse Lookup and dont add count
      # unnecesarily
      $TestbedSpecLookUpTable->{$eachvmnic} = $tuple;
      
#      #Cleanup/delete entries
#      my $deleteElements = $TestbedSpecLookUpTable->{deleteElements};
#      foreach my $deleteKey (@$deleteElements) {
#         delete $TestbedSpecLookUpTable->{$deleteKey};
#      }



      delete $TestbedSpecLookUpTable->{deleteElements};
      # Overwrite it
      if (defined $rememberTuple) {
         $newWorkload->{testport} = $rememberTuple;
      }

      # Important Critical code
      #if ((not defined $oldWorkload->{setportrunningconfiguration}) &&
      #    (not defined $oldWorkload->{setupnativetrunkvlan})) {
         if ($justQuesry eq "0") {
            $TestbedSpecLookUpTable->{$host1host2pswitchPortCount} = $count;
         }
      #}
      #print "====1====count=$count for $eachvmnic\n";
      #$TestbedSpecLookUpTable->{$host1host2pswitchPortCount} = $count;
      $count++;
   }
   if (defined $oldWorkload->{portstatus}) {
      $newWorkload->{portstatus} = $oldWorkload->{portstatus};
      delete $oldWorkload->{portstatus};
   }

   if (defined $oldWorkload->{setlldptransmitport}) {
      $newWorkload->{setlldptransmitport} = $oldWorkload->{setlldptransmitport};
   }

   if (defined $oldWorkload->{setlldpreceiveport}) {
      $newWorkload->{setlldpreceiveport} = $oldWorkload->{setlldpreceiveport};
   }

   if (defined $oldWorkload->{checkcdponswitch}) {
      delete $newWorkload->{vmnicadapter};
      $newWorkload->{checkcdponswitch} = $oldWorkload->{checkcdponswitch};
   }

   if (defined $oldWorkload->{checkcdponesx}) {
      delete $newWorkload->{vmnicadapter};
      $newWorkload->{checkcdponesx} = $oldWorkload->{checkcdponesx};
   }


   if (defined $oldWorkload->{checklldponesx}) {
      delete $newWorkload->{vmnicadapter};
      $newWorkload->{checklldponesx} = $oldWorkload->{checklldponesx};
   }

   if (defined $oldWorkload->{checklldponswitch}) {
      delete $newWorkload->{vmnicadapter};
      $newWorkload->{checklldponswitch} = $oldWorkload->{checklldponswitch};
   }


   delete $newWorkload->{vmnicadapter};
   delete $oldWorkload->{vmnicadapter};
   $newWorkload->{Type} = "Port";

   # Pswitch
   if (not defined $newWorkload->{testport}) {
      return $self->PreparePswitch($newWorkload,$oldWorkload);
   }
#print "===12===" . Dumper($newWorkload);
   delete $newWorkload->{testswitch};
   #delete $oldWorkload->{pswitch};
#print "===12===" . Dumper($newWorkload);
   return $newWorkload;
}


sub PreparePswitch
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   
   $newWorkload->{Type} = "Switch";
   $newWorkload->{testswitch} = "pswitch.[-1].x.[x]";
   
   return $newWorkload;
}

sub PrepareSwIndex
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   if (defined $oldWorkload->{swindex}) {
      my $refToArray = $self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
      $newWorkload->{testswitch} = join ",", @$refToArray;
   }
   return $newWorkload;
}


sub PrepareChecklocalmtumatch
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   if (defined $oldWorkload->{testswitch}) {
      my $refToArray = $self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
      $newWorkload->{testswitch} = join ",", @$refToArray;
   }


   my @values = split (/:/, $oldWorkload->{checklocalmtumatch});
   $newWorkload->{'checklocalmtumatch'} = $values[0];

   if (defined $values[1]) {
      my $oldTempWorkload = $oldWorkload;
      $oldWorkload->{'inttype'} = "vmnic";
      $oldTempWorkload->{testadapter} = $values[1];
      my $newTempWorkload = $self->HelperTestAdapter($oldWorkload);
      $newWorkload->{'vmnicadapter'} = $newTempWorkload->{testadapter};
   }
   delete $oldWorkload->{'inttype'};
   delete $oldWorkload->{'testswitch'};
   delete $newWorkload->{'inttype'};
   return $newWorkload;
}


sub PrepareCheckteamchkmatch
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   my $refToArray = $self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
   $newWorkload->{testswitch} = join ",", @$refToArray;

   return $newWorkload;
}


sub PrepareMontorHost
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'switch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   # Prepare switch
   if (defined $oldWorkload->{switch}) {
      my $refToArray = $self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
      $newWorkload->{testswitch} = join ",", @$refToArray;
   }

   # Prepare vmnic
   if (defined $oldWorkload->{'testadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldWorkload->{'inttype'} = "vmnic";
      $oldTempWorkload->{testadapter} = $oldWorkload->{'testadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldWorkload);
      $newWorkload->{'vmnicadapter'} = $newTempWorkload->{testadapter};
   }
   delete $oldWorkload->{'inttype'};
   delete $newWorkload->{'inttype'};

   delete $oldWorkload->{'testadapter'};
   delete $newWorkload->{'testadapter'};

   return $newWorkload;
}


sub PrepareNicIndex
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   if (defined $oldWorkload->{'nicindex'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldWorkload->{'inttype'} = "vmnic";
      $oldTempWorkload->{testadapter} = $oldWorkload->{'nicindex'};
      my $newTempWorkload = $self->HelperTestAdapter($oldWorkload);
      $newWorkload->{'vmnicadapter'} = $newTempWorkload->{testadapter};
   }
   delete $oldWorkload->{'inttype'};
   delete $newWorkload->{'inttype'};
   return $newWorkload;
}

sub GetSwitchTupleBasedonNumber
{
   my $self = shift;
   my $testswitch = shift;
   my $switchtype = shift;
   my $target = shift;
   my @testswitcharray;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   #print Dumper($TestbedSpecLookUpTable);
   my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
   $testswitch = $self->ConvertRangeToCommaSeparatedValues($testswitch);
   my @arrayOfTestSwitches = split (',', $testswitch);
   my @arrayofTarget = split(',', $target);
   foreach my $eachTarget (@arrayofTarget) {
      foreach my $switchindex (@arrayOfTestSwitches) {
         if ($switchtype =~ /pswitch/i) {
            # Handle pswitch case
            push @testswitcharray, "pswitch.[-1].x.[x]";
            return \@testswitcharray;
         }
         if (defined $refToSwitchArray->[$switchindex-1]) {
            # Currently only getting values from TestbedSpec
            # Handling vdswitch and vss
            #print "====1====" . Dumper($TestbedSpecLookUpTable);
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            if (exists($host1Machines{$eachTarget})) {
               push @testswitcharray, $refToSwitchArray->[$switchindex-1];
            } else {
               if (not defined $TestbedSpecLookUpTable->{host2switcharray}) {
                  push @testswitcharray, $refToSwitchArray->[$switchindex-1];
               } else {
                  my $refToHelperSwitchArray = $TestbedSpecLookUpTable->{host2switcharray};
                  push @testswitcharray, $refToHelperSwitchArray->[$switchindex-1];
               }
            }
         } else {
            if ($switchtype =~ /vdswitch/i) {
               push @testswitcharray, "vc.[1].vds.[$switchindex]";
            } else {
               # Need to decide which host should be chosen
               my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
               if (exists($host1Machines{$eachTarget})) {
                  push @testswitcharray, "host.[1].vss.[$switchindex]";
               } else {
                  push @testswitcharray, "host.[2].vss.[$switchindex]";
               }
            }
         }
      }
   }
   return \@testswitcharray;
}


sub GetPGTupleBasedonNumber
{
   my $self = shift;
   my $testpg = shift;
   my $switchtype = shift;
   my $target = shift;
   my @testpgarray;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
   if ((defined $refToSwitchArray->[0]) &&
       ($refToSwitchArray->[0] =~ /vds/i)) {
      $switchtype = "vdswitch";
   } else {
      $switchtype = "vsswitch";
   }
   if ($switchtype =~ /vdswitch/i) {
      # If switch type is vdswitch, pg is dvportgroup
      push @testpgarray, "vc.[1].dvportgroup.[$testpg]";
   } else {
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$target})) {
         # If switch type is vss and host is 1, construct
         # following tuple
         push @testpgarray, "host.[1].portgroup.[$testpg]";
      } else {
         push @testpgarray, "host.[2].portgroup.[$testpg]";
      }
   }
   return \@testpgarray;
}

sub PrepareLacpmode
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   my $target = $oldWorkload->{'target'} || 'SUT';
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      # If switch type is vss and host is 1, construct
      # following tuple
      $newWorkload->{host} = "host.[1].x.[x]";
   } else {
      $newWorkload->{host} = "host.[2].x.[x]";
   }
   return $newWorkload;
}

sub GetVmnicTupleBasedonNumber
{
   my $self = shift;
   my $oldWorkload = shift;
   my $vmnicadapter = $oldWorkload->{vmnicadapter};
   my $target = $oldWorkload->{target} || "SUT"; # To resolve LLDP issues

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      return "host.[1].vmnic.[$vmnicadapter]";
   } else {
      return "host.[2].vmnic.[$vmnicadapter]";
   }
}


sub MoveDVPGToVCWorkload
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = 'vdswitch';
   $newWorkload->{testvc} = "vc.[1].x.[x]";
   $newWorkload->{Type} =   "VC";
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # There might be host.[1].vss.[1] present in sutswitcharray
   # in $TestbedSpecLookUpTable
   # 'sutswitcharray' => [
   #                       'vc.[1].vds.[1]',
   #                       'host.[1].vss.[1]',
   #                       'vc.[1].vds.[2]',
   #                       'vc.[1].vds.[3]'
   #                     ],
   # In such scenarios we may accidently receive
   # $newWorkload->{testswitch} as 'host.[1].vss.[1]' if
   # testswtich index is 2 in ver1 workload example VDSVersion
   # in VDS tds. Skip to the next switch in above array.
   my @nums = @{$TestbedSpecLookUpTable->{sutswitcharray}};
   my $index = undef;
   $index = first { $nums[$_] =~ m/vss/i } 0..$#nums;
   $index = $index + 1;
   if (defined $index) {
    #print "==1===index=$index";
      if ($index <= $oldWorkload->{'testswitch'}) {
         my $refToArray =$self->GetSwitchTupleBasedonNumber($oldWorkload->{'testswitch'} + 1, 
                                                            $switchtype,
                                                            $target);
         $newWorkload->{testswitch} = join ",", @$refToArray;
      }
   }


   my @arrayOfDvpgName = split('\,', $oldWorkload->{createdvportgroup});
   foreach my $dvpgName (@arrayOfDvpgName) {
      $TestbedSpecLookUpTable->{'dvpgpgCount'} = $TestbedSpecLookUpTable->{'dvpgpgCount'} + 1;
      my $dvpgcount = $TestbedSpecLookUpTable->{'dvpgpgCount'};
      my $index = "[" . $dvpgcount . "]";
      $newWorkload->{dvportgroup}{$index} = {
         #$index => {
            'binding' => $oldWorkload->{binding},
            #'name'    => $oldWorkload->{createdvportgroup},
            'name'    => $dvpgName,
            'vds'     => $newWorkload->{testswitch},
            'ports'   => $newWorkload->{ports},
            'nrp'     => $oldWorkload->{nrp},
         #},
      };
      if (defined $newWorkload->{dvportgroup}{$index}{binding}) {
         if ($newWorkload->{dvportgroup}{$index}{binding} =~ /earlybinding/i) {
            $newWorkload->{dvportgroup}{$index}{autoExpand} = "0";
         }
      }
      #delete $oldWorkload->{nrp};
      my $dvpgtuple = "vc.[1].dvportgroup.[$TestbedSpecLookUpTable->{'dvpgpgCount'}]";
      $TestbedSpecLookUpTable->{$dvpgName} = $dvpgtuple;
      #delete $newWorkload->{testswitch};
      # Caching it for future workloads
      # $TestbedSpecLookUpTable->{'vc'}{'[1]'}{$oldWorkload->{createdvportgroup}} = $newWorkload->{dvportgroup};
      $TestbedSpecLookUpTable->{'vc'}{'[1]'}{$dvpgName} = $newWorkload->{dvportgroup};
   }

   delete $oldWorkload->{nrp};
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{datacenter};
   delete $newWorkload->{datacenter};
   return $newWorkload;
}


sub PrepareQuealloc
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $testpg = $newWorkload->{testpg};
   my ($host, $hostIndex, $pg, $pgIndex) = split ('\.', $testpg);
   my $vmknic = $host . "." . $hostIndex . "." . "vmknic" . "." . "[1]";
   $newWorkload->{testvmknic} = $vmknic;
   return $newWorkload;
}

sub PrepareVDS
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   $newWorkload->{testvc} = "vc.[1].x.[x]";
   $newWorkload->{Type} =   "VC";
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $TestbedSpecLookUpTable->{'vcVdsCount'}  = $TestbedSpecLookUpTable->{'vcVdsCount'}  + 1;
   my $vdscount = $TestbedSpecLookUpTable->{'vcVdsCount'} ;
   my $index = "[" . $vdscount . "]";
   my @arrayOfVmnicAdapters;

   #Extract Hosts and vmnic adapter
   my @arrayOfHosts;
   if (defined $oldWorkload->{uplink}) {
      my $uplink = $oldWorkload->{uplink};
      my @arrayOfUplink = split (',', $uplink);
      foreach my $entry (@arrayOfUplink) {
         my ($target, $numberOfUplinks) = split ('::', $entry);
         #$numberOfUplinks = $numberOfUplinks + 1;

         my $host1UsedVmnicCount;
         if (defined $TestbedSpecLookUpTable->{'host1vmnicCountUsed'}) {
            $host1UsedVmnicCount = $TestbedSpecLookUpTable->{'host1vmnicCountUsed'};
         } else {
            $host1UsedVmnicCount = "0";
         }

         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$target})) {
            $numberOfUplinks = $numberOfUplinks + $host1UsedVmnicCount;
            $host1UsedVmnicCount = $host1UsedVmnicCount + 1;

            my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $host1UsedVmnicCount);
            push @arrayOfHosts, "host.[1].x.[x]";
            my $host1Count = $TestbedSpecLookUpTable->{'host1vmnicCount'};
            if (defined $TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'}) {
               # That means something was removed recently so lets add that back
               push @arrayOfVmnicAdapters, "host.[1].vmnic.[$TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'}]";
            } else {
               push @arrayOfVmnicAdapters, "host.[1].vmnic.$uplinkRange";
               $TestbedSpecLookUpTable->{'host1vmnicCountUsed'} = $host1UsedVmnicCount;
            }
            # Added on April 3 2013

         } else {
            push @arrayOfHosts, "host.[2].x.[x]";
            my $host2UsedVmnicCount;
            if (defined $TestbedSpecLookUpTable->{'host2vmnicCountUsed'}) {
               $host2UsedVmnicCount = $TestbedSpecLookUpTable->{'host2vmnicCountUsed'};
            } else {
               $host2UsedVmnicCount = "0";
            }
            $numberOfUplinks = $numberOfUplinks + $host2UsedVmnicCount;
            $host2UsedVmnicCount = $host2UsedVmnicCount + 1;
            my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $host2UsedVmnicCount);
            if (defined $TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'}) {
               # That means something was removed recently so lets add that back
               push @arrayOfVmnicAdapters, "host.[2].vmnic.[$TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'}]";
            } else {
               push @arrayOfVmnicAdapters, "host.[2].vmnic.$uplinkRange";
               $TestbedSpecLookUpTable->{'host2vmnicCountUsed'} = $host2UsedVmnicCount;
            }
            my $host2Count = $TestbedSpecLookUpTable->{'host2vmnicCount'};
         }
      }
   }

   # Extract Host Second attempt
   if (defined $oldWorkload->{hosts}) {
      my @arrayOfTarget = split (',', $oldWorkload->{hosts});
      foreach my $entry (@arrayOfTarget) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$entry})) {
            push @arrayOfHosts, "host.[1].x.[x]";
         } else {
            push @arrayOfHosts, "host.[2].x.[x]";
         }
      }
   } else {
      push @arrayOfHosts, "host.[1].x.[x]";
   }

   my %hashToRemoveDuplicateEntries;
   @hashToRemoveDuplicateEntries{@arrayOfHosts} = ();
   @arrayOfHosts = keys %hashToRemoveDuplicateEntries;
   my $host = join ";;", @arrayOfHosts;

   # Removing dupliacte elements from @arrayOfVmnicAdapters
   my %refHashVmnic = map { $_ => 1} @arrayOfVmnicAdapters;
   @arrayOfVmnicAdapters = keys %refHashVmnic;

   my $vmnicadapter;
   if (@arrayOfVmnicAdapters) {
      $vmnicadapter = join ";;", @arrayOfVmnicAdapters;
   }

   # Create vds compoenent
   my $dcname;
   if ((not defined $oldWorkload->{dcname}) ||
       (not defined $TestbedSpecLookUpTable->{$oldWorkload->{dcname}})) {
      $dcname = "vc.[1].datacenter.[1]";
   } else {
      $dcname = $TestbedSpecLookUpTable->{$oldWorkload->{dcname}};
   }
   if (defined $oldWorkload->{vdsname}) {
      $TestbedSpecLookUpTable->{$oldWorkload->{vdsname}} = "vc.[1].vds.$index";
   }
   $newWorkload->{vds} = {
      $index => {
         'datacenter'   => $dcname,
         'host'         => $host,
         'vmnicadapter' => $vmnicadapter,
         'version'      => $oldWorkload->{version},
         'name'         => $oldWorkload->{vdsname},
         #'numuplinkports' => "1",
         configurehosts => "add",
      },
   };
   if (not defined $vmnicadapter) {
      delete $newWorkload->{vds}{$index}{vmnicadapter};
   }
   # Delete hosts/configurehosts, that means host will be added in next workload
   if (not defined $oldWorkload->{hosts}) {
      #delete $newWorkload->{vds}{$index}{host};
      #delete $newWorkload->{vds}{$index}{configurehosts};
   }

   my $vdstuple = "vc.[1].vds.[$vdscount]";
   $TestbedSpecLookUpTable->{$oldWorkload->{vdsname}} = $vdstuple;
   push @{$TestbedSpecLookUpTable->{sutswitcharray}}, $vdstuple;
   delete $newWorkload->{testswitch};
   delete $newWorkload->{testhost};
   delete $newWorkload->{opt};
   # Doing this so that uplink doesn't call this again
   delete $oldWorkload->{uplink};
   delete $newWorkload->{datacenter};
#print "===1AfterVDSAdded===" . Dumper($TestbedSpecLookUpTable);
   return $newWorkload;
}


sub PrepareConfigureUplinks
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{target} || "SUT";
   if ($oldWorkload->{configureuplinks} =~ /Add/i) {
      $newWorkload->{configureuplinks} = "add";
   } else {
      $newWorkload->{configureuplinks} = "remove";
   }
   my @refVmnicEntry;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      my $uplink = $oldWorkload->{vmnicadapter};
      my @arrayOfUplink = split (',', $uplink);
      foreach my $entry (@arrayOfUplink) {
         push @refVmnicEntry, "host.[1].vmnic.[$entry]";
         $TestbedSpecLookUpTable->{'host1vmnicCount'} = $entry;
         $TestbedSpecLookUpTable->{'host1vmnicCountUsed'} = $TestbedSpecLookUpTable->{'host1vmnicCountUsed'} + 1;
      }
   } else {
      my $uplink = $oldWorkload->{vmnicadapter};
      my @arrayOfUplink = split (',', $uplink);
      foreach my $entry (@arrayOfUplink) {
         push @refVmnicEntry, "host.[2].vmnic.[$entry]";
         $newWorkload->{vmnicadapter} = "host.[2].vmnic.[$entry]";
         $TestbedSpecLookUpTable->{'host2vmnicCount'} = $entry;
         $TestbedSpecLookUpTable->{'host2vmnicCountUsed'} = $TestbedSpecLookUpTable->{'host2vmnicCountUsed'} + 1;
      }
   }
   delete $oldWorkload->{host};
   $newWorkload->{vmnicadapter} = join ";;", @refVmnicEntry;
   return $newWorkload;
}

# Just using this key host1vmnicCount/host2vmnicCount here
# Might need to use this in PrepareVDS and PrepareUplink
sub PrepareUplink
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   if (($oldWorkload->{opt} =~ /createvds/i) &&(not exists $newWorkload->{vds})
       ) {
      print "\n===PrepareVDSPrepareUplink===\n" . Dumper($newWorkload);  
      return $self->PrepareVDS($oldWorkload, $newWorkload);
   }

   # Under SwitchWorkload
   $newWorkload->{Type} = "Switch";

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # Get the right VDS switch
   if (defined $oldWorkload->{vdsname}) {
      if ($oldWorkload->{vdsname} =~ /^\d+$/) {
          #vds index
          my $index = $oldWorkload->{vdsname};
          $index = $index - 1;
          my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
          $newWorkload->{testswitch} = $refToSwitchArray->[$index];
      } else {
          #vds name get from database
          $testswitch = $TestbedSpecLookUpTable->{$oldWorkload->{vdsname}};
          $newWorkload->{testswitch} = $testswitch;
      }
   }

   # Decide the operation
   if ($oldWorkload->{'opt'} =~ /adduplink/i) {
      $newWorkload->{configureuplinks} = "add";
      # Get the right vmnic adapter
      my @arrayOfVmnicAdapters;
      if (defined $oldWorkload->{uplink}) {
         my $uplink = $oldWorkload->{uplink};
         my @arrayOfUplink = split (',', $uplink);
         foreach my $entry (@arrayOfUplink) {
            # Remeber the number here is num of vmnic adapters
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            my ($target, $numberOfUplinks) = split ('::', $entry);
            if (exists($host1Machines{$target})) {
               my $host1UsedVmnicCount = $TestbedSpecLookUpTable->{'host1vmnicCountUsed'};
               $numberOfUplinks = $numberOfUplinks + $host1UsedVmnicCount;
               $host1UsedVmnicCount = $host1UsedVmnicCount + 1;
               my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $host1UsedVmnicCount);
               #$numberOfUplinks = $numberOfUplinks + $TestbedSpecLookUpTable->{'host1vmnicCount'};
               #$TestbedSpecLookUpTable->{'host1vmnicCount'} = $TestbedSpecLookUpTable->{'host1vmnicCount'} + 1;
               #my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $TestbedSpecLookUpTable->{'host1vmnicCount'});
               my $host1Count = $TestbedSpecLookUpTable->{'host1vmnicCount'};
               if (defined $TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'}) {
                  # That means something was removed recently so lets add that back
                  push @arrayOfVmnicAdapters, "host.[1].vmnic.[$TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'}]";
               } else {
                  push @arrayOfVmnicAdapters, "host.[1].vmnic.$uplinkRange";
               }
            } else {
               my $host2UsedVmnicCount = $TestbedSpecLookUpTable->{'host2vmnicCountUsed'};
               $numberOfUplinks = $numberOfUplinks + $host2UsedVmnicCount;
               $host2UsedVmnicCount = $host2UsedVmnicCount + 1;
               my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $host2UsedVmnicCount);
               #$numberOfUplinks = $numberOfUplinks + $TestbedSpecLookUpTable->{'host2vmnicCount'};
               #$TestbedSpecLookUpTable->{'host2vmnicCount'} = $TestbedSpecLookUpTable->{'host2vmnicCount'} + 1;
               #my $uplinkRange = $self->ConvertToRange($numberOfUplinks, $TestbedSpecLookUpTable->{'host2vmnicCount'});
               if (defined $TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'}) {
                  # That means something was removed recently so lets add that back
                  push @arrayOfVmnicAdapters, "host.[2].vmnic.[$TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'}]";
               } else {
                  push @arrayOfVmnicAdapters, "host.[2].vmnic.$uplinkRange";
               }
               my $host2Count = $TestbedSpecLookUpTable->{'host2vmnicCount'};
            }
         }
      }
      my $vmnicadapter = join ";;", @arrayOfVmnicAdapters;
      $newWorkload->{vmnicadapter} = $vmnicadapter;
   } else {
      $newWorkload->{configureuplinks} = "remove";
      # Get the right vmnic adapter
      my @arrayOfVmnicAdapters;
      if (defined $oldWorkload->{uplink}) {
         my $uplink = $oldWorkload->{uplink};
         my @arrayOfUplink = split (',', $uplink);
         foreach my $entry (@arrayOfUplink) {
            my ($target, $index) = split ('::', $entry);
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            if (exists($host1Machines{$target})) {
               push @arrayOfVmnicAdapters, "host.[1].vmnic.[$index]";
               # Storing the index which has been deleted, this will
               # be used while adding back vmnic adapter
               $TestbedSpecLookUpTable->{'host1vmnicRemovedIndex'} = $index;
            } else {
               push @arrayOfVmnicAdapters, "host.[2].vmnic.[$index]";
               # Storing the index which has been deleted, this will
               # be used while adding back vmnic adapter
               $TestbedSpecLookUpTable->{'host2vmnicRemovedIndex'} = $index;
            }
         }
      }
      my $vmnicadapter = join ";;", @arrayOfVmnicAdapters;
      $newWorkload->{vmnicadapter} = $vmnicadapter;
      delete $oldWorkload->{host};
   }
   delete $oldWorkload->{host};
   delete $newWorkload->{opt};
   delete $newWorkload->{testvc};
   delete $newWorkload->{testhost};
#   print "===1====" . Dumper($newWorkload);
   return $newWorkload;
}


sub DeleteVSSFromHost
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{target};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   # Find which host
   my $vssTuple;
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      $vssTuple = $TestbedSpecLookUpTable->{host1vssnameTuple}{$oldWorkload->{vswitchname}};
   } else {
      $vssTuple = $TestbedSpecLookUpTable->{host2vssnameTuple}{$oldWorkload->{vswitchname}};
   }
   $newWorkload->{deletevss} = $vssTuple;
   return $newWorkload;
}


sub AddVSSToHost
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{target};

   if ($oldWorkload->{vswitch} =~ /delete/i) {
      return $self->DeleteVSSFromHost($oldWorkload, $newWorkload);
   }
   #if (exists $newWorkload->{vss}) {
   #   return $newWorkload;
   #}


   my $vssTuple;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   # Find which host
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      # Keep count of vswitch added under each host
      $TestbedSpecLookUpTable->{'host1vssCount'} = $TestbedSpecLookUpTable->{'host1vssCount'} + 1;
      $vssTuple = "host.[1].vss.[$TestbedSpecLookUpTable->{'host1vssCount'}]";
      # foreach vsswitchname add the tuple
      $TestbedSpecLookUpTable->{host1vssnameTuple}{$oldWorkload->{vswitchname}} = $vssTuple;
      my $index = "[" . $TestbedSpecLookUpTable->{'host1vssCount'} . "]";
      $newWorkload->{vss} = {
         $index => {
            'name'    => $oldWorkload->{vswitchname},
         },
      };
   } else {
      $TestbedSpecLookUpTable->{'host2vssCount'} = $TestbedSpecLookUpTable->{'host2vssCount'} + 1;

      $vssTuple = "host.[2].vss.[$TestbedSpecLookUpTable->{'host2vssCount'}]";
      # foreach vsswitchname add the tuple
      $TestbedSpecLookUpTable->{host2vssnameTuple}{$oldWorkload->{vswitchname}} = $vssTuple;
      my $index = "[" . $TestbedSpecLookUpTable->{'host2vssCount'} . "]";
      $newWorkload->{vss} = {
         $index => {
            'name'    => $oldWorkload->{vswitchname},
         },
      };
   }
   push @{$TestbedSpecLookUpTable->{sutswitcharray}}, $vssTuple;
   #print "TestbedSpecLookUp=" . Dumper($TestbedSpecLookUpTable);
   #delete $oldWorkload->{vswitchname};
   #print "===1===" . Dumper($newWorkload);
   return $newWorkload;
}


sub AddVmknicToHost
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   if (($oldWorkload->{vmknic} =~ /delete/i) || ($oldWorkload->{vmknic} =~ /remove/i)) {
      return $self->DeleteVmknic($oldWorkload, $newWorkload);
   }
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   if (not defined  $TestbedSpecLookUpTable->{'host1vmknicCount'}) {
       $TestbedSpecLookUpTable->{'host1vmknicCount'} = "0";
   }
   $TestbedSpecLookUpTable->{'host1vmknicCount'} = $TestbedSpecLookUpTable->{'host1vmknicCount'} + 1;
   my $index = "[" . $TestbedSpecLookUpTable->{'host1vmknicCount'} . "]";
   $newWorkload->{vmknic} = {
      $index => {
         "ipv4" => $oldWorkload->{ip} || "dhcp", #ipv4address
         "netmask"     => $oldWorkload->{netmask} || "255.255.0.0",
      },
   };
   my $pg;
   if (defined $oldWorkload->{portgroupname}) {
      $pg = $oldWorkload->{portgroupname};
   } elsif (defined $oldWorkload->{pgname}) {
      $pg = $oldWorkload->{pgname};
   }
   my $target1 = $oldWorkload->{target} || "SUT";
   my @arrayOfTarget = split ('\,', $target1);
   foreach my $target (@arrayOfTarget) {
      if ($pg =~ /^\d+$/) {
         my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
         my $refToArray =$self->GetPGTupleBasedonNumber($pg, $switchtype, $target);
         #$newWorkload->{vmknic}{$index}{switch} = join ",", @$refToArray;
         $newWorkload->{vmknic}{$index}{portgroup} = join ",", @$refToArray;
      } elsif ($pg !~ /^\d+$/) {
         $newWorkload->{vmknic}{$index}{portgroup} = $TestbedSpecLookUpTable->{$pg};
      }
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$target})) {
         $TestbedSpecLookUpTable->{host1vmknicTuple}{$pg} = "host.[1].vmknic.$index";
      } else {
         $TestbedSpecLookUpTable->{host2vmknicTuple}{$pg} = "host.[2].vmknic.$index";
      }
   }
      #print "===1===" . Dumper($TestbedSpecLookUpTable);
      if (defined $newWorkload->{testswitch}) {
         delete $newWorkload->{testswitch};
         delete $oldWorkload->{testswitch};
         delete $newWorkload->{ip};
         $newWorkload->{Type} = "Host";
      }
   if (not defined $newWorkload->{testhost}) {
      my @arrayofTestHost;
      my @arrayOfMachines = split (',', $target1);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
   }
   delete $newWorkload->{netmask};
   delete $oldWorkload->{netmask};
   return $newWorkload;
}


sub Removehostfromvds
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'vdsindex'} || '1';
   my $switchtype = 'vdswitch';

   my $refToArray =$self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
   $newWorkload->{testswitch} = join ",", @$refToArray;

   return $newWorkload;
}


sub DeleteVmknic
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $TestbedSpecLookUpTable->{'host1vmknicCount'} = $TestbedSpecLookUpTable->{'host1vmknicCount'} + 1;
   $newWorkload->{deletevmknic} = $oldWorkload->{vmknic};
   # Find which host
   my $target = $oldWorkload->{target} || "SUT";
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   my $vmknicTuple;
   my $pg;
   if (defined $oldWorkload->{portgroupname}) {
      $pg = $oldWorkload->{portgroupname};
   } elsif (defined $oldWorkload->{pgname}) {
      $pg = $oldWorkload->{pgname};
   }
   if (exists($host1Machines{$target})) {
      $vmknicTuple = $TestbedSpecLookUpTable->{host1vmknicTuple}{$pg};
   } else {
      $vmknicTuple = $TestbedSpecLookUpTable->{host2vmknicTuple}{$pg};
   }
   if (defined $vmknicTuple) {
      $newWorkload->{deletevmknic} = $vmknicTuple;
   } else {
      #$oldWorkload->{testadapter} = $vmnic;
      #$dummyneworkload = $self->HelperTestAdapter($oldWorkload);
      #push @arrayOfVMnics, $dummyneworkload->{testadapter};
      #print "===1===" . Dumper($TestbedSpecLookUpTable);
      $newWorkload->{deletevmknic} = undef;
   }
   if (defined $newWorkload->{testswitch}) {
      delete $newWorkload->{testswitch};
      delete $oldWorkload->{testswitch};
      delete $newWorkload->{ip};
      $newWorkload->{Type} = "Host";
   }
   if (not defined $newWorkload->{testhost}) {
      my @arrayofTestHost;
      my @arrayOfMachines = split (',', $target);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
            $TestbedSpecLookUpTable->{'host1vmknicCount'}--;
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
            $TestbedSpecLookUpTable->{'host2vmknicCount'}--;
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
   }
   return $newWorkload;
}


sub DeletePGFromHost
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{target};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $pgTuple;
#print "===1===" .Dumper($TestbedSpecLookUpTable);
   # Find which host
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$target})) {
      $pgTuple = $TestbedSpecLookUpTable->{host1pgnameTuple}{$oldWorkload->{portgroupname}};
   } else {
      $pgTuple = $TestbedSpecLookUpTable->{host2pgnameTuple}{$oldWorkload->{portgroupname}};
   }
   if (not defined $pgTuple) {
      $pgTuple = $TestbedSpecLookUpTable->{$oldWorkload->{portgroupname}}
   }
   $newWorkload->{deleteportgroup} = $pgTuple;
   delete $oldWorkload->{vswitchname};
   delete $oldWorkload->{portgroupname};
   return $newWorkload;
}


sub Prepareremovedvportgroup
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $refToArray =$self->GetPGTupleBasedonNumber($oldWorkload->{removedvportgroup}, "vds", "SUT");
   $newWorkload->{deleteportgroup} = join ",", @$refToArray;
   return $newWorkload;
}


sub AddPGToHost
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{target};

   if (((defined $oldWorkload->{portgroup}) &&
       ($oldWorkload->{portgroup} =~ /delete/i)) ||
       ((defined $oldWorkload->{configureportgroup}) &&
       ($oldWorkload->{configureportgroup} =~ /delete/i))) {
      return $self->DeletePGFromHost($oldWorkload, $newWorkload);
   }

   if ((not defined $oldWorkload->{portgroup}) &&
       (not defined $oldWorkload->{configureportgroup}) &&
       (not defined $oldWorkload->{vswitch})) {
      return $newWorkload;
   }

   if (((defined $oldWorkload->{vswitch}) && ($oldWorkload->{vswitch} =~ /add/i)) &&
       !(exists $newWorkload->{portgroup})) {
      $newWorkload = $self->AddVSSToHost($oldWorkload, $newWorkload);
   } elsif ((defined $oldWorkload->{vswitch}) && ($oldWorkload->{vswitch} =~ /delete/i)) {
      $newWorkload = $self->AddVSSToHost($oldWorkload, $newWorkload);
      return $newWorkload;
   }
   #print "===1===";
   if ( (not exists $oldWorkload->{configureportgroup}) &&
       (not defined $oldWorkload->{configureportgroup}) &&
       ($oldWorkload->{portgroup} ne "add")) {
      return $newWorkload;
   }
   #print "====2===";

   if (defined $oldWorkload->{pgname}) {
      $oldWorkload->{portgroupname} = $oldWorkload->{pgname};
   }

   my $pgTuple;
   my $vssTuple;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   # Find which host
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};

   my $pgnumber;
   if (defined $oldWorkload->{pgnumber}) {
      $pgnumber = $oldWorkload->{pgnumber};
      # pgnumber addition VSSTds and VMKTCPIP
      for (my $i=1; $i <= $pgnumber; $i++) {
         my $index = $i + 1;
         $TestbedSpecLookUpTable->{"$oldWorkload->{portgroupname}-$i"} = "host.[1].portgroup.[$index]";
         $index = "[" . $index . "]";
         $newWorkload->{portgroup}{$index} = {
               'name' => "$oldWorkload->{portgroupname}-$i",
               'vss'  => "host.[1].vss.[1]",
         };
      }
      delete $oldWorkload->{vswitchname};
      delete $oldWorkload->{portgroupname};
      delete $oldWorkload->{pgname};
      delete $oldWorkload->{pgnumber};
      delete $newWorkload->{pgnumber};
      delete $newWorkload->{testswitch};
      return $newWorkload;
   }

   # Standard Addition
   if (exists($host1Machines{$target})) {
      # Keep count of vswitch added under each host
      $TestbedSpecLookUpTable->{'host1pgCount'} = $TestbedSpecLookUpTable->{'host1pgCount'} + 1;
      $pgTuple = "host.[1].portgroup.[$TestbedSpecLookUpTable->{'host1pgCount'}]";
      # foreach vsswitchname add the tuple
      # Commented the below lines to find if its truly necessary
      #$TestbedSpecLookUpTable->{host1pgnameTuple}{$oldWorkload->{portgroupname}} = $pgTuple;
      $TestbedSpecLookUpTable->{$oldWorkload->{portgroupname}} = $pgTuple;
      $vssTuple = $TestbedSpecLookUpTable->{host1vssnameTuple}{$oldWorkload->{vswitchname}} || $newWorkload->{testswitch};
      my $index = "[" . $TestbedSpecLookUpTable->{'host1pgCount'} . "]";
      $newWorkload->{portgroup} = {
         $index => {
            'name' => $oldWorkload->{portgroupname},
            'vss'  => $vssTuple
         },
      };
   } else {
      $TestbedSpecLookUpTable->{'host2pgCount'} = $TestbedSpecLookUpTable->{'host2pgCount'} + 1;
      $pgTuple = "host.[2].portgroup.[$TestbedSpecLookUpTable->{'host2pgCount'}]";
      # foreach vsswitchname add the tuple
      # Commented the below lines to find if its truly necessary
      #$TestbedSpecLookUpTable->{host2pgnameTuple}{$oldWorkload->{portgroupname}} = $pgTuple;
      $TestbedSpecLookUpTable->{$oldWorkload->{portgroupname}} = $pgTuple;
      $vssTuple = $TestbedSpecLookUpTable->{host2vssnameTuple}{$oldWorkload->{vswitchname}} || $newWorkload->{testswitch};
      my $index = "[" . $TestbedSpecLookUpTable->{'host2pgCount'} . "]";
      $newWorkload->{portgroup} = {
         $index => {
            'name' => $oldWorkload->{portgroupname},
            'vss'  => $vssTuple  || $newWorkload->{testswitch},
         },
      };
   }



   #print "TestbedSpecLookUp=" . Dumper($TestbedSpecLookUpTable);
   delete $oldWorkload->{vswitchname};
   delete $oldWorkload->{portgroupname};
   delete $oldWorkload->{configureportgroup};
   delete $oldWorkload->{pgname};
   delete $oldWorkload->{pgnumber};
   delete $newWorkload->{pgnumber};
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{testswitch};
   #print "====1===" . Dumper($newWorkload);
   return $newWorkload;
}

sub PrepareAddPortToDVPG
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my @arrayOfpg = split ('\,', $oldWorkload->{addporttodvportgroup});
   my @finalArray;
   foreach my $dvpg (@arrayOfpg) {
      push @finalArray, $TestbedSpecLookUpTable->{$dvpg};
   }
   $newWorkload->{testportgroup} = join ',',@finalArray;
   if (defined $oldWorkload->{ports}) {
      $newWorkload->{addporttodvportgroup} = $oldWorkload->{ports};
   } else {
      $newWorkload->{addporttodvportgroup} = "1";
   }

   delete $oldWorkload->{ports};
   delete $oldWorkload->{addporttodvportgroup};
   delete $oldWorkload->{testswitch};
   delete $newWorkload->{testswitch};
   $newWorkload->{Type} = "PortGroup";
   #print "==1===" . Dumper($newWorkload);
   return $newWorkload;
}

sub PrepareNicTeaming
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if (defined $TestbedSpecLookUpTable->{$oldWorkload->{'confignicteaming'}}) {
      $newWorkload->{confignicteaming} = $TestbedSpecLookUpTable->{$oldWorkload->{'confignicteaming'}};
   } else {
      my $testpg = $oldWorkload->{'confignicteaming'};
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      $newWorkload->{confignicteaming} = join ",", @$refToArray;
   }


   # Handle stand by nics
   if (defined $oldWorkload->{'standbynics'}) {
      my $standByNics = $oldWorkload->{'standbynics'};
      $standByNics =~ s/^\s+//;
      $standByNics =~ s/\s+$//;
      my @vmnics    = split(/\+/, $standByNics);
      my $dummyneworkload;

      my @arrayOfVMnics;
      $oldWorkload->{inttype} = "vmnic";
      foreach my $vmnic (@vmnics) {
         $oldWorkload->{testadapter} = $vmnic;
         $dummyneworkload = $self->HelperTestAdapter($oldWorkload);
         push @arrayOfVMnics, $dummyneworkload->{testadapter};
      }
      $newWorkload->{'standbynics'} = join ";;", @arrayOfVMnics;
   }
   if (defined $oldWorkload->{notifyswitch}) {
      $newWorkload->{'notifyswitch'} = $oldWorkload->{'notifyswitch'};
   }

   return $newWorkload;
}


sub PrepareSetFailOverOrder
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   my $setFailOverOrder = $oldWorkload->{'setfailoverorder'};
   $setFailOverOrder =~ s/^\s+//;
   $setFailOverOrder =~ s/\s+$//;
   my @vmnics    = split(/\+/, $setFailOverOrder);
   my $dummyneworkload;

   my @arrayOfVMnics;
   $oldWorkload->{inttype} = "vmnic";
   foreach my $vmnic (@vmnics) {
      $oldWorkload->{testadapter} = $vmnic;
      $dummyneworkload = $self->HelperTestAdapter($oldWorkload);
      push @arrayOfVMnics, $dummyneworkload->{testadapter};
   }
   $newWorkload->{'setfailoverorder'} = join ";;", @arrayOfVMnics;
   return $newWorkload;
}


sub PrepareAccessVlan
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $switchtype = $oldWorkload->{'switchtype'};
   my $testswitch = $oldWorkload->{'testswitch'};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if (not defined $switchtype) {
      # Check if vds is present in testbedspec
      my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
      my $switchTuple = $refToSwitchArray->[$testswitch-1];
      if ($switchTuple =~ /vds/i) {
         $switchtype = "vdswitch";
      } else {
         $switchtype = "vsswitch";
      }
   }
   #my $testpg = $oldWorkload->{'portgroup'};
   my @arrayOfDvpgName = split('\,', $oldWorkload->{portgroup});
   # Introducing Uplink
   my $uplinkPG;

   if ($oldWorkload->{portgroup} eq "Uplink") {
      $uplinkPG = "vc.[1].vds.[1].uplinkportgroup.[1]";
   }
   my @arrayofpg;
   foreach my $testpg (@arrayOfDvpgName) {
      if ($TestbedSpecLookUpTable->{$testpg}) {
         #$newWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{portgroup}};
         push @arrayofpg, $TestbedSpecLookUpTable->{$testpg};
      } else {
         my $refToArray = $self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
         @arrayofpg = @$refToArray;
         #$newWorkload->{portgroup} = join ",", @$refToArray;
         #$testpg = join ",", @$refToArray;
      }
   }
   $newWorkload->{Type} = "PortGroup";
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{testswitch};
   delete $newWorkload->{portgroup};
   delete $oldWorkload->{portgroup};
   #$newWorkload->{testportgroup} = $testpg;
   $newWorkload->{testportgroup} = join ",", @arrayofpg;

   # Introducing Uplink
   if (defined $uplinkPG) {
      $newWorkload->{testportgroup} = $uplinkPG;
   }
   $newWorkload->{vlantype} = "access";
   $newWorkload->{vlan} = $oldWorkload->{'accessvlan'};

   return $newWorkload;
}


# Danger API
sub PrepareVlan
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $newWorkloadSecond;

   my $target      = $oldWorkload->{'target'} || 'SUT';
   my $switchtype  = $oldWorkload->{'switchtype'} || 'vswitch';
   my $inttype     = $oldWorkload->{inttype} ; #|| 'vnic';
   my $testadapter = $oldWorkload->{testadapter} || '1';

   if (($oldWorkload->{mtu}) && ($switchtype ne "pswitch")) {
    $newWorkloadSecond = $self->PrepareSwitchOrPortGroupLight($oldWorkload, $newWorkload);
    delete $newWorkloadSecond->{testadapter};
    delete $newWorkloadSecond->{vlan};
    $newWorkloadSecond->{mtu} = $oldWorkload->{mtu};

   }

   if ($switchtype eq "pswitch") {
      #return $self->PrepareVlanPswitch($oldWorkload, $newWorkload);
   }
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my @arrayofTestVM;
   my $tuple;
   my $testpg;
   my @refToArray;
   my @arrayOfMachines = split (',', $target);
   foreach my $machines (@arrayOfMachines) {
      # find inventory either vm or host
      if ($inttype =~ m/vnic/i) {
         # tuple has to be vm
         if ($machines =~ m/SUT/i) {
            my $inventoryIndex = "1";
            $tuple = "vm.[$inventoryIndex].vnic.[$testadapter]";
         } else {
            my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
            my $index = 0;
            $index = first { $nums[$_] eq $machines } 0..$#nums;
            my $inventoryIndex = $index + "1";
            $tuple = "vm.[$inventoryIndex].vnic.[$testadapter]";
         }
      }
      if ($inttype =~ m/vmknic/i) {
         # tuple has to be host
         my @arrayofTestHost;
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machines})) {
            $tuple = "host.[1].vmknic.[$testadapter]";
         } else {
            $tuple = "host.[2].vmknic.[$testadapter]";
         }
      }
      # Construct pg tuple using $tuple
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      my @arrayofPG;
      if (defined $oldWorkload->{portgroup}) {
         @arrayofPG = split(',', $oldWorkload->{portgroup});
      } elsif (defined $oldWorkload->{testpg}) {
         @arrayofPG = split(',', $oldWorkload->{testpg});
      }
      #print "===1===" . Dumper($oldWorkload);
      foreach my $pg (@arrayofPG) {
         if (defined $TestbedSpecLookUpTable->{$pg}) {
            $testpg = $TestbedSpecLookUpTable->{$pg};
            push @refToArray, $testpg;
         }
      }
      if ((not defined $oldWorkload->{portgroup}) && (not defined $oldWorkload->{testpg})) {
         my ($inventory, $indexIn, $component, $indexComp) = split ('\.', $tuple);
         $testpg = $self->{testcaseHash}{TestbedSpec}{$inventory}{$indexIn}{$component}{$indexComp}{portgroup};
         push @refToArray, $testpg;
      }
   }

   my %newhash;
   if (defined $newWorkloadSecond) {
      %newhash = %$newWorkloadSecond;
   }

   $newWorkload->{Type} = "PortGroup";
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{testswitch};
   delete $oldWorkload->{testadapter};
   delete $newWorkload->{testadapter};
   delete $oldWorkload->{mtu};
   delete $newWorkload->{mtu};
#   delete $newWorkload->{testpg};
   $newWorkload->{testportgroup} = join ",", @refToArray;

   if ($newWorkload->{testportgroup} eq '') {
      if (defined $newWorkload->{testpg}) {
         $newWorkload->{testportgroup} = $newWorkload->{testpg};
      } else {
         $newWorkload->{testportgroup} = "host.[1].portgroup.[$oldWorkload->{testpg}]";
      }
      $newWorkload->{vlantype} = "access";
   }
   delete $oldWorkload->{testpg};
   delete $newWorkload->{testpg};
   $newWorkload->{vlan} = $oldWorkload->{'vlan'};

   # Magic
   my $newWorkloadReturn;
   if (defined $newWorkloadSecond) {
      $TestbedSpecLookUpTable->{MAGICINSERTION} = "1";
      $newWorkloadReturn = {
       'A' => $newWorkload,
       'B' => \%newhash
      };
      return $newWorkloadReturn;
   }
   return $newWorkload;
}


sub PrepareSetpvlantype
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $machine = $oldWorkload->{'target'} || 'SUT';
   my $tuple;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $switchtype = $oldWorkload->{'switchtype'};
   my $testswitch = $oldWorkload->{'testswitch'};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if (not defined $switchtype) {
      # Check if vds is present in testbedspec
      my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
      my $switchTuple = $refToSwitchArray->[$testswitch-1];
      if ($switchTuple =~ /vds/i) {
         $switchtype = "vdswitch";
      } else {
         $switchtype = "vsswitch";
      }
   }
   my $testpg = $oldWorkload->{'setpvlantype'};
   if ($TestbedSpecLookUpTable->{$oldWorkload->{setpvlantype}}) {
      #$newWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{portgroup}};
      $testpg = $TestbedSpecLookUpTable->{$oldWorkload->{setpvlantype}};
   } else {
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      #$newWorkload->{portgroup} = join ",", @$refToArray;
      $testpg = join ",", @$refToArray;
   }

   # Add Test host because vds doesn't have host obj
   $newWorkload->{Type} = "PortGroup";
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{testswitch};
   $newWorkload->{testportgroup} = $testpg;
   $newWorkload->{vlantype} = "pvlan";
   $newWorkload->{vlan} = $oldWorkload->{'pvlan'};
   return $newWorkload;
}


sub PrepareTrunkRange
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $machine = $oldWorkload->{'target'} || 'SUT';
   my $tuple;

   my $target = $oldWorkload->{'target'} || 'SUT';
   my $switchtype = $oldWorkload->{'switchtype'};
   my $testswitch = $oldWorkload->{'testswitch'};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if (not defined $switchtype) {
      # Check if vds is present in testbedspec
      my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
      my $switchTuple = $refToSwitchArray->[$testswitch-1];
      if ($switchTuple =~ /vds/i) {
         $switchtype = "vdswitch";
      } else {
         $switchtype = "vsswitch";
      }
   }
   my $testpg = $oldWorkload->{'portgroup'};
   if ($TestbedSpecLookUpTable->{$oldWorkload->{portgroup}}) {
      #$newWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{portgroup}};
      $testpg = $TestbedSpecLookUpTable->{$oldWorkload->{portgroup}};
   } else {
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      #$newWorkload->{portgroup} = join ",", @$refToArray;
      $testpg = join ",", @$refToArray;
   }

   # Configure Uplink if found
   my $uplinkPG;
   if ($oldWorkload->{portgroup} eq "Uplink") {
      $uplinkPG = "vc.[1].vds.[1].uplinkportgroup.[1]";
   }

   # Add Test host because vds doesn't have host obj
   $newWorkload->{Type} = "PortGroup";
   delete $newWorkload->{testswitch};
   delete $oldWorkload->{testswitch};
   $newWorkload->{testportgroup} = $testpg;
   # Introducing Uplink
   if (defined $uplinkPG) {
      $newWorkload->{testportgroup} = $uplinkPG;
   }
   $newWorkload->{vlantype} = "trunk";
   $newWorkload->{vlan} = $oldWorkload->{'trunkrange'};
   return $newWorkload;
}


sub PrepareVerifyVnicSwitchport
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my ($dummyOldworkload, $dummyneworkload);
   $dummyOldworkload->{inttype} = "vnic";
   $dummyOldworkload->{testadapter} = $oldWorkload->{verifyvnicswitchport};
   $dummyneworkload = $self->PrepareTestAdapter($dummyOldworkload);
   $newWorkload->{verifyvnicswitchport} = $dummyneworkload->{testadapter};
   #print "==1===" . Dumper($newWorkload);
   return $newWorkload;
}

sub PrepareBlockPort
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $target = $oldWorkload->{'target'} || 'SUT';

   my ($dummyOldworkload, $dummyneworkload);
   $dummyOldworkload->{testadapter} = $oldWorkload->{blockport};
   $dummyneworkload = $self->PrepareTestAdapter($dummyOldworkload);
   $newWorkload->{blockport} = $dummyneworkload->{testadapter};
   if ($switchtype =~ /vdswitch/i) {
      # If switch type is vdswitch, pg is dvportgroup
      $newWorkload->{portgroup} = "vc.[1].dvportgroup.[$oldWorkload->{portgroup}]";
   } else {
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$target})) {
         $newWorkload->{portgroup} = "host.[1].portgroup.[$oldWorkload->{portgroup}]";
      } else {
         $newWorkload->{portgroup} = "host.[2].portgroup.[$oldWorkload->{portgroup}]";
      }
   }
   return $newWorkload;
}


sub PrepareVerifyActiveVmnic
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   $oldWorkload->{vmnicadapter} = $oldWorkload->{verifyactivevmnic};
   $newWorkload->{verifyactivevmnic} = $self->GetVmnicTupleBasedonNumber($oldWorkload);
   return $newWorkload;
}


sub PrepareSetDvsUplinkPortstatus
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';

   $oldWorkload->{vmnicadapter} = $oldWorkload->{vmnic};
   $newWorkload->{vmnicadapter} = $self->GetVmnicTupleBasedonNumber($oldWorkload);
   my $refToArray =$self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
   $newWorkload->{switch} = join ",", @$refToArray;

   return $newWorkload;
}

sub PrepareUnBlockPort
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $target = $oldWorkload->{'target'} || 'SUT';

   my ($dummyOldworkload, $dummyneworkload);
   $dummyOldworkload->{testadapter} = $oldWorkload->{unblockport};
   $dummyneworkload = $self->PrepareTestAdapter($dummyOldworkload);
   $newWorkload->{unblockport} = $dummyneworkload->{testadapter};
   if ($switchtype =~ /vdswitch/i) {
      # If switch type is vdswitch, pg is dvportgroup
      $newWorkload->{portgroup} = "vc.[1].dvportgroup.[$oldWorkload->{portgroup}]";
   } else {
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$target})) {
         $newWorkload->{portgroup} = "host.[1].portgroup.[$oldWorkload->{portgroup}]";
      } else {
         $newWorkload->{portgroup} = "host.[2].portgroup.[$oldWorkload->{portgroup}]";
      }
   }
   return $newWorkload;
}


sub PrepareVerification
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my @element = keys %$oldWorkload;
   
#   my $index = pop @element;
#print "===1===" . Dumper($oldWorkload);
   foreach my $index (@element) {
      if ($oldWorkload->{$index}{target}) {
         $vdLogger->Debug("Prepare Verification");
         my @array = split ('\,', $oldWorkload->{$index}{target});
         my @finalarray;
         foreach my $target (@array) {
            my $oldWorkloadForSupport->{testadapter} = $target;
            #my $target = $oldWorkload->{$index}{target};
            if (($target eq "dstvm") || ($target eq "dst") ||
                ($target eq "dsthost") || ($target eq "srcvm") ||
                ($target eq "src") || ($target eq "srchost")) {
               push @finalarray, $target;
            } else {
               my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
               push @finalarray, $newWorkloadForSupport->{testadapter};
            }
            $oldWorkload->{$index}{target} = join ',', @finalarray;
         }
      }
      if ($oldWorkload->{$index}{Target}) {
         $vdLogger->Debug("Prepare Verification");
         my @array = split ('\,', $oldWorkload->{$index}{Target});
         my @finalarray;
         foreach my $target (@array) {
            my $oldWorkloadForSupport->{testadapter} = $target;
            #my $target = $oldWorkload->{$index}{Target};
            if (($target eq "dstvm") || ($target eq "dst") ||
                ($target eq "dsthost") || ($target eq "srcvm") ||
                ($target eq "src") || ($target eq "srchost")) {
               push @finalarray, $target;
            } else {
               my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
               push @finalarray, $newWorkloadForSupport->{testadapter};
            }
         }
         $oldWorkload->{$index}{Target} = join ',', @finalarray;
      }
      if ($oldWorkload->{$index}{src}) {
         $vdLogger->Debug("Prepare Verification");
         my $oldWorkloadForSupport->{testadapter} = $oldWorkload->{$index}{src};
         my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
         $oldWorkload->{$index}{src} = $newWorkloadForSupport->{testadapter};
      }
      if ($oldWorkload->{$index}{dst}) {
         $vdLogger->Debug("Prepare Verification");
         my $oldWorkloadForSupport->{testadapter} = $oldWorkload->{$index}{dst};
         my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
         $oldWorkload->{$index}{dst} = $newWorkloadForSupport->{testadapter};
      }
   }
   return $oldWorkload;
}


sub PrepareTrafficAdapters
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   if ((not defined $oldWorkload->{'testadapter'}) ||
       (not defined $oldWorkload->{'supportadapter'})) {
      $vdLogger->Debug("Either Test or Support Adapter not Provided");
      $newWorkload->{Type} = "Traffic";
      return $newWorkload;
   }

   # First process the testadapter;
   $newWorkload = $self->HelperTestAdapter($oldWorkload,$newWorkload);

   # Second process the supportadapter
   # Doing this because PrepareTestAdapter()
   # api only understand testadapter because
   # the key supportadapter is not supported
   my $oldWorkloadForSupport->{testadapter} = $oldWorkload->{supportadapter};
   if (defined $oldWorkload->{supportinttype}) {
      $oldWorkloadForSupport->{inttype} = $oldWorkload->{supportinttype}
   }

   my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport,
                                                        undef,
                                                        "support");
   $newWorkload->{supportadapter} = $newWorkloadForSupport->{testadapter};
   if ($oldWorkload->{verificationadapter}) {
      my $oldWorkloadForSupport->{testadapter} = $oldWorkload->{verificationadapter};
      my $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
      $newWorkload->{verificationadapter} = $newWorkloadForSupport->{testadapter};
   }

   if ($newWorkload->{supportadapter} eq $newWorkload->{testadapter}) {
      my @supportAdapter = split '\.' ,$newWorkload->{supportadapter};
      if ($supportAdapter[0] =~ /host/i) {
         $newWorkload->{supportadapter} = "$supportAdapter[0].[2].$supportAdapter[2].$supportAdapter[3]";
      }
   }

  if ($newWorkload->{supportadapter} eq $newWorkload->{testadapter}) {
     $newWorkload->{supportadapter} = "vm.[2].vnic.[1]";
  }

   $newWorkload->{Type} = "Traffic";
   return $newWorkload;
}

sub PrepareErspanip
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{erspanip}) {
      $key = "erspanip";
      $oldWorkload->{erspanip} =~ s/\;/\,/g;
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{erspanip};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   $newWorkload->{$key} = $newWorkloadForSupport->{testadapter};
   $newWorkload->{$key} =~ s/\,/\;/g;
   return $newWorkload;
}


sub PrepareSrcrxport
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{srcrxport}) {
      $key = "srcrxport";
      $oldWorkload->{srcrxport} =~ s/\;/\,/g;
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{srcrxport};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   $newWorkload->{$key} = $newWorkloadForSupport->{testadapter};
   $newWorkload->{$key} =~ s/\,/\;/g;
   if ($oldWorkload->{srcrxport} =~ /null/i) {
      $newWorkload->{$key} = "null";
   }
   return $newWorkload;
}


sub PrepareDstport
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   if ($oldWorkload->{dstport} eq "0") {
      $newWorkload->{dstport} = "0";
      return $newWorkload;
   }
   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{dstport}) {
      $key = "dstport";
      $oldWorkload->{dstport} =~ s/\;/\,/g;
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{dstport};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   $newWorkload->{$key} = $newWorkloadForSupport->{testadapter};
   $newWorkload->{$key} =~ s/\,/\;/g;

   return $newWorkload;
}


sub PrepareDstuplink
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{dstuplink}) {
      $key = "dstuplink";
      $oldWorkload->{dstuplink} =~ s/\;/\,/g;
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{dstuplink};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   $newWorkload->{$key} = $newWorkloadForSupport->{testadapter};
   $newWorkload->{$key} =~ s/\,/\;/g;
   return $newWorkload;
}

sub PrepareSrctxport
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $key;
   my ($oldWorkloadForSupport, $newWorkloadForSupport);
   if ($oldWorkload->{srctxport}) {
      $key = "srctxport";
      $oldWorkload->{srctxport} =~ s/\;/\,/g;
      $oldWorkloadForSupport->{testadapter} = $oldWorkload->{srctxport};
   }
   $newWorkloadForSupport = $self->HelperTestAdapter($oldWorkloadForSupport);
   $newWorkload->{$key} = $newWorkloadForSupport->{testadapter};
   $newWorkload->{$key} =~ s/\,/\;/g;
   return $newWorkload;
}

#            "MigrateVdsVss11" => {
#               Type           => "Switch",
#               TestSwitch     => "vc.[1].vds.[1]",
#               migratemgmtnettovss => "host.[1].x.[x]",
#               vmknictuple       => "host.[1].vmknic.[1]",
#               vss            => "host.[1].vss.[1]",
#            },
sub PrepareMigratemgmtnettovss
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
  #my $testswitch = $oldWorkload->{'vss'} || '1';
  #my $switchtype = 'vsswitch';

   $newWorkload->{migratemgmtnettovss} = "host.[1].x.[x]";
   $newWorkload->{vmknictuple} = "host.[1].vmknic.[1]";

   #my $refToArray =$self->GetSwitchTupleBasedonNumber($testswitch, $switchtype, $target);
   $newWorkload->{vss} = "host.[1].vss.[1]";
   $newWorkload->{vmknictuple} = "host.[1].vmknic.[1]";
   delete $newWorkload->{dvportgroup};
   return $newWorkload;
}


sub PrepareMigratemgmtnettovds
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'} || 'SUT';
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if ($oldWorkload->{migratemgmtnettovds} =~ /^\d+$/) {
      my $refToArray =$self->GetPGTupleBasedonNumber($oldWorkload->{migratemgmtnettovds}, undef, $target);
      $newWorkload->{migratemgmtnettovds} = join ",", @$refToArray;
   } else {
      $newWorkload->{migratemgmtnettovds} = $TestbedSpecLookUpTable->{$oldWorkload->{migratemgmtnettovds}};
   }

   $newWorkload->{portgroup} = $oldWorkload->{portgroup};
   $newWorkload->{host} = "host.[1].x.[x]";
   $newWorkload->{testswitch} = "vc.[1].vds.[1]";
   return $newWorkload;
}


sub PrepareNetAdapter
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   if (not defined $oldWorkload->{testadapter}) {
      $oldWorkload->{testadapter} = "1"
   }
   $newWorkload = $self->PrepareTestAdapter($oldWorkload);
   $newWorkload->{Type} = "NetAdapter";
   if ($oldWorkload->{sleepbetweencombos}) {
      $newWorkload->{sleepbetweenworkloads} = $oldWorkload->{sleepbetweencombos};
   }
   if (defined $oldWorkload->{ipv4}) {
      #$newWorkload->{ipv4address} = $oldWorkload->{ipv4};
      $newWorkload->{ipv4} = $oldWorkload->{ipv4};
   }
   return $newWorkload;
}


sub PrepareNetAdapterVmotion
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   $newWorkload->{configurevmotion} = $oldWorkload->{vmotion};

   return $newWorkload;
}


sub PrepareTestAdapter
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my ($inventory, $inventoryIndex, $target, $returnTestAdapter);
   my ($componentType, $componentIndex, $tuple);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();

   my @arrTuples;
   my @arrayOfTestAdapters = split (',', $oldWorkload->{testadapter});
   foreach my $adapter (@arrayOfTestAdapters) {
      if ((defined $adapter) && ($adapter =~ /(:|\.)/)) {
         $adapter =~ s/\:/\./g;
         my @arr = split('\.', $adapter);
         $target = $arr[0];
         $componentType = $arr[1];
         $componentIndex = $arr[2];
      } else {
         $target = $oldWorkload->{target} || "SUT";
         $componentType  = lc($oldWorkload->{inttype}) || "vnic";
         $componentIndex = $adapter || "1";
      }

      # Resolving Inventory and Inventory Index
      my @arrTarget = split(',', $target);
      for my $target (@arrTarget) {
         # Resolving Inventory for host/vm case.
         if ($componentType =~ m/vmknic|vmnic/i) {
            # The tuples involves host and vmknics/vmnic
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            if (exists($host1Machines{$target})) {
               $inventoryIndex = "1";
            } else {
               $inventoryIndex = "2";
            }
            $inventory = "host";
         } elsif ($componentType =~ m/vnic|pci/i) {
            if ($componentType =~ /pci/i) {
               $componentType = "pcipassthru";
            } else {
               $componentType = "vnic";
            }
            # The tuples involves vm and vnics/pci
            $inventory = "vm";
            # Resolving Inventory Index for vnic/pci case.
            if ($target =~ m/SUT/i) {
               $inventoryIndex = "1";
            } elsif ($componentType =~ m/vnic|pci/i) {
               my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
               my $index = first { $nums[$_] eq $target } 0..$#nums;
               $inventoryIndex = $index + "1";
               #$target =~ s/\D//g;
               #$inventoryIndex = $target + "1";
            }
         }
         $tuple = "$inventory.[$inventoryIndex].$componentType.[$componentIndex]";
         push (@arrTuples, $tuple);
      }
   }
   $returnTestAdapter = join(',',@arrTuples);
   $newWorkload->{testadapter} = $returnTestAdapter;
   # Handle depricated Keys
   my %depricatedKeys = map { $_ => 1 } @{$WorkloadLookUpTable->{NetAdapter}{depricatedkeys}};
   foreach my $oldkey (keys %$oldWorkload) {
      if (exists($depricatedKeys{$oldkey})) {
         my $method = $WorkloadLookUpTable->{NetAdapter}{$oldkey};
         $newWorkload = $self->$method($oldWorkload,$newWorkload);
      }
   }
   return $newWorkload;
}


sub HelperTestAdapter
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $support = shift || undef;
   my ($inventory, $inventoryIndex, $target, $returnTestAdapter);
   my ($componentType, $componentIndex, $tuple);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   my @arrTuples;
   if (defined $oldWorkload->{testadapter}) {
      my @arrayOfTestAdapters = split (',', $oldWorkload->{testadapter});
      foreach my $adapter (@arrayOfTestAdapters) {
         if ((defined $adapter) && ($adapter =~ /(:|\.)/)) {
            $adapter =~ s/\:/\./g;
            my @arr = split('\.', $adapter);
            $target = $arr[0];
            $componentType = $arr[1];
            $componentIndex = $arr[2];
         } else {
            $target = $oldWorkload->{target} || "SUT";
            $componentType  = lc($oldWorkload->{inttype}) ||
                              lc($oldWorkload->{testinttype}) || "vnic";
            #print "\n===1===$self->{testcaseHash}{TestName}";
            # Special case for NetworkDataPath tests
            my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
            my @nums = @{$TestbedSpecLookUpTable->{SupportAdapterIsVM2}};
            my $index = undef;
            if ((defined $support) && ($componentType =~ /vnic/i)) {
                my $testname = $self->{testcaseHash}{TestName};
                $index = first { $nums[$_] =~ m/$testname/i } 0..$#nums;
                #print "===1===$testname";
                if (defined $index) {
                   $target = "helper1";
                }
             }
            $componentIndex = $adapter || "1";
         }
         if (($target eq "dstvm") || ($target eq "dst") ||
             ($target eq "dsthost") || ($target eq "srcvm") ||
             ($target eq "src") || ($target eq "srchost")) {
            $newWorkload->{testadapter} = $target;
            return $newWorkload;
         }
   
         # Resolving Inventory and Inventory Index
         # Resolving Inventory for host/vm case.
         if ($componentType =~ m/vmknic|vmnic/i) {
            # The tuples involves host and vmknics/vmnic
            my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
            if (exists($host1Machines{$target})) {
               $inventoryIndex = "1";
            } else {
               $inventoryIndex = "2";
            }
            $inventory = "host";
         } elsif ($componentType =~ m/vnic|pci/i) {
            if ($componentType =~ /pci/i) {
               $componentType = "pcipassthru";
            } else {
               $componentType = "vnic";
            }
            # The tuples involves vm and vnics/pci
            $inventory = "vm";
            # Resolving Inventory Index for vnic/pci case.
            if ($target =~ m/SUT/i) {
               $inventoryIndex = "1";
            } elsif ($componentType =~ m/vnic|pci/i) {
               #print "\n===helpervm for $target";
               #print "==12==" . Dumper($TestbedSpecLookUpTable);
               if (defined $TestbedSpecLookUpTable->{vmarray}) {
                  my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
                  my $index = first { $nums[$_] eq $target } 0..$#nums;
                  #$target =~ s/\D//g;
                  #$inventoryIndex = $target + "1";
                  $inventoryIndex = $index + "1";
               }
               #print "\n===helpervm for $target = $inventoryIndex" . Dumper($TestbedSpecLookUpTable);
            }
         }
         $tuple = "$inventory.[$inventoryIndex].$componentType.[$componentIndex]";
         push (@arrTuples, $tuple);
      }
   }
   $returnTestAdapter = join(',',@arrTuples);
   $newWorkload->{testadapter} = $returnTestAdapter;
   #print "===1===" . Dumper($newWorkload);
   return $newWorkload;
}

sub PrepareDVFilter
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $target = $oldWorkload->{'target'};
   my ($dvfiltertest, $roles) = split(':',$target);
   $newWorkload->{role} = $roles;

   my @arrayofTestVM;
   if ($dvfiltertest =~ m/SUT/i) {
      my $inventoryIndex = "1";
      push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
   } else {
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
      
      my $index = 0;
      $index = first { $nums[$_] eq $dvfiltertest} 0..$#nums;
      my $inventoryIndex = $index + "1";
      push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
   }
   $newWorkload->{testdvfilter} = join ',', @arrayofTestVM;

   if (defined $oldWorkload->{'slowpathtarget'}) {
      my $target = $oldWorkload->{'slowpathtarget'};
      if ($target =~ m/SUT/i) {
         my $inventoryIndex = "1";
         $newWorkload->{slowpathtarget} = "vm.[$inventoryIndex].x.[x]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $target} 0..$#nums;
         my $inventoryIndex = $index + "1";
         $newWorkload->{slowpathtarget} = "vm.[$inventoryIndex].x.[x]";
      }
   }

   if (defined $oldWorkload->{'helpertarget'}) {
      my $target = $oldWorkload->{'helpertarget'};
      if ($target =~ m/SUT/i) {
         my $inventoryIndex = "1";
         $newWorkload->{slowpathtarget} = "vm.[$inventoryIndex].x.[x]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $target} 0..$#nums;
         my $inventoryIndex = $index + "1";
         $newWorkload->{slowpathtarget} = "vm.[$inventoryIndex].x.[x]";
      }
   }

   if (($oldWorkload->{'testadapter'}) || ($oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload,$newWorkload);
   }
   if (defined $oldWorkload->{'supportadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldTempWorkload->{testadapter} = $oldWorkload->{'supportadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldWorkload);
      $newWorkload->{'supportadapter'} = $newTempWorkload->{testadapter};
   }
   $newWorkload->{'Type'} = "DVFilter";
   return $newWorkload;
}


sub PrepareTestHost
{
   my $self = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $testswitch = $oldWorkload->{'testswitch'} || '1';
   my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $machine = $oldWorkload->{'target'} || "SUT";
   my $tuple;
   if ((defined $oldWorkload->{'testadapter'}) || (defined $oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload, $newWorkload);
   }
   if (defined $oldWorkload->{'supportadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldTempWorkload->{testadapter} = $oldWorkload->{'supportadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldTempWorkload);
      $newWorkload->{'supportadapter'} = $newTempWorkload->{testadapter};
   }
   if (defined $oldWorkload->{'uplinkname'}) {
    my @arrayOfUplinkName;
      my @pnicArray = split(/-/, $oldWorkload->{'uplinkname'});
      foreach my $item (@pnicArray) {
         my $oldTempWorkload = $oldWorkload;
         $oldTempWorkload->{testadapter} = $item;
         my $newTempWorkload = $self->HelperTestAdapter($oldWorkload);
         push @arrayOfUplinkName, $newTempWorkload->{testadapter};
      }
      $newWorkload->{'vmnicadapter'} = join ';;',@arrayOfUplinkName;
   }

   my @arrayofTestHost;
   my @arrayOfMachines = split (',', $machine);
   foreach my $machine (@arrayOfMachines) {
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      if (exists($host1Machines{$machine})) {
         push @arrayofTestHost, "host.[1].x.[x]";
      } else {
         push @arrayofTestHost, "host.[2].x.[x]";
      }
   }
   $newWorkload->{testhost} = join(',',@arrayofTestHost);
   $newWorkload->{Type} = "Host";

   # Handle depricated Keys
   my %depricatedKeys = map { $_ => 1 } @{$WorkloadLookUpTable->{Host}{depricatedkeys}};
   foreach my $oldkey (keys %$oldWorkload) {
      if (exists($depricatedKeys{$oldkey})) {
         my $method = $WorkloadLookUpTable->{Host}{$oldkey};
         $newWorkload = $self->$method($oldWorkload,$newWorkload,$switchtype);
      }
   }
   if ((defined $oldWorkload->{'ip'}) &&
       (defined $oldWorkload->{firewall}) &&
       ($oldWorkload->{firewall} =~ /IPSet/i)) {
      $newWorkload->{ip} = $oldWorkload->{'ip'};
   }
   if ($oldWorkload->{configureportgroup}) {
      delete $oldWorkload->{testswitch};
      delete $newWorkload->{testswitch};
   }
   return $newWorkload;
}


sub PrepareCommand
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   my $target = $oldWorkload->{target};
   my $hosttype = $oldWorkload->{hosttype};
   if (defined $target) {
      if ($hosttype =~ m/vm/i) {
         my $inventoryIndex;
         if ($target =~ m/SUT/i) {
            $inventoryIndex = "1";
         } else {
            my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
            my $index = first { $nums[$_] eq $target } 0..$#nums;
            $inventoryIndex = $index + "1";
         }
         $newWorkload->{testvm} = "vm.[$inventoryIndex].x.x";
      } elsif ($hosttype =~ m/esx/i) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$target})) {
            $newWorkload->{testhost} = "host.[1].x.[x]";
         } else {
            $newWorkload->{testhost} ="host.[2].x.[x]";
         }
      } elsif ($hosttype =~ /local/i) {
         $newWorkload->{testlocal} ="local";
      } elsif ($hosttype =~ m/vc/i) {
         $newWorkload->{testvc} ="vc.[1].x.[x]";
      }
   }
   $newWorkload->{Type} = "Command";
   $newWorkload->{command} = $oldWorkload->{command};
   return $newWorkload;
}


sub PrepareTestVC
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpec = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $WorkloadLookUpTable = $self->GetWorkloadLookUpTable();
   if (defined $oldWorkload->{vm}) {
      my $inventoryIndex;
      my @arrayofTestVM;
      my @arrayOfMachines = split (',', $oldWorkload->{vm});
      foreach my $machines (@arrayOfMachines) {
         if ($machines =~ m/SUT/i) {
            $inventoryIndex = "1";
            push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
         } else {
            $machines =~ s/\D//g;
            $inventoryIndex = $machines + "1";
            push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
         }
      }
      $newWorkload->{vm} = join(',',@arrayofTestVM);
   }

   if ((defined $oldWorkload->{testhost}) ||
      ($oldWorkload->{opt} =~ /removevdr/i)) {
      if (not defined  $oldWorkload->{testhost}) {
         $oldWorkload->{testhost} =  $oldWorkload->{host};
      }
      my @arrayofTestHost;
      my @arrayOfMachines = split (',', $oldWorkload->{testhost});
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
   } else {
      my @arrayofTestHost;
      my $target;
      if (defined $oldWorkload->{vm}) {
         $target = $oldWorkload->{vm};
      } elsif (defined $oldWorkload->{hosts}) {
         $target = $oldWorkload->{hosts};
      } elsif (defined $oldWorkload->{host}) {
         $target = $oldWorkload->{host};
      } else {
         $target = "SUT";
      }
      my @arrayOfMachines = split (',', $target);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
   }

   if (defined $oldWorkload->{dsthost}) {
      my @arrayofTestHost;
      my @arrayOfMachines = split (',', $oldWorkload->{dsthost});
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{dsthost} = join(',',@arrayofTestHost);
   }

   if (defined $oldWorkload->{referencehost}) {
      my @arrayofTestHost;
      my @arrayOfMachines = split (',', $oldWorkload->{referencehost});
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{referenceHost} = join(',',@arrayofTestHost);
   }

   # Doing this now to fix astupid issue
   $newWorkload->{testvc} = "vc.[1].x.[x]";
   $newWorkload->{Type} = "VC";
   if ($oldWorkload->{opt} =~ /connect/i) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      delete $newWorkload->{testhost};
      #$TestbedSpecLookUpTable->{vccount} = "YES";
      $self->{testcaseHash}{TestbedSpec}{vc}{'[1]'} = {};
      $TestbedSpec->{vc}{'[1]'} = {};
   }
   if ($oldWorkload->{opt} =~ /checkpools/i) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      #delete $newWorkload->{testhost};
      #$TestbedSpecLookUpTable->{vccount} = "YES";
      $self->{testcaseHash}{TestbedSpec}{vc}{'[1]'} = {};
      $TestbedSpec->{vc}{'[1]'} = {};
   }

   if ((defined $oldWorkload->{vdsname}) && ($oldWorkload->{vdsname} !~ /^\d+$/) &&
       ($oldWorkload->{opt} !~ /createvds/i)) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      $newWorkload->{vds} = $TestbedSpecLookUpTable->{$oldWorkload->{vdsname}};
   }

   # Add removevdr
   if ($oldWorkload->{opt} =~ /removevdr/i) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      my $target = $oldWorkload->{target} || "SUT";
      my $refToArray = $self->GetSwitchTupleBasedonNumber($oldWorkload->{vdsindex}, "vdswitch", $target);
      $newWorkload->{vds} = join ",", @$refToArray;
      delete $oldWorkload->{testhost};
      delete $oldWorkload->{vdsindex};
   }

   if (($oldWorkload->{vdsindex}) &&
      ($oldWorkload->{opt} !~ /removevdr/i)) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      my $target = $oldWorkload->{target} || "SUT";
      my $refToArray =$self->GetSwitchTupleBasedonNumber($oldWorkload->{vdsindex}, "vdswitch", $target);
      $newWorkload->{vds} = join ",", @$refToArray;
      delete $newWorkload->{testhost};
   }

   # Add vmk
   if ($oldWorkload->{opt} =~ /vdl2/i) {
      $newWorkload = $self->PrepareVDL2($oldWorkload, $newWorkload);
   }

   # Add setmac
   if ($oldWorkload->{opt} =~ /setmac/i) {
      $newWorkload->{opt} = $oldWorkload->{opt};
   }

   # Add removevds
   if ($oldWorkload->{opt} =~ /removevds/i) {
      if (defined $oldWorkload->{vdsindex}) {
         $newWorkload->{deletevds} = "vc.[1].vds.[1]";
      }
      if (defined $oldWorkload->{vdsname}) {
         $newWorkload->{deletevds} = $TestbedSpecLookUpTable->{$oldWorkload->{vdsname}};
      }
      delete $newWorkload->{vds};
      delete $newWorkload->{testhost};
      delete $oldWorkload->{vdsindex};
      delete $newWorkload->{opt};
   } elsif ($oldWorkload->{opt} =~ /createvds/i) {
      #print "\n===PrepareVDSMain===\n";
      $newWorkload = $self->PrepareVDS($oldWorkload, $newWorkload);
   }

   if ($oldWorkload->{sleepbetweencombos}) {
      $newWorkload->{sleepbetweenworkloads} = $oldWorkload->{sleepbetweencombos};
   }

   # Add vmk
   if (($oldWorkload->{opt} =~ /addvmk|removevmk/i)) {
      $newWorkload = $self->PrepareAddvmk($oldWorkload, $newWorkload);
      $newWorkload->{opt} = $oldWorkload->{opt};
   }

   # Add vmk
   if (($oldWorkload->{opt} =~ /changevmknic/i)) {
      $newWorkload = $self->PrepareChangevmknic($oldWorkload, $newWorkload);
   }

  # Handle nrp
   if (($oldWorkload->{opt} =~ /nrp|counter|netio|optout|setlinnet|vxlan|removehostfromvds|removehostfromdc/i)) {
      $newWorkload->{opt} = $oldWorkload->{opt};
   }

  # Handle vxlan
   if (($oldWorkload->{opt} =~ /vxlantsamcheck/i)) {
      my @arrayOdVDS = split('\,',$oldWorkload->{testswitch});
      my @arrayOfSwitch;
      foreach my $index (@arrayOdVDS) {
         my @switchArray = @{$TestbedSpecLookUpTable->{sutswitcharray}};
         push @arrayOfSwitch, $switchArray[$index-1];
      }
      $newWorkload->{testswitch} = join ';;',@arrayOfSwitch;
      my @arraofHost = split ('\,' , $newWorkload->{testhost});
      $newWorkload->{testhost} = join ';;', @arraofHost;
   }

  # Handle folder add/delete
   if (($oldWorkload->{opt} =~ /folder/i)) {
      $newWorkload->{opt} = $oldWorkload->{opt};
      delete $newWorkload->{testhost};
   }

   # Add Datacenter
   if (($oldWorkload->{opt} =~ /adddc|removedc/i)) {
      $newWorkload = $self->PrepareDatacenter($oldWorkload, $newWorkload);
   }
   # Remove Host from VDS
   if (($oldWorkload->{opt} =~ /removehostfromvds/i)) {
      $newWorkload = $self->Removehostfromvds($oldWorkload, $newWorkload);
   }

   # Add vmk
   if (($oldWorkload->{opt} =~ /profile|editpolicyopt|checkcompliance|importanswer/i)) {
      $newWorkload = $self->PrepareProfile($oldWorkload, $newWorkload);
   }

   # Handle removehostfromvds
   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} =~ /removehostfromvds/i)) {
      delete $newWorkload->{testswitch};
   }

   # Handle vmotion
   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} =~ /vmotion/i)) {
       $newWorkload = $self->PrepareVmotion($oldWorkload, $newWorkload);
   }

   # Handle removehostfromvds
   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} =~ /setvdsuplink/i)) {
    if (defined $oldWorkload->{count}) {
        $newWorkload->{count} = $oldWorkload->{count};
    }
   }

   # Handle depricated Keys
   my %depricatedKeys = map { $_ => 1 } @{$WorkloadLookUpTable->{VC}{depricatedkeys}};
   foreach my $oldkey (keys %$oldWorkload) {
      if (exists($depricatedKeys{$oldkey})) {
         my $method = $WorkloadLookUpTable->{VC}{$oldkey};
         $newWorkload = $self->$method($oldWorkload,$newWorkload);
      }
   }

   return $newWorkload;
}


sub PrepareVmotion
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $newWorkload->{Type} = "VM";
   $newWorkload->{testvm} = $newWorkload->{vm};
   if ((defined $oldWorkload->{roundtrip}) && ($oldWorkload->{roundtrip} =~ /yes/i)) {
      $newWorkload->{vmotion} = "roundtrip";
   } else {
      $newWorkload->{vmotion} = "oneway";
   }

   if (defined $oldWorkload->{iterations}) {
      $newWorkload->{iterations} = $oldWorkload->{iterations};
   }

   delete $newWorkload->{vm};
   delete $newWorkload->{testhost};
   delete $newWorkload->{testvc};
   delete $oldWorkload->{dsthost};
   delete $oldWorkload->{opt};
   delete $oldWorkload->{roundtrip};
   delete $oldWorkload->{vm};
   return $newWorkload;
}

sub PrepareChangevmknic
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $vds;
   if (defined $oldWorkload->{vdsindex}) {
      $vds = $oldWorkload->{vdsindex};
   } else {
      $vds = "1";
   }
   $newWorkload->{opt} = $oldWorkload->{opt};
   my $target = $oldWorkload->{target} || "SUT";
   my $refToArray =$self->GetSwitchTupleBasedonNumber($vds, "vdswitch", $target);
   $newWorkload->{vds} = join ",", @$refToArray;
   $newWorkload->{opt} = $oldWorkload->{opt};
   return $newWorkload;
}


sub PrepareConfigureportrules
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $tuple = $oldWorkload->{configureportrules};
   $tuple =~ s/qw//;
   $tuple =~ s/\(|\)//g;
   my $oldTempWorkloadVM->{testadapter} = $tuple;
   my $newTempWorkloadVM = $self->HelperTestAdapter($oldTempWorkloadVM);
   $newWorkload->{configureportrules} = $newTempWorkloadVM->{testadapter};

   # prepare testhost
   my $machine = $oldWorkload->{target};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   if (exists($host1Machines{$machine})) {
      $newWorkload->{testhost} = "host.[1].x.[x]";
   } else {
      $newWorkload->{testhost} = "host.[2].x.[x]";
   }

   # prepare testvm
   if ($machine =~ m/SUT/i) {
      my $inventoryIndex = "1";
      $newWorkload->{testvm} = "vm.[$inventoryIndex].x.[x]";
   } else {
      my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
      my $index = 0;
      $index = first { $nums[$_] eq $machine } 0..$#nums;
      my $inventoryIndex = $index + "1";
      $newWorkload->{testvm} = "vm.[$inventoryIndex].x.[x]";
   }

   return $newWorkload;
}



sub PrepareBackuprestore
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   $newWorkload->{portgroup} = "vc.[1].dvportgroup.[$oldWorkload->{testswitch}]";
   return $newWorkload;
}

sub PrepareVDL2
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   if (defined $oldWorkload->{pgname}) {
      $newWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{pgname}};
      delete $newWorkload->{pgname};
      delete $oldWorkload->{pgname};
   }
   my $peerhost = $oldWorkload->{peerhost};
   if (defined $oldWorkload->{peerhost}) {
      my @arrayofTestHost;
      my $machine = $oldWorkload->{peerhost};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{peerhost} = join(',',@arrayofTestHost);
   }
   if (defined $oldWorkload->{host}) {
      my @arrayofTestHost;
      my $machine = $oldWorkload->{host};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
   }

   if (defined $oldWorkload->{testadapter}) {
      my @arrayofTestHost;
      my $machine = $peerhost;
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            $newWorkload->{testadapter} = "host.[1].vmknic." . "[" . $oldWorkload->{testadapter} . "]";
         } else {
            $newWorkload->{testadapter} = "host.[2].vmknic." . "[" . $oldWorkload->{testadapter} . "]";
         }
      }
   }

   $newWorkload->{opt} = $oldWorkload->{opt};
   delete $oldWorkload->{testadapter};
   return $newWorkload;
}



sub PrepareProfile
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # For Referencehost to dstHost
   if (defined $oldWorkload->{referencehost}) {
      my @arrayofTestHost;
      my $machine = $oldWorkload->{referencehost};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{dsthost} = join(',',@arrayofTestHost);
   }

   if ($oldWorkload->{opt} eq "createprofile") {
      delete $oldWorkload->{opt};
      delete $newWorkload->{testhost};
      $newWorkload->{createprofile} = "profile";
      $newWorkload->{targetprofile} = $oldWorkload->{targetprofile};
      delete $oldWorkload->{dsthost};
      delete $newWorkload->{dsthost};
      delete $oldWorkload->{referencehost};
      delete $newWorkload->{referencehost};
      delete $oldWorkload->{referenceHost};
      delete $newWorkload->{referenceHost};
   }

   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} eq "associateprofile")) {
      $newWorkload->{associateprofile} = $oldWorkload->{targetprofile};
      delete $oldWorkload->{opt};
      delete $newWorkload->{testhost};
      delete $oldWorkload->{targetprofile};
      delete $newWorkload->{targetprofile};
   }

   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} eq "destroyprofile")) {
      $newWorkload->{destroyprofile} = $oldWorkload->{targetprofile};
      delete $oldWorkload->{opt};
      delete $newWorkload->{testhost};
      delete $oldWorkload->{targetprofile};
      delete $newWorkload->{targetprofile};
   }

   if ((defined $oldWorkload->{opt}) && ($oldWorkload->{opt} eq "editpolicyopt")) {
      #$newWorkload = $oldWorkload;
      $newWorkload->{opt} = $oldWorkload->{opt};
      $oldWorkload->{testhost} = $oldWorkload->{host};
      $newWorkload->{targetprofile} = $oldWorkload->{targetprofile};
   }

   # For Referencehost to dstHost
   if (defined $oldWorkload->{referencehost}) {
      my @arrayofTestHost;
      my $machine = $oldWorkload->{referencehost};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{dsthost} = join(',',@arrayofTestHost);
   }

   # For Host to srcHost
   if ((defined $oldWorkload->{host}) ||
       ($oldWorkload->{opt} eq "checkcompliance") ||
       ($oldWorkload->{opt} eq "importanswer") ||
       ($oldWorkload->{opt} eq "applyprofile")) {
      my @arrayofTestHost;
      my $machine = $oldWorkload->{host};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      if ((defined $oldWorkload->{opt}) && 
          (($oldWorkload->{opt} eq "checkcompliance") ||
          ($oldWorkload->{opt} eq "importanswer") ||
          ($oldWorkload->{opt} eq "applyprofile"))) {
         if ($oldWorkload->{opt} eq "checkcompliance") {
            $newWorkload->{checkcompliance} = $oldWorkload->{targetprofile};
            $newWorkload->{compliancestatus} = "compliant";
         } elsif ($oldWorkload->{opt} eq "importanswer") {
            my @arrayDir = split('\/', $oldWorkload->{answerfile});
            $newWorkload->{importanswer} = $arrayDir[2];
            delete $oldWorkload->{answerfile};
         } elsif ($oldWorkload->{opt} eq "applyprofile") {
            $newWorkload->{applyprofile} = $oldWorkload->{targetprofile};
            delete $oldWorkload->{answerfile};
         }
         
         delete $oldWorkload->{referenceHost};
         delete $newWorkload->{referenceHost};
         delete $newWorkload->{testhost};
         delete $newWorkload->{opt};
         delete $oldWorkload->{opt};
      }
      $newWorkload->{srchost} = join(',',@arrayofTestHost);

   }


   # For Host to srcHost
   if (defined $newWorkload->{testhost}) {
      my @arrayofTestHost;
      my $machine = $newWorkload->{testhost};
      my @arrayOfMachines = split (',', $machine);
      foreach my $machine (@arrayOfMachines) {
         my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
         if (exists($host1Machines{$machine})) {
            push @arrayofTestHost, "host.[1].x.[x]";
         } else {
            push @arrayofTestHost, "host.[2].x.[x]";
         }
      }
      $newWorkload->{testhost} = join(',',@arrayofTestHost);
      $newWorkload->{opt} = $oldWorkload->{opt};
      delete $oldWorkload->{srchost};
      delete $newWorkload->{srchost};
   }

   return $newWorkload;
}


sub PrepareConstantKey
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $keyName = shift;
   $keyName = shift;

   my $constantTable = GetvdNetConstantTable;
   my $keyValue = $oldWorkload->{$keyName};
   if (defined $constantTable->{$keyValue}) {
      $newWorkload->{$keyName} = $constantTable->{$keyValue};
   }

   return $newWorkload;
}


sub PrepareAddvmk
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   if ($oldWorkload->{opt} =~ /removevmk/i) {
      return $self->PrepareRemovevmk($oldWorkload, $newWorkload);
   }
   #print "===1==" . Dumper($newWorkload);
   #print "===2==" . Dumper($oldWorkload);
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $newWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{dvportgroupname}};
   $newWorkload->{datacenter} = $TestbedSpecLookUpTable->{$oldWorkload->{dcname}};
   delete $newWorkload->{dvportgroupname};
   delete $oldWorkload->{dvportgroupname};
   return $newWorkload;
}


sub PrepareRemovevmk
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   delete $newWorkload->{portgroup};
   delete $oldWorkload->{portgroup};
   delete $newWorkload->{datacenter};
   delete $oldWorkload->{datacenter};
   return $newWorkload;
}


sub PrepareDatacenter
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   if ($oldWorkload->{opt} =~ /removedc/i) {
      return $self->PrepareDeleteDatacenter($oldWorkload, $newWorkload);
   }
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $TestbedSpecLookUpTable->{'dcCount'}  = $TestbedSpecLookUpTable->{'dcCount'}  + 1;
   my $dccount = $TestbedSpecLookUpTable->{'dcCount'} ;
   my $index = "[" . $dccount . "]";

   my @arrayOfHosts;
   my @arrayOfTarget = split('\,', $oldWorkload->{hosts});
   my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
   foreach my $target (@arrayOfTarget) {
      if (exists($host1Machines{$target})) {
         push @arrayOfHosts, "host.[1].x.[x]";
      } else {
         push @arrayOfHosts, "host.[2].x.[x]";
      }
   }
   my $host = join(';;', @arrayOfHosts);
   my $datacenter = $oldWorkload->{dcname};
   $datacenter =~ s/\/|\\//g;
   #$datacenter =~ s/\///g;
   $newWorkload->{datacenter} = {
      $index => {
         'host' => $host,
         'name' => $datacenter,
      }
   };
   delete $newWorkload->{opt};
   delete $newWorkload->{testhost};
   $TestbedSpecLookUpTable->{$datacenter} = "vc.[1].datacenter.$index";
   return $newWorkload;
}

sub PrepareDeleteDatacenter
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $TestbedSpecLookUpTable->{'dcCount'}  = $TestbedSpecLookUpTable->{'dcCount'} - 1;
   my $datacenter = $oldWorkload->{dcname};
   $datacenter =~ s/\///g;
   if (defined $TestbedSpecLookUpTable->{$datacenter}) {
      $newWorkload->{deletedatacenter} = $TestbedSpecLookUpTable->{$datacenter};
   } else {
      $datacenter = "/" . $datacenter;
      $newWorkload->{deletedatacenter} = $TestbedSpecLookUpTable->{$datacenter};
   }
   
   delete $newWorkload->{opt};
   delete $newWorkload->{testhost};
#print "===1===$datacenter" . Dumper($TestbedSpecLookUpTable);
   return $newWorkload;
}


sub PrepareAddremdvfiltertovm
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{target} || "SUT";
   my @arrayofTestVM;
   my $inventoryIndex;
   my @arrayOfMachines = split (',', $target);
   foreach my $machines (@arrayOfMachines) {
      if ($machines =~ m/SUT/i) {
         $inventoryIndex = "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $machines } 0..$#nums;
         $inventoryIndex = $index + "1";
         #$machines =~ s/\D//g;
         #$inventoryIndex = $machines + "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      }
   }
   $newWorkload->{testvm} = join(',',@arrayofTestVM);

   return $newWorkload;

}

sub PrepareEsxclivmportlistverify
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{target} || "SUT";
   my @arrayofTestVM;
   my $inventoryIndex;
   my @arrayOfMachines = split (',', $target);
   foreach my $machines (@arrayOfMachines) {
      if ($machines =~ m/SUT/i) {
         $inventoryIndex = "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $machines } 0..$#nums;
         $inventoryIndex = $index + "1";
         #$machines =~ s/\D//g;
         #$inventoryIndex = $machines + "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      }
   }
   $newWorkload->{esxclivmportlistverify} = join(',',@arrayofTestVM);

   return $newWorkload;

}


sub PrepareLRO
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{target} || "SUT";
   my @arrayofTestVM;
   my $inventoryIndex;
   my @arrayOfMachines = split (',', $target);
   foreach my $machines (@arrayOfMachines) {
      if ($machines =~ m/SUT/i) {
         $inventoryIndex = "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].vnic.[1]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $machines } 0..$#nums;
         $inventoryIndex = $index + "1";
         #$machines =~ s/\D//g;
         #$inventoryIndex = $machines + "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].vnic.[1]";
      }
   }
   $newWorkload->{adapter} = join(',',@arrayofTestVM);

   return $newWorkload;

}
sub PrepareTestVM
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;

   my $target = $oldWorkload->{target} || "SUT";
   my $inventoryIndex;
   # Resolving Inventory Index for vnic/pci case.
   if (($oldWorkload->{'testadapter'}) || ($oldWorkload->{'inttype'})) {
      $newWorkload = $self->HelperTestAdapter($oldWorkload, $newWorkload);
   }

   if (defined $oldWorkload->{'clientadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldTempWorkload->{testadapter} = $oldWorkload->{'clientadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldTempWorkload);
      $newWorkload->{'clientadapter'} = $newTempWorkload->{testadapter};
    
   }

   my @arrayofTestVM;
   my @arrayOfMachines = split (',', $target);
   foreach my $machines (@arrayOfMachines) {
      if ($machines =~ m/SUT/i) {
         $inventoryIndex = "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      } else {
         my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         
         my $index = 0;
         $index = first { $nums[$_] eq $machines } 0..$#nums;
         $inventoryIndex = $index + "1";
         #$machines =~ s/\D//g;
         #$inventoryIndex = $machines + "1";
         push @arrayofTestVM, "vm.[$inventoryIndex].x.[x]";
      }
   }

   # Handle Port Group
   if (defined $oldWorkload->{'portgroupname'}) {
      my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
      if ($oldWorkload->{'portgroupname'} =~ /^\d+$/) {
         my $refToSwitchArray = $TestbedSpecLookUpTable->{sutswitcharray};
         my $pgTuple;
         my $switchtype;
         if ((defined $refToSwitchArray->[0]) &&
             ($refToSwitchArray->[0] =~ /vds/i)) {
            $switchtype = "vdswitch";
         } else {
            $switchtype = "vsswitch";
         }
         my $testpg = $oldWorkload->{'portgroupname'};
         my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
         $newWorkload->{testpg} = join ",", @$refToArray;
      } else {
         $newWorkload->{testpg} = $TestbedSpecLookUpTable->{$oldWorkload->{'portgroupname'}};
      }

   }

   $newWorkload->{testvm} = join(',',@arrayofTestVM);
   $newWorkload->{Type} = "VM";
   if ($oldWorkload->{sleepbetweencombos}) {
      $newWorkload->{sleepbetweenworkloads} = $oldWorkload->{sleepbetweencombos};
   }
   $newWorkload->{operation} = $oldWorkload->{operation};
   if (defined $oldWorkload->{iterations}) {
      $newWorkload->{iterations} = $oldWorkload->{iterations};
   }

   if ($oldWorkload->{operation} =~ /ChangePortGroup/i) {
       $newWorkload = $self->PrepareChangePortGroup($oldWorkload,$newWorkload);
   }

   # Handle poweron/poweroff keys
   if (($oldWorkload->{operation} =~ /poweroff/i) &&
       ($oldWorkload->{operation} =~ /poweron/i)) {
       $newWorkload->{vmstate} = "poweroff,poweron";
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
       delete $newWorkload->{waitforvdnet};
       delete $oldWorkload->{waitforvdnet};
   }

   # Handle suspend/resume keys
   #print "===1===$oldWorkload->{operation}";
   if (($oldWorkload->{operation} =~ /suspend/i) &&
       ($oldWorkload->{operation} =~ /resume/i)) {
       $newWorkload->{vmstate} = "suspend,resume";
       delete $newWorkload->{waitforvdnet};
       delete $oldWorkload->{waitforvdnet};
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
   }

   # Handle poweron/poweroff/suspend/resume keys
   if  ((exists $oldWorkload->{operation}) && ($oldWorkload->{operation} =~ /poweron/i)) {
       $newWorkload->{vmstate} = "poweron";
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
       delete $newWorkload->{waitforvdnet};
       delete $oldWorkload->{waitforvdnet};
   }
   if ((exists $oldWorkload->{operation}) && ($oldWorkload->{operation} =~ /poweroff/i)) {
       $newWorkload->{vmstate} = "poweroff";
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
   }
   if ((exists $oldWorkload->{operation}) && ($oldWorkload->{operation} =~ /suspend/i)) {
       $newWorkload->{vmstate} = "suspend";
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
   }
   if ((exists $oldWorkload->{operation}) && ($oldWorkload->{operation} =~ /resume/i)) {
       $newWorkload->{vmstate} = "resume";
       delete $oldWorkload->{operation};
       delete $newWorkload->{operation};
       delete $newWorkload->{waitforvdnet};
       delete $oldWorkload->{waitforvdnet};
   }

   if (defined $oldWorkload->{'passthroughadapter'}) {
      my $oldTempWorkload = $oldWorkload;
      $oldTempWorkload->{testadapter} = $oldWorkload->{'passthroughadapter'};
      my $newTempWorkload = $self->HelperTestAdapter($oldTempWorkload);
      $newWorkload->{'passthroughadapter'} = $newTempWorkload->{testadapter};
      $newWorkload = $self->PrepareVnic($oldWorkload, $newWorkload, "pcipassthru");
      delete $oldWorkload->{vfindex};
      delete $oldWorkload->{pciindex};
      delete $oldWorkload->{operation};
      delete $newWorkload->{operation};
      delete $oldWorkload->{passthroughadapter};
      delete $newWorkload->{'passthroughadapter'};
   }

   # Add/Remove Vnic
   if ((defined $newWorkload->{operation}) &&
      ($newWorkload->{operation} =~ /hotaddvnic|hotremovevnic/i)) {
      $newWorkload = $self->PrepareVnic($oldWorkload, $newWorkload);
   }

   # drivername
   if (defined $oldWorkload->{drivername}) {
      delete $oldWorkload->{drivername};
   }

   return $newWorkload;
}


#sub PrepareSetmonitoring
#{
#   my $self        = shift;
#   my $oldWorkload = shift;
#   my $newWorkload = shift;
#   my $target = $oldWorkload->{target} || "SUT";
#}


sub PrepareVnic
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $type        = shift || "vnic";
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # get the drivername
   my $target = $oldWorkload->{target} || "SUT";
   my $driverName;
   my $suthelperVnicCount;
   if (defined $oldWorkload->{drivername}) {
      $driverName = $oldWorkload->{drivername};
   } else {
      if ($target =~ m/SUT/i) {
         $driverName =$self->{testcaseHash}{TestbedSpec}{'vm'}{'[1]'}{"vnic"}{'[1]'}{'driver'};
      } else {
         my @nums = @{$TestbedSpecLookUpTable->{vmarray}};
         my $index = first { $nums[$_] eq $target } 0..$#nums;
         my $inventoryIndex = $index + "1";
         #$target =~ s/\D//g;
         #my $inventoryIndex = $target + "1";
         $driverName =$self->{testcaseHash}{TestbedSpec}{'vm'}{"[$inventoryIndex]"}{"vnic"}{'[1]'}{'driver'};
      }
   }

   my $vnicCount;
   my $countEntry;
   if ($target =~ m/SUT/i) {
      $countEntry = "sutVnicCount";
   } else {
      $countEntry = $target . "VnicCount";

   }
   $vnicCount = $TestbedSpecLookUpTable->{$countEntry};

   if ($newWorkload->{operation} =~ /hotremovevnic/i) {
      return $self->PrepareDeleteVnic($oldWorkload, $newWorkload, $type);
   }

   # Compose the vnic and remeber vnic count
   my $commaSeparated = $oldWorkload->{testadapter} || "1";
   my $index;
   my $iterations = $oldWorkload->{iterations} || "1";
   $TestbedSpecLookUpTable->{$countEntry} = $TestbedSpecLookUpTable->{$countEntry} + $iterations;
   my $result = $oldWorkload->{expectedresult} || "PASS";
   if ($result =~ /FAIL/i) {
      $TestbedSpecLookUpTable->{$countEntry} = $TestbedSpecLookUpTable->{$countEntry} - $iterations;
   }
   $iterations = $iterations + 1;
   my $lowerCount = $vnicCount + 1;
   $index = $self->ConvertToRange($TestbedSpecLookUpTable->{$countEntry},$lowerCount);

   if ($type =~ /pci/i) {
      $driverName = "sriov";
   }

   #$index = "[$index]";
   $newWorkload->{$type} = {
      "$index" => {
         'driver' => $driverName,
         'portgroup' => $newWorkload->{testpg} || "host.[1].portgroup.[1]",
         #'maxtimeout' => $oldWorkload->{maxtimeout},
      },
   };


   if (defined $oldWorkload->{passthroughadapter}) { #addpcipassthroughvm
      $newWorkload->{$type}{$index}{vmnic} = $newWorkload->{passthroughadapter};
   }

   # Delete unwanted keys
   delete $newWorkload->{testpg};
   delete $newWorkload->{testadapter};
   delete $newWorkload->{iterations};
   delete $newWorkload->{operation};
   return $newWorkload;
}


sub PrepareDeleteVnic
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $type        = shift || "deletevnic";
   if ($type =~ /pci/i) {
      $type = "deletepcipassthru";
   } else {
      $type = "deletevnic";
   }
   $newWorkload->{$type} = $newWorkload->{testadapter};
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();

   # Remeber vnic count
   my @arrayOfSUTAdapters = split ('\,', $newWorkload->{$type});
   my $count = @arrayOfSUTAdapters;

   $TestbedSpecLookUpTable->{sutVnicCount} = $TestbedSpecLookUpTable->{sutVnicCount} - $count;

   delete $newWorkload->{testpg};
   delete $newWorkload->{testadapter};
   delete $newWorkload->{iterations};
   delete $newWorkload->{operation};

   return $newWorkload;
}


sub PrepareChangePortGroup
{
   my $self        = shift;
   my $oldWorkload = shift;
   my $newWorkload = shift;
   my $returnThisWorkload;

   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   $returnThisWorkload->{Type} = "NetAdapter";
   $newWorkload = $self->PrepareTestAdapter($oldWorkload, $newWorkload);
   $returnThisWorkload->{testadapter} = $newWorkload->{testadapter};
   $returnThisWorkload->{reconfigure} = "true";
   if (defined $TestbedSpecLookUpTable->{$oldWorkload->{portgroupname}}) {
    $returnThisWorkload->{portgroup} = $TestbedSpecLookUpTable->{$oldWorkload->{portgroupname}};
   } elsif (($oldWorkload->{portgroupname} =~ /^\d+$/) &&
           (exists $self->{testcaseHash}{TestbedSpec}{vc}) &&
           (exists $self->{testcaseHash}{TestbedSpec}{vc}{'[1]'}{dvportgroup})) {
      my $testpg = $oldWorkload->{portgroupname};
      my $target = $oldWorkload->{target} || "SUT";
      my $switchtype = $oldWorkload->{'switchtype'} || 'vdswitch';
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      $returnThisWorkload->{portgroup} = join ",", @$refToArray;
   } elsif ($oldWorkload->{portgroupname} =~ /^\d+$/) {
      my $testpg = $oldWorkload->{portgroupname};
      my $target = $oldWorkload->{target} || "SUT";
      my $switchtype = $oldWorkload->{'switchtype'} || 'vsswitch';
      my $refToArray =$self->GetPGTupleBasedonNumber($testpg, $switchtype, $target);
      $returnThisWorkload->{portgroup} = join ",", @$refToArray;
   }
   #$oldWorkload->{Type} = "NetAdapter";
   return $returnThisWorkload;
}

sub RemoveOldMgmtKeys
{
   my $self = shift;
   my $WorkloadLookUpTable = shift;
   my $refWorkload = shift;
   #print "refWork" . Dumper($refWorkload);
   #Removing the Old Mgmt Keys
   my @mgmtKeys;
   if (defined $refWorkload->{type}) {
      if (defined $WorkloadLookUpTable->{$refWorkload->{type}}->{mgmtkeys}) {
         @mgmtKeys = split(',',$WorkloadLookUpTable->{$refWorkload->{type}}->{mgmtkeys});
      }
   } elsif ($refWorkload->{Type}) {
      if (defined $WorkloadLookUpTable->{$refWorkload->{Type}}->{mgmtkeys}) {
         @mgmtKeys = split(',',$WorkloadLookUpTable->{$refWorkload->{Type}}->{mgmtkeys});
      }
   }
   foreach my $key (@mgmtKeys) {
     delete $refWorkload->{$key};
   }
   return $refWorkload;
}


sub MergeRemainingKeys
{
   my $self = shift;
   my $refWorkload = shift;
   my $newWorkload = shift;
   #Appending the non mgmt keys to new Workload hash
   $newWorkload = {%$newWorkload, %$refWorkload};
   return $newWorkload;
}


sub ConvertToRange
{
   my $self = shift;
   my $range = shift;
   my $lowerRange = shift || "1";
   if ( $range > $lowerRange ) {
      $range = "[$lowerRange-$range]";
   } else {
      $range = "[$range]";
   }
   return $range;
}

sub ConvertCommaSeparatedToRange
{
   my $self = shift;
   my $commaSeparated = shift;
   my @array = split('\,', $commaSeparated);
   if ($array[0] == "1") {
      return "[$commaSeparated]";
   } else {
      return "[$array[0]-$array[-1]]";
   }
}


sub ConvertRangeToCommaSeparatedValues
{
   my $self = shift;
   my $range = shift;
   my @array = split ('-', $range);
   my $noOfElements = @array;
   if ($noOfElements == 1) {
      return $range;
   }
   my @returnArray;
   for (my $count = $array[0]; $count <= $array[1]; $count++) {
      push @returnArray, $count;
   }
   my $commaSeparate = join (",", @returnArray);
   return $commaSeparate;
}

sub AddMachinesToHostsBasedOnRules
{
   my $self      = shift;
   my $TdsFolder = shift;
   my $parameter = $self->{testcaseHash}{Parameters};
   #$vdLogger->Debug("Dump of paramters" . Dumper($parameter));
   my $newWorkloadList;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $ruleList = $self->{testcaseHash}{Parameters}{Rules};
   #print "===1==" . Dumper($self);
   # For VirtualNetDevices
   if ($self->{testcaseHash}{Category} eq "Virtual Net Devices") {
      $TdsFolder = "VirtualNetDevices";
   }

   my @nums = @{$TestbedSpecLookUpTable->{NoRULES2}};
   my $testname = $self->{testcaseHash}{TestName};
   my $index = first { $nums[$_] =~ m/$testname/i } 0..$#nums;
   #print "===1===$testname";
   if (defined $index) {
      $TdsFolder = "VirtualNetDevices";
   }


   $vdLogger->Debug("Rules1" . Dumper($ruleList));
   my $rulesArrayRef;
   if (defined $ruleList) {
      # Just for an outstanding corner case:
      $ruleList = $ruleList . "," . $ruleList;
      $rulesArrayRef = $self->GetRulesArray($ruleList);
   } elsif ((not defined $ruleList) &&
            !(exists $TestbedSpecLookUpTable->{NoRULES}{$TdsFolder}) &&
            (exists $parameter->{SUT}) &&
            (exists $parameter->{helper1}) &&
            !(exists $parameter->{helper2})) {
      $vdLogger->Info("Rules not defined, but tests not part of VirtualNetDevices" .
                       " so there will be two hosts");
      $ruleList = "SUT.host != helper1.host";
      $rulesArrayRef = $self->GetRulesArray($ruleList);
   } else {
      $vdLogger->Debug("Rules not defined, push all machines under host 1");
      return $self->AddAllMachinesToHost1();
   }

   my @ListOfMachines;
   my $host1push = undef;
   push (@{$TestbedSpecLookUpTable->{host1}}, "SUT");
   foreach my $key ($parameter) {
      if (($key =~ m/vc/i) || ($key =~ m/Rules/i)) {
         next;
      }
      foreach my $rule (@$rulesArrayRef) {
         my $refArray = $TestbedSpecLookUpTable->{host1};
         if ($rule->{condition} =~ m/eq/i) { #Handling eq case
            foreach my $entry (@$refArray) {
               if ((defined $rule->{leftMachine}) && (defined $rule->{rightMachine}) && (defined $entry)) {
                  $vdLogger->Debug("Host1 == E =$entry, L=$rule->{leftMachine}, R=$rule->{rightMachine} \n");
                  if (($rule->{leftMachine} =~ m/$entry/i) || ($rule->{rightMachine} =~ m/$entry/i)) {
                     if ($rule->{leftMachine} !~ m/$entry/i) {
                        $host1push = $rule->{leftMachine};
                     } elsif ($rule->{rightMachine} !~ m/$entry/i) {
                        $host1push = $rule->{rightMachine};
                     }
                  } elsif (($rule->{leftMachine} !~ m/$host1push/i) && ($rule->{rightMachine} !~ m/$host1push/i)) {
                     $vdLogger->Debug("Host2 == E =$entry, L=$rule->{leftMachine}, R=$rule->{rightMachine} \n");
                     push (@{$TestbedSpecLookUpTable->{host2}}, $rule->{leftMachine});
                     push (@{$TestbedSpecLookUpTable->{host2}}, $rule->{rightMachine});
                  }
               }
            }
            if (defined $host1push) {
               push (@{$TestbedSpecLookUpTable->{host1}}, $host1push);
            }
         } else { #Handling ne case
            if (($rule->{leftMachine} =~ m/SUT/i) || ($rule->{rightMachine} =~ m/SUT/i)) {
               if ($rule->{leftMachine} !~ m/SUT/i) {
                  push (@{$TestbedSpecLookUpTable->{host2}}, "$rule->{leftMachine}");
               } else {
                  push (@{$TestbedSpecLookUpTable->{host2}}, "$rule->{rightMachine}");
               }
            } else {
               my %refHashHost1 = map { $_ => 1} @{$TestbedSpecLookUpTable->{host1}};
               if (exists($refHashHost1{$rule->{leftMachine}})) {
                  push (@{$TestbedSpecLookUpTable->{host2}}, "$rule->{rightMachine}");
               }  elsif (exists($refHashHost1{$rule->{rightMachine}})) {
                  push (@{$TestbedSpecLookUpTable->{host2}}, "$rule->{leftMachine}");
               }
            }
         }
      }
   }
   # Removing dupliacte elements from host1
   my %refHashHost1 = map { $_ => 1} @{$TestbedSpecLookUpTable->{host1}};
   @{$TestbedSpecLookUpTable->{host1}} = keys %refHashHost1;

   # Removing dupliacte elements from host2
   if (defined $TestbedSpecLookUpTable->{host2}) {
      my %refHashHost2 = map { $_ => 1} @{$TestbedSpecLookUpTable->{host2}};
      @{$TestbedSpecLookUpTable->{host2}} = keys %refHashHost2;
   }
   #Remove common entries
   my @dupentries = ();
   #print "\n===1===" . Dumper($TestbedSpecLookUpTable);
   if (defined $TestbedSpecLookUpTable->{host2}) {
      my %refHashHost2 = map { $_ => 1} @{$TestbedSpecLookUpTable->{host2}};
      my %host1Machines = map { $_ => 1 } @{$TestbedSpecLookUpTable->{'host1'}};
      foreach my $key (keys %refHashHost2) {
         if (exists($host1Machines{$key})) {
            $TestbedSpecLookUpTable->{host2} = ();
         } else {
            push @dupentries, $key;
         }
      }
   }
   if (not defined $TestbedSpecLookUpTable->{host2}) {
      #print "\n===1===" . Dumper(@dupentries);
      $TestbedSpecLookUpTable->{'host2'} = \@dupentries;
   }
   if ($#{TestbedSpecLookUpTable->{'host2'}} < 0) {
      $vdLogger->Debug("Host2 array is empty setting it to undef");
      $TestbedSpecLookUpTable->{'host2'} = undef;
   }
}


sub AddAllMachinesToHost1
{
   my $self = shift;
   my $newWorkloadList;
   my $TestbedSpecLookUpTable = $self->GetTestbedSpecLookUpTable();
   my $ruleList = $self->{testcaseHash}{Parameters}{Rules};
   my $rulesArrayRef;

   my @ListOfMachines;
   my $host1push = undef;
   foreach my $key (keys %{$self->{testcaseHash}{Parameters}}) {
      if (($key =~ m/vc/i) || ($key =~ m/Rules/i)) {
         next;
      }
      push (@{$TestbedSpecLookUpTable->{host1}}, $key);
   }
}


sub GetRulesArray {
   my $self = shift;
   my $ruleList = shift;
   $vdLogger->Debug("Rules2" . Dumper($ruleList));
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
# GetNewTDSName --
#     Method to create v2 TDS based v1 TDS;
#
# Input:
#     None
#
# Results:
#     SUCCESS, if zookeeper session is initialized successfully;
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub GetNewTDSName
{
   my $self = shift;
   my $tdsFile = $self->{'tdsIDs'};
   my ($destTdsFile, $tdsName);
   my $destDir = $self->{'logDir'} . "/";

   $tdsFile = @$tdsFile[0];
   my @pathArr = split(/\./, $tdsFile);
   pop @pathArr;
   $tdsName = $pathArr[-1];
   $tdsFile = join "/", @pathArr;
   $tdsFile = "../TDS/" . $tdsFile . "Tds.pm";
   $tdsFile =~ /.*\/(.*Tds.pm)/;
   $destTdsFile = $destDir . $1 . ".V2";

   return ($tdsName, $destTdsFile);
}


sub createHeaderBody()
{
my $self = shift;
my $tdsName = shift;
my $header =  <<"HEADER";
use FindBin;
use lib "\$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use Tie::IxHash;

\@ISA = qw(TDS::Main::VDNetMainTds);
{
tie(\%$tdsName, 'Tie::IxHash');
\%$tdsName = (
HEADER

return $header;
}
sub createNewBody()
{
my $self = shift;
my $tdsName = shift;
my $newBody =  <<"NEW";
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for $tdsName.
#
# Input:
#       None.
#
# Results:
#       An instance/object of $tdsName class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my (\$proto) = \@_;
   # Below way of getting class name is to allow new class as well as
   # \$class->new.  In new class, proto itself is class, and \$class->new,
   # ref(\$class) return the class
   my \$class = ref(\$proto) || \$proto;
   my \$self = \$class->SUPER::new(\\\%$tdsName);
   return (bless(\$self, \$class));
}
NEW

return $newBody;
}
1;
