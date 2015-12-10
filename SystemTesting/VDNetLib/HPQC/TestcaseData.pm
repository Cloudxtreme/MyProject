#!/usr/bin/perl
########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::HPQC::TestcaseData;

#
# This class has attributes and methods to process test case
# between VDNet and HPQC
#

use strict;
use warnings;
use Data::Dumper;
use JSON;


########################################################################
#
# new--
#     Constructor to create an object of VDNetLib::HPQC::TestcaseData
#
# Input:
#     testcaseHash : reference to one vdnet testcase hash
#
# Results:
#     An object of VDNetLib::HPQC::TestcaseData
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $testcaseHash = $options{testcaseHash};
   my $testcase;

   # convert keys in testcase hash to lower case
   %$testcase = (map { lc $_ => $testcaseHash->{$_}} keys %$testcaseHash);
   my $hpqcTestcase = {
      'Subject'          => $testcase->{qcpath} || '',
      'Product'         => $testcase->{product} || '',
      'FunctionalArea'  => $testcase->{category} || '',
      'Component'       => $testcase->{component} || '',
      'TestCaseName'    => $testcase->{testname} || '',
      'PMT#'            => $testcase->{pmt} || '',
      'Objective'       => $testcase->{summary} || '',
      'Pre-Condition'   => $testcase->{precondition} || '',
      'QCInternal'      => $testcase->{qcinternal} || 'MANUAL',
      'Procedure'       => $testcase->{procedure} || '',
      'ExpectedResult'  => $testcase->{expectedresult} || '',
      'Status'          => $testcase->{status} || '',
      'AutomationLevel'      => $testcase->{automationlevel} || '',
      'FullyAutomatable?'    => $testcase->{fullyautomatable} || '',
      'AutoScriptPath(ID?)'  => $testcase->{scriptpath} || '',
      'ExecDuration(min)'    => $testcase->{duration} || '',
      'TestCaseLevel'        => $testcase->{testcaselevel} || '',
      'TestCaseType'         => $testcase->{testcasetype} || '',
      'TestCasePriority'     => $testcase->{priority} || '',
      'TestCaseDeveloper'    => $testcase->{developer} || '',
      'PartnerFacing'        => $testcase->{partnerfacing} || '',
      'Keyword'              => $testcase->{tags} || '',
      'Hardware'             => $testcase->{hardware} || '',
      'Software'             => $testcase->{software} || '',
      'TestBed'              => $testcase->{testbed} || '',
      'Others'               => $testcase->{others} || '',
      'TDSReference'         => $testcase->{tdsreference} || '',
      'Attachment'           => $testcase->{attachment} || '',
   };
   my $self = {
      'hpqcTest' => $hpqcTestcase,
   };
   bless ($self, $class);
   return $self;
}


########################################################################
#
# ConvertTestToJSON--
#     Method to convert testcase hash to JSON object
#
# Input:
#     None
#
# Results:
#     JSON object of the test case
#
# Side effects:
#     None
#
########################################################################

sub ConvertTestToJSON
{
   my $self = shift;
   return encode_json($self->{'hpqcTest'});
}
1;

