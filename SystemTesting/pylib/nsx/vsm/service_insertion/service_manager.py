import vsm_client
import vmware.common.logger as logger
import service_manager_schema
from vsm import VSM

class ServiceManager(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create ServiceManager object
        @param vsm object on which ServiceManager has to be configured
        """
        super(ServiceManager, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_manager_schema.ServiceManagerSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/si/servicemanager")
        self.id = None

