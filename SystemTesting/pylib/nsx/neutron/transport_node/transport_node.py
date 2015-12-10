import vmware.common.logger as logger
import neutron_client

class TransportNode(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create TransportNode object

        @param neutron object on which TransportNode object has to be configured
        """
        super(TransportNode, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'transport_node_schema.TransportNodeSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/transport-nodes')
        self.id = None

if __name__ == '__main__':
    pass
