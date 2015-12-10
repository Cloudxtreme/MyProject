use strict;
use warnings;
use Data::Dumper;
use FindBin;

use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/";

use VDNetLib::Switch::Switch;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 9,
                                               'logToFile'   => 1,
                                               'logFileName' => "createSwitchObj.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}
my $options;
$options->{logObj} = $vdLogger;


$options->{'switch'} = "vdtest";
$options->{switchType} = "vswitch";
$options->{host} = "10.20.116.232";
$options->{hostOpsObj} = undef;

my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
if (not defined $stafHelper) {
     $vdLogger->Error("STAF is not running");
     exit -1;
}

$options->{hostOpsObj} = VDNetLib::Host::HostOperations->new($options->{host}, $stafHelper);

if ($options->{hostOpsObj} eq FAILURE) {
   $vdLogger->Error(VDGetLastError());
   exit -1;
}

our $switchObj = VDNetLib::Switch::Switch->new('switch' => $options->{'switch'},
                                               'switchType' => $options->{switchType},
	                                       'host' => $options->{host},
                                               'hostOpsObj' => $options->{hostOpsObj},
);

if ($switchObj eq FAILURE) {
   $vdLogger->Error(VDGetLastError());
   exit -1;
}

$vdLogger->Info("SwitchObj:" . Dumper($switchObj));
