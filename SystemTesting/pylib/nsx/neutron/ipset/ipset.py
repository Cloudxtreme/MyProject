import vmware.common.logger as logger
from ipset_schema import IPSetSchema
import neutron_client
import neutron


class IPSet(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create IPSet object

        @param neutron object on which IPSet object has to be configured
        """
        super(IPSet, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'ipset_schema.IPSetSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/groupings/ipsets')
        self.id = None

if __name__ == '__main__':
    import base_client
    log = logger.setup_logging('Neutron IPSet Test')
    neutron_object = neutron.Neutron("10.110.30.213:443", "localadmin", "default")
    ipset_client = IPSet(neutron=neutron_object)

    #Create New IPSet
    py_dict = {'schema': 'IPSet', 'display_name': 'IPSet-1', 'value': '192.168.0.101'}
    result_objs = base_client.bulk_create(ipset_client, [py_dict])
    print "Create IPSet Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response
    print "IPSet id: %s" % ipset_client.id

    #Update IPSet
    py_dict1 = {'schema': 'IPSet', 'display_name': 'IPSet-1', 'value': '192.168.100.101', 'revision':'2'}
    response_status = ipset_client.update(py_dict1)
    print "Update result response: %s" % response_status

    #Delete IPSet
    response_status = ipset_client.delete()
    print "Delete result response: %s" % response_status.status_code
