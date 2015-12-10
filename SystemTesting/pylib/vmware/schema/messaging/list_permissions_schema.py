import vmware.common.base_schema as base_schema


class ListPermissionsSchema(base_schema.BaseSchema):
    _schema_name = "ListPermissionsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListPermissionsSchema object
        """
        super(ListPermissionsSchema, self).__init__()
        self.table = [PermissionsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class PermissionsEntrySchema(base_schema.BaseSchema):
    _schema_name = "HostPermissionsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create PermissionsEntrySchema object
        """
        super(PermissionsEntrySchema, self).__init__()

        self.name = None
        self.conf = None
        self.read = None
        self.write = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
