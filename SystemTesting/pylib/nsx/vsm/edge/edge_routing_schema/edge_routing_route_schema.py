import base_schema


class RoutingRouteSchema(base_schema.BaseSchema):
    _schema_name = "route"
    def __init__(self, py_dict=None):
        """ Constructor to create RoutingRouteSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RoutingRouteSchema, self).__init__()
        self.set_data_type('xml')
        self.vnic = None
        self.mtu = None
        self.network = None
        self.nextHop = None
        self.description = None
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)