import vmware.common.logger as logger
import nvp_client
import connection
import nvp_logical_switch_schema
import transport_zone_schema

class LogicalSwitch(nvp_client.NVPClient):

    def __init__(self, nvp_controller=None):

        super(LogicalSwitch, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_logical_switch_schema.LogicalSwitch'

        if nvp_controller != None:
            self.set_connection(nvp_controller.get_connection())

        self.set_create_endpoint('lswitch')

