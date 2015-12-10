import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM


class DNS(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create DNS object

        @param edge object on which DNS has to be configured
        """
        super(DNS, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'edge_dns_schema.DNSSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/dns/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <dns>
        <version>6</version>
        <enabled>true</enabled>
        <cacheSize>16</cacheSize>
        <listeners>
            <vnic>any</vnic>
        </listeners>
        <dnsViews>
            <dnsView>
                <viewId>view-0</viewId>
                <name>vsm-default-view</name>
                <enabled>true</enabled>
                <viewMatch>
                    <ipAddress>any</ipAddress>
                    <vnic>any</vnic>
                </viewMatch>
                <recursion>false</recursion>
                <forwarders>
                    <ipAddress>10.112.0.1</ipAddress>
                    <ipAddress>10.112.0.2</ipAddress>
                </forwarders>
            </dnsView>
        </dnsViews>
        <logging>
            <enable>true</enable>
            <logLevel>info</logLevel>
        </logging>
    </dns>
    '''

    log = logger.setup_logging('Gateway Services Edge DNS - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    dns = DNS(edge)
    dns_schema = dns.read()
    dns_schema.print_object()