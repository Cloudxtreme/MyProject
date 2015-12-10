import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM
import routing_global_config_schema

class GlobalRouting(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create Global Routing object
        @param edge object
        on which global Routing has to be configured
        """
        super(GlobalRouting, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'routing_global_config_schema.RoutingGlobalConfigSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/routing/config/global")
        self.create_as_put = True
        self.id = None

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.24.20.24:443", "admin", "default", "")
    edge = Edge(vsm_obj)
    edge.id = "edge-5"
    SR_client = GlobalRouting(edge)
    py_dict = { 'ecmp': 'true'}
    schema_obj = routing_global_config_schema.RoutingGlobalConfigSchema(py_dict)
    result_obj = SR_client.create(schema_obj)
    print result_obj.get_response_data()

