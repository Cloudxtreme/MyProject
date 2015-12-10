import base_schema

class CollectorSchema(base_schema.BaseSchema):
    _schema_name = "collector"

    def __init__(self, py_dict=None):
        """ Constructor to create CollectorSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(CollectorSchema, self).__init__()
        self.set_data_type("xml")
        self.ip = None
        self.port = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
