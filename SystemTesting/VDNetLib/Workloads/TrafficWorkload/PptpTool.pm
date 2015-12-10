########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::PptpTool;
my $version = "1.0";


#This is pptp tool generate GRE packets.
#We have to run pptpd server in one vm and pppd
#in another vm as client to generate the packets

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
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);


use constant BINARY_PPTP_SERVER => "pptpd";
use constant BINARY_PPTP_CLIENT => "pppd";


########################################################################
#
# new --
#       Instantiates PPTP  client or server object
#
# Input:
#       none
#
# Results:
#       returns object of pptptool class(in either client or server
#       mode)
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
#       Returns the pptp binary depending on win, esx or linux and
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

   if ($os =~ m/linux|mac|darwin/i) {
      if ($self->{'mode'} =~ m/server/i ) {
         return BINARY_PPTP_SERVER;
      } else {
         return BINARY_PPTP_CLIENT;
      }
   } 
    else {
      $vdLogger->Error("PPTP binary requested for unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

}

########################################################################
#
# GetToolOptions -
#       Start the server
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

   if ($self->{'mode'} =~ m/(server)/i ) {
              return " restart ";
           }
   return 0;
}



########################################################################
#
# StartClient --
#       Start client 
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
      $vdLogger->Error("VPN Server Down and can not start VPN client");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $testOptions = " call provider logfd 2 nodetach debug dump ";
    #Now working on the client part
   $command = "$self->{command} $testOptions";
   $vdLogger->Info("Executing VPN command to connect the server  client($self->{command}) on $controlIP");
   $vdLogger->Info("With testoptions: $testOptions");
   $result = $self->{staf}->STAFSyncProcess($controlIP, $command);
   $vdLogger->Info("The result output :" .  Dumper($self->{result}));
   if (($result->{rc} == 1) || ($result->{exitCode} == 16)) {
      #VDSetLastError("ESTAF");
      $vdLogger->Error("The client failed to start");
      return "FAIL";
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

   $testOptions = " restart"; 
   $command = "$self->{command} $testOptions ";
   $vdLogger->Info("Launching VPN  server($self->{command}) on $controlIP");
   $vdLogger->Info("With testoptions: $testOptions");
   $result = $self->{staf}->STAFSyncProcess($controlIP, $command);
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("$self->{command} $testOptions unable to start the VPN server");
      return FAILURE;
   }else {
         $vdLogger->Info(" VPN  server is running");
         return SUCCESS;
   }
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



#################################################################
#  ToolSpecificJob -
#     
#      As there is nothing specific with this tool,override the
#      Parent method. 
#
#
################################################################
sub ToolSpecificJob
{

return SUCCESS;

}

########################################################################
#
# GetLaunchType --
#       Returns launch type of process.
#
# Input:
#       none
#
# Results:
#       uses the constant CLIENT_LAUNCH_TYPE
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
#       none.
#
# Results:
#       none.
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
# Stop-
#        Nothing to be done
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
#       Parses for vpn interfaces
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
   my $ppp0 = "";
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

   $control_ip = $session->{client}->{controlip};


   $command = "ifconfig | grep -i ppp0 ";
   $ret = $self->{staf}->STAFSyncProcess($control_ip, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      return "FAIL";
   } else {
       $vdLogger->Info("Stdout of ifconfig to check ppp interface".
                           "\n$self->{stdout}");
 
      $vdLogger->Info("Pass to finish  test");
      return "PASS";
   }
}



1;
