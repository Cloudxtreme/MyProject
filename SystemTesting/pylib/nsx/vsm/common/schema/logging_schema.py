import base_schema

class LoggingSchema(base_schema.BaseSchema):
    _schema_name = "logging"
    def __init__(self, py_dict=None):
        """ Constructor to create LoggingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoggingSchema, self).__init__()
        self.set_data_type('xml')

        self.enable = None
        self.logLevel = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
