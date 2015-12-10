import result
import base_client
import edge_schema
from vsm import VSM
import vmware.common.global_config as global_config
import tasks

class GatewayServicesEdge(base_client.BaseClient):
    def __init__(self, vsm):
        """ Constructor to create GatewayServiceEdge object

        @param vsm object on which GatewayServiceEdge has to be configured
        """
        super(GatewayServicesEdge, self).__init__()
        self.log = global_config.pylogger
        self.schema_class = 'edge_schema.EdgeSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.set_connection(vsm.get_connection())
        self.connection.api_header = '/api/4.0'
        self.set_create_endpoint("/edges")
        self.id = None
        self.location_header = None

    @tasks.thread_decorate
    def create(self, schema_object):
        #result_obj = super(Edge, self).create(schema_object)
        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        response = result_obj.get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        if location is not None:
            self.id = location.split('/')[-1]
            result_obj.set_response_data(self.id)
        return result_obj

if __name__ == '__main__':
    var = '''
    <edge>
        <id>edge-11</id>
        <version>36</version>
        <status>deployed</status>
        <datacenterMoid>datacenter-2</datacenterMoid>
        <datacenterName>vsmDc</datacenterName>
        <tenant>default</tenant>
        <name>Edge-01</name>
        <fqdn>vShield-edge-11</fqdn>
        <enableAesni>true</enableAesni>
        <enableFips>false</enableFips>
        <vseLogLevel>info</vseLogLevel>
        <vnics>
            <vnic>
                <label>vNic_0</label>
                <name>Interface-1</name>
                <addressGroups>
                    <addressGroup>
                        <primaryAddress>192.168.0.1</primaryAddress>
                        <subnetMask>255.255.255.0</subnetMask>
                        <subnetPrefixLength>24</subnetPrefixLength>
                    </addressGroup>
                    <addressGroup>
                        <primaryAddress>192.168.200.1</primaryAddress>
                        <subnetMask>255.255.255.0</subnetMask>
                        <subnetPrefixLength>24</subnetPrefixLength>
                    </addressGroup>
                    <addressGroup>
                        <primaryAddress>198.169.0.1</primaryAddress>
                        <subnetMask>255.255.255.252</subnetMask>
                        <subnetPrefixLength>30</subnetPrefixLength>
                    </addressGroup>
                </addressGroups>
                <mtu>1500</mtu>
                <type>uplink</type>
                <isConnected>true</isConnected>
                <index>0</index>
                <portgroupId>virtualwire-1</portgroupId>
                <portgroupName>LS-1</portgroupName>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>false</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_1</label>
                <name>vnic1</name>
                <addressGroups>
                    <addressGroup>
                        <primaryAddress>192.172.0.1</primaryAddress>
                        <subnetMask>255.255.255.0</subnetMask>
                        <subnetPrefixLength>24</subnetPrefixLength>
                    </addressGroup>
                </addressGroups>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>true</isConnected>
                <index>1</index>
                <portgroupId>dvportgroup-21</portgroupId>
                <portgroupName>dvPortgroup1</portgroupName>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_2</label>
                <name>vnic2</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>2</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_3</label>
                <name>vnic3</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>3</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_4</label>
                <name>vnic4</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>4</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_5</label>
                <name>vnic5</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>5</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_6</label>
                <name>vnic6</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>6</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_7</label>
                <name>vnic7</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>7</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_8</label>
                <name>vnic8</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>8</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
            <vnic>
                <label>vNic_9</label>
                <name>vnic9</name>
                <addressGroups/>
                <mtu>1500</mtu>
                <type>internal</type>
                <isConnected>false</isConnected>
                <index>9</index>
                <enableProxyArp>false</enableProxyArp>
                <enableSendRedirects>true</enableSendRedirects>
            </vnic>
        </vnics>
        <appliances>
            <applianceSize>compact</applianceSize>
            <appliance>
                <highAvailabilityIndex>0</highAvailabilityIndex>
                <vcUuid>5003856f-a6e0-257e-203b-7c70a5b30d90</vcUuid>
                <vmId>vm-32</vmId>
                <resourcePoolId>domain-c7</resourcePoolId>
                <resourcePoolName>vsmCluster.0</resourcePoolName>
                <datastoreId>datastore-17</datastoreId>
                <datastoreName>local-0</datastoreName>
                <hostId>host-15</hostId>
                <hostName>10.110.28.172</hostName>
                <vmFolderId>group-v3</vmFolderId>
                <vmFolderName>vm</vmFolderName>
                <vmHostname>vShield-edge-11-0</vmHostname>
                <vmName>Edge-01-0</vmName>
                <deployed>true</deployed>
                <edgeId>edge-11</edgeId>
            </appliance>
        </appliances>
        <cliSettings>
            <remoteAccess>true</remoteAccess>
            <userName>admin</userName>
            <sshLoginBannerText>
    ***************************************************************************
    NOTICE TO USERS


    This computer system is the private property of its owner, whether
    individual, corporate or government.  It is for authorized use only.
    Users (authorized or unauthorized) have no explicit or implicit
    expectation of privacy.

    Any or all uses of this system and all files on this system may be
    intercepted, monitored, recorded, copied, audited, inspected, and
    disclosed to your employer, to authorized site, government, and law
    enforcement personnel, as well as authorized officials of government
    agencies, both domestic and foreign.

    By using this system, the user consents to such interception, monitoring,
    recording, copying, auditing, inspection, and disclosure at the
    discretion of such personnel or officials.  Unauthorized or improper use
    of this system may result in civil and criminal penalties and
    administrative or disciplinary action, as appropriate. By continuing to
    use this system you indicate your awareness of and consent to these terms
    and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the
    conditions stated in this warning.

    ****************************************************************************</sshLoginBannerText>
            <passwordExpiry>99999</passwordExpiry>
        </cliSettings>
        <features>
            <l2Vpn>
                <version>0</version>
                <enabled>false</enabled>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
            </l2Vpn>
            <featureConfig/>
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
            <sslvpnConfig>
                <version>5</version>
                <enabled>false</enabled>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
                <advancedConfig>
                    <enableCompression>false</enableCompression>
                    <forceVirtualKeyboard>false</forceVirtualKeyboard>
                    <randomizeVirtualkeys>false</randomizeVirtualkeys>
                    <preventMultipleLogon>false</preventMultipleLogon>
                    <clientNotification></clientNotification>
                    <enablePublicUrlAccess>false</enablePublicUrlAccess>
                    <timeout>
                        <forcedTimeout>0</forcedTimeout>
                        <sessionIdleTimeout>10</sessionIdleTimeout>
                    </timeout>
                </advancedConfig>
                <clientConfiguration>
                    <autoReconnect>true</autoReconnect>
                    <upgradeNotification>false</upgradeNotification>
                </clientConfiguration>
                <layoutConfiguration>
                    <portalTitle>VMware</portalTitle>
                    <companyName>VMware</companyName>
                    <logoExtention>jpg</logoExtention>
                    <logoUri>/3.0/edges/edge-1/sslvpn/config/layout/images/portallogo</logoUri>
                    <logoBackgroundColor>FFFFFF</logoBackgroundColor>
                    <titleColor>996600</titleColor>
                    <topFrameColor>000000</topFrameColor>
                    <menuBarColor>999999</menuBarColor>
                    <rowAlternativeColor>FFFFFF</rowAlternativeColor>
                    <bodyColor>FFFFFF</bodyColor>
                    <rowColor>F5F5F5</rowColor>
                </layoutConfiguration>
                <authenticationConfiguration>
                    <passwordAuthentication>
                        <authenticationTimeout>1</authenticationTimeout>
                        <primaryAuthServers/>
                        <secondaryAuthServer/>
                    </passwordAuthentication>
                </authenticationConfiguration>
            </sslvpnConfig>
            <dns>
                <version>5</version>
                <enabled>false</enabled>
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
                    </dnsView>
                </dnsViews>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
            </dns>
            <routing>
                <version>8</version>
                <enabled>true</enabled>
                <routingGlobalConfig>
                    <routerId>192.168.0.1</routerId>
                    <logging>
                        <enable>true</enable>
                        <logLevel>info</logLevel>
                    </logging>
                </routingGlobalConfig>
                <staticRouting>
                    <defaultRoute>
                        <vnic>0</vnic>
                        <mtu>1500</mtu>
                        <description></description>
                        <gatewayAddress>192.168.0.10</gatewayAddress>
                    </defaultRoute>
                    <staticRoutes/>
                </staticRouting>
            </routing>
            <highAvailability>
                <version>5</version>
                <enabled>false</enabled>
                <declareDeadTime>15</declareDeadTime>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
                <security>
                    <enabled>false</enabled>
                </security>
            </highAvailability>
            <syslog>
                <version>0</version>
                <enabled>false</enabled>
            </syslog>
            <featureConfig/>
            <loadBalancer>
                <version>0</version>
                <enabled>false</enabled>
                <enableServiceInsertion>false</enableServiceInsertion>
                <accelerationEnabled>false</accelerationEnabled>
                <gslbServiceConfig>
                    <listeners/>
                    <serviceTimeout>6</serviceTimeout>
                    <persistentCache>
                        <maxSize>20</maxSize>
                        <ttl>300</ttl>
                    </persistentCache>
                    <queryPort>5666</queryPort>
                </gslbServiceConfig>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
            </loadBalancer>
            <ipsec>
                <version>0</version>
                <enabled>false</enabled>
                <logging>
                    <enable>false</enable>
                    <logLevel>info</logLevel>
                </logging>
                <sites/>
                <global>
                    <caCertificates/>
                    <crlCertificates/>
                </global>
            </ipsec>
            <dhcp>
                <version>8</version>
                <enabled>true</enabled>
                <staticBindings/>
                <ipPools>
                    <ipPool>
                        <autoConfigureDNS>true</autoConfigureDNS>
                        <poolId>pool-1</poolId>
                        <ipRange>192.172.0.11-192.172.0.21</ipRange>
                        <defaultGateway>192.172.0.11</defaultGateway>
                        <domainName>vmware.com</domainName>
                        <leaseTime>infinite</leaseTime>
                    </ipPool>
                </ipPools>
                <logging>
                    <enable>true</enable>
                    <logLevel>info</logLevel>
                </logging>
            </dhcp>
            <nat>
                <version>7</version>
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
                    <natRule>
                        <ruleId>196611</ruleId>
                        <ruleTag>196611</ruleTag>
                        <ruleType>user</ruleType>
                        <action>snat</action>
                        <vnic>0</vnic>
                        <originalAddress>10.112.28.172</originalAddress>
                        <translatedAddress>192.168.0.1-192.168.0.255</translatedAddress>
                        <loggingEnabled>true</loggingEnabled>
                        <enabled>true</enabled>
                        <description>SNAT Rule for Interface-1</description>
                        <protocol>any</protocol>
                        <originalPort>any</originalPort>
                        <translatedPort>any</translatedPort>
                    </natRule>
                </natRules>
            </nat>
            <bridges>
                <version>5</version>
                <enabled>false</enabled>
            </bridges>
            <featureConfig/>
            <featureConfig/>
        </features>
        <autoConfiguration>
            <enabled>true</enabled>
            <rulePriority>high</rulePriority>
        </autoConfiguration>
        <type>gatewayServices</type>
        <hypervisorAssist>false</hypervisorAssist>
        <edgeAssistId>0</edgeAssistId>
        <queryDaemon>
            <enabled>false</enabled>
            <port>5666</port>
        </queryDaemon>
    </edge>
    '''

    log = logger.setup_logging('Gateway Services Edge - Test')
    vsm_obj = VSM("10.110.27.110", "admin", "default", "")

    edge_client = GatewayServicesEdge(vsm_obj)

    #Create Gateway Services Edge
    py_dict = {'datacentermoid': 'datacenter-422',
               'datacentername': '1-datacenter-1563',
               'tenant': 'default',
               'name': 'edge-1001',
               'enableaesni': True,
               'enablefips': False,
               'vseloglevel': 'info',
               'type': 'gatewayServices',
               'appliances': {'appliancesize': 'compact', 'deployappliances': False},
               'clisettings': {'remoteaccess': False, 'username': 'admin', 'password': 'default'},
               'autoconfiguration': {'enabled': True, 'rulepriority': 'high'},
               'querydaemon': {'enabled': True, 'port': 5666},
               'vnics': [{'label': 'vNic_0', 'name': 'NIC-1',
                                   'addressgroups': [{
                                                         'primaryaddress': '192.168.0.1',
                                                          'subnetmask': '255.255.255.224',
                                                          'subnetprefixlength': 27
                                                     }],
                                   'mtu': 1500, 'type': 'internal', 'isconnected': True, 'index': 0,
                                   'portgroupid': 'network-438', 'portgroupname': 'VM Network',
                                   'enableproxyarp': False, 'enablesendredirects': False
                                  }],
               }

    edge_schema_object = edge_client.get_schema_object(py_dict)
    #edge_schema_object.print_object()
    result_obj_1 = edge_client.create(edge_schema_object)
    print result_obj_1.status_code

    edge_schema = edge_client.read()
    edge_schema.print_object()

    #Delete Gateway Services Edge
    response_status = edge_client.delete()
    print response_status.status_code
