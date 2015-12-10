import result
import vmware.common.logger as logger
import neutron_client


class ServicesNodeDhcpConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeDhcpConfig object

        @param logical_services_node object on which ServicesNodeDhcpConfig object has to be configured
        """
        super(ServicesNodeDhcpConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'dhcp_config_schema.DhcpConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-routers/" \
                                 + logical_services_node.id \
                                 +"/service-bindings/dhcp/config")
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

    #Configure DHCP
    py_dict1 = {'display_name': 'DHCP-1',\
                'enabled': 1,\
                'config_elements':[\
                    {'enabled': 1, \
                     'ip_ranges': [{'range':'192.168.1.105-192.168.1.120'}],\
                     'interface_id': lsr_interface_client.id ,\
                     'dhcp_options':{\
                         'routers':['192.168.1.2'],\
                         'default_lease_time':'1000',\
                         'domain_name':'vmware.com',\
                         'hostname':'host1'}}],\
                     'dhcp_options':{\
                         'routers':['192.168.1.2'],\
                         'default_lease_time':'1000',\
                         'domain_name':'vmware.com',\
                         'hostname':'host1'}}

    dhcp_config_client = ServicesNodeDhcpConfig(logical_services_node_client)
    result_obj = dhcp_config_client.update(py_dict1, True)
    print "Create Service Status code: %s" % result_obj.status_code

    #Delete DHCP configuration
    result_obj = dhcp_config_client.delete()
    print "Delete DHCP result response: %s" % result_obj.status_code

    #Delete Logical Services Router Interface
    result_obj = lsr_interface_client.delete()
    print "Delete LSR Interface result response: %s" % result_obj.status_code

    #Delete Logical Services Router
    result_obj = logical_services_node_client.delete()
    print "Delete result response: %s" % result_obj.status_code