import base_schema
from edge_firewall_rule_schema import FirewallRuleSchema
from edge_firewall_default_policy_schema import FirewallDefaultPolicySchema
from edge_firewall_global_config_schema import FirewallGlobalConfigSchema

class FirewallSchema(base_schema.BaseSchema):
    _schema_name = "firewall"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.defaultPolicy = FirewallDefaultPolicySchema()
        self.globalConfig = FirewallGlobalConfigSchema()
        self.firewallRules = [FirewallRuleSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)