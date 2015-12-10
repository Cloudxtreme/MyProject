package TDS::NSX::Networking::VXLAN::VXLANSanityTds;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use TDS::NSX::Networking::VXLAN::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);

my $testworkload = {
   Sequence => [
      ['CreateVirtualWire1'],
      ['CreateVirtualWire2'],
      ['CreateVirtualWire3'],
      ['PlaceVMsOnVirtualWire1'],
      ['PlaceVMsOnVirtualWire2'],
      ['PlaceVMsOnVirtualWire3'],
      ['PoweronVM1','PoweronVM2'],
      ['PoweronVM3','PoweronVM4'],
      ['PoweronVM5','PoweronVM6'],
      ['NetperfTestVirtualWire1'],
      ['NetperfTestVirtualWire2'],
      ['NetperfTestVirtualWire3'],
   ],
   ExitSequence => [
      ['RebootHost'],
   ],
   "RebootHost" => REBOOT_CTRLR_HOST,
   'CreateVirtualWire1' => {
      Type  => "TransportZone",
      testtransportzone   => "vsm.[1].networkscope.[1]",
      VirtualWire  => {
         "[1]" => {
            name               => "AutoGenerate",
            tenantid           => "AutoGenerate",
            controlplanemode   => "MULTICAST_MODE",
         },
      },
   },
   'CreateVirtualWire2' => {
      Type  => "TransportZone",
      testtransportzone   => "vsm.[1].networkscope.[1]",
      VirtualWire  => {
         "[2]" => {
            name               => "AutoGenerate",
            tenantid           => "AutoGenerate",
            controlplanemode   => "UNICAST_MODE",
         },
      },
   },
   'CreateVirtualWire3' => {
      Type  => "TransportZone",
      testtransportzone   => "vsm.[1].networkscope.[1]",
      VirtualWire  => {
         "[3]" => {
            name               => "AutoGenerate",
            tenantid           => "AutoGenerate",
            controlplanemode   => "HYBRID_MODE",
         },
      },
   },
   'PlaceVMsOnVirtualWire1' => {
      Type => "VM",
      TestVM => "vm.[1],vm.[4]",
      vnic => {
         '[1]'   => {
            driver     => "e1000",
            portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
            connected => 1,
            startconnected => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'PlaceVMsOnVirtualWire2' => {
      Type => "VM",
      TestVM => "vm.[2],vm.[5]",
      vnic => {
         '[1]'   => {
            driver     => "e1000",
            portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
            connected => 1,
            startconnected => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'PlaceVMsOnVirtualWire3' => {
      Type => "VM",
      TestVM => "vm.[3],vm.[6]",
      vnic => {
         '[1]'   => {
            driver     => "e1000",
            portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
            connected => 1,
            startconnected => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'PoweronVM1' => {
       Type => "VM",
       TestVM => "vm.[1]",
       vmstate  => "poweron",
    },
    'PoweronVM2' => {
       Type => "VM",
       TestVM => "vm.[2]",
       vmstate  => "poweron",
    },
    'PoweronVM3' => {
       Type => "VM",
       TestVM => "vm.[3]",
       vmstate  => "poweron",
    },
    'PoweronVM4' => {
       Type => "VM",
       TestVM => "vm.[4]",
       vmstate  => "poweron",
    },
    'PoweronVM5' => {
       Type => "VM",
       TestVM => "vm.[5]",
       vmstate  => "poweron",
    },
    'PoweronVM6' => {
       Type => "VM",
       TestVM => "vm.[6]",
       vmstate  => "poweron",
    },
   "NetperfTestVirtualWire1" => {
      Type           => "Traffic",
      toolName       => "netperf",
      L4Protocol     => "tcp,udp",
      TestAdapter    => "vm.[1].vnic.[1]",
      SupportAdapter => "vm.[4].vnic.[1]",
      TestDuration   => "60",
   },
   "NetperfTestVirtualWire2" => {
      Type           => "Traffic",
      toolName       => "netperf",
      L4Protocol     => "tcp,udp",
      TestAdapter    => "vm.[2].vnic.[1]",
      SupportAdapter => "vm.[5].vnic.[1]",
      TestDuration   => "60",
   },
   "NetperfTestVirtualWire3" => {
      Type           => "Traffic",
      toolName       => "netperf",
      L4Protocol     => "tcp,udp",
      TestAdapter    => "vm.[3].vnic.[1]",
      SupportAdapter => "vm.[6].vnic.[1]",
      TestDuration   => "60",
   },
};

{
   %VXLANSanity = (
      'OneDatacenterTwoVDSThreeControlMode' => {
         TestName         => 'OneDatacenterTwoVDSThreeControlMode',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify that one datacenter,two vds ' .
                             'three control plane mode ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHosts_OneDataCenter_TwoVDS_ThreeControllers_sixVMs,
         'WORKLOADS'   => $testworkload,
      },
      'TwoDatacenterTwoVDSThreeControlMode' => {
         TestName         => 'TwoDatacenterTwoVDSThreeControlMode',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify that two datacenter,two vds ' .
                             'three control plane mode ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoHosts_TwoDataCenter_TwoCluster_TwoVDS_ThreeControllers_sixVMs,
         'WORKLOADS'   => $testworkload,
      },

  );
}

##########################################################################
# new --
#       This is the constructor for VXLAN sanity TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VXLANSanity class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   #
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   #
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VXLANSanity);
   return (bless($self, $class));
}

1;

