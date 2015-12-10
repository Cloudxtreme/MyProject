import pylib
#import logger
import vsm_client
from edge import Edge
from vsm import VSM
from relay_schema import RelaySchema
import sys
sys.path.append('.')
#import xmltodict

class DHCPRelay(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create DHCPRELAY object

        @param edge object on which DHCP RELAY  has to be configured
        """
        super(DHCPRelay, self).__init__()
#        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'relay_schema.RelaySchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = 'api/4.0'
        self.set_create_endpoint("edges/" + edge.id + "/dhcp/config/relay")
        self.set_delete_endpoint("edges/" + edge.id + "/dhcp/config/relay")
        self.set_read_endpoint("edges/" + edge.id + "/dhcp/config/relay")
        self.id = None
        self.create_as_put = True

if __name__ == '__main__':
    var = '''
    <relay>
       <relayServer>
            <groupingObjectId>IPset1</groupingObjectId>
            <groupingObjectId>IPset2</groupingObjectId>
            <ipAddress>10.117.35.202</ipAddress>
            <fqdn>www.dhcpserver</fqdn>
       </relayServer>
       <relayAgents>
            <relayAgent>
               <vnicIndex>1</vnicIndex>
               <giAddress>192.168.1.254</giAddress>
            </relayAgent>
            <relayAgent>
               <vnicIndex>3</vnicIndex>
               <giAddress>192.168.3.254</giAddress>
            </relayAgent>
       </relayAgents>
    </relay>
    '''

    import base_client
#    log = logger.setup_logging('DHCP relay test for VDR')
    vsm_obj = VSM("10.144.139.49", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"
    dhcp_client = DHCPRelay(edge)
    py_dict = {'relayserver': {'ipaddress' : ['10.117.35.202', '10.117.35.203' ]} , 'relayagents': [ {'vnicindex' : '10', 'giaddress' : '172.31.1.1'},{ 'vnicindex' : '11', 'giaddress' : '172.32.1.1'}]}
    schema_obj = RelaySchema(py_dict)
    result_obj = dhcp_client.create(schema_obj)
    print result_obj.get_response_data()
