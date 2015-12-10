#!/usr/bin/perl

########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

########################################################################
# Description
# This is the wrapper script for running vdNet with VMTF framework to
# run Networking tests.
# Flow
# 1. It accepts three xml files namely resource.xml,testlist.xml and
#    session.xml. However the name of the files can be different, but
#    while passing arguments to VRun harness correct files should be
#    passed.
# 2. Creates the command line for vdNet by obtaining the parameters from
#    xml files.
# 3. Calls the vdNet.pl with suitable command line args and collects the
#    test results from vdNet.pl file using the Tie module.
#
# Ex Usage:
#    vrun -R /automation/harness/xmls/resource.xml
#         -T /automation/harness/xmls/testlist.xml
#         -S /automation/harness/xmls/session.xml
# Input:
#       -R   - Resource XML file
#       -T   - TestList XML file
#TODO:  -S   - Sessions XML file
#
# Output:
#     Result of vdNet.pl file
########################################################################

#
# Load all the necessary modules
#

use strict;
use warnings;
use VMP;
use PLSTAF;
use vet;
use Data::Dumper;
use GlobalConfig;
use vdNetUsage;
use VRun;

# This is required to access the result of
# vdNet.pl script.
my %VDNET;
use Tie::Persistent;
if (-e "file-vdNet-vrunwrap") {
   unlink "file-vdNet-vrunwrap";
}

#
# use the following flag for debugging
# purposes only by setting it to 1
#

my $debug = 0;

#
# command line args provided to vdNet.pl
#

my @testMcs = ();
my @tdsIDs = ();
my $resultFile; # provided in the command line argument;

#
# keys are object to the test sets
#

my %TDS = ();

#
# This hash contains complete test case information
#

my ($resource,$test,$report); # required for VMTF
my $hostIP; # required by VMTF
my $hostType; # required by VMTF
my $hostUser; # required by VMTF
my $hostPassword; # required by VMTF
my $testCaseID; # This is required by VMTF
my $exitVal = new GlobalConfig;
my $EXIT_SUCCESS = $exitVal->getExitValue("EXIT_SUCCESS");
my $EXIT_FAILURE = $exitVal->getExitValue("EXIT_FAILURE");


#
# =======   VMTF Integration Starts here   =======
# The VRun::Init will return reference to three
# hashes from the input xml files passed to it.
# The testbed info and other details shall  be
# obtained from these hash references.
# The report hash is empty at this time, but its
# contents should be filled before being passed
# back to harness script using Sendreport command
# The reporting is implemented using Report method
#

($resource,$test,$report) = VRun::Init("$0");
if (!defined($resource)) {
   print STDERR "$0:  Init Failed.\n";
   exit $EXIT_FAILURE;
}


#
# Print the xml contents turned into hashes
# for the sake of verification.
#

print "============================================\n" if $debug;
print "resource = " . Dumper($resource) if $debug;
print "============================================\n" if $debug;
print "testlist = " . Dumper($test) if $debug;
print "============================================\n" if $debug;
print "report   = " . Dumper($report) if $debug;
print "============================================\n" if $debug;

my $hostSize = @{$resource->{host}};
my @hostArray;
my $i;

for ($i = 0; $i < $hostSize; $i++) {
   $hostArray[$i] = $resource->{host}[$i];
}


#
#  Get the first host from the resource data
#  Note: At present only first available host
#  information is collected. The rest of the
#  information can be used in future for tests
#  like vmotion.
#

my $host = $hostArray[0];


#
#  Extract information specific to the selected host
#

$hostType     = $hostArray[0]->{type}[0];
$hostIP	      = $hostArray[0]->{ip}[0];
$hostUser     = $hostArray[0]->{username}[0];
$hostPassword = $hostArray[0]->{password}[0];

print "HOSTTYPE : $hostType \n" if $debug;
print "HOSTIP   : $hostIP \n" if $debug;
print "HOSTUSER : $hostUser \n" if $debug;
print "HOSTPASWD: $hostPassword \n" if $debug;


#
# Obtain SUT IP and Helper Machine IPs in the following
# block of code
#

my $vmArraySize = @{$hostArray[0]->{virtualmachines}[0]->{vm}};
my @vms = @{$hostArray[0]->{virtualmachines}[0]->{vm}};
my $sutIP;
my $helperIP1;


#
# We expect one sut ip and one helper ip atlease for
# the test. However test can have more helper machine
# and we are collecting the information on those ips
# also.
#

#
# obtain SUT IP
#

if (defined $vms[0]->{ip}[0]) {
    $sutIP = $vms[0]->{ip}[0];
    push(@testMcs,"$sutIP,$hostIP");
} else {
    &Report($report, $VRun::ERROR, $hostIP, "SUT IP not supplied");
    exit $EXIT_FAILURE;
}

#
# obtain helper IP
#

if (defined $vms[1]->{ip}[0]) {
    $helperIP1 = $vms[1]->{ip}[0];
    push(@testMcs,"$helperIP1,$hostIP");
} else {
    &Report($report, $VRun::ERROR, $hostIP, "Helper IP not supplied");
    exit $EXIT_FAILURE;
}

#
# Obtain other Helper IPs
#

my @helpers;
for ($i = 2; $i < $vmArraySize; $i++) {
   if (defined $vms[$i]->{ip}[0]) {
       $helpers[$i] = $vms[$i]->{ip}[0];
       push(@testMcs,"$helpers[$i],$hostIP");
   }
}


#
# At present only one tds id per invocation is addressed.
# VMTF will support multiple tds ids in the next version
# where test input can be produced using config files
#

my $tds = $test->{'parms'} =~ m/[0-9a-z]+:[a-z.]+:[0-9a-z]+/i;
@tdsIDs = $&;

#
# Check if tds id is supplied or not
#

if (not defined $tdsIDs[0]) {
   # logging an error as test inputs are not complete
   print $vdNetUsage::usage;
   &Report($report, $VRun::ERROR, $hostIP, "Test input not supplied");
   exit $EXIT_FAILURE;
}

$testCaseID = $tdsIDs[0];

my $vmString;
foreach my $el (@testMcs) {
    $vmString .= "-i $el ";
}

my $result = `perl vdNet.pl $vmString -t $tdsIDs[0] -v`;

#
# read stored data, no modification of file data
#
tie %VDNET, 'Tie::Persistent', 'file-vdNet-vrunwrap','rw';
print "VDNET STATUS IN WRAPPER is $VDNET{STATUS} **\n" if $debug;

my $testString;
if ($VDNET{STATUS} =~ /PASS/i) {
   $testString = "Test $testCaseID Completed Successfully";
   &Report($report, $VRun::PASS, $hostIP, "$testString");
} else {
   $testString = "Test $testCaseID Failed to run";
   &Report($report, $VRun::FAIL, $hostIP, "$testString");
}

untie %VDNET;
exit 0;
# END OF MAIN



#----------------------------------------------------------------------
#
# Method Name: Report()
#
# Method Task: Calls the report function with supplied arguments
#
# Input      :
#              1. report hash to be filled
#              2. Pass/Fail/ status or other VRUN messages
#              3. HostIP
#              4. Resason for test status
#
# output     : None
#
# Side effects: Prints the results to the log
#
#----------------------------------------------------------------------

sub Report($$$$)
{
   my $report      = shift;            # IN:  Ref. to report structure
   my $status      = shift;            # IN:  Pass/fail status
   my $machine     = shift;            # IN:  Host on which run
   my $description = shift;            # IN:  description of result


   #
   #  We populate the $report hash with the information
   #  we wish to send back to the harness
   #

   $report->{status}  = $status;
   $report->{machine} = $machine;
   $report->{comment} = $description;
   $report->{testid}  = $testCaseID; # This is obtained from top of the file

   print "report = " . Dumper($report);


   #
   #  Now we send the data to the harness
   #

   VRun::Report($report);
}

