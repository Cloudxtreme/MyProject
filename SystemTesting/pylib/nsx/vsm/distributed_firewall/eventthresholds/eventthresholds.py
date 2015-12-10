import pylib
import logger
import vsm_client
import event_thresholds_schema
from vsm import VSM

class EventThresholds(vsm_client.VSMClient):

    def __init__(self, vsm=None):
        """ Constructor to create EventThresholds object

        @param vsm object on which EventThresholds object has to be configured
        """
        super(EventThresholds, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'event_thresholds_schema.EventThresholdsSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/firewall/stats/eventthresholds")
        self.set_read_endpoint("/firewall/stats/eventthresholds")

        self.create_as_put = True


if __name__ == '__main__':

    vsm_obj = VSM("10.24.20.211:443", "admin", "default", "", "4.0")
    eventthresholds_client = EventThresholds(vsm_obj)

    py_dict = {'cpu':{'percentvalue':'11'},
               'memory':{'percentvalue':'9'}}

    schema_obj = event_thresholds_schema.EventThresholdsSchema(py_dict)

    result_obj = eventthresholds_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()




