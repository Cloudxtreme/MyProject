import base_client
import vmware.common.logger as logger
import deployment_scope_schema
from vsm import VSM

class DeploymentScope(base_client.BaseClient):
    def __init__(self, service=None):
        """ Constructor to create DeploymentScope object

        @param service object
        """
        super(DeploymentScope, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'deployment_scope_schema.DeploymentScopeSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.set_connection(service.get_connection())
        #endpoint e.g. si/service/service-1/servicedeploymentspec/deploymentscope
        self.create_endpoint = 'si/service/' + str(service.id) + '/servicedeploymentspec/deploymentscope'
        self.id = None
        self.update_as_post = False

    def read(self):
        si = deployment_scope_schema.DeploymentScope()
        si.set_data(self.base_read())
        return si