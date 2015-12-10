import base_schema
import resource_link_schema
import nat_rule_match_schema

class NatRuleSchema(base_schema.BaseSchema):
    _schema_name = "natrule"

    def __init__(self, py_dict=None):
        """ Constructor to create NatRuleSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(NatRuleSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.rule_type = None
        self.uuid = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.schema = None
        self.order = None
        self.match = nat_rule_match_schema.NatRuleMatchSchema()
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)