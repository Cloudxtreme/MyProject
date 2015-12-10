import base_schema
import resource_link_schema

class LoadBalancerGslbSecuritySchema(base_schema.BaseSchema):
    _schema_name = "loadbalancergslbsecurity"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGslbSecuritySchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGslbSecuritySchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.crl_certificate = [str]
        self.enabled = None
        self.ca_certificate = [str]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.service_certificate = None
        self.schema = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)