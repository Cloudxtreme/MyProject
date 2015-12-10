#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::OldVerification::PktCapVerification;

#
# This module gives object for packet capture verification. It deals
# with filter string generation. Capturing packets according to traffic.
# Converts the tcpdump capture file to human readable format and reads the
# file for errors, packet drops or other desired patterns. Gives out this
# result to user of this package.
#
#

# To this knowledge the verification of following is not possible through
# packet capture.
# DeviceStatus
# WoL
# Rings
# Queues
# RSS
# Buffers


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

###############################################################################
#
# new -
#       This method reads the verification hash provided. tcpdump always
#       runs on destination host(which is server). More tasks are:
#       1. Generate file name with unique timestamp which will store captured
#          packets in raw form.
#       2. Fetch required details from verification hash like controlip
#          testip, os, interface on which to run the capture.
#
# Input:
#       verification hash (required) - a specificaton in form of hash which
#       contains traffic details as well as testbed details.
#
# Results:
#       Obj of PktCapVerification module - in case everything goes well.
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
   my ($captureFile, $launchStatusFile);
   my $sourceDir;
   my $machine;
   my $promiscuousFlag;
   if (not defined $veriWorkload->{sniffer}) {
      if (not defined $veriWorkload->{server}) {
         $vdLogger->Error("Testbed information missing in Verification ".
                       "hash provided");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      } else {
         # We test if the traffic flow was received properly.
         # Traffic always starts from client and goes to server
         # Thus we capture on server in both scenarios
         # For inbound traffic SUT = server and Helper = client
         # For outbond traffic SUT = client and Helper = server
         $machine = "server";
         # For not putting the adapter in promiscous mode.
         $promiscuousFlag = " -p ";
      }
   } else {
      # Tcpdump/Windump will be launched on a sniffer VM/Host's interface
      # For putting the adapter in promiscuous mode.
      $promiscuousFlag = " ";
      $machine = "sniffer";
   }

   $vdLogger->Trace("Capture will be done on $machine. ".
                    "Filter will be generated from".
                    Dumper($veriWorkload->{server}));

   # We always attach sourceDir to be that of linux/MC because that
   # is the case in most scenarios.
   # When it is win we just use perl regex to replace the linux dir
   # with that of win dir.
   $sourceDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   $captureFile = VDNetLib::Common::Utilities::GetTimeStamp();
   # Attaching the pid of the process to file Name
   $launchStatusFile = "stdout-". $captureFile . "-$$.tmp";
   $launchStatusFile = $sourceDir . $launchStatusFile;

   $captureFile = "PktCap-". $captureFile . "-$$.pcap";
   $captureFile = $sourceDir . $captureFile;

   my $self = {
      fileName => $captureFile,
      launchstdout => $launchStatusFile,
      os => $veriWorkload->{$machine}->{os},
      arch => $veriWorkload->{$machine}->{arch},
      testip => $veriWorkload->{$machine}->{testip},
      controlip => $veriWorkload->{$machine}->{controlip},
      interface => $veriWorkload->{$machine}->{interface},
      #TODO: Come up with some algorithm to know what information
      # is to be extracted from packetCapture file based on
      # NetadapterHash and trafficWorkloadHash. Hardcoding count for now.
      packetInfo => "count",
      # This flag maintains if the stopCapture method was called or not
      # if it is not called due to any error condition whatsoever it will
      # be called from Destructor, as destructor is called indefinately.
      stopCaptureCalled => 0,
      # Filter string consists of 1) Static hard-coded values 2) Dynamic values
      # which are based on type of traffic and adapter settings. Static part:
      # -p for promiscuous mode
      # -e for printing the link-level/ethernet header on each dump line
      # -vvv for verbose output.
      # -s is the number of bytes you want to capture. give 1514 (to get
      #    everything). Larger lenght also increases processing time thus
      #    more packets might get dropped. Setting snaplen to
      #    0 means use the required length to catch whole packets.
      # -C for checking whether the file is currently larger than file_size
      #    and, if so, close the current savefile and open a new one. This is
      #    checked before writing raw packet to a savefile. The captured
      #    packets are stored in 20MB files. The first file will have the name
      #    given by the user. The succeeding files will have the name given
      #    by the user succeeded by 1,2.. and so on. For this reason, no
      #    filename should end with a number.
      # -Z Not sure why we use(Legacy)
      # -n By default tcpdump performs DNS query to lookup hostname
      #    associated with an IP address and uses the hostname in
      #    the output. -n stops conversion of hostname
      # -c Lowercase c is for count. Count number of packets you want to
      #    capture
      #    It is useful in case one doesn't wnat to call stopCapture.
      #
      #    TODO: count is hardcoded - remove it
      filterString => $promiscuousFlag . " -e -vvv -s 0 -C 20 -Z root -n -c 1000",
      vlanFlag => 0,
   };

   if (defined $veriWorkload->{$machine}->{vlan}) {
      if (int($veriWorkload->{$machine}->{vlan}) != 0) {
         $self->{vlan} = $veriWorkload->{$machine}->{vlan};
         $vdLogger->Info("Reading user set vlan value in PktCap". $self->{vlan});
      }
   }

   if ($self->{filterString} =~ / -p /i) {
      $vdLogger->Info("Enabling Promiscuous mode on $self->{interface} ".
                      "in $self->{controlip}");
   }

   if(not defined $self->{interface}){
      $vdLogger->Error("Interface:$self->{interface} on which to start ".
                       "capture is missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   bless ($self, $class);
   return $self;
}


###############################################################################
#
# BuildCommand -
#       This method builds the command(binary) for this verification tool.
#       1. For linux tcpdump
#       2. For windows
#          a. Based on the OS, get the binariespath from
#             VDNetLib::Common::GlobalConfig
#          b. Set command to the windump path after copying it to another dir.
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
   my $arch = $self->{arch};
   my $os = $self->{os};
   my ($command, $wincmd, $result);

   if (not defined $os || not defined $arch ||
       not defined $self->{controlip}) {
      $vdLogger->Error("Cannot proceed without os:$os or arch:$arch or ".
                       "serverIP:$self->{controlip} parameters in ".
                       "BuildToolCommand");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($os =~ m/linux/i) {
      #TODO: Remove /sbin/ from below after addinf tcpdump to the system path
      $self->{bin} = "tcpdump";
   } elsif ($os =~ m/win/i) {
      my ($globalConfigObj, $binpath, $binFile, $path2Bin);
      $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(
                               VDNetLib::Common::GlobalConfig::OS_WINDOWS
                                               );
      $path2Bin = "$binpath" . "$arch\\\\windows\\\\";
      $binFile = "WinDump.exe";
      $self->{bin}  = $path2Bin . $binFile;
      my $winLocalDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
      #TODO: Consolidate the tool copying algorithm in all tool based modules.
      #Do this when you add copying binaries in SetUpAutomation code.
      $wincmd = "\"my \$localToolsDir=\'$winLocalDir\';".
                                  "my \$ns = \'$winLocalDir$binFile\';".
                                  "my \$src = \'$self->{bin}\';".
                                   "((-d \$localToolsDir)||".
                                   "(mkdir \$localToolsDir))&&".
                                   "(`copy \$src \$localToolsDir`);".
                                   "((-d \'c:\\temp\') || ".
                                   "(mkdir \'c:\\temp\'))\"";

      $command = "perl -e ". $wincmd;
      $result = $self->{staf}->STAFSyncProcess($self->{controlip},
                                               $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $self->{bin}  = $winLocalDir . $binFile;
      $self->{bin} =~ s/\\\\/\\/g;
      $vdLogger->Debug("binary is changed to $self->{bin} for os:$os");

      # File check needs to be done only in case of windows as tcpdump
      # always exists by default on windows.
      $result = $self->{staf}->IsFile($self->{controlip}, $self->{bin});
      if (not defined $result) {
         $vdLogger->Debug("File:$self->{bin} missing on $self->{controlip}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } elsif($result ne 1) {
         $vdLogger->Debug("File:$self->{bin} missing on $self->{controlip}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      my ($globalConfigObj, $binpath, $binFile, $path2bin);
      $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(
                                   VDNetLib::Common::GlobalConfig::OS_ESX);
      $path2bin = "$binpath" . "$arch/esx/";
      $binFile = "tcpdump-uw";
      $self->{bin}  = $path2bin . $binFile;
   } elsif ($os =~ m/mac|darwin/i) {
      my ($globalConfigObj, $binpath, $binFile, $path2bin);
      $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      $binpath = $globalConfigObj->BinariesPath(
                                   VDNetLib::Common::GlobalConfig::OS_MAC);
      $path2bin = "$binpath" . "$arch/mac/";
      $binFile = "tcpdump";
      $self->{bin}  = $path2bin . $binFile;
   } else {
      $vdLogger->Error("Unknown os:$os for building ToolCommand");
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
#       Checks if the filter string is appropriate. Runs staf command to start
#       capture process on respective OS. Queries the process handle to see
#       if the process was started successfully. Saves the process handle.
#
# Input:
#       None.
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
   my ($command, $result);
   my $host = $self->{controlip};
   my $fileName = $self->{fileName};
   my $filterString = $self->{filterString};
   my $os = $self->{os};
   my $binary = $self->{bin};
   my $interface;
   my $opts = undef;

   # remove the last word "and" from the filter string.
   $filterString =~ s/and$//ig;

   # tpcumdp does not like vlan filter at the end PR#676902
   if($filterString =~ m/vlan/i) {
      $filterString =~ s/and vlan (\d+)//i;
      my $removedVLAN = $1;
      my @splitFilter= split('-c 1000',$filterString);
      $filterString  = $splitFilter[0] . " -c 1000 " ."vlan "
                       . $removedVLAN ." and " . $splitFilter[1];
   }

   if ($os =~ m/win/i) {
      # If you launch a program on win using staf, staf creates a cmd terminal
      # and return the PID of that cmd terminal. Thus when you want to kill
      # the program it will kill the cmd process which launched the program
      # and not the program. We pass noshell while launching this command
      # which does not launch process using cmd terminal.
      $opts->{NoShell} = 1;
      # Get the windows directory from GlobalConfig.
      my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
      # Remove the linux dir path and prepend windows dir path
      $fileName =~ s/.+\//$winDir/;
      if ($self->{interface} !~ /^(\d+)$/) {
         # it is a not a digit means it is a GUID, get the windumpindex
         my $windex = $self->GetWinDumpIndex($self->{controlip},
                                             $self->{interface});
         if ($windex =~ /^\d+$/) {
            $self->{interface} = $windex;
            $interface = $windex;
            $vdLogger->Debug("Windows windump interface index:$windex ");
         } else {
            $vdLogger->Error("Unable to find windump index:$windex for ".
                             "interface");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      } else {
         # In case it is digit it will already be the index. Though
         # it is rare possbility that testbed will give index instead of
         # GUID.
         $interface = $self->{interface};
      }
   } else {
      # For linux/ESX interface would be like ethX.
      $interface = $self->{interface};
   }

   # If the tool is ping, get rid of the 'tcp' keyword from the filterString
   if ($self->{workload}->{toolname} =~ m/ping/i) {
      $filterString =~ s/tcp/icmp[icmptype] == icmp-echo/;
   }
   # Command to run tcpdump/windump on the remote host.
   # using -w file_name it writes the raw packets to file rather than parsing
   # and printing them on stdout.
   $command = "$binary -i $interface -w $fileName $filterString";
   $vdLogger->Info("Launching packet capture ($binary) in $host at ".
                   "interface:$interface");
   if($os =~ m/(esx|vmkernel)/i) {
      # tcpdump-uw does not support writing the packets to file
      # by tcpdump-uw using option "-w fileName"
      # Thus we write to file using pipe of OS.
      $command = "$binary -i $interface $filterString > $fileName";
      $vdLogger->Info("Filter-String:$filterString > $fileName");
   } else {
      $vdLogger->Info("Filter-String:$filterString -w $fileName");
   }
   $result = $self->{staf}->STAFAsyncProcess($host, $command,
                                             $self->{launchstdout}, $opts);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{processHandle} = $result->{handle};
   $vdLogger->Info("Successfully launched PacketCapture with handle:".
                    "$self->{processHandle}");
   return SUCCESS;

}


###############################################################################
#
# ProcessVerificationKeys -
#       Helps in generating filter string based on the traffic and adapter
#       settings. This translates the verification hash keyworkds into the
#       language which tcpdump understands. E.g. When a hash has l3protocol
#       as IPv6 this method converts it into ip6. Simiarly, for a
#       sessionport of 49165 into "port 49165".
#       In future more keys can be interpreted and added to the filter.
#
# Input:
#       verification hash key (required)   - E.g. l3protocol
#       verification hash Value (required) - E.g. ipv6
#
# Results:
#       string in case the value is understool by tcpdump.
#       0 in case there is no translation for that key for tcpdump.
#       FAILURE in case of failure
#
# Side effects:
#       None
#
###############################################################################

sub ProcessVerificationKeys
{
   my ($self, $key, $workloadPtr) = @_;
   if (not defined $key || not defined $workloadPtr) {
      $vdLogger->Error("Either key or value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $value = $workloadPtr->{$key};
   if(not defined $value) {
      return 0;
   }
   if($value eq "") {
      return 0;
   }

   switch ($key) {
      case m/(client)/i {
         # In both inbound and outbound src host is always client
         # reason being SUT or helper can acquire the role of client
         # but for packetcapture client only generates the packets
         # and thus is the src host all the time.
         # Also in inbound session client becomes helper we need not
         # worry if we are capturing RX path packets in inbound session.
         # It is already taken care of. Similarly for TX path.
         if ($workloadPtr->{routingscheme} =~ m/multicast/i ||
             $workloadPtr->{multicasttimetolive} ne "" ) {
            return "src host $value->{testip} and";
         } else {
            return "src host $value->{testip} and";
         }
      }
      case m/(server)/i {
         # In both inbound and outbound dst host is always server.
         if($workloadPtr->{routingscheme} =~ m/multicast/i ||
            $workloadPtr->{multicasttimetolive} ne "" ) {
            return "dst host $value->{multicastip} and";
         } else {
            return "dst host $value->{testip} and";
         }
      }
      #TODO: Use port number as filter needs more testing
#      case m/(sessionport)/i {
#            return "port $value and";
#      }
      case m/(l4protocol)/i {
         if ($workloadPtr->{routingscheme} =~ m/multicast/i ||
            $workloadPtr->{multicasttimetolive} ne "" ) {
            return 0;
         } elsif($value ne "") {
            return "$value and";
         }
      }
      case m/(l3protocol)/i {
         if ($value =~ /6$/) {
            return "ip6 and";
         } else {
            return "ip and";
         }
      }
      case m/(VLAN)/i {
         if($self->{vlanFlag} == 1) {
            return 0;
         }
         if(defined $self->{vlan}) {
            # Overwriting vlan if external vlan is given by user in
            # filterString
            $value = $self->{vlan};
         }
         if (int($value) > 0 ) {
            $self->{vlanFlag} = 1;
            return "vlan $value and";
         }
         return 0;
      }
      case m/(sendmessagesize)/i {
         # We cannot capture packets greater than MTU size.
         # Max possible MTU size can be 9000 with JF.
         # If SendMessageSize > MTU then we set MTU
         # else we set the greater SendMessageSize.
         my $mtu = $workloadPtr->{server}->{mtu};
         if(int($value) < int($mtu)) {
            return "greater $value and"
         } else {
            return 0;
         }
      }
      else {
         return 0;
      }
   }
   return FAILURE;
}


###############################################################################
#
# UpdateFilterString -
#       Checks for an existing keyword in the filter string and replaces the
#       updated value if it fits the criteria. The criteria depends on the
#       new value.
#
# Input:
#       string(required) - which one wants to find in filter
#       value(required) - which one wants to replace in filterString
#
# Results:
#       SUCCESS - in case the string is found in filter.(It returns success
#       even in the case of string is found & replaced with new value)
#       0 - in case string is not found.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub UpdateFilterString
{
   my ($self, $replaceWord, $replaceValue) = @_;
   if (not defined $replaceWord ||not defined $replaceValue) {
      $vdLogger->Warn("UpdateFilterString missing parameters");
      return 0;
   }

   my $filterString = $self->{filterString};
   my $temp;

   # Taking the example of filter string "-p -e 1521-vvv -C 20 and less 1500"
   # if less is found then we return SUCCESS so that we dont append another
   # less X string to it.
   # Now we also check if the previous value of less = 1500 is greater than
   # new value 1499. In this case we replace less with 1499 and return SUCCESS
   if ($filterString =~ m/$replaceWord/i) {
      # If the filter tag has value then use it else return SUCCESS
      if($filterString =~ /$replaceWord (.*?) /){
         $temp = $1;
      } else {
         return SUCCESS;
      }
      if(($replaceWord =~ m/greater/i && $temp < $replaceValue) ||
         ($replaceWord =~ m/less/i && $temp > $replaceValue)) {
         $filterString =~ s/greater (.*?) /$replaceValue/;
         return SUCCESS;
      } else {
         return SUCCESS;
      }
   } else {
      return 0;
   }
   return 0;
}

###############################################################################
#
# ExtractPacketInfo -
#       Extracts the desired packet Information from the packet statistics
#       hash.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
# Results:
#       string in case the value is understool by tcpdump.
#       0 in case there is no translation for that key for tcpdump.
#       FAILURE in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractPacketInfo
{
   my $self = shift;
   my $extractInfo = shift;

   my $packetStatHash = $self->ParseCapturedFile();
   if ($packetStatHash =~ m/FAILURE/i) {
      $vdLogger->Error("PacketCaptureStats:$packetStatHash are missing");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (not defined $extractInfo) {
      if (not defined $self->{packetInfo} || $self->{packetInfo} eq "") {
         $extractInfo = "count";
         $self->{packetInfo} = $extractInfo;
      } else {
         $extractInfo = $self->{packetInfo};
      }
   }

   if (not defined $extractInfo) {
      $vdLogger->Error("Information to be extraced from packetStats is ".
                       "missing");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Extracting PacketInfo:$extractInfo from captured packets");
   switch ($extractInfo) {
      case m/(count)/i {
         return $packetStatHash->{count};
      }
      case m/(avglen)/i {
         return $packetStatHash->{avglen};
      }
      case m/(min)/i {
         return $packetStatHash->{minPacketSize};
      }
      case m/(max)/i {
         return $packetStatHash->{minPacketSize};
      }
      case m/(tcpchecksum)/i {
         return $packetStatHash->{tcpCksumError};
      }
      case m/(udpchecksum)/i {
         return $packetStatHash->{ucpCksumError};
      }
      case m/(badpackets)/i {
         return  $packetStatHash->{badPackets};
      }
      else {
         $vdLogger->Error("Unknown packetInfo:$extractInfo specified");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   return FAILURE;
}

###############################################################################
#
# GetWinDumpIndex -
#       This method is used get the WinDump Index of a NIC given its GUID
#
# Input:
#       None.
#
# Results:
#       winDump index (string) in case of SUCCESS
#       FAILURE in case of failure
#
# Side effects:
#       None
#
###############################################################################

sub GetWinDumpIndex
{
   my $self = shift;
   my $GUID = $self->{interface};
   my $command;
   my $result;
   $GUID =~ s/\^\{//;
   $GUID =~ s/\}\^//;

   $command = "$self->{bin} -D";
   $result = $self->{staf}->STAFSyncProcess($self->{controlip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ( $result->{stdout} =~ /.*(\d+).\\\S+\\.*$GUID.*/ ) {
      return $1;
   } else {
      $vdLogger->Error("windump index not found for GUID:$GUID ".
                       "on host:$self->{controlip}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}

###############################################################################
#
# StopVerification -
#       This method builds the command(binary) for this verification tool.
#       1. For linux tcpdump
#       2. For windows
#          a. Based on the OS, get the binariespath from
#             VDNetLib::Common::GlobalConfig
#          b. Set command to the windump path after copying it to another dir.
#
# Input:
#       arch (required)
#       os (required)
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
   my $command;
   my $result;
   my $os = $self->{'os'};
   my $host = $self->{controlip};
   my $processHandle = $self->{processHandle};

   $self->{stopCaptureCalled} = 1;

   if (not defined $processHandle){
      $vdLogger->Error("StopCapture called without processHandle ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $result = $self->{staf}->GetProcessInfo($host, $processHandle);
   if ($result->{rc}) {
      my $launchStdoutFile = $self->{launchstdout};
      my $pktcapStdout = $self->{staf}->STAFFSReadFile($host,
                                                      $launchStdoutFile);
      if (not defined $pktcapStdout) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of pktcap launch code. File:$launchStdoutFile on ".
                          "$host");
         VDSetLastError("ESTAF");
         return FAILURE;
      } else {
         $vdLogger->Error("PktCap had died after saying:\n$pktcapStdout");
         if($pktcapStdout =~ m/(SIOCGIFINDEX|SIOCGIFHWADDR|ioctl)/i &&
            $os =~ m/(esx|vmkernel)/i) {
            # tcpdump-uw though needs to be started on vmkX interface
            # if there is no portgroup on it, tcpdump-uw fails with
            # tcpdump-uw: SIOCGIFHWADDR: Invalid argument
            $vdLogger->Warn("Does a portgroup exists on this ".
                             "$self->{interface} interface?");
         }
         VDSetLastError("EFAILURE");
         return FAILURE;
      }
   }
   my $pid = $result->{pid};

   if ($os =~ m/win/i) {
      $command = " TASKKILL /FI \"PID eq $pid\" /F";
   } else {
      $command = "kill -9 $pid";
   }

   $vdLogger->Info("Stopping packet Capture by killing process ".
                   "with PID:$pid");

   $result = $self->{staf}->STAFSyncProcess($host, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   return SUCCESS;
}

###############################################################################
#
# GetResult -
#       This method converts the pcap files into human readable format and
#       then calls GetResult methods on these files to parse required
#       information out of them.
#
# Input:
#       packetInfo(optional) - Info one wants to extract from the packet
#                              capture session. E.g. "count"
#
#
# Results:
#       integer value of the information to be extract from packet capture
#       FAILURE in case something goes wrong.
#
# Side effects:
#       Even in case of failure the files are deleted and thus are not
#       available for debugging.
#       When GetResult() returns 0 there are two scenarios
#          a) Either filter is very draconian and nothing was captured
#          b) Nothing was capture due to some error with tcpdump
#
###############################################################################

sub GetResult
{
   my $self = shift;
   my $packetInfo = shift || undef;
   my $host;
   my $command;
   my $result;
   my $os;
   my $sourceFileName;
   my $fileCount = 1;
   my $fileName;
   $host = $self->{'controlip'};
   $os = $self->{'os'};
   my $binary = $self->{bin};
   $sourceFileName = $self->{'fileName'};
   $fileName = $sourceFileName;

   # Get the masterController IP for copying
   # pcap files from SUT/Helper to masterController.
   my $masterControlleraddr;
   if (($masterControlleraddr = VDNetLib::Common::Utilities::GetLocalIP()) eq
       FAILURE) {
      $vdLogger->Error("Not able to get LocalIP:$masterControlleraddr");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }


   # Loop for:
   # 1) Check if pcap file exits or not
   # 2) Copy the file if it exists
   # 3) Convert it to human readable format
   # 4) Continue the loop with pcap1 file
   my $copyFileName;
   while(1)
   {
      if ( $os =~ m/win/i ) {
         my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
         $copyFileName = $sourceFileName;
         $copyFileName =~ s/.+\//$winDir/;
      } else {
         $copyFileName = $sourceFileName;
      }

      # We check if the file exists on remote machine.
      # This method returns undef if the file does not exits on remote host.
      $result = $self->{staf}->IsDirectory($host, $copyFileName);
      if(not defined $result) {
         # If copying any file failed then break from loop
         last;
      } else {
         $result = $self->{staf}->STAFFSCopyFile("$copyFileName",
                                                 "/tmp/",
                                                 "$host",
                                                 "$masterControlleraddr");
         if($result eq -1) {
            # If at all copying file failed then break from loop and
            # process rest of the files which are already copied.
            last;
         }
      }

      # Converting to human readable format to enable parsing
      # This is done in Master Controller itself.
      # Doing it in SUT or Helper would be slow and cumbersome.
      $command = "tcpdump -e -vvv -s0 -r ".
                 "$sourceFileName > $sourceFileName.tmp";
      if($os =~ m/(esx|vmkernel)/i) {
         $command = "cp ".
                 "$sourceFileName  $sourceFileName.tmp";
      }
      $result = $self->{staf}->STAFSyncProcess("local", $command);
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # If file exists and its size is zero then bail out
      my $fileSize = -s "$sourceFileName.tmp";
      if (-z $sourceFileName .".tmp") {
         $vdLogger->Warn("file:$sourceFileName.tmp has size:$fileSize. ".
                         "Something went wrong. Either traffic is not flowing"
                         ." OR your filter expression is very draconian");
         $vdLogger->Debug("Dumping pcap > pcap.tmp's staf output" .
                           Dumper($result));
         return 0;
      }
      $sourceFileName = $fileName . $fileCount;
      $fileCount++;
   }

   unless (-e $fileName || -z $fileName) {
      $vdLogger->Error("Not even one capture file filled with packets got ".
                      "created:" . $fileName);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $ret = $self->ExtractPacketInfo($packetInfo);
   if ($ret eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Info("Packet's:$self->{packetInfo} is:$ret");
      return $ret;
   }

}

###############################################################################
#
# ParseCapturedFile -
#       This method interprets the information in the tmp file and collects
#       various stats from it. Stats include checksum errors, bad packets,
#       length of packets, etc. It then saves them in a packetStats hash.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#       Even in case of failure the files are deleted and thus are not
#       available for debugging.
#
###############################################################################

sub ParseCapturedFile
{
   my $self = shift;
   my $fileName = $self->{fileName};
   my $fileCount = 1;
   my $packetStatHash;
   if (not defined $fileName || not defined $fileCount) {
      $vdLogger->Error("InterpretCapturedFile called without required " .
                       "parameters");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($line, @temp, @packetLen);
   my $tcpCksumError = 0;
   my $udpCksumError = 0;
   my $badPackets = 0;
   my $file = $fileName;

   while(1) {
      $file = $file . ".tmp";
      #checking if that file exists on the host
      unless (-e $file) {
         last;
      }
      # If file exists and its size is zero then bail out
      if (-z $file) {
         $vdLogger->Warn("Capture file:$file should not be empty");
      }

      if (not defined open(FILE, "<$file")) {
         $vdLogger->Error("Unable to open file $file for reading:"
                       ."$!");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Collection various stats after looping though all the data
      # of file.
      while($line = <FILE>) {
         if ($line =~ m/length (\d+)/i) {
            push(@packetLen,$1);
         }
         if ($line =~ /bad tcp chksum/) {
            $tcpCksumError++;
         }
         if ($line =~ /bad udp chksum/) {
            $udpCksumError++;
         }
         if (($line =~ /bad cksum/) || ($line =~ /incorrect/) ||
             ($line =~ /bad opt/) || ($line =~ /bad hdr length/)) {
            $badPackets++;
         }
      }
      # Moving on to the next file which tcpdump might have saved by
      # appending a number on front of it.
      $file = "$fileName"."$fileCount";
      $fileCount++;
      close(FILE);
   }

   # Total TCP Checksum Error
   $packetStatHash->{tcpCksumError} = $tcpCksumError;
   # Total UDP Checksum Error
   $packetStatHash->{ucpCksumError} = $udpCksumError;
   # Total Bad Packets
   $packetStatHash->{badPackets} = $badPackets;

   # Logic for counting number of packets
   $packetStatHash->{count} = scalar(@packetLen);
   if(scalar(@packetLen) == 0){
      $vdLogger->Warn("Packet capture Stats failed:".Dumper($packetStatHash));
      return FAILURE;
   }
   # Logic for findig average length of packets.
   my ($item, $sum);
   $sum = 0;
   foreach $item (@packetLen) {
      $sum = $sum + $item;
   }
   $packetStatHash->{avglen} = $sum / scalar(@packetLen);

   # Logic for calculating minimum and maximum packet size
   my @sortedArray = sort {$a <=> $b} (@packetLen);
   $packetStatHash->{minPacketSize} = $sortedArray[0];
   $packetStatHash->{maxPacketSize}  = $sortedArray[-1];
   $vdLogger->Info("Complete packet capture Stats:".Dumper($packetStatHash));

   return $packetStatHash;
}

###############################################################################
#
# DESTROY -
#       This method is destructor for this class. It takes care of wiping off
#       all the pcap and tmp files created during the session. This will
#       delete files irrespective of program ending peacefully.
#       Launches staf command to cleanup all *.pcap* files from all machines.
#
# Input:
#       None.
#
# Results:
#       SUCCESS - if everything goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       Even in case of failures the files are deleted and thus are not
#       available for debugging.
#
###############################################################################

sub DESTROY
{
   my $self = shift;
   my ($command, $result);
   my $stopCapture = $self->{stopCaptureCalled};
   my $fileName = $self->{fileName};
   my $os = $self->{os};

   if ($stopCapture == 0) {
      if ($self->StopVerification() eq FAILURE) {
         $vdLogger->Error("Failed to stop packet capturing ".
                          "process");
         VDSetLastError("EOPFAILED");
         return FAILURE;
       }
   }

   # Remove all files of this session which have unique timestamp
   # Thus delete all pcap files of current timestamp
   $fileName =~ m/PktCap-(.*)/;
   my $timeStamp = $1;
   # Command for deleting pcap files on MasterController
   my $localDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $localCommand = "rm -f " . $localDir . "*$timeStamp*";
   # Cleaning up the MasterController of all pcap files.
   $result = $self->{staf}->STAFSyncProcess("local", $localCommand);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # This is for deleting the pcap files sitting on SUT/Helper
   if ($self->{os} =~ /(lin|esx|vmkernel|mac|darwin)/i) {
      $command = $localCommand;
   } else {
     # Generating a string del /Q C:\\Tools\*.pcap*
     # /Q is to supress windows prompt confirming deletion.
     my $winDir = VDNetLib::Common::GlobalConfig::GetLogsDir($os);
     my $copyFileName = $winDir;
     $copyFileName =~  s/\\\\/\\/g;
     $command = "del /Q $copyFileName"."*$timeStamp";
   }
   $result = $self->{staf}->STAFSyncProcess($self->{controlip}, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Deleted all packet Capture files");
   return SUCCESS;

}

1;
