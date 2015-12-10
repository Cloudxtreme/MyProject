
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Verification::Verification;

#
# 1) It acts as an interface to outside world for using any sort of test
# verification like Netstat, vmware.log, dmesg, PacketCapture, vsish.
# 2) Interface that any verification technique must adhere to, in order to
# work with vdNet automation.
# 3) Acts as a parent to other verification modules so that parent provides a
# common code to all child modules and they only need to implement
# methods which are specific that child.
# 4) Creates all children(child classes) based on default behavior and
# based on what verification hash has been provided.

# Usage:
########################################################################
#
# http://engweb.vmware.com/~gaggarwal/New_Verification_presentation.pptx
#
########################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Data::Dumper;
use Switch;

# For printing the results in a tabular format.
use Text::Table;

use VDNetLib::Workloads::Utils;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
#
# These are most of the features a user can use to monitor
# counters. E.g. a user can say alltso => "change" and this
# will monitor if all tso realted counters are changing or not
#
my @allFeatures = ("tso", "multicast", "broadcast", "unicast",
                   "dd", "queue", "headers", "uplink",
                   "pkt-handle", "lro", "ring", "buffer",
                   "zerocopy", "sw", "allocation", "split",
                   "actions", "csum", "offload", "clone");
#
# We monitor all -ve counters if user wants so. He can say
# defaultMonitoring => "on/error", (on|off|error|workload)
# But they dont take part in pass or fail scenario. They just warn user
# about possible bad scenarios.
# They are considered in results only if user doesn't pass any expected output
#
my @allErrors = ("fail", "discard", "drop", "error", "stale",
                 "overflow", "invalid", "miss", "abort",
                 "timeout", "retransmission", "rst", "bad",
                 "exceptions");
#
# These are aliases used for counters in diffrent systems. E.g.
# some counters are called headers and same counters in some other
# system are called hdrs, thus we check alias as well when users passes one.
# Error and Buffer are special cases where only one way mapping is required
#
my $aliases = {
   drop => "drp",
   drp => "drop",
   error => "err",
   header => "hdr",
   hdr => "header",
   broadcast => "bcast",
   bcast => "broadcast",
   multicast => "mcast",
   mcast => "multicast",
   unicast => "ucast",
   ucast => "unicast",
   buffer => "buf",
   receive => "rx",
   rx  => "receive",
   transmit => "tx",
   tx  => "transmit",
};

use constant DEFAULT_MONITORING => "no";

# Flag to keep old testcase still working with new verification.
# 1) The difference is that in new verification you cannot run a
# verification module without setting any expectation.
# Thus this flag generats default expectation for the old testcase
# so that they run with this new code.
# 2) For some Verification Types the target is compulsory, to make
# the code backward compatible we take default targets. But this
# behavior will be reset once all testcase follow new Verification.
use constant BACKWARD_COMPATIBLE => 1;

my @operationalKeys = qw(sleepbeforefinal);

###############################################################################
#
# new -
#       This package acts as a interface of Verification module and as
#       parent class of all verification jobs. new() creates object for child
#       classes of this module. It does so by providing a common interface
#       for object creation and object use.
#
# Input:
#       testbed - Hash containing testbed (mandatory)
#       verificationhash - hash containing verifiction keys/value pairs (mandatory)
#       workloadhash - workload which calls this verification module (optional)
#
# Results:
#       SUCCESS - A pointer to child instance/object of Verification
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
   if (not defined $options{testbed} ||
       not defined $options{verificationhash}) {
      $vdLogger->Error("testbed or verificationhash missing in Verification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Create a duplicate copy of the given verification hash
   my $tempVerify = $options{verificationhash};
   my %temp = %$tempVerify;
   my $dupVerification = \%temp;

   # Make all the keys (not values) in verificationhash lowercase
   %$dupVerification = (map { lc $_ => $dupVerification->{$_}} keys %$dupVerification);

   my $self  = {
     'testbed'      => $options{testbed},
     'verihash'     => $dupVerification,
      # This is same dir which testbed + workload dir
      # E.g. /vdnetlogs/TIMESTAMP/TESTCASE/TRAFFICWorkload/
     'localLogsDir' => $options{localLogsDir},
   };

   #
   # The LogsDir is the /tmp on MC
   # TODO: If the workload has some session id then attach that as well
   # as it would be easier to map the verification logs with the workload.
   #
   my $sourceDir;
   if (not defined $self->{localLogsDir}) {
      $sourceDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   } else {
      $sourceDir = $self->{localLogsDir};
   }

   if ($sourceDir !~ /\/$/) {
      $sourceDir = $sourceDir . "/";
   }

   my $timeStamp = VDNetLib::Common::Utilities::GetTimeStamp();
   $self->{localLogsDir} = $sourceDir . "Verification-". $timeStamp;
   unless(-d $self->{localLogsDir}){
      my $ret = `mkdir -p $self->{localLogsDir}`;
      if ($ret ne "") {
         $vdLogger->Error("Failed to create verification logs dir:".
                          "$self->{localLogsDir}");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $vdLogger->Debug("Verification log collected at:$self->{localLogsDir}");
   }
   if($self->{localLogsDir} !~ /\/$/) {
      $self->{localLogsDir} = $self->{localLogsDir} . "/";
   }

   #
   # Checking if workloadhash should be required param will be done as
   # and when required.
   #
   $self->{workloadhash} = $options{workloadhash}
                                   if defined $options{workloadhash};

   # Reusing the staf handle from testbed, if not create it.
   if (not defined $self->{staf}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{staf} = $temp;
   }

   #
   # Blessing now so that we can start calling object methods
   # inside new itself.
   #
   bless $self, $class;

   # Freeing some temp resources.
   $tempVerify = undef;
   %options = ();

   #
   # A user can pass a list of negative counters he wants to monitor by
   # default. User can do so using key negativecounters.
   # Attaching global counters to parent so that each child can inherit it
   # during creation of child classes.
   #
   if (defined $self->{verihash}->{negativecounters}) {
      my @tempAllErrors;
      if($self->{verihash}->{negativecounters}=~ /\,/) {
         @tempAllErrors  = split(',', $self->{verihash}->{negativecounters});
      } else {
         $tempAllErrors[0] = $self->{verihash}->{negativecounters};
      }
      $self->{counters}->{allerrors} = \@tempAllErrors;
   } else {
      $self->{counters}->{allerrors} = \@allErrors;
   }
   $self->{counters}->{aliases} = $aliases;
   $self->{counters}->{allfeatures} = \@allFeatures;

   #
   # Input should have hashes defined where verification Type
   # is the unique element in each hash. If not hash then return error.
   # Foreach hash, read the verificationtype first, if not defined then error.
   # Then read the target, if target not defined its
   # ok(backward compatible) - use default target. E.g. dst for pktcap(as per
   # old verification)
   # Now for each combo (verificationType, target) call createchildren().
   # After Obj creation, target and verificationKey keys can be removed from the hash.
   # Rest remaining keys are expectedChange, Each obj will point to his own
   # expectedChange hash.
   # Use a FLAG, if expectedChanges are not defined use a default
   # ExpectedChange hash(to keep code backward compatible)
   #
   my $noBlockFound = 0;
   foreach my $veriBlock (values %$dupVerification) {
      if(ref($veriBlock) =~ /HASH/i) {
         $noBlockFound = 1;
         if(not defined $veriBlock->{verificationtype}) {
            $vdLogger->Error("verificationtype key not defined in ".
                             Dumper($veriBlock));
            $vdLogger->Error("Check for case sensitive also");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         } else {
            #
            # TODO: Remove leading and trailing spaces before and after commas.
            # E.g. In VerificationType = "Pktcap , stats, log" Remove spaces.
            # TODO: Will do this check in next version of Verification.
            $self->RemoveSpaceAndMakeLC($veriBlock);
            #
            # We call ProcessTargetKey here so that when nodes are discovered
            # parent can cache them so that other children can just use it
            # instead of disocovering again and again.
            # As its just a trigger we dont use the result of ProcessTargetKey
            # to verify anything.
            # # TODO: Keeping code just in case we want to resolve src, dst
            # words into something else in future.
            # #TODO: PR#: 793676
            #   if (defined $veriBlock->{target}) {
            #      if ($self->ProcessTargetKey($veriBlock->{target}) eq FAILURE) {
            #         $vdLogger->Error("Not all nodes found. Desired $veriBlock->{target}.".
            #                          " Found:". Dumper($self->{nodes}));
            #         $vdLogger->Error("Add it in Parameters section of testcase hash");
            #         VDSetLastError("ENOTDEF");
            #         return FAILURE;
            #      }
            #   }
            #
            # Child modules are created based on two params. Type of child * target
            # Thus if target = "dsthost, helper2:vnic:2" and
            # StatsType => “nic, protocol, ethernet" we will have create 2 * 3 = 6
            # child classes. Then the ones which do not qualify w.r.t.
            # platform/drivertype/os distro/kernel version etc are dropped
            # as they declare themselves as "unsupported"
            #
            my $ret = $self->CreateChildren($veriBlock);
            if ($ret ne SUCCESS) {
               $vdLogger->Error("Creating objects failed in Verification");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         }
      }
   }

   if ($noBlockFound == 0) {
      $vdLogger->Error("No verification block found as input to verification.pm");
      VDSetLastError("ENOTFOUND");
      return FAILURE;
   }

   #
   # Discovers all the params, sets them locally for each child
   # Then calls a Initialize Verification on each child handle to
   # prepare him for StartVerification.
   #
   my $ret = $self->ConfigureVerification();
   if ($ret ne SUCCESS) {
      $vdLogger->Error("ConfigureVerification failed in Verification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $self;

}


##############################################################################
#
# RemoveSpaceAndMakeLC --
#       A utility method to remove leading and trailing spaces in values of
#       hash key and make them lowercase
#
# Input:
#       string - hash which has to be converted.
#
# Results:
#       Hash of nodes.
#
# Side effects:
#       None
#
##############################################################################

sub RemoveSpaceAndMakeLC
{
   #
   # Remove leading and traling spaces from comma seperated values of hashes
   # also make the values lowercase (except for StatsNode which might have
   # user defined customNode which is case senstive on esx)
   # Dont make the vsishNode values lowercase as they are case senstive
   # as a user might pass custome node name.
   #
   my $self = shift;
   my $hash = shift;

   my @ConvertKeys = qw(target verificationtype);

   my $flag = 1;
   foreach my $hashKey (keys %$hash) {
      my $hashValue = $hash->{$hashKey};
      if ($hashValue =~ /HASH/) {
         $self->RemoveSpaceAndMakeLC($hashValue);
      } else {
         foreach my $convertKey (@ConvertKeys) {
            if ($convertKey !~ /^$hashKey$/i) {
               next;
            } else {
               delete $hash->{$hashKey};
               $hash->{$convertKey} = $hashValue;
            }
         }
      }
   }
}


###############################################################################
#
# ProcessTargetKey -
#       Converts the targets into a format which verification can understand.
#       A method useful for both child and parent.
#
# Input:
#       target node (optional)
#
# Results:
#       SUCCESS - All targets are formatted and stored in $self->{nodes}
#       NoSuchNode - incase an optional node is not found.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ProcessTargetKey
{

   my $self = shift;
   my $vNode = shift;

   my $failIfNotFound;
   #
   # A user can say target => src but this src might be esx
   # host or a guest vm. Thus we consider both and try to do
   # verification on both, if supported.
   # we leave the "SUT:vnic:1,helper2:vmknic:2" as it is as they
   # are specific nodes.
   #
   if (($vNode =~ /src\w+/) || ($vNode =~ /dst\w+/)) {
      #
      # When both src and dst (if both defined) are not specific
      # we assume we will resolve the target and make it OK if
      # we dont find both vnic and vmknic for that target.
      # If user is specific then we fail in case we dont find the
      # desired target
      #
      $failIfNotFound = 1;
   }

   if($vNode =~ /(src$|dst$)/i) {
      #
      # By src we mean srcvm AND srchost. Same for dst
      # Src also means the location from where the traffic
      # is originating.
      # A SUT will be src for outbound session
      # and dst for inbound session.
      # # TODO: Keeping code just in case we want to resolve src, dst
      # words into something else in future.
      # TODO: PR#: 793676
      #      $vNode =~ s/src/srcvm\,srchost/i if $vNode !~ /(srcvm|srchost)/i;
      #      $vNode =~ s/dst/dstvm\,dsthost/i if $vNode !~ /(dstvm|dsthost)/i;
   }

   # If the string is comma seperated it means there are multiple targets/nodes.
   my $nodeStr = $vNode;
   my @nodeArray;
   if($nodeStr =~ /\,/i) {
      @nodeArray = split(',',$nodeStr);
   } else {
      $nodeArray[0] = $nodeStr;
   }

   #
   # This should return a spec which we can use to convert all required
   # testbed/netadapter/traffic vars into vars which verification
   # module understands.
   # This also caches info so that all child classes dont have to find the
   # nodes themselves(again and again).
   # If a child needs any child specific params from testbed
   # they will have to call ConvertVerificationNode themselves with their
   # own spec/ConversionHash.
   #
   my $conversionHash = $self->GetConversionHash();
   if ($conversionHash eq FAILURE) {
      $vdLogger->Error("Conversion Hash missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # For every target node we store the info locally.
   # Say for target = srchost we will store $self->{srchost}->{os}
   # $self->{srchost}->{arch} etc. Now each child knows his target
   # thus they can fetch os arch etc without needing to learn testbed
   # or workloadhash. Also this makes it accessible to each child at once.
   #
   my $convertedNode;
   foreach my $node (@nodeArray) {
      if(not defined $self->{nodes}->{$node}) {
         #
         # Now get the node details from testbed/traffic/netadapter etc
         # using the conversion hash and store in $self->{nodes} by calling
         # SaveNode()
         #
         $convertedNode = $self->ConvertVerificationNode($node,
                                                         $conversionHash);
         if ((not defined $convertedNode) || ($convertedNode eq FAILURE)) {
            $vdLogger->Error("Node Conversion failed");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         } elsif($convertedNode =~ /NoSuchNode/i) {
            if ((defined $failIfNotFound) && ($failIfNotFound)) {
               $vdLogger->Warn("Node: $node does not exists in testbed");
               return "NoSuchNode";
            } else {
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         } else {
            # TODO: Check if the node is duplicate, if yes return duplicate
            my $ret = $self->SaveNode($node, $convertedNode);
            if ($ret eq FAILURE) {
               $vdLogger->Error("SetNode returned failure");
               VDSetLastError("EFAILED");
               return FAILURE;
            }
         }
      }
   }

   # This means all targets were resolved.
   return SUCCESS;


}


##############################################################################
#
# GetConversionHash --
#       It returns a conversionHash specification given which helps in
#       converting testbed and various other workloadhashes into local
#       variables.
#
# Input:
#       None
#
# Results:
#       conversion hash - a hash containging node info in language
#                         verification module understands.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
##############################################################################

sub GetConversionHash {
   my $self = shift;

   #
   # This spec says that variable on the left in traffic/testbed
   # will be called as variable on the right. This also makes
   # a local copy of all traffic and testbed vars.
   # This local copy is then distributed to all child classes thus
   # they dont have to discover on their own.
   #
   my $spec = {
      'traffic' => {
         'adapter'      => "adapter",
         'adapterindex' => "adapterindex",
         'machinename'  => "machinename",
      },
      'testbed' => {
         'hostobj' => {
            'arch'    => 'arch',
            'os'      => 'os',
            'hostIP'    => "host",
         },
         'adapter' => {
            'interface'  => 'interface',
            'controlIP'  => 'targetip',
            'driver'     => 'drivername',
            'macAddress' => 'mac',
         },
      },
   };

   return $spec;

}


##############################################################################
#
# ConvertVerificationNode --
#       It returns a convertedHash by following the conversionHash
#       specification given by user or a default conversion specification.
#       A mediator between verification and external world(testbed, any
#       workload)
#
# Input:
#       Node (mandatory)
#       ConversionHash (optional) - how to convert testbed in local variables
#                                   OR how to convert a workload into local
#                                   variables.
#
# Results:
#       converted hash - a hash containging node info in language verification
#                        module understands.
#       0 in case node does not exists
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
##############################################################################

sub ConvertVerificationNode {

   my ($self, $node, $conversionHash) = @_;
   my $workloadhash = $self->{workloadhash} || undef;
   my $formattedNode;
   my $wkloadType;
   my $workloadnode;

   $formattedNode->{adapterobj} = undef;
   if (not defined $conversionHash) {
      $conversionHash = $self->GetConversionHash();
      $vdLogger->Debug("Dump of hash" . Dumper($conversionHash));
   }
   $vdLogger->Trace("Input node:$node");
   if (not defined $node) {
      $vdLogger->Error("node parameter missing in " .
                       "method ConvertVerificationNode");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif (($node =~ /(src|dst)/i) && (not defined $workloadhash) &&
         ($self->{testbed}{version} == '1')) {

      #
      # If the node is srchost or srcvm (same for dst) then we need
      # a workload hash to provide info as to which node in testbed is
      # acting as src/dst
      # Testbed contains SUT, helper info but at a given time when
      # verification is called only calling workload knows which node is
      # source and which is dst
      #
      $vdLogger->Error("Workload hash missing in ConvertVerificationNode");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif (($node =~ /(src|dst|:|.)/i) && (defined $workloadhash)) {
      #
      # This can be made a method in future if child wants to override
      # this behavior
      # Based on the node and the conversion hash we convert the required
      # keys from testbed and workloadhash into local vars maintained by
      # verification.
      #
      $wkloadType = ref($workloadhash);
      my $workloadNodeID;
      if ($wkloadType =~ /traffic/i) {
         # No processing required if $node is in SUT:vnic:1 format
         if ($node =~ /(src|dst)/i) {
            $workloadnode = "client" if $node =~ /src/i;
            $workloadnode = "server" if $node =~ /dst/i;
            if (not defined $workloadhash->{$workloadnode}) {
               $vdLogger->Error("Cannot find WORKLOADNODE in workloadhash for "
                    . "endpoint:$node.");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }

            #
            # This is the node we want to find in testbed and read
            # all its params.
            # Either use the nodeid in both traffic and verification or
            # use machinename, adapterindex and adapter as diff vars.
            #
            $workloadNodeID = $workloadhash->{$workloadnode}->{nodeid};
         } else {
            $workloadNodeID = $node;
         }
         if ( ($node !~ /host/)
            && ($workloadNodeID =~ /(vnic)/i)) {
            $node = "vnic";
         } elsif (($node !~ /host/) &&
             ($workloadNodeID =~ /(pci)/i)) {
            $node = "pci";
         } elsif (($node !~ /host/) &&
             ($workloadNodeID =~ /(vmnic)/i)) {
            $node = "vmnic";
            $formattedNode->{os} = "vmkernel";
            $formattedNode->{arch} = "x86_32";
         } else {
            $node = "vmknic";
            $formattedNode->{os} = "vmkernel";

            # As we use binary from 32 bit folder of vdnet
            $formattedNode->{arch} = "x86_32";
         }
         $workloadNodeID =~ s/:(\S+):/:$node:/;
         $node = $workloadNodeID;
         my $conversionTraffic = $conversionHash->{traffic};
         if (defined $conversionTraffic) {
            foreach my $key (sort keys %$conversionTraffic) {
               my $value = $conversionTraffic->{$key};
               # These are the keys of SUT/helperX in conversion hash(outside adapter)
               if ($value =~ "HASH") {
                  # This is the VM part of conversion hash.
                  my $conversionNodeHash = $value;
                  my $traffiNode = $workloadhash->{$key};
                  foreach my $nodeKey (sort keys %$conversionNodeHash) {
                     my $nodeValue = $conversionNodeHash->{$nodeKey};
                     my $trafficValue = $workloadhash->{$key}->{$nodeKey}
                                    if defined $workloadhash->{$key}->{$nodeKey};
                     $formattedNode->{$nodeValue} =
                                   $trafficValue if defined $trafficValue;
                  }
               } else {
                  my $trafficHashValue = $workloadhash->{$key};
                  if(defined $trafficHashValue &&
                     (not defined $formattedNode->{$value})) {
                     $formattedNode->{$value} = $trafficHashValue;
                  }
               }
            }
         } # end of traffic conversion loop
         $vdLogger->Debug("formatedNode after traffic conversion:".
                          Dumper($formattedNode));
      } elsif ($wkloadType =~ /(switch|host)/i) {
         $vdLogger->Debug("Converting workload type:$wkloadType".Dumper($self->{workloadhash}->{workload}));
      } else {
         $vdLogger->Error("Not sure how to handle this workload type:".
                          "$wkloadType. Not implementted" . Dumper($self->{workloadhash}));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      # end of workloadTypo == traffic loop
   }
   #
   # The wkload keys in $formattedNode will be overwritten by testbed keys
   # As workload might have a hash of src VM and target node might be src Host
   # Thus based on $node we get that infomation from testbed.
   #
   $vdLogger->Trace("Node after Conversion:$node");
   my $conversionTestbedHash = $conversionHash->{testbed};
   if(not defined $conversionTestbedHash) {
      # There is no conversion related to testbed.
      #TODO: Not sure if we should return from here or continue.
      return $formattedNode;
   }
   $formattedNode->{nodeid} = $node;
   my $args = $node;
   $args =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($args);
   my $netAdapterObj = $ref->[0];
   $formattedNode->{adapterobj} = $netAdapterObj;
   my $vmOpsObj;

   my $hostObj;
   if ($netAdapterObj->{intType} =~ /^vmknic/i ||
        $netAdapterObj->{intType} =~ /^vmnic/i) {
      $hostObj = $netAdapterObj->{hostObj};
      $formattedNode->{os} = $hostObj->{os};
      $formattedNode->{arch} = $hostObj->{arch};
      $formattedNode->{netstack} = $netAdapterObj->{netstackName};
   } elsif ($netAdapterObj->{intType} =~ /^vnic/i) {
      $vmOpsObj = $netAdapterObj->{vmOpsObj};
      $hostObj = $vmOpsObj->{hostObj};
      $formattedNode->{os} = $vmOpsObj->{os};
      $formattedNode->{arch} = $vmOpsObj->{arch};
   } elsif ($netAdapterObj->{intType} =~ /^pif/i) {
      $vmOpsObj = $netAdapterObj->{vmOpsObj};
      $hostObj = $netAdapterObj->{hostObj};
      $formattedNode->{os} = $vmOpsObj->{os};
      $formattedNode->{arch} = $vmOpsObj->{arch};
   } elsif ((not defined $hostObj) && ($node =~ /host/i)) {
      my $ref = $self->{testbed}->GetComponentObject($node);
      $hostObj = $ref->[0];
   }
   $formattedNode->{hostobj} = $hostObj;

   if (!ref($netAdapterObj)) {
      $vdLogger->Trace("Failed to get netAdapterObj for node:" . $node);
      return "NoSuchNode";
   }

   foreach my $key (sort keys %$conversionTestbedHash) {
      my $value = $conversionTestbedHash->{$key};
      if (($key =~ /^adapter$/i) && ($value =~ "HASH")) {
         # This is the adapter part of conversion hash.
         $vdLogger->Debug("For key = $key: ".Dumper(\$value));
         my $conversionAdapter = $conversionTestbedHash->{$key};
         foreach my $adapterKey (sort keys %$conversionAdapter) {
            my $netadapterValue = $netAdapterObj->{$adapterKey};
            if (defined $netadapterValue) {
               $vdLogger->Debug("Adapter key = $conversionAdapter->{$adapterKey}, value = $netadapterValue");
               $formattedNode->{$conversionAdapter->{$adapterKey}} = $netadapterValue ;
            }
         }
      } elsif (($key =~ /vm/i) && ($value =~ "HASH")) {
         # This is the VM part of conversion hash.
         $vdLogger->Debug("For key = $key: ".Dumper(\$value));
         my $conversionVM = $conversionTestbedHash->{$key};
         foreach my $vmKey (sort keys %$conversionVM) {
            my $vmValue = $vmOpsObj->{$vmKey};
            if (defined $vmValue) {
               $vdLogger->Debug("VM key = $conversionVM->{$vmKey}, value = $vmValue");
               $formattedNode->{ $conversionVM->{$vmKey} } = $vmValue;
            }
         }
      } elsif (($key =~ /host/i) && ($value =~ "HASH")) {
         # This is the Host part of conversion hash.
         $vdLogger->Debug("For key = $key: ".Dumper(\$value));
         my $conversionHost = $conversionTestbedHash->{$key};
         foreach my $hostKey (sort keys %$conversionHost) {
            $vdLogger->Debug("Host object is: ".Dumper(\$hostObj));
            my $hostValue = $hostObj->{$hostKey};
            if (defined $hostValue) {
               $vdLogger->Debug("Host key = $conversionHost->{$hostKey}, value = $hostValue");
               $formattedNode->{ $conversionHost->{$hostKey} } = $hostValue;
            }
         }
      } elsif ($key =~ /switches/i) {
         # This is the My switches part of conversion hash.
         my $switchID = $workloadhash->{componentIndex};
         my $ref = $self->{testbed}->GetComponentObject($switchID);
         my $switchObj = $ref->[0];
         if (defined $switchObj) {
            $formattedNode->{myswitches} = $switchObj;
         }
      }
   }

   # Correct Pswitch Object
   if (defined $formattedNode->{pswitchobj}) {
      my $switchObj = $formattedNode->{pswitchobj};
      $formattedNode->{pswitchobj} = $switchObj->{switchObj};
   }

   # Correct VDS Object
   if (defined $formattedNode->{myswitches}) {
      my $switchObj = $formattedNode->{myswitches};
      $formattedNode->{myswitches} = $switchObj->{switchObj};
   }
   $vdLogger->Debug("The formattedNode is".Dumper(\$formattedNode));
   return $formattedNode;
}


###############################################################################
#
# SaveNode -
#       Saves the node in $self for future use/reference by other
#       child classes/self
#
# Input:
#       Node name (mandatory)
#       Node hash (mandatory)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
##############################################################################

sub SaveNode {
   my $self     = shift;
   my $nodeName = shift;
   my $nodeHash = shift;

   # Save the node in self
   $self->{nodes}->{$nodeName} = $nodeHash;

   #
   # If srcVM and helper1:vnic:1 pointing to same node then
   # we just save a pointer to same hash instead of discovering node
   # details again and again.
   # We do this only in case of src/dst(VM/Host).
   #
   if ($nodeName !~ /:/i) {
      $self->{nodes}->{$nodeHash->{nodeid}} = $nodeHash;
   }

   return SUCCESS;
}


###############################################################################
#
# CreateChildren -
#       Creates child classes and assings them parent pointers, targets etc.
#       Asks each child classes their children's names and lets them create
#       grandchild if they say so. Each child says what type of target it
#       supports.
#       Thus child classes are created based on type of child * no of targets.
#       This design is like a doubly linked list. i.e. Each child has pointer
#       to its parent and each parent mantains list of his child classes.
#       A generic method which child can inherit and use to create their
#       own child classes(i.e. grandchild classes)
#
# Input:
#       none
#
# Results:
#       SUCCESS - Pointers to child and parent are created successfully.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CreateChildren
{
   my $self = shift;
   my $veriBlock = shift;
   my $childName = $veriBlock->{verificationtype} || $self->{childrens};
   my $vtarget   = $veriBlock->{target};
   my (@childrens, @targets, $ret);

   #
   # If user has passed names of child modules to create then
   # create those childs with each target.
   # Else get the list of default child classes and create child
   # modules for each target.
   # If targets are not defined then use default targets.
   #

   # GetMyChildren should always return a pointer to an array of child classes
   $ret = $self->GetMyChildren();
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to get children names from GetMyChildren()");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   if (defined $childName) {
      # We might have more than one child class(comma seperated values)
      my @userChildrens;
      if($childName !~ /\,/i) {
         $userChildrens[0] = $childName;
      } else {
         @userChildrens = split(',', $childName);
      }
      #
      # Now compare the names of the child given by user to the list
      # of child this parent has. We use the child name from the parent's
      # list.
      #
      my @myChildrens =  @{$ret};
      foreach my $userChild (@userChildrens) {
        my $childFound = 0;
        foreach my $mChild (@myChildrens) {
           # Verify if we know the child user is passing. We know the
           # childrens returned by GetMyChildren()
           if($userChild =~ /^$mChild$/i) {
              push(@childrens, $mChild);
              $childFound = 1;last;
           }
        }
         if($childFound == 0) {
            $vdLogger->Info("Unknown child to this parent:$userChild");
           push(@childrens, $userChild);
         }
      }
   } else {
      $vdLogger->Error("No verificationtype given by user?");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Now loop through each child and create child * target = objects.
   foreach my $child (@childrens) {
      #
      # This is just a dummy object so that we can get the
      # supported target info for this type of child. We need
      # this info to run a loop of child creation.
      # Acutal child creation happens in this @targets loop below.
      #
      my $childObj = $self->CreateChildObj($child);
      if ($childObj eq FAILURE) {
         $vdLogger->Error("Failed to create child obj for $child child");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      #
      # GetSupportedTarget will check list of targets
      # given by user which is supported by this child.
      # If user does not specify any target then a default list will be
      # used by the child inside GetSupportedTarget()
      #
      my $result = $childObj->GetSupportedTarget($vtarget);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get list of supported target");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      @targets = split(/,/, $result);

      #
      # This is the actual child creation loop which creates child classes
      # for each node in @targets.
      #
      foreach my $machine  (@targets) {
         # 1) Create child
         # 2) If this child has his own children then create them too
         #    else work on this child
         $childObj = $self->CreateChildObj($child);
         if ($childObj eq FAILURE) {
            $vdLogger->Error("Failed to create child obj for $child ".
                             "child inside loop");
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         #
         # If child does not have a child (no grandchild) then attaching
         # child handle in parents list of children
         #
         if (scalar($childObj->GetMyChildren()) > 0) {
            #
            # This would create grandchild class, if any
            #
            $self->{allchildrens}->{$child} = $childObj;
            $ret = $childObj->CreateChildren();
          if ($ret ne SUCCESS) {
             $vdLogger->Error("CreateChildren failed for parent:$child".
                              " inside loop of targets");
             VDSetLastError("ENOTDEF");
             return FAILURE;
          }
            last;
         } else {
            #
            # This child has no child of his own.
            # see if the machine he wants to use exits in $self->{nodes}
            #
            if(not defined $self->{nodes}->{$machine}) {
               $ret = $self->ProcessTargetKey($machine);
               if ($ret =~ /(NoSuchNode)/i) {
                  # child had suggested this as one of the default node and it
                  # does not exists thus moving on to next node.
                  $vdLogger->Debug("Node does not exists");
                  next;
               } elsif($ret =~ /(FAILURE)/i) {
                 $vdLogger->Error("Required node not found");
                 VDSetLastError("ENOTDEF");
                 return FAILURE;
               }
               $childObj->{nodes} = $self->{nodes};
            }
            # Set the target for this verification object.
            $childObj->{target} = $machine;
            #
            # Get the verification types of parent and child and set them
            #
            $self->{veritype} = $self->GetVerificationType();
            $childObj->{veritype} = $childObj->GetVerificationType();

            my %childBlock = %$veriBlock;
            my $childBlockPtr = \%childBlock;
            #
            # Remove the target and verificationtype from this
            # child verification block.
            #
            delete $childBlockPtr->{target};
            delete $childBlockPtr->{verificationtype};
            #
            # Old testcase use the expectedresult for Verification
            # New Verification does not support this key. This is
            # just to keep the code backward compatible
            #
            if ((BACKWARD_COMPATIBLE == 1) &&
                 (defined $childBlockPtr->{expectedresult})) {
               $childObj->{expectedresult} = $childBlockPtr->{expectedresult};
               delete $childBlockPtr->{expectedresult};
            }
            #
            # Now from this block we check if a counter or a config key
            # have target appended to it. If yes, then we strip the
            # key and give it to that object.
            # E.g. verificationtype = pktcap and target = src,dst
            # and src.count => 1000 then strip count key from this block
            # and give it to pktcap-src obj. Thus pktcap-dst obj will not
            # waste time processing it.
            #
            foreach my $blockKey (keys %$childBlockPtr) {
               my $blockValue = $childBlockPtr->{$blockKey};
               #
               # We split the src.pktcapfilter into src and pktcapfilter
               # We also make sure if target is in SUT:vmknic:1.dmesg
               # format. We also make sure we dont fidle with nodes of
               # vsish or activeVMNic etc E.g. /net/portset.droppedTx = 0
               # But we do need to process src./net/portset.droppedTx = 0
               #
               my $i = 2;
               while($i > 0) {
                  $blockKey = $blockKey if $i == 2;
                  $blockKey = $blockValue if $i == 1;
                  my $targetKey = 1;
                  if (($blockKey =~ /\./) && ($blockKey !~ /^\//)) {
                     $blockKey =~ m/(.*?)\./;
                     my $keytarget = $1;
                     #
                     # If target is in SUT:vmknic:1 format, compare
                     # it with nodeid else compare it with target
                     #
                     if ($keytarget !~ /:/) {
                        if ($childObj->{target} !~ /$keytarget/i) {
                           $targetKey = 0;
                        }
                     } else {
                        if ($self->{nodes}->{$childObj->{target}}->{nodeid} !~ /$keytarget/i) {
                           $targetKey = 0;
                        }
                     }
                     #
                     # We want to delete any couter/config with target
                     # appended in front of it. After deleting, we save
                     # if the target is same as that of childObj
                     #
                     delete $childBlockPtr->{$blockKey};
                     if ($targetKey == 1) {
                        $blockKey =~ s/(.*?)\.(.*)/$2/;
                        if ($i == 2) {
                           $childBlockPtr->{$blockKey} = $blockValue;
                        } elsif ($i == 1) {
                           $blockKey =~ /(.*?)\.(.*)/;
                           my $counter = $2;
                           $blockKey = $1;
                           if ($counter =~ /^(\w+)/) {
                              $counter = $1;
                           }
                           $blockKey = $blockKey . "." . $counter;
                           $childBlockPtr->{$blockKey} = "dontcare";
                        }
                     }
                  }
                  $i--;
                }
            }

            #
            # Store the rest of block in the obj and
            # treat the rest of the block as ExpectedChange
            #
            $childObj->{expectedchange} = $childBlockPtr;
            #
            # save the name of the child in the 'allchildrens' list of parent var
            # This makes sure we dont crete childs pointing to same node
            # with different names.
            #
            my $str =  $childObj->GetPriority() . $child . "-" .
                       $self->{nodes}->{$machine}->{nodeid};
            if(not defined $self->{allchildrens}->{$str}) {
               $self->{allchildrens}->{$str} = $childObj;
            }
         }
      }
   }

   return SUCCESS;
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#       This list is used in case user does not specify any verification type
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
#  fix PR: 1209500 PktcapUserWorldVerification is called by default
#  since current find child tool method is use 'match', so both 'PktCapUserWorld'
#  and 'PktCap' will match 'pktcap', this will make you get an unexpected tool.
#  please be careful of this if you add new capture tool in future.

   return ["PktCap", "NFDump", "Stress", "Interrupt", "DataDiff",
           "PktCapUserWorld", # Misc
           "NIC", "VSISH", "dvPort", "ActiveVMNic", "NIOC",       # Stats Family
           "Dmesg", "VMwareLog", "VMKernelLog", "VarLog", "VOB", # Log Family
           "LACPLog", "PSwitchLog", # Log Family
           ];
}

###############################################################################
#
# CreateChildObj -
#       Creates child objects and bless it with parent attributes.
#
# Input:
#       childType - Type of Verification of which object is to be
#                   created (mandatory)
#
# Results:
#       child object - returns child obj handle
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CreateChildObj
{
   my $self = shift;
   my $childType = shift;
   my $child = undef;
   my @myChildrens = @{$self->GetMyChildren()};
   foreach $child (@myChildrens)
   {
      if($child =~ m/$childType/i){
         # Overwrite in case user gives a different caps lock.
         $childType = $child;
         last;
      } else {
         $child = undef;
      }
   }

   if($child = undef){
      $vdLogger->Error("Verification Type:$child not supported");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Instantiating obj of $childType"."Verification");
   #
   # All modules should adhere to the standard name used here.
   # E.g PktCapVerification, DmesgVerification, NetStatVerification
   #
   my $childModule = "VDNetLib::Verification::"."$childType"."Verification";
   eval "require $childModule";
   if ($@) {
      $vdLogger->Error("Failed to load package $childModule $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Keep new (method) of child as light as possible for better performance.
   my $childObj = $childModule->new(verihash => $self->{verihash});
   if ($childObj eq FAILURE) {
      $vdLogger->Error("Failed to create obj of package $childModule");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (defined $childObj){
      #
      # Copy the attributes of parent to child object.
      # Thus parents and child classes share these attributes now.
      # They also talk to each other's handles stored in them
      # from storing each other's handles. If one updates the other knows
      #
      foreach my $key (keys %$self){
         if ($key =~ /children/) {
            next;
         }
         if (not defined $childObj->{$key}) {
            $childObj->{$key} = $self->{$key}
         }
      }
      $childObj->{myparent} = $self;
      bless $childObj, $childModule;
   }

   return $childObj;
}


###############################################################################
#
# GetVerificationType -
#       Returns the type of verification $self obj is.
#
# Input:
#       none
#
# Results:
#       verification type
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVerificationType
{
   my $self = shift;
   my $veriType = ref($self);
   $veriType =~ s/VDNetLib::Verification::(\w+)Verification//g;
   return lc($1);

}


###############################################################################
#
# VerificationSpecificJob -
#       A void method which the child can override and do things which are
#       specific to that child
#       Parents leaves a hook so that future childs can make changes without
#       modifying the parent.
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

sub VerificationSpecificJob
{
   # A void method which has to be overridden in child.
   # Even if child doesn't want to implement it parent's method will
   # be called and SUCCESS will be returned.

   return SUCCESS;
}


###############################################################################
#
# GetSupportedTarget -
#       Checks if all the targets given by user in verification hash are
#       supported by this module. If not, they are dropped.
#       If user does not give any target then default targets are picked
#       for that module by asking GetDefaultTargets().
#       Child classes can override the values by implementing their own
#       GetDefaultTargets();
#       These default modules are also checked for supported.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values of target supported by this child
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetSupportedTarget
{

   my $self = shift;
   my $vtarget = shift;

   #
   # Incase user does not specify a verification target, each
   # child picks his own target by default.
   #
   if (not defined $vtarget) {
      #
      # E.g. When a user says VerificationJob => "log" &
      # and LogType => "dmesg"
      # the child module(dmesg) should say DefaultTarget is guest
      #
      $vtarget = $self->GetDefaultTargets() if BACKWARD_COMPATIBLE == 1;
      if ($vtarget eq FAILURE) {
         $vdLogger->Error("GetDefaultTargets returned failure");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   }

   return $vtarget;

}


###############################################################################
#
# GetDefaultTargets -
#       Returns the default target to do verification on, in case user does
#       not specify any target.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values of default target.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultTargets
{
   # If no target is specified, by default this verification
   # is done on src,dst. By src we mean srcvm AND srchost. Same for dst
   # One can also override this method and say helper1 or SUT here if this
   # verification is only supported on SUT.
   return "src,dst";
}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version it will be caught later.
#       Every child needs to implement this.
#       Parent should not implement it.
#       TODO: Move it from this package.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values supported platform
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetSupportedPlatform
{

   # This verification is supported inside the guest
   # as well as on host.
   return "guest,host";

}

###############################################################################
#
# ConfigureVerification -
#       Finds out which method to execute using function pointer hash.
#       Calls ExecuteChildMethod for every child object(leaf node). Thus all
#       child verification modules start building commands one after another
#       if a child does not support building command in that environment, then
#       that child is dropped before calling StartVerification.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ConfigureVerification
{

   my $self = shift;

   #
   # Remove the key as it is not related to expectedchange, expectedchange
   # should only contain the output, values etc which user is expecting
   # from the command/API
   #
   foreach my $key (@operationalKeys) {
      if (exists $self->{verihash}->{$key}) {
         $self->{$key} = $self->{verihash}->{$key};
         delete $self->{verihash}->{$key};
      }
   }
   # SetRequiredParams() is for reading the params from testbed or a
   # workload hash which might be required by a verification module.
   #TODO: PR#: 793676
   $self->ExecuteChildMethod("SetRequiredParams");
   #TODO: Error handling for these methods. + delete unsupported objects
   # if target is src,dst where dst is windows and
   # verificationType = pktcap and nic stats. As nic stats is not supported
   # on windows this method will say unsupported. Thus we delete the obj.
   # Print not doing verification on target as its unsupported.

   # Any specific task a child wants to do.
   $self->ExecuteChildMethod("VerificationSpecificJob");

   # Initialize Verification is for initializing/registering all counters/nodes
   # and preparing all the information which needs to be extracted from
   # the system.
   $self->ExecuteChildMethod("InitVerification");
   $self->ExecuteChildMethod("SetExpectedChange");

   # Remove verification child classes which do not have any expectations
   # set in them. This happends when defaultMonitoring is off and user
   # does not specify any expectedChange for this Verification type.
   $self->ExecuteChildMethod("DeleteUnwantedChildren");

   return SUCCESS;
}


###############################################################################
#
# ExecuteChildMethod -
#       Calls the method on the leaf node(child) as pointed by the hash.
#       When child itself is a parent, then it makes a recursive call and
#       goes down to its own child. Thus we keeps on traversing untill we
#       find the leaf node. Then we execute the methods on this leaf node.
#
# Input:
#       CallerMethod - Method which called ExecuteChildMethod and exists in
#                      $self->{methodptr} hash
#
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ExecuteChildMethod
{
   my $self = shift;
   my $callerMethod = shift;

   my $childMethod; #  = $self->{methodptr}->{$callerMethod}->{method};
   if(not defined $childMethod) {
      # Try with caller method if child method is not defined.
      $childMethod = $callerMethod;
   }
   my $allChildrens = $self->{allchildrens};

   foreach my $child (keys %$allChildrens) {
      my $childObj = $allChildrens->{$child};
      #
      # If the childObj has its own child class then traverse to it
      # Keep traversing till leaf node is reached.
      #TODO: PR#: 793676 GetMyChildren is not required now
      #
      if (scalar($childObj->GetMyChildren()) > 0) {
         $childObj->ExecuteChildMethod($callerMethod); #$callerMethod;
      } else {
         # Executing the desired method on the leaf node.
         my $ret = $childObj->$childMethod;
         #TODO: Differential between failure and unsupported.
         if ($ret =~ /(SUCCESS|PASS)/) {
            next;
         }
         if ($ret !~ /fail$/i) {
            $vdLogger->Error("$callerMethod() returned $ret for $child");
            $vdLogger->Error("Thus not doing $childObj->{veritype} Verification ".
                             "on $childObj->{nodeid} $childObj->{targetip}")
         }
         if (defined $childObj->{resulthash}) {
            my $childResultHash = $childObj->{resulthash};
            foreach my $resultKey (keys %$childResultHash) {
               my $resultValue =  $childResultHash->{$resultKey};
               $self->{resulthash}->{$child}->{$resultKey} = $resultValue;
            }
         }
         $self->{resulthash}->{$child}->{deathMethod} = $callerMethod ."()";
         $self->{resulthash}->{$child}->{deathMethodReturn} = $ret;
         delete $allChildrens->{$child};
      }
   }
   return SUCCESS;
}


###############################################################################
#
# SetRequiredParams -
#       This is a child method. It helps child see if all the params it
#       requires exists in testbed or workload.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everthing goes well.
#       FAILURE -
#
# Side effects:
#       None
#
###############################################################################

sub SetRequiredParams
{
   #
   # This method is for child only. All childrens use it. Thus keeping
   # it in parent as its a common code.
   #
   my $self = shift;
   my $target = $self->{target};
   my $tempParams = {};
   my $ret = SUCCESS;
   #
   # 1) Get the list of params must needed for this module
   # $self->GetParams()
   # 2) Loop through each param in this result and see if
   # they are in $self->{nodes}->{target}
   # if yes then save it locally
   # if no then GetChildConversionHash to know how and what to read
   # from workload/testbed to get this param
   # call ConvertVerificationNode, when it returns read it from hash
   # Also save it in $self->{nodes}->{$target} for others to use it.
   #

   my $targetParams = $self->{nodes}->{$target};
   foreach my $param (keys %$targetParams) {
      #
      # We dont want to overwite any vars set by class from the node vars
      # E.g. for VSISH Verification target os is always vmkernel thus
      # we dont overwrite it thus we have if not defined condition here.
      #
      $self->{$param} = $targetParams->{$param} if not defined $self->{$param};
   }

   my $requiredParams = $self->RequiredParams();
   if ($requiredParams eq FAILURE) {
      $vdLogger->Error("RequiredParams returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $param (@$requiredParams) {
      if ((!exists $self->{$param}) && (!exists $tempParams->{$param})) {
         $ret = "unsupported";
         my $convertedNode = $self->ConvertVerificationNode($target, $self->GetChildHash());
         if (not defined $convertedNode) {
            $vdLogger->Error("Node Conversion failed");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }

         foreach my $key (sort keys %$convertedNode) {
            $targetParams->{$key} = $convertedNode->{$key};
            $self->{$key} = $convertedNode->{$key};
            $tempParams->{$key} = $convertedNode->{$key};
            if ($key =~ $param)   {
               $ret = SUCCESS;
            }
         }
         if($ret =~ /unsupported/i) {
            $vdLogger->Error("Param:$param needed for verification is missing".
                             " in SetRequiredParams()");
         }
      }
   }
   return $ret;
}


###############################################################################
#
# StartVerification -
#       Finds out which method to execute using function pointer hash.
#       Calls ExecuteChildMethod for every child object. Thus all
#       child verification modules start one after another.
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

sub StartVerification
{

   my $self = shift;
   $self->ExecuteChildMethod("Start");

}


###############################################################################
#
# StopVerification -
#       Calls ExecuteChildMethod for every child object. Thus all
#       child verification modules stop one after another.
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

sub StopVerification
{

   my $self = shift;
   if (defined $self->{sleepbeforefinal}) {
      $vdLogger->Info("Waiting for $self->{sleepbeforefinal} sec before ".
                      "gathering final info...");
      sleep(int($self->{sleepbeforefinal}));
   }
   $self->ExecuteChildMethod("Stop");

}


###############################################################################
#
# GetResult -
#       Calls ExecuteChildMethod for every child object. Thus all
#       child verification modules post their results on their objects
#       after another.
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

sub GetResult
{

   my $self = shift;
   # TODO: To make the flow more efficient what we do is call VerificationSpecificJob
   # and ask do all processing using async calls or forks and then
   # call GetResult to fetch results.
   $self->ExecuteChildMethod("VerificationSpecificJob");
   #
   # We set the expectations after traffic is complted so that
   # if netperf is reporting 1gbit/sec for 10sec, there should be roughly a
   # gigabit worth of bytes tx'ed in the stats. So, a sort of increase in stats
   # relative to some test activity. To do that we have to know the throughput
   # from the traffic hash and thus set expectations on the tx'ed or rx'ed bytes
   # in vsish nodes.
   # Setting the expectations(default and actual) given by user
   # and that which is suggested by traffic/netadapter or other workloads
   #
   $self->ExecuteChildMethod("ExtractResults");
   $self->ExecuteChildMethod("DisplayDiff");

   # Now determine pass/fail based on all the result we got.
   $self->ExecuteChildMethod("ReportResult");

   if (defined $self->{resulthash}) {
      #
      # This will be defined in case a module gave error/failed
      # This makes debugging a lot easier as it dumps why
      # a module failed, after which method, return type of method
      # which counters caused failed etc. If the module failed
      # due to reasons like unsupported etc. This can be extended
      # for better debugging of errors.
      #
      my $resultHash = $self->{resulthash};
      $vdLogger->Trace("Dumping all Verification failures");
      foreach my $moduleName (keys %$resultHash) {
         my $module = $resultHash->{$moduleName};
         $vdLogger->Error("$moduleName  failed with:" . Dumper($module));
      }
      return "FAIL";
   }

   return SUCCESS;

}


###############################################################################
#
# SetExpectedChange -
#       Sets the expected change given by user on matching counters for this
#       verification type. E.g. if user says allTSO => "change" then find
#       all tso related counters and monitor if they 'change'
#       There are variations to this behavior as covered below.
#       Expectations can also be set by traffic workload and default -ve
#       counters.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub SetExpectedChange
{
   my $self = shift;
   my $target = $self->{target};
   my $ret;

   # We will have four kinds of expectations
   # 1) specific expectation 2) generic expectation
   # 3) workload based expectation 4) default expectation

   # 1) specific expectation are when user sets specific counters
   # like droppedTsoTx => ""
   # 2) generic counters are all counters that match when user gives
   # allTSO, allLRO, allTx etc
   # allTSO will match all counters related to TSO
   # we do flip the -ve counters in this case. e.g user is monitoring tso
   # and wants allTSO => "change" all tso counters to change
   # but then TSOTXError should not change so we flip it to "nochange"

   # 3) workload based expectation are enabled by traffic/netadapter or
   # other workloads
   # Traffic and netadapter will tell what type of traffic to
   # expect for workload expectations
   # E.g. traffic hash can tell one needs to monitor all
   # multicast packets in vsish node even if user doesn't enable them
   # Thus looping through traffic+netadapter will generate key words like
   # allMulticast, allBroadcast, allTSO, allRing, allQueue which will be
   # used to generate workload based expectations
   # These keywords will mean different thing for different verifications
   # PktCap will try to generate filter for capturing TSO packets
   # VSISH will try to read TSO related counters. etc

   # 4) Default expectations are monitoring all -ve counters mentioned in
   # @allErrors global variable (like counters with fail, discard, drop, err etc)

   # Thus we always monitor -ve counters and traffic enabled counters
   # irrespective of user's input
   # Final Result will be calculated based on result of each counter of each of
   # these four expectations.


   my $isExpectationsSet = 0;
   my $expectedHash;
   my $defaultMonitoring = DEFAULT_MONITORING;

   # See if user wants to do default Verification/monitoring of counters.
   if(defined $self->{verihash}->{defaultmonitoring}) {
      $defaultMonitoring = $self->{verihash}->{defaultmonitoring};
   }

   #
   # Data from a workload might also be needed to generate
   # expectations. Make a local copy of hash and lower the
   # case for them
   #
   my $expectedHashPtr = $self->{expectedchange};
   my %tempExpectedHash =  %$expectedHashPtr;
   $expectedHash = \%tempExpectedHash;
   # Make all the keys (not values) in verificationhash lowercase
   %$expectedHash = (map { lc $_ => $expectedHash->{$_}} keys %$expectedHash);

   # Process specific keys first. E.g. bytesTSOTx = "5+",
   # Then process generic keys starting with 'all*'
   foreach my $expectedKey (keys %$expectedHash) {
      my $expectedValue = $expectedHash->{$expectedKey};
      #
      # we also support relative verification (This is an example of
      # matching ethtool -S counter on src and dst as part of NIC Stats)
      # 'dstvm.VSIS_NODE_PATH.TSO bytes tx' => "srcvm.VSIS_NODE_PATH.TSO bytes tx",
      # 'dstvm.VSIS_NODE_PATH.TSO bytes tx' => "srcvm.VSIS_NODE_PATH.TSO bytes tx+500",
      # 'dstvm.VSIS_NODE_PATH.TSO bytes tx' => "srcvm.VSIS_NODE_PATH.TSO bytes tx-500",
      # 'dstvm.VSIS_NODE_PATH.TSO bytes tx' => "srcvm.VSIS_NODE_PATH.TSO bytes tx-+500",
      #
      next if $expectedKey =~ /(^all)/i;
      $ret = $self->SetExpectations($expectedKey, $expectedValue, "specific");
      if($ret eq FAILURE) {
         $vdLogger->Error("SetExpectations failed for ".
                          "$expectedKey,$expectedValue,'specific'");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   # Process generic keys now. e.g. allLRO => "nochange"
   $self->ProcessExpectationHash($expectedHash, "generic");


   # If user says not to set default expectations then return
   # from there.
   if ($defaultMonitoring =~ /^(none|no|off)$/i) {
      return SUCCESS;
   }

   if($defaultMonitoring =~ /(workload|all|yes|on)/i) {
      # Data from a workload might also be needed to generate
      # expectations
      my $workloadhash = $self->{workloadhash};
      # TODO: A method on $self to know if it should process
      # this hash. This will improve performance.
      my $wkloadType = ref($workloadhash);
      my ($monitorKey, $monitorValue);
      if ($wkloadType =~ /traffic/i) {
         $wkloadType = "traffic";
         #
         # If the workload is traffic then we also see if the
         # target is src or dst. Based on src and dst we set
         # if it is suppose to monitor TX or RX counters
         #
         $workloadhash = $self->ExpectationFromTraffic($workloadhash);
      } else {
         $wkloadType = "unknownWkload";
      }
      $self->ProcessExpectationHash($workloadhash, "workload");
   }

   if($defaultMonitoring =~ /(default|error|all|yes|on)/i) {
      #
      # For all the negative counters/error counters set the expected value
      # to nochange and set the expectation as default.
      #
      my $allErrors = $self->{counters}->{allerrors};
      my $errHash;
      foreach my $err (@$allErrors) {
         $errHash->{"all".$err} = "nochange";
      }
      $self->ProcessExpectationHash($errHash, "default");
   }

   return SUCCESS;
}

##############################################################################
#
# ExpectationFromTraffic --
#       A utility method to remove leading and trailing spaces in values of
#       hash key and make them lowercase
#
# Input:
#       string - hash which has to be converted.
#
# Results:
#       Hash of nodes.
#
# Side effects:
#       None
#
##############################################################################

sub ExpectationFromTraffic
{
   my $self = shift;
   my $trafficWkload = shift;
   my $target = $self->{target};
   my $trafficExp = undef;
   #
   # If the workload is traffic then we also see if the
   # target is src or dst. Based on src and dst we set
   # if it is suppose to monitor TX or RX counters
   #
   my $direction = "";
   if($target =~ /src/i) {
      $direction = "tx";
   } elsif($target =~ /dst/i) {
      $direction = "rx";
   }

   $trafficExp->{"all".$direction} = "change";
   if (($trafficWkload->{routingscheme} eq "") ||
       ($trafficWkload->{routingscheme} =~ /unicast/i)) {
      $trafficExp->{"allucast bytes ".$direction} = "change";
      $trafficExp->{"allucast pkts ".$direction} = "change";
   }


   foreach my $trafficKey (keys %$trafficWkload) {
      my $trafficValue = $trafficWkload->{$trafficKey};
      next if $trafficValue eq "";
      switch ($trafficKey) {
         case m/(routingscheme)/i {
            if ($trafficValue =~ m/multicast/i) {
               $trafficExp->{"allmulticast"} = "change";
            } elsif ($trafficValue =~ m/broadcast/i) {
               $trafficExp->{"allbroadcast"} = "change";
            } else {
               $trafficExp->{"allunicast"} = "change";
            }
         }
         case m/(l3protocol)/i {
            if ($trafficValue =~ m/ipv4/i) {
               $trafficExp->{"allipv4"} = "change";
            } elsif ($trafficValue =~ m/ipv6/i) {
               $trafficExp->{"allipv6"} = "change";
            }
         }
         case m/(l4protocol)/i {
            if ($trafficValue =~ m/tcp/i) {
               $trafficExp->{"alltcp"} = "change";
            } elsif ($trafficValue =~ m/udp/i) {
               $trafficExp->{"alludp"} = "change";
            }
         }
         else {
            next;
         }
      }
   }

   return $trafficExp;

}


###############################################################################
#
# ProcessExpectationHash -
#       Given a hash, iterator though each value of the hash and set the
#       expectation using the keys and values from this hash.
#
# Input:
#       expectation hash (mandatory)
#       expectation type str(mandatory)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   my $self = shift;
   my $expectedHash = shift;
   my $expectationType = shift;
   my $ret;

   # Process keys starting with 'all*'
   foreach my $expectedKey (keys %$expectedHash) {
      my $expectedValue = $expectedHash->{$expectedKey};
      if($expectedKey =~ /\./) {
         my @values = split('\.',$expectedKey);
         my $arrCount = scalar(@values);
         if($arrCount > 1) {
            my $expTarget = $values[0];
            if ($self->{target} !~ /$expTarget/i) {
               next;
            }
         }
         if($arrCount > 2) {
            my $expType = $values[1];
            if ($self->{veritype} !~ /$expType/i) {
               next;
            }
         }
         $expectedKey = $values[$arrCount -1];
      }
      next if $expectedKey !~ /^all/i;
      $expectedKey =~ s/^all//;
      $expectedKey = lc($expectedKey);
      # If an alias exits then add that in expectedHash so
      # that it will be picked up in next loop. Will it be?
      my $aliases = $self->{counters}->{aliases};
      if(exists $aliases->{$expectedKey}) {
         # If alias exists then also set expectation using that alias.
         $self->SetExpectations($aliases->{$expectedKey}, $expectedValue, $expectationType);
      }
      $ret = $self->SetExpectations($expectedKey, $expectedValue, $expectationType);
      if($ret eq FAILURE) {
         $vdLogger->Error("SetExpectations failed for ".
                          "$expectedKey,$expectedValue,'generic'");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# SetExpectations -
#       Sets the expectation type and expectation value on counters of the
#       template hash.
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

sub SetExpectations
{
   my $self = shift;
   my $expectedKey = shift;
   my $expectedValue = shift;
   my $expectationType = shift || "default";
   my $expectedNode = undef;

   if ($expectedKey =~ /\./) {
      $expectedKey =~ m/(.*)\.(.*)$/;
      $expectedNode = $1;
      $expectedKey = $2;
   }

   if (not defined $expectedKey){
      $vdLogger->Error("ExpectedKey:$expectedKey is missing".
                       " in SetExpectations");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # There are 4 types of expectations 1) specific 2) generic
   # 3) wkload 4) default
   # depending on the pass/fail or each expectation we compute
   # the final result
   #
   my ($allMac, $allNodes, $template, $found, $allErrors);
   my $aliases = $self->{counters}->{aliases};

   my $bucket = $self->GetBucket();
   # Run the loop on all nodes of all machines.
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      # For all nodes get the template and work on it
      foreach my $node (keys %$allNodes) {
         #
         # If expectedNode is defined then lets not search in all
         # template nodes.
         #
         if (defined $expectedNode) {
            next if lc($expectedNode) !~ lc($node);
         }
         $template = $allNodes->{$node}->{template};
         $found = 0;
         # For each template get all the counters
         foreach my $templateKey (sort keys %$template) {
            my $templateValue = $template->{$templateKey};
            if($templateValue ne '0') {
               # Expectation on this key is already set.
               next;
            }
            #
            # If expectation type is generic/default/wkload then match
            # approx e.g. allTSO => 6 then match dropTSOTX =~ tso.
            # if expectation type is specific then match the
            # exact key e.g. dropTSOTX = 6
            #
            if ($expectationType =~ /(generic|workload|default)/i) {
               if ($expectedKey =~ /(\+|\-)/) {
                  # This is for handling the scenario of allTSO+TX or allTSO-RX
                  $expectedKey =~ m/(\w+)(\+|\-)(\w+)/i;
                  my $firstWord = $1;
                  my $secondWord = $3;
                  my $operator = $2;
                 if (($operator =~ /\-/) &&
                     ($templateKey =~ /$firstWord/i) &&
                     ($templateKey !~ /$secondWord/i)){
                    #
                    # For allTSO-RX, I am insterested in all tso
                    # counters expect rx in them
                    #
                 } elsif (($operator =~ /\+/) &&
                          ($templateKey =~ /$firstWord/i) &&
                          ($templateKey =~ /$secondWord/i)) {
                    #
                    # For allTSO+RX, I am insterested in all tso
                    # counters with rx in them also.
                    #
                 } else {
                    next;
                 }
               } elsif ($templateKey !~ /$expectedKey/i) {
                  next;
               }
            } elsif($expectationType =~ /specific/i) {
                 if($templateKey !~ /^$expectedKey$/i) {
                  next;
               }
            }
            #
            # In case of workload we also need to do one more thing
            # if the expectedKey is in any feature list then go ahead
            # But if it is not in feature list e.g. bytes, rx, tx
            # then see
            #
            my $greenFlag = 0;
            my $redFlag = 0;
            if ($expectationType =~ /(workload)/i) {
               #
               # Suppose workload has allRX = change then we dont
               # want bcastRX and mcastRX to be set.
               # This logic applies to keys which are not feature
               # If it is a feature we want to monitor everything about it
               #
               my $allFeatures = $self->{counters}->{allfeatures};
               foreach my $feature (@$allFeatures) {
                  my $featureAlias = $aliases->{$feature};
                  if ($expectedKey =~ /$feature/i){
                     #
                     # If expectedkey(e.g. tso) is a feature then
                     # let the code flow go ahead as we want to
                     # monitor every counter for tso
                     #
                     last;
                  }
                  if ($templateKey =~ /$feature/i){
                     $redFlag = 1;
                  }
                  if(defined $featureAlias) {
                     if ($expectedKey =~ /$featureAlias/i){
                        last;
                     }
                     if($templateKey =~ /$featureAlias/i) {
                         $redFlag = 1;
                     }
                  }
               }
               if ($redFlag == 1) {
                  next;
               }
            }

            #TODO: deprecate this set after testing
            $allNodes->{$node}->{change} = $expectationType;
            # compare the template key with allErr
            my ($newKey, $newValue);
            $newKey = $templateKey;
            #
            # Convert the string like change/nochange to int so that
            # its easier to compare
            #
            $newValue = $self->ConvertExpStrToInt($expectedValue);
            #
            # If the expectationType is generic or workload then
            # we find all -ve counters related to it and flip them
            # E.g. a user says allTSO => "change" then we set all
            # +ve tso counters to 'change' and all -ve counters
            # related to tso to 'nochange'(Fliped counter)
            #
            if ($expectationType =~ /(generic|workload|default)/i) {
               $allErrors = $self->{counters}->{allerrors};
               foreach my $errCounter (@$allErrors) {
                  #
                  # For each templatKey, see if it is a -ve counter
                  # flip the expected value. E.g. droppedTSOTx
                  # is a -ve counter as it has drop in it.
                  #
                  if($templateKey =~ /$errCounter/i) {
                     $newValue = $self->ConvertExpStrToInt($newValue, "flip");
                     # break out of the loop if we found that -ve counter
                     last;
                  }
                  #
                  # Check if the -ve counter had any alias.
                  # E.g. drop has alias drp. If it does had an alias
                  # check if the templatekey matches with the alias.
                  # if it does then its a -ve counter, flip it.
                  #
                  my $aliases = $self->{counters}->{aliases};
                  if((exists $aliases->{$errCounter}) &&
                      ($templateKey =~ $aliases->{$errCounter})) {
                     $newValue = $self->ConvertExpStrToInt($newValue, "flip");
                     last;
                  }
               }
            }
            #
            # Only set expectations on counters which are intilialized
            # to 0. The counters which are already set to some level of
            # expectation won't be overridden.
            # For counters which are 0 we set the counter to
            # expected value:expectation type
            #
            if($templateValue eq '0') {
               $template->{$templateKey} = $newValue .":". $expectationType;
            }
         }
      }
   }

   return SUCCESS;
}


###############################################################################
#
# DeleteUnwantedChildren -
#       Remove child classes which are not supported. Remove child classes
#       for which there is no expectation set.
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

sub DeleteUnwantedChildren
{
   my $self = shift;

   #
   # TODO: Also check if relative counter is set.
   # 'srcvm.vsish.bytesTSOTXok'    => "dstvm.vsish.bytesTSOTXok+500",
   # then we need to vsish for dstvm also even if there is no
   # expectation from dstvm vsish.
   #
   my ($allMac, $allNodes, $template, $found, $allErrors);
   my $bucket = $self->GetBucket();
   # Run the loop on all nodes of all machines.
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      # For all nodes get the template and work on it
      foreach my $node (keys %$allNodes) {
         my $support = $allNodes->{$node}->{supported};
         if (defined $support && $support =~ /no/i) {
            $vdLogger->Warn("$node has flag supported => no ");
            $vdLogger->Warn("$self->{veritype} is not supported on ".
                            "$self->{target}.");
            return "unsupported";
         }
         $template = $allNodes->{$node}->{template};
         if (not defined $template) {
            $vdLogger->Info("No expectation set for $self->{veritype} ".
                            "on $self->{target}.");
            return "unsupported";
         }
         if($template =~ /HASH/) {
            my $allValuesUnset = 1;
            foreach my $value (values %$template) {
               if($value ne "0") {
                  $allValuesUnset = 0;
               }
            }
            if($allValuesUnset == 1) {
               $vdLogger->Info("No expectation set for $self->{veritype} ".
                            "on $self->{target}.");
               return "unsupported";
            }
         }
      }
   }

   my $ret = $self->VerificationSpecificDeletion();
   if ($ret =~ /unsupported/) {
      return "unsupported";
   }

   return SUCCESS;
}


###############################################################################
#
# VerificationSpecificDeletion -
#       If a Verification is not supported on a platform, os version, kernel
#       version, target type then child can say unsupported.
#
# Input:
#       none
#
# Results:
#       unsupported - in case its not supported.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
###############################################################################

sub VerificationSpecificDeletion { return SUCCESS; }


###############################################################################
#
# ConvertExpStrToInt -
#       Convert expectation str to integer. E.g. nochange means 0.
#
# Input:
#       value - in str(mandatory)
#       flip - to flip the value or not(optional)
#
#
# Results:
#       intr value - in case everthing goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
###############################################################################

sub ConvertExpStrToInt
{
   my $self = shift;
   my $value = shift;
   if (not defined $value){
      $vdLogger->Error("value:$value is missing in ConvertExpStrToInt");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $flip = shift || "dont";

   if($value !~ /^(change|[0]|[1]\+)$/i) {
      return $value;
   }

   if($flip =~ /flip/i) {
      if($value =~ /(^change$|[1]\+)/i){
         # a diff of 0 is considered as nochange
         return "0";
      } elsif($value =~ /(^nochange$|[0])/i){
         # a diff of 1+ is considered as change
         return "1+";
      }
   } else {
      # This block is to return actual value(i.e. no flipping)
      if($value =~ /(^change$|[1]\+)/i){
         # a diff of 0 is considered as nochange
         return "1+";
      } elsif($value =~ /(^nochange$|[0])/i){
         # a diff of 1+ is considered as change
         return "0";
      }
   }

   VDSetLastError("EFAILED");
   return FAILURE;
}


###############################################################################
#
# DoDiff -
#       Perform a diff of initial and final stats. Take the diff and compare
#       it with template. It's a parent(Stats) method.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub DoDiff
{
   my $self = shift;
   #
   # Get all the nodes from the stats bucket.
   # For each node 1) take a diff of the final - initial state
   #
   my $allNodes;
   my $bucket = $self->GetBucket();
   # Run the loop on all nodes in the stats bucket
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $node = $allNodes->{$nodeKey};
         #
         # Before taking a diff of final - initial value
         # check 1) if the node is supported 2) If both initial
         # and final values are there
         #
         if (((defined $node->{supported}) && ($node->{supported} =~ /no/i))){
            delete $allNodes->{$nodeKey};
            next;
         }
         if (not defined $node->{final}) {
            $vdLogger->Error("final log/data is missing");
            VDSetLastError("ENOTDEFINED");
            return FAILURE;
         }
         if (not defined $node->{initial}) {
            #
            # When initial hash is not defined that means there was no
            # initial state. Thus in formual diff = |final - initial| we
            # make diff = final as initial is NULL
            # E.g. lacp stats instead of saying tx = 0 will display
            # lacp is disabled. after enabling it tx becomes 1. Thus diff
            # should be tx = 1 as intial state was null. This is generic
            # concept and will apply in make places.
            #
            $vdLogger->Debug("Initial data is NULL. Making Diff = Final");
            $node->{diff} = $node->{final};
            return SUCCESS;
         }
         #
         # Just take diff of the final - intial value
         # if the diff is -ve it means the device must have got reset
         # in between which might have made all counters 0. thus
         # final counter value < initial value
         #
         my ($resultHash, $finalValue, $initialValue);
         my $finalHash = $node->{final};
         my $initHash = $node->{initial};
         foreach my $key (keys %$finalHash){
            if(defined $initHash->{$key}) {
               #
               # TODO: Call a method here to perform diff on counters for stats
               # and pktcap and diff on file for LogVerification
               #
               my $actualResult = $self->PerformActualDiff($initHash->{$key},
                                                           $finalHash->{$key},
                                                           $key);
               $resultHash->{$key} = $actualResult;
               $vdLogger->Trace("actualResult in DoDiff():" .
                                Dumper($actualResult));
            } else {
               $vdLogger->Warn("Key:$key is missing in initial hash");
               $resultHash->{$key} = $finalHash->{$key};
            }
         }
         # Saving the diff
         $node->{diff} = $resultHash;
      }
   }

   return SUCCESS;
}



###############################################################################
#
# PerformActualDiff -
#       Perform a diff on the counter values.
#
# Input:
#       initial value
#       final value
#       key - counter name/stats name (optional)
#
# Results:
#       diff - difference in final - intial value.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub PerformActualDiff
{
   my $self = shift;
   my $initialValue = shift;
   my $finalValue = shift;
   my $counterName = shift;
   my $result;

   if (ref($finalValue) =~ /HASH/) {
      if (ref($initialValue) !~ /HASH/) {
         $vdLogger->Error("Initial and final value must be of same type, HASH");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      foreach my $key (keys %$initialValue) {
         if (!exists $finalValue->{$key}) {
            $vdLogger->Error("key:$key not present in final hash. ".
                             "Skipping it...");
            next;
         } else {
            next if (not defined $finalValue->{$key}) &&
                    (not defined $initialValue->{$key});
            $result->{$key} = $self->PerformActualDiff($initialValue->{$key},
                                                $finalValue->{$key}, $key);
            if ($result->{$key} eq FAILURE) {
               $vdLogger->Error("PerformActualDiff($initialValue->{$key},".
                                "$finalValue->{$key}) returned failure");
               VDSetLastError("EFAILED");
               return FAILURE;
            }
         }
      }
   } elsif (ref($finalValue) =~ /ARRAY/) {
      if (ref($initialValue) !~ /ARRAY/) {
         $vdLogger->Error("Initial and final value must be of same type, ARRAY");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      if (scalar(@$initialValue) !=  scalar(@$finalValue)) {
         $vdLogger->Error("Initial and final Array must be of same size. ".
                          "Still continuing...");
      }
      my $count = 0;
      my @resultArray;
      foreach (@$initialValue) {
         my $firstInput =  $$initialValue[$count];
         my $secondInput = $$finalValue[$count];
         my $ret = $self->PerformActualDiff($firstInput, $secondInput);
         if ($ret eq FAILURE) {
            $vdLogger->Error("PerformActualDiff($firstInput, $secondInput) ".
                             "returned failure");
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         push(@resultArray,  $ret);
         $count++;
      }
      $result = \@resultArray;
   } else {
      if ((not defined $finalValue) &&
          (not defined $initialValue)) {
         return "";
      }
      if (not defined $initialValue) {
         $initialValue = "";
      }
      if (not defined $finalValue) {
         $finalValue = "";
      }
      if (($finalValue =~ /(\D+)/) ||
          ($initialValue =~ /(\D+)/)) {
         #
         # We do the diff of two strings
         # for string we usually want the counter to go from state1-state2
         # thus we return intialState->finalState.
         #
         $result = "$initialValue" . "->" . "$finalValue";
      } else {
         #
         # This is where we do the diff of the counters. For integers
         # diff is always final - initial
         #
         $result = $finalValue - $initialValue;
      }
      $vdLogger->Trace("counterName:$counterName, finalValue:$finalValue,".
                       " initialValue:$initialValue");
   }

   return $result;

}

###############################################################################
#
# CompareNodes -
#       Compare the diff(final - initial) computed with expected value set
#       by user or workload. Based upon comparison of expected value and
#       actual value(diff) set pass/fail on the respective counter.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub CompareNodes
{
   my $self = shift;
   #
   # Get all the nodes from the stats bucket.
   # For each node compare diff and tempalte. i.e.
   # Compare each counter's expected value and actual value
   # and tag pass/fail on that counter.
   #
   my ($allNodes, $resultHash);
   my $bucket = $self->GetBucket();
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $node = $allNodes->{$nodeKey};
         if ((not defined $node->{diff}) ||
             (not defined $node->{template})) {
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         my $diffHash = $node->{diff};
         my $tempalateHash = $node->{template};
         #
         # For each expected counter key in template, comparing it with
         # the actual value.
         #
         my $expectedCounterFound = 0;
         foreach my $key (keys %$tempalateHash) {
            #
            # If there is no expectation set on this counter move on to next.
            next if $tempalateHash->{$key} eq '0';
            $expectedCounterFound = 1;
            #
            # Split the expectation type and expected value.
            # as we store it as "4+:user" which means user expects it to be
            # more than 4 or more.
            #
            my @tempExpValue = split(':',$tempalateHash->{$key});
            my $expValue = $tempExpValue[0];
            if (not defined $diffHash->{$key}) {
               # API return undef if key is not found thus no need for error
               # check.
               $diffHash->{$key} = $self->FindKeyInHash($diffHash, $key);
            }
            my $actualValue = $diffHash->{$key};
            my $counterResult;
            #
            # Set the result, expectation type, expected value, actual value,
            # intial and final value for each counter. Thus
            # bytesTSOTx hash will have all the above mentioned values.
            # and we store all these counters in their respective nodes.
            #
            if (defined $diffHash->{$key}) {
               if ($expValue =~ /\.\[/) {
                  my @values = split('\.',$expValue);
                  my $arrCount = scalar(@values);
                  my $expTarget = undef;
                  my $expType = undef;
                  if($arrCount > 1) {
                      $expTarget = $values[0];
                  }
                  if($arrCount > 2) {
                     $expType = $values[1];
                  }
                  $expValue = $values[$arrCount -1];
                  my $targetObj = $self->GetTargetObj($expTarget, $self->{veritype});
                  if($targetObj eq FAILURE) {
                     $vdLogger->Error("CompareCounterValues failed for ".
                                      "$key,$expValue,$actualValue");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
                  my $targetKey;
                  if ($expValue =~ /^(\w+)/) {
                     $targetKey = $1;
                  } else {
                     $vdLogger->Error("Remote Obj's key not defined in expectedChange");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
                  my $targetValue = $targetObj->{statsbucket}->{$nodesInBucket}->{$nodeKey}->{diff}->{$targetKey};
                  if ($expValue =~ m/(\.*)(\+*|\-*)(\+*|\-*)(\d*)$/) {
                     $expValue = $targetValue . "$2". "$3" . "$4";
                  }

                  if($expValue =~ /(\d+)\+(\d+)/) {
                     $expValue = int($1)+int($2);
                  } elsif($expValue =~ /(\d+)\-(\d+)/) {
                     $expValue = int($1)-int($2);
                  } elsif($expValue =~ /(\d+)(\+|\-)(\+|\-)(\d+)/) {
                     my $start = int($1)-int($4);
                     my $end = int($1)+int($4);
                     $expValue =     $start . "-" . $end;
                  }
               }
               $counterResult = $self->CompareCounterValues($expValue, $actualValue);
               if($counterResult eq FAILURE) {
                  $vdLogger->Error("CompareCounterValues failed for ".
                                   "$key,$expValue,$actualValue");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               $resultHash->{$key}->{result} = $counterResult;
               $resultHash->{$key}->{expectationtype} = $tempExpValue[1];
               $resultHash->{$key}->{expectedvalue} = $expValue;
               $resultHash->{$key}->{actualvalue} = $actualValue;
               if(defined $node->{initial}->{$key}) {
                  $resultHash->{$key}->{initial} = $node->{initial}->{$key};
               } else {
                  $resultHash->{$key}->{initial} = $self->FindKeyInHash($node->{initial}, $key);
#                 $resultHash->{$key}->{initial} = undef;
               }
               if(defined $node->{final}->{$key}) {
                  $resultHash->{$key}->{final} = $node->{final}->{$key};
               } else {
                  $resultHash->{$key}->{final} = $self->FindKeyInHash($node->{final}, $key);
#                 $resultHash->{$key}->{final} = undef;
               }
            } else {
               $vdLogger->Error("It is strange that the templatekey:$key is ".
                                 "missing in diff");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

         }
         # If there was no expectation with this node then delete the node so
         # that we dont display blank result line in DisplayDiff
         if($expectedCounterFound == 0) {
            delete $allNodes->{$nodeKey};
         }

         # A node will thus have hashes which are all counters containing
         # all states.
         $node->{result} = $resultHash;
         $resultHash = undef;
         # Freeing up resources to conserve memory.
         delete $node->{template};
         # Not deleting diff as some other obj might need it for
         # relative comparison of counters.
         if(defined $node->{initial}) {
            delete $node->{initial};
         }
         if(defined $node->{final}) {
            delete $node->{final};
         }
      }
   }

   return SUCCESS;

}


###############################################################################
#
# CompareCounterValues -
#       Compare actual counter value with expected value and determine pass or
#       fail.
#
# Input:
#       expectedValue (mandatory)
#       actualValue (mandatory)
#
# Results:
#       pass/fail - in case everthing goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
###############################################################################

sub CompareCounterValues
{
   my $self = shift;
   my $expectedValue = shift;
   my $actualValue = shift;
   if (not defined $expectedValue || not defined $actualValue){
      $vdLogger->Error("Either expectedvalue:$expectedValue or ".
                       "actualvalue:$actualValue is missing in ".
                       "CompareCounterValues");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($expectedValue =~ /\%/) {
      if ($actualValue !~ /\%/) {
         $vdLogger->Error("Data Units are not same in CompareCounterValues");
      } else {
         $expectedValue =~ s/\%//g;
         $actualValue =~ s/\%//g;
      }
   }

   # If numbers are decimal, round them off
   if ($expectedValue =~ /\./) {
      $expectedValue =~ /(\d+)(\.)(\d)/;
      #
      # After this match $1 will have the num before .
      # $2 has the . and $3 matches the num after .
      # if the first digit after . is 5 or more then we
      # increment the number by 1 else round if off original
      # without decimals
      #
      if($3 > 4) {
         $expectedValue = int($1) + 1;
      } else {
         $expectedValue = int($1);
      }
   }
   if ($actualValue =~ /\./) {
      $actualValue =~ /(\d+)(\.)(\d)/;
      if($3 > 4) {
         $actualValue = int($1) + 1;
      } else {
         $actualValue = int($1);
      }
   }
   switch($expectedValue) {
      case m/(^change$)/i {
         #
         # Actual Value should be greater than 0 signifying
         # it has changed as its a diff
         #
         if(int($actualValue) > 0) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/^(nochange|[0])$/i {
         # Actual Value should be 0 signifying nochange as its a diff
         if(int($actualValue) == 0) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/(dontcare|ignore)/i {
         return "pass";
      }
      case m/^(\d+)(\+)$/i {
         # Actual Value should be equal to or more than expected value
         $expectedValue =~ m/(\d+)(\+)/i;
         my $temp = $1;
         if(int($actualValue) > (int($temp) - 1)) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/^(\d+)(\-)$/i {
         # Actual Value should be equal to or less than expected value
         $expectedValue =~ m/(\d+)(\-)/i;
         my $temp = $1;
         if(int($actualValue) < (int($temp) + 1)) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/^(\d+)$/i {
         # Actual Value should be equal to expected value
         $expectedValue =~ m/^(\d+)$/i;
         if(int($actualValue) == $1) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/^0x([0-9a-fA-F]{1,2})/i {
         $actualValue = substr $actualValue, 2;
         # Actual Value should be equal to expected value
         $expectedValue =~ m/^0x([0-9a-fA-F]{1,2})/i;
         if($actualValue eq $1) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/^(\d+)(\-)(\d+)$/i {
         # Actual Value should be in the expected range.
         $expectedValue =~ m/^(\d+)(\-)(\d+)$/i;
         my $rangeStart = $1;
         my $rangeEnd = $3;
         if((($rangeStart -1) < int($actualValue) ) &&
             (int($actualValue) < ($rangeEnd + 1))) {
            return "pass";
         } else {
            return "fail";
         }
      }
      case m/(\w+)(-|->)(\w+)/i {
         if ($actualValue =~ /$expectedValue/i) {
            return "pass";
         } else {
            $expectedValue =~ m/(\w+)(-|->)(\w+)/i;
            my $firstExpStr = $1;
            my $secondExpStr = $3;
            $actualValue =~ m/(\w+)(-|->)(\w+)/i;
            my $firstActualStr = $1;
            my $secondActualStr = $3;
            if ((not defined $firstExpStr) || (not defined $firstActualStr) ||
                (not defined $secondExpStr) || (not defined $secondActualStr) ||
                ($firstExpStr !~ /$firstActualStr/i) ||
                ($secondExpStr !~ /$secondActualStr/i)) {
               return "fail";
            } else {
               return "pass";
            }
         }
      }
      case m/\w+/ {
         # normal string comparsion
         if ($actualValue eq $expectedValue) {
            return "pass";
         } else {
            return "fail";
         }
      }

   }

   VDSetLastError("EFAILED");
   return FAILURE;
}


###############################################################################
#
# DisplayDiff -
#       Perform a diff of initial and final stats. Take the diff and compare
#       it with template. It's a parent(Stats) method.
#
# Input:
#       verification type (nic or vsish)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub DisplayDiff
{
   my $self = shift;
   my $displayType = $self->{displaytype} || "NodeCentric";

   my $tb = Text::Table->new(
      "COUNTERS                  ", "INITIAL VALUE  ", "FINAL VALUE  ",
      "CHANGE(Diff)  ", "EXPECTED CHANGE  ", "EXPECTED BY  ", "RESULT  ");
   #
   # Get the stats bucket
   # For each counter in a node load all the values of the counter
   # in a table to display it.
   #
   my ($allNodes, $resultHash);
   my $partition = "------------------------------------------";

   my $bucket = $self->GetBucket();
   # Run the loop on all nodes of all machines.
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $allCounters = $allNodes->{$nodeKey}->{result};
         if (not defined $allCounters) {
            $vdLogger->Warn("Result hash not defined for $nodeKey on ".
                            "$self->{nodeid} $self->{target}");
            return SUCCESS;
         }
         foreach my $counter (keys %$allCounters) {
            my $counterHash = $allCounters->{$counter};
            my $expectationBy = $counterHash->{expectationtype};
            $expectationBy = "user" if $expectationBy =~ /(specific|generic)/i;
            if($displayType =~ /targetcentric/i) {
               $counter =  $nodeKey . " -> " . $counter;
            }
            $tb->load([$counter,
                       $counterHash->{initial},
                       $counterHash->{final},
                       $counterHash->{actualvalue},
                       $counterHash->{expectedvalue},
                       $expectationBy,
                       $counterHash->{result}
            ]);
         }
         if ($displayType =~ /nodecentric/i) {
            print $partition . $partition . $partition . "\n";
            $vdLogger->Info("Results for ".
                            uc($self->{veritype})." \nTarget:\t\t\t ".
                            "$self->{target} \nMachine Node:\t\t ".
                            "$self->{nodeid} \nVerification ".
                            "Node:\t $nodeKey\n\n". $tb);
            $tb->clear();
         }
      }
      if ($displayType =~ /targetcentric/i) {
            $vdLogger->Info("Results for ".
                            uc($self->{veritype}).
                            " \nTarget:\t\t\t $self->{target}".
                            "\nMachine Node:\t\t $self->{nodeid} \n\n". $tb);
         $tb->clear();
      }
   }

   return SUCCESS;
}


###############################################################################
#
# ReportResult -
#       Perform a diff of initial and final stats. Take the diff and compare
#       it with template. It's a parent(Stats) method.
#
# Input:
#       verification type (nic or vsish)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub ReportResult
{
   my $self = shift;
   my ($allNodes, @failedCounters);

   $self->{resulthash}->{actualresult} = "PASS";

   my $bucket = $self->GetBucket();
   # Run the loop on all nodes of all machines.
   foreach my $nodesInBucket (keys %$bucket) {
      $allNodes = $bucket->{$nodesInBucket};
      foreach my $nodeKey (keys %$allNodes) {
         my $allCounters = $allNodes->{$nodeKey}->{result};
         foreach my $counter (keys %$allCounters) {
            my $counterHash = $allCounters->{$counter};
            if ((defined $counterHash) &&
                ($counterHash->{result} =~ /fail/)) {
               push(@failedCounters, $counter);
               #
               # Parent and child communicate using the shared
               # var = resulthash.
               # If a child module fails it updated the parent
               # var and tells him the counters because of which
               # it failed.
               #
               $self->{resulthash}->{actualresult} = "FAIL";
            }
         }
      }
   }

   #
   # We dont need the key expectedresult in this New Verification.
   # This is just for keeping the the old testcases backward compatible
   # Thus when expectedresult is set to fail and actualresult is fail
   # then make the actualresult as pass.
   # This block will become obsolete once BACKWARD_COMPATIBLE flag
   # is turned off.
   #
   if ((BACKWARD_COMPATIBLE == 1) && defined $self->{expectedresult}) {
      my $expectedResult = $self->{expectedresult};
      if (($expectedResult =~ /(fail|ignore)/i) &&
          ($self->{resulthash}->{actualresult} =~ /fail/i)) {
         $self->{resulthash}->{actualresult} = "PASS";
      }
   }

   if (@failedCounters > 0) {
      #
      # Tell the parent about the counters because of which this
      # child failed.
      #
      $self->{resulthash}->{reason} = "failedcounters";
      $self->{resulthash}->{failedcounters} = \@failedCounters;
      my $veritype = $self->{veritype};
      my $target = $self->{target};
      my $str = $veritype . "-" . $target;
      $vdLogger->Trace("Dumping all the counters which caused failure of ".
                       "$str " . Dumper(@failedCounters));
   }

   return $self->{resulthash}->{actualresult};

}


###############################################################################
#
# GetPriority -
#       Some verfications might be critical to start at once. Thus we
#       prioritize them using the way we store them.
#       child modules can override it.
#
# Input:
#       None
#
# Results:
#       string - containing string based id.
#
# Side effects:
#       None
#
###############################################################################

sub GetPriority
{
   my $self = shift;
   #
   # Will use this incase a module has higher priority.
   # Some verifications might be time sensitive.
   #
   return "";

}


###############################################################################
#
# GetTargetObj -
#       Some verfications might be critical to start at once. Thus we
#       prioritize them using the way we store them.
#       child modules can override it.
#
# Input:
#       None
#
# Results:
#       string - containing string based id.
#
# Side effects:
#       None
#
###############################################################################

sub GetTargetObj
{
   my $self = shift;
   my $target = shift;
   my $veriType = shift;
   my $targetAlias;

   if (not defined $target || not defined $veriType){
      $vdLogger->Trace("Either target or verification type not provided ".
                       "in GetTargetObj");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($target !~ /vm$/ && $target !~ /host$/ && $target !~ /:/ ) {
      my $workloadhash = $self->{workloadhash};
      my $workloadnode;
      if ($workloadhash =~ /traffic/i) {
         $workloadnode = "client" if $target =~ /src/i;
         $workloadnode = "server" if $target =~ /dst/i;

         if(not defined $workloadhash->{$workloadnode}){
            $vdLogger->Error("workloadnode:$workloadnode missing in workloadhash for ".
                             "endpoint:$target method ConvertVerificationNode()");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         #
         # This is the node we want to find in testbed and read
         # all its params.
         # Either use the nodeid in both traffic and verification or
         # use machinename, adapterindex and adapter as diff vars.
         #
         $targetAlias = $workloadhash->{$workloadnode}->{nodeid};
      }
   } else {
      $targetAlias = $self->{nodes}->{$target}->{nodeid}
   }

   if (not defined $targetAlias){
      $vdLogger->Error("$veriType not done on $target. Not object found.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $allChildrens = $self->{myparent}->{allchildrens};
   foreach my $child (keys %$allChildrens) {
      if ((($child =~ $target) || ($child =~ $targetAlias)) &&
           ($child =~ /$veriType/i)) {
         return $allChildrens->{$child};
      }
   }

   return undef;

}


##############################################################################
#
# GetBackwardCompatibility --
#       Return backward compatibility flag.
#
# Input:
#       none
#
# Results:
#       same as header.
#
# Side effects:
#       None
#
##############################################################################

sub GetBackwardCompatibility
{
   return BACKWARD_COMPATIBLE
}


##############################################################################
#
# FindKeyInHash --
#       If the diff is a nested hash and the user is interested in one of the
#       key in the hash, then find that key return the value
#
# Input:
#       key (mandatory)
#
# Results:
#       undef if not found
#       value of the key if found
#
# Side effects:
#       None
#
##############################################################################

sub FindKeyInHash
{
   return undef;
}

##############################################################################
#
# DESTROY --
#       Destructor of this class.
#
# Input:
#       string - hash which has to be converted.
#
# Results:
#       Hash of nodes.
#
# Side effects:
#       None
#
##############################################################################

sub DESTROY
{
   return SUCCESS;
}
1;
