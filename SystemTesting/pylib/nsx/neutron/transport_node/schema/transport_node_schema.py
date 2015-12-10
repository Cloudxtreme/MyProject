import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema
from mgmtconn_credential_schema import MgmtConnCredentialSchema
from transport_zone_endpoint_schema import TransportZoneEndpointSchema

class TransportNodeSchema(base_schema.BaseSchema):
    _schema_name = "transportnode"

    def __init__(self, py_dict=None):
        """ Constructor to create TransportNodeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TransportNodeSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.credential = MgmtConnCredentialSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [TagSchema()]
        self.zone_end_points = [TransportZoneEndpointSchema()]
        self._create_time = None
        self._links = [ResourceLinkSchema()]
        self.admin_status_enabled = None
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.integration_bridge_id = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
