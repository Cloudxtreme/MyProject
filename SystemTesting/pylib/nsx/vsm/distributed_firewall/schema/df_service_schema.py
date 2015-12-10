import base_schema

class ServiceSchema(base_schema.BaseSchema):
    _schema_name = "service"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceSchema, self).__init__()
        self.set_data_type("xml")
        self.isValid = None
        self.type = None
        self.name = None
        self.value = None
        self.protocol = None
        self.protocolName = None
        self.subProtocol = None
        self.subProtocolName = None
        self.destinationPort = None
        self.sourcePort = None



        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
