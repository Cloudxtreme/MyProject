import base_schema

class AccessControlEntrySchema(base_schema.BaseSchema):
    _schema_name = "accessControlEntry"
    def __init__(self, py_dict=None):
        super(AccessControlEntrySchema, self).__init__()
        self.set_data_type('xml')
        self.role = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
