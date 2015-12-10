########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved.
########################################################################
package VDNetLib::HPQC::HPQC;

# This is interface between HPQC and VDNet.

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler);

use constant QC_CONNECTOR          => 'com.vmware.qc.QcConnector';
use constant QC_STATUS             => 'com.vmware.qc.QcTestStatus';

my $instance;


###############################################################################
#
# new --
#      Constructor/entry point to create an singleton object of this package
#      (VDNetLib::HPQC::hpqc)
#
# Input:
#
#
# Results:
#      An object of VDNetLib::HPQC package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my ($class)   = @_;
   my $self      = {};
   my $connector = undef;
   my $port      = VDNetLib::Common::GlobalConfig::INLINE_JVM_INITIAL_PORT;
   if ( not defined $instance){
      $instance = bless {}, $class;
      # Create inline java object of qcConnector
      $instance->{connector} = CreateInlineObject(QC_CONNECTOR);
      if (defined $instance->{connector}) {
         $vdLogger->Info("qcConnector object created successfully");
      } else {
         $vdLogger->Error("qcConnector object created failed");
      }
   }
   return $instance;
}


###############################################################################
#
# FindTestInstance --
#      Find test case id according testpath/testset/testcase name.
#
# Input:
#      testpath  - test path name, like
#                  "Root/MN.next/Networking-FVT/SampleCycle"
#      testset   - test set name, like
#                  "testcycle"
#      testcase  - test case name, like
#                  "ESXi.Network.VDL2.Positive.Offloading.IPv6"
#
# Results:
#      test case id if found, undef if not found.
#
# Side effects:
#      None
#
###############################################################################

sub FindTestInstance
{
   my ($self,$testpath,$testset,$testcase)   = @_;
   my $tcid = undef;
   my $id = undef;

   eval {
      my $tc = $self->{connector}->findTestInstance($testpath,
                                                    $testset,$testcase);
      $id = $tc->getId();

   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Get test case instance failed!");
      return undef;
   }
   return $id;
}


###############################################################################
#
# PostResult2QC --
#      update the status on HPQC according test case id
#
# Input:
#      testid    - test case instance id
#      Status    - value of [PASS,SKIP,FAIL]
#
# Results:
#      No
#
# Side effects:
#      None
#
###############################################################################

sub PostResult2QC
{
   my ($self,$id,$status) = @_;
   my $tmp = undef;
   eval {
      LoadInlineJavaClass('com.vmware.qc.QcTestStatus');
      if ($status =~ /SKIP/i ){
         $vdLogger->Debug("Update HPQC with keyword SKIP testid = $id)");
         $tmp = $VDNetLib::InlineJava::VDNetInterface::com::vmware::qc::QcTestStatus::NOT_COMPLETED;
      } elsif ($status =~ /PASS/i ) {
         $vdLogger->Debug("Update HPQC with keyword PASS (testid = $id)");
         $tmp = $VDNetLib::InlineJava::VDNetInterface::com::vmware::qc::QcTestStatus::PASSED;
      } elsif ($status =~ /FAIL/i ) {
         $vdLogger->Debug("Update HPQC with keyword FAIL (testid = $id)");
         $tmp = $VDNetLib::InlineJava::VDNetInterface::com::vmware::qc::QcTestStatus::FAILED;
      }
      if (defined $tmp){
         $self->{connector}->postResult2Qc($id,$tmp);
      } else {
         $vdLogger->Error("Update HPQC with wrong keyword ($status)");
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("update status to HPQC failed!");
   }
}

1;
