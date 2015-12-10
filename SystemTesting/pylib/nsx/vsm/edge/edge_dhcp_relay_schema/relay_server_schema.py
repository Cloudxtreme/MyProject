import base_schema

class RelayServerSchema(base_schema.BaseSchema):
    _schema_name = "relayServer"

    def __init__(self, py_dict=None):
        """ Constructor to create RelayServerSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RelayServerSchema, self).__init__()
        self.set_data_type("xml")
        self.ipAddress = [""]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
