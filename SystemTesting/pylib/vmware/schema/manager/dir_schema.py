import vmware.common.base_schema as base_schema


class DirSchema(base_schema.BaseSchema):
    _schema_name = "DirSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create DirSchema object
        """
        super(DirSchema, self).__init__()
        self.table = [DirEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class DirEntrySchema(base_schema.BaseSchema):
    _schema_name = "DirEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create DirEntrySchema object
        """
        super(DirEntrySchema, self).__init__()
        self.permissions = None
        self.size = None
        self.month = None
        self.date = None
        self.year = None
        self.time = None
        self.TZ = None
        self.file_name = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
