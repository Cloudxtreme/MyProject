import base_schema
from resource_link_schema import ResourceLinkSchema
from transport_type_schema import TransportTypeSchema

class TransportZoneEndpointSchema(base_schema.BaseSchema):
    _schema_name = "transportzoneendpoint"

    def __init__(self, py_dict=None):
        """ Constructor to create TransportZoneEndpointSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TransportZoneEndpointSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.transport_zone_id = None
        self.transport_type = TransportTypeSchema()
        self._links = [ResourceLinkSchema()]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
