import vsm_client
import vmware.common.logger as logger
import service_instance_runtime_info_schema
from vsm import VSM
import inspect
import result

class ServiceInstanceRuntimeInfo(vsm_client.VSMClient):
    def __init__(self, serviceinstance=None):
        """ Constructor to create ServiceInstanceRuntimeInfo object
        @param vsm object on which ServiceInstanceRuntimeInfo has to be configured
        """
        super(ServiceInstanceRuntimeInfo, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_instance_runtime_info_schema.ServiceInstanceRuntimeInfoSchema'
        self.set_connection(serviceinstance.get_connection())
        #create endpoint e.g. si/serviceinstance/serviceinstance-1/runtimeinfo
        self.set_create_endpoint("si/serviceinstance/" + str(serviceinstance.id) + "/runtimeinfo")
        self.id = None
        self.update_as_post = True

    def update(self, py_dict, override_merge=False):
        # set endpoint
        # 'create_endpoint': 'si/serviceinstance/serviceinstance-17/runtimeinfo'
        # /si/serviceinstance/<serviceinstance-Id>/runtimeinfo/<sir-Id>/config?action=install
        endpoint = self.create_endpoint + '/' + str(self.id) + '/config?action=' + str(py_dict)
        if self.update_as_post:
             self.response = self.request('POST', endpoint)
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj
