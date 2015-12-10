import base_schema

class KeyValueSchema(base_schema.BaseSchema):
    _schema_name = "keyValue"
    def __init__(self, py_dict=None):
        """ Constructor to create KeyValueSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(KeyValueSchema, self).__init__()
        self.set_data_type('xml')
        self.key = None
        self.value = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
