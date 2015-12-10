import vmware.common.base_schema as base_schema


class ListQueuesSchema(base_schema.BaseSchema):
    _schema_name = "ListQueuesSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListQueuesSchema object
        """
        super(ListQueuesSchema, self).__init__()
        self.table = [QueuesEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class QueuesEntrySchema(base_schema.BaseSchema):
    _schema_name = "QueuesEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create QueuesEntrySchema object
        """
        super(QueuesEntrySchema, self).__init__()

        self.name = None
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)