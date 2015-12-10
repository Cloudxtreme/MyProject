import vmware.common.base_schema as base_schema


class ListConsumersSchema(base_schema.BaseSchema):
    _schema_name = "ListConsumersSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListConsumersSchema object
        """
        super(ListConsumersSchema, self).__init__()
        self.table = [ConsumersEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ConsumersEntrySchema(base_schema.BaseSchema):
    _schema_name = "ConsumersEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ConsumersEntrySchema object
        """
        super(ConsumersEntrySchema, self).__init__()

        self.queue = None
        self.id = None
        self.tag = None
        self.acknowledgment = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)