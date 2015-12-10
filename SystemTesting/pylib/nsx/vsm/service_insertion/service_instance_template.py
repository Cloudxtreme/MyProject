import vsm_client
import logger
import service_instance_template_schema
#import result
from vsm import VSM

class ServiceInstanceTemplate(vsm_client.VSMClient):
    def __init__(self, service=None):
        """ Constructor to create ServiceInstanceTemplate object

        @param vsm object on which ServiceInstanceTemplate has to be configured
        """
        super(ServiceInstanceTemplate, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_instance_template_schema.ServiceInstanceTemplateSchema'
        self.set_connection(service.get_connection())
        self.set_create_endpoint("/si/service/" + str(service.id) + "/serviceinstancetemplate")
        self.id = None
        self.update_as_post = False
