import base_schema
import resource_link_schema

class ZoneEndpointConfigSchema(base_schema.BaseSchema):
    _schema_name = "zoneendpointconfig"

    def __init__(self, py_dict=None):

        super(ZoneEndpointConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.transport_zone_id = None
        self.schema = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.revision = None
