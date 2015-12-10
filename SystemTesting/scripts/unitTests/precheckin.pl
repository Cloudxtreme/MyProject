########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved.
########################################################################

#
# precheckin.pl--
#     Pre-checkin script to verify any changes made to vdnet.
#     This should be run in addition to unit tests specific to the changes
#
# Example:
#     perl /automation/scripts/unitTests/precheckin.pl --host 10.115.172.181 \
#     --vc 10.114.164.251 -src 10.20.116.224
#
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../../";


my $vcAddr;
my $host;
my $vdnetSource;
my $vmRepository;

unless
     (GetOptions (
         "vc|vc=s"            => \$vcAddr,
         "src|classdir=s"     => \$vdnetSource,
         "host|host=s"        => \$host,
         "vmrepos|vmrepos=s"  => \$vmRepository,
         )) {
        print "Invalid options\n";
        PrintUsage();
        exit -1;
     }

if ((not defined $vcAddr) || (not defined $vdnetSource) ||
   (not defined $host)) {
   PrintUsage();
   exit -1;
}

my $vdNetCommand = "$FindBin::Bin/../../main/vdnet " .
                   "--vc $vcAddr " .
                   "--hosts " . $host . "," . $host . " " .
                   "--vms \"sut=win-2003sp2-ent-32,helper=RHEL61_srv_64\" " .
                   "-t Sample.Sample.PreCheckin " .
                   "-src $vdnetSource " .
                   "--racetrack vdnet\@racetrack.eng.vmware.com";

if (defined $vmRepository) {
   $vdNetCommand = $vdNetCommand . " --vmrepos $vmRepository";
}

print "vdNet command:$vdNetCommand\n";
exit(system($vdNetCommand));


sub PrintUsage
{
   print "USAGE: --vc <vcIP> --hosts <hostIP>,<hostIP> -src " .
         "<vdnetSrcIP> --vmrepos <server:/share>\n";

}
