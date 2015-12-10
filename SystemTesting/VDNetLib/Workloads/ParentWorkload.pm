########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::ParentWorkload;

#
# This package has methods which will be common across
# all *Workloads.pm modules
#

use FindBin qw($Bin);
use lib "$FindBin::Bin/../";
use strict;
use warnings;
use Storable 'dclone';
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger PASS FAIL SKIP PERSIST_DATA_REGEX);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack VDGetAllErrors IsFailure);
use VDNetLib::Common::Tasks;
use VDNetLib::Common::ZooKeeper;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use VDNetLib::InlinePython::VDNetInterface qw(LoadInlinePythonModule
                                              ConvertYAMLToHash
                                              ConvertToPythonBool);
use VDNetLib::Testbed::Utilities;
use Inline::Python qw(py_call_function);
use VDNetLib::Common::Utilities;
use Storable 'dclone';
use VDNetLib::Workloads::Utilities;
use List::Util qw(first);
use Scalar::Util qw(blessed);
use constant COMPONENT_DELIMITER => '(?<=\]),';



########################################################################
#
# StoreComponentObject--
#     Only one object is stored in the testbed for the specific tuple id.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       tuple         - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - Result from the core api
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     Range is not supported currenlty
#
########################################################################

sub APIPostProcess
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;
   if ((exists $paramValues->{$keyName}{'[1]'}{metadata}{skipstorage}) &&
       ($paramValues->{$keyName}{'[1]'}{metadata}{skipstorage} =~ /yes/i)) {
      # Since the code flow is associated with
      # crud tests, we dont store the objects.
      # We directly call the DeleteComponent()
      # to cleanup/check if deletion of component
      # works.
      my $result = $testObject->DeleteComponent($runtimeResult);
      if ($result eq FAILURE) {
         $vdLogger->Error("Deletion of obj failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      return $self->StoreSubComponentObjects($testObject,
                                             $keyName,
                                             $keyValue,
                                             $paramValues,
                                             $runtimeResult);
   }
   return SUCCESS;
}


########################################################################
#
# InitVerification -
#       If Verification key is defined then set event and ask
#       Caller(WorkloadManager) to provide the verification hash
#
# Input:
#       workloadhash - A workload hash should be a blessed object
#       of any of the trafficworkload, switchworkload's session data.
#       E.g. trafficworkload send session hash as workloadhash (optional)
#
# Results:
#       verification Obj - in case verification was called successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub InitVerification
{
   my $self = shift;
   my $workloadhash = shift || undef;
   #
   # Check in cache if we got any verification hash in previous iterations
   # if yes, use it. If no, then see if verification key is defined.
   # if defined get the verification hash.
   #
   my $verifyHash = $self->{cache}->{verificationhash};
   if (not defined $verifyHash) {
      #
      # Check if parent has supplied verification hash, if not
      # ask parent to return that hash.
      #
      if (ref($self->{'verification'}) =~ /HASH/i) {
         $verifyHash = $self->{'verification'};
      } else {
         $vdLogger->Trace("Using SetEvent to ReturnWorkloadHash from parent");
         $verifyHash = $self->{testbed}->SetEvent("ReturnWorkloadHash",
                                                 $self->{'verification'});
         if (FAILURE eq $verifyHash || (ref($verifyHash) !~ /HASH/)) {
            $vdLogger->Error("Failed to get Verification hash:" .
                             "$self->{'verification'} from parent");
            VDSetLastError(VDGetLastError());
            return FAIL;
         }
      }
      #
      # If we have found the verification hash for the first time
      # then save it in cache for subsequent iterations for traffic
      #
      $self->{cache}->{verificationhash} = $verifyHash;
   }

   $vdLogger->Info("Working on Verification of switch functionality ...");
   $vdLogger->Trace(Dumper($verifyHash));
   my $veriModule = "VDNetLib::Verification::Verification";
   eval "require $veriModule";
   if ($@) {
      $vdLogger->Error("Loading Verification.pm, failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # Each Worklod should have his own sub log folder where it can
   # store verification logs
   #
   my $verificationLogs = $self->{localLogsDir};
   if (not defined $verificationLogs) {
      $vdLogger->Warn("var 'localLogsDir' missing in this workload. ".
                       "Required to collect verification logs");
   }
   my $veriObj = $veriModule->new(testbed => $self->{testbed},
                                  verificationhash => $verifyHash,
                                  workloadhash => $workloadhash,
                                  localLogsDir => $verificationLogs
                                 );
   if ($veriObj eq FAILURE) {
      $vdLogger->Error("Verification obj creation failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{verificationHandle} = $veriObj;

   if ($veriObj->StartVerification() eq FAILURE) {
      $vdLogger->Error("StartVerification failed in SwitchWorkload");
      $vdLogger->Debug(Dumper($veriObj));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $veriObj;
}


########################################################################
#
# FinishVerification -
#       Calls StopVerification and then GetResult on verification for
#       the a workload
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case session is started successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub FinishVerification
{
   my $self = shift;
   my $verificationResult;

   # verificationHandle should be defined because FinishVerification()
   # is called only when user defines verification key in the
   # workload hash
   my $veriObj = $self->{verificationHandle};
   if (not defined $veriObj) {
      $vdLogger->Error("Verfication Handle missing in SwitchWorkload");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($veriObj->StopVerification() eq FAILURE) {
      $vdLogger->Error("StopVerification failed in TrafficWorkload");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $verificationResult = $veriObj->GetResult();
   #
   # Freeing memory by destroying the obj explicitilty
   #
   $self->{verificationHandle} = undef;

   if ($verificationResult ne SUCCESS) {
      $vdLogger->Error("Verification of SwitchWorkload failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $verificationResult;
}


#######################################################################
#
# GetNetAdapterObject --
#      This method is used to return network adapter object from the
#      Testbed datastructure
#
# Input:
#      intAdapter  : number (ver1) and tuple (ver2)  (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#      intType     : either vnic or vmknic/vmnic
#
# Result:
#      Based on the $index, vmnic adapter object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetNetAdapterObject
{
   my $self         = shift;
   my %args         = @_;
   my $target       = $args{target};
   my $intType      = $args{intType};
   my $testAdapter  = $args{testAdapter};
   my $tuple;

   $testAdapter =~ s/\:/\./g;
   if (($self->{testbed}{version} == 1) && ($testAdapter =~ /^\d+$/)) {
      if (defined $intType) {
         $tuple = "$target.$intType.$testAdapter";
      } else {
         $tuple = "$target.vnic.$testAdapter";
      }
   } else {
      $tuple = "$testAdapter";
   }
   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
#  GetHostObject --
#       This method can be used for getting the desired support
#       host obj
#
# Input:
#       args - a tuple or number. Default will be SUT.host.1 for ver1
# Results:
#      SUCCESS - return the reference to array containg the host obj
#      FAILURE in case of any failures
#
# Side effetcs:
#       None
#
########################################################################

sub GetHostObjects
{
   my $self   = shift;
   my $args   = shift || undef;
   my $tuple;

   if (not defined $args) {
      $tuple = "SUT.host.1";
   }

   if (($self->{testbed}{version} == 1) && ($args !~ /\.+/)) {
      $tuple = "$args.host.1";
   } else {
      $tuple = "$args";
   }

   $tuple =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
#  GetVCObjects --
#       This method can be used for getting the desired
#       vc obj
#
# Input:
#       args - a tuple or number. Default will be SUT.vc.1 for ver1
#
# Results:
#      SUCCESS - return the reference to array containg the vc obj
#      FAILURE in case of any failures
#
# Side effetcs:
#       None
#
########################################################################

sub GetVCObjects
{
   my $self   = shift;
   my $args   = shift;
   my $tuple;

   if (not defined $args) {
      $tuple = "SUT.vc.1";
   }

   if (($self->{testbed}{version} == 1) && ($args !~ /\.+/)) {
      $tuple = "$args.vc.1";
   } else {
      $tuple = "$args";
   }

   $tuple =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($tuple);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $tuple");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


########################################################################
#
# GetSwitchNames --
#      This method is used to return an array of switch names from
#      Testbed datastructure
#
# Input:
#      component   : number (ver1) and tuple (ver2) (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Returns an array of switch names
#
# Side effects:
#      None
#
#########################################################################

sub GetSwitchNames
{
   my $self      = shift;
   my $component = shift;
   my $target    = shift;
   my @names     = ();

   if (($component =~ /^\d+$/) || ($component =~ /(:|\.)/)) {
      my $refToArray = $self->GetSwitchObjects($component, $target);
      foreach my $element (@$refToArray) {
         my $swname;
         if (defined $element->{'switch'}) {
            $swname = $element->{'switch'};
         } elsif (defined $element->{'name'}) {
            $swname = $element->{'name'};
         }
         push(@names, $swname);
      }
   } else {
      push (@names, $component);
   }

   return \@names;
}


#######################################################################
#
# GetSwitchObjects --
#      This method is used to return switch object from the
#      Testbed datastructure.
#      Cannot be used for physical switches
#
# Input:
#      component   : number (ver1) and tuple (ver2)  (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Based on the $index, switch object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetSwitchObjects
{
   my $self      = shift;
   my $component = shift;
   my $target    = shift;
   my $args;
   my $ref;

   $component =~ s/\:/\./g;
   if (($self->{testbed}{version} == 1) && ($component =~ /^\d+$/)) {
      $args = "$target.switch.$component";
   } else {
      $args = $component;
   }
   $ref = $self->{testbed}->GetComponentObject($args);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $args");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


#######################################################################
#
# GetPortGroupNames --
#      This method is used to return an array of portgroup names from
#      Testbed datastructure
#
# Input:
#      component   : number (ver1) and tuple (ver2) (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Returns an array of portgroup names
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupNames
{
   my $self      = shift;
   my $component = shift;
   my $target    = shift;
   my @names     = ();
   if (($component =~ /^\d+$/) || ($component =~ /(:|\.)/)) {
      my $refToArray = $self->GetPortGroupObjects($component, $target);
      foreach my $element (@$refToArray) {
         push(@names, $element->{'pgName'});
      }
   } else {
      push (@names, $component);
   }
   return \@names;
}


#######################################################################
#
# GetPortGroupObjects --
#      This method is used to return portgroup object from the
#      Testbed datastructure
#
# Input:
#      component   : number (ver1) and tuple (ver2) (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Based on the $index, port group object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetPortGroupObjects
{
   my $self      = shift;
   my $component = shift;
   my $target    = shift;
   my $args;
   my $ref;

   $component =~ s/\:/\./g;
   if (($self->{testbed}{version} == 1)  && ($component =~ /^\d+$/)) {
      $args = "$target.portgroups.$component";
   } else {
      $args = $component;
   }
   $ref = $self->{testbed}->GetComponentObject($args);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $args");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


#######################################################################
#
# GetComponentObjects --
#      This method is used to return component objects from the
#      Testbed datastructure
#
# Input:
#      component   : tuple, example: host.[<index>].component.[<index>]
#
# Result:
#      Based on the $index, component object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetComponentObjects
{
   my $self      = shift;
   my $component = shift;
   my $args;
   my $ref;
   $ref = $self->{testbed}->GetComponentObject($component);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $component");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}

#######################################################################
#
# GetPyComponentObjectsFromTuple--
#      This method is used to return python component objects from the
#      Testbed datastructure
#
# Input:
#      keyvalue: tuple, example: esx.[<index>], esx.[<lastindex>]
#
# Result:
#      Based on the indices, corresponding Facade objects are returned.
#
# Side effects:
#      None
#
########################################################################

sub GetPyComponentObjectsFromTuple
{
   my $self = shift;
   my $keyValue = shift;
   my @arrayOfNodes;
   my $perlObjs = $self->GetMultipleComponentObjects($keyValue);
   if ($perlObjs eq FAILURE) {
       $vdLogger->Error("Failed to get testbed components for $keyValue");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   foreach my $perlObj (@$perlObjs) {
      my $parentPyObj;
      if (exists $perlObj->{parentObj}) {
         my $parentPerlObj = $perlObj->{parentObj};
         $parentPyObj = $parentPerlObj->GetInlinePyObject();
         if ($parentPyObj eq FAILURE) {
            $vdLogger->Error("Failed to get inline python object for" .
                             "$parentPerlObj");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }
      my $pyObj = $perlObj->GetInlinePyObject($parentPyObj);
      if ($pyObj eq FAILURE) {
         $vdLogger->Error("Failed to get inline python object for $perlObj");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfNodes, $pyObj;
   }
   return \@arrayOfNodes;
}


#######################################################################
#
# GetVMObjects --
#      This method is used to return vm object from the
#      Testbed datastructure
#
# Input:
#      component   : number (ver1) and tuple (ver2) (mandatory)
#      target      : SUT/Helper (mandatory for ver1)
#
# Result:
#      Based on the target,vm object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetVMObjects
{
   my $self   = shift;
   my $target = shift;

   my $args;
   if (($self->{testbed}{version} == 1) && ($target !~ /\.+/)) {
      $args = "$target.vm.1";
   } else {
      $args = $target;
   }
   $args =~ s/\:/\./g;
   my $ref = $self->{testbed}->GetComponentObject($args);
   if (not defined $ref) {
      $vdLogger->Error("Invalid ref for tuple $args");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref;
}


#######################################################################
#
# GetUplinkObjects --
#      This method returns reference of array of uplink adapter
#      objects from the Testbed datastructure in case of v2 and dummy
#      datastructre in case of v1.
#
# Input:
#      uplink   :  tuple for both ver1 and ver2 (mandatory)
#
# Result:
#      Based on the uplink tuple,vm object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetUplinkObjects
{
   my $self      = shift;
   my $uplink    = shift;
   my @netObjects;

   if (defined $uplink) {
      my @freepnics;
      my @arrayObject;
      my $freecount;
      my $count;
      my @pnics = split( /,/,$uplink);
      if (($self->{testbed}{version} == 1)) {
         for my $node (@pnics) {
            if ($node =~ /(.*):(.*):(.*)/) {
               my $host          = $1;
               my $driver        = $2;
               my $adapterNumber = $3;
               my $netHash = {};
               my $refHost = $self->GetHostObjects($host);
               my $hostObj = $refHost->[0];
               if (!defined $hostObj->{hostIP}){
                  next;
               }
               my $tuple = "$host.vc.1";
               my $refVCObj = $self->GetVCObjects($tuple);
               my $vcObj = $refVCObj->[0];
               my $esxUtils = $hostObj->{esxutil};
               my $refFreePnics = $esxUtils->GetFreePNics($hostObj->{hostIP},
                                                          $driver);
               if ($refFreePnics eq FAILURE) {
                  $vdLogger->Error("Failed to get free pnics from" .
                                   "under $hostObj->{hostIP}");
                  VDSetLastError("EFAIL");
                  return FAILURE;
               } else {
                  @freepnics = @{$refFreePnics};
                  $freecount = @freepnics;
               }
               if ($freecount < $adapterNumber){
                  $vdLogger->Error("There is no enough PNic on esx host," .
                                   "please check your test bed," .
                                   "free nics available: $freecount, required ".
                                   "pnics: $adapterNumber");
                  VDSetLastError("EFAIL");
                  return FAILURE;
               }
               for (my $item = 0; $item < $adapterNumber; $item++) {
                  $netHash->{interface} = $freepnics[$item];
                  $netHash->{hostObj}{hostIP} = $hostObj->{hostIP};
                  push (@netObjects, $netHash);
                  $netHash = undef;
               }
            }
         }
      } else {
         for my $node (@pnics) {
            my $ref = $self->GetNetAdapterObject(testAdapter => $node);
            my $netObj = $ref->[0];
            push (@netObjects, $netObj);
         }
      }
   }
   return \@netObjects;
}


########################################################################
#
#  GetListOfTuples --
#       This method can be used for getting comma separated list of tuples
#       for comma separated input. E.g. for input "SUT,helper1" and
#       type 'vc', the return value will be "SUT.vc.1,helper1.vc.1"
#
# Input:
#       args - comma separted string, e.g., SUT,helper1
# Results:
#      SUCCESS - return list of tuples
#      FAILURE - incase of null inpout
# Side effetcs:
#       None
#
########################################################################

sub GetListOfTuples
{
   my $self     = shift;
   my $string   = shift;
   my $type     = shift;
   my $index    = shift || "1";

   if ((defined $string) && (defined $type)) {
      my @arr = split(/,/, $string);
      my @tempArry = map {"$arr[$_]".":$type:$index"} 0..$#arr;
      my $newString = join (',', @tempArry);
      return $newString;
   } else {
      return FAILURE;
   }
}


########################################################################
#
#  ConfigureComponent --
#       This api is being used as a generic api. This api will be
#       called by all the workloads first. If the key is present in
#       the keydatabase of that workload, then this api will get executed
#       else the control will return back to the workload from where it
#       was invoked earlier.
#
# Input:
#       configHash        - configuration that needs to be executed. (Mandatory)
#       testObj           - object for which the above configuration needs to be
#                           done (netadapter/switch/vc/vm/host object).
#                           (Mandatory)
#       verificationStyle - Style of verification like diff. Default value
#                           is 'default'
#       tuple             - A way of representing vdnet objects, format is
#                           inventory.[index].component.[index].
#       skipPostProcess   - Key that allows vdnet to skip the execution of
#                           post process methods associated with action
#
# Results:
#       SUCCESS - in case configuration was successful
#       FAILURE - in case configuration was unsuccessful
#       undef   - in case key was not part of KEYSDATABASE
#
# Side effetcs:
#       None
#
########################################################################

sub ConfigureComponent
{
   my $self              = shift;
   my %args              = @_;
   my $configHash        = $args{configHash};
   my $testObj           = $args{testObject};
   my $tuple             = $args{tuple};
   my $skipPostProcess   = $args{skipPostProcess};
   my $skipMethod        = $args{skipMethod} || 0;
   my $verificationStyle = $args{verificationStyle};
   # TODO(prabuddh): Fix other workloads.pm files to pass in persist data
   # explicitly to ConfigureComponent and remove this key from their
   # configHash.
   my $persistData       = $args{persistData} || $configHash->{persistdata};
   #
   # For stress or large iteration workload, user might be interested in not
   # spending time on post-process such as storing/deleting objects etc.
   # Another use case: user needs to delete a component on server but
   # retain the object reference such that using stale attributes causes
   # workload to fail.
   # For example, delete a vnic and try to send traffic to/from using the
   # stale ip. The test should fail. If object is deleted, then vdnet will throw
   # error and prevent negative testing. In such cases, skippostprocess will be
   # useful.
   #

   unless (%$configHash) {
      $vdLogger->Info("Configuring component with NULL spec: " .
                   Dumper($configHash));
      return SUCCESS;
   }
   # Making the hash lower case
   %$configHash = (map { lc $_ => $configHash->{$_}} keys %$configHash);
   if (defined $configHash->{'skippostprocess'}) {
      $skipPostProcess = $configHash->{'skippostprocess'};
      delete $configHash->{'skippostprocess'};
   }
   if (defined $configHash->{'skipmethod'}) {
      $skipMethod = $configHash->{'skipmethod'};
      delete $configHash->{'skipmethod'};
   }
   $self->{runtime} = {};
   my $ret;
   # 1303989 need parse $configHash to calculate index if needed
   if (defined $tuple) {
      my $expandedSpec = VDNetLib::Common::Utilities::ExpandTupleValueRecursive(
                                              $configHash, $tuple);
      if (not defined $expandedSpec) {
         $vdLogger->Error("Expanded spec is undef for $tuple");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      if (IsFailure($expandedSpec)) {
         $vdLogger->Error("Failed to expand spec for $tuple " . Dumper($configHash));
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $configHash = $expandedSpec;
      $vdLogger->Info("Expanded spec for $tuple : " .
                   Dumper($configHash));
   }

   if (not defined $tuple) {
      # TODO (prabuddh): check why tuple is not passed in all cases
      $tuple = $self->{componentIndex};
   }

   if (not defined $tuple) {
      $tuple = $testObj->{objID};
   }
   if (not defined $tuple) {
      $vdLogger->Error("compentIndex and objID are not set and " .
                       "Component index $tuple not defined at function: " .
                       Dumper(caller));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Info("Configuring component $tuple with spec: " .
                   Dumper($configHash));

   my $keysDatabase = $self->{keysdatabase};
   # Process all Parameters type
   foreach my $index (keys %{$configHash}) {
      if ($index =~ /\[\?\]/) {
         #
         # if the key has delimiter in the key
         # like this 'checkifexists[~]contains',
         # then this is verification key and
         # shouldnot be processed by parameter
         # section. So skip this key.
         next;
      }
      if (not defined $keysDatabase->{$index}) {
         $vdLogger->Warn("Parameter key *$index* not part of KEYSDATABASE, " .
                          "this will trigger legacy code paths");
         return undef;
      }
      if ((exists $keysDatabase->{$index}) &&
          (defined $keysDatabase->{$index}{type}) &&
          ($keysDatabase->{$index}{type} ne "parameter")) {
         $vdLogger->Trace("Skipping non parameter type argument: $index");
         next;
      }
      # reseting the result for each param key
      $ret = FAILURE;
      $vdLogger->Debug("Storing arguments based on the parameter $index");
      if (exists $keysDatabase->{$index}) {
         my $result = undef;
         if ($configHash->{$index} =~ PERSIST_DATA_REGEX) {
            $vdLogger->Debug("Start to fetch the runtime data for $configHash->{$index}");
            $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                                  $configHash->{$index},
                                                                  $index);
            if ($result eq FAILURE) {
                $vdLogger->Error("Failed to get saved runtime data for $configHash->{$index}");
                VDSetLastError("EOPFAILED");
                return FAILURE;
            }
            $self->{runtime}{parameters}{$index} = $result;
         } elsif (defined $keysDatabase->{$index}{method}) {
            my $method = $keysDatabase->{$index}{method};
            $result = $self->$method($configHash->{$index}, $testObj, $index);
            $vdLogger->Debug("Method $method on Parameter key $index " .
                             "returned" . Dumper($result));
            if ($result eq FAILURE) {
                $vdLogger->Error("Failed to set Parameter of $index using $method");
                VDSetLastError("EOPFAILED");
                return FAILURE;
            }
            $self->{runtime}{parameters}{$index} = $result;
         } else {
            $self->{runtime}{parameters}{$index} = $configHash->{$index};
         }
      } else {
            $vdLogger->Warn("Skipping non keydb based parameter: $index");
            return FAILURE;
      }
      $ret = SUCCESS;
   }

   $vdLogger->Trace("Parameter processing completed, " .
                    "now process action keys");
   # Process all Action type
   foreach my $index (keys %{$configHash}) {
      if ($index =~ /\[\?\]/) {
         #
         # if the key has delimiter in the key
         # like this 'checkifexists[~]contains',
         # then this is verification key and
         # shouldnot be processed by action
         # section. So skip this key.
         next;
      }
      if (not defined $configHash->{$index}) {
         next;
      }
      if (not defined $keysDatabase->{$index}) {
         $vdLogger->Warn("Action key *$index* not part of KEYSDATABASE " .
                          "this will trigger legacy code paths");
         return undef;
      }
      if ((exists $keysDatabase->{$index}) &&
          (defined $keysDatabase->{$index}{type}) &&
         (($keysDatabase->{$index}{type} ne "action") &&
         ($keysDatabase->{$index}{type} ne "component"))) {
         next;
      }
      if ($configHash->{$index} =~ PERSIST_DATA_REGEX) {
         $vdLogger->Debug("Start to fetch the runtime data for $configHash->{$index}");
         my $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                               $configHash->{$index},
                                                               $index);
         if ($result eq FAILURE) {
             $vdLogger->Error("Failed to get saved runtime data for $configHash->{$index}");
             VDSetLastError("EOPFAILED");
             return FAILURE;
         }
         $configHash->{$index} = $result;
      }
      # reseting the result for each action key
      if (exists $keysDatabase->{$index}) {
         $ret = FAILURE;
         $vdLogger->Debug('calling HandleActionKeys');
         $ret = $self->HandleActionKeys($testObj, $configHash, $index,
                                        $skipPostProcess, $skipMethod);
         if ($ret eq FAILURE) {
            $vdLogger->Error("Failure while processing action type keys");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   $vdLogger->Trace("action keys processing completed, " .
                    "now process verification keys");

   # Process all Verification type
   foreach my $index (keys %{$configHash}) {
      if (not defined $configHash->{$index}) {
         next;
      }
      my $globalCondition;
      if ($index =~ /\[\?\]/) {
         #
         # if the key has delimiter in the key
         # like this 'checkifexists[~]contains',
         # then we need to split the above string
         # and extract the key and global condition
         # out if it, and make changes to the cofig
         # hash as well.
         #
         my @arrayOfInitialVal = split ('\[\?\]', $index);
         $globalCondition = $arrayOfInitialVal[1];
         my $backupHash = dclone $configHash->{$index};
         delete $configHash->{$index};
         $index = $arrayOfInitialVal[0];
         $configHash->{$index} = dclone $backupHash;
      }
      if (not defined $keysDatabase->{$index}) {
         $vdLogger->Warn("Verification key *$index* not part of KEYSDATABASE, " .
                          "this will trigger legacy code paths");
      } elsif (not defined $keysDatabase->{$index}{type}) {
          $vdLogger->Warn("Type of key (e.g. action/verification/component) " .
                          "is not specified in this key definition:\n" .
                          Dumper($keysDatabase->{$index}))
      }

      if ((defined $keysDatabase->{$index}{type}) &&
         ($keysDatabase->{$index}{type} ne "verification")) {
         next;
      }
      $vdLogger->Trace("Start verification for key $index");
      # reseting the result for each verification key
      $ret = FAILURE;
      $ret = $self->HandleVerificationKeys($testObj,
                                           $configHash,
                                           $index,
                                           $skipPostProcess,
                                           $globalCondition,
                                           $verificationStyle,
                                           $persistData);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Verification failed for key $index");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Verification passed for key $index");
   }
   return $ret;
}

########################################################################
#
# PreProcessNSXHashTypeAPI --
#     Method to process NSX specs which does not involve any vdnet component
#     creation. REST calls are POST, we use CreateAndVerifyComponent from vdnet
#     point of view as the obj is new but there is no need to store it as object
#     in zookeeper or tuple thus we just create it and forget about it
#     treating it as configuration on exisiting vdnet object
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#
# Results:
#     Reference to an array which has 3 elements:
#     [0]: name of the component
#     [1]: reference to the test object
#     [2]: reference to an array of hash which contains hash as
#          spec
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNSXHashTypeAPI
{
   my $self       = shift;
   my $testObject = shift;
   my $keyName    = shift;
   my $keyValue   = shift;
   my $paramValue = shift;
   my $paramList  = shift;

   my @array;
   push(@array, %$paramValue);
   return [$keyName, \@array];
}


########################################################################
#
#  PreProcessShiftTypeAPI --
#       This method pushes runtime parameters into an array in proper oder
#       and returns the reference to array. This API is used mainly where
#       the arguments are shift type and not hash based input.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
#       For e.g. For Following key 'mtu' and workload 'TestWorkload'
#          'mtu'        => {
#               description    => "Configure QoS Guard",
#               type           => "action",
#               preprocess     => "PreProcessShiftTypeAPI",
#               method         => "SetMTU",
#               params         => ["mtu"],
#               format         => "<integer>",
#            },
#           TestWorkload => {
#              Type       => "Switch",
#              TestSwitch => "vc.[1].vds.[1]",
#              MTU        => "1500",
#           }
#
#            The input to this api will look like:
#            testobject - Object representing vc.[1].vds.[1]
#            keyName    - mtu
#            keyValue   - 1500
#            paramValue - { mtu => "1500" }
#            paramList  - mtu
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessShiftTypeAPI
{
   my $self              = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array ;
   #
   # Push all params from paramList whether it is defined or not.
   # Because, removing a param if not defined would re-order/corrupt
   # the way API is expecting the input
   #
   foreach my $parameter (@$paramList) {
      push(@array, $paramValues->{$parameter});
   }
   $vdLogger->Debug("After preprocessing the params is ".Dumper(\@array));
   return \@array;

}


########################################################################
#
#  PreProcessHashTypeAPI --
#       This method pushes runtime parameters into a hash and returns the
#       reference to hash. This API is used when the argument to method are
#       in key-value pair format and not in array format.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
#       For e.g. For Following key 'mtu' and workload 'TestWorkload'
#          'mtu'        => {
#               description    => "Configure QoS Guard",
#               type           => "action",
#               preprocess     => "PreProcessShiftTypeAPI",
#               method         => "SetMTU",
#               params         => ["mtu"],
#               format         => "<integer>",
#            },
#           TestWorkload => {
#              Type       => "Switch",
#              TestSwitch => "vc.[1].vds.[1]",
#              MTU        => "1500",
#           }
#
#            The input to this api will look like:
#            testobject - Object representing vc.[1].vds.[1]
#            keyName    - mtu
#            keyValue   - 1500
#            paramValue - { mtu => "1500" }
#            paramList  - mtu
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessHashTypeAPI
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array;
   push(@array, %$paramValues);
   return \@array;
}


########################################################################
#
#  PreProcessHashRefTypeAPI --
#       This method pushes runtime parameters into a hash "reference
#       and returns it. This API is used when the argument to method are
#       in key-value pair format and not in array format.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue - Reference to hash where keys are the contents of
#                    'params' and values are the values that are assigned
#                    to these keys in config hash.
#       paramList  - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessHashRefTypeAPI
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $temp;
   %$temp = %$paramValues;
   foreach my $key (keys %$temp) {
      if (not defined $temp->{$key}) {
         delete $temp->{$key};
      }
   }
   my @array;

   push(@array, $temp);
   return \@array;
}

########################################################################
#
#  PreProcessReconfigure --
#       This method pushes runtime parameters into a hash "reference
#       and returns it. This API is used when the argument to method are
#       in key-value pair format and not in array format.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue - Reference to hash where keys are the contents of
#                    'params' and values are the values that are assigned
#                    to these keys in config hash.
#       paramList  - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessReconfigure
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $temp;
   my @array;
   my $keysDatabase = $self->{keysdatabase};

   %$temp = %$paramValues;
   foreach my $key (keys %$temp) {
      if (not defined $temp->{$key}) {
         delete $temp->{$key};
      }
   }
   # Process all Parameters type
   foreach my $index (keys %{$temp}) {
      my $method;
      if ($index eq "reconfigure") {
         $method = "PreProcessNestedParameters";
      } elsif ((defined $keysDatabase->{$index}{type}) &&
               ($keysDatabase->{$index}{type} ne "parameter")) {
         next;  # Skip non parameter type keys
      } elsif (defined $keysDatabase->{$index}{method}) {
         $method = $keysDatabase->{$index}{method};
      } else {
         next;  # No need to call any methods when method is not defined
      }
      $vdLogger->Debug("Calling method: $method for $index");
      my $result = $self->$method($temp->{$index}, $testObject, $index);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set Parameter of $index using $method");
         VDSetLastError("EKEYSDBMETHODFAILED");
         return FAILURE;
      }
      $vdLogger->Debug("Calling method $method for $index, returned: " .
                       Dumper($result));
      $temp->{$index} = $result;
   }
   push(@array, $temp);
   return \@array;
}


########################################################################
#
#  GetSwitchNameFromReference --
#       This method is used to return Switch Names
#
# Input:
#       $configHash - a hash containing the config that needs to be run
#
# Results:
#    SUCCESS - returns the name of the switch
#    FAILURE - incase of any failure
#
# Side effetcs:
#       None
#
########################################################################

sub GetSwitchNameFromReference
{
   my $self = shift;
   my $testswitch = shift;
   my $result= $self->GetSwitchNames($testswitch);
   return $result->[0];
}


########################################################################
#
# StartWorkload --
#      This method can be accessed by any of the concrete classes
#      will process the workload hash of type based on the object for
#      which the workload has been instantiated. This api gets object
#      from the test<type> and calls ProcessTuple().
#
# Input:
#      None
#
# Results:
#     PASS, if workload is executed successfully,
#     FAIL, in case of any error;
#
# Side effects:
#     Depends on the VM workload being executed
#
########################################################################

sub StartWorkload
{
   my $self     = shift;
   my $workload = $self->{workload};
   my $testbed  = $self->{testbed};

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);

   # Number of Iterations to run the test for
   my $iterations = $dupWorkload->{'iterations'};
   if (not defined $iterations) {
      $iterations = 1;
   }

   # Get the management keys and targetkey from internal data structure
   my $managementKeys = $self->{'managementkeys'};
   my $targetKey = $self->{'targetkey'};
   my $testKeys = $dupWorkload->{$targetKey};
   my $sleepBetweenWorkloads = $dupWorkload->{'sleepbetweenworkloads'};
   if (defined $sleepBetweenWorkloads) {
      $vdLogger->Info("Sleep between workloads of value " .
                      "$sleepBetweenWorkloads is given. Sleeping ...");
      sleep($sleepBetweenWorkloads);
   }

   my $verificationStyle;
   if ((exists $dupWorkload->{'verificationstyle'}) &&
      (defined $dupWorkload->{'verificationstyle'})) {
      $verificationStyle = $dupWorkload->{'verificationstyle'};
      delete $dupWorkload->{'verificationstyle'};
   } else {
      $verificationStyle = "default";
   }


   my $persistData;
   if ((exists $dupWorkload->{'persistdata'}) &&
      (defined $dupWorkload->{'persistdata'}) &&
      ($dupWorkload->{'persistdata'} =~ /yes/i)) {
      $persistData = "yes";
      delete $dupWorkload->{'persistdata'};
   } else {
      $persistData = "no";
   }

   #
   # In the workload hash, not all the keys represent the network configuration
   # to be made on the given device. There are keys that control how to run
   # the workload. These keys can be referred as management keys. The
   # management keys are removed from the duplicate hash

   foreach my $key (@$managementKeys) {
     delete $dupWorkload->{$key};
   }
   $vdLogger->Info("Number of Workload Iterations to run: $iterations");
   for (my $i=1; $i<=$iterations; $i++) {
      $vdLogger->Info("Running Iteration: $i");
      if (not defined $testKeys) {
         $vdLogger->Error("Missing Mgmt key Test<blah> in workload definition, " .
                          "like TestHost for Type: Host workload");
         VDSetLastError("EINVALID");
         return FAIL;
      }
      my @arrayOfTestKeys = split(COMPONENT_DELIMITER, $testKeys);
      my @newArray = ();
      foreach my $index (@arrayOfTestKeys) {
         # Getting value from persist data
         if ($index  =~ PERSIST_DATA_REGEX) {
            my $hash_ref = {};
            $hash_ref->{'testkey'} = $index;
            my $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                                       $hash_ref->{testkey},
                                                                       'testkey');
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to resolve component $index " .
                                "from persist data");
               VDSetLastError("EOPFAILED");
               return FAIL;
            } else {
               $index = $result;
               $vdLogger->Info("Resolved vdnet index from persist data $index");
            }
         }

         my $refArray = $self->{testbed}->GetAllComponentTuples($index);
         if ($refArray eq FAILURE) {
            $vdLogger->Error("Failed to get all indexes for $index");
            VDSetLastError(VDGetLastError());
            return FAIL;
         }
         push @newArray, @$refArray;
      }

      # We have two code paths here.
      # VDNET_WORKLOAD_THREADS is the switch to take the 2) code path
      # 1) ForkManager which launches a new process for each workload
      # This does not support launching parallel processes for testComponent
      # inside a workload
      # 2) Threads, which launch threads for each workload. We also
      # support launching threads for each testComponent inside a workload
      #
      if ($ENV{VDNET_WORKLOAD_THREADS}) {
         my $clonedWorkload = dclone $dupWorkload;
         my $functionRef = sub {$self->ProcessTestKeys(@_)};
         my $timeout = VDNetLib::TestData::TestConstants::MAX_TIMEOUT;
         my $result = $self->RunWorkloadsUsingThreads($functionRef,
                                                      \@newArray,
                                                      $timeout,
                                                      $clonedWorkload,
                                                      $verificationStyle,
                                                      $persistData);
         if ($result eq FAILURE) {
            $vdLogger->Error("RunWorkloadsUsingThreads failed with " . $result);
            VDSetLastError(VDGetLastError());
            return FAIL;
         }
      } else {
         foreach my $testKey (@newArray) {
            $testKey =~ s/^\s+//;
            $self->SetComponentIndex($testKey);
            # Because ProcessTestKeys() deletes keys from the workload hash
            # during processing we need to send a cloned copy of workload for
            # each iteration so that behavior is consistent
            my $clonedWorkload = dclone $dupWorkload;
            my $result = $self->ProcessTestKeys($clonedWorkload,
                                                $testKey,
                                                $verificationStyle,
                                                $persistData);
            if ($result eq FAILURE) {
               $vdLogger->Error("ProcessTestKeys failed");
               VDSetLastError(VDGetLastError());
               return FAIL;
            }
         }
      }
   } # end of iteration loop
   return PASS;
}


########################################################################
#
# ProcessTestKeys --
#      This method will process the workload hash  of all types of workload
#      and execute necessary operations.
#
# Input:
#      dupWorkload       : Reference to test keys Hash
#      testkey           : VMOperations object of the SUT/helper VM
#      verificationStyle : Style of verification like diff. Default value
#                          is 'default'
#
# Results:
#      "SUCCESS", if all the network configurations are successful,
#      FAILURE, in case of any error.
#
# Side effects:
#     Would runs only for workloads except for the ones added
#     in VDNet ver-1.
#
########################################################################

sub ProcessTestKeys
{
   my $self              = shift;
   my $dupWorkload       = shift;
   my $testKey           = shift;
   my $verificationStyle = shift;
   my $persistData       = shift;

   my $workload    = $self->{workload};
   my $testbed     = $self->{testbed};

   my $ref =  $self->{testbed}->GetComponentObject($testKey);
   if ($ref eq FAILURE) {
      $vdLogger->Error("Not able to find object for tuple : $testKey");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $testObject = $ref->[0];

   my $runworkload;
   if (defined $dupWorkload->{'runworkload'}) {
      $runworkload = $dupWorkload->{'runworkload'};
      delete $dupWorkload->{'runworkload'};
   }

   my $verification;
   if (defined $dupWorkload->{'verification'}) {
      $verification = $dupWorkload->{'verification'};
      delete $dupWorkload->{'verification'};
   }

   my $skipPostProcess = 0;
   if (defined $dupWorkload->{'skippostprocess'}) {
      $skipPostProcess = $dupWorkload->{'skippostprocess'};
      delete $dupWorkload->{'skippostprocess'};
   }
   my $skipMethod = 0;
   if (defined $dupWorkload->{'skipmethod'}) {
      $skipMethod = $dupWorkload->{'skipmethod'};
      delete $dupWorkload->{'skipmethod'};
   }
   my $noofretries = 1;
   if (defined $dupWorkload->{'noofretries'}) {
      $noofretries = $dupWorkload->{'noofretries'};
      delete $dupWorkload->{'noofretries'};
      $vdLogger->Info("Number of retries value $noofretries is given.");
   }
   my $sleepbetweenretry = undef;
   if (defined $dupWorkload->{'sleepbetweenretry'}) {
      $sleepbetweenretry = $dupWorkload->{'sleepbetweenretry'};
      delete $dupWorkload->{'sleepbetweenretry'};
      $vdLogger->Info("Sleep time between each retry is $sleepbetweenretry seconds.");
   }

   #
   # Create an iterator object and find all possible combination of workloads
   # to be run. The iterator module takes care ofidentifying these different
   # data types and generates combination if more than one VM Operation is
   # provided.
   #

   my $constrantDataBase;
   if (keys %$dupWorkload == 1) {
      my $key = (keys %$dupWorkload)[0];

      # Get the current working directory to
      # fetch the values from yaml file
      my $cwd = $Bin . '/../VDNetLib/TestData/APITestValues/';
      my $valuesFile = $cwd .  $key . 'Values.' . 'yaml';

      #Check if yaml file exist
      if (-e $valuesFile) {
         # Convert yaml to perl hash
         $constrantDataBase = VDNetLib::Common::Utilities::ConvertYAMLToHash($valuesFile);
      }
      else{
         #if yaml file does not exist return error
         $vdLogger->Warn("Unable to find values file for: $key");
      }
   }

   my $finalResult = SUCCESS;

   my $iteratorObj =
          VDNetLib::Common::Iterator->new(workloadHash   => $dupWorkload,
                                          constraintHash => $constrantDataBase);

   my $configCount = 1;
   # NextCombination() method gives the first combination of keys

   my %testOps = $iteratorObj->NextCombination();
   my $testOpsHash = \%testOps;

   while (my ($key, $value) = each (%testOps)) {
      $vdLogger->Info("Working on configuration set $configCount for $testKey" .
                       Dumper($testOpsHash));
      my $sleepBetweenCombos = $dupWorkload->{'sleepbetweencombos'};
      if (defined $sleepBetweenCombos) {
         $vdLogger->Info("Sleep between combination of value " .
               "$sleepBetweenCombos is given. Sleeping ...");
         sleep($sleepBetweenCombos);
      }
      my $retryCount = 0;
      my $result = FAILURE;
      while ($retryCount < $noofretries) {
         my $sleepBetweenWorkloads = $dupWorkload->{'sleepbetweenworkloads'};
         if (defined $sleepBetweenWorkloads) {
             $vdLogger->Info("Sleep between workloads of value " .
                         "$sleepBetweenWorkloads is given. Sleeping ...");
             sleep($sleepBetweenWorkloads);
         }
         $result = $self->ConfigureComponent(configHash        => $testOpsHash,
                                             testObject        => $testObject,
                                             tuple             => $testKey,
                                             skipPostProcess   => $skipPostProcess,
                                             skipMethod        => $skipMethod,
                                             verificationStyle => $verificationStyle,
                                             persistData       => $persistData);
         $retryCount++;
         if ((defined $result) && ($result eq SUCCESS)) {
            $vdLogger->Info("Configuration set $configCount PASSED for $testKey " .
                            "with retry $retryCount times");
            last;
         }
         $vdLogger->Info("Configuration set $configCount FAILED for $testKey " .
                         "with retry $retryCount times");
         # Below condition aims to save $sleepbetweenretry seconds by
         # not sleeping when $retryCount == $noofretries
         if (defined $sleepbetweenretry) {
            $vdLogger->Info("Now sleep $sleepbetweenretry seconds before next retry.");
            sleep($sleepbetweenretry);
         }
      }

      if ((not defined $result) || ($result eq FAILURE)) {
         $vdLogger->Info("No of retries reached $noofretries, failed to configure $testKey");
         VDSetLastError(VDGetLastError());
         # If this combination is generated from
         # magic hash then we want all the combinations
         # to be executed, thereby ignoring the failure
         $finalResult = FAILURE;
         if (not defined $constrantDataBase) {
            return FAILURE;
         }
      } else {
         $vdLogger->Debug("Configuration set $configCount PASSED for $testKey");
      }

      # Run workload for verification if runworkload in dupWorkload;
      if (defined $runworkload) {
         $vdLogger->Info("Processing runworkload hash for workload" .
                          "verification.");
         if ($self->RunChildWorkload($runworkload) eq FAILURE) {
            $vdLogger->Error("Failed to execute runworkload for verification: " .
                             Dumper($runworkload));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      #
      # Consecutive NextCombination() calls iterates through the list of all
      # available combination of hashes
      #

      %testOps = $iteratorObj->NextCombination();
      $configCount++;
   }
   if ($finalResult eq FAILURE) {
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RunChildWorkload --
#      This method will process the runworkload hash for verification
#      purpose.
# Input:
#      childWorkload : verification workload hash is mandatory
#
# Results:
#      "SUCCESS", if verification workload get successfully executed,
#      FAILURE, in case of any error.
#
# Side effects:
#
########################################################################

sub RunChildWorkload
{
   my $self        = shift;
   my $childWorkload = shift;

   if (not defined $childWorkload->{'Type'}) {
      $vdLogger->Error("Unable to find workload type in give workload hash: " .
                        Dumper($childWorkload));
      VDSetLastError(" EOPFAILED");
      return FAILURE;
   }

   my $workloadType = "VDNetLib::Workloads::" . $childWorkload->{'Type'} .
                      "Workload";
   eval "require $workloadType";
   if ($@) {
      $vdLogger->Error("unable to load module $workloadType: $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $workloadObj = $workloadType->new(workload => $childWorkload,
                                        testbed  => $self->{'testbed'});
   if ($workloadObj eq FAILURE) {
	   $vdLogger->Error("Failed to create $workloadType object");
	   $vdLogger->Debug(VDGetLastError());
	   return FAILURE;
   }

   my $childResult =  $workloadObj->StartWorkload();

   if (not defined $childWorkload->{expectedresult}) {
      $childWorkload->{expectedresult} = PASS;
   }

   # The TrafficWorkload::StartWorkload returns final result of the workload, so
   # TrafficWorkload::CompareWorkloadResult doesn't compare the expectedresult
   # with actualresult. However, other workloads will compare the expectedresult
   # with actualresult in ParentWorkload::CompareWorkloadResult, so that get the
   # final result of that workload.
   # We also need to use the same above logic here, or there maybe potential bug
   # when using runworkload key to run traffic workload.
   # Below code snippet just porting the code in TrafficWorkload::CompareWorkloadResult
   # and ParentWorkload::CompareWorkloadResult to distinguish the comparison logics
   # between traffic workload and other workloads.
   $vdLogger->Info('Handling childworkload ' . $childWorkload->{'Type'} . 'Workload');
   if ($childResult =~ /skip/i) {
      return "SKIP";
   }
   # Handle traffic workload
   if ($childWorkload->{'Type'} =~ /Traffic/i) {
      if ($childWorkload->{expectedresult} =~ /ignore/i) {
         $vdLogger->Info("Result:$childResult of childworkload " .
         "IGNORED since the expected result is : " . $childWorkload->{expectedResult});
         return SUCCESS;
      } else {
         $vdLogger->Info("Result:$childResult of childworkload");
         return $childResult =~ /fail/i ? FAILURE : SUCCESS;
      }
   # Handle other workloads
   } else {
      if ($childWorkload->{expectedresult} =~ /$childResult/i) {
         $vdLogger->Info("Result:$childResult of childworkload " .
            "matches the expected result: " .
            $childWorkload->{expectedresult});
         return SUCCESS;
      } elsif ($childWorkload->{expectedresult} =~ /ignore/i) {
         $vdLogger->Info("Result:$childResult of childworkload " .
         "IGNORED since the expected result is : " . $childWorkload->{expectedResult});
         return SUCCESS;
      }else {
         $vdLogger->Error("---> Result:$childResult of childworkload " .
            "NOT matching the expected result: " .
            $childWorkload->{expectedresult} .
            " <---");
         $vdLogger->Error("Failed to run workload with hash: " .
            Dumper($childWorkload));
         $vdLogger->Debug(VDGetLastError());
         return FAILURE;
      }
   }
}

###############################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of HostWorkload,
#      if needed. This method should be defined as it is a required
#      interface for VDNetLib::Workloads.
#
# Input:
#     None
#
# Results:
#     To be added
#
# Side effects:
#     None
#
###############################################################################

sub CleanUpWorkload {
   my $self = shift;
   # TODO - there is no cleanup required as of now. Implement any
   # cleanup operation here if required in future.
   return PASS;
}


########################################################################
#
#  GetArrayOfObjects --
#       This method returns a reference to array of objects
#
# Input:
#     arrayOfTuples - reference to array of tuples.
#
# Results:
#      SUCCESS - returns reference to array of Objects.
#      FAILURE - when ref is undifined
#
# Side effetcs:
#       None
#
########################################################################

sub GetArrayOfObjects
{
   my $self = shift;
   my $arrayOfTuples = shift;
   my @refToArrayOfObjects;

   foreach my $tuple (@$arrayOfTuples) {
      my $ref = $self->{testbed}->GetComponentObject($tuple);
      if ((not defined $ref) || (defined $ref && $ref =~ /FAILURE/i)) {
         $vdLogger->Error("GetComponentObject returned $ref for tuple $tuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push (@refToArrayOfObjects, $ref->[0]);
   }
   return \@refToArrayOfObjects;
}


########################################################################
#
# HandleActionKeys --
#     Method to handle "action"  type keys and their dependencies
#
# Input:
#     testObj   : reference to test object
#     configHash: reference to the configuration hash from testspec
#     index     : key (action type) name that needs to be processed
#
# Results:
#     SUCCESS, if the keys are processed without errors;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub HandleActionKeys
{
   my $self       = shift;
   my $testObj    = shift;
   my $configHash = shift;
   my $index      = shift;
   my $skipPostProcess = shift;
   my $skipMethod      = shift || 0;

   # Executing pre process of action key
   my $keysDatabase = $self->{keysdatabase};
   my $method;

   #
   # check if dependency exists
   # if does then process that first and delete from the configHash
   # This is a recursive call
   #

   my $dependencyKey = $keysDatabase->{$index}{dependency};
   if (defined $dependencyKey) {
      # Handling multiple dependency keys
      my @dependencyKeyArray = @{$keysDatabase->{$index}{dependency}};
      foreach my $key (@dependencyKeyArray) {
         if (defined $configHash->{$key}) {
            $vdLogger->Debug("Processing dependency key $key:" .
                            "Dumper($configHash->{$key})");
            my $result = $self->HandleActionKeys($testObj, $configHash,
                                                 $key);
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to process dependency key " .
                                "$key");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
         }
      }
   }
   if (not defined $keysDatabase->{$index}{preprocess}) {
      $vdLogger->Error("No preprocess method defined for action key $index");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $method = $keysDatabase->{$index}{preprocess};
   $self->{runtime}{order} = $keysDatabase->{$index}{params};
   $self->{runtime}{action} = $configHash->{$index};
   $self->{runtime}{parameters}{$index} = $configHash->{$index};
   my $params = $keysDatabase->{$index}{params};
   my $refToHash;
   foreach my $item (@{$keysDatabase->{$index}{'params'}}) {
      if (exists $self->{runtime}{parameters}{$item}) {
         $refToHash->{$item} = $self->{runtime}{parameters}{$item};
      }
   }

   $vdLogger->Debug("Calling method $method as part of HandleActionKeys");

   my $result = $self->$method($testObj,
                               $index,
                               $configHash->{$index},
                               $refToHash,
                               $params);
   if ($result eq SKIP) {
      return SKIP;
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Pre-process API $method returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{runtime}{arguments} = $result;

   $method = undef;
   $method = $keysDatabase->{$index}{method};
   if ($skipMethod == 0) {
      # Executing method of action key
      if (not defined $method) {
         $vdLogger->Error("Method is not defined for the action key: " .
                          Dumper($index));
         return FAILURE;
      }
      $vdLogger->Debug("Running method $method for action key $index");
      my $args = $self->{runtime}{arguments};
      if (ref($args) ne "ARRAY") {
         $vdLogger->Error("HandlActionKey expects arguments to be in the form " .
                          "of array, got:" . Dumper($args));
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $result = $testObj->$method(@$args);
      if (not defined $result) {
         $vdLogger->Warn("Action method $method returns None for success, fix it");
         $result = SUCCESS;
      }
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to configure $index");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{runtime}{result} = $result;
   } else {
      if (not defined $method) {
         $method = "";
      }
      $vdLogger->Debug("Skipping method $method for action key $index");
      $self->{runtime}{result} = SUCCESS;
   }

   # Executing post process of action key
   if ((defined $keysDatabase->{$index}{postprocess}) && (!$skipPostProcess)) {
      my $method = $keysDatabase->{$index}{postprocess};
      $vdLogger->Debug("Running postprocess $method for action key $index");
      my $result = $self->$method($testObj,
                                  $index,
                                  $configHash->{$index},
                                  $refToHash,
                                  $self->{runtime}{result});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($result =~ /^\d+$/) {
         $vdLogger->Info("Return code: $result " .
                         "returning the result instead of SUCCESS");
         return $result;
      }
   } else {
      $vdLogger->Debug("Skipping postprocess $method for action key $index");
   }
   $vdLogger->Debug("Deleting $index from config hash");
   delete $self->{runtime}{parameters}{$index};
   delete $configHash->{$index};
   return SUCCESS;
}


########################################################################
#
# PreProcessVerification --
#       This method pushes runtime parameters into an array in proper order
#       and returns the reference to array.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessVerification
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      #
      # If $parameter equal to $keyName, that means
      # the value is a spec which needs special treatment.
      # In below case if the spec has tuples whose objects
      # have attribute mapping, then the following method
      # should work. Else the user has to implement their
      # own method to process this spec.
      #
      # For Example, if the verification key 'checkifexists'
      # (key is present in TestComponentWorkload) is part
      # of @$paramList, then the value held by this key
      # "checkifexists" is a spec that will be used to obtain
      # user data. In order to get the userdata using
      # ProcessUserDataForVerification() from this key,
      # we need to do the following check so that above method
      # is invoked.
      #
      if ($parameter eq $keyName) {
         $userData =
          VDNetLib::Workloads::Utilities::ProcessUserDataForVerification(
                                                                     $self,
                                                                     $keyValue,
                                                                     "values");
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}


########################################################################
#
# PreProcessVerificationAndParameters --
#       This method pushes runtime parameters into an array in proper order
#       and returns the reference to array.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessVerificationAndParameters
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @arguments;
   my $userData =
      VDNetLib::Workloads::Utilities::ProcessUserDataForVerification($self,
                                                                  $keyValue,
                                                                  "values");
  push(@arguments, $userData);

   # $paramValues->{$keyName} contains component specs
   # We also want to send all other parameters
   # than the $paramValues->{$keyName}
   # So delete element from $additionalParams having $keyName
   # And return those $additionalParams also
   my $additionalParams = $paramValues;
   if (defined $additionalParams->{$keyName}) {
      delete $additionalParams->{$keyName};
   }
   push (@arguments, $additionalParams);

   return \@arguments;
}


########################################################################
#
# PreProcessActionKey --
#       This method pushes runtime parameters into an array in proper order
#       and returns the reference to array.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessActionKey
{
   my $self   = shift;
   my @array;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   if (defined $keyValue) {
      if ($keyValue =~ /\./) {
         my $ref = $self->{testbed}->GetComponentObject($keyValue);
         if ($ref eq "FAILURE") {
            $vdLogger->Error("Invalid ref $ref for tuple $keyValue");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         push(@array, $ref);
      } else {
         push(@array, $keyValue);
      }
   } else {
      return FAILURE;
   }

   foreach my $parameter (@$paramList) {
      push(@array, $paramValue->{$parameter});
   }

   return \@array;
}

########################################################################
#
# PreProcessVerificationTemplate --
#       !!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!!!!!!!!
#       Please dont call this method. It is just a template
#       on how to write PreProcess methods for verification keys
#
#       While writing their own PreProcess method for verification key,
#       a developer needs to write new code for getting userData
#       from keyValue. On how to do this is explained below.
#       Please remeber that the method is pretty much the same
#       except for Process $keyValue.
#
#       NOTE: If your classes already have attribute mapping,
#       then there is no need to create your own PreProcess method
#       for the verification key. You can simply use
#       PreProcessVerification()
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessVerificationTemplate
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      if ($parameter eq $keyName) {
          #
          # -----------------
          # Process $keyValue
          # -----------------
          # If your class has already implemented attribute
          # mapping, then in that case just reuse the method
          # PreProcessVerification() as preprocess.
          #
          # If your class doesn't have attribute mapping
          # then you need to manually make the changes in
          # your customized Preprocess method where only
          # Step3 will change and rest of the steps will
          # remain as is. The changes needs to be done to
          # only $keyValue

          # At this point of time $keyValue looks like below
          # The output is captured by Dumping $keyValue
          # in PreProcessVerification() while running the
          # Internal.VDNet.Infrastructure.VerificationUnitTest
          #  [{
          #   'abc' =>
          #    [{
          #     'array' =>
          #      [
          #         {
          #           'cdf' =>
          #              {
          #                 'zone' => 'testinventory.[1].testcomponent.[1]'
          #              }
          #         }
          #       ],
          #     'password' => 'testinventory.[1].testcomponent.[1]',
          #     'name' => 'test2',
          #     'ipaddress' => 'self',
          #     'schema' => '12345',
          #     'username' => 'testinventory.[1].testcomponent.[1]'
          #    }]
          #  }];
          #
          #
          # The developer has to write code which creates a new
          # spec called $userData. Using $keyValue, the new code
          # should replace tuples with some values. The tuples can
          # be obtained by using methods like GetOneObjectFromOneTuple().
          # Once you have the object, you can either access a class
          # variable or call a method to construct the value.
          #  [{
          #   'abc' =>
          #    [{
          #     'array' =>
          #      [
          #         {
          #           'cdf' => {
          #                      'zone' => '6.0'
          #                    }
          #         }
          #       ],
          #     'password' => 'default',
          #     'name' => 'test2',
          #     'ipaddress' => '10.10.10.10',
          #     'schema' => '12345',
          #     'username' => 'admin'
          #    }]
          #  }];
          #
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}


########################################################################
#
# HandleVerificationKeys --
#     Method to handle "verification" type keys.
#
#     New Words in VDNet Verification Infrastructure:
#     Introducing new terms used in VDNet Verification Infrastructure.
#     Any concern/discussion/bug shall involve heavy usage of these words.
#     Please familiarize yourself with them and go through the below
#     documentation for understanding the usage of these terms and where
#     and how they are used.
#
#        serverData     - data received from server which is understandable
#                         by the infrastructure code
#        userData       - data received from the user or Testcase spec which
#                         is understandable by the infrastructure code
#        compare        - an operation to compare serverData and userData
#        delimiter      - a symbol [?] used between condition and conditionValue
#        condition      - expression to be used in compare operation.
#                         e.g. 'equal_to' or 'exists'. Anything on the left hand
#                         side of [?] delimiter is a condition.
#        conditionValue - Anything on the right hand side of [?]. e.g.
#                         a string or tuples.
#        serverform     - an empty server form that will be pushed to core
#                         api. The core api is going to fill out the form
#                         and send it back to HandleVerificationKeys().
#
#
#     What:
#     Verification is based on a very simple principal:
#        Get data from server(serverData) using some kind of get()
#        and compare the server data with data the
#        user expects it to be (userData).
#
#     Why:
#     1. Common Compare Operations
#     We dont want VDNet developers to write their own
#     verification. Verification of complex data involves
#     comparison of them using recursion. A lot of common
#     code can be placed infrastructure layer there by saving
#     development time.
#
#     2. Prepare Server Data
#     The data received form the server get() may not be understood
#     by the infrastructure layer if proper abstractions are not present.
#     A good example is attribute mapping. This hash is there because
#     python libraries didnt abstract server keys properly to test cases.
#     To avoid this, the verification infrastructure provides an empty form
#     known as the 'serverform' to core apis which make server calls.
#     The core api fills out the empty 'serverform' from data received
#     from read calls on server. After filling out the 'serverform', the
#     core api sends back the completed form to the verification
#     infrastructure for comparision with user data.
#
#     3. Prepare User Data
#     It is also tricky to prepare the user data, so in our current
#     verification infrastructure, we either take help of attribute
#     mapping or we give the entire control to the developer to prepare
#     user data. It is mandatory to prepare user data at workload layer
#     in the pre process method.
#
#     VDNet already does #3 and #2 (of Why part). Using 'preprocess'
#     method for action keys in KeysDatabase, userdata/expectations
#     are resolved. Using the 'method', the data is sent to servers
#     where this data is used to set configuartions.
#
#     How:
#     We execute a series of steps to accomplish verification.
#     A high Level summary of steps is provided below and
#     further explanation is mentioned inside the code.
#
#     Step 1 --------------------> Process Parameters (already done)
#     Step 2 \
#     Step 3   \
#     Step 4     ----------------> Prepare user data - Step 2-7
#     Step 5   /
#     Step 6 /
#     Step 7 --------------------> Get server data using core api
#     Step 8 --------------------> Compare user data and server data
#
#     Please go through the following steps in code as well as their
#     explanations are presented in more detailed manner.
#
# Input:
#     testObj          : reference to test object
#     verificationHash : reference to the configuration hash from testspec
#     verificationKey  : key (action type) name that needs to be processed
#     skipPostProcess  : [optional] key to skip post process if set to 1.
#     globalCondition  : [optional] used only when the user wants to verify
#                        if the input complex structure is part of an array
#                        of spec.
#     verificationStyle: Style of verification like diff. Default value
#                        is 'default'
# Results:
#     SUCCESS, if the keys are processed without errors;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub HandleVerificationKeys
{
   my $self              = shift;
   my $testObj           = shift;
   my $verificationHash  = shift;
   my $verificationKey   = shift;
   my $skipPostProcess   = shift;
   my $globalCondition   = shift;
   my $verificationStyle = shift || "default";
   my $persistData       = shift || "no";

   #
   # Step 1: Process Parameters
   # Explanation: By This time Step 1 is
   # already done and all the necessary
   # paramteres are already processed. Just
   # thought it would be helpful to let
   # the reader be aware of this.
   #

   #
   # Step 2: Empty Form
   # Explanation: Genrate nested hash with just
   # keys and no values. In this step we create
   # an empty verification form that will be
   # later sent to the core api.
   #

   # Expecting the dclone's value $verificationHash->{$verificationKey}
   # to be a hash.
   my $copyOfSpec = dclone $verificationHash->{$verificationKey};
   my $emptyForm =
   VDNetLib::Workloads::Utilities::ProcessUserDataForVerification($self,
                                                                  $copyOfSpec,
                                                                  "empty");
   if ($emptyForm eq FAILURE) {
      $vdLogger->Error("Failed to generate empty hash");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Trace("Step 2 completed, the empty form is " . Dumper($emptyForm));

   #
   # Step 3: Condition Hash
   # Explanation: Generate nested hash with just conditions.
   # This hash will be later used to merge with the
   # output of the Step 6 i.e. $userData. $conditionHash
   # will have keys which will have values as "equal_to".
   # The delimiter [?] and the right hand side of delimiter
   # is not present as a value in this hash.
   #
   $copyOfSpec = dclone $verificationHash->{$verificationKey};
   my $conditionHash =
   VDNetLib::Workloads::Utilities::ProcessUserDataForVerification($self,
                                                                  $copyOfSpec,
                                                                  "condition");
   if ($conditionHash eq FAILURE) {
      $vdLogger->Error("Failed to generate condition hash");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Step 3 completed, the condition hash is " .
                    Dumper($conditionHash));

   #
   # Step 4: Tuple Hash
   # Explanation: Genrate nested hash with just tuples.
   # This hash will be be fed to preprocess method of
   # verification key, such as PreProcessverification()
   # $expectedData will have keys which will have values
   # equal to either tuples or string. The delimiter [?]
   # and the left hand side of delimiter is not present
   # as a value in this hash.
   #
   $copyOfSpec = dclone $verificationHash->{$verificationKey};
   my $expectedData =
   VDNetLib::Workloads::Utilities::ProcessUserDataForVerification($self,
                                                                  $copyOfSpec,
                                                                  "tuple");
   if ($expectedData eq FAILURE) {
      $vdLogger->Error("Failed to process user data for verification");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Step 4 completed, the expected data hash is " .
                    Dumper($expectedData));

   #
   # Step 5: Process Paramteres of verification
   # Explanation: While executing the preprocess
   # $method of verification key, we dont send
   # $configHash->{$index} in arguments. Instead
   # we send $expectedData (the output from above
   # step). That the preprocess method doens't
   # have to worry about splitting based on [?]
   # delimiter and removing the conditions on left
   # hand side of [?] like equal_to, etc.
   #
   my $keysDatabase = $self->{keysdatabase};
   my $method;

   $method = $keysDatabase->{$verificationKey}{preprocess};
   $self->{runtime}{order} = $keysDatabase->{$verificationKey}{params};
   $self->{runtime}{verification} = $verificationHash->{$verificationKey};
   $self->{runtime}{parameters}{$verificationKey} = $verificationHash->{$verificationKey};
   my $params = $keysDatabase->{$verificationKey}{params};
   my $refToHash;
   foreach my $item (@{$keysDatabase->{$verificationKey}{'params'}}) {
      $refToHash->{$item} = $self->{runtime}{parameters}{$item};
   }

   # Executing pre process of verification key
   my $result = $self->$method($testObj,
                               $verificationKey,
                               $expectedData,
                               $refToHash,
                               $params);

   if ($result eq FAILURE) {
      $vdLogger->Error("Pre-process API $method returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @paramList = @{$self->{runtime}{order}};
   my $count = first {$paramList[$_] eq $verificationKey} 0..$#paramList;
   my $processedUserData = $result->[$count];
   $result->[$count] = $emptyForm;
   $self->{runtime}{arguments} = $result;
   $vdLogger->Debug("Step 5 completed, processed user data is " .
                    Dumper($processedUserData));

   #
   # Step 6: Create User Data
   # In this step we merge $userData from Step5
   # with $conditionHash which we got from Step3.
   # When we merge this data, we can use this new
   # datastructure to be feed to Compare operation
   # along wiht the server data.
   #
   my $userData =
   VDNetLib::Workloads::Utilities::ProcessUserDataForVerification(
                                                             $self,
                                                             $processedUserData,
                                                             "merge",
                                                             $conditionHash);
   if ($userData eq FAILURE) {
      $vdLogger->Error("Failed to process user data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Step 6 completed, the expected data hash is " .
                    Dumper($userData));

   #
   # Step 7: Get Server Data from core api
   #
   $method = undef;
   $method = $keysDatabase->{$verificationKey}{method};
   if (not defined $method) {
      $vdLogger->Error("Method for verification key $verificationKey is " .
                       "not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("Running method $method for verification " .
                    "key $verificationKey");
   my $args = $self->{runtime}{arguments};
   # TODO(Prabuddh): Remove this hack and update HandleVerificationKey instead.
   my %dupdict = %{$self->{runtime}{parameters}};
   my $dict = \%dupdict;
   if (defined $dict->{'sleepbetweenworkloads'}) {
      delete $dict->{'sleepbetweenworkloads'};
   }

   $result = $testObj->$method(@$args, $dict);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to run method $method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{runtime}{result} = $result;
   if ((exists $result->{status}) &&
       ($result->{status} eq FAILURE)) {
      $vdLogger->Info("Server call failed for $verificationKey" .
                      Dumper($result));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Executing post process of verification key
   if ((defined $keysDatabase->{$verificationKey}{postprocess}) && (!$skipPostProcess)) {
      $method = $keysDatabase->{$verificationKey}{postprocess};
      $vdLogger->Debug("Running postprocess $method for verification key");
      my $result = $self->$method($self->{runtime}{result});
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to call postprocess for $verificationKey");
         VDSetLastError("EPOSTPROCESS");
         return FAILURE;
      }
   }

   my $serverData;
   if (defined $result->{response}) {
      # result coming from Python layer, result obj
      $serverData = $result->{response};
   } elsif (defined $result->{stdout}) {
      # result coming from Perl layer, STAF result containing stdout
      $serverData = $result->{stdout};
   } else {
      # result coming from Perl layer, user directly sends result->{stdout}
      $serverData = $result;
   }
   $vdLogger->Debug("Step 7 completed, server data is " . Dumper($serverData));


   if ($verificationStyle eq "diff") {
      my $logDir = $vdLogger->GetLogDir() . $self->{name} . '-' .
                   $self->{componentIndex};
      my $result = VDNetLib::Workloads::Utilities::StoreDataToFile($serverData,
                                                                   $logDir);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to store server data to file");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $numberOfFiles =
         VDNetLib::Workloads::Utilities::CheckVerificationLogs($logDir);
      #
      # Call GetSimpleDiff() only when both current
      # and previous log are available.
      #
      if ($numberOfFiles > 1) {
         $serverData = $self->GetSimpleDiff($logDir);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to get diff between current and" .
                             " previous server data");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $vdLogger->Debug("Either current log or previous logs dont exists");
         delete $verificationHash->{$verificationKey};
         return SUCCESS;
      }
   }

   #
   # Step 8: Verify UserData and Server Data
   # using the compare operation.
   #
   my $ret = $self->VerifySimpleSpec($serverData,
                                     $userData,
                                     $globalCondition);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Verification process failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Step 8 completed, verification process passed for " .
                    "$verificationKey , deleting $verificationKey from " .
                    "config hash");
   delete $verificationHash->{$verificationKey};
   if ($persistData eq 'yes') {
      $vdLogger->Info("Storing stats value for $self->{componentIndex}" .
                      " under attributeGroupName = $verificationKey");
      $result = $self->{testbed}->SetRuntimeStatsValue($self->{componentIndex},
                                                       lc($self->{name}),
                                                       lc($verificationKey),
                                                       $serverData);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set runtime statistics for $self->{componentIndex}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# GetSimpleDiff--
#     method used for verification user data and diff between current
#     and previously recorded server data
#
# Input:
#     logDir - hash containing pathh for current and previous log
#
# Results:
#     Return diff hash
#     Return FAILURE in case of any error
#
# Side effects:
#
########################################################################

sub GetSimpleDiff
{
   my $self   = shift;
   my $logDir = shift;

   #
   # Get the diff between the current and previous log
   #
   my ($currentHash, $previousHash);
   my $currentLogLocation = $logDir . '/' . 'current.log';
   my $previousLogLocation = $logDir . '/' . 'previous.log';
   $currentHash =
      VDNetLib::Workloads::Utilities::GetDataFromFile($currentLogLocation);
   $previousHash =
      VDNetLib::Workloads::Utilities::GetDataFromFile($previousLogLocation);

   $vdLogger->Debug("Previous data was " . Dumper($previousHash));
   $vdLogger->Debug("Current data is " . Dumper($currentHash));
   $vdLogger->Debug("Finding the diff between current and previous data");

   my $compareObj = VDNetLib::Common::Compare->new();
   my $diff = $compareObj->GetDiffBetweenDataStructures($currentHash,
                                                        $previousHash);
   return $diff;
}



########################################################################
#
# VerifySimpleSpec--
#     method used for verification of server and user data
#
# Input:
#     serverData       - server data received from the core api
#     userData         - user data where the key's value contains condition
#                        and data separated by delimiter [?]
#     globalCondition  - [optional] used only when the user wants to verify
#                        if the input complex structure is part of an array
#                        of spec.
#
# Results:
#     Return SUCCESS if verification passes
#     Return FAILURE in case of any error
#
# Side effects:
#
########################################################################

sub VerifySimpleSpec
{
   my $self            = shift;
   my $serverData      = shift;
   my $userData        = shift;
   my $globalCondition = shift;



   if (defined $globalCondition) {
      $vdLogger->Info("Check user data for condition=$globalCondition against" .
                      " server data ");
      $vdLogger->Info("User Data" . Dumper($userData));
      $vdLogger->Info("Server Data " . Dumper($serverData));
   } else {
      $vdLogger->Info("Running verification for server data against user data");
      $vdLogger->Info("User Data" . Dumper($userData));
      $vdLogger->Info("Server Data " . Dumper($serverData));
   }

   #
   # Step 9:Perform Compare Operation
   #
   my $compareObj = VDNetLib::Common::Compare->new();
   my $result = $compareObj->CompareDataStructures($userData,
                                                   $serverData,
                                                   $globalCondition);
   my $table = Text::Table->new("User Data (Input from TDS)\n\n",
                                "Server Data (Output from Library/Product)\n\n",
                                "Result (Compare User and Server Data)\n\n");
   my $userPrettyData =
      VDNetLib::Common::Utilities::PrettyPrintDataStructure($userData);
   my $serverPrettyData =
      VDNetLib::Common::Utilities::PrettyPrintDataStructure($serverData);
   $table->load([$userPrettyData,
                 $serverPrettyData,
                 $result]);
   $vdLogger->Info("Following is the summary of verification operation\n\n" .
                   $table . "\n\n");
   if ($result eq FAILURE) {
      $vdLogger->Error("Comparison failed between user data and server data");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# OperateOnConfigSpec --
#     This method populates the runtime paramters based on the
#     config spec provided by the user. The used case for this api is
#     specially when the caller wants a spec that will be sent as an
#     argument to a core api.
#
#        For e.g.: If SwitchWorkload wants to call CreateLag(spec) api
#        from its own scope where CreateLag is method under Switch.pm.
#        If the spec is something like this:
#        $spec => { 'lagname' => 'vdnetLag',
#                   'lagtimeout' => 'short',
#                 },
#        The switchworkload doesn't have the keys as these keys are part
#        of LACPWorkload. To resolve the paramters, the caller which in
#        our case is SwitchWorkload, creates a LACPWorkload.pm object and
#        calls ProcessVDNetConfigSpec() and passes $spec as argument. Now
#        ProcessVDNetConfigSpec() will call ConfigureComponent(). Since
#        there are no action keys in $spec, only the parameters section
#        is populated. Once parameters section is populated, the values
#        are set in self.
#
# Input:
#     configHash            : Spec in hash format
#     component             : key that represents the sub-component
#                             creation, e.g. workload:
#
#                                  Typte: VM
#                                  TestVM: vm.[1]
#                                  vnic:
#                                     '[4]':
#                                        driver: e1000
#
#                             In this case key is 'vnic'
#
#     componentIndexInArray : number, from above example the vnic index
#                             in array is 4.
#
# Results:
#     Return the parameters under the runtime hash
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub OperateOnConfigSpec
{
   my $self                  = shift;
   my $configHash            = shift;
   my $componentIndexInArray = shift;
   my $component             = shift;

   my $dummyObj   = {};
   my $result = FAILURE;
   my $stats;

   # Process the parameters only
   $vdLogger->Debug("Process vdnet config spec");

   ($result, $stats) = $self->HandleParameterKeys(
                            'configHash'       => $configHash,
                            'testObject'       => $dummyObj,
			    'componentIndexInArray' => $componentIndexInArray,
                            'component' => $component);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to process vdnet config spec");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return ($result, $stats);
}


########################################################################
#
# StoreComponentObject--
#     Only one object is stored in the testbed for the specific tuple id.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       tuple         - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - Result from the core api
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     Range is not supported currenlty
#
########################################################################

sub StoreComponentObjects
{
   my $self   = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result = FAILURE;
   my $Obj  = $runtimeResult->[0];
   if ((not defined $keyValue) || (not defined $Obj)) {
      $vdLogger->Error("Either tuple or Obj is missing.");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   $result = $self->{testbed}->SetComponentObject($keyValue, $Obj);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# StoreAndBackupSubComponentObjects--
#     Method for backing up testbed to a file.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       tuple         - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - Result from the core api
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     Range is not supported currenlty
#
########################################################################

sub StoreAndBackupSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;
   my $tuple = $self->{componentIndex};

   # $keyValue represents the file that will store the product backup. Here
   # we are using the name of that file to create the name of the file to
   # be used to backup the zookeeper hierarchy.
   my $backupFilename = $keyValue->{'file'} . "-zookeeper-snapshot";

   $result = $self->{testbed}->BackupInventoryToFile($tuple, $backupFilename);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to run backup for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# StoreAndRestoreSubComponentObjects--
#     Method for restoring testbed from a file.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       tuple         - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - Result from the core api
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     Range is not supported currenlty
#
########################################################################

sub StoreAndRestoreSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;
   my $tuple = $self->{componentIndex};
   my $restoreFilename = $keyValue->{'file'} . "-zookeeper-snapshot";

   if ($self->{testbed}->RestoreInventoryFromFile($tuple, $restoreFilename) eq FAILURE) {
      $vdLogger->Error("Failed to run backup for $tuple");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# StoreSubComponentObjects --
#     Method to store sub-component/component objects
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       keyValue      - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - order in which the arguments will be passed to core api
#
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub StoreSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;


   my $tuple = $self->{componentIndex};
   my @arrOfObjects = @$runtimeResult;

   if ((not defined $tuple) || !(@arrOfObjects)) {
      $vdLogger->Error("Either tuple=$tuple or the objects not defined" .
                        Dumper(@arrOfObjects));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $keyValue = VDNetLib::Common::Utilities::ExpandTuplesInSpec($keyValue);
   my $numberOfExpectedObjects = keys %$keyValue;
   my $numberOfObtainedObjects = @arrOfObjects;
   if ($numberOfExpectedObjects != $numberOfObtainedObjects) {
      $vdLogger->Error("ExpectedObjects= $numberOfExpectedObjects not equal to" .
                       "Objects=$numberOfObtainedObjects received from core api");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   foreach my $key (sort (keys %$keyValue)) {
      my $newSpec = $keyValue->{$key};
      $vdLogger->Debug("Constructing hash for key $keyName and index $key");
      $tuple =~ s/\.x.*//g;
      $vdLogger->Info("Successfully created " . $tuple . "." .$keyName .
	              ".[$key] Configuring it...");
      $tuple =~ s/\[|\]//g;
      my $newTuple = "$tuple.$keyName.$key";
      my $newObject = shift(@arrOfObjects);

      $result = $self->{testbed}->SetComponentObject($newTuple, $newObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # This will replicate the incoming object if it is a cluster peer
      # subcomponent e.g. neutronpeer
      # This will also replicate all subcomponents from test obejct to
      # inventory object corresponding to new object if the new object is
      # peer type
      if ($self->ReplicateAcrossCluster($testObject, $keyName, $newTuple, $newObject, $key) eq FAILURE) {
         $vdLogger->Error("Failed to run replication for key $keyName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # This will make copies of the incoming object across the peers
      # (if it has any) of this particular inventory object
      my $ret = $self->StoreSubComponentAcrossPeers($newTuple, $newObject,
                                                    $keyName);
      if (not defined $ret || $ret eq FAILURE) {
         $vdLogger->Error("Failed to run replication for key $keyName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Now we want to configure the newly created component
      # No point in trying if the hash is empty
      my $hashSize = keys %$newSpec;
      if ($hashSize > 0) {
         if ((int($self->{runtime}{'statistics'}{$keyName}{$key}{action}) > 0) ||
            (int($self->{runtime}{'statistics'}{$keyName}{$key}{component}) > 0) ||
            (int($self->{runtime}{'statistics'}{$keyName}{$key}{verification}) > 0)) {
            $vdLogger->Trace("Configuring $newTuple:" . Dumper($newSpec));
            my $keysdatabase = $self->{'keysdatabase'};
            my $workloadName = $keysdatabase->{$keyName}{linkedworkload};
            my $dummyWorkload = {};
            my $package = 'VDNetLib::Workloads::' . $workloadName;
            my $componentWorkloadObj = $package->new(workload   => $dummyWorkload,
                                                     testbed    => $self->{testbed},
                                                     stafHelper => $self->{stafHelper});
            if ($componentWorkloadObj eq FAILURE) {
               $vdLogger->Error("Failed to load linked workload $package");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            $componentWorkloadObj->SetComponentIndex($newTuple);
            $vdLogger->Info("Found nested first level action/component/" .
                            "verification keys, configuring them");
            $result = $componentWorkloadObj->ConfigureComponent('configHash' => $newSpec,
                                                'testObject' => $newObject);
            if ((defined $result) && ( $result eq FAILURE)) {
               $vdLogger->Error("Failed to configure $workloadName component".
                                " with :". Dumper($newSpec));
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         } else {
            $vdLogger->Info("No nested first level action, component and " .
                            "verification keys found");
         }
      }
      if ((defined $self->{runtime}{'statistics'}{$keyName}{$key}{parameter}) &&
          (defined $self->{runtime}{'statistics'}{$keyName}{$key}{action}) &&
          (defined $self->{runtime}{'statistics'}{$keyName}{$key}{component}) &&
          (defined $self->{runtime}{'statistics'}{$keyName}{$key}{verification})) {
         my $table = Text::Table->new("Parameter\n------------\n",
                                      "Action\n------------\n",
                                      "Component\n------------\n",
                                      "Verification\n------------\n");
         $table->load([$self->{runtime}{'statistics'}{$keyName}{$key}{parameter},
                       $self->{runtime}{'statistics'}{$keyName}{$key}{action},
                       $self->{runtime}{'statistics'}{$keyName}{$key}{component},
                       $self->{runtime}{'statistics'}{$keyName}{$key}{verification}]);
         $vdLogger->Debug("Summary: number of executed keys under " .
                      "$keyName.[$key]\n\n" . $table . "\n\n");
      }
   }
   return SUCCESS;
}


########################################################################
#
# StoreSubComponentAcrossPeers --
#     Method to store sub-component/component objects. This is used when
#     adding objects to entities that have peers. For e.g. neutronpeer.
#
# Input:
#       newTuple      - Tuple of new object
#       newObject     - Object to be stored across peers
#       keyName       - Name of the action key
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub StoreSubComponentAcrossPeers
{
   my $self = shift;
   my $newTuple = shift;
   my $newObject = shift;
   my $keyName = shift;

   $vdLogger->Debug("Storing $newTuple across all peers");

   my $objID = $self->{'componentIndex'};

   $objID =~ s/\]/@/;
   $objID =~ s/@[^@]*$//;
   $objID =~ s/\[\[/\[/;
   $objID = $objID . ']';

   my $result = $self->{testbed}->GetComponentObject($objID);
   my $obj = @$result[0];
   my $peerName;
   if ($obj->can('GetPeerName')) {
      $peerName = $obj->GetPeerName();
      $vdLogger->Debug("Peer name for object is $peerName");
   } else {
         $vdLogger->Debug("Skipping StoreSubComponentAcrossPeers");
         return SUCCESS;
   }

   if ($newObject->can('GetIsGlobal')) {
      my $isGlobal = $newObject->GetIsGlobal();
      if ($isGlobal ne VDNetLib::Common::GlobalConfig::TRUE) {
         $vdLogger->Debug("Skipping StoreSubComponentAcrossPeers " .
                          "for non global object");
         return SUCCESS;
      }
   } else {
      $vdLogger->Debug("Skipping StoreSubComponentAcrossPeers for non " .
                       "global object");
      return SUCCESS;
   }

   if ($keyName eq $peerName) {
      $vdLogger->Debug("Skipping StoreSubComponentAcrossPeers as ".
                       "this seems like peer registration");
      return SUCCESS;
   }

   my $tuples = $objID . '.' . $peerName . '.[-1]';

   my $allNodeTuples = $objID;
   $allNodeTuples =~ s/(\d+)/-1/g;

   # Getting inventory tuples for peers of inventory node on which this call
   # was made
   my $targetTuples = $self->{testbed}->GetNodeTuplesFromPeers($tuples,
                                                $allNodeTuples, $newTuple);

   # Adding stored subcomponent to all peers
   foreach my $targetTuple (@$targetTuples) {
      # Updating the parent object filed of the new object to point to the cluster peer
      my $updatedNewObject = $self->UpdateParent($newObject, $targetTuple);
      $vdLogger->Debug("Storing peer object at $targetTuple after Updating Parent");
      my $result = $self->{testbed}->SetComponentObject($targetTuple, $updatedNewObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# UpdateParent --
#     Method to update the parent object field of an object with the
#     parent object of an input tuple.
#
# Input:
#       newObject    - An object, whose parent object field is to be updated.
#       targetTuple  - Tuple of new object whose parent object is to be used
#                      for updating the parent object field of the new object.
#
# Results:
#     Return updated new object
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateParent
{
   my $self = shift;
   my $newObject = shift;
   my $targetTuple = shift;

   $targetTuple =~ s/\][^\]]+$/\]/;

   # Getting the cluster peer node object
   my $updatedNewObject = $newObject;
   my $result = $self->{testbed}->GetComponentObject($targetTuple);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get parent object of replicated object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $parentObjString = $newObject->GetObjectParentAttributeName();
   $updatedNewObject->{$parentObjString} = @$result[0];

   return $updatedNewObject;
}


########################################################################
#
# ReplicateAcrossCluster --
#     Method to store sub-component/component objects and replicate them
#     over cluster peers
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       newTuple      - Tuple of new object
#       newObject     - Object that is to be replicated across cluster
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ReplicateAcrossCluster
{
   my $self = shift;
   my $testObject = shift;
   my $keyName = shift;
   my $newTuple = shift;
   my $newObject = shift;
   my $key = shift;
   my $inpTuple = $self->{componentIndex};
   my $tuple = $inpTuple;

   $vdLogger->Debug("Starting replication process for $newTuple");

   # Replication of stored object accross the cluster starts from here

   my $tuples = $inpTuple;
   $tuples =~ s/(\d+)/-1/g;

   # Getting tuples for all inventory nodes e.g. neutron tuples
   my $tupleArray = $self->{testbed}->GetAllComponentTuples($tuples);
   # Get the object of the newly stored peer tuple
   my $peerObject = $self->GetOneObjectFromOneTuple($newTuple);

   # Get id of the inventory node
   my $targetId;
   if ((exists $peerObject->{'id'}) && (defined $peerObject->{'id'})) {
      $targetId = $peerObject->{'id'};
   } else {
         $vdLogger->Debug("Skipping replication as object has no id");
         return SUCCESS;
   }

   my $peerNode;

   # We have created the peer and now we
   # need to figure out the corresponding inventory tuple
   # for the stored peer.
   # For example, if we create a cluster of two neutron nodes
   # then neutron.1.neutronpeer.1 can corresponds to neutron 2
   # and neutron.2.neutronpeer.1 can corresponds to neutron 1
   foreach my $tupleInstance (@$tupleArray) {
      my $object = $self->GetOneObjectFromOneTuple($tupleInstance);
      if ((exists $object->{'id'}) && (defined $object->{'id'})) {
         if ($targetId eq $object->{'id'}) {
            $vdLogger->Debug("Peer node found for $tupleInstance, proceeding with replication");
            $peerNode = $tupleInstance;
         }
      }
   }

   my $node = $inpTuple;

   if (defined $peerNode) {
      # tuple is our source from where the sub components
      # (except peer nodes $keyname) will be
      # duplicated to destination peerNode
      my $result = $self->{testbed}->RecursiveReplicateComponents($tuple, $peerNode, $keyName);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Replicating the peer node as well. The only difference is that the node
      # will have a different id
      $newObject->{'id'} = $peerObject->{'id'};

      my $oldObject = $peerObject;
      $oldObject->{'id'} = $testObject->{'id'};
      # TODO: Need to change this to make sure we can join two clusters to each other
      # Note: A node cannot be part of multiple cluster

      # Adding $tuple as peer object to the inventory corresponding to $peerNode
      my $nodeKey = $node;
      $nodeKey =~ s/.*\.//g;
      $vdLogger->Debug("Adding peer $peerNode.$keyName.[$nodeKey] to cluster");
      my $updatedOldObject = $self->UpdateParent($oldObject, $peerNode);
      $result = $self->{testbed}->SetComponentObject("$peerNode.$keyName.[$nodeKey]", $updatedOldObject);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my $tupleToAvoid = $peerNode;
      #
      # e.g.
      # We have a cluster with four neutron nodes:
      #
      # neutron.1                  neutron.2                   neutron.3                   neutron.4
      # peer.2 -> neutron.2        peer.1 -> neutron.1         peer.1 -> neutron.1         peer.1 -> neutron.1
      # using SetComponentObject() using SetComponentObject()  using SetComponentObject()  using SetComponentObject()
      # added in iteration 1       added in iteration 1        added in iteration 2        added in iteration 3
      #
      #
      # peer.2 -> neutron.3        peer.3 -> neutron.3         peer.2 -> neutron.2         peer.2 -> neutron.2
      # using SetComponentObject() using AddNewNodeToPeers()   using AddPeersToNewNode()   using AddPeersToNewNode()
      # added in iteration 2       added in iteration 2        added in iteration 2        added in iteration 3
      #
      #
      # peer.3 -> neutron.4        peer.4 -> neutron.4         peer.4 -> neutron.4         peer.3 -> neutron.3
      # using SetComponentObject() using AddNewNodeToPeers()   using AddNewNodeToPeers()   using AddPeersToNewNode()
      # added in iteration 3       added in iteration 3        added in iteration 3        added in iteration 3
      #
      #
      # To populate remaining peer nodes on each inventory in the cluster
      # we use AddNewNodeToPeers() and AddPeersToNewNode()
      # Once these methods are executed, all the nodes know about
      # their peers in the cluster through peer tuples
      #
      # Using this algorithm we are creating/populating our own cluster
      # and we expect the product to behave in exactly similar fashion
      #
      $result = $self->{testbed}->AddNewNodeToPeers($tuple, $newObject, $tupleToAvoid, $keyName, $key);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $result = $self->{testbed}->AddPeersToNewNode($tuple, $newObject, $tupleToAvoid, $keyName);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("Finished adding remaining peers");
   }
   return SUCCESS;

}

########################################################################
#
# CallLinkedWorkloadToTransformSpecs--
#     Method to process sub component specification provided by user
#     For tuple vc.[1].vds.[1].lag.[1], sub component is lag.[1]
#
# Input:
#     keyValue              : Array reference containing hash/specs that
#                             contains sub component properties.
#     key                   : key that represents the sub-component
#                             creation, e.g. workload:
#
#                             Typte: VM
#                             TestVM: vm.[1]
#                             vnic:
#                                '[4]':
#                                   driver: e1000
#
#                             In this case key is 'vnic'
#
# Results:
#     SUCCESS - reference to return value from sub-component  workload
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub CallLinkedWorkloadToTransformSpecs
{
   my $self = shift;
   my $keyValue = shift;
   my $key = shift;
   my $returnValues = [];
   my $componentConfiguration = $self->{'keysdatabase'};
   my $workloadName = $componentConfiguration->{$key}{linkedworkload};
   $vdLogger->Debug("Start sub component pre-process for component=$key," .
                    "\n" . Dumper($keyValue));
   # Create Lag workload object
   my $dummyWorkload = {};
   my $package = 'VDNetLib::Workloads::' . $workloadName;
   eval "require $package";
   if ($@) {
      $vdLogger->Error("Failed to load package $package : $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $componentWorkloadObj = $package->new(workload   => $dummyWorkload,
                                            testbed    => $self->{testbed},
                                            stafHelper => $self->{stafHelper});
   foreach my $index (sort (keys %$keyValue)) {
     $componentWorkloadObj->SetComponentIndex($index);
     my ($returnValue, $stats) = $componentWorkloadObj->OperateOnConfigSpec(
          $keyValue->{$index}, $index, $key);
     if ($returnValue eq FAILURE) {
        $vdLogger->Error("Failed to process sub component spec:\n" .
                         Dumper($keyValue->{$index}));
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
     $self->{runtime}{statistics}{$key}{$index} = $stats;
     push @$returnValues, $returnValue;
   }
   return $returnValues;
}


########################################################################
#
# CallLinkedWorkloadToTransformSpec --
#     Method to process sub component specification provided by user
#     For tuple vc.[1].vds.[1].lag.[1], sub component is lag.[1]
#
# Input:
#     keyValue              : reference to hash/spec that contains sub
#                             component properties
#     testObj               : the vdnet object represented by vdnet index
#     key                   : key that represents the sub-component
#                             creation, e.g. workload:
#
#                             Typte: VM
#                             TestVM: vm.[1]
#                             vnic:
#                                '[4]':
#                                   driver: e1000
#
#                             In this case key is 'vnic'
#
#     componentIndexInArray : number, from above example the vnic index
#                             in array is 4.
#
# Results:
#     SUCCESS - reference to return value from sub-component  workload
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub CallLinkedWorkloadToTransformSpec
{
   my $self              = shift;
   my $keyValue          = shift;
   my $testObj           = shift;
   my $key               = shift;
   my $componentIndexInArray  = shift;

   my $componentConfiguration = $self->{'keysdatabase'};
   my $workloadName = $componentConfiguration->{$key}{linkedworkload};
   $vdLogger->Debug("Start sub component pre-process for component=$key, " .
                    "index=$componentIndexInArray " . Dumper($keyValue));
   # Create Lag workload object
   my $dummyWorkload = {};
   my $package = 'VDNetLib::Workloads::' . $workloadName;
   eval "require $package";
   if ($@) {
      $vdLogger->Error("Failed to load package $package : $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $componentWorkloadObj = $package->new(workload   => $dummyWorkload,
                                            testbed    => $self->{testbed},
                                            stafHelper => $self->{stafHelper});
   # Request <sub-component> Workload to process specification
   # and return runtimehash without configuring
   $componentWorkloadObj->SetComponentIndex($self->{componentIndex});
   my ($returnValue, $stats) = $componentWorkloadObj->OperateOnConfigSpec($keyValue,
                                                                $componentIndexInArray,
                                                                $key);
   if ($returnValue eq FAILURE) {
      $vdLogger->Error("Failed to process sub component spec");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{runtime}{statistics}{$key}{$componentIndexInArray} = $stats;
   return $returnValue;
}

########################################################################
#
# TransformSubComponentSpec --
#     This method is used to convert a spec from testbed format to a
#     format which can used by ConfigureComponent() under ParentWorkload
#
#        For e.g.: Following spec from TestbedSpec is modified.
#           vdsConfighash => {
#               datacenter => "vc.[1].datacenter.[1]",
#               'lag' => {
#                  '[1]' => {
#                     'lagname' => 'vdnetLag1',
#                     'lagtimeout' => 'short',
#                     },
#                  '[2]' => {
#                     'lagname' => 'vdnetLag2',
#                     'lagtimeout' => 'long',
#                     },
#                  },
#               'mtu' => '1450',
#            },
#         The hash is converted to following array which is collection of specs.
#         The reference to @specArray is returned. This reference is eventually
#         passed on to the core api which creates/returns lag objects.
#
#           @specArray = [
#               {
#                  'lagname' => 'vdnetLag1',
#                  'lagtimeout' => 'short',
#                },
#               {
#                  'lagname' => 'vdnetLag2',
#                  'lagtimeout' => 'long',
#                },
#            ]
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#
#
# Results:
#     Return the modified config hash
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub TransformSubComponentSpec
{
    my $self       = shift;
    my $testObject = shift;
    my $keyName    = shift;
    my $keyValue   = shift;
    my @resolvableAttrRegexes = ("->", PERSIST_DATA_REGEX);
    my @resolvedSpecs;
    $keyValue = VDNetLib::Common::Utilities::ExpandTuplesInSpec($keyValue);
    my $attrsToResolve = VDNetLib::Common::Utilities::FindHashValues(
        \@resolvableAttrRegexes, $keyValue);
    my @uniqueAttrsToResolve = ();
    foreach my $attrToResolve (@$attrsToResolve) {
        my $key = $attrToResolve->[0];
        my $value = $attrToResolve->[1];
        if (grep {$_->[1] eq $value} @uniqueAttrsToResolve) {
            next;
        } else {
            push @uniqueAttrsToResolve, [$key, $value];
        }
    }
    my $alreadyResolvedAttrs;
    foreach my $attr (@uniqueAttrsToResolve) {
        my $key = $attr->[0];
        my $value = $attr->[1];
        if ($value =~ PERSIST_DATA_REGEX) {
            my $result = VDNetLib::Workloads::Utilities::GetAttributes(
                  $self, $value, $key);
            if ($result eq FAILURE) {
                $vdLogger->Error("Failed to get saved runtime data for " .
                                 "$value");
                VDSetLastError("ERUNTIME");
                return FAILURE;
            }
            $alreadyResolvedAttrs->{$value} = $result;
        } elsif ($value =~ /->/i) {
            my $result = $self->GetComponentAttribute($value, $testObject);
            if ($result eq FAILURE) {
                VDSetLastError("EINVALID");
                $vdLogger->Error("Failed to fetch $value from object:\n" .
                                 Dumper($testObject));
                return FAILURE;
            }
            $alreadyResolvedAttrs->{$value} = $result;
        }
    }
    if (defined $alreadyResolvedAttrs) {
        $keyValue = VDNetLib::Common::Utilities::ReplaceInStruct(
            $alreadyResolvedAttrs, $keyValue);
    }
    my $ret = $self->CallLinkedWorkloadToTransformSpecs(
        $keyValue, $keyName);
    if (FAILURE eq $ret) {
        $vdLogger->Error("Failed to pre-process the specs");
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    return [$ret];
}

########################################################################
#
# ReadComponentSpecRuntimeData
#     Method to process component spec and get the saved runtime data
#     before futher handling
#
# Input:
#     spec: Component spec before read runtime data, eg.
#           {
#             'portgroup' => 'esx.[4].portgroup.[1]',
#             'ipv4address' => 'nsxcontroller.[1]->read_ip->ip',
#             'netmask' => '255.255.252.0'
#           }
#           after reading operation, ipv4address will be replaced by
#           saved runtime data
#           {
#             'portgroup' => 'esx.[4].portgroup.[1]',
#             'ipv4address' => '10.144.138.12',
#             'netmask' => '255.255.252.0'
#
# Results:
#     SUCCESS - reference to the new spec after read operation
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub ReadComponentSpecRuntimeData
{
    my $self = shift;
    my $spec = shift;

    foreach my $key (keys %$spec) {
       if ($spec->{$key} =~ PERSIST_DATA_REGEX) {
          $vdLogger->Debug("Start to fetch the runtime data for $spec->{$key}");
          my $result = VDNetLib::Workloads::Utilities::GetAttributes(
            $self, $spec->{$key}, $key);
          if ($result eq FAILURE) {
              $vdLogger->Error("Failed to get saved runtime data for $spec->{$key}");
              VDSetLastError("EOPFAILED");
              return FAILURE;
          }
          $spec->{$key} = $result;
      }
    }
    return $spec;
}


########################################################################
#
# SetComponentIndex --
#     Method to assign value to componentIndex attribute
#
# Input:
#     componentIndex: tuple, e.g. host.[1].vmknic.[1]
#
# Results:
#     SUCCESS - if attribute is added successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub SetComponentIndex
{
   my $self          = shift;
   my $componentIndex = shift;
   if (not defined $componentIndex) {
      $vdLogger->Warn("Failed to add componentIndex to Workload");
   }
   $self->{componentIndex} = $componentIndex;
   return SUCCESS;
}


########################################################################
#
# GetComponentIndex --
#     Method to assign value to componentIndex attribute
#
# Input:
#     None
#
# Results:
#     index - componentIndex
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub GetComponentIndex
{
   my $self = shift;
   return $self->{componentIndex};
}


########################################################################
#
# ConstructArrayOfObjects --
#     Method to construct an array of objects based on the input tuples
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash
#
# Results:
#     Return reference to array of objects,
#
# Side effects:
#     None
#
########################################################################

sub ConstructArrayOfObjects
{
   my $self        = shift;
   my $testObject  = shift;
   my $keyName     = shift;
   my $keyValue    = shift;
   my $paramValues = shift;
   my $paramList  = shift;

   my @arguments;
   if (not defined $keyValue) {
      $vdLogger->Error("keyvalue variable is not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $refArrayofTuples = $self->{testbed}->GetAllComponentTuples($keyValue);
   if ($refArrayofTuples eq FAILURE) {
      $vdLogger->Error("Get component tuples failed for $keyValue.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $refArrayOfObjects = $self->GetArrayOfObjects($refArrayofTuples);
   if ($refArrayOfObjects eq FAILURE) {
      $vdLogger->Error("Get Objects failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   push (@arguments, $refArrayOfObjects);
   return \@arguments;
}


########################################################################
#
# PreProcessDeleteComponentsAndParameters --
#     Method to pre-process input for DeleteComponent method
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash
#
# Results:
#     Return reference to array of objects and parameter values
#
# Side effects:
#     None
#
########################################################################

sub PreProcessDeleteComponentsAndParameters
{
   my $self        = shift;
   my $testObject  = shift;
   my $keyName     = shift;
   my $keyValue    = shift;
   my $paramValues = shift;
   my $paramList  = shift;

   my @arguments = ();
   my $refArrayOfObjects = $self->ConstructArrayOfObjects($testObject,
							  $keyName,
							  $keyValue,
                                                          $paramValues,
                                                          $paramList);

   if ($refArrayOfObjects eq FAILURE) {
      return FAILURE;
   }

   push (@arguments, @$refArrayOfObjects);

   # $paramValues->{$keyName} contains component specs
   # We also want to send all other parameters
   # than the $paramValues->{$keyName}
   # So delete element from $additionalParams having $keyName
   # And return those $additionalParams also
   my $additionalParams = $paramValues;
   if (defined $additionalParams->{$keyName}) {
      delete $additionalParams->{$keyName};
   }
   push (@arguments, $additionalParams);

   return \@arguments;
}


########################################################################
#
# RemoveSubComponentObjects --
#     Method to delete objects represented by tuples
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash.
#                    The objects associated witj these tuples will be
#                    deleted.
#
# Results:
#     SUCCESS - if objects is deleted successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub RemoveSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue) = @_;

   if ((not defined $keyValue)) {
      $vdLogger->Error("keyValue = $keyValue not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Successfully deleted components $keyValue");
   my $result = $self->{testbed}->SetComponentObject($keyValue, "delete");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RemoveComponentObject --
#     This method allows the component to delete itself from vdnet.
#     The component is stored as inventory.[x].component.[y], so if we
#     add this method as a postprocess for a action/component key, then
#     this method will delete itself (i.e. inventory.[x].component.[y])
#     from zookeeper
#
# Input:
#     None
#
# Results:
#     SUCCESS - if object is deleted successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub RemoveComponentObject
{
   my $self = shift;

   if ((not defined $self) || (not defined $self->{componentIndex})) {
      $vdLogger->Error("testObject not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $result = $self->{testbed}->SetComponentObject($self->{componentIndex}, "delete");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to delete object $self->{componentIndex} in post process");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully deleted component $self->{componentIndex}");
   return SUCCESS;
}


########################################################################
#
# RemoveAndReplicateSubComponentObjects --
#     Method to delete objects represented by tuples. This method is for
#     peer type entities. For e.g. neutronpeer.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash.
#                    The objects associated witj these tuples will be
#                    deleted.
#
# Results:
#     SUCCESS - if objects is deleted successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub RemoveAndReplicateSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue) = @_;

   if ((not defined $keyValue)) {
      $vdLogger->Error("keyValue = $keyValue not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Deleting objects represented by tuple $keyValue");

   my $type = $testObject->{'type'};

   my $objID = $self->{'componentIndex'};

   $objID =~ s/\]/@/;
   $objID =~ s/@[^@]*$//;
   $objID = $objID . ']';

   my $result = $self->{testbed}->GetComponentObject($objID);
   my $obj = @$result[0];
   my $peerName;

   if ($obj->can('GetPeerName')) {
      $peerName = $obj->GetPeerName();
      $vdLogger->Debug("Peer name for object is $peerName");
      my $tuples = $objID . '.' . $peerName . '.[-1]';
      my $objects = $self->{testbed}->GetComponentObject($tuples);

      # Getting inventory tuples of all peers of this particular inventory node
      my $allNodeTuples = $objID;
      $allNodeTuples =~ s/(\d+)/-1/g;
      my $targetTuples = $self->{testbed}->GetNodeTuplesFromPeers($tuples, $allNodeTuples, "");

      # Removing all stored subcomponents from this particular inventory node
      my $tuple = $objID ;
      $vdLogger->Debug("Removing all subcomponents from $tuple");
      $result = $self->{testbed}->RemovePeerComponents($tuple, $keyValue);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to update the testbed hash.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Removing peer nodes from this particular inventory node
      $vdLogger->Debug("Removing all peers from $tuple");
      foreach my $targetTuple (@$targetTuples) {
         my $result = $self->{testbed}->RemovePeer($targetTuple, $keyValue, $peerName);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to update the testbed hash.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   $result = $self->{testbed}->SetComponentObject($keyValue, "delete");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# RemoveReplicatedSubComponentObjects
#  --
#     Method to delete objects represented by tuples. This method is for
#     objects created on entites that have peers. For e.g. neutronpeer.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash.
#                    The objects associated with these tuples will be
#                    deleted.
#
# Results:
#     SUCCESS - if objects are deleted successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub RemoveReplicatedSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue) = @_;

   if ((not defined $keyValue)) {
      $vdLogger->Error("keyValue = $keyValue not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Deleting objects represented by tuple $keyValue");

   my $result = $self->{testbed}->GetComponentObject($keyValue);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get object to delete for key: $keyValue");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $type = $testObject->{'type'};

   if ($result != undef && @$result[0] != undef) {
      if (@$result[0]->can('GetIsGlobal')) {
         my $isGlobal = @$result[0]->GetIsGlobal();
         if ($isGlobal eq VDNetLib::Common::GlobalConfig::TRUE) {
            my $objID = $self->{'componentIndex'};

            $objID =~ s/\]/@/;
            $objID =~ s/@[^@]*$//;
            $objID = $objID . ']';

            my $result = $self->{testbed}->GetComponentObject($objID);
            my $obj = @$result[0];
            my $peerName;

            if ($obj->can('GetPeerName')) {
               $peerName = $obj->GetPeerName();
               $vdLogger->Debug("Peer name for object is $peerName");

               my $tuples = $objID . '.' . $peerName . '.[-1]';

               # Getting inventory tuples for all peers of the inventory node on
               # which this call was made
               my $allNodeTuples = $objID;
               $allNodeTuples =~ s/(\d+)/-1/g;
               my $targetTuples = $self->{testbed}->GetNodeTuplesFromPeers($tuples,
                                                                  $allNodeTuples,
                                                                  $keyValue);

               $vdLogger->Debug("Deleting $keyValue across all peers in the cluster");
               foreach my $targetTuple (@$targetTuples) {
                  $vdLogger->Debug("Deleting $targetTuple from the cluster");
                  my $result = $self->{testbed}->SetComponentObject($targetTuple,
                                                                        "delete");
                  if ($result eq FAILURE) {
                     $vdLogger->Error("Failed to update the testbed hash.");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
               }
               if (grep {$_ eq $keyValue} @$targetTuples) {
                  $vdLogger->Debug("$keyValue is in target tuples " . Dumper($targetTuples));
                  return SUCCESS;
               }
            }
         } else {
           $vdLogger->Debug("Skip removing replicated version of this object");
        }
      } else {
         $vdLogger->Debug("Skipping Removing replicated version of this object");
      }
   }

   $result = $self->{testbed}->SetComponentObject($keyValue, "delete");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# RemoveListOfReplicatedSubComponentObjects--
#     Method to delete objects for a list of sub-components.
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       subComponents - reference to array of sub-component names
#
# Results:
#     SUCCESS - if objects are deleted successfully, return SUCCESS
#     FAILURE - incase of any other event
#
# Side effects:
#     None
#
########################################################################

sub RemoveListOfReplicatedSubComponentObjects
{
   my $self = shift;
   my ($testObject, $keyName, $subComponents) = @_;

   if ((not defined $subComponents)) {
      $vdLogger->Error("Sub-Components $subComponents not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (ref($subComponents) ne "ARRAY") {
      $vdLogger->Error("Sub-components $subComponents passed should be an array");
      VDSetLastError("EINVLAID");
      return FAILURE;
   }

   my $result = SUCCESS;
   my $componentIndex = $self->{'componentIndex'};
   foreach my $subComponent (@$subComponents) {
      $subComponent = $componentIndex . '.' . $subComponent . '.[-1]';
      if (FAILURE eq $self->RemoveReplicatedSubComponentObjects($testObject,
                                                        $keyName,
                                                        $subComponent)) {
         $vdLogger->Error("Failed to remove subcomponent $subComponent");
         VDGetLastError(VDGetLastError());
         $result = FAILURE;
      }
   }
   return $result;
}


########################################################################
#
#  HandleParameterKeys --
#       This api is being used as a generic api. This api will be
#       called by all the workloads to process param keys. If the key is
#       present in the keydatabase of that workload, then this api will
#       get executed else the control will return back to the workload
#       from where it was invoked earlier.
#
# Input:
#       configHash - configuration that needs to be executed. (Mandatory)
#       testObj    - object for which the above configuration needs to be
#                     done (netadapter/switch/vc/vm/host object). (Mandatory)
#
# Results:
#       SUCCESS - in case configuration was successfull
#       FAILURE - in case configuration was unsuccessfull
#
# Side effetcs:
#       None
#
########################################################################

sub HandleParameterKeys
{
   my $self             = shift;
   my %args             = @_;
   my $configHash       = $args{configHash};
   my $testObj          = $args{testObject};
   my $componentIndexInArray = $args{componentIndexInArray};
   my $component             = $args{component};
   my $result;

   $self->{runtime}{parameters} = {};
   $vdLogger->Debug("Configuring from abstract class for configHash:" .
                     Dumper($configHash));

   my $keysDatabase = $self->{keysdatabase};

   my $stats = {
      parameter => 0,
      action => 0,
      component => 0,
      verification => 0,
   };
   # Process all Parameters type
   foreach my $index (keys %{$configHash}) {
      if ((defined $keysDatabase->{$index}{type}) &&
         ($keysDatabase->{$index}{type} ne "parameter")) {
         if ($keysDatabase->{$index}{type} eq 'action') {
            $stats->{action} = $stats->{action} + 1;
         }
         if ($keysDatabase->{$index}{type} eq 'component') {
            $stats->{component} = $stats->{component} + 1;
         }
         if ($keysDatabase->{$index}{type} eq 'verification') {
            $stats->{verification} = $stats->{verification} + 1;
         }
         next;
      }
      $vdLogger->Debug("Storing arguments based on the parameter $index");
      $stats->{parameter} = $stats->{parameter} + 1;
      if (defined $keysDatabase->{$index}{method}) {
         my $method = $keysDatabase->{$index}{method};
         $result = $self->$method($configHash->{$index},
                                  $testObj,
                                  $index,
                                  $componentIndexInArray,
                                  $component);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to set Parameter of $index using $method");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $self->{runtime}{parameters}{$index} = $result;
      } else {
         $self->{runtime}{parameters}{$index} = $configHash->{$index};
      }
   }
   return ($self->{runtime}{parameters}, $stats);
}


########################################################################
#
# GetMultipleComponentObjects --
#     Method to process multiple components together and return reference
#     to an array of objects to each of the components
#
# Input:
#     host: list of tuples separated by ;;
#
# Results:
#     Reference to an array of objects corresponding to given components
#
# Side effects:
#     None
#
########################################################################

sub GetMultipleComponentObjects
{
   my $self	  = shift;
   my $components = shift;
   my @args;
   my $refArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($components);
   if ($refArray eq FAILURE) {
         $vdLogger->Error('Invalid ref for tuple list');
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }

   my @finalTuplesList;
   #
   # Resolve -1 in all the tuples
   #
   # Check if there is -1
   if (grep(/\[?-1\]?/, @$refArray)) {
       $vdLogger->Debug('-1 option found in vdnet index, trying to resolve it');
       foreach my $tuple (@$refArray) {
           my $resolvedTupleArray = $self->{testbed}->ResolveTuple($tuple);
           if ($resolvedTupleArray eq FAILURE) {
               $vdLogger->Error("Failed to resolve $tuple");
               VDSetLastError(VDGetLastError());
               return FAILURE;
           }
           @finalTuplesList = (@finalTuplesList, @$resolvedTupleArray);
       }
   } else {
       @finalTuplesList = @$refArray;
   }

   foreach my $tuple (@finalTuplesList) {
      my $result = $self->{testbed}->GetComponentObject($tuple);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $tuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


#######################################################################
#
# PreProcessHost --
#     Method to process "host" property in testspec
#
# Input:
#     host: tuple representing host
#
# Results:
#     object corresponding to given host object
#
# Side effects:
#     None
#
########################################################################

sub PreProcessHost
{
   my $self = shift;
   my $host = shift;
   my @args;

   my $refHostArray = VDNetLib::Common::Utilities::ProcessMultipleTuples($host);
   foreach my $hostTuple (@$refHostArray) {
      my $result = $self->{testbed}->GetComponentObject($hostTuple);
      if (not defined $result) {
         $vdLogger->Error("Invalid ref for tuple $hostTuple");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@args, $result->[0]);
   }
   return \@args;
}


########################################################################
#
#  PreProcessHosts --
#       This method returns reference to array containing hosts objects
#
# Input:
#       configHash - the config spec which has deletehostsfromdc key
#
# Results:
#      SUCCESS - returns reference to array containing hosts objects
#      FAILURE - incase of result is undefined
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessHosts
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue) = @_;

   my $refHost = VDNetLib::Common::Utilities::ProcessMultipleTuples($keyValue);
   my $result = $self->GetArrayOfObjects($refHost);
   if ($result eq FAILURE) {
      $vdLogger->Error("Invalid ref for array of tuples $keyValue");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# PostProcessUpdateTestbedWithNewObject --
#     Post process method for which updates(stores obj handle)
#     testbed with the new component/subcomponent object
#
# Input:
#     testObj - Core API object under test.
#               E.g. HostWorkload will have hostObj as testObj
#     keyName - action/param key name
#     keyValue - action/param key value
#     refToHash - workload hash
#     runtimeResult -
#     paramValue    - Reference to hash where keys are the contents of
#                     'params' and values are the values that are assigned
#                     to these keys in config hash.
#     runtimeResult - Result from the core api
#
# Results:
#     SUCCESS, if new object is updated successfully;
#     FAILURE, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub PostProcessUpdateTestbedWithNewObject
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   return $self->{testbed}->SetComponentObject($keyValue, $runtimeResult);
}


########################################################################
#
# PostProcessUpdateObjectItself--
#     Post process method which updates the object itself in parent
#     process when child process changes anything in the object.
#
# Input:
#     testObj - Core API object under test.
#               E.g. HostWorkload will have hostObj as testObj
#     keyName - action/param key name
#     keyValue - action/param key value
#     refToHash - workload hash
#     runtimeResult -
#     paramValue    - Reference to hash where keys are the contents of
#                     'params' and values are the values that are assigned
#                     to these keys in config hash.
#     runtimeResult - Result from the core api
#
# Results:
#     SUCCESS, if new object is updated successfully;
#     FAILURE, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub PostProcessUpdateObjectItself
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   return $self->{testbed}->SetComponentObject($self->{componentIndex},
                                               $testObject);
}


#######################################################################
#
# GetOneObjectFromOneTuple --
#      This method is used to return component object from the
#      Testbed datastructure, given a single tuple
#
# Input:
#      component   : tuple, example: host.[<index>].component.[<index>]
#
# Result:
#      Based on the tuple, object is returned
#
# Side effects:
#      None
#
########################################################################

sub GetOneObjectFromOneTuple
{
   my $self      = shift;
   my $component = shift;
   my $args;
   my $ref;

   $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $ref->[0];
}


########################################################################
#
#  GetKeysTable --
#       This method returns the KEYSDATABASE of the current Workload and
#       merges with the ParentWorkload
#
# Input:
#
# Results:
#      SUCCESS - returns the KEYSDATABASE hash.
#
# Side effetcs:
#       None
#
########################################################################

sub GetKeysTable
{
   my $self = shift;
   my $currentPackage;

   $self =~ /(.*)\=.*/;
   $currentPackage = $1;
   $currentPackage =~ m/\:\:(\w+)$/;
   $currentPackage = $1;

   # Get the current working directory to
   # fetch the keysdatabase from yaml file
   my $cwd = $Bin . '/../VDNetLib/Workloads/yaml/';
   my $fileCurrent = $cwd .  $currentPackage . '.' . 'yaml';
   my $fileParent = $cwd . 'ParentWorkload' . '.' . 'yaml';
   if (exists $self->{keysTable} and defined $self->{keysTable}{$fileCurrent}) {
      return $self->{keysTable}{$fileCurrent};
   }

   # FIXME(Prabuddh): Add back logging for ConvertYAMLToHash calls once the issue
   # with duplicated KeysDB loading is fixed
   my $currentPackageKeysDB = ConvertYAMLToHash(
        $fileCurrent, $vdLogger->GetLogDir(), 1);
   if ($currentPackageKeysDB eq FAILURE) {
      return FAILURE;
   }
   # FIXME(Prabuddh): Add back $logging for ConvertYAMLToHash calls once the issue
   # with duplicated KeysDB loading is fixed
   my $myparentKeysDB = ConvertYAMLToHash(
        $fileParent, $vdLogger->GetLogDir(), 1);
   if ($myparentKeysDB eq FAILURE) {
      return FAILURE;
  }

   # Merge keys database from Parent with the
   # current keys data base
   foreach my $key (keys %$myparentKeysDB){
      if (!exists $currentPackageKeysDB->{$key}) {
         $currentPackageKeysDB->{$key} = $myparentKeysDB->{$key};
      }
   }
   # Making the keys lower case
   %$currentPackageKeysDB = (
      map { lc $_ => $currentPackageKeysDB->{$_}
      } keys %$currentPackageKeysDB
   );
   # Cache the already loaded keys.
   $self->{keysTable}{$fileCurrent} = $currentPackageKeysDB;
   return $currentPackageKeysDB;
}

########################################################################
#
# PreProcessDeleteComponent --
#     Method to process deleteComponent type keys or in general keys
#     of format delete<Component> => "<tuple>"
#
# Input:
#     testObject - An object, whose core api will be executed
#     keyName    - Name of the action key
#     keyValue - Reference to hash/spec that contains NIOC
#                  configuration details
#
# Results:
#     Reference to
#
# Side effects:
#
########################################################################

sub PreProcessDeleteComponent
{
   my $self	 = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @arguments = ();
   my $refArraryVnicObjects = $self->ConstructArrayOfObjects($testObject,
							     $keyName,
							     $keyValue);

   if ($refArraryVnicObjects eq FAILURE) {
      return FAILURE;
   }
   $refArraryVnicObjects = $refArraryVnicObjects->[0];
   push (@arguments, $refArraryVnicObjects);

   return \@arguments;
}


########################################################################
#
# StoreNestedObjects --
#      Method to add objects for N spec parameters recursively. This API
#      iterates through spec provided in workload or testbed spec and
#       add objects provided in the runtime results
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       keyValue      - Value assigned to action key in config hash
#       paramValue    - N spec parameters, looks like below:
#          'filter' => [
#                        {
#                          'filtername' => 'dvfilter-generic-vmware',
#                          'filterstatus' => 'enabled',
#                          'rule' => [
#                                     {
#                                        'srcip' => '192.168.0.1',
#                                        'ruleoperation' => 'add',
#                                        'ruleaction' => 'drop'
#                                      },
#                                      {
#                                        'srcip' => '192.168.0.1',
#                                        'ruleoperation' => 'add',
#                                        'ruleaction' => 'drop'
#                                      }
#                                    ]
#                        },
#                        {
#                          'filtername' => 'dvfilter-generic-vmware',
#                          'filterstatus' => 'enabled',
#                          'rule' => [
#                                      {
#                                        'srcip' => '192.168.0.1',
#                                        'ruleoperation' => 'add',
#                                        'ruleaction' => 'drop'
#                                      },
#                                      {
#                                        'srcip' => '192.168.0.1',
#                                        'ruleoperation' => 'add',
#                                        'ruleaction' => 'drop'
#                                      }
#                                    ]
#                        }
#                      ]
#
#       runtimeResult - nested spec consisting of array and hashes containing objects #
#                              looks like below
#                 [
#                  {  object => REFObjofFilter1,
#                     rule   => [
#                                 {
#                                     object => REFObjofRule1,
#                                  },
#                                  {
#                                     object => REFObjofRule2,
#                                  }
#                               ]
#                  },
#                  {  object => REFObjofFilter2,
#                     rule   => [
#                                  {
#                                     object => REFObjofRule1,
#                                  },
#                                  {
#                                     object => REFObjofRule2,
#                                  }
#                               ]
#                  },
#                ]
#
# Results:
#        SUCCESS, stores all the objects based on the N spec Paramters
#        FAILURE, incase of any error
#
# Side effects:
#      None
#
#########################################################################

sub StoreNestedObjects
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult, $tuple, $workloadObj) = @_;
   my $result = FAILURE;
   my @arrayOfKeys;
   if (not defined $tuple) {
       # When this api is called for the fist time
       # $tuple is not set, so it will set to
       # test<> from workload. e.g. if workload type is
       # PortGroup and testportgroup is
       # "vc.[1].dvportgoup.[1]" then set $tuple to
       # this value.
       $tuple = $self->{componentIndex};
       @arrayOfKeys = keys %$paramValues;
   } else {
      push  @arrayOfKeys, $keyName;
   }
   foreach my $keyName (@arrayOfKeys) {
       # When this api is called for the fist time
       # $workloadObj is not set, therefore
       # set $workloadObj to $self. But when recursion
       # kicks in, the $workloadObj is always set and below
       # condiion is always false.

       if (not defined $workloadObj) {
          $workloadObj = $self;
          $keyValue = $self->{workload}{$keyName};
           # The last is invoked because some paramter keys
           # will not have linked workload so this api should
           # avoid processing them as they dont have an associated
           # object. Therefore we skip these keys
            my $keysdatabase = $workloadObj->{'keysdatabase'};
          my $linkedworklaod = $keysdatabase->{$keyName}{linkedworkload};
          if (not defined $linkedworklaod) {
            last;
          }
      }

      $keyValue = VDNetLib::Common::Utilities::ExpandTuplesInSpec($keyValue);
      my $count = "0";
      foreach my $index (sort keys %$keyValue) {
         my $keysdatabase = $workloadObj->{'keysdatabase'};
         if (exists $keysdatabase->{$keyName}{subcomponent}) {
            my @arayOfSubComponentKeys = keys %{$keysdatabase->{$keyName}{subcomponent}};
            foreach my $subComponentKeys (@arayOfSubComponentKeys) {
               if (exists $keyValue->{$index}{$subComponentKeys}) {
                  my $workloadName = $keysdatabase->{$keyName}{subcomponent}{$subComponentKeys};
                  my $dummyWorkload = {};
                  my $package = 'VDNetLib::Workloads::' . $workloadName;
                  my $componentWorkloadObj = $package->new(workload   => $dummyWorkload,
                                                           testbed    => $self->{testbed},
                                                           stafHelper => $self->{stafHelper});
                  my $newKeyName = $subComponentKeys;
                  my $newTuple = "$tuple.$keyName.[$index]";
                  $result = $self->StoreNestedObjects(undef,
                                                      $newKeyName,
                                                      $keyValue->{$index}{$newKeyName},
                                                      undef,
                                                      $runtimeResult->[$count]->{$newKeyName}, #object from runtimeresult
                                                      $newTuple,
                                                      $componentWorkloadObj);
                  if ($result eq FAILURE) {
                     $vdLogger->Error("Failed to store the Object for $newTuple");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
               }
            }
         }
         my $refObject = $runtimeResult->[$count];
         my @arrayOfObjects;
         push @arrayOfObjects, $refObject->{object};
         my $newTuple = "$tuple.$keyName.[$index]";
         $result = $self->StoreComponentObjects(undef,undef, $newTuple, undef, \@arrayOfObjects);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to store Objects for $newTuple");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      $count++;
   }
   return SUCCESS;
}


########################################################################
#
# TransformSubComponentSpecOfParameter --
#     This method is used to convert a spec from testbed format to a
#     format which can used by ConfigureComponent() under ParentWorkload
#
#        For e.g.: Following spec from TestbedSpec is modified.
#         dvportgroup  => {
#                     '[1]'   => {
#                        vds     => "vc.[1].vds.[1]",
#                        ports   => "1",
#                       'filter' => {
#                            '[1]'  => {
#                                'filtername' => 'dvfilter-generic-vmware',
#                                'filterstatus' => 'enabled',
#                                'rule' => {
#                                   '[1]' => {
#                                     'ruleoperation' => 'add',
#                                      'srcip'        => 'srcip',
#                                      'ruleaction'   => 'drop',
#                                      'protocol'     => 'icmp',
#                                   },
#                                   '[2-3]' => {
#                                       'ruleoperation' => 'remove',
#                                       'srcip'        => 'srcip',
#                                       'ruleaction'   => 'accept',
#                                       'protocol'     => 'icmp',
#                                   },
#                                },
#                           },
#                       },
#                     },
#               },
#
#         The hash is converted to following array which is collection of specs.
#         The reference to @specArray is returned. This reference is eventually
#         passed on to the core api which creates/returns filter and rule  objects.
#         @specArray = [
#                          {
#                             'protocol' => 'icmp',
#                             'srcip' => 'srcip',
#                             'ruleoperation' => 'add',
#                             'ruleaction' => 'accept'
#                          },
#                          {
#                            'protocol' => 'icmp',                         '
#                             srcip' => 'srcip',
#                            'ruleoperation' => 'remove',
#                            'ruleaction' => 'accept'
#                         }
#                         {
#                            'protocol' => 'icmp',
#                            'srcip' => 'srcip',
#                            'ruleoperation' => 'remove',
#                           'ruleaction' => 'accept'
#                         }
#                     ];
#
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the parameter key
#       subComponentSpec   - Value assigned to parameter key in config hash
#
#
#Results:
#    Return the modified config hash
#    Return FAILURE in case of any error
#
#Side effects:
#   None
#
#
#########################################################################

sub TransformSubComponentSpecOfParameter
{
   my $self = shift;
   my $subComponentSpec = shift;
   my $testObject = shift;
   my $keyName = shift;
   my @specArray;
   my @arguments;
   my $refNewConfigSpecN = {};
   my $keyValue = VDNetLib::Common::Utilities::ExpandTuplesInSpec($subComponentSpec);
    foreach my $index (sort (keys %$keyValue)) {

      # Call the api recursively
       foreach my $indexKeys (keys %{$keyValue->{$index}}) {
         my $componentConfiguration = $self->{'keysdatabase'};
         if (defined $componentConfiguration->{$indexKeys}{linkedworkload}) {
            $refNewConfigSpecN->{$indexKeys} = $self->TransformSubComponentSpecOfParameter(
                                                                  $keyValue->{$index}{$indexKeys},
                                                                  undef,
                                                                  $indexKeys);
           if ( $refNewConfigSpecN->{$indexKeys} eq FAILURE) {
              $vdLogger->Error("Failed to process vdnet config Spec");
              VDSetLastError(VDGetLastError());
              $vdLogger->Debug(Dumper($refNewConfigSpecN));
              return FAILURE;
            }
         }
      }

      $vdLogger->Debug("Processing for key $keyName and index $index");
      my $refNewConfigSpec = $self->CallLinkedWorkloadToTransformSpec($keyValue->{$index},
                                                                      undef,
                                                                      $keyName);
      if ($refNewConfigSpec eq FAILURE) {
         $vdLogger->Error("Failed to process vdnet config spec");
          $vdLogger->Debug(Dumper($keyValue->{$index}));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $refNewConfigSpec = {%$refNewConfigSpecN, %$refNewConfigSpec};
      push(@specArray, $refNewConfigSpec);
   }

   push (@arguments, \@specArray);
   return \@specArray;

}

######################################################################
#
# ProcessIp --
#     Method to process the tuple
#     and return the appropriate ipv4 address
#
# Input:
#    testTuple - The tuple of the test source like host.[1].vmknic.[1]/
#                    vm.[1].vnic.[1]
#
#
# Results:
#     IPv4 address  will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessIP
{
   my $self = shift;
   my $testTuple = shift;
   my $reftestObj = $self->{testbed}->GetComponentObject($testTuple);
   my $testadpterObj =  $reftestObj->[0];
   if (not defined  $testadpterObj) {
      $vdLogger->Error("Reference test adapter not defined in ProcessIP");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $testIP  = $testadpterObj->GetIPv4();
   return $testIP;
}


######################################################################
#
# ProcessMAC --
#     Method to process the tuple
#     and return the appropriate MAC address
#
# Input:
#   component - Raw MAC address, or tuple of the test source like
#               host.[1].vmknic.[1]/vm.[1].vnic.[1]
#
# Results:
#     Mac address  will be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessMAC
{
   my $self = shift;
   my $component = shift;
   my $vnicObj   = undef;
   my $macAddrRegex = VDNetLib::TestData::TestConstants::MAC_ADDR_REGEX;
   if ($component =~ /$macAddrRegex/i) {
      $vdLogger->Debug("$component not a tuple, returning it directly.");
      return $component;
   }
   my $ref = $self->{testbed}->GetComponentObject($component);
   if ((not defined $ref) || ($ref eq FAILURE)) {
      $vdLogger->Error("Invalid ref for tuple $component");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (ref($ref) ne "ARRAY") {
      $vdLogger->Error("Expects variable ref to be of type ARRAY");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   }
   if (scalar(@$ref) > 1) {
      $vdLogger->Error("Expects ref to be array of lenght 1. Supports only " .
                       "single VDNet index.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vnicObj = $ref->[0];
   if (not defined $vnicObj) {
      $vdLogger->Error("Vnic Object not found for $component.");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   }

   # Checkif mac address is undef.
   if (not defined $vnicObj->{macAddress}) {
      $vdLogger->Warn("No MAC address found for $component. Returning undef.");
      return undef;
   } elsif ($vnicObj->{macAddress} =~ /$macAddrRegex/i) {
     # Check if mac address matches the $macAddrRegex to validate it.
      $vdLogger->Debug("Processed tuple $component to return " .
                       "$vnicObj->{macAddress}.");
      return $vnicObj->{macAddress};
   }
   else {
      $vdLogger->Error("$vnicObj->{macAddress} not a valid MAC address.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
#
#  AutogenerateId --
#       This method generates id for any inventory/component based on
#       ComponentIndex if user wants to autogenerate the id
#       Does not generate id if user has already passed an id
#
# Input:
#       configHash
#       testObj
#       index
#       componentIndexInArray
#
# Results:
#      Returns id
#
# Side effetcs:
#       None
#
########################################################################

sub AutogenerateId
{
   my $self             = shift;
   my $value            = shift;
   my $testObj          = shift;
   my $index            = shift;
   my $componentIndexInArray = shift;

   if ((not defined $componentIndexInArray) || (lc($value) ne "autogenerate")) {
      return $value;
   }

   return $componentIndexInArray;
}


########################################################################
#
#  AutogenerateName --
#       This method generates name for any inventory/component based on
#       ComponentName - ComponentIndex - PID of process if user wants
#       to autogenerate the name
#       Does not generate name if user has already passed a name
#
# Input:
#       configHash
#       testObj
#       index
#       componentIndexInArray
#
# Results:
#      Returns name
#
# Side effetcs:
#       None
#
########################################################################

sub AutogenerateName
{
   my $self             = shift;
   my $value            = shift;
   my $testObj          = shift;
   my $index            = shift;
   my $componentIndexInArray = shift;

   if ((not defined $componentIndexInArray) || (lc($value) ne "autogenerate")) {
      return $value;
   }
   my $componentName = $self->{targetkey};
   $componentName =~ s/test//i;
   my $autoName = VDNetLib::Common::Utilities::GenerateNameWithRandomId(
                                                  $componentName,
                                                  $componentIndexInArray);
   return $autoName;
}


########################################################################
#
#  GenerateIPUsingEquation --
#       This method generates ip address based out of indexes
#       if the input is 1.1.1.x and if the index is 6, then the
#       generated ip address is 1.1.1.6
#
# Input:
#       value            - The value of the key for which equation needs processing
#       testObj          - The adapter object
#       index            - name of the key
#       componentIndex   - number, from below example the vnic index
#                          in array is 4.
#       component        - key that represents the sub-component
#                             creation, e.g. workload:
#
#                                  Typte: VM
#                                  TestVM: vm.[1]
#                                  vnic:
#                                     '[4]':
#                                        driver: e1000
#
#                          In this case key is 'vnic'
#
# Results:
#      Returns name
#
# Side effetcs:
#       None
#
########################################################################

sub GenerateIPUsingEquation
{
   my $self           = shift;
   my $value          = shift;
   my $testObj        = shift;
   my $index          = shift || 'dummy';
   my $componentIndex = shift || 1;
   my $component      = shift || 'VDTestInventory';

   my $vdnetindex = $self->{componentIndex};
   if ($value !~ /x/) {
      $vdLogger->Info("Returning the value:$value as no equation found");
      return $value;
   } elsif ($value =~ /=/) {
      $vdLogger->Debug("Equation found: $value");
      my ($key, $ip) = split('=', $value);
      my @ipIndex = split('\.', $ip);
      my @newArray;
      foreach my $eachOctet (@ipIndex) {
         $vdLogger->Debug("Processing for octet: $eachOctet, index: $component");
         my $lookForString;
         my $indexToBeUsed;
         # Construct the string which can be
         if ($eachOctet =~ /$component/) {
            $vdLogger->Debug("Trying to use index from component: $component");
            $lookForString = $eachOctet;
            $indexToBeUsed = $componentIndex;
            $vdLogger->Debug("Use $lookForString & index:$indexToBeUsed");
            if ($eachOctet =~ /$lookForString/) {
               $eachOctet =~ s/$lookForString/$indexToBeUsed/;
               $vdLogger->Debug("Will evaluate the equation $eachOctet");
               $eachOctet = eval $eachOctet;
            }
         } else {
            $vdLogger->Debug("Trying to use index from vdnet index: $vdnetindex");
            $eachOctet = VDNetLib::Common::Utilities::VDNetInventoryBasedAlgorithm(
                                            $componentIndex,
                                            $eachOctet,
                                            $vdnetindex);
         }
         push @newArray, $eachOctet;
      }
      # Joining array as . separated to create ip
      # address out of it
      my $newip = join '.', @newArray;
      $vdLogger->Info("The equation: $value was resolved to a new ip: $newip");
      return $newip;
   }
}

########################################################################
#
# PreProcessNSXSubComponent --
#     Method to process NSX component specs
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the component key
#       keyValue   - Value assigned to action key in config hash
#
# Results:
#     Reference to an array which has 3 elements:
#     [0]: name of the component
#     [1]: reference to the test object
#     [2]: reference to an array of hash which contains sub-component
#          spec
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNSXSubComponent
{
   my $self       = shift;
   my $testObject = shift;
   my $keyName    = shift;
   my $keyValue   = shift;
   my $paramValues = shift;
   my $paramList  = shift;

   my @vdnetIndex = split ('\.', $self->{componentIndex});
   pop @vdnetIndex;
   my $derivedComponent = pop @vdnetIndex;
   my $className;
   if (exists $self->{keysdatabase}{$keyName}{objtype}) {
      $className = $self->{keysdatabase}{$keyName}{objtype}{$derivedComponent};
      if (not defined $className) {
         $vdLogger->Error("Class name:" .ref($self) . ": Key $keyName is " .
                          "not defined for component=$derivedComponent");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }

   my $specArray = $self->TransformSubComponentSpec($testObject, $keyName, $keyValue);
   if ($specArray eq FAILURE) {
      $vdLogger->Error("TransformSubComponentSpec method failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # $paramValues->{$keyName} contains component specs
   # We also want to send all other parameters
   # than the $paramValues->{$keyName}
   # So delete element from $additionalParams having $keyName
   # And return those $additionalParams
   my $additionalParams = $paramValues;
   if (defined $additionalParams->{$keyName}) {
      delete $additionalParams->{$keyName};
   }

   return [$keyName, $specArray->[0], $className, $additionalParams];
}


########################################################################
#
# PostProcessDatacenter --
#     Post process method for Datacenter key
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       keyValue      - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - order in which the arguments will be passed to core api
#
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
#
########################################################################

sub PostProcessDatacenter
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;

   $result = $self->StoreSubComponentObjects(@_);

   if ($result eq FAILURE) {
      return FAILURE;
   }

   my $args = $self->{runtime}{arguments};
   $args    = $args->[0];
   foreach my $arguments (@$args) {
      if (defined $arguments->{host}) {
         my $hostObjArr = $arguments->{host};
         foreach my $hostObj (@$hostObjArr) {
            if (defined $hostObj) {
               $result = $self->{testbed}->SetComponentObject($hostObj->{objID},$hostObj);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Failed to update the testbed hash.");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            }
         }
      }
   }

   return SUCCESS;
}


#######################################################################
#
# ProcessParameters --
#      This method will replace tuples with objects
#
# Input:
#      input : four possible values - string, tuple, array reference
#              or hash reference
#
# Results:
#      tuples replaced with objects is returned
#
# Side effects:
#
#########################################################################

sub ProcessParameters
{
   my $self = shift;
   my $input = shift;
   my $testObject = shift;

   if ((ref($input) ne "ARRAY") && (ref($input) ne "HASH")) {
      return $self->ReplaceWithValues($input);
   }

   if (ref($input) eq "ARRAY") {
      my $arrayDuplicate = dclone $input;
      foreach my $arrayElement (@$arrayDuplicate) {
         my $value = $self->RecurseResolveTuple($arrayElement);
         if (FAILURE eq $value) {
            $vdLogger->Error("Failed to resolve array element");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      return $arrayDuplicate;
   } elsif (ref($input) eq "HASH") {
      my $hashDuplicate = dclone $input;
      my $result = $self->RecurseResolveTuple($hashDuplicate);
      if (FAILURE eq $result) {
         $vdLogger->Error("Failed to resolve hash value");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return $hashDuplicate;
   }
}


#######################################################################
#
# RecurseResolveTuple --
#      This method recurses through the data structure where tuples
#      are to be replaced with objects.
#
# Input:
#      input : four possible values - string, tuple, array
#              reference or hash reference
#
# Results:
#      tuples replaced with objects is returned
#
# Side effects:
#
########################################################################

sub RecurseResolveTuple
{
   my $self = shift;
   my $param = shift;
   my $payload;
   my $result;

   if (ref($param) eq "HASH") {
      foreach my $key (keys %$param) {
         if (ref($param->{$key}) eq "HASH") {
            $result = $self->RecurseResolveTuple($param->{$key});
            if (FAILURE eq $result) {
                return FAILURE;
            }
            $param->{$key} = $result;
         } elsif (ref($param->{$key}) eq "ARRAY") {
            my @inputArray = ();
            foreach my $arrayElement (@{$param->{$key}}) {
               if ($arrayElement =~ m/\.\[/i) {
                  $vdLogger->Debug("vdnet index is : $arrayElement");
                  my $refArray = $self->GetMultipleComponentObjects($arrayElement);
                  if (FAILURE eq $refArray) {
                     return FAILURE;
                  }
                  push @inputArray, @$refArray;
               } else {
                  $vdLogger->Debug("ArrayElement is string : " .
                                   Dumper($arrayElement));
                  $result = $self->RecurseResolveTuple($arrayElement);
                  if (FAILURE eq $result) {
                     return FAILURE;
                  }
                  push @inputArray, $result;
               }
            }
            $param->{$key} = \@inputArray;
         } else {
            $result = $self->ReplaceWithValues($param->{$key});
            if (FAILURE eq $result) {
               return FAILURE;
            }
            $param->{$key} = $result;
         }
         if (FAILURE eq $param->{$key}) {
            $vdLogger->Error("Parameter resolution failed for key '$key'");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   } elsif (ref($param) eq "ARRAY") {
      foreach my $element (@$param) {
         $self->RecurseResolveTuple($element);
         if (FAILURE eq $element) {
            $vdLogger->Error("Parameter resolution failed for array element");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   }
   if (FAILURE eq $param) {
      $vdLogger->Warn("Parameter is FAILURE");
   }
   return $param;
}

#######################################################################
#
# ReplaceWithValues --
#      This method checks if input is a tuple or not. If its a tuple,
#      the value gets replaced with a tuple.
#
# Input:
#      value : two possible values - string or tuple
#
# Results:
#      tuples replaced with objects if found
#
# Side effects:
#
########################################################################

sub ReplaceWithValues
{
   my $self = shift;
   my $value = shift;
   if ($value =~ m/\.\[/i) {
      my $componentObj  = $self->GetOneObjectFromOneTuple($value);
      return $componentObj;
   } else {
      return $value;
   }
}


########################################################################
#
#  PickRandomElementFromArray
#       This method does what the method name says if user gives an array
#       Else just returns the value as it is.
#       E.g. vlan => VDNetLib::Common::GlobalConfig::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
#
# Input:
#       value can be string or array
#       E.g. "lacp" will return lacp
#       ["lacp", "lacpv1", "lacpv2"] will pick any random value from this array
#
# Results:
#      Returns the same value or a random element from the array of values
#
# Side effetcs:
#       None
#
########################################################################

sub PickRandomElementFromArray
{
   my $self             = shift;
   my $value            = shift;
   return VDNetLib::Common::Utilities::PickRandomElementFromArray($value);
}


########################################################################
#
# InitializeUsingThreads --
#     A generic method for all initialization using threads.
#
# Input:
#     functionRef: reference to a Perl function/sub-routine;
#     component  : <vc/host/vm/vsm>
#     timeout    : max timeout to initialize one of the given component
#
# Results:
#     SUCCESS, if the given component is initialized successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializeUsingThreads
{
   my $self          = shift;
   my %args          = @_;
   my $functionRef   = $args{functionRef};
   my $functionArgs  = $args{functionArgs};
   my $component     = $args{component};
   my $timeout       = $args{timeout};
   @_ = ();

   my $testbedSpec  = $self->{'testbedSpec'};
   my $tasksObj = VDNetLib::Common::Tasks->new();
   my $decorator = sub { $self->WorkloadDecoratorForThreads(@_)};
   my @decoratorArgs = ($functionRef, $functionArgs);
   $tasksObj->QueueTask(functionRef  => $decorator,
                        functionArgs => \@decoratorArgs,
                        outputFile   => undef,
                        timeout      => $timeout);
   if (FAILURE eq $tasksObj->RunScheduler()) {
      $vdLogger->Error("Failed to run scheduler to initialize $component");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
#  ConvertTuplesToObjects --
#     Method to be executed for converting array of tuples into
#     array of objects
#
#  Input:
#
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Array of values
#
#  Results:
#       Reference to array of objects
#
#  Side effects:
#     None
#
#########################################################################

sub ConvertTuplesToObjects
{
   my $self = shift;
   my $testObj = shift;
   my $keyName = shift;
   my $keyValue = shift;
   my @arrayOfNodes;

   foreach my $node (@$keyValue) {
      my $result= $self->GetComponentObjects($node);
      if($result eq FAILURE) {
         $vdLogger->Error("Testbed and/or workload not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push @arrayOfNodes,  @$result;
   }
   my @returnReference;
   push @returnReference, \@arrayOfNodes;
   return \@returnReference;
}


########################################################################
#
#  ConvertParamTuplesToObjects --
#     Method to be executed for converting array of tuples into
#     array of objects. Also this method extracts the class hierarchy
#     from the given tuple
#
#  Input:
#
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Array of values
#
#  Results:
#       Reference to array of objects
#
#  Side effects:
#     None
#
########################################################################

sub ConvertParamTuplesToObjects
{
   my $self = shift;
   my $testObj = shift;
   my $keyName = shift;
   my $keyValue = shift;
   my @arrayOfNodes;
   my @temp = split('\.', $keyValue);

   my $inventoryTuple = $temp[0] . '.' . $temp[1];
   my $result= $self->GetComponentObjects($inventoryTuple);
   if ($result eq FAILURE) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # remove first 2 elements.
   splice @temp, 0, 2;

   # copy all odd elements from @temp.
   my @hierarchyElements = map { $temp[$_*2] } 0..int(@temp/2)-1;

   my $allKeys = join('/',@hierarchyElements);

   my @retArray;
   push @retArray, $result;
   push @retArray, $allKeys;

   return \@retArray;
}

########################################################################
#
# PreProcessUpdateSubComponent --
#     Method to pre-process input for updating sub components
#
# Input:
#     Same as pre-process template
#
# Results:
#     same as pre-process template
#
# Side effects:
#     None
#
########################################################################

sub PreProcessUpdateSubComponent
{
   my $self       = shift;
   my $testObject = shift;
   my $keyName    = shift;
   my $keyValue   = shift;
   my $paramValue = shift;
   my $paramList  = shift;

   return [$keyName, $self->ProcessParameters($keyValue)];
}


########################################################################
#
# PreProcessVerifyArpEntry --
#     Method to process user spec data parameters
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method PreProcessVerifyArpEntryOnController.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyArpEntry
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            my $netAdapterIpObj  = $entry->{ip};
            my $netAdapterMacObj = $entry->{mac};
            my $netAdapterIP = $netAdapterIpObj->GetIPv4();
            $entry->{ip} = $netAdapterIP;
            my $netAdapterMac = $netAdapterMacObj->{macAddress};
            if ($netAdapterMac eq undef or $netAdapterMac eq '') {
               if ($netAdapterIpObj->can('get_mac')) {
                  $netAdapterMac = $netAdapterIpObj->get_mac();
               }
            }
            $entry->{mac} = uc($netAdapterMac);
         }
         $vdLogger->Debug("Data after processing user input " . Dumper($userProcessedData));
         $userData = $userProcessedData;
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}

########################################################################
#
# SetWorkloadName --
#     Method to set the name attribute of workload Object
#
# Input:
#     workloadName: Set the name attribute of workload Object
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub SetWorkloadName
{
   my $self         = shift;
   my $workloadName = shift;
   $self->{name} = $workloadName;
}


########################################################################
#
# PreProcessVerifySameDataAllObjects--
#     Method to preprocess the attributes of Ipset endpoint
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifySameDataAllObjects
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my $keysDatabase = $self->{keysdatabase};
   my $keysDatabaseMethod = $keysDatabase->{$keyName}{method};

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData = {};
      if ($parameter eq $keyName) {
         foreach my $key (keys %$keyValue) {
            if (ref($keyValue->{$key}) =~ /ARRAY/) {
               my $arrayRef = $keyValue->{$key};
               foreach my $element (@$arrayRef){
                  #
                  # If the key is a tuple
                  #
                  if ($element =~ m/\w+\.\[\d+\]/i) {
                     my $verifyTestObj = $self->GetOneObjectFromOneTuple($element);
                     if ($verifyTestObj eq FAILURE) {
                        $vdLogger->Error("Tuple has not been passed in the ".
                           "required tuple format : inventory.[#].component.[#] or the ".
                           "object does not exist");
                        VDSetLastError("ENOTDEF");
                        return FAILURE;
                     }
                     my $userDataFromAPI = $verifyTestObj->$keysDatabaseMethod;
                     push(@{$userData->{$key}}, $userDataFromAPI->{$key});
                  } else {
                     push(@{$userData->{$key}},$element);
                  }
               }
            } else {
               if ($keyValue->{$key} =~ m/\w+\.\[\d+\]/i) {
                  my $verifyTestObj = $self->GetOneObjectFromOneTuple($keyValue->{$key});
                  if ($verifyTestObj eq FAILURE) {
                     $vdLogger->Error("Tuple has not been passed in the ".
                        "required tuple format : inventory.[#].component.[#] or the ".
                        "object does not exist");
                     VDSetLastError("ENOTDEF");
                     return FAILURE;
                  }
                  my $userDataFromAPI = $verifyTestObj->$keysDatabaseMethod;
                  $userData->{$key} = $userDataFromAPI->{$key};
               } else {
                  $userData->{$key} = $keyValue->{$key};
               }
            }
         }
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}


########################################################################
#
# CompareWorkloadResult--
#     Method to compare the workload result with expectedresult and
#     decide the final result
#
# Input:
#     expectedResult : User input expected result
#     actualResult   : Actual workload result
#     workload   : workload name
#
# Results:
#     returns result hash of expected,actual,final result and
#     description
#
# Side effects:
#     None
#
########################################################################

sub CompareWorkloadResult
{
   my $self = shift;
   my ($expectedResult,$actualResult,$workload) = @_;
   my $workloadEndMessage;
   my $finalResult;

   if (ref($expectedResult) =~ /HASH/i) {
      return $self->CompareWorkloadResultHash($expectedResult,
                                              $actualResult,
                                              $workload);

   }

   if ($actualResult =~ /skip/i) {
      $finalResult = SKIP;
   } elsif ($expectedResult =~ /$actualResult/i) {
      $workloadEndMessage = "Result:$actualResult of workload $workload " .
         "matches the expected result: " .$expectedResult;
      $finalResult = PASS;
   } elsif ($expectedResult =~ /ignore/i)  {
      $workloadEndMessage = "Result:$actualResult of workload $workload " .
         "IGNORED since the expected result is : " .$expectedResult;
      $finalResult = PASS;
   } else {
      $workloadEndMessage = "Result:$actualResult of workload $workload " .
         "NOT matching the expected result: " .$expectedResult;
      $finalResult = FAIL;
   }
   $vdLogger->Debug($workloadEndMessage);

   my $result = {
      'expectedResult' => $expectedResult,
      'result' => $actualResult,
      'finalResult' => $finalResult,
      'workloadEndMessage' => $workloadEndMessage,
   };
   return $result;
}


########################################################################
#
# CompareWorkloadResultHash--
#     Method to compare the workload result hash with expectedresult and
#     decide the final result
#
# Input:
#     expectedResult : User input expected result hash
#     actualResult   : Actual workload result hash
#     workload   : workload name
#
# Results:
#     returns result hash of expected,actual,final result and
#     description
#
# Side effects:
#     None
#
########################################################################

sub CompareWorkloadResultHash
{
    my $self = shift;
    my ($expectedResult,$actualResult,$workload) = @_;
    my $notMatched='';
    my $workloadEndMessage;
    my $finalResult = PASS;
    $actualResult = VDGetAllErrors();
    my $compareObj = VDNetLib::Common::Compare->new();

    # TODO(James S)expectedResult->{status_code} can only
    # accept scalar values.

    # Using 'contains' verification module
    # to check if expected result is part of all the results
    my @expectedResultArray;
    push @expectedResultArray, $expectedResult;
    $vdLogger->Debug("Start comparing the input provided in ExpectedResult" .
                     "and the entire vdnet stack trace using contains" .
                     "operator");
    my $testResult = $compareObj->CompareDataStructures(\@expectedResultArray,
                                                        $actualResult,
                                                        'contains');
    if ($testResult eq FAILURE) {
        $finalResult = FAIL;
        $workloadEndMessage = "$finalResult: Actual did NOT match Expected" .
            " for WORKLOAD $workload: " .
            " expected=". Dumper($expectedResult) .
            " actual=" . Dumper($actualResult);
        $vdLogger->Error($workloadEndMessage);
    } else {
        $workloadEndMessage = "$finalResult: Actual matched Expected" .
            " for WORKLOAD $workload: " .
            " expected=". Dumper($expectedResult) .
            " actual=" . Dumper($actualResult);
        $vdLogger->Debug($workloadEndMessage);
    }

    # Serializing the hash to string PR 1340333.
    my $result = {
      'expectedResult' => Dumper($expectedResult),
      'result' => Dumper($actualResult),
      'finalResult' => $finalResult,
      'workloadEndMessage' => $workloadEndMessage,
    };
    return $result;
}

# alias to PreProcessNSXSubComponent
sub PreProcessSubComponentsInPython
{
   return PreProcessNSXSubComponent(@_);
}

# PreProcessNSXSubComponent returns key name, spec array, class name and
# additional parameters, but Autoload function only takes spec array.
# This function selectively returns only processed spec array and additional
# parameters in a single hash i.e. element 1 and 3 of array returned by
# PreProcessNSXSubComponent method.
sub PreProcessReturnSpecForAutoload
{
   my (@retArray);
   my $processedArray = PreProcessNSXSubComponent(@_);
   if ($processedArray eq FAILURE) {
      return FAILURE;
   }
   my %retHash = ('schema' => $processedArray->[1],
                  'additional_params' => $processedArray->[3]);
   push(@retArray, \%retHash);
   return \@retArray;
}

########################################################################
#
# GetComponentAttribute--
#     Method to get the value of a component's attribute.
#     The format of the key is:
#     <payload_key>: <component_index>-><attribute_name>
#     For example:
#     external_id: 'esx.[1]->id'
#     In this case, the 'id' of esx.[1] will be passed
#     as value for external_id
#
#
# Input:
#     attributeValue : Values of the params in the test hash
#     testObj        : Testbed object being used here
#     attributeKey   : Name of the key being worked upon here
#
#        Example:
#           external_id: 'esx.[1]->id'
#              attributeValue is 'esx.[1]->id'
#              attributeKey is 'id'
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub GetComponentAttribute
{
   my $self           = shift;
   my $attributeValue = shift;
   my $testObj        = shift;
   my $attributeKey   = shift;
   my $keysDatabase = $self->{keysdatabase};

   if ($attributeValue =~ m/\.\[/i) {

      #
      # Check if the value of the attribute/parameter key
      # has pointer to attribute different than attributeKey,
      # if yes, then use that key. This is required to keep
      # parameters passed in test yaml to be explicit and also
      # helps in negative testing. For, example, if the payload
      # takes a parameter, say, thumbprint, then user might want
      # to pass certificate to go negative testing.
      # '->' operator is already well used in verification and
      # passing data between workloads.
      #
      my @temp = split('->', $attributeValue);
      my $componentIndex = $temp[0];
      my $k = $attributeKey || 'UNDEF';
      my $v = $attributeValue || 'UNDEF';
      $attributeKey = (defined $temp[1]) ? $temp[1] : $attributeKey;
      if (not exists $keysDatabase->{$attributeKey}) {
          $vdLogger->Error("Key *$k* not part of keys database, " .
                           "used as $k: $v");
          $vdLogger->Error("Please add *$attributeKey* to keysdb at the " .
                           "right location");
      }
      my $componentObjects = $self->GetComponentObjects($componentIndex);
      if ((not defined $componentObjects) || ($componentObjects eq FAILURE)) {
        $vdLogger->Error("Unable to resolve tuple: $componentIndex");
        VDSetLastError("EINVALID");
        return FAILURE;
      }
      if (scalar(@$componentObjects) > 1) {
         $vdLogger->Error("Multiple objects are not supported: $componentIndex");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $perlObj = $componentObjects->[0];
      if ((not defined $perlObj) || ($perlObj eq FAILURE)) {
          $vdLogger->Error("Unable to resolve tuple: $componentIndex");
          VDSetLastError("EINVALID");
          return FAILURE;
      }
      # FIXME(Prabuddh): When Bug 1363576 is resolved this handling of getters
      # for perl object needs to be made more robust and foolproof
      my $perlMethod = "Get" . "$attributeKey";

      if (eval{$perlObj->can($perlMethod)}) {
          $vdLogger->Debug("Calling perl method: $perlMethod on $perlObj");
          return $perlObj->$perlMethod();
      }
      return VDNetLib::Workloads::Utilities::GetAttrFromPyObject(
          $componentIndex, $componentObjects, $attributeKey);
   } else {
      return $self->ProcessParameters($attributeValue, $testObj);
   }
}

########################################################################
#
# GetMultipleComponentAttributeFromArray--
#     Method to get the value of a component's attribute from array.
#     The format of the key is:
#     <payload_key>:
#            - <component_index>-><attribute_name>
#
#     For example:
#         ipaddresses:
#              - 'nsxedge.[1]->management_ip'
#
#     In this case, the 'management_ip' of nsxedge.[1] will be passed
#     as list to ipaddresses
#
# Input:
#     attributeValue : Values of the params in the test hash
#     testObj        : Testbed object being used here
#     attributeKey   : Name of the key being worked upon here
#
#        Example:
#         ipaddresses:
#              - 'nsxedge.[1]->management_ip'
#
#         attributeValue is   nsxedge.[1]->management_ip'
#         attributeKey is 'ipaddresses'
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub GetMultipleComponentAttributeFromArray
{
   my $self           = shift;
   my $attributeValue = shift;
   my $testObj        = shift;
   my $attributeKey   = shift;

   my @listOfValues;
   if (not defined $attributeValue) {
      $vdLogger->Error("AttributeValue not defined : " . Dumper($attributeValue));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   foreach my $value (@$attributeValue) {
      my $returnValue = $self->GetComponentAttribute($value, $testObj, $attributeKey);
      if ($returnValue eq FAILURE) {
         $vdLogger->Error("$value not available");
         VDGetLastError("EINVALID");
         return FAILURE;
      }
      push(@listOfValues, $returnValue);
   }
   return \@listOfValues;
}

########################################################################
#
# PreProcessNestedParameters--
#     Method to preprocess nested spec including values that contain
#     vdnet index
#
# Input:
#     spec       : Values of the params in the test hash
#     testObj    : Testbed object being used here
#     param      : Name of the key being worked upon here
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error, or a key is not part of KEYSDATABASE
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNestedParameters
{
   my $self       = shift;
   my $spec       = shift;
   my $testObj    = shift;
   my $param      = shift;
   my $componentIndex = shift;
   my $component      = shift;
   my $keysDatabase = shift || $self->GetKeysTable();
   my $result;
   my $finalResult;

   if (ref($spec) =~ /HASH/) {
      $vdLogger->Debug("Iterating through hash " . Dumper($spec));
      foreach my $key (keys %$spec) {
         if (not exists $keysDatabase->{$key}) {
             $vdLogger->Error("Key *$key* not part of keys database");
             VDSetLastError("EKEYSDB");
             return FAILURE;
         } elsif (ref($spec->{$key}) =~ /HASH/) {
            my $result = $self->PreProcessNestedParameters(
                  $spec->{$key}, $testObj, $key, $componentIndex, $component,
                  $keysDatabase);
            if ($result eq FAILURE) {
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }
            $spec->{$key} = $result;
         } elsif ($spec->{$key} =~ PERSIST_DATA_REGEX) {
            my $subvdnet_index;
            my $value = $spec->{$key};
            # if $spec->{$key} is ->\w.*->.+\+\-\>\w.*, such as
            # my $str='nsxmanager.[1]->read_nexthop_gateway->gateway+->get_ip_route->nexthop';
            # it means we want nsxmanager.[1].nsxedge.[1]->get_ip_route->nexthop
            # and in turn the value of the next hop like '192.168.70.100'.
            # So for above str, the final result will be '192.168.70.100'
            if ($value =~ m/(.*\-\>\w.*\-\>.+)\+(\-\>\w.*)/) {
               $value = $1;
               $subvdnet_index = $2;
               $spec->{$key} = $value;
            }

            $vdLogger->Debug("Start to fetch the runtime data for $spec->{$key}");
            my $result = VDNetLib::Workloads::Utilities::GetAttributes(
                  $self, $spec->{$key}, $key);

            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to get the saved runtime data for $spec->{$key}");
               VDSetLastError("EREADRUNTIME");
               return FAILURE;
            } else {
               $value = $result;
               $vdLogger->Info("Resolved vdnet index from  persist data $value");
            }
            if (defined $subvdnet_index) {
               $value = "$value$subvdnet_index";
               my $hash_ref = {};
               $hash_ref->{'testkey'} = $value;
               $result = VDNetLib::Workloads::Utilities::GetAttributes($self,
                                                                       $value,
                                                                       'testkey');
             }
            $spec->{$key} = $result;
         } elsif (defined $keysDatabase->{$key}{method}) {
            my $method = $keysDatabase->{$key}{method};
            my $result = $self->$method(
                  $spec->{$key}, $testObj, $key, $componentIndex, $component);
            $vdLogger->Debug("Running method $method on Parameter key $key returned $result");
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to set Parameter of $key using $method");
               VDSetLastError("EKEYSDBMETHODFAILED");
               return FAILURE;
            }
            $spec->{$key} = $result;
         }
         # else case no change in the value of $spec->{$key};
      }
      $finalResult = $spec;
   } elsif (ref($spec) =~ /ARRAY/) {
      my @arrayFormat;
      foreach my $element (@$spec) {
         my $result;
         $vdLogger->Debug("Iterating through array");
         if ((ref($element) =~ /HASH/) ||
             (ref($element) =~ /ARRAY/)) {
            $result = $self->PreProcessNestedParameters(
                  $element, $testObj, $param, $componentIndex, $component,
                  $keysDatabase);
            if ($result eq FAILURE) {
                $vdLogger->Error("Failed to PreProcessNestedParameters for " .
                                 Dumper($element) . " of spec " . Dumper($spec));
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }
            if ((ref($result) =~ /HASH/) || (ref($result) =~ /ARRAY/)) {
                $result = dclone $result;
            }
         } else {
            $vdLogger->Debug("Element is simple string, returning: $element");
            $result = $element;
         }
         push @arrayFormat, $result;
      }
      $finalResult = \@arrayFormat;
   } else  {
     $vdLogger->Debug("Not pre-processing non hash/arrary formats of spec: " .
                      Dumper($spec));
     $finalResult = $spec;
   }

   return $finalResult;
}

#######################################################################
#
# PreProcessNestedParametersForAction
#    Wrapper method for PreProcessNestedParameters()
#    This is being done because the method signature of Action methods
#    is different from the method signature of parameter keys
#    e.g. For Action:
#       Method($testObject, $keyName, $keyValue, $paramValues, $paramList)
#    e.g. For Parameter:
#       Method($keyValue, $testObject, $keyName)
#
# Input:
#     testObject - An object, whose core api will be executed
#     keyName    - Name of the action key
##    keyValue  -  Reference to hash/spec that contains NIOC
#                  configuration details
#
# Results:
##     Reference to
#
# Side effects:
#
########################################################################

sub PreProcessNestedParametersForAction
{
   my $self              = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array;
   my $result = $self->PreProcessNestedParameters($keyValue, $testObject, $keyName);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to run PreProcessNestedParameters " .
                       "for action key $keyName.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   push @array, $result;
   return \@array;
}


########################################################################
#
# ProcessUUID --
#     Method to process instanceuuid key in VM spec.
#     If 'auto' is given as value for instanceuuid, then this
#     method returns auto-generated uuid
#
# Input:
#     uuid: auto or any specific uuid
#
# Results:
#     if 'auto' is given as input, then a random generated uuid
#     is returned;
#     Otherwise, same input value is returned as it is.
#
# Side effects:
#     None
#
########################################################################

sub ProcessUUID
{
   my $self = shift;
   my $uuid = shift;

   if ($uuid =~ /auto/) {
      LoadInlineJavaClass('java.util.UUID');
      $uuid = VDNetLib::InlineJava::VDNetInterface::java::util::UUID->randomUUID();
      $uuid = $uuid->toString();
   } else {
      $uuid =~ s/:/-/g;
      return $uuid;
   }
}


########################################################################
#
# ProcessResourceParameter --
#     Method to process 'resource' key. This method finds resource
#     from buildweb if the elements of resource contain tuple
#     <product>:<branch>:<build_type>:<official|sandbox>:<filePattern>
#
# Input:
#     resource: reference to an array where each element is
#               absolute path to a file or tuple
#
# Results:
#     updated resource which is reference to array
#
########################################################################

sub ProcessResourceParameter
{
   my $self = shift;
   my $resource = shift;

   if (not defined $resource) {
      $vdLogger->Error("Resource not defined to process");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Load the build_utilities python module
   LoadInlinePythonModule("build_utilities");
   my $index = 0;
   foreach my $item (@$resource) {
      if (($item =~ /\//) or ($item !~ m/:/)) {
         # if the file is absolute an absolute path, then no need to process
         # or if the file is not seperated by ':', it is a package name also no
         # need to process
         $index++;
         next;
      } else {
         my $build = py_call_function("build_utilities",
                                      "get_build_from_tuple",
                                      $item);
         if ((not defined $build) || ($build eq "")) {
            $vdLogger->Error("Could not find build for the given resource " .
                             $item);
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $vdLogger->Debug("Found $build for given resource $item");

         my @temp = split(":", $item);
         my $deliverable = py_call_function("build_utilities",
                                            "get_build_deliverable_url",
                                            $build, $temp[-1]);
         if ((not defined $deliverable) || ($deliverable eq "")) {
            $vdLogger->Error("Could not find deliverable URL for the " .
                             "given resource " . $item);
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }

         $vdLogger->Debug("Found $deliverable for given resource $item");
         $resource->[$index] = $deliverable;
      }
      $index++;
   }
   $vdLogger->Info("Updated resource list: " . Dumper($resource));
   return $resource;
}


########################################################################
#
# WorkloadDecoratorForThreads --
#     This method transforms (similar to decorators in Python)
#     the given function. The usage is specifically for threads
#     which requires zookeeper and inline JVM connections to be
#     re-established.
#
# Input:
#     functionRef : reference to a function to be executed
#     args        : reference to an array of arguments
#
# Results:
#     return value of the given function
#
# Side effects:
#     None
#
########################################################################

sub WorkloadDecoratorForThreads
{
   my $self        = shift;
   my $functionRef = shift;
   my $args        = shift;
   my $result = FAILURE;
   @_ = ();
   my $zkh;
   if ($ENV{VDNET_WORKLOAD_THREADS}) {
      STDOUT->autoflush(1);
      if (FAILURE eq $self->{testbed}->UpdateZooKeeperHandle()) {
         $vdLogger->Error("Failed to update zookeeper handle");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      VDNetLib::InlineJava::VDNetInterface->ReconnectJVM();
   }

   eval {
      $result = &$functionRef(@$args);
   };
   if ($@) {
      $vdLogger->Error("Exception thown while calling thread callback function with " .
                       "return value $result for " . Dumper($functionRef) .
                       " with $args Exception details:" . $@);
   }
   #
   # error check should be done by caller, since this is generic code
   # and the return value can be different depending on the method
   # being called.
   #
   if ($ENV{VDNET_WORKLOAD_THREADS}) {
      $self->{testbed}->{zookeeperObj}->CloseSession($self->{testbed}->{zkHandle});
      if ($result eq FAILURE) {
         $vdLogger->Debug("Stack from thread:" . VDGetLastError());
         VDCleanErrorStack();
         return FAILURE;
      }
   }
   return $result;
}


########################################################################
#
# RunWorkloadsUsingThreads ---
#     A generic method for running workloads using threads.
#
# Input:
#     functionRef: reference to a Perl function/sub-routine;
#     arrayTuples : workload set in vdnet sequence
#     timeout    : max timeout to initialize one of the given component
#
# Results:
#     SUCCESS, if the given component is initialized successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunWorkloadsUsingThreads
{
   my $self          = shift;
   my $functionRef   = shift;
   my $arrayTuples   = shift;
   my $timeout       = shift;
   my $clonedWorkload= shift;
   my $verificationStyle= shift;
   my $persistData   = shift;
   my $testbedSpec   = $self->{testbed}->{'testbedSpec'};
   @_ = ();

   # Close the handle in parent process before creating new thread
   $self->{testbed}->{zookeeperObj}->CloseSession($self->{testbed}->{zkHandle});

   my $tasksObj = VDNetLib::Common::Tasks->new();
   my $result = FAILURE;
   my $queuedTasks = 0;
   foreach my $testKey (@$arrayTuples) {
      $testKey =~ s/\:/\./g;
      my $decorator = sub {
                         $self->SetComponentIndex($testKey);
                         $self->WorkloadDecoratorForThreads(@_)
                      };
      my @args = ($clonedWorkload, $testKey, $verificationStyle, $persistData);
      my @decoratorArgs = ($functionRef, \@args);
      # Use name of workload as taskId
      my $taskId = $testKey;
      $tasksObj->QueueTask(functionRef  => $decorator,
                           functionArgs => \@decoratorArgs,
                           outputFile   => "/tmp/parent",
                           taskId       => $taskId,
                           timeout      => $timeout);
      $self->{result}{$taskId}{exitCode} = undef;
      $queuedTasks++;
   }
   my $completedThreads = $tasksObj->RunScheduler();
   if ($completedThreads eq FAILURE) {
      $vdLogger->Error("Failed to run scheduler for workloads");
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   } elsif ($completedThreads != $queuedTasks) {
      $vdLogger->Error("For workload, number of queued tasks $queuedTasks" .
                       " is not equal to completed tasks $completedThreads");
      VDNetLib::Common::Utilities::CollectMemoryInfo();
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
   } else {
      $result = SUCCESS;
   }
   return $result;
}

########################################################################
#
# PreProcessDeleteListOfComponents --
#     Method to pre-process input for DeleteComponent method
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value(Tuple) assigned to action key in config hash
#
# Results:
#     Return reference to array of objects and parameter values
#
# Side effects:
#     None
#
########################################################################

sub PreProcessDeleteListOfComponents
{
   my $self        = shift;
   my $testObject  = shift;
   my $keyName     = shift;
   my $keyValue    = shift;
   my $paramValues = shift;
   my $paramList  = shift;
   my $componentTuple;

   my @arguments = ();
   my @refArrayOfAllObjects = ();
   my $inventoryID = $self->{'componentIndex'};
   foreach my $componentName (@$keyValue) {
     $componentTuple = $inventoryID.".".$componentName.'.[-1]';
     my $refArrayOfObjects = $self->ConstructArrayOfObjects($testObject,
                                                            $keyName,
                                                            $componentTuple,
                                                            $paramValues,
                                                            $paramList);

     if ($refArrayOfObjects eq FAILURE) {
        $vdLogger->Error("Unable to construct array of objects for $componentTuple");
        VDSetLastError("EOPFAILED");
        return FAILURE;
     }
     foreach my $componentArray (@$refArrayOfObjects)  {
        if (scalar(@$componentArray)) {
           foreach my $refObject (@$componentArray) {
              push (@refArrayOfAllObjects, $refObject);
           }
        }
     }
   }
   push (@arguments, \@refArrayOfAllObjects);
   my $additionalParams = $paramValues;
   if (defined $additionalParams->{$keyName}) {
      delete $additionalParams->{$keyName};
   }
   push (@arguments, $additionalParams);
   return \@arguments;
}


########################################################################
#
# CheckExpectedResult --
#     Method to check expected result for workload Object. If expectedresult
#     is a string, then check if it is in permitted values (PASS/FAIL/IGNORE)
#     If it is hash or other structure, directly return SUCCESS
#
# Input:
#     None
#
# Results:
#     SUCCESS, if pass to check
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CheckExpectedResult
{
   my $self         = shift;
   my $inputResult = $self->{expectedresult};
   my @permitted = ("FAIL","PASS","IGNORE");

   # If expectedresult not specified, return SUCCESS
   if (not defined $inputResult) {
      return SUCCESS;
   }

   if ((ref($inputResult) eq "ARRAY") || (ref($inputResult) eq "HASH")) {
      $vdLogger->Debug("Workload expectedresult is not a scalar");
      return SUCCESS;
   }
   if (grep {$_ eq uc($inputResult)} @permitted) {
      # If in permitted values, change $self->{expectedresult} to upper case
      $self->{expectedresult} = uc($inputResult);
      $vdLogger->Debug("Workload expectedresult is set to " .
                       $self->{expectedresult});
      return SUCCESS;
   }

   $vdLogger->Error("Workload expectedresult should be PASS/FAIL/IGNORE" .
                    ",now received $inputResult");
   return FAILURE;
}


########################################################################
#
# PersistTestData --
#     Method to persist user specified test data under the folder
#     <component index>/runtime/<key>/<key>.
#     e.g. /testbed/vm/1/vnic/1/runtime/<key_name>/<key_name>.
#     The value gets overriden with the last used value if the same key is
#     used with the same component index.
#
# Input:
#       testObject - The current Testobject
#       keyName    - Name of the action key
#       $testdata -  reference to array of data to be persisted
#
# Results:
#     SUCCESS, if test data is successfully stored;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub PersistTestData
{
   my $self = shift;
   my ($testObject, $keyName, $testdata) = @_;

   my $compindex = undef;
   if (defined $self->{componentIndex}) {
      $compindex = $self->{componentIndex};
   } else {
      $vdLogger->Error("Unable to find the component index of the test object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Persisting user specified test data for $compindex");
   my $verif_value = undef;
   my $attrib_value_hash = undef;
   my $result = undef;
   my @listoftestdata;
   if (ref($testdata) =~ /HASH/) {
      push(@listoftestdata, $testdata);
   } elsif (ref($testdata) =~ /ARRAY/) {
      @listoftestdata = @{$testdata};
   } else {
      $vdLogger->Error("Scalar test data will not be persisted for $compindex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $verif_hash (@listoftestdata) {
      foreach my $verif_key (keys %{$verif_hash}) {
         $verif_value = $verif_hash->{$verif_key};
         $attrib_value_hash = {$verif_key => $verif_value};
         $result = $self->{testbed}->SetRuntimeStatsValue($compindex,
                                                          $verif_key,
                                                          $verif_key,
                                                          $attrib_value_hash);
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to set runtime statistics for $compindex" .
                             "Encountered problem with key $verif_key");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# ComparePersistedTestData --
#     Method to compare persisted user specified test data with the one
#       stored in the zookeeper folder under:
#     <component index>/runtime/<key>/<key>.
#     e.g. /testbed/vm/1/vnic/1/runtime/<key_name>/<key_name>.
#
#     Note: This method has very limited utility as it is meant to be
#        used for preprocessing the user data provided to
#        'get_test_data' verification key. Ideally, each component
#        should have access to its data (including one stored in ZK)
#        but in the current design, only workload layer can access the
#        data stored in ZK for a given component and this data can be
#        accessed via preprocess or postprocess methods which reside
#        in the workload layer. Hence without the ability to access the
#        component's ZK data in the component layer, this preprocess
#        method is being used as a workaround to compare the user
#        provided/expected data with that fetched from the ZK.
#        XXX(salmanm): Also note that this method is only comparing the
#           data for equality, other comparison operators are not
#           supported.
#
# Input:
#       testObject - The current Testobject
#       keyName - Name of the action key
#       expectedData - Expected data hash (user provided input).
#
# Results:
#     When the comparison succeeds, the data fetched from the Zookeeper
#        is returned.
#     FAILURE is returned in case it doesn't or if an error is met.
#
# Side effects:
#     None
#
########################################################################

sub ComparePersistedTestData
{
   my $self = shift;
   my ($testObject, $keyName, $expectedData) = @_;
   my $componentIndex = undef;
   if (defined $self->{componentIndex}) {
      $componentIndex = $self->{componentIndex};
   } else {
      $vdLogger->Error("Component index of the test object is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $self->{runtime}{parameters}{$keyName}) {
       $vdLogger->Error("Parameters are not passed to key: $keyName");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $verificationHash = $self->{runtime}{parameters}{$keyName};
   if ((not defined ref($verificationHash)) || (ref($verificationHash) ne 'HASH')) {
      $vdLogger->Error("Expected hash, got:\n" . Dumper($verificationHash));
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Convert the tuple to ZK Path.
   my $zkNodePath = VDNetLib::Testbed::Utilities::ConvertVdnetIndexToPath(
        $componentIndex);
   my $componentPath = "$self->{testbed}{zkSessionNode}/$zkNodePath";
   my @keysToFetchFromZK = keys(%$verificationHash);
   my $fetchedData = $self->GetPersistedTestData(
        $componentPath, \@keysToFetchFromZK);
   if ($fetchedData eq FAILURE) {
      $vdLogger->Error("Failed to get the persisted test data for: " .
                       "$componentIndex, for one of the keys in:\n" .
                       Dumper(@keysToFetchFromZK));
      return FAILURE;
   }
   my $ret = $self->VerifySimpleSpec($fetchedData,
                                     $expectedData,
                                     'equal_to');
   if ($ret eq FAILURE) {
      $vdLogger->Error("Verification process failed");
      VDSetLastError("EOPFAIL");
      return FAILURE;
   }
   my @ret = ($fetchedData);
   return \@ret;
}


########################################################################
#
# GetPersistedTestData --
#     Method to fetch user specified test data under the folder
#       <component index>/runtime/<key>/<key>.
#       e.g. /testbed/vm/1/vnic/1/runtime/<key_name>/<key_name>.
# Input:
#       zKComponentPath - Component path for the particular component
#           e.g. /testbed/vm/1/vnic/1
#       keys - Array Ref containing keys to be fetched from ZK.
#
# Results:
#     SUCCESS, if test data is successfully stored;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPersistedTestData
{
   my $self = shift;
   my $zKComponentPath = shift;
   my $keys = shift;
   if (not defined $keys || ref($keys) ne 'ARRAY') {
       $vdLogger->Error("Invalid keys provided for accessing ZK data: " .
                        Dumper($keys));
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $fetchedData = {};
   foreach my $key (@$keys) {
       # XXX(mbindal/salmanm): Improve how the test data is stored in ZK.
       # BZ #1414842
       my $testDataPath = "$zKComponentPath/runtime/$key/$key/1";
       my $result = $self->{testbed}->GetDataFromZooKeeperPath($testDataPath);
       if ($result == VDNetLib::Common::ZooKeeper::ZNONODE) {
          $vdLogger->Error("Failed to get the persisted test data for: " .
                           "key: $key, using ZK path: $testDataPath. " .
                           "That path does not exist in ZK!");
          return FAILURE;
       } elsif ($result eq FAILURE) {
          $vdLogger->Error("Failed to get the persisted test data for: " .
                           "key: $key, using ZK path: $testDataPath.");
          return FAILURE;
       }
       $fetchedData->{$key} = $result->{$key};
   }
   return $fetchedData;

}


########################################################################
#
# ReplaceObjectsWithVDNetIndex --
#       Method to replace perl obj with its ObjID
#
# Input:
#       objs - hash, array, etc, which includes perl objs.
#
# Results:
#     always return SUCCESS
#
# Side effects:
#     None
#
########################################################################

sub ReplaceObjectsWithVDNetIndex
{
   my $self = shift;
   my $objs = shift;

   if (ref($objs) eq "HASH") {
      foreach my $k (keys %$objs) {
         if (ref($objs->{$k}) eq "HASH") {
            $self->ReplaceObjectsWithVDNetIndex($objs->{$k});
         } elsif (ref($objs->{$k}) eq "ARRAY") {
            $self->ReplaceObjectsWithVDNetIndex($objs->{$k});
         } elsif (blessed($objs->{$k})) {
            $objs->{$k} = $objs->{$k}->{objID};
         }
      }
   } elsif (ref($objs) eq "ARRAY") {
      for my $i (0 .. $#{$objs}) {
         if (ref($objs->[$i]) eq "HASH") {
            $self->ReplaceObjectsWithVDNetIndex($objs->[$i]);
         } elsif (ref($objs->[$i]) eq "ARRAY") {
            $self->ReplaceObjectsWithVDNetIndex($objs->[$i]);
         } elsif (blessed($objs->[$i])) {
            $objs->[$i] = $objs->[$i]->{objID};
         }
      }
   } elsif (blessed($objs)) {
      $objs = $objs->{objID};
   }

   return SUCCESS;
}


########################################################################
#
# ResolveTuplesInSpaceSeparatedString --
#    Method to resolve tuples embedded within a space separated string.
#
# Example:
# input: "foo vm.[1].vnic.[1]->GetMACAddress bah srcaddr==vm.[1].vnic.[1]->GetIPv4"
# output: "foo 00:0C:29:F1:ED:7F bah srcaddr==192.168.101.178"
#
# Input:
#   $inputStr: Space separated string that can contain <tuple->method>
#
# Results:
#   $outputStr: Input string with resolved tuple values.
#
# Side effects:
#     None
#
########################################################################

sub ResolveTuplesInSpaceSeparatedString
{
   my $self = shift;
   my $inputStr = shift;
   my $delimiter = " ";
   return VDNetLib::Workloads::Utilities::ResolveTuplesInDelimitedString($self,
      $inputStr, $delimiter);
}

1;
