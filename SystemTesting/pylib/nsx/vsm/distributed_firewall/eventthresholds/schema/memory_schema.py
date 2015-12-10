import base_schema

class MemorySchema(base_schema.BaseSchema):
    _schema_name = "memory"

    def __init__(self, py_dict=None):
        """ Constructor to create MemorySchema object
        @param py_dict : python dictionary to construct this object
        """
        super(MemorySchema, self).__init__()
        self.set_data_type("xml")
        self.percentValue = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
