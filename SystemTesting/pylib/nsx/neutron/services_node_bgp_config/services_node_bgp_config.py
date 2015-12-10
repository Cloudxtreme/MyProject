import neutron_client
import vmware.common.logger as logger


class ServicesNodeBgpConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeBgpConfig object

        @param logical_services_node object on which ServicesNodeBgpConfig object has to be configured
        """
        super(ServicesNodeBgpConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'bgp_config_schema.BgpConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-nodes/" + logical_services_node.id + "/service-bindings/routing/bgp")
        self.id = None

if __name__ == '__main__':
    pass