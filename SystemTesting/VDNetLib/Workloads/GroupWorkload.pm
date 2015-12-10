########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::GroupWorkload;

#
# This package/module is used to run workload that involves executing
# Group operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
#
# Group workload looks like a common workload, but it is not pure one.
# Group workload looks like a Sequence, but it is not a pure one.
# Based on above two points, we tailer features of both common workload
# and Sequence for group workload to use.
#
# Summary of its design after discussion with Giri,
# There are two types of keys in group workload,
# 1. test level, i.e. iterations. Which will overwrite the one if any in test
#    case hash.
# 2. workload level, i.e. noofretries. which will be merged to a specific
#    workload in group workload sequence. The key in specific workload has lower
#    priority.
# The sequence in group workload is an array(Note the one in WORKLOADS is an
# array of array). The workloads in group workload run in sequential. No exit
# sequence for group workload. Group workload implemented as below,
# create a new test case hash for group workload, merge the test level keys
# accoringly, use a separate WorkloadsManager to run group workload, the call
# stacks are as below,
# WorkloadsManger(m1)->RunWorkload (p1) -> RunSequence -> StartChildWorkload(p2)
# -> GroupWorkload->StartWorkload->WorkloadsManger(m2)->RunWorkload->RunSequence
# ->StartChildWorkload(p3)
# in above call stacks, m1 and m2 maintain their own $self->{result} separately
# Group workload design doc is available at:
# https://wiki.eng.vmware.com/Yuanyou/GroupWorkloads#A_Separate_Workload_named_GroupWorklod.28Working_on.29
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and testcase hash which contains
# group workloads.
#
# The group workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type      => "Group" (this is mandatory and the value should be same)
#
# Group Operation Keys:-
# --------------------------
## Test level keys: -
## -------------------------
## iterations   => 'number of iterations to run for the group workload'
## Workload level keys:-
## -------------------------
## noofretires  => 'number of retries to run for a workload'

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger PASS TRUE);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE SKIP VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::TestData::StressTestData;
use VDNetLib::Workloads::Utils;
use Storable 'dclone';
use Inline::Python qw(py_eval py_call_function);
use VDNetLib::TestData::TestConstants;

########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::GroupWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      testcase - reference to testcase hash
#
# Results:
#      Returns a VDNetLib::Workloads::GroupWorkload object, if successful;
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

   if ((not defined $options{testcase}) || (not defined $options{testbed}) ||
      (not defined $options{session}) || (not defined $options{logDir})) {
      $vdLogger->Error('testcase and/or testbed and/or session and/or ' .
                       'logDir not provided');
      VDSetLastError('EINVALID');
      return 'FAILURE';
   }

   $self = {
      'testbed'      => $options{testbed},
      'testcase'     => $options{testcase},
      'session'      => $options{session},
      'logDir'       => $options{logDir},
      'targetkey'    => "testgroup",
   };

   bless ($self, $class);
   return $self;
}

################################################################################
#
# BuildNewWorkloadGroup --
#       Build a new testcase hash from testcase hash for group workload.
#       It overwrites the corresponding keys in testcase hash using test
#       level keys from group workload. It merges the corresponding keys
#       in workloads from group workload sequence using workload level
#       keys from group workload(high priority).
#       0. create new testcase hash(newWorkloadGroup) from existing testcase
#          hash
#       1. Delete Sequence/WORKLOADS from newWorkloadGroup
#       2. Create Sequence/WORKLOADS from Sequence/groupworkload
#       3. Replace noofretries of each workload in Sequence/groupworkload with
#          noofretries for group workload
#       4. Replace Iterations of Sequence/WORKLOADS with iterations of group
#          workload
#       5. Delete group workload from newWorkloadGroup
#       6. Delete ExitSequence from newWorkloadGroup if any
#       Note:
#       Sequence in GroupWorkload is an array
#       Sequence in WORKLOADS is an array of array
#
# Input:
#       None
#
# Results:
#       None
#
# Side effects:
#       None
#
###############################################################################

sub BuildNewWorkloadGroup
{
   my $self = shift;
   $vdLogger->Debug('The original testcasehash: ' . Dumper($self->{testcase}));
   $self->{newWorkloadGroup} = dclone $self->{testcase};
   my $workload = $self->{name};
   my $workloads = $self->{newWorkloadGroup}{WORKLOADS};

   my $sequence = [];
   for my $seq (@{$workloads->{$workload}{sequence}}) {
      $vdLogger->Trace('Processing workload ' . $seq);
      push @$sequence, [$seq];
      # process workload level keys. Add more if any
      if (defined $workloads->{$workload}{noofretries}) {
         $workloads->{$seq}{noofretries} = $workloads->{$workload}{noofretries};
      } else {
         delete $workloads->{$seq}{noofretries};
      }
   }
   delete $workloads->{Sequence};
   $workloads->{Sequence} = $sequence;
   delete $workloads->{ExitSequence} if defined $workloads->{ExitSequence};

   # process test level keys. Add more if any
   delete $workloads->{Iterations};
   if (defined $workloads->{$workload}{iterations}) {
      $workloads->{Iterations} = $workloads->{$workload}->{iterations};
   }

   delete $workloads->{$workload};
   $vdLogger->Debug('The new workload group: ' . Dumper($self->{newWorkloadGroup}));
}

########################################################################
#
# GetWorkloadsManagerObj--
#     Method to return workloads manager object
#
# Input:
#     None
#
# Results:
#     return workloads manager object
#
# Side effects:
#     None
#
########################################################################

sub GetWorkloadsManagerObj
{
   my $self = shift;
   return $self->{workloadsManager};
}


########################################################################
#
# SetWorkloadsManagerObj--
#     Method to set/initialize workloads manager object
#
# Input:
#     None
#
# Results:
#     SUCCESS, if workloads manager object is initialize successfully
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetWorkloadsManagerObj
{
   my $self = shift;
   my $workloadObj = VDNetLib::Workloads::WorkloadsManager->new(
                                             session => $self->{session},
                                             testbed => $self->{testbed},
                                             logDir =>  $self->{logDir},
                                             testcase => $self->{newWorkloadGroup}
                                             );
   if ($workloadObj eq FAILURE) {
      $vdLogger->Error("Failed to create Workloads object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $workloadObj->{groupWorkload} = TRUE;
   $vdLogger->Info('Created wrokloads manager to run group workload');
   $self->{workloadsManager} = $workloadObj;
   return SUCCESS;
}

########################################################################
#
# StartWorkload --
#      This method will process the workload hash of type 'Host'
#      and execute necessary operations (executes host related
#      methods mostly from VDNetLib::Host::HostOperations.pm).
#
# Input:
#      None
#
# Results:
#     "PASS", if workload is executed successfully,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the Host workload being executed
#
########################################################################

sub StartWorkload {
   my $self = shift;
   $self->BuildNewWorkloadGroup();
   if ($self->SetWorkloadsManagerObj() eq FAILURE) {
      $vdLogger->Error('Failed to set workloads manager');
      return FAILURE;
   }
   my $workloadObj = $self->GetWorkloadsManagerObj();
   $self->{result} = $workloadObj->RunWorkload();
   return $self->{result};
}


########################################################################
#
# CleanUpWorkload --
#      This method is to perform any cleanup of HostWorkload,
#      if needed. This method should be defined as it is a required
#      interface for VDNetLib::Workloads::Workloads.
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
########################################################################

sub CleanUpWorkload {
   my $self = shift;
   # TODO - there is no cleanup required as of now. Implement any
   # cleanup operation here if required in future.
   return PASS;
}

1;
