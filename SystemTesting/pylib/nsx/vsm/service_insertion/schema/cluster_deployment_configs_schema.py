import base_schema
from cluster_deployment_config_schema import ClusterDeploymentConfigSchema

class ClusterDeploymentConfigsSchema(base_schema.BaseSchema):
    _schema_name = "clusterDeploymentConfigs"

    def __init__(self, py_dict=None):
        """ Constructor to create ClusterDeploymentConfigsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ClusterDeploymentConfigsSchema, self).__init__()
        self.set_data_type('xml')
        self.clusterDeploymentConfigArray = [ClusterDeploymentConfigSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)