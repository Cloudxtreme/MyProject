import base_schema

class DNSListenersSchema(base_schema.BaseSchema):
    _schema_name = "listeners"
    def __init__(self, py_dict=None):
        """ Constructor to create DNSListenersSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DNSListenersSchema, self).__init__()
        self.set_data_type('xml')
        self.vnic = None
        self.ipAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)