#!/usr/bin/perl
#########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::VirtualNetDevices::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'CSO_ENABLE_TX',
   'CSO_ENABLE_RX',
   'CSO_DISABLE_TX',
   'CSO_DISABLE_RX',
   'ENABLE_SG',
   'DISABLE_SG',
   'ENABLE_TSO',
   'DISABLE_TSO',
   'CONFIGURE_IP',
   'PING_TRAFFIC',

);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant CSO_ENABLE_TX => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tcptxchecksumipv4',
      'enable'       => 'true',
   },
   'iterations' => '1',
};

use constant CSO_ENABLE_RX => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tcprxchecksumipv4',
      'enable'       => 'true',
   },
   'sleepbetweenworkloads' => '60',
   'iterations' => '1'
};

use constant CSO_DISABLE_TX => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tcptxchecksumipv4',
      'enable'       => 'false',
   },
   'iterations' => '1'
};
use constant CSO_DISABLE_RX => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tcprxchecksumipv4',
      'enable'       => 'false',
   },
   'sleepbetweenworkloads' => '60',
   'iterations' => '1'
};
use constant ENABLE_SG => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'sg',
      'enable'       => 'true',
   },
};
use constant DISABLE_SG => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'sg',
      'enable'       => 'false',
   },
};
use constant ENABLE_TSO => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tsoipv4',
      'enable'       => 'true',
   },
};
use constant DISABLE_TSO => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tsoipv4',
      'enable'       => 'false',
   },
};
use constant CONFIGURE_IP => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
    'ipv4' => 'AUTO',
};

use constant PING_TRAFFIC => {
   'Type' => 'Traffic',
   'noofoutbound' => '2',
   'testduration' => '60',
   'toolname' => 'ping',
   'noofinbound' => '2',
   'L3Protocol'     => 'ipv4,ipv6',
   'TestAdapter' => 'vm.[1].vnic.[1]',
   'supportadapter' => 'vm.[2].vnic.[1]',
};

1;
