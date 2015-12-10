import vmware.common.logger as logger
import vsm_client
import edge_high_availability_schema
from edge import Edge
from vsm import VSM


class HighAvailability(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create HighAvailability object

        @param edge object
        on which HighAvailability has to be configured
        """
        super(HighAvailability, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = \
            'edge_high_availability_schema.HighAvailabilitySchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/highavailability/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <highAvailability>
        <version>7</version>
        <enabled>true</enabled>
        <vnic>any</vnic>
        <ipAddresses>
            <ipAddress>192.180.0.1/30</ipAddress>
            <ipAddress>192.180.0.2/30</ipAddress>
        </ipAddresses>
        <declareDeadTime>15</declareDeadTime>
        <logging>
            <enable>false</enable>
            <logLevel>info</logLevel>
        </logging>
        <security>
            <enabled>false</enabled>
        </security>
    </highAvailability>
    '''

    log = logger.setup_logging('Gateway Services Edge DNS - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    high_availability = HighAvailability(edge)
    high_availability_schema = high_availability.read()
    high_availability_schema.print_object()