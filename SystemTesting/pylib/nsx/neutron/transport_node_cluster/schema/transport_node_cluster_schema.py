import base_schema
import resource_link_schema
import zone_endpoint_config_schema
import tag_schema

class TransportNodeClusterSchema(base_schema.BaseSchema):
    _schema_name = "transportnodecluster"

    def __init__(self, py_dict=None):

        super(TransportNodeClusterSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.domain_resource_id = None
        self.id = None
        self.domain_type = None
        self._create_time = None
        self.zone_end_points = [zone_endpoint_config_schema.ZoneEndpointConfigSchema()]
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.domain_id = None
        self.tags = [tag_schema.TagSchema()]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

