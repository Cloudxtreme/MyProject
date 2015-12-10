import base_schema
from edge_sslvpnconfig_timeout_schema import SSLVPNConfigTimeoutSchema


class SSLVPNConfigAdvancedConfigSchema(base_schema.BaseSchema):
    _schema_name = "advancedConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigAdvancedConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigAdvancedConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.enableCompression = None
        self.forceVirtualKeyboard = None
        self.randomizeVirtualkeys = None
        self.preventMultipleLogon = None
        self.clientNotification = None
        self.enablePublicUrlAccess = None
        self.timeout = SSLVPNConfigTimeoutSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)