import base_client
import vmware.common.logger as logger
from segment_range_schema import SegmentRangeSchema
import neutron

class SegmentRange(base_client.BaseClient):

    def __init__(self, neutron=None):
        """ Constructor to create LogicalSwitch object

        @param neutron object on which LogicalSwitch object has to be configured
        """
        super(SegmentRange, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'segment_range_schema.SegmentRangeSchema'
        self.set_content_type('application/json')
        self.set_accept_type('application/json')
        self.auth_type = "neutron"
        self.client_type = "neutron"

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/pools/segmentid-pools')
        self.id = None
        self.update_as_post = False

    def read(self):
        neutron_segment_range = SegmentRangeSchema()
        neutron_segment_range.set_data(self.base_read())
        return neutron_segment_range

if __name__ == '__main__':
    pass