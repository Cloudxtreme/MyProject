import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema
from configuration_state_schema import ConfigurationStateSchema
from dns_settings_schema import DNSSettingsSchema

class LogicalServicesNodeSchema(base_schema.BaseSchema):
    _schema_name = "logicalservicesnode"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalServicesNodeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LogicalServicesNodeSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
#        self.tags = [TagSchema()]
#        self.service_bindings = [str]
        self._create_time = None
#        self.state = ConfigurationStateSchema()
        self._links = [ResourceLinkSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None
        self.location = None
        self.capacity = None
        self.dns_settings = DNSSettingsSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
