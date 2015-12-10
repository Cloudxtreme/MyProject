import vmware.common.logger as logger
from transport_zone_schema import TransportZoneSchema
import neutron_client


class TransportZone(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create TransportZone object

        @param neutron object on which TransportZone object has to be configured
        """
        super(TransportZone, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'transport_zone_schema.TransportZoneSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/transport-zones')
        self.set_state_endpoint('/transport-zones/%s/state')
        self.id = None

if __name__ == '__main__':
    from bulk_get_schemas import BulkGetSchemas
    import neutron
    log = logger.setup_logging('Neutron IPSet Test')
    neutron_object = neutron.Neutron("10.110.27.173", "localadmin", "default")
    tz = TransportZone(neutron_object)
    bulk_get_tz = BulkGetSchemas(TransportZoneSchema())
    tz_list = tz.base_query()
    bulk_get_tz.set_data(tz_list, tz.accept_type)
    print bulk_get_tz
    print bulk_get_tz.print_object()

    for tz_schema in bulk_get_tz.results:
        tz.id = tz_schema.id
        state_schema = tz.get_state()
        print state_schema.state

