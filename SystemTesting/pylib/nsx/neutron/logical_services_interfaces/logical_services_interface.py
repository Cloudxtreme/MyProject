import neutron_client
#import vmware.common.logger as logger
from logical_services_interface_schema import LogicalServicesInterfaceSchema

class LogicalServicesInterface(neutron_client.NeutronClient):

    def __init__(self, logical_services_node=None):
        """ Constructor to create LogicalServicesInterface object

        @param LogicalSwitch object on which LogicalServicesInterface object has to be configured
        """
        super(LogicalServicesInterface, self).__init__()
#        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'logical_services_interface_schema.LogicalServicesInterfaceSchema'

        if logical_services_node is not None:
            self.set_connection(logical_services_node.get_connection())

        self.set_create_endpoint("/lservices-routers/" + logical_services_node.id + "/interfaces")
        self.id = None


if __name__ == '__main__':
    pass
