import base_schema


class CertificateSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "x509certificate"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(CertificateSchema, self).__init__()
        self.subjectCn = None
        self.issuerCn = None
        self.version = None
        self.serialNumber = None
        self.signatureAlgo = None
        self.signature = None
        self.notBefore = None
        self.notAfter = None
        self.issuer = None
        self.subject = None
        self.publicKeyAlgo = None
        self.publicKeyLength = None
        self.rsaPublicKeyModulus = None
        self.rsaPublicKeyExponent = None
        self.sha1Hash = None
        self.md5Hash = None
        self.isCa = None
        self.isValid = None

        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

