import vmware.common.base_schema as base_schema


class ShowNtpAssociationsSchema(base_schema.BaseSchema):
    _schema_name = "ShowNtpAssociationsSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ShowNtpAssociationsSchema object
        """
        super(ShowNtpAssociationsSchema, self).__init__()
        self.table = [NtpEntrySchema()]
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class NtpEntrySchema(base_schema.BaseSchema):
    _schema_name = "NtpEntrySchema"

    def __init__(self, py_dict=None):
        """ Constructor to create NtpEntrySchema object
        """
        super(NtpEntrySchema, self).__init__()
        self.remote = None
        self.local = None
        self.st = None
        self.poll = None
        self.reach = None
        self.delay = None
        self.offset = None
        self.disp = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)