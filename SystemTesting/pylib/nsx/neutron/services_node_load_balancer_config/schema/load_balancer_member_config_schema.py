import base_schema
import resource_link_schema

class LoadBalancerMemberConfigSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancermemberconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerMemberConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerMemberConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.weight = None
        self.port = None
        self.monitor_port = None
        self.ip_address = None
        self.condition = None
        self.name = None
        self.member_id = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.revision = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)