#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::StatsVerification;

#
# This module gives object of Stats verification. It deals with gathering
# initial and final stats before a test is executed and then taking a diff
# between the two stats.
#

# Inherit the parent class.
require Exporter;
use vars (qw(@ISA));
@ISA = qw(VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

###############################################################################
#
# Start -
#       A common method of all children of statsVerification to get the initial
#       and final state of stats. It's a child method.
#
# Input:
#       state - inital stats or final stats(optional)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub Start
{
   my $self = shift;
   my $state = shift;
   my $veritype = $self->{veritype};

   if (not defined $state){
      $state = "initial";
   }

   $vdLogger->Info("Gathering $state $veritype stats for ".
                   "($self->{nodeid}) on $self->{targetip}");

   if (not defined $veritype) {
      $vdLogger->Error("VerificationType:$veritype missing in StartStats");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # For all nodes in each machine, if the node is supported by the target
   # then get the values of all the counters on that node.
   my $cacheVeriData = $self->{statsbucket};
   my $machine = $self->{targetip};
   my $allNodes = $self->{statsbucket}->{nodes};
   foreach my $node (keys %$allNodes) {
      my $nodeHash = $allNodes->{$node};
      if (((defined $nodeHash->{supported}) && ($nodeHash->{supported} =~ /no/i)) ||
          (defined $nodeHash->{$state})) {
         next;
      }
      # Get the counters and then convert the raw stdout in hash format.
      my $ret = $self->ExecuteStatsCmd($machine, $node);
      if ($ret eq FAILURE || $ret =~ /unsupported/i) {
         $vdLogger->Error("Getting stats failed on $machine for $node");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $hash = $self->ConvertRawDataToHash($ret);
      if ($hash eq FAILURE) {
         $vdLogger->Error("Converting RawData to hash failed on $machine for ".
        "$node" . Dumper($ret));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Store the results in $state of the node
      $nodeHash->{$state} = $hash;
   }

   return SUCCESS;
}


###############################################################################
#
# Stop -
#       StopVerification equivalent method in children for stopping the
#       verification to get the final counters.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub Stop
{
   my $self = shift;
   my $ret = $self->Start("final");
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Stop Stats on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# ExtractResults -
#       GetResults equivalent method in children for getting the results.
#
# Input:
#       none.
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExtractResults
{
   my $self = shift;
   #
   # 1) Do a diff between initial and final values
   #
   my $ret = $self->DoDiff();
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Performing diff on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # 2) Compare the actual value(diff) with the expected value
   # and set pass/fail for the respective counter in each node.
   #
   $ret = $self->CompareNodes();
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Comparing nodes on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# InitVerification -
#       Initialize verification on this object.
#
# Input:
#       expectation key (mandatory)
#       expectation value (mandatory)
#       expectation type (optional)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub InitVerification
{
   my $self = shift;
   $self->{os} = "vmkernel" if $self->{os} =~ /(vmkernel|esx)/i;
   my $veriType = $self->{veritype};
   my $targetNode = $self->{nodeid};
   my $myOS = $self->{os};
   #
   # StatsVerification is just an abstract class(no Obj of its own)
   # The objs are created of stats's children.
   # Now we call RequiredParams on each children to see if he got
   # all the required params from testbed, traffic or other workload.
   # these params should be there in $self at this point of time to
   # move ahead successfully.
   # E,g.
   # For vsish verification and intType = vnic
   # Check for driverName it should be defined for sure.
   # For NIC verification
   # for vnic = interface(eth0) should be defined for sure
   # for pnic = vmnicX should be defined for sure.
   #
   my $allparams = $self->RequiredParams();
   foreach my $param (@$allparams) {
      if (not exists $self->{$param}) {
      $vdLogger->Error("Param:$param missing in InitVerification for $veriType".
                       "Verification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
      }
   }

   # 1) Get the nodes from template.
   # 2) Check if statsNode is defined by user. Which means he wants
   # to collect stats from these nodes only, if defined then
   # compare template and userNode to correct the Case(upper/lower)
   # If not defined then use the template.

   my ($nodeList, $userNodeList, $vsishNodeStr, $templateNodeList, $found);
   my $nodePtr = $self->GetDefaultNode();
   foreach my $os (keys %$nodePtr) {
      next if $os !~ /$myOS/i;
      # Get the nodeList corresponding to the target os type.
      # in case of esx we get vsish nodes and in case of linux+NICSTATS we
      # get ethtool
      $templateNodeList = $nodePtr->{$os};
      if ($os =~ /(esx|vmkernel)/) {
         # In case of vsish nodes a user might specify which vsish nodes
         # he wants to monitor. If he does not then we work on the nodes
         # we got from GetDefaultNode()
         # $vsishNodeStr = $self->{$veriType . "node"};
         $vsishNodeStr = $self->{expectedchange};
         if (defined $vsishNodeStr) {
            # 1) Fixing user given node format. E.g clientstats should
            # be clientStats etc.
            # 2) Remove duplicate nodes. E.g. if user says
            # clientStats.dropTSOTx = 1
            # clientStats.TXByteOk = 1 then we need to read clientStats
            # just once and not make staf calls for each user input.
            foreach my $vsishNode (keys %$vsishNodeStr) {
               my $vsisNodeValue = $vsishNodeStr->{$vsishNode};
               $vsishNode =~ s/(.*)\.(.*)$/$1/;
               $vsishNode = $self->FixUserStatsNodeStr($vsishNode);
               $nodeList->{$vsishNode} = undef if not defined $nodeList->{$vsishNode};
            }
            $found = 0;
            # For each userNode find the corresponding node in templateNode
            # if it matches pick the template node so that even if user
            # gives false upper/lower case of words we use the tempalateNode
            # Mark these nodes found as 'known' else 'unknown'
#            foreach my $uNode (keys %$userNodeList) {
#               foreach my $tNode (keys %$templateNodeList) {
#                  $found = 0;
#                  if ($tNode =~ /^$uNode$/i) {
#                     $nodeList->{$tNode} = $templateNodeList->{$tNode};
#                     $nodeList->{$tNode}->{nodetype} = "known";
#                     $found = 1;
#                     last;
#                  }
#               }
#               $nodeList->{$uNode}->{nodetype} = "unknown" if $found == 0;
#            }
         } else {
            $nodeList = $templateNodeList;
         }
      } else {
         $nodeList = $templateNodeList;
      }
   }

   # For nodes check support
   # 3) Delete nodes which do not belong to this targetdriver
   # type(for VsishStats)
   # 4) delete nodes which does not belong to this pNIC type
   # for NICStats
   # 5) If node is ethtool -X where X is param attach the
   # target interface name to this node.

   foreach my $statsNode (keys %$nodeList) {
      if ($targetNode =~ /vmknic/i) {
         # delete all the vnic related nodes
         if ($statsNode =~ /(vmxnet3|e1000|vmxnet2)/i) {
            delete $nodeList->{$statsNode};
         }
      } elsif ($targetNode =~ /vnic/i) {
         # Check for driverName it should be defined for sure.
         if (($statsNode =~ /(vmxnet3|e1000|vmxnet2)/i) &&
             ($statsNode!~ /$self->{drivername}/i)) {
            delete $nodeList->{$statsNode};
         }
      }
      if ($statsNode=~ /ethtool/i) {
         my $newNode = $statsNode. $self->{interface};
         delete $nodeList->{$statsNode};
         $nodeList->{$newNode}->{nodetype} = "known";
      }
   }


   # 6) Get registered nodes from parent and see if your
   # list of nodes are already registered in cache
   # If not then, we will register them.
   # Reusing the cached nodes saves lot of time and memory in case
   # of vsish node processing.

   my ($registeredNodes, $ret);
   if (exists $self->{myparent}->{cache}) {
      my $cache = $self->{myparent}->{cache};
      $registeredNodes = $cache->{$veriType}->{$self->{targetip}};
   }

   foreach my $node (keys %$nodeList) {
      $found = 0;
      # For all the nodes in the nodeList we are woring on, check if the
      # node already exists in registered nodes.
      if (defined $registeredNodes) {
         # For each registered Node of parent cache, delete the node
         # from the list, as that node is already registered with parent
         foreach my $regNode (keys %$registeredNodes) {
            # 1) If the node start from /net try to compare as it is first
            # 2) If no match, break it from ports/(\d+)/ and then compare
            if ($regNode =~ /\/$node/i) {
               delete $nodeList->{$node};
               $found = 1;
               last;
            } elsif ($node =~ /(PORTNUMBER\/|PORT\/)(.+)/) {
               my $tempNode = $2;
               if (defined $tempNode && $regNode =~ /$tempNode/i) {
                  delete $nodeList->{$node};
                  $found = 1;
                  last;
               }
            }
         }
      }
      # As this node is already registered with parent cache we move
      #  onto next node
      next if $found == 1;
      # Command will either return 'unsupported' or raw data.
      # in case of later we convert it to hash and store it as template so
      # that we can set expected values on those counters.
      # we also say supported = 'yes/no' for these nodes.
      $ret = $self->InitStatsCmd($self->{targetip}, $node);
      $ret = $self->ExecuteStatsCmd($self->{targetip}, $node);
      if (($ret eq "unsupported") || ($ret eq FAILURE)) {
         return FAILURE;
      } else {
         # Convert from raw data to Hash.
         my $hash = $self->ConvertRawDataToHash($ret, 0);
         $self->{statsbucket}->{nodes}->{$node}->{"template"} = $hash;
         $ret = "yes";
      }
      $self->{statsbucket}->{nodes}->{$node}->{"supported"} = $ret;
   }

   return SUCCESS;

}


###############################################################################
#
# FixUserStatsNodeStr -
#       Fixing the syntax in user given StatsNode str.
#
# Input:
#       statsNodeStr (mandatory)
#
# Results:
#       fixed string - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub FixUserStatsNodeStr
{

   # This method will take care of all formats except rxqueue3stats.
   my $self = shift;
   my $statsNodeStr = shift;

   # Replace all - with /
   $statsNodeStr =~ s/-/\//g;

   # Replace all digits with /digits except for vmxnet2clientstats.
   # intr0 will become intr/0, txqueue4 will become txqueue/4
   # TODO: Will enable this check in next version.
   #$statsNodeStr =~ s/(\/*)(\d+)(\W|$)/\/$2$3/g;

   # Replace word queue with queues as understood by esx
   $statsNodeStr =~ s/queue\//queues\//g;

   # Replace all queue/x with queue/x/stats as understool by esx
   # Replace all intr/x with intr/x/stats as understool by esx
   # TODO: Will enable this check in next version.
   #$statsNodeStr =~ s/(queues|intr)\/(\d+)/$1\/$2\/stats/g;

   # Replace all txsummary with txSummary (same for rxsummary)
   # Replace all clientstats with clientStats (same for hdrspstats)
   # Not replace just 'stats' and intr/0/stats txqueue/0/stats
   $statsNodeStr =~ s/(\w)s(ummary|tats)/$1S$2/g;

   # TODO: interpret intr/x/stats as 1 2 3 4 ....
   # Also intr-all-stats, intr-X

   # Fix drivernames if messed up by regex
   $statsNodeStr =~ s/(vmxnet)\/(\d)/$1$2/g;
   $statsNodeStr =~ s/(e)\/(\d+)/$1$2/g;

   $statsNodeStr =~ s/(vmnic)\/(\d)/$1$2/g;
   $statsNodeStr =~ s/(vSwitch)\/(\d)/$1$2/ig;

   return $statsNodeStr;
}



###############################################################################
#
# ConvertRawDataToHash -
#       Converts the raw ethtool and vsish data into hash.
#
# Input:
#       data (mandatory)
#       initialize counters (optional)
#
# Results:
#       stdout of command - in case everything goes well
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ConvertRawDataToHash
{
   my $self = shift;
   my $data = shift;
   my $initCounter = shift;

   my $hash = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $data);
   return $hash;
}


###############################################################################
#
# ExecuteStatsCmd -
#       Execute stats command - which might be vsish or ethool.
#
# Input:
#       target ip (mandatory)
#       Node name (mandatory)
#
# Results:
#       stdout of command - in case everything goes well
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ExecuteStatsCmd
{
   my $self = shift;
   my $targetip = shift;
   my $node = shift;
   my ($command, $result, $vswitch, $portnumber, $vsishPort);

   if (not defined $targetip ||
      not defined $node){
      $vdLogger->Error("Either targetip or node not defined in".
                       " ExecuteStatsCmd.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # The first two usually belong with nic stats. pnic stats are collected from
   # vsish node though.
   #
   if ($node =~ /(ethtool|interrupt|net-dvs)/i) {
      # Covers NIC Stats, ProcINT, Net-DVS
      $command = $node;
   } elsif (($node =~ /pNics/) && ($node !~ /(VMNIC|UPLINK)/)) {
      $command = "vsish -e get " . $node;
   }
   else {
      #
      # This is the if some verification involes getting data from vsish.
      # The node can either be absolute or relative.
      #
      if ($node =~ /^\//) {
         #
         # If node var contains absolute path then it means user
         # has given custom node. See if we need to replace MACROS
         # on this custom node
         # E.g. user can give "/net/portsets/VSWITCH/uplinks/vmnic0/vlanStats/0/stats"
         # or "/net/portsets/PORTSET/ports/PORT/vmxnet3/rxqueue/0/clientStats"
         # then we need to replace VSWITCH, UPLINK, VMNIC, etc
         #
         if ($node =~ /<ACTIVEVMNIC>/) {
            if (not defined $self->{macnode}->{activevmnic}) {
               if ($self->FindActiveVMNic("activevmnic") eq FAILURE) {
                  $vdLogger->Error("Not able to find <ACTIVEVMNIC> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<ACTIVEVMNIC\>\/)/\/$self->{macnode}->{activevmnic}\//g;
         }
         if ($node =~ /(<UPLINK>|<VMNIC>)/) {
            if (defined $self->{nic}) {
               $self->{macnode}->{uplink} = $self->{nic};
            }
            if (not defined $self->{macnode}->{uplink}) {
               if ($self->GetVSISHNodeDetails("uplink") eq FAILURE) {
                  $vdLogger->Error("Not able to find <UPLINK> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<UPLINK\>\/|\/\<VMNIC\>\/)/\/$self->{macnode}->{uplink}\//g;
         }
         if ($node =~ /(<VLAN>|<VLANID>)/) {
            if (not defined $self->{macnode}->{pgvlan}) {
               if ($self->GetVSISHNodeDetails("pgvlan") eq FAILURE) {
                  $vdLogger->Error("Not able to find <VLAN> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<VLAN\>\/|\/\<VLANID\>\/)/\/$self->{macnode}->{pgvlan}\//g;
         }
         if ($node =~ /(<VSWITCH>|<PORTSET>)/) {
            if (not defined $self->{macnode}->{vswitch}) {
               if ($self->GetVSISHNodeDetails("vswitch") eq FAILURE) {
                  $vdLogger->Error("Not able to find <VSWITCH> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<VSWITCH\>\/|\/\<PORTSET\>\/)/\/$self->{macnode}->{vswitch}\//g;
         }
         if ($node =~ /(<PORTNUMBER>|<PORT>)/) {
            if (not defined $self->{macnode}->{vsishportnum}) {
               if ($self->GetVSISHNodeDetails("vsishnodepath") eq FAILURE) {
                  $vdLogger->Error("Not able to find <PORTNUMBER> for ".
                  "$self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<PORTNUMBER\>\/|\/\<PORT\>\/)/\/$self->{macnode}->{vsishportnum}\//g;
         }
         if ($node =~ /(<SCHEDVMNIC>|<SCHEDNODE>)/) {
            $node =~ s/\<SCHEDVMNIC\>/$self->{macnode}->{schedvmnic}/;
            $node =~ s/\<SCHEDNODE\>/$self->{macnode}->{schednode}/;
            $vdLogger->Info("Collecting stats from $node");
         }
         #
         # After substituting all MACROS we get the command we can execute.
         #
         $command = $node;
      } else {
         #
         # If node var is not absolute then it means user
         # has given relative path. Get the vsish node path in this case
         #
         my $vsishNodePath = $self->{macnode}->{vsishnodepath};
         if (not defined $vsishNodePath) {
            $vsishNodePath = $self->GetVSISHNodeDetails("vsishnodepath");
            if ($vsishNodePath eq FAILURE) {
               $vdLogger->Error("Not able to find VSISH Node path for ".
                                "$self->{mac}");
               VDSetLastError("ENOTDEF");
               return "unsupported";
            }
         }
         $command = $vsishNodePath . $node;
      }
      #
      # Now that we got the complete path we apped vsish get in front of it
      # VSISH command should be like
      #~ # vsish -e get /net/portsets/vSwitch1/ports/33554437/clientStats
      #
      $command = "vsish -pe get " . $command;
   }

   $result = $self->{staf}->STAFSyncProcess($targetip, $command);
   if ( (defined $result->{rc}) && (defined $result->{exitCode}) &&
       ($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("command:$command failed on $targetip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stderr} &&
      $result->{stderr} =~ /(bad command|not found|invalid|path|VSISHPath_Form|Not supported)/i) {
      # For vsish node not found
      # ~ # vsish -e get /net/portsets/vss-0-1614/ports/50331982/watever
      # VSISHPath_Form():Extraneous 'watever' in path.
      # VSISHCmdGetInt():mal-formed path
      # For ethtool -Y where ethool -Y ethX is not supported
      $vdLogger->Debug("Dump of $command on $targetip " . Dumper($result));
      return "unsupported";
   }

   if (defined $result->{stdout} &&
      $result->{stdout} ne "") {
      return $result->{stdout};
   }

   return "unsupported";
}


###############################################################################
#
# GetVSISHNodeDetails -
#       Get the vsish node details like portgroup id, name, vswitch name for
#       a given mac address.
#
# Input:
#       element - what attribute one is looking for from vsish node (mandatory)
#       options - can pass some parameters to save time. E.g. vswitch
#                 name (optional)
#
# Results:
#       element - vsish node element which was requested.
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVSISHNodeDetails
{
   my $self = shift;
   my $element = shift;
   my $options = shift;

   # Our center point is the mac address associated to the SUT.
   # we use mac to find the vsish path, pgName, vlan id etc or other details
   if (not defined $self->{mac}) {
      $vdLogger->Error("macAddress of $self->{nodeid} to find VSI Port ".
                       "details is missing");
      VDSetLastError("ENOTDEF");
      return "unsupported";
   }
   $self->{macnode}->{macaddress} = $self->{mac};

   if (defined $self->{macnode}->{$element}) {
      return   $self->{macnode}->{$element};
   }

   # If the element is not found then we will find it and cache it.
   # There are different ways to find differnet elements.
   # Entry point is always mac address.
   # 1) Using mac address
   #    a) Find the portgroup from vmx file
   #    b) Find the VSI node path from VSISH nodes portset/status and
   #       grepping from mac address
   # a) is fast - just return pgName
   # b) is expensive - returns vswitch name & pgName also

   # For a) look for that pgObj in testbed hash.
   #        If pgObj is found call GetPGProperties on pgObj and find vlanid
   #        Also pgObj will contain vswitch name.
   #        Use this vswitch name to find the corresponding vswitch Obj
   #        in testbed and thus find the uplink for this vswitch
   #        If Switch/PortGroup are not updated in testbed at runtime then Objs
   #        won't be there thus fallback on technique b)
   # For b) we already know the vswitch use it.

   # In case of vsishNodePath we skip the faster method because it
   # does not give that data.

   # In all other case we first try with a) and then with b)

   # TODO: Harish's suggestions to make it work for vds as well
   # okay, here is the solution to make it work for vds,
   # 1) From the mac get the dvport (HostOperation::GetvNICDVPort method).
   # 2) get the dvs portset name.
   # 3) find the mapping b/w vds portset and vds.. (i think HostOperation
   # does have a method to do this but i can't recall this right now)

   if ($element !~ /vsishnodepath/) {
      #
      # 1) We know the MAC of vNIC.
      # 2) Call hostobj->GetPGFromMAC
      # 3) After getting the PG name, match the PG name in the list of PGs
      #    to find the PG Obj
      # 4) On the PG obj do GetPGProperties to find pgName and vlan id
      # 5) PG Obj has the vswitch name. Use it to find the vswitch Obj
      #    and find the attribute uplink from this vswitch Obj.
      # Note, references to all Objs are used from testbed.
      #
      if (defined $self->{vmx}) {
         if (not defined $self->{portgroups}) {
            $vdLogger->Trace("portgroups obj array to find VSI ".
                             "Port details of $self->{nodeid} is missing");
         }
         $vdLogger->Info("Finding PGName corresponding to $self->{mac}".
                         "($self->{nodeid}) on $self->{targetip} for $self->{vmx}");
         my $hostObj = $self->{hostobj};
         if (not defined $hostObj) {
            $vdLogger->Trace("hostObj from testbed is missing. ".
                          "Can't call GetPGNameFromMAC");
            goto FALLBACK;
         }
         my $pgName = $hostObj->GetPGNameFromMAC($self->{vmx},$self->{mac});
         if ($pgName eq FAILURE){
            $vdLogger->Warn("Getting PGName for $self->{mac} on ".
                             "$self->{targetip} failed. ".
                             "Using fallback...");
            goto FALLBACK;
         }
         #
         # Now that we know the pgname. lets find its Obj.
         #
         my $pgArray;
         my $pgFoundFlag = 0;
         if ($self->{testbed}{version} != 1) {
            my $tuple = "host.[-1].portgroup.[-1]";
            $vdLogger->Debug("Getting all pg objects");
            $pgArray =  $self->{testbed}->GetComponentObject($tuple);
         } else {
            $pgArray = $self->{portgroups};
         }
         foreach my $pgObj (@$pgArray) {
            if ($pgObj->{pgName} =~ $pgName) {
               $pgFoundFlag = 1;
               #
               # This is the portgroup obj in testbed we are looking for.
               # as its the portgroup on which the vNIC is connected.
               #
               my $pgHash = $pgObj->GetPGProperties();
               if ($pgHash eq FAILURE) {
                  $vdLogger->Warn("Getting PG Properties for $pgName on ".
                                    "$self->{targetip} failed");
                  goto FALLBACK;
               }
               $vdLogger->Trace("Got PG properties:" . Dumper($pgHash));
               if (not defined $pgHash->{vlan}){
                  $vdLogger->Trace("There is no vlan id for:".
                                   Dumper($self->{macnode}));
               } else {
                  $self->{macnode}->{pgvlan} = $pgHash->{vlan};
               }
               #
               # Storing the switch name from the porgroup obj we got
               # and using it to find the uplink from the list of
               # switch objs in the testbed.
               #
               my $switch = $pgObj->{switch};
               if (not defined $switch) {
                  $vdLogger->Warn("switch name missing in pgObj" . Dumper($pgObj));
                  goto FALLBACK;
               }
               $self->{macnode}->{vswitch} = $pgObj->{switch};
               my $switchObj = $hostObj->{switches}->{$switch};
               if (not defined $switchObj) {
                  $vdLogger->Trace("Not able to find switch:$switch Obj ".
                                   "in testbed for $self->{mac}");
                  $vdLogger->Trace("Switches:" . Dumper($hostObj->{switches}));
               }
               my $uplink = $switchObj->{uplink};
               if (not defined $uplink){
                  $vdLogger->Trace("There is no uplink for:".
                                  Dumper($self->{macnode}));
               } else {
                  $self->{macnode}->{uplink} = $uplink;
               }
               $vdLogger->Trace("Node info for $self->{mac}:".
                                 Dumper($self->{macnode}));
            }
         }
         $vdLogger->Trace("$self->{mac} is on $pgName portgroup. Exacting info...");
         if ($pgFoundFlag == 0) {
            $vdLogger->Trace("Not able to find portgroup:$pgName Obj ".
                             "in testbed for $self->{mac}");
            $vdLogger->Trace("Portgroups:" . Dumper($self->{portgroups}));
         }
      } else {
         goto FALLBACK;
      }
   }

FALLBACK:
   # This is the slower method b) we fall back on.
   #
   # Just finds the vsishNodePath. One can obtain vswitch & pgname
   # info from it
   #
   # 1) We know the MAC of vNIC.
   # 2) Call hostobj->GetvNicVSIPort which returns the vsish node path
   # for that vNIC based on the vNIC's mac address.
   #
   my $hostObj = $self->{hostobj};
   if (not defined $hostObj) {
      my $hostModule = "VDNetLib::Host::HostOperations";
      eval "require $hostModule";
      if ($@) {
         $vdLogger->Error("hostObj from testbed is missing. ".
                          "Tried loading new HostOperations.pm, ".
                          "that too failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $hostObj = $hostModule->new($self->{targetip});
      if ($hostObj eq FAILURE) {
         $vdLogger->Error("hostObj from testbed is missing. ".
                          "Tried created new hostObj, that too failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $self->{hostobj} = $hostObj;
   }
   if ((not defined $self->{macnode}->{pgname}) ||
       (not defined $self->{macnode}->{vswitch}) ||
       (not defined $self->{macnode}->{vsishnodepath} &&
        $element =~ /vsishnodepath/)) {
      $vdLogger->Info("Finding VSI node path corresponding to $self->{mac}".
                     "($self->{nodeid}) on $self->{targetip} ...");

      my ($hash, $vsishNodePath) = $hostObj->GetvNicVSIPort(
                                                 $self->{mac},
                                                 $self->{macnode}->{vswitch}
                                                          );
      if ($hash eq FAILURE){
         $vdLogger->Error("Fetching VSISH Port failed for $self->{mac} ");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ((not defined $hash->{pgname}) ||
         (not defined $hash->{vswitch}) ||
         (not defined $hash->{vsishportnum})){
         $vdLogger->Error("Could not get either pgname or vswitch or".
                          "vsishportnum from GetvNicVSIPort");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Saving it so that we don't have to calculate next time.
      $vsishNodePath = $vsishNodePath . "/";
      $self->{macnode}->{vsishnodepath} = $vsishNodePath;
      $self->{macnode}->{vswitch} = $hash->{vswitch};
      $self->{macnode}->{pgname} = $hash->{pgname};
      $self->{macnode}->{vsishportnum} = $hash->{vsishportnum};
      $vdLogger->Trace("Node info for $self->{mac}:".
                        Dumper($self->{macnode}));
  }

  if ($element !~ /vsishnodepath/) {
     my $pgModule = "VDNetLib::Switch::VSSwitch::PortGroup";
     eval "require $pgModule";
     if ($@) {
        $vdLogger->Error("hostObj from testbed is missing. ".
                         "Tried loading new HostOperations.pm, ".
                         "that too failed");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
     my $pgObj = $pgModule->new(pgName => $self->{macnode}->{pgname},
                                hostip => $self->{targetip},
                                switch => $self->{macnode}->{vswitch});
     if ($pgObj eq FAILURE) {
        $vdLogger->Error("pgObj from testbed is missing. ".
                         "Tried created new pgObj, that too failed");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
     # Get the uplink and vlan from this method.
     my $rethash = $pgObj->PortGroupGetUplinkAndVLAN($self->{macnode}{vswitch});
     if ($rethash eq FAILURE) {
        $vdLogger->Error("PortGroupGetUplinkAndVLAN ".
                         "returned failed");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
     # Get the vlan from the hash
     if (not defined $rethash->{vlanid}){
        $vdLogger->Trace("There is no vlan id for:" . Dumper($self->{macnode}));
     } else {
        $self->{macnode}->{pgvlan} = $rethash->{vlanid};
     }
     # Get the uplink from the hash
     if (not defined $rethash->{uplink}){
        $vdLogger->Trace("There is no uplink for:" . Dumper($self->{macnode}));
     } else {
        $self->{macnode}->{uplink} = $rethash->{uplink};
     }
     $vdLogger->Trace("Node info for $self->{mac}:".
                      Dumper($self->{macnode}));
  }

   # Return the element requested by the user.
   if (defined $self->{macnode}->{$element}) {
      return $self->{macnode}->{$element};
   } else {
      $vdLogger->Error("Not able to find vsish element:$element for ".
                       "$self->{mac} from vsish nodes");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


###############################################################################
#
# FindActiveVMNic -
#       Find the active vmnic from the nic teaming by using the load balancing
#       settings of the vswitch.
#
# Input:
#       element - what attribute one is looking for from vsish node (mandatory)
#       options - can pass some parameters to save time. E.g. vswitch
#                 name (optional)
#
# Results:
#       element - vsish node element which was requested.
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub FindActiveVMNic
{
   my $self = shift;
   my $element = "activevmnic";
   my $options = shift;

   # Our center point is the mac address associated to the SUT.
   # we use mac to find the vsish path, pgName, vlan id etc or other details
   if (not defined $self->{macnode}->{vsishnodepath}) {
      if ($self->GetVSISHNodeDetails("vsishnodepath") eq FAILURE) {
         $vdLogger->Error("Not able to find vsishnodepath for $self->{mac}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   $vdLogger->Trace("Node info for $self->{mac}:" . Dumper($self->{macnode}));

   my ($vnicObj, $pgObj,$vmObj);
   my $switchName = $self->{macnode}->{vswitch};
   my $hostObj = $self->{hostobj};
   my $switchObj = $self->{switchobj};
   if (not defined $switchObj) {
      my $type = "vswitch";
      if ($switchName =~ /portset/i) {
         #
         # In case of vdswitch, the vsish tree has switch names as
         # portset names (which is different from what is seen on VC).
         # Since, this verification module makes use of both esxcli/staf sdk
         # related APIs as well as vsish, all different aliases of the switch
         # corresponding to the src adapter need to be found.
         #
         $switchName = $hostObj->GetDVSNameFromPortset($switchName);
         if ($switchName eq FAILURE) {
            $vdLogger->Error("Failed to get switch name from portset");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $self->{macnode}{vswitch} = $switchName;
         my $vsishNodePath = $self->{macnode}->{vsishnodepath};
         my $command = "vsish -pe get $vsishNodePath" . "status";
         my $result = $hostObj->{stafHelper}->STAFSyncProcess($hostObj->{hostIP},
                                                              $command);

         # check for success or failure of the command executed using staf
         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to obtain the portset info");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         #
         # Similar to switch name, the portgroups in a switch is also represented
         # with different forms such port ids, portgroup names (vc), portgroup
         # keys. Each alias is with respect to host/vc/esxcli.
         #
         # For this verification process, the port id (integer) corresponding to
         # the source adapter's portgroup need to be found.
         #
         my $dvPortGroupID;
         if ($result->{stdout} =~ /dvPortId\"\s+\:\s+\"(\d+)\"/i) {
            $dvPortGroupID = $1;
         } else {
            $vdLogger->Debug("Executing $command, Result:". Dumper($result));
         }
         $self->{macnode}{pgname} = $dvPortGroupID;

         $type = "vdswitch"; # use dvswitch for now.
      }

      my $tuple = $self->{nodeid};
      $vdLogger->Info("Getting vnic object for $tuple");
      my $refVnicObj =  $self->{testbed}->GetComponentObject($tuple);

      $vnicObj = $refVnicObj->[0];
      $pgObj = $vnicObj->{pgObj};
      $vmObj = $vnicObj->{vmOpsObj};
      $hostObj = $vmObj->{hostObj};
      $switchObj = $pgObj->{switchObj};
      $self->{switchobj} = $switchObj;
   }

   $vdLogger->Trace("Virtual switch name of $self->{mac} is $switchName");
   $vdLogger->Trace("Port id of $self->{mac} on $self->{targetip} is " .
                   $self->{macnode}{pgname});
   my $portID = $self->{macnode}{pgname};
   my $teamPolicy = "FAILURE";
   if ($switchObj->{'switchType'} eq "vswitch") {
      # for vswitch
      $teamPolicy = $switchObj->{switchObj}->GetvSwitchNicTeamingPolicy();
   } else {
      # in case of vdswitch
      $teamPolicy = $hostObj->GetDVSTeamPolicy($switchObj->{'switch'},
                                               $self->{macnode}{pgname});
   }

   $vdLogger->Debug("Team policy : " . Dumper($teamPolicy));

   #
   # From the teaming policies, retrieve the load balancing option set on the
   # switch.
   #
   my $loadBalancing = $teamPolicy->{'Load Balancing'};
   $vdLogger->Info("Load balancing option on $self->{mac} is $loadBalancing");

   my $activeVMNIC;
   my $esxTopData;

   if ($loadBalancing =~ /srcport/) {
      $vdLogger->Info("Using srcport algorithm to find active vmnic");
      $activeVMNIC = $switchObj->GetActiveVMNic($self->{macnode}{vsishportnum},
                                                undef,
                                                $self->{macnode}{pgname},
                                                $hostObj);
   } elsif ($loadBalancing =~ /srcmac/i) {
      $vdLogger->Info("Using srcmac algorithm to find active vmnic");
      $activeVMNIC = $switchObj->GetActiveVMNic($self->{mac},
                                                undef,
                                                $portID,
                                                $hostObj);
   } elsif ($loadBalancing =~ /iphash/i) {
      $vdLogger->Info("Using iphash algorithm to find active vmnic");
      if (not defined $self->{workloadhash}->{server}->{testip}) {
         $vdLogger->Error("workload hash does not contain server's testip. ".
                          "It is required to calculate iphash active vmnic".
                          Dumper($self->{workloadhash}));
         VDSetLastError("ENOTFOUND");
         return FAILURE;
      }
      my $dstIP = $self->{workloadhash}->{server}->{testip};
      my $srcIP = $self->{workloadhash}->{client}->{testip};
      $vdLogger->Debug("activevmnicverification: Src IP and Dst ".
                       "IP:$srcIP, $dstIP");
      $activeVMNIC = $switchObj->GetActiveVMNic($srcIP,
                                                $dstIP,
                                                $portID,
                                                $hostObj);
   } else {
      $vdLogger->Info("Using explicit/teamUplink method to find active vmnic");
      $activeVMNIC =
         $hostObj->GetActiveVMNicOfvNic($self->{mac});
         $esxTopData = $activeVMNIC; # active uplink shown on esxtop/vsish is
                                     # needed at multiple places, so saving it.
   }

   if ((not defined $activeVMNIC) ||
      ($activeVMNIC eq "") ||
      ($activeVMNIC eq FAILURE)) {
      $vdLogger->Error("Failed to find the active vmnic for $self->{mac}".
		       " on $self->{targetip}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($activeVMNIC =~ /dvuplink/i) {
      $activeVMNIC = $hostObj->GetActiveDVUplinkPort($self->{macnode}{vswitch},
                                                     $activeVMNIC);
   }
   $vdLogger->Info("Active vmnic computed for $self->{mac} is $activeVMNIC");
   if ($activeVMNIC eq FAILURE) {
      $vdLogger->Error("Failed to get active vmnic of $self->{mac} on ".
                       "$self->{targetip}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{macnode}{activevmnic} = $activeVMNIC;


   if ((defined $teamPolicy->{'Standby Adapters'}) &&
       ($teamPolicy->{'Standby Adapters'} ne "")){
      #
      # If standby adapters are defined in the switch's teaming policy,
      # then it is important to ensure that the active uplink shown on
      # esxtop is not any of the standby adapters.
      #
      $vdLogger->Info("Standby adapters:$teamPolicy->{'Standby Adapters'}");
      if (not defined $esxTopData) {
         $esxTopData = $switchObj->GetTeamUplink($self->{macnode}{vsishportnum});
         if ($esxTopData eq FAILURE) {
            $vdLogger->Error("Failed to get active vmnic of $self->{mac} on ".
                             "$self->{targetip}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      #
      # Check if the number of active adapters is greater than or equal to 1.
      # If true, then verify that the active uplink is not any of the adapters
      # under standby mode.
      #
      if (scalar(@{$teamPolicy->{'ActiveAdapters'}})) {
         if ($esxTopData =~ /$teamPolicy->{'Standby Adapters'}/) {
            $vdLogger->Error("Active VMNic computed should not be part of " .
                            "standby adapters $teamPolicy->{'Standby Adapters'}");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   } else {
      $vdLogger->Trace("No standby adapters configured");
   }

   if (defined $self->{macnode}->{$element}) {
      return   $self->{macnode}->{$element};
   } else {
      $vdLogger->Error("Not able to find vsish element:$element for ".
                       "$self->{mac} from vsish nodes");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


###############################################################################
#
# GetDVPortNum -
#       Find the active vmnic from the nic teaming by using the load balancing
#       settings of the vswitch.
#
# Input:
#       element - what attribute one is looking for from vsish node (mandatory)
#       options - can pass some parameters to save time. E.g. vswitch
#                 name (optional)
#
# Results:
#       element - vsish node element which was requested.
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDVPortNum
{
   my $self = shift;
   my $element = "dvportnum";
   my $options = shift;

   # Our center point is the mac address associated to the SUT.
   # we use mac to find the vsish path, pgName, vlan id etc or other details
   if (not defined $self->{macnode}->{vsishnodepath}) {
      if ($self->GetVSISHNodeDetails("vsishnodepath") eq FAILURE) {
         $vdLogger->Error("Not able to find vsishnodepath for $self->{mac}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   $vdLogger->Trace("Node info for $self->{mac}:" . Dumper($self->{macnode}));
   my $hostObj = $self->{hostobj};

   my $vsishNodePath = $self->{macnode}->{vsishnodepath};
   $vsishNodePath =~ s/\/$//;
   # Get the dvs port ID
   $self->{macnode}->{$element} = $hostObj->GetvNicDVSPortID($self->{mac},
                                                             $vsishNodePath);
   if ($self->{macnode}->{$element} eq FAILURE) {
      $self->{macnode}->{$element} = undef;
   }

   if (defined $self->{macnode}->{$element}) {
      return   $self->{macnode}->{$element};
   } else {
      $vdLogger->Error("Not able to find vsish element:$element for ".
                       "$self->{mac} from vsish nodes");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#
# Input:
#       None
#
# Results:
#       array - containing names of child modules
#
# Side effects:
#       None
#
###############################################################################

sub GetMyChildren
{
   return ["NIC", "VSISH", "ProcINT", "dvPort"];
}


###############################################################################
#
# GetBucket -
#       Get the name of the bucket storing stats.
#
# Input:
#       None
#
# Results:
#       ptr to bucket.
#
# Side effects:
#       None
#
###############################################################################

sub GetBucket
{
   my $self = shift;
   return $self->{statsbucket};
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


###############################################################################
#
# InitStatsCmd -
#       Execute stats command - which might be vsish or ethool.
#
# Input:
#       target ip (mandatory)
#       Node name (mandatory)
#
# Results:
#       Set all vsish nodes to be zero.
#       stdout of command - in case everything goes well
#       "unsupported" - in case a node or ethool option is not supported
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub InitStatsCmd
{
   my $self = shift;
   my $targetip = shift;
   my $node = shift;
   my ($command, $result, $vswitch, $portnumber);

   if ((not defined $targetip) ||
      (not defined $node)){
      $vdLogger->Error("Either targetip or node not defined in".
                       " InitStatsCmd.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # The first two usually belong with nic stats. pnic stats are collected from
   # vsish node though.
   #
   if ($node =~ /(ethtool|interrupt|net-dvs)/i) {
      # Covers NIC Stats, ProcINT, Net-DVS
      $command = $node;
   } elsif ($node =~ /pNics/) {
      $command = "vsish -e set " . $node . " 0";
   } else {
      #
      # This is the if some verification involes getting data from vsish.
      # The node can either be absolute or relative.
      #
      if ($node =~ /^\//) {
         #
         # If node var contains absolute path then it means user
         # has given custom node. See if we need to replace MACROS
         # on this custom node
         # E.g. user can give "/net/portsets/VSWITCH/uplinks/vmnic0/vlanStats/0/stats"
         # or "/net/portsets/PORTSET/ports/PORT/vmxnet3/rxqueue/0/clientStats"
         # then we need to replace VSWITCH, UPLINK, VMNIC, etc
         #
         if ($node =~ /<ACTIVEVMNIC>/) {
            if (not defined $self->{macnode}->{activevmnic}) {
               if ($self->FindActiveVMNic("activevmnic") eq FAILURE) {
                  $vdLogger->Error("Not able to find <ACTIVEVMNIC> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<ACTIVEVMNIC\>\/)/\/$self->{macnode}->{activevmnic}\//g;
         }
         if ($node =~ /(<UPLINK>|<VMNIC>)/) {
            if (not defined $self->{macnode}->{uplink}) {
               if ($self->GetVSISHNodeDetails("uplink") eq FAILURE) {
                  $vdLogger->Error("Not able to find <UPLINK> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<UPLINK\>\/|\/\<VMNIC\>\/)/\/$self->{macnode}->{uplink}\//g;
         }
         if ($node =~ /(<VLAN>|<VLANID>)/) {
            if (not defined $self->{macnode}->{pgvlan}) {
               if ($self->GetVSISHNodeDetails("pgvlan") eq FAILURE) {
                  $vdLogger->Error("Not able to find <VLAN> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<VLAN\>\/|\/\<VLANID\>\/)/\/$self->{macnode}->{pgvlan}\//g;
         }
         if ($node =~ /(<VSWITCH>|<PORTSET>)/) {
            if (not defined $self->{macnode}->{vswitch}) {
               if ($self->GetVSISHNodeDetails("vswitch") eq FAILURE) {
                  $vdLogger->Error("Not able to find <VSWITCH> for $self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<VSWITCH\>\/|\/\<PORTSET\>\/)/\/$self->{macnode}->{vswitch}\//g;
         }
         if ($node =~ /(<PORTNUMBER>|<PORT>)/) {
            if (not defined $self->{macnode}->{vsishportnum}) {
               if ($self->GetVSISHNodeDetails("vsishnodepath") eq FAILURE) {
                  $vdLogger->Error("Not able to find <PORTNUMBER> for ".
                  "$self->{mac}");
                  VDSetLastError("ENOTDEF");
                  return FAILURE;
               }
            }
            $node =~ s/(\/\<PORTNUMBER\>\/|\/\<PORT\>\/)/\/$self->{macnode}->{vsishportnum}\//g;
         }
         #
         # After substituting all MACROS we get the command we can execute.
         #
         $command = $node;
      } else {
         #
         # If node var is not absolute then it means user
         # has given relative path. Get the vsish node path in this case
         #
         my $vsishNodePath = $self->{macnode}->{vsishnodepath};
         if (not defined $vsishNodePath) {
            $vsishNodePath = $self->GetVSISHNodeDetails("vsishnodepath");
            if ($vsishNodePath eq FAILURE) {
               $vdLogger->Error("Not able to find VSISH Node path for ".
                                "$self->{mac}");
               VDSetLastError("ENOTDEF");
               return "unsupported";
            }
         }
         $command = $vsishNodePath . $node;
      }
      #
      # Now that we got the complete path we append vsish set in front of it
      # VSISH command should look like
      #~ # vsish -e set /net/portsets/vSwitch1/ports/33554437/clientStats
      #
      $command = "vsish -e set " . $command . " 0";
   }

   $result = $self->{staf}->STAFSyncProcess($targetip, $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("command:$command failed on $targetip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stderr} ||
      $result->{stderr} =~ /(bad command|not found|invalid|path|VSISHPath_Form|Not supported)/i) {
      # For vsish node not found
      # ~ # vsish -e get /net/portsets/vss-0-1614/ports/50331982/watever
      # VSISHPath_Form():Extraneous 'watever' in path.
      # VSISHCmdGetInt():mal-formed path
      # For ethtool -Y where ethool -Y ethX is not supported
      $vdLogger->Debug("Dump of $command on $targetip " . Dumper($result->{stdout}));
      return "unsupported";
   }

   if ((defined $result->{stdout}) &&
      $result->{stdout} ne "") {
      return $result->{stdout};
   }

   return "unsupported";
}
1;
