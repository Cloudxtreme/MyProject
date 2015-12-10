import base_schema

class CpsSchema(base_schema.BaseSchema):
    _schema_name = "connectionsPerSecond"

    def __init__(self, py_dict=None):
        """ Constructor to create CpsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(CpsSchema, self).__init__()
        self.set_data_type("xml")
        self.value = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
