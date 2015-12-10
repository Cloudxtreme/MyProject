from nsxapi_appliance_management_schema import NSXAPIApplianceManagementSchema
import vsm_client
import vmware.common.logger as logger
from vsm import VSM


class ReplicatorStatus(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(ReplicatorStatus, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nsxapi_appliance_management_schema.NSXAPIApplianceManagementSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("api/1.0")
        self.set_create_endpoint("appliance-management/components/component/NSXREPLICATOR/status")
        self.id = None
        self.update_as_post = False
