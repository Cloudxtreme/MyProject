import vsm_client
import vmware.common.logger as logger
import versioned_deployment_spec_schema
from vsm import VSM

class VersionedDeploymentSpec(vsm_client.VSMClient):
    def __init__(self, service=None):
        """ Constructor to create VersionedDeploymentSpec object
        @param vsm object on which Service has to be configured
        """
        super(VersionedDeploymentSpec, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'versioned_deployment_spec_schema.VersionedDeploymentSpecSchema'
        self.set_connection(service.get_connection())
        self.set_create_endpoint("/si/service/" + str(service.id) + "/servicedeploymentspec/versioneddeploymentspec")
        self.id = None

