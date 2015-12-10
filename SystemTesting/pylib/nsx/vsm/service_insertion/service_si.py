import vsm_client
import vmware.common.logger as logger
import service_si_schema
import deployed_services_status_schema
import result
import time
from vsm import VSM
import tasks

class Service(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create Service object
        @param vsm object on which Service has to be configured
        """
        super(Service, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_si_schema.ServiceSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/si/service")
        self.id = None
        self.update_as_post = False

    def get_response_dict(self):
        self.log.debug("*** Sleeping for 120 seconds before checking deployment status ***")
        time.sleep(120)
        # Here we are setting new read_endpoint, schema class
        self.set_read_endpoint('si/deploy/service')
        self.schema_class = 'deployed_services_status_schema.DeployedServicesStatusSchema'
        object = self.read()
        service_array = object.deployedServicesArray
        service_dict = None
        for service in service_array:
           if self.id == service.serviceId:
              service_dict = service.__dict__
        if service_dict != None:
           return service_dict
        else:
           # return undefined service dict if service is not available
           empty_service_dict =  { "progressStatus": None}
           return empty_service_dict

    @tasks.thread_decorate
    # Overriding create function in the base_client.py
    # in order to get data without empty tags
    def create(self, schema_object):
        """ Client method to perform create operation

        @param schema_object instance of ServiceSchema class
        @return result object
        """

        if schema_object is not None:
           self.response = self.request('POST', self.create_endpoint,
                                             schema_object.get_data_without_empty_tags(self.content_type))
        else:
           self.response = self.request('POST', self.create_endpoint)

        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj
