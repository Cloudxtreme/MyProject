import base_schema
from runtime_nic_info_schema import RuntimeNicInfoSchema

class LoadBalancerGlobalServiceInstanceSchema(base_schema.BaseSchema):
    _schema_name = "globalServiceInstance"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGlobalServiceInstanceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerGlobalServiceInstanceSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.serviceId = None
        self.instanceTemplateUniqueId = None
        self.runtimenicinfoarray = [RuntimeNicInfoSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
