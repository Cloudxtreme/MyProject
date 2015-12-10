import base_schema


class LoadBalancerServerSslSchema(base_schema.BaseSchema):
    _schema_name = "serverSsl"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerServerSslSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerServerSslSchema, self).__init__()
        self.set_data_type('xml')
        self.ciphers = None
        self.serviceCertificate = None
        self.caCertificate = None
        self.crlCertificate = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)