########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::TcpreplayTool;
my $version = "1.0";


#
# This module gives client/server objects for tcpreplay application
# It mostly deals with configuration of tcpreplay tool.
# Running the tool,getting result and stopping it are done by parent
# class of the tool. Child then inherits these methods.
# E.g. building command and testoptions is done by parent and
# then this package is asked to fill appropriate binary
# This module just populates the tcpreplay specific parameters and thus
# contains methods specific to tcpreplay. Other functionalites include:
# - Specifies constants related to tcpreplay.
# - Maintains the knowdlege of the traffic it supports
#


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);


use strict;
use warnings;
use Switch;
use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

use constant BINARY_TCPREPLAY_SERVER => "tcpdump";
use constant BINARY_TCPREPLAY_CLIENT => "tcpreplay";
use constant BINARY_TCPREWRITE => "/automation/bin/x86_32/linux/tcpreplay/tcprewrite";

use constant FILE_SEND_PCAP => "/tmp/send.pcap";
use constant FILE_RECEIVE_PCAP => "/tmp/receive.pcap";
use constant FILE_RECEIVE_TXT => "/tmp/receive.txt";
use constant FILE_SEND_TXT => "/tmp/send.txt";

########################################################################
#
# new --
#       Instantiates tcpreplay client or server object
#
# Input:
#       none
#
# Results:
#       returns object of TcpreplayTool class.
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;
   my $self  = {
      mode => undef,
      packetFile => "",
      packetType => "",
      dstMAC => "",
      srcMAC => "",
   };
   bless($self, $class);
   return $self;
}



########################################################################
#
# SupportedKeys -
#       Maintains a table of what type of
#       traffic values it supports.
#       In future if tcpreplay does not support any traffic just make an entry
#       in this table
#       It can be expanded to contain more rules.
#
# Input:
#       Traffic Key (required) - A hash key in Session hash
#       Traffic Value (required) - Value of that key in Session hash
#
# Results:
#       SUCCESS in case of Supported traffic
#       0 in case of unsupported traffic.
#       FAILURE in case of any error.
#
# Side effects:
#       None
#
########################################################################

sub SupportedKeys
{
   my ($self, $sessionKey, $sessionValue) = @_;
   if (not defined $sessionKey || not defined $sessionValue) {
      $vdLogger->Warn("SupportedKeys called with ".
                      "$sessionKey=$sessionValue");
   }
   return SUCCESS;
}


########################################################################
#
# GetToolBinary -
#       Returns the tcpreplay binary/command depending on linux and
#       client or server mode
#
# Input:
#       os (required)
#
# Results:
#       tool binary string - in case of success
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub GetToolBinary
{
   my $self  = shift;
   my $os = shift;

   if ($os =~ m/linux/i) {
      if ($self->{'mode'} =~ m/server/i ) {
         return BINARY_TCPREPLAY_SERVER;
      } else {
         return BINARY_TCPREPLAY_CLIENT;
      }
   } else {
      $vdLogger->Error("tcpreplay binary not support $os");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

}

#########################################################################
#
# BuildToolCommand -
#       This method ping command based on the OS
#
# Input:
#       os (required)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
########################################################################

sub BuildToolCommand
{
   my $self = shift;
   my %args = @_;
   my $os = $args{os};
   my ($globalConfigObj, $binpath, $binFile, $path2Bin);
   $globalConfigObj = new VDNetLib::Common::GlobalConfig;

   if (not defined $os || $os !~ m/linux/i) {
      $vdLogger->Error("Tcpreplay only support Linux ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $binFile = $self->GetToolBinary($os);
   if ($self->{mode} =~ m/client/i) {
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      $path2Bin = "$binpath" . "x86_32/linux/tcpreplay/";
      $self->{command} = $path2Bin . $binFile;
   } else {
      $self->{command} = $binFile;
   }
   return SUCCESS;
}

########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       tcpreplay understands.
#
# Input:
#       Session Key (required)   - E.g. localsendsocketsize
#       Session Value (required) - E.g. 4198
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       string in case of success
#       0 in case there is no translation for that key
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub GetToolOptions
{

   my $self    = shift;
   my %args  = @_;
   my $sessionKey = $args{'sessionkey'};
   my $sessionID  = $args{'sessionID'};
   my $sessionValue = $args{'sessionvalue'} || undef;
   my $ret;

   if (not defined $sessionKey || not defined $sessionID ) {
      $vdLogger->Error("one or more parameters missing in ".
                       "GetToolOptions.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $sessionValue) {
      $sessionValue = $sessionID->{$sessionKey};
   }

   if ($sessionValue eq "") {
      return 0;
   }

   switch ($sessionKey) {
         case m/PacketFile/i {
             $vdLogger->Info("PacketFile is $sessionValue");
             $self->{packetFile} = $sessionValue;
             if ($self->{mode} =~ m/server/i) {
                  return "";
             } else {
                  return FILE_SEND_PCAP;
             }
         }
         case m/PacketType/i {
             $vdLogger->Info("PacketType is $sessionValue");
             if (!$sessionValue) {
                 return 0;
             }
             $self->{packetType} = $sessionValue;
             return "";
         }
         else {
            return 0;
         }
  }
  return 0;
}

########################################################################
#
# RewritePacket -
#       This translates the raw packet file into current packet file
#       tcpreplay will send out, and the function will replace the
#       destination MAC and source MAC
#
# Input:
#       Session Key (required)   - E.g. localsendsocketsize
#       Session Value (required) - E.g. 4198
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       string in case of success
#       0 in case there is no translation for that key
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub RewritePacket
{
   my $self = shift;
   my $session = shift;
   my $source_packet = shift;
   my $dst_mac;
   my $src_mac;
   my $command;
   my $ret;
   my $control_ip;

   $dst_mac = VDNetLib::Common::Utilities::GetMACFromIP(
                                                        $session->{server}->{testip},
                                                        $self->{staf},
                                                        $session->{server}->{controlip});
   if (!$dst_mac) {
      $vdLogger->Error("Can not get MAC address of $session->{server}->{testip} on $session->{server}->{controlip}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{dstMAC} = $dst_mac;
   $src_mac = VDNetLib::Common::Utilities::GetMACFromIP(
                                                        $session->{client}->{testip},
                                                        $self->{staf},
                                                        $session->{client}->{controlip});
   if (!$src_mac) {
      $vdLogger->Error("Can not get MAC address of $session->{server}->{testip} on $session->{server}->{controlip}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{srcMAC} = $src_mac;

   if ($self->{mode} =~ /server/i) {
       $control_ip = $session->{server}->{controlip};
   } else {
       $control_ip = $session->{client}->{controlip};
   }
   $command = "rm -f " . FILE_SEND_PCAP . ";" . BINARY_TCPREWRITE . " --enet-dmac=$dst_mac --enet-smac=$src_mac" .
              " --infile=$source_packet --outfile=". FILE_SEND_PCAP;
   $vdLogger->Info($command);
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $ret = $self->{staf}->IsFile($control_ip, FILE_SEND_PCAP);
   if (not defined $ret || $ret != 1) {
      $vdLogger->Error(FILE_SEND_PCAP . " not present on $control_ip");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS - to comply with interface
#
# Side effects:
#       None
#
###############################################################################

sub ToolSpecificJob
{
   my $self = shift;
   my $sessionID  = shift;
   my $os = $sessionID->{$self->{'mode'}}->{'os'};
   my $controlIP = $sessionID->{$self->{'mode'}}->{'controlip'};
   my $ret;

   if ($self->{packetFile} eq "") {
        $vdLogger->Error("Need one parmater PacketFile");
        VDSetLastError("EOPFAILED");
        return FAILURE;
   }

   $ret = $self->RewritePacket($sessionID, $self->{packetFile});
   if ($ret eq FAILURE) {
          $vdLogger->Error("Can not rewrite PacketFile");
          VDSetLastError("EOPFAILED");
          return FAILURE;
   }
   if ($self->{mode} =~ m/client/i) {
     $ret = $self->{staf}->IsFile($controlIP, $self->{command});
     if (not defined $ret) {
        $vdLogger->Error("File:$self->{command} not present on $controlIP");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     } elsif ($ret ne 1) {
        $vdLogger->Error("File:$self->{command} not present on $controlIP");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
   }
   return SUCCESS;
}


########################################################################
#
# StartClient --
#       Start client of tool on the target VM to via local testIP
#       Execute self->{command} on the target VM with testOptions
#
# Input:
#       Object of Session class - Session ID (required)
#
# Results:
#       Stores the result in self->result
#       FAILURE - in case of error
#
# Side effects:
#       None
#
########################################################################

sub StartClient
{
   my $self = shift;
   my $session = shift;
   my ($command, $opts, $result);
   my $controlIP = $session->{client}->{controlip};
   my $testOptions;

   if (not defined $self->{command}) {
      $vdLogger->Error("StartClient: command is not defined".Dumper($self));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Check the status of the server before launching client
   if ($self->IsToolServerRunning($session) eq FAILURE) {
      $vdLogger->Error("Traffic Server Down and can not start tcpreplay client");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if (!$session->{client}->{interface}) {
      $vdLogger->Error("tcpreplay client must know which interface in Linux is used to send out traffic");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $testOptions = " -i $session->{client}->{interface} -M 0.5 " . $self->{testOptions};
   # Now working on the client part
   $command = "$self->{command} $testOptions";
   $vdLogger->Info("Launching traffic client($self->{command}) on $controlIP");
   $vdLogger->Info("With testoptions: $testOptions");
   $result = $self->{staf}->STAFSyncProcess($controlIP, $command);

   if ($result->{rc} && $result->{exitCode}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{stdout} = $result->{stdout};
   $self->{stderr} = $result->{stderr};
   return SUCCESS;
}

########################################################################
#
# StartServer -
#       This method is required as parent enforces server model
#
# Input:
#       None
#
# Results:
#       SUCCESS - to comply with interface
#
# Side effects:
#       None
#
########################################################################

sub StartServer
{
   my $self = shift;
   my $session = shift;
   my ($command, $result, $pid, $processName);
   my $controlIP = $session->{server}->{controlip};
   my $testOptions;

   if (not defined $self->{command}) {
      $vdLogger->Error("StartServercommand:$self->{command} is not defined"
                       .Dumper($self));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (!$self->{srcMAC} || !$self->{dstMAC}) {
      $vdLogger->Error("Source MAC or destination MAC is blank"
                       . Dumper($self));
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (!$session->{server}->{interface}) {
      $vdLogger->Error("tcpreplay server must know which interface in Linux is used to listen ");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # command to clean the receive.pcap
   $command = "rm -f " . FILE_RECEIVE_PCAP;
   $self->{staf}->STAFSyncProcess($controlIP, $command);

   $testOptions = " -w " . FILE_RECEIVE_PCAP . " -s 1600 -i $session->{server}->{interface}" .
                  " ether dst $self->{dstMAC} and ether src $self->{srcMAC}";
   #"tcpdump -w /tmp/receive.pcap -s 1600 -i eth1  ether dst $dstMacAddr and ether src $srcMacAddr";
   $command = "$self->{command} $testOptions &";

   $vdLogger->Info("Launching traffic server($self->{command}) on $controlIP");
   $vdLogger->Info("With testoptions: $testOptions");
   $result = $self->{staf}->STAFAsyncProcess($controlIP, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Trace("The 3 sec sleep is required for the server to initialize completely,".
                   "otherwise it fails with Broken pipe error.");
   sleep(3);
   $self->{childHandle} = $result->{handle};

   return SUCCESS;
}

########################################################################
#
# GetThroughput --
#       Parses received packet file of tcpreplay session
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       "PASS" if test success
#       "FAIL" if test fail
#       FAILURE in case of error.
#
# Side effects;
#       none
#
########################################################################

sub GetThroughput
{
   my $self = shift;
   my $session = shift;
   my $minExpResult = shift || undef;
   my $command;
   my $control_ip;
   my $ret;
   my $send_count;
   my $receive_count;

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if(not defined $self->{stdout}){
      # stderr is set when process is launched in sync mode.
      # In case of async error is in temp file which is then
      # read
      if(defined $self->{stderr}){
         $vdLogger->Warn("stdout not defined. stderr is: $self->{stderr}");
      }
   } else {
      # To remove extra blank lines in stdout as it looks ineligible.
      $self->{stdout}  =~ s/\r\r\n/\n/g;
      $vdLogger->Info("Stdout of $session->{toolname} on ".
                      "$session->{client}->{controlip}\n$self->{stdout}");
   }

   $control_ip = $session->{server}->{controlip};

   # stop tcpdump to get all sent packet
   $command = "killall -s SIGINT " . BINARY_TCPREPLAY_SERVER;
   $vdLogger->Info($command);
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $ret = $self->{staf}->IsFile($control_ip, FILE_RECEIVE_PCAP);
   if (not defined $ret || $ret != 1) {
      $vdLogger->Error(FILE_RECEIVE_PCAP . " not present on $control_ip");
      return "FAIL";
   }

   # check packet type
   $command = "tcpdump -r " . FILE_RECEIVE_PCAP . ">" . FILE_RECEIVE_TXT;
   $vdLogger->Info($command);
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $ret = $self->{staf}->IsFile($control_ip, FILE_RECEIVE_TXT);
   if (not defined $ret || $ret != 1) {
      $vdLogger->Error(FILE_RECEIVE_TXT . " not present on $control_ip");
      return "FAIL";
   }
   if ($self->{packetType} eq "") {
       $vdLogger->Error("No parameter PacketType");
       VDSetLastError("ESTAF");
       return "FAIL";
   }
   $command = "cat " . FILE_RECEIVE_TXT . "| grep -i $self->{packetType} ";
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ /$self->{packetType}/gi) {
      $vdLogger->Info("Traffic server received $self->{packetType} frames");
   } else {
      $vdLogger->Error("Traffic server did not receive $self->{packetType} frames");
      return "FAIL";
   }

   # check packet count
   $command = "tcpdump -r " . FILE_SEND_PCAP . ">" . FILE_SEND_TXT;
   $vdLogger->Info($command);
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $ret = $self->{staf}->IsFile($control_ip, FILE_SEND_TXT);
   if (not defined $ret || $ret != 1) {
      $vdLogger->Error(FILE_SEND_TXT . " not present on $control_ip");
      return "FAIL";
   }

   $command = "cat " . FILE_SEND_TXT . "| grep -i $self->{packetType} | wc -l";
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ m/(\d+)\s*/) {
        $send_count = $1;
   } else {
        $vdLogger->Error("Can no get the count of $self->{packetType} frame");
        VDSetLastError("ESTAF");
        return FAILURE;
   }
   $vdLogger->Info("Sent out $send_count $self->{packetType} frames");

   $command = "cat " . FILE_RECEIVE_TXT . "| grep -i $self->{packetType} | wc -l";
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ m/(\d+)\s*/) {
        $receive_count = $1;
   } else {
        $vdLogger->Error("Can no get the count of $self->{packetType} frame");
        VDSetLastError("ESTAF");
        return FAILURE;
   }
   $vdLogger->Info("Received $receive_count $self->{packetType} frames");

   if ($receive_count eq $send_count) {
      $vdLogger->Info("Pass to finish $self->{packetType} test");
      return "PASS";
   } else {
      $vdLogger->Error("Fail to finish $self->{packetType} test");
      return "FAIL";
   }
}

########################################################################
#
# GetLaunchType --
#       Overrides the parent method and returns launch type of process.
#
# Input:
#       none
#
# Results:
#       sync as ping should be executed in sync mode.
#
# Side effects;
#       none
#
########################################################################

sub GetLaunchType
{
   return "sync";
}

########################################################################
#
# IsToolServerRunning --
#       Overrides the parent method as there is nothing to be done in
#       Ping module. Ping module does not have a server.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects;
#       none
#
########################################################################

sub IsToolServerRunning
{
   my $self = shift;
   my $session = shift;
   my $result;
   my $serverCtrlIP = $session->{server}->{controlip};
   my $serverHandle = $session->{server}->{instance0}->{childHandle};

   # First check - checking the status of process.
   $result = $self->{staf}->GetProcessInfo($serverCtrlIP,$serverHandle);
   if ($result->{rc}) {
      return FAILURE;
   }
   return SUCCESS;
}
1;
