import vmware.common.base_schema as base_schema


class ARPTableSchema(base_schema.BaseSchema):
    """
    Schema class for ARP Table.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'connection-id': '1',
    ...                'adapter_ip': '192.168.139.11',
    ...                'adapter_mac': '00:50:56:b2:30:6e',
    ...                'vni': '6796'},
    ...                {'connection-id': '2',
    ...                'adapter_ip': '192.168.138.131',
    ...                 'adapter_mac': '00:50:56:b2:40:33',
    ...                 'vni': '6796'},
    ...                {'connection-id': '3',
    ...                 'adapter_ip': '192.168.139.201',
    ...                 'adapter_mac': '00:50:56:b2:75:d1',
    ...                 'vni': '6796'}]}
    >>> pprint.pprint(ARPTableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'adapter_ip': '192.168.139.11',
                'adapter_mac': '00:50:56:b2:30:6e'},
               {'adapter_ip': '192.168.138.131',
                'adapter_mac': '00:50:56:b2:40:33'},
               {'adapter_ip': '192.168.139.201',
                'adapter_mac': '00:50:56:b2:75:d1'}]}
    """
    _schema_name = "ARPTableSchema"

    def __init__(self, py_dict=None):
        super(ARPTableSchema, self).__init__()
        self.table = [ARPTableEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class ARPTableEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in ARP table.

    >>> import pprint
    >>> py_dict = {'adapter_ip': '192.168.139.11',
    ...            'adapter_mac': '00:50:56:b2:30:6e',
    ...            'connection_id': '1', 'vni': '6796'}
    >>> pprint.pprint(ARPTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object(), width=78)
    {'adapter_ip': '192.168.139.11', 'adapter_mac': '00:50:56:b2:30:6e'}
    """
    _schema_name = "ARPTableEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the ARPTableEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for an ARP table
            entry as key-value.
        """
        super(ARPTableEntrySchema, self).__init__()
        self.adapter_ip = None
        self.adapter_mac = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
