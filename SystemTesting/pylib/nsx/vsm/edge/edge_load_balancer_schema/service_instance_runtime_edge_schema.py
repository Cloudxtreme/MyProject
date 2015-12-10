import base_schema
from logging_schema import LoggingSchema

class ServiceInstanceRuntimeEdgeSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstanceRuntimeEdgeSchema"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceRuntimeEdgeSchema, self).__init__()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
