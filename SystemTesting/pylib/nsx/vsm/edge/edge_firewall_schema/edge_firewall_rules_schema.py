import base_schema
from edge_firewall_rule_schema import FirewallRuleSchema


class FirewallRulesSchema(base_schema.BaseSchema):
    _schema_name = "firewallRules"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallRulesSchema Schema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallRulesSchema, self).__init__()
        self.set_data_type('xml')
        self.firewallRule = FirewallRuleSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
