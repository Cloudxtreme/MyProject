import vsm_client
import vmware.common.logger as logger
import vendor_template_schema
import result
from vsm import VSM
import tasks

class VendorTemplate(vsm_client.VSMClient):
    def __init__(self, service=None):
        """ Constructor to create Service object
        @param vsm object on which Service has to be configured
        """
        super(VendorTemplate, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vendor_template_schema.VendorTemplateSchema'
        self.set_connection(service.get_connection())
        self.set_create_endpoint("/si/service/" + str(service.id) + "/vendortemplate")
        self.id = None
        self.update_as_post = False

    @tasks.thread_decorate
    # Overriding create function in the base_client.py
    # in order to get data without empty tags
    def create(self, schema_object):
        """ Client method to perform create operation

        @param schema_object instance of VendorTemplate class
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
