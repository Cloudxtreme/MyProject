#!/usr/bin/perl
#########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::DVFilter::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'ALLVM_POWER_OFF',
   'VM_POWER_OFF',
   'VM_POWER_ON',
   'DVFILTER_HOST_SETUP',
   'ADD_DVFILTER_TO_VM',
   'ADD_DVFILTER_TO_SP_VM',
   'CONFIG_VMKNIC',
   'NEW_SLOWPATH_VM',
   'SLOWPATH_VM_INIT',
   'START_SLOWPATH_1_AGENT',
   'START_SLOWPATH_2_USERSPACE_AGENT',
   'START_SLOWPATH_2_KERNEL_AGENT',
   'STOP_SLOWPATH_AGENT',
   'BLOCK_ICMP',
   'BLOCK_TCP',
   'CLEAR_DVFILTERCTL',
   'VERIFY_PING_PASS',
   'VERIFY_IPERF_PASS',
   'VERIFY_IPERF_FAIL',
   'VERIFY_PING_FAIL',
   'CHECK_VMKLOG'
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);
use constant ALLVM_POWER_OFF => {
   'Type' => 'VM',
   'TestVM' => 'vm.[-1]',
   'vmstate' => 'poweroff'
};
use constant VM_POWER_OFF => {
   'Type' => 'VM',
   'TestVM' => 'vm.[1],vm.[3]',
   'vmstate' => 'poweroff'
};
use constant VM_POWER_ON => {
   'Type' => 'VM',
   'TestVM' => 'vm.[1],vm.[3]',
   'vmstate' => 'poweron'
};
use constant DVFILTER_HOST_SETUP => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'dvfiltertype' => 'slow',
   'dvfilterhostsetup' => 'qw(dvfilter-generic:add)'
};
use constant ADD_DVFILTER_TO_VM => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'adddvfilter' => 'qw(filter1:name:dvfilter-dummy filter1:onFailure:failOpen)',
   'adapters' => 'vm.[1].vnic.[1]'
};
use constant ADD_DVFILTER_TO_SP_VM => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'adddvfilter' => 'qw(filter0:name:dvfilter-faulter filter0:param0:dvfilter-dummy)',
   'adapters' => 'vm.[3].vnic.[1-2]'
};
use constant CONFIG_VMKNIC => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'host.[1].vmknic.[1]',
   'binddvfilter' => '1'
};
use constant NEW_SLOWPATH_VM => {
   'Type' => 'VM',
   'TestVM' => 'vm.[3]',
   'dvfilter' => {
      '[1]' => {}
   }
};
use constant SLOWPATH_VM_INIT => {
   'Type' => 'DVFilterSlowpath',
   'TestDVFilter' => 'vm.[3].dvfilter.[1]',
   'adapters' => 'vm.[3].vnic.[1-2]',
   'initslowpathvm' => 'true'
};
use constant START_SLOWPATH_1_AGENT => {
   'Type' => 'DVFilterSlowpath',
   'TestDVFilter' => 'vm.[3].dvfilter.[1]',
   'startslowpathagent' => 'one',
   'agentname' => 'dvfilter-dummy',
   'destination_ip' => 'host.[1].vmknic.[1]'
};
use constant STOP_SLOWPATH_AGENT => {
   'Type' => 'DVFilterSlowpath',
   'TestDVFilter' => 'vm.[3].dvfilter.[1]',
   'closeslowpathagent' => 'true'
};
use constant START_SLOWPATH_2_USERSPACE_AGENT => {
   'Type' => 'DVFilterSlowpath',
   'TestDVFilter' => 'vm.[3].dvfilter.[1]',
   'startslowpathagent' => 'userspace',
   'agentname' => 'dvfilter-dummy',
   'adapter' => 'vm.[3].vnic.[1]',
   'destination_ip' => 'host.[1].vmknic.[1]'
};
use constant START_SLOWPATH_2_KERNEL_AGENT => {
   'Type' => 'DVFilterSlowpath',
   'TestDVFilter' => 'vm.[3].dvfilter.[1]',
   'startslowpathagent' => 'kernel',
   'agentname' => 'dvfilter-dummy',
   'adapter' => 'vm.[3].vnic.[2]',
   'destination_ip' => 'host.[1].vmknic.[1]'
};
use constant BLOCK_ICMP => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'vm' => 'vm.[1]',
   'dvfilterctl' => 'dvfilter-dummy',
   'destination_ip' => 'vm.[3].vnic.[3]',
   'dvfilterconfigspec' => {
      'outbound' => 1,
      'tcp' => 0,
      'inbound' => 1,
      'udp' => 0,
      'icmp' => 1
   }
};
use constant BLOCK_TCP => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'vm' => 'vm.[1]',
   'dvfilterctl' => 'dvfilter-dummy',
   'destination_ip' => 'vm.[3].vnic.[3]',
   'dvfilterconfigspec' => {
      'outbound' => 1,
      'tcp' => 46001,
      'inbound' => 1,
      'udp' => 0,
      'icmp' => 0
   }
};
use constant CLEAR_DVFILTERCTL => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'vm' => 'vm.[1]',
   'dvfilterctl' => 'dvfilter-dummy',
   'destination_ip' => 'vm.[3].vnic.[3]',
   'dvfilterconfigspec' => {
      'delay' => 0,
      'outbound' => 0,
      'tcp' => 0,
      'inbound' => 0,
      'copy' => 0,
      'udp' => 0,
      'icmp' => 0
   }
};
use constant VERIFY_IPERF_PASS => {
   'Type' => 'Traffic',
   'l4protocol' => 'TCP',
   'testduration' => '100',
   'portnumber' => 46001,
   'toolname' => 'iperf',
   'noofinbound' => '1',
   'testadapter' => 'vm.[1].vnic.[1]',
   'supportadapter' => 'vm.[2].vnic.[1]'
};
use constant VERIFY_IPERF_FAIL => {
   'Type' => 'Traffic',
   'expectedresult' => 'FAIL',
   'l4protocol' => 'TCP',
   'testduration' => '20',
   'portnumber' => 46001,
   'toolname' => 'iperf',
   'noofinbound' => '1',
   'testadapter' => 'vm.[1].vnic.[1]',
   'supportadapter' => 'vm.[2].vnic.[1]'
};
use constant VERIFY_PING_PASS => {
   'Type' => 'Traffic',
   'testduration' => '100',
   'toolname' => 'ping',
   'noofinbound' => '1',
   'testadapter' => 'vm.[1].vnic.[1]',
   'supportadapter' => 'vm.[2].vnic.[1]'
};
use constant VERIFY_PING_FAIL => {
   'Type' => 'Traffic',
   'expectedresult' => 'FAIL',
   'testduration' => '20',
   'toolname' => 'ping',
   'noofinbound' => '1',
   'testadapter' => 'vm.[1].vnic.[1]',
   'supportadapter' => 'vm.[2].vnic.[1]'
};
use constant CHECK_VMKLOG => {
   'Type' => 'Host',
   'TestHost' => 'host.[1]',
   'expectedresult' => 'FAIL',
   'verifyvmklog' => 'ERROR'
};

1;
