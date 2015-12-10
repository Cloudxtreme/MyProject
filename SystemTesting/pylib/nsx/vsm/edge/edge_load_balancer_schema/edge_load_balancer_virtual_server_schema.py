import base_schema


class LoadBalancerVirtualServerSchema(base_schema.BaseSchema):
    _schema_name = "virtualServer"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerVirtualServerSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerVirtualServerSchema, self).__init__()
        self.set_data_type('xml')
        self.virtualServerId = None
        self.name = None
        self.description = None
        self.enabled = None
        self.ipAddress = None
        self.protocol = None
        self.port = None
        self.connectionLimit = None
        self.applicationProfileId = None
        self.applicationRuleId = None
        self.defaultPoolId = None
        self.enableServiceInsertion = None
        self.accelerationEnabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)