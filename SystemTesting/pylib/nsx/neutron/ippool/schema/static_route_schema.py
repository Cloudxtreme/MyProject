import base_schema

class StaticRouteSchema(base_schema.BaseSchema):
    _schema_name = "staticroute"

    def __init__(self, py_dict=None):
        """ Constructor to create StaticRouteSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(StaticRouteSchema, self).__init__()
        self.next_hop = None
        self.destination_cidr = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)