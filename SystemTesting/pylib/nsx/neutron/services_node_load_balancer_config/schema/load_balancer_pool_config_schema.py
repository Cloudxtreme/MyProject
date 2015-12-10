import base_schema
import resource_link_schema
import tag_schema
import resource_link_schema
import load_balancer_member_config_schema

class LoadBalancerPoolConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerpoolconfig"

    def __init__(self, py_dict=None):

        super(LoadBalancerPoolConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.snat_enable = None
        self.pool_id = None
        self.ip_address = None
        self.name = None
        self.description = None
        self.algorithm = None
        self._create_user = None
        self.type = None
        self.tags = [tag_schema.TagSchema()]
        self.id = None
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.members = [load_balancer_member_config_schema.LoadBalancerMemberConfigSchema()]
        self.ttl = None
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.fallback_algorithm = None
        self.monitor_ids = [str]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)