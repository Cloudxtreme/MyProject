# Copyright (C) 2014 VMware, Inc. All rights reserved.
""" LogicalRouterSchema for cli output from ESX net-vdr command """
import vmware.common.base_schema_v2 as base_schema_v2


class LogicalRouterPortEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for Port entries in Logical Router (DR) Table

    >>> import pprint
    >>> py_dict = {'lrport_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061',
    ...            'mode': 'routing,distributed,uplink',
    ...            'overlay_net_id': 'overlay:5401',
    ...            'ip_address': '192.168.1.1',
    ...            'macaddress' : '00:0a:bb:cc:9e:ff',
    ...            'connected_switch': 'dvswitch0',
    ...            'vxlan_control_plane_status': 'disabled',
    ...            'multicast_ip': '239.0.0.1',
    ...            'port_state': 'enabled',
    ...            'flags': '0x200a',
    ...            'dhcp_relay_servers': '192.168.9.4'}
    >>> pyobj = LogicalRouterPortEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'connected_switch': 'dvswitch0',
     'dhcp_relay_servers': '192.168.9.4',
     'flags': '0x200a',
     'ip_address': '192.168.1.1',
     'macaddress': '00:0a:bb:cc:9e:ff',
     'mode': 'routing,distributed,uplink',
     'multicast_ip': '239.0.0.1',
     'overlay_net_id': 'overlay:5401',
     'lrport_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061',
     'port_state': 'enabled',
     'vxlan_control_plane_status': 'disabled'}
    """
    connected_switch = None
    vxlan_control_plane_status = None
    dhcp_relay_servers = None
    flags = None
    ip_address = None
    macaddress = None
    mode = None
    multicast_ip = None
    overlay_net_id = None
    lrport_uuid = None
    port_state = None


class LogicalRouterPortSchema(base_schema_v2.BaseSchema):
    """
    Schema class for Logical Router Ports

    >>> import pprint
    >>> py_dict = {'table': [{
    ...     'lrport_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061',
    ...     'mode': 'routing,distributed,uplink',
    ...     'overlay_net_id': 'overlay:5401',
    ...     'ip_address': '192.168.1.1',
    ...     'macaddress' : '00:0a:bb:cc:9e:ff',
    ...     'connected_switch': 'dvswitch0',
    ...     'vxlan_control_plane_status': 'disabled',
    ...     'multicast_ip': '239.0.0.1',
    ...     'port_state': 'enabled',
    ...     'flags': '0x200a',
    ...     'dhcp_relay_servers': '192.168.9.4'}]}
    >>> pyobj = LogicalRouterPortSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'connected_switch': 'dvswitch0',
                'dhcp_relay_servers': '192.168.9.4',
                'flags': '0x200a',
                'ip_address': '192.168.1.1',
                'macaddress': '00:0a:bb:cc:9e:ff',
                'mode': 'routing,distributed,uplink',
                'multicast_ip': '239.0.0.1',
                'overlay_net_id': 'overlay:5401',
                'lrport_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061',
                'port_state': 'enabled',
                'vxlan_control_plane_status': 'disabled'}]}
    """
    table = (LogicalRouterPortEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
