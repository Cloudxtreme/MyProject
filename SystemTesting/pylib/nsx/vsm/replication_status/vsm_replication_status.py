import vsm_client
import vmware.common.logger as logger
from vsm import VSM


class ReplicationStatus(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which Replication status has to be checked
        """
        super(ReplicationStatus, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_replication_status_schema.ReplicationStatusSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        self.set_create_endpoint("universalsync/status")
        self.id = None
        self.update_as_post = False


if __name__ == '__main__':
    from vmware.common.global_config import pylogger
    vsm_obj = VSM("10.110.25.146", "admin", "default", "")
    replication_status_client = ReplicationStatus(vsm_obj)

    result_obj = replication_status_client.read()
    pylogger.debug("LastSyncTime: %s" %
                   result_obj.nsxManagersStatusList[0].lastSuccessfulSyncTime)
    pylogger.debug("VSM ID: %s" %
        result_obj.nsxManagersStatusList[0].vsmId)
    pylogger.debug("SycnState: %s " %
                   result_obj.nsxManagersStatusList[0].syncState)

