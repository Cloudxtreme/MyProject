import base_schema
from logging_schema import LoggingSchema
from edge_sslvpnconfig_advancedconfig_schema import SSLVPNConfigAdvancedConfigSchema
from edge_sslvpnconfig_client_configuration_schema import SSLVPNConfigClientConfigurationSchema
from edge_sslvpnconfig_layout_configuration_schema import SSLVPNConfigLayoutConfigurationSchema
from edge_sslvpnconfig_authentication_configuration_schema import SSLVPNConfigAuthenticationConfigurationSchema


class SSLVPNConfigSchema(base_schema.BaseSchema):
    _schema_name = "sslvpnConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create SSLVPNConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.logging = LoggingSchema()
        self.advancedConfig = \
            SSLVPNConfigAdvancedConfigSchema()
        self.clientConfiguration = \
            SSLVPNConfigClientConfigurationSchema()
        self.layoutConfiguration = \
            SSLVPNConfigLayoutConfigurationSchema()
        self.authenticationConfiguration = \
            SSLVPNConfigAuthenticationConfigurationSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)