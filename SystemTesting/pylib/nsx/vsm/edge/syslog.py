import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM


class SysLog(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create SysLog object

        @param edge object on which SysLog has to be configured
        """
        super(SysLog, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'edge_syslog_schema.SysLogSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/syslog/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <syslog>
        <version>2</version>
        <enabled>true</enabled>
        <protocol>tcp</protocol>
        <serverAddresses>
            <ipAddress>10.110.28.172</ipAddress>
            <ipAddress>10.110.28.173</ipAddress>
        </serverAddresses>
    </syslog>
    '''

    log = logger.setup_logging('Gateway Services Edge DNS - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    syslog = SysLog(edge)
    syslog_schema = syslog.read()
    syslog_schema.print_object()