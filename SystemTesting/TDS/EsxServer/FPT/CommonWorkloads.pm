#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::FPT::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'POWERON_VM1',
   'POWERON_VM2',
   'POWERON_VM3',
   'POWEROFF_VM1',
   'POWEROFF_VM2',
   'POWEROFF_VM3',
   'POWEROFF_ALL_VMS',
   'DELETE_PASSTHROUGH1_ON_VM1',
   'DELETE_PASSTHROUGH2_ON_VM1',
   'DELETE_PASSTHROUGH1_ON_VM2',
   'DELETE_PASSTHROUGH1_ON_VM3',
   'DELETE_PASSTHROUGH_ALL_ON_VM1',
   'DELETE_PASSTHROUGH_ALL_ON_VM2',
   'DELETE_VNIC1_ON_VM1',
   'DELETE_VNIC1_ON_VM2',
   'DELETE_VNIC1_ON_VM3',
   'REMOVE_UPLINK1_VDS1',
   'REMOVE_UPLINK_VDS1',
   'REMOVE_UPLINK_ALLHOST_VDS1',
   'DELETE_VDS1',
   'DELETE_VDS2',
   'DISABLE_SRIOV_VMNIC1_HOST1',
   'DISABLE_SRIOV_VMNIC2_HOST1',
   'DISABLE_SRIOV_HOST1',
   'DISABLE_SRIOV_VMNIC1_HOST2',
   'DELETE_VSS1',
   'DELETE_HOST1_PG',
   'DELETE_HOST1_PG1',
   'REMOVE_HOST1_VMKNIC',
   'REMOVE_HOST2_VMKNIC',
);

our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant POWERON_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweron",
};
use constant POWERON_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweron",
};
use constant POWERON_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweron",
};
use constant POWEROFF_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweroff",
};
use constant POWEROFF_ALL_VMS  => {
    Type    => "VM",
    TestVM  => "vm.[-1]",
    vmstate =>  "poweroff",
    expectedResult => "ignore"
};
use constant REMOVE_UPLINK_VDS1  => {
    Type => 'Switch',
    TestSwitch => 'vc.[1].vds.[1]',
    configureuplinks => 'remove',
    vmnicadapter => 'host.[1-2].vmnic.[1]'
};
use constant REMOVE_UPLINK_ALLHOST_VDS1  => {
    Type => 'Switch',
    TestSwitch => 'vc.[1].vds.[1]',
    configureuplinks => 'remove',
    vmnicadapter => 'host.[1-2].vmnic.[1]'
};
use constant DELETE_PASSTHROUGH1_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    deletevnic =>  "vm.[1].pcipassthru.[1]",
    expectedResult => "ignore"
};
use constant DELETE_PASSTHROUGH2_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    deletevnic =>  "vm.[1].pcipassthru.[2]",
    expectedResult => "ignore"
};
use constant DELETE_PASSTHROUGH1_ON_VM2 => {
    Type    => "VM",
    TestVM  => "vm.[2]",
    deletevnic =>  "vm.[2].pcipassthru.[1]",
    expectedResult => "ignore"
};
use constant DELETE_PASSTHROUGH1_ON_VM3 => {
    Type    => "VM",
    TestVM  => "vm.[3]",
    deletevnic =>  "vm.[3].pcipassthru.[1]",
    expectedResult => "ignore"
};
use constant DELETE_VNIC1_ON_VM1 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[1]',
     'deletevnic' => 'vm.[1].vnic.[1]'
};
use constant DELETE_VNIC1_ON_VM2 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[2]',
     'deletevnic' => 'vm.[2].vnic.[1]'
};
use constant DELETE_VNIC1_ON_VM3 => {
     'Type' => 'VM',
     'TestVM' => 'vm.[3]',
     'deletevnic' => 'vm.[3].vnic.[1]'
};
use constant DELETE_VDS1 => {
    Type => "VC",
    TestVC => "vc.[1]",
    deletevds => "vc.[1].vds.[1]",
};
use constant DELETE_VDS2 => {
    Type => "VC",
    TestVC => "vc.[1]",
    deletevds => "vc.[1].vds.[2]",
};
use constant DISABLE_SRIOV_VMNIC1_HOST1 => {
    Type     => "Host",
    TestHost => "host.[1]",
    sriov    => "disable",
    vmnicadapter   => "host.[1].vmnic.[1]",
};
use constant DISABLE_SRIOV_VMNIC1_HOST2 => {
    Type     => "Host",
    TestHost => "host.[2]",
    sriov    => "disable",
    vmnicadapter   => "host.[2].vmnic.[1]",
};
use constant DISABLE_SRIOV_VMNIC2_HOST1 => {
    Type     => "Host",
    TestHost => "host.[1]",
    sriov    => "disable",
    vmnicadapter   => "host.[1].vmnic.[2]",
};
use constant DISABLE_SRIOV_HOST1 => {
    Type     => "Host",
    TestHost => "host.[1]",
    sriov    => "disable",
    vmnicadapter   => "host.[1].vmnic.[1-2]",
};
use constant DELETE_VSS1 => {
    Type => "Host",
    TestVC => "Host.[1]",
    deletevds => "host.[1].vss.[1]",
};
use constant DELETE_HOST1_PG => {
    Type            => "Host",
    Testhost        => "host.[1]",
    deleteportgroup => "host.[1].portgroup.[1-2]",
};
use constant DELETE_HOST1_PG1 => {
    Type            => "Host",
    Testhost        => "host.[1]",
    deleteportgroup => "host.[1].portgroup.[1]",
};
use constant REMOVE_UPLINK1_VDS1  => {
    Type => 'Switch',
    TestSwitch => 'vc.[1].vds.[1]',
    configureuplinks => 'remove',
    vmnicadapter => 'host.[1].vmnic.[1]'
};
use constant REMOVE_HOST1_VMKNIC => {
    Type => "Host",
    TestHost => "host.[1]",
    deletevmknic => "host.[1].vmknic.[1]",
};
use constant REMOVE_HOST2_VMKNIC => {
    Type => "Host",
    TestHost => "host.[2]",
    deletevmknic => "host.[2].vmknic.[1]",
};
use constant DELETE_PASSTHROUGH_ALL_ON_VM1 => {
    Type    => "VM",
    TestVM  => "vm.[1]",
    deletevnic =>  "vm.[1].pcipassthru.[1-6]",
    expectedResult => "ignore"
};
use constant DELETE_PASSTHROUGH_ALL_ON_VM2 => {
    Type    => "VM",
    TestVM  => "vm.[2]",
    deletevnic =>  "vm.[2].pcipassthru.[1-6]",
    expectedResult => "ignore"
};