import vsm_client
import vmware.common.logger as logger
import result
import service_instances_schema
import service_instance_schema
from vsm import VSM
import tasks

class ServiceInstance(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create ServiceInstance object
        @param vsm object on which ServiceInstance has to be configured
        """
        super(ServiceInstance, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_instance_schema.ServiceInstanceSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint('/si/serviceinstance')
        self.set_read_endpoint('/si/serviceinstances')
        self.set_delete_endpoint('/si/serviceinstance')
        self.id = None

    # Overriding read function in the base_client.py
    def read(self):
        """ Client method to perform READ operation """
        self.schema_class = 'service_instances_schema.ServiceInstancesSchema'
        schema_object = super(ServiceInstance, self).read()
        self.schema_class = 'service_instance_schema.ServiceInstanceSchema'
        return schema_object

    @tasks.thread_decorate
    # Overriding create function in the base_client.py
    def create(self, r_schema):
        service_instances_object = self.read()
        service_instances_array = service_instances_object.serviceInstanceArray
        required_service_instance = ''
        # check for the default service instance created for host based
        # service insertion, if the service instance is not created for
        # management based service insertion then create a new one using
        # post call
        for s in service_instances_array:
            if r_schema._serviceid == s.service.objectId: # check for defined r_schema._serviceid
                self.log.debug("Service Instance is %s" % s.objectId)
                required_service_instance = s.objectId
        if required_service_instance != '' and required_service_instance != None:
           result_obj = result.Result()
           result_obj.set_status_code(200)
           result_obj.set_response_data(required_service_instance)
        else:
           # make a create call, if the service instance is not there
           self.schema_class = 'service_instance_schema.ServiceInstanceSchema'
           self.log.debug("Make POST call to create service instance")
           self.response = self.request('POST', self.create_endpoint,
               r_schema.get_data_without_empty_tags(self.content_type))
           result_obj = result.Result()
           self.set_result(self.response, result_obj)
        return result_obj
