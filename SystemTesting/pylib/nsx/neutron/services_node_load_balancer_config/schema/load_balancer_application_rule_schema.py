import base_schema
import resource_link_schema
import tag_schema

class LoadBalancerApplicationRuleSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerapplicationrule"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerApplicationRuleSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerApplicationRuleSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.display_name = None
        self.rule_id = None
        self.description = None
        self._create_user = None
        self.script = None
        self._create_time = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self._last_modified_time = None
        self.revision = None
        self._last_modified_user = None
        self.id = None
        self.tags = [tag_schema.TagSchema()]
        self.name = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)