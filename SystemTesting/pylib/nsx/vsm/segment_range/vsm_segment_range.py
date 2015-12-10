import vsm_client
from vsm_segment_range_schema import SegmentRangeSchema
from vsm import VSM
import vmware.common.logger as logger


class SegmentRange(vsm_client.VSMClient):
    def __init__(self, vsm=None, scope=None):
        """ Constructor to create SegmentRange managed object

        @param vsm object on which segment range has to be configured
        """
        super(SegmentRange, self).__init__()
        self.schema_class = 'vsm_segment_range_schema.SegmentRangeSchema'
        self.set_connection(vsm.get_connection())
        if scope is None or scope is "":
            self.set_create_endpoint("/vdn/config/segments")
        else:
            self.set_create_endpoint("/vdn/config/segments?isUniversal=true")
            self.set_read_endpoint("/vdn/config/segments")
            self.set_delete_endpoint("/vdn/config/segments")
        self.id = None
        self.location_header = None

    def create(self, schema_object):
        """ Creates segment range with specified parameters

        @param schema object which has the paramters to create
               the segment range
        """
        result_obj = super(SegmentRange, self).create(schema_object)
        location_header = self.location_header
        if location_header is not None:
            self.id = location_header.split('/')[-1]
            result_obj[0].set_response_data(self.id)
        return result_obj


if __name__ == '__main__':
    import base_client
    var = """
    <segmentRange>
    <name>name-2</name>
    <desc>desc</desc>
    <begin>10000</begin>
    <end>11000</end>
    </segmentRange>
    """
    log = logger.setup_logging('VDNScopeTest')
    vsm_obj = VSM("10.110.28.44:443", "admin", "default")
    segment_range_obj = SegmentRange(vsm_obj)
    py_dict = {'name': 'seg-python-1', 'desc': 'Second_Seg', 'begin': '15000', 'end': '15500'}
    #segment_id = base_client.bulk_create(segment_range_obj, [py_dict])
    #segment_range_obj.id = '3'
    #response = segment_range_obj.delete()
    py_dict1 = {'name': 'demo-segmentid-253124', 'begin': '11001', 'end': '12000'}
    #py_dict2 = {'name': '5001-5100', 'begin': '5001', 'end': '5100'}
    #print segment_range_obj.verify(['3'], [py_dict])
    #result = base_client.bulk_verify(segment_range_obj, ['3', '2'], [py_dict1, py_dict2])
    #log.info(result)
    base_client.bulk_create(segment_range_obj, [py_dict])
    segment_range_obj.delete()

    #print segment_range
