import base_schema
from edge_routing_route_schema import RoutingRouteSchema
from edge_routing_default_route_schema import RoutingDefaultRouteSchema


class RoutingStaticRoutingSchema(base_schema.BaseSchema):
    _schema_name = "staticRouting"
    def __init__(self, py_dict=None):
        """ Constructor to create RoutingStaticRoutingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RoutingStaticRoutingSchema, self).__init__()
        self.set_data_type('xml')
        self.staticRoutes = [RoutingRouteSchema()]
        self.defaultRoute = RoutingDefaultRouteSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)