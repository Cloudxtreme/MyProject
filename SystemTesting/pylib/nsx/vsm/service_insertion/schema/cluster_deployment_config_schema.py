import base_schema
from service_dep_schema import ServicesDepSchema

class ClusterDeploymentConfigSchema(base_schema.BaseSchema):
    _schema_name = "clusterDeploymentConfig"

    def __init__(self, py_dict=None):
        """ Constructor to create ClusterDeploymentConfigSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ClusterDeploymentConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.clusterId = None
        self.datastore = None
        self.services = [ServicesDepSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
