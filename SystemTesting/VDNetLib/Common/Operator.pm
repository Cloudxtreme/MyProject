##############################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
##############################################################################
package VDNetLib::Common::Operator;

use strict;
use warnings;

use English;
use Data::Dumper;
use Net::IP;
use Storable 'dclone';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                             LoadInlinePythonModule);
use Inline::Python qw(py_call_function);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS CONTINUE SUCCESS_OR_FAILURE);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant OPERATORHASH => {
 '>'  =>  {
  'method' => "GreaterThan",   # name of the method which will be used
                               # by the operator.
  'replaceWithServer' => "yes" # option of replacing user value with
                               # server value. Usually set to 'yes'.
                               # 'no' only for operators like not_contains
                               # or not_equal to.
 },
 '==' =>  {
  'method' => "EqualTo",
  'replaceWithServer' => "yes"
 },
 'equal_to' =>  {
  'method' => "EqualTo",
  'replaceWithServer' => "yes"
 },
 'not_equal_to' =>  {
  'method' => "NotEqualTo",
  'replaceWithServer' => "yes"
 },
 '<'  =>  {
  'method' => "LessThan",
  'replaceWithServer' => "yes"
 },
 '!=' =>  {
  'method' => "NotEqualTo",
  'replaceWithServer' => "no"
 },
 'exists' =>  {
  'method' => "Exists",
  'replaceWithServer' => "yes"
 },
 'defined' =>  {
  'method' => "Defined",
  'replaceWithServer' => "yes"
 },
 'not_defined' =>  {
  'method' => "NotDefined",
  'replaceWithServer' => "yes"
 },
 'contains' =>  {
  'method' => "Contains",
  'replaceWithServer' => "yes"
 },
 'contain_once' =>  {
  'method' => "ContainOnce",
  'replaceWithServer' => "yes"
 },
 'not_contains' =>  {
  'method' => "NotContains",
  'replaceWithServer' => "no"
 },
 'boolean'      =>  {
  'method' => "Boolean",
  'replaceWithServer' => "yes"
 },
 'match'      =>  {
  'method' => "Match",
  'replaceWithServer' => "yes"
 },
 'ip_range' => {
  'method' => "IPRange",
  'replaceWithServer' => "yes"
 },
 '[]' => {
  'method' => "IPRange",
  'replaceWithServer' => "yes"
 },
 'not_match'      =>  {
  'method' => "NotMatch",
  'replaceWithServer' => "no"
 },
  'file_equal_to' =>  {
  'method' => "FileEqualTo",
  'replaceWithServer' => "yes"
 },
 'is_between' => {
  'method' => "IsBetween",
  'replaceWithServer' => "yes"
 },
 'contain_once_reverse' =>  {
  'method' => "ContainOnceReverse",
  'replaceWithServer' => "yes"
 },
 'super_set' => {
  'method' => "SuperSet",
  'replaceWithServer' => "no"
 },
};

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;
   $self = {};
   bless ($self, $class);
   $self->{operatorhash} = $self->OPERATORHASH;
   return $self;
}

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass});
   };

   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}

sub Exists
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ((defined $actualValue) || ($actualValue ne '')) {
      $vdLogger->Info("User data: $actualValue is defined");
      return SUCCESS;
   } else {
      $vdLogger->Error("User data: $actualValue is not defined");
      return FAILURE;
   }
}


sub Defined
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ((defined $actualValue) || ($actualValue ne '')) {
      $vdLogger->Info("User data: $actualValue is defined");
      return SUCCESS;
   } else {
      $vdLogger->Error("User data: $actualValue is not defined");
      return FAILURE;
   }
}


sub NotDefined
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ((not defined $actualValue) || ($actualValue eq '')) {
      $vdLogger->Info("User data: $actualValue not defined");
      return SUCCESS;
   } else {
      $vdLogger->Error("User data: $actualValue is defined");
      return FAILURE;
   }
}


sub Boolean
{
   my $self           = shift;
   my $expectedValue  = shift;
   my $actualValue     = shift;
   if ((defined $actualValue) && (lc($actualValue) eq "true")) {
      $vdLogger->Info("User data is boolean type with value = true");
      return SUCCESS;
   } elsif ((defined $actualValue) && (lc($actualValue) eq "1"))  {
      $vdLogger->Info("User data is boolean type with value = 1");
      return SUCCESS;
   } elsif ((defined $actualValue) && (lc($actualValue) eq "0"))  {
      $vdLogger->Info("User data is boolean type with value = 0");
      return SUCCESS;
   } elsif ((defined $actualValue) && (lc($actualValue) eq "false"))  {
      $vdLogger->Info("User data is boolean type with value = false");
      return SUCCESS;
   } elsif (defined $actualValue) {
      $vdLogger->Error("User data is defined but the value" .
                       " is not boolean in nature = $actualValue");
      return FAILURE;
   } else {
      $vdLogger->Error("User data: $actualValue is not defined");
      return FAILURE;
   }
}



sub Contains
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   my $result = FAILURE;
   $vdLogger->Warn("Currently contains only works at global level and " .
                   "at nested levels");
   $result = $self->RecurseThroughDataStructure($expectedValue,
                                                $actualValue,
                                                "contains");

   if ($result eq SUCCESS) {
      $vdLogger->Info("Success\!!! Server data contains the user data");
      return SUCCESS;
   } else {
      $vdLogger->Error("Failure\!!! data does not contain the user data");
      return FAILURE;
   }

}


sub NotContains
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;

   my $result = FAILURE;
   if (ref($expectedValue) ne ref($actualValue)) {
      $vdLogger->Error("expectedValue reftype ref($expectedValue) is not " .
                       "equal to actualValue reftype ref($actualValue)");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (ref($expectedValue) =~ /HASH/) {
      # based on requirement, for hash only consider both expectedValue and
      # actualValue have one key, and their value should be ARRAY type
      # for SCALAR type value, please use not_equal_to
      foreach my $key (keys %$expectedValue) {
         if (!exists $actualValue->{$key}) {
            $vdLogger->Warn("key $key doesn't exist in server data");
            return FAILURE;
         }
         if ((not defined $expectedValue->{$key}) &&
             (defined $actualValue->{$key})) {
            next;
         }
         if ((not defined $actualValue->{$key}) &&
             (defined $expectedValue->{$key})) {
            next;
         }
         if ((not defined $actualValue->{$key}) &&
             (not defined $expectedValue->{$key})) {
            $vdLogger->ERROR("Both values for $key are undef");
            return FAILURE;
         }
         if (ref($expectedValue->{$key}) =~ /ARRAY/) {
            $result = $self->NotContains($expectedValue->{$key},
                                         $actualValue->{$key});
            if ($result eq FAILURE) {
               $vdLogger->Error("Compare operation failed for key: $actualValue->{$key}");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
         } else {
               $vdLogger->Error("Inner structure not support HASH/SCALAR type,
                   Currently only support ARRAY type");
               VDGetLastError("EOPFAILED");
               return FAILURE;
         }
      }
   } elsif (ref($expectedValue) =~ /ARRAY/) {
      foreach my $individualExpectedValue (@{$expectedValue}) {
         foreach my $individualActualValue (@{$actualValue}) {
            $result = $self->RecurseThroughDataStructure($individualExpectedValue,
                                                         $individualActualValue,
                                                         "not_contains");
            if ($result eq FAILURE) {
               $vdLogger->Error("Failure\!!! Server data contains user data");
               return FAILURE;
            }
         }
      }
   }
   $vdLogger->Info("Success\!!! Server data doesn't have the user data");
   return SUCCESS;
}


sub LessThan
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ($expectedValue > $actualValue) {
      $vdLogger->Info("User data: $expectedValue is greater than the " .
                      "server data: $actualValue");
      return SUCCESS;
   } else {
      $vdLogger->Error("User data: $expectedValue is less than the " .
                       "server data: $actualValue");
      return FAILURE;
   }

}


sub GreaterThan
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ($expectedValue < $actualValue) {
      $vdLogger->Info("User data: $expectedValue is less than the " .
                       "server data: $actualValue");
      return SUCCESS;
   } else {
      $vdLogger->Error("User data: $expectedValue is more than the " .
                       "server data: $actualValue");
      return FAILURE;
   }

}


sub NotEqualTo
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   my $loggingLevel = do { @_ ? shift : VDNetLib::Common::VDLog::ERROR };
   if ($expectedValue ne $actualValue) {
      $vdLogger->Info("User data: $expectedValue is not equal to " .
                      "server data: $actualValue");
      return SUCCESS;
   } else {
      $vdLogger->LogCommon($loggingLevel, "User data: $expectedValue is " .
                      "equal to server data: $actualValue");
      return FAILURE;
   }

}



sub RecurseThroughDataStructure
{
   my $self           = shift;
   my $expectedValue  = shift;
   my $actualValue    = shift;
   my $condition      = shift;

   my $result = FAILURE;
   if (ref($expectedValue) ne ref($actualValue)) {
      $vdLogger->Error("expectedValue reftype ref($expectedValue) is not " .
                       "equal to actualValue reftype ref($actualValue)");
      $vdLogger->Error("expectedValue: " . Dumper($expectedValue));
      $vdLogger->Error("actualValue: " . Dumper($actualValue));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (ref($expectedValue) =~ /HASH/) {
      if (ref($actualValue) !~ /HASH/) {
         $vdLogger->Error("$actualValue is not a hash type");
         return FAILURE;
      }
      my $keyIndex = 0;
      my $keysCount = keys %$expectedValue;
      foreach my $key (keys %$expectedValue) {
         $keyIndex = $keyIndex + 1;
         if ((!exists $actualValue->{$key}) && ($condition ne "not_contains")) {
            $vdLogger->Error("key $key \'$actualValue->{$key}\' doesn't exist in server data");
            return FAILURE;
         }
         if ((not defined $expectedValue->{$key}) &&
             (defined $actualValue->{$key})) {
            next;
         }
         if ((not defined $actualValue->{$key}) &&
             (defined $expectedValue->{$key})) {
            if ((defined $condition) && ($condition eq "not_contains")) {
                return SUCCESS;
            } else {
                $vdLogger->Error("key=\'$actualValue->{$key}\' doesn't exist in server data,
                                but exists in user data");
                return FAILURE;
            }
         }

         # Since in python layer, when a field doesn't exist,
         # it will return something like 'switch_vni' => undef .
         # The following code is added to handle the following situation,
         # when both userdata and serverdata should contains the hash with value "undef",
         # which means the record shouldn't exist on the server:
         #
         # expectedValue: $VAR1 = {
         #  'replication_mode' => undef,
         #  'switch_vni' => undef
         # };
         # actualValue: $VAR1 = {
         #  'controller_ip' => undef,
         #  'replication_mode' => undef,
         #  'switch_vni' => undef,
         #  'controller_status' => undef
         # };
         #
         # Under this circumstance, the contains/contain_once should return true.
         if ((not defined $actualValue->{$key}) &&
             (not defined $expectedValue->{$key})) {
            $vdLogger->Debug("Both values for $key are undef");
         }
         if ((ref($expectedValue->{$key}) =~ /HASH/) ||
             (ref($expectedValue->{$key}) =~ /ARRAY/)) {
            $result = $self->RecurseThroughDataStructure($expectedValue->{$key},
                                                         $actualValue->{$key},
                                                         $condition);
            if ($result eq FAILURE) {
               $vdLogger->Error("Compare operation failed for key: $actualValue->{$key}");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
            return $result;
         } else {
            if ((defined $condition) && ($condition ne "not_contains")) {
               $vdLogger->Debug("Check if expected value is equal to actual value" .
                               " for key \'$key\'");
               $result = $self->EqualTo($expectedValue->{$key},
                                        $actualValue->{$key},
                                        VDNetLib::Common::VDLog::INFO);
            } else {
               $vdLogger->Debug("Check if expected value is not equal to actual value" .
                               " for key \'$key\'");
               $result = $self->NotEqualTo($expectedValue->{$key},
                                           $actualValue->{$key},
                                           VDNetLib::Common::VDLog::INFO);
            }
            if ($result eq FAILURE) {
               if ((defined $condition) && ($condition eq "not_contains")
                                        && ($keyIndex < $keysCount)) {
               # handle not_contains operator here
               # if not_contains is used for hash, then compare only one key
               # failed should be counted as all comparsion failed, for example:
               # both user data and server data include "adapter_ip=192.168.1.12"
               # so when compared to adapter_ip, they are equals, but we cannot
               # make final comparsion result as FAILED. Because their 'adapter_mac'
               # are not the same, so the final comparsion result should be
               # 'SUCCESS'
               # - User Data:
               #       'table' => [
               #                    {
               #                      'adapter_ip' => '192.168.1.12',
               #                      'adapter_mac' => 'ff:ff:ff:ff:ff:ff'
               #                    }
               #                  ]
               #     };
               # - Server Data:
               #       'table' => [
               #                    {
               #                      'adapter_mac' => '00:0c:29:89:29:12',
               #                      'adapter_ip' => '192.168.1.12'
               #                    },
               #                    {
               #                      'adapter_mac' => '00:0c:29:7c:ad:aa',
               #                      'adapter_ip' => '192.168.1.56'
               #                    },
               #                  ]
               #     };
                    $vdLogger->Warn("Compare key=$key failed since they are " .
                                    "equals in user data and server data, now " .
                                    "will compare next key value");
                    next;
               }
               $vdLogger->Debug("Compare operation failed for key $key: $actualValue->{$key}");
               return $result;
            } else {
               if ((defined $condition) && ($condition eq "not_contains")) {
               # for not_contains, if the current key value is not the same, then
               # no need to compare the next key
                   last;
               }
               $vdLogger->Debug("Compare operation passed for key $key: $actualValue->{$key}," .
                               " lets compare next key");
               next;
            }
         }
      }
   } elsif (ref($expectedValue) =~ /ARRAY/) {
      if (ref($actualValue) !~ /ARRAY/) {
         $vdLogger->Error("user data is of type array but server data" .
                          " is not of array");
         $vdLogger->Error("User Data:" . Dumper($expectedValue));
         $vdLogger->Error("Server Data:" . Dumper($actualValue));
         return FAILURE;
      }

      if ((scalar(@$expectedValue) !=  scalar(@$actualValue)) &&
         ($condition eq "equal_to")) {
         $vdLogger->Error("number of elements in user data array dont match" .
                          " with no of elements in server data");
         $vdLogger->Error("User Data:" . Dumper($expectedValue));
         $vdLogger->Error("Server Data:" . Dumper($actualValue));
         return FAILURE;
      }

      my @resultArray;
      foreach my $elementexpectedValue (@$expectedValue) {
         # Start checking actual values from beginning. Reset index.
         my $actualValueIndex = 0;
         # Before starting to iterate over $expectedValue, check if there is
         # any $actualValue left to compare with.
         if (scalar(@$actualValue) == 0) {
            $vdLogger->Error("No server data left for comparison.");
            $vdLogger->Error("User Data:" . Dumper($expectedValue));
            $vdLogger->Error("Server Data:" . Dumper($actualValue));
         }
         $result = FAILURE;
         foreach my $elementactualValue (@$actualValue) {
            my $conditionInput  =  $elementexpectedValue;
            my $finalInput = $elementactualValue;
            $result = $self->RecurseThroughDataStructure($conditionInput,
                                                         $finalInput,
                                                         $condition);
            if ($result eq SUCCESS) {
               $vdLogger->Info(
                  "User data matched against an entry in server data.");
               $vdLogger->Info(
                  "Now delete this entry to avoid comparing multiple user " .
                  "data entries with same server data entry.");
               splice(@$actualValue, $actualValueIndex, 1);
               last;
            }
            if ((defined $condition) && ($condition eq "contains") &&
                ($result eq FAILURE)) {
               # Did not find a match with this actual entry, check the next.
               # Hence increment index.
               $actualValueIndex = $actualValueIndex + 1;
               next;
            }
            if ($result eq FAILURE) {
               $vdLogger->Error("Compare failed for array expectedValue");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
         }
         if (($result eq FAILURE) && (defined $condition)) {
            $vdLogger->Error("Verification of user data and server data" .
                             "failed for condition= $condition");
            VDGetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   } else {
      if ((defined $condition) && ($condition ne "not_contains")) {
         $result = $self->EqualTo($expectedValue,$actualValue,
                                  VDNetLib::Common::VDLog::INFO);
      } else {
         $result = $self->NotEqualTo($expectedValue,$actualValue,
                                     VDNetLib::Common::VDLog::INFO);
      }
      if ($result eq FAILURE) {
         $vdLogger->Error("Compare operation failed");
         return FAILURE;
      }
   }
   return $result;
}

sub ContainOnceReverse
{
   my $self           = shift;
   my $expectedValue  = shift;
   my $actualValue    = shift;

   return $self->ContainOnce($actualValue,$expectedValue);
}

sub ContainOnce
{
   my $self           = shift;
   my $expectedValue  = shift;
   my $actualValue    = shift;

   my $result = FAILURE;
   if (ref($expectedValue) ne ref($actualValue)) {
      $vdLogger->Error("expectedValue reftype ref($expectedValue) is not " .
                       "equal to actualValue reftype ref($actualValue)");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (ref($expectedValue) =~ /HASH/) {
      foreach my $key (keys %$expectedValue) {
         if (!exists $actualValue->{$key}) {
            $vdLogger->Warn("key $key doesn't exist in server data");
            return FAILURE;
         }
         if ((not defined $expectedValue->{$key}) &&
             (defined $actualValue->{$key})) {
            next;
         }
         if ((not defined $actualValue->{$key}) &&
             (defined $expectedValue->{$key})) {
            $vdLogger->Warn("key=\'$actualValue->{$key}\' doesn't exist in server data");
            return FAILURE;
         }
         if ((not defined $actualValue->{$key}) &&
             (not defined $expectedValue->{$key})) {
            $vdLogger->Debug("Both values for $key are undef");
         }
         if ((ref($expectedValue->{$key}) =~ /HASH/) ||
             (ref($expectedValue->{$key}) =~ /ARRAY/)) {
            $result = $self->ContainOnce($expectedValue->{$key},
                                         $actualValue->{$key});
            if ($result eq FAILURE) {
               $vdLogger->Warn("Compare operation failed for key:" . $key);
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
         } else {
            $result = $self->EqualTo($expectedValue->{$key}, $actualValue->{$key}, "Info");
            if ($result eq FAILURE) {
               $vdLogger->Debug("User value didnt match with server value");
               return $result;
            } else {
               $vdLogger->Debug("Continue to check for remaining keys");
               next;
            }
         }
      }
   } elsif (ref($expectedValue) =~ /ARRAY/) {
      # Check if both server/user data contains just empty list.
      if ((scalar(@$expectedValue) ==  scalar(@$actualValue)) &&
          (scalar(@$expectedValue) == 0))  {
         $result = SUCCESS;
      }
      foreach my $elementexpectedValue (@$expectedValue) {
         my $duplicate = 0;
         foreach my $elementactualValue (@$actualValue) {
            $result = $self->ContainOnce($elementexpectedValue,
                                         $elementactualValue);
            if (($result eq SUCCESS) && ($duplicate == 0)) {
               $vdLogger->Info("User data matched against " .
                               "an entry in server data, now check for duplicate entries");
               $duplicate++;
               next;
            }
            if ($result eq SUCCESS) {
               $vdLogger->ERROR("Duplicate entry in server data found!!!");
               $duplicate++;
               last;
            }
            if ($result eq FAILURE) {
               $vdLogger->Debug("Continue to check for next element in actual value");
               next;
            }
         }
         if ($duplicate == 0) {
            $vdLogger->Warn("In server data, no entry found for" .
                             " user data " . Dumper ($elementexpectedValue));
            VDSetLastError("EOPFAILED");
            return FAILURE;
         } elsif ($duplicate > 1) {
            $vdLogger->Warn("In server data, duplicate entry found for" .
                             " user data " . Dumper ($elementexpectedValue));
            VDSetLastError("EOPFAILED");
            return FAILURE;
         } else {
            $vdLogger->Info("In server data, no duplicate entry found for" .
                             " user data " . Dumper ($elementexpectedValue));
            $result = SUCCESS;
            next;
         }
      }
   } else {
      $result = $self->EqualTo($expectedValue, $actualValue, "Info");
      if ($result eq FAILURE) {
         $vdLogger->Debug("User string didnt match with server string");
         return $result;
      } else {
         $vdLogger->Debug("Continue to check for remaining keys");
         return SUCCESS;
      }
   }
   return $result;
}


sub CompareUndefAndType
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;

   if((not defined $expectedValue) && (not defined $actualValue)) {
      $vdLogger->Debug("In EqualTo Both expectedValue and actualValue are undefined.");
      return SUCCESS;
   }
   if((defined $expectedValue) && (not defined $actualValue)) {
      $vdLogger->Error("expectedValue $expectedValue is not " .
                       "equal to actualValue *UNDEFINED*");
      return FAILURE;
   }
   if (ref($expectedValue) ne ref($actualValue)) {
      $vdLogger->Error("expectedValue reftype ref($expectedValue) is not " .
                       "equal to actualValue reftype ref($actualValue)");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return CONTINUE;
}


sub EqualTo
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   my $loggingLevel = do { @_ ? shift : VDNetLib::Common::VDLog::ERROR };

   my $result = FAILURE;

   if ($self->CompareUndefAndType($expectedValue, $actualValue) =~ SUCCESS_OR_FAILURE) {
        return $MATCH;
   }
   if (ref($expectedValue) =~ /HASH/) {
      foreach my $key (keys %$expectedValue) {
         if (!exists $actualValue->{$key}) {
            $vdLogger->Warn("key $key doesn't exist in server data");
            return FAILURE;
         }

         if ((not defined $actualValue->{$key}) &&
            (not defined $expectedValue->{$key})) {
            $vdLogger->Warn("Values for key $key is undefined in both" .
                            "expected and actual values");
            next;
         } elsif (((not defined $actualValue->{$key}) &&
                  (defined $expectedValue->{$key})) ||
                  ((defined $actualValue->{$key}) &&
                  (not defined $expectedValue->{$key}))) {
            $vdLogger->Error("key=\'$actualValue->{$key}\' doesn't exist in" .
                             "either user data or server data");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         my $hash = ref($expectedValue->{$key});
         if ((ref($expectedValue->{$key}) =~ /HASH/) ||
             (ref($expectedValue->{$key}) =~ /ARRAY/)) {
            $vdLogger->Debug("Key=$key has a complex datastructure as value");
            $result = $self->EqualTo($expectedValue->{$key},
                                     $actualValue->{$key});
            if ($result eq FAILURE) {
               $vdLogger->Error("Compare operation failed for key: $actualValue->{$key}");
               VDGetLastError("EOPFAILED");
               return FAILURE;
            }
         } else {
            if ($expectedValue->{$key} eq $actualValue->{$key}) {
               $vdLogger->Info("User data: $expectedValue->{$key} is equal to " .
                                "server data: $actualValue->{$key}");
               $result = SUCCESS;
               next;
            } else {
               $vdLogger->LogCommon($loggingLevel, "User data: " .
                                    "$expectedValue->{$key} is not equal to " .
                                    "server data: $actualValue->{$key}");
               return FAILURE;
            }
         }
      }
   } elsif (ref($expectedValue) =~ /ARRAY/) {
      if (ref($actualValue) !~ /ARRAY/) {
         $vdLogger->Error("expected data is of type array but server data" .
                          " is not of array");
         $vdLogger->Error("expected Data:" . Dumper($expectedValue));
         $vdLogger->Error("Server Data:" . Dumper($actualValue));
         return FAILURE;
      }
      if (scalar(@$expectedValue) !=  scalar(@$actualValue)) {
         $vdLogger->Error("number of elements in expected data array dont match" .
                          " with no of elements in server data");
         $vdLogger->Error("expected Data:" . Dumper($expectedValue));
         $vdLogger->Error("Server Data:" . Dumper($actualValue));
         return FAILURE;
      }
      my $copyActualValue = $actualValue;
      my $index = 0;
      # Needs to start as SUCCESS for empty arrays
      $result = SUCCESS;
      foreach my $elementexpectedValue (@$expectedValue) {
         foreach my $elementactualValue (@$copyActualValue) {
            $result = $self->EqualTo($elementexpectedValue,
                                     $elementactualValue);
            if ($result eq SUCCESS) {
               $vdLogger->Info("User data matched against " .
                               "an entry in server data");
               splice @$copyActualValue, $index, 1;
               last;
            }
            if ($result eq FAILURE) {
               $vdLogger->Debug("Compare failed between expected and" .
                                " actual array element ");
               $vdLogger->Error("expected Data:" . Dumper($elementexpectedValue));
               $vdLogger->Error("Server Data:" . Dumper($elementactualValue));
               return FAILURE;
            }
            $index++;
         }
         if ($result eq SUCCESS) {
            $vdLogger->Info("User data matched against " .
                            "an entry in server data");
            next;
         }
      }
   } else {
      if ($expectedValue eq $actualValue) {
         $vdLogger->Info("User data: $expectedValue is equal to " .
                          "server data: $actualValue");
         return SUCCESS;
      } else {
         $vdLogger->LogCommon($loggingLevel, "User data: $expectedValue " .
                                  "is not equal to server data: $actualValue");
         return FAILURE;
      }
   }
   return $result;
}


sub Match
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ((ref($expectedValue) !~ /HASH|ARRAY/) && (ref($actualValue) !~ /HASH|ARRAY/)) {
      $actualValue =~ s/[\s|\t]+//g;
      $expectedValue =~ s/[\s|\t]+//g;
      if ($actualValue =~ /$expectedValue/i) {
         $vdLogger->Info("User data: $expectedValue matched " .
                         "server data $actualValue");
         return SUCCESS;
      } else {
         $vdLogger->Error("User data: $expectedValue didn't match " .
                          "server data $actualValue");
         return FAILURE;
      }
   }
   $vdLogger->Error("Match operator functionality only supports strings");
   return FAILURE;
}


sub NotMatch
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   if ((ref($expectedValue) !~ /HASH|ARRAY/) && (ref($actualValue) !~ /HASH|ARRAY/)) {
      if ($actualValue =~ /$expectedValue/i) {
         $vdLogger->Error("User data: $expectedValue matched " .
                          "server data $actualValue");
         return FAILURE;
      } else {
         $vdLogger->Info("User data: $expectedValue didn't match " .
                         "server data $actualValue");
         return SUCCESS;
      }
   }
   $vdLogger->Error("NotMatch operator functionality only supports strings");
   return FAILURE;
}

sub IPRange
{
   my $self           = shift;
   my $expectedValue = shift;
   my $actualValue     = shift;
   my $range;
   my $ip;
   if ((ref($expectedValue) !~ /HASH|ARRAY/) &&
       (ref($actualValue) !~ /HASH|ARRAY/)) {
      eval {
         $range = Net::IP->new($expectedValue);
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while creating " .
                       "an IP object of $expectedValue:\n". $@);
         return FAILURE;
      }
      eval {
         $ip = Net::IP->new($actualValue);
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while creating " .
                          "an IP object of $actualValue:\n". $@);
         return FAILURE;
      }
      if ($range->overlaps($ip)) {
         $vdLogger->Info("Server data: $actualValue is in the " .
                         "given user data IP range $expectedValue");
         return SUCCESS;
      } else {
         $vdLogger->Info("Server data: $actualValue is not in the given " .
                         "user data IP range $expectedValue");
         return FAILURE;
      }
   }
   $vdLogger->Error("IPRange operator functionality only supports strings");
   return FAILURE;
}

sub FileEqualTo
{
   my ($self, $function_name, $args) = @_;
   eval {
      LoadInlinePythonModule('operators_utilities');
   };
   if ($@) {
      $vdLogger->Info("Exception thrown while loading " .
                       "inline component of operators_utilities:\n". $@);
      return FAILURE;
   }
   my $result = py_call_function("operators_utilities",
                                 "file_equal_to",
                                 $args,
                                 $function_name);
   $vdLogger->Info("Result of operators_utilities: ". $result);
   return $result;
}

sub IsBetween
{
   my ($self, $function_name, $args) = @_;
   eval {
      LoadInlinePythonModule('operators_utilities');
   };
   if ($@) {
      $vdLogger->Info("Exception thrown while loading " .
                       "inline component of operators_utilities:\n". $@);
      return FAILURE;
   }
   my $result = py_call_function("operators_utilities",
                                 "is_between",
                                 $args,
                                 $function_name);
   $vdLogger->Info("Result of operators_utilities: ". $result);
   return $result;
}

sub SuperSet
{
   my ($self, $function_name, $args) = @_;

   eval {
      LoadInlinePythonModule('operators_utilities');
   };
   if ($@) {
      $vdLogger->Info("Exception thrown while loading " .
                       "inline component of operators_utilities:\n". $@);
      return FAILURE;
   }
   my $result = py_call_function("operators_utilities",
                                 "super_set",
                                 $args,
                                 $function_name);
   $vdLogger->Info("Result of operators_utilities: ". $result);
   return $result;
}

1;
