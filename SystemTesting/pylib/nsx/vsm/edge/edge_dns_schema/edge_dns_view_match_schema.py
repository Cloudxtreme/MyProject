import base_schema

class DNSViewMatchSchema(base_schema.BaseSchema):
    _schema_name = "viewMatch"
    def __init__(self, py_dict=None):
        """ Constructor to create DNSViewMatchSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DNSViewMatchSchema, self).__init__()
        self.set_data_type('xml')
        self.vnic = None
        self.ipAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)