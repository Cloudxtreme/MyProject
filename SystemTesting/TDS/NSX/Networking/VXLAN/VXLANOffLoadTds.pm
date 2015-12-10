package TDS::NSX::Networking::VXLAN::VXLANOffLoadTds;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use TDS::NSX::Networking::VXLAN::TestbedSpec;
use TDS::NSX::Networking::VXLAN::CommonWorkloads ':AllConstants';
use TDS::NSX::Networking::VXLAN::TestbedSpec ':AllConstants';
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %VXLANOffLoad = (
      'HWCapabilities' => {
         TestName         => 'HWCapabilities',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload Capability is enabled',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['VerifyVmnic1SupportVxlanOffload'],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'VerifyVmnic1SupportVxlanOffload' => {
              'Type'           => 'NetAdapter',
              'TestAdapter'    => 'host.[1].vmnic.[1]',
              'capabilityType' => 'CAP_ENCAP',
              'verifyvmnichwcapability' => [
                 {
                    'value[?]equal_to' => '1',
                 },
              ],
            },
         },
      },
      'TSOenabledCKOenabledTCPIPV4' => {
         TestName         => 'TSOenabledCKOenabledTCPIPV4',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is working ' .
                             'when both TSO and CKO are enabled ' .
                             'and IPV4 TCP traffic is sent',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'NetperfTest1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '64512',
               'toolname' => 'netperf',
               'TestAdapter'    => "vm.[1].vnic.[1]",
               'SupportAdapter' => "vm.[2].vnic.[1]",
               'testduration' => '100',
               'bursttype' => 'stream',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv4',
               'sendmessagesize' => '14000',
            },
            'EnableTSOIPV4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'HasTSOCKOLogOnHost' => {
               Type => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [
                  {
                     'tso[?]match' => "Inner & Outer TSO enabled",
                     'length[?]>'  => "10000",
                  },
               ],
               noofretries  => "3",
               sleepbetweenworkloads => "80",
            },
         },
      },
      'TSOenabledCKOenabledUDPIPV4' => {
         TestName         => 'TSOenabledCKOenabledUDPIPV4',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is working ' .
                             'when both TSO and CKO are enabled ' .
                             'and IPV4 UDP traffic is sent',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'NetperfTest1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '64512',
               'toolname' => 'netperf',
               'TestAdapter'    => "vm.[1].vnic.[1]",
               'SupportAdapter' => "vm.[2].vnic.[1]",
               'testduration' => '100',
               'l4protocol' => 'udp',
               'l3protocol' => 'ipv4',
               'sendmessagesize' => '1400',
            },
            'EnableTSOIPV4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'HasTSOCKOLogOnHost' => {
               Type => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [
                  {
                     'tso[?]match' => "TSO not enabled",
                     'length[?]>'  => "1000",
                  },
               ],
               noofretries  => "3",
               sleepbetweenworkloads => "80",
            },
         },
      },
      'TSOenabledCKOenabledTCPIPV6' => {
         TestName         => 'TSOenabledCKOenabledTCPIPV6',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is working ' .
                             'when both TSO and CKO are enabled ' .
                             'and IPV6 TCP traffic is sent',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV6'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'NetperfTest1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '64512',
               'toolname' => 'netperf',
               'TestAdapter'    => "vm.[1].vnic.[1]",
               'SupportAdapter' => "vm.[2].vnic.[1]",
               'testduration' => '100',
               'bursttype' => 'stream',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'sendmessagesize' => '14000',
            },
            'EnableTSOIPV6' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'HasTSOCKOLogOnHost' => {
               Type => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [
                  {
                     'tso[?]match' => "Inner & Outer TSO enabled",
                     'length[?]>'  => "10000",
                  },
               ],
               noofretries  => "3",
               sleepbetweenworkloads => "80",
            },
         },
      },
      'TSOenabledCKOenabledTCPIPV4Reboot' => {
         TestName         => 'TSOenabledCKOenabledTCPIPV4Reboot',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is working ' .
                             'when both TSO and CKO are enabled ' .
                             'and IPV4 TCP traffic is sent' .
                             'After rebooting the host' .
                             'VXLAN_Offload is still working',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
               ['RebootHost1'],
               ['PoweronVM1'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'PoweronVM1' => POWERON_VM1,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'NetperfTest1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '64512',
               'toolname' => 'netperf',
               'TestAdapter'    => "vm.[1].vnic.[1]",
               'SupportAdapter' => "vm.[2].vnic.[1]",
               'testduration' => '100',
               'bursttype' => 'stream',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv4',
               'sendmessagesize' => '14000',
            },
            'EnableTSOIPV4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'HasTSOCKOLogOnHost' => {
               Type => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [
                  {
                     'tso[?]match' => "Inner & Outer TSO enabled",
                     'length[?]>'  => "10000",
                  },
               ],
               noofretries  => "3",
               sleepbetweenworkloads => "80",
            },
            'RebootHost1' => {
                Type           => "Host",
                TestHost       => "host.[1]",
                reboot         => "yes",
            },
         },
      },
      'TSOenabledCKOenabledTCPIPV4ICMP' => {
         TestName         => 'TSOenabledCKOenabledTCPIPV4ICMP',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is not working for' .
                             'ICMP traffic',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],

               ['PingTestVirtualWire1',
                'Check_TSOCKONotEnabled_OnHost'],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'EnableTSOIPV4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'PingTestVirtualWire1' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'TestAdapter'     => "vm.[1].vnic.[1]",
               'SupportAdapter'  => "vm.[2].vnic.[1]",
               'testduration'    => '100',
               'pingpktsize'     => '2000',
            },
            'Check_TSOCKONotEnabled_OnHost' => {
               Type     => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [{
                  'tso[?]match' => "TSO not enabled",
                  'cko[?]match' => "Checksum not offloaded",
                  'length[?]<'  => "2000",
               },],
               noofretries     => "3",
               sleepbetweenworkloads => "60",
            },
         },
      },
      'TSOTCPIPV4AddDeleteUplink' => {
         TestName         => 'TSOTCPIPV4AddDeleteUplink',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'Verify VXLAN_Offload is working ' .
                             'when add and remove the uplink ' .
                             'from the host',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_17,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM'],
               ['EnableTSOIPV4'],
               ['EnableIPCheckSum'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
               ['RemoveUplink'],
               ['AddUplink'],
               ['NetperfTest1',
                'HasTSOCKOLogOnHost',
               ],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteAllVirtualWires']
            ],

            'CreateVirtualWire' => {
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
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM' => POWERON_VM,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'NetperfTest1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '64512',
               'toolname' => 'netperf',
               'TestAdapter'    => "vm.[1].vnic.[1]",
               'SupportAdapter' => "vm.[2].vnic.[1]",
               'testduration' => '100',
               'bursttype' => 'stream',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv4',
               'sendmessagesize' => '14000',
            },
            'EnableTSOIPV4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
            },
            'EnableIPCheckSum' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tcptxchecksumipv4',
                  'enable'       => 'true',
               },
            },
            'HasTSOCKOLogOnHost' => {
               Type => "Host",
               testhost => "host.[1]",
               switch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               "verifytsockoonhost" => [
                  {
                     'tso[?]match' => "Inner & Outer TSO enabled",
                     'length[?]>'  => "10000",
                  },
               ],
               noofretries  => "3",
               sleepbetweenworkloads => "80",
            },
            'RemoveUplink' => {
	       'Type'            => 'Switch',
	       'TestSwitch'      => 'vc.[1].vds.[1]',
	       'configureuplinks'=> 'remove',
	       'vmnicadapter'    => 'host.[1].vmnic.[1]'
	    },
            'AddUplink' => {
	       'Type'             => 'Switch',
	       'TestSwitch'       => 'vc.[1].vds.[1]',
	       'configureuplinks' => 'add',
	       'vmnicadapter'     => 'host.[1].vmnic.[1]'
	    },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for VXLANOffLoad TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VXLANOffLoad class
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
   my $self = $class->SUPER::new(\%VXLANOffLoad);
   return (bless($self, $class));
}

1;
