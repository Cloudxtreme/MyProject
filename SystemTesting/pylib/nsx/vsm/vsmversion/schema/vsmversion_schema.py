import base_schema

class VSMVersionInfoSchema(base_schema.BaseSchema):
    """
        This schema is not used for configuration
    """
    _schema_name = "versionInfo"
    def __init__(self, py_dict=None):
        super(VSMVersionInfoSchema, self).__init__()
        self.majorVersion = 0
        self.minorVersion = 0
        self.patchVersion = 0
        self.buildNumber = None
        self.set_data_type('xml')
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

