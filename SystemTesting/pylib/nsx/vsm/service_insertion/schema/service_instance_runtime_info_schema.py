import pylib
import base_schema
from service_instance_deployment_scope_schema import ServiceInstanceDeploymentScopeSchema

class ServiceInstanceRuntimeInfoSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstanceRuntimeInfo"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceRuntimeInfoSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceRuntimeInfoSchema, self).__init__()
        self.set_data_type('xml')
        self.status = None
        self.installState = None
        self.versionedDeploymentSpecId = None
        self.deloymentScope = ServiceInstanceDeploymentScopeSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    py_dict = {'installstate': 'INSTALLED', 'status': 'OUT_OF_SERVICE', 'versioneddeploymentspecid': 1484,
               'deloymentscope': {'clusters': {'string': ['domain-c55','domain-c56']}, 'datastore': 'datastore-63',
                                  'datanetworks': {'string': ['dvportgroup-72','dvportgroup-73']}
                                  }}
    deploy_schema = ServiceInstanceRuntimeInfoSchema(py_dict)
    print deploy_schema.get_data('xml')
