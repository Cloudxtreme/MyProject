import base_schema
from edge_sslvpnconfig_password_authentication_schema import SSLVPNConfigPasswordAuthenticationSchema


class SSLVPNConfigAuthenticationConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "authenticationConfiguration"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigAuthenticationConfigurationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigAuthenticationConfigurationSchema, self).__init__()
        self.set_data_type('xml')
        self.passwordAuthentication = \
            SSLVPNConfigPasswordAuthenticationSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)