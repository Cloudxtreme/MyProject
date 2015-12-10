import base_schema
from route_rule_schema import RuleSchema


class RedistributionSchema(base_schema.BaseSchema):
    _schema_name = "redistribution"

    def __init__(self, py_dict=None):
        """ Constructor to create RedistributionSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RedistributionSchema, self).__init__()
        self.set_data_type("xml")
        self.rules = [RuleSchema()]
        self.enabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
