#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################

########################################################################
#
# vdNet.pl --
#     This perl script is the entry point of VDNet.
#     VDNet is a tool for configuring and verifying Cloud Infrastructure
#     specifically the networking components along with various IO
#     workloads.
#     VDNet is composed of harness + framework + library + test cases.
#     For more details on VDNet, refer to wiki.eng.vmware.com/VDNet
#
########################################################################

#
# Load all the modules necessary
#
BEGIN {
$ENV{VDNET_USE_THREADS} = (defined $ENV{VDNET_USE_THREADS}) ?
                           $ENV{VDNET_USE_THREADS} : 1;
require forks if ($ENV{VDNET_USE_THREADS}); #forks has be loaded before anything
}
use strict;
use warnings;
use Carp;
use FindBin;
use Fcntl qw(:DEFAULT :flock);
use Getopt::Long;
use Data::Dumper;
use LWP::Simple;
use Storable 'dclone';
use POSIX qw(setsid);

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../TDS/";
use lib "$FindBin::Bin/../VDNetLib/VIX/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Text::Table;

use VDNetLib::Session::Session;
use VDNetLib::TestSession::VDNetv1;
use VDNetLib::TestSession::VDNetv2;
use VDNetLib::TestSession::ATS;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDNetUsage;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);
use constant TRUE => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

#
# Defining signal handlers
#

#
# Defined a custom signal handler USR1. When VDNETUSR signal is sent to
# vdnet process, detailed core dump will be thrown and the process will quit.
# This is useful when vdnet process hangs, for example, when it enters
# interruptible sleep state due to i/o buffering issues.
#
use sigtrap "handler" => \&SignalHandler,
                         'INT', 'USR1';
# autoflush stdout
$| = 1;

my $globalConfig = new VDNetLib::Common::GlobalConfig;
my $EXIT_SUCCESS = $globalConfig->GetExitValue("EXIT_SUCCESS");
my $EXIT_FAILURE = $globalConfig->GetExitValue("EXIT_FAILURE");
my $vdnetUsage = $VDNetLib::Common::VDNetUsage::usage;
my $cliParams = {}; # initialize the hash to store all command line parameters
# store the list of options passed on command line in $optionsList
# this will be useful for printing the complete option list when needed
my $optionsList = "";
foreach my $item(@ARGV) {
   $optionsList = $optionsList." $item ";
}
$cliParams->{optionsList} = $optionsList;
unless (GetOptions(
                    "vc|vc=s"                   => \$cliParams->{vc},
                    "sut|sut=s"                 => \$cliParams->{sut},
                    "helper|helper=s"           => \@{$cliParams->{helper}},
                    "tdsID|t=s"                 => \@{$cliParams->{tdsIDs}},
                    "list|l=s"                  => \$cliParams->{listTests},
                    "skiptests|skiptests=s"     => \$cliParams->{skipTests},
                    "hosts|hosts=s"             => \$cliParams->{hostlist},
                    "vms|vms=s"                 => \$cliParams->{vmlist},
                    "pswitch|pswitch=s"         => \$cliParams->{pswitch},
                    "skipsetup|s:s"             => \$cliParams->{skipSetup},
                    "hosted|hosted:s"           => \$cliParams->{hosted},
                    "src|src:s"                 => \$cliParams->{vdNetSrc},
                    "logs|logs:s"               => \$cliParams->{logDirName},
                    "loglevel:s"                => \$cliParams->{logLevel},
                    "logfilelevel:s"            => \$cliParams->{logFileLevel},
                    "consoleLog:s"              => \$cliParams->{logToConsole},
                    "vmrepos|vmrepos=s"         => \$cliParams->{repository},
                    "shared|shared=s"           => \$cliParams->{sharedStorage},
                    "listvms|listvms:s"         => \$cliParams->{listVMs},
                    "options|options=s"         => \$cliParams->{vdnetOptions},
                    "tags|tags=s"               => \$cliParams->{userTags},
                    "testbed|testbed=s"         => \$cliParams->{testbed},
                    "testconfig|testconfig=s"   => \$cliParams->{testConfig},
                    "nocleanup|nocleanup:s"     => \$cliParams->{noCleanup},
                    "listkeys|listkeys=s"       => \$cliParams->{listKeys},
                    "configjson|j=s"            => \$cliParams->{configJSON},
                    "config|c=s"                => \$cliParams->{configYAML},
                    "userspec|u=s"              => \$cliParams->{userTestbedSpec},
                    "interactive|i=s"           => \$cliParams->{"interactive"},
                    "exitoninteractive|exitoninteractive=s" =>
                       \$cliParams->{"exitoninteractive"},
                    "cachetestbed|ct=s"         => \$cliParams->{"cachetestbed"},
                    "nsxsdkbuild|nsxsdkbuild=s" => \$cliParams->{nsxsdkbuild},
                    "optionsyaml|optionsyaml=s" => \$cliParams->{custom_yaml},
                    "testset|testset=s" => \$cliParams->{testSetDescription},
                    "help|h"                    => sub {
                       print $vdnetUsage;
                       exit $EXIT_SUCCESS;
                    },
                    )) {
                       print STDERR "$0: Invalid options";
                       print STDERR "$0: $VDNetLib::Common::VDNetUsage::usage";
                       exit $EXIT_FAILURE;
                    }

#
# A VDNet process (created by running this script) creates an instance of
# Session class.
# Session class has attributes and implement methods to configure a vdnet
# session. One of the important function of Session class is create the
# test list based on user input.
# VDNet creates an instance of TestSession for every test case.
# TestSession is responsible to create testbed spec based on user input,
# Setup, RunTest and Cleanup.
# The final output/exit code of vdnet process is decided based on the
# results from ALL the test sessions.
#
#Store session as a global variable
our $session;
eval {
   $session = VDNetLib::Session::Session->new('cliParams' => $cliParams);
   if ($session eq FAILURE) {
      $vdLogger->Error("Failed to create VDNet session object");
      $vdLogger->Debug(VDGetLastError());
      exit $EXIT_FAILURE;
   }
};

if ($@) {
   $vdLogger->Error("Caught exception while creating session: $@");
   exit $EXIT_FAILURE;
}
# Store the logger object for the main session
my $result;

#
# Handle all vdnet utility options/scripts here
#
if (defined $cliParams->{'listVMs'}) {
   $vdLogger->Info("List of VMs:" . $session->GetVMList($session->{'vmServer'},
                                                        $session->{'vmShare'}));
   exit $EXIT_SUCCESS;
}

if (defined $cliParams->{listKeys}) {
   $session->ListKeys($cliParams->{listKeys});
   exit $EXIT_SUCCESS;
}

if (defined $cliParams->{'listTests'}) {
   $session->PrintListOfTDSIDS($cliParams->{'listTests'},
                               $cliParams->{'userTags'});
   exit $EXIT_SUCCESS;
}
# END of handling utility scripts

# At this point, throw error if --config option is not given
if ((not defined $cliParams->{configJSON}) && (not defined $cliParams->{configYAML})) {
   $vdLogger->Error("Command line option --config missing");
   $vdLogger->Info("$VDNetLib::Common::VDNetUsage::usage");
   exit $EXIT_FAILURE;
}

my @sessionsSummaryContainer = ();
eval {
   $result = $session->Run();
   if ($result ne FAILURE) {
      @sessionsSummaryContainer = @$result;
   } else {
      $vdLogger->Error("Run Session failed");
      $vdLogger->Debug(VDGetLastError());
   }
};
if ($@) {
   $vdLogger->Error("Caught exception while running session: $@");
}

# Find the final result of session based on all test session results
my $finalResult = $EXIT_SUCCESS;
foreach my $item (@sessionsSummaryContainer) {
   if ($item->{result} =~ /FAIL/i) {
      $finalResult = $EXIT_FAILURE;
   }
}

# If the vdnet session initialization fails, @sessionsSummaryContainer
# will be empty so check that and update the $finalResult
if (scalar(@sessionsSummaryContainer) == 0) {
   $finalResult = $EXIT_FAILURE;
}

$vdLogger->Info("Final result: $finalResult");

my $summary = undef;
eval {
   # Get Summary before calling session cleanup, otherwise,
   # there methods within FormatSummary which are dependent
   # on vdnet session will not work
   $summary = $session->FormatSummary(\@sessionsSummaryContainer,
                                      $cliParams->{testbed});
   $result = $session->Cleanup($finalResult);
};
if ($@) {
   $vdLogger->Error("Caught exception in session cleanup: $@");
   $result = FAILURE;
}
if ($result eq FAILURE) {
   $vdLogger->Error("Failed to do vdnet session cleanup" .
                    Dumper(VDGetLastError()));
   $finalResult = $EXIT_FAILURE;
}
if (defined $summary) {
    $vdLogger->Info("Summary:\n" . $summary);
}
$vdLogger->Destroy();
exit $finalResult;
# END OF MAIN


########################################################################
#
# SignalHandler --
#      Routine to handle SIGINT signals.
#
# Input:
#      Signal SIGINT
#
# Results:
#      Cleanup the existing session and exit with code 1
#
# Side effects:
#      The current session will be interrupted.
#
########################################################################

sub SignalHandler
{
   my $signal = shift;
   # TODO - collect list of pids started from Workloads.pm,
   # Send signal to them as well. Upon receiving the signal each
   # processes should call CleanupWorkload()
   #

   if ($signal eq 'USR1') {
      require Carp; Carp::cluck("vdnet stack trace");
      $vdLogger->Error("$signal received, see the stderr for stack trace");
      return undef;
   }
   $vdLogger->Abort("Signal $signal received, doing cleanup and exiting");
   if (defined $session->{currentTestSession}) {
      $session->{currentTestSession}{result} = "ABORT";
   }
   if ((defined $session->{'testLevel'}) &&
      (($session->{'testLevel'} eq 'complete') ||
       ($session->{'testLevel'} eq 'cleanupOnly'))) {
      if (defined $session->{currentTestSession}) {
         $session->{currentTestSession}->Cleanup(1);
      }
      $session->Cleanup();
   }
   $vdLogger->Abort("Session is aborted. Exiting now...");
   if (defined $session->{currentTestSession}) {
      $session->{currentTestSession}->End();
   }
   exit $EXIT_FAILURE;
}
