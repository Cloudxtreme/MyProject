import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM
import static_routing_schema


class StaticRouting(vsm_client.VSMClient):
    """" Class to create static routing object on edge"""

    def __init__(self, edge=None):
        """ Constructor to create Static Routing object
        @param edge object
        on which static Routing has to be configured
        """
        super(StaticRouting, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'static_routing_schema.StaticRoutingSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/"+ edge.id + "/routing/config/static")
        self.create_as_put = True
        self.id = None

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.24.20.161:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-9"
    SR_client = StaticRouting(edge)
    py_dict = {
        'staticroutes': [{'network': '80.50.50.0/24',
        'nexthop': '3.3.3.123'}, {'network': '70.50.50.0/24',
        'nexthop': '3.3.3.125'}]}
    schema_obj = static_routing_schema.StaticRoutingSchema(py_dict)
    result_obj = SR_client.create(schema_obj)
    print result_obj.get_response_data()
