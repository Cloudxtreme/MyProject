import vmware.common.base_schema as base_schema


class LogicalSwitchSchema(base_schema.BaseSchema):
    """
    Schema class for Logical Switches

    >>> import pprint
    >>> py_dict = {'table': [{'replication_mode': 'mtep',
    ...                       'controller_ip': '10.24.29.58',
    ...                       'switch_vni': '5469',
    ...                       'controller_status': 'up'},
    ...                      {'replication_mode': 'source',
    ...                       'controller_ip': '10.24.29.59',
    ...                       'switch_vni': '5470',
    ...                       'controller_status': 'up'}]}
    >>> for entry_obj in LogicalSwitchSchema(py_dict=py_dict).table:
    ...     pprint.pprint(vars(entry_obj))
    {'controller_ip': '10.24.29.58',
     'controller_status': 'up',
     'replication_mode': 'mtep',
     'switch_vni': '5469'}
    {'controller_ip': '10.24.29.59',
     'controller_status': 'up',
     'replication_mode': 'source',
     'switch_vni': '5470'}
    """
    _schema_name = "LogicalSwitchSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalSwitchSchema object
        """
        super(LogicalSwitchSchema, self).__init__()
        self.table = [LogicalSwitchEntrySchema()]

        if py_dict:
            self.get_object_from_py_dict(py_dict=py_dict)


class LogicalSwitchEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in Logical Switches Table

    >>> import pprint
    >>> py_dict = {'controller_ip': '192.168.139.11',
    ...            'controller_status': 'up',
    ...            'replication_mode': 'mtep',
    ...            'switch_vni': '6796'}
    >>> pprint.pprint(vars(LogicalSwitchEntrySchema(py_dict=py_dict)))
    {'controller_ip': '192.168.139.11',
     'controller_status': 'up',
     'replication_mode': 'mtep',
     'switch_vni': '6796'}
    """
    _schema_name = "LogicalSwitchEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalSwitchEntrySchema object
        """
        super(LogicalSwitchEntrySchema, self).__init__()

        self.switch_vni = None
        self.controller_ip = None
        self.controller_status = None
        self.replication_mode = None

        if py_dict:
            self.get_object_from_py_dict(py_dict=py_dict)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
