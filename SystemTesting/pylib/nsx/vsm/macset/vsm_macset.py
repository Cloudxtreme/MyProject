import vsm_client
import vmware.common.logger as logger
from vsm import VSM

UNIVERSAL_SCOPE = 'universal'

class MACSet(vsm_client.VSMClient):
    def __init__(self, vsm=None, scope=None):
        """ Constructor to create MACSet object

        @param vsm object on which MACSet has to be configured
        """
        super(MACSet, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_macset_schema.MACSetSchema'
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint("/services/macset/universalroot-0")
        else:
            self.set_create_endpoint("/services/macset/globalroot-0")

        self.set_read_endpoint("/services/macset")
        self.set_delete_endpoint("/services/macset")
        self.set_query_endpoint("/services/macset/scope/globalroot-0")
        self.id = None
        self.update_as_post = False

    def get_value(self):
        mac_set_schema_object = self.read()
        return mac_set_schema_object.value

if __name__ == '__main__':
    import base_client
    var = """
    <macset>
        <revision>0</revision>
        <name>TestMACSet-" + str(iterNo) + "</name>
        <description>Creating MACSet by ATS on scope globalroot-0</description>
        <inheritanceAllowed>true</inheritanceAllowed>
        <value>00:50:56:9f:b7:51</value>
    </macset>
    """
    log = logger.setup_logging('MacSet-Test')
    vsm_obj = VSM("10.110.28.193:443", "admin", "default")
    macset_client = MACSet(vsm_obj)

    #Create MACSet
    py_dict1 = {'name': 'macset-auto-1', 'value': '00:50:56:9f:b7:51', 'description': 'Test'}
    result_objs = base_client.bulk_create(macset_client, [py_dict1])
    print result_objs[0].status_code
    print macset_client.id

    #Update MACSet
    py_dict1 = {'description': 'Modified test description', 'revision': '2'}
    response_status = macset_client.update(py_dict1)
    print response_status

    #Delete MACSet
    response_status = macset_client.delete()
    print response_status.status_code
