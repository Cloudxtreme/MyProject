import vsm_client
import vmware.common.logger as logger
from urllib import urlencode


class VSMUniversalEntityReplicationStatus(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create VSMUniversalEntityReplicationStatus object

        @param vsm object on which Replication status has to be checked
        """
        super(VSMUniversalEntityReplicationStatus, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_entity_sync_status_schema.VSMEntitySyncStatusSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        self.set_create_endpoint("universalsync/entitystatus")
        self.id = None
        self.update_as_post = False

    def read(self, object_type=None, object_id=None):
        url_params = {
            'objectType': object_type,
            'objectId': object_id
        }
        return super(VSMUniversalEntityReplicationStatus, self).read(
            url_parameters=url_params)

if __name__ == '__main__':
    from vmware.common.global_config import pylogger
    from vsm import VSM
    vsm_obj = VSM("10.110.25.146", "admin", "default", "")
    replication_status_client = VSMUniversalEntityReplicationStatus(vsm_obj)
    entity_sync_schema = replication_status_client.read(
        object_type='SecurityGroup',
        object_id="securitygroup-3fdeb0d0-4fb6-4d8e-840e-430833b7d354")
    pylogger.info("VSMID: %s" % entity_sync_schema.elements[0].vsmId)
    pylogger.info("VSMID: %s" % entity_sync_schema.elements[1].vsmId)


