import pprint

import vmware.interfaces.crud_interface as crud_interface
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class ESX55CRUDImpl(crud_interface.CRUDInterface):
    """Adapter related operations."""

    @classmethod
    def create(cls, client_object, **schema_object):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")

    @classmethod
    def read(cls, client_object, **schema_object):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")

    @classmethod
    def update(cls, client_object, connection_cookie=None,
               portgroup_key=None, port_key=None, switch_uuid=None,
               external_id=None, ip=None, mac=None, mtu=None,
               net_stack_instance_key=None, opaque_network_id=None,
               opaque_network_type=None, pinned_pnic=None,
               portgroup=None, tso=None, dhcp=None, subnet_mask=None):
        """
        Updates the vmknic using the specified schema.

        @type client_object: client instance
        @param client_object: vmknic client instance

        @type schema_dict: dict
        @param schema_dict: vmknic_schema dict that holds key-value
            pairs for vim.host.VirtualNic.Specification object

        @rype: NoneType
        @return: None
        """
        vns = vim.host.VirtualNic.Specification()

        if switch_uuid is not None:
            dvpc = vim.dvs.PortConnection()
            if connection_cookie is not None:
                dvpc.connectionCookie = connection_cookie
            if portgroup_key is not None:
                dvpc.portgroupKey = portgroup_key
            if port_key is not None:
                dvpc.portKey = port_key
            dvpc.switchUuid = switch_uuid
            vns.distributedVirtualPort = dvpc

        if opaque_network_id is not None:
            ons = vim.host.VirtualNic.OpaqueNetworkSpec()
            ons.opaqueNetworkId = opaque_network_id
            ons.opaqueNetworkType = opaque_network_type
            vns.opaqueNetwork = ons

        if dhcp is not None:
            ips = vim.host.IpConfig()
            ips.dhcp = dhcp
            if dhcp is False:
                ips.ipAddress = ip
                ips.subnetMask = subnet_mask
            vns.ip = ips

        if external_id is not None:
            vns.externalId = external_id
        if mac is not None:
            vns.mac = mac
        if mtu is not None:
            vns.mtu = mtu
        if net_stack_instance_key is not None:
            vns.netStackInstanceKey = net_stack_instance_key
        if pinned_pnic is not None:
            vns.pinnedPnic = pinned_pnic
        if portgroup is not None:
            vns.portgroup = portgroup
        if tso is not None:
            vns.tsoEnabled = tso

        network_sys = client_object.parent.get_network_system()

        try:
            network_sys.UpdateVirtualNic(client_object.name, vns)
            network_sys.RefreshNetworkSystem()

        except Exception as e:
            pylogger.error("Could not update %s on host: %r"
                           % (client_object.name, e))
            raise

        pylogger.info("Updated properties on %s" % client_object.name)
        pylogger.debug("VirtualNic spec updated to %s"
                       % pprint.pformat(vns.__dict__))

    @classmethod
    def delete(cls, client_object, **schema_object):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")
