import nvp_client
import vmware.common.logger as logger
from nvp_logical_switch_port_schema import LogicalSwitchPortSchema

class LogicalSwitchPort(nvp_client.NVPClient):

    def __init__(self, logical_switch=None):
        """ Constructor to create LogicalSwitchPort object

        @param LogicalSwitch object on which LogicalSwitchPort object has to be configured
        """
        super(LogicalSwitchPort, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_logical_switch_port_schema.LogicalSwitchPortSchema'

        if logical_switch is not None:
            self.set_connection(logical_switch.get_connection())

        self.set_create_endpoint("lswitch/" + logical_switch.id +"/lport")
        self.id = None
        self.update_as_post = False

if __name__ == '__main__':
    pass
