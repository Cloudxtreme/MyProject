# Copyright (C) 2014 VMware, Inc. All rights reserved.
""" LogicalRouterSchema for cli output from ESX net-vdr command """
import vmware.common.base_schema_v2 as base_schema_v2


class LogicalRouterEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in Logical Router (DR) Table

    >>> import pprint
    >>> py_dict = {'lr_uuid': 'dc5d028a-0677-4f90-8bf2-846da0206130',
    ...            'vdr_id': '1438272149',
    ...            'number_of_ports': '2',
    ...            'number_of_routes': '2',
    ...            'lr_state' : 'enabled'}
    ...            'controller_ip': '10.10.10.10',
    ...            'control_plane_ip': '10.10.10.10',
    ...            'control_plane_active': 'yes',
    ...            'num_unique_nexthops': '0',
    ...            'generation_number': '0',
    ...            'edge_active': 'no'}
    >>> pyobj = LogicalRouterEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'control_plane_active': None,
     'control_plane_ip': None,
     'controller_ip': None,
     'edge_active': None,
     'generation_number': None,
     'lr_hosts': None,
     'lr_state': 'enabled',
     'num_unique_nexthops': None,
     'number_of_ports': '2',
     'number_of_routes': '2',
     'vdr_id': '1438272149',
     'lr_uuid': 'dc5d028a-0677-4f90-8bf2-846da0206130'}
    >>> py_dict = {'lr_uuid': 'foo',
    ...            'num_unique_nexthops': '0',
    ...            'generation_number': '0',
    ...            'edge_active': 'no'}
    >>> pyobj = LogicalRouterEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'control_plane_active': None,
     'control_plane_ip': None,
     'controller_ip': None,
     'edge_active': 'no',
     'generation_number': '0',
     'lr_hosts': None,
     'lr_state': None,
     'num_unique_nexthops': '0',
     'number_of_ports': None,
     'number_of_routes': None,
     'vdr_id': None,
     'lr_uuid': 'foo'}
    """
    lr_uuid = None
    vdr_id = None
    lr_hosts = None
    number_of_routes = None
    number_of_ports = None
    lr_state = None
    controller_ip = None
    control_plane_ip = None
    control_plane_active = None
    num_unique_nexthops = None
    generation_number = None
    edge_active = None


class LogicalRouterSchema(base_schema_v2.BaseSchema):
    """
    Schema class for Logical Routers

    >>> import pprint
    >>> py_dict = {'table': [{'lr_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061',
    ...                       'vdr_id': '1438272149',
    ...                       'number_of_ports': '2',
    ...                       'number_of_routes': '2',
    ...                       'lr_state' : 'enabled',
    ...                       'controller_ip': '10.10.10.10',
    ...                       'control_plane_ip': '10.10.10.10',
    ...                       'control_plane_active': 'yes',
    ...                       'num_unique_nexthops': '0',
    ...                       'generation_number': '0',
    ...                       'edge_active': 'no'}]}
    >>> pyobj = LogicalRouterSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'control_plane_active': 'yes',
                'control_plane_ip': '10.10.10.10',
                'controller_ip': '10.10.10.10',
                'edge_active': 'no',
                'generation_number': '0',
                'lr_hosts': None,
                'lr_state': 'enabled',
                'num_unique_nexthops': '0',
                'number_of_ports': '2',
                'number_of_routes': '2',
                'vdr_id': '1438272149',
                'lr_uuid': 'dc5d028a-0677-4f90-8bf2-846da02061'}]}
    >>> for py_dict in (None, {}, {'table': []}):
    ...    pyobj = LogicalRouterSchema(py_dict=py_dict)
    ...    pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': []}
    {'table': []}
    {'table': []}
    >>> for py_dict in ({'table': {}},):
    ...    pyobj = LogicalRouterSchema(py_dict=py_dict)
    Traceback (most recent call last):
    ...
    RuntimeError: LogicalRouterSchema: Invalid value={} for attr=table
    """
    table = (LogicalRouterEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
