import base_schema
import resource_link_schema
import load_balancer_gslb_security_schema
import load_balancer_gslb_persistent_cache_config_schema

class LoadBalancerGlobalServiceConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerglobalserviceconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGlobalServiceConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGlobalServiceConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.gslb_security = load_balancer_gslb_security_schema.LoadBalancerGslbSecuritySchema()
        self.revision = None
        self.query_port = None
        self.enabled = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.ip_adresses = [str]
        self.persistence_cache = \
            load_balancer_gslb_persistent_cache_config_schema.LoadBalancerGslbPersistentCacheConfigSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)