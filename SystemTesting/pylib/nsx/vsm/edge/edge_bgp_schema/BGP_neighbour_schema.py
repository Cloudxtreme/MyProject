import base_schema


class BGPNeighbourSchema(base_schema.BaseSchema):
    _schema_name = "bgpNeighbour"

    def __init__(self, py_dict=None):
        """ Constructor to create BgpNeighbourSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(BGPNeighbourSchema, self).__init__()
        self.set_data_type("xml")
        self.bgpFilters = None
        self.holdDownTimer = None
        self.weight = None
        self.remoteAS = None
        self.protocolAddress = None
        self.forwardingAddress = None
        self.password = None
        self.ipAddress = None
        self.keepAliveTimer = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
