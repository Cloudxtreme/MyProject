import vmware.common.logger as logger
import vsm_client


class IPDetection(vsm_client.VSMClient):

    def __init__(self, vsm=None, scope=None):
        """ Constructor to create IPDetection object

        @param vsm object on which IPDetection type has to be configured
        """
        super(IPDetection, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'ipdetection_schema.IPDetectionSchema'
        self.set_connection(vsm.get_connection())
        if scope is not None:
            self.set_create_endpoint("services/iprepository/config/scope/%s" % scope)
        else:
            self.set_create_endpoint("services/iprepository/config/scope/globalroot-0")
        self.id = None
        self.update_as_post = False
