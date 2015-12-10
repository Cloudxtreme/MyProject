########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::PingTool;
my $version = "1.0";


#
# This module deals with configuration of Ping Utility
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
# This module just populates the ping specific parameters and thus
# contains methods specific to ping. Other functionalites include:
# - Specific constants related to Ping.
# - Maintains the knowdlege of the traffic it supports
#


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);


##TODO: Verify if this block if required as parent class already has it
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Switch;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

use constant PING_COMMAND => "ping";
use constant NUM_PACKET_SECOND => 1;
# This is the minimum amount of percentage of packets we should receive
use constant MIN_EXP_RESULT => 75;

########################################################################
#
# new --
#       Instantiates ping object. Remember that TrafficTool enforces
#       client server model but ping is standalone thus it has methods
#       like StartServer but they just return SUCCESS as there is no
#       server in case of ping.
#
# Input:
#       none
#
# Results:
#       returns object of PingTool class.
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;
   my $self  = {
      'mode' => undef,
      'pktCountFlag' => 0,
   };
   return (bless($self, $class));
}



########################################################################
#
# SupportedKeys -
#       Maintains a table (in form of switch case) of what type of
#       traffic values it supports.
#       In future if Ping does not support any traffic just make an entry
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

   return SUCCESS;

}


########################################################################
#
# GetToolBinary -
#       Returns the ping binary/command depending on win or linux or esx
#
# Input:
#       os (required)
#
# Results:
#       tool binary string - in case of success
#       FAILURE in case of failure
#
# Side effects:
#       Some ESX versions might have ping, some might have vmkping as
#       command.
#
########################################################################

sub GetToolBinary
{
   my $self  = shift;
   my $os = shift;

   if ($os =~ m/(linux|win|mac|darwin)/i) {
      return "ping";
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      return "vmkping";
   } else {
      $vdLogger->Error("Unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       ping understands. E.g. When a session says run ping for duration
#       of 5 sec. Then this method converts it into number of packets
#       to send for that duration. Currently we send 1 packet per sec.
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
      case m/(l3protocol|addressfamily)/i {
         if ($sessionValue =~ m/ipv6/i ||  $sessionValue =~ m/af_inet6/i) {
            # On windows IPv6 is usually sourced. i.e. IPv6 traffic
            # needs to be told which source interface to use for
            # sending traffic.
            # TODO: This can be remove after routes are set
            # before running the IPv6 traffic.
            if($sessionID->{client}->{os} =~ m/^win/i){
               return " -6 ";
            } elsif($sessionID->{client}->{os} =~ m/(esx|vmkernel)/i) {
               return " -6 ";
            } else {
               # Source binding is done by default now
               #return " -I $sessionID->{client}->{testip}";
            }
         }
      }
      case m/(server)/i {
         my $srcBindStr = "";
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $srcBindStr =  " -I $sessionID->{client}->{testip}";
         } elsif ($sessionID->{client}->{os} =~ m/mac|darwin/i) {
            $srcBindStr =  " -S $sessionID->{client}->{testip}";
         } elsif ($sessionID->{client}->{os} =~ m/(esx|vmkernel)/i) {
            $srcBindStr =  " -I $sessionID->{client}->{interface}";
         } elsif ($sessionID->{client}->{os} =~ m/^win/i &&
                 $sessionID->{l3protocol} =~ m/ipv6/i) {
            $srcBindStr =  " -S $sessionID->{client}->{testip}";
         }
         if ($self->{mode} =~ m/client/i &&
             $sessionID->{routingscheme} !~ m/broadcast/i ) {
            # Changed the format of the parameters passed to ping to the following
            # as the previous format doesnt work with Mac. But this is compatible
            # with Mac and Linux.
            return $srcBindStr."  $sessionValue->{'testip'} ";
         } else {
          # As we carry only broadcast address in traffic hash
          # we dont know the address of local interface thus cannot
          # do source binding here.
          return " $sessionValue->{'testip'}";
         }
         last;
      }
      case m/(pktfragmentation)/i {
         if ($sessionValue =~ m/(no|disable)/i) {
            if($sessionID->{client}->{os} =~ m/^win/i){
               if($sessionID->{l3protocol} =~ m/ipv6/i){
                  $vdLogger->Info("Ignoring DoNotFragment bit as its ".
                                  "applicable only on IPv4 for windows");
               } else {
                  return "-f ";
               }
            } elsif ($sessionID->{client}->{os} =~ m/(vmkernel|esx)/i){
               return "-d";
            } else {
               # do (prohibit fragmentation, even local one)
               # dont (do not set DF flag)
               return "-M do";
            }
         }
      }
      case m/(routingscheme)/i {
         if ($self->{mode} =~ m/client/i) {
            if($sessionValue =~ m/broadcast/i){
               if($sessionID->{client}->{os} =~ m/linux/i){
                  return "-b ";
               }
            }
            if($sessionValue =~ m/flood/i){
               if($sessionID->{client}->{os} =~ m/linux|mac|darwin/i){
                  return "-f -c 10000";
                  $self->{pktCountFlag} = 1;
               } else {
                  $vdLogger->Warn("Only linux supports flood ping attack");
               }
            }
         }
         last;
      }
      case m/(pingpktsize)/i {
         if ($self->{mode} =~ m/client/i) {
            if($sessionID->{client}->{os} =~ m/^win/i){
               return "-l $sessionValue";
            } else {
               return "-s $sessionValue";
            }
         }
         last;
      }
      case m/(ipttl)/i {
         if ($self->{mode} =~ m/client/i) {
            if($sessionID->{client}->{os} =~ m/^win/i){
               return "-i $sessionValue";
            } else {
               return "-t $sessionValue";
            }
         }
         last;
      }
      case m/(testduration)/i {
          if ($self->{mode} =~ m/client/i && $self->{pktCountFlag} == 0) {
             # We try to send 1 packet per sec if interval is not specified.
             # Else number of packets = duration/interval.
             my $numPackets;
             if (defined $sessionID->{packetinterval}) {
                $vdLogger->Debug("PacketInterval specified with TestDuration. ".
                                 "Calculating packet count as Duration/Interval.");
                $numPackets = $sessionValue / $sessionID->{packetinterval};
             }
             else {
                $vdLogger->Debug("PacketInterval not specified with TestDuration. ".
                                 "Assuming default interval of 1 pkt/sec.");
                $numPackets = $sessionValue * NUM_PACKET_SECOND;
             }
             # This logic is: For windows we set the packet count
             # But for linux we check if user wants to run a flood
             # ping attack. If he wants to run it we don't set the
             # packetCount but hard code the value to 10,000 as a
             # parameter to flood ping attack.
             if(($sessionID->{client}->{os} =~ m/^win/i)){
              return "-n $numPackets";
             } elsif($sessionID->{routingscheme} !~ m/flood/i) {
              return "-c $numPackets";
             }
          }
          last;
      }
      case m/(packetinterval)/i {
          if ($self->{mode} =~ m/client/i) {
             if ($sessionID->{client}->{os} =~ m/^linux/i){
                return "-i $sessionValue";
             }
             else {
                $vdLogger->Error("Specifying packet interval supported only on linux.");
             }
          }
          last;
      }
      else {
         return 0;
      }
   }
   return 0;
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
   my $self    = shift;
   if ($self->{mode} =~ m/server/i) {
      return SUCCESS;
   }

   my %args  = @_;
   my $os = $args{'os'};

   if (not defined $os) {
      $vdLogger->Error("Cannot proceed without OS parameter ".
                       "in BuildToolCommand.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{command}  = $self->GetToolBinary($os);
   return SUCCESS;
}


###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool. In case of IPv6 linux uses binary ping6
#       thus this method helps to change the binary at last moment without
#       interrupting rest of the code.
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
   my $self    = shift;
   my $sessionID  = shift;
   my $os = $sessionID->{$self->{'mode'}}->{'os'};

   if ($sessionID->{l3protocol} =~ m/ipv6/i) {
      if($os =~ m/linux/i){
         $self->{command}  = $self->GetToolBinary($os) . "6";
      }
   }

   #
   # for esx if the interface does not belong to the
   # default tcpip stack then append the netstack paramter
   # the ping command.
   #
   if ($os =~ m/(esx|vmkernel)/i) {
      my $netstack = $sessionID->{$self->{'mode'}}->{'netstack'};
      if ($netstack !~ m/defaultTcpipStack/i) {
         my $command = $self->GetToolBinary($os);
         $self->{command} = $command . " ++netstack=$netstack";
      }
   }

   if($sessionID->{routingscheme} =~ m/broadcast/i){
      if($sessionID->{client}->{os} =~ m/linux/i &&
         $sessionID->{server}->{os} =~ m/^win/i &&
         $self->{mode} =~ m/client/i){
            $vdLogger->Warn("Windows might not reply to brocast ping. ".
                            "Others in same subnet might reply so trying....");
      }
      if($sessionID->{server}->{os} =~ m/(esx|vmkernel)/i){
         #
         # For esx to respond to ping request one must have
         # vsish -e set /net/tcpip/instances/subnet16-23179/sysctl/_net_inet_icmp_bmcastecho 1
	 # here subnet16-23179 is the netstack instance name
	 #
         my $command = "vsish -e set /net/tcpip/instances/";
         $command = $command . $sessionID->{server}->{'netstack'};
         $command = $command . "/sysctl/_net_inet_icmp_bmcastecho 1";
         my $ctrlIP = $sessionID->{server}->{controlip};
         my $result = $self->{staf}->STAFSyncProcess($ctrlIP,$command);

         if ($result->{rc} || $result->{exitCode}) {
            $vdLogger->Trace("Setting $command on $ctrlIP failed");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
           $vdLogger->Trace("Successfully set $command on $ctrlIP");
         }
      }
      if($sessionID->{server}->{os} =~ m/linux/i){
         # For linux to respond to ping request one must have
         # sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
         my $command = "sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0";
         my $ctrlIP = $sessionID->{server}->{controlip};
         my $result = $self->{staf}->STAFSyncProcess($ctrlIP,$command);

         if ($result->{rc} || $result->{exitCode}) {
            $vdLogger->Trace("Setting sysctl ".
                             "-w net.ipv4.icmp_echo_ignore_broadcasts=0 on ".
                             "$ctrlIP failed");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
           $vdLogger->Trace("Successfully set sysctl ".
                             "-w net.ipv4.icmp_echo_ignore_broadcasts=0 on ".
                             "$ctrlIP");
         }
      }

      if($sessionID->{client}->{os} =~ m/linux/i){
         # Disabling the ping reply from localhost on client
         my $command = "sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1";
         my $ctrlIP = $sessionID->{client}->{controlip};
         my $result = $self->{staf}->STAFSyncProcess($ctrlIP,$command);

         if ($result->{rc} || $result->{exitCode}) {
            $vdLogger->Trace("Setting sysctl ".
                             "-w net.ipv4.icmp_echo_ignore_broadcasts=1 on ".
                             "$ctrlIP failed");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
           $vdLogger->Trace("Successfully set sysctl ".
                             "-w net.ipv4.icmp_echo_ignore_broadcasts=1 on ".
                             "$ctrlIP");
         }
      }

      if($sessionID->{server}->{os} =~ m/mac/i){
         # Command to enable mac to receive ping requests.
         my $command = "sysctl -w net.inet.icmp.bmcastecho=1";
         my $ctrlIP = $sessionID->{server}->{controlip};
         my $result = $self->{staf}->STAFSyncProcess($ctrlIP,$command);

         if ($result->{rc} || $result->{exitCode}) {
            $vdLogger->Trace("Setting $command on ".
                             "$ctrlIP failed");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
           $vdLogger->Trace("Successfully set $command on ".
                             "$ctrlIP");
         }
      }

      if($sessionID->{client}->{os} =~ m/mac/i){
         # Disabling the ping reply from localhost on client
         my $command = "sysctl -w net.inet.icmp.bmcastecho=0";
         my $ctrlIP = $sessionID->{client}->{controlip};
         my $result = $self->{staf}->STAFSyncProcess($ctrlIP,$command);

         if ($result->{rc} || $result->{exitCode}) {
            $vdLogger->Trace("Setting $command on ".
                             "$ctrlIP failed");
            VDSetLastError("ESTAF");
            return FAILURE;
         } else {
           $vdLogger->Trace("Successfully set $command on ".
                             "$ctrlIP");
         }
      }
   }

   return SUCCESS;
}


########################################################################
#
# StartServer -
#       This method is required as parent enforces a client server model and as
#       ping does not have any server it just returns SUCCESS.
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
   return SUCCESS;
}


########################################################################
#
# Stop-
#       This method is required as parent enforces a client server model and as
#       ping does not have any server there is nothing to be stopped. Clients
#       are always started with timer or limited amount of data to be sent after
#       which the client ends on its own. Here also we will start ping with
#       limited number of packets or time duration.
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

sub Stop
{
   return SUCCESS;
}


########################################################################
#
# GetThroughput --
#       Parses stdout of ping session and warns if percentage packet loss
#       is greater than 25%.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS if packet loss is less than 25%
#       FAILURE in case of error.
#
# Side effects;
#       none
#
########################################################################

sub GetThroughput
{
   my $self = shift;
   my $sessionID = shift;
   my $minExpResult = shift || undef;
   my $trafficToolStdOut = "";

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;
   if(not defined $self->{stdout}){
      # stderr is set when process is launched in sync mode.
      # In case of async error is in temp file which is then
      # read
      if(defined $self->{stderr}){
         $vdLogger->Warn($clientInstance ."'s stdout not defined.".
                         " stderr is: $self->{stderr}");
      }
   } elsif($self->{stdout} =~ m/bad/i || $self->{stdout} eq "" ||
           $self->{stdout} =~ m/not a valid/i) {
      $vdLogger->Trace("Something went wrong with stdout of $clientInstance".
                       ":$self->{stdout}");
      if(defined $self->{stderr}){
         $vdLogger->Error("$self->{stderr}");
      }
   } else {
      # To remove extra blank lines in stdout as it looks ineligible.
      $self->{stdout}  =~ s/\r\r\n/\n/g;
      my @stats = split(/statistics/,$self->{stdout});
      # As ping is now executed before every run dialing down the
      # verbosity of its output for cleaner logs.
      if (defined $stats[1]) {
          $vdLogger->Debug("Stdout of $clientInstance from ".
                           "$sessionID->{client}->{controlip} to ".
                           "$sessionID->{server}->{controlip}\n$stats[1]");
      } else {
          $vdLogger->Debug("Stdout of $clientInstance from ".
                           "$sessionID->{client}->{controlip} to ".
                           "$sessionID->{server}->{controlip}\n".
                           "$self->{stdout}");
      }
      $trafficToolStdOut = $self->{stdout};
      if (not defined $trafficToolStdOut) {
         $vdLogger->Error("Traffic tool output is undefined");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   # Common stdout of linux/windows/esx is something like this
   # Reply from 192.168.0.170: bytes=32 time<1ms TTL=64
   # Reply from 192.168.0.170: bytes=32 time<1ms TTL=64
   # Reply from 192.168.0.170: bytes=32 time<1ms TTL=64
   # Ping statistics for 192.168.0.170:
   # Packets: Sent = 10, Received = 10, Lost = 0 (0% loss),
   # Approximate round trip times in milli-seconds:
   # Minimum = 0ms, Maximum = 0ms, Average = 0ms
   # Thus we try to find the line with loss word in it and then
   # parse the percentage value.

   my @lines = split(/\n/,$trafficToolStdOut);
   my ($sent, $loss, $percentage, $line);
   foreach $line (@lines){
      if ($line =~ m/(loss|lost)/i){
         if ($line =~ m/(\d+)% packet loss/i ||
             $line =~ m/(\d+)% loss/i){
            $percentage = $1;
         } else {
            $vdLogger->Warn("Cannot find packet loss value from ping ".
                            "stdout of $clientInstance");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         last;
      }
   }


   if(not defined $minExpResult){
      $minExpResult = MIN_EXP_RESULT;
   } else {
      # If minimum expected result is to be ignored i.e. "minExpResult => IGNORE",
      # throughput of the traffic session need not be calculated
      if ($minExpResult =~ /IGNORE/i) {
         $vdLogger->Info("Ignoring traffic output verification as per user ".
                         "for ".$clientInstance);
         return SUCCESS;
      }
      $vdLogger->Debug("Minimum packets expected to be received:".$minExpResult." %");
   }

   # Check if the number we got is of type floating point and if it is greater
   # than 25
   if (defined $percentage && ($percentage =~ /[0-9]+\.?[0-9]*/) &&
      ((100 - int($percentage)) < $minExpResult)) {
      $vdLogger->Info("Minimum packets expected to be received:".$minExpResult." %");
      $vdLogger->Error($clientInstance."'s Ping packet loss is: $percentage \%");
      return FAILURE;
   } elsif(defined $percentage) {
      $vdLogger->Info($clientInstance."'s Ping packet loss is: $percentage \%");
      return "PASS"
   } else {
      $vdLogger->Warn("Undefined Percentage Packet loss for $clientInstance");
   }
   return FAILURE;
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
# PrintTrafficStdout --
#       Overrding parent's method.
#
# Input:
#	none.
#
# Results:
#	none.
#
# Side effects;
#       none
#
########################################################################

sub PrintTrafficStdout
{

   return SUCCESS;
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
   return SUCCESS;
}
1;
