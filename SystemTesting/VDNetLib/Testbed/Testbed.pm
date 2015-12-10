#############################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::Testbed::Testbed;

##############################################################################
#  Testbed class is an abstract class which has common APIs
#
#  Side effects:
#
##############################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT);
use VDNetLib::Common::Utilities;
use VDNetLib::VM::VMOperations;
use VDNetLib::Host::HostOperations;
use VDNetLib::VC::VCOperation;
use VDNetLib::VC::Datacenter;
use VDNetLib::Switch::Switch;
use VDNetLib::Switch::VSSwitch::PortGroup;
use Carp;

use constant GUESTIP_DEFAULT_TIMEOUT => 300;
use constant GUESTIP_SLEEPTIME => 5;
use constant GUEST_BOOTTIME => 60;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VMWARE_TOOLS_BASE_PATH => "/usr/lib/vmware/";
use constant VDNET_LOCAL_MOUNTPOINT => "vdtest";

my @machineAttributes = qw(ip host vmx os hostType);
my $masterControlIP;


########################################################################
#
# CollectTestbedDetails --
#      This method collects all testbed information for the given
#      machine.
#
# Input:
#      adapterObj: reference to VDNetLib::NetAdapter::NetAdapter object
#                  if details corresponding to adapter has to be
#                  collected (optional)
# Results:
#      Returns reference to a hash with following keys. The possible
#      values currently returned for each key is also given:
#      'platform'    : "esx" or "vmkernel"
#      'guestos'     : "win" or "linux"
#      'ndisversion' : "5.1" or "6.1"
#      'kernelversion' "2.4" or "2.6"
#
# Side effects:
#      None
#
########################################################################

sub CollectTestbedDetails

{
   my $self       = shift;
   my $adapterObj = shift;
   my $testbedInfo; # return hash
   if (not defined $adapterObj) {
      $vdLogger->Error("adapterObj not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my ($command, $result, $data);

   my $vmOpsObj = $adapterObj->{vmOpsObj};
   my $hostObj = $vmOpsObj->{hostObj};
   my $host    = $hostObj->{hostIP};
   my $guestIP = $adapterObj->{controlIP};

   # Instead os, it should have been hostType.
   # hostType attribute tells us if the host
   # is hosted on a vm or if its VMKernal.
   # Even though hostType attribute  is set properly
   # in Testbedv2.pm, it gets undefined somehwhere.
   # Currenlty os and hostType are different
   # attributes but storing same value, so we are
   # using os.
   my $platform = $hostObj->{os};
   $testbedInfo->{'platform'} = $platform;

   my $guestOS = $vmOpsObj->{os};

   if (not defined $guestOS) {
    # Sometimes the $vmOpsObj->{os} is undefined
    # So assigning a default value "linux"
    $guestOS = "linux";
   }
   if ($guestOS =~ /win|windows/i) {
      $guestOS = "win";
   }

   if ($guestOS =~ /lin|linux/i) {
      $guestOS = "linux";
   }
   $testbedInfo->{'guestos'} = $guestOS;

   # return right here if NetAdapter object is not defined.
   if (not defined $adapterObj) {
      return $testbedInfo;
   }

   my $driverVersion;
   my $ndisVersion;
   if ($guestOS =~ /win/) {
      #
      # In case of windows, get the 'ndisversion' and make 'kernelversion'
      # as "NA"
      $ndisVersion = $adapterObj->GetNDISVersion(); 

      if (not defined $ndisVersion) {
         $vdLogger->Error("ndis version not defined for " .
                          "$adapterObj->{interface} on " .
                          $adapterObj->{controlIP});
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $testbedInfo->{'ndisversion'} = $ndisVersion;
      $testbedInfo->{'kernelversion'} = "NA";
   } else {
      #
      # In case of linux, get the 'kernelversion' and make 'ndisversion'
      # as "NA"
      #

      $command = 'GET SYSTEM VAR "STAF/Config/OS/MajorVersion"';
      ($result, $data) = $self->{stafHelper}->runStafCmd($guestIP,
                                                         'VAR',
                                                         $command);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get os/kernel version for $guestIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my $kernelVersion = $data;
      if (not defined $kernelVersion) {
         $vdLogger->Error("kernel version not defined on $guestIP");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # The kernel version might be in two types like 2.6.32-19.x.* or
      # 2.6.32.19. Extract only 2.6.32 from these.
      my @kernel = split('-', $kernelVersion);
      if ((defined $kernel[0]) && ($kernelVersion =~ /-/)) {
         $kernelVersion = $kernel[0];
      } else {
         my @kminor = split('\.', $kernelVersion);
         if ($kernelVersion =~ /2.6/) {
            $kernelVersion = "2.6." . $kminor[2];
         } elsif ($kernelVersion =~ /2.4/) {
            $kernelVersion = "2.4";
         }
      }

      $testbedInfo->{'kernelversion'} = $kernelVersion;
      $testbedInfo->{'ndisversion'} = "NA";
   }
   # Now get the driver version
   $driverVersion = $adapterObj->GetDriverVersion();
   if ((not defined $driverVersion) || ($driverVersion eq FAILURE)) {
      $vdLogger->Error("Failed to get adapter driver version");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $testbedInfo->{'driverversion'} = $driverVersion;
   return $testbedInfo;
}


########################################################################
#
# SetEvent --
#      This method sends an event message to parent process or updates
#      parent process about certain changes. In vdnet, workloads are
#      run by forking a new process. In order to communicate with the
#      parent, the child processes uses this method. This method sends
#      a signal (USR1) to the parent process and sends a message
#      containing event name and supporting parameters. Until an
#      acknowledgment message is received, this method sends signal
#      and message periodically. Once ACK is received, it waits for
#      completion message from the parent process.
#
# Input:
#      eventName: name of the event. The event name should be one from
#                 the list of registered events given in VDNetLib::Events
#                 package (Required)
#      params   : reference to an array, with each element containing
#                 the parameters required to execute callback function
#                 corresponding to the event name
#
# Results:
#      "SUCCESS", if successful in communicating with parent process;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub SetEvent
{
   my $self      = shift;
   my $eventName = shift;
   my $params    = shift;


   if (not defined $eventName) {
      $vdLogger->Error("Event name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # We update timeout value dynamically based on
   # the MaxTimeOut key of workloads. In case,
   # it is not specified then use this default timeout value.
   #
   my $timeout = VDNetLib::Common::GlobalConfig::DEFAULT_WORKLOAD_TIMEOUT;
   my $stafHandle = $self->{stafHelper}{handle}{handle};
   my $pid =  $self->{pid};
   my $startTime = time();
   my $result;

   #
   # Creating an identifier which is a unique string for every event
   # notifications.
   #
   my $identifier = $$ . "-" . time();

   #
   # Message to parent is sent in the form of hash.
   # eventName - indicates the name of the event to look up from registered
   #             events
   # params    - reference to array. This is the array that will passed as
   #             parameter to the callback function corresponding to the event
   # identifier- unique string to establish one-one communication between
   #             parent and child
   #
   my $event;
   $event->{'eventName'} = $eventName;
   $event->{'params'}    = $params;
   $event->{'identifier'} = $identifier;
   $event->{'data'} = undef;
   $event->{'result'} = undef;

   #
   # SendMessage() method in STAF does not understand hash, it needs a scalar
   # string as message to be passed, so marshilling the hash to a scalar string
   # before sending the message to parent.
   #
   $event = VDNetLib::Common::Utilities::SerializeData($event);

   my $ack = 0; # initialize ack to 0 to indicate not received
   while ($timeout && $startTime + $timeout > time()) {
      $vdLogger->Debug("Sending SIGUSR1 to process $pid");
      my $command = "kill -10 $pid";
      my $result  = $self->{stafHelper}->STAFSyncProcess("local", $command);
      if (($result->{rc} != 0)) {
         $vdLogger->Error("Failed to send kill command" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      sleep 2; # give some time for parent to react to the signal

      # setting options for sending message through staf
      my $opts;
      $opts->{'type'} = "VDNet_Event"; # unique string to identify event
                                       # handler messages in a queue
                                       #
      $opts->{'handle'} = $stafHandle;
      # sending the message
      $vdLogger->Debug("Sending message $event to parent process");
      $result = $self->{stafHelper}->SendMessage($event, "local", $opts);
      if (not defined $result) {
         $vdLogger->Error("Failed to send message. Event:" . Dumper($event) .
                          " Opts:" . Dumper($opts));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      sleep 5; # TODO - remove hardcoding,, wait between sending and getting
               # ready to receive ack

      # look for ack message from parent
      $result = $self->{stafHelper}->GetMessage(5, "VDNet_Event",
                                                   undef, undef);
      if (defined $result && $result->{'message'} =~ /ack-$identifier/) {
    if ($result->{'message'} =~ /::timeout-(\d+)/i) {
       # 20 sec overhead for sendMessage and GetMessage communication.
            $timeout = 20 + int($1) if defined $1;
            $vdLogger->Trace("Event:$identifier increased timeout to:$timeout");
         }
         $ack = 1;
         last;
      }
      # if ack message is not received, send the signal/message again. Do this
      # until timeout is hit or ack message is received.
      #
   }
   if (!$ack) {
      $vdLogger->Error("Failed to connect with parent for identifier:".
             "$identifier");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("Received ack for identifier $identifier");

   # We prepare $event here just for debugging purpose.
   # So that we can dump the entire event info in case of error.
   $event = eval ($event);

   #
   # Now that ack message is received, look for finish message
   # TODO - may be put a sleep here if the time to execute callback function
   # corresponding to the event is known.
   #
   my $finish = 0;
   my $msg = undef;
   $startTime = time();
   while ($timeout && $startTime + $timeout > time()) {
      $vdLogger->Debug("Waiting to get complettion msg for identifier $identifier");
      $result = $self->{stafHelper}->GetMessage(5, "VDNet_Event",
                                                      undef, undef);
      if (defined $result && $result->{'message'} =~ /(PASS|FAIL)-$identifier/) {
         $msg = eval ($result->{'message'});
         $event->{'data'} = $msg->{'data'} if
                                             defined $msg->{'data'};
         $event->{'result'} = $msg->{'result'} if
                                             defined $msg->{'result'};
         $finish = 1;
         last;
      }
      sleep 20;
   }

   if (!$finish) {
      $vdLogger->Error("Failed to receive completion message for identifier " .
                       $identifier);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("identifier-$identifier received completion ".
                   "msg:$event->{'result'}");
   # Completion messages are sent the format <PASS|FAIL>-<eventIdentifier>
   if ($result->{'message'} =~ "PASS-$identifier") {
      if(defined $event->{data}) {
         return $event->{data};
      } else {
         return SUCCESS;
      }
   } else {
      $vdLogger->Info("Event failed. Dumping" . Dumper($event));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

}
1;
