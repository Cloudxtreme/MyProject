import base_schema
import resource_link_schema
import tag_schema
import nat_rule_schema

class NatConfigSchema(base_schema.BaseSchema):
    _schema_name = "natconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create NatConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(NatConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [tag_schema.TagSchema()]
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.nat_rules = [nat_rule_schema.NatRuleSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)