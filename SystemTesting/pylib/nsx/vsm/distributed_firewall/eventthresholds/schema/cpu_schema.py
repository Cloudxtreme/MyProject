import base_schema

class CpuSchema(base_schema.BaseSchema):
    _schema_name = "cpu"

    def __init__(self, py_dict=None):
        """ Constructor to create CpuSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(CpuSchema, self).__init__()
        self.set_data_type("xml")
        self.percentValue = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
