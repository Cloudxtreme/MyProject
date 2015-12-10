import base_schema
from resource_link_schema import ResourceLinkSchema
from internal_port_schema import InternalPortSchema

class TransportTypeSchema(base_schema.BaseSchema):
    _schema_name = "transporttype"

    def __init__(self, py_dict=None):
        """ Constructor to create TransportZoneEndpointSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TransportTypeSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.type = None
        self.internal_port = InternalPortSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
