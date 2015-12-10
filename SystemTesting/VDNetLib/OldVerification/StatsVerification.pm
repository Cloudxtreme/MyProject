#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::OldVerification::StatsVerification;

#
# This module gives object of Stats verification. It deals with gathering
# initial and final stats before a test is executed and then taking a diff
# between the two stats.
#

# ########################  Design  ################################
# Machine A  (client) -------------------> Machine B (server)
# -------------------------- ESX ----------------------------
# These are two VM on ESX host. when machine A acts as client and
# sends packets to machine B
# We go to machine B and gather ethernet stats from it.
# We also find the port it is connected to on ESX and gather the
# stats from this port.
# ##################################################################


# ########################  Usage  #################################
# Just provide verification => stats in Traffic Workload. E.g.
# WORKLOADS => {
#     "NetperfTraffic" => {
#            Type           => "Traffic",
#            ToolName       => "netperf",
#            TestDuration   => "60",
#            Verification   => 'stats',
#            },
# }
# ##################################################################

# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::OldVerification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::Utilities;

use PLSTAF;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Host::HostOperations;

###############################################################################
#
# new -
#       This method reads the verification hash provided. Fetch required
#       details from verification hash like controlip testip, os,
#       interface on which to run the capture. stats are always
#       calculated on 1) destination VM(which is server) using netstat
#       and 2) ESX Host using VSISH.
#
# Input:
#       verification hash (required) - a specificaton in form of hash which
#       contains traffic details as well as testbed details.
#
# Results:
#       Obj of StatsVerification module - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $veriWorkload = $options{workload};
   my $machine;

   if (not defined $veriWorkload->{sniffer}) {
      if (not defined $veriWorkload->{server}) {
         $vdLogger->Error("Testbed information missing in Verification ".
                       "hash provided");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      } else {
         # Traffic always starts from client and goes to server
         # Thus we verify stats on the server.
         # We also verify stats on ESX of server
         # For inbound traffic SUT = server and Helper = client
         # For outbond traffic SUT = client and Helper = server
         $machine = "server";
      }
   } else {
      $machine = "sniffer";
   }

   my $self = {
      machine => $veriWorkload->{$machine},
   };

   bless ($self, $class);
   return $self;
}


###############################################################################
#
# ProcessTestbed -
#       To process information from the testbed, check for required data
#       find mac address of test interface if required.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessTestbed
{

   my $self = shift;
   $self->{os} = $self->{machine}->{os};
   $self->{testip} = $self->{machine}->{testip};
   $self->{controlip} = $self->{machine}->{controlip};

   if(not defined $self->{machine}->{esxip}) {
      $self->{ignoreVSISH} = 1;
      $vdLogger->Warn("VSISH stats wont be calculated as ESXIP ".
                       " is missing");
   } else {
      $self->{ignoreVSISH} = 0;
      $self->{esxip} = $self->{machine}->{esxip};
   }

   if ($self->{ignoreVSISH} == 0) {
      if (not defined $self->{machine}->{macaddress}) {
         my $result = $self->{staf}->GetMACFromIP($self->{controlip},
                                                  $self->{testip});
         if (not defined $result) {
            $self->{ignoreVSISH} = 0;
            $vdLogger->Warn("VSISH stats wont be calculated as MAC address".
                            " of test adapter is missing");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $self->{mac} = $result;
      } else {
         $self->{mac} = $self->{machine}->{macaddress};
      }
   }
   # If the OS is linux then we need interface name to gather statistics
   # of that interface.
   if($self->{os} =~ /linux/i){
      if(not defined $self->{machine}->{interface}){
         $vdLogger->Error("Interface on which to get stats".
                          " is missing". Dumper($self->{machine}));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      } else {
         $self->{interface} = $self->{machine}->{interface};
      }
   }

   if(not defined $self->{vsishPort}) {
      my $hostObj = VDNetLib::Host::HostOperations->new($self->{esxip});
      # Now based on the test adapter's (on which traffic server is running) mac
      # address we find out which vsish port it belongs to on ESX
      $vdLogger->Info("Finding VSI Port corresponding to $self->{mac} ".
                      "on $self->{esxip}...");
      my $vsishPort = $hostObj->GetvNicVSIPort($self->{mac});
      if($vsishPort eq FAILURE){
         $vdLogger->Error("Fetching VSISH Port failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Saving it so that we don't have to calculate next time.
      $self->{vsishPort} = $vsishPort;
   }

   if ($self->{os} =~ /linux/i) {
      my $guest = $self->{controlip};
      my $host = $self->{esxip};
      my $command = "ethtool -i " . $self->{interface};
      my $result = $self->{staf}->STAFSyncProcess($guest, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
         $vdLogger->Error("Couldn't get driver info from ethtool, it failed" .
                       " with error: $result->{stderr}");
      }
      my $ethtoolInfo = $result->{stdout};
      # The following code is only applicable for vmxnet3
      if ($ethtoolInfo =~ /vmxnet3/i) {
         my @driverInfo = split('\.', $ethtoolInfo);

         # Multi tx/rx queues and RSS is only supported for driver versions
         # 1.0.16.0 or later
         if ($driverInfo[2] >= 16) {
            $command = "vsish -e ls " . $self->{vsishPort} . "/vmxnet3/rxqueues/ | wc -l";
            $result = $self->{staf}->STAFSyncProcess($host, $command);
            if ($result->{rc}) {
               VDSetLastError("ESTAF");
               return FAILURE;
            } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
               $vdLogger->Error("Couldn't get number of rxqueues from VSISH," .
                       " failed with error: $result->{stderr}");
            }
            $self->{numrqs} = $result->{stdout};
       $command = "vsish -e ls " . $self->{vsishPort} . "/vmxnet3/txqueues/ | wc -l";
            $result = $self->{staf}->STAFSyncProcess($host, $command);
            if ($result->{rc}) {
               VDSetLastError("ESTAF");
               return FAILURE;
            } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
               $vdLogger->Error("Couldn't get number of txqueues from VSISH," .
                       " failed with error: $result->{stderr}");
            }
            $self->{numtqs} = $result->{stdout};
         }
      }
      $command = "cat /proc/cpuinfo | grep processor | wc -l";
      $result = $self->{staf}->STAFSyncProcess($guest, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
         $vdLogger->Error("Couldn't get CPU info from proc FS, it failed" .
                       " with error: $result->{stderr}");
      }
      $self->{numcpus} = $result->{stdout};
   }
   return SUCCESS;
}

###############################################################################
#
# BuildCommand -
#       This method builds the command(binary) for gathering statistics.
#       For linux and windows there is in-house command netstat and for esx
#       we use the user world binary netstat-uw.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub BuildCommand
{
   my $self = shift;
   my %args = @_;
   my $os = $self->{os};
   my ($command, $wincmd, $result);

   if (not defined $os || not defined $self->{controlip}) {
      $vdLogger->Error("Cannot proceed without os:$os or ".
                       "serverIP:$self->{controlip} parameters in ".
                       "BuildToolCommand");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($os =~ m/(linux|win)/i) {
      $self->{bin} = "netstat";
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      # netstat-uw is not supported on MN thus commenting this
      # code for now
      # http://bugzilla.eng.vmware.com/show_bug.cgi?id=614280
      return SUCCESS;
      #my ($globalConfigObj, $binpath, $binFile, $path2bin);
      #$globalConfigObj = new VDNetLib::Common::GlobalConfig;
      #$binpath = $globalConfigObj->BinariesPath(
      #                             VDNetLib::Common::GlobalConfig::OS_ESX);
      #$path2bin = "$binpath" . "x86_32/esx/";
      #$binFile = "netstat-uw";
      #$self->{bin}  = $path2bin . $binFile;
   } else {
      $vdLogger->Error("Unknown os:$os for building ToolCommand in ".
                       "StatVerification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "$self->{bin} -h ";
   $result = $self->{staf}->STAFSyncProcess($self->{controlip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Trace("Built command:$self->{bin} for os:$os");
   return SUCCESS;
}


###############################################################################
#
# StartVerification -
#       Gathers ethernet statistics, protocol statistics and calls a method to
#       get VSISH Statistics.
#
# Input:
#       state/tag - which one wants to apply to results so that they can take
#                   a diff between various results later on.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub StartVerification
{
   my $self = shift;
   my $state = shift ;
   if (not defined $state){
      $state = "Initial";
   }

   my ($command, $result, $tag);
   my $host = $self->{controlip};
   my $os = $self->{os};
   my $interface = $self->{interface};
   my $count;

   # First collecting stats from VM then from ESX host using VSISH.
   # Getting ethernet stats
   $tag = "ether" . $state;
   if ($os =~ m/win/i) {
      #TODO: This is not much useful as it gives overall ethernet statistics
      # and not stats specific to an adapter.
      # If anyone knows any other command to get specific stats then please help.
      $command = $self->{bin} . " -e"
   } elsif($os =~ m/linux/i) {
      $command = $self->{bin} . " --interfaces"
   }

   # This check is because even if we use netstat-uw on ESX it does not
   # support ethernet stats. It only supports protocol statistics.
   if($os !~ m/(esx)/i && $os !~ m/(vmkernel)/i) {
      $result = $self->{staf}->STAFSyncProcess($host, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
         $vdLogger->Error("netstat command in StatsVerification failed with: ".
                          "$result->{stderr}");
      }
      $self->{statsBucket}->{$tag} = $result->{stdout};
   }

   # Now getting protocol stats. netstat-uw is being deprecated
   # on esx > 4.5 thus removed it.
   $tag = "proto" . $state;
   if ($os =~ m/(win)/i) {
      $command = $self->{bin} . " -s"
   } elsif($os =~ m/linux/i) {
      $command = $self->{bin} . " --statistics"
   }
   # Don't do anything on ESX.
   if($os !~ m/(esx)/i && $os !~ m/(vmkernel)/i) {
      $result = $self->{staf}->STAFSyncProcess($host, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stderr} =~ /(invalid option|not found)/i) {
         $vdLogger->Error("netstat command in StatsVerification failed with: ".
                          "$result->{stderr}");
      }
      $self->{statsBucket}->{$tag} = $result->{stdout};
   }


   # Collecting stats from ESX now.
   if($self->{ignoreVSISH} == 0){
      $tag = "vsish" . $state;
      $result = $self->GetVSISHStats();
      if ($result eq FAILURE) {
         $vdLogger->Error("GetVSISHStats returned:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $self->{statsBucket}->{$tag} = $result;
   }
   # Get the multi tx/rx queue stats (only applicable for Linux vmxnet3 driver
   # with driver version 1.0.16.0 or later)
   if ((defined $self->{numrqs}) && (defined $self->{numrqs})) {
      for ($count = $self->{numrqs} - 1; $count >= 0; $count--) {
         $tag = "vsishRq" . $count . $state;
         $command = "vsish -e get " . $self->{vsishPort} . "/vmxnet3/rxqueues/"
                          . $count . "/stats";
         $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
         if ($result->{rc}) {
            VDSetLastError("ESTAF");
            return FAILURE;
         } elsif(defined $result->{stderr} &&
            $result->{stderr} =~ /(bad command|not found|invalid)/i) {
            $vdLogger->Error("VSISH command in StatsVerification failed with: ".
                       "$result->{stderr}");
         }
         $self->{statsBucket}->{$tag} = $result->{stdout};
      }
      for ($count = $self->{numtqs} - 1; $count >= 0; $count--) {
         $tag = "vsishTq" . $count . $state;
         $command = "vsish -e get " . $self->{vsishPort} . "/vmxnet3/txqueues/"
                          . $count . "/stats";
         $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
         if ($result->{rc}) {
            VDSetLastError("ESTAF");
            return FAILURE;
         } elsif(defined $result->{stderr} &&
            $result->{stderr} =~ /(bad command|not found|invalid)/i) {
            $vdLogger->Error("VSISH command in StatsVerification failed with: ".
                       "$result->{stderr}");
         }
         $self->{statsBucket}->{$tag} = $result->{stdout};
      }
      # Get the total rx stats
      $tag = "vsishRxTotal" . $state;
      $command = "vsish -e get " . $self->{vsishPort} . "/vmxnet3/rxSummary";
      $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif(defined $result->{stderr} &&
         $result->{stderr} =~ /(bad command|not found|invalid)/i) {
         $vdLogger->Error("VSISH command in StatsVerification failed with: ".
                    "$result->{stderr}");
      }
      $self->{statsBucket}->{$tag} = $result->{stdout};
      # Get the total rx stats
      $tag = "vsishTxTotal" . $state;
      $command = "vsish -e get " . $self->{vsishPort} . "/vmxnet3/txSummary";
      $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif(defined $result->{stderr} &&
         $result->{stderr} =~ /(bad command|not found|invalid)/i) {
         $vdLogger->Error("VSISH command in StatsVerification failed with: ".
                    "$result->{stderr}");
      }
      $self->{statsBucket}->{$tag} = $result->{stdout};

      #   Get the stats from /proc/interrupts
      if ($os =~ /linux/i) {
         $tag = "procIntrs" . $state;
         $command = "cat /proc/interrupts | grep $interface";
         $result = $self->{staf}->STAFSyncProcess($host, $command);
         if ($result->{rc}) {
            VDSetLastError("ESTAF");
            return FAILURE;
         } elsif(defined $result->{stderr} &&
            $result->{stderr} =~ /(bad command|not found|invalid)/i) {
            $vdLogger->Error("/proc/interrupts command in StatsVerification" .
            " failed with: $result->{stderr}");
         }
         $self->{statsBucket}->{$tag} = $result->{stdout};
      }
   }
   return SUCCESS;
}


###############################################################################
#
# GetVSISHStats -
#       Gathers VSISH Statistics using command such as
#       vsish -e get /net/portsets/vSwitch1/ports/33554437/clientStats
#       Ref: https://wiki.eng.vmware.com/Netstats
#
# Input:
#       None.
#
# Results:
#       VSISH stats - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVSISHStats
{
   my $self = shift;
   my ($command, $result);

   # command should be like
   #~ # vsish -e get /net/portsets/vSwitch1/ports/33554437/clientStats
   $command = "vsish -e get " . $self->{vsishPort} . "/clientStats";
   $result = $self->{staf}->STAFSyncProcess($self->{esxip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif(defined $result->{stderr} &&
      $result->{stderr} =~ /(bad command|not found|invalid)/i) {
      $vdLogger->Error("VSISH command in StatsVerification failed with: ".
                       "$result->{stderr}");
   }
   return $result->{stdout};
}


###############################################################################
#
# ProcessVerificationKeys -
#       Complying with parent interface.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessVerificationKeys
{
   #TODO: This can be extended in future to display more information relavant
   # to test. E.g. current we display only errores, drops, discard and TX OK
   # RX OK packets. In future if testcase is TSO we can also display TSO based
   # packets.
   return SUCCESS;
}

###############################################################################
#
# AppendTestOptions -
#       Complying with parent interface.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################


sub AppendTestOptions
{

   return SUCCESS;
}

###############################################################################
#
# ExtractVSISHStats -
#       Extracts VSISH Statistics by taking difference of initial and final
#       stats. Algorithm is detailed in the body of method
#
# Input:
#       None.
#
# Results:
#       VSISH stats - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractVSISHStats
{
   my $self = shift;
   my $initialStats = shift;
   my $finalStats = shift;
   my @initLines = split("\n",$initialStats);
   my @finalLines = split("\n",$finalStats);
   my (@initWords, $initHash, $finalHash, $resultHash, $line, @temp, $key);

   # VSISH Stats looks something like this
   # port client stats {
   #   pktsTxOK:174303200
   #   bytesTxOK:244649323587
   #   droppedTx:0
   #   pktsTsoTxOK:234966847
   #   bytesTsoTxOK:2790853693988
   #   droppedTsoTx:0
   #   pktsSwTsoTx:0
   #   droppedSwTsoTx:0
   #   pktsZerocopyTxOK:397324772
   #   pktsRxOK:676251051
   #   bytesRxOK:81315804192
   #   droppedRx:40640
   #   pktsSwTsoRx:0
   #   droppedSwTsoRx:0
   #   actions:0
   #   uplinkRxPkts:0
   #   clonedRxPkts:0
   #   pksBilled:0
   #   droppedRxDueToPageAbsent:0
   #   droppedTxDueToPageAbsent:0
   #}

   # 1) Split according to :
   # 2) Remove any leading or trailing spaces in both key and value
   # 3) Store it in a hash
   # Do this for both initialStats and finalStats.

   foreach $line (@initLines){
      @temp = split(":",$line);
      if(defined $temp[1]){
         $temp[0] =~ s/^\s+//;
         $temp[0] =~ s/\s+$//;
         $temp[1] =~ s/^\s+//;
         $temp[1] =~ s/\s+$//;
         $initHash->{$temp[0]} = $temp[1];
      }
   }

   foreach $line (@finalLines){
      @temp = split(":",$line);
      if(defined $temp[1]){
         $temp[0] =~ s/^\s+//;
         $temp[0] =~ s/\s+$//;
         $temp[1] =~ s/^\s+//;
         $temp[1] =~ s/\s+$//;
         $finalHash->{$temp[0]} = $temp[1];
      }
   }

   # Now take a difference of final stats - initial stats.
   foreach $key (%$finalHash){
      if(defined $initHash->{$key}) {
         $resultHash->{$key} = $finalHash->{$key} - $initHash->{$key};
      }
   }

   return $resultHash;
}

###############################################################################
#
# ExtractProcIntrStatsLinux -
#       Extracts /proc/interrupts Statistics gathered from linux VM.
#
# Input:
#       None.
#
# Results:
#       Displays the /proc/interrupts stats
#
# Side effects:
#       None
#
###############################################################################

sub ExtractProcIntrStatsLinux
{
   my $self = shift;
   my $interface = $self->{interface};
   my $initialStats = $self->{statsBucket}->{procIntrsInitial};
   my $finalStats = $self->{statsBucket}->{procIntrsFinal};
   my (@final, $line, @temp, @temp2, @t, @t2);
   my $i;
   my $j;
   my $numRows;
   my $numColumns;

   my @initLines = split("\n",$initialStats);
   $numRows = $#initLines + 1;
   $numColumns = $self->{numcpus} + 3;
   foreach $line (@initLines) {
      @t = split(/\s+/,$line);
      push (@temp, [@t]);
   }

   my @finalLines = split("\n",$finalStats);
   foreach $line (@finalLines) {
      @t2 = split(/\s+/,$line);
      push (@temp2, [@t2]);
   }

   for ($i = 0; $i < $numRows; $i++) {
      for ($j = 0; $j <= $numColumns; $j++) {
         if ($temp[$i]->[$j] =~ /^[0-9]+$/ && $temp2[$i]->[$j] =~ /^[0-9]+$/) {
            $final[$i][$j] = $temp2[$i]->[$j] - $temp[$i]->[$j];
         } else {
            $final[$i][$j] = $temp[$i]->[$j];
         }
      }
   }

   if ($#final < 0) {
      $vdLogger->Error("Couldn't extract /proc/interrupts stats");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Print the stats difference
   $vdLogger->Info("/proc/interrupts Stats");
   for ($i = 0; $i < $numRows; $i++) {
      for ($j = 0; $j <= $numColumns; $j++) {
         if (defined $final[$i][$j]) {
            $vdLogger->Info("$final[$i][$j]");
         }
      }
   }
   return SUCCESS;
}

###############################################################################
#
# ExtractEtherStatsLinux -
#       Extracts ethernet Statistics gathered from linux VM. Algorithm is
#       detailed in the body of method
#
# Input:
#       None.
#
# Results:
#       VSISH stats - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractEtherStatsLinux
{
   my $self = shift;
   my $interface = $self->{interface};
   my $initialStats = $self->{statsBucket}->{etherInitial};
   my $finalStats = $self->{statsBucket}->{etherFinal};
   my (@initWords, $initHash, $finalHash, $resultHash, $line, @temp, @temp2, $key);

   #Ethernet stats look something like this
   #Kernel Interface table
   #Iface       MTU Met    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
   #eth0       1500   0   518587      0      0      0   517596      0      0      0 BMRU
   #eth1       1500   0 14870492      0      0      0   461281      0      0      0 BMRU
   #eth2       1500   0 83891177      0      0      0      114      0      0      0 BMRU
   #lo        16436   0     3857      0      0      0     3857      0      0      0 LRU

   # 1) Split the lines according to \n
   # 2) filter out the line which has the required interface
   # 3) split the line according to spaces
   # 4) For both keys and values associate them according to positions.
   # 5) Do this for both initialStats and finalStats

   my @initLines = split("\n",$initialStats);
   foreach $line (@initLines){
      if($line =~ m/$interface/i){
         @temp2 = split(" ",$line);
      }
   }
   if($initLines[1] =~ m/(iface|TX|RX)/i){
      @temp = split(" ",$initLines[1]);
      my $i=0;
      foreach $key (@temp ){
         $initHash->{$temp[$i]} = $temp2[$i];
         $i++;
      }
   } else {
      $vdLogger->Error("Ethernet Stats format not as expected:" .
                       Dumper($initialStats));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my @finalLines = split("\n",$finalStats);
   foreach $line (@finalLines){
      if($line =~ m/$interface/i){
         @temp2 = split(" ",$line);
      }
   }
   if($finalLines[1] =~ m/(iface|TX|RX)/i){
      @temp = split(" ",$finalLines[1]);
      my $i=0;
      foreach $key (@temp ){
         $finalHash->{$temp[$i]} = $temp2[$i];
         $i++;
      }
   } else {
      $vdLogger->Error("Ethernet Stats format not as expected:" .
                       Dumper($finalStats));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   foreach $key (%$finalHash){
      if(defined $initHash->{$key} && $initHash->{$key} =~ /^[0-9]+$/) {
         $resultHash->{$key} = $finalHash->{$key} - $initHash->{$key};
      }
   }

   return $resultHash;
}

###############################################################################
#
# ExtractEtherStatsWin -
#       Extracts ethernet Statistics gathered from windows VM. Algorithm is
#       detailed in the body of method
#
# Input:
#       None.
#
# Results:
#       VSISH stats - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractEtherStatsWin
{
   my $self = shift;
   my $interface = $self->{interface};
   my $initialStats = $self->{statsBucket}->{etherInitial};
   my $finalStats = $self->{statsBucket}->{etherFinal};
   my (@initWords, $initHash, $finalHash, $resultHash, $line, @temp, @temp2,
       $key);

   #Ethernet stats look something like this
   #C:\Tools>netstat -e
   #Interface Statistics
   #                           Received            Sent
   #
   #Bytes                     442364986      1586055137
   #Unicast packets            13822316        10819989
   #Non-unicast packets        14064259           18741
   #Discards                          0               0
   #Errors                            0               0
   #Unknown protocols             62654

   my @initLines = split("\n",$initialStats);
   foreach $line (@initLines){
      if($line =~ m/(received|sent|statistic)/i){
         next;
      }
      @temp = split(" ",$line);
      if($line =~ m/(packet|unknown protocols)/i){
         $temp[1] = $temp[2];
      }
      if(defined $temp[1]){
         $temp[0] =~ s/^\s+//;
         $temp[0] =~ s/\s+$//;
         $temp[1] =~ s/^\s+//;
         $temp[1] =~ s/\s+$//;
         # We only store received data.
         $initHash->{$temp[0]} = $temp[1];
      }
   }

   my @finalLines = split("\n",$finalStats);
   foreach $line (@finalLines){
      if($line =~ m/received|sent/i){
         next;
      }
      @temp = split(" ",$line);
      if($line =~ m/(packet|unknown protocols)/i){
         $temp[1] = $temp[2];
      }
      if(defined $temp[1]){
         $temp[0] =~ s/^\s+//;
         $temp[0] =~ s/\s+$//;
         $temp[1] =~ s/^\s+//;
         $temp[1] =~ s/\s+$//;
         # We only store received data.
         $finalHash->{$temp[0]} = $temp[1];
      }
   }

   foreach $key (%$finalHash){
      if(defined $initHash->{$key}) {
         $resultHash->{$key} = $finalHash->{$key} - $initHash->{$key};
      }
   }

   return $resultHash;
}


###############################################################################
#
# StopVerification -
#       This method just takes another snapshot of all the stats so that both
#       stats can be compared.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub StopVerification
{
   my $self = shift;
   # We just call the same method which gather stats from every place
   # and attach this tag final to it.
   # Then we take a diff of initial and final stats.
   if ($self->StartVerification("Final") ne SUCCESS)
   {
      $vdLogger->Error("StartVerification did not return SUCCESS ".
                       "in StatsVerification");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetResult -
#       This method calls the appropriate method which will do the diff between
#       initial and final stats and returns the result.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
#
# Results:
#       integer value of the information to be extract from Stats
#       FAILURE in case something goes wrong.
#
# Side effects:
#
###############################################################################

sub GetResult
{
   my $self = shift;
   my $result;
   my $count;

   # Check if both the initial and final stats are available for
   # ethernet, protocol and vsish
   # Thus get all keys from statBucket and if both are present then
   # call appropriate method to get the difference in initial and final
   # stats.
   if(defined $self->{statsBucket}->{etherInitial} &&
      defined $self->{statsBucket}->{etherFinal}) {
      if($self->{os} =~ /win/i){
         $result = $self->ExtractEtherStatsWin();
         if($result ne FAILURE){
            $self->DisplayStats("Windows Ethernet Statistics", $result);
         } else {
          $vdLogger->Error("ExtractEtherStatsWin returned: $result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      } else {
         $result = $self->ExtractEtherStatsLinux();
         if($result ne FAILURE){
            $self->DisplayStats("Linux Ethernet Statistics", $result);
         } else {
          $vdLogger->Error("ExtractEtherStatsLinux returned: $result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   }

   if(defined $self->{statsBucket}->{protoInitial} &&
      defined $self->{statsBucket}->{protoFinal}) {
      # TODO: For Future, if there is a requirement in any TDS to take
      # a diff of protocol stats then a method to ExtractProtoStats
      # can be written.
   }

   if(defined $self->{statsBucket}->{vsishInitial} &&
      defined $self->{statsBucket}->{vsishFinal} &&
      $self->{ignoreVSISH} == 0) {
      $result = $self->ExtractVSISHStats($self->{statsBucket}->{vsishInitial},
      $self->{statsBucket}->{vsishFinal});
      if($result ne FAILURE){
         $self->DisplayStats("VSISH Statistics", $result);
      } else {
         $vdLogger->Error("ExtractVSISHStats returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   # Multi tx/rx queue stats
   if(defined $self->{numtqs} &&
      defined $self->{numrqs} &&
      $self->{ignoreVSISH} == 0) {
      my $tag1;
      my $tag2;

      # Extract the captured (initial/final) tx/rx stats for each queue
      for ($count = $self->{numrqs} - 1; $count >= 0; $count--) {
         $tag1 = "vsishRq" . $count . "Initial";
         $tag2 = "vsishRq" . $count . "Final";
         $result = $self->ExtractVSISHStats($self->{statsBucket}->{$tag1},
      $self->{statsBucket}->{$tag2});
         if($result ne FAILURE){
            $self->DisplayStats("VSISH Multi Rq Statistics", $result);
         } else {
            $vdLogger->Error("ExtractVSISHStats returned: $result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      for ($count = $self->{numtqs} - 1; $count >= 0; $count--) {
         $tag1 = "vsishTq" . $count . "Initial";
         $tag2 = "vsishTq" . $count . "Final";
         $result = $self->ExtractVSISHStats($self->{statsBucket}->{$tag1},
      $self->{statsBucket}->{$tag2});
         if($result ne FAILURE){
            $self->DisplayStats("VSISH Multi Tq Statistics", $result);
         } else {
            $vdLogger->Error("ExtractVSISHStats returned: $result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      # Now extract the proc file system stats
      $result = $self->ExtractProcIntrStatsLinux();
      if ($result eq FAILURE) {
         $vdLogger->Error("ExtractProcIntrStatsLinux returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
  }
  # Here we extract the total tx/rx queue stats
  if(defined $self->{statsBucket}->{vsishRxTotalInitial} &&
      defined $self->{statsBucket}->{vsishRxTotalFinal} &&
      $self->{ignoreVSISH} == 0) {
      $result = $self->ExtractVSISHStats($self->{statsBucket}->{vsishRxTotalInitial},
      $self->{statsBucket}->{vsishRxTotalFinal});
      if($result ne FAILURE){
         $self->DisplayStats("VSISH RxSummary Statistics", $result);
      } else {
         $vdLogger->Error("ExtractVSISHStats returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   if(defined $self->{statsBucket}->{vsishTxTotalInitial} &&
      defined $self->{statsBucket}->{vsishTxTotalFinal} &&
      $self->{ignoreVSISH} == 0) {
      $result = $self->ExtractVSISHStats($self->{statsBucket}->{vsishTxTotalInitial},
      $self->{statsBucket}->{vsishTxTotalFinal});
      if($result ne FAILURE){
         $self->DisplayStats("VSISH TxSummary Statistics", $result);
      } else {
         $vdLogger->Error("ExtractVSISHStats returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# DisplayStats -
#       This method calls the appropriate method which will do the diff between
#       initial and final stats and returns the result.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
# Results:
#       integer value of the information to be extract from Stats
#       FAILURE in case something goes wrong.
#
# Side effects:
#
###############################################################################

sub DisplayStats
{
   my $self = shift;
   my $string = shift;
   my $display = shift;
   my $key;
   my $count = 0;

   # Whatever is relavant for this test will be displayed on stdout rest will
   # be thrown in log file for future analysis.
   $vdLogger->Info("####### $string #######");
   foreach $key (keys %$display){
      if($key =~ m/(err|discard|drp|drop)/i ||
         ($key =~ m/(ok|byte)/i && $display->{$key} != 0 )) {
         $vdLogger->Info("   $key:$display->{$key}");
         if($key =~ m/(ok|byte)/i){
            $count = 1;
         }
      } else {
        $vdLogger->Trace("   $key:$display->{$key}");
      }
   }
   if (($count == 0) && (not defined $self->{numtqs})) {
      $vdLogger->Error("Not even one pkt or byte were transacted. ".
                       "Please debug");
   }
   return SUCCESS;
}


###############################################################################
#
# DESTROY -
#       This method is destructor for this class.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#
###############################################################################

sub DESTROY
{
   return SUCCESS;
}

1;
