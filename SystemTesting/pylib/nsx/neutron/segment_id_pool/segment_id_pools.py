import neutron_client


class SegmentIDPools(neutron_client.NeutronClient):
    def __init__(self, neutron):
        """ Constructor to create SegmentIDPools managed object

        @param neutron : neutron object on which this managed object needs to be configured
        """
        super(SegmentIDPools, self).__init__()
        self.schema_class = 'segment_id_pools_schema.SegmentIDPoolsSchema'
        self.set_connection(neutron.get_connection())
        self.set_create_endpoint("/pools/segmentid-pools")
        self.id = None
        self.location_header = None





