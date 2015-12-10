import vmware.common.logger as logger
import neutron_client

class LogicalServicesNode(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create LogicalServicesNode object

        @param neutron object on which LogicalServicesNode object has to be configured
        """
        super(LogicalServicesNode, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'logical_services_node_schema.LogicalServicesNodeSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/lservices-routers')
        self.id = None


if __name__ == '__main__':
    import base_client
    import neutron
    log = logger.setup_logging('Neutron Logical Services Router Test')
    neutron_object = neutron.Neutron("10.112.11.7", "admin", "default")
    lsr_client = LogicalServicesNode(neutron=neutron_object)

    #Create New Logical Services Router
    py_dict = {'display_name': 'Router-1', 'capacity': 'SMALL',\
               'dns_settings':{'domain_name':'node1', 'primary_dns':'10.112.0.1', 'secondary_dns':'10.112.0.2'}}
    result_objs = base_client.bulk_create(lsr_client, [py_dict])
    print "Create Logical Services Router Status code: %s" % result_objs[0].status_code
    print "Logical Services Router id: %s" % lsr_client.id

    #Update Logical Services Router
    py_dict1 = {'display_name': 'Router-01', 'capacity': 'SMALL',\
               'dns_settings':{'domain_name':'node1', 'primary_dns':'10.112.0.1', 'secondary_dns':'10.112.0.2'}}
    result_obj = lsr_client.update(py_dict1)
    print "Update result response: %s" % result_obj.status_code

    #Delete Logical Services Router
    result_obj = lsr_client.delete()
    print "Delete result response: %s" % result_obj.status_code