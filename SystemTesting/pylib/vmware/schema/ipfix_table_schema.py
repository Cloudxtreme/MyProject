import vmware.common.base_schema_v2 as base_schema_v2


class IPFIXTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in net-dvs/ovs-vsctl list ipfix output.

    >>> import pprint
    >>> py_dict = {'internal flows only': 'false',
    ...            'com.vmware.common.alias': 'xxx ,  proptype = config',
    ...            'packet_sample_probability': '1',
    ...            'idle_timeout': '60 seconds',
    ...            'flow_timeout': '60 seconds',
    ...            'collector': '127.0.2.121:80'}
    >>> pprint.pprint(IPFIXTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    2014-12-08 13:22:27 WARNING  Attribute max_flows not found or is None, Defaulting to class value  # noqa
    2014-12-08 13:22:27 WARNING  Attribute domain_id not found or is None, Defaulting to class value  # noqa
    {'collector': '127.0.2.121:80',
     'domain_id': None,
     'flow_timeout': '60 seconds',
     'idle_timeout': '60 seconds',
     'max_flows': None,
     'packet_sample_probability': '1'}
    """
    idle_timeout = None
    flow_timeout = None
    packet_sample_probability = None
    collector = None
    max_flows = None
    domain_id = None
    ip_address = None
    port = None


class IPFIXTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for IPFIX configuration.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'com.vmware.common.alias': 'xxx ,  proptype = config',
    ...                'idle_timeout': '60 seconds',
    ...                'internal flows only': 'false',
    ...                'packet_sample_probability': '1',
    ...                'flow_timeout': '60 seconds',
    ...                'collector': '127.0.2.121:80'
    ...               }]
    ...            }
    >>> pprint.pprint(IPFIXTableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    2014-12-08 13:26:38 WARNING  Attribute max_flows not found or is None, Defaulting to class value  # noqa
    2014-12-08 13:26:38 WARNING  Attribute domain_id not found or is None, Defaulting to class value  # noqa
    {'table': [{'collector': '127.0.2.121:80',
                'domain_id': None,
                'flow_timeout': '60 seconds',
                'idle_timeout': '60 seconds',
                'max_flows': None,
                'packet_sample_probability': '1'}]}
    """
    table = (IPFIXTableEntrySchema,)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
