use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../";
use lib "$FindBin::Bin/../../../VDNetLib/";
use lib "$FindBin::Bin/../../../VDNetLib/CPAN/5.8.8/";

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::VM::VMOperations;
use VDNetLib::Workloads::VMWorkload;
use VDNetLib::Host::HostOperations;
use VDNetLib::NetAdapter::NetAdapter;

my $logLevel = undef;
my $logFileName = "vm-Workload-Tests.log";
use constant DEFAULT_LOG_LEVEL => 7; #
$logLevel = (defined $logLevel) ? "$logLevel" : DEFAULT_LOG_LEVEL;
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logFileName' => $logFileName,
                                               'logToFile'   => 1,
                                               'logLevel'    => $logLevel);

if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::VDLog object";
   exit -1;
}

my $options;
$options->{logObj} = $vdLogger;


###############################################################################
#
# This is the workload we want to test.
#
my $vmWorkload = {
    'WORKLOADS' => {
        'VM_1' => {
            Type           => "VM",
            Target         => "SUT",  # All the operations will be done on SUT
            Iterations     => "1",
            Operation      => "suspend,resume",
         }
     },
};


##############################################################################
# Config section - BEGIN
##############################################################################

#
# Not all params are mandatory.
# Different params are required for different operations.
#

my $machine1 = "SUT";               # All the operations will be done on machine1 = SUT
my $machine2 = "helper1";

$options->{$machine1}->{'os'} = "linux";
$options->{$machine1}->{'arch'} = "x86_64";
$options->{$machine1}->{'testip'} = "192.168.116.179";
$options->{$machine1}->{'interface'} = "eth4";
$options->{$machine1}->{'mtu'} = "1500";
$options->{$machine1}->{'controlip'} = "10.20.116.179";
$options->{$machine1}->{'host'} = "10.20.116.232";
$options->{$machine1}->{'driver'} = "vmxnet3";
$options->{$machine1}->{'macAddress'} = "00:0C:29:34:36:2C";
$options->{$machine1}->{'intType'} = "vnic";
$options->{$machine1}->{'hostObj'} = VDNetLib::Host::HostOperations->new($options->{$machine1}->{'host'});
$options->{$machine1}->{'pgName'} = "vdtest";

$options->{$machine2}->{'os'} = "linux";
$options->{$machine2}->{'arch'} = "x86_64";
$options->{$machine2}->{'testip'} = "192.168.119.155";
$options->{$machine2}->{'interface'} = "eth4";
$options->{$machine2}->{'mtu'} = "1500";
$options->{$machine2}->{'controlip'} = "10.20.119.155";
$options->{$machine2}->{'driver'} = "vmxnet3";
$options->{$machine2}->{'macAddress'} = "00:0C:29:38:78:45";
$options->{$machine2}->{'intType'} = "vnic";

# Both VMs are on same host
$options->{$machine2}->{'host'} = $options->{$machine1}->{'host'};
$options->{$machine2}->{'hostObj'} = $options->{$machine1}->{'hostObj'};
$options->{$machine2}->{'pgName'} = "vdtest";

$options->{$machine2}->{'os'} = "linux";
$options->{$machine2}->{'arch'} = "x86_32";
$options->{$machine2}->{'testip'} = "192.168.116.24";
$options->{$machine2}->{'interface'} = "eth0";
$options->{$machine2}->{'mtu'} = "1500";
$options->{$machine2}->{'controlip'} = "10.20.116.24";
$options->{$machine2}->{'driver'} = "vmxnet3";
$options->{$machine2}->{'macAddress'} = "00:0C:29:95:22:B4";
$options->{$machine2}->{'intType'} = "vnic";

# Both VMs are on different host
#$options->{$machine2}->{'host'} = "10.20.x.x";

#
# edit all the following options appropriately
#
$options->{vmx} = "/vmfs/volumes/datastore1/vdtest-4880/SUT/rhel-53-srv-hw7-32-lsi-1gb-1cpu.vmx";
#$options->{vmx} = "/vmfs/volumes/datastore1/vdtest-18163/helper1/RHEL61_srv_64.vmx";
#$options->{vmx} = "[datastore1]vdtest-4880/SUT/rhel-53-srv-hw7-32-lsi-1gb-1cpu.vmx";
$options->{host} = $options->{$machine1}->{'host'};
$options->{ip} = $options->{$machine1}->{'controlip'};
$options->{hostType} = "vmkernel";



##############################################################################
# Config section - END
##############################################################################

#
# Creating an obj of VMOperations and placing the pointer in testbed.
#
our $vmOpsObj = VDNetLib::VM::VMOperations->new($options);
if ($vmOpsObj eq "FAILURE") {
   $vdLogger->Error("failed");
   exit -1;
}

#
# Simulating a testbed hash for our unit testing.
#

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
                         'hostObj' => $options->{$machine1}->{'hostObj'},
                         'vmOpsObj' => $vmOpsObj,
                         'Adapters' => {
                                    1      => VDNetLib::NetAdapter::NetAdapter->new(
                                       'controlIP' => $options->{$machine1}->{'controlip'},
                                       'driver' => $options->{$machine1}->{'driver'},
                                       'macAddress' => $options->{$machine1}->{'macAddress'},
                                       'interface' => $options->{$machine1}->{'interface'}
                                    ),
                                    vmknic => {
                                           1 =>  {
                                              'controlIP' => $options->{$machine1}->{'host'},
                                              'driver' => 'vmkernel'
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
                         'hostObj' => $options->{$machine2}->{'hostObj'},
                         'vmOpsObj' => $vmOpsObj,
                         'Adapters' => {
                                    1      => VDNetLib::NetAdapter::NetAdapter->new(
                                       'controlIP' => $options->{$machine2}->{'controlip'},
                                       'driver' => $options->{$machine2}->{'driver'},
                                       'macAddress' => $options->{$machine2}->{'macAddress'},
                                       'interface' => $options->{$machine2}->{'interface'}
                                     ),
                                    vmknic => {
                                           1 =>  {
                                              'controlIP' => $options->{$machine2}->{'host'},
                                              'driver' => 'vmkernel'
                                           },
                                    },
                          },
                 },
           },
        }, 'Testbed' );


#
# Creating obj and then calling method on the obj
#
my $mytestscriptobj = VDNetLib::Workloads::VMWorkload->new(
                                                testbed => $VAR1,
                                                workload => $vmWorkload->{'WORKLOADS'}->{'VM_1'},
                                                          );
my $result = $mytestscriptobj->StartWorkload();

if (not defined $result || $result =~ /fail/i) {
   $vdLogger->Error("StartWorkload returned $result ". Dumper($mytestscriptobj));
   VDSetLastError(VDGetLastError());
   return 0;
} else {
   $vdLogger->Info("StartWorkload returned $result ");
}

exit 0;
