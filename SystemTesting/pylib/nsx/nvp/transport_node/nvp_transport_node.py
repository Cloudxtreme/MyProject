import vmware.common.logger as logger
import nvp_client
import connection
import nvp_transport_node_schema

class TransportNode(nvp_client.NVPClient):

    def __init__(self, nvp_controller=None):

        super(TransportNode, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_transport_node_schema.TransportNode'
        self.set_create_endpoint('transport-node')

        if nvp_controller != None:
            self.set_connection(nvp_controller.get_connection())

