import base_schema
from edge_nat_rule_schema import EdgeNATRuleSchema


class EdgeNATRulesSchema(base_schema.BaseSchema):
    _schema_name = "natRules"
    def __init__(self, py_dict=None):

        """ Constructor to create EdgeNATRulesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeNATRulesSchema, self).__init__()
        self.set_data_type('xml')
        self.natRule = EdgeNATRuleSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)