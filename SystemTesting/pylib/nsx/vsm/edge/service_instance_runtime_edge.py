import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM
import service_instance_runtime_edge_schema

class ServiceInstanceRuntimeEdge(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create ServiceInstanceRuntimeEdge object

        @param edge object
        on which ServiceInstanceRuntimeEdge has to be configured
        """
        super(ServiceInstanceRuntimeEdge, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = \
            'service_instance_runtime_edge_schema.ServiceInstanceRuntimeEdgeSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/loadbalancer/serviceinstanceruntimes?action=install")
        self.create_as_put = False
        self.id = None

