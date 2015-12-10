import base_schema
import redistribution_rule_schema

class RedistributionConfigSchema(base_schema.BaseSchema):
    _schema_name = "redistributionconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create RedistributionConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(RedistributionConfigSchema, self).__init__()
        self.rules = [redistribution_rule_schema.RedistributionRuleSchema()]
        self.redistribution_enabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)