import base_schema
import resource_link_schema
import firewall_rule_stats_schema
import tag_schema

class FirewallRuleSchema(base_schema.BaseSchema):
    _schema_name = "firewallrule"

    def __init__(self, py_dict=None):

        super(FirewallRuleSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.rule_type = None
        self.rule_tag = None
        self.display_name = None
        self.description = None
        self._create_user = None
        self.logging_enabled = None
        self.destination = [str]
        self.enabled = None
        self.id = None
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.source = [str]
        self.action = None
        self.services = [str]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self._stats = firewall_rule_stats_schema.FirewallRuleStatsSchema()
        self.tags = [tag_schema.TagSchema()]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)