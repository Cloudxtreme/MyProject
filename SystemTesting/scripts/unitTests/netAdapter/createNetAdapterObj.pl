use strict;
use warnings;
use Data::Dumper;
use FindBin;
use Cwd;
use Sys::Hostname;

#use PLSTAF;

use lib "$FindBin::Bin/../../../";
use lib "$FindBin::Bin/../../../VDNetLib/";
use lib "$FindBin::Bin/../../../TDS/";
use lib "$FindBin::Bin/../../../VDNetLib/VIX/";
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::Host::HostOperations;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::PLSTAF;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 10,
                                               'logToFile'   => 1,
                                               'logFileName' => "vdnet.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}
my $options;
$options->{logObj} = $vdLogger;

# edit all the following options appropriately
$options->{controlIP} = "10.20.116.179";

my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
if (not defined $stafHelper) {
     $vdLogger->Error("STAF is not running");
     exit -1;
}

################################################################
# Creating NetAdapter Obj for vNIC
################################################################

our $netObj = VDNetLib::NetAdapter::NetAdapter->new(
					           controlIP => $options->{controlIP},
                                                   intType => "vnic",
			                           interface => "eth4",
#                                                  interface => "{DBE69D57-8B50-473C-8991-97EAD6D95C16}",
								 # interface for Windows
                                                                 # You can get this by doing
                                                                 # Windump.exe -D in windows
                                                   );
if ($netObj eq FAILURE) {
   $vdLogger->Error(VDGetLastError());
   exit -1;
}
$vdLogger->Info("NetAdapterObj:" . Dumper($netObj));
