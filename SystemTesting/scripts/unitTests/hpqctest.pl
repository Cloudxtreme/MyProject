########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved.
########################################################################
#
# hpqctest.pl--
# A unit test script to verify hpqc module.
#

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

use constant QC_CONNECTOR                     => 'com.vmware.qc.QcConnector';
use constant QC_STATUS                        => 'com.vmware.qc.QcTestStatus';

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 9,
                                               'logToFile'   => 0,
                                               'logFileName' => "vdnet.log");

if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit 1;
}

# Input parameters - update them depending on your test setup
our $classPathDir = '/usr/local/staf/services/VMware5x/lib';
our $result = 0;

if (not defined $classPathDir) {
   print "--classdir paramater is empty\n";
   exit 1;
}

my $port  = VDNetLib::Common::GlobalConfig::INLINE_JVM_INITIAL_PORT;

$result = LoadInlineJava(DEBUG => 0, DIRECTORY => '/tmp',
                         CLASSDIR  => $classPathDir,PORT => $port);

CheckResult();
print "** Inline Java module loaded successfully **\n";

eval {
   my $connector = CreateInlineObject(QC_CONNECTOR);
   #my $status = CreateInlineObject(QC_STATUS);
   my $status = $com::vmware::qc::QcTestStatus::NOT_COMPLETED;
   if (defined $connector ) {
      print "** qcconnector created successfully **\n";
   } else {
      print "** qcconnector created failed **\n";
      exit 1;
   }
   my $ti = $connector->findTestInstance("Root/MN.next/Networking-FVT/SampleCycle",
             "testcycle","ESXi.Network.VDL2.Positive.Offloading.IPv6");

   my $id = $ti->getId();
   print("** Test case instance id is $id\n");
   # FAILED, PASSED, NOT_COMPLETED
   my $new_ti = $connector->postResult2Qc($id,
                $VDNetLib::InlineJava::VDNetInterface::com::vmware::qc::QcTestStatus::NOT_COMPLETED);
   my $ss = $new_ti->getStatus()->toString();
   print ("** Update status successful - $id: $ss\n");

};
if ($@) {
      InlineExceptionHandler($@);
      print "update HPQC status failed.\n";
      exit 1;
}



sub CheckResult
{
   if (!$result) {
      print "check result $result.\n";
      exit $result;
   }
}


