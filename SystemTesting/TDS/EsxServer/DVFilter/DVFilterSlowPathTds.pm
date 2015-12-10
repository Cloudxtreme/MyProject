#!/usr/bin/perl
########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::DVFilter::DVFilterSlowPathTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use TDS::EsxServer::DVFilter::TestbedSpec;

@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::EsxServer::DVFilter::CommonWorkloads ':AllConstants';

{
   %DVFilterSlowPath = (
      'dvFilterSlowpathCrashAppliance' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathCrashAppliance',
         'Summary' => 'Crash appliance when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilterSlowPath::dvFilterSlowpathCrashAppliance',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath1Agent'
               ],
               [
                  'BlockTCP'
               ],
               [
                  'VerifyIperfFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyIperfPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'BlockTCP'
               ],
               [
                  'VerifyIperfFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyIperfPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'CrashSlowpathVM'
               ],
               [
                  'CheckSUTHost'
               ],
               [
                  'CheckVMKLog'
               ],
               [
                  'ResetSlowpathVM'
               ]
            ],
            'ExitSequence' =>[
               [
                  'ALLVMPowerOff'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VMPowerOff' => VM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'VerifyIperfPass' => VERIFY_IPERF_PASS,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'StartSlowpath1Agent' => START_SLOWPATH_1_AGENT,
            'BlockTCP' => BLOCK_TCP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'BlockICMP' => BLOCK_ICMP,
            'VerifyIperfFail' => VERIFY_IPERF_FAIL,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'CrashSlowpathVM' => {
               'Type' => 'Command',
               'vmstate' => 'crash',
               'testvm' => 'vm.[3]'
            },
            'CheckSUTHost' => {
               'Type' => 'Command',
               'command' => 'hostname',
               'testhost' => 'host.[1]'
            },
            'ResetSlowpathVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[3]',
               'operation' => 'reset'
            }
         }
      },


      'dvFilterSlowpathFloodPingAppliance' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathFloodPingAppliance',
         'Summary' => 'FloodPing appliance when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Tags' => 'slowpath',
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathFloodPingAppliance',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath1Agent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'VerifyPingPass',
                  'RunFloodPingSlowpathVM2',
                  'RunFloodPingSlowpathVM'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail',
                  'RunFloodPingSlowpathVM2',
                  'RunFloodPingSlowpathVM'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass',
                  'RunFloodPingSlowpathVM2',
                  'RunFloodPingSlowpathVM'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail',
                  'RunFloodPingSlowpathVM2',
                  'RunFloodPingSlowpathVM'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass',
                  'RunFloodPingSlowpathVM2',
                  'RunFloodPingSlowpathVM'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'CheckVMKLog'
               ]
            ],
            'ExitSequence' => [
              [
                  'ALLVMPowerOff'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VMPowerOff' => VM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'StartSlowpath1Agent' => START_SLOWPATH_1_AGENT,
            'BlockICMP' => BLOCK_ICMP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'RunFloodPingSlowpathVM' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'testduration' => '1800',
               'routingscheme' => 'flood',
               'expectedresult' => 'ignore',
               'noofoutbound' => '1',
               'testadapter' => 'vm.[3].vnic.[3]',
               'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'RunFloodPingSlowpathVM2' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'testduration' => '100',
               'noofinbound' => '1',
               'testadapter' => 'vm.[3].vnic.[3]',
               'supportadapter' => 'host.[1].vmknic.[1]'
            },
         }
      },


      'dvFilterSlowpathKernelSpaceAgentStress' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathKernelSpaceAgentStress',
         'Summary' => 'Put heavy network traffic on the DVFilter slowpath VM and monitor its status(PR#840873)',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathKernelSpaceAgentStress',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic',
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'VerifyTrafficStress'
               ],
               [
                  'VerifySlowpathVMAlive'
               ],
               [
                  'StopSlowpathAgent'
               ]
            ],
            'ExitSequence' => [
              [
                  'ALLVMPowerOff'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VMPowerOff' => VM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyTrafficStress' => {
               'Type' => 'Traffic',
               'portnumber' => 56001,
               'toolname' => 'iperf',
               'testduration' => '900',
               'iterations' => '2',
               'testadapter' => 'vm.[1].vnic.[1]',
               'l4protocol' => 'TCP',
               'noofinbound' => '1',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifySlowpathVMAlive' => {
               'Type' => 'Command',
               'command' => 'pgrep dvfilter',
               'testvm' => 'vm.[3]'
            }
         }
      },


      'dvFilterSlowpathKillAppliance' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathKillAppliance',
         'Summary' => 'Kill appliance when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathKillAppliance',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath1Agent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'KillSlowpathVM'
               ],
               [
                  'CheckSUTHost'
               ],
               [
                  'CheckVMKLog'
               ],
            ],
             'ExitSequence' => [
                [
                  'ALLVMPowerOff'
                ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VMPowerOff' => VM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'StartSlowpath1Agent' => START_SLOWPATH_1_AGENT,
            'BlockICMP' => BLOCK_ICMP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'KillSlowpathVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[3]',
               'operation' => 'killvm'
            },
            'CheckSUTHost' => {
               'Type' => 'Command',
               'command' => 'hostname',
               'testhost' => 'host.[1]'
            },
            'PowerOnSlowpathVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[3]',
               'vmstate' => 'poweron'
            }
         }
      },


      'dvFilterSlowpathMultipleProtectedVM' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathMultipleProtectedVM',
         'Summary' => 'Run Multiple ProtectedVM when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathMultipleProtectedVM',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_3,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ]
           ],
            'ExitSequence' => [
              [
                  'ALLVMPowerOff'
               ],
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'BlockICMP' => BLOCK_ICMP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VMPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1],vm.[3],vm.[4]',
               'vmstate' => 'poweroff'
            },
            'VMPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1],vm.[3],vm.[4]',
               'vmstate' => 'poweron'
            },
            'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-dummy filter1:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1],vm.[4].vnic.[1]'
            },
            'VerifyPingPass' => {
               'Type' => 'Traffic',
               'testduration' => '100',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VerifyPingFail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '20',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            }
         }
      },


      'dvFilterSlowpathRebootAppliance' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathRebootAppliance',
         'Summary' => 'Reboot appliance when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathRebootAppliance',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath1Agent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass',
               ],
               [
                  'RebootSlowpathVM'
               ],
               [
                  'VerifyPingPass',
               ],
               [
                  'CheckVMKLog'
               ]
            ],
            'ExitSequence' => [
               [
                  'ALLVMPowerOff'
               ],
            ],

            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VMPowerOff' => VM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'StartSlowpath1Agent' => START_SLOWPATH_1_AGENT,
            'BlockICMP' => BLOCK_ICMP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'RebootSlowpathVM' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[3]',
               'operation' => 'reboot'
            }
         }
      },


      'dvFilterSlowpathRestartAgent' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathRestartAgent',
         'Summary' => 'Restart slowpath agent when running DVFilter slowpath',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathRestartAgent',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM'
               ],
               [
                  'SlowpathVMInit'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath1Agent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'StartSlowpath2UserspaceAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'RunRestartSlowpathAgent'
               ],
               [
                  'CheckSlowpathVM'
               ],
               [
                  'StartSlowpath2KernelAgent'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent'
               ],
               [
                  'CheckVMKLog'
               ]
            ],
            'ExitSequence' => [
               [
                  'ALLVMPowerOff'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'VMPowerOff' => VM_POWER_OFF,
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'DVFilterHostSetup' => DVFILTER_HOST_SETUP,
            'AddDVFilterToVM' => ADD_DVFILTER_TO_VM,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'VMPowerOn' => VM_POWER_ON,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM' => NEW_SLOWPATH_VM,
            'SlowpathVMInit' => SLOWPATH_VM_INIT,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'StartSlowpath1Agent' => START_SLOWPATH_1_AGENT,
            'BlockICMP' => BLOCK_ICMP,
            'ClearDVFilterCtl' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'RunRestartSlowpathAgent' => {
               'Type' => 'DVFilterSlowpath',
               'TestDVFilter' => 'vm.[3].dvfilter.[1]',
               'agentname' => 'dvfilter-dummy',
               'adapters' => 'vm.[3].vnic.[1-2]',
               'destination_ip' => 'host.[1].vmknic.[1]',
               'restartagent' => 'true'
            },
            'CheckSlowpathVM' => {
               'Type' => 'Command',
               'command' => 'hostname',
               'testvm' => 'vm.[3]'
            }
         }
      },


      'dvFilterSlowpathTwoAppliances' => {
         'Component' => 'network dvfilter/vmsafe-net',
         'Category' => 'ESX Server',
         'TestName' => 'dvFilterSlowpathTwoAppliances',
         'Summary' => 'Test the case of two DVFilter slowpath VMs',
         'ExpectedResult' => 'PASS',
         'Tags' => undef,
         'Version' => '2',
         'testID' => 'TDS::EsxServer::DVFilter::DVFilter::dvFilterSlowpathTwoAppliances',
         'TestbedSpec' => $TDS::EsxServer::DVFilter::TestbedSpec::Topology_2,
         'WORKLOADS' => {
            'Sequence' => [
               [
                  'VMPowerOff'
               ],
               [
                  'DVFilterHostSetup'
               ],
               [
                  'AddDVFilterToVM'
               ],
               [
                  'AddDVFilterToSPVM'
               ],
               [
                  'AddDVFilterToSPVM2'
               ],
               [
                  'VMPowerOn'
               ],
               [
                  'ConfigVmknic'
               ],
               [
                  'NewSlowpathVM1'
               ],
               [
                  'NewSlowpathVM2'
               ],
               [
                  'SlowpathVMInit1'
               ],
               [
                  'SlowpathVMInit2'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath2UserspaceAgent1'
               ],
               [
                  'StartSlowpath2UserspaceAgent2'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP1'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl1'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP2'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl2'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent1'
               ],
               [
                  'StopSlowpathAgent2'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StartSlowpath2KernelAgent1'
               ],
               [
                  'StartSlowpath2KernelAgent2'
               ],
               [
                  'BlockICMP1'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl1'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'BlockICMP2'
               ],
               [
                  'VerifyPingFail'
               ],
               [
                  'ClearDVFilterCtl2'
               ],
               [
                  'VerifyPingPass'
               ],
               [
                  'StopSlowpathAgent1'
               ],
               [
                  'StopSlowpathAgent2'
               ],
               [
                  'CheckVMKLog'
               ]
            ],
            'ExitSequence' =>[
               [
                  'ALLVMPowerOff'
               ]
            ],
            'Duration' => 'time in seconds',
            'Iterations' => '1',
            'ALLVMPowerOff' => ALLVM_POWER_OFF,
            'VerifyIperfPass' => VERIFY_IPERF_PASS,
            'AddDVFilterToSPVM' => ADD_DVFILTER_TO_SP_VM,
            'ConfigVmknic' => CONFIG_VMKNIC,
            'NewSlowpathVM1' => NEW_SLOWPATH_VM,
            'SlowpathVMInit1' => SLOWPATH_VM_INIT,
            'VerifyPingPass' => VERIFY_PING_PASS,
            'BlockICMP1' => BLOCK_ICMP,
            'ClearDVFilterCtl1' => CLEAR_DVFILTERCTL,
            'StopSlowpathAgent1' => STOP_SLOWPATH_AGENT,
            'StartSlowpath2UserspaceAgent1' => START_SLOWPATH_2_USERSPACE_AGENT,
            'StartSlowpath2KernelAgent1' => START_SLOWPATH_2_KERNEL_AGENT,
            'VerifyPingFail' => VERIFY_PING_FAIL,
            'CheckVMKLog' => CHECK_VMKLOG,
            'VMPowerOff' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1],vm.[3-4]',
               'vmstate' => 'poweroff'
            },
            'DVFilterHostSetup' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'dvfilterhostsetup' => 'qw(dvfilter-generic:add dvfilter-generic-1:add dvfilter-generic-2:add)'
            },
            'AddDVFilterToVM' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter1:name:dvfilter-dummy filter1:onFailure:failOpen filter2:name:dvfilter-dummy-2 filter2:onFailure:failOpen)',
               'adapters' => 'vm.[1].vnic.[1]'
            },
            'AddDVFilterToSPVM2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'adddvfilter' => 'qw(filter0:name:dvfilter-faulter filter0:param0:dvfilter-dummy-2)',
               'adapters' => 'vm.[4].vnic.[1-2]'
            },
            'VMPowerOn' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[1],vm.[3-4]',
               'vmstate' => 'poweron'
            },
            'NewSlowpathVM2' => {
               'Type' => 'VM',
               'TestVM' => 'vm.[4]',
               'dvfilter' => {
                  '[1]' => {}
               }
            },
            'SlowpathVMInit2' => {
               'Type' => 'DVFilterSlowpath',
               'TestDVFilter' => 'vm.[4].dvfilter.[1]',
               'adapters' => 'vm.[4].vnic.[1-2]',
               'initslowpathvm' => 'true'
            },
            'StartSlowpath2UserspaceAgent2' => {
               'Type' => 'DVFilterSlowpath',
               'TestDVFilter' => 'vm.[4].dvfilter.[1]',
               'startslowpathagent' => 'userspace',
               'adapter' => 'vm.[4].vnic.[1]',
               'agentname' => 'dvfilter-dummy-2',
               'destination_ip' => 'host.[1].vmknic.[2]'
            },
            'StartSlowpath2KernelAgent2' => {
               'Type' => 'DVFilterSlowpath',
               'TestDVFilter' => 'vm.[4].dvfilter.[1]',
               'startslowpathagent' => 'kernel',
               'adapter' => 'vm.[4].vnic.[2]',
               'agentname' => 'dvfilter-dummy-2',
               'destination_ip' => 'host.[1].vmknic.[2]'
            },
            'BlockICMP2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'dvfilterctl' => 'dvfilter-dummy-2',
               'destination_ip' => 'vm.[4].vnic.[3]',
               'dvfilterconfigspec' => {
                  'delay' => 0,
                  'outbound' => 1,
                  'tcp' => 0,
                  'inbound' => 1,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 1
               }
            },
            'ClearDVFilterCtl2' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'vm' => 'vm.[1]',
               'dvfilterctl' => 'dvfilter-dummy-2',
               'destination_ip' => 'vm.[4].vnic.[3]',
               'dvfilterconfigspec' => {
                  'delay' => 0,
                  'outbound' => 0,
                  'tcp' => 0,
                  'inbound' => 0,
                  'copy' => 0,
                  'udp' => 0,
                  'icmp' => 0
               }
            },
            'StopSlowpathAgent2' => {
               'Type' => 'DVFilterSlowpath',
               'TestDVFilter' => 'vm.[4].dvfilter.[1]',
               'closeslowpathagent' => 'true'
            }
         }
      },


   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for DVFilter.
#
# Input:
#       None.
#
# Results:
#       An instance/object of DVFilter class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%DVFilterSlowPath);
   return (bless($self, $class));
}
