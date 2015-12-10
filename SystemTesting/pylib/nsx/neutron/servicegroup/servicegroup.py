import vmware.common.logger as logger
import neutron_client

class ServiceGroup(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create ServiceGroup object

        @param neutron object on which ServiceGroup object has to be configured
        """
        super(ServiceGroup, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_group_schema.ServiceGroupSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/groupings/service-groups')
        self.id = None

if __name__ == '__main__':
    pass