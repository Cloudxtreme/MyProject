import base_schema
import resource_link_schema
import tag_schema
import load_balancer_global_ip_pool_schema
import load_balancer_global_ip_persistence_schema

class LoadBalancerGlobalIpSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerglobalip"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGlobalIpSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGlobalIpSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self.algorithm = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self.enabled = None
        self.fqdn = None
        self._create_time = None
        self.ip_pools = \
            [load_balancer_global_ip_pool_schema.LoadBalancerGlobalIpPoolSchema()]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.ttl = None
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.persistence = \
            load_balancer_global_ip_persistence_schema.LoadBalancerGlobalIpPersistenceSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)