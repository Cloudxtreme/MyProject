import base_schema
from deployed_cluster_schema import DeployedClusterSchema
from datastore_object_schema import DatastoreObjectSchema
from dvportgroup_schema import DVPortGroupSchema

class DeployedServiceStatusSchema(base_schema.BaseSchema):
    _schema_name = "deployedService"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstancesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DeployedServiceStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.deploymentUnitId = None
        self.serviceId = None
        self.cluster = DeployedClusterSchema()
        self.serviceName = None
        self.datastore = DatastoreObjectSchema()
        self.dvPortGroup = DVPortGroupSchema()
        self.upgradeAvailable = None
        self.progressStatus = None
        self.operationalStatus = None
        self.internalService = None
        self.upgradeNeedsNetworkAndDsSettings = None
        self.serviceStatus = None
        self.vibOnlyAgency = None
        self.visibleInFabricUI = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)