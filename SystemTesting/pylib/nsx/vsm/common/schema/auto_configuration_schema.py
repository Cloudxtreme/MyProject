import base_schema

class AutoConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "autoConfiguration"
    def __init__(self, py_dict=None):
        """ Constructor to create AutoConfigurationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(AutoConfigurationSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.rulePriority = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)