import result
import vmware.common.logger as logger
import neutron_client


class ServicesNodeFirewallConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeFirewallConfig object

        @param logical_services_node object on which ServicesNodeFirewallConfig object has to be configured
        """
        super(ServicesNodeFirewallConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'firewall_config_schema.FirewallConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-routers/" \
                                 + logical_services_node.id \
                                 +"/service-bindings/firewall/config")
        self.id = None

    def delete(self):
        self.id = None
        self.response = self.request('DELETE', self.delete_endpoint, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj

if __name__ == '__main__':
    import base_client
    import neutron
    from logical_services_node import LogicalServicesNode
    from logical_services_interface import LogicalServicesInterface

    log = logger.setup_logging("Neutron Load Balancer Test")
    neutron_object = neutron.Neutron("10.112.11.7", "admin", "default")

    logical_services_node_client = LogicalServicesNode(neutron=neutron_object)

    #Create New Logical Services Router
    py_dict = {'display_name': 'Router-1', 'capacity': 'SMALL',\
               'dns_settings':{'domain_name':'node1', 'primary_dns':'10.112.0.1', 'secondary_dns':'10.112.0.2'}}
    result_objs = base_client.bulk_create(logical_services_node_client, [py_dict])
    print "Create Logical Services Router Status code: %s" % result_objs[0].status_code
    print "Logical Services Router id: %s" % logical_services_node_client.id

    py_dict = {'address_groups': \
                   [{'secondary_ip_addresses': ['192.168.1.2'], \
                     'primary_ip_address': '192.168.1.1', \
                     'subnet': '24'}], \
               'interface_type': 'INTERNAL', \
               'interface_options': {\
                   'enable_proxy_arp': 0, \
                   'enable_send_redirects': 0}, \
               'display_name': 'intf-1', \
               'interface_number': 1}

    #Create New Logical Services Router Interface
    lsr_interface_client = LogicalServicesInterface(logical_services_node_client)
    schema_object = lsr_interface_client.get_schema_object(py_dict)
    result_obj = lsr_interface_client.create(schema_object)
    print "Create LSR Interface Status code: %s" % result_obj.status_code
    print "LSR Interface id: %s" % lsr_interface_client.id

    py_dict = {
        "display_name" : "Firewall-1",
        "default_policy": "ACCEPT",
        "global_config": {
        "icmp_timeout": 10,
        "ip_generic_timeout": 120,
        "tcp_timeout_close": 30,
        "tcp_timeout_established": 3600,
        "udp_timeout": 60,
        "icmp6_timeout": 10,
        "tcp_timeout_open": 30
        },
        "rules":  [
        {
            "display_name" : "Firewall-Rule-1",
            "rule_type":"USER",
            "action":"ACCEPT",
            "source":[],
            "destination":[],
            "services":[]
        }
        ]
    }

    firewall_config_client = ServicesNodeFirewallConfig(logical_services_node_client)
    result_obj = firewall_config_client.update(py_dict, True)
    print "Create Service Status code: %s" % result_obj.status_code

    firewall_config_client.id = None
    firewall_config_schema = firewall_config_client.read()

    #Delete Firewall configuration
    firewall_config_client.id = None
    result_obj = firewall_config_client.delete()
    print "Delete Firewall result response: %s" % result_obj.status_code

    #Delete Logical Services Router Interface
    result_obj = lsr_interface_client.delete()
    print "Delete LSR Interface result response: %s" % result_obj.status_code

    #Delete Logical Services Router
    result_obj = logical_services_node_client.delete()
    print "Delete result response: %s" % result_obj.status_code