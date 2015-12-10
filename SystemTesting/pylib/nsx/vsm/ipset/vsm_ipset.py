import vsm_client
import vmware.common.logger as logger
from vsm import VSM

UNIVERSAL_SCOPE = 'universal'

class IPSet(vsm_client.VSMClient):
    def __init__(self, vsm=None, scope=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(IPSet, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_ipset_schema.IPSetSchema'
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint("/services/ipset/universalroot-0")
        else:
            self.set_create_endpoint("/services/ipset/globalroot-0")

        self.set_read_endpoint("/services/ipset")
        self.set_delete_endpoint("/services/ipset")
        self.set_query_endpoint("/services/ipset/scope/globalroot-0")
        self.id = None
        self.update_as_post = False

    def get_value(self):
        ip_set_schema_object = self.read()
        return ip_set_schema_object.value


if __name__ == '__main__':
    import base_client
    var = """
    <ipset>
        <revision>0</revision>
        <name>TestIpSet-" + str(iterNo) + "</name>
        <description>Creating IpSet by ATS on scope globalroot-0</description>
        <inheritanceAllowed>true</inheritanceAllowed>
        <value>192.168.1.1</value>
    </ipset>
    """
    log = logger.setup_logging('IPSet-Test')
    vsm_obj = VSM("10.110.29.100:443", "admin", "default", None)
    ipset_client = IPSet(vsm_obj, 'universal')

    #Create IPSet
    py_dict1 = {'name': 'ipset-auto-1', 'value': '192.168.1.1', 'description': 'Test'}
    result_objs = base_client.bulk_create(ipset_client, [py_dict1])
    print result_objs[0].status_code
    print ipset_client.id

    #Update IPSet
    py_dict1 = {'description': 'Modified test description', 'revision': '2'}
    response_status = ipset_client.update(py_dict1)
    print response_status

    #Delete IPSet
    response_status = ipset_client.delete()
    print response_status.status_code