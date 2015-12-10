import vmware.common.logger as logger
import neutron_client


class ServicesNodeLoadBalancerConfig(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create ServicesNodeLoadBalancerConfig object

        @param logical_services_node object on which ServicesNodeLoadBalancerConfig object has to be configured
        """
        super(ServicesNodeLoadBalancerConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'load_balancer_config_schema.LoadBalancerConfigSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-routers/" \
                                 + logical_services_node.id \
                                 + "/service-bindings/loadbalancer/config")
        self.id = None

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

    #Configure Load Balancer Service
    py_dict1 = {\
        'virtual_servers': [\
            {\
                'protocol': 'HTTP',\
                'name': 'vs1',\
                'enabled': 1,\
                'acceleration_enabled': 1,\
                'connection_limit': 5,\
                'connection_rate_limit': 5,\
                'ip_address': '192.168.1.9',\
                'port': 8080\
            }\
        ],\
        'display_name': 'Load Balancer-1',\
        'application_rules': [\
            {\
                'rule_id': 'applicationRule-1',\
                'name': 'Rule1',\
                'script': 'capture request  header Host len 32'\
            }\
        ],\
        'pools': [\
            {\
                'name': 'Pool1',\
                'monitor_ids': ['monitor-1'],\
                'algorithm': 'round_robin',\
                'members': [\
                    {\
                        'monitor_port': 80,\
                        'min_conn': 0,\
                        'name': 'Member1',\
                        'weight': 100,\
                        'max_conn': 5,\
                        'member_id': 'member-1',\
                        'ip_address': '192.168.1.10',\
                        'port': 80,\
                        'max_retries': 5,\
                        'interval': 60,\
                        'timeout': 3600,\
                        'condition': 'enabled'\
                    }\
                ],\
                'pool_id': 'pool-1'\
            }\
        ],\
        'enabled': 1,\
        'acceleration_enabled': 1,\
        'monitors': [\
            {\
                'monitor_id': 'monitor-1',\
                'type': 'HTTP',\
                'name': 'Monitor1',\
                'method': 'POST'\
            }\
        ],\
        'logging':{\
                'enable': 1,\
                'log_level': 'INFO'
            }\
    }

    load_balancer_config_client = ServicesNodeLoadBalancerConfig(logical_services_node_client)
    result_obj = load_balancer_config_client.update(py_dict1, True)
    print "Create Service Status code: %s" % result_obj.status_code

    #Disable Load Balancer Service
    py_dict1 = {\
        'virtual_servers': [],\
        'display_name': 'Load Balancer-1',\
        'application_rules': [],\
        'pools': [],\
        'enabled': 0,\
        'acceleration_enabled': 0,\
        'monitors': [],\
        'logging':{\
                'enable': 0,\
                'log_level': 'INFO'
            }\
    }

    load_balancer_config_client = ServicesNodeLoadBalancerConfig(logical_services_node_client)
    result_obj = load_balancer_config_client.update(py_dict1, True)
    print "Disable Service Status code: %s" % result_obj.status_code

    #Delete Logical Services Router Interface
    result_obj = lsr_interface_client.delete()
    print "Delete LSR Interface result response: %s" % result_obj.status_code

    #Delete Logical Services Router
    result_obj = logical_services_node_client.delete()
    print "Delete result response: %s" % result_obj.status_code