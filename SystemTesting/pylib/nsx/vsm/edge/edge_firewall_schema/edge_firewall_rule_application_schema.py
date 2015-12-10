import base_schema
from edge_firewall_rule_application_service_schema import FirewallRuleApplicationServiceSchema


class FirewallRuleApplicationSchema(base_schema.BaseSchema):
    _schema_name = "application"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallRuleApplicationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallRuleApplicationSchema, self).__init__()
        self.set_data_type('xml')
        self.applicationId = None
        self.service = FirewallRuleApplicationServiceSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)