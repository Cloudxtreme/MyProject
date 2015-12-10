import neutron_client
import vmware.common.logger as logger
import neutron
from neutron_tasks_schema import NeutronTasksSchema

class NeutronTasks(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create add neutron nodes to cluster

        @param neutron cluster to which neutron node is to be attached
        """
        super(NeutronTasks, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'neutron_tasks_schema.NeutronTasksSchema'
        self.set_content_type('application/json')
        self.set_accept_type('application/json')
        self.auth_type = "neutron"
        self.client_type = "neutron"

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/tasks')
        self.id = None
        self.update_as_post = False

if __name__ == '__main__':
    log = logger.setup_logging('Neutron IPSet Test')
    neutron_object = neutron.Neutron("10.110.30.255:443", "localadmin", "default")
    cl_nodes = ClusterNodes(neutron=neutron_object)

    #Add new node to existing cluster
    py_dict = {'user_name': 'localadmin', 'remote_address': '10.110.27.77:443',
               'password': 'default', 'cert_thumbprint': ''}
    result_objs = base_client.bulk_create(cl_nodes, [py_dict])
    print "Create IPSet Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response
    print "IPSet id: %s" % cl_nodes.id
