import base_schema
import resource_link_schema
import tag_schema

class VirtualServerConfigSchema(base_schema.BaseSchema):
    _schema_name = "virtualserverconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create VirtualServerConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(VirtualServerConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.protocol = None
        self.enabled = None
        self.application_profile_id = None
        self.port = None
        self.name = None
        self.id = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.default_pool_id = None
        self._last_modified_user = None
        self.schema = None
        self.description = None
        self.tags = [tag_schema.TagSchema()]
        self.connection_rate_limit = None
        self.application_rule_ids = [str]
        self._create_time = None
        self.acceleration_enabled = None
        self.ip_address = None
        self._create_user = None
        self.connection_limit = None
        self._last_modified_time = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)