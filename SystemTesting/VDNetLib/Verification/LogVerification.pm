#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::LogVerification;

#
# This module gives object of Log verification. It deals with gathering
# log before the start of test and after the test and checks for strings and
# patterns in the diff of the log.
#

# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

my @operationalKeys = qw(sleepbeforefinal);
###############################################################################
#
# new -
#       This method returns the handle to object of LogVerification.
#       Also set the list of children if a user has defined so.
#
# Input:
#       none.
#
# Results:
#       Obj of LogVerification module - in case everything goes well.
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

   #
   # We need this hash to decide how many childrens to create
   # as per given by user.
   # it will be in verification Hash -> logtype
   #
   if (not defined $options{verihash}) {
      $vdLogger->Error("Verification Hash missing in new()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self  = {
     'verihash'    => $options{verihash},
   };
   bless ($self, $class);

   #
   # LogVerification finds his list of children from logtype var defined
   # by user. If not defined, then a default list of childrens will be used.
   #
   if (defined $self->{verihash}->{logtype}) {
      $self->{childrens} = $self->{verihash}->{logtype};
   }

   return $self
}


###############################################################################
#
# InitVerification -
#       Initialize verification on this object. A log type may have different
#       nodes e.g. var log has kern.log, messages, daemon etc. We store these
#       nodes as per OS. This selects the nodes according to the target os
#       for each type of log verification.
#
# Input:
#       None
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
   my $myOS = $self->{os};
   my $veriType = $self->{veritype};
   my $targetNode = $self->{nodeid};

   # Check if all the required params are defined or not
   my $allparams = $self->RequiredParams();
   foreach my $param (@$allparams) {
      if(not exists $self->{$param}) {
      $vdLogger->Error("Param:$param missing in InitVerification for $veriType".
                       "Verification");
      VDSetLastError("ENOTDEF");
      return FAILURE;
      }
   }

   #
   # Remove the key as it is not related to expectedchange, expectedchange
   # should only contain the output, values etc which user is expecting
   # from the command/API
   #
   foreach my $key (@operationalKeys) {
      if ((exists $self->{expectedchange}->{$key}) ||
          (exists $self->{expectedchange}->{lc($key)})) {
         $self->{$key} = $self->{expectedchange}->{$key} ||
                         $self->{expectedchange}->{lc($key)};
         delete $self->{expectedchange}->{$key};
         delete $self->{expectedchange}->{lc($key)};
      }
   }

   # 1) Get the default log types from template.
   # 2) Keep the ones supported by target os. delete the rest.
   my $logList;
   my $allLogTypes = $self->GetDefaultLogType();
   foreach my $os (keys %$allLogTypes) {
      next if $os !~ /$myOS/i;
      # Get the log types corresponding to the target os type.
      $logList = $allLogTypes->{$os};
      last;
   }
   $self->{logbucket}->{logs} = $logList;
   return SUCCESS;

}


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
   my $ret;

   if (not defined $state){
      $state = "initial";
   }

   # For all logs, if the log type is supported by the target
   # then get the values of all the counters on that node.
   my $logList = $self->{logbucket}->{logs};
   foreach my $logType (keys %$logList) {
      $vdLogger->Info("Gathering $state $logType log for ".
                      "($self->{nodeid}) on $self->{targetip}");
      my $logHash = $logList->{$logType};
      #
      # A log type stores the method and obj by which that log
      # can be obtained. E.g.
      # "dmesg" => {
      #      'method'   => 'GetDmesgLogs',
      #      'obj'      => 'vmopsobj',
      #   },
      #
      if ((defined $logHash->{obj}) && (defined $logHash->{method})){
         my ($objPtr, $method, @value, $dstFileName);
         #
         # Generating the destination file name with the log type
         # intial or final state and the log directory given by parent.
         #
         $dstFileName = $self->{target} . "-" . $logType . ".log";
         $dstFileName =  $dstFileName . "-" . $state;
         $dstFileName =  $self->{localLogsDir} . $dstFileName;
         $vdLogger->Trace("$state $logType log filename: $dstFileName");
         #
         # Generating the obj->Method(parameters) to get the logs
         # from the remote machine.
         #
         $objPtr = $logHash->{obj};
         $method = $logHash->{method};
         push(@value, $dstFileName);
         if(defined $self->{$objPtr}) {
            my $obj = $self->{$objPtr};
            $ret = $obj->$method(@value);
            if($ret eq FAILURE || $ret =~ /unsupported/) {
               $vdLogger->Error("ExecuteStatsCmd failed for ".
                                "$self->{targetip}:$self->{nodeid}");
               VDSetLastError("EFAILED");
               return FAILURE;
            }
            my $resultHash;
            $resultHash->{$logType} = $dstFileName;
            $logHash->{$state} = $resultHash;
         } else {
            $vdLogger->Error("ObjPtr:$objPtr required for method:$method is ".
                             "missing in self ");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("$logType"."'s GetLog method missing for ".
                      "($self->{nodeid}) on $self->{targetip}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
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
   if (defined $self->{sleepbeforefinal}) {
      $vdLogger->Info("Waiting for $self->{sleepbeforefinal} sec before ".
                      "gathering final logs...");
      sleep(int($self->{sleepbeforefinal}));
   }
   my $ret = $self->Start("final");
   if($ret ne SUCCESS) {
      $vdLogger->Error("Stop on $self->{veritype} log for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# ProcessExpectationHash -
#       Overriding parent method just to save processing time.
#
# Input:
#       None
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   return SUCCESS;
}


###############################################################################
#
# SetExpectations -
#       Sets the expectation type and expectation value on log strings of the
#       template log hash.
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
   my $expectationType = shift;

   my $allLogs;
   if($expectedKey !~ /present/i) {
      # Log Verification is only interested in keys whose value is
      # 'present' or 'notpresent' as of now which means user expects
      # a string to be present or not present in the log file.
      return SUCCESS;
   }

   my $bucket = $self->GetBucket();
   foreach my $logsInBucket (keys %$bucket) {
      $allLogs = $bucket->{$logsInBucket};
      foreach my $logType (keys %$allLogs) {
         # for each log set the string and its exptectation type in
         # the template hash.
         if (ref($expectedValue) !~ /ARRAY/) {
            $vdLogger->Error('key = ["", ""]' . "is the supported format for all".
                             " log verification");
            VDSetLastError("EINVALID");
            return FAILURE;
         } else {
            #
            # User gives input in this format StringPresent = ["string_content"],
            # Internally we store it as string_content = "stringpresent"
            # as there might be array of multiple string and we cannot use
            # stringpresent as key for all these strings
            #
            foreach (@$expectedValue) {
               $allLogs->{$logType}->{template}->{$_} =
                                          $expectedKey . ":" .$expectationType;
            }
         }
      } # end of allNodes
   } # end of bucket

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
   # 1) Perform a diff of intial and final log file.
   my $ret = $self->DoDiff();
   if($ret ne SUCCESS) {
      $vdLogger->Error("Performing diff on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # 2) Compare the actual value(diff) with the expected value
   # and set pass/fail for the respective strings in each log file's diff
   $ret = $self->ParseDiffFile();
   if($ret ne SUCCESS) {
      $vdLogger->Error("ParseDiffFile() on $self->{veritype} for ".
                        "target $self->{nodeid} failed");
      return FAILURE;
   }
   return SUCCESS;
}



###############################################################################
#
# PerformActualDiff -
#       Perform a diff on the intial and final log file.
#
# Input:
#       initial Log
#       final Log
#       key - counter name/stats name (optional)
#
# Results:
#       diff - difference in final - intial Log.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub PerformActualDiff
{

   my $self = shift;
   my $initialLog = shift;
   my $finalLog = shift;
   my $logType = shift;
   my $diffLog = $self->{localLogsDir} . $self->{target} . "-$logType".
                 ".log" . "-diff";

   unless(-e $initialLog) {
      $vdLogger->Error("Initial log file:$initialLog is missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   unless(-e $finalLog) {
      $vdLogger->Error("Final log file:$finalLog is missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   # Always do a diff of intial - final and see what was added.
   # We will filter out the difference between added and removed
   # lines during parsing of diff to make sure we don't do false positives
   # in case of log rollovers.
   my $out;
   $out = `diff -c $initialLog $finalLog > $diffLog`;
   if($out ne '') {
      $vdLogger->Trace("diff of log file shows:" . $out);
   }

   if (-e $diffLog) {
      if (-z $diffLog) {
         $vdLogger->Info("Size of $self->{veritype} diff on $self->{nodeid} is 0");
         $vdLogger->Trace("Size of diff:$diffLog for target $self->{nodeid} is 0");
      }
   } else {
      $vdLogger->Error("Diff file:$diffLog not generated");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   return $diffLog;

}


###############################################################################
#
# ParseDiffFile -
#       This method searches the strings given by user in the diff of the logs
#       generated during the intial and final log intervals.
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

sub ParseDiffFile
{
   my $self = shift;

   # Get all the logs from the logs bucket.
   # For each log search the strings in the log's diff files
   # Compare each counter's expected Log and actual value
   # and tag pass/fail on that counter.

   # We will use system's grep utility because if the test is long
   # or log level is high then the diff of the intial - final log
   # would be large and to process such data using perl's file handle
   # won't make sense as it would put the entire date in memory which
   # will create trashing for bigger file sizes.

   # This is to show why we use fgrep (grep -F).
   # fgrep switches off the regex interpretation of grep and thus
   # we can take any string from user to match in the diff file
   # and now worry about escaping his special chars.
   # grep  "0000:0b:00.0[A] -> GSI 19" dmesg-diff
   # grep -F "0000:0b:00.0[A] -> GSI 19" dmesg-diff
   #> ACPI: PCI Interrupt 0000:0b:00.0[A] -> GSI 19 (level, low) -> IRQ 83


   my ($allLogs, $resultHash);
   my $bucket = $self->{logbucket};
   foreach my $logsInBucket (keys %$bucket) {
      $allLogs = $bucket->{$logsInBucket};
      foreach my $logNode (keys %$allLogs) {
         my $logType = $allLogs->{$logNode};
         if (not defined $logType->{diff}) {
            $vdLogger->Error("diff file not defined for $logType for ".
                             "$self->{target}");
            return FAILURE;
         }
         if (not defined $logType->{template}) {
            $vdLogger->Warn("No expectation set for $logType on ".
                            "$self->{target}");
            return FAILURE;
         }
         my ($cmd, $output);
         my $diffHash = $logType->{diff};
         my $tempalateHash = $logType->{template};
         # For each expected counter key in template, comparing it with
         # the actual value.
         my $expectedCounterFound = 0;
         foreach my $string (keys %$tempalateHash) {
            foreach my $logDiff (keys %$diffHash) {
               unless(-e $diffHash->{$logDiff}) {
                  $vdLogger->Trace("Diff log file:$diffHash->{$logDiff} ".
                                   "is missing");
                  return FAILURE;
               }
               #
               # We need this information
               # String
               # Actual Value: present in log or not
               # Expected Value: present in log or not
               # Expected By: User or default
               # Result: pass/fail based on actual and expected
               # No of occurences of the strin in the log
               # log snippets containing the strings.
               #
               $tempalateHash->{$string} =~ m/(.*):(.*)/i;
               $resultHash->{$string}->{expected} = $1;
               $resultHash->{$string}->{expectedby} = $2;

               #TODO: The grep options can be obtained from user also.
               # if not provided use these default options.
               # Caution: There can be side effects.
               $cmd = "grep -ri -F -A 1 -B 1 \"$string\" $diffHash->{$logDiff}";
               $output = `$cmd`;
               # if output does not have anything
               if($output eq "") {
                  # Output is blank thus string is not present
                  $resultHash->{$string}->{actual} = "notpresent";
                  if($tempalateHash->{$string} =~ /notpresent/i) {
                     $resultHash->{$string}->{result} = "pass";
                  } else {
                     $resultHash->{$string}->{result} = "fail";
                  }
               } else {
                  # As string is detected we first strip the various occurences
                  # of the string into snippets.
                  # Then in each snippet we make sure the snippet is not a stale
                  # log entry using CheckLogSnippet, if it is not then we store it
                  my (@logSnippets, $count);
                  if($output =~ /\n--\n/) {
                     @logSnippets = split('\n--\n', $output);
                  } else {
                     $logSnippets[0] = $output;
                  }

                  $count = 1;
                  foreach my $snippet (@logSnippets) {
                     my $present;
                     # Check if the snippet is not just a stale log entry.
                     ($present, $snippet) = $self->CheckLogSnippet($snippet, $string);
                     if ($present == 1) {
                        $resultHash->{$string}->{"occurence".$count} = $snippet;
                        $count++;
                     } else {
                        next;
                     }
                  }

                  # If there is at least one occurence of log snippet matching
                  # the string user wants then we say string is present
                  # We calculate pass fail based on what user had expected.
                  if($count > 1) {
                     # Output is not blank thus string is present
                     $resultHash->{$string}->{actual} = "present";
                     if($tempalateHash->{$string} =~ /(^present|^stringpresent)/i) {
                        $resultHash->{$string}->{result} = "pass";
                     } else {
                        $resultHash->{$string}->{result} = "fail";
                     }
                  } # end of count > 1 if block
               } # end of else block which has $output eq something
            }
         }

         $logType->{result} = $resultHash;
         $resultHash = undef;
         # Freeing up resources to conserve memory.
         delete $logType->{template};
         # Not deleting diff as some other obj might need it for
         # relative comparison of counters.
         if(defined $logType->{initial}) {
            delete $logType->{initial};
         }
         if(defined $logType->{final}) {
            delete $logType->{final};
         }
      }
   }

   return SUCCESS;

}


###############################################################################
#
# CheckLogSnippet -
#       Makes sure the log snippet is not a stale log entry.
#       Trims down the log string so that it can be displayed properly on
#       the screen.
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

sub CheckLogSnippet
{
   my $self = shift;
   my $snippet = shift;
   my $string = shift;
   my ($retStatus, $retString, $lineHash, $line);
   my $stringFoundFlag = 0;

   my (@snippetLines, $count);
   if($snippet =~ /\n/) {
      @snippetLines = split('\n', $snippet);
   } else {
      $snippetLines[0] = $snippet
   }

   $count = 1;
   foreach my $thisSnippet (@snippetLines) {
      $thisSnippet =~ m/^(\<|\>|\+|\-)(.*)?/i;
      my $sign = $1;
      #
      # We ignore the old/stale lines. which are indicated by < which means
      # the expected string was found in lines which are not removed from the
      # diff file Similarly for - sign(it means lines were removed).
      # We are only interested in lines that were added.
      #
      if ((defined $sign) && ($sign !~ /(\<|\-)/)){
         $line = $2;
         if(defined $line) {
            $lineHash->{$count} = $line;
         }
      }
      $count++;
   }

   #
   # This will only contain lines which are added to the log file
   # after taking a diff of intial - final log
   #
   my @lineArray;
   foreach my $lineNo (keys %$lineHash) {
      my $line = $lineHash->{$lineNo};
      # First check if the line is greater than 100 char. If yes, then
      # clip the line from the end.
      # if the line has the string we were looking for in the log
      # then clip is with the search string in the middle.
      my $lineLength = length($line);
      if (int($lineLength) > 100) {
         if ($line =~ /$string/i) {
            # Clip the line around the matching string
            my $strLenght = length($string);
            my $remainingLength = 50 - $strLenght;
            #
            # Matching the first occurence of string and storing rest
            # of the string in parts, trimming them appropriately
            #
            # Working on the part precedding the string
            $line  =~ /(^|.*?)$string?(.*)/i;
            my ($part1, $part2) = ($1, $2);
            if(defined $part1) {
               $lineLength = length($part1);
               if(int($lineLength) > 50) {
                  $part1 =~ /(.{1,50})?/;
                  $part1 = $1;
                  $part1 = " ..." . $part1;
               }
               $line = $part1 . $string;
            }
            # Working on the part after the string
            if(defined $part2) {
               $lineLength = length($part2);
               if(int($lineLength) > 50) {
                  $part2 =~ /(.{1,50})?/;
                  $part2 = $1;
                  $part2 = $part2 . " ...";
               }
               if(defined $part1) {
                  $line = $line . $part2;
               } else {
                  $line = $string . $part2;
               }
            }
         } else {
            # Clip the end portion of the line(Starting of line
            # gives more context)
            $line =~ /(.{1,100})?/;
            $line = $1;
            $line = $line . " ...";
         }
      }
      $lineHash->{$lineNo} = $line;
   }

   my $finalStr = "";
   foreach my $lineNo (sort keys %$lineHash) {
      my $line = $lineHash->{$lineNo};
      $line =  ">". $line . "\n";
      $finalStr = $finalStr . $line;
   }

   if ($finalStr =~ /$string/i) {
      $retString = $finalStr;
      $retStatus = 1;
   } else {
      $vdLogger->Trace("Snippet might be old, so not considering:\n$snippet");
      $retString = "";
      $retStatus = 0;
   }

   return $retStatus, $retString;

}

###############################################################################
#
# DisplayStats -
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
   my $tb = Text::Table->new(
    "STRING               ", "ACTUAL   ",
    "EXPECTED   ", "EXPECTED BY   ", "RESULT   ");

   my $tb2 = Text::Table->new(
    "STRING               ", "OCCURENCES    ","LOG SNIPPET(with context)");


   # Get the stats bucket
   # For each counter in a node load all the values of the counter
   # in a table to display it.
   my ($allLogs, $resultHash);
   my $partition = "---------------------------------------------";
   my $bucket = $self->{logbucket};
   # Run the loop on all nodes of all machines.
   foreach my $logsInBucket (keys %$bucket) {
      $allLogs = $bucket->{$logsInBucket};
      foreach my $logType (keys %$allLogs) {
         my $allStrings = $allLogs->{$logType}->{result};
         foreach my $string (keys %$allStrings) {
            my $stringHash = $allStrings->{$string};
            my $expectationBy = $stringHash->{expectedby};
            $expectationBy = "user" if $expectationBy =~ /(specific|generic)/i;
            $tb->load([$string,
                       $stringHash->{actual},
                       $stringHash->{expected},
                       $expectationBy,
                       $stringHash->{result},
               ]);
         }
         print $partition . $partition . $partition . "\n";
         $vdLogger->Info("Results for $self->{target}($self->{nodeid}):".
                         uc($self->{veritype})."\n". $tb);
         foreach my $string (keys %$allStrings) {
            my $stringHash = $allStrings->{$string};
            my $ocurrenceFlag = 0;
            foreach my $ocurrence (sort keys %$stringHash) {
               next if $ocurrence !~ /^occurence/;
               $ocurrenceFlag = 1;
               my $logsnippet = $stringHash->{$ocurrence};
               $ocurrence =~ s/occurence(\d+)/$1/;
               chomp($logsnippet);
               if($logsnippet =~ /\n/) {
                  $tb2->load(["\n".$string,
                              "\n".int($ocurrence),
                              $logsnippet . "\n---",
                  ]);
               } else {
                  $tb2->load([$string,
                              int($ocurrence),
                              $logsnippet. "\n---",
                  ]);
               }
            }
            if($ocurrenceFlag == 1) {
               $vdLogger->Info("\n".$tb2);
            }
         }
         $tb->clear();
         $tb2->clear();
      }

   }



   return SUCCESS;
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
   return $self->{logbucket};
}



###############################################################################
#
# RequiredParams -
#       This is a child method. It says what param does it need from testbed
#       traffic or netadapter to intialize verification.
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

sub RequiredParams
{
   # This is child method. Move it.
   my $self = shift;
   my $os = $self->{os};

   my @params = [];
   if($os =~ /(linux|win)/i) {
      @params = ('vmopsobj');
   } elsif ($os =~ /(esx|vmkernel)/i)  {
      @params = ('hostobj');
   }

   return \@params;
}


##############################################################################
#
# GetChildHash --
#       Its a child method. It returns a conversionHash which is specific to
#       what child wants.
#
# Input:
#       none
#
# Results:
#       converted hash - a hash containging node info in language verification
#                        module understands.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
##############################################################################

sub GetChildHash
{
   my $self = shift;
   my $spec = {
      'testbed'   => {
         'hostobj'         =>  'hostobj',
         'vmOpsObj'  =>  'vmOpsObj',
         'adapter'   =>   {
            'driver'     => 'drivername',
            'interface'  => 'interface',
         },
      },
   };

   return $spec;
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
   # Log module creates childrens as they are just like
   # different nodes from where the information is to be collected.
   return ["Dmesg", "VMwareLog", "VMKernelLog", "VarLog"];
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

1;
