import base_schema
import resource_link_schema
import bgp_filter_schema

class BgpNeighborSchema(base_schema.BaseSchema):
    _schema_name = "bgpneighbor"

    def __init__(self, py_dict=None):
        """ Constructor to create BgpNeighborSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(BgpNeighborSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.bgp_filters = [bgp_filter_schema.BgpFilterSchema()]
        self.weight = None
        self.hold_down_timer = None
        self.forwarding_address = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.protocol_address = None
        self.keep_alive_timer = None
        self.remote_as = None
        self.password = None
        self.ip_address = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)