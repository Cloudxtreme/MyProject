import base_client
from base_client import BaseClient
import base_schema
import connection
from expect_client import ExpectClient
import httplib
from ipdetection import IPDetection
from vsm_replicator_force_sync import ReplicatorForceSync
import vmware.common.logger as logger
import vsmconfig
import vsm_global_config_schema
import vc_info_schema


class VSM(BaseClient):
    ''' Class to store attributes and methods for VSM '''

    def __init__(self, ip, user, password, cert_thumbprint, version=None):
        ''' Constructor to create an instanc of VSM class

        @param ip:  ip address of VSM
        @param user: user name to create connection
        @param password: password to create connection
        '''

        super(VSM, self).__init__()
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.set_create_endpoint("services/vcconfig")
        self.schema_class = 'vc_info_schema.VCInfoSchema'

        if version == None or version == "":
            conn = connection.Connection(ip, user, password, "api/2.0", "https")
        else:
            conn = connection.Connection(ip, user, password, "api/" + version, "https")

        self.set_connection(conn)

    def init(self, py_dict):
        base_client.bulk_create(self, [py_dict])

    def get_expect_connection(self):
        ip = self.get_connection().ip
        expect_connection = connection.Connection(ip,
                                                  self.get_connection().username,
                                                  self.get_connection().password,
                                                  "None",
                                                  "expect")
        return expect_connection

    def get_id(self):
        vsm_config = vsmconfig.VsmConfig(self)
        return vsm_config.get_uuid()

    @staticmethod
    def terminate_expect_connection(expect_conn):
        expect_client = ExpectClient()
        expect_client.set_connection(expect_conn)

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint('\r')
        expect_client.set_expect_prompt('root@')
        # if the connection is on root shell
        # exit from from root shell
        try:
            expect_client.read()
            expect_client.set_create_endpoint('exit')
            expect_client.set_expect_prompt('>')
            expect_client.read()
        except:
            pass

        expect_client.set_create_endpoint('exit')
        expect_client.set_expect_prompt('')
        expect_client.read()

    def force_sync_replication(self, *args):
        replicator_force_sync_client = ReplicatorForceSync(self)
        result_obj = replicator_force_sync_client.create(None)
        if result_obj[0].get_status_code() == httplib.NO_CONTENT:
            return "SUCCESS"
        return "FAILURE"

    def configure_ip_detection(self, *args):
        # value of args[1] is
        # ['configure_ipdetection', {'arpsnoopenabled': 'true',
        #                            'scopeid': 'globalroot-0',
        #                            'dhcpsnoopenabled': 'false'}]
        # Extract schema dict from args[1]
        py_dict = args[1][1]
        ip_detection_client = IPDetection(self,scope=py_dict['scopeid'])
        result_obj = ip_detection_client.update(py_dict)
        if result_obj.get_status_code() == httplib.OK:
            return "SUCCESS"
        return "FAILURE"

if __name__=='__main__':
    py_dict = {'vcinfo': {'userName': 'root', 'password': 'vmware', 'ipaddress': '10.110.28.50'}}
    vsm_obj = VSM("10.110.28.44:443", "admin", "default","")
    vsm_obj.update(py_dict)
