import vmware.common.base_schema as base_schema


class ListvHostsSchema(base_schema.BaseSchema):
    _schema_name = "ListvHostsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListvHostsSchema object
        """
        super(ListvHostsSchema, self).__init__()
        self.table = [HostsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class HostsEntrySchema(base_schema.BaseSchema):
    _schema_name = "HostsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create HostsEntrySchema object
        """
        super(HostsEntrySchema, self).__init__()

        self.name = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)