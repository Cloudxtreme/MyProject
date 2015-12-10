import base_schema


class IPPoolSchema(base_schema.BaseSchema):
    _schema_name = "ipPool"
    def __init__(self, py_dict=None):
        """ Constructor to create IPPoolSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPPoolSchema, self).__init__()
        self.set_data_type('xml')

        self.ipRange = None
        self.defaultGateway = None
        self.domainName = None
        self.primaryNameServer = None
        self.secondaryNameServer = None
        self.leaseTime = None
        self.autoConfigureDNS = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)