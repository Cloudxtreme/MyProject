import vmware.common.base_schema as base_schema


class ListBindingsSchema(base_schema.BaseSchema):
    _schema_name = "ListBindingsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListBindingsSchema object
        """
        super(ListBindingsSchema, self).__init__()
        self.table = [BindingsEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class BindingsEntrySchema(base_schema.BaseSchema):
    _schema_name = "BindingsEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create BindingsEntrySchema object
        """
        super(BindingsEntrySchema, self).__init__()

        self.source_kind = None
        self.source_name = None
        self.destination_kind = None
        self.destination_name = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
