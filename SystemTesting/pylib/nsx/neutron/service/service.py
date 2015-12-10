import vmware.common.logger as logger
import neutron
import neutron_client

class Service(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create Service object

        @param neutron object on which Service object has to be configured
        """
        super(Service, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_schema.ServiceSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/groupings/services')
        self.id = None

if __name__ == '__main__':
    import base_client
    log = logger.setup_logging('Neutron Services Test')
    neutron_object = neutron.Neutron("10.110.30.213:443", "localadmin", "default")
    service_client = Service(neutron=neutron_object)

    #Create New Service
    py_dict = {'schema': 'Service', 'display_name': 'Auto-Service-1', 'value': '101', 'application_protocol': 'TCP', 'source_port': '2345'}
    result_objs = base_client.bulk_create(service_client, [py_dict])
    print "Create Service Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response
    print "Service id: %s" % service_client.id

    #Update Service
    py_dict1 = {'schema': 'Service', 'display_name': 'Auto-Service-1', 'value': '101', 'application_protocol': 'UDP', 'source_port': '1234', 'revision':'2'}
    response_status = service_client.update(py_dict1)
    print "Update result response: %s" % response_status

    #Delete Service
    response_status = service_client.delete()
    print "Delete result response: %s" % response_status.status_code
