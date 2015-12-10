import base_schema


class RoutingDefaultRouteSchema(base_schema.BaseSchema):
    _schema_name = "defaultRoute"
    def __init__(self, py_dict=None):
        """ Constructor to create RoutingDefaultRouteSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RoutingDefaultRouteSchema, self).__init__()
        self.set_data_type('xml')
        self.vnic = None
        self.mtu = None
        self.description = None
        self.gatewayAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)