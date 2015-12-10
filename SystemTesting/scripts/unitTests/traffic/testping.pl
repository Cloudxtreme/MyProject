
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../";
use lib "$FindBin::Bin/../../../VDNetLib/";


use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Workloads::TrafficWorkload;


my $logLevel = undef;
my $logFileName = "ping-traffic.log";
use constant DEFAULT_LOG_LEVEL => 7; #
$logLevel = (defined $logLevel) ? "$logLevel" : DEFAULT_LOG_LEVEL;
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logFileName' => $logFileName,
                                       'logToFile' => 1,
                                       'logLevel' => $logLevel);

if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::VDLog object";
   exit -1;
}

my $options;
$options->{logObj} = $vdLogger;

# edit all the following options appropriately
#$options->{vmx} = "[datastore1] vdtest1/helper1/RHEL6-e1000e.vmx";
#$options->{absvmx} = "/vmfs/volumes/vdtest1/helper1/RHEL6-e1000e.vmx";
#$options->{host} = "prme-kamal.eng.vmware.com";


##############################################################################
# Config section - BEGIN
##############################################################################

# Mandotory

my $machine1 = "SUT";
my $machine2 = "helper1";
my $machine3 = "helper2";
$options->{$machine1}->{'os'} = "linux";
$options->{$machine1}->{'arch'} = "x86_32";
$options->{$machine1}->{'testip'} = "192.168.119.197";
$options->{$machine1}->{'controlip'} = "10.20.119.197";
$options->{$machine2}->{'os'} = "linux";
$options->{$machine2}->{'arch'} = "x86_32";
$options->{$machine2}->{'testip'} = "192.168.116.176";
$options->{$machine2}->{'controlip'} = "10.20.116.176";

# Optional
$options->{$machine1}->{'interface'} = "eth0";
$options->{$machine1}->{'mtu'} = "1500";
$options->{$machine1}->{'host'} = "10.20.116.232";
$options->{$machine2}->{'interface'} = "eth0";
$options->{$machine2}->{'mtu'} = "1500";
# Both VMs are on same host
$options->{$machine2}->{'host'} = $options->{$machine1}->{'host'};

# Both VMs are on different host
$options->{$machine2}->{'host'} = "10.20.x.x";



# All keys are optional except Type
my $trafficWorkload = {
          'WORKLOADS' => {
              'TRAFFIC' => {
                    Type           => "Traffic",
                   'ToolName' => "ping", #netperf, iperf ....
#                    ExpectedResult  => "FAIL",
#                    MinExpResult  => "5600",
#                    MaxThroughput  => "2000",
#                    iterations => "2",
                    TestDuration   => 3,
                    TestAdapter    => "SUT:vnic:1",
                    SupportAdapter => "helper1:vnic:1",
#                    RoutingScheme => "multicast",
#                   'L3Protocol' => "IPv6",  # ICMP,ICMPv6
#                   'L4Protocol' => "udp",  #TCP, UDP
                    NoOfInbound => "2", # Number of RX sessions to run in parallel
                                           # Inbound tests the RX path of SUT
                                           # SUT is running server(remote machine)
                                           # Helper machine is running client(local machine)
                   'NoOfOutbound' => "2", #number of outbound sessions
#                   'BurstType' => "stream,rr",
#                   'LocalSendSocketSize' => "4000",   #Send socket buffer size
#                   'LocalReceiveSocketSize' => "5000",   #Send socket buffer size
#                   'RemoteSendSocketSize' => "6000",   #Send socket buffer size
#                   'RemoteReceiveSocketSize' => "7000",   #Send socket buffer size
#                   'SendMessageSize' => "1024,2000",/ # In case of stream
#                   'ReceiveMessageSize' => "2000", # In case of stream
#                   'RequestSize' => "8010", # In case of RR
#                   'ResponseSize' => "13", # In case of RR
#                   'RoutingScheme' => "broadcast",#unicast,broadcast,anycast",
#                   'MulticastTimeToLive'   => '32',  # Useful when switch is present
#                   'UDPBandwidth' => "500000000", # MAX value when server on windows
#                   'PktFragmentation' => 'no',    # do not fragment of ping
#                   'PingPktSize' => "50",
#                   'dataintegritycheck' => 'disable',
#                   'tcpmss' => "20",
#                   'tcpwindowsize' => "40",
#                   'clientthread' => "3",
#                   'AlterBufferAlignment' => "16", # to alter alignment of buffer used
                                                    # in tx and rx calls on local mahcine
#                   'PortNumber' => '42865',   # Port number on which server should listen.
#                   'BufferRings' => '',   # Number of buffers in send/receive buffer rings.
#                    natedport => "49001",
#                   'connectivitytest' => "0",
#                   'Verification'   => 'pktcap',
#                   'VerificationAdapter' => "helper2:vnic:1",
#                   'PktCapFilter' => "vlan 302",
#                   'SleepBetweenCombos' => "3",
#                   'SleepBetweenOperations' => "30",
                            }
                         },
        };

my $VAR1;
$VAR1 = bless( {
           'testbed' => {
                 $machine1 => {
                         'ip' => $options->{$machine1}->{'controlip'},
                         'arch' => $options->{$machine1}->{'arch'},
                         'testip' =>  $options->{$machine1}->{'testip'},
                         'os' =>  $options->{$machine1}->{'os'},
                         'interface' => $options->{$machine1}->{'interface'},
                         'mtu' => $options->{$machine1}->{'mtu'},
                         'host' => $options->{$machine1}->{'host'},
                         'Adapters' => {
                                    1      => {
                                    },
                                    vmknic => {
                                           1 =>  {
                                           },
                                    },
                          },
                 },
                 $machine2 => {
                         'ip' => $options->{$machine2}->{'controlip'},
                         'arch' => $options->{$machine2}->{'arch'},
                         'testip' =>  $options->{$machine2}->{'testip'},
                         'os' =>  $options->{$machine2}->{'os'},
                         'interface' => $options->{$machine2}->{'interface'},
                         'mtu' => $options->{$machine2}->{'mtu'},
                         'host' => $options->{$machine2}->{'host'},
                         'Adapters' => {
                              1      => {
                              },
                              vmknic => {
                                     1 =>  {
                                     },
                              },
                          },
                 },
                 $machine3 => {
                         'ip' => $options->{$machine3}->{'controlip'},
                         'arch' => $options->{$machine3}->{'arch'},
                         'testip' =>  $options->{$machine3}->{'testip'},
                         'os' =>  $options->{$machine3}->{'os'},
                         'interface' => $options->{$machine3}->{'interface'},
                         'mtu' => $options->{$machine3}->{'mtu'},
                         'host' => $options->{$machine3}->{'host'},
                         'Adapters' => {
                              1      => {
                              },
                              vmknic => {
                                     1 =>  {
                                     },
                              },
                          },
                 },

           },
        }, 'Testbed' );


##############################################################################
# Config section - END
##############################################################################

# Making all keys and values in traffic lowercase.
my $traffic = $trafficWorkload->{'WORKLOADS'}->{'TRAFFIC'};
%$traffic = (map { lc $_ => $traffic->{$_}} keys %$traffic);

my $mytestscriptobj = VDNetLib::Workloads::TrafficWorkload->new(
                                             testbed => $VAR1,
                                             workload => $traffic
                                                    );
my $result = $mytestscriptobj->StartWorkload();
if (not defined $result || $result =~ /fail/i) {
  $vdLogger->Error("StartWorkload returned $result ");
   VDSetLastError(VDGetLastError());
   return 0;
} else {
  $vdLogger->Info("StartWorkload returned $result ");
}

exit 0;
