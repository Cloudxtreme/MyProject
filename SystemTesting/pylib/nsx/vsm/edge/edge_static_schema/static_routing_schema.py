import base_schema
from route_schema import RouteSchema


# TODO from default_route_schema import DefaultRouteSchema TODO
class StaticRoutingSchema(base_schema.BaseSchema):
    _schema_name = "staticRouting"

    def __init__(self, py_dict=None):
        """ Constructor to create StaticRoutingSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(StaticRoutingSchema, self).__init__()
        self.set_data_type("xml")
        self.type = None
        self.staticRoutes = [RouteSchema()]
# TODO       self.defaultRoute = DefaultRouteSchema()"TODO"

        if py_dict is not None:
            print " py_dict in RouteSchema", py_dict
            self.get_object_from_py_dict(py_dict)
