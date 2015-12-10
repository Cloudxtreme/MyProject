use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../../../../";
use lib "$FindBin::Bin/../../../../VDNetLib/";

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::EsxUtils;


VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 10,
                                               'logToFile'   => 1,
                                               'logFileName' => "getFreePnics.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}

# Input params for this unit test
################################################################################
my $esxHostIP = "10.115.172.60" || <STDIN>;
################################################################################


if (not defined $esxHostIP) {
     $vdLogger->Error("Please provide esx host ip");
     exit -1;
}

my $options;
$options->{logObj} = $vdLogger;
my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
if (not defined $stafHelper) {
     $vdLogger->Error("STAF is not running");
     exit -1;
}

my $esxUtilObj = VDNetLib::Common::EsxUtils->new($vdLogger, $stafHelper);
if (not defined $esxUtilObj) {
   $vdLogger->Error("Failed to create EsxUtils object");
   VDSetLastError("EOPFAILED");
   exit 0;
}

my @nicList = $esxUtilObj->GetFreePNics($esxHostIP, "same");
$vdLogger->Info("max free pnics of similar kind:" . Dumper(@nicList));

my @nicList2 = $esxUtilObj->GetFreePNics($esxHostIP, );
$vdLogger->Info("all free pnics:" . Dumper(@nicList2));

exit 0;
