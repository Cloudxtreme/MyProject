import pylib
import vmware.common.logger as logger
import result
import vsm_client
import flow_configuration_schema
from vsm import VSM
import traceback
import tasks

class FlowConfiguration(vsm_client.VSMClient):

    def __init__(self, vsm=None):
        """ Constructor to create FlowConfiguration object

        @param vsm object on which FlowConfiguration object has to be configured
        """
        super(FlowConfiguration, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'flow_configuration_schema.FlowConfigurationSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/app/flow/config")
        self.set_read_endpoint("/app/flow/config")
        self.set_delete_endpoint("/app/flow/config")

        self.update_as_post = False
        self.create_as_put = True

    @tasks.thread_decorate
    def create(self, schema_obj):
        # Read current config
        temp_obj = self.read()
        try:
            # Merge current config with new config
            self.merge_objects(temp_obj, schema_obj)
        except:
            tb = traceback.format_exc()
            self.log.debug("Trace Back: %s" % tb)

        # Create using PUT
        self.response = self.request('PUT', self.create_endpoint,
                            temp_obj.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj


if __name__ == '__main__':

    vsm_obj = VSM("10.24.226.221:443", "admin", "default", "","2.1")
    fe_client = FlowConfiguration(vsm_obj)

    py_dict = {
                  'collectflows' : "true"
              }

    schema_obj = flow_configuration_schema.FlowConfigurationSchema(py_dict)

    result_obj = fe_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()




