import base_schema
from logging_schema import LoggingSchema


class RoutingGlobalConfigSchema(base_schema.BaseSchema):
    _schema_name = "routingGlobalConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create RoutingGlobalConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RoutingGlobalConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.routerId = None
        self.logging = LoggingSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)