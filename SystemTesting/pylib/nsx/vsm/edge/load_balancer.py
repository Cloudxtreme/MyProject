import vmware.common.logger as logger
import vsm_client
from edge import Edge
from vsm import VSM


class LoadBalancer(vsm_client.VSMClient):
    def __init__(self, edge=None):
        """ Constructor to create LoadBalancer object

        @param edge object
        on which LoadBalancer has to be configured
        """
        super(LoadBalancer, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = \
            'edge_load_balancer_schema.LoadBalancerSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges/" + edge.id + "/loadbalancer/config")
        self.create_as_put = True
        self.id = None


if __name__ == '__main__':
    var = '''
    <loadBalancer>
        <version>3</version>
        <enabled>true</enabled>
        <enableServiceInsertion>true</enableServiceInsertion>
        <accelerationEnabled>true</accelerationEnabled>
        <applicationProfile>
            <applicationProfileId>applicationProfile-1</applicationProfileId>
            <persistence>
                <method>sourceip</method>
            </persistence>
            <name>Profile-1</name>
            <insertXForwardedFor>false</insertXForwardedFor>
            <sslPassthrough>false</sslPassthrough>
            <template>TCP</template>
        </applicationProfile>
        <applicationRule>
            <applicationRuleId>applicationRule-2</applicationRuleId>
            <name>App-Rule-1</name>
            <script>acl backup_page url_beg /backup
    use_backend pool-backup if backup_page</script>
        </applicationRule>
        <gslbServiceConfig>
            <enabled>false</enabled>
            <listeners/>
            <serviceTimeout>6</serviceTimeout>
            <persistentCache>
                <maxSize>20</maxSize>
                <ttl>300</ttl>
            </persistentCache>
            <queryPort>5666</queryPort>
        </gslbServiceConfig>
        <logging>
            <enable>true</enable>
            <logLevel>info</logLevel>
        </logging>
    </loadBalancer>
    '''

    log = logger.setup_logging('Gateway Services Edge DNS - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    load_balancer = LoadBalancer(edge)
    load_balancer_schema = load_balancer.read()
    load_balancer_schema.print_object()