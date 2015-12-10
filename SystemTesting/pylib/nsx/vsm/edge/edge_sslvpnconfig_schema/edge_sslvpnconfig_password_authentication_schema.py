import base_schema

class SSLVPNConfigPasswordAuthenticationSchema(base_schema.BaseSchema):
    _schema_name = "passwordAuthentication"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigPasswordAuthenticationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigPasswordAuthenticationSchema, self).__init__()
        self.set_data_type('xml')
        self.authenticationTimeout = None
        self.primaryAuthServers = None
        self.secondaryAuthServer = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)