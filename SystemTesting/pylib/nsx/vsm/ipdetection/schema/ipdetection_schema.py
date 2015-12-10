import base_schema


class IPDetectionSchema(base_schema.BaseSchema):
    _schema_name = "ipRepositoryConfig"

    def __init__(self, py_dict=None):
        """ Constructor to create IPDetectionSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPDetectionSchema, self).__init__()
        self.set_data_type('xml')
        self.scopeId = None
        self.dhcpSnoopEnabled = None
        self.arpSnoopEnabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)