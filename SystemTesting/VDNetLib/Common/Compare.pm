##############################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
##############################################################################
package VDNetLib::Common::Compare;

#
# The objective of this class is to do data comparison.
# Data comparison can be of various types. It can be either
# normal diff between the input from expected and output from
# a cli or server call. Or it can be diff between initial
# and final data from server call and then comparing the
# diff with the expected data. This class helps us implement
# various compare operation.
#

use strict;
use warnings;

use Data::Dumper;
use Storable 'dclone';
use Scalar::Util qw(looks_like_number);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Operator;

########################################################################
#
# new --
#     Entry to VDNetLib::Common::Compare. Creates an instance of
#     VDNetLib::Common::Compare object.
#
# Input:
#     operatorType - operator class under VDNetLib/Operator
#
# Results:
#      A VDNetLib::Common::Compare object
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self  = {
     # For simple diff between
     # datastructures, the
     # verificationStyle can be
     # set to default.
     'verificationStyle' => $options{verificationStyle} || "default",
     'operatorType'     => "Operator",
   };
   bless ($self, $class);
   return $self;
}


########################################################################
#
# CompareDataStructures --
#     This methods compare two datastructures and returns the result
#
# Input:
#     expectedValue   - This hash has the conditions for each key given
#                       by the user.
#     actualValue     - This hash has the values for each key returned
#                       from the server.
#     globalCondition - [optional] used only when the expected wants to verify
#                       if the input complex structure is part of server spec.
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub CompareDataStructures
{
   my $self            = shift;
   my $expectedValue  = shift;
   my $actualValue      = shift;
   my $globalCondition = shift;

   $vdLogger->Debug("Start datastructure comparison");
   my $result = $self->DepthFirstSearchForVerification($expectedValue,
                                                       $actualValue,
                                                       $globalCondition);

   if ($result eq "FAILURE") {
      $vdLogger->Error("Compare operation failed");
      VDSetLastError("EOPFAILED");
      return FAILURE
   }

   # Special requirement not related
   # to the DFS algorithm call the CompareValues()
   # if global comparison. It is different from
   # else part in the above code. That part
   # is executed in the inputs are just strings.
   if (defined $globalCondition) {
      # checking the contain_once part
      $vdLogger->Info("Running for top level condition $globalCondition");
      $vdLogger->Debug(Dumper($expectedValue));
      $vdLogger->Debug(Dumper($actualValue));

      my $operatorObj = VDNetLib::Common::Operator->new();
      my $method = $operatorObj->{operatorhash}{$globalCondition}{method};
      $result = $operatorObj->$method($expectedValue, $actualValue);
      if ($result eq "FAILURE") {
         $vdLogger->Error("Compare operation failed for top level condition =".
                          " $globalCondition");
         VDSetLastError("EOPFAILED");
         return $result;
      } else {
         $vdLogger->Debug("Expected hash is part of actual hash," .
                         " proceed for next element.");
         return $result;
      }
   }

   return $result;
}


########################################################################
#
# DepthFirstSearchForVerification --
#     Recurses through data until the leaf key/value pair is hit
#     and while traversing back if a key with delimiter is encountered
#     then operator method is called. if the operator method returns
#     success, then this node is marked touched and delimiter is removed
#     if it is present on that node.
#
# Input:
#     expectedValue   - This hash has the conditions for each key
#     actualValue     - This hash has the values for each key
#     conditionHash   - a hash containing all the operators for the
#                        corressponding key.
# Results:
#     SUCCESS, if the datastructures are equal
#     Failure, if the datastructures are not equal
#
# Side effects:
#     None
#
########################################################################

sub DepthFirstSearchForVerification
{
   my $self            = shift;
   my $expectedValue   = shift;
   my $actualValue     = shift;
   my $globalCondition = shift || '';

   my $result = SUCCESS;

   #
   # Start for HASH
   #
   if (ref($expectedValue) =~ /HASH/) {
      $vdLogger->Debug("Start comparing hashes");
      foreach my $key (keys %$expectedValue) {
         my @arrayOfInitialVal = split ('\[\?\]', $key);
         my $keyInActualValue = $arrayOfInitialVal[0];
         #
         # If leaf node is HASH or
         # ARRAY recurse again
         #
         if ((ref($expectedValue->{$key}) =~ /HASH/) ||
             (ref($expectedValue->{$key}) =~ /ARRAY/)) {
            if (defined $actualValue && exists $actualValue->{$keyInActualValue}) {
                    $result = $self->DepthFirstSearchForVerification(
                                                    $expectedValue->{$key},
                                                    $actualValue->{$keyInActualValue});
                    if ($result eq "FAILURE") {
                    $vdLogger->Error("Compare operation failed for key: " .
                                     "$actualValue->{$keyInActualValue}");
                    VDGetLastError("EOPFAILED");
                    return FAILURE;
                }
            } else {
                $vdLogger->Error("Key " . $keyInActualValue .
                                 " not exist in server data");
                VDGetLastError("EOPFAILED");
                return FAILURE;
            }
         }
         #
         # If leaf node is string
         # call compare operation
         #
         if (defined $arrayOfInitialVal[1]) {
            $vdLogger->Debug("Comparing \'$keyInActualValue\' in expected " .
                            "data against with server data for condition" .
                            " $arrayOfInitialVal[1]");
            #
            # call the operator method and check
            # if the server value needs to replaced
            #
            my $condition;
            if ($key =~ /\?/) {
               my @arrayOfInitialVal = split ('\[\?\]', $key);
               $condition = $arrayOfInitialVal[1];
            }
            my $operatorObj = VDNetLib::Common::Operator->new();
            my $method = $operatorObj->{operatorhash}{$condition}{method};
            # using for case where OR between 0 and undef return undef
            # instead 0 should be returned
            my $finalExpectedValue;
            if ((defined $expectedValue->{$key}) &&
               (not defined $expectedValue->{$keyInActualValue})) {
               $finalExpectedValue = $expectedValue->{$key};
            } elsif ((not defined $expectedValue->{$key}) &&
                     (defined $expectedValue->{$keyInActualValue})) {
               $finalExpectedValue = $expectedValue->{$keyInActualValue};
            } elsif ((not defined $expectedValue->{$key}) &&
                     (not defined $expectedValue->{$keyInActualValue})) {
               $finalExpectedValue = undef;
            }
            my $replaceWithServer = $operatorObj->{operatorhash}{$condition}{replaceWithServer};
            $result = $operatorObj->$method($finalExpectedValue,
                                            $actualValue->{$keyInActualValue});
            if ($result eq "FAILURE") {
               $vdLogger->Error("Compare operation failed for key: " .
                                "$keyInActualValue, where expected value" .
                                " was " . Dumper($finalExpectedValue) .
                                " and actual value was " .
                                Dumper($actualValue->{$keyInActualValue}));
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
            # Resolve Data
            # Replace user data with the server data
            # so that delimiter and operator are removed
            if (($key =~ /\?/) && ($replaceWithServer eq "yes")) {
               $vdLogger->Debug("Replace user data with server data for key " .
                                "$key");
               delete $expectedValue->{$key};
               $expectedValue->{$keyInActualValue} =
                    $actualValue->{$keyInActualValue};
            } elsif ($key =~ /\?/) {
               $vdLogger->Debug("Retaining user data for key $key because " .
                                "\'not\' was found in operator. Removing" .
                                " delimiter [?] and condition from the key");
               if ((ref($expectedValue->{$key}) =~ /HASH/) ||
                   (ref($expectedValue->{$key}) =~ /ARRAY/)) {
                      $expectedValue->{$keyInActualValue} =
                         dclone $expectedValue->{$key};
                   } else {
                      $expectedValue->{$keyInActualValue} = $expectedValue->{$key};
                   }
               delete $expectedValue->{$key};
            }
         } else {
            $vdLogger->Warn("No condition found for key $key");
            next;
         }
      }
   } elsif (ref($expectedValue) =~ /ARRAY/) {
      #
      # Start for ARRAY
      #
      my @resultArray;
      my $result = FAILURE;
      my $indexCondition = 0;
      foreach my $elementExpectedValue (@$expectedValue) {
         $vdLogger->Debug("Checking for element number $indexCondition ".
                          Dumper(\$elementExpectedValue)." in user data");
         foreach my $elementActualValue (@$actualValue) {
            my $conditionInput  =  $elementExpectedValue;
            my $finalInput = $elementActualValue;
            $vdLogger->Debug("Start comparing arrays");
            $result = $self->DepthFirstSearchForVerification($conditionInput,
                                                             $finalInput,
                                                             $globalCondition);
            if ($result eq "SUCCESS") {
               $vdLogger->Debug("Expected data matched against " .
                               "an entry in server data");
               $vdLogger->Debug("Expected data: " . Dumper($conditionInput));
               $vdLogger->Debug("Server data: " . Dumper($finalInput));
               last;
            }
            if ($result eq "FAILURE") {
               if ($globalCondition eq "contains"){
                 next;
               } else {
                 $vdLogger->Error("Compare failed for array expectedValue");
                 VDGetLastError("EOPFAILED");
                 return FAILURE;
               }
            }
            $vdLogger->Error("Compare failed for array expectedValue");
            VDGetLastError("EOPFAILED");
            return FAILURE;
         }
         $indexCondition++;
      }
   } else {
      #
      # If leaf node is string
      # call compare operation
      #
      if ($expectedValue !~ /\?/) {
         $vdLogger->Warn("No condition defined for string comparison of" .
                          " expected value $expectedValue with the server" .
                          " value $actualValue");
         # return false positive
         return SUCCESS;
      }

      my $condition;
      if ($expectedValue =~ /\?/) {
         my @arrayOfInitialVal = split ('\[\?\]', $expectedValue);
         $condition = $arrayOfInitialVal[1];
      }
      my $operatorObj = VDNetLib::Common::Operator->new();
      my $method = $operatorObj->{operatorhash}{$condition}{method};
      my $replaceWithServer = $operatorObj->{operatorhash}{$condition}{replaceWithServer};
      $result = $operatorObj->$method($expectedValue,$actualValue);
      if ($result eq "FAILURE") {
         $vdLogger->Error("Compare operation failed");
         return FAILURE;
      }
      # Resolve Data
      # Replace user data with the server data
      # so that delimiter and operator are removed
      if (($expectedValue =~ /\?/) && ($replaceWithServer eq "yes")) {
         $vdLogger->Info("Replace user data with server data");
         $expectedValue = $actualValue;
      } else {
         $vdLogger->Info("Retaining user data with server data " .
                         "because \'not\' was found in operator");
      }

   }

   return $result;
}


########################################################################
#
# DeltaDiff --
#     This methods performs the comparison at key level between the
#     expectedcondition and the out from the server. If the input is a
#     number then and diff is returned, but if the input is a string
#     an "and" between the two values is returned.
#
# Input:
#     expectedValue - This hash has the conditions for each key
#     actualValue     - This hash has the values for each key
#
# Results:
#      Returns diff between initial value and actual value if both are
#      numbers, else return actual value.
#
# Side effects:
#     Will break in case the value is a key or array
#
########################################################################

sub DeltaDiff
{
   my $self = shift;
   my $currentValue = shift;
   my $previousValue = shift;

   my $diff;
   if (looks_like_number($currentValue) && looks_like_number($previousValue)) {
      $diff = $currentValue - $previousValue;
   } else {
      $diff = $currentValue;
   }
   return $diff;
}


########################################################################
#
# GetDiffBetweenDataStructures --
#     Recurses through data until the leaf key/value pair is hit. if
#     value is a number then a diff is calculated between the current
#     and previous value. If the value is a string then most current
#     value is returned
#
# Input:
#     currentValue   - This hash has current values
#     previousValue  - This hash has old values
#
# Results:
#     SUCCESS, return the diff between current and previous value
#     FAILURE, in case of any failure
#
# Side effects:
#     None
#
########################################################################

sub GetDiffBetweenDataStructures
{
   my $self            = shift;
   my $currentValue   = shift;
   my $previousValue     = shift;

   my $result = FAILURE;

   #
   # Start for HASH
   #
   if (ref($currentValue) =~ /HASH/) {
      $vdLogger->Debug("Start comparing hashes");
      foreach my $key (keys %$currentValue) {
         #
         # If leaf node is HASH or
         # ARRAY recurse again
         #
         if ((ref($currentValue->{$key}) =~ /HASH/) ||
             (ref($currentValue->{$key}) =~ /ARRAY/)) {
            $result = $self->GetDiffBetweenDataStructures($currentValue->{$key},
                                                        $previousValue->{$key});
            if ($result eq "FAILURE") {
               $vdLogger->Error("Diff failed for hash expectedValue");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
            $currentValue->{$key} = $result;
         } else {
            #
            # If leaf node is string
            #
            $result = $self->DeltaDiff($currentValue->{$key},
                                       $previousValue->{$key});
            if ($result eq "FAILURE") {
               $vdLogger->Error("DeltaDiff operation failed");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
            $currentValue->{$key} = $result;
         }
      }
   } elsif (ref($currentValue) =~ /ARRAY/) {
      #
      # Start for ARRAY
      #
      my $result = FAILURE;
      my $indexCondition = 0;
      foreach my $elementExpectedValue (@$currentValue) {
         $vdLogger->Debug("Checking for element number $indexCondition ".
                          "in user data");
         foreach my $elementActualValue (@$previousValue) {
            my $conditionInput  =  $elementExpectedValue;
            my $finalInput = $elementActualValue;
            $vdLogger->Debug("Start comparing arrays");
            $result = $self->GetDiffBetweenDataStructures($conditionInput,
                                                          $finalInput);
            if ($result eq "FAILURE") {
               $vdLogger->Error("Diff failed for array expectedValue");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
         }
         $indexCondition++;
      }
   } else {
      #
      # if leaf node is string
      #
      $vdLogger->Warn("Not doing diff for individual elements, " .
                      "only for key/value pair");
      return $currentValue;
   }
   return $currentValue;
}
1;
