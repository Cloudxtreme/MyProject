import vsm_client
import vmware.common.logger as logger
import service_profile_binding_schema
from vsm import VSM

class ServiceProfileBinding(vsm_client.VSMClient):
    def __init__(self, serviceprofile=None):
        """ Constructor to create ServiceProfileBinding object
        @param vsm object on which ServiceProfileBinding has to be configured
        """
        super(ServiceProfileBinding, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_profile_binding_schema.ServiceProfileBindingSchema'
        self.set_connection(serviceprofile.get_connection())
        #create endpoint e.g. si/serviceprofile/serviceprofile-1/binding
        self.set_create_endpoint("/si/serviceprofile/" + str(serviceprofile.id) + "/binding")
        self.set_read_endpoint('si/serviceprofile/' + str(serviceprofile.id))
        self.id = None
        self.update_as_post = False

