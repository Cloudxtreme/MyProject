#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use lib "/dbc/pa-dbc1102/gaggarwal/vdnet/main/VDNetLib/Spirent/";

use FindBin;
use lib "$FindBin::Bin/../../../";
use lib "$FindBin::Bin/../../../../";
use lib "$FindBin::Bin/../../../../../";
use VDNetLib::Workloads::TrafficWorkload::SpirentTool;

use VDNetLib::Common::GlobalConfig qw($vdLogger);

my $logLevel = undef;
my $logFileName = "spirent-traffic.log";
use constant DEFAULT_LOG_LEVEL => 7; #
$logLevel = (defined $logLevel) ? "$logLevel" : DEFAULT_LOG_LEVEL;
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logFileName' => $logFileName,
                                       'logToFile' => 1,
                                       'logLevel' => $logLevel);

if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::VDLog object";
   exit -1;
}



my $sessionID = undef;
$sessionID->{sessionlogs} = "/dbc/pa-dbc1102/gaggarwal/vdnet/main/scripts/unitTests/traffic/spirent/";

my $self = VDNetLib::Workloads::TrafficWorkload::SpirentTool->new();

print Dumper($self);

$self->{testOptions}{source}{controlip}      = "10.115.172.207";

$self->{testOptions}{source}{macaddress}      = "00:0c:29:a8:15:e4";
$self->{testOptions}{destination}{macaddress} = "ff:ff:ff:ff:ff:ff";

$self->{testOptions}{source}{testip}	  = "172.31.5.35";
$self->{testOptions}{destination}{testip} = "172.31.5.1";
$self->{testOptions}{stream}{type} = "ethernet";
# Default is ARP Request
$self->{testOptions}{stream}{payload} = "arp";
# For ARP Response
# $self->{testOptions}{stream}{payload}{arp}{operation} = 2;
 
$self->{testOptions}{noOfOutStreams}  = 1;
$self->{testOptions}{testDuration} = 120;

print "starting the traffic...\n\n";

my $result = $self->StartClient($sessionID);

print ("retrieving the results...\n");
$self->GetResult();

1;
