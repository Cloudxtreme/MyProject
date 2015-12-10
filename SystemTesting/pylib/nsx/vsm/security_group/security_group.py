import vmware.common.logger as logger
import vsm_client
import security_group_schema
from vsm import VSM

UNIVERSAL_SCOPE = 'universal'

class SecurityGroup(vsm_client.VSMClient):

    def __init__(self, vsm=None, scope=None):
        """ Constructor to create SecurityGroup object

        @param vsm object on which SecurityGroup object has to be configured
        """
        super(SecurityGroup, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'security_group_schema.SecurityGroupSchema'
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint("/services/securitygroup/universalroot-0")
        else:
            self.set_create_endpoint("/services/securitygroup/globalroot-0")
        self.set_read_endpoint("/services/securitygroup/scope/globalroot-0")
        self.set_delete_endpoint("/services/securitygroup")
        self.id = None
        self.update_as_post = False


if __name__ == '__main__':

    vsm_obj = VSM("10.144.139.32:443", "admin", "default", "")
    security_group_client = SecurityGroup(vsm_obj)

    py_dict = {"name":"apiTest1", "revision":"0"}
    schema_obj = security_group_schema.SecurityGroupSchema(py_dict)

    result_obj = security_group_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()

