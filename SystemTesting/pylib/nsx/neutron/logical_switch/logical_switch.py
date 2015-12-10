import vmware.common.logger as logger
import neutron_client

class LogicalSwitch(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create LogicalSwitch object

        @param neutron object on which LogicalSwitch object has to be configured
        """
        super(LogicalSwitch, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'logical_switch_schema.LogicalSwitchSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_state_endpoint('/lswitches/%s/state')
        self.set_create_endpoint('/lswitches')
        self.id = None

if __name__ == '__main__':
    import neutron
    import base_client
    log = logger.setup_logging('Neutron IPSet Test')
    neutron_object = neutron.Neutron("10.110.31.147", "admin", "default")
    ls = LogicalSwitch(neutron=neutron_object)

    #Create New IPSet
    py_dict = {'transport_zone_binding': [{'transport_zone_id': 'tz-40c99b73-a476-43db-995c-9a41aab59016'}], 'display_name': 'ls_1'}
    result_objs = base_client.bulk_create(ls, [py_dict])
