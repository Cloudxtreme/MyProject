#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::Common::Utilities;
use PLSTAF;

#use Getopt::Long qw(GetOptionsFromString);
use Getopt::Long;

# Following are the parameters coming from portable tools framework
# convert these parameters into vdNet command line args

my $hostIP;
my $SUTVMName;
my $helperVMName;
my $deviceName;
my $logdir;

my $portableToolsUsage = "Usage: -h <hostIP> -g <SUTVMName> " .
                         "-hvm1 <helperVMName> -device <deviceName>" .
                         "-logdir <logdir>\n";

my $vdNetCmd = "/automation/main/vdNet.pl";
my $vdNetArgs="";
my $resultFile;
my $racetrack;
my $PowMgmt = " -t VirtualNetDevices.VirtualNetDevices.WOL ";
my $IPv6Pow = " -t VirtualNetDevices.VirtualNetDevices.TCPUDPTraffic " .
              " -t VirtualNetDevices.VirtualNetDevices.TSOIPV6 " .
              " -t VirtualNetDevices.VirtualNetDevices.IPV6sVLAN " .
              " -t VirtualNetDevices.VirtualNetDevices.IPV6gVLAN " .
              " -t VirtualNetDevices.VirtualNetDevices.TSOIPV6Operations " .
              " -t VirtualNetDevices.VirtualNetDevices.IPV6UDP " .
              " -t VirtualNetDevices.VirtualNetDevices.ChecksumIPV6 " ;

my $JTCL    = " -t VirtualNetDevices.VirtualNetDevices.PowerOnOff " .
              " -t VirtualNetDevices.VirtualNetDevices.SuspendResume " .
              " -t VirtualNetDevices.VirtualNetDevices.DisconnectConnectvNIC " .
              " -t VirtualNetDevices.VirtualNetDevices.SnapshotRevertDelete " .
              " -t VirtualNetDevices.VirtualNetDevices.EnableDisablevNIC " .
              " -t VirtualNetDevices.VirtualNetDevices.Checksum " .
              " -t VirtualNetDevices.VirtualNetDevices.JumboFrame " .
              " -t VirtualNetDevices.VirtualNetDevices.JumboFrameOperations " .
              " -t VirtualNetDevices.VirtualNetDevices.JumboFramegVLAN " .
              " -t VirtualNetDevices.VirtualNetDevices.JumboFramesVLAN " .
              " -t VirtualNetDevices.VirtualNetDevices.EnableDisableTSO " .
              " -t VirtualNetDevices.VirtualNetDevices.HotAddvNIC " .
              " -t VirtualNetDevices.VirtualNetDevices.JFPingSR " .
              " -t VirtualNetDevices.VirtualNetDevices.TSOOperations " .
              " -t VirtualNetDevices.VirtualNetDevices.TSOgVLAN " .
              " -t VirtualNetDevices.VirtualNetDevices.TSOsVLAN " ;
# TODO        " -t $driverName:LPD.LRO_LPD_Functionality:$driverName " .

# Not validating GetOptions return value as portable tools could have other
# options for other FVT tests.

GetOptions (
              "hostip|h=s"       => \$hostIP,
              "SUTVMName|g=s"    => \$SUTVMName,
              "hvm1=s"           => \$helperVMName,
              "device=s"         => \$deviceName,
              "logdir|l=s"       => \$logdir,
              "racetrack=s"        => \$racetrack,
              "help"             => sub {
                                       print $portableToolsUsage;
	                               exit 0;
                                    },
);

# validate all parameters, I guess POTS framework can handle die
if ((not defined $hostIP) || ($hostIP eq "")) {
   die "Invalid Host IP address\n";
}

if ((not defined $SUTVMName) || ($SUTVMName eq "")) {
   die "Invalid SUT VM Name\n";
}

if ((not defined $helperVMName) || ($helperVMName eq "")) {
   die "Invalid helper VM Name\n";
}

# device is an optional arg, check for valid name if provided
if ((defined $deviceName) &&
    (($deviceName eq "") || ($deviceName !~ /vmxnet2/))) {
   die "Invalid device name\n";
}

if ((not defined $logdir) || ($logdir eq "")) {
   die "Invalid logdir\n";
}

my $SUTVal = "$SUTVMName" . ':' . $hostIP;
my $helperVal = "$helperVMName" . ':' . $hostIP;
my $logfile;

if ($logdir =~ /\/$/) {
   $resultFile = $logdir . 'test_result.txt';
   $logfile = $logdir . 'vdnet-pots.log';
} else {
   $resultFile = $logdir . '/test_result.txt';
   $logfile = $logdir . '/vdnet-pots.log';
}

if (defined $deviceName && $deviceName =~ /vmxnet2/) {
   $SUTVal = $SUTVal . ',vnic=vmxnet2';
   $helperVal = $helperVal . ',vnic=vmxnet2';
}
# TODO: remove -src option after fixing exit14
$vdNetArgs .= " --options notools -src local -sut \"$SUTVal\" -helper \"$helperVal\" " . "$JTCL " . "$IPv6Pow " . "$PowMgmt " .  " -resultfile $resultFile";
$vdNetCmd .= $vdNetArgs;
if (defined $racetrack) {
   $vdNetCmd .= " -racetrack $racetrack";
}
print "$vdNetCmd\n";
system("$vdNetCmd | tee $logfile");
