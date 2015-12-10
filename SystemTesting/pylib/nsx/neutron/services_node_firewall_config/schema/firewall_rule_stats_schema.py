import base_schema
import resource_link_schema


class FirewallRuleStatsSchema(base_schema.BaseSchema):
    _schema_name = "firewallrulestats"

    def __init__(self, py_dict=None):

        super(FirewallRuleStatsSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.byte_count = None
        self.timestamp = None
        self.packet_count = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.schema = None
        self.conn_count = None
        self.revision = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)