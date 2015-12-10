import base_schema
from deployed_service_status_schema import DeployedServiceStatusSchema

class DeployedServicesStatusSchema(base_schema.BaseSchema):
    _schema_name = "deployedServices"

    def __init__(self, py_dict=None):
        """ Constructor to create DeployedServicesStatusSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DeployedServicesStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.deployedServicesArray = [DeployedServiceStatusSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)