use strict;
use warnings;
use Data::Dumper;
use FindBin;
use Cwd;
use Sys::Hostname;

use PLSTAF;

use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/";
use lib "$FindBin::Bin/../../TDS/";
use lib "$FindBin::Bin/../../VDNetLib/VIX/";
use VDNetLib::VM::VMOperations;
use VDNetLib::Host::HostOperations;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 7,
                                               'logToFile'   => 1,
                                               'logFileName' => "vdnet.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}
my $options;
$options->{logObj} = $vdLogger;

# edit all the following options appropriately
$options->{vmx} = "[datastore1] vdtest3/SUT/win-2003sp2-ent-32.vmx";
$options->{absvmx} = "/vmfs/volumes/datastore1/vdtest3/SUT/win-2003sp2-ent-32.vmx";
$options->{host} = "prme-mgr.eng.vmware.com";
$options->{hostType} = "vmkernel";
$options->{'waitstate'} = "poweredon";
$options->{'snapshotname'} = "vdtest";
$options->{'portgroupname'} = "vdtest";
$options->{'macaddress'} = "00:0c:29:45:29:1c";
$options->{'devicename'} = "vmxnet3";
$options->{'vmknic'} = "vmk1-pg-8631";

my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
if (not defined $stafHelper) {
     $vdLogger->Error("STAF is not running");
     exit -1;
}

our $vmOpsObj = VDNetLib::VM::VMOperations->new($options);

if ($vmOpsObj eq FAILURE) {
   $vdLogger->Error(VDGetLastError());
   exit -1;
}

our $hostOpsObj = VDNetLib::Host::HostOperations->new($options->{host}, $stafHelper);

if ($hostOpsObj eq FAILURE) {
   $vdLogger->Error(VDGetLastError());
   exit -1;
}

my @operations = ('register','getguestinfo','getpowerstate', 'poweron',
                   'suspend','resume', 'poweroff', 'rmsnap', 'createsnap',
                   'revertsnap','poweron', 'getpgname','changeportgroup',
                   'disconnectvnic', 'connectvnic', 'hotaddvnic',
                   'hotremovevnic', 'standby', 'killvm', 'listvmknics',
                   'addvmknic');
foreach my $operation (@operations) {
   if (ExecuteOps($operation, $options) eq "FAILURE") {
      exit -1;
   }
}

sub ExecuteOps
{
   my $operation = shift;
   my $options = shift;

   my $vmx = $vmOpsObj->{vmx};
   $vdLogger->Info("Executing operation: $operation");
   my %operationNames = (
      'register'           => {
         'obj'       => $vmOpsObj,
         'method'    => 'VMOpsRegisterVM',
         'param'     => "",
      },
      'unregister'           => {
         'obj'       => $vmOpsObj,
         'method'    => 'VMOpsUnRegisterVM',
         'param'     => "",
      },
      'getpowerstate'           => {
         'obj'       => $vmOpsObj,
         'method'    => 'VMOpsGetPowerState',
         'param'     => "",
      },
      'register'           => {
         'obj'       => $vmOpsObj,
         'method'    => 'VMOpsRegisterVM',
         'param'     => "",
      },
      'poweron'            => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsPowerOn',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'poweroff'           => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsPowerOff',
         'param'           => '',
         # vsi node will be lost no passthru verification needed
      },
      'suspend'            => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsSuspend',
         'param'           => '',
         'upt'             => {
            # vsi node will be lost
            'transition'   => 'VM_OP',
         },
      },
      'resume'             => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsResume',
         'param'           => '',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
         'obj'       => $vmOpsObj,
      'waitforstate'       => {
         'method'          => 'WaitForVMState',
         'param'           => $options->{'waitstate'},
      },
      'getguestinfo'       => {
         'obj'       => $vmOpsObj,
         'method'          => 'GetGuestInfo',
         'param'     => "",
      },
      'createsnap'         => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsTakeSnapshot',
         'param'           => $options->{'snapshotname'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => 'VM_OP',
         },
      },
      'revertsnap'         => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsRevertSnapshot',
         'param'           => $options->{'snapshotname'},
         'upt'             => {
            # vsi node will be lost
            'transition'   => undef,
         },
      },
      'rmsnap'             => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsDeleteSnapshot',
         'param'           => $options->{'snapshotname'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'getadaptersinfo'    => {
         'obj'       => $vmOpsObj,
         'method'          => 'GetAdaptersInfo',
         'param'           => "",
      },
      'connectvnic'        => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsConnectvNICCable',
         'param'           => $options->{'macaddress'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'disconnectvnic'     => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsDisconnectvNICCable',
         'param'           => $options->{'macaddress'},
         'upt'             => {
            # vsi node is lost
            'transition'   => undef,
         },
      },
      'reset'              => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsReset',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'shutdown'           => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsShutdown',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'hibernate'          => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsHibernate',
         'upt'             => {
            'status'       => 'VNIC_FEATURES',
            'transition'   => undef,
         },
      },
      'standby'            => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsStandby',
         'upt'             => {
            'status'       => 'VNIC_FEATURES',
            'transition'   => undef,
         },
      },
      'killvm'             => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsKill',
         'upt'             => {
            'status'       => '',
            'transition'   => undef,
         },
      },
      'hotaddvnic'         => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsHotAddvNIC',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'hotremovevnic'      => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsHotRemovevNIC',
         'param'           => $options->{'macaddress'},
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'changeportgroup'    => {
         'obj'       => $vmOpsObj,
         'method'          => 'VMOpsChangePortgroup',
         'upt'             => {
            'status'       => 'OK',
            'transition'   => undef,
         },
      },
      'getpgname'    => {
         'obj'     => $hostOpsObj,
         'method'  => 'GetPGNameFromMAC',
      },
      'listvmknics'    => {
         'obj'     => $hostOpsObj,
         'method'  => 'ListVmknics',
      },
      'addvmknic'    => {
         'obj'     => $hostOpsObj,
         'method'  => 'AddVmknic',
      },
   );


   #
   # Now, the keys in the given VMWorkload hash are processed one by
   # one.
   #
   # Find the VMOperation method name for each operation.
   #
   $operation = lc($operation);
   my $method = $operationNames{$operation}{'method'};
   if (not defined $method) {
      $vdLogger->Error("Method name not found for $operation operation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @value = ();
   if ($operationNames{$operation}{'param'}) {
      push(@value, $operationNames{$operation}{'param'});
   } elsif ($operation eq "changeportgroup") {
      push(@value, $options->{'macaddress'});
      push(@value, "VM Network");
   } elsif ($operation eq "hotaddvnic") {
      push(@value, $options->{'devicename'});
      push(@value, $options->{'portgroupname'});
   } elsif ($operation eq "getpgname") {
      push(@value, $options->{'absvmx'});
      push(@value, $options->{'macaddress'});
   } elsif ($operation eq "addvmknic") {
      my %hash = (
         pgName => $options->{'vmknic'},
         ip     => "dhcp",
      );
      push(@value, %hash);
   }

   my $result = $operationNames{$operation}{'obj'}->$method(@value);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to execute $operation on $vmx");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info(Dumper($result));
}
