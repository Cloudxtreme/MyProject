import base_schema
from edge_ospf_cli_redistribute_rule_schema import OspfCliRedistributeRuleSchema

class OspfCliRedistributeSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "redistribute"
    def __init__(self, py_dict=None):
        """ Constructor to create OspfRedistributeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(OspfCliRedistributeSchema, self).__init__()
        self.rules = [OspfCliRedistributeRuleSchema()]
        self.enabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
