import base_schema
import resource_link_schema

class LoadBalancerClientSslSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerclientssl"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerClientSslSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerClientSslSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.client_auth = None
        self.crl_certificate = [str]
        self.ciphers = None
        self.ca_certificate = [str]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.service_certificate = [str]
        self.schema = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)