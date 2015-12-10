########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::CommandWorkload;

#
# This module executes any command line or scripts (environment variable PATH
# must have path to the script/command) defined by 'Command' type workloads
# in the test case hash.
#
# TODO - update the workload hash structure with all keys  and supported values
# here.
#
use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError VDGetLastError );

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use constant TARGETDATABASE => {
   'testhost' =>  "hostIP",
   'testvm'   =>  "vmIP",
   'testvc'   =>  "vcaddr",
};

########################################################################
#
# new --
#      Method which returns an object of VDNetLib::CommandWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::CommandWorkload object, if successful;
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

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      };

    bless ($self, $class);
    return $self;
}


########################################################################
#
# StartWorkload --
#      This method will process the workload hash  of type 'Command'
#      and execute necessary operations (executes command with given
#      options).
#
# Input:
#      None
#
# Results:
#     "PASS", if successful,
#     "FAIL", in case of any error;
#
# Side effects:
#     Depends on the command/script being executed
#
########################################################################

sub StartWorkload {
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};
   my ($targetIP, $testTarget,$tuple);
   my $is_Async;

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);
   %temp =  %$dupWorkload;

   # Find the test mgm key and the tuple assigned to it
   foreach my $key (keys %$dupWorkload) {
      if ($key =~ /test/i) {
         $testTarget = $key;
         $tuple = $dupWorkload->{$testTarget};
      }
   }

   my $sleepBetweenWorkloads = $dupWorkload->{'sleepbetweenworkloads'};
   if (defined $sleepBetweenWorkloads) {
      $vdLogger->Info("Sleep between workloads of value " .
                      "$sleepBetweenWorkloads is given. Sleeping ...");
      sleep($sleepBetweenWorkloads);
   }

   my $command = $dupWorkload->{command};
   $vdLogger->Debug("Running Command Workload for command=$command on $testTarget=$tuple");

   if ($tuple =~ /local/i) {
      $targetIP = "local";
   } else {
      my $tagetTable = $self->GetTargetKeysTable();
      # Get the ip type from hash
      my $ipAttribute = $tagetTable->{$testTarget};
      my $testObj = $self->GetOneObjectFromOneTuple($tuple);
      $targetIP = $testObj->{$ipAttribute};
   }

   #default expect result is PASS;
   if (not defined $dupWorkload->{expectedresult}) {
      $dupWorkload->{expectedresult} = "PASS";
   }
   my $stafInput;
   $stafInput->{logObj} = $vdLogger;
   my $stafObj = VDNetLib::Common::STAFHelper->new($stafInput);

   if (not defined $stafObj) {
      $vdLogger->Error("Failed to create STAF object");
      VDSetLastError("ESTAF");
      return "FAIL";
   }
   my $ret;
   my $args;
   if (defined $dupWorkload->{args}) {
      $args = $dupWorkload->{args};
      $command = $command . " " . $args;
   }
   $vdLogger->Info("TargetIP:$targetIP, command:$command");

   if ($dupWorkload->{async} && $dupWorkload->{async} eq "1") {
       $is_Async = 1;
       $vdLogger->Info("Run $command by async process on $targetIP");
   } else {
       $is_Async = 0;
       $vdLogger->Info("Run $command by synchronous process on $targetIP");
   }

   my $result;
   if ($is_Async == 0) {
      $result = $stafObj->STAFSyncProcess($targetIP, $command);
   } else {
      $result = $stafObj->STAFAsyncProcess($targetIP, $command);
   }

   if ($result->{rc} != 0) {
      $vdLogger->Error("Command $command returned failure");
      $vdLogger->Debug("Stderr: " . $result->{stderr});
      VDSetLastError("EFAIL");
      $ret = "FAIL";
   }
   ### if the command which STAF is executing fails ###
   if ($result->{exitCode} && $result->{exitCode} != 0) {
      $vdLogger->Error("Command $command returned failure");
      $vdLogger->Debug("Stderr: " . $result->{stderr});
      VDSetLastError("EFAIL");
      $ret = "FAIL";
   }

   if (defined $result->{stdout}) {
         $vdLogger->Debug("Stdout: " . $result->{stdout});
   }
   if (defined $dupWorkload->{expectedstring}) {
      if (($result->{stdout} =~ m/$dupWorkload->{expectedstring}/is) ||
         ($result->{stderr} =~ m/$dupWorkload->{expectedstring}/is)) {
         $vdLogger->Info("The $command output matched expected output");
         return "PASS";
      } else {
         $vdLogger->Info("The $command output mismatched expected output");
            return "FAIL";
      }
   }
   if (defined $ret) {
      return "FAIL";
   } else {
      return "PASS";
   }

}


########################################################################
#
# CleanUpWorkload --
#      This method will do all cleanup functions. This method has to be
#      implemented since it is mandatory to work with
#      VDNetLib::Workloads.
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     Depends on the command/script being executed
#
########################################################################

sub CleanUpWorkload {
   return "SUCCESS";
}

########################################################################
#
# GetTargetKeysTable --
#      This method will return the TARGETDATABASE hash
#
# Input:
#      None
#
# Results:
#     "TARGETDATABASE", if successful,
#
# Side effects:
#
########################################################################

sub GetTargetKeysTable
{
   my $self = shift;
   return TARGETDATABASE;
}


1;
