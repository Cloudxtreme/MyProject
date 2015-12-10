import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.vdswitch.dvportgroup.dvportgroup as dvportgroup
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger
VSphereAPIClient = vsphere_client.VSphereAPIClient


class DVPortgroupAPIClient(dvportgroup.DVPortgroup, VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(DVPortgroupAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
        self.dvpg_mor = self.get_dvpg_mor()
        if self.dvpg_mor is not None:
            self.dvpg_key = self.dvpg_mor.key

    def get_dvpg_mor(self):
        vds_mor = self.parent.vds_mor
        for pg in vds_mor.portgroup:
            if pg.name == self.name:
                return pg

    def get_dvs_port_connection(self, **kwargs):
        spec = vim.dvs.PortConnection()
        if kwargs.get('portgroup_key') is not None:
            spec.portgroupKey = kwargs.get('portgroup_key')
        if kwargs.get('port_key') is not None:
            spec.portKey = kwargs.get('port_key')
        spec.switchUuid = kwargs.get('switch_uuid')
        if kwargs.get('opaque_network_id') is not None:
            opaque = vim.host.VirtualNic.OpaqueNetworkSpec()
            opaque.opaqueNetworkId = kwargs.get('opaque_network_id')
            opaque.opaqueNetworkType = kwargs.get('opaque_network_type')
            spec.opaqueNetwork = opaque
        return spec

    def get_ip_config(self, **kwargs):
        spec = vim.host.IpConfig()
        dhcp = kwargs.get('dhcp')
        if dhcp is True:
            spec.dhcp = dhcp
            return spec
        else:
            spec.ipAddress = kwargs.get('ip')
            if kwargs.get('netmask') is not None:
                spec.subnetMask = kwargs.get('netmask')
            return spec

    def get_vnic_spec(self, **kwargs):
        spec = vim.host.VirtualNic.Specification()
        if kwargs.get('dvport_spec') is not None:
            spec.distributedVirtualPort = kwargs.get('dvport_spec')
        if kwargs.get('ip_config') is not None:
            spec.ip = kwargs.get('ip_config')
        if kwargs.get('mac') is not None:
            spec.mac = kwargs.get('mac')
        if kwargs.get('mtu') is not None:
            spec.mtu = kwargs.get('mtu')
        return spec

    def get_security_policy(self, **kwargs):
        spec = vim.dvs.VmwareDistributedVirtualSwitch.SecurityPolicy()
        if kwargs.get('allow_promiscuous') is not None:
            bool_policy_1 = vim.BoolPolicy()
            bool_policy_1.value = kwargs.get('allow_promiscuous')
            spec.allowPromiscuous = bool_policy_1
        if kwargs.get('forged_transmits') is not None:
            bool_policy_2 = vim.BoolPolicy()
            bool_policy_2.value = kwargs.get('forged_transmits')
            spec.forgedTransmits = bool_policy_2
        if kwargs.get('mac_changes') is not None:
            bool_policy_3 = vim.BoolPolicy()
            bool_policy_3.value = kwargs.get('mac_changes')
            spec.macChanges = bool_policy_3
        return spec

    def get_traffic_shaping_policy(self, **kwargs):
        spec = vim.dvs.DistributedVirtualPort.TrafficShapingPolicy()
        if kwargs.get('avg_bandwidth') is not None:
            long_policy_1 = vim.LongPolicy()
            long_policy_1.value = kwargs.get('avg_bandwidth')
            spec.averageBandwidth = long_policy_1
        if kwargs.get('burst_size') is not None:
            long_policy_2 = vim.LongPolicy()
            long_policy_2.value = kwargs.get('burst_size')
            spec.burstSize = long_policy_2
        if kwargs.get('enabled') is not None:
            bool_policy = vim.BoolPolicy()
            bool_policy.value = kwargs.get('enabled')
            spec.enabled = bool_policy
        if kwargs.get('peak_bandwidth') is not None:
            long_policy_3 = vim.LongPolicy()
            long_policy_3.value = kwargs.get('peak_bandwidth')
            spec.peakBandwidth = long_policy_3
        return spec

    def get_dvpg_config_spec(self, **kwargs):
        spec = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        if kwargs.get('auto_expand') is not None:
            spec.autoExpand = kwargs.get('auto_expand')
        if kwargs.get('description') is not None:
            spec.description = kwargs.get('description')
        if kwargs.get('name') is not None:
            spec.name = kwargs.get('name')
        if kwargs.get('numports') is not None:
            spec.numPorts = kwargs.get('numports')
        if kwargs.get('portgroup_type') is not None:
            spec.type = kwargs.get('portgroup_type')
        if kwargs.get('resource_pool') is not None:
            spec.vmVnicNetworkResourcePoolKey = kwargs.get('resource_pool')
        return spec
