import vmware.interfaces.network_interface as network_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger

INBOUND = "inbound"
OUTBOUND = "outbound"


class VC55NetworkImpl(network_interface.NetworkInterface):

    @classmethod
    def edit_security_policy(cls, client_object, forged_transmits=None,
                             allow_promiscuous=None, mac_changes=None):

        """
        Edits the security policy of the DVPortgroup

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type forged_transmits: bool
        @param forged_transmits: The flag to indicate whether or not the
            virtual network adapter should be allowed to send network
            traffic with a different MAC address than that of the
            virtual network adapter.
        @type allow_promiscuous: bool
        @param allow_promiscuous: The flag to indicate whether or not all
            traffic is seen on the port
        @type mac_changes: bool
        @param mac_changes: The flag to indicate whether or not the
            Media Access Control (MAC) address can be changed.

        @rtype: str
        @return: Status of the operation
        """
        dvpg_mor = client_object.dvpg_mor
        dvpg_port_config = dvpg_mor.config.defaultPortConfig
        dvpg_port_config.securityPolicy = client_object.get_security_policy(
            forged_transmits=forged_transmits, mac_changes=mac_changes,
            allow_promiscuous=allow_promiscuous)
        dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        dvpg_config.defaultPortConfig = dvpg_port_config
        dvpg_config.configVersion = dvpg_mor.config.configVersion
        try:
            task = dvpg_mor.ReconfigureDVPortgroup_Task(dvpg_config)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not edit security policy", e)

    @classmethod
    def set_access_vlan(cls, client_object, vlan=None):
        """
        Sets an access vlan on the portgroup.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type vlan: int
        @param vlan: The VLAN ID for ports. Possible values:
            A value of 0 specifies that you do not want the port
                associated with a VLAN.
            A value from 1 to 4094 specifies a VLAN ID for the port.

        @rtype: str
        @return: Status of the operation
        """
        dvpg_mor = client_object.dvpg_mor
        dvpg_port_config = dvpg_mor.config.defaultPortConfig
        vlan_spec = vim.dvs.VmwareDistributedVirtualSwitch.VlanIdSpec()
        vlan_spec.vlanId = vlan
        dvpg_port_config.vlan = vlan_spec
        dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        dvpg_config.defaultPortConfig = dvpg_port_config
        dvpg_config.configVersion = dvpg_mor.config.configVersion
        try:
            task = dvpg_mor.ReconfigureDVPortgroup_Task(dvpg_config)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not set access vlan", e)

    @classmethod
    def set_private_vlan(cls, client_object, vlan=None):
        """
        Sets a private vlan on the portgroup.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type vlan: int
        @param vlan: The VLAN ID for ports. Possible values:
            A value of 0 specifies that you do not want the port
                associated with a VLAN.
            A value from 1 to 4094 specifies a VLAN ID for the port.

        @rtype: str
        @return: Status of the operation
        """
        dvpg_mor = client_object.dvpg_mor
        dvpg_port_config = dvpg_mor.config.defaultPortConfig
        vlan_spec = vim.dvs.VmwareDistributedVirtualSwitch.PvlanSpec()
        vlan_spec.pvlanId = vlan
        dvpg_port_config.vlan = vlan_spec
        dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        dvpg_config.defaultPortConfig = dvpg_port_config
        dvpg_config.configVersion = dvpg_mor.config.configVersion
        try:
            task = dvpg_mor.ReconfigureDVPortgroup_Task(dvpg_config)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not set private vlan", e)

    @classmethod
    def set_vlan_trunking(cls, client_object, vlan_start=None, vlan_end=None):
        """
        Sets vlan trunking on the portgroup.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type vlan_start: int
        @param vlan_start: Starting vlan ID
        @type vlan_end: int
        @param vlan_end: Ending vlan ID

        @rtype: str
        @return: Status of the operation
        """
        dvpg_mor = client_object.dvpg_mor
        dvpg_port_config = dvpg_mor.config.defaultPortConfig
        vlan_spec = vim.dvs.VmwareDistributedVirtualSwitch.TrunkVlanSpec()
        num_range = vim.NumericRange()
        num_range.start = vlan_start
        num_range.end = vlan_end
        vlan_spec.vlanId = [num_range]
        dvpg_port_config.vlan = vlan_spec
        dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        dvpg_config.defaultPortConfig = dvpg_port_config
        dvpg_config.configVersion = dvpg_mor.config.configVersion
        try:
            task = dvpg_mor.ReconfigureDVPortgroup_Task(dvpg_config)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not set vlan trunking, e")

    @classmethod
    def edit_traffic_shaping(cls, client_object, avg_bandwidth=None,
                             burst_size=None, enabled=None,
                             peak_bandwidth=None, mode=None):
        """
        Edits the traffic shaping policy.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type avg_bandwidth: long
        @param avg_bandwidth: The average bandwidth in bits per second if
            shaping is enabled on the port.
        @type burst_size: long
        @param burst_size: The maximum burst size allowed in bytes if
            shaping is enabled on the port.
        @type enabled: bool
        @param enabled: The flag to indicate whether or not traffic
            shaper is enabled on the port.
        @type peak_bandwidth: long
        @param peak_bandwidth: The peak bandwidth during bursts in bits
            per second if traffic shaping is enabled on the port.
        @type mode: str
        @param mode: inbound or  ourbound
        @rtype: str
        @return: Status of the operation
        """
        dvpg_mor = client_object.dvpg_mor
        dvpg_port_config = dvpg_mor.config.defaultPortConfig
        shaping_policy = client_object.get_traffic_shaping_policy(
            avg_bandwidth=avg_bandwidth, burst_size=burst_size,
            enabled=enabled, peak_bandwidth=peak_bandwidth, mode=mode)
        if mode == INBOUND:
            dvpg_port_config.inShapingPolicy = shaping_policy
        if mode == OUTBOUND:
            dvpg_port_config.outShapingPolicy = shaping_policy
        dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
        dvpg_config.defaultPortConfig = dvpg_port_config
        dvpg_config.configVersion = dvpg_mor.config.configVersion
        try:
            task = dvpg_mor.ReconfigureDVPortgroup_Task(dvpg_config)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not edit traffic shaping policy", e)

    @classmethod
    def migrate_network(cls, client_object, hostname=None, vnic=None,
                        portgroup=None, port_key=None, src=None, dst=None):
        """
        Migrates network from src switch to dst switch.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type vnic: str
        @param vnic: Device ID of vnic
        @type portgroup: str
        @param portgroup: Portgroup name (needed if dst is vss) 
        @type port_key: str
        @param port_key: Key of the port (needed if dst is vds)
        @type src: str
        @param src: "vss" or "vds"
        @type dst: str
        @param dst: "vss" or "vds"

        @rtype: NoneType
        @return: None
        """
        host_mor = None
        vds_mor = client_object.parent.vds_mor
        for member in vds_mor.config.host:
            if member.config.host.name == hostname:
                host_mor = member.config.host
            else:
                host_mor = None
            if host_mor is None:
                raise Exception("Host not found on %s" % (client_object.name))
        network_sys = host_mor.configManager.networkSystem
        if src == 'vss' and dst == 'vds':
            dvs_port_config = client_object.get_dvs_port_connection(
                portgroup_key=client_object.dvpg_key,
                port_key=port_key, switch_uuid=client_object.parent.uuid)
            nic_spec = vim.host.VirtualNic.Specification()
            nic_spec.distributedVirtualPort = dvs_port_config
            for virtual_nic in network_sys.networkInfo.vnic:
                if virtual_nic.device == vnic:
                    try:
                        network_sys.UpdateVirtualNic(vnic, nic_spec)
                        return
                    except Exception as e:
                        raise Exception("Could not migrate management network", e)
            pylogger.error("Could not find virtual nic on the specified host")
        elif src == 'vds' and dst == 'vss':
            nic_spec = vim.host.VirtualNic.Specification()
            nic_spec.portgroup = portgroup
            try:
                network_sys.UpdateVirtualNic(vnic, nic_spec)
                return
            except Exception as e:
                raise Exception("Could not migrate network to legacy switch", e)
        else:
            pylogger.error("src and dst networks have to be vss or vds")
