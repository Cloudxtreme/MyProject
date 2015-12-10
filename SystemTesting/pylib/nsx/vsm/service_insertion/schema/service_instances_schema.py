import base_schema
from service_instance_schema import ServiceInstanceSchema

class ServiceInstancesSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstances"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstancesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstancesSchema, self).__init__()
        self.set_data_type('xml')
        self.serviceInstanceArray = [ServiceInstanceSchema()]
        self._serviceid = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)