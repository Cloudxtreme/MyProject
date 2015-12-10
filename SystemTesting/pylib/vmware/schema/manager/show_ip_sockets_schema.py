import vmware.common.base_schema as base_schema


class ShowIPSocketsSchema(base_schema.BaseSchema):
    _schema_name = "IpSocketsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ShowIPSocketsSchema object
        """
        super(ShowIPSocketsSchema, self).__init__()
        self.table = [IPSocketsEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class IPSocketsEntrySchema(base_schema.BaseSchema):
    _schema_name = "IPSocketsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create IPSocketsEntrySchema object
        """
        super(IPSocketsEntrySchema, self).__init__()
        self.proto = None
        self.remote = None
        self.remote_port = None
        self.local = None
        self.local_port = None
        self.inward = None
        self.outward = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)