import vmware.common.base_schema as base_schema


class ListUsersSchema(base_schema.BaseSchema):
    _schema_name = "ListUsersSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListUsersSchema object
        """
        super(ListUsersSchema, self).__init__()
        self.table = [UsersEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class UsersEntrySchema(base_schema.BaseSchema):
    _schema_name = "UsersEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create UsersEntrySchema object
        """
        super(UsersEntrySchema, self).__init__()

        self.name = None
        self.role = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
