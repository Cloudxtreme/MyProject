import vmware.common.logger as logger
import vsm_client
from vsm import VSM


class SecurityGroupTranslateMACAddresses(vsm_client.VSMClient):

    def __init__(self, security_group=None,):
        """ Constructor to get translated MAC addresses from
        security group

        @param security group object on which translation has to be checked
        """
        super(SecurityGroupTranslateMACAddresses, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_mac_nodes_schema.MACNodesSchema'
        self.set_connection(security_group.get_connection())
        self.set_create_endpoint(
            "/services/securitygroup/%s/translation/macaddresses"
            % security_group.id)
        self.id = None
        self.update_as_post = False


if __name__ == '__main__':
    from security_group import SecurityGroup
    vsm_obj = VSM("10.110.25.146", "admin", "default", "")
    security_group_client = SecurityGroup(vsm_obj)
    security_group_client.id = "securitygroup-3fdeb0d0-4fb6-4d8e-840e-430833b7d354"

    translation_client = SecurityGroupTranslateMACAddresses(security_group_client)
    result_obj = translation_client.read()


