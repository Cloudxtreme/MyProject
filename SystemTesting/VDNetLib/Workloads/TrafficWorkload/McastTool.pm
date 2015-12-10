########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::McastTool;
my $version = "1.0";


#
# This module gives client/server objects for mcast_tool.py
# It mostly deals with configuration of mcast_tool tool.
# Running the tool,getting result and stopping it are done by parent
# class of the tool. Child then inherits these methods.
# E.g. building command and testoptions is done by parent and
# then this package is asked to fill appropriate binary
# This module just populates the mcast_tool specific parameters and thus
# contains methods specific to mcast_tool. Other functionalites include:
# - Specifies constants related to mcast_tool.
# - Maintains the knowledge of the traffic it supports
#
# This tool is designed to work with Linux VM.  In actual TDS, we may
# call method SetMulticastVersion in VMOperations.pm under a Linux VM to
# set wanted version of multicast report message (IGMPv1/v2/v3, MLDv1/v2)
# before this tool running.
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

use constant PYTHON_PATH => "/bldmnt/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/";
use constant BINARY_PYTHON => "python";
use constant BIN_PATH => "/automation/pylib/io_tools/mcast_report/";
use constant MCASTTOOL_SCRIPT => "mcast_tool.py";
use constant MCAST_CONFIG_FILE => "/tmp/mcast_task.conf";
use constant SLEEP_AFTER_SERVER_START => 5;

########################################################################
#
# new --
#       Instantiates mcast_report or server object
#
# Input:
#       none
#
# Results:
#       returns object of McastTool class.
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
   };
   bless($self, $class);
   return $self;
}

########################################################################
#
# SupportedKeys -
#       Maintains a table of what type of
#       traffic values it supports.
#       It can be expanded to contain more rules.
#
# Input:
#       Traffic Key (required) - A hash key in Session hash
#       Traffic Value (required) - Value of that key in Session hash
#
# Results:
#       SUCCESS in case of Supported traffic
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
#       Returns the mcast_tool binary/command depending on linux and
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
       return BINARY_PYTHON;
   } else {
       $vdLogger->Error("mcast_tool binary not support $os");
       VDSetLastError("ENOTDEF");
       return FAILURE;
   }
}


#########################################################################
#
# BuildToolCommand -
#       This method mcast_tool.py command based on the OS
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

   if (not defined $os || $os !~ m/linux/i) {
      $vdLogger->Error("mcast_tool only support Linux ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{command} = PYTHON_PATH . BINARY_PYTHON . " " .
                             BIN_PATH . MCASTTOOL_SCRIPT;
   return SUCCESS;
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       mcast_tool understands.
#
# Input:
#       Session Key (required)   - E.g. group_address
#       Session Value (required) - E.g. 239.1.1.1
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
   my $self  = shift;
   my %args  = @_;
   my $sessionKey = $args{'sessionkey'};
   my $sessionID  = $args{'sessionID'};
   my $sessionValue = $args{'sessionvalue'} || undef;
   my $ret = 0;

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

   if ($self->{'mode'} =~ m/(server)/i) {
      switch ($sessionKey) {
         case m/(server)/i {
            $self->{host} = $sessionID->{server}->{controlip};
            $ret = " -s -H $sessionID->{server}->{controlip} ";
            last;
         }
         case m/(sessionport)/i {
            $sessionID->{server}->{testport} = $sessionValue;
            $ret = " -p $sessionValue ";
            last;
         }
      }
   } else {
      switch ($sessionKey) {
         case m/McastMethod/i {
            if ($sessionValue =~ m/(quit)/i) {
               $self->{McastMethod} = $sessionValue;
               $ret = " -c -q -H $sessionID->{server}->{controlip} ";
            } else {
               $self->{McastMethod} = $sessionValue;
               $self->{McastInterface} = $sessionID->{server}->{interface};
               $ret =  " -c -f " . MCAST_CONFIG_FILE .
                                  " -H $sessionID->{server}->{controlip} ";
            }
            last;
         }
         case m/(sessionport)/i {
            $ret = " -p $sessionID->{sessionport} ";
            last;
         }
         case m/McastGroupAddr/i {
            $self->{McastGroupAddr} = $sessionValue;
            last;
         }
         case m/McastIpFamily/i {
            $self->{McastIpFamily} = $sessionValue;
            last;
         }
         case m/McastSourceAddrs/i {
            $self->{McastSourceAddrs} = $sessionValue;
            last;
         }
      }
  }
  return $ret;
}


########################################################################
#
# GetThroughput --
#       Parses stdout of Mcast session and warns if no output.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS if test succeeded
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
   my $srcip = $sessionID->{client}->{testip};
   my $dstip = $sessionID->{server}->{testip};

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;

   if (not defined $self->{stdout}) {
      $vdLogger->Error("stdout for $clientInstance McastReport not defined.");
      return FAILURE;
   } elsif ($self->{stdout} eq "") {
      $vdLogger->Error("no stdout of $clientInstance McastReport.");
      return FAILURE;
   }
   if ($self->{stdout} =~ m/SUCCESS:.*/i) {
      $vdLogger->Debug("McastReport on $clientInstance is working: " .
                                                   "$self->{stdout}");
      return SUCCESS;
   }
   $vdLogger->Error("McastReport on $clientInstance failed: $self->{stdout}");

   return FAILURE;
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
#       FAILURE - in case of error
#
# Side effects:
#       None
#
########################################################################

sub StartServer
{
   my $self = shift;
   my $sessionID = shift;
   my ($command, $result, $pid, $processName);
   my $controlIP = $sessionID->{'server'}->{'controlip'};

   if (not defined $self->{command}) {
      $vdLogger->Error("StartServercommand:$self->{command} is not defined"
                                                          . Dumper($self));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $tries = 1;
   while ($tries--) {
      ($pid, $processName) = $self->IsPortOccupied($sessionID);
      if ((defined $pid) && ($pid =~ m/FAILURE/i)) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif (defined $pid) {
         my $oldPort = $sessionID->{'sessionport'};
         if($self->{command} =~m/$processName/i){
            # For multicast report tool, only one server to be launched.
            $vdLogger->Info("$processName already running on $oldPort on " .
                                                               "$controlIP");
            $sessionID->{'serveralreadyrunning'} = "yes";
            return SUCCESS;
         } else {
            # In case a given port is occupied by some other process we will
            # try on next available port
            $vdLogger->Trace("$oldPort on $controlIP is already occupied ".
                             "by $processName");
         }
         $sessionID->{'sessionport'} = $sessionID->ReadAndWritePort($oldPort);
         my $newPort = $sessionID->{'sessionport'};
         $vdLogger->Info("Trying to start $sessionID->{'toolname'} ".
                         "server on port:$newPort on $controlIP");
         # Replacing the old port with new one.
         $self->{testOptions} =~ s/$oldPort/$newPort/g;
         $tries++;
      } else {
         last;
      }
   }

   $command = "$self->{command} $self->{testOptions}";
   my $os = $sessionID->{'server'}->{os};
   $command =~ s/\s+$//g; # remove space at the end of the command

   $self->{'outputFile'} =  $self->GetOutputFileName($os);
   # push the filename in to scratchFiles array, so that they can be
   # deleted during cleanup
   push(@{$self->{scratchFiles}}, $self->{outputFile});

   $result = $self->{staf}->STAFAsyncProcess($controlIP, $command,
                                             $self->{outputFile});
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{childHandle} = $result->{handle};
   $vdLogger->Info("Launching traffic server ($command) on $controlIP");
   $vdLogger->Trace("The sleep is required for the server to " .
                    "initialize completely, otherwise it fails with" .
                                                " Broken pipe error.");
   sleep(SLEEP_AFTER_SERVER_START);
   $self->{childHandle} = $result->{handle};
   return SUCCESS;
}


########################################################################
#
# StartClient --
#       Start client of tool on the targetHost to via local testIP
#       Execute self->{BuildCmd} on the targetHost with testOptions
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
   my $sessionID = shift;

   if ($self->{McastMethod} !~ m/(quit)/i) {
      my $dstfile = MCAST_CONFIG_FILE;
      open(FILE, ">", $dstfile);
      print FILE "[mcast_task1]\n";
      print FILE "method = " . $self->{McastMethod} . "\n";
      print FILE "interface = " . $self->{McastInterface} . "\n";
      print FILE "family = " . $self->{McastIpFamily} . "\n";
      print FILE "group_address = " . $self->{McastGroupAddr} . "\n";
      if (defined $self->{McastSourceAddrs}) {
          print FILE "source_addr_array = " . $self->{McastSourceAddrs} . "\n";
      }
      close (FILE);

      my $result;
      $result = $self->{staf}->STAFFSCopyFile(
                                       MCAST_CONFIG_FILE,
                                       MCAST_CONFIG_FILE,
                                       $sessionID->{mcIP},
                                       $sessionID->{server}->{'controlip'});
      if ($result ne 0) {
         $vdLogger->Error("Failed to copy mcast config file to server vm");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   return $self->SUPER::StartClient($sessionID);
}


###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool.
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
###############################################################################

sub ToolSpecificJob
{
   return SUCCESS;
}


########################################################################
#
# IsToolServerRunning --
#       Overrides the parent method.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS - in case tool server is running
#       FAILURE - in case of error.
#
# Side effects;
#       none
#
########################################################################

sub IsToolServerRunning
{

   my $self = shift;
   my $sessionID = shift;

   if ((defined $sessionID->{'serveralreadyrunning'}) &&
        $sessionID->{'serveralreadyrunning'} eq "yes") {
      $vdLogger->Debug("serveralreadyrunning is yes");
      return SUCCESS;
   }

   return $self->SUPER::IsToolServerRunning($sessionID);
}


########################################################################
# Stop --
#       Overwrite Overrides the parent method, server may be terminated
#       by launching client with option '-q',
#              mcast_tool.py -c -q [-H ip] [-p port]
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       none
#
########################################################################

sub Stop
{
   return SUCCESS;
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
#       sync as mcast_tool should be executed in sync mode.
#
# Side effects;
#       none
#
########################################################################

sub GetLaunchType
{
   return "sync";
}

1;
