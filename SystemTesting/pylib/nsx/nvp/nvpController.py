import json
import sys
import time

from base_client import BaseClient
import connection

from cloudnet import CloudNet
from utilities import wait_until

class NVPController(BaseClient):
    ''' Class to store attributes and methods for NVP '''

    # This function initializes the nvp controller once it is deployed.
    # TODO Please generate ssh key on the host running this script
    def init_nvp_controller(self,ip):
        """
        cloudnet_obj = CloudNet(ip, set_root_ssh_access=False, auth=True,
                     auth_cli=True, set_ntp=False, manager_transport=None,
                     manager_port=None, parent=None, debug=True)
        """

        cloudnet_obj = CloudNet(ip, passwd='nicira', auth=False, set_ntp=False, debug=True)
        cloudnet_obj.ncli.set_root_ssh_access()
        cloudnet_obj.perm_auth_expect(passwd='nicira')
        # This also restarts api server
        cloudnet_obj.ncli.set_service_certificate()
        wait_until(cloudnet_obj.api_is_listening, minimum=15)
        # Clear Controller
        cloudnet_obj.ncli.clear_runtime_state(force=True)
        cloudnet_obj.ncli.set_management_address(ip)
        cloudnet_obj.ncli.join_cluster(ip, force=True)
        cloudnet_obj.ncli.set_root_ssh_access()
        cloudnet_obj.perm_auth_expect(passwd='nicira')
        cloudnet_obj.connect()


    def __init__(self, ip, user, password):
        ''' Constructor to create an instance of NVP controller

        @param ip:  ip address of NVP Controller
        @param user: user name to create connection
        @param password: password to create connection
        '''

        super(NVPController, self).__init__()
        conn = connection.Connection(ip, user, password, "ws.v1", "https")
        self.set_connection(conn)
        self.id = None

    def get_id(self,response):
        response_object = json.loads(response)
        return None

if __name__=='__main__':
    nvp_controller__obj = NVPController("10.24.20.204:443", "admin", "admin")
