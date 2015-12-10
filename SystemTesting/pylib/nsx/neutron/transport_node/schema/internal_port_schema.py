import base_schema
from resource_link_schema import ResourceLinkSchema

class InternalPortSchema(base_schema.BaseSchema):
    _schema_name = "internalport"

    def __init__(self, py_dict=None):
        """ Constructor to create InternalPortSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(InternalPortSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self._links = [ResourceLinkSchema()]
        self.ip_address = None
        self.device_id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
