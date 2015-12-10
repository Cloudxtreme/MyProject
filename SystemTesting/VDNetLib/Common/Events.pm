########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Common::Events;

#
# This package takes care of handling events, executing callback funtions
# corresponding to each event. It has access to all the objects created in
# vdNet automation. Therefore, updating any class attributes or calling any
# methods of a class can be handled here.
#
# To register a new event, add a new key (event name) to "registeredEvents"
# hash in new() method. Provide details like 'callback' and other event related
# information with the event's hash.
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);


########################################################################
#
# new --
#      This is the entry point to VDNetLib::Common::Events class.
#      It returns an object of this class.
#
# Input:
#      A named hash with following keys:
#      workloadsManager: reference to an object of
#         VDNetLib::Workloads::Workloads class (Required)
#
# Results:
#      An object of VDNetLib::Common::Events class, if successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub new {
   my $class = shift;
   my %options = @_;
   my $self;
   $self = {
      'workloadsManager' => $options{workloadsManager},
      'testbed'      => $options{testbed},
      'testcase'     => $options{testcase},
      };

   if (not defined $options{workloadsManager}) {
      $vdLogger->Error("Object of VDNetLib::Workloads::Workloads " .
                       "is not  provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   bless ($self, $class);


   my %registeredEvents = (
      #
      # Currently this causes a new workload to be run without spawning
      # a separate process for it. The new workload gets to run in  the
      # parent (vdnet.pl/Testbed) process workspace. In future we  need
      # to correct this behavior. And make sure that every workload is
      # is spawned as a new process by all means.
      #
      'RunWorkload'  => {
         'callback' => [$self->{workloadsManager}, 'StartChildWorkload'],
      },
      'ReturnWorkloadHash'  => {
         'callback' => [$self->{workloadsManager}, 'ReturnWorkloadHash'],
      },
      'AddSwitch'  => {
         'callback' => [$self, 'AddSwitchEvent'],
      },
      'ConfiguregVLAN'  => {
         'callback' => [$self, 'ConfiguregVLANEvent'],
      },
      'VCAnchor'  => {
         'callback' => [$self, 'VCAnchorEvent'],
      },
      'SetMACAddress' => {
         'callback' => [$self, 'SetMACAddressEvent'],
      },
      'VMNicEvent' => {
         'callback' => [$self, 'VMKNicEvent'],
      },
      'VNicEvent' => {
         'callback' => [$self, 'VNicEvent'],
      },
      'GetPortRunningConfigurationEvent' => {
         'callback' => [$self, 'GetPortRunningConfigurationEvent'],
      },
      'SetIPv4' => {
         'callback' => [$self, 'SetIPv4Event'],
      },
      'PCIUpdate' => {
         'callback' => [$self, 'UpdatePCITestbedInfo'],
      },
      'PowerOffVM' => {
         'callback' => [$self->{testbed}, 'PowerOffVMEvent'],
      },
   );
   # Store the registered events as class attribute
   $self->{registeredEvents} = \%registeredEvents;
   return $self;
}


########################################################################
#
# ProcessEvent --
#      This method all the events in vdNet automation. The way an event
#      invoked is, a process (usually workloads) will send SIGUSR1 and
#      a event message periodically. The signal handler code receives
#      the signal and invokes this method. This method receives the
#      message and sends an acknowledgement message, if the message
#      received is relevant. Then, the received event will be looked
#      upon the list of registered events. Once found, corresponsing
#      callback function will be executed and a message will be send
#      back to the child process on completion.
#
# Input:
#      None
#
# Results:
#      undef, if the event received is irrelevant;
#      Otherwise, sends a completion message to the child process.
#      The message format is <PASS|FAIL>-<identifier>. Identifier
#      is a unique string that represents a particular event
#      notification.
#
# Side effects:
#      None
#
########################################################################

sub ProcessEvent
{
   my $self = shift;

   my $workloadMgr = $self->{workloadsManager};
   my $testbed = $self->{testbed};
   my $registeredEvents = $self->{registeredEvents};
   my $result = undef;
   my $data = undef;

   # Receive the message from the child process
   $result = $self->{testbed}{stafHelper}->GetMessage(5, "VDNet_Event",
                                                         undef, undef);
   if (not defined $result) {
      $vdLogger->Debug("No message received, this method has got nothing to do");
      return;
   }

   my $srcHandle = $result->{'handle'};
   my $event = $result->{message};

   #
   # The sender sends hash in a serialized format, doing an eval gets the
   # original hash structure back.
   #
   $event = eval($event);
   if (ref($event) ne "HASH" ) {
      $vdLogger->Debug("Not the message expected");
      return undef; # this is not the msg looking for
   }

   $vdLogger->Debug("Process event:\n". Dumper($event));

   # Get the source identifier for this event notification
   my $srcIdentifier = $event->{'identifier'};
   my $ackMessage = $srcIdentifier;
   my $opts;
   $opts->{'type'} = "VDNet_Event";

   # Need to the know source staf handle to reply back
   $opts->{'handle'} = $srcHandle;

   my $workloadHash = $self->{testcase}{WORKLOADS}{$event->{params}};
   foreach my $key (keys %$workloadHash) {
      if ($key =~ /maxtimeout/i) {
         $ackMessage = $ackMessage . "::timeout-" . $workloadHash->{$key};
      }
   }
   $vdLogger->Debug("Sending ACK msg to identifier $ackMessage");
   $result = $self->{testbed}{stafHelper}->SendMessage("ack-" . $ackMessage,
                                                          "local", $opts);
   if ($result != 0) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("Send message failed" . Dumper($result));
      $result = "FAIL";
      goto SEND_COMPLETE_MSG;
   }

   if (not defined $registeredEvents->{$event->{eventName}}) {
      $vdLogger->Error("Unknown event type $event->{eventName}");
      $result = "FAIL";
      goto SEND_COMPLETE_MSG;
   }

   my $callback = $registeredEvents->{$event->{eventName}}{'callback'};
   if (not defined $callback) {
      $vdLogger->Error("Callback funtion not defined for event " .
                       $event->{eventName});
   }
   my $obj = @$callback[0];
   my $method = @$callback[1];
   my @params;
   if (ref($event->{params}) eq "ARRAY") {
      @params = @{$event->{params}};
   } else {
      $params[0] = $event->{params};
   }

   $vdLogger->Info("Executing callback function $method in event handler code");
   if (defined $obj) {
      $result = $obj->$method(@params);
   } else {
      $result = &{$method}(@params);
   }

SEND_COMPLETE_MSG:
   if ($result =~ /FAIL/) {
      $result = "FAIL-" . $srcIdentifier;
      $vdLogger->Error("EventHandler: Method execution of Event " .
                       "$event->{eventName} failed");
      $vdLogger->Debug(VDGetLastError());
   } else {
      $event->{'data'} = $result;
      $result = "PASS-" . $srcIdentifier;
   }

   $event->{'result'} = $result;
   $event = VDNetLib::Common::Utilities::SerializeData($event);
   $vdLogger->Debug("Sending event hash and completion msg \"$result\" ".
                    "to $srcIdentifier");
   $result = $self->{testbed}{stafHelper}->SendMessage($event,
                                                          "local",
                                                          $opts);
   if ($result != 0) {
      VDSetLastError("ESTAF");
      $vdLogger->Error("send message" . Dumper($result));
   }
}


########################################################################
#
# AddSwitchEvent --
#      This is callback function of event "AddvSwitch".
#      It creates an object of the vswitch being added and adds
#      reference to this object under testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is integer (Required)
#      switchName: name of the switch created (Required)
#      switchType: type of the switch (vdswitch/vswitch) (Required)
#
# Results:
#      "SUCCESS", if VDNetLib::Switch::Switch object is created
#                 successfully for the given switch;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub AddSwitchEvent
{
   my $self        = shift;
   my $tuple     = shift;
   my $switchName  = shift;
   my $switchType  = shift;
   my $datacenter  = shift;

   my @arr = split('\.', $tuple);
   my $machine = $arr[0];

   if ((not defined $tuple) || (not defined $switchName) ||
      (not defined $switchType)) {
      $vdLogger->Warn("machine and/or switchName and/or switchType " .
                       "not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Retrieve the hostObj for the given machine
   my $hostObj = $self->{testbed}{testbed}{$machine}{hostObj};
   if (not defined $hostObj) {
      $vdLogger->Error("hostObj for $machine not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # vcObj and datacenter name are need if the switch type is vdswitch
   my $vcObj = $self->{testbed}->{vc}->{vcOpsObj};

   if ($switchType =~ /vdswitch/i) {
      if ((not defined $vcObj) || (not defined $datacenter)) {
         $vdLogger->Error("VCObj and/or datacenter name not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   # Create Switch object here using the parameters above
   my $switchObj = VDNetLib::Switch::Switch->new('switch'     => $switchName,
                                                 'switchType' => $switchType,
                                                 'host'       => $hostObj->{hostIP},
                                                 'hostOpsObj' => $hostObj,
                                                 'datacenter' => $datacenter,
                                                 'vcObj'      => $vcObj);
   if ($switchObj eq FAILURE) {
      $vdLogger->Error("Failed to create switch object for $switchName " .
                       " on $machine");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Get the reference in testbed hash where list of Switch objects are
   # maintained.
   #
   my $switchRef = $self->{testbed}{testbed}{$machine}{switches};
   my @switchArray = ();

   # There could be no such list, if this is the first switch created
   if (not defined $switchRef) {
      $vdLogger->Warn("Reference to switch objects in testbed has " .
                       " not defined, may be this is the first switch added");
      $switchArray[0] = $switchObj;
   } else {
      @switchArray = @$switchRef;
      # Otherwise, find array size and store the object created as the last
      # entry
      my $arrSize = scalar(@switchArray);
      $switchArray[$arrSize] = $switchObj;
   }
   $self->{testbed}{testbed}{$machine}{switches} = \@switchArray;

   return SUCCESS;
}


########################################################################
#
# ConfiguregVLANEvent --
#      This method implements callback function for "ConfiguregVLAN"
#      event.
#
# Input:
#      Named hash with following keys:
#      'machine'     : SUT or helper<x> (Required)
#      'parentInteface' : interface name (example,ethX) of parent
#                         adapter (Required)
#      'addVLANID'   : vlan id added to parent adapter
#      'removeVLANID': vlan id removed from parent adapter
#      'vlanNetObj'  : reference NetAdapter object for child interface
#
# Results:
#      "SUCCESS", if parent's testbed hash is updated successfully
#      "FAILURE", in case of any error
#
# Side effects:
#      In case, addVLANID is defined, parent's index will become
#      <parentIndex>.<$addVLANID>. example: 2.113;
#
########################################################################

sub ConfiguregVLANEvent
{
   my $self = shift;
   my %args = @_;

   my $machine      = $args{machine};
   my $testAdapter     = $args{testAdapter};
   my $addVLANID       = $args{addVLANID};
   my $removeVLANID    = $args{removeVLANID};
   my $parentInterface = $args{parentInterface};
   my $vlanNetObj      = $args{vlanNetObj};
   my $intType         = $args{intType} || "vnic";

   if ((not defined $machine) || (not defined $parentInterface)) {
      $vdLogger->Error("machine or interfaceName not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ((not defined $addVLANID) && (not defined $removeVLANID)) {
      $vdLogger->Error("Either add vlan id or remove vlan id must be provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Guest VLAN in linux works different from windows
   # When vlan is added to an adapter, say eth1, a child vlan node,
   # eth1.<vlanid> is created. Example, eth1.113. In order for the traffic to
   # go through the child vlan node, the parent adapter's, eth1, subnet should
   # be totall different. This is suggested as best practices while configuring
   # gVLAN.
   #
   # SetVLAN() in NetAdapter returns reference to another netadapter obj with
   # child vlan node as interface. The obj will look like
   # {
   #    controlIP => <ip address>
   #    interface => "eth1.113",
   # }
   # In virtual devices TDS, when gVLAN is configured, all the test cases
   # should run only on the child vlan node. So, while writing test cases,
   # in NetAdapter type workloads, if "vlan" key is given for TestAdapter = <x>,
   # then TestAdapter =<x> in any other workload should point to the child node,
   # not the parent node.
   # Therefore, in this callback function, we update the parent and child index
   # in testbed hash to always point to the child vlan interface, if vlan is
   # enabled.
   #

   my $adapterRef;

   if ($intType =~ /pci/i) {
      $adapterRef = $self->{testbed}{testbed}{$machine}{Adapters}{pci};
   } else {
      $adapterRef = $self->{testbed}{testbed}{$machine}{Adapters};
   }

   my $parentIndex;
   foreach my $adapter (keys %$adapterRef) {
      if (defined $adapterRef->{$adapter}{'interface'}) {
         if ($adapterRef->{$adapter}{'interface'} eq $parentInterface) {
            $parentIndex = $adapter;
            last;
         }
      }
   }

   if ($parentIndex =~ /(\d+)\.(\d+)/) {
      $parentIndex = $1;
   }

   $vdLogger->Info("AddgVLANEvent: Original index of parent index $parentIndex");

   if (not defined $parentIndex) {
      $vdLogger->Error("Cannot find index for $parentInterface in testbed " .
                       "for $machine");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $childIndex;
   if (defined $removeVLANID) {
      $childIndex = $parentIndex . "." . $removeVLANID;
      #
      # If vlan is removed from parent interface, then revert the parent
      # netadapter to the original index stored in testbed hash.
      #
      if (defined $adapterRef->{$childIndex}) {
         $vdLogger->Info("Reverting parent index as $parentIndex");
         $adapterRef->{$parentIndex} =
            $adapterRef->{$childIndex};
         delete $adapterRef->{$childIndex};

      }
   }

   if (defined $addVLANID) {
      $childIndex = $parentIndex . "." . $addVLANID;

      if (not defined $vlanNetObj) {
         $vdLogger->Error("Child NetAdapter object not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      #
      # If vlan is added, then store the parent object with index
      # <parentIndex>.<vlanID> and store the netadapter object of newly
      # created vlan node with index <parentIndex>
      #
      if (not defined $adapterRef->{$childIndex}) {
         $vdLogger->Info("Converting parent index as $childIndex");
         $vdLogger->Info("Converting child index as $parentIndex");
         $adapterRef->{$childIndex} =  $adapterRef->{$parentIndex};
         $adapterRef->{$parentIndex} = $vlanNetObj;
      }
   }
   return SUCCESS;
}


########################################################################
#
# VCAnchorEvent --
#      This method implements callback function for "VCAnchor"
#      event.
#
# Input:
#      Named hash with following keys:
#      'vmanchor'      : VM anchor value
#      'hostanchor'    : Host anchor value
#      'setupanchor'   : setup anchor value
#
# Results:
#      "SUCCESS", if updated {vcOpsObj} value successful.
#      "FAILURE", in case of any error
#
# Side effects:
#
########################################################################

sub VCAnchorEvent
{
   my $self        = shift;
   my $vmanchor    = shift;
   my $hostanchor  = shift;
   my $setupanchor = shift;
   $self->{testbed}->{vc}->{vcOpsObj}->{setupAnchor} = $setupanchor;
   $self->{testbed}->{vc}->{vcOpsObj}->{hostAnchor}  = $hostanchor;
   $self->{testbed}->{vc}->{vcOpsObj}->{vmAnchor}    = $vmanchor;
   $vdLogger->Info("VC anchor updated with $setupanchor,$hostanchor,$vmanchor");
   return SUCCESS;
}


########################################################################
#
# SetMACAddressEvent --
#      Callback function to handle changes in mac address of vNic.
#      This routine stores the original mac address of an adapter.
#      This mac address is later used when resetting the mac address.
#
# Input:
#      Named hash parameters with keys:
#      machine : SUT/helper<X> (Required)
#      adapter : interface name of an adapter, example "eth0" (Required)
#      mac     : new mac address (Required)
#
# Results:
#      SUCCESS, if original mac address of the given adapter is saved;
#      FAILURE, in case of any errors
#
########################################################################

sub SetMACAddressEvent
{
   my $self = shift;
   my %args = @_;

   my $netObj  = $args{adapter};
   my $mac      = $args{mac};
   my $adapter = $netObj->{interface};

   if ((not defined $netObj) || (not defined $adapter) ||
       (not defined $mac)) {
      $vdLogger->Error("One or more parameters missing to set event");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }


   #
   # We just store the original mac to use when mac reset is requested. Not
   # updating parent testbed or anything because w.r.t VC/VI client, the mac
   # address of this adapter is still the original address. Changing
   # the mac address in parent testbed would create difference in what is
   # available inside the guest and seen outside the guest.
   #
   my $vmOpsObj = $netObj->{vmOpsObj};
   if (not defined $netObj->{originalMAC}) {
      $netObj->{originalMAC} = $netObj->{'macAddress'};
      $vdLogger->Info("Updated original mac address of $netObj->{interface} as " .
                      "$netObj->{'macAddress'} at $vmOpsObj->{vmx}");
   }

   $vdLogger->Info("Now the mac address set on $netObj->{interface} " .
                   "in $vmOpsObj->{vmx} is $mac");
   return SUCCESS;
}


########################################################################
#
# VMKNicEvent --
#      This is callback function of event "VMKNic".
#      It creates an object of the vmknic being added and adds
#      reference to this object under testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is integer (Required)
#      pgName : name of the vmknic portgroup (Required)
#      operation: add/delete (Optional, default is add)
#
# Results:
#      "SUCCESS", if VDNetLib::NetAdapter::NetAdapter object is created
#                 successfully for the given vmknic;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub VMKNicEvent
{
   my $self        = shift;
   my $tuple       = shift;
   my $netObj      = shift;

   if ((not defined $tuple) || (not defined $netObj)) {
      $vdLogger->Warn("VMKNICEvent: tuple and/or netObj not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $result = $self->{testbed}->SetComponentObject($tuple, $netObj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to update the testbed for $tuple");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# VNicEvent --
#      This is callback function of event "VNicEvent".
#      It creates an object of the Vnic being added and adds
#      reference to this object under testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is integer (Required)
#      mac    : mac address of adapter added or removed (Required)
#      operation: add/remove (Optional, default is add)
#
# Results:
#      "SUCCESS", if VDNetLib::NetAdapter::NetAdapter object is created
#                 successfully for the given vnic;
#      "FAILURE", in case of any error
#
# Side effects:
#      GetAllAdapters() called in this method would enable all adapters
#      in the given machine. So, it is user's responsibility to
#      re-configure the device status
#
########################################################################

sub VNicEvent
{
   my $self          = shift;
   my $tuple         = shift;
   my $mac           = shift;
   my $operation     = shift || "add";

   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref $ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $vmOpsObj = $ref->[0];
   my @arr = split('\.', $tuple);
   my $machine = $arr[0];

   if ((not defined $machine)) {
      $vdLogger->Warn("VNICEvent: machine not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $hash;
   $hash->{controlIP} = $self->{testbed}{testbed}{$machine}{ip};

   if ((not defined $hash->{controlIP}) || (not defined $mac)) {
      $vdLogger->Error("ControlIP and/or mac for $machine not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($operation =~ /add/i) {
      my $matchingAdapter = undef;
      my @result;
      my $retry = 3;

      while ($retry-- > 0) {
         #
         # Collect all the adapters inside the VM and look for the adapter that
         # matches the mac address of the adapter being added.
         #
         @result = VDNetLib::NetAdapter::Vnic::Vnic::GetAllAdapters($hash);
         if ($result[0] eq "FAILURE") {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         foreach my $adapter (@result) {
            $vdLogger->Debug("adapter: $adapter->{'macAddress'} mac:$mac");
           if ($adapter->{'macAddress'} =~ /$mac/i) {
               $matchingAdapter = $adapter;
               last;
            }
         }
         if ((not defined $matchingAdapter) && ($retry > 0)) {
            $vdLogger->Debug("Failed to find the matching adapter." .
                             " Will retry one more time...");
            sleep 10;
         }
      }

      if (not defined $matchingAdapter) {
         $vdLogger->Error("Failed to find matching adapter");
         $vdLogger->Debug("GetAdapters:" . Dumper(@result));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      #
      # Once the new adapter is discovered from guest point of view,
      # create NetAdapter object of type vnic and store in the testbed hash.
      #
      $matchingAdapter->{'vmOpsObj'} = $vmOpsObj;
      $vdLogger->Debug("Matching Adapter:" . Dumper($matchingAdapter));
      my $netObj = VDNetLib::NetAdapter::NetAdapter->new(%{$matchingAdapter});
      if ($netObj eq FAILURE) {
         $vdLogger->Error("Failed to create vnic object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      #
      # Now, find the index under which the new adapter object should be stored
      # in testbed hash.
      #
      my $existingCount = keys %{$self->{testbed}{testbed}{$machine}{Adapters}};
      my $adaptersList = $self->{testbed}{testbed}{$machine}{Adapters};
      my $index = 0;
      for (my $i = 1; $i <= $existingCount; $i++) {
         #
         # Check for only indexes like 1,2 ..., n because vmknic and vmnic are
         # also under $self->{testbed}{testbed}{$machine}{Adapters}
         #
         if (defined $self->{testbed}{testbed}{$machine}{Adapters}{$i}) {
            $index++;
         }
      }
      $index = $index + 1; # new index is max value of available index + 1
      $vdLogger->Info("Adding NetAdapter object for vNic interface " .
                      "$netObj->{interface} with index $index");
      $self->{testbed}{testbed}{$machine}{Adapters}{$index} = $netObj;
      return SUCCESS;
   } elsif ($operation =~ /remove/i) { # event handler code for hotremove
      my $adaptersList = $self->{testbed}{testbed}{$machine}{Adapters};
      my $matchingIndex = undef;
      foreach my $index (keys %{$adaptersList}) {
         if ($adaptersList->{$index}{'macAddress'} =~ /$mac/i) {
            $matchingIndex = $index;
            last;
         }
      }
      if (defined $matchingIndex) {
         $vdLogger->Info("Removing index $matchingIndex from the vnic list");
         delete $self->{testbed}{testbed}{$machine}{Adapters}{$matchingIndex};
         return SUCCESS;
      } else {
         $vdLogger->Error("The given $mac is not part of adapterslist");
         $vdLogger->Debug("AdaptersList:" . Dumper($adaptersList));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unknown operation $operation given for vNic event");
   }

   $vdLogger->Error("Failed to update testbed hash about vNic event");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# GetPortRunningConfigurationEvent --
#      This is callback function of event "GetPortRunningConfiguration".
#      It retrieves the running-configuration of the physical switch port
#      and adds a reference to this object under testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is integer (Required)
#      switchName: name of the switch created (Required)
#      switchType: type of the switch (vdswitch/vswitch) (Required)
#
# Results:
#      "SUCCESS", if the event has been registered into the testbed
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetPortRunningConfigurationEvent
{
   my $self = shift;
   my $portRunConfig = shift;
   my $switchPort = shift;
   my $machine = shift;

   if ((not defined $portRunConfig) ||
       (not defined $switchPort) ||
       (not defined $machine)) {
      $vdLogger->Error("One or more parameters missing to set event");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $portMapHash = $self->{testbed}{testbed}{$machine}{pswitch}{switchObj}{portMap};
   $portMapHash->{runConfig}->{$switchPort} = $portRunConfig;

   $vdLogger->Info("Updated testbed hash with information of running config ".
                   "of switchport $switchPort");

   return SUCCESS;
}


########################################################################
#
# SetIPv4Event --
#      This is callback function of event "SetIPv4".
#      It sets the newly assigned IP address of an interface to the
#      testbed hash.
#
# Input:
#      machine: SUT or helper<x>, where x is integer (Required)
#      ip: new IP address to be updated (Required)
#      index: index of the adapter entry in testbed hash (Required)
#
# Results:
#      "SUCCESS", if the new IP address is updated successfully
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub SetIPv4Event
{
   my $self = shift;
   my %args = @_;

   my $machine  = $args{machine};
   my $ip       = $args{ip};
   my $index    = $args{index};

   if ((not defined $machine) ||
       (not defined $index) ||
       (not defined $ip)) {
      $vdLogger->Error("One or more parameters missing to set event");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{testbed}{testbed}{$machine}{Adapters}{$index}{ipv4} = $ip;

   $vdLogger->Info("Updated testbed hash with information of new IP ".
                   "address: $ip for adapter: $index on $machine");

   return SUCCESS;
}


########################################################################
#
# UpdatePCITestbedInfo--
#     Event handler to refresh the PCI adapters on a VM
#
# Input:
#     machine: SUT or helper<x>
#
# Results:
#     SUCCESS, if the testbed is updated with PCI adapter instances;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdatePCITestbedInfo
{
   my $self = shift;

   my $machine         = shift;

   # TODOVer2 event handler for v2
   if ($self->{testbed}->InitializePCIAdapters($machine) eq FAILURE) {
      $vdLogger->Error("Event handler failed to Initialize PCI adapters");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}
1;
