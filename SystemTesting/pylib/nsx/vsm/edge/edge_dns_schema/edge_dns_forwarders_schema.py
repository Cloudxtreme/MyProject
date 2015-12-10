import base_schema


class DNSForwardersSchema(base_schema.BaseSchema):
    _schema_name = "forwarders"
    def __init__(self, py_dict=None):
        """ Constructor to create DNSForwardersSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DNSForwardersSchema, self).__init__()
        self.set_data_type('xml')
        self.ipAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)