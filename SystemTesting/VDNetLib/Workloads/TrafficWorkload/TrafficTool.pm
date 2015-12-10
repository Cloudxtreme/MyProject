#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Workloads::TrafficWorkload::TrafficTool;
my $version = "1.0";

#
# 1) It acts as an interface to outside world for using traffic tools
# 2) Interface that any traffic tool must adhere in order to work with vdNet
# automation
# 3) Chooses appropriate tool for the given session based on the supported
# traffic knowledge provided by the child tool itself.
# 4) Acts as a parent to various traffic tool so that generic methods are
# implemented by parent and child only need to implement methods
# which are specific that child.
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::GlobalConfig qw($vdLogger IP_REGEX);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::TestData::TestConstants;

# Keep these lines as they help in debugging. The issue being When you make
# some change in NetperfTool and it has error doing eval NetperfTool at
# runtime doesnt give proper error message. Just keep these lines as they
# help in debugging.
use VDNetLib::Workloads::TrafficWorkload::NetperfTool;
use VDNetLib::Workloads::TrafficWorkload::IperfTool;
use VDNetLib::Workloads::TrafficWorkload::PingTool;
use VDNetLib::Workloads::TrafficWorkload::ArpPingTool;
use VDNetLib::Workloads::TrafficWorkload::TcpreplayTool;
use VDNetLib::Workloads::TrafficWorkload::MacofTool;
use VDNetLib::Workloads::TrafficWorkload::NmapTool;
use VDNetLib::Workloads::TrafficWorkload::FragrouteTool;
use VDNetLib::Workloads::TrafficWorkload::McastTool;
use VDNetLib::Workloads::TrafficWorkload::LighttpdTool;
use VDNetLib::Workloads::TrafficWorkload::ScapyTool;

# Possbile values "async" and "sync"
use constant CLIENT_LAUNCH_TYPE => "async";

# For some OSes 60 is minimum wait time before quering the handle of process
use constant WAIT_TIMEOUT => 60;

our $esxConnectionState;
#our @scratchFiles;

###############################################################################
#
# new -
#       This package acts as a parent class of all traffic tools and creates
#       object of child classes of this module. It does so
#       by providing a common interface for object creation and object use.
#       This class decides which tool to invoke and in which mode. Makes a
#       request to the child tool for instantiating its object.
#
# Input:
#       Object of Session class - Session ID (required)
#       Instance number - A counter which keeps track of how many
#                         parallel clients this server has.
#
# Results:
#       SUCCESS - A pointer to child instance/object of TrafficTool is placed
#                 in session hash and SUCCESS is returned.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my $sessionID = shift;
   my $instance = shift;
   if (not defined $sessionID || $sessionID eq "" || not defined $instance) {
      $vdLogger->Error("One or more parameter missing in ".
                       "new of TrafficTool");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Order in which tools will be tried out. Array is popped thus netperf
   # will be tried first.
   # Please make sure that Netperf is the default tool.
   # NOTE: All new tools should be prepended to this
   # array instead of appending.
   my @OrderofTools = qw(Scapy Lighttpd Mcast Fragroute ArpPing Macof Nmap PktInjector Tcpreplay
			 Spirent Ping Iperf Netperf);

   # When in Server mode it takes undef, (unless user has explicity mentioned
   # which tool to use) tries out various tools for this
   # session. For client mode, server must have already decided which
   # tool to use.
   my $toolName;
   if (defined $sessionID->{'toolname'} && $sessionID->{'toolname'} ne "") {
      $toolName = $sessionID->{'toolname'};
   } else {
      $toolName = "";
   }

   # Check if the instance0 exists in server key of session ID object, if
   # not, the request is for server else its for client instance.
   my $toolMode = undef;
   if (not defined $sessionID->{'server'}->{'instance0'}) {
      $toolMode = "server";
   } else {
      $toolMode = "client";
   }

   my $attrs  = {
      mode    => $toolMode,
      testOptions =>  "",
      pid => undef,
      scratchFiles => $sessionID->{sessionscratchfiles},
      outputFile => undef,
      instance => $instance,
   };

   # Reusing the staf handle from testbed. Traffic modules pass
   # on the handle to all packages.
   # If does not exists, create it.
   $attrs->{staf}  = $sessionID->{staf};
   if (not defined $attrs->{staf}) {
      my $options;
      $options->{logObj} = $vdLogger;
      $attrs->{staf} = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $attrs->{staf}) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # Check if a specific ToolName is requested in Session ID, if not,
   # then first try with Netperf. Now netperf module will see if
   # the requested traffic is unsupported, if unsupported it will reject
   # object creation.Then try with iperf.
   # Each child class module(tool) will maintain what it supports.
   my $childObj;
   if ($toolName ne "") {
      # Below check helps in two cases 1) This catches if the tool mentioned
      # is the one supported by vdNet. 2) In case User specifies a toolName
      # with different case there wont be problem as we take value from array.
      # This helps as tool module's name (NetperfTool) is decided at run time.
      foreach my $tool (@OrderofTools) {
         if (lc($toolName) eq lc($tool)) {
            $toolName = $tool;
         }
      }
      $childObj = $class->CreateToolChild(toolName => $toolName,
                                          toolMode => $toolMode,
                                          sessionID =>$sessionID,
                                          attrs => $attrs);
   } else {
   # Try these tools in the order of @OrderofTools array.
      while(@OrderofTools) {
         my $toolOfPreference = pop(@OrderofTools);
         $childObj = $class->CreateToolChild(toolName => $toolOfPreference,
                                             toolMode => $toolMode,
                                             sessionID => $sessionID,
                                             attrs => $attrs);
         if ($childObj ne 0) {
            $sessionID->{'toolname'} = $toolOfPreference;
            # Break out of loop as we found which tool to use for this
            # session's traffic. No more tries.
            last;
         } else {
            $vdLogger->Trace("$toolOfPreference didnt qualify for this ".
                             "traffic. Trying next tool ...");
         }
      } # end of while loop
   } # end of else


   if (defined $childObj && $childObj ne 0) {
      my ($key, $currentTestOption, $currentMachineHandle);
      $currentMachineHandle = $sessionID->{$toolMode};
      # Place the pointer of this tool object in current Session's machine pair
      # E.g. toolserver object pointer is place in Session->Server
      $currentMachineHandle->{'instance'. $instance} = $childObj;

      # Build the path and append binary to that path to run the tool.
      if ($childObj->BuildToolCommand(
                         os => $currentMachineHandle->{'os'},
                         arch => $currentMachineHandle->{'arch'}
                                     ) ne SUCCESS) {
         $vdLogger->Error("BuildToolCommand didnt return Success".
                          Dumper($childObj));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # An issue with the ping command in Mac OSX is that, if any of the traffic
      # parameters are give after the -S parameter (it binds the traffic to a
      # source and sink) then it gives a wrong usage error. In the current code
      # however, the parameters are processed as they are received from the hash.
      # Therefore in order to solve this, we are saving the '-S' parameter to
      # append to the rest of the command at the end.
      my $srcBind = "";

      # For each key in session convert the key into something which the tool
      # understands. E.g. Netperf understands localsendsocketsize as "-s 54"
      foreach $key (keys %$sessionID) {
         $currentTestOption = $childObj->GetToolOptions(
                                                 sessionkey => $key,
                                                 sessionID => $sessionID);
        if ($currentTestOption ne 0) {
           if($currentTestOption =~ m/-S|-I/
              && $currentMachineHandle->{'os'} =~ m/mac|darwin/i) {
              $srcBind = $currentTestOption;
           } else {
              if($childObj->AppendTestOptions($currentTestOption) eq FAILURE) {
                 $vdLogger->Warn("AppendTestOptions returned failure");
              }
           }
        }
      }

      # The -I parameter is appended to the rest of the command at the end.
      if(($srcBind ne "") && ($childObj->AppendTestOptions($srcBind)
                              eq FAILURE)) {
         $vdLogger->Warn("AppendTestOptions returned failure");
      }

      # Hook to perform workaround just before launching server/client
      # This would be an empty method in Parent. Child can implement this
      # method and can perform any task specific to that tool E.g. Copying
      # the binaries to c:\Tools on windows and launching the command from
      # that location (Samba issue faced in Netperf)
      if ($childObj->ToolSpecificJob($sessionID) ne SUCCESS) {
         $vdLogger->Error("ToolSpecificJob didnt return Success");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($childObj->Start($sessionID) ne SUCCESS) {
         $vdLogger->Error("Start method didnt return Success");
         $vdLogger->Debug(Dumper($childObj));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
      return SUCCESS;
      }
   } else {
      $vdLogger->Error("Unable to create a child tool class for this ".
                       "session of traffic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

}


###############################################################################
#
# CreateToolChild -
#       Creates object of child classes of TrafficTool module
#       Copies the keys to this child in case of success and blesses the
#       self with child object so that we can call methods on it.
#       Checks if that child supports the traffic we want
#       Report false if the child does not support so that we can try with
#       some other tool.
#
# Input:
#       toolName (required)
#       toolMode (required)
#       attributes (required)
#       Object of Session class - Session ID (required)
#
# Results:
#       A child instance/object of TrafficTool
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CreateToolChild
{
   my $self    = shift;
   my %args  = @_;
   my $toolName = $args{'toolName'};
   my $toolMode = $args{'toolMode'};
   my $sessionID = $args{'sessionID'};
   my $attrs = $args{'attrs'};

   if (not defined $toolName || not defined $toolMode || not defined $sessionID ||
      not defined $attrs) {
      $vdLogger->Error("One or more parameter missing in ".
                       "CreateToolChild method".Dumper($self));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # All the tools package name should adhere to the standard name used here.
   # E.g NetperfTool, IperfTool.
   my $childObjType = "VDNetLib::Workloads::TrafficWorkload::"."$toolName"."Tool";
   eval "require $childObjType";

   $self = $childObjType->new(mode => $toolMode);
   if (defined $self){
      my $key;
      foreach $key (keys %$attrs) {
         $self->{$key} = $attrs->{$key};
      }
      bless $self, $childObjType;
      # Check if this tool supports the traffic in this session
      # Dont check for client, only server can decide this
      if ($toolMode =~ m/Server/i) {
         my $key;
         foreach $key (keys %$sessionID) {
            if ($self->SupportedKeys($key, $sessionID->{$key}) eq 0) {
               return 0;
            }
         }
      }
   } else {
      $vdLogger->Error("Unable to create child object of $toolName" .
                       Dumper($self));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $self;
}


###############################################################################
#
# BuildToolCommand -
#       This method builds the client and server command based on the
#       respective mode.
#       1. Based on the OS, get the binariespath from VDNetLib::GlobalConfig
#       2. Set command to the netperf/toolserver path
#
# Input:
#       port (required)
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

sub BuildToolCommand
{
   my $self    = shift;
   my %args  = @_;
   my $arch = $args{'arch'};
   my $os = $args{'os'};

   if (not defined $os || not defined $arch) {
      $vdLogger->Error("Cannot proceed without OS or Arch parameter ".
                       "in BuildToolCommand.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ((not defined $self->{mode}) ||
       (!(($self->{mode} !~ m/server/i) ||
       ($self->{mode} !~ m/client/i)))) {
      $vdLogger->Error("BuildCmd: Instantiate the object with correct mode" .
                       "(client or server)");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($globalConfigObj, $binpath, $binFile, $path2Bin);
   $globalConfigObj = new VDNetLib::Common::GlobalConfig;
   if ($os =~ m/linux/i) {
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      $path2Bin = "$binpath" . "$arch/linux/";
      $binFile = $self->GetToolBinary($os);
      $self->{command}  = $path2Bin . $binFile;
   } elsif ($os =~ m/mac|darwin/i) {
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_MAC);
      $path2Bin = "$binpath" . "$arch/mac/";
      $binFile = $self->GetToolBinary($os);
      $self->{command}  = $path2Bin . $binFile;
   } elsif ($os =~ m/win/i) {
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $path2Bin = "$binpath" . "$arch\\\\windows\\\\";
      $binFile = $self->GetToolBinary($os);
      $self->{command}  = $path2Bin . $binFile;
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      $binpath = $globalConfigObj->BinariesPath(VDNetLib::Common::GlobalConfig::OS_ESX);
      # $arch returns x86_64 for esx
      $path2Bin = "$binpath" . "x86_32/esx/"; # TODO - remove hard-coding of arch
                                              # There are no binaries under
                                              # x86_64 for esx/vmkernel either.
                                              # Check with gaggarwal or
                                              # hchilkot
                                              #
      $binFile = $self->GetToolBinary($os);
      $self->{command}  = $path2Bin . $binFile;
   } else {
      $vdLogger->Error("Unknown OS:$os for building ToolCommand");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Trace("Built command $self->{command} for os:$os");
   return SUCCESS;
}


###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool. As most of the tools in windows needs to be run
#       from the local temp directory this code copies the binary to local
#       dir in windows and then checks for presence of binary in both win
#       and linux.
#       If any children want to do something more or less than this he can
#       overridden this method to performs his own workarounds(if required)
#       Parent calls the hook before calling start on server/client thus
#       will run the client/server with this change.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
###############################################################################

sub ToolSpecificJob
{
   ## TODO:Check if binary is present on c:\tool before copying blindly
   my $self    = shift;
   my $sessionID  = shift;
   my $os = $sessionID->{$self->{'mode'}}->{'os'};
   my $controlIP = $sessionID->{$self->{'mode'}}->{'controlip'};
   my $interface = $sessionID->{$self->{'mode'}}->{'interface'};
   my $netstack = $sessionID->{$self->{'mode'}}->{'netstack'};
   my $result;

   if ($os =~ m/^win/i) {
      my $winLocalDir =  VDNetLib::Common::GlobalConfig::GetLogsDir($os);
      my $binary = $self->GetToolBinary($os);

      ## TODO: Ask globalCOnfig for temp directories on OSes AND Use staf's copy service.
      my $wincmd = "\"my \$localToolsDir=\'$winLocalDir\';".
                   "my \$ns = \'$winLocalDir$binary\';".
                   "my \$src = \'$self->{command}\';".
                   "( ( -d \$localToolsDir )||(mkdir \$localToolsDir ) ) && ".
                   "(`copy \$src \$localToolsDir`);((-d \'c:\\temp\') || ".
                   "(mkdir \'c:\\temp\') )\"";

      my $command = "perl -e " . $wincmd;
      $result = $self->{staf}->STAFSyncProcess($controlIP,
                                                  $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $self->{command}  = $winLocalDir . $self->GetToolBinary($os);
      my $temp = $self->{command};
      $temp =~ s/\\\\/\\/g;
      push(@{$self->{scratchFiles}}, $temp);
      $vdLogger->Debug("command is changed to $self->{command} for os:$os");
   }

   $result = $self->{staf}->IsFile($controlIP, $self->{command});
   if (not defined $result) {
      $vdLogger->Error("File:$self->{command} not present on $controlIP");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } elsif($result ne 1) {
      $vdLogger->Error("File:$self->{command} not present on $controlIP");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # Incase we need to run tool on any other netstack instance other
   # the default, append the ++netstack parameter to the tool.
   #
   if ($os =~ /(esx|vmkernel)/i) {
      if ($netstack !~ /defaultTcpipStack/i) {
         my $command = $self->{command};
         $self->{command} = $command." ++netstack=$netstack";
         $vdLogger->Debug("$command would be run on netstack $netstack");
      }
   }

   # In case of multicast test on ESX we need to add a static route
   # otherwise the traffic will not flow.
   # If src os is esx and test is multicast then add this statis route
   # ~ # esxcfg-route -a 239.0.0.0/8 192.168.0.141
   # Adding static route 239.0.0.0/8 to VMkernel
   # For ipv6
   # ~ # esxcfg-route -f V6 -a ff39::/16 2001:bd6::c:2957:176
   # Adding static route ff39::/16 to VMkernel
   if ($os =~ /(esx|vmkernel)/i &&
      ((defined $sessionID->{routingscheme} &&
        $sessionID->{routingscheme} =~ /multicast/i) ||
       (defined $sessionID->{multicasttimetolive} &&
        $sessionID->{multicasttimetolive} ne ""))) {

      my $testIP = $sessionID->{$self->{'mode'}}->{'testip'};
      my $command;
      if ((defined $sessionID->{l3protocol}) &&
          ($sessionID->{l3protocol} =~ m/ipv6/i)) {
         $command = "esxcfg-route -f V6 -a " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                                                               " $testIP ";
      } else {
         $command = "esxcfg-route -a " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV4_ROUTE_DEST .
                                                               " $testIP ";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP,$command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stdout} =~ /Adding static route/i) {
         $vdLogger->Trace("$result->{stdout} in ($controlIP)");
      } else {
         $vdLogger->Warn("Not able to execute cmd $command $testIP on esx");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   }

   # In case of multicast test on linux vm we need to add a static route
   # otherwise the traffic will not flow.
   # If src os is linux or mac and test is multicast then add this statis route
   # ~ # route add -net 239.0.0.0/8 eth0
   # Adding static route 239.0.0.0/8 to linux test interface
   # For ipv6
   # ~ # route add -A inet6 ff39::/16 eth0
   # Adding static route ff39::/16 to linux test interface
   if ($os =~ /linux|mac/i &&
      ((defined $sessionID->{routingscheme} &&
        $sessionID->{routingscheme} =~ /multicast/i) ||
       (defined $sessionID->{multicasttimetolive} &&
        $sessionID->{multicasttimetolive} ne ""))) {

      my $command;
      if ((defined $sessionID->{l3protocol}) &&
          ($sessionID->{l3protocol} =~ m/ipv6/i)) {
         if ($os =~ /linux/i) {
            # Delete default route for multicast from local routing table.
            my $controlInterface = $self->{staf}->GetGuestInterfaceFromIP($controlIP);
            my $delDefaultRouteCmd = "ip -6 route del " .
                VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                " dev $controlInterface table local";
            $result = $self->{staf}->STAFSyncProcess($controlIP,$delDefaultRouteCmd);
            if ($result->{rc} != 0 || $result->{exitCode} != 0) {
               if($result->{stderr} =~ /No such process/i) {
                  $vdLogger->Trace("Route does not exist on $controlIP");
                  $vdLogger->Trace(Dumper($result));
                  return SUCCESS;
               }
               $vdLogger->Warn("Deleting route failed $controlIP:$result->{stderr}");
            }
         }
         $command = "route add -A inet6 " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                                                            " $interface ";
      } else {
         $command = "route add -net " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV4_ROUTE_DEST .
                                                            " $interface ";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP,$command);
      if ($result->{rc} != 0 || $result->{exitCode} != 0) {
         if($result->{stderr} =~ /File exists/i) {
            $vdLogger->Trace("Route already exists on $controlIP ");
            $vdLogger->Trace(Dumper($result));
            return SUCCESS;
         }
         $vdLogger->Error("Adding route failed $controlIP:$result->{stderr}");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   return SUCCESS;
}




########################################################################
#
# Start --
#       Calls StartServer if the mode of the object is set to server else
#       calls StartClient
#
# Input:
#       Object of Session class - Session ID (required)
#
# Results:
#       Result from StartServer or StartClient method.
#
# Side effects:
#       Fills in the global TDS hash everytime it
#       is called for a test category.
#
########################################################################

sub Start
{
   my $self = shift;
   my $sessionID = shift;

   $vdLogger->Trace("Starting traffic tool with mode: $self->{mode}");
   if ($self->{mode} =~ m/server/i) {
      return $self->StartServer($sessionID);
   } elsif ($self->{mode} =~ m/client/i) {
      return $self->StartClient($sessionID);
   } else {
      $vdLogger->Error("Inappropriate mode. Please set appropriate mode".
                       $self->{mode});
      VDSetLastError("EINVALID");
      return FAILURE;
   }
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
   my ($command, $opts, $result);
   my $controlIP = $sessionID->{'client'}->{'controlip'};

   # We give the liberty to the tool to be invoked in async or sync mode.
   my $launchType = $self->GetLaunchType();
   $launchType = "async" if not defined $launchType;

   $vdLogger->Trace("Starting traffic tool client in mode: $launchType");

   if (not defined $self->{command}) {
      $vdLogger->Error("StartClient: command is not defined".Dumper($self));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Trace("Checking health of server before launching client...");
   if ($self->IsToolServerRunning($sessionID) eq FAILURE) {
      $vdLogger->Error("Traffic Server Down. Cannot proceed...");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Now working on the client part
   my $instance = $self->{instance};
   $command = "$self->{command} $self->{testOptions} ";
   if($instance == 1) {
      $vdLogger->Info("Launching traffic client-". $instance .
                   " ($self->{command}) on $controlIP");
      $vdLogger->Info("with testoptions: $self->{testOptions}");
   } else {
      $vdLogger->Info("Launching traffic client-". $instance .
                   " with same testoptions");
      $vdLogger->Trace("testoptions for $instance are: $self->{testOptions}");
   }

   if ($launchType =~ /async/i) {
      my $os = $sessionID->{'client'}->{os};
      $self->{'outputFile'} =  $self->GetOutputFileName($os);

      # push the filename in to scratchFiles array, so that they can be
      # deleted during cleanup
      push(@{$self->{scratchFiles}}, $self->{outputFile});
      $result = $self->{staf}->STAFAsyncProcess($controlIP,
                                                $command,
                                                $self->{outputFile});
   } else {
      $result = $self->{staf}->STAFSyncProcess($controlIP,
                                               $command);
   }

   # For scenario like ping destination unreachable, $result->{rc}=0,
   # while $result->{exitCode}=1. We should not return FAILURE for
   # this kind of result. So only checks $result->{rc}
   #
   if ($result->{rc}) {
      $vdLogger->Error("Command $command failed on $controlIP : " .
                 Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($launchType =~ /async/i) {
      # if the mode is async, save the pid
      $self->{childHandle} = $result->{handle};
      $result = $self->{staf}->GetProcessInfo($controlIP, $result->{handle});
      if ($result->{rc}) {
         if(defined $result->{endTimestamp}) {
            $vdLogger->Error("Client terminated as endtimestamp is defined : " .
                       Dumper($result));
         }
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $self->{pid} = $result->{pid};
      return SUCCESS;
   } else {
      $self->{stdout} = $result->{stdout};
      $self->{stderr} = $result->{stderr};
      return SUCCESS;
   }
}


########################################################################
# StartServer --
#       Start toolserver on the targetHost
#
#       1. Check if toolserver is running on the port specified, on the
#          targetHost by calling IsPortOccupied
#       3. If not, start toolserver in async mode, get the pid by quering
#          the handle, then add 1 to pid if it is linux else return error
#
# Input:
#       Object of Session class - Session ID (required)
#
# Results:
#       Stores the result in self->result
#       FAILURE - in case of error
#
# Side effects:
#       Stores the handle of the toolserver process in the
#       $self->childHandle
#       Stores the PID of the toolserver process in $self->{pid}
#
########################################################################

sub StartServer
{
   my $self = shift;
   my $sessionID = shift;
   my ($command, $result, $pid, $processName);
   my $controlIP = $sessionID->{'server'}->{'controlip'};

   $vdLogger->Trace("Starting traffic tool server.");
   if (not defined $self->{command}) {
      $vdLogger->Error("StartServercommand:$self->{command} is not defined"
                       .Dumper($self));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Keep trying for available ports in case toolserver is already
   # running on this port. We will not use toolserver which we didn't
   # create as it might end anytime.
   # Destroying toolserver in Destructor makes sure that their are no
   # zombie toolserver lying around.
   my $tries = 1;
   while ($tries--) {
      ($pid, $processName) = $self->IsPortOccupied($sessionID);
      if ((defined $pid) && ($pid =~ m/FAILURE/i)) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif (defined $pid) {
         my $oldPort = $sessionID->{'sessionport'};
         # This is to cover multicast when more than one machines are involved.
         # reuserport helps in scenario where SUT is server for multiple clients
         # instead of starting multiple servers we use the same server to serve
         # multiple clients on various helper machines.
         if ((defined $sessionID->{reuseport} &&
              $sessionID->{reuseport} =~ m/yes/i) &&
              ($sessionID->{routingscheme} =~ m/multicast/i ||
               $sessionID->{multicasttimetolive} ne "" ||
               $sessionID->{udpbandwidth} ne "" )) {
            if($self->{command} =~m/$processName/i){
               # For inbound session server is already running on that port
               # for all the clients.
               $vdLogger->Info("$processName already running on $oldPort on ".
                               "$controlIP");
               last;
            } else {
               # In case a given port is occupied by some other process we will
               # try on next available port
               $vdLogger->Trace("$oldPort on $controlIP is already occupied ".
                                "by $processName");
            }
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
   # XXX(salmanm): Following space replacement with single space will be
   # problematic if any of the options provided contains spaces that needs to
   # be relayed to the traffic tool being ran.
   $vdLogger->Debug("Command before removing spaces: $command");
   $command =~ s/\s{2,}/ /g;  # Remove extra spaces from the command.
   $vdLogger->Debug("Command after removing spaces: $command");
   $self->{'serverCommand'} = $command;


   #
   # On windows, run toolserver as an asynchrous process. The process has to be
   # started without a shell in order to get the actual process id of the
   # toolserver.exe instead of cmd.exe (which will be invoked if process is
   # invoked with default options)
   #
   my $opts;
   if($sessionID->{'server'}->{os} =~ m/^win/i) {
      $opts->{NoShell} = 1;
   } else {
      $opts = undef;
   }

   $self->{'outputFile'} =  $self->GetOutputFileName($os);
   # push the filename in to scratchFiles array, so that they can be
   # deleted during cleanup
   push(@{$self->{scratchFiles}}, $self->{outputFile});

   $result = $self->{staf}->STAFAsyncProcess($controlIP, $command,
                                             $self->{outputFile}, $opts);
   if (not defined $result || ref($result) ne 'HASH' || $result->{rc}) {
      $vdLogger->Error("Expected a result hash with RC 0, got:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{childHandle} = $result->{handle};
   $vdLogger->Trace("The 5 sec sleep is required for the server to initialize completely,".
                   "otherwise it fails with Broken pipe error.");
   sleep(5);
   $self->{childHandle} = $result->{handle};
   my $procInfo = $self->{staf}->GetProcessInfo($controlIP, $self->{childHandle});

   if (not defined $result || ref($result) ne 'HASH' || $result->{rc}) {
      $vdLogger->Error("Expected a result hash with RC 0, got:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Launched traffic server ($command) on $controlIP with " .
                   "PID: $procInfo->{pid}");
   return SUCCESS;
}


########################################################################
# Stop --
#       Terminates toolserver process on the targetHost
#       1. Get the netstat output
#       2. if there are one or multiple toolservers are running then get
#          pid and port
#       3. if the port matches the  input argument port then return the
#          pid else return undef, in case of STAF errors return ESTAF
#
# Input:
#       Object of Session class - Session ID (required)
#
# Results:
#       pid in case it is found else undef
#       FAILURE - in case of error.
#
# Side effects:
#       none
#
########################################################################

sub Stop
{
   my $self = shift;
   my $sessionID = shift;
   my ($command,  $result);
   my $controlIP = $sessionID->{'server'}->{controlip};
   my $os = $sessionID->{'server'}->{os};
   my $interface = $sessionID->{$self->{'mode'}}->{'interface'};

   # Stope method is only for server. As, if you stop the server the client
   # stops on its own.
   if ($self->{mode} !~ m/server/i) {
      $vdLogger->Error("Stop method only applicable for Server mode" .
                       $self->{mode});
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $self->{childHandle}) {
      $vdLogger->Error("childHandle of process not defined for " .
                       $self->{mode});
      # Not setting any error as it might have been done somewhere else
      # and we dont want to overwrite that error stack.
      return FAILURE;
   }

   if (not defined $self->{staf}) {
      my $hash = {'logObj' => $vdLogger};
      $self->{staf} = new VDNetLib::Common::STAFHelper($hash);
      if(not defined $self->{staf}) {
         $vdLogger->Error("Is staf running on localhost? staf handle not ".
                          "created");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # GetProcessInfo returns:
   # PID of process on windows
   # PID of shell on linux and esx
   # On linux you can add a 1 to PID of shell as linux
   # launches it as next process
   # But on esx we are not sure of the pid. Thus we already store the pid
   # of the process when we do IsPortOccupied() in StartClient()

   if ($os !~ m/(esx|vmkernel)/i) {
      $result = $self->{staf}->GetProcessInfo($controlIP, $self->{childHandle});
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $self->{pid} = $result->{pid};
   }
   if (!$self->{pid}) {
      $vdLogger->Error("Stop $sessionID->{'toolname'} server process is ".
                       "called with invalid pid");
      $vdLogger->Debug(Dumper($self));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my @expectedReturnCode = (0);
   my @expectedExitCode = (0);
   if ($os =~ m/(linux)/i) {
      my $matchingProcs = $self->{staf}->STAFSyncProcess(
        $controlIP, "ps -ef | grep '$self->{serverCommand}'", undef, undef, 1);
      $vdLogger->Debug("Following processes will be killed:\n" .
                       $matchingProcs->{stdout});
      $command = "pkill -f '$self->{serverCommand}'";
      # XXX (salmanm): Even with STAF exit code 15, the actual process is killed
      # properly. Need to figure out what causes STAF command to terminate when
      # using pkill -f. I guess that since a subset of the command run by STAF
      # matches with that the one used by pkill, both STAF as well as the tool
      # are being terminated.
      @expectedExitCode = (15);
   } elsif ($os =~ m/^win/i) {
      $command = " TASKKILL /FI \"PID eq $self->{pid}\" /F";
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      $command = "kill -9 $self->{pid}";
   } elsif ($os =~ m/mac|darwin/i) {
      # In mac , when staf returns the process ID, it is always 2 less than the
      # actual process ID, and hence we should add 2 to the result.
      $self->{pid} = $self->{pid} +2 if $sessionID->{toolname} =~ /netperf/i;
      $command = " kill -9 $self->{pid} wait";
   }

   # Iperf server takes time to cleanup, even though in netstat it shows that
   # it has released that port. Thus if next workload is started
   # immediately and it tries to start server on that port it fails
   # saying that port is not available.
   # Thus giving time to iperf to cleanup. Or better approach would be
   # to ask user to use SleepBetweenCombos after iperf workload.
   #if($sessionID->{toolname} =~ m/iperf/i) {
   #   sleep(10);
   #}

   $vdLogger->Debug("Killing $sessionID->{'toolname'} server process with PID:".
                    $self->{pid} . " on $controlIP for flowID:$sessionID");
   $result = $self->{staf}->STAFSyncProcess(
        $controlIP, $command, undef, undef, 1, 'Error', \@expectedReturnCode,
        \@expectedExitCode);
   if ($result eq FAILURE or
       (defined $result->{stdout} && $result->{stdout} ne "") or
       (defined $result->{stderr} && $result->{stderr} ne "")) {
      # kill or pkill may return stdout/stderr in case of failure even if the
      # return code is 0, so checking for both stdout/stderr as well as STAF
      # command success here.
      $vdLogger->Error("Failed to kill command \"$self->{serverCommand}\"" .
                       "(PID: $self->{pid}) on $controlIP");
      if (ref($result) eq 'HASH' and $result->{stdout} ne "") {
        $vdLogger->Error("STDOUT: $result->{stdout}");
      }
      if (ref($result) eq 'HASH' and $result->{stderr} ne "") {
        $vdLogger->Error("STDERR: $result->{stderr}");
      }
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Doing route cleanup on linux vm when it is the server interface in
   # case of multicast traffic
   if ($os =~ /linux/i &&
      ((defined $sessionID->{routingscheme} &&
        $sessionID->{routingscheme} =~ /multicast/i) ||
       (defined $sessionID->{multicasttimetolive} &&
        $sessionID->{multicasttimetolive} ne ""))) {

      my $command;
      if ((defined $sessionID->{l3protocol}) &&
          ($sessionID->{l3protocol} =~ m/ipv6/i)) {
         if ($os =~ /linux/i) {
            # Add default route for multicast from local routing table.
            my $controlInterface = $self->{staf}->GetGuestInterfaceFromIP($controlIP);
            my $addDefaultRouteCmd = "ip -6 route add " .
                VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                " dev $controlInterface table local";
            $result = $self->{staf}->STAFSyncProcess($controlIP,$addDefaultRouteCmd);
            if ($result->{rc} != 0 || $result->{exitCode} != 0) {
               if($result->{stderr} =~ /File exists/i) {
                  $vdLogger->Trace("Route already exists on $controlIP ");
                  $vdLogger->Trace(Dumper($result));
                  return SUCCESS;
               }
               $vdLogger->Error("Adding route failed $controlIP:$result->{stderr}");
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
         $command = "route del -A inet6 " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                                                            " $interface ";
      } else {
         $command = "route del -net " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV4_ROUTE_DEST .
                                                            " $interface ";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP,$command);
      if ($result->{rc} != 0 || $result->{exitCode} != 0) {
          if($result->{stderr} =~ /No such process/i) {
            $vdLogger->Trace("Route does not exist on $controlIP");
            $vdLogger->Trace(Dumper($result));
            return SUCCESS;
         }
         $vdLogger->Warn("Deleting route failed $controlIP:$result->{stderr}");
      }
   }

   # Doing route cleanup on esx when it is the src interface in
   # case of multicast traffic
   $controlIP = $sessionID->{'client'}->{controlip};
   $os = $sessionID->{'client'}->{os};

   if ($os =~ /(esx|vmkernel)/i &&
      ((defined $sessionID->{routingscheme} &&
        $sessionID->{routingscheme} =~ /multicast/i) ||
       (defined $sessionID->{multicasttimetolive} &&
        $sessionID->{multicasttimetolive} ne ""))) {

      my $testIP = $sessionID->{$self->{'mode'}}->{'testip'};
      my $command;
      if ((defined $sessionID->{l3protocol}) &&
          ($sessionID->{l3protocol} =~ m/ipv6/i)) {
         $command = "esxcfg-route -f V6 -d " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                                                               " $testIP ";
      } else {
         $command = "esxcfg-route -d " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV4_ROUTE_DEST .
                                                               " $testIP ";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP,$command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($result->{stdout} =~ /Deleting static route/i) {
         $vdLogger->Trace("$result->{stdout} in ($controlIP)");
      } else {
         $vdLogger->Warn("Not able to delete route $command $testIP on esx");
      }
   }

   # Doing route cleanup on linux vm when it is the client interface in
   # case of multicast traffic
   if ($os =~ /linux/i &&
      ((defined $sessionID->{routingscheme} &&
        $sessionID->{routingscheme} =~ /multicast/i) ||
       (defined $sessionID->{multicasttimetolive} &&
        $sessionID->{multicasttimetolive} ne ""))) {

      my $command;
      if ((defined $sessionID->{l3protocol}) &&
          ($sessionID->{l3protocol} =~ m/ipv6/i)) {
         $command = "route del -A inet6 " .
             VDNetLib::TestData::TestConstants::MULTICAST_IPV6_ROUTE_DEST .
                                                             " $interface";
      } else {
         $command = "route del -net ".
             VDNetLib::TestData::TestConstants::MULTICAST_IPV4_ROUTE_DEST .
                                                             " $interface";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP,$command);
      if ($result->{rc} != 0 || $result->{exitCode} != 0) {
          if($result->{stderr} =~ /No such process/i) {
            $vdLogger->Trace("Route does not exist on $controlIP");
            $vdLogger->Trace(Dumper($result));

            return SUCCESS;
         }
         $vdLogger->Warn("Deleting route failed $controlIP:$result->{stderr}");
      }
   }

   return SUCCESS;
}


########################################################################
# GetResult --
#       Returns the previous run's result if it is netperf
#       return self->{result}
#
# Input:
#       Object of Session class - Session ID (required)
#       timeout in seconds (optional)
#
# Results:
#       FAILURE - in case of any execution error
#       FAIL - if expectations are not met
#       PASS/SUCCESS - if expectaitons are met.
#
# Side effects:
#       none
#
########################################################################

sub GetResult
{
   my $self = shift;
   my $sessionID = shift;
   my $timeout = shift;
   my $minExpResult = shift;
   my $maxThroughput = shift || undef;

   my $launchType = $self->GetLaunchType();
   my ($command, $result);

   if (not defined $sessionID) {
      $vdLogger->Error("sessionID parameter missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $controlIP = $sessionID->{'client'}->{controlip};

   # if the process is started in async mode then childhandle will be
   # defined, if so, check if the process is complete and if it is, copy
   # contents of the file then call GetThroughPut. Call GetThroughPut
   # directly in case the process was launched synchro.
   if ($launchType =~ /async/i) {
      if (not defined $self->{childHandle}) {
         $vdLogger->Error("Handle for $sessionID->{'toolname'} client ".
                          "not available". Dumper($self));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      my $testDuration = $sessionID->{testduration};
      # Check if the timout specifiied by user or test is draconian
      # if yes, override it.
      if ((not defined $timeout) || ($timeout < WAIT_TIMEOUT ||
         $timeout < $testDuration)) {
         $timeout = $testDuration + WAIT_TIMEOUT;
      }
      do {
         sleep(5);
         $timeout--;
         # If endTimeStamp is defined it means the process is already completed
         # if not then we wait for process to be completed.
         $result = $self->{staf}->GetProcessInfo($controlIP, $self->{childHandle});
         if ($result->{rc}) {
            if (not defined $result->{endTimestamp}) {
               $vdLogger->Error("endTimeStamp not defined and rc != 0 for ".
                                "$self->{childHandle} on $controlIP in GetResult()");
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
      } while($timeout > 0 && (not defined $result->{endTimestamp}) != 0);

      if ($timeout == 0) {
          $vdLogger->Error("Hit Timeout=$testDuration min for ".
			                        "$self->{childHandle} on $controlIP. Still trying ".
			                        "to read stdout");
      }

      $self->{stdout} = $self->{staf}->STAFFSReadFile($controlIP,
                                                      $self->{outputFile});
      if (not defined $self->{stdout}) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of traffic client. File:$self->{outputFile} on ".
                          "$controlIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif(defined $self->{stdout} &&
              $self->{stdout} =~ m/(could not establish|connection refused)/i){
         $vdLogger->Error("Traffic failed with stdout:\n $self->{stdout}");
         # Debug output for netperf related failures.
         my $portRegex = '([0-9]+)';
         my $matchErrorString = "are you sure there is a netserver " .
                                "listening on " . IP_REGEX . " at port " .
                                "$portRegex?";
         if ($self->{stdout} =~ /$matchErrorString/) {
             my $serverIP = $sessionID->{'server'}->{controlip};
             my $port = $1;
             my $netstatCommand = "netstat -anp | grep $port";
             my $portStatusResult = $self->{staf}->STAFSyncProcess(
                $serverIP, $netstatCommand, undef, undef, 1);
             if ($portStatusResult eq FAILURE) {
                 $vdLogger->Warn("Unable to get the list of ports on the " .
                                 "server");
             } elsif ($portStatusResult->{stdout} eq "") {
                 $vdLogger->Info("No port ($port) found on $serverIP");
             } else {
                 $vdLogger->Info("Port(s) matching $port found on $serverIP " .
                                 "are:\n$portStatusResult->{stdout}");
                 $vdLogger->Warn("Did some other process acquired this " .
                                 "netserver port ($port) and cause the failure?");
             }

         }
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   my $throughputResult = $self->GetThroughput($sessionID,
                                               $minExpResult,
                                               $maxThroughput);
   #
   # Print the stdout of traffic if traffic fails else send it to log file
   #
   $self->PrintTrafficStdout($sessionID, $throughputResult);
   if ($throughputResult eq FAILURE ) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # now delete the file temporary file as we copied the contents to
   # stdout. Files won't be deleted in case throughput is FAILURE
   # In that case we will collects the files before calling
   # DelScratchFiles.
   $self->DelScratchFiles($sessionID, [$self->{outputFile}]);

   return $throughputResult;
}


########################################################################
# GetServerResult --
#       Returns the previous run's result from server side.
#
# Input:
#       Object of Session class - Session ID (required)
#       Minimum expected result - minExpResult (optional)
#       Maximum throughput      - maxThroughput (optional)
#       Maximum lost data rate  - maxLossRate (optional)
#
# Results:
#       FAILURE - in case of any execution error
#       SUCCESS - if expectations are met.
#
# Side effects:
#       none
#
########################################################################

sub GetServerResult
{
   my $self          = shift;
   my $sessionID     = shift;
   my $minExpResult  = shift;
   my $maxThroughput = shift || undef;
   my $maxLossRate   = shift || undef;

   my ($command, $result);

   if (not defined $sessionID) {
      $vdLogger->Error("sessionID parameter missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Only check result from server side for iperf multicast traffic.
   if (($sessionID->{toolname} !~ /iperf/i) &&
       ($sessionID->{routingscheme} !~ m/multicast/i)) {
      return SUCCESS;
   }
   my $controlIP = $sessionID->{'server'}->{controlip};

   # Server is always started in async mode then childhandle will be
   # defined, if so, check if the process is complete and if it is, copy
   # contents of the file then call GetThroughPut. Call GetThroughPut
   # directly in case the process was launched synchro.
   if (not defined $self->{childHandle}) {
      $vdLogger->Error("Handle for $sessionID->{'toolname'} server ".
                       "not available". Dumper($self));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{server}->{stdout} = $self->{staf}->STAFFSReadFile($controlIP,
                                           $self->{outputFile});
   if (not defined $self->{server}->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of traffic server. File:$self->{outputFile}".
                       " on $controlIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Debug("Server $controlIP stdout:\n" . $self->{server}->{stdout});
   my $throughputResult = $self->GetServerThroughput($sessionID,
                                                     $minExpResult,
                                                     $maxThroughput,
                                                     $maxLossRate);
   if ($throughputResult eq FAILURE ) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # now delete the file temporary file as we copied the contents to
   # stdout. Files won't be deleted in case throughput is FAILURE
   # In that case we will collects the files before calling
   # DelScratchFiles.
   $self->DelScratchFiles($sessionID, [$self->{server}->{outputFile}]);

   return SUCCESS;
}


########################################################################
# GetServerThroughput --
#       Parses stdout of traffic session and warns "low" if throughput
#       OR transactions per second is less than 1.
#
# Input:
#       Session ID (required)   - A hash containing session keys and
#                                  session values (required)
#       Minimum expected result - minExpResult (optional)
#       Maximum throughput      - maxThroughput (optional)
#       Maximum lost data rate  - maxLossRate (optional)
#
# Results:
#       FAILURE - in case of any execution error
#       SUCCESS - if expectations are met.
#
# Side effects;
#       none
#
########################################################################

sub GetServerThroughput
{
   my $self          = shift;
   my $sessionID     = shift;
   my $minExpResult  = shift;
   my $maxThroughput = shift || undef;
   my $maxLossRate   = shift || undef;

   if ($self->{mode} !~ /server/i) {
      $vdLogger->Error("Method is valid only for server mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (($sessionID->{toolname} !~ /iperf/i) and
       ($sessionID->{routingscheme} !~ m/multicast/i)) {
      $vdLogger->Error("Method is valid only for iperf multicast traffic.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $trafficToolServerStdOut = $self->{server}->{stdout};
   if (not defined $trafficToolServerStdOut) {
      $vdLogger->Error("Traffic tool server output is undefined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $thruputData = undef;
   my $lossRate = undef;
   my $dataUnit = undef;
   my @lines = split(/\n/, $trafficToolServerStdOut);
   my $nPattern = "[0-9]+\.?[0-9]*";

   # The line we are interested in has following format,
   # [ID] Interval     Transfer    Bandwidth      Jitter   Lost/Total Datagrams
   # [ 8] 0.0-10.0 sec 23.2 MBytes 19.5 Mbits/sec 0.107 ms 26/16573 (0.16%)
   # Bandwidth and Lost Rate will be matched.
   foreach my $line (@lines) {
      if ($line =~ /($nPattern)\s+(\S?)bits\/sec.*\Q(\E($nPattern)%\Q)\E/i) {
         $thruputData = $1;
         $dataUnit = $2 . "bits";
         $lossRate = $3;
         last;
      }
   }
   if (not defined $thruputData or not defined $lossRate) {
      $vdLogger->Error("Failed to parse stdout for server " .
                       "$sessionID->{'server'}->{controlip} ".
                       "to get throughput and lost Data");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Info("Server $sessionID->{'server'}->{controlip} result, " .
                         "throughoutput is $thruputData $dataUnit\/sec, ".
                         "lossRate is $lossRate%");

   if(not defined $maxLossRate){
      $maxLossRate = 10;
   }
   if(not defined $minExpResult){
      $minExpResult = 1;
   }
   # If minimum expected result is to be ignored i.e. "minExpResult => IGNORE",
   # throughput of the traffic session need not be calculated
   if ($minExpResult =~ /IGNORE/i) {
      $vdLogger->Info("Ignoring traffic verification as per test requirement" .
                      " for server $sessionID->{'server'}->{controlip}");
      return SUCCESS;
   }

   # As the user give the expected max throughput in Mega unit
   # lets convert everything into Mega.
   if ($dataUnit =~ m/gbits/i){
      $thruputData = $thruputData * 1000;
   } elsif ($dataUnit =~ m/kbits/i) {
      $thruputData = $thruputData / 1000;
   }
   $dataUnit = "Mbits";

   if (int($thruputData) < $minExpResult) {
      $vdLogger->Info("Expected throughput: $minExpResult $dataUnit\/sec");
      $vdLogger->Error("server side throughput is low: " .
                            "$thruputData $dataUnit\/sec");
      return FAILURE;
   }
   if ((defined $maxThroughput) and (int($thruputData) > $maxThroughput)) {
      $vdLogger->Error("Server side throughput: $thruputData $dataUnit\/sec ".
                                "EXCEEDED maxThroughput: ".
                                "$maxThroughput $dataUnit\/sec ");
      return FAILURE;
   }
   # lossRate may be 0.xxxx%, four digits after the decimal point.
   # for example, a stdout from iperf multicast server looked like below,
   # [ 8] 0.0-10.0 sec 18.8 MBytes  15.8 Mbits/sec 0.325 ms 1/13410 (0.0075%)
   if (($lossRate - $maxLossRate) >= 0.0001) {
      $vdLogger->Error("Expected max loss rate is: $maxLossRate%, but server " .
                            "$sessionID->{'server'}->{controlip} actual loss " .
                            "rate is higher: $lossRate%");
      return FAILURE;
   }

   return SUCCESS;
}

########################################################################
#
# DelScratchFiles --
#       Delete if any scratch files are created in
#       VDNetLib::Common::GlobalConfig::GetLogsDir().
#       directory when netperf is launched in client mode
#       Reference to list of files that needs to be cleaned up
#       This argument is optional, when not given it uses the
#       complete list available in scratchFiles
#
# Input:
#       Object of Session class - Session ID (required)
#       list of files to be deleted  (optional)
#
# Results:
#       FAILURE in case of error
#       SUCCESS if file deletion goes well.
#
# Side effects:
#       None
#
########################################################################

sub DelScratchFiles
{
   my $self = shift;
   my $sessionID = shift;
   my $list = shift;
   my @filesToCleanup;
   my ($command, $result);

   if (not defined $sessionID) {
      $vdLogger->Error("sessionID parameter missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $controlIP = $sessionID->{'client'}->{controlip};

   if (defined $list) {
      @filesToCleanup = @$list;
   } else {
      @filesToCleanup = @{$self->{scratchFiles}};
   }

   foreach my $file (@filesToCleanup) {
      # skip undefined entries
      next if (not defined $file);
      if ($file eq '/') {
         $vdLogger->Error("Attempting to remove something under root system");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      if ($sessionID->{'client'}->{os} =~ /lin/i) {
         $command  = "rm -f $file";
      } else {
         $file =~  s/\\\\/\\/g;
         $command  = "del /Q $file";
      }
      $result = $self->{staf}->STAFSyncProcess($controlIP, $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } # end of for loop
   return SUCCESS;
}


########################################################################
# AppendTestOptions --
#       Appends the given string to self->{testOptions}
#
# Input:
#       String
#
# Results:
#       SUCCESS in case $self->{testOptions} is appended correctly.
#       FAILURE in case of error
#
# Side effects:
#       none
#
########################################################################

sub AppendTestOptions
{
   my $self = shift;
   my $option = shift;
   if (not defined $option || $option eq "") {
      $vdLogger->Error("option parameter missing in ".
                       "AppendTestOptions");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{testOptions} = $self->{testOptions} . " $option";
   return SUCCESS;
}


########################################################################
#
# IsPortOccupied --
#       This method is for finding if a trafficToolServer is already
#       running on that particular port. The reason we dont use already
#       running trafficToolServer is that it might have been started by
#       some other process and that process might terminate it. Thus every
#       session should start its own trafficToolServer. This method is
#       used to check before starting a trafficToolServer on a given port.
#       It can also be used to get the status of trafficToolServer
#       when any Iperf test fails.
#
# Algorithm:
#       1. Get the netstat output
#       2. if there are one or multiple trafficToolServers are running
#          then get pid and port
#       3. if the port matches the  input argument port then return the
#          pid else return FAILURE, in case of STAF errors return ESTAF
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       pid in case it is found else undef
#       In case of STAF error return ESTAF
#
# Side effects:
#       none
#
########################################################################

sub IsPortOccupied
{
   my $self = shift;
   my $sessionID = shift;
   my $sessionServer = $sessionID->{'server'};
   my ($port, $result);
   my (@lines, @cols, $ret, $data, $command, $prog, $serverBinary);
   my $trafficToolServerPID = undef;
   my $trafficToolServerName = "unknown";
   my $testIP  = $sessionID->{server}{testip};

   if (not defined $sessionServer || not defined $sessionID ||
      $sessionServer eq "") {
      $vdLogger->Error("Session details missing in IsPortOccupied");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } else {
      $port = $sessionID->{'sessionport'};
   }
   my $IPPortSocket = $testIP . ":" . $port;
   $IPPortSocket = $sessionID->{server}{multicastip} . ":" . $port
                   if $sessionID->{routingscheme} =~ "multicast";

   if ($self->{mode} !~ m/server/i) {
      $vdLogger->Error("Method not applicable on Iperf(client) object");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $serverBinary = $self->GetToolBinary($sessionServer->{os});
   if ($sessionServer->{os} =~ m/(linux|esx|vmkernel)/i) {
      # We are looking for E.g. netstat -nlp \| grep port_number

      $command = "netstat -nlp \| grep " . $port if
                                        $sessionServer->{os} =~ m/linux/i;
      #
      # When checking if a port if enabled or not, the interface/ip address
      # should be passed as well. Otherwise, even if a port is bound to a
      # specific port on different ip address, then we get port as busy,
      # which is incorrect.
      # TODO - Should the same logic be applied for linux?
      #

      if($sessionServer->{os} =~ m/esx|vmkernel/i) {
         $result = $self->{staf}->STAFSyncProcess($sessionServer->{'controlip'},
                                                  "uname -a");
         if ($result->{rc} && $result->{exitCode}) {
            VDSetLastError("ESTAF");
            return FAILURE;
         } elsif($result->{stdout} =~ / 4\.(\d+)\.(\d+) /) {
            # Use the following command for 4.x version
            $esxConnectionState = "esxcli network connection list";
         } else {
            #
            # The ports usage on esx 6.0.0 is per netstack instance.
            # so use the netstack name.
            #
            my $netstack = $sessionServer->{netstack};
            $esxConnectionState = "esxcli network ip connection list -N $netstack";
         }
         $command = $esxConnectionState. " \| grep ".$IPPortSocket;
      }

      $result = $self->{staf}->STAFSyncProcess($sessionServer->{'controlip'},
                                               $command);
      if (($result->{rc} && $result->{exitCode}) ||
          (not defined $result->{stdout})) {
         $vdLogger->Error("Command:$command failed on ".
                          "$sessionServer->{'controlip'} " . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $data = $result->{stdout};
      $vdLogger->Debug("Netstat output from $sessionServer->{'controlip'}".
                       ":$data");

      # netstat -nlp output on linux look like
      # tcp        0      0 *:12865                     *:*
      # LISTENING      8447/trafficToolServer
      # For Ipv6 binded address:
      # It looks like tcp       0    0     2001:bd6::c:2957:426e:49152
      # *:*           LISTEN 358/iperf
      # split the netstat output based on new line if there are multiple
      # trafficToolServers running
      # For esx the output is 'tcp 0 0 0.0.0.0:49152 0.0.0.0:0 LISTEN 35250112'
      # thus fixing match for that as well.
      @lines = split(/\n/, $data);
      foreach my $line (@lines) {
         # remove multiple white spaces
         $line =~ s/\s+/ /g;
         @cols = split(/ /, $line);
         # Changed it to read IPv6 address also
         # E.g. 2001:bd6::c:2957:426e:49152.
         if ($line =~ /.?\:(\d+) /) {
            my $trafficToolServerPort = $1;
            # pid/program is in the last column
            my $pid;
            # The stdout on esx 5.0.0 has changed such that
            # last column might be processname and not pid in some
            # cases. Here are the two cases showing both.
            # tcp 0 0 127.0.0.1:12001 0.0.0.0:0 LISTEN 2756 hostd-worker
            # tcp 0 0 0.0.0.0:8000 0.0.0.0:0 LISTEN 2626

            #
            # The output on esx 6.0.0 has the CC Algorithm type in
            # second last column. See PR 946077.
            # Here is the sample output on 6.0.0 host.
            # tcp 0 0 127.0.0.1:8307 127.0.0.1:28545 ESTABLISHED 1000112540 newreno hostd-worker
            #
            if($cols[-1] =~ /(\d+)/) {
               $pid = $cols[-1];
            } elsif($cols[-2] =~ /(\d+)/) {
               $pid = $cols[-2];
            } else {
               $pid = $cols[-3];
            }
            # grab only the pid value
            $pid =~ s/(.*?)\/.*/$1/;
            $trafficToolServerPID = $pid;
            $vdLogger->Trace("pid of already runnning process".
                             ":$trafficToolServerPID ");
            # if the port matches the input port arg, then return the pid
            if($line =~ m/$serverBinary/i){
               $trafficToolServerName = $serverBinary;
            }
            return $trafficToolServerPID,$trafficToolServerName
            if ($trafficToolServerPort eq $port);
            $trafficToolServerPID = undef;
         }
      }
   } elsif ($sessionServer->{os} =~ m/mac|darwin/i) {
      # Using 'lsof' in Mac, find the process(if any) listening to a specific port.
      # The output generated has the following format:
      # netserver 42403 thomass    4u    IPv4 0x0f6e2748       0t0     TCP *:12865
      # (LISTEN). According to this output, the second column has the PID.
      # The first column contains the process name, therefore, if the process is
      # netserver, this process can be terminated using the PID returned to the
      # Stop function.
      $command = "lsof -i -n -P | grep ".$port;
      $result = $self->{staf}->STAFSyncProcess($sessionServer->{'controlip'},
                                               $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $data = $result->{stdout};
      $vdLogger->Debug("lsof output in Mac from $sessionServer->{'controlip'}".
                       ":$data");

      @lines = split(/\n/, $data);
      foreach my $line (@lines) {
         # remove multiple white spaces
         $line =~ s/\s+/ /g;
         @cols = split(/ /, $line);

         # pid/program is in the second column
         my $pid;
         $pid = $cols[1];
         # To remove the leading whitespaces
         $pid =~ s/^ *//;
         # To remove the trailing whitespaces
         $pid =~ s/ *$//;

         # Now to find the port number of this process: we need to extract the port
         # from the lsof output, the port number forms the second last column of the
         # output and has the format like TCP *:12865
         my $trafficToolServerPort;
         my @trafficPortArray = split(':', $cols[@cols - 2]);
         # The port is the last component of the second last column of the
         # output of lsof.
         $trafficToolServerPort = $trafficPortArray[@trafficPortArray - 1];
         $trafficToolServerPort =~ s/^ *//;
         $trafficToolServerPort =~ s/ *$//;
         $trafficToolServerPID = $pid;
         $vdLogger->Trace("pid of already runnning process".
                          ":$trafficToolServerPID ");
         # if the port matches the input port arg, then return the pid
         if($line =~ m/$serverBinary/i){
            $trafficToolServerName = $serverBinary;
         }
         return $trafficToolServerPID,$trafficToolServerName
         if ($trafficToolServerPort eq $port);
         $trafficToolServerPID = undef;
      }

   } elsif ($sessionServer->{os} =~ m/^win/i) {
      $command = "netstat -abon";
      $result = $self->{staf}->STAFSyncProcess($sessionServer->{'controlip'},
                                                  $command);
      if ($result->{rc} && $result->{exitCode}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $data = $result->{stdout};

      # netstat output on windows looks like
      #   TCP    0.0.0.0:49157          0.0.0.0:0              LISTENING
      #   612
      #    [services.exe]
      @lines = split(/\n/, $data);
      my ($pidline, $pid);
      foreach my $line (@lines) {
         if ($line =~ /(TCP|UDP)/) {
            # save the line if it has TCP socket
            $pidline = $line;
         }
         # The port could be used by some random process, so only check for
         # exe and not netserver.exe
         # When a line contains system or an exe we go into this block
         # and extract info we saved in $pidline.
         next if ($line !~ m/(exe|system)/i);
         if ($line =~ /\[(.*)\]/) {
            $prog = $1;
            $pidline =~ s/\s+/ /g;
            # remove trailing spaces
            $pidline =~ s/^\s*//;
            @cols = split(/ /, $pidline);
            # In IP:port column, remove IP:
            $cols[1] =~ s/.*\://;
            # pid is in last column
            chomp($cols[-1]);
            chomp($cols[1]);
            if($line =~ m/$serverBinary/i){
               $trafficToolServerName = $serverBinary;
            }
            if ($cols[1] eq $port ) {
               $vdLogger->Trace("Port:$port is occupied by ".
                          "Program:$prog,Port:$cols[1],Pid:$cols[-1]");
               return $cols[-1], $trafficToolServerName;
            }
         }
      }
   } else {
      $vdLogger->Error("Unknown OS:$sessionServer->{os} for building ".
                       "ToolCommand");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Trace("Port:$port is unoccupied. Starting $serverBinary on it...");
   return $trafficToolServerPID;
}

########################################################################
# GetThroughput --
#       Parses stdout of traffic session and warns "low" if throughput
#       OR transactions per second is less than 1.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       FAILURE - in case of any execution error
#       FAIL - if expectations are not met
#       PASS/SUCCESS - if expectaitons are met.
#
# Side effects;
#       none
#
########################################################################

sub GetThroughput
{
   my $self = shift;
   my $sessionID = shift;
   my $minExpResult = shift;
   my $maxThroughput = shift || undef;
   my $dataUnit = "Mbits";

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;

   my $trafficToolStdOut = $self->{stdout};
   if (not defined $trafficToolStdOut) {
      $vdLogger->Error("Traffic tool output is undefined for ".
                       $clientInstance);
      VDSetLastError("EINVALID");
      return FAILURE;
   } elsif ($trafficToolStdOut =~ m/warning/i &&
            $trafficToolStdOut =~ m/ack of last datagram/i) {
      # To catch the scenario of UDP port blocked by firewall
      # where we want the test to fail.
      # [  8] WARNING: did not receive ack of last datagram after 1 tries.
      $vdLogger->Warn("Warning in stdout of ".$clientInstance.
                      ". Treating it as failure.");
      VDSetLastError("EFAILED");
      return FAILURE;
   }  elsif($trafficToolStdOut =~ m/permission denied/i) {
      # To catch the scenario of permission issues.
      # write2 failed: Permission denied
      # read failed: Permission denied
      $vdLogger->Warn("Permission denied in stdout of ".$clientInstance.
                      ". Treating it as failure.");
      VDSetLastError("EFAILED");
      return FAILURE;
   }  elsif ($trafficToolStdOut =~ m/DATA CORRUPTION DETECTED/i) {
      # If the data integrity check fails,
      # the output will look something like:
      # DATA CORRUPTION DETECTED
      # First corruption occured on packet <number>
      # - <number> packets corrupted
      $vdLogger->Warn("DATA CORRUPTION DETECTED in  ".$clientInstance.
                      ". Treating it as failure.");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   #
   # We follow the algorithm of parsing the stdout such that
   # Split the stdout in lines according to \n
   # Then start with last line first into words. Split the line
   # according to space. Now start from the last words first and
   # see if they are digits/floating point numbers etc. Break the loop
   # when data is found
   # Currently this algorithm works for both stdout of netperf and
   # stdout of iperf(gives last line with datagrams sent in case of udp)
   # Thus we ignore that line as we are interested only in throughput.
   #
   my $thruputData;
   my @lines = split(/\n/,$trafficToolStdOut);
   my $lineCount = scalar @lines;
   my $find = 0;
   my $rrFlag = 0;
   #
   # If the tool is iperf, then the process the stdout
   # differently.
   #
   if ($sessionID->{toolname} =~ /iperf/i) {
      foreach my $line (@lines) {
         if ($line =~ /([0-9]+\.?[0-9]+)\s\S?bits\/sec/i) {
            $thruputData = $1;
            if($line =~ m/Kbits/ || $line =~ m/3bit/){
               $dataUnit = "Kbits";
            } elsif($line =~ m/Gbits/) {
               $dataUnit = "Gbits";
            } else {
               $dataUnit = "bits";
            }
            goto END_OF_SEARCH;
         }
      }
   }

   foreach my $t (@lines) {
      my @words = split(/ /,$lines[$lineCount-1]);
      my $wordCount = scalar @words;
      foreach (@words) {
         if($t =~ m/Kbits/ || $t =~ m/3bit/){
            $dataUnit = "Kbits";
         } elsif ($t =~ m/Gbits/) {
            $dataUnit = "Gbits";
         }

         # We ignore the line which gives datagram information
         # as we are interested in throughput.
         # local 192.168.0.203 port 49152 connected with 224.0.65.80 port 49152
         #  0.0- 5.0 sec    642 KBytes  1.05 Mbits/sec
         # Sent 447 datagrams
         if($words[$wordCount-1] =~ m/(datagram)/i){
            last;
         }
         # We check if we have hit the first line and still there
         # is no information of throughput in the stdout of traffic run
         # local 192.168.30.2 port 49152 connected with 192.168.30.1 port 49152
         if($words[$wordCount -2] =~ m/port/i){
            if($lines[$lineCount-1] =~ m/(port (\d+) connected with)/i){
               # There is no throughput information in this stdout
               goto END_OF_SEARCH;
            } else {
               last;
            }
         }

         # If stdout says "shutdown_control: no response received  errno 0"
         # we still need to see what the throughput is, thus we skip
         # reading 0 from this line.
         if($lines[$lineCount-1] =~ m/(no response received)/i){
            last;
         }

         # This is a special case scenario for Netperf RR type traffic.
         # The last line does not contain throughput information thus
         # ignoring it.
         if(($sessionID->{bursttype} =~ m/rr/i  ||
             $sessionID->{requestsize} ne "" ||
             $sessionID->{responsesize} ne "") && $rrFlag == 0){
            $rrFlag = 1;
            last;
         }
         # This is a special case scenario. For iperf when traffic is udp
         # and it is not mutlicast then the stdout format is different.
         # If there are more expections in future it would be better to move
         # this type of hack in the child module itself rather than complicating
         # the parent code.
         if ($sessionID->{udpbandwidth} ne "" && $sessionID->{toolname} =~ m/iperf/i) {
            $wordCount = $wordCount - 8;
         } elsif (($sessionID->{l4protocol} =~ m/udp/i &&
                  $sessionID->{toolname} =~ m/iperf/i) ||
                  $sessionID->{routingscheme} =~ m/multicast/i) {
            $wordCount = $wordCount - 11;
         }

         if($words[$wordCount-1] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/){
            $thruputData = $words[$wordCount-1];
            $find = 1;
            last;
         }
         $wordCount--;
      }
      if($find == 1){
         last;
      }
      $lineCount--;
   }

END_OF_SEARCH:

   if(not defined $minExpResult){
      # We dont care about UDP throughput much thus keep it to 1 Mbps
      # by default, user can still override it if he wants
      if ($sessionID->{l4protocol} =~ m/udp/i) {
         $minExpResult = 1;
      } else {
         $minExpResult = 10;
      }
   }

   # If minimum expected result is to be ignored i.e. "minExpResult => IGNORE",
   # throughput of the traffic session need not be calculated
   if ($minExpResult =~ /IGNORE/i) {
      $vdLogger->Info("Ignoring traffic verification as per test requirement ".
                      "for ".$clientInstance);
      return SUCCESS;
   }

   # Check if the number we got is of type floating point and if it is less
   # than one.  less than one means really low throughput.
   if (defined $thruputData) {
      # As the user give the expected max throughput in Mega unit
      # lets convert everything into Mega.
      if ($dataUnit =~ m/gbits/i){
         $thruputData = $thruputData * 1000;
      } elsif ($dataUnit =~ m/kbits/i) {
         $thruputData = $thruputData / 1000;
      }
      $dataUnit = "Mbits";
      $vdLogger->Trace("Placed thruputData:$thruputData in ".
                       "server($sessionID->{server}{nodeid}) hash");
      $sessionID->{server}{'sessionthroughput'} = $thruputData;
      $sessionID->{server}{'throughput'} = $thruputData;
      # If throughput is -ve number then consider it as failure as
      # it usually happens when connection is reset by server/peer.
      if($thruputData != abs($thruputData)) {
         $vdLogger->Error($clientInstance ."'s session throughput ".
                          "is Negative: $thruputData $dataUnit\/sec");
         return FAILURE;
      }
      if (($thruputData =~ /[0-9]+\.?[0-9]*/) &&
         (int($thruputData) < $minExpResult)) {
         $vdLogger->Info("Expected throughput: $minExpResult $dataUnit\/sec");
         $vdLogger->Error($clientInstance ."'s session throughput ".
                          "is low: $thruputData $dataUnit\/sec");
         return "FAIL";
      }

      if (defined $maxThroughput) {
         if(int($thruputData) > $maxThroughput) {
            $vdLogger->Error($clientInstance ."'s session ".
                             "throughput: $thruputData $dataUnit\/sec ".
                             "EXCEEDED maxThroughput: ".
                             "$maxThroughput $dataUnit\/sec ");
            return "FAIL";
         } else {
            $vdLogger->Info($clientInstance ."'s session ".
                            "throughput is: $thruputData $dataUnit\/sec");
            return "PASS";
         }
      } else {
         $vdLogger->Info($clientInstance ."'s session throughput ".
                         "is: $thruputData $dataUnit\/sec");
         return "PASS";
      }
   } else {
      $vdLogger->Warn("Undefined Session throughput");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Error("Didnt match any throughput condition in GetThroughput()");
   VDSetLastError("ENOTDEF");
   return FAILURE;
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
   return CLIENT_LAUNCH_TYPE;
}


########################################################################
#
# PrintTrafficStdout --
#       Print the traffic output on console only if traffic fails.
#       Print the output in log file if traffic passes. This cannot
#       be done inside getthroughput as traffic might fail at any
#       check.
#
#
# Input:
#       SessionID(mandatory) - session hash
#       trafficResult(mandatory) - result of traffic flow to determine
#                                  wheather to print on console or send
#                                  it to log.
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
   my $self = shift;
   my $sessionID = shift;
   my $trafficResult = shift;
   my $srcNode = "$sessionID->{client}->{nodeid}";
   my $dstNode = "$sessionID->{server}->{nodeid}";
   my $instance = $self->{instance};
   $instance = "Client-". $instance;

   if ((not defined $trafficResult) ||
       ((defined $trafficResult) && ($trafficResult =~ /FAIL/i))){
      $vdLogger->Error($instance ." $sessionID->{toolname} session ".
                      " $sessionID->{client}->{controlip}".
                      "($srcNode) ----------> ".
                      "$sessionID->{server}->{controlip}($dstNode)".
                      " \n$self->{stdout}");
   } else {
      $vdLogger->Trace($instance ." $sessionID->{toolname} session ".
                       "$sessionID->{client}->{controlip}".
                       "($srcNode) ----------> ".
                       "$sessionID->{server}->{controlip}($dstNode)".
                       " \n$self->{stdout}");
   }
}

########################################################################
#
# GetOutputFileName --
#       Returns the temp filename which stores the output of async
#       processes
#
# Input:
#       os (mandatory)
#
# Results:
#       Filename along with log directory for that os.
#
# Side effects;
#       none
#
########################################################################

sub GetOutputFileName
{
   my $self = shift;
   my $os = shift;
   my $string = shift || "Stdout";

   my $logDir;
   # Generating unique filename as
   # Binary's name + stdout + timestamp + random + pid + client/server + instance
   # which will store the stdout of its traffic session.
   # Add a random to output file name to avoid duplicate name
   # Please take a look PR 1139256
   my $fileName = VDNetLib::Common::Utilities::GetTimeStamp();
   $fileName = $fileName . "-" . int(rand(getpgrp($$) % 2000)) . "-$$-" .
               $self->{mode} ."-" .$self->{instance};
   $fileName = $self->GetToolBinary($os) ."-". $string ."-". $fileName;
   $vdLogger->Debug("Output file name : $fileName");

   if ($os =~ /(linux|esx|vmkernel|mac|darwin)/i) {
      $logDir =  VDNetLib::Common::GlobalConfig::GetLogsDir();
   } elsif ($os =~ /win/i) {
      $logDir =  VDNetLib::Common::GlobalConfig::GetLogsDir("win");
   } else {
      $vdLogger->Error("Cannot proceed without OS parameter ".
                       "in GetOutputFileName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $logDir . $fileName;
}


########################################################################
#
# IsToolServerRunning --
#       This method is for finding if a trafficToolServer running or did
#       it quit with some error message.
#
# Algorithm:
#       1. GetProcessInfo on server's handle
#       2. If endTimeStamp is defined then that means the server ended
#          a. check what the stdout says in this case.
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS - in case tool server is running
#       FAILURE - in case of error.
#
# Side effects:
#       none
#
########################################################################
# TODO: Additional check can be added by grepping the netstat for that
# port and this binary if need be.
sub IsToolServerRunning
{

   my $self = shift;
   my $sessionID = shift;
   my $result;
   my $serverCtrlIP = $sessionID->{server}->{controlip};
   my $serverHandle = $sessionID->{server}->{instance0}->{childHandle};
   my $serverOutputFile = $sessionID->{server}->{instance0}->{outputFile};

   # First check - checking the status of process.
   $result = $self->{staf}->GetProcessInfo($serverCtrlIP,$serverHandle);
   if ($result->{rc}) {
      my $serverStdout = $self->{staf}->STAFFSReadFile($serverCtrlIP,
                                                      $serverOutputFile);
      if (not defined $serverStdout) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of traffic client. File:$serverOutputFile on ".
                          "$serverCtrlIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif($serverStdout =~ m/(cannot executed binary|not found)/i){
         $vdLogger->Error("Traffic server failed with stdout:\n ".
                          "$serverStdout");
         VDSetLastError("EOPFAILED");
      } else {
         $vdLogger->Warn("Traffic server died after saying:\n$serverStdout");
      }
      return FAILURE;
   }

   # This is additional check - checking if server is running on that port.
   # For the corner of cornest case where - iperf + inbound + outbound
   # + user specified port is given together we need to make another
   # check if server got started on that port.
   my ($pid, $processName) =
       $sessionID->{server}->{instance0}->IsPortOccupied($sessionID);
   if (not defined $pid) {
      $vdLogger->Error("Traffic Server failed to start on $serverCtrlIP");
      $vdLogger->Warn("If you have traffic = iperf + inbound + ".
                      "outbound + user specified port, change at least ".
                      "one parameter OR use SleepBetweenCombos => 20");
      $vdLogger->Trace("Dumping traffic server stdout:" . $serverOutputFile);
      $self->{stdout} = $self->{staf}->STAFFSReadFile($serverCtrlIP,
                                                      $serverOutputFile);
      if (not defined $self->{stdout}) {
         $vdLogger->Error("Something went wrong with reading the stdout file ".
                          "of traffic server. File:$serverOutputFile on ".
                          "$serverCtrlIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      } else {
         $vdLogger->Trace($self->{stdout});
      }
      VDSetLastError("EFAILED");
      return FAILURE;
   } elsif($sessionID->{server}->{os} =~ /(esx|vmkernel)/i) {
      # GetProcessInfo returns the pid of shell.
      # On linux you can add a 1 to it. But on esx we are not sure
      # of the pid. Thus we do grep of netstat like connection list
      # and store the pid.
      $sessionID->{server}->{instance0}->{pid} = $pid;
   }

   return SUCCESS;
}


########################################################################
#
# TestBinary --
#       Tests if a binary executes on the given OS by doing binary -h
#
# Input:
#       String
#
# Results:
#       SUCCESS in case $self->{testOptions} is appended correctly.
#       FAILURE in case of error
#
# Side effects:
#       none
#
########################################################################

sub TestBinary
{
   my $self = shift;
   my $sessionID = shift;
   if (not defined $sessionID) {
      $vdLogger->Error("session hash missing in TestBinary");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $mode = $self->{mode};
   my ($command, $opts, $result);
   my $controlIP = $sessionID->{$mode}->{'controlip'};

   $command = $self->{command};
   $command = $command . " -h";
   $result = $self->{staf}->STAFSyncProcess($controlIP, $command);
   if ($result->{rc} && $result->{exitCode}) {
      $vdLogger->Debug("Testing binary $command failed on $controlIP");
      return FAILURE;
   }

   my $dstfile = $sessionID->{sessionlogs} . "binary-test";
   # Scratch files are logs/stdouts on remote machines SUT/helper etc
   $dstfile = $dstfile . ".log";
   open(FILE, ">", $dstfile);
   print FILE "STDOUT:" . $result->{stdout} . "\n\nSTDERR". $result->{stderr};
   close (FILE);

   if (($result->{stdout} =~ /usage/i) || ($result->{stderr})) {
      return SUCCESS;
   } else {
      return FAILURE;
   }

}



########################################################################
#
# CollectLogs --
#       collects all the logs required for post mortem analysis like
#       output of ps, netstat, ifconfig, ethtool etc.
#
# Input:
#       String
#
# Results:
#       SUCCESS in case $self->{testOptions} is appended correctly.
#       FAILURE in case of error
#
# Side effects:
#       none
#
########################################################################

sub CollectLogsAndState
{
   my $self = shift;
   my $sessionID = shift;
   if (not defined $sessionID) {
      $vdLogger->Error("session hash missing in CollectLogsAndState");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $mode = $self->{mode};
   my ($command, $opts, $result);
   my $controlIP = $sessionID->{$mode}->{'controlip'};

   #
   # For method 1 we only support netdapter obj as of now. As traffic is
   # associated to netadapter(not tightly bound though)
   #
   my $trafficPostMortem = {
      'interface-state' => {
         'method' => "GetNetworkConfig",
         'obj' => "netadapterobj",
      },
      'route-state' => {
         # It looks like directly doing a staf call is much quicker
         # than going through netadapterObj->Vnic->NetDiscover->LocalAgent
         # ->remoteAgent and back. Thus switching to command for now.
         #'method' => "GetRouteConfig",
         #'obj' => "netadapterobj",
         'linux' => "route -n",
         'vmkernel' => "/sbin/esxcfg-route",
         'win'   => "route print",
      },
      # $esxConnectionState should be defined in case adapter type
      # is vmknic and if adapter type is vmknic then only we try to
      # collect connection state for on the host.
      'connection-state' => {
         'linux' => "netstat -nlp",
         'vmkernel'   => $esxConnectionState,
         'win'   => "netstat -abon",
      },
      'process-state' => {
         'linux' => "ps -eaf",
         'win' => "tasklist",
         'vmkernel' => "ps",
      },
      # TODO: Not sure if this is helpful. Will implement it in future if it is.
      # 'link-state' => {
      #    'linux' => "ethtool",
      # },
   };

   # For each key in the postmortem hash. First try with exisiting method
   # If a method is not defined then try with os specific commands
   foreach my $pm (keys %$trafficPostMortem) {
      my $pmHash = $trafficPostMortem->{$pm};
      # Generating the file name of the file which will be copy
      # to the master controller.
      my $dstfile = $sessionID->{sessionlogs} . "$pm";
      # Scratch files are logs/stdouts on remote machines SUT/helper etc
      $dstfile = $dstfile . ".log";
      $pmHash->{dstfile} = $dstfile;
      if(defined $pmHash->{method}) {
         #
         # This is method 1. Find the obj on which method will be called
         #
         my $netObj = $sessionID->{$mode}->{$pmHash->{obj}};
         if(not defined $netObj) {
            # we should know the interface name to create a new NetAdapter obj
            my $interface = $sessionID->{$mode}->{'interface'};
            if(not defined $interface) {
               $vdLogger->Debug("interface missing in traffic's $mode hash".
                                " Cannot collect $pm");
               next;
            }
            my $module = "VDNetLib::NetAdapter::NetAdapter";
            eval "require $module";
            if ($@) {
               $vdLogger->Debug("netadapter obj was not defined in traffic.".
                                " Loading new $module, but that too failed");
               next;
            }
            $netObj = $module->new(controlIP => $controlIP,
                                   interface => $interface);
            if($netObj eq FAILURE) {
               $vdLogger->Debug("netadapter obj was not defined in traffic.".
                                "Creating new $module obj failed");
               next;
            }
            $sessionID->{$mode}->{$pmHash->{obj}} = $netObj;
         }
         my $method = $pmHash->{method};
         my $ret = $netObj->$method($dstfile);
         if($ret eq FAILURE) {
            $vdLogger->Debug("$method on $netObj returned failured.".
                             " Cannot collect $pm");
         }
         # Deleting this postmortem as we are done with it.
         # We only delete the method PMs so that we can wait on rest
         # of the async PMs.
         delete $trafficPostMortem->{$pm};
         #
      }   else {
         #
         # This is method 2. Call command directly on target machine to
         # fetch information.
         #
         my $os = $sessionID->{$mode}->{os};
         $os = "vmkernel" if $os =~ /esx/i;
         foreach my $pmOS (keys %$pmHash) {
            if($os !~ /^$pmOS/) {
               next;
            } else {
               $os = $pmOS;
               $command = $pmHash->{$os};
               $result = $self->{staf}->STAFSyncProcess($controlIP, $command);
               if ($result->{rc} && $result->{exitCode}) {
                  $vdLogger->Debug(" Cannot collect $pm as $command ".
                                   "failed on $controlIP");
               } else {
                  open(FILE, ">", $dstfile);
                  print FILE $result->{stdout};
                  close (FILE);
               }
            }
         }

      }
      #
      $vdLogger->Debug("$pm info is in $dstfile");
      #
   }

   # Now copy all the scratch file to the local dir.
   my $masterControlleraddr = $sessionID->{mcIP};
   if(not defined $masterControlleraddr) {
      if (($masterControlleraddr = VDNetLib::Common::Utilities::GetLocalIP()) eq
           FAILURE) {
         $vdLogger->Error("Not able to get LocalIP:$masterControlleraddr".
                          " in CollectLogsAndState()");
         return FAILURE;
      }
      $sessionID->{mcIP} = $masterControlleraddr;
   }

   my @trafficScratchFiles = @{$self->{scratchFiles}};
   for (my $i = 0; $i <= $#trafficScratchFiles; $i++){
      my $file = $trafficScratchFiles[$i];
      #
      # For client mode we will copy all the client files
      # netserver-Stdout-092-154549-25721-client-1
      #
      if($file !~ /$mode/i) {
        next;
      }
      $result = $self->{staf}->STAFFSCopyFile("$file",
                                              $sessionID->{sessionlogs},
                                              "$controlIP",
                                              "$masterControlleraddr");
      if($result eq -1) {
         $vdLogger->Debug("Copying log $file to $masterControlleraddr failed");
      } else {
         delete $trafficScratchFiles[$i];
      }
   }
   # Update the var as we copied some of the files.
   $self->{scratchFiles} = \@trafficScratchFiles;
   my $dstfile = $sessionID->{sessionlogs} . "session-dump";
   # Scratch files are logs/stdouts on remote machines SUT/helper etc
   $dstfile = $dstfile . ".log";
   open(FILE, ">", $dstfile);
   print FILE Dumper($sessionID);
   close (FILE);

   # This is to del the files from the SUT/Helper
   $self->DelScratchFiles($sessionID, [$self->{outputFile}]);
   return SUCCESS;
}

1;
