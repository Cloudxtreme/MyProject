import base_schema


class VSMUuidSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "vsmUuid"
    def __init__(self, py_dict=None):
        super(VSMUuidSchema, self).__init__()
        self.uuid = None

        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

