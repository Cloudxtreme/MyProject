########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::Utilities;

#
# This package has utility methods which
# can be consumed by all *Workloads.pm modules
#
use FindBin;
use lib "$FindBin::Bin/../";
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use Scalar::Util qw(blessed);
use Storable 'dclone';
use File::Copy;
use Scalar::Util qw(looks_like_number);
use constant ReplaceMethods => {
   'empty'     => "ReplaceWithNull",
   'condition' => "ReplaceWithCondition",
   'tuples'    => "ReplaceWithTuple",
   'values'    => "ReplaceWithValues",
   'merge'     => "MergeValuesWithDelimiter",
};


#######################################################################
#
# ProcessUserDataForVerification --
#      This method will replace tuples with objects
#
# Input:
#      workloadObj     : object of workload.
#      input           : complex datastructure
#      replacementType : default is values. Other possible values are
#                        empty, condition, tuples and merge. This value
#                        decided which method will be used to replace
#                        original values with new values.
#      helperHash      : [optional], to be sent only if replacementType is
#                        'merge'. This hash is merged with input.
#
# Results:
#      Return new input based on replacementType
#      Return FAILURE incase of any errors.
#
# Side effects:
#
########################################################################

sub ProcessUserDataForVerification
{
   my $workloadObj            = shift;
   my $input                  = shift;
   my $replacementType        = shift || "values";
   my $helperHash             = shift;

   if (ref($input) eq "ARRAY") {
      my @inputArray = ();
      my $count = 0;
      foreach my $arrayElement (@{$input}) {
         my $result = RecurseThroughDatastructure($workloadObj,
                                                  $arrayElement,
                                                  $replacementType,
                                                  $helperHash->[$count]);
         if ($result eq "FAILURE") {
            $vdLogger->Error("Failure in with replace methods");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         push(@inputArray, $result);
         $count++;
      }
      return \@inputArray;
   } elsif (ref($input) eq "HASH") {
      my $result = RecurseThroughDatastructure($workloadObj,
                                               $input,
                                               $replacementType,
                                               $helperHash);
      if ($result eq "FAILURE") {
         $vdLogger->Error("Failure in with replace methods");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return $input;
   } else {
      $vdLogger->Error("The input is neither hash nor array," .
                       "format not supported" . Dumper($input));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


#######################################################################
#
# RecurseThroughDatastructure --
#      This method recurses through the data structure and calls
#      appropriate replace methods based on the requirement.
#
# Input:
#      workloadObj     : object of workload.
#      input           : complex datastructure
#      replacementType : default is values. Other possible values are
#                        empty, condition, tuples and merge. This value
#                        decided which method will be used to replace
#                        original values with new values.
#      helperHash      : [optional], to be sent only if replacementType is
#                        'merge'. This hash is merged with input.
#
# Results:
#      Return new input based on replacementType
#      Return FAILURE incase of any errors.
#
# Side effects:
#
########################################################################

sub RecurseThroughDatastructure
{
   my $workloadObj     = shift;
   my $input           = shift;
   my $replacementType = shift;
   my $helperHash      = shift;
   my $payload;

  my $replaceMethodHash = GetReplaceMethods();

   if (ref($input) eq "HASH") {
      $vdLogger->Trace("Reference type of input is HASH");
      foreach my $key (keys %$input) {
         $vdLogger->Trace("Recursing for key $key");
         if ((ref($input->{$key}) eq "HASH")) {
            $vdLogger->Trace("Value is of type hash for key $key");
            my $result;
            my ($first_matching_key) = grep {lc($_) eq lc($key) || $_ =~ /^$key\[\?\]/i} keys %$helperHash;
            if ((defined $first_matching_key) &&
                (defined $helperHash->{$first_matching_key})) {
               $vdLogger->Debug("Merging input with helper hash for key $key");
               $result = RecurseThroughDatastructure($workloadObj,
                                           $input->{$key},
                                           $replacementType,
                                           $helperHash->{$first_matching_key});
               if ($result eq "FAILURE") {
                  $vdLogger->Error("Merging between input & helper " .
                                   "hash failed for hash structure");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            } else {
               $vdLogger->Trace("Performing $replacementType for key $key");
               $result = RecurseThroughDatastructure($workloadObj,
                                           $input->{$key},
                                           $replacementType);
               if ($result eq "FAILURE") {
                  $vdLogger->Error("Replacement operation failed for ".
                                   "replacementType = $replacementType");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            }
            # While traversing back, these operations need to be
            # performed based on $replacementType.
            $input = SubstitutionOfChildNodes($replacementType,
                                              $key,
                                              $input,
                                              $result,
                                              $first_matching_key);
         } elsif (ref($input->{$key}) eq "ARRAY") {
            $vdLogger->Trace("Value is of type array for key $key");
            my @inputArray = ();
            my $count = 0;
            my @arrayHelper;
            my ($first_matching_key) = grep {lc($_) eq lc($key) || $_ =~ /^$key\[\?\]/i} keys %$helperHash;
            if (defined $first_matching_key) {
               $vdLogger->Debug("Trying to populate arrayHelper with " .
                                "first_matching_key=$first_matching_key" .
                                " and from input" . Dumper($input) .
                                "using helper hash" . Dumper($helperHash));
               if (defined @{$helperHash->{$first_matching_key}}) {
                  @arrayHelper = @{$helperHash->{$first_matching_key}};
               }
            }
            foreach my $arrayElement (@{$input->{$key}}) {
               if (defined $arrayHelper[$count]) {
                  $vdLogger->Debug("Merging input with helper array " .
                                   "for key $key");
                  my $result = RecurseThroughDatastructure($workloadObj,
                                                         $arrayElement,
                                                         $replacementType,
                                                         $arrayHelper[$count]);
                  if ($result eq "FAILURE") {
                     $vdLogger->Error("Merging between input & helper " .
                                      "hash failed for array structure");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
                  push(@inputArray, $result);
               } else {
                  $vdLogger->Trace("Performing $replacementType for key $key");
                  my $result = RecurseThroughDatastructure($workloadObj,
                                                           $arrayElement,
                                                           $replacementType);
                  if ($result eq "FAILURE") {
                     $vdLogger->Error("Replacement operation failed for " .
                                      "replacementType = $replacementType " .
                                      "for array structure");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
                  push(@inputArray, $result);
               }
               $count++;
            }
            # While traversing back, these operations need to be
            # performed based on $replacementType.
            $input = SubstitutionOfChildNodes($replacementType,
                                              $key,
                                              $input,
                                              \@inputArray,
                                              $first_matching_key);
         } else {
            $vdLogger->Trace("Value is of type scalar for key $key");
            my $result = ReplaceNodeValues($replacementType, $key, $input, $workloadObj,
                                           $helperHash);
            if ($result eq "FAILURE") {
               $vdLogger->Error("Unable to replace node with values for key value pair");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
   } elsif (ref($input) eq "ARRAY") {
      $vdLogger->Debug("Reference type of input is HASH");
      my @inputArray = ();
      my $count = 0;
      foreach my $arrayElement (@{$input}) {
         push(@inputArray, RecurseThroughDatastructure($workloadObj,
                                                       $arrayElement,
                                                       $replacementType,
                                                       $helperHash->[$count]));
         $count++;
      }
      return \@inputArray;
   } else {
      my $result = ReplaceNodeValues($replacementType, undef, $input);
      if ((defined $result) && ($result eq "FAILURE")) {
         $vdLogger->Error("Unable to replace node with values for string");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return $input;
}


#######################################################################
#
# SubstitutionOfChildNodes --
#      This methods helps in replacing child nodes with new child
#      nodes for the same parent denpding on replacement type.
#
# Input:
#      replacementType     : can be either empty/condition/tuple/merge
#      key                 : a value having delimiter and operator
#      input               : the replacement for input hash where
#                            input->{key} is the parent node and all
#                            the values under this node are child nodes.
#      $result             : new set of child nodes.
#      $first_matching_key : [OPTIONAL] value without delimiter and
#                            operator. Used specifically for merging.
#
# Results:
#      Return new value to the key $key
#
# Side effects:
#
########################################################################

sub SubstitutionOfChildNodes
{
   my $replacementType    = shift;
   my $key                = shift;
   my $input              = shift;
   my $result             = shift;
   my $first_matching_key = shift;

   if ($replacementType eq "empty") {
      my @arrayOfInitialVal = split ('\[\?\]', $key);
      delete $input->{$key};
      $key = $arrayOfInitialVal[0];
      $input->{$key} = $result;
   } elsif ($replacementType eq "condition") {
      $input->{$key} = $result;
   } elsif ($replacementType eq "tuple") {
      my @arrayOfInitialVal = split ('\[\?\]', $key);
      delete $input->{$key};
      $key = $arrayOfInitialVal[0];
      $input->{$key} = $result;
   } elsif (($replacementType eq "merge") &&
      (defined $first_matching_key)) {
      my $orginalValue = $input->{$key};
      $input->{$first_matching_key} = $result;
      if ($key ne $first_matching_key) {
         delete $input->{$key};
      }
   }
   return $input;
}


#######################################################################
#
# ReplaceNodeValues --
#      This methods helps in replacing node values with new
#      new denpding on replacement type.
#
# Input:
#      replacementType     : can be either empty/condition/tuple/merge
#      key                 : [OPTIONAL] a key in a hash whose values
#                            needs to be replaces
#      input               : hash where input->{key} is the node whose
#                            values will be replaced
#      workloadObj         : [OPTIONAL] workload object used to reuse
#                            methods from ParentWorkload.pm
#      helperHash          : [OPTIONAL] hash which will be merged with
#                            input hash.
#
# Results:
#      Return new value to the key $key
#
# Side effects:
#
########################################################################

sub ReplaceNodeValues
{
   my $replacementType    = shift;
   my $key                = shift;
   my $input              = shift;
   my $workloadObj        = shift;
   my $helperHash         = shift;

   if ($replacementType eq "empty") {
      if (defined $key) {
         $vdLogger->Trace("Calling ReplaceWithNull() for key $key");
         ReplaceWithNull($workloadObj, $input,$key);
      } else {
         $vdLogger->Debug("Send null back instead of $input for $replacementType");
         return undef;
      }
   } elsif ($replacementType eq "condition") {
      if (defined $key) {
         $vdLogger->Debug("Calling ReplaceWithCondition() for key $key");
         ReplaceWithCondition($workloadObj, $input,$key);
      } else {
         $vdLogger->Debug("Send null back instead of $input for $replacementType");
         return undef;
      }
   } elsif ($replacementType eq "tuple") {
      if (defined $key) {
         $vdLogger->Debug("Calling ReplaceWithTuple() for key $key");
         my $result = ReplaceWithTuple($workloadObj, $input,$key);
         if ($result eq "FAILURE") {
            $vdLogger->Error("Unable to replace tuple, check if node exists" .
                             "check if node exists in Zookeeper");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $vdLogger->Debug("Send $input back for $replacementType");
         return $input;
      }
   } elsif ($replacementType eq "values") {
      if (defined $key) {
         $vdLogger->Debug("Calling ReplaceWithValues() for key $key");
         $input =  ReplaceWithValues($workloadObj, $input,$key);
      } else {
         $vdLogger->Debug("Send $input back for $replacementType");
         return $input;
      }
   } elsif ($replacementType eq "merge") {
      if (defined $key) {
         $vdLogger->Debug("Calling MergeValuesWithDelimiter() for key $key");
         MergeValuesWithDelimiter($workloadObj, $input, $key, $helperHash);
      } else {
         $vdLogger->Debug("Send $input back for $replacementType");
         return $input;
      }
   }
   return $input;
}

#######################################################################
#
# ReplaceWithValues --
#      In this method, key's value (if tuple) is replaced with class
#      variables or output from class methods. If the key's value
#      is not a tuples then above doesn't take place and the value
#      is retained as is.
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value (if value is a tuple) is replaced
#                    with class variables or output from class methods.
#                    If the key's value is not a tuples then above doesn't
#                    take place and the value is retained as is.
#
# Results:
#      Return new value to the key $key
#      Return FAILURE incase of any errors.
#
# Side effects:
#
########################################################################

sub ReplaceWithValues
{
   my $workloadObj      = shift;
   my $userData         = shift;
   my $key              = shift;

   my $conditionValue = $userData->{$key};
   if($conditionValue eq "undef") {
      $userData->{$key} = undef;
      return $userData;
   }
   my $keysDatabase = $workloadObj->GetKeysTable();
   if ((not exists $keysDatabase->{$key}) || (not defined $keysDatabase->{$key})) {
        $vdLogger->Warn("key $key not defined in keydatabase, please define it");
   }
   if ((exists $keysDatabase->{$key}) &&
       (defined $keysDatabase->{$key}{method}) &&
       ($keysDatabase->{$key}{method} eq "GetComponentAttribute")) {
      my $method = $keysDatabase->{$key}{method};
      my $result = $workloadObj->$method($conditionValue, undef, $key);
      if ($result eq FAILURE) {
          $vdLogger->Error("Unable to run $method for key $key");
          VDSetLastError("EINVALID");
          return "FAILURE";
      }
      $userData->{$key} = $result;
      return $userData;
   }


   my $componentObj = {};
   if (defined $conditionValue &&
       (($conditionValue =~ m/\.\[/i) ||
        ($conditionValue =~ "self"))) {
      if ($conditionValue =~ "self") {
         $vdLogger->Debug("Value contains special string self. Replacing" .
                          " with tuple $workloadObj->{componentIndex}");
         $conditionValue = $workloadObj->{componentIndex};
      }
      $componentObj  = $workloadObj->GetOneObjectFromOneTuple($conditionValue);
      if (not defined $componentObj) {
         $vdLogger->Error("Invalid ref for tuple $conditionValue");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $reftype = ref($componentObj);
      $vdLogger->Debug("The value held by key $key is an object " .
                       "of type $reftype");
      my $mapping = $componentObj->GetAttributeMapping();
      if (not defined $mapping) {
         $vdLogger->Error("Object $reftype doesn't contain attribute mapping");
         $vdLogger->Error("Either add attribute mapping to this class type" .
                          " $reftype or write your own preprocess method");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $method = $mapping->{$key}{attribute};
      if (exists $mapping->{$key}) {
         if (exists $componentObj->{$mapping->{$key}{attribute}}) {
            $vdLogger->Debug("Class variable $mapping->{$key}{attribute}" .
                          " found in obect $reftype");
            #
            # As per the description in method header,
            # we are creating a new vaue comprising of
            # class variable.
            #
            $userData->{$key} = $componentObj->{$mapping->{$key}{attribute}};
      } elsif ($componentObj->can($method)) {
            $vdLogger->Debug("Class method $method found in obect $reftype");
            # can checks if the object has a method called $method
            # As per the description in method header,
            # we are creating a new value comprising of
            # the return value of method($key, $userData).
            #
            $userData->{$key} = $componentObj->$method($key, $userData);
         }
      }
   } else {
      #
      # The reftype of the value is not an abject.
      # Hence just modify the $key to the one matching
      # in $mapping->{$key}{payload} and assign back the
      # same key value $userData->{$key} to it
      #
      $conditionValue = $workloadObj->{componentIndex};
      $componentObj  = $workloadObj->GetOneObjectFromOneTuple($conditionValue);
      $vdLogger->Debug("The value held by key $key is not an object");
      if (not defined $componentObj) {
         $vdLogger->Error("Invalid ref for tuple $conditionValue");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $reftype = ref($componentObj);
      $vdLogger->Debug("The value held by key $key is an object " .
                       "of type $reftype");
      $vdLogger->Debug("Using attribute mapping to fill out the new value");
      if ($componentObj->can("GetAttributeMapping")) {
	  my $mapping = $componentObj->GetAttributeMapping();
      if (exists $mapping->{$key}) {
	     if (exists $mapping->{$key}{payload}) {
            #In my understanding it should be $userData->{$key} = $mapping->{$key}{payload}
            #but don't change it in case of breaking python code
	        $userData->{$key} = $userData->{$key};
           }
         } else {
	        $vdLogger->Debug("This object doesn't have GetAttributeMapping method,
                          the UserData won't be replaced with values");
         }
      }
   }

   return $userData;
}


#######################################################################
#
# ReplaceWithNull --
#      This method will replace values with null.
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value is replaced with NULL.
#
# Results:
#      Assign NULL to the key $key
#
# Side effects:
#
########################################################################

sub ReplaceWithNull
{
   my $workloadObj      = shift;
   my $param            = shift;
   my $key              = shift;

   my @arrayOfInitialVal = split ('\[\?\]', $key);
   delete $param->{$key};
   $key = $arrayOfInitialVal[0];
   $param->{$key} = undef;
}


#######################################################################
#
# ReplaceWithCondition --
#      This method will replace values with condition.
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value is replaced with condition.
#
# Results:
#      Assign condition as a value to the key $key
#
# Side effects:
#
########################################################################

sub ReplaceWithCondition
{
   my $workloadObj      = shift;
   my $param            = shift;
   my $key              = shift;

   my @arrayOfInitialVal = split ('\[\?\]', $key);
   $param->{$key} = undef;
}


#######################################################################
#
# ReplaceWithTuple --
#      This method will replace values with RHS of delimiter [?].
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value is replaced RHS of delimiter [?].
#
# Results:
#      Assign RHS of delimiter [?] as a value to the key $key
#
# Side effects:
#
########################################################################

sub ReplaceWithTuple
{
   my $workloadObj      = shift;
   my $param            = shift;
   my $key              = shift;

   my @arrayOfInitialVal = split ('\[\?\]', $key);
   my $originalValue = $param->{$key};
   my $originalKey = $param->{$key};
   if ($originalKey !~ m/\-\>/) {
      delete $param->{$key};
      $key = $arrayOfInitialVal[0];
      $param->{$key} = $originalValue;
   } else {
      my $result = GetAttributes($workloadObj, $param->{$key}, $key);
      if ($result eq "FAILURE") {
         $vdLogger->Error("Failed to replace value with $originalKey");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      delete $param->{$key};
      $key = $arrayOfInitialVal[0];
      $param->{$key} = $result;
   }
}


#######################################################################
#
# GetAttrFromPyObject--
#      This method will get the python object from the passed in perl object
#      and then will call the get_<attribute> method on that object.
#
# Input:
#      componentIndex: Tuple e.g. kvm.[1]
#      componentObjects: Perl object corresponding to the above tuple.
#      attributeKey: The key who's value is being fetched from the python
#      object.
#
# Return:
#      Attribute Value if succeeded in retrieval, FAILURE otherwise.
#
# Side effects:
#      None
#
########################################################################

sub GetAttrFromPyObject
{
      my $componentIndex = shift;
      my $componentObjects = shift;
      my $attributeKey = shift;
      if ($componentObjects eq FAILURE) {
         $vdLogger->Error("No object found for vdnet index $componentIndex");
         VDSetLastError("EINVALID");
         return "FAILURE";
      }
      if (scalar(@$componentObjects) > 1) {
         $vdLogger->Error("Multiple objects are not supported");
         VDSetLastError("EINVALID");
         return "FAILURE";
      }
      my $perlObj = $componentObjects->[0];
      # Step1: Create inline object of Parent
      # Inline python class
      my $parentPyObj;
      if (defined $perlObj->{parentObj}) {
         my $parentPerlObj = $perlObj->{parentObj};
         my $packageName = blessed $parentPerlObj;
         $parentPyObj = $parentPerlObj->GetInlinePyObject();
         if ($parentPyObj eq "FAILURE") {
            $vdLogger->Error("Failed to get inline python object for $packageName");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }
      # Step2: Create inline object of $perlObj
      # Inline python class
      my $packageName = blessed $perlObj;
      my $pyObj = $perlObj->GetInlinePyObject($parentPyObj);
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $packageName");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $responseData;
      my $method = 'get_' . $attributeKey;
      my $result = undef;
      $vdLogger->Debug("We got pyObj, now executing method=$method");
      # Step3: Run get_attribute() method
      eval {
         # TODO(gjayavelu) Check with Stefan Seifert <nine@detonation.org>
         # on why assigning returning value of python method on a pre-defined
         # variable does not catch exception from Python. Example,
         # if $result was set to some Perl string/array,
         # $result = $pyObj->$method(); will not catch ANY exception from
         # Python
         # $result = $pyObj->$method();
         $result = CallMethodWithKWArgs($pyObj, $method, undef);
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while executing $method " .
                          "on $pyObj->{__class__}:\n". $@);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if (not defined $result) {
         $vdLogger->Error("$method returned None when called on " .
                          "$pyObj->{__class__}");
         VDSetLastError("EINVALID");
         return "FAILURE";
      } elsif ($result eq FAILURE) {
         # TODO(Prabuddh): Should python methods be returning 'FAILURE' string?
         $vdLogger->Error("$method failed when called on $pyObj->{__class__}");
         VDSetLastError("EOPFAILED");
         return "FAILURE";
      }
      return $result;
}


# XXX: This method should not exist. Should re-use GetComponentAttribute
# from ParentWorkload.pm and avoid code duplication/redundancy.
#######################################################################
#
# GetAttributes --
#      This method will decide which wrapper method to be used
#      to access runtime stats.
#
# Input:
#      workloadObj : object of workload.
#      value: Value corresponding to the key being resolved.
#      key         : a key whose value is replaced RHS of delimiter [?].
#
# Results:
#      Return the runtime data
#
# Side effects:
#
########################################################################

sub GetAttributes
{
   my $workloadObj      = shift;
   my $value = shift;
   my $key              = shift;
   my @arrayOfInitialVal = split ('\-\>', $value, 2);

   # if the zero element has vdnet index
   # that means fetch data without workload
   # and index reference
   if ($arrayOfInitialVal[0] =~ /\[/) {
      if ($arrayOfInitialVal[1] =~ /test_data/i
              # following line to match the persist data
              or $arrayOfInitialVal[1] =~ /\w.*\-\>/) {
         # Not Calling GetDefaultAttributes
         # becuase read is expensive
         return GetCustomAttributes($workloadObj, $value, $key);
      } else {
         my $componentObjects = $workloadObj->{testbed}->GetComponentObject(
             $arrayOfInitialVal[0]);
         if ($componentObjects eq FAILURE) {
            $vdLogger->Error("Failed to get the component object for " .
                             "$arrayOfInitialVal[0]");
            return FAILURE;
         }
         my $perlObj = $componentObjects->[0];
         if ($perlObj eq FAILURE) {
             VDSetLastError("EINVALID");
             return FAILURE;
         }
         my $perlMethod = "Get" . "$arrayOfInitialVal[1]";
         if (defined $perlObj && eval{$perlObj->can($perlMethod)}) {
             $vdLogger->Debug("Calling perl method $perlMethod");
             return $perlObj->$perlMethod();
         }
         return GetAttrFromPyObject(
             $arrayOfInitialVal[0], $componentObjects, $arrayOfInitialVal[1]);
      }
   } else {
      # if the zero element does not has vdnet index
      # that means fetch data with workload and
      # index reference
      $vdLogger->Info("Trying to fetch runtime stats based on workload = " .
                      "$arrayOfInitialVal[0] and their iteration # = " .
                      "$arrayOfInitialVal[1]");
      return GetRuntimeWorkloadAttributes($workloadObj, $value, $key);
   }
}


#######################################################################
#
# GetDefaultAttributes --
#      This method will return data fetched from the Read() method
#      sitting in the classes
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value is replaced RHS of delimiter [?].
#
# Results:
#      Return the runtime data from Read() call
#
# Side effects:
#
########################################################################

sub GetDefaultAttributes
{
   my $workloadObj      = shift;
   my $param            = shift;
   my $key              = shift;
   my @arrayOfInitialVal = split ('\-\>', $param->{$key});
   my $vdnetIndex = $arrayOfInitialVal[0];
   my $attribute = $arrayOfInitialVal[2];
   $vdLogger->Info("Trying to fetch attribute value of $attribute" .
                   " from $vdnetIndex object");
   my $componentObj  = $workloadObj->GetOneObjectFromOneTuple($vdnetIndex);
   if (not defined $componentObj) {
      $vdLogger->Error("Invalid ref for tuple $vdnetIndex");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $returnValue = $componentObj->Read();
   my $attributeValue = $returnValue->{response}{$attribute};
   $vdLogger->Info("Value of $attribute is $attributeValue");
   return $attributeValue;
}


#######################################################################
#
# GetCustomAttributes --
#      This method will return data fetched from the runtime data
#      stored under the object.
#
# Input:
#      workloadObj : object of workload.
#      value: value corresponding to the key being resolved.
#      key         : a key whose value is replaced RHS of delimiter [?].
#
# Results:
#      Return the runtime data
#
# Side effects:
#
########################################################################

sub GetCustomAttributes
{
   my $workloadObj      = shift;
   my $value = shift;
   my $key              = shift;
   my @arrayOfInitialVal = split ('\-\>', $value);
   my $vdnetIndex = $arrayOfInitialVal[0];
   my $verificationKey = $arrayOfInitialVal[1];
   if ($verificationKey =~ /test_data/i) {
      $verificationKey = $arrayOfInitialVal[2];
   }
   splice @arrayOfInitialVal, 0, 2;
   $vdLogger->Info("Trying to fetch attribute value of $verificationKey" .
                   " from $vdnetIndex object");

   my $tuple = $workloadObj->{testbed}->ResolveTuple($vdnetIndex);
   if (FAILURE eq $tuple) {
       $vdLogger->Error("Failed to resolve tuple: $vdnetIndex");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   if (scalar(@$tuple) > 1) {
      $vdLogger->Error("Expected the vdnet index $vdnetIndex to be " .
                       "resolved to a single component but got: " .
                       Dumper($tuple));
      $vdLogger->Error("Fetching data from multiple nodes is not supported");
      VDSetLastError("ERUNTIME");
      return FAILURE;
   }

   my $node = $workloadObj->{testbed}->GetRuntimeDefaultNode($tuple->[0],
                                                             $verificationKey);
   if ($node eq "FAILURE") {
      $vdLogger->Error("Failed to get default node  from $vdnetIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my ($workloadName, $workloadIndex) = split ('/', $node);
   my $runtimeStats =
      $workloadObj->{testbed}->GetRuntimeStatsValue($tuple->[0],
                                                    $workloadName,
                                                    $workloadIndex,
                                                    $verificationKey);
   if ($runtimeStats eq "FAILURE") {
      $vdLogger->Error("Failed to get runtime info from $vdnetIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $ref = RetrieveDataFromRuntimeStats($runtimeStats, \@arrayOfInitialVal);
   $vdLogger->Info("The fetched runtime value is: $ref");
   return $ref;
}


#######################################################################
#
# GetRuntimeWorkloadAttributes --
#      This method will return data fetched from workloads
#
# Input:
#      workloadObj : object of workload.
#      value: Value corresponding to the key being resolved.
#      key         : a key whose value is replaced RHS of delimiter [?].
#
# Results:
#      Return the workloads runtime data
#
# Side effects:
#
########################################################################

sub GetRuntimeWorkloadAttributes
{
   my $workloadObj      = shift;
   my $value = shift;
   my $key              = shift;
   my @arrayOfInitialVal = split ('\-\>', $value);

   my $vdnetIndex = $arrayOfInitialVal[2];
   my $workloadName = lc($arrayOfInitialVal[0]);
   my $workloadIndex = lc($arrayOfInitialVal[1]);
   my $verificationKey = lc($arrayOfInitialVal[3]);

   splice @arrayOfInitialVal, 0, 4;
   $vdLogger->Info("Trying to fetch runtime information from " .
                   " $vdnetIndex");
   my $runtimeStats =
      $workloadObj->{testbed}->GetRuntimeStatsValue($vdnetIndex,
                                                    $workloadName,
                                                    $workloadIndex,
                                                    $verificationKey);
   if ($runtimeStats eq "FAILURE") {
      $vdLogger->Error("Failed to get runtime info from $vdnetIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $ref = RetrieveDataFromRuntimeStats($runtimeStats, \@arrayOfInitialVal);
   $vdLogger->Info("Runtime value is  $ref");
   return $ref;
}


#######################################################################
#
# RetrieveDataFromRuntimeStats --
#      This method is used to access data from datastructure
#
# Input:
#      runtimeStats  : complex datastructure from where the data is accessed
#      arrayOfValues : each element contains a reference that helps in
#                      traversing through the datastructure, e.g.
#                      read->result->physical_address which means access
#                      read hash and from there access the key result. The
#                      key 'result' holds another hash and in that access
#                      the key 'physical_address' and  return the value.
#                      For lists, this method depends on a helper method
#                      called RetrieveDataFromRuntimeStatsHavingLists()
#
# Results:
#      Return the workloads runtime data
#
# Side effects:
#
########################################################################

sub RetrieveDataFromRuntimeStats
{
   my $runtimeStats   = shift;
   my $arrayOfValues  = shift;
   my $returnValue;
   my $copyArrayOfValues = dclone $arrayOfValues;
   my $level = shift @$arrayOfValues;
   if (scalar @$arrayOfValues == 0) {
      if ($level =~ /\[/) {
         $vdLogger->Debug("Looks like the runtime data is list");
         return RetrieveDataFromRuntimeStatsHavingLists($runtimeStats, $copyArrayOfValues);
      } else {
         return $runtimeStats->{$level};
      }
   } else {
      if ($level =~ /\[/) {
         $level =~ s/\[|\]//g;
         $returnValue = RetrieveDataFromRuntimeStats($runtimeStats->[$level],
                                      $arrayOfValues);
      } else {
         $returnValue = RetrieveDataFromRuntimeStats($runtimeStats->{$level},
                                      $arrayOfValues);
      }
   }

   return $returnValue;
}


#######################################################################
#
# RetrieveDataFromRuntimeStatsHavingLists --
#      This method is used to access data from list/array
#
# Input:
#      runtimeStats  : complex datastructure from where the data is accessed
#      arrayOfValues : each element contains a reference that helps in
#                      traversing through the datastructure, e.g.
#                      ['0', 'abc', ['2']] which means access the first
#                      element, then access the key 'abc' and then access
#                      the third element of datastructure runtimeStats.
#
# Results:
#      Return the workloads runtime data
#
# Side effects:
#
#######################################################################

sub RetrieveDataFromRuntimeStatsHavingLists
{
   my $runtimeStats   = shift;
   my $arrayOfValues  = shift;
   my $returnValue;
   $vdLogger->Debug("Runtime stats:" . Dumper($runtimeStats));
   $vdLogger->Debug("Array of Values:" . Dumper($arrayOfValues));
   my $index = 0;
   if (ref($arrayOfValues) =~ /ARRAY/i) {
      $vdLogger->Debug("Still dealing with arrays");
      foreach my $element (@$arrayOfValues) {
         $vdLogger->Debug("Element is : " . Dumper($element));
         my $eval_element = eval($element);
         $vdLogger->Debug("Eval Element is : " . Dumper($eval_element));
         if (ref($eval_element) =~ /ARRAY/i) {
            $arrayOfValues = $eval_element;
            $vdLogger->Debug("Element is Array" . Dumper($eval_element));
            $vdLogger->Debug("Runtime stats" . Dumper($runtimeStats));
            my $first_element = shift @$arrayOfValues;
            $vdLogger->Debug("First Element is" . Dumper($first_element));
            $vdLogger->Debug("Array of values after shift" . Dumper(@$arrayOfValues));
            if (looks_like_number($element)) {
               $vdLogger->Debug("Runtime stats for recursion $first_element " .
                                " array " . Dumper($runtimeStats->[$first_element]));
               $returnValue =
                   RetrieveDataFromRuntimeStatsHavingLists(
                                              $runtimeStats->[$first_element],
                                              @$arrayOfValues);
            } else {
                $vdLogger->Debug("Runtime stats for recursion $first_element" .
                                 " hash " . Dumper($runtimeStats->{$first_element}));
                $returnValue =
                    RetrieveDataFromRuntimeStatsHavingLists(
                                              $runtimeStats->{$first_element},
                                              @$arrayOfValues);
            }
         } elsif (ref($element) =~ /HASH/i) {
            $vdLogger->Debug("\nNot uspported yet");
         } else {
            $vdLogger->Debug("Element is string" . Dumper($element));
            $vdLogger->Debug("Runtime stats" . Dumper($runtimeStats));
            splice @$arrayOfValues, 0, 1;
            $returnValue =
                RetrieveDataFromRuntimeStatsHavingLists(
                                            $runtimeStats->[$element],
                                            @$arrayOfValues);
         }
      }
   } else {
      $vdLogger->Debug("Finally reached the end and returning the desired value");
      $returnValue = $runtimeStats->{$arrayOfValues};
   }
   $vdLogger->Debug("Returning the desired value: $returnValue");
   return $returnValue;
}

#######################################################################
#
# MergeValuesWithDelimiter --
#      This method will create a new value for key $key
#      The new value will look like:
#         <condition> "[?]" . <value>
#
# Input:
#      workloadObj : object of workload.
#      userData    : a hash containing key/value pair.
#      key         : a key whose value will be modified
#      helperHash  : a hash whose will be used to create a new value and
#                    assigned to key
#
# Results:
#      Create a new value using delimiter [?] as a value to the key $key
#
# Side effects:
#
########################################################################

sub MergeValuesWithDelimiter
{
   my $workloadObj             = shift;
   my $param                   = shift;
   my $key                     = shift;
   my $helperHash              = shift;

   my ($first_matching_key) = grep { $_ =~ /^$key/ } keys %$helperHash;
   if ((defined $first_matching_key) && ($first_matching_key =~ /\?/)) {
      my $orginalValue = $param->{$key};
      $param->{$first_matching_key} = $orginalValue;
      delete $param->{$key};
   }
}


#######################################################################
#
# GetReplaceMethods --
#      return the ReplaceMethods hash
#
# Input:
#      none
#
# Results:
#      return the ReplaceMethods hash
#
# Side effects:
#
########################################################################

sub GetReplaceMethods
{
   return ReplaceMethods;
}


########################################################################
#
#  HealthCheckupAndRecovery
#       This method traverses the method array, run check up method to check
#       healthy. If not, run recovery method to restart the service
#
# Input:
#       $inventoryObj: inventory object
#       methodArray: method array (required), which has following format:
#       my @methodArray = (
#        {
#         'checkupmethod' => 'CheckHostUpWithPing',
#         'recoverymethod' => 'RecoverHost',
#        },
#        {
#         'checkupmethod' => 'CheckHostUpWithHostd',
#         'recoverymethod' => 'HostdRestart',
#        },
#       );
#
# Results:
#      TRUE: The health was good
#      FALSE: The health was bad and we recovered
#      FAILURE: The health was bad but the recovery failed
#
# Side effetcs:
#      None
#
########################################################################

sub HealthCheckupAndRecovery
{
   my $inventoryObj = shift;
   my $methodArray = shift;
   my $finalResult = VDNetLib::Common::GlobalConfig::TRUE;
   if (not defined $inventoryObj) {
      $vdLogger->Error("Inventory object not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # If all the check up method returns TRUE, function will return TRUE;
   # If one of check up method returns FALSE and recovery succeed,
   # function will return FALSE;
   # If one of recovery method returns FAILURE, function will exit and return FAILURE

   foreach my $methodHash (@$methodArray) {
      if (ref($methodHash) ne "HASH") {
         $vdLogger->Error("The input is not hash," .
                       "format not supported " . Dumper($methodHash));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $checkMethod = $methodHash->{'checkupmethod'};
      my $recoveryMethod = $methodHash->{'recoverymethod'};
      my $checkResult = 0;
      my $recoveryResult = 0;
      if ((not defined $checkMethod) || (not defined $recoveryMethod)) {
         $vdLogger->Error("Check or recovery method not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      # Run check method, if not healthy, then run recovery method
      my $functionRef = $inventoryObj->can($checkMethod);
      if ($functionRef) {
         $checkResult = $inventoryObj->$functionRef();
      }
      if ($checkResult == VDNetLib::Common::GlobalConfig::TRUE) {
         next;
      }

      #  if one check method returns FALSE, the final result should be false

      $finalResult = $checkResult;
      $functionRef = $inventoryObj->can($recoveryMethod);
      if ($functionRef) {
         $recoveryResult = $inventoryObj->$functionRef();
      }
      if ($recoveryResult eq FAILURE) {
         $finalResult = FAILURE;
      }
   }
   return $finalResult;
}


#######################################################################
#
# StoreDataToFile --
#      This method will store data at either of the following locations
#      logDir/current.log or logDir/previous.log
#      Logic:
#         if current.log doesnot exist
#            then store data in current.log
#         else if curent.log exists
#            then move the contents of current.log to previous.log
#            and overwrite current.log with new contents.
#
# Input:
#      serverData  : data to be stored at particular file location
#      logDir      : location to store verification logs
#
# Results:
#      SUCCESS, in case the file is successfully stored
#      FAILURE, in case of any failure
#
# Side effects:
#
########################################################################

sub StoreDataToFile
{
   my $serverData  = shift;
   my $logDir      = shift;

   # Prepare to dump server data in a file
   my $dumper = new Data::Dumper([$serverData]);
   $dumper->Indent(0);
   # If Terse(0) is used then $VAR1 also
   #  get stored in the file.
   $dumper->Terse(1);
   $dumper->Quotekeys(0);
   # Serialized data is ready
   my $dumperValue = $dumper->Dump();

   # Prepare the path where current.log and previous.log
   # will be stored
   # Check if directory exists, if not create it
   if (!(-d $logDir)) {
      mkdir $logDir, 0755;
   }

   # Prepare file location
   my $currentLogFile = $logDir . '/current.log';

   my $destTdsHandle;
   # Check if current.log exists
   if (!(-e $currentLogFile)) {
      # current.log doesnot exist, so lets create it
      eval {
         open($destTdsHandle, ">", $currentLogFile);
         $vdLogger->Debug("Storing server logs at $currentLogFile");
         # dump new content from $serverData to current.log
         print $destTdsHandle $dumperValue;
      };
   } else {
      # current.log exists, so move the contents of
      # current.log to previous.log using copy
      my $previousLogFile = $logDir . '/previous.log';
      $vdLogger->Debug("Moving $currentLogFile to $previousLogFile");
      #
      # copy new content from $serverData to current.log
      # and move old data in current.log to previous.log
      eval {
         rename $currentLogFile, $previousLogFile;
         $vdLogger->Debug("Storing server logs at $currentLogFile");
         open($destTdsHandle, ">", $currentLogFile);
         print $destTdsHandle $dumperValue;
      };
   }
   if ($@) {
      $vdLogger->Error("Exception thrown while copying data to current.log:$@");
      VDSetLastError("ENOENT");
      return FAILURE;
   }
   # closing the file handle
   close($destTdsHandle);

   return SUCCESS;
}


#######################################################################
#
# GetDataFromFile --
#      This method will return de-serialized data from a file
#
# Input:
#      logDir : location where verification logs are present
#
# Results:
#      SUCCESS, return the de-serialized data
#      FAILURE, incase file is not present or de-serialization failed
#
# Side effects:
########################################################################

sub GetDataFromFile
{
   my $path = shift;
   my $destTdsHandle;
   eval {
      open($destTdsHandle, $path);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while opening file $path: $@");
      VDSetLastError("ENOENT");
      return FAILURE;
   }
   $vdLogger->Debug("Getting data from file $path");
   # Get the first line of the file. Since all the
   # data is serialized, everything will be part
   # of first line
   my $firstLine = <$destTdsHandle>;
   # To de-serialize the data
   my @serializedData = eval $firstLine;

   if ($@) {
      $vdLogger->Error("Exception thrown while de-serializing file loacted at" .
                       "$path: $@");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   # Doing this because eval return data in array format
   # where 0 points to the value that was stored in the file.
   my $returnValue = $serializedData[0];
   # closing the file handle
   close($destTdsHandle);
   return $returnValue;
}


#######################################################################
#
# CheckVerificationLogs --
#      This method will return a hash with locations of current.log and
#      previous.log file location in the following format
#         my $pathHash = {
#            'current'  => <location of current.log>,
#            'previous' => <location of previous.log>,
#         };
#
# Input:
#      logDir : location where verification logs are present
#
# Results:
#      SUCCESS, return 2 saying two files current & previous were found
#      FAILURE, incase the file doesn't exists at the location
#
# Side effects:
########################################################################

sub CheckVerificationLogs
{
   my $logDir = shift;
   my $currentLogFile = $logDir. '/current.log';
   my $previousLogFile = $logDir . '/previous.log';
   my $count = 0;
   if ((-e $currentLogFile) && (-e $previousLogFile)) {
      $count = $count + 2;
      return $count;
   } else {
      $vdLogger->Debug("Current or previous log file not found at $logDir");
   }
   return $count;
}


########################################################################
#
# DeleteVerificationFiles --
#     Method to delete verification files
#
# Input:
#     None
#
# Results:
#     SUCCESS, if node for test session is deleted successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DeleteVerificationFiles
{
   my $self = shift;
   my $logDir = $vdLogger->{logFileName};
   my @arrayForPath = split('\/', $logDir);
   # Deleting the last element testcase.log
   pop @arrayForPath;
   # Deleting the second last element 1_<Test_Name>
   pop @arrayForPath;
   $logDir = join('/',@arrayForPath) . '/';
   $vdLogger->Debug("Checking if verification logs exists for test case");

   # Lets find the folders where current.log exists
   my $command = 'find ' . $logDir . ' -name current.log';
   my $output = `$command`;
   unless (not defined $output) {
      my @arryin = ();
      my $count = 0;
      foreach my $line (split /\n/, $output) {
         my @arrayForPath = split('\/',$line);
         # Deleting the last element current.log
         pop @arrayForPath;
         my $parentFolder = join('/',@arrayForPath);
         $parentFolder = $parentFolder . '/';
         $vdLogger->Debug("Deleting folder $parentFolder");
         eval {
            $command = 'rm -rf ' . $parentFolder;
            `$command`;
         };
         if ($@) {
            $vdLogger->Error("Exception thrown deleting verification logs" .
                             "$command: $@");
            VDSetLastError("ENOENT");
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# ResolveTuplesInDelimitedString --
#    Method to resolve tuples embedded within a delimited string.
#    Current limitation is tuple must be restricted to basic form of
#    vm.[1].vnic.[1]. Indices like [-1], [1-4] not supported with this
#    method for now.
#
# Example:
# input: "foo vm.[1].vnic.[1]->GetMACAddress bah srcaddr==vm.[1].vnic.[1]->GetIPv4"
# delimited: " "
# output: "foo 00:0C:29:F1:ED:7F bah srcaddr==192.168.101.178"
#
# Input:
#   $inputStr: Delimited string that can contain <tuple->method>
#   $delimiter: Delimiter to split the string. Defaults to ' '
#
# Results:
#   $outputStr: Input string with resolved tuple values.
#
# Side effects:
#     None
#
########################################################################

sub ResolveTuplesInDelimitedString
{
   my $self = shift;
   my $inputStr = shift;
   my $delimiter = shift || ' ';
   if (not defined $inputStr) {
      $vdLogger->Error("Insufficient parameters for ResolveDelimitedString()." .
                       " Requires input string.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $outputStr = "";
   my @strArry;
   # Split the delimited string to get individual elements.
   @strArry = split($delimiter, $inputStr);
   foreach my $word (@strArry) {
      # TODO(gangarm): Enhance this to support all tuple representations like
      # vm.[-1], or vm.[1-4], etc.
      # Check if $word is of form <tuple->method>.
      my $parsedWord = VDNetLib::Common::Utilities::ParseTextTupleMethod($word);
      if (defined $parsedWord) {
         $vdLogger->Debug("Resolving $word.");
         my $text = $parsedWord->{'text'};
         my $tuple = $parsedWord->{'tuple'};
         my $method = $parsedWord->{'method'};
         if ($method =~ /\s+/) {
            $vdLogger->Error("Method name cannot contain white-space. Got " .
                             "$method.");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         # Get the tuple object.
         my $tupleObj = $self->GetOneObjectFromOneTuple($tuple);
         $vdLogger->Debug("Got object $tupleObj from $tuple.");
         if ($tupleObj eq FAILURE) {
            $vdLogger->Error("Failed to get tuple object for $tuple");
            return FAILURE;
         }
         # Run the specified method on the tuple object.
         $vdLogger->Debug("Running $method on $tupleObj.");
         my $resolvedValue = $tupleObj->$method();
         if ($resolvedValue eq FAILURE) {
            $vdLogger->Error("Method $method on $tupleObj returned FAILURE.");
            return FAILURE;
         }
         # Replace <tuple->method> in original $word with the resolved value.
         $word = "$text$resolvedValue";
      }
      # Append $word to $outputStr.
      $outputStr = "$outputStr $word";
   }
   $vdLogger->Debug("Output string after resolving tuples: $outputStr");
   return $outputStr;
}
1;
