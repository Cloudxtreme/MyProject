import base_schema
import resource_link_schema

class RedistributionRuleSchema(base_schema.BaseSchema):
    _schema_name = "redistributionrule"

    def __init__(self, py_dict=None):
        """ Constructor to create RedistributionRuleSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(RedistributionRuleSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.from_bgp = None
        self.from_ospf = None
        self.connected = None
        self.from_isis = None
        self.action = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.from_static = None
        self.schema = None
        self.prefix_name = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)