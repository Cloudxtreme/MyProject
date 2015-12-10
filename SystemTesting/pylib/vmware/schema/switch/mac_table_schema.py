import vmware.common.base_schema as base_schema


class MACTableSchema(base_schema.BaseSchema):
    """
    Schema class for MAC Table.

    >>> import pprint
    >>> py_dict = {
    ...      'table': [{'adapter_mac': 'aa:aa:aa:bb:bb:cc',
    ...                 'adapter_ip': '192.168.1.2'},
    ...                {'adapter_mac': 'aa:ac:aa:bf:bb:cc',
    ...                 'adapter_ip': '192.168.1.4'}]}
    >>> pprint.pprint(MACTableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object(), width=60)
    {'table': [{'adapter_ip': '192.168.1.2',
                'adapter_mac': 'aa:aa:aa:bb:bb:cc'},
               {'adapter_ip': '192.168.1.4',
                'adapter_mac': 'aa:ac:aa:bf:bb:cc'}]}
    """
    _schema_name = "MACTableSchema"

    def __init__(self, py_dict=None):
        super(MACTableSchema, self).__init__()
        self.table = [MACTableEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class MACTableEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in MAC table.

    >>> import pprint
    >>> py_dict = {'adapter_mac': 'aa:aa:aa:bb:bb:cc',
    ...            'adapter_ip': '192.168.1.2'}
    >>> pprint.pprint(MACTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'adapter_ip': '192.168.1.2', 'adapter_mac': 'aa:aa:aa:bb:bb:cc'}
    """
    _schema_name = "MACTableEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the MACTableEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for a MAC table
            entry as key-value.
        """
        super(MACTableEntrySchema, self).__init__()
        self.adapter_mac = None
        # in vdl2 table, adapter_ip is vtep's ip address
        self.adapter_ip = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
