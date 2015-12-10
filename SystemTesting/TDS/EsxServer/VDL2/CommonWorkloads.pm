########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDL2::CommonWorkloads;

# Export workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'CheckAndInstallVDL2',
   'SetMTU_VDS',
   'EnableVDL2',
   'DisableVDL2',
   'CreateVDL2Vmknic_VDSVlan0',
   'RemoveVDL2Vmknic_VDSVlan0',
   'EnableTSODHCPForVnicofVM',
   'PowerOnVM'
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant CheckAndInstallVDL2 => {
   'Type' => 'Host',
   'TestHost' => 'host.[-1]',
   'vdl2' => 'checkAndInstallVDL2'
};

use constant SetMTU_VDS => {
   'Type' => 'Switch',
   'TestSwitch' => 'vc.[1].vds.[-1]',
   'mtu' => '1550'
};

use constant EnableVDL2 => {
   'Type' => 'VC',
   'TestVC' => 'vc.[1]',
   'testswitch' => 'vc.[1].vds.[-1]',
   'opt' => 'enablevdl2'
};

use constant CreateVDL2Vmknic_VDSVlan0 => {
   'Type' => 'VC',
   'TestVC' => 'vc.[1]',
	'vlanid' => '0',
	'testswitch' => 'vc.[1].vds.[-1]',
	'opt' => 'createvdl2vmknic'
};

use constant DisableVDL2  => {
   'Type' => 'VC',
   'TestVC' => 'vc.[1]',
   'vds' => 'vc.[1].vds.[-1]',
   'opt' => 'disablevdl2'
};

use constant RemoveVDL2Vmknic_VDSVlan0 => {
   'Type' => 'VC',
   'TestVC' => 'vc.[1]',
   'vlanid' => '0',
   'vds' => 'vc.[1].vds.[-1]',
   'opt' => 'removevdl2vmknic'
};

use constant EnableTSODHCPForVnicofVM => {
   'Type' => 'NetAdapter',
   'TestAdapter' => 'vm.[-1].vnic.[1]',
   'configure_offload' =>{
      'offload_type' => 'tsoipv4',
      'enable'       => 'true',
   },
   'ipv4' => 'dhcp'
};

use constant PowerOnVM => {
   'Type' => 'VM',
   'TestVM' => 'vm.[-1]',
   'vmstate' => 'poweron'
};

1;

