import vmware.nsx_api.base.base_schema as base_schema


class BackupRequestSchema(base_schema.BaseSchema):
    _schema_name = "backuprequestschema"

    def __init__(self, py_dict=None):
        super(BackupRequestSchema, self).__init__()
        self.passphrase = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    __slots__ = ['passphrase', ]
