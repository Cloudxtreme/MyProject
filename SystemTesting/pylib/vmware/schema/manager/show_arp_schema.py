import vmware.common.base_schema as base_schema


class ShowArpSchema(base_schema.BaseSchema):
    _schema_name = "ArpSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ShowArpSchema object
        """
        super(ShowArpSchema, self).__init__()
        self.table = [ArpEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ArpEntrySchema(base_schema.BaseSchema):
    _schema_name = "ArpEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ArpEntrySchema object
        """
        super(ArpEntrySchema, self).__init__()
        self.protocol = None
        self.address = None
        self.hardwareaddr = None
        self.type = None
        self.interface = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)