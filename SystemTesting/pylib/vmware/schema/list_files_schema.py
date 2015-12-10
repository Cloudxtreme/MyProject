import vmware.common.base_schema as base_schema


class ListFilesSchema(base_schema.BaseSchema):
    _schema_name = "ListFilesSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListFilesSchema object
        """
        super(ListFilesSchema, self).__init__()
        self.table = [ListFilesEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ListFilesEntrySchema(base_schema.BaseSchema):
    _schema_name = "ListFilesEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ListFilesEntrySchema object
        """
        super(ListFilesEntrySchema, self).__init__()
        self.permissions = None
        self.number_of_links = None
        self.owner = None
        self.group = None
        self.size = None
        self.month = None
        self.day = None
        self.time = None
        self.file_name = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
