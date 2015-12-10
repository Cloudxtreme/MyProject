from access_control_entry_schema import AccessControlEntrySchema
import vsm_client
import vmware.common.logger as logger
import result
from vsm import VSM
import tasks

class AccessControlEntry(vsm_client.VSMClient):
    """ Class to assign role using acess control """
    def __init__(self, vsm=None):
        """ Constructor to create AccessControlEntry managed object

        @param vsm object over which vdn scope has to be created
        """
        super(AccessControlEntry, self).__init__()
        self.schema_class = 'access_control_entry_schema.AccessControlEntrySchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("api/2.0")
        #Endpoint is services/usermgmt/role/<VCUser>
        #Assuming root will always be the VC user in testing
        self.set_create_endpoint("/services/usermgmt/role/administrator@vsphere.local")
        self.id = None

    @tasks.thread_decorate
    def create(self, schema_object):
        desired_role = ""
        if hasattr(schema_object, 'role'):
            desired_role = schema_object.role
        #Read and see if root VC user already has the role
        #If yes, then just return """
        access_control_entry = self.read()
        if hasattr(access_control_entry, 'role'):
            if access_control_entry.role == desired_role:
                self.log.debug("root already has role %s" % access_control_entry.role)
                result_obj = result.Result()
                result_obj.set_status_code('200')
                return result_obj
        #It comes here means root does not have this desired role
        #So assigning this role to root """
        result_obj = super(AccessControlEntry, self).create(schema_object)
        return result_obj[0]
