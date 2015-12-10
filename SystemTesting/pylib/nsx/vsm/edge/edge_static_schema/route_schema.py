import base_schema


class RouteSchema(base_schema.BaseSchema):
    _schema_name = "route"

    def __init__(self, py_dict=None):
        """ Constructor to create RouteSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RouteSchema, self).__init__()
        self.set_data_type("xml")
        self.network = None
        self.nextHop = None
        self.type = None
        self.description = None
        self.mtu = None
        self.vnic = None

        if py_dict is not None:
            print " py_dict in RouteSchema", py_dict
            self.get_object_from_py_dict(py_dict)
