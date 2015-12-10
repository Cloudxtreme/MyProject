import pylib
import re
import vmware.common.logger as logger
import vsm_client
import ipfix_configuration_schema
from vsm import VSM
import tasks

class IPFIX(vsm_client.VSMClient):

    def __init__(self, vsm=None):
        """ Constructor to create IPFIX object

        @param vsm object on which IPFIX object has to be configured
        """
        super(IPFIX, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'ipfix_configuration_schema.IpfixConfigurationSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/firewall/globalroot-0/config/ipfix")
        self.set_read_endpoint("/firewall/globalroot-0/config/ipfix")
        self.set_delete_endpoint("/firewall/globalroot-0/config/ipfix")

        self.update_as_post = False
        self.create_as_put = True

    @tasks.thread_decorate
    def create(self, schema_obj):
        for collector in schema_obj.collector:
            # ipv6 addresses are in form of list
            # using the first address in list
            if type(collector.ip) is list:
                collector.ip = re.split('/', collector.ip[0])[0]
        result_obj = super(IPFIX, self).create(schema_obj)
        self.id = "ipfix-1"
        result_obj[0].response_data = "ipfix-1"
        return result_obj[0]

    def delete(self, schema_object = None):
        self.id = None
        return super(IPFIX, self).delete()


if __name__ == '__main__':

    vsm_obj = VSM("10.24.227.148", "admin", "default", "","4.0")
    ipf_client = IPFIX(vsm_obj)

    py_dict = {
                  'contextid' : "globalroot-0",
                  'ipfixenabled' : "true",
                  'flowtimeout' : "5",
                  'collector' : [{
                                    'ip' : "fc00:10:24:227:250:56ff:fe92:aa8/64",
                                    'port' : "9999",
                                }],
              }

    schema_obj = ipfix_configuration_schema.IpfixConfigurationSchema(py_dict)

    result_obj = ipf_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()

