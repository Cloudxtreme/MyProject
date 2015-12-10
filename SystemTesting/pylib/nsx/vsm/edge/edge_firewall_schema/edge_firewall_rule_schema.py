import base_schema
from edge_firewall_rule_application_schema import FirewallRuleApplicationSchema
from edge_firewall_rule_source_schema import FirewallRuleSourceSchema
from edge_firewall_rule_destination_schema import FirewallRuleDestinationSchema


class FirewallRuleSchema(base_schema.BaseSchema):
    _schema_name = "firewallRule"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallRuleSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallRuleSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.ruleTag = None
        self.name = None
        self.ruleType = None
        self.action = None
        self.enabled = None
        self.loggingEnabled = None
        self.description = None
        self.source = FirewallRuleSourceSchema()
        self.destination = FirewallRuleDestinationSchema()
        self.application = FirewallRuleApplicationSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)