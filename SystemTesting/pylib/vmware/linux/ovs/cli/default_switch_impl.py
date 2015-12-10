import collections

import vmware.common.utilities as utilities
import vmware.interfaces.switch_interface as switch_interface
import vmware.linux.ovs.ovs_helper as ovs_helper

OVS = ovs_helper.OVS


class DefaultSwitchImpl(switch_interface.SwitchInterface):

    @classmethod
    def configure_uplinks(cls, client_object, uplinks=None):
        raise NotImplementedError

    @classmethod
    def get_ports(cls, client_object):
        """
        Fetches all the ports on the switch along with attachment information
        for each port.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @rtype: dict
        @return: Returns dict of dicts  where the outer dict contains the
            port names as keys and the inner dict holds information for the
            uuid and the inner most dict has information about the uuid of each
            interface attached to the port keyed by interface name.
        """
        ret = collections.defaultdict(
            lambda: collections.defaultdict(dict))
        bridge = client_object.ovsdb.Bridge.get_one(search='name=%s' %
                                                    client_object.name)
        ports = client_object.ovsdb.Port.get_all()
        interfaces = client_object.ovsdb.Interface.get_all()
        port_uuids = utilities.as_list(bridge.ports)
        for port_uuid in port_uuids:
            for port in ports:
                if port.uuid == port_uuid:
                    ret[port.name]['uuid'] = port_uuid
                    port_iface_uuids = utilities.as_list(port.interfaces)
                    for port_iface_uuid in port_iface_uuids:
                        for iface in interfaces:
                            if iface.uuid == port_iface_uuid:
                                ret[port.name]['interfaces'][iface.name] = (
                                    iface.uuid)
        return ret

    @classmethod
    def set_external_bridge_id(cls, client_object, id_=None):
        """
        Sets the external bridge id to the provided value.
        """
        cmd = OVS.set_external_id(table='bridge', record=client_object.name,
                                  key='bridge-id', value=id_)
        return client_object.connection.request(cmd)

    @classmethod
    def _get_port_name_from_remote_ip(cls, client_object, ip_address=None):
        """
        Helper to get the ports that have remote end points set as the ip
        address passed in.
        """
        get_port_cmd = OVS.find_columns_in_table(
            OVS.INTERFACE, OVS.NAME, OVS.OPTIONS, ip_address,
            key=OVS.REMOTE_IP)
        data = client_object.connection.request(get_port_cmd).response_data
        matched_ports = []
        for port_record in data.splitlines():
            _, port = port_record.split(':')
            matched_ports.append(port.strip())
        return matched_ports

    @classmethod
    def set_port_mtu(cls, client_object, ip_address=None, value=None,
                     adapter_name=None):
        """
        Sets the MTU on the provided OVS port as specified by the interface or
        the remote ip address of the remote host.
        """
        if adapter_name:
            set_mtu_cmd = OVS.set_column_of_record(OVS.INTERFACE, adapter_name,
                                                   OVS.MTU, value)
            client_object.connection.request(set_mtu_cmd)
        if ip_address:
            tunnel_ports = utilities.as_list(
                cls._get_port_name_from_remote_ip(
                    client_object, ip_address=ip_address))
            for port in tunnel_ports:
                set_mtu_cmd = OVS.set_column_of_record(
                    OVS.INTERFACE, port, OVS.MTU, value)
                client_object.connection.request(set_mtu_cmd)
