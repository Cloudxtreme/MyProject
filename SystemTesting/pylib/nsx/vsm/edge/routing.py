import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM


class Routing(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create Routing object

        @param edge object
        on which Routing has to be configured
        """
        super(Routing, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'edge_routing_schema.EdgeRoutingSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/routing/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <routing>
        <version>8</version>
        <enabled>true</enabled>
        <routingGlobalConfig>
            <routerId>192.168.0.1</routerId>
            <logging>
                <enable>true</enable>
                <logLevel>info</logLevel>
            </logging>
        </routingGlobalConfig>
        <staticRouting>
            <defaultRoute>
                <vnic>0</vnic>
                <mtu>1500</mtu>
                <description></description>
                <gatewayAddress>192.168.0.10</gatewayAddress>
            </defaultRoute>
            <staticRoutes/>
        </staticRouting>
    </routing>
    '''

    log = logger.setup_logging('Gateway Services Edge Routing - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    routing = Routing(edge)
    routing_schema = routing.read()
    routing_schema.print_object()