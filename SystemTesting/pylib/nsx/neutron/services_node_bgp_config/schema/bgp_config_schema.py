import base_schema
import resource_link_schema
import bgp_neighbor_schema
import redistribution_config_schema

class BgpConfigSchema(base_schema.BaseSchema):
    _schema_name = "bgpconfig"

    def __init__(self, py_dict=None):
        """ Constructor to create BgpConfigSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(BgpConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.as_number = None
        self.neighbors = [bgp_neighbor_schema.BgpNeighborSchema()]
        self.enabled = None
        self.redistribution_config = redistribution_config_schema.RedistributionConfigSchema()
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.schema = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)