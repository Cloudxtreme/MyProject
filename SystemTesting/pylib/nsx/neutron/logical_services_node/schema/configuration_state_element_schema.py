import base_schema

class ConfigurationStateElementSchema(base_schema.BaseSchema):
    _schema_name = "configurationstateelement"

    def __init__(self, py_dict=None):
        """ Constructor to create ConfigurationStateElementSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ConfigurationStateElementSchema, self).__init__()
        self.error_message = None
        self.backing_resource_uri = None
        self.state = None
        self.sub_system_name = None
        self.error_code = None
        self.sub_system_uri = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)