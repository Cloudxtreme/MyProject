import base_schema
from BGP_neighbour_schema import BGPNeighbourSchema
from redistribution_schema import RedistributionSchema


class BGPSchema(base_schema.BaseSchema):
    _schema_name = "bgp"

    def __init__(self, py_dict=None):
        """ Constructor to create BgpRoutingSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(BGPSchema, self).__init__()
        self.set_data_type("xml")
        self.gracefulRestart = None
        self.defaultOriginate = None
        self.localAS = None
        self.enabled = None
        self.bgpNeighbours = [BGPNeighbourSchema()]
        self.redistribution = RedistributionSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
