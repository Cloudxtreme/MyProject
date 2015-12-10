import vmware.common.logger as logger
import neutron_client


class TransportNodeCluster(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create TransportNodeCluster object

        @param neutron object on which TransportNodeCluster object has to be configured
        """
        super(TransportNodeCluster, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'transport_node_cluster_schema.TransportNodeClusterSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/transport-clusters')
        self.id = None


if __name__ == '__main__':
    pass