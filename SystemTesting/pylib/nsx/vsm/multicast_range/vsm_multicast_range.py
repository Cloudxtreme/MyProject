import vsm_client
from vsm_multicast_range_schema import MulticastRangeSchema
from vsm import VSM


class MulticastRange(vsm_client.VSMClient):
    def __init__(self, vsm=None, scope=None):
        """ Constructor to create MulticastRange managed object

        @param vsm : vsm object on which this managed object needs to be configured
        """
        super(MulticastRange, self).__init__()
        self.schema_class = 'vsm_multicast_range_schema.MulticastRangeSchema'
        self.set_connection(vsm.get_connection())
        if scope is None or scope is "":
            self.set_create_endpoint("/vdn/config/multicasts")
        else:
            self.set_create_endpoint("/vdn/config/multicasts?isUniversal=true")
            self.set_read_endpoint("/vdn/config/multicasts")
            self.set_delete_endpoint("/vdn/config/multicasts")
        self.id = None
        self.location_header = None

    def create(self, schema_object):
       """ Creates multicast range with specified parameters

       @param schema object which has the paramters to create
              multicast start and end and name.
       """
       result_obj = super(MulticastRange, self).create(schema_object)
       location_header = self.location_header
       if location_header is not None:
           self.id = location_header.split('/')[-1]
           result_obj[0].set_response_data(self.id)
       return result_obj


if __name__ == '__main__':
    import base_client
    var = """
    <multicastRange>
    <name>first_multicast</name>
    <desc>desc</desc>
    <begin>239.1.1.1</begin>
    <end>239.3.3.3</end>
    </multicastRange>
    """
    vsm_obj = VSM("10.24.20.197:443", "admin", "default")
    multicast_range_obj = MulticastRange(vsm_obj)
    multicast_range_obj.read();
    py_dict = {'name': 'multicast-python-1', 'desc': 'First_Multicast', 'begin': '239.0.0.1', 'end': '239.0.0.100'}
    base_client.bulk_create(multicast_range_obj, [py_dict])
    multicast_range_obj.delete();

