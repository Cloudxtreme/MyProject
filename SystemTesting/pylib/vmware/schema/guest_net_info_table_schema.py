import vmware.common.base_schema_v2 as base_schema_v2


class GuestNetInfoTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in GuestNetInfo table.

    >>> import pprint
    >>> py_dict = {'ipv4_array': ['10.144.139.23'],
    ...            'network': 'VM Network',
    ...            'ipv6_array': ['fe80::20c:29ff:feec:5e36'],
    ...            'mac': '00:0c:29:ec:5e:36',
    ...            'device_label': 'Network adapter 2'}
    >>> pprint.pprint(GuestNetInfoTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'device_label': 'Network adapter 2',
     'ipv4_array': ['10.144.139.23'],
     'ipv6_array': ['fe80::20c:29ff:feec:5e36'],
     'mac': '00:0c:29:ec:5e:36',
     'network': 'VM Network'}

    """
    device_label = None
    mac = None
    ipv4_array = None
    ipv6_array = None
    network = None
    portgroup = None
    adapter_class = None


class GuestNetInfoTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for GuestNetInfo Table.

    >>> import pprint
    >>> py_dict = {
    ...             'table': [{'ipv4_array': ['10.144.139.23'],
    ...             'network': 'VM Network',
    ...             'ipv6_array': ['fe80::20c:29ff:feec:5e36'],
    ...             'mac': '00:0c:29:ec:5e:36',
    ...             'device_label': 'Network adapter 2'}]}
    >>>
    >>> pprint.pprint(GuestNetInfoTableSchema(
    ...             py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'device_label': 'Network adapter 2',
                'ipv4_array': ['10.144.139.23'],
                'ipv6_array': ['fe80::20c:29ff:feec:5e36'],
                'mac': '00:0c:29:ec:5e:36',
                'network': 'VM Network'}]}

    """
    table = (GuestNetInfoTableEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
