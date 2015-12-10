########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::MH;

#
# This class inherits VDNetLib::TestSession::VDNetv2 class.
# It stores attributes and implements methods to run MH tests
#
use strict;
use warnings;

use base 'VDNetLib::TestSession::VDNetv2';

use FindBin;
use lib "$FindBin::Bin/../";

use JSON;
use Data::Dumper;
use XML::LibXML;
use File::Basename;
use Storable 'dclone';
use VDNetLib::Common::FindBuildInfo;
use VDNetLib::Common::Utilities;
use VDNetLib::Testbed::Testbedv2;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort );
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);


#######################################################################
#
# new --
#     Constructor to create an instance of
#     VDNetLib::TestSession::MH
#
# Input:
#     Named hash parameters with following keys:
#     testcaseHash  : reference to vdnet test case hash (version 2)
#     userInputHash : reference to hash containing all user input
#
#
# Results:
#     An object of VDNetLib::TestSession::MH
#
# Side effects :
#     None
#
#######################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self = VDNetLib::TestSession::VDNetv2->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSession::MH".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Framework options:" . $self->{testFramework});

   $self->{'version'} = "MH";
   bless $self, $class;
   return $self;
}


#########################################################################
#
# StartMHTestRun --
#    Method to start the vcqe test run
#
# Input:
#    None
#
# Results:
#    None
#
# Side effects:
#    None
#
#########################################################################

sub StartMHTestRun
{
   my $self = shift;
   my ($mh, $testID) =
       split(/MH./, $self->{testcaseHash}->{testID}, 2);

   my $testbedFile;
   my $testFramework = $self->{testFramework};

   #
   # Check if 'inventory' is given under 'testframework' option.
   # If yes, then pass the value as it is to mh_runner.py. This is needed
   # for special cases which does not require provisioning from
   # vdnet. Otherwise, send the testbed json as input to mh_runner.py
   #
   if (defined $testFramework->{inventory}) {
      $testbedFile = $testFramework->{inventory};
   } else {
      $testbedFile = $vdLogger->{logDir} . '../testbed.json';
   }

   my $cmd = "cd $ENV{QE_LIB}/qe ; python  mh_runner.py -l -b $vdLogger->{logDir}";
   $vdLogger->Info("Starting python command $cmd to run test");
   system("$cmd 2>&1 > /dev/null");

   my $data;
   if (open (my $json_str, $vdLogger->{logDir}."testlist.json")) {
      my $json = JSON->new;
      $data = $json->decode(<$json_str>);
      close($json_str);
   } else {
      $vdLogger->Error("Failed to open testlist.json file");
      return FAILURE;
   }

   my $failed = 0;
   my $noRuns = 1;
   foreach my $testInfo (@$data) {
      my $testid = $testInfo->{'testid'};
      if ($testid eq $testID ) {
         my $result = $self->ExecuteMHTest($testid,
                                           $testbedFile,
                                           $vdLogger->{logDir});
         if ($result eq 'FAILURE') {
            $failed = 1;
         }
         $noRuns = 0;
      }
   }

   if ($noRuns) {
      $vdLogger->Error("Failed to find testid=$testID");
      return FAILURE;
   }
   if ($failed) {
      return FAILURE;
   }
   return SUCCESS;
}


#########################################################################
#
# ExecuteMHTest --
#     Method to execute the vcqe test class or the test suite
#
# Input:
#     testID - test class to be executed
#
# Results:
#     SUCCESS, if test was run successfully and it passed
#     FAILURE, if test failed
#
# Side effects:
#     None
#
#########################################################################

sub ExecuteMHTest
{
   my $self = shift;
   my $testID = shift;
   my $inventoryFileName = shift;
   my $logDir = shift;

   my $cmd = "cd $ENV{QE_LIB}/qe ; python mh_runner.py -b $logDir -t $testID --inventory $inventoryFileName";
   $vdLogger->Info("Starting python command $cmd to run test");
   my $result = system($cmd . " > $logDir/mh.log");

   if (open (my $logData, $vdLogger->{logDir}."mh.log")) {
      my $data =  <$logData>;
      $vdLogger->Info("Logs from MH: $data");
      close($logData);
   }

   if ($result) {
      $vdLogger->Error("Test $testID returned failure");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RunTest --
#     Method to run test using the given testcase hash and testbed
#
# Input:
#     None
#
# Results:
#     SUCCESS, if test is run successfully
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunTest
{
   my $self = shift;
   my $result = FAILURE;
   $self->{'result'} = "FAIL";

   $result = $self->StartMHTestRun();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure while running MH Tests");
      return FAILURE;
   }
   $vdLogger->Info("Completed MH Test run");

   if ($result ne 'FAILURE') {
      $self->{'result'} = "PASS";
   }

   return $result;
}
1;
