# Copyright (C) 2014 VMware, Inc. All rights reserved.
""" RouteTableSchema for cli output from ESX net-vdr command """
import vmware.common.base_schema_v2 as base_schema_v2


class RouteTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for routing table entries in Logical Router (DR)
    route table.

    >>> import pprint
    >>> py_dict = {'destination': '192.168.1.0',
    ...            'mask': '255.255.255.0',
    ...            'next_hop': '0.0.0.0',
    ...            'dr_flags': 'UCI',
    ...            'dr_ref' : '1',
    ...            'origin': 'MANUAL',
    ...            'route_uptime': '1976',
    ...            'egress_iface': '4e8ecc7d-2e0b-44'}
    >>> pyobj = RouteTableEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'destination': '192.168.1.0',
     'mask': '255.255.255.0',
     'next_hop': '0.0.0.0',
     'dr_flags': 'UCI',
     'dr_ref' : '1',
     'origin': 'MANUAL',
     'route_uptime': '1976',
     'egress_iface': '4e8ecc7d-2e0b-44'}
    """
    destination = None
    mask = None
    next_hop = None
    dr_flags = None
    dr_ref = None
    origin = None
    route_uptime = None
    egress_iface = None


class RouteTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for routing table of a Logical Router.

    >>> import pprint
    >>> py_dict = {'table': [{'destination': '192.168.1.0',
    ...                       'mask': '255.255.255.0',
    ...                       'next_hop': '0.0.0.0',
    ...                       'dr_flags': 'UCI',
    ...                       'dr_ref' : '1',
    ...                       'origin': 'MANUAL',
    ...                       'route_uptime': '1976',
    ...                       'egress_iface': '4e8ecc7d-2e0b-44'}]}
    >>> pyobj = RouteTableSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'destination': '192.168.1.0',
                'mask': '255.255.255.0',
                'next_hop': '0.0.0.0',
                'dr_flags': 'UCI',
                'dr_ref' : '1',
                'origin': 'MANUAL',
                'route_uptime': '1976',
                'egress_iface': '4e8ecc7d-2e0b-44'}]}
    """
    table = (RouteTableEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
