########################################################################
# Copyright (C) 2011 VMWare, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Workloads::WorkloadsManager;

#
# This package is the key player in vdNet automation which reads and executes
# every step in the test case hash. One of the main keys in the test case
# hash is "WORKLOADS". This contains information about how to execute the
# various sub-workloads or steps (represented as key value pair). The sequence
# or order of execution of these steps is mentioned as the key 'Sequence' under
# the "WORKLOADS" hash. As mentioned above, each step or sub-workload itself is
# a hash with key-value that defines what to execute. The key 'Type' in the
# sub-workload hash tells which module/package has the implementation to
# understand these key value pairs.
#
# This package is generic that it executes various steps as a separate process
# using Parallel::ForkManager CPAN package.
# This package is an interface to various workload modules. In order to comply
# with this package, all workload modules must be implement the following
# methods:
# - new() to create the workload class object;
# - StartWorkload() to start the workload (which will be executed as a separate
#                                         process);
# - CleanUpWorkload() to do all cleanup work after executing the workload.
#
# Also, the StartWorkload() method's return value should be either "PASS"
# or "FAIL" to indicate success/failure.
#
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use Data::Dumper;
use Storable 'dclone';
use List::Util qw (max);
use Text::Table;
use VDNetLib::Parallel::ForkManager;

use TDS::Main::VDNetMainTds;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDGetLastError VDSetLastError
                                   VDCleanErrorStack);
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::NetAdapter::Vnic::Vnic;
use VDNetLib::Common::Events;
use VDNetLib::Common::Utilities;
use POSIX qw(SIGALRM);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler ConfigureLogger
                                         StopInlineJVM);
use constant TRUE => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;


########################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::Workloads
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      testcase - reference to testcase hash
#
# Results:
#      Returns a VDNetLib::Workloads::Workloads object, if successful;
#      "FAILURE", in case of error
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
      'testbed'      => $options{testbed},
      'testcase'     => $options{testcase},
      'session'      => $options{session},
      'logDir'       => $options{logDir},
      'stateTable'   => "",
      'groupWorkload'=> VDNetLib::Common::GlobalConfig::FALSE,
      'result'       => {
         'finalSequence' => [],
         },
      };

   if ((not defined $options{testbed}) || (not defined $options{testcase}) ||
      (not defined $options{session})) {
      $vdLogger->Error("Test case, Session and/or Test bed not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   bless ($self, $class);

   my $eventHandler = VDNetLib::Common::Events->new(workloadsManager => $self,
                                                    );
   if ($eventHandler eq FAILURE) {
      $vdLogger->Error("Failed to create object of VDNetLib::Common::Events");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{eventHandler} = $eventHandler;

   $self->{logCollector} = $self->{testbed}->{logCollector};
   return $self;
}


########################################################################
#
# ResolveOverrides --
#      Method which creates new workloads from an existing ones and overrides
#      some of their keys.
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", in case of SUCCESS
#
# Side effects:
#      None
#
########################################################################

sub ResolveOverrides
{
   my $self = shift;
   my $workloads = $self->{testcase}->{WORKLOADS};
   foreach my $key (keys %$workloads) {
      if (ref ($workloads->{$key}) eq 'HASH') {
         if ($workloads->{$key}->{'Type'} eq 'Reference') {
            my $target = dclone ($workloads->{$workloads->{$key}->{'ReferenceWorkload'}});
            my $template = $workloads->{$key};
            foreach my $newKey (keys %$template) {
               if (($newKey ne 'Type') and ($newKey ne 'ReferenceWorkload')) {
                  $target->{$newKey} = $workloads->{$key}->{$newKey};
                  my $type = ref ($target->{$newKey});
                  if ($type eq 'HASH') {
                     my $hash = $workloads->{$workloads->{$key}->{'ReferenceWorkload'}}->{$newKey};
                     my $newHash = VDNetLib::Common::Utilities::MergeSpec($target->{$newKey}, $hash);
                     $target->{$newKey} = $newHash;
                  }
               }
            }
            $self->{testcase}->{WORKLOADS}->{$key} = $target;
         }
      }
   }

   return SUCCESS;
}

########################################################################
#
# ResolveImports --
#      Method which imports sequence sets and workload sets from files
#      that have been specified in the TDS sequence.
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", in case of SUCCESS
#
# Side effects:
#      None
#
########################################################################

sub ResolveImports
{
   my $self = shift;
   my $sequence = $self->{testcase}->{WORKLOADS}{Sequence};
   my @newSequences = ();

   my $workloadFile = $self->{testcase}->{workloadFile};

   # Resolving sequence sets. Sequence set names should be in all caps.
   foreach my $instance (@$sequence) {
      my $sequences;
      my $hasCustom = 0;
      foreach my $workload (@$instance) {
         # Checking if sequence name is in all caps.
         if (uc($workload) eq $workload) {
            my $sequenceName = $workload;
            $vdLogger->Debug("Importing seq set $sequenceName from file: $workloadFile");
            if (-e $workloadFile) {
               if (exists LoadFile($workloadFile)->{Sequences}->{$sequenceName}) {
                  $sequences = LoadFile($workloadFile)->{Sequences}->{$sequenceName};
                  $hasCustom = 1;
               } else {
                  $vdLogger->Error("Sequence set $sequenceName not found in Import File!");
               }
            } else {
               $vdLogger->Debug("Import File $workloadFile not found. " .
                               "Workload $workload is defined in upper case.");
            }
         }
      }
      if ($hasCustom) {
         # Resolving sequence set by adding all sequences listed under it in
         # the CommonWorkloads.yaml.
         foreach my $seq (@$sequences) {
            push(@newSequences, $seq);
         }
      } else {
         push(@newSequences, $instance);
      }
   }
   $self->{testcase}->{WORKLOADS}{Sequence} = \@newSequences;

   # Resolving workload sets. Workload set names as well as keys should be in
   # all caps
   my $newWorkloads;
   my $allWorkloads = $self->{testcase}->{WORKLOADS};
   foreach my $key (keys %$allWorkloads) {
      # Checking if Workload set key name is in all caps
      if (uc($key) eq $key) {
         my $workloadName = $allWorkloads->{$key};
         $vdLogger->Debug("Importing workload set $workloadName from file: $workloadFile");
         if (-e $workloadFile) {
            if (exists LoadFile($workloadFile)->{Workloads}->{$workloadName}) {
               my $workloads = LoadFile($workloadFile)->{Workloads}->{$workloadName};
               foreach my $newKey (%$workloads) {
                  $newWorkloads->{$newKey} = $workloads->{$newKey};
               }
            } else {
               $vdLogger->Error("Workload set $key not found in Import File!");
               $newWorkloads->{$key} = $allWorkloads->{$key};
            }
         } else {
            $vdLogger->Debug("Import File $workloadFile not found!");
            $newWorkloads->{$key} = $allWorkloads->{$key};
         }
      } else {
         $newWorkloads->{$key} = $allWorkloads->{$key};
      }
   }

   $self->{testcase}->{WORKLOADS} = $newWorkloads;

   return SUCCESS;
}


########################################################################
#
# RunWorkload --
#      This is the main method to process test case hash in vdnet
#      framework. This method takes care of any initialization (for now
#      only guest network adapters) and all the test and exit/cleanup
#      workloads defined in the test case.
#
# Input:
#     None (attributes 'testcase', 'session', and 'testbed' must be
#     defined in the object).
#
# Results:
#    "PASS" - if the test case is passed;
#    "FAIL" - if the test case is failed;
#
# Side effects:
#     Depends on the type of workloads being run
#
########################################################################

sub RunWorkload
{
   my $self     = shift;
   my $testbed = $self->{testbed};
   my $testcase = $self->{testcase};
   my $session  = $self->{session};
   my $workload = shift;
   my $ignoreFailure;
   #
   # Check if 'IgnoreFailure' flag is defined in the test case hash.
   # If IgnoreFailure is set to "1", then workloads will continue to
   # run even if any workloads fail.
   #
   if (defined $testbed->{ignoreFailure}){
      $ignoreFailure = $testbed->{ignoreFailure};
      $vdLogger->Info("Ignorefail option has been set through command line,".
                      "by pass the definition in each workload items");
   }else{
      $ignoreFailure = $testcase->{WORKLOADS}{IgnoreFailure};
      $ignoreFailure = (defined $ignoreFailure) ?
         $ignoreFailure : VDNetLib::Common::GlobalConfig::FALSE;
   }
   #
   # Do initial verification of all the keys and values defined in the test
   # case hash.
   #
   if (defined $testcase->{WORKLOADS}) {
      # Verify whether all the information under 'WORKLOADS' is correct
      if (FAILURE eq $self->VerifyWorkloadHash($testcase->{WORKLOADS})) {
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
   }

   my $result = "FAIL";
   if (not defined $testcase->{WORKLOADS}{Iterations}) {
      $testcase->{WORKLOADS}{Iterations} = 1;
   }

   #PR 1118709: Close the Zookeeper handle before forking
   my $zkObj = $self->{session}{zookeeperObj};
   $zkObj->CloseSession($self->{testbed}{'zkHandle'});
   $self->{testbed}{'zkHandle'} = undef;
   #
   # First run all test workloads. Pass the value of IgnoreFailure flag.
   #
   $vdLogger->Info("Number of testcase Iterations to run " .
	            $testcase->{WORKLOADS}{Iterations});
   # totalIterations var is for printing on stdout for users
   # iterationCounter is making a copy of Iterations key in Workloads
   # so that we don't change the actual value in case multiple
   # testcases refer to same sequence of workloads
   my $totalIterations = $testcase->{WORKLOADS}{Iterations};
   my $iterationCounter = $testcase->{WORKLOADS}{Iterations};
   if (defined $testcase->{WORKLOADS}{Sequence}) {
      while ($iterationCounter != 0) {
         $iterationCounter--;
         my $currentIteration = int($totalIterations) - int($iterationCounter) + 1;
         $vdLogger->Info("Running workloads under Sequence key for Iteration = " .
	                $currentIteration);
         my $mainSequence = $testcase->{WORKLOADS}{Sequence};
         if (defined $workload) {
            $mainSequence = [[$workload]];
         }
         if ($ENV{VDNET_WORKLOAD_THREADS}) {
            $result = $self->RunSequenceUsingThreads($mainSequence,
                                                     $ignoreFailure);
         } else {
            $result = $self->RunSequence($mainSequence,
                                         $ignoreFailure);
         }
         my $interactive = $self->{session}{interactive};
         if (defined $interactive) {
            if (($interactive =~ /onfailure/i) && (!$self->{result}{final})) {
               next;
            } else {
               return $self->GetFinalResult();
            }
         }
      }
   } else {
       $vdLogger->Info("Setting mainsequence result to PASS as the " .
                       "mainsequence->Sequence is not defined");
       $result = VDNetLib::Common::GlobalConfig::PASS;
   }

   #
   # It is a best practice to cleanup any changes made to testbed components by
   # the test workloads called above. That way, there is no impact on any tests
   # run later on the same testbed components.
   # Here pass IgnoreFailure flag as TRUE because ALL cleanup workloads should
   # run irrespective of any failure in other cleanup/exit workloads.
   #
   my $exitSequence = $testcase->{WORKLOADS}{ExitSequence};
   if (defined $workload) {
         $exitSequence = undef;
   }
   if (defined $exitSequence) {
      $vdLogger->Info("Running workloads under ExitSequence key");
      #
      # Save the result of main sequence
      #
      my $mainSequenceResult = $result;

      #
      # reset the final result to SUCCESS, so that ExitSequence can run
      #
      $self->{result}{final} = VDNetLib::Common::GlobalConfig::EXIT_SUCCESS;
      my $exitResult;
      if ($ENV{VDNET_WORKLOAD_THREADS}) {
         $exitResult = $self->RunSequenceUsingThreads($exitSequence,
            VDNetLib::Common::GlobalConfig::TRUE);
      } else {
         $exitResult = $self->RunSequence($exitSequence,
            VDNetLib::Common::GlobalConfig::TRUE);
      }
      #
      # The main sequence's result take precedence over the ExitSequence's
      # result when main sequence's result is not SUCCESS.
      #
      # Exit sequence's result is considered only when main sequence's result
      # is SUCCESS. So, if something wrong happened in ExitSequence, we throw
      # that as final result
      #
      #
      if ($mainSequenceResult =~ m/PASS/i) {
         $result = $exitResult;
      } else {
         $result = $mainSequenceResult;
      }
   }

   if (($self->{groupWorkload} eq VDNetLib::Common::GlobalConfig::TRUE)) {
      $vdLogger->Info("Workloads Manager finished to run group workload: $result");
      return $result;
   }
   #
   # Deleting verification files stored under Testcase folders.
   #
   my $ret = VDNetLib::Workloads::Utilities::DeleteVerificationFiles();
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to delete verification files");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   #PR 1118709: Re-create zookeeper handle after child processes are over
   if (FAILURE eq $self->{testbed}->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Make sure log collection flag is set
   if ((defined $self->{session}{'collectLogs'}) &&
       ($self->{session}{'collectLogs'} == 1) && ($result eq "FAIL")) {
      $self->{testbed}->{areLogsCollected} = TRUE;
   }

   return $result;
}


########################################################################
#
# RunSequence --
#      Method to process and execute the workloads using the given
#      sequence. Sequence is an array of array which dictates the order
#      of workloads to be executed.
#
# Input:
#      sequenceArray: reference to array of arrays which has workload
#                     names under "WORKLOADS" key in test case hash.
#      ignoreFailure: "0" or "1" to indicate whether workload failures
#                     remaining workloads should be run or not in case
#                     of any one workload failure.
#
# Results:
#    "PASS" - if the given sequence is executed successfully;
#    "FAIL" - in case of any failure;
#
# Side effects:
#     Depends on the type of workloads being run
#
########################################################################

sub RunSequence
{
   my $self          = shift;
   my $sequenceArray = shift;
   my $ignoreFailure = shift;
   my $testbed = $self->{testbed};
   my $testcase = $self->{testcase};
   my $session  = $self->{session};

   my $sessionCount = 0;

   #
   # Read the given Sequence array.
   # Sequence array contains index to one or more workloads
   # in the test case. The order of execution is represented in
   # in the form of array of arrays.
   #
   # Pick first element of the array. If it contains multiple elements/indexes
   # then read the 'Parallel' key in the corresponding index and check if that
   # specific workload can run in parallel with other workloads. If a workload
   # cannot be executed in parallel with other workloads, then skip that
   # workload.
   # TODO: other option could be wait until other parallel workloads are
   # executed.
   #
   # For the first element in the 'Sequence' array, if there are N indexes,
   # then start each workload as a separate process.
   # Then proceed to the next element in the 'Sequence' and perform the same
   # steps mentioned above. Once all the elements in the 'Sequence' array are
   # processed, analyzed the results of various sub-processes and return
   # PASS/FAIL appropriately.
   #
   #

   #PR 1118709: Close the Zookeeper handle before forking
   my $zkObj = $self->{session}{zookeeperObj};
   $zkObj->CloseSession($self->{testbed}{'zkHandle'});
   $self->{testbed}{'zkHandle'} = undef;

   #
   # Each element in sequence array represents sub-workload/step/hash which
   # altogether defines the procedure/operations to be executed in order to
   # complete the given test case.
   #
   if (defined $sequenceArray) {
      my $workArray = $sequenceArray;
      foreach my $set (@{$workArray}) {
         #
         # process each element from the given sequence array
         #

         #
         # Create an object of Parallel::ForkManager with a parameter as number
         # of processes to support in this object.
         #
         my $pm = new Parallel::ForkManager(scalar(@{$set}));

         # Register callback functions before starting each sub-process.
         $pm->run_on_start(
            sub {
               my ($pid,$ident)=@_;
               $self->RunOnStart($pid, $ident);
            }
         );

         # Register callback functions upon completion of each sub-process.
         $pm->run_on_finish(
            sub { my ($pid, $exitCode, $ident, $exitSignal) = @_;
               $self->RunOnFinish($pid, $exitCode, $ident, $exitSignal);
            }
         );

         # Now, process every element (which is a sub-workload/step/operation
         # part of the test case procedure) within elements of 'Sequence'
         # array. In other words, process every array in 'Sequence' array.
         #
         foreach my $operation (@{$set}) {
            my $interactivePoint = $self->{session}{interactive};
            #
            # If interactive point is hit i.e if user wished
            # to interact with the session before running this workload,
            # then return without executing workload
            #
            if ((defined $interactivePoint) &&
               ($operation eq $interactivePoint)) {
               $vdLogger->Info("Hit interactive point before running workload " .
                               $operation);
               return $self->GetFinalResult();
            }
            #
            # Check if $self->{result}{final} is set to 1, if yes, then it
            # means some workload failed, so quit.
            #
            #
            if (defined $self->{result}{final} &&
               $self->{result}{final} ==
                  VDNetLib::Common::GlobalConfig::EXIT_SKIP) {
               $vdLogger->Error("Quit running other workloads, if any, since " .
                                "the previous workload skipped");
               return "SKIP";
            }

            if ((defined $self->{result}{final}) &&
                ($self->{result}{final} != 0)) {
               $self->{testbed}->{areLogsCollected} = TRUE;
               if ($ignoreFailure eq VDNetLib::Common::GlobalConfig::FALSE) {
                  $vdLogger->Error("Quit running other workloads, if any, since " .
                                   "the previous workload failed. " .
                                   "Also, IgnoreFailure not defined");
                  return "FAIL";
               }
            }
            #
            # Check if the given sub-workload/operation/step can run in parallel
            # with other process. If no, then skip it.
            #
            if (ref($testcase->{WORKLOADS}{$operation}) ne "ARRAY") {
               if (defined $testcase->{WORKLOADS}{$operation}{Parallel} &&
                   $testcase->{WORKLOADS}{$operation}{Parallel} =~ /no/i) {
                  next;
               }
            }
            # Create a sub-process for each workload/item
            my $pid = $pm->start($operation);
            if (!$pid) {
               # This is inside child process --
               # Resetting the result for child process as the parent might collect
               # failure from some other child process and copy it on to child
               $self->{result}{final} = VDNetLib::Common::GlobalConfig::EXIT_SUCCESS;
               $SIG{'INT'} = sub { };  # "ignore in child worload"
               $SIG{'SEGV'} = \&HandleSEGVSignal;
               #
               # Its a known issue that we have to reconnect JVM
               # in the child process or else it won't load the java classes
               # in the forked child process.
               # http://search.cpan.org/dist/Inline-Java/Java.pod
               #
               VDNetLib::InlineJava::VDNetInterface->ReconnectJVM();

               #
               # Create a new zookeeper handle for the sub-process.
               # It is mandatory that each process maintains its own
               # session to connect to a given server/port.
               #
               # PR 1269835 zk handle will be created in
               # self->{testbed}->UpdateZooKeeperHandle()
               # we do not need call $zkObj->CreateZkHandle here
               my $zkObj = $self->{session}{zookeeperObj};

               #
               # Also, update the zookeeper handle in the testbed
               # such that all zookeeper related calls in testbed
               # makes use of this new handle.
               # Updating the 'zkHandle' directly on zookeeperObj
               # was causing race-condition. That has to be
               # investigated more to see if that is by design
               # or a bug
               #

               if (FAILURE eq $self->{testbed}->UpdateZooKeeperHandle()) {
                  $vdLogger->Error("Failed to update zookeeper handle");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               my $result;
               #
               # Fix for PR1126039: use eval to catch exception in the
               # forked process. Otherwise, an exception in child
               # process triggers eval {} on parent process
               # and results in unexpected behavior.
               #
               eval {
                  #
                  # Check if the workload is hash or array, if its array then
                  # it means its CustomSequence or ReportSequence/GroupWorkload
                  #
                  if (ref($testcase->{WORKLOADS}{$operation}) eq "ARRAY") {
                     $vdLogger->Info("Runnning custom sequence $operation");
                     $result = $self->RunSequence($testcase->{WORKLOADS}{$operation},
                                                  $ignoreFailure);
                  } else {
                     $result = $self->StartChildWorkload($operation);
                  }
               };
               if ($@) {
                  $vdLogger->Error("Caught exception in child process while " .
                                   "executing $operation: $@");
                  $result = "FAIL";
               }
               # Important to close the session esp. when cacheTestbed options
               # is used, otherwise process would hang.
               $zkObj->CloseSession($self->{testbed}{zkHandle});
               $self->{testbed}{'zkHandle'} = undef;
               # also, disconect all ssh handles using undef, otherwise
               # new handles created within the child process would cause
               # segfault during cleanup
               $sshSession = undef;

               if ($result eq "FAIL") {
                  $vdLogger->Error("Failed to execute workload $operation");
                  $vdLogger->Debug(Dumper(VDGetLastError()));
                  VDCleanErrorStack();
                  exit VDNetLib::Common::GlobalConfig::EXIT_FAILURE;
               }
               if ($result eq "SKIP") {
                  $vdLogger->Error("Skipping workload $operation");
                  exit VDNetLib::Common::GlobalConfig::EXIT_SKIP;
               }
               exit VDNetLib::Common::GlobalConfig::EXIT_SUCCESS;
            } else {
               # This is parent process --
               $self->{result}{$pid}{workload} = $operation;
            }
            my $finish = $pm->finish($operation);
         }
         $pm->wait_all_children;
      } # end of sub-array of array of Sequence
   } # end of 'Sequence'

   # print the workloads report
   my $table = Text::Table->new("Workload", "\t", "Process ID",
                                "\t", "Exit code", "\t", "Duration (secs)");
   my $underline = "-" x 12;
   $table->load([$underline, "\t", $underline, "\t", $underline, "\t", $underline]);
   foreach my $pid (@{$self->{result}{finalSequence}}) {
      $table->load([$self->{result}{$pid}{workload}, "\t",
                    $pid, "\t", $self->{result}{$pid}{exitCode}, "\t",
                    $self->{result}{$pid}{duration}]);

   }
   my $temp =  $table->stringify();
   # give  a tabspace of 4
   my $tabSpace = "\t" x 4;
   $temp =~ s/\n/\n$tabSpace/g;
   $vdLogger->Info("Workload results:\n$tabSpace" . $temp);
   return $self->GetFinalResult();
}


########################################################################
#
# RunSequenceUsingThreads---
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

sub RunSequenceUsingThreads
{
   my $self          = shift;
   my $sequenceArray = shift;
   my $ignoreFailure = shift;
   my $testbed = $self->{testbed};
   my $testcase = $self->{testcase};
   my $session  = $self->{session};

   my $sessionCount = 0;
   my $result;

   #
   # Read the given Sequence array.
   # Sequence array contains index to one or more workloads
   # in the test case. The order of execution is represented in
   # in the form of array of arrays.
   #
   # Pick first element of the array. If it contains multiple elements/indexes
   # then read the 'Parallel' key in the corresponding index and check if that
   # specific workload can run in parallel with other workloads. If a workload
   # cannot be executed in parallel with other workloads, then skip that
   # workload.
   # TODO: other option could be wait until other parallel workloads are
   # executed.
   #
   # For the first element in the 'Sequence' array, if there are N indexes,
   # then start each workload as a separate process.
   # Then proceed to the next element in the 'Sequence' and perform the same
   # steps mentioned above. Once all the elements in the 'Sequence' array are
   # processed, analyzed the results of various sub-processes and return
   # PASS/FAIL appropriately.
   #
   #

   #PR 1118709: Close the Zookeeper handle before forking
   my $zkObj = $self->{session}{zookeeperObj};
   $zkObj->CloseSession($self->{testbed}{'zkHandle'});
   $self->{testbed}{'zkHandle'} = undef;

   #
   # Each element in sequence array represents sub-workload/step/hash which
   # altogether defines the procedure/operations to be executed in order to
   # complete the given test case.
   #
   if (defined $sequenceArray) {
      my $workArray = $sequenceArray;
      foreach my $set (@{$workArray}) {
         #
         # process each element from the given set
         #

         my $tasksObj = VDNetLib::Common::Tasks->new();
         my $result = FAILURE;
         my $queuedTasks = 0;

         # Now, process every element (which is a sub-workload/step/operation
         # part of the test case procedure) within elements of 'Sequence'
         # array. In other words, process every array in 'Sequence' array.
         #
         foreach my $operation (@{$set}) {
            my $functionRef;
            my $decorator;
            my @decoratorArgs;
            $decorator = sub { $self->WorkloadDecoratorForThreads(@_)};
            #
            # Check if the workload is hash or array, if its array then
            # it means its CustomSequence or ReportSequence/GroupWorkload
            #
            if (ref($testcase->{WORKLOADS}{$operation}) eq "ARRAY") {
               $functionRef = sub {$self->RunSequenceUsingThreads(@_)};
               $vdLogger->Info("Runnning custom sequence $operation");
               $decorator = sub { $self->WorkloadDecoratorForThreads(@_)};
               @decoratorArgs = ($functionRef, $testcase->{WORKLOADS}{$operation},
                                 $ignoreFailure);
            } else {
               $functionRef = sub {$self->StartChildWorkload(@_)};
               @decoratorArgs = ($functionRef, $operation);
            }
            my $interactivePoint = $self->{session}{interactive};
            #
            # If interactive point is hit i.e if user wished
            # to interact with the session before running this workload,
            # then return without executing workload
            #
            if ((defined $interactivePoint) &&
               ($operation eq $interactivePoint)) {
               $vdLogger->Info("Hit interactive point before running workload " .
                               $operation);
               return $self->GetFinalResult();
            }
            #
            # Check if $self->{result}{final} is set to 1, if yes, then it
            # means some workload failed, so quit.
            #
            #
            if (defined $self->{result}{final} &&
               $self->{result}{final} ==
                  VDNetLib::Common::GlobalConfig::EXIT_SKIP) {
               $vdLogger->Error("Quit running other workloads, if any, since " .
                                "the previous workload skipped");
               return "SKIP";
            }

            if (defined $self->{result}{final} &&
               $self->{result}{final} != 0 && $ignoreFailure
               eq VDNetLib::Common::GlobalConfig::FALSE) {
               $vdLogger->Error("Quit running other workloads, if any, since " .
                                "the previous workload failed. " .
                                "Also, IgnoreFailure not defined");
               return "FAIL";
            }
            # Now send the entire set to threads
            my $timeout = VDNetLib::TestData::TestConstants::MAX_TIMEOUT;
            # Close the handle in parent process before creating new thread
            $self->{testbed}->{zookeeperObj}->CloseSession($self->{testbed}->{zkHandle});
            # Use name of workload as taskId
            my $taskId = $operation;
            $tasksObj->QueueTask(functionRef  => $decorator,
                                 functionArgs => \@decoratorArgs,
                                 outputFile   => "/tmp/manager",
                                 taskId       => $taskId,
                                 timeout      => $timeout);
               $queuedTasks++;
         } # end of 'set'
         my $completedThreads = $tasksObj->RunScheduler();
         if ($completedThreads eq FAILURE) {
             $vdLogger->Error("Failed to run scheduler for workloads");
             $result = FAILURE;
         } elsif ($completedThreads != $queuedTasks) {
               $vdLogger->Error("For workload, number of queued tasks $queuedTasks" .
                                " is not equal to completed tasks $completedThreads");
            #
            # PR 1199274
            # dump memory info for debugging,
            # sometimes thread creation fails
            # due to not enough memory
            #
            VDNetLib::Common::Utilities::CollectMemoryInfo();
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         } else {
            $result = 0;
         }
         #
         # create a new handle for the parent process since the control is back from
         # thread to parent process
         #
         if (FAILURE eq $self->{testbed}->UpdateZooKeeperHandle()) {
            $vdLogger->Error("Failed to update zookeeper handle");
            VDSetLastError(VDGetLastError());
            $result = FAILURE;
         }
         # Update the final result if any workload in set fails
         if ($result) {
            $self->{result}{final} = $result;
         }
      } # end of 'Sequence'
   }
   $vdLogger->Info("Result: " . Dumper($self->{result}));

   return $self->GetFinalResult();
}

########################################################################
#
# StartChildWorkload --
#      This method creates an instance of the given child workload,
#      invokes StartWorkload() and CleanUpWorkload() methods.
#      The interface of all child workloads follows the rules
#      defined by this package (can be called as Parent process or
#      workload manager).
#
# Input:
#      workload: name of the workload (one of the key names under
#                (WORKLOADS hash in the test case hash) (Required)
#
# Results:
#      "PASS", if the child workload is executed successfully;
#      "FAIL", if the child workload fails or in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub StartChildWorkload
{
   my $self       = shift;
   my $workload   = shift;
   my $testcase   = $self->{testcase};
   my $testbed    = $self->{testbed};
   my $logDir     = $self->{logDir};

   if (not defined $testcase || not defined $testbed ||
      not defined $workload) {
      $vdLogger->Info("Insufficient parameters passed");
      VDSetLastError("ENOTDEF");
      return "FAIL";
   }

   my $workloadSpec = $testcase->{WORKLOADS}{$workload};
   if (not defined $workloadSpec) {
      $vdLogger->Error("Workload not defined in WORKLOADS: $workload");
      $vdLogger->Error("Workload $workload hash is\n:" . Dumper($workloadSpec));
      VDSetLastError("ENOTDEF");
      return "FAIL";
   }
   my $workloadType = $workloadSpec->{Type};
   if (not defined $workloadType) {
      $vdLogger->Error("Workload type not specified for workload: $workload");
      $vdLogger->Error("Workload $workload hash is\n:" . Dumper($workloadSpec));
      VDSetLastError("ENOTDEF");
      return "FAIL";
   }

   # Append "Workload" to the type of workload
   $workloadType = "VDNetLib::Workloads::" . $workloadType .
                   "Workload";

   #
   # Load the workload module that can understand and process the
   # workload hash.
   #
   eval "require $workloadType";

   if ($@) {
      $vdLogger->Error("unable to load module $workloadType:$@");
      #
      # Please note, even though this code is in a package, they
      # are being executed as a different sub-process, so using
      # 'exit' instead of 'return' command to capture the exitcode
      # of the process.
      #
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }

   my @verificationKeys = ("verification", "Verification", "VERIFICATION");
   foreach my $key (@verificationKeys) {
      my $workloadVerification = $testcase->{WORKLOADS}{$workload}{$key};
      if (defined $workloadVerification){
         #
         # If a workload has verification key with a value.
         # check in workloads if there is a hash with that name.
         # if yes then replace the verification key's value with that
         # hash.
         #
         # TODO: Do this for every workload, not just for traffic.
         if (defined $testcase->{WORKLOADS}{$workloadVerification}) {
            delete  $testcase->{WORKLOADS}{$workload}{$key};
            $testcase->{WORKLOADS}{$workload}{$key} =
            $testcase->{WORKLOADS}{$workloadVerification};
            $vdLogger->Trace("Replaced $key in $workload Workload " .
                             "with $workloadVerification hash");
            last;
         }
      }
   }

   # Get and save runworkload hash if defined;
   if ((join " ", (keys %{$testcase->{WORKLOADS}{$workload}})) =~
       /(runworkload)/i) {
      my $runWorkloadKey = $1;
      my $runWorkload = $testcase->{WORKLOADS}{$workload}{$runWorkloadKey};
      if ((not defined $testcase->{WORKLOADS}{$runWorkload}) ||
          (ref($testcase->{WORKLOADS}{$runWorkload}) !~ /HASH/) ||
          (not defined $testcase->{WORKLOADS}{$runWorkload}{Type})) {
         $vdLogger->Debug("$runWorkloadKey not defined in test case workloads " .
                          "or not a valid workload hash");
      } else {
         $testcase->{WORKLOADS}{$workload}{"runworkload"} =
                                        $testcase->{WORKLOADS}{$runWorkload};
      }
   }

   my $workloadObj;
   my $maxTimeout = $self->GetWorkloadMaxTimeout(
       $testcase->{WORKLOADS}{$workload}{maxtimeout});
   $vdLogger->Debug("Workload: $workload has max timeout value of $maxTimeout");

   delete $testcase->{WORKLOADS}{$workload}{maxtimeout};

   if ($workloadSpec->{Type} eq 'Group') {
      $workloadObj =  $workloadType->new(
                                         testcase => $testcase,
                                         testbed  => $testbed,
                                         session  => $self->{session},
                                         logDir   => $logDir,
                                         eventHandler => $self->{eventHandler});
   } else {
      $workloadObj =  $workloadType->new(
                                         workload => $testcase->{WORKLOADS}{$workload},
                                         testbed  => $testbed,
                                         logDir   => $logDir,
                                         eventHandler => $self->{eventHandler});
   }

   my $dupWorkload = $testcase->{WORKLOADS}{$workload};
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);
   if (defined $workloadObj->{targetkey}) {
      my $tupleKey = $workloadObj->{targetkey};
      my $tuple = $dupWorkload->{$tupleKey};
      $workloadObj->SetComponentIndex($tuple);
   }

   if ($workloadObj eq FAILURE) {
      $vdLogger->Error("Failed to create $workloadType object");
      $vdLogger->Debug(Dumper(VDGetLastError()));
      return "FAIL";
   }
  if ($workloadObj->CheckExpectedResult() eq FAILURE) {
      $vdLogger->Error("Failed to set expected result for workload");
      $vdLogger->Debug(Dumper(VDGetLastError()));
      return "FAIL";
   }

   $workloadObj->SetWorkloadName($workload);
   $vdLogger->Info("Starting the workload: $workload");

   #
   # making a copy, not reference so that the original test case hash
   # is not affected
   #
   my %dupWorkload = %{$testcase->{WORKLOADS}{$workload}};
   my $temp = \%dupWorkload;
   %$temp = (map { lc $_ => $temp->{$_}} keys %$temp);

   # Here we set the alarm signal handler to honor the timeout.
   my $sigset = POSIX::SigSet->new(SIGALRM);

   #
   # This is the alarm signal handler for the child workload process.
   # It gets executed only when a particular workload does not finish
   # up within the specified timeout value.
   #
   my $action = POSIX::SigAction->new(
		      sub {
			$vdLogger->Error("TIMEOUT => Couldn't complete".
					 " the workload: $workload, in".
					 " allowed $maxTimeout".
					 " seconds. Hence exiting the".
					 " workload process.");
			$vdLogger->Error("Failed to execute workload $workload");
         # capture the stack trace in case of timeout
         require Carp; Carp::cluck("vdnet stack trace");
         $vdLogger->Debug(Dumper(VDGetLastError()));
			VDCleanErrorStack();
                        #run log collector.
                        if ((defined $self->{session}{'collectLogs'}) &&
                            ($self->{session}{'collectLogs'} == 1)) {
                           if ($self->{testbed}->CollectAllLogs(FALSE) eq FAILURE) {
                              $vdLogger->Error("Failed to collect logs for debugging");
                           }
                        } else {
                           $vdLogger->Info("No logs will be collected. To enable" .
                                           " log collection please set collectLogs" .
                                           " to 1 in user config files");
                        }
			exit VDNetLib::Common::GlobalConfig::EXIT_FAILURE;
		      },
		      $sigset, &POSIX::SA_NODEFER);

   POSIX::sigaction(SIGALRM, $action);
   alarm ($maxTimeout);

   #
   # Call StartWorkload() to run the workload/operation using the
   # workload hash.
   #
   my $result = $workloadObj->StartWorkload();

   # Resetting the alarm.
   alarm (0);

   $vdLogger->Info("Workload $workload return value: $result");
   my $expectedResult = $temp->{expectedresult} || "PASS";
   my $resultHash = $workloadObj->CompareWorkloadResult($expectedResult,$result,$workload);
   my $racetrackObj = $vdLogger->{rtrackObj};
   if (defined $racetrackObj) {
      $racetrackObj->TestCaseVerification($resultHash->{workloadEndMessage},
                                          $resultHash->{result},
                                          $resultHash->{expectedResult},
                                          $resultHash->{finalResult});
   }

   if ($resultHash->{finalResult} eq "FAIL") {
      $vdLogger->Error("$workloadType workload failed");
      #run log collector.
      if ((defined $self->{session}{'collectLogs'}) &&
          ($self->{session}{'collectLogs'} == 1)) {
         if ($self->{testbed}->CollectAllLogs(FALSE) eq FAILURE) {
            $vdLogger->Error("Failed to collect logs for debugging");
         }
      } else {
            $vdLogger->Info("No logs will be collected. To enable" .
                            " log collection please set collectLogs" .
                            " to 1 in user config files");
      }
      $vdLogger->Error("Error: " . Dumper(VDGetLastError()));
      return "FAIL";
   }
   if ($resultHash->{finalResult} eq "SKIP") {
      return $resultHash->{finalResult};
   }
   # Do Cleanup after running the workload
   $result = $workloadObj->CleanUpWorkload();
   if ($result eq "FAIL") {
      $vdLogger->Error("$workloadType cleanup failed");
      $vdLogger->Debug(Dumper(VDGetLastError()));
      return "FAIL";
   }
   return "PASS";
}

########################################################################
#
# VerifyWorkloadHash --
#      Method to verify the 'WORKLOADS' hash in the testcase hash.
#
# Input:
#      'WORKLOADS' hash from the testcase hash.
#
# Results:
#     "SUCCESS", if all the entries are correct;
#     "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub VerifyWorkloadHash {
   my $self = shift;
   my $workload = shift;

   if (not defined $workload) {
      $vdLogger->Error("Workload hash not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # TODO -
   # Do all possible checks to make sure the values in the 'WORKLOADS'
   # hash are correct.
   #

   #
   # Making sure the entries in 'Sequence' refers to correct and existing
   # sub-workload hash.
   #
   if (defined $workload->{Sequence}) {
      my $workArray = $workload->{Sequence};
      foreach my $set (@{$workArray}) {
         foreach my $operation (@{$set}) {
            if (not defined $workload->{$operation}) {
               $vdLogger->Error("Invalid workload $operation given in Sequence");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
         } # end of sub-array of array of Sequence
      } # end of array of Sequence
   }
   return SUCCESS;
}


########################################################################
#
# RunOnStart --
#      Method that is registered as callback function before starting
#      any sub-process using ForkManager.
#      Execute all necessary operations before starting any
#      sub-workload/operation that is part of test case procedure.
#
# Input:
#      pid   - process id
#      ident - process identifier
#
# Results:
#      TODO
#
# Side effects:
#      TODO
#
########################################################################

sub RunOnStart
{
   my $self = shift;
   my ($pid,$ident)=@_;
   $self->{result}{$pid}{startTime} = time;
   $vdLogger->Debug("Workload $ident started, pid: $pid");
}


########################################################################
#
# RunOnFinish --
#      Method that is registered as callback function at the completion
#      of any sub-process that was started using ForkManager.
#      Execute all necessary operations at the completion of any
#      sub-workload/operation that is part of test case procedure.
#
# Input:
#      pid      - process id
#      exitCode - exit code of the process
#      ident    - process identifier
#      exitSignal - exit signal
#
# Results:
#      TODO
#
# Side effects:
#      TODO
#
########################################################################

sub RunOnFinish
{
   my $self = shift;
   my ($pid, $exitCode, $ident, $exitSignal) = @_;
   $self->{result}{$pid}{duration} = time - $self->{result}{$pid}{startTime};
   $vdLogger->Info("Workload $ident, PID $pid finished with " .
                   "exit code:$exitCode and exit signal:$exitSignal\n\n");
   if ($exitSignal) {
      $exitCode = $exitSignal;
   }
   # Store the process exit information in 'result'attribute of this class
   $self->{result}{$pid}{exitCode} = $exitCode;
   push(@{$self->{result}{finalSequence}}, $pid);

   # Update the final result if any one of the workload fails
   if ($exitCode) {
      $self->{result}{final} = $exitCode;
   }
}


########################################################################
#
# ProcessEvent --
#      This method is a wrapper to VDNetLib::Common::Event class'
#      ProcessEvent() method.
#
# Input:
#      None
#
# Results:
#      Return the output of ProcessEvent() method.
#
# Side effects:
#      None
#
########################################################################

sub ProcessEvent
{
   my $self = shift;
   return $self->{eventHandler}->ProcessEvent();

}


########################################################################
#
# ReturnWorkloadHash --
#      Method to verify the 'WORKLOADS' hash in the testcase hash.
#
# Input:
#      'WORKLOADS' hash from the testcase hash.
#
# Results:
#     "SUCCESS", if all the entries are correct;
#     "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub ReturnWorkloadHash
{
   my $self = shift;
   my $workloadName = shift;
   my $testcase = $self->{testcase};

   if (not defined $workloadName) {
      $vdLogger->Error("Workloadname not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Making sure the request workload exits in the WORKLOADS hash.
   #
   if(not defined $testcase->{WORKLOADS}->{$workloadName}) {
      $vdLogger->Error("workload named:$workloadName does not exits ".
                       "in WORKLOADS hash");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Trace("Returning workload:$workloadName from WORKLOADS");
   return $testcase->{WORKLOADS}->{$workloadName};
}


########################################################################
#
# GetFinalResult --
#     Method to get final result of the workload session
#
# Input:
#     None
#
# Results:
#     Final result: PASS/FAIL/SKIP
#
# Side effects:
#     None
#
########################################################################

sub GetFinalResult
{
   my $self = shift;
   if (!$self->{result}{final}) {
      return "PASS";
   } elsif ($self->{result}{final} == 3) {
      return "SKIP";
   } elsif ($self->{result}{final} eq 'PASS') {
      return "PASS";
   } else {
      return "FAIL";
   }
}


########################################################################
#
# ResetFinalResult --
#     Method to reset final result of workloads session.
#     Use this only on special needs
#
# Input:
#     None
#
# Results:
#     final result will be set to PASS by default
#
# Side effects:
#     None
#
########################################################################

sub ResetFinalResult
{
   my $self = shift;
   $self->{result}{final} = VDNetLib::Common::GlobalConfig::EXIT_SUCCESS;
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
   STDOUT->autoflush(1);
   if (FAILURE eq $self->{testbed}->UpdateZooKeeperHandle()) {
      $vdLogger->Error("Failed to update zookeeper handle");
      VDSetLastError(VDGetLastError());
   }
   VDNetLib::InlineJava::VDNetInterface->ReconnectJVM();

   eval {
      $result = &$functionRef($args);
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
   $self->{testbed}->{zookeeperObj}->CloseSession($self->{testbed}->{zkHandle});
   if ($result eq FAILURE) {
      $vdLogger->Debug("Stack from thread:" . VDGetLastError());
      VDCleanErrorStack();
   }
   return $result;
}


########################################################################
#
# GetWorkloadMaxTimeout ---
#     A method that decides which Max Timeout value to use, out of three
#     possible values.
#       - DEFAULT_WORKLOAD_TIMEOUT in GlobalConfig
#       - maxtimeout value specified in Workload
#       - maxWorkloadTimeout value specified in config file
#     Behavior of selection process works as follows
#       If both global and local (in workload) maxtimeout specified
#       use whichever one is larger (including default supplied in GloblConfig.pm).
#       If no values specified use the default supplied in GlobalConfig.pm
#
# Input:
#     None
#
# Results:
#     Returns a Maximum Workload Timeout Value
#
# Side effects:
#     None
#
########################################################################

sub GetWorkloadMaxTimeout
{
   my $self          = shift;
   my $localMaxTimeout = shift || 0;
   my $sessionMaxWorkloadTimeout = $self->{session}{maxWorkloadTimeout} || 0;

   my $maxTimeout = max(
       $localMaxTimeout,
       $sessionMaxWorkloadTimeout,
       VDNetLib::Common::GlobalConfig::DEFAULT_WORKLOAD_TIMEOUT);

   return $maxTimeout
}

########################################################################
#
# HandleSEGVSignal --
#     Method to catch segmentation fault and exit
#
# Input:
#
# Results:
#     The process will be terminated with exit code 1
#
# Side effects:
#     The process will no longer be active
#
########################################################################

sub HandleSEGVSignal
{
   $vdLogger->Error("Caught SEGV signal in child process\n");
   $vdLogger->Info("Try setting ulimit -s unlimited " .
                   "on your launcher and try again\n");
	exit VDNetLib::Common::GlobalConfig::EXIT_FAILURE;
}
1;
