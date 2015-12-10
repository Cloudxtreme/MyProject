import base_client
import vmware.common.logger as logger
from nsx_upgrade_schema import NSXUpgradeSchema
import result

class NSXUpgrade(base_client.BaseClient):

    def __init__(self, nsx_appliance=None):
        """ Constructor to create NSXUpgrade object

        @param vsm object on which NSXUpgrade object has to be configured
        """
        super(NSXUpgrade, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nsx_upgrade_schema.NSXUpgradeSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.client_type = "vsm"
        if nsx_appliance != None:
            self.set_connection(nsx_appliance.get_connection())
        self.upload_endpoint = 'appliance-management/upgrade/uploadbundle/NSX'
        self.info_endpoint = 'appliance-management/upgrade/information/NSX'
        self.start_endpoint = 'appliance-management/upgrade/start/NSX'
        self.status_endpoint = 'appliance-management/upgrade/status/NSX'
        self.build_endpoint = 'appliance-management/global/info'
        self.create_endpoint = self.start_endpoint
        self.read_endpoint = self.status_endpoint
        self.id = None

    def read(self):
        temp_schema = self.schema_class
        self.schema_class = 'nsx_upgrade_status_schema.NSXUpgradeStatusSchema'
        obj = super(NSXUpgrade, self).read()
        self.schema_class = temp_schema
        return obj

if __name__ == '__main__':
    pass
