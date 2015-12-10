import base_schema


class FromSchema(base_schema.BaseSchema):
    _schema_name = "from"

    def __init__(self, py_dict=None):
        """ Constructor to create FromSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(FromSchema, self).__init__()
        self.set_data_type("xml")
        self.bgp = None
        self.ospf = None
        self.static = None
        self.connected = None
        self.isis = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
