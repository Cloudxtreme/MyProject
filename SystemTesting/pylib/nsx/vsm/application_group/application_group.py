import vmware.common.logger as logger
import vsm_client
import application_group_schema
from vsm import VSM

UNIVERSAL_SCOPE = 'universal'


class ApplicationGroup(vsm_client.VSMClient):

    def __init__(self, vsm=None, scope=None):
        """ Constructor to create ApplicationGroup object

        @param vsm object on which ApplicationGroup object has to be configured
        """
        super(ApplicationGroup, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'application_group_schema.ApplicationGroupSchema'
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint("/services/applicationgroup/universalroot-0")
        else:
            self.set_create_endpoint("/services/applicationgroup/globalroot-0")
        self.set_read_endpoint("/services/applicationgroup")
        self.set_delete_endpoint("/services/applicationgroup")
        self.id = None
        self.update_as_post = False