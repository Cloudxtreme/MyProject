import vmware.common.base_schema as base_schema


class ListUserPermissionsSchema(base_schema.BaseSchema):
    _schema_name = "ListUserPermissionsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListUserPermissionsSchema object
        """
        super(ListUserPermissionsSchema, self).__init__()
        self.table = [UserPermissionsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class UserPermissionsEntrySchema(base_schema.BaseSchema):
    _schema_name = "UserPermissionsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create UserPermissionsEntrySchema object
        """
        super(UserPermissionsEntrySchema, self).__init__()

        self.name = None
        self.conf = None
        self.read = None
        self.write = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
