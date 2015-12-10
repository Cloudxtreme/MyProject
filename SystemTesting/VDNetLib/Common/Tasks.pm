##########################################################
# Copyright 2013 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

package VDNetLib::Common::Tasks;

#
# Tasks.pm --
#     This package takes care of creating/manipulating/terminating Perl threads
#     to handle multi tasks simultaneously. A attribute named taskHash in this
#     package is declared to store all tasks need to be scheduled. Up to 30
#     worker threads could be exctued in parallel. The default timeout of each
#     thread is 180s. If thread is not finised in this time duration, it will
#     be forcibly terminated. Any other modules using this package need to
#     provide sub reference and its argument list via QueueTask in advance.
#
#     The structure of task handle hash:
#     $taskHash->{taskId}{id}         : ID of task;
#     $taskHash->{taskId}{subRef}     : Reference to a sub;;
#     $taskHash->{taskId}{argArr}     : List of argument;
#     $taskHash->{taskId}{outputFile} : task output file path;
#     $taskHash->{taskId}{status}     : Task status, one of
#                                                -1, Detached
#                                                 0, Joined
#                                                 1, Ready to start
#                                                 2, Running
#     $taskHash->{taskId}{result}     : The result of this task;
#
#

use strict;
use warnings;
use Data::Dumper;

use threads;
use threads::shared;
use Thread::Queue;
use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError
                                   VDGetLastError VDCleanErrorStack);

# Only 30 workers are allowed to create at this moment;
use constant MAXWORKERS => 30;
use constant DEFAULT_TIMEOUT => 1800;

########################################################################
#
# new --
#      This is the entry point to VDNetLib::Common::Tasks class.
#      It returns an object of this class.
#
# Input:
#      A named hash with following keys:
#      maxWorkers : Maximum number of workers to spawn # Optional
#      maxWorkerTimeout : Maximum number of workers to spawn # Optional
#
# Results:
#      An object of VDNetLib::Common::Tasks class, if successful,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;
   $self->{'workers'} = 0;
   $self->{'status'} = 0;
   $self->{'taskId'} = 0;
   $self->{'maxTimeout'} = (defined $options{'maxWorkerTimeout'}) ? $options{'maxWorkerTimeout'} :
                                                              DEFAULT_TIMEOUT;
   $self->{'maxWorkers'} = (defined $options{'maxWorkers'}) ? $options{'maxWorkers'} :
                                                              MAXWORKERS;
   $self->{'taskHash'} = {};
   my $threadsQueueObj = Thread::Queue->new();
   $self->{'queuesObj'} = $threadsQueueObj;
   my $trackerQueueObj = Thread::Queue->new();
   $self->{'trackerQueueObj'} = $trackerQueueObj;
   $vdLogger->Debug("Created instance of Task with $self->{'maxWorkers'} ".
       "workers and max timeout $self->{'maxTimeout'}");

   bless ($self, $class);
   return $self;
}


########################################################################
#
# QueueTask --
#      Add a task to the queue
#
# Input:
#      A named hash with following keys:
#      functionRef   :  Reference to a Perl sub routine;  # Required
#      functionArgs  :  Reference to routine's arguments;  # Required
#      outputFile    :  The file name which output should be redirected
#                       If omitted, task output will not be saved
#      timeout        : max timeout for this task
#
# Results:
#      task ID which could be used to acquire other task information;
#
# Side effects:
#      None
#
########################################################################

sub QueueTask
{
   my $self       = shift;
   my %options    = @_;
   @_ = (); # workaround to fix scalar leaked issue (fixed in Perl 5.12)
            # https://rt.perl.org/rt3/Public/Bug/Display.html?id=70602
   my $subRef     = $options{'functionRef'};
   my $argRef     = $options{'functionArgs'};
   my $outputFile = $options{'outputFile'};
   my $timeout    = $options{'timeout'};
   my $taskId     = (defined $options{'taskId'}) ? $options{'taskId'} :
                                                   $self->{'taskId'};

   if (not defined $outputFile) {
      $vdLogger->Debug("No output file specified, discarding task outputs");
      $outputFile = "null";
   }

   $timeout = (defined $timeout) ? $timeout : DEFAULT_TIMEOUT;
   my @argArr = @$argRef;

   my $taskHash = $self->{'taskHash'};
   $taskHash->{$taskId}{'id'}       = $taskId;
   $taskHash->{$taskId}{'subRef'}     = $subRef;
   $taskHash->{$taskId}{'argArr'}     = \@argArr;
   $taskHash->{$taskId}{'outputFile'} = $outputFile;
   $taskHash->{$taskId}{'status'}     = undef;
   $taskHash->{$taskId}{'result'}     = undef;
   $taskHash->{$taskId}{'timeout'}     = $timeout;

   if ($taskHash->{$taskId}{'timeout'} > $self->{'maxTimeout'}) {
      $self->{'maxTimeout'} = $taskHash->{$taskId}{'timeout'};
   }
   my $threadsQueueObj = $self->{'queuesObj'};
   #Enqueue the new task
   eval {
      $vdLogger->Debug("Enqueuing taskId: $taskId");
      $threadsQueueObj->enqueue($taskId);
   };
   if ($@) {
      $vdLogger->Error("Failed to enqueue task $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{'taskId'} += 1;
   return $taskId;
}


########################################################################
#
# RunSheduler --
#      Method to schedule tasks, monitor for completion and collect
#      results
#     (QueueTask() is assumed to be called before calling this
#     method)
#
# Input:
#     None
#
# Results:
#      "SUCCESS", if all tasks are executed successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub RunScheduler
{
   my $self = shift;
   @_ =();
   my $finalResult = SUCCESS;
   return $self->ScheduleWorkersWithoutThreads() if !$ENV{VDNET_USE_THREADS};
   $vdLogger->Debug("Using threads");
   my $trackerQueueObj = $self->{'trackerQueueObj'};
   my $scheduler;
   my $completedThreads = 0;
   eval {
      $scheduler = async {$self->ScheduleWorkers()};
   };
   if ($@) {
      $vdLogger->Error("Failed to run scheduler $@");
      VDSetLastError("EOPFAILED");
      $finalResult = FAILURE;
      goto EXIT;
   }

      my $retry = 60;
      while (!$trackerQueueObj->pending() && $retry) {
         sleep 1; # a small delay before tracking threads status
            $retry--;
      }
      if (!$retry) {
         $vdLogger->Error("Threads initialization seems to be failed, " .
                          "ensure QueueTask() is called");
         VDSetLastError("EOPFAILED");
         $finalResult = FAILURE;
         goto EXIT;
      }

      #
      # Max timeout is computed based on number of batches involved
      #
      my $threadTimeout = $self->{'maxTimeout'}; # + int($self->{'maxTimeout'}/$self->{'maxWorkers'});
      $vdLogger->Debug("Joining/Detaching alive worker threads $threadTimeout");
      my $waitToFinishTime = time;
      #
      # maintain a local copy of all thread objects instead of
      # always relying on threads->list(). That way, the number
      # of successful thread execution can be compared based on
      # local copy. Local copy and threads->list() should match,
      # otherwise, that would also explain error in some threads.
      #
      my $masterList;
      while (defined (my $threadHash = $trackerQueueObj->dequeue_nb())) {
         foreach my $threadId (keys %$threadHash) {
            $masterList->{$threadId} = $threadHash->{$threadId};
         }
      }
      #
      # Loop until timeout is hit or if master list is non-empty
      # or main scheduler is still active.
      #
      while ((scalar(keys %$masterList) || $scheduler->is_running()) &&
            (time < ($waitToFinishTime + $threadTimeout))) {
         foreach my $thread (threads->list()) {
            my $tid = $thread->tid();
            if ($tid == $scheduler->tid()) {
               next;
            }
            if (not exists $masterList->{$tid}) {
               next;
            }
            my $error = $thread->error();
            if ($thread->is_joinable()) {
               $vdLogger->Debug("Worker $tid in joinable state");
               my $result = $thread->join();
               delete $masterList->{$tid};
               if (not defined $result) {
                  $vdLogger->Debug("Worker $tid in undef state");
                  next;
               }
               if (($result eq FAILURE) || ($result eq "FAIL")) {
                  $vdLogger->Error("Thread $tid returned $result");
                  $vdLogger->Debug("StackTrace:\n" .
                           VDNetLib::Common::Utilities::StackTrace());
                  $vdLogger->Debug(VDGetLastError());
                  $finalResult = FAILURE;
                  goto EXIT;
               }
               $completedThreads++;
            } elsif ($thread->is_running()) {
               $vdLogger->Debug("Worker $tid in running state");
               sleep(3);
            } elsif ($thread->is_detached()) {
               $vdLogger->Error("Worker $tid is unexpectedly in detached state");
               delete $masterList->{$tid};
            } else {
               $vdLogger->Error("Worker $tid in unknown state");
               sleep(3);
            }
            if (defined $error) {
               $vdLogger->Error("Found error in executing thread $tid: $error");
               $finalResult = FAILURE;
               goto EXIT;
            }
         }
         # push queued thread ids for tracking
         while (defined (my $threadHash = $trackerQueueObj->dequeue_nb())) {
            my $threadId = (keys %$threadHash)[0];
            if (not exists $masterList->{$threadId}) {
               $masterList->{$threadId} = $threadHash->{$threadId};
            }
         }
      }
      #
      # If there any pending threads running beyond max timeout, detach them
      #
      if ((scalar(keys %$masterList))) {
         $vdLogger->Error("Hit timeout to complete task in $threadTimeout secs");
         $finalResult = FAILURE;
      }
EXIT:
      $scheduler->detach();
      my $pendingThreads = 0;
      foreach my $tid (keys %$masterList) {
         # detach only threads that are still pending
         # due to errors and that are part of the masterList
         # which are created within the scope of RunScheduler().
         # Tryning to detach threads other than masterList could
         # lead to adverse effects such as hanging the parent process.
         foreach my $thread (threads->list()) {
            if ($tid == threads->tid()) {
               $vdLogger->Warn("detaching thread " . $tid .
                               " due to error in other threads");
               $thread->detach();
               $pendingThreads++;
            }
         }
      }
      $vdLogger->Info("Number of pending threads, client: " .
                      scalar(keys %$masterList) . " system: " .
                      $pendingThreads);
      $vdLogger->Debug("Total completedThreads $completedThreads");
      $finalResult = ($finalResult eq FAILURE) ? FAILURE : $completedThreads;
      return $finalResult;
}


########################################################################
#
# ScheduleWorkers --
#     This method takes care of batch processing with the max number
#     of active tasks as self->{maxWorkers}
#
# Input:
#     None
#
# Results:
#     FAILURE, in case of any error;
#     return value of the given the function in scalar context;
#
# Side effects:
#     None
#
########################################################################

sub ScheduleWorkers
{
   my $self = shift;
   @_ = ();

   my $threadsQueueObj = $self->{'queuesObj'};
   $threadsQueueObj->enqueue(undef);

   my $trackerQueueObj = $self->{'trackerQueueObj'};

   while ($threadsQueueObj->pending() ) {
      if (threads->list() < $self->{'maxWorkers'}) {
         my $taskId = $threadsQueueObj->dequeue_nb();
         if (not defined $taskId) {
            last;
         }
         my $retry = 5;
         $vdLogger->Debug("Starting task $taskId");
         my $threadObj;
         while ($retry > 0) {
            $threadObj = threads->create(sub {
                              my $result = $self->StartWorker($taskId);
                              return $result;
                              });
            if (not defined $threadObj) {
               $vdLogger->Debug("Failed to create thread for task $taskId ");
               $retry--;
               next;
            } else {
               last;
            }
         }
         if ($retry == 0) {
            $vdLogger->Error("Failed to create thread for task $taskId " .
                             "in 5 retries so not scheduling new tasks");
            VDNetLib::Common::Utilities::CollectMemoryInfo();
            last;
         }
         #
         # Queuing thread objects require sharing to be enabled
         # on th objects, so pushing thread ids instead
         #
         my $tid = $threadObj->tid();
         $vdLogger->Trace("Enqueuing $tid for task $taskId");
         $trackerQueueObj->enqueue({$tid => $taskId});
     } else {
        sleep 3; # wait for queue to be free,
                 # TODO: make it dynamic based
                 # on other tasks ?
     }
   }
   $trackerQueueObj->enqueue(undef);
   $vdLogger->Info("Done scheduling all jobs");
   return SUCCESS;
}


########################################################################
#
# ScheduleWorkersWithoutThreads --
#     Method to run all tasks sequentially.
#     NOTE: This will be deprecated soon
#
# Input:
#     None
#
# Results:
#     return value of every task i.e sub-routine
#
# Side effects:
#     None
#
########################################################################

sub ScheduleWorkersWithoutThreads
{
   my $self = shift;
   my $threadsQueueObj = $self->{'queuesObj'};
   while (defined (my $taskId = $threadsQueueObj->dequeue_nb())) {
      $vdLogger->Trace("Processing task $taskId");
      if (FAILURE eq $self->StartWorker($taskId)) {
         $vdLogger->Error("Failed to execute task $taskId");
         return FAILURE;
      }
   }
}


########################################################################
#
# StartWorker --
#      Method to process all tasks, only 10 workers are allowed by now;
#      if task not ended in threadTimeout, Will triger a signal handler;
#
# Input:
#     taskId: task Id (the value return by QueueTask())
#
# Results:
#      None, all thread results are saved in %tashHash;
#
# Side effects:
#      None
#
########################################################################

sub StartWorker
{
   my $self    = shift;
   my $taskId  = shift;
   @_ = ();
   my $threadObj;
   my $subRef;
   my $argRef;

   #
   # Start a worker thread to monitor task ID queue. If there are pending tasks
   # in queue, it will process them one bye one. Will exit if task ID queue is
   # empty.
   #
   my $taskHash = $self->{'taskHash'};
   $subRef = $taskHash->{$taskId}{'subRef'};
   $argRef = $taskHash->{$taskId}{'argArr'};
   return &{$subRef}(@$argRef);
}
1;
