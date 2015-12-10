import base_schema
from edge_routing_global_config_schema import RoutingGlobalConfigSchema
from edge_routing_static_routing_schema import RoutingStaticRoutingSchema


class EdgeRoutingSchema(base_schema.BaseSchema):
    _schema_name = "routing"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeRoutingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeRoutingSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.version = None
        self.routingGlobalConfig = RoutingGlobalConfigSchema()
        self.staticRouting = RoutingStaticRoutingSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)