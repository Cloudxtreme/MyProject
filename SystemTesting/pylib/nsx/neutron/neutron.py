from base_client import BaseClient
import connection
import inspect
import json
import time

from cluster_nodes import ClusterNodes
from add_member_to_cluster_request_schema import AddMemberToClusterRequest
from nsxapi_appliance_management import NSXAPIApplianceManagement
from nsxapi_appliance_management_schema import NSXAPIApplianceManagementSchema
from neutron_backup import ConfigSnapshot
from neutron_operating_mode import OperatingMode
from vsm import VSM

class Neutron(BaseClient):
    ''' Class to store attributes and methods for Neutron '''

    def init_neutron(self, ip, user, password):

        # Starting NSXAPI server
        vsm = VSM(ip, user, password, "", "1.0")
        appliance = NSXAPIApplianceManagement(vsm)
        appliance_schema = NSXAPIApplianceManagementSchema({})
        appliance.create(appliance_schema)
        time.sleep(10)
        appliance.read()
        time.sleep(30)

        cluster_nodes = ClusterNodes(self)
        cluster_nodes_schema = cluster_nodes.query()

        for result in cluster_nodes_schema.results:
            if result.host_address == ip:
                self.id = result.id

        return self.id

    def delete_neutron(self, ip, user, password):
        ''' Method for stopping NSXAPI Server and clearing its inventory
        @param ip:  ip address of Neutron
        @param user: user name to create connection
        @param password: password to create connection
        '''

        # Stopping and clearing NSXAPI server
        vsm = VSM(ip, user, password, "", "1.0")
        appliance = NSXAPIApplianceManagement(vsm)
        appliance.stop()

        retry_count = 1
        while retry_count < 15:
            time.sleep(10)
            status_object = appliance.read()
            if status_object.result == "STOPPED":
                break
            retry_count = retry_count + 1

        appliance.clear()

    def __init__(self, ip, user, password):
        ''' Constructor to create an instance of Neutron class

        @param ip:  ip address of Neutron
        @param user: user name to create connection
        @param password: password to create connection
        '''

        super(Neutron, self).__init__()

        conn = connection.Connection(ip, user, password, "nsxapi/api/v1/", "https")
        self.set_connection(conn)

    def get_id(self):
        cluster_nodes = ClusterNodes(self)
        cluster_nodes_schema = cluster_nodes.query()
        self.id = cluster_nodes_schema.results[0].id
        return self.id

    def get_id(self,response):
        response_object = json.loads(response)
        # There is currently no id associated with nvp which is different from VSM registrations.
        # But, this is a placeholder if an id gets associated with a nvp controller
        return None

    def change_operating_mode(self, py_dict):
        omc = OperatingMode(self)
        result_obj = omc.update(py_dict)
        return result_obj

    def backup(self, payload):
        csc = ConfigSnapshot(self)
        result_obj = csc.get(payload['file'])
        return result_obj

    def restore(self, payload):
        csc = ConfigSnapshot(self)
        result_obj = csc.update(payload['file'])
        return result_obj

if __name__=='__main__':
    neutron_obj = Neutron("10.110.30.213:443", "localadmin", "default")
