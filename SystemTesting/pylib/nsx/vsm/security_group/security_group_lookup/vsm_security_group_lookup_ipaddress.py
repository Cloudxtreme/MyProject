import vmware.common.logger as logger
import vsm_client
from vsm import VSM


class SecurityGroupLookupIPAddress(vsm_client.VSMClient):

    def __init__(self, security_group=None, ip_address=None):
        """ Constructor to get translated IP addresses from
        security group

        @param security group object on which translation has to be checked
        """
        super(SecurityGroupLookupIPAddress, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_security_groups_schema.SecurityGroupsSchema'
        self.set_connection(security_group.get_connection())
        if ip_address is None:
            raise ValueError("IP Address to be used for lookup is None")
        self.set_create_endpoint(
            "/services/securitygroup/lookup/ipaddress/%s" % ip_address)

if __name__ == '__main__':
    from security_group import SecurityGroup
    vsm_obj = VSM("10.110.28.109", "admin", "default", "")
    security_group_client = SecurityGroupLookupIPAddress(vsm_obj, '192.168.1.1')

    result_obj = security_group_client.read()
    print result_obj.get_py_dict_from_object()


