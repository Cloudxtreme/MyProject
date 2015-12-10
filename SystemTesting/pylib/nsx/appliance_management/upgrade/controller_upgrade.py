import base_client
import vmware.common.logger as logger
import result
from controller_upgrade_schema import ControllerUpgradeSchema
from controller_upgrade_capability_schema import ControllerUpgradeCapabilitySchema
from connection import Connection

class ControllerUpgrade(base_client.BaseClient):

    def __init__(self, nsx_appliance=None):
        """ Constructor to create ControllerUpgrade object

        @param vsm object on which ControllerUpgrade object has to be configured
        """
        super(ControllerUpgrade, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'controller_upgrade_schema.ControllerUpgradeSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.client_type = "vsm"
        if nsx_appliance != None:
            self.set_connection(nsx_appliance.get_connection())
        self.start_endpoint = '/vdn/controller/cluster/upgrade'
        self.capability_endpoint = 'vdn/controller/upgrade-available'
        self.create_endpoint = self.start_endpoint
        self.cluster_status_endpoint    = self.start_endpoint
        self.id = None

    def set_connection(self, vsm_conn):
        """ This method is needed to set the correct upgrade controller api version

        @param connection object to set
        """
        conn = Connection(vsm_conn.ip,
                          vsm_conn.username,
                          vsm_conn.password,
                          "api/2.0", vsm_conn.type)
        self.connection = conn

    def query_upgrade_capability(self):
        """
        Method to query controllers upgrade capability
        """
        self.response = self.request('GET', self.capability_endpoint, "")
        self.log.debug(self.response.status)
        response = self.response.read()
        capability_schema = ControllerUpgradeCapabilitySchema()
        capability_schema.set_data(response, self.accept_type)
        return capability_schema

    def query_controller_cluster_upgrade_status(self):
        """
        Method to query controllers cluster upgrade status
        """
        self.response = self.request('GET', self.cluster_status_endpoint, "")
        self.log.debug(self.response.status)
        response = self.response.read()
        status_schema = ControllerUpgradeSchema()
        status_schema.set_data(response, self.accept_type)
        return status_schema

    def create(self, schema_object):
        result_obj = super(ControllerUpgrade, self).create(schema_object)

        if result_obj[0].error is not None:
            return result_obj

        response_data = result_obj[0].get_response_data()
        response = result_obj[0].get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        if response_data is not None and response_data != "":
            self.id = response_data
        return result_obj

if __name__ == '__main__':
    pass
