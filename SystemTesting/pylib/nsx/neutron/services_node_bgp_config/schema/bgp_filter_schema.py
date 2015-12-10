import base_schema
import resource_link_schema

class BgpFilterSchema(base_schema.BaseSchema):
    _schema_name = "bgpfilter"

    def __init__(self, py_dict=None):
        """ Constructor to create BgpFilterSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(BgpFilterSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.direction = None
        self.ip_prefix_le = None
        self.ip_prefix_ge = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.action = None
        self.revision = None
        self.network = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)