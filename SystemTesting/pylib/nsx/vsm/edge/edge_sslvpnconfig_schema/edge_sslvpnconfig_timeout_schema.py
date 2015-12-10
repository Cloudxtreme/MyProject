import base_schema


class SSLVPNConfigTimeoutSchema(base_schema.BaseSchema):
    _schema_name = "timeout"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigTimeoutSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigTimeoutSchema, self).__init__()
        self.set_data_type('xml')
        self.forcedTimeout = None
        self.sessionIdleTimeout = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)