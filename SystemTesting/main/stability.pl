#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;

my $usage = "Usage: ./stability.pl -vc <vcIP> -sutHost <esx1> -sutVM <sutVM> " .
            "-pSwitch <pSwitch> -helpHost <esx2> -helpVM <helpVM> " .
            "-repos <repos> -user <RaceTrack User>\n";

# Testbed
my $esx1;
my $esx2;
my $vc;
my $sutvm;
my $pswitch;
my $helpvm;
my $repos;
my $user;

unless(GetOptions(
      "vc=s"         => \$vc,
      "sutHost=s"    => \$esx1,
      "sutVM=s"      => \$sutvm,
      "pSwitch=s"    => \$pswitch,
      "helpHost=s"   => \$esx2,
      "helpVM=s"     => \$helpvm,
      "repos=s"      => \$repos,
      "user=s"       => \$user,
      "help|h"       => sub {
                           print $usage;
                           exit 0;
                        }
                  )
) {
   die "Invalid option!\n";
}

my $cmd = "./vdNet.pl -vc $vc " .
          "-sut \"host=$esx1,pswitch=$pswitch,vm=$sutvm\" " .
          "-helper \"host=$esx2,vm=$helpvm\" " .
          "-helper \"host=$esx2,vm=$helpvm\" ";

my @cases = (
   'Sample.Sample.FirewallTest',
   'Sample.Sample.IperfTwoHelper',
   'Sample.Sample.VnicVmkNictest',
   'Sample.Sample.IperfTraffic',
   'Sample.Sample.EventHandler2',
   'Sample.Sample.SuspendResume',
   'sample.Sample.vNicComboTest',
   'Sample.Sample.TSOsVLAN',
   'Sample.Sample.VmknicIperf',
   'Sample.Sample.CreatePG',
   'Sample.Sample.ChangeRingParams',
   'Sample.Sample.ConfigurePGAndvSwitch',
   'Sample.Sample.CreatevSwitch',
   'Sample.Sample.EnableDisableRSS',
   'Sample.Sample.ChangeTSOTraffic',
   'Sample.Sample.EventHandler1',
   'Sample.Sample.PingTraffic',
   'Sample.Sample.MultipleAdapters',
   'Sample.Sample.TSOTCP',
   'Sample.Sample.VMNictest',
   'Sample.Sample.SnapShot',
   'Sample.Sample.UDPTraffic',
   'Sample.Sample.MultipleHelpersTest',
   'Sample.Sample.JumboFrame',
   'Sample.Sample.TestvSwitch',
   'SampleVC.SampleVC.VCUnitTest',
   'SampleVC.SampleVC.VDSUnitTest',
   'SampleVC.SampleVC.SetNetIORM',
   'SampleVC.SampleVC.ChangePortgroupWork',
   'EsxServer.DVFilter.DVFilter.dvFilterStress',
   'EsxServer.DVFilter.DVFilter.dvFilterICMPTest',
   'EsxServer.DVFilter.DVFilter.dvFilterConfigModule',
   'EsxServer.NetIORM.NetIORM.SystemPoolsCreation',
   'EsxServer.NetIORM.NetIORM.VMResPoolsAddRemove',
   'EsxServer.NetIORM.NetIORM.SystemPoolsDelete',
   'EsxServer.CHF.CHF.OpaqueChannel',
   'EsxServer.CHF.CHF.OpaqueChannelInvalid',
   'EsxServer.CHF.CHF.Configuration',
   'EsxServer.CHF.CHF.InvalidConfiguration',
   'EsxServer.Firewall.Firewall.VerifyDisabledService',
   'EsxServer.Firewall.Firewall.VerifyInputDefaultServiceCIMHttpsServer',
   'EsxServer.Firewall.Firewall.VerifyInputOutputDefaultServiceCIMSLP',
   'EsxServer.VDS.LLDP.LLDPBoth',
   'EsxServer.VDS.LLDP.LLDPDefaultSettings',
   'EsxServer.VDS.LLDP.BasicConfiguration');

for my $each (@cases) {
   $cmd .= "-t $each ";
}

$cmd .= "-vmrepos \"$repos\" " .
        "-racetrack \"$user\"";

print "$cmd\n\n";

print `$cmd 2>/dev/null | grep Racetrack`;
