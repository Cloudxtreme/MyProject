# Copyright (C) 2014 VMware, Inc. All rights reserved.
""" ArpTableSchema for cli output from ESX net-vdr command """
import vmware.common.base_schema_v2 as base_schema_v2


class ArpTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for arp table entries in Logical Router (DR) route table.

    >>> import pprint
    >>> py_dict = {'ip': '192.168.1.1',
    ...            'mac': '255.255.255.0',
    ...            'dr_flags': 'VI',
    ...            'expiry': 'permanent',
    ...            'srcport': '0',
    ...            'refcnt': '1',
    ...            'logical_router_port_id': '4fd0-9f36-2fbecb9b5016'}
    >>> pyobj = ArpTableEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'dr_flags': 'VI',
     'expiry': 'permanent',
     'ip': '192.168.1.1',
     'logical_router_port_id': '4fd0-9f36-2fbecb9b5016',
     'mac': '255.255.255.0',
     'refcnt': '1',
     'srcport': '0'}
    """
    ip = None
    mac = None
    dr_flags = None
    expiry = None
    srcport = None
    refcnt = None
    logical_router_port_id = None


class ArpTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for arp table of a Logical Router.

    >>> import pprint
    >>> py_dict = {'table': [{'ip': '192.168.1.1',
    ...                       'mac': '255.255.255.0',
    ...                       'dr_flags': 'VI',
    ...                       'expiry': 'permanent',
    ...                       'srcport': '0',
    ...                       'refcnt': '1',
    ...                       'logical_router_port_id': '9f36-2fbecb9b5016'}]}
    >>> pyobj = ArpTableSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'dr_flags': 'VI',
                'expiry': 'permanent',
                'ip': '192.168.1.1',
                'logical_router_port_id': '9f36-2fbecb9b5016',
                'mac': '255.255.255.0',
                'refcnt': '1',
                'srcport': '0'}]}
    """
    table = (ArpTableEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
