import vmware.common.logger as logger
import vsm_client
import edge_firewall_schema
import result
from edge import Edge
from vsm import VSM
import tasks

class Firewall(vsm_client.VSMClient):
    def __init__(self, edge=None, version=None):
        """ Constructor to create Firewall object

        @param edge object
        on which Firewall has to be configured
        """
        super(Firewall, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = \
            'edge_firewall_schema.FirewallSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        if version == None or version == "":
            self.connection.api_header = '/api/4.0'
        else:
            self.connection.api_header = '/api/'+str(version)
        self.set_create_endpoint("/edges/" + edge.id + "/firewall/config")
        self.set_read_endpoint("/edges/" + edge.id + "/firewall/config")
        self.create_as_put = True
        self.id = None

    @tasks.thread_decorate
    def create(self, schema_object):
        """ Client method to perform create operation

        @param schema_object instance of BaseSchema class
        @return result object
        """

        if self.create_as_put:
               self.log.error('This is workaround, File a PR, '+
                  'create should not be a PUT call')
               self.response = self.request('PUT', self.create_endpoint,
                                            schema_object.get_data_without_empty_tags(self.content_type))
        else:
            if schema_object is not None:
                self.response = self.request('POST', self.create_endpoint,
                                             schema_object.get_data_without_empty_tags(self.content_type))
            else:
                self.response = self.request('POST', self.create_endpoint)

        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj


if __name__ == '__main__':
    var = '''
    <firewall>
        <version>1</version>
        <enabled>true</enabled>
        <globalConfig>
            <tcpPickOngoingConnections>false</tcpPickOngoingConnections>
            <tcpAllowOutOfWindowPackets>false</tcpAllowOutOfWindowPackets>
            <tcpSendResetForClosedVsePorts>true</tcpSendResetForClosedVsePorts>
            <dropInvalidTraffic>true</dropInvalidTraffic>
            <logInvalidTraffic>false</logInvalidTraffic>
            <tcpTimeoutOpen>30</tcpTimeoutOpen>
            <tcpTimeoutEstablished>3600</tcpTimeoutEstablished>
            <tcpTimeoutClose>30</tcpTimeoutClose>
            <udpTimeout>60</udpTimeout>
            <icmpTimeout>10</icmpTimeout>
            <icmp6Timeout>10</icmp6Timeout>
            <ipGenericTimeout>120</ipGenericTimeout>
        </globalConfig>
        <defaultPolicy>
            <action>deny</action>
            <loggingEnabled>false</loggingEnabled>
        </defaultPolicy>
        <firewallRules>
            <firewallRule>
                <id>131074</id>
                <ruleTag>131074</ruleTag>
                <name>firewall</name>
                <ruleType>internal_high</ruleType>
                <action>accept</action>
                <enabled>true</enabled>
                <loggingEnabled>false</loggingEnabled>
                <description>firewall</description>
                <source>
                    <vnicGroupId>vse</vnicGroupId>
                </source>
            </firewallRule>
            <firewallRule>
                <id>131075</id>
                <ruleTag>131075</ruleTag>
                <name>dhcp</name>
                <ruleType>internal_high</ruleType>
                <action>accept</action>
                <enabled>true</enabled>
                <loggingEnabled>false</loggingEnabled>
                <description>dhcp</description>
                <destination>
                    <vnicGroupId>vnic-index-1</vnicGroupId>
                </destination>
                <application>
                    <service>
                        <protocol>udp</protocol>
                        <port>67</port>
                        <sourcePort>any</sourcePort>
                    </service>
                </application>
            </firewallRule>
            <firewallRule>
                <id>131073</id>
                <ruleTag>131073</ruleTag>
                <name>default rule for ingress traffic</name>
                <ruleType>default_policy</ruleType>
                <action>deny</action>
                <enabled>true</enabled>
                <loggingEnabled>false</loggingEnabled>
                <description>default rule for ingress traffic</description>
            </firewallRule>
        </firewallRules>
    </firewall>
    '''

    log = logger.setup_logging('Gateway Services Edge Firewall - Test')
    vsm_obj = VSM("10.110.26.12:443", "admin", "default", "")

    edge = Edge(vsm_obj)
    edge.id = "edge-1"

    firewall = Firewall(edge)
    firewall_schema = firewall.read()
    firewall_schema.print_object()
