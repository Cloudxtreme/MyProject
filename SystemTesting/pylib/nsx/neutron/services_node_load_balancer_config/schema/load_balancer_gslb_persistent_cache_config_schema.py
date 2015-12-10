import base_schema
import resource_link_schema

class LoadBalancerGslbPersistentCacheConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancergslbpersistentcacheconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGslbPersistentCacheConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGslbPersistentCacheConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.ttl = None
        self.revision = None
        self.max_size = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)