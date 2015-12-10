import base_schema
from edge_nat_rule_schema import EdgeNATRuleSchema


class EdgeNATSchema(base_schema.BaseSchema):
    _schema_name = "nat"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeNATSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeNATSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.natRules = [EdgeNATRuleSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)