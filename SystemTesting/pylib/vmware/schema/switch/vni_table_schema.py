import doctest

import vmware.common.base_schema as base_schema


class VNITableSchema(base_schema.BaseSchema):
    """
    Schema class for VNI Table.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'vni': 5001,
    ...                'controller': '192.168.1.2',
    ...                'bum_replication': 'Enabled',
    ...                'arp_proxy': 'Enabled',
    ...                'connections': 3,
    ...                'vteps': 3},
    ...               {'vni': 5002,
    ...                'controller': '192.168.1.3',
    ...                'bum_replication': 'Disabled',
    ...                'arp_proxy': 'Enabled',
    ...                'connections': 5,
    ...                'vteps': 2}]}
    >>> pprint.pprint(VNITableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'arp_proxy': 'Enabled',
                'bum_replication': 'Enabled',
                'connections': 3,
                'controller': '192.168.1.2',
                'vni': 5001,
                'vteps': 3},
               {'arp_proxy': 'Enabled',
                'bum_replication': 'Disabled',
                'connections': 5,
                'controller': '192.168.1.3',
                'vni': 5002,
                'vteps': 2}]}
    """
    _schema_name = "VNISchema"

    def __init__(self, py_dict=None):
        super(VNITableSchema, self).__init__()
        self.table = [VNITableEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class VNITableEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in VNI table.

    >>> import pprint
    >>> py_dict = {'vni': 5001,
    ...            'controller': '192.168.1.2',
    ...            'bum_replication': 'Enabled',
    ...            'arp_proxy': 'Enabled',
    ...            'connections': 3,
    ...            'vteps': 3}
    >>> pprint.pprint(VNITableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'arp_proxy': 'Enabled',
     'bum_replication': 'Enabled',
     'connections': 3,
     'controller': '192.168.1.2',
     'vni': 5001,
     'vteps': 3}
    """
    _schema_name = "VNITableEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the VNITableEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for a VNI table
            entry as key-value.
        """
        super(VNITableEntrySchema, self).__init__()
        self.vni = None
        self.controller = None
        self.bum_replication = None
        self.arp_proxy = None
        self.connections = None
        self.vteps = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    doctest.testmod()
