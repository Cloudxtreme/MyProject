import vmware.common.logger as logger
import neutron_client

class MulticastRange(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create LogicalSwitch object

        @param neutron object on which LogicalSwitch object has to be configured
        """
        super(MulticastRange, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'multicast_range_schema.MulticastRangeSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/pools/multicast-pools')
        self.id = None


if __name__ == '__main__':
    pass