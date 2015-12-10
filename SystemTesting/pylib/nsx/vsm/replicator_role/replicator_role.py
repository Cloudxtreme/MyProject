import vsm_client
import vmware.common.logger as logger
from vsm import VSM
import tasks


class ReplicatorRole(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(ReplicatorRole, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'replicator_role_schema.ReplicatorRoleSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("universalsync/configuration/role")
        self.id = None
        self.update_as_post = False

    @tasks.thread_decorate
    def create(self, schema_object):
        desired_role = ""
        if hasattr(schema_object, 'role'):
            desired_role = schema_object.role
        self.set_create_endpoint("universalsync/configuration/role?action=set-as-%s" % desired_role)
        result_obj = super(ReplicatorRole, self).create(schema_object)
        return result_obj[0]
