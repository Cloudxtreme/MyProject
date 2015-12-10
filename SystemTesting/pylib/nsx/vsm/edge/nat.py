import vmware.common.logger as logger
import vsm_client
import edge_nat_schema
from edge import Edge
from vsm import VSM


class NAT(vsm_client.VSMClient):
    def __init__(self, edge=None, version=None):
        """ Constructor to create NAT object

        @param edge object
        on which NAT has to be configured
        """
        super(NAT, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = \
            'edge_nat_schema.EdgeNATSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        if version == None or version == "":
            self.connection.api_header = '/api/4.0'
        else:
            self.connection.api_header = '/api/'+str(version)
        self.set_create_endpoint("/edges/" + edge.id + "/nat/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <nat>
        <version>6</version>
        <enabled>true</enabled>
        <natRules>
            <natRule>
                <ruleId>196609</ruleId>
                <ruleTag>196609</ruleTag>
                <ruleType>user</ruleType>
                <action>dnat</action>
                <vnic>0</vnic>
                <originalAddress>10.112.28.172</originalAddress>
                <translatedAddress>192.168.0.1-192.168.0.255</translatedAddress>
                <loggingEnabled>true</loggingEnabled>
                <enabled>true</enabled>
                <description></description>
                <protocol>any</protocol>
                <originalPort>any</originalPort>
                <translatedPort>any</translatedPort>
            </natRule>
        </natRules>
    </nat>
    '''

    log = logger.setup_logging('Gateway Services Edge NAT - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    nat = NAT(edge)
    nat_schema = nat.read()
    nat_schema.print_object()
