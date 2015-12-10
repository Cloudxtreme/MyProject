import neutron_client
import vmware.common.logger as logger
from logical_switch_port_schema import LogicalSwitchPortSchema

class LogicalSwitchPort(neutron_client.NeutronClient):

    def __init__(self, logical_switch=None):
        """ Constructor to create LogicalSwitchPort object

        @param LogicalSwitch object on which LogicalSwitchPort object has to be configured
        """
        super(LogicalSwitchPort, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'logical_switch_port_schema.LogicalSwitchPortSchema'

        if logical_switch is not None:
            self.set_connection(logical_switch.get_connection())

        self.set_create_endpoint("/lswitches/" + logical_switch.id +"/ports")
        self.id = None

if __name__ == '__main__':
    pass