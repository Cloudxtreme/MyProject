import vmware.interfaces.adapter_interface as adapter_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def add_virtual_interface(cls, client_object, hostname=None, ip=None,
                              netmask=None, dhcp=None, port_key=None,
                              mac=None, mtu=None, opaque_network_id=None,
                              opaque_network_type=None):
        """
        Adds a virtual interface to the portgroup.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type ip: str
        @param ip: IP address of the virtual interface
        @type netmask: str
        @param netmask: Subnet mask for the interface
        @type dhcp: bool
        @param dhcp: Flag to specify if DHCP is enabled
        @type port_key: str
        @param port_key: Key of the dvport
        @type mac: str
        @param mac: MAC of the virtual interface
        @type mtu: int
        @param mtu: Packet size in bytes for the virtual interface
        @type opaque_network_id: str
        @param opaque_network_id: ID of opaque network to which vnic is
            connected
        @type opaque_network_type: str
        @param opaque_network_type: Type of opaque network

        @rtype: str
        @return: Name of the virtual interface
        """
        portgroup_key = client_object.dvpg_key
        switch_uuid = client_object.parent.uuid
        host_mor = None
        vds_mor = client_object.parent.vds_mor
        for member in vds_mor.config.host:
            if member.config.host.name in hostname:
                host_mor = member.config.host
            else:
                host_mor = None
            if host_mor is None:
                raise Exception("Host not found on %s" % (client_object.name))
        network_sys = host_mor.configManager.networkSystem
        dvport_spec = client_object.get_dvs_port_connection(
            portgroup_key=portgroup_key, port_key=port_key,
            switch_uuid=switch_uuid
            opaque_network_id=opaque_network_id,
            opaque_network_type=opaque_network_type)
        ip_config = client_object.get_ip_config(
            ip=ip, netmask=netmask, dhcp=dhcp)
        vnic_spec = client_object.get_vnic_spec(
            dvport_spec=dvport_spec,
            ip_config=ip_config, mac=mac, mtu=mtu)
        try:
            return network_sys.AddVirtualNic("", vnic_spec)
        except Exception as e:
            raise Exception("Could not add virtual interface", e)
