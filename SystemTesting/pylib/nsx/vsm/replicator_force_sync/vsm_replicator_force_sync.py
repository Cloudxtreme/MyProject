import vsm_client
import vmware.common.logger as logger


class ReplicatorForceSync(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to issue force sync on replicator
        @param vsm object on which IPSet has to be configured
        """
        super(ReplicatorForceSync, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("universalsync/sync?action=invoke")
        self.id = None
        self.update_as_post = False
