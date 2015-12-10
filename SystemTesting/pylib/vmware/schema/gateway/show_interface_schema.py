import vmware.common.base_schema as base_schema


class ShowInterfaceSchema(base_schema.BaseSchema):
    """
    Schema Class for show interface command executed on Edge VM
    >>> import pprint
    >>> py_dict =  'hwaddr': '00:0c:29:59:b6:ff', 'vnic_state': 'up',
    ...             'ip6': ['fe80::20c:29ff:fe59:b6ff'],
    ...             'ip4': ['10.110.62.210']}
    >>> pyobj = ShowInterfaceSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'hwaddr': '00:0c:29:59:b6:ff',
    'ip4': ['10.110.62.210'],
    'ip6': ['fe80::20c:29ff:fe59:b6ff'],
    'vnic_state': 'up'}
     """

    _schema_name = "ShowInterfaceSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ShowInterfaceSchema object
        """
        super(ShowInterfaceSchema, self).__init__()
        self.vnic_state = None
        self.ip4 = None
        self.ip6 = None
        self.hwaddr = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
