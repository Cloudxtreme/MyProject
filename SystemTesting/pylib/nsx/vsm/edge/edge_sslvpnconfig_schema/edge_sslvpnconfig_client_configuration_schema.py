import base_schema

class SSLVPNConfigClientConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "clientConfiguration"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigClientConfigurationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigClientConfigurationSchema, self).__init__()
        self.set_data_type('xml')
        self.autoReconnect = None
        self.upgradeNotification = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)