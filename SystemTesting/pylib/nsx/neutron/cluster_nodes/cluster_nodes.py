import json
import time

from add_member_to_cluster_request_schema import AddMemberToClusterRequest
import base_client
import neutron_client
import neutron
import vmware.common.logger as logger
import neutron_result
from neutron_cluster_node_result_list import ResultList
from neutron_tasks import NeutronTasks
from neutron_tasks_schema import NeutronTasksSchema
from neutron_tasks_response import NeutronTasksResponse
from neutron_tasks_response_schema import NeutronTasksResponseSchema
from node_config_schema import NodeConfigSchema
from nsxapi_appliance_management_schema  import NSXAPIApplianceManagementSchema
from nsxapi_appliance_management import NSXAPIApplianceManagement
from vsm import VSM

import result

class ClusterNodes(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create add neutron nodes to cluster

        @param neutron cluster to which neutron node is to be attached
        """
        super(ClusterNodes, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'add_member_to_cluster_request_schema.AddMemberToClusterRequest'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/cluster/nodes')
        self.id = None
        self.update_as_post = False

    def read(self):
        """ Client method to perform READ operation """
        schema_object = NodeConfigSchema()
        if self.id is not None:
            self.response = self.request('GET', self.read_endpoint + "/" + self.id, "")
        else:
            self.response = self.request('GET', self.read_endpoint, "")
        self.log.debug(self.response.status)
        payload_schema = self.response.read()

        schema_object.set_data(payload_schema, self.accept_type)

        return schema_object

    def delete(self, schema_object=None):
        """ Client method to perform DELETE operation """
        neutron_cluster_node = self.read()
        result_obj = super(ClusterNodes, self).delete(schema_object)
        conn = self.get_connection()

        neutron_client = neutron.Neutron(neutron_cluster_node.host_address,
                                         conn.username,
                                         conn.password)
        neutron_client.delete_neutron(neutron_cluster_node.host_address,
                                      conn.username,
                                      conn.password)
        time.sleep(30)
        self.reboot_cluster()
        time.sleep(60)

        return result_obj

    def reboot_cluster(self):
        ''' Method for reboot all NSXAPI servers that are in a cluster with this node

        '''
        neutron_result_list_schema = self.query()
        for neutron_result_schema in neutron_result_list_schema.results:
            conn = self.get_connection()
            vsm = VSM(neutron_result_schema.host_address,
                      conn.username, conn.password, "", "1.0")
            appliance = NSXAPIApplianceManagement(vsm)
            appliance_schema = NSXAPIApplianceManagementSchema({})
            appliance.stop()
            #TODO: Add polling mechanism
            time.sleep(30)
            appliance.create(appliance_schema)
            appliance.read()

    def create(self, r_schema):
        add_member_to_cluster_schema = r_schema
        result_obj = super(ClusterNodes, self).create(add_member_to_cluster_schema)
        data = None
        if result_obj.status_code == int(403):
            result = neutron_result.Result()
            data = result_obj.get_response_data()
            result.set_data(data, self.accept_type)
            if add_member_to_cluster_schema.cert_thumbprint == '' or \
                    add_member_to_cluster_schema.cert_thumbprint is None:
                add_member_to_cluster_schema.cert_thumbprint = result.errorData.thumbprint
                result_obj = super(ClusterNodes, self).create(add_member_to_cluster_schema)
                data = result_obj.get_response_data()

        conn = self.get_connection()
        neutron_instance = neutron.Neutron(conn.ip, conn.username, conn.password)

        done = 0
        retries = 0
        tasks = NeutronTasks(neutron_instance)
        task_schema = NeutronTasksSchema()
        task_schema.set_data(data, self.accept_type)
        while done == 0:
            tasks.id = task_schema.id
            if task_schema.status == "success":
                done = 1
            else:
                if task_schema.status != "running":
                    break
                time.sleep(30)
                task_schema = tasks.read()
                retries = retries + 1
                if retries > 5:
                    break

        tasks_response = NeutronTasksResponse(tasks)
        tasks_response_schema = tasks_response.read()
        result_obj.response = tasks_response_schema.get_data(self.accept_type)
        self.id = tasks_response_schema.id
        result_obj.response_data = result_obj.response
        return result_obj

    def query(self):
        """ Method to perform GET operation """

        self.response = self.request('GET', self.read_endpoint)
        self.log.debug(self.response.status)
        response = self.response.read()
        neutron_result_list_schema = ResultList()
        neutron_result_list_schema.set_data(response, self.accept_type)

        return neutron_result_list_schema

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
