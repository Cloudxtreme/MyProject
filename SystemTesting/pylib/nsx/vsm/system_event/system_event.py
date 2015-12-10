import vsm_client
from vmware.common.global_config import pylogger
import paged_system_event_list_schema
from vsm import VSM

class SystemEvent(vsm_client.VSMClient):

    def __init__(self, vsm=None):
        """ Constructor to create SystemEvent object

        @param vsm object on which SystemEvent object has to be configured
        """
        super(SystemEvent, self).__init__()
        self.log = pylogger
        self.schema_class = 'paged_system_event_list_schema.PagedSystemEventListSchema'
        self.set_connection(vsm.get_connection())
        self.set_read_endpoint("systemevent?sortOrderAscending=false")

    def read_dfw_events(self):
        """ Checks for event with given code"""

        schema_obj = self.read()

        event_dict = {
            'cpu_ts' : 0,
            'mem_ts' : 0,
            'cps_ts' : 0,
            'cpu_event_count' : 0,
            'mem_event_count' : 0,
            'cps_event_count' : 0,
        }

        if not schema_obj:
            self.log.error("No events returned by GET call")

        for event_obj in schema_obj.dataPage.systemEvent :

            if event_obj.eventCode == '301080':
                #Check for Firewall_CPU_THRESHOLD_CROSSED(301080) event
                if event_dict['cpu_ts'] == 0:
                    self.log.debug("CPU threshold crossed at %s" % event_obj.timestamp)
                    event_dict['cpu_ts'] = event_obj.timestamp
                event_dict['cpu_event_count'] += 1

            elif event_obj.eventCode == '301081':
                #Check for Firewall_MEMORY_THRESHOLD_CROSSED(301081) event
                if event_dict['mem_ts'] == 0:
                    self.log.debug("Memory threshold crossed at %s" % event_obj.timestamp)
                    event_dict['mem_ts'] = event_obj.timestamp
                event_dict['mem_event_count'] += 1

            elif event_obj.eventCode == '301082':
                #Check for Firewall_CPS_THRESHOLD_CROSSED(301082) event
                if event_dict['cps_ts'] == 0:
                    self.log.debug("CPS threshold crossed at %s" % event_obj.timestamp)
                    event_dict['cps_ts'] = event_obj.timestamp
                event_dict['cps_event_count'] += 1

        return event_dict


if __name__ == '__main__':

    vsm_obj = VSM("10.24.226.208:443", "admin", "default", "")
    es_client = SystemEvent(vsm_obj)

    print es_client.read_dfw_events()



