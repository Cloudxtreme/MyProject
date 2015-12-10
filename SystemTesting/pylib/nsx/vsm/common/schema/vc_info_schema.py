import base_schema

class VCInfoSchema(base_schema.BaseSchema):
    _schema_name = "vcInfo"
    def __init__(self, py_dict=None):
        super(VCInfoSchema, self).__init__()
        self.set_data_type('xml')
        self.ipAddress = None
        self.userName = None
        self.password = None
        self.certificateThumbprint = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)