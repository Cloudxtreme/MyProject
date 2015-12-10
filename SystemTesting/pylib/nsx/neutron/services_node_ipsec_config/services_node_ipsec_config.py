import neutron_client
import vmware.common.logger as logger


class ServicesNodeIpSecConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeIpSecConfig object

        @param logical_services_node object on which ServicesNodeIpSecConfig object has to be configured
        """
        super(ServicesNodeIpSecConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'ipsec_config_schema.IpSecConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-nodes/" + logical_services_node.id + "/service-bindings/ipsec/config")
        self.id = None

if __name__ == '__main__':
    pass