import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.vdswitch.vdswitch as vdswitch
import pyVmomi as pyVmomi

vim = pyVmomi.vim


class VDSwitchAPIClient(vdswitch.VDSwitch, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(VDSwitchAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
        self.vds_mor = self.get_vds_mor()
        self.uuid = self.vds_mor.uuid

    def get_vds_mor(self):
        content = self.connection.anchor.RetrieveContent()
        for dc in content.rootFolder.childEntity:
            if isinstance(dc, vim.Datacenter):
                if dc.name == self.parent.name:
                    for child in dc.networkFolder.childEntity:
                        if isinstance(
                                child,
                                vim.dvs.VmwareDistributedVirtualSwitch):
                            if child.name == self.name:
                                return child
            elif isinstance(dc, vim.Folder):
                for datacenter in dc.childEntity:
                    if isinstance(datacenter, vim.Datacenter):
                        if datacenter.name == self.parent.name:
                            for child in datacenter.networkFolder.childEntity:
                                if isinstance(
                                        child,
                                        vim.dvs.VmwareDistributedVirtualSwitch):
                                    if child.name == self.name:
                                        return child
                    elif isinstance(datacenter, vim.Folder):
                        dc = datacenter
                        continue

    def get_distributed_virtual_switch(self, kwargs):
        dvs = vim.DistributedVirtualSwitch()
        dvs.config = self.get_vmware_dvs_config_spec(kwargs)
        return dvs

    def get_vmware_dvs_config_spec(self, **kwargs):
        vmware_dvs_config = vim.dvs.VmwareDistributedVirtualSwitch.ConfigSpec()
        if "strip_original_vlan" in kwargs or "session_id" in kwargs:
            vmware_dvs_config.vspanConfigSpec = self.get_vmware_dvs_vspan_config_spec(kwargs)
        return vmware_dvs_config

    def get_vmware_dvs_vspan_config_spec(self, kwargs):
        vspan_config = vim.dvs.VmwareDistributedVirtualSwitch.VspanConfigSpec()
        if kwargs.get('operation') is not None:
            vspan_config.operation = kwargs.get('operation')
        else:
            vspan_config.operation = 'edit'
        vspan_config.vspanSession = self.get_vmware_vspan_session(kwargs)
        return [vspan_config]

    def get_vmware_vspan_session(self, kwargs):
        vspan = vim.dvs.VmwareDistributedVirtualSwitch.VspanSession()
        if kwargs.get('description') is not None:
            vspan.description = kwargs.get('description')
        if kwargs.get('enabled') is not None:
            vspan.enabled = kwargs.get('enabled')
        if kwargs.get('encap_vlan_id') is not None:
            vspan.encapsulationVlanId = kwargs.get('encap_vlan_id')
        if kwargs.get('session_id') is not None:
            vspan.key = kwargs.get('session_id')
        if kwargs.get('mirrored_packet_length') is not None:
            vspan.mirroredPacketLength = kwargs.get('mirrored_packet_length')
        if kwargs.get('sampling_rate') is not None:
            vspan.samplingRate = kwargs.get('sampling_rate')
        if kwargs.get('session_type') is not None:
            vspan.sessionType = kwargs.get('session_type')
        if kwargs.get('name') is not None:
            vspan.name = kwargs.get('name')
        if kwargs.get('normal_traffic_allowed') is not None:
            vspan.normalTrafficAllowed = kwargs.get('normal_traffic_allowed')
        if kwargs.get('strip_original_vlan') is not None:
            vspan.stripOriginalVlan = kwargs.get('strip_original_vlan')

        vspan.destinationPort = self.get_vmware_vspan_port_destination(kwargs)

        vspan.sourcePortReceived = self.get_vmware_vspan_port_src_rx(kwargs)

        vspan.sourcePortTransmitted = self.get_vmware_vspan_port_src_tx(kwargs)
        return vspan

    def get_vmware_vspan_port_destination(self, kwargs):
        vport = vim.dvs.VmwareDistributedVirtualSwitch.VspanPorts()
        if kwargs.get('dest_ip') is not None:
            vport.ipAddress = [kwargs.get('dest_ip')]
        if kwargs.get('dest_port_key') is not None:
            vport.portKey = [kwargs.get('dest_port_key')]
        if kwargs.get('dest_uplink_port_name') is not None:
            vport.uplinkPortName = [kwargs.get('dest_uplink_port_name')]
        if kwargs.get('dest_vlans') is not None:
            vport.vlans = [kwargs.get('dest_vlans')]
        return vport

    def get_vmware_vspan_port_src_rx(self, kwargs):
        vport = vim.dvs.VmwareDistributedVirtualSwitch.VspanPorts()
        if kwargs.get('src_ip_rx') is not None:
            vport.ipAddress = [kwargs.get('src_ip_rx')]
        if kwargs.get('src_port_key_rx') is not None:
            vport.portKey = [kwargs.get('src_port_key_rx')]
        if kwargs.get('src_uplink_port_name_rx') is not None:
            vport.uplinkPortName = [kwargs.get('src_uplink_port_name_rx')]
        if kwargs.get('src_vlans_rx') is not None:
            vport.vlans = [kwargs.get('src_vlans_rx')]
        return vport

    def get_vmware_vspan_port_src_tx(self, kwargs):
        vport = vim.dvs.VmwareDistributedVirtualSwitch.VspanPorts()
        if kwargs.get('src_ip_tx') is not None:
            vport.ipAddress = [kwargs.get('src_ip_tx')]
        if kwargs.get('src_port_key_tx') is not None:
            vport.portKey = [kwargs.get('src_port_key_tx')]
        if kwargs.get('src_uplink_port_name_tx') is not None:
            vport.uplinkPortName = [kwargs.get('src_uplink_port_name_tx')]
        if kwargs.get('src_vlans_tx') is not None:
            vport.vlans = [kwargs.get('src_vlans_tx')]
        return vport

    def get_ldp_config_spec(self, **kwargs):
        ldp = vim.host.LinkDiscoveryProtocolConfig()
        ldp.operation = kwargs.get('mode')
        ldp.protocol = kwargs.get('protocol')
        return ldp

    def get_ipfix_config(self, **kwargs):
        ipfix = vim.dvs.VmwareDistributedVirtualSwitch.IpfixConfig()
        ipfix.activeFlowTimeout = kwargs.get('active_flow_timeout')
        if kwargs.get('collector_ip') is not None:
            ipfix.collectorIpAddress = kwargs.get('collector_ip')
        if kwargs.get('collector_port') is not None:
            ipfix.collectorPort = kwargs.get('collector_port')
        ipfix.idleFlowTimeout = kwargs.get('idle_flow_timeout')
        ipfix.internalFlowsOnly = kwargs.get('internal_flows_only')
        if kwargs.get('observationDomainId') is not None:
            ipfix.observationDomainId = kwargs.get('observation_domain_id')
        ipfix.samplingRate = kwargs.get('sampling_rate')
        return ipfix

    def get_pvlan_config_spec(self, **kwargs):
        pvlan = vim.dvs.VmwareDistributedVirtualSwitch.PvlanConfigSpec()
        pvlan.operation = kwargs.get('operation')
        pvlan_entry = vim.dvs.VmwareDistributedVirtualSwitch.PvlanMapEntry()
        pvlan_entry.primaryVlanId = kwargs.get('primary_vlan_id')
        pvlan_entry.secondaryVlanId = kwargs.get('secondary_vlan_id')
        pvlan_entry.pvlanType = kwargs.get('pvlan_type')
        pvlan.pvlanEntry = pvlan_entry
        return [pvlan]

    def get_host_member_config(self, **kwargs):
        config = vim.dvs.HostMember.ConfigSpec()
        if kwargs.get('host_mor') is not None:
            config.host = kwargs.get('host_mor')
        if kwargs.get('maxports') is not None:
            config.maxProxySwitchPorts = kwargs.get('maxports')
        if kwargs.get('operation') is not None:
            config.operation = kwargs.get('operation')
        elif kwargs.get('operation') is None:
            config.operation = 'edit'
        if kwargs.get('backing') is not None:
            config.backing = kwargs.get('backing')
        return config

    def get_dvs_config_spec(self, **kwargs):
        dvs = vim.DistributedVirtualSwitch.ConfigSpec()
        return dvs

    def get_dvs_failure_criteria(self, **kwargs):
        failure = vim.dvs.VmwareDistributedVirtualSwitch.FailureCriteria()
        bool_policy_1 = vim.BoolPolicy()
        bool_policy_2 = vim.BoolPolicy()
        bool_policy_1.value = kwargs.get('check_beacon')
        if kwargs.get('check_beacon') is not None:
            failure.checkBeacon = bool_policy_1
        bool_policy_2.value = kwargs.get('check_duplex')
        if kwargs.get('check_duplex') is not None:
            failure.checkDuplex = bool_policy_2
        return failure

    def get_notify_switches(self, value):
        bool_policy = vim.BoolPolicy()
        if value is not None:
            bool_policy.value = value
        return bool_policy

    def get_uplink_port_policy(self, policy):
        string_policy = vim.StringPolicy()
        if policy is not None:
            string_policy.value = policy
        return string_policy

    def get_reverse_policy(self, reverse_policy):
        bool_policy = vim.BoolPolicy()
        if reverse_policy is not None:
            bool_policy.value = reverse_policy
        return bool_policy

    def get_rolling_policy(self, rolling_order):
        bool_policy = vim.BoolPolicy()
        if rolling_order is not None:
            bool_policy.value = rolling_order
        return bool_policy

    def get_vmware_uplink_port_order_policy(self, **kwargs):
        policy = vim.dvs.VmwareDistributedVirtualSwitch.UplinkPortOrderPolicy()
        if kwargs.get('active_uplink_port') is not None:
            policy.activeUplinkPort = kwargs.get('active_uplink_port')
        if kwargs.get('standby_uplink_port') is not None:
            policy.standbyUplinkPort = kwargs.get('standby_uplink_port')
        return policy

    def get_vmware_port_config_policy(self):
        policy = vim.dvs.VmwareDistributedVirtualSwitch.VmwarePortConfigPolicy()
        return policy

    def get_uplink_port_teaming_policy(self, **kwargs):
        teaming = vim.dvs.VmwareDistributedVirtualSwitch.UplinkPortTeamingPolicy()
        teaming.failureCriteria = kwargs.get('failure')
        teaming.notifySwitches = kwargs.get('notify')
        teaming.policy = kwargs.get('policy')
        teaming.reversePolicy = kwargs.get('reverse')
        teaming.rollingOrder = kwargs.get('rolling')
        teaming.uplinkPortOrder = kwargs.get('uplink_port_order')
        return teaming

    def get_dvs_host_pnic_spec(self, **kwargs):
        spec = vim.dvs.HostMember.PnicSpec()
        spec.pnicDevice = kwargs.get('pnic')
        if kwargs.get('uplink_portgroup') is not None:
            spec.uplinkPortgroupKey = kwargs.get('uplink_portgroup')
        if kwargs.get('uplink_port') is not None:
            spec.uplinkPortKey = kwargs.get('uplink_port')
        return [spec]

    def get_dvs_host_pnic_backing(self, spec):
        backing = vim.dvs.HostMember.PnicBacking()
        backing.pnicSpec = spec
        return backing
