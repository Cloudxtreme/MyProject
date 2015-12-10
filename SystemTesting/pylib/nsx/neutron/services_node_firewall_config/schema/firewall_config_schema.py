import base_schema
import resource_link_schema
import firewall_rule_schema
import tag_schema
import firewall_options_schema


class FirewallConfigSchema(base_schema.BaseSchema):
    _schema_name = "firewallconfig"

    def __init__(self, py_dict=None):

        super(FirewallConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.rules = [firewall_rule_schema.FirewallRuleSchema()]
        self.logging_enabled = None
        self.tags = [tag_schema.TagSchema()]
        self.global_config = firewall_options_schema.FirewallOptionsSchema()
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.default_policy = None
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)