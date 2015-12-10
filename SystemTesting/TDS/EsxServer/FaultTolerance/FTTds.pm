#!/usr/bin/perl
#########################################################################
#Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FaultTolerance::FTTds;

@ISA = qw(TDS::Main::VDNetMainTds);

# This file contains the structured hash for category, FPT tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

#
# Begin test cases
#
{
   %FT = (
      'FtvmTsoCsoMtu' => {
         TestName         => "FtvmTsoCsoMtu",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Verify supported features (Change in MTU, Change in ring, tso, cso)
                              by enabling and disabling test in SMP FT enabled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Change MTU of the switch, SUTVM, Helper VM to 9000 '.
           '5. Enable TSO adn CSO in the SUTVM '.
           '6. Inject Fault Tolerance by killing the Primary VM '.
           '7. Start the traffic from Helper VM to SUT VM '.
           '8. Check if the VM is protected again and Traffic dint fail '.
           '9. Inject FaultTOlerance again to bring the SUTVM back to Host1 ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P0',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
               Sequence   => [
                               ['ClusterAdvancedoptions'],
                               ['PowerOff'],
                               ['PowerOffVM2'],
                               ['EnableFT'],
                               ['PowerOn'],
                               ['PowerOnVM2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                               ['SwitchMTU9000'],
                               ['SutvmMTU9000'],
                               ['HelpervmMTU9000'],
                               ['EnableTSO'],
                               ['EnableCSOTx',
                                'EnableCSORx'],
                               ['Traffic1'],
                               ['InjectFautTolerance_1'],
                               ['CheckFaultToleranceState_primaryhost'],
                               ['InjectFautTolerance_2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                            ],
              ExitSequence  => [
                                 ['PowerOff'],
                                 ['PowerOffVM2'],
                                 ['DisableFT'],
                               ],
            'ClusterAdvancedoptions' => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
               EditCluster => "edit",
               ha   => 1,
               advancedoptions => {
                                    'ignoreInsufficientHbDatastore'  => 'true',
                                  },
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => "enable",
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron",
            },
            'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron",
            },
            'CheckFaultToleranceState_secondaryhost' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'SwitchMTU9000' => {
                Type       => 'Switch',
                TestSwitch => 'vc.[1].vds.[1]',
                mtu        => '9000'
            },
            'SutvmMTU9000' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               MTU            => "9000",
            },
            'HelpervmMTU9000' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               MTU            => "9000",
            },
            'EnableTSO' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               configure_offload =>{
                  offload_type => 'tsoipv4',
                  enable        => 'true',
               },
            },
            'EnableCSORx' => {
               Type              => 'NetAdapter',
               TestAdapter       => 'vm.[1].vnic.[1]',
               configure_offload' =>{
                  offload_type' => 'tcprxchecksumipv4',
                  enable'       => 'true',
               },
               sleepbetweenworkloads' => '60',
            },
            'EnableCSOTx' => {
               Type              => 'NetAdapter',
               TestAdapter       => 'vm.[1].vnic.[1]',
               configure_offload' =>{
                  offload_type' => 'tcptxchecksumipv4',
                  enable'       => 'true',
               },
            },
            'Traffic1' => {
               Type           => 'Traffic',
               noofoutbound   => '1',
               testduration   => '30',
               toolname       => 'netperf',
               noofinbound    => '1',
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'CheckFaultToleranceState_primaryhost' => {
               Type      => "Host",
               TestHost  => "host.[1]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[1]",
                                          },
            },
            'InjectFautTolerance_2' => {
               Type           => "Host",
               TestHost       => "host.[2]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
         },
      },

      'FtvmDisconnectVnic' => {
         TestName         => "FtvmDisconnectVnic",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Hot Remove VNic from FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Hot Remov vnic form the SMTFTVM, this action should fail'.
           '5. Check if the VM is protected again and Traffic dint fail '.
           '6. Inject FaultTolerance again to bring the SUTVM back to Host1 ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState'],
                           ['RemovevNICFromVM1'],
                           ['Traffic1'],
                          ],
            ExitSequence  => [
                               ['PowerOffVM2'],
                               ['PowerOff'],
                               ['DisableFT'],
                             ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'RemovevNICFromVM1' => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               deletevnic     => 'vm.[1].vnic.[1]',
               ExpectedResult => "Fail",
            },
            'Traffic1' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
         },
      },

      'FtvmDiskSnapshot' => {
         TestName         => "FtvmDiskSnapshot",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Disk only Snapshot of the FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Take Disk only snapshot of the Fault Tolerance VM, this action should fail ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P1',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState'],
                           ['DiskSnapshot'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'DiskSnapshot'  => {
                Type => 'VM',
                TestVM => 'vm.[1]',
                snapshotname => 'FTSnapshotNeg',
                operation => 'createsnap',
                ExpectedResult => 'Fail',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmStartConnect' => {
         TestName         => "FtvmStartConnect",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Disable Start Connected FautTolerance enbaled VM",
         Procedure        =>
           '1. Add a Vnic to the SUTVM and enable Start Connected option'.
           '2. Enable Fault Tolerance for the VM '.
           '3. Power ON the VM '.
           '4. Check if Fault Tolerance is enabled '.
           '5. Do a ping test from the HelperVM to SUTVM'.
           '6. Power OFF the VM and Disable FT '.
           '7. Remove vnic from the VM ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,
         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['AddvNICOnVM_1'],
                           ['MakeSurevNICConnected'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState'],
                           ['PingTest'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['DisableFT'],
                           ['RemoveVnicFromVM_1'],
                          ],
            'AddvNICOnVM_1' => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               vnic => {
                  '[2]'   => {
                     driver      => "vmxnet3",
                     portgroup   => "vc.[1].dvportgroup.[3]",
                     connected   => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'MakeSurevNICConnected' => {
                Type           => "NetAdapter",
                reconfigure    => "true",
                testadapter    => "vm.[1].vnic.[2]",
                connected      => 1,
                startconnected => 1,
            },
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'PingTest' => {
                Type           => "Traffic",
                maxtimeout     => "30",
                ToolName       => "Ping",
                TestAdapter    => "vm.[1].vnic.[1]",
                SupportAdapter => "vm.[2].vnic.[1]",
                NoofOutbound   => 1,
                NoofInbound    => 1,
                TestDuration   => "60",
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 0,
            },
            'RemoveVnicFromVM_1' => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               deletevnic => "vm.[1].vnic.[2]"
            },
          },
       },
      'FtvmAutoIntx' => {
         TestName         => "FtvmAutoIntx",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Interrupt Modes for FautTolerance enbaled VM",
         Procedure        =>
           '1. Add a Vnic to the SUTVM and disable Start Connected option '.
           '2. Enable Fault Tolerance for the VM '.
           '3. Power ON the VM '.
           '4. Check if Fault Tolerance is enabled '.
           '5. Enable the 4 different interrupt modes  '.
           '6. Start the traffic from Helper VM to the SUT VM '.
           '7. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P1',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,
         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState'],
                           ['IntrModes_1'],
                           ['Traffic1'],
                           ['IntrModes_2'],
                           ['Traffic2'],
                           ['IntrModes_3'],
                           ['Traffic3'],
                           ['IntrModes_4'],
                           ['Traffic4'],
                           ['IntrModes_5'],
                           ['Traffic5'],
                           ['IntrModes_6'],
                           ['Traffic6'],
                           ['SetDefault'],
                           ['Traffic7'],
                          ],
             ExitSequence  => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'IntrModes_1' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'AUTO-INTX'
             },
             'Traffic1' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'IntrModes_2' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'AUTO-MSI'
            },
            'Traffic2' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'IntrModes_3' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'AUTO-MSIX'
            },
            'Traffic3' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'IntrModes_4' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'ACTIVE-INTX'
            },
            'Traffic4' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'IntrModes_5' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'ACTIVE-MSI'
            },
            'Traffic5' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'IntrModes_6' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'ACTIVE-MSIX'
            },
            'Traffic6' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'SetDefault' => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               intrmode => 'AUTO-MSIX'
            },
            'Traffic7' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 0,
            },
          }
       },

      'FtvmRemoveMod' => {
         TestName         => "FtvmRemoveMod",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Removing driver Module for FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Remove e1000 driver module from the VM '.
           '5. Do ping test from Helper VM from SUT VM which should fail '.
           '6. Load the e1000 module back to VM1 '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,
         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState'],
                           ['RemoveModuleE1000VM1'],
                           ['PingTest'],
                           ['LoadModuleE1000VM1'],
                           ['PingTest_1'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
               Type => "VM",
               TestVM => "vm.[1]",
               secondaryhost => "host.[2]",
               faulttolerance => 'enable',
            },
            'PowerOn'  => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweron"
            },
            'PowerOnVM2'  => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'RemoveModuleE1000VM1' => {
               Type           => "Command",
               TestVM         => "vm.[1]",
               Command        => "rmmod e1000",
            },
            'PingTest' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
               ExpectedResult => "Fail",
            },
            'LoadModuleE1000VM1'  => {
               Type           => "Command",
               TestVM         => "vm.[1]",
               Command        => "modprobe vmxnet3",
            },
            'PingTest_1' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          }
       },

      'FtvmWol' => {
         TestName         => "FtvmWol",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Wake up on Lan Magic Packet for FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Enable WOL magic packet and suspend the VM '.
           '5. Inject FaultTolerance and send the WOl packet from the Helper VM '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P3',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P3',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,
         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['WOL'],
                           ['Ping','Standby','Wake','InjectFaultTolerance'],
                           ['CheckFaultToleranceState_secondaryhost'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
               Type => "VM",
               TestVM => "vm.[1]",
               secondaryhost => "host.[2]",
               faulttolerance => 'enable',
            },
            'PowerOn'  => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweron"
            },
            'PowerOnVM2'  => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweron"
            },
            'CheckFaultToleranceState_primaryhost' => {
               Type      => "Host",
               TestHost  => "host.[1]",
               faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                          },
            },
            'Ping' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'routingscheme' => 'flood',
               'noofinbound' => '8'
            },
            'WOL' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'wol' => 'MAGIC',
               'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'Standby' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'iterations' => '1',
               'operation' => 'standby'
           },
           'Wake' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'wakeupguest' => 'MAGIC',
               'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'SuspendResume' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1]',
               'iterations' => '1',
               'vmstate' => 'suspend,poweron'
           },
           'InjectFautTolerance_1' => {
                Type           => "Host",
                TestHost       => "host.[1]",
                faulttoleranceoperation   => {
                                                faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                                faulttolerancevm => "vm.[1]",
                                             },
            },
            'CheckFaultToleranceState_secondaryhost' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                          },
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 0,
            },
         },
      },

      'FtvmTso1500' => {
         TestName         => "FtvmTso1500",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Getting packet size greater than 1500 in the SUTVM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Enable Tso'.
           '5. Inject FaultTolerance and send traffic from the HelperVM to the SUTVM with different packet size '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P0',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
               Sequence   => [
                               ['PowerOff'],
                               ['PowerOffVM2'],
                               ['EnableFT'],
                               ['PowerOn'],
                               ['PowerOnVM2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                               ['EnableTSO'],
                               ['Traffic1','InjectFautTolerance_1'],
                               ['CheckFaultToleranceState_primaryhost'],
                               ['InjectFautTolerance_2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                             ],
               ExitSequence  => [
                               ['PowerOff'],
                               ['PowerOffVM2'],
                               ['DisableFT'],
                            ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => "enable",
             },
             'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron",
             },
             'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron",
             },
             'CheckFaultToleranceState_secondaryhost' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
             },
             'EnableTSO' => {
                Type => 'NetAdapter',
                TestAdapter => 'vm.[1].vnic.[1]',
                configure_offload =>{
                  offload_type => 'tsoipv4',
                  enable        => 'true',
                },
             },
             'Traffic1' => {
                Type           => 'Traffic',
                noofoutbound   => '1',
                testduration   => '30',
                toolname       => 'netperf',
                noofinbound    => '1',
                testadapter    => 'vm.[1].vnic.[1]',
                supportadapter => 'vm.[2].vnic.[1]',
             },
             'InjectFautTolerance_1' => {
                Type           => "Host",
                TestHost       => "host.[1]",
                faulttoleranceoperation   => {
                                                faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                                faulttolerancevm => "vm.[1]",
                                             },
             },
             'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
             },
             'InjectFautTolerance_2' => {
                Type           => "Host",
                TestHost       => "host.[2]",
                faulttoleranceoperation   => {
                                                faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                                faulttolerancevm => "vm.[1]",
                                             },
             },
             'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
             },
             'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
             },
             'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
             },
          },
       },

      'FtvmTso1500To9000' => {
         TestName         => "FtvmTso1500To9000",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Getting packet size from 1500 to 9000 in the SUTVM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. CHange MTU in switch, SUTVM, HelperVM to 9000 and Enable Tso '.
           '5. Inject FaultTolerance and send traffic from the HelperVM to the SUTVM with different packet size '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P1',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
               Sequence   => [
                               ['PowerOff'],
                               ['PowerOffVM2'],
                               ['EnableFT'],
                               ['PowerOn'],
                               ['PowerOnVM2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                               ['SwitchMTU9000'],
                               ['SutvmMTU9000'],
                               ['HelpervmMTU9000'],
                               ['EnableTSO'],
                               ['Traffic1','InjectFautTolerance_1'],
                               ['CheckFaultToleranceState_primaryhost'],
                               ['InjectFautTolerance_2'],
                               ['CheckFaultToleranceState_secondaryhost'],
                             ],
               ExitSequence  => [
                               ['PowerOff'],
                               ['PowerOffVM2'],
                               ['DisableFT'],
                            ],

            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => "enable",
             },
             'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron",
             },
             'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron",
             },
             'CheckFaultToleranceState_secondaryhost' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
             },
             'SwitchMTU9000' => {
                Type       => 'Switch',
                TestSwitch => 'vc.[1].vds.[1]',
                mtu        => '9000'
             },
             'SutvmMTU9000' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               MTU            => "9000",
             },
             'HelpervmMTU9000' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               MTU            => "9000",
             },
             'EnableTSO' => {
                Type => 'NetAdapter',
                TestAdapter => 'vm.[1].vnic.[1]',
                configure_offload =>{
                  offload_type => 'tsoipv4',
                  enable        => 'true',
                },
             },
             'Traffic1' => {
                Type           => 'Traffic',
                noofoutbound   => '1',
                testduration   => '30',
                toolname       => 'netperf',
                noofinbound    => '1',
                testadapter    => 'vm.[1].vnic.[1]',
                supportadapter => 'vm.[2].vnic.[1]',
             },
             'InjectFautTolerance_1' => {
                Type           => "Host",
                TestHost       => "host.[1]",
                faulttoleranceoperation   => {
                                                faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                                faulttolerancevm => "vm.[1]",
                                             },
             },
             'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
             },
             'InjectFautTolerance_2' => {
                Type           => "Host",
                TestHost       => "host.[2]",
                faulttoleranceoperation   => {
                                                faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                                faulttolerancevm => "vm.[1]",
                                             },
             },
             'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
             },
             'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
             },
             'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
             },
          },
       },

      'FtvmHotAddVnic' => {
         TestName         => "FtvmHotAddVnic",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Hot add Vnic to the Fault Tolerance VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Hot add Vnic to the Fault Tolerance VM which should fail '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState'],
                           ['HotAddVnicVM1'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'HotAddVnicVM1' => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               'vnic' => {
                   '[2]' => {
                         portgroup => 'vc.[1].dvportgroup.[3]',
                         driver     => "vmxnet3",
                   },
               },
               ExpectedResult => "Fail",
            },
            'Traffic1' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmInvalidMTU' => {
         TestName         => "FtvmInvalidMTU",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Disable Start Connected FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Set an invalid MTU value to the SUT VM, the VM should not crash '.
           '5. Do a ping test from HelperVM to SUTVM '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P1',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState'],
                           ['InvalidMTU'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            InvalidMTU => {
               Type => 'NetAdapter',
               TestAdapter => 'vm.[1].vnic.[1]',
               ExpectedResult => 'FAIL',
               MTU => '9001'
            },
            'Traffic1' => {
               Type           => 'Traffic',
               toolname       => 'ping',
               Routingscheme  => "broadcast",
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
               testduration   => '20'
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
         },
      },

      'FtvmVmotion' => {
         TestName         => "FtvmVmotion",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "VMotion for the FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Do vmotion for the SUT VM from Host 1 to Host 2 '.
           '6. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'vmotion,P1',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['Host1ToHost4Vmotion'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'CheckFaultToleranceState_secondaryhost' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'Host1ToHost4Vmotion' => {
                Type     => 'VM',
                TestVM   => 'vm.[1]',
                priority => 'high',
                vmotion  => 'twoway',
                dsthost  => 'host.[4]',
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmResetVM' => {
         TestName         => "FtvmResetVM",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Reset FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Reset Fault Tolerance VM '.
           '5. Inject FaultTolerance '.
           '6. Check if the Failover has taken place properly '.
           '7. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',

         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "FtvmResetVM",
         Version          => "2" ,
         Summary          => "This is the precheck-in test case ".
                             "for the advancedoptions in a HA cluster",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['ResetVM', 'InjectFautTolerance_1'],
                           ['CheckFaultToleranceState_primaryhost'],
                          ],
            ExitSequence  => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'ResetVM' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "reset",
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'CheckFaultToleranceState_secondaryhost' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmHibernateResumeVM' => {
         TestName         => "FtvmHibernateResumeVM",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Hibernate and Resume FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Hibernate the SUT VM '.
           '5. Inject FaultTolerance and Resume the VM from inside ',
           '6. Check if VM has successfully transitioned and is able to Resume ',
           '7. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['HibernateVM'],
                           ['ResumeVM'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['InjectFautTolerance_1'],
                           ['CheckFaultToleranceState_primaryhost'],
                          ],
            ExitSequence => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'HibernateVM' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "hibernate",
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'CheckFaultToleranceState_secondaryhost' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[1]",
                                          },
            },
            'ResumeVM' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmSuspendResumeVM' => {
         TestName         => "FtvmSuspendResumeVM",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Suspend Resume FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Suspend the SUT VM '.
           '5. Inject FaultTolerance and resume the VM '.
           '6. Check if the VM has transitioned properly and Resumed '.
           '7. Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'manual,P2',
         AutomationStatus => 'manual',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['SuspendVM'],
                           ['ResumeVM'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['InjectFautTolerance_1'],
                           ['CheckFaultToleranceState_primaryhost'],
                          ],
             ExitSequence => [
                           ['PowerOff'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron",
            },
            'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'SuspendVM' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "suspend",
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'CheckFaultToleranceState_secondaryhost' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[1]",
                                          },
            },
            'ResumeVM' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmRSSVM' => {
         TestName         => "FtvmRSSVM",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "RSS for FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM '.
           '2. Power ON the VM '.
           '3. Check if Fault Tolerance is enabled '.
           '4. Enable RSS and Multiple queues on the Fault Tolerance VM '.
           '5. Inject FaultTolerance and resume the VM '.
           '6. Check if the VM has transitioned properly and Resumed '.
           '7. Disable the Txqueue, RSS and Power OFF the VM and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'vmxnet3,P1',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['EnableFT'],
                           ['PowerOn'],
                           ['PowerOnVM2'],
                           ['CheckFaultToleranceState_secondaryhost'],
                           ['EnableRSS'],
                           ['MultiQueueTxUDP'],
                           ['MultiQueueRxUDP'],
                           ['InjectFautTolerance_1'],
                           ['CheckFaultToleranceState_primaryhost'],
                          ],
             ExitSequence => [
                           ['DisableMultiTxQueues'],
                           ['DisableMultiRxQueues'],
                           ['DisableRSS'],
                           ['PowerOff'],
                           ['PowerOffVM2'],
                           ['DisableFT'],
                          ],
            'EnableFT'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'PowerOn'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'PowerOnVM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState_primaryhost' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                            },
            },
            'EnableRSS' => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "vm.[1].vnic.[1]",
               setrss          => "Enable",
            },
            'MultiQueueTxUDP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'set_queues' => {
                  'direction' => 'tx',
                  'value'     => '1,2,4,8',
                },
               'maxtimeout' => '16200',
               'verification' => 'UDPTraffic',
               'iterations' => '1'
            },
            'MultiQueueRxUDP' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'set_queues' => {
                  'direction' => 'rx',
                  'value'     => '1,2,4,8',
                },
               'maxtimeout' => '16200',
               'verification' => 'UDPTraffic',
               'iterations' => '1'
            },
            'DisableMultiTxQueues' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'set_queues' => {
                  'direction' => 'tx',
                  'value'     => '1',
                },
               'iterations' => '1'
            },
            'DisableMultiRxQueues' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'set_queues' => {
                  'direction' => 'rx',
                  'value'     => '1',
                },
               'iterations' => '1'
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'CheckFaultToleranceState_secondaryhost' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[1]",
                                          },
            },
            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               setrss         => "Disable",
            },
            'PowerOff' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'DisableFT' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
          },
       },

      'FtvmVM1VM3' => {
         TestName         => "FtvmVM1VM3",
         Category         => "Fault Tolerance",
         Component        => "SMPFT",
         Product          => "ESX",
         Version          => "2",
         QCPath           => 'OP\FaultTolerance',
         Summary          => "Disable Start Connected FautTolerance enbaled VM",
         Procedure        =>
           '1. Enable Fault Tolerance for the VM1 and VM3 '.
           '2. Power ON the VM1 and VM3 '.
           '3. Check if Fault Tolerance is enabled for both the VMs '.
           '4. Inject FaultTolerance VM1 and VM3 and start traffic from VM1 to VM3 '.
           '5. Check if the VM has successfully moved to its secondary hosts '.
           '6. Power OFF the VMs and Disable FT ',
         ExpectedResult   => "PASS",
         Status           => 'Execution Ready',
         Tags             => 'e1000,vmxnet3,P0',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLeverl   => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'araman',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_ThreeHost_ThreeDVS_Threedvpg_ThreeVM,

         WORKLOADS => {
            Sequence   => [
                           ['PowerOff_VM1'],
                           ['PowerOff_VM2'],
                           ['PowerOff_VM3'],
                           ['EnableFT_VM1'],
                           ['PowerOn_VM1'],
                           ['PowerOn_VM2'],
                           ['CheckFaultToleranceState_secondaryhost_VM1'],
                           ['Traffic1'],
                           ['PowerOff_VM1'],
                           ['DisableFT_VM1'],
                           ['EnableFT_VM3'],
                           ['PowerOn_VM3'],
                           ['CheckFaultToleranceState_secondaryhost_VM3'],
                           ['Traffic2'],
                           ['InjectFautTolerance_1'],
                           ['CheckFaultToleranceState_primaryhost_VM1'],
                           ['InjectFautTolerance_2'],
                           ['CheckFaultToleranceState_primaryhost_VM3'],
                         ],
            ExitSequence => [
                           ['PowerOff_VM2'],
                           ['PowerOff_VM3'],
                           ['DisableFT_VM3'],
                          ],
            'EnableFT_VM1'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                secondaryhost => "host.[2]",
                faulttolerance => 'enable',
            },
            'CheckFaultToleranceState_primaryhost_VM1' => {
                Type      => "Host",
                TestHost  => "host.[1]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[1]",
                                           },
            },
            'EnableFT_VM3'  => {
                Type => "VM",
                TestVM => "vm.[3]",
                secondaryhost => "host.[1]",
                faulttolerance => 'enable',
            },
            'PowerOn_VM1'  => {
                Type => "VM",
                TestVM => "vm.[1]",
                vmstate => "poweron"
            },
            'PowerOn_VM2'  => {
                Type => "VM",
                TestVM => "vm.[2]",
                vmstate => "poweron"
            },
            'PowerOn_VM3'  => {
                Type => "VM",
                TestVM => "vm.[3]",
                vmstate => "poweron"
            },
            'CheckFaultToleranceState_primaryhost_VM3' => {
                Type      => "Host",
                TestHost  => "host.[2]",
                faulttoleranceoperation => {
                                              faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                              faulttolerancevm => "vm.[3]",
                                           },
            },
            'Traffic1' => {
               Type           => 'Traffic',
               noofoutbound   => '1',
               testduration   => '50',
               toolname       => 'netperf',
               noofinbound    => '1',
               testadapter    => 'vm.[1].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'Traffic2' => {
               Type           => 'Traffic',
               noofoutbound   => '1',
               testduration   => '50',
               toolname       => 'netperf',
               noofinbound    => '1',
               testadapter    => 'vm.[3].vnic.[1]',
               supportadapter => 'vm.[2].vnic.[1]',
            },
            'InjectFautTolerance_1' => {
               Type           => "Host",
               TestHost       => "host.[1]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[1]",
                                            },
            },
            'InjectFautTolerance_2' => {
               Type           => "Host",
               TestHost       => "host.[2]",
               faulttoleranceoperation   => {
                                               faulttoleranceoption => VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE,
                                               faulttolerancevm => "vm.[3]",
                                            },
            },
            'CheckFaultToleranceState_secondaryhost_VM1' => {
               Type      => "Host",
               TestHost  => "host.[2]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[1]",
                                          },
            },
            'CheckFaultToleranceState_secondaryhost_VM3' => {
               Type      => "Host",
               TestHost  => "host.[1]",
               faulttoleranceoperation => {
                                             faulttoleranceoption => VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE,
                                             faulttolerancevm => "vm.[3]",
                                          },
            },
            'PowerOff_VM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOff_VM2' => {
               Type => "VM",
               TestVM => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOff_VM3' => {
               Type => "VM",
               TestVM => "vm.[3]",
               vmstate => "poweroff",
            },
            'DisableFT_VM1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               faulttolerance => 'disable',
            },
            'DisableFT_VM3' => {
               Type => "VM",
               TestVM => "vm.[3]",
               faulttolerance => 'disable',
            },
          },
       },
    )
}


##########################################################################
# new --
#       This is the constructor for FTTds
#
# Input:
#       none
#
# Results:
#       An instance/object of FTTds class
#
# Side effects:
#       None
#
########################################################################

sub new
{
      my ($proto) = @_;
      # Below way of getting class name is to allow new class as well as
      # $class->new.  In new class, proto itself is class, and $class->new,
      # ref($class) return the class
      my $class = ref($proto) || $proto;
      my $self = $class->SUPER::new(\%FT);
      return (bless($self, $class));
}

1;
