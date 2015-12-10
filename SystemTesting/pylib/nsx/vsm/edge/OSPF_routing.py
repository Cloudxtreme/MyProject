import pylib
import vmware.common.logger as logger
import vsm_client
from vsm import VSM
from edge import Edge
import OSPF_routing_schema


class OSPF(vsm_client.VSMClient):
    """ Class to configure ospf on edge"""

    def __init__(self, edge=None):
        """ Constructor to create Ospf Routing managed object

        @param edge object on which BGP will configured
        """
        super(OSPF, self).__init__()
        self.log.debug("Configuring Ospf on Edge %s" % edge.id)
        self.schema_class = 'OSPF_routing_schema.OSPFSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/routing/config/ospf")

        self.create_as_put = True
        self.id = None

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.24.20.207:443", "admin", "default", "")
    edge = Edge(vsm_obj)
    edge.id = "edge-4"
    SR_client = OSPF(edge)
    py_dict = {
       'enabled': 'true',
       'ospfareas': [{'areaid': '1', 'type': 'nssa',
       'authentication': {'type': 'password', 'value':'pawan'}}],
       'ospfinterfaces': [{'vnic': '1', 'areaid': '1',
       'hellointerval': '10', 'deadinterval': '40',
       'priority': '128', 'cost': '1'}]}
    schema_obj = OSPF_routing_schema.OSPFSchema(py_dict)
    result_obj = SR_client.create(schema_obj)
    print result_obj.get_response_data()
