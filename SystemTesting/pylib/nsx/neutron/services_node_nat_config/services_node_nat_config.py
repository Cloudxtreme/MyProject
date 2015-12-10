import neutron_client
import vmware.common.logger as logger


class ServicesNodeNatConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeNatConfig object

        @param logical_services_node object on which ServicesNodeNatConfig object has to be configured
        """
        super(ServicesNodeNatConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nat_config_schema.NatConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-nodes/" + logical_services_node.id + "/service-bindings/nat/config")
        self.id = None

if __name__ == '__main__':
    pass