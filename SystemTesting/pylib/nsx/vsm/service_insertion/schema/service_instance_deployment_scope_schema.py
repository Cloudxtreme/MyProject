import base_schema
from service_instance_clusters_schema import ServiceInstanceClustersSchema
from datanetworks_schema import DatanetworksSchema
from runtime_nic_info_schema import RuntimeNicInfoSchema

class ServiceInstanceDeploymentScopeSchema(base_schema.BaseSchema):
    _schema_name = "deloymentScope"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceDeploymentScopeSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceDeploymentScopeSchema, self).__init__()
        self.set_data_type('xml')
        self.datastore = None
        self.clusters = ServiceInstanceClustersSchema()
        self.dataNetworks = DatanetworksSchema()
        self.nics = [RuntimeNicInfoSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
