import pylib
import vmware.common.logger as logger
import vsm_client
from vsm import VSM
from edge import Edge
import BGP_routing_schema


class BGP(vsm_client.VSMClient):
    """ Class to configure BGP on edge"""

    def __init__(self, edge=None):
        """ Constructor to create BGP Routing managed object

        @param edge object on which BGP will configured
        """
        super(BGP, self).__init__()
        self.log.debug("Configuring BGP on Edge %s" % edge.id)
        self.schema_class = 'BGP_routing_schema.BGPSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/routing/config/bgp")

        self.create_as_put = True
        self.id = None

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.24.20.234:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"
    SR_client = BGP(edge)
    py_dict = {
        'localas': '1000', 'bgpneighbours': [{'ipaddress': '20.20.20.2',
        'remoteas': '300'}], 'redistribution': {'enabled': 'true',
        'rules': [{'id': '0', 'action': 'permit',
        'fromprotocol': {'static':'true', 'connected': 'true'}}]}}
    schema_obj = bgp_routing_schema.BgpSchema(py_dict)
    result_obj = SR_client.create(schema_obj)
    print result_obj.get_response_data()
